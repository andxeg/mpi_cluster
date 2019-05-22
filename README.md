# NOTES
All benchmarks were run on:

VM1 (master)
- 172.30.7.172 nfv:nfv
- mpiuser:mpiuser for MPI
- `/home/mpiuser/cloud/benchmarks`

VM2 (slave1)
-  172.30.7.194 nfv:nvf
- mpiuser:mpiuser for MPI
- `/home/mpiuser/cloud/benchmarks`

Check all benchmarks from master.
`/home/mpiuser/cloud` is a shared folder.

# Таблица с бенчмарками

| Network       | Computation             | Combined   | Framework   |
| ------------- | ----------------------- | ---------- | ----------- |
| IMB(1)        | HPL(2)                  | IMB        |   SAMRAI    |
| MSU_MPI_test  | NAS parallel benchmark  | IOR(4)     |  HyperCLaw  |
| comm          | IMB*                    | MPIMEMU    |             |
| netperf       | C_LINPACK (without MPI) | MPIBLIB    |             |
| nettest       | CPU2 (Fortran)          |            |             |
| comm          | Dhrystone               |            |             |
| ttcp          | Flops                   |            |             |
| OMB(3)        | HeapSort                |            |             |
|               | Matrix_Multiply         |            |             |
|               | NAS_Kernels (Fortran)   |            |             |
|               | STREAM                  |            |             |
|               | Jacobi2D                |            |             |
|               | NAMD                    |            |             |
|               | ChaNGa                  |            |             |
|               | Sweep3D                 |            |             |
|               | Nqueens                 |            |             |
|               | ZIATEST                 |            |             |
|               | HANOI                   |            |             |
|               | SIM                     |            |             |
(1) IMB - Intel MPI Benchmark

(2) HPL - high performance LINPACK

(3) OMB - Ohio Micro Benchmark suite

(4) IOR - InterleavedOrRandom

# NAS Parallel Benchmarks (NPB)
## Main links
https://www.nas.nasa.gov/publications/npb.html

(source code) https://www.nas.nasa.gov/assets/npb/NPB3.4.tar.gz

## Folder
`/home/mpiuser/cloud/benchmarks/NPB/NPB3.4/NPB3.4-MPI`

## Description
BT -- 3D Навье-Стокс, метод переменных направлений

CG -- Оценка наибольшего собственного значения симметричной разреженной матрицы

EP -- Генерация пар случайных чисел Гаусса

FT -- Быстрое преобразование Фурье, 3D спектральный метод

IS -- Параллельная сортировка

LU -- 3D Навье-Стокс, метод верхней релаксации

MG -- 3D уравнение Пуассона, метод Multigrid

SP -- 3D Навье-Стокс, Beam-Warming approximate factorization

????? Что дает запуск бенчмарка ?????

Измеряет количество операций с плавующей запятой в

секунду, которые может выполнять компьютер/кластер

## Extra
- Скачиваем последнюю версию NPB
- Копируем конфиг `./config/NAS.samples/make.def.gcc_mpich` в `./config/make.def`
- Переходим в корень и запускаем компиляцию, как написано в README.install, например:
    ```bash
    $ make bt CLASS=S
    ```
- Запускаем программу (2 варианта)
    ``` bash
    $ mpirun -np <number of processes> -hosts <list of hosts separated by comma> <binary file>
    $ mpirun -np <number of processes> -hostfile <file with ip addresses of cluster nodes> <binary file>
    ```
- Можно сразу несколько бенчмарков скомпилировать, для этого нужно добавить в папку `./config` файл `suite.def` и выполнить в корне команду:
```bash
$ make suite
```
Проверил класс S для всех бенчмарков (bt.S.x, cg.S.x, ep.S.x, ft.S.x, is.S.x, ft.S.x, is.S.x, lu.S.x, mg.S.x, sp.S.x).
Пример запуска:
```bash
$ mpirun -np 16 --hosts master,slave1 ./bin/bt.S.x
```

