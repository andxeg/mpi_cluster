#!/usr/bin/env python3

import argparse
import os
import re
from tabulate import tabulate
import traceback
import numpy as np
import pandas as pd
import matplotlib
#matplotlib.use('Agg')
import matplotlib.pyplot as plt
from tqdm import tqdm

#plt.rcParams.update({'font.size': 14})
#np.set_printoptions(precision=4)


input_dir = None
output_dir = None
npb_header = [
    'UUID',
    'name',
    'cpu_cores',
    'cpu_total',
    'cpu_steal',
    'net_receivedBytes',
    'net_transmittedBytes',
]
npb_names = ['is', 'ep', 'cg', 'lu', 'ft']#, 'mg', 'sp', 'bt']
npb_sizes = ['A', 'B', 'C', 'D', 'E']
npb_threads = [1, 2, 4, 8, 16]

class PureExperiment:
    def __init__(self, _filename):
        filename = _filename.split('/')[0]
        # <program name>_<size>_<number of vm>.out
        params = filename.split('_')
        self.name = params[0].split('.')[0]
        self.size = params[1]
        self.vms = int(params[2].split('.')[0])

        self.time = None
        # Mean values
        self.cpu = None
        self.network = None

        #print('PureExperiment', self.name, self.size, self.vms)


class SharingExperiment:
    def __init__(self, _filename):
        filename = _filename.split('/')[0]
        # lu.A.x_lu.A.x_4_8_mon_second.out
        params = filename.split('_')

        self.first_name = params[0].split('.')[0]
        self.first_size = params[0].split('.')[1]
        self.first_vms = params[2]

        self.second_name = params[1].split('.')[0]
        self.second_size = params[1].split('.')[1]
        self.second_vms = params[3]


def load_data(file_path, first=True):
    full_data = pd.read_csv(file_path,
                            delimiter='\t', header=None,
                            index_col=False, names=npb_header)
    full_data = full_data.drop(columns='UUID')

    if first:
        data = full_data[full_data['name'] == 'master-first']
    else:
        data = full_data[full_data['name'] == 'master-second']

    #if data.empty

    # Clear data
    data.dropna(inplace=True)

    cpu = data['cpu_total'] / np.max(data['cpu_total'])
    network = data['net_transmittedBytes']# / np.max(data['net_transmittedBytes'])

    return cpu, network


def load_npb_time(file_path):
    with open(file_path) as f:
        data = f.read()
        time = re.findall(r'Time in seconds =\s*(\d+.\d+|\d+)', data)
        if time:
            seconds = float(time[0])
            return seconds
        else:
            return np.nan


def plot_timeline():
    for experiment_file in experiment_files:
        try:
            #experiment = '_'.join(first_experiment_file.split('_')[:-2])
            print('Processing', experiment_file)

            #first_name = experiment_file.split('_')[0].split('.')[0]
            #second_name = experiment_file.split('_')[1].split('.')[0]

            plt.figure(figsize=(18, 6))
            #for name, experiment_file, color, net_color in data_list:
            cpu, network = load_data(input_dir + experiment_file)
            network = network / np.max(network)

            cpu = cpu.rolling(window=15, min_periods=1).mean()
            network = network.rolling(window=15, min_periods=1).mean()

            plt.plot(cpu, color='red', label='CPU usage')
            plt.plot(network, color='blue', linestyle='dashed', label='Network usage')

            plt.xlabel('Time')
            plt.ylabel('Percentage')
            plt.legend()
            plt.tight_layout()
            #plt.show()
            plt.savefig(experiment_dir + 'plot/%s.png' % experiment_file, fmt='png')
            plt.gcf().clear()
        except:
            traceback.print_exc()


