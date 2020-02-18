import datetime

from api import identity
from logging import info
from utilities import types

args = types.Arguments()


def get_current(timezone):
    return datetime.datetime.now(timezone) \
        .strftime("%d/%m/%Y %H:%M:%S")


def log_time_stamp_start():
    if not args.timestamp:
        info("##### token-hunter started at UTC %s from IP %s##### ",
             get_current(datetime.timezone.utc), identity.get_public_ip())


def log_time_stamp_end():
    if not args.timestamp:
        info("##### token-hunter finished at UTC %s ##### ", get_current(datetime.timezone.utc))
