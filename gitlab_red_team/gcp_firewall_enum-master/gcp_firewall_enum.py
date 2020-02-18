#!/usr/bin/env python3

"""
Process gcloud output to determine applied firewall rules.

Firewall rules are applied via multiple methods and Google does not provide
an easy way to script what rules are actually applied to what compute
instances.

Please see the included README for detailed instructions.
"""

import glob
import sys
import os
import json
import argparse
import re


def process_args():
    """Handles user-passed parameters"""
    parser = argparse.ArgumentParser()
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument('--single', '-s', type=str, action='store',
                        help='Single directory containing json files.')
    target.add_argument('--multi', '-m', type=str, action='store',
                        help='Root directory contains multiple subdirectories'
                        ' of json files')

    parser.add_argument('--exclude', '-e', type=str, action='store',
                        help='Skip compute instances matching python regex')

    args = parser.parse_args()
    if args.single:
        target = os.path.abspath(args.single)
    else:
        target = os.path.abspath(args.multi)

    # Before moving on, validate all the input data is present
    if not os.path.isdir(target):
        print("[!] That directory does not exist. Please try again.")
        sys.exit()

    # If a regrex is provided, validate it
    if args.exclude:
        try:
            args.exclude = re.compile(args.exclude)
        except re.error:
            print("[!] Error parsing regex. Please try harder.")
            sys.exit()

    return args

def parse_json(file):
    """
    Loads the json data from a file into memory
    """
    # If used in multi mode, there is a good chance we hit a lot of empty
    # or missing files. We'll return empty data on those so the program can
    # continue with the next directory.
    if not os.path.isfile(file):
        return {}

    with open(file, 'r') as infile:
        try:
            data = json.load(infile)
        except json.decoder.JSONDecodeError:
            return {}

    return data

def cleanup_rules(rules):
    """
    Extracts details from firewall rules for easier processing
    """
    clean_rules = []

    for rule in rules:
        name = rule['name']
        udp_ports = []
        tcp_ports = []

        if 'all' in rule['allowed']:
            tcp_ports = ['all']
            udp_ports = ['all']
        else:
            for ports in rule['allowed']:
                if 'tcp' in ports:
                    tcp_ports = [port.replace('tcp:', '') for port in ports.split(',')]
                if 'udp' in ports:
                    udp_ports = [port.replace('udp:', '') for port in ports.split(',')]

        # If a rule set has no target tags and no target svc account
        # then it is applied at the VPC level, so we grab that here.
        if 'targetServiceAccounts' not in rule and 'targetTags' not in rule:
            network = rule['network']
        # Otherwise, we are not interested in the network and can discard
        # it so that future functions will not think rules are applied
        # network-wide.
        else:
            network = ''

        # Tags and target svc accounts may or may not exist
        if 'targetTags' in rule:
            net_tags = rule['targetTags'].split(',')
        else:
            net_tags = []
        if 'targetServiceAccounts' in rule:
            svc_tags = rule['targetServiceAccounts'].split(',')
        else:
            svc_tags = []

        clean_rules.append({'name': name,
                            'tcp_ports': tcp_ports,
                            'udp_ports': udp_ports,
                            'net_tags': net_tags,
                            'svc_tags': svc_tags,
                            'network': network})
    return clean_rules

def cleanup_instances(instances, exclude):
    """
    Extracts details from instace data for easier processing
    """
    clean_instances = []
    excluded = 0

    for instance in instances:
        # The following values should exist for each instance due to the
        # gcloud filtering used.
        name = instance['name']
        networks = [interface['network'] for interface in instance['networkInterfaces']]
        external_ip = instance['networkInterfaces'][0]['accessConfigs'][0]['natIP']

        # Complete skip instances matching user-provided regex, if given
        if exclude and re.match(exclude, name):
            excluded += 1
            continue

        # The following values may or may not exist, it depends how the
        # instance is configured.
        if 'serviceAccounts' in instance:
            svc_account = instance['serviceAccounts'][0]['email']
        else:
            svc_account = ''
        if 'tags' in instance:
            tags = instance['tags']['items']
        else:
            tags = []

        clean_instances.append({'name': name,
                                'tags': tags,
                                'svc_account': svc_account,
                                'networks': networks,
                                'external_ip': external_ip})

    if excluded:
        print("[*] Excluded {} instances due to provided regex"
              .format(excluded))

    return clean_instances

def merge_dict(applied_rules, rule, instance):
    """
    Adds or updates final entries into dictionary

    Using a discrete function as several functions update this dictionary, so
    we need to check for the existence of a key and then decide to create or
    update it.
    """
    name = instance['name']

    if name in applied_rules:
        applied_rules[name]['allowed_tcp'].update(rule['tcp_ports'])
        applied_rules[name]['allowed_udp'].update(rule['udp_ports'])
    else:
        applied_rules[name] = {'external_ip': instance['external_ip'],
                               'allowed_tcp': set(rule['tcp_ports']),
                               'allowed_udp': set(rule['udp_ports'])}

    return applied_rules

def process_tagged_rules(applied_rules, rules, instances):
    """
    Extracts effective firewall rules applied by network tags on instances
    """
    for rule in rules:
        for instance in instances:
            for tag in rule['net_tags']:
                if tag in instance['tags']:
                    applied_rules = merge_dict(applied_rules, rule, instance)
    return applied_rules

