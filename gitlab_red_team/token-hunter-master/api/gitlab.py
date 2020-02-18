from logging import warning

import os
import re
import requests
from api import http
from utilities import types, constants


def build_session():
    command_args = types.Arguments()

    def get_cert():
        if not command_args.cert:
            return True
        return command_args.cert

    def get_proxies():
        proxy_url = command_args.proxy
        if not proxy_url:
            return {}
        return {
            "http": proxy_url,
            "https": proxy_url,
        }

    session = requests.session()
    session.headers.update({
        "PRIVATE-TOKEN": os.getenv(constants.Environment.gitlab_api_token()),
        "USER-AGENT": "token-hunter"
    })
    session.proxies = get_proxies()
    session.verify = get_cert()
    return session


class GitLab:

    def __init__(self, base_url, session_builder=build_session):
        self.http = http.Http(session_builder)
        self.base_url = base_url + "/api/v4"
        self.visited_urls = {}
        self.next_page_regex = re.compile(r'<([^<>]*?)>; rel="next"')

    def get_issue_comments(self, project_id, issue_id):
        return self.get('{}/projects/{}/issues/{}/discussions'.format(self.base_url, project_id, issue_id))

    def get_issues(self, project_id):
        return self.get('{}/projects/{}/issues'.format(self.base_url, project_id))

    def get_project_snippets(self, project):
        return self.get('{}/projects/{}/snippets'.format(self.base_url, project))

    def get_snippet_raw(self, snippet_id):
        return self.get('{}/snippets/{}/raw?line_ending=raw'.format(self.base_url, snippet_id))

    def get_personal_projects(self, member):
        return self.get('{}/users/{}/projects'.format(self.base_url, member))

    def get_group_projects(self, group):
        return self.get('{}/groups/{}/projects'.format(self.base_url, group))

    def get_group(self, group):
        return self.get('{}/groups/{}'.format(self.base_url, group))

    def get_members(self, group):
        return self.get('{}/groups/{}/members'.format(self.base_url, group))

    def get_current_user(self):
        details = self.get('{}/user'.format(self.base_url))

        if not details:
            return False

        username = details['username']
        return username

    def get(self, url):
        """
        Helper function to interact with GitLab API using python requests

        The important things here are:
            - Adding the PRIVATE-TOKEN header based on env variable
            - interacting with the pagination process via LINK headers
              (https://docs.gitlab.com/ee/api/README.html#pagination)
        """

        response = self.http.get_with_retry_and_paging_adjustment(url)

        if not (response and response.status_code == 200):
            # If code not 200, no results to process
            return False
        # The "Link" header is returned when there is more than one page of
        # results. GitLab asks that we use this link instead of crafting
        # our own.
        if 'Link' not in response.headers:
            # Otherwise, return just the single result
            return response.json() if response.headers["Content-Type"] == "application/json" else response.text
        # initialize a new variable to begin compounding multi-page
        # results
        all_results = response.json()
        # Now, loop through until there is no 'next' link provided
        while 'Link' in response.headers and 'rel="next"' in response.headers['Link']:
            next_url = re.findall(self.next_page_regex, response.headers['Link'])[0]
            # Add the individual response to the collective
            response = self.http.get_with_retry_and_paging_adjustment(next_url)
            if response.status_code == 200:
                all_results += response.json()
            else:
                warning("[!] Error (%s) processing pagination URL: %s", response.status_code, next_url)
        # Return the collective results
        return all_results




