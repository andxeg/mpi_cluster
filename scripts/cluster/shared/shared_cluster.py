import os
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


class Colors:
    DEFAULT = "yellow"
    SUCCESS = "green"
    ERROR   = "red"

class Node(object):
    def __init__(self, type, config):
        self._type          = type
        self._name         = config["name"]
        self._host         = config["host"]
        self._user         = config["user"]
        self._password     = config["password"]
        self._work_dir     = config["path"]
        self._ext_iface    = config["ext-iface"]

        self._connection = Connection(user = self._user,
                                      host = self._host,
                                      connect_kwargs = {
                                        'allow_agent': False,
                                        'look_for_keys': False,
                                        'password': self._password
                                      },
                                      connect_timeout=5)

    def __str__(self):
        return "[%s] name %20s; %30s; %10s" % (self._type,
                                                self._name,
                                                self._user + '@' + self._host,
                                                self._password)
    @property
    def host(self):
        return self._host

    def log_prefix(self):
        return "[%10s| %20s| %30s]" % (self._type, 
                                       self._name,
                                       self._user + '@' + self._host)

class Server(Node):
    def __init__(self, name, config, vms_start_script, vm_conf_script, cl_conf_script, cl_del_script, vm_params, master=False):
        super(Server, self).__init__("SERVER", config)
        self._cluster_name = name
        self._resources    = config["resources"]
        self._timeout      = int(config.get("timeout", 10)) # timeout in seconds for start one VM

        self._vms_start_script = vms_start_script
        self._vm_conf_script   = vm_conf_script
        self._cl_conf_script   = cl_conf_script
        self._cl_del_script    = cl_del_script
        self._vm_params        = vm_params

        if "vm_num" not in config:
            # calculate number of virtual machine
            # Should I give some resources to linux bridges?
            self._vm_number = min(int(math.log(float(self._resources["cpu"]) / self._vm_params["cpu"], 2)),
                                  int(math.log(float(self._resources["ram"]) / self._vm_params["ram"], 2)))
        else:
            self._vm_number = int(config["vm_num"])

        self._master = False

    def __str__(self):
        return "%s; %15s; %5d" % (super(Server, self).__str__(),
                                  "with master" if self._master else "without master",
                                  self._vm_number)

    def get_vm_number(self):
        return self._vm_number

    def get_slaves_number(self):
        return (self._vm_number - 1) if self._master else self._vm_number

    def set_master_role(self, is_master):
        self._master = is_master

    def start_vms(self, vm_start, vxlan_start, suffix, ip_start, bridge_addr):
        # if master == True => create local cluster with master else without master
        ## mc2e -> ./start_vms.sh yes 3 1 40 '-first' 1 1024 1 '/home/arccn/images' 'br-ext' 172.30.11.100 192.168.131.36 'node_setup.sh' 30

        # Transfer vms_start and vm_conf scripts to server
        self._connection.put(self._vms_start_script,
                             os.path.join(self._work_dir, "cluster", self._vms_start_script.split('/')[-1]))

        self._connection.put(self._vm_conf_script,
                             os.path.join(self._work_dir, "cluster", self._vm_conf_script.split('/')[-1]))

        self._connection.run("cd %s && bash ./%s '%s' %d %d %d '%s' %d %d %d '%s' '%s' '%s' '%s' '%s' %d" %
                             (os.path.join(self._work_dir, "cluster"),
                              self._vms_start_script.split('/')[-1],
                              "yes" if self._master else "no",
                              self.get_slaves_number(),
                              vm_start,
                              vxlan_start,
                              suffix,
                              ip_start,
                              self._vm_params["ram"],
                              self._vm_params["cpu"],
                              os.path.join(self._work_dir, "images"),
                              self._ext_iface,
                              self._host,
                              bridge_addr,
                              self._vm_conf_script.split('/')[-1],
                              self._vm_number * self._timeout))

        LOG.debug("%s %s" % (colored(self.log_prefix(), Colors.DEFAULT), colored("VMs were started", Colors.SUCCESS)))

    def configure_vms(self, vm_start, suffix, cluster_ip_addresses):
        ## mc2e -> ./configure_vms.sh yes 3 1 '-first' 'node_setup.sh' '10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4'
        
        # Transfer cluster configure script to server
        self._connection.put(self._cl_conf_script,
                             os.path.join(self._work_dir, "cluster", self._cl_conf_script.split('/')[-1]))

        self._connection.run("cd %s && bash ./%s '%s' %d %d '%s' '%s' '%s'" % 
                             (os.path.join(self._work_dir, "cluster"),
                              self._cl_conf_script.split('/')[-1],
                              "yes" if self._master else "no",
                              self.get_slaves_number(),
                              vm_start,
                              suffix,
                              self._vm_conf_script.split('/')[-1],
                              cluster_ip_addresses))


        LOG.debug("%s %s" % (colored(self.log_prefix(), Colors.DEFAULT), colored("VMs were configured", Colors.SUCCESS)))

    def delete(self, vm_start, vxlan_start, suffix):
        # sudo ./clear.sh yes 3 1 40 '-first'
        # sudo ./clear.sh no  4 4 44 '-first'
        
        # Transfer script for cluster removing to server
        self._connection.put(self._cl_del_script,
                             os.path.join(self._work_dir, "cluster", self._cl_del_script.split('/')[-1]))

        with self._connection.cd(os.path.join(self._work_dir, "cluster")):
            self._connection.run("sudo bash ./%s '%s' %d %d %d '%s'" %
                                  (self._cl_del_script.split('/')[-1],
                                  "yes" if self._master else "no",
                                  self.get_slaves_number(),
                                  vm_start,
                                  vxlan_start,
                                  suffix))

        LOG.debug("%s %s" % (colored(self.log_prefix(), Colors.DEFAULT), colored("VMs were deleted", Colors.SUCCESS)))
