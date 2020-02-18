# Token-Hunter

Collect OSINT for [GitLab groups](https://docs.gitlab.com/ee/user/group/) and [members](https://docs.gitlab.com/ee/user/project/members/#share-project-with-group) and search the group and group members' [snippets](https://docs.gitlab.com/ee/user/snippets.html), [issues](https://docs.gitlab.com/ee/user/project/issues/), and [issue discussions](https://docs.gitlab.com/ee/api/discussions.html#discussions-api) for sensitive data that may be included in these assets. The information gathered is intended to compliment and inform the use of additional tools such as [TruffleHog](https://github.com/dxa4481/truffleHog) or [GitRob](https://github.com/michenriksen/gitrob), which search git commit history using a similar technique of regular expression matching.  

# How the tool works

Start by providing a group ID for a specific group on GitLab.  You can find the group ID underneath the group name in the GitLab UI.  Token-Hunter will use the GitLab group ID to find all associated projects for that group and, optionally, the groups members personal projects.  Configure the tool to look for sensitive data in assets related to the projects it finds.  Token-Hunter uses the [same set of regular expressions as TruffleHog](https://github.com/dxa4481/truffleHogRegexes) with a few additions for GitLab specific tokens.  Token-Hunter depends on these [easily configurable regular expressions](https://gitlab.com/gitlab-com/gl-security/gl-redteam/token-hunter/blob/master/regexes.json) for accuracy and effectiveness.  Currently, the tool supports GitLab snippets, issues, and issue discussions with plans for future expansion to other assets.  The tool is intended to be very configurable to allow for efficient discovery of sensitive data in the assets you're specifically interested in.

# Usage

Before running the tool, you will need to [generate a GitLab Personal Access Token (PAT)](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) and export it as an environment variable. This can be done as shown below (please select `api` in the `scopes` section):

```
export GITLAB_API_TOKEN=xxxxx
```

Next, clone the repository and install dependencies with:

```
git clone https://gitlab.com/gitlab-com/gl-security/gl-redteam/token-hunter.git
pip3 install -r ./requirements.txt
```

Then, you can run the tool and specify your options as follows:

```
usage: token-hunter.py [-h] -g GROUP [-u URL] [-m] [-s] [-i] [-t] [-p PROXY]
                    [-c CERT] [-l LOGFILE]

Collect OSINT for GitLab groups and members. Optionally search the group and
group members project snippets, issues, and issue discussions and comments for
sensitive data.

optional arguments:
  -h, --help            show this help message and exit
  -u URL, --url URL     Optional argument that specifies the root url of your
                        GitLab instance. If the argument is not supplied, it
                        defaults to 'https://gitlab.com'
  -m, --members         Include group members personal projects and their
                        related assets in the searchfor sensitive data.
  -s, --snippets        Searches found projects for GitLab Snippets with
                        sensitive data.
  -i, --issues          Searches found projects for GitLab Issues and
                        discussions/comments with sensitive data.
  -t, --timestamp       Disables display of start/finish times and originating
                        IP to the output
  -p PROXY, --proxy PROXY
                        Proxies all requests using the provided URI matching
                        the scheme: http(s)://user:pass@10.10.10.10:8000
  -c CERT, --cert CERT  Used in tandem with -p (--proxy), this switch provides
                        a fully qualified path to a certificate to verify TLS
                        connections. Provide a fully qualified path to the
                        dynamic cert. Example:
                        /Users/<username>/owasp_zap_root_ca.cer.
  -l LOGFILE, --logfile LOGFILE
                        Will APPEND all output to specified file.

required arguments:
  -g GROUP, --group GROUP
                        ID or HTML encoded name of a GitLab group. This
                        option, by itself, will display group projects and
                        member names only.
```

# Usage Examples

`./token-hunter.py -g 123456`

The simplest use case is to return all the project URLs associated with a group by providing the group ID with the `-g` switch.  You can find the group ID underneath the group name in the GitLab UI.  No token searches are performed with this configuration.

`./token-hunter.py -g 123456 -m`

Finds all projects for group 123456 as well as all of the personal projects for the group members.  No token searches are performed with this configuration.

`./token-hunter.py -g 123456 -ms`

Finds all projects for group 123456 as well as all of the personal projects for the group members.  The `-s` switch tells Token-Hunter to search GitLab snippets associated with each found project for sensitive data.

`./token-hunter.py -g 123456 -msi`

Finds all projects for group 123456 as well as all of the personal projects for the group members.  The `-s` switch tells Token-Hunter to search GitLab snippets associated with each found project for sensitive data.  The `-i` switch tell Token-Hunter to also search issues and discussions  for each of the found projects for sensitive data.  **CAUTION** This configuration has the potential to pull a lot of data!

`./token-hunter.py -g 123456 -msit -u https://mygitlab-instance.com -p http://127.0.01:8080 -c /Users/hacker/owasp_zap_ca_cert.cer -l ./appended-output.txt`

Performs the same asset searches as the previous example against a self-hosted installation of GitLab running at `https://mygitlab-instance.com`.  Requests and responses that the tool generates are proxied through `http://127.0.01:8080` using the certificate defined at the fully qualified path `/Users/hacker/owasp_zap_ca_cert.cer` to decrypt the TLS traffic.  Timestamps and origin IP are excluded from the output with the `-t` switch.  Output is *APPENDED* to the `./appended-output.txt` file with the `-l` switch.

# Contributing

Contributions are welcome from the community.  You can find and add to the issue list, submit merge requests, and add to the existing discussions.  Token-Hunter is written in python 3.  To make a code contribution:

1. [Install python version 3](https://realpython.com/installing-python/)
1. Install pip version 3 to manage dependencies using the guide above.
1. Clone the repository
1. In the root directory, install dependencies with `pip3 install -r ./requirements.txt`
1. [Create a branch](https://docs.gitlab.com/ee/gitlab-basics/create-branch.html) for the changes you'd like to make.
1. Modify or add test coverage in the existing `./test_*` files, adding new files as needed.
1. Execute tests, written in [pytest](http://doc.pytest.org/), with `pytest -v` to make sure they pass.
1. Create a merge requests for your changes and tag `@gitlab-red-team` to review and merge it.
1. Repeat!