Проверил все варианты классов для bt, ft, lu, sp. Bt and sp require a square number of processes other benchmarks requires a power-of-two number of processes. C require 3GB disk space. D required 135 GB disk space.

bt A, B, C, D(not enough disk space), S

ft A, B, C(error), D(error), S

lu A, B, C, D(error), S

sp A, B, C, D(error), S

Класс определяет размер задачи.
Размеры задач и параметры можно посмотреть тут -> https://www.nas.nasa.gov/publications/npb_problem_sizes.html

Пример результата выполнения бенчмарка:

BT Benchmark Completed.

Class = S Size = 12x 12x 12

Iterations = 60

(!)Time in seconds = 8.22

(!)Total processes = 16

(!)Active procs = 16

(!)Mop/s total = 27.76 (mflops)

(!)Mop/s/process = 1.74

Operation type = floating point

Verification = SUCCESSFUL

Version = 3.4

Compile date = 14 May 2019

Example of public results -> http://pm2.gforge.inria.fr/newmadeleine/NAS/tcp.html

# High Performance Linpack (HPL)
## Main links
https://www.top500.org/project/linpack/

http://www.netlib.org/benchmark/hpl/

(source code) http://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz

## Folder
`/home/mpiuser/cloud/benchmarks/HIGH_PERF_LINPACK/hpl-2.3`

## Description
????? Что дает запуск бенчмарка ?????

Измеряет количество операций с плавующей запятой в

секунду, которые может выполнять компьютер/кластер

## Extra
### BLAS installation
Для бенчмарка понадобится библиотека BLAS.
BLAS -> http://www.netlib.org/blas/
Optimized BLAS -> http://www.netlib.org/blas/faq.html

Можно установить ее вручную либо установить Atlas.
See -> http://www.netlib.org/atlas/
Atlas Source -> http://www.netlib.org/atlas/atlas3.6.0.tgz
```bash
$ make (ask questions and define you architecture)
$ make install arch=<arch>
$ make sanity_test arch=<arch>
```

### Intel compilers installation
Можно использовать mpich и gcc, а можно соответствующие компиляторы от Intel.
Чтобы установить компилятор Intel, нужно скачать parallel_studio_xe_2019,
сделать custom installation, установив только нужные компоненты.

Я скачал эту версию:
http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15268/parallel_studio_xe_2019_update3_cluster_edition_online.tgz
(install.sh -> далее нужно отказаться от установки ненужных компонент, так как полная установка будет занимать 10.7Gb)
(все пакеты можно отбросить, оставить только c++ compiler, этот способ работает)

Либо можно скачать все сразу (4.5Gb):
http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15268/parallel_studio_xe_2019_update3_cluster_edition.tgz

### IntelMPI and IntelMKL (Math Kernel Library) installation
Registration is needed in Intel site for download.
- IntelMPI -> http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15260/l_mpi_2019.3.199.tgz
IntelMPI installation guide -> http://registrationcenter-download.intel.com/akdlm/irc_nas/1718/INSTALL.html?lang=en&fileExt=.html
(Briefly run install.sh and follow the instructions).
Default installation to the folder `$HOME/intel`

- IntelMKL -> http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/15275/l_mkl_2019.3.199.tgz
(Briefly run install.sh and follow the instructions)
(Install InteMPI too)
Default installation to the folder `$HOME/intel`

- Then source variables for IntelMPI and IntelMKL
    ```bash
    $ source ~/intel/impi/2019.3.199/intel64/bin/mpivars.sh
    ```
- Setting `I\_MPI\_ROOT` to env variables then `I\_MPI\_ROOT`
This env vars are used in Makefile of High Performance Linpack.
and
    ```bash
    $ source ~/intel/mkl/bin/mklvars.sh intel64
    $ source ~/intel/bin/compilervars.sh intel64
    ```
Add this source to `.bashrc` file in home directory.

### Linpack compilation from source
- Выполняешь скрипт `make_generic` в директории `./setup`, см. корневую директорию бенчмарка.
Скрипт генерирует `Make.UNKNOWN`, переименовываешь его в `Make.generic` и копируешь в корень бенчмарка.
- Устанавливаешь BLAS -> https://www.youtube.com/watch?v=Wp0cHUiOHTQ
For Ubuntu:
    ``` bash
    sudo apt-get install libblas3 libblas-dev libblas-common libblas-doc libblas-test
    ```