class Bridge(Node):
    def __init__(self, config, create_script, delete_script):
        super(Bridge, self).__init__("BRIDGE", config)
        self._create_script = create_script
        self._delete_script = delete_script

    def create(self):
        # bridge up   -> ./linux_bridge_up.sh  0 0 br-cluster '' '' ''

        # Transfer bridge script to server
        self._connection.put(self._create_script,
                             os.path.join(self._work_dir, self._create_script.split('/')[-1]))

        self._connection.run("cd %s && bash ./%s 0 0 br-cluster '' '' ''" % 
                            (self._work_dir, self._create_script.split('/')[-1]))

        LOG.debug("%s %s" % (colored(self.log_prefix(), Colors.DEFAULT), colored("Bridge were created", Colors.SUCCESS)))

    def delete(self, vxlan_start, amount):
        # bridge down -> ./linux_bridge_down.sh <vxlan_start> <amount> br-cluster

        # Transfer bridge script to server
        self._connection.put(self._delete_script,
                             os.path.join(self._work_dir, self._delete_script.split('/')[-1]))

        self._connection.run("cd %s && bash ./%s %d %d br-cluster" % 
                            (self._work_dir, self._delete_script.split('/')[-1], vxlan_start, amount))

        LOG.debug("%s %s" % (colored(self.log_prefix(), Colors.DEFAULT), colored("Bridge and vxlan interfaces were deleted", Colors.SUCCESS)))


    def connect(self, vxlan_start, vxlan_num, ip_addr):
        # ./linux_bridge_up.sh 40 4 br-cluster br-ext 192.168.131.36 172.30.11.100

        self._connection.run("cd %s && bash ./%s %d %d br-cluster %s %s %s" % 
                            (self._work_dir,
                             self._create_script.split('/')[-1],
                             vxlan_start,
                             vxlan_num,
                             self._ext_iface,
                             self.host,
                             ip_addr))

        LOG.debug("%s %s" % (colored(self.log_prefix(), Colors.DEFAULT), colored("%s was connected to bridge" % ip_addr, Colors.SUCCESS)))

