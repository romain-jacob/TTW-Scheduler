# TTW Scheduler

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3530665.svg)][ttw_zenodo]

This repository contains the source code for the TTW Scheduler, presented in the following paper:

> **Time-Triggered Wireless Architecture**  
Romain Jacob, Licong Zhang, Marco Zimmerling, Samarjit Chakraborty, Lothar Thiele   
Accepted to ECRTS 2020  
[arXiv (submitted version)](https://arxiv.org/abs/2002.07491)

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Installation Instructions](#installation-instructions)
- [Getting Started](#getting-started)
- [Comparing Scheduling Strategies](#comparing-scheduling-strategies)
- [Solving your own Problem](#solving-your-own-problem)

<!-- /TOC -->

Time-Triggered Wireless (TTW) is a wireless architecture for multi-mode cyber-physical systems.
TTW consists of two main components: a system-wide real-time scheduler that executes offline and a communication stack called TTnet that runs online on distributed low-power wireless devices (An implementation of TTnet is available in a [dedicated repository](https://github.com/romain-jacob/TTW-Artifacts)).
Based on the application specification (e.g., tasks, messages, modes) and system parameters (e.g., number of nodes, message sizes), the scheduler synthesizes optimized scheduling tables for the entire system. These tables are loaded onto the devices, and at runtime each device follows the table that corresponds to the current mode.
The TTW scheduler statically synthesizes the schedule of all tasks, messages, and communication rounds by solving a MILP.

This repository contains a [Matlab][matlab] implementation of the TTW scheduler, using [Gurobi][gurobi] to solve the MILP formulation.
> Although Matlab and Gurobi are both commercial software (which is not ideal), free academic and/or student licenses are currently available from the software vendors.

## Installation Instructions

This software (should) run on common operating systems (Windows, macOS, Linux) but **requires a 64-bit** version.

+ Get Matlab (R2016 or newer) for example via your academic institution or the [official Matlab website][matlab]. It must be a **64-bit version**.
+ Get the [Gurobi Optimizer](https://www.gurobi.com/downloads/gurobi-software/) from the Gurobi website. Download the latest version corresponding to your OS. You need to create an account using an **institutional email address** (eg, `john.doe@ethz.ch`).
+ Follow the [online quick start guide](https://www.gurobi.com/documentation/quickstart.html) corresponding to your OS to install and setup Gurobi.  
To validate your academic license, you must to be connected to Internet via your academic institution (either physically or via VPN).
+ Setup Gurobi for Matlab; OS-specific instructions are in the quick start guide under `MATLAB Interface/Setting up Gurobi for MATLAB`
+ Optionally, you can enter `savepath` in the Matlab command window to avoid having to redo this last step every time you open Matlab.

> **/!\ ---- Beware ---- /!\**  
While preparing for the release of these software, we noticed differences in the schedules produced by the Gurobi solver, depending on the version.  
If you want to guarantee the reproducibility of your results, do not forget specifying the Matlab and Gurobi solver versions.  
> **/!\ /!\ /!\ /!\ /!\ /!\ /!\**

**Tested configurations**  
+ Ubuntu 18.04 LTS, Matlab 2019b, Gurobi 9.0.1


## Getting Started

The main script is `main_multimode.m`; it performs all the initialization, loads the scheduling problen, attempts to solve it, and (optionally) produces some visualization of the resulting schedules.

In this script, there are only three parameters relevant for the user, all located in the `%% User parameters` section.

|Parameter|Usage|
|:---|:---|
|`configuration`  | Define the scheduling problem to solve, loaded byt the `loadConfig.m` funtion. See [Solving your own Problem]((#solving-your-own-problem)) for details.|
|`print`  | Enable/disable the generation of visualizations of the schedules.|
|`compute_iis`  | Enable/disable the computation of the Irreducible Inconsistent Subsystem; in short, this indicates what set of constraints make a scheduling problem unfeasible to solve.  Read more: http://www.gurobi.com/documentation/8.1/refman/matlab_gurobi_iis.html|

By default, the `simple_example` configuration is being loaded. This is a simple scheduling problem with a handful of applications and three modes.

## Comparing Scheduling Strategies
As described in the [_Time-Triggered Wireless Architecture_  paper](https://arxiv.org/abs/2002.07491), synthesizing compatible schedules across multiple modes creates some dependencies _between_ the modes' schedules.
The paper proposes an efficient schedule inheritance strategy (`minimal_inheritance`) which guarantees the compatibility of schedules while minimizing the overhead in terms of number of communication rounds scheduled.
We compare this strategy against two baselines
(see the paper for details).

+ The `no-inheritance` approach is optimal in terms of number of rounds scheduled, but does not guarantee schedules compatibility across modes.
+ The `full-inheritance` approach guarantees schedules compatibility but is very conservative.

The `main_multimode_comparison.m` performs this comparison between the different strategies. Again, the `%% User parameters` section contains all the relevant user settings.

|Parameter|Usage|
|:---|:---|
|`configuration`  | Define the scheduling problem to solve, loaded byt the `loadConfig.m` funtion. See [Solving your own Problem]((#solving-your-own-problem)) for details.|
|`no_inheritance`  | Enable/disable running this inheritance strategy for comparison.|
|`minimal_inheritance`  | Enable/disable running this inheritance strategy for comparison.|
|`full_inheritance`  | Enable/disable running this inheritance strategy for comparison.|
|`print_plot`  | Enable/disable the generation of summary plots of the comparison results.|

By default, the `evaluation` configuration is being loaded. This is a scheduling problem used in the inheritance evaluation presented in [the paper (Sections 5.2 and 5.3)](https://arxiv.org/abs/2002.07491).
Its is a moderately hard scheduling problem (5 modes, 15 applications); it is not too challenging in order to be feasible even when using the `full_inheritance`.

## Solving your own Problem

To solve your own scheduling problem, you must
1. write your own configuration file,
2. save is in the `/configurations` directory,
3. add your configuration file name in `loadConfig.m`

The simplest way to get started is to modify the `simple_example` configuration. The file contains detailed information about the different data structure and their intended use.


[matlab]: https://www.mathworks.com/products/matlab.html
[gurobi]: https://www.gurobi.com/
[ttw_repo]: https://github.com/romain-jacob/TTW-Scheduler
[ttw_zenodo]: https://doi.org/10.5281/zenodo.3530665
