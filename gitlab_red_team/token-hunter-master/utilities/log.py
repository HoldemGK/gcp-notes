import logging
import sys
from utilities import types

args = types.Arguments()


def configure():
    logging.basicConfig(format='%(message)s', level=logging.INFO, stream=sys.stdout)
    logfile = args.logfile
    if logfile:
        logging.getLogger().addHandler(logging.FileHandler(logfile))
