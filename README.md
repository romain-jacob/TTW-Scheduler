# TTW Scheduler
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3530665.svg)][ttw_zenodo]

This repository contains the source code for the TTW Scheduler, presented in the following paper:

> **Time-Triggered Wireless Architecture**  
Romain Jacob, Licong Zhang, Marco Zimmerling, Samarjit Chakraborty, Lothar Thiele   
Accepted to ECRTS 2020  
[arXiv (submitted version)](https://arxiv.org/abs/2002.07491)

Time-Triggered Wireless (TTW) is a wireless architecture for multi-mode cyber-physical systems.
TTW consists of two main components: a system-wide real-time scheduler that executes offline and a communication stack called TTnet that runs online on distributed low-power wireless devices (An implementation of TTnet is available in a [dedicated repository](https://github.com/romain-jacob/TTW-Artifacts)).
Based on the application specification (e.g., tasks, messages, modes) and system parameters (e.g., number of nodes, message sizes), the scheduler synthesizes optimized scheduling tables for the entire system. These tables are loaded onto the devices, and at runtime each device follows the table that corresponds to the current mode.
The TTW scheduler statically synthesizes the schedule of all tasks, messages, and communication rounds by solving a MILP.

This repository contains a [Matlab][matlab] implementation of the TTW scheduler, using [Gurobi][gurobi] to solve the MILP formulation.
> Although Matlab and Gurobi are both commercial software (which is not ideal), free academic and/or student licenses are currently available from the software vendors.

## Installation Instructions

This software (should) run on common operating systems (Windows, macOS, Linux) but **requires a 64-bit** version.

+ Get Matlab (R2016 or newer), either via your academic institution or the [official Matlab website][matlab]. It must be a **64-bit version**.
+ Get the [Gurobi Optimizer](https://www.gurobi.com/downloads/gurobi-software/) from the Gurobi website. Download the latest version corresponding to your OS. You need to create an account using an **institutional email address** (eg, `john.doe@ethz.ch`).
+ Follow the [online quick start guide](https://www.gurobi.com/documentation/quickstart.html) corresponding to your OS to install and setup Gurobi.  
To validate your academic license, you must to be connected to Internet via your academic institution (either physically or via VPN).
+ Setup Gurobi for Matlab; OS-specific instructions are in the quick start guide under `MATLAB Interface/Setting up Gurobi for MATLAB`
+ Optionally, you can enter `savepath` in the Matlab command window to avoid having to redo this last step every time you open Matlab.

**Tested configurations**  
+ Ubuntu 18.04 LTS, Matlab 2019b, Gurobi 9.0.1


## Getting Started

The main scripts are:
- `main_multimode.m` > Run the multimode based on `modes_configuration_sample.m`
- `main_multimode_comparison.m` > Compare the effects of different reservation strategies

## Solving your own Problem

**wip**

[matlab]: https://www.mathworks.com/products/matlab.html
[gurobi]: https://www.gurobi.com/
[ttw_repo]: https://github.com/romain-jacob/TTW-Scheduler
[ttw_zenodo]: https://doi.org/10.5281/zenodo.3530665