Стандартная реализация BLAS неэффективна, но на ВМ другую скорее всего не запустишь.
Если запускать на железе, то есть оптимизированные BLAS библиотеки, см. выше.
- Далее подготавливаем Make файл и компилируем.
Copy hpl-2.3/setup/Make.Linux_Intel64
and change path to IntelMPI, change TOPdir to to
root directory where your download HPL
See example of Makefile preparation here -> https://ulhpc-tutorials.readthedocs.io/en/latest/parallel/mpi/HPL/
When you prepare Makefile type commands:
    ```bash
    $ make arch=generic clean_arch_all
    $ make arch=generic
    ```

- Здесь подробное описание запуска Linpack бенчмарка -> https://parallel.ru/sites/default/files/info/parallel/cluster/appendix3.pdf
HPL.dat file description you can find in ./TUNING file
Find binary file in ./bin/<arch>/
Modify HPL.dat and launch xhpl
N - размеры квадратных матриц
Ps, Qs - варианты разбиения матриц по процессам
(читать по столбцам a х b).

Запуск:
```bash
$ mpirun -np N ./xhpl
```
N должно быть не меньше максимального произведения
соответствующих вариантов пар Ps и Qs.

# Intel Linpack and MPI benchmarks
## Main links
When you install Intel MPI and Intel MKL you can
find benchmarks in installation directory:
Intel Linpack Benchmark, Intel MPI Benchmark.

## Folder
`<intel products installation directory>/mkl/benchmarks/`

`<intel products installation directory>/impi/<version>/benchmarks/imb`

## Description
????? Что дает запуск бенчмарка ?????
* Performance of a cluster system, including node performance, network latency, and throughput
* Efficiency of the MPI implementation used
* Benchmarks output (есть примеры) -> https://software.intel.com/en-us/imb-user-guide-output

## Extra

Нужен intel c/c++ compiler 2016, intel MKL 2018, intel mpi 5.1. (про установку написано выше в бенчмарке HPL)

Как установить см. тут -> https://github.com/nemequ/icc-travis (этот способ у меня не удался, лицензия не подошла)

Нужно установить intel c/c++ compiler, чтобы скомпилировать бенчмарки.

### MKL (`~/intel/mkl/benchmarks/`)
- hpcg (у меня не сработал)
    - only when processor support AVX, AVX2
- linpack
    - runme_xeon64 -> write performance in GFlops
    - xlinpack_xeon64*
- mp_linpack (This is HPL, see above)
    - runme_intel64_dynamic
    - xhpl_intel64_dynamic

### MPI (`~/intel/impi/<version>/benchmarks/imb`)
Intel MPI Benchmark User's Guide -> https://software.intel.com/en-us/imb-user-guide-getting-started
intel c/c++ compiler is needed
- imb (Intel MPI Benchmark)
    this benchmark is installed with Intel MPI, but you
    can download it separately from repository ->
    https://github.com/intel/mpi-benchmarks

    See `ReadMe_IMB.txt` and launch benchmarks

    Memory and disk space requirements -> https://software.intel.com/en-us/imb-user-guide-memory-and-disk-space-requirements

Q - number of process in mpirun command

