import sys
import math
import json
import logging
import argparse
from argparse import RawTextHelpFormatter
import collections
from copy import deepcopy
from fabric2 import Connection
from logging.config import dictConfig

from tqdm import tqdm
from termcolor import colored


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
    def __init__(self, name, config, cl_script, vm_script, vm_params):
        self.cluster_name = name
        self.server_name  = config["name"]
        self.address      = config["address"]
        self.user         = config["user"]
        self.password     = config["password"]
        self.resources    = config["resources"]
        self.path         = config["path"]
        self.iface        = config["ext-iface"]

        self.cluster_script = cl_script
        self.vm_script = vm_script
        self.vm_params = vm_params

        # TODO
        # calculate number of virtual machine
        # I also should give some resources to linux bridges
        self.vm_number = min(int(math.log(float(self.resources["cpu"]) / self.vm_params["cpu"], 2))
                             int(math.log(float(self.resources["ram"]) / self.vm_params["ram"], 2)))

    def __str__(self):
        return "[SERVER] name %20s; %10s@%20s : %10s" % (self.name, self.user, self.address, self.password)

    def create(self):
        pass

class Bridge:
    def __init__(self, config, script):
        self.name = config["name"]
        self.address = config["address"]
        self.user = config["user"]
        self.password = config["password"]

    def __str__(self):
        return "[BRIDGE] name %20s; %10s@%20s : %10s" % (self.name, self.user, self.address, self.password)

    def create(self):
        pass

class Cluster:

    def __init__(self, name, config, cl_script, vm_script, br_script, vm_params):
        self.name = name

        self.bridge = Bridge(config["bridge"], br_script)

        self.servers = [
            Server(name, server_config, cl_script, vm_script, vm_params, bridge)
            for server_config in config["servers"]
        ]

    def __str__(self):
        result = "\n"
        for server in self.servers:
            result += str(server) + '\n'

        result += str(self.bridge) + '\n'

        return result

    def create(self):
        """
            Shared cluster creating steps:
            - calculate total number of vms
            - create bridge with appropriate number of interfaces
            - start all vms (launch start_vms.sh on each server)
                - create bridges for each virtual machines
                - set up addr to each vm in cluster
                - copy node_setup.sh to each vm in cluster
                - 
            - 
        """
        


"""
    Create MPI cluster with several servers.
    One server contains K virtual machines, where 
    K is min(n, m):
        n: server_CPUs = (2 ** n) * vm_cpu
        m: server_RAM  = (2 ** m) * vm_ram

    Hard drive is ignored.

    This script launch on each server cluster script, which create VM on local server.
    Cluster script use another script for VM configure.
    Bridge script is used for configure remote bridge, through which traffic between VMs will be passed.
"""
if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Create MPI cluster with several servers.\n"
        "Example: python %s -n 'first'\
                            -cfg config.json \
                            -cs start_vms.sh \
                            -cc configure_vms.sh \
                            -vs node_setup.sh \
                            -bs linux_bridge_up.sh \
                            -cpu 1 \
                            -ram 1024" % sys.argv[0],
        formatter_class=RawTextHelpFormatter)

    ap.add_argument('-n', '--name', required=True, type=str, help="cluster name")
    ap.add_argument('-cfg', '--config', required=True, type=str, help="config file with servers description, see config.template")
    ap.add_argument('-cs', '--cluster_start_script', required=True, type=str, help="script for VMs creation in single server")
    ap.add_argument('-cc', '--cluster_conf_script', required=True, type=str, help="script for configure VMs in whole cluster")
    ap.add_argument('-vs', '--vm_conf_script', required=True, type=str, help="script for VM configure in cluster")
    ap.add_argument('-bs', '--bridge_conf_script', required=True, type=str, help="script for bridge configure")
    ap.add_argument('-cpu', '--vm_cpu', required=True, type=int, help="cpu per virtual machine")
    ap.add_argument('-ram', '--vm_ram', required=True, type=int, help="ram per virtual machine")
    args = vars(ap.parse_args())

    name            = args["name"]
    filename        = args["config"]
    cl_start_script = args["cluster_start_script"]
    cl_conf_script  = args["cluster_conf_script"]
    vm_script       = args["vm_conf_script"]
    br_script       = args["bridge_conf_script"]
    vm_cpu          = args["vm_cpu"]
    vm_ram          = args["vm_ram"]

    # LOG.debug("config: %s, cpu per VM: %d, ram per VM: %d" % (config_filename, vm_cpu, vm_ram))

    with open(filename, "r") as f:
        config = json.load(f)
    LOG.debug(json.dumps(config, sort_keys=True, indent=4))

    cluster = Cluster(name, config, cl_start_script, cl_conf_script, vm_script, br_script, {"cpu": vm_cpu, "ram": vm_ram})
    LOG.debug(cluster)

    LOG.debug("Well done!!!")



## bridge -> ./linux_bridge_up.sh 40 4 br-cluster br-ext 192.168.131.36 172.30.11.100
## bridge -> ./linux_bridge_up.sh 44 4 br-cluster br-ext 192.168.131.36 192.168.131.124

## mc2e -> ./start_vms.sh 3 40 '-first' 1 '/home/arccn/images' 'br-ext' 172.30.11.100 192.168.131.36
## s247 -> ./start_vms.sh 3 44 '-first' 5 '/home/arccn/MC2E/images' 'enp16s0f0' 192.168.131.124 192.168.131.36
