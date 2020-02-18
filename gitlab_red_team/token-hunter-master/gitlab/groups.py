from logging import info
from api import gitlab
from utilities import types

gitlab = gitlab.GitLab(types.Arguments().url)


def get(group):
    info("[*] Fetching group details for %s", group)
    return gitlab.get_group(group)