MPI-1 (https://software.intel.com/en-us/imb-user-guide-mpi-1-benchmarks) (test MPI functions)
    - IMB-MPI1
        - Single Transfer Benchmarks (two active processes) (https://software.intel.com/en-us/imb-user-guide-single-transfer-benchmarks)
        - Parallel Transfer Benchmarks (more than two active processes) (https://software.intel.com/en-us/imb-user-guide-single-transfer-benchmarks)
        - Collective Benchmarks (measuse MPI collective operations) (https://software.intel.com/en-us/imb-user-guide-collective-benchmarks)
    - IMB-P2P

MPI-2 (https://software.intel.com/en-us/imb-user-guide-mpi-2-benchmarks)
    (the same classification as for MPI-1)
    - IMB-EXT (Q=2)
    - IMB-IO (Q=1)

MPI-3 (https://software.intel.com/en-us/imb-user-guide-mpi-3-benchmarks)
    - IMB-NBC
        non-blocking collective ops
    - IMB-RMA
    - IMB-MT
        - multiple thread per rank

Benchmark Methodology -> https://software.intel.com/en-us/imb-user-guide-control-flow

При запуске бенчмарка можно указывать имя бенчмарка и параметры.
By default, all benchmarks of the selected component are run.
Какие параметры бывают см. тут -> https://software.intel.com/en-us/imb-user-guide-command-line-control

Список параметров можно узнать так:
```bash
$ ./IMB-<benchmark> -help
```

# Several CPU benchmarks
## Main Links
https://parallel.ru/computers/benchmarks/perf.html

## Folder
`/home/mpiuser/cloud/benchmarks`

## Description
This benchmarks test CPU performance, MPI is not used.

## Extra
- C_LINPACK (https://parallel.ru/sites/default/files/ftp/benchmarks/clinpack/clinpack.zip)
- CPU2 (Fortran), remove -pfa from makefile and comment LUNS
    in analysis.f (https://parallel.ru/sites/default/files/ftp/benchmarks/cpu2/cpu2.unix.zip)
- Dhrystone (https://parallel.ru/sites/default/files/ftp/benchmarks/dhrystone/dhrystone.zip)
    ```bash
    $ ./dhry11 (input -> 1000000000)
    $ ./dhry21 (input -> 1000000000)
    ```
- Flops (https://parallel.ru/sites/default/files/ftp/benchmarks/flops/flops.zip)
- HeapSort (https://parallel.ru/sites/default/files/ftp/benchmarks/heapsort/heapsort.zip)
- Matrix_Multiply (https://parallel.ru/sites/default/files/ftp/benchmarks/mm/mm.zip)
- NAS_Kernels (Fortran) (https://parallel.ru/sites/default/files/ftp/benchmarks/NAS/nas.zip)
- STREAM (https://github.com/jeffhammond/STREAM)

# Several Network benchmarks
## Main links
https://parallel.ru/computers/benchmarks/net.html

## Folder
`/home/mpiuser/cloud/benchmarks`

## Description
Benchmarks for test network performance in Linux, some with MPI.

## Extra
- MSU_MPI_test (https://parallel.ru/testmpi/) (https://parallel.ru/sites/default/files/ftp/mpi-bench-suite-1.1.zip)
- transfer - тест латентности и скорости пересылок между двумя узлами;
- nettest - тест пропускной способности сети при сложных обменах по различным логическим топологиям;
- mpitest - тест эффективности основных операций MPI;
- nfstest - тест производительности файл-сервера.
- (not checked) comm (https://parallel.ru/sites/default/files/ftp/benchmarks/comm/comm.tgz)
- (not checked) netperf (https://parallel.ru/ftp/benchmarks/netperf) (https://parallel.ru/sites/default/files/ftp/benchmarks/netperf/netperf-2.1pl3.zip)
- (not checked) nettest (https://parallel.ru/sites/default/files/ftp/benchmarks/nettest/nettest.zip)
- (not checked) ttcp (https://parallel.ru/sites/default/files/ftp/benchmarks/ttcp/ttcp.zip)

# SAMRAI (not checked)
## Main links
https://computation.llnl.gov/projects/samrai

## Folder
`/home/mpiuser/cloud/benchmarks/SAMRAI`

## Description
SAMRAI - framework for parallel adaptive multi-physics applications.
It is library helps develop specific application.
Adaptive mesh refinement (AMR) is a methodology for placing fine spatial and temporal mesh resolution near key features where it is needed most

SAMRAI is a popular C++ software framework developed to implement
parallel adaptive multi-physics applications (77)

# HyperCLaw MPI (not checked)
## Main links
https://www.researchgate.net/publication/44790058_A_protocol_reconfiguration_and_optimization_system_for_MPI
https://pdfs.semanticscholar.org/693c/dbffcb117138aa37206f87c2c682233b44fd.pdf

## Description
Adaptive Mesh Refinement framework.
It is analogue to SAMRAI
HyperCLaw is a hybrid C++/Fortran AMR code developed and maintained
by Lawrence Berkeley National Laboratory (78)

# Ohio Micro Benchmark suite (OMB)
## Main links
https://www.nersc.gov/users/computational-systems/cori/nersc-8-procurement/trinity-nersc-8-rfp/nersc-8-trinity-benchmarks/omb-mpi-tests/

## Folder
`/home/mpiuser/cloud/benchmarks/OMB_MPI`

## Description
It includes traditional benchmarks and performance measures such as latency, bandwidth and host overhead

# IOR
## Main links
https://www.nersc.gov/users/computational-systems/cori/nersc-8-procurement/trinity-nersc-8-rfp/nersc-8-trinity-benchmarks/ior/

## Folder
`/home/mpiuser/cloud/benchmarks/IOR`

## Description
IOR is designed to measure parallel file system I/O performance 
at both the POSIX and MPI-IO level. "IOR" stands "InterleavedOrRandom,”
which has very little to do with how the program works currently. 
This parallel program performs writes and reads to/from files under
several sets of conditions and reports the resulting throughput rates.

## Extra
Binary file in `IOR/src/C`

# ZIATEST (not checked)
## Main links
https://www.nersc.gov/users/computational-systems/cori/nersc-8-procurement/trinity-nersc-8-rfp/nersc-8-trinity-benchmarks/ziatest/)

## Folder
`/home/mpiuser/cloud/benchmarks/ZIATEST`

## Description
Thus, the benchmark seeks to measure not just the time required
to spawn processes on remote nodes, but also the time required
by the interconnect to form inter-process connections capable of
communicating.

## Extra
If mpi.h is not found then modify Makefile.

Change set MPICC to value mpicc.

Check with mpich, not with Intel MPI

# MPIMEMU
## Main links
https://www.nersc.gov/users/computational-systems/cori/nersc-8-procurement/trinity-nersc-8-rfp/nersc-8-trinity-benchmarks/mpimemu/

## Folder
`/home/mpiuser/cloud/benchmarks/MPIMEMU`

## Description
The code mpimemu is a simple tool that helps approximate MPI library 
memory usage as a function of scale.

## Extra
Install switch.pms, compile and run:
```bash
$ sudo apt-get install libswitch-perl
$ ./configure
$ make
$ ./util/env-setup-bash
$ ./src/mpimemu-run
```

# Jacobi2D
## Main links 
https://www.mcs.anl.gov/research/projects/mpi/tutorial/mpiexmpl/src/jacobi/C/main.html

## Folder
`/home/mpiuser/cloud/benchmarks/JACOBI2D`

## Description
Jacobi2D - common in scientific simulations, numerical linear algebra, solutions of partial differential equations, and image processing.

## Extra
Change grid sizes and processes count in source code if necessary.


# NAMD (not checked)
## Main links
http://www.ks.uiuc.edu/Research/namd/utilities/

(instruction) https://hpcadvisorycouncil.atlassian.net/wiki/spaces/HPCWORKS/pages/8126556/Getting+started+with+NAMD+Benchmarks

https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=NAMD

(source code) http://www.ks.uiuc.edu/Research/namd/utilities/apoa1.tar.gz

## Description
CHARM++ is required
NAMD - A highly scalable molecular dynamics application
A highly scalable molecular dynamics
application representative of a complex real world
application used ubiquitously on supercomputers.

ApoA1 has been the standard NAMD cross-platform benchmark for years. 

# ChaNGa (not checked)
## Main links
(source code) https://github.com/N-BodyShop/changa

## Description
Charm is required
ChaNGa - A cosmological simulation application which performs 
collisionless N-body interactions.

A cosmological simulation application which performs collisionless 
N-body interactions using Barnes-Hut tree for calculating forces

# Sweep3D (not checked)
## Main links

## Description
Sweep3D - A particle transport code widely used for evaluating HPC architectures.
A particle transport code widely used for evaluating HPC
architectures. Sweep3D exploits parallelism via a wavefront
process.

# NQueens
## Main links
https://rosettacode.org/wiki/N-queens_problem

Serial version
- https://parallel.ru/sites/default/files/ftp/benchmarks/queens/queens.zip

Parallel version
- http://penguin.ewu.edu/~trolfe/MpiQueen/
- https://github.com/feynmanliang/NQueens-Parallel
    ```bash
    $ mpirun -np 4 -hostfile ~/hosts ./bin/nqueens 8 4)
    ```

## Folder
`/home/mpiuser/cloud/benchmarks/NQUEENS`

## Description
NQueens - A backtracking state space search implemented as tree structured computation.
A backtracking state space search implemented as tree structured computation. The goal is

to place N queens on an N ×N chessboard (N = 18
in our runs) so that no two queens attack each other.
Communication happens only for load balancing

# MPIBLIB
## Main links
(article) https://hcl.ucd.ie/files/52050227.pdf

(source code) https://hcl.ucd.ie/project/mpiblib
https://hcl.ucd.ie/system/files/mpiblib-1.2.0.tar.gz

## Folder
`/home/mpiuser/cloud/benchmarks/MPIBLIB/mpiblib-1.2.0`

## Description

## Extra
Check then in your system mpirun and mpiexec is from OpenMPI
and not from Intel MPI
If you has several version of MPI library then modify PATH like this
```bash
$ PATH=/usr/bin/:$PATH; make
```

When launch library then set `LD\_LIBRARY\_PATH` like this
```bash
$ LD_LIBRARY_PATH=/usr/lib/:$LD_LIBRARY_PATH; mpirun -np 2 ./tests/p2p-eager
```
GNU scientific library is required:
```bash
$ sudo apt-get install libgsl-dev
```

Boost graph library is required (https://www.osetc.com/en/how-to-install-boost-on-ubuntu-16-04-18-04-linux.html)
```bash
$ sudo apt install libboost-dev
$ sudo apt install libboost-all-dev
```


# Other benchmarks
- HANOI (https://parallel.ru/sites/default/files/ftp/benchmarks/hanoi/hanoi.zip)
- SIM (https://parallel.ru/sites/default/files/ftp/benchmarks/sim/sim.zip)

-----------------------------------------------------------


# Other links
* http://www.panticz.de/Linpack
* http://www.roylongbottom.org.uk/linpack%20results.htm
* https://pdfs.semanticscholar.org/693c/dbffcb117138aa37206f87c2c682233b44fd.pdf
* NERSC all benchmarks -> https://www.nersc.gov/users/computational-systems/cori/nersc-8-procurement/trinity-nersc-8-rfp/nersc-8-trinity-benchmarks/
* NERSC SMB benchmark -> https://www.nersc.gov/users/computational-systems/cori/nersc-8-procurement/trinity-nersc-8-rfp/nersc-8-trinity-benchmarks/smb/

* http://mvapich.cse.ohio-state.edu:8080/benchmarks/

* https://parallel.ru/sites/default/files/ftp/benchmarks/pmb/PMB-MPI1.pdf

* http://www.roylongbottom.org.uk/linux%20benchmarks.htm

* https://kitty.in.th/index.php/2017/02/13/intel-linpack-benchmark-on-debian-and-ubuntu/

* https://www.programering.com/a/MTO0QDNwATk.html

* https://ubuntuforums.org/showthread.php?t=1004406

* http://www.roylongbottom.org.uk/linpack%20results.htm

* http://www.netlib.org/benchweb/

* https://link.springer.com/article/10.1007/s11227-005-2340-2

* http://etutorials.org/Linux+systems/cluster+computing+with+linux/Part+II+Parallel+Programming/Chapter+9+Advanced+Topics+in+MPI+Programming/9.10+Measuring+MPI+Performance/

* https://cdp.clustermonkey.net/index.php/Cluster_Benchmarking_Packages
