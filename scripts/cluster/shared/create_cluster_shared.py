import sys
import json
import logging
import argparse
from argparse import RawTextHelpFormatter
import collections
from copy import deepcopy
from fabric2 import Connection
from logging.config import dictConfig


logging_config = dict(
    version = 1,
    formatters = {
        'f': {'format':
              '[%(asctime)s %(filename)s:%(lineno)s - %(funcName)20s() %(levelname)-8s] %(message)s'}
        },
    handlers = {
        'h': {'class': 'logging.StreamHandler',
              'formatter': 'f',
              'level': logging.DEBUG}
        },
    root = {
        'handlers': ['h'],
        'level': logging.DEBUG,
        },
)

dictConfig(logging_config)

LOG = logging.getLogger(__name__)


class Server:
    def __init__(self, config):
        self.name = config["name"]
        self.address = config["address"]
        self.user = config["user"]
        self.password = config["password"]

    def __str__(self):
        return "[SERVER] name %20s; %10s@%20s : %10s" % (self.name, self.user, self.address, self.password)

class Bridge:
    def __init__(self, config):
        self.name = config["name"]
        self.address = config["address"]
        self.user = config["user"]
        self.password = config["password"]

    def __str__(self):
        return "[BRIDGE] name %20s; %10s@%20s : %10s" % (self.name, self.user, self.address, self.password)

class Cluster:
    def __init__(self, config):
        self.servers = [Server(server_config) for server_config in config["servers"]]
        self.bridge = Bridge(config["bridge"])

    def __str__(self):
        result = "\n"
        for server in self.servers:
            result += str(server) + '\n'

        result += str(self.bridge) + '\n'

        return result


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Create MPI cluster with several servers.\n"
        "Example: python %s -cfg config.json -cpu 1 -ram 1024" % sys.argv[0],
        formatter_class=RawTextHelpFormatter)

    ap.add_argument('-cfg', '--config', required=True, type=str, help="config file with servers description, see config.template")
    ap.add_argument('-cpu', '--vm_cpu', required=True, type=int, help="cpu per virtual machine")
    ap.add_argument('-ram', '--vm_ram', required=True, type=int, help="ram per virtual machine")
    args = vars(ap.parse_args())

    config_filename = args["config"]
    vm_cpu          = args["vm_cpu"]
    vm_ram          = args["vm_ram"]

    # LOG.debug("config: %s, cpu per VM: %d, ram per VM: %d" % (config_filename, vm_cpu, vm_ram))

    with open(config_filename, "r") as f:
        config = json.load(f)
    LOG.debug(json.dumps(config, sort_keys=True, indent=4))

    cluster = Cluster(config)
    LOG.debug(cluster)

    LOG.debug("Well done!!!")