class Cluster:
    def __init__(self, name, config, vms_start_script=None, cl_conf_script=None, vm_conf_script=None, br_script=None,
                 cl_del_script=None, br_del_script=None, vm_params=None):
        
        self._ip_start    = 1
        self._vxlan_start = 40

        self._name = name

        self._bridge = Bridge(config["bridge"], br_script, br_del_script)

        self._servers = [
            Server(name, server_config, vms_start_script, vm_conf_script, cl_conf_script, cl_del_script, vm_params)
            for server_config in config["servers"]
        ]

        if not len(self._servers):
            raise Exception("There are not any servers in cluster")

        # Set master role to the first server
        self._servers[0].set_master_role(True)

    def __str__(self):
        result = "\n"
        for server in self._servers:
            result += str(server) + '\n'

        result += str(self._bridge) + '\n'

        return result

    def log_prefix(self):
        return "[%10s| %20s]" % ("CLUSTER", self._name)

    def create(self):
        """
            Shared cluster creating steps:
            - calculate total number of vms
            - create bridge with appropriate number of interfaces
            - start all vms (launch start_vms.sh on each server)
                - create bridges for each virtual machines
                - set up addr to each vm in cluster
                - copy node_setup.sh to each vm in cluster
            - configure all vms in cluster
                - configure ssh without password from master to each slaves
                - configure NFS
        """

        LOG.debug("%s %s" % (colored(self.log_prefix(), Colors.DEFAULT), colored("Cluster creation was started", Colors.SUCCESS)))

        self._bridge.create()

        # The following steps should be done sequentially
        # STEP 1: create bridge with necessary interfaces
        vxlan_start = self._vxlan_start
        for server in self._servers:
            self._bridge.connect(vxlan_start,
                                 server.get_vm_number(),
                                 server.host)

            vxlan_start += server.get_vm_number()

        # STEP 2: start virtual machine in each server
        vm_start    = 1
        vxlan_start = self._vxlan_start
        ip_start    = self._ip_start
        for server in self._servers:
            server.start_vms(vm_start, vxlan_start, '-' + self._name, ip_start, self._bridge.host)
            vm_start += server.get_slaves_number()
            vxlan_start += server.get_vm_number()
            ip_start += server.get_vm_number()

        # STEP 3: configure virtual machines in whole cluster
        # Tiny hardcode - cluster's VM has IP addresses from 10.0.0.*/24 subnet
        total_vm_num = vxlan_start - self._vxlan_start
        cluster_ip_addresses = ','.join(["10.0.0." + str(i) for i in range(1, total_vm_num+1)])
        vm_start = 1
        for server in self._servers:
            server.configure_vms(vm_start, '-' + self._name, cluster_ip_addresses)
            vm_start += server.get_slaves_number()

        LOG.debug("%s %s" % (colored(self.log_prefix(), Colors.DEFAULT), colored("Cluster was created", Colors.SUCCESS)))

    def delete(self):
        LOG.debug("%s %s" % (colored(self.log_prefix(), Colors.DEFAULT), colored("Cluster removing was started", Colors.SUCCESS)))

        # STEP 1: Delete all virtual machines on each server
        vm_start    = 1
        vxlan_start = self._vxlan_start
        ip_start    = self._ip_start
        for server in self._servers:
            server.delete(vm_start, vxlan_start, '-' + self._name)
            vm_start += server.get_slaves_number()
            vxlan_start += server.get_vm_number()

        # STEP 2: Delete vxlan interfaces and bridge
        total_vm_num = vxlan_start - self._vxlan_start
        self._bridge.delete(self._vxlan_start, total_vm_num+1)

        LOG.debug("%s %s" % (colored(self.log_prefix(), Colors.DEFAULT), colored("Cluster was deleted", Colors.SUCCESS)))
        

def create_cluster(args):
    name             = args["name"]
    filename         = args["config"]
    vms_start_script = args["vms_start_script"]
    cl_conf_script   = args["cluster_conf_script"]
    vm_conf_script   = args["vm_conf_script"]
    br_script        = args["bridge_conf_script"]
    vm_cpu           = args["vm_cpu"]
    vm_ram           = args["vm_ram"]

    # LOG.debug("config: %s, cpu per VM: %d, ram per VM: %d" % (config_filename, vm_cpu, vm_ram))

    with open(filename, "r") as f:
        config = json.load(f)
    LOG.debug(json.dumps(config, sort_keys=True, indent=4))

    try:
        cluster = Cluster(name,
                          config,
                          vms_start_script=vms_start_script,
                          cl_conf_script=cl_conf_script,
                          vm_conf_script=vm_conf_script,
                          br_script=br_script,
                          vm_params={"cpu": vm_cpu, "ram": vm_ram})

        LOG.debug(cluster)

        cluster.create()
    except Exception as e:
        LOG.error(colored("Cannot create cluster: %s" % e), Colors.ERROR)