def process_vpc_rules(applied_rules, rules, instances):
    """
    Extracts effective firewall rules applied by VPC membership
    """
    for rule in rules:
        for instance in instances:
            # In the cleaning function, we only applied a network tag if the
            # rule is applied to the whole VPC. So a match means it applies.
            if rule['network'] and rule['network'] in instance['networks']:
                applied_rules = merge_dict(applied_rules, rule, instance)

    return applied_rules

def process_svc_rules(applied_rules, rules, instances):
    """
    Extracts effective firewall rules applied by service accounts
    """
    for rule in rules:
        if rule['svc_tags']:
            for instance in instances:
                if instance['svc_account'] in rule['svc_tags']:
                    applied_rules = merge_dict(applied_rules, rule, instance)

    return applied_rules

def process_output(applied_rules):
    """
    Takes the python dictionary format and output several useful files
    """
    if not applied_rules:
        print("[!] No publicly exposed ports, sorry!")
        sys.exit()

    print("[*] Processing output for {} instances with exposed ports"
          .format(len(applied_rules)))

    out_dir = 'out-firewall-data'
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    # First, write the raw data in CSV
    with open(out_dir + '/applied-rules.csv', 'w') as outfile:
        outfile.write("name,external_ip,allowed_tcp,allowed_udp\n")
        for i in applied_rules:
            outfile.write("{},{},{},{}\n"
                          .format(i,
                                  applied_rules[i]['external_ip'],
                                  applied_rules[i]['allowed_tcp'],
                                  applied_rules[i]['allowed_udp'])
                          .replace("set()", ""))

    # Next, make an nmap script
    nmap_tcp = 'nmap --open -Pn -sV -oX {}-tcp.xml {} -p {}\n'
    nmap_tcp_common = 'nmap --open -Pn -sV -oX {}-tcp.xml {}\n'
    nmap_udp = 'sudo nmap --open -Pn -sU -sV -oX {}-udp.xml {} -p {}\n'
    nmap_udp_common = 'sudo nmap --open -Pn -sU -sV -oX {}-udp.xml {} -F\n'

    with open(out_dir + '/run-nmap.sh', 'w') as outfile:
        for name in applied_rules:
            external_ip = applied_rules[name]['external_ip']

            # Need to check for "all" ports a few ways, as it can be
            # a text flag of 'all' or the admin can manually specific a
            # big ol' range.
            if applied_rules[name]['allowed_tcp']:
                ports = ','.join(applied_rules[name]['allowed_tcp'])
                if 'all' in ports or '0-65535' in ports or '1-65535' in ports:
                    outfile.write("echo running common TCP scans against {}\n"
                                  .format(name))
                    outfile.write(nmap_tcp_common.format(name, external_ip))
                else:
                    outfile.write("echo running TCP scans against {}\n"
                                  .format(name))
                    outfile.write(nmap_tcp.format(name, external_ip, ports))

            if applied_rules[name]['allowed_udp']:
                ports = ','.join(applied_rules[name]['allowed_udp'])
                if 'all' in ports or '0-65535' in ports or '1-65535' in ports:
                    outfile.write(nmap_udp_common.format(name, external_ip))
                else:
                    outfile.write("echo running UDP scans against {}\n"
                                  .format(name))
                    outfile.write(nmap_udp.format(name, external_ip, ports))

    # Now, write masscan script for machines with all TCP ports open
    masscan = 'sudo masscan -p{} {} --rate=1000 --open-only -oX {}-masscan.xml --banner\n'
    with open(out_dir + '/run-masscan.sh', 'w') as outfile:
        for name in applied_rules:
            external_ip = applied_rules[name]['external_ip']

            if set(['all']) in applied_rules[name].values():
                outfile.write("echo running full masscan against {}\n"
                              .format(name))
                outfile.write(masscan.format('1-65535', external_ip, name))

    print("[+] Wrote some files to {}, enjoy!".format(out_dir))


def main():
    """
    Main function to parse json files and write analyzed output
    """
    args = process_args()

    applied_rules = {}
    rules = []
    instances = []

    # Functions below in a loop based on whether we are targeting json files
    # in a single directory or a tree with multiple project subdirectories.
    if args.multi:
        targets = glob.glob(args.multi + '/*')
    else:
        targets = [args.single]

    for target in targets:
        rules = parse_json(target + '/firewall-rules.json')
        instances = parse_json(target + '/compute-instances.json')

        if not rules or not instances:
            print("[!] No valid data in {}".format(target))
            continue

        # Clean the data up a bit
        rules = cleanup_rules(rules)
        print("[*] Processed {} firewall rules in {}"
              .format(len(rules), target))

        instances = cleanup_instances(instances, args.exclude)
        print("[*] Processed {} instances in {}"
              .format(len(instances), target))

        # Connect the dots and build out the applied rules dictionary
        applied_rules = process_tagged_rules(applied_rules, rules, instances)
        applied_rules = process_vpc_rules(applied_rules, rules, instances)
        applied_rules = process_svc_rules(applied_rules, rules, instances)

    # Process data and create various output files
    process_output(applied_rules)


if __name__ == '__main__':
    main()
