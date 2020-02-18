from utilities import types, validate
from api import gitlab
from logging import info

gitlab = gitlab.GitLab(types.Arguments().url)


def get_all(project_id, project_url):
    issues = []
    details = gitlab.get_issues(project_id)
    if validate.api_result(details):
        info("[*] Found %s issues for project %s", len(details), project_url)
        for item in details:
            issues.append(types.Issue(item['iid'], item['web_url'], item['description']))
    return issues


def sniff_secrets(issue):
    monitor = types.SecretsMonitor()
    return monitor.sniff_secrets({issue.web_url: issue.description})