def delete_cluster(args):
    name             = args["name"]
    filename         = args["config"]
    cl_del_script    = args["cluster_delete_script"]
    br_del_script    = args["bridge_delete_script"]

    with open(filename, "r") as f:
        config = json.load(f)
    LOG.debug(json.dumps(config, sort_keys=True, indent=4))

    try:
        cluster = Cluster(name,
                          config,
                          cl_del_script=cl_del_script,
                          br_del_script=br_del_script)

        LOG.debug(cluster)

        cluster.delete()
    except Exception as e:
        LOG.error(colored("Cannot delete cluster: %s" % e), Colors.ERROR)


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

    argv = sys.argv[1:]

    examples = [
                "Example: python %s create"
                            " -na  first"
                            " -co  test_config.json"
                            " -vss start_vms.sh"
                            " -ccs configure_vms.sh"
                            " -vcs ../../vm_configure/node_setup.sh"
                            " -bcs ../remote/linux_bridge_up.sh"
                            " -cpu 1"
                            " -ram 1024 2>&1 | tee output.file" % sys.argv[0],
                "Example: python %s delete"
                            " -na  first"
                            " -co  test_config.json"
                            " -cds ../remote/clear.sh"
                            " -bds ../remote/linux_bridge_down.sh 2>&1 | tee output.file" % sys.argv[0]
    ]

    ap = argparse.ArgumentParser(description="Create MPI cluster with several servers.\n" + '\n'.join(examples),
                                 formatter_class=RawTextHelpFormatter)
    
    subparsers = ap.add_subparsers(title="commands", dest="command", help='sub-commands')

    ## CREATE ARGUMENTS
    parser_create = subparsers.add_parser('create', help='create MPI cluster')

    parser_create.add_argument('-na',  '--name', required=True, type=str, help="[STRING] cluster name")
    parser_create.add_argument('-co',  '--config', required=True, type=str, help="[PATH] config file with servers description, see config.template")
    parser_create.add_argument('-vss', '--vms_start_script', required=True, type=str, help="[PATH] script for VMs creation in single server")
    parser_create.add_argument('-ccs', '--cluster_conf_script', required=True, type=str, help="[PATH] script for configure VMs in whole cluster")
    parser_create.add_argument('-vcs', '--vm_conf_script', required=True, type=str, help="[PATH] script for configure one VM in cluster")
    parser_create.add_argument('-bcs', '--bridge_conf_script', required=True, type=str, help="[PATH] script for bridge configure")
    parser_create.add_argument('-cpu', '--vm_cpu', required=True, type=int, help="[INT] cpu per virtual machine")
    parser_create.add_argument('-ram', '--vm_ram', required=True, type=int, help="[INT] ram per virtual machine")

    ## DELETE ARGUMENTS
    parser_delete = subparsers.add_parser('delete', help='delete MPI cluster')

    parser_delete.add_argument('-na',  '--name', required=True, type=str, help="[STRING] cluster name")
    parser_delete.add_argument('-co',  '--config', required=True, type=str, help="[PATH] config file with servers description, see config.template")
    parser_delete.add_argument('-cds', '--cluster_delete_script', required=True, type=str, help="[PATH] script to delete cluster`")
    parser_delete.add_argument('-bds', '--bridge_delete_script', required=True, type=str, help="[PATH] script to delete bridge")

    ## PARSE ARGUMENTS
    args = vars(ap.parse_args(argv))
    LOG.debug(args)

    if args["command"] == 'create':
        create_cluster(args)
    elif args["command"] == 'delete':
        delete_cluster(args)

    LOG.debug(colored("Well done!!!", "green"))


# Manual cluster creation with 4 VMs on one server and 4 VMs on another
## COPY to server scripts:
## '../../vm_configure/node_setup.sh'
## './start_vms.sh'
## './configure_vms.sh'

## BRIDGE
# bridge -> ./linux_bridge_up.sh  0 0 br-cluster '' '' ''
# bridge -> ./linux_bridge_up.sh 40 4 br-cluster eth0 192.168.131.36 172.30.11.100
# bridge -> ./linux_bridge_up.sh 44 4 br-cluster eth0 192.168.131.36 192.168.131.124

## START VMS LOCAL
# mc2e -> ./start_vms.sh yes 3 1 40 '-first' 1 1024 1 '/home/arccn/mpi/images'  'enp9s0f0'  172.30.11.100 192.168.131.36 'node_setup.sh' 30
# s247 -> ./start_vms.sh no  4 4 44 '-first' 5 1024 1 '/home/arccn/MC2E/images' 'enp16s0f0' 192.168.131.124 192.168.131.36 'node_setup.sh' 30

## CONFIGURE VMS GLOBAL (SSH WITHOUT PASSWORD, NFS)
# mc2e -> ./configure_vms.sh yes 3 1 '-first' 'node_setup.sh' '10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6,10.0.0.7,10.0.0.8'
# s247 -> ./configure_vms.sh no  4 4 '-first' 'node_setup.sh' '10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6,10.0.0.7,10.0.0.8'

## Delete cluster
# bridge -> ./linux_bridge_down.sh 40 8 br-cluster
# mc2e   -> sudo ./clear.sh yes 3 1 40 '-first'
# s247   -> sudo ./clear.sh no  4 4 44 '-first'

## Test script
# python shared_cluster.py create -na  first -co  test_config.json -vss start_vms.sh -ccs configure_vms.sh -vcs ../../vm_configure/node_setup.sh -bcs ../remote/linux_bridge_up.sh -cpu 1 -ram 1024
# python shared_cluster.py delete -na  first -co  test_config.json -cds ../remote/clear.sh -bds ../remote/linux_bridge_down.sh
