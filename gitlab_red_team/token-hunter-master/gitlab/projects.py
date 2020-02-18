from logging import info
from api import gitlab
from utilities import validate, types

gitlab = gitlab.GitLab(types.Arguments().url)


def all_group_projects(group):
    group_projects = {}

    info("[*] Fetching projects from group %s", group)
    details = gitlab.get_group_projects(group)
    if validate.api_result(details):
        info("[*] Found %s projects for group %s", len(details), group)

        for item in details:
            group_projects.update({item['id']: item['http_url_to_repo']})

    return group_projects


# move to gitlab/members
def all_member_projects(member):
    personal_projects = {}
    details = gitlab.get_personal_projects(member)
    if validate.api_result(details):
        info("[*] Found %s projects for member %s", len(details), member)
        for item in details:
            personal_projects[item['id']] = item['http_url_to_repo']

    return personal_projects