def plot_task_curve():
    plt.figure(figsize=(18, 6))
    for experiment_file in experiment_files:
        # Check non-overlapping tasks
        if int(experiment_file.split('_')[2]) + int(experiment_file.split('_')[3]) <= 16:
        #if experiment_file.split('_')[2] == '16':
            print('Processing', experiment_file)
            try:
                cpu, network = load_data(input_dir + experiment_file)
                #color = 'ro' if int(experiment_file.split('_')[2]) == 8 else 'bo'
                color = None
                task_type = experiment_file.split('_')[0].split('.')[0]
                if task_type == 'cg':
                    color = 'ro'
                elif task_type == 'lu':
                    color = 'bo'
                elif task_type == 'is':
                    color = 'go'
                elif task_type == 'ft':
                    color = 'co'

                plt.plot(np.mean(network), np.mean(cpu), color)
            except:
                traceback.print_exc()


    plt.xlabel('Network')
    plt.ylabel('CPU')
    plt.legend()
    plt.tight_layout()
    plt.show()
    #plt.savefig(experiment_dir + 'plot/classification.png', fmt='png')
    plt.gcf().clear()


def load_pure_experiments():
    pure_exps = []
    for filename in tqdm(os.listdir(os.path.join(input_dir, 'pure_NPB/cluster/'))):
        try:
            exp = PureExperiment(filename)

            cluster_file = os.path.join(input_dir, 'pure_NPB/cluster/', filename)
            exp.time = load_npb_time(cluster_file)

            monitor_file = os.path.join(
                input_dir, 'pure_NPB/monitor/',
                filename[:-4] + '_mon.out'
            )
            exp.cpu, exp.network = load_data(monitor_file, first=True)
            #load_data(monitor_file, second=True)

            pure_exps.append(exp)
        except:
            pass

    return pure_exps


def plot_pure_experiments():
    threads = [1, 2, 4, 8, 16]
    labels = ['%d' % t for t in threads]
    pure_exps = load_pure_experiments()

    # Fix task size
    pure_exps = [e for e in pure_exps if e.size == 'B']

    print('Total number:', len(pure_exps))
    plt.figure(figsize=(12, 9))
    for index, task_name in enumerate(npb_names):
        named_exps = [e for e in pure_exps if e.name == task_name]
        print('Name %s:' % task_name, len(named_exps))

        box_data = []
        for t in threads:
            threaded_data = [d for d in named_exps if d.vms == t]
            print('    Thread %d:' % t, len(threaded_data))
            #data = [np.mean(d.cpu) for d in threaded_data]
            thread_box_data = []
            for td in threaded_data:
                data = list(td.cpu)
                print('        Mean:', np.mean(td.cpu), '| Samples:', len(td.cpu))
                thread_box_data.extend(data)
            box_data.append(thread_box_data)

        plt.subplot(2, 3, index+1)
        plt.boxplot(box_data, showfliers=False, vert=True)
        plt.xticks([1, 2, 3, 4, 5], labels)
        plt.xlabel('Thread number')
        plt.ylabel('CPU usage')
        plt.tight_layout()
        plt.title('Task: %s' % task_name)
        #plt.gcf().subplots_adjust(left=adjust_left)
        #plt.savefig(data_dir + '/plot/' + 'packet_error_%d.pdf' % delay, fmt='pdf')

    plt.show()
    plt.gcf().clear()


def print_pure_experiments():
    table_headers = ['Size', 1, 2, 4, 8, 16]
    threads = [1, 2, 4, 8, 16]

    pure_exps = load_pure_experiments()
    for task_name in npb_names:
        print('Task', task_name)
        exps = [e for e in pure_exps if e.name == task_name]
        table_rows = []
        for task_size in npb_sizes:
            sized_exps = [e for e in exps if e.size == task_size]
            row = [task_size]
            if sized_exps:
                for thread_num in threads:
                    threaded_exps = [e for e in sized_exps if e.vms == thread_num]
                    time_list = [float(e.time) for e in threaded_exps]
                    exp = np.mean(time_list) if time_list else np.nan
                    row.append(exp)
            else:
                row += [np.nan] * 5
            table_rows.append(row)
        print(tabulate(headers=table_headers, tabular_data=table_rows))
        print()


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('-i', '--input_dir',
                    required=False, type=str,
                    default=os.path.expanduser('~/experiments/mc2e/'),
                    help='Input directory')
    ap.add_argument('-o', '--output_dir',
                    required=False, type=str,
                    default=os.path.expanduser('~/experiments/mc2e/plot/'),
                    help='Output directory')
    args = vars(ap.parse_args())

    input_dir = args['input_dir']
    output_dir = args['output_dir']

    # TODO: load experiments
