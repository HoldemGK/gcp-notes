from utilities import types
from api import gitlab
from utilities import validate, types
from logging import info

gitlab = gitlab.GitLab(types.Arguments().url)


def get_all(project_id, issue_id, issue_web_url):
    comments = []
    detail = gitlab.get_issue_comments(project_id, issue_id)
    if validate.api_result(detail):
        for item in detail:
            legit_comments = 0
            for note in item['notes']:
                if note['system']:  # ignore system notes:  https://docs.gitlab.com/ee/api/discussions.html
                    continue
                comments.append(types.Comment('issue', issue_web_url, note['body']))
                legit_comments += 1
        if legit_comments > 0:
            info("[*] Found %s comments for issue %s", legit_comments, issue_web_url)
    return comments


def sniff_secrets(comment):
    monitor = types.SecretsMonitor()
    return monitor.sniff_secrets({comment.parent_url: comment.comment_body})
