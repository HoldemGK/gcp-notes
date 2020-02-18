from utilities import types
from api import gitlab
from utilities import validate, types
from logging import info

gitlab = gitlab.GitLab(types.Arguments().url)


def get_all(projects):
    snippets = {}
    for project in projects:
        for key, value in project.items():
            details = gitlab.get_project_snippets(key)
            if validate.api_result(details):
                info("[*] Found %s snippets for project %s", len(details), value)
                for item in details:
                    snippets.update({item['id']: item['web_url']})
    return snippets


def sniff_secrets(snippets):
    if len(snippets) == 0:
        return []
    secrets = []
    raw_data = {}
    for snippet_id, snippet_url in snippets.items():
        raw_content = gitlab.get_snippet_raw(snippet_id)
        raw_data.update({snippet_url: raw_content})
    if len(raw_data) > 0:
        monitor = types.SecretsMonitor()
        found_secrets = monitor.sniff_secrets(raw_data)
        for secret in found_secrets:
            secrets.append(secret)
    return secrets
