#!/usr/bin/env python3

from logging import info
from utilities import time, validate, log
from gitlab import analyzer as gitlab_analyzer


def main():
    try:
        log.configure()
        time.log_time_stamp_start()
        validate.environment()
        validate.gitlab_api_keys()
        gitlab_analyzer.analyze()
    except KeyboardInterrupt:
        info("[!] Keyboard Interrupt, abandon ship!")
    finally:
        time.log_time_stamp_end()


if __name__ == '__main__':
    main()
