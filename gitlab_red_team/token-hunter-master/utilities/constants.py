class Environment:
    @staticmethod
    def gitlab_api_token():
        return "GITLAB_API_TOKEN"


class Urls:
    @staticmethod
    def gitlab_com_base_url():
        return "https://gitlab.com"


class Requests:
    @staticmethod
    def retry_max_tries():
        return 2

    @staticmethod
    def retry_backoff():
        return 4

    @staticmethod
    def retry_delay():
        return 4


class Banner:
    @staticmethod
    def render():
        print("")
        print("   .---.  .----. .-. .-..----..-. .-..-. .-..-. .-..-. .-. .---. .----..----. ")
        print("  {_   _}/  {}  \| |/ / | {_  |  `| || {_} || { } ||  `| |{_   _}| {_  | {}  }")
        print("    | |  \      /| |\ \ | {__ | |\  || { } || {_} || |\  |  | |  | {__ | .-. |")
        print("    `-'   `----' `-' `-'`----'`-' `-'`-' `-'`-----'`-' `-'  `-'  `----'`-' `-'")
        print("")
        print("  By GitLab Red Team (https://gitlab.com/gitlab-com/gl-security/gl-redteam)")
        print("")
