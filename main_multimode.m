%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% multimode_main.m
% Main script file for the multi-mode schedule synthesis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, 
% Romain Jacob,
%
% last update 27.06.19
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
% 
% Log
% 
% 27.06.19:
%  + added support for flexible round lengths. The rounds are not assumed
%  to contain a fixed number of slots anymore. This does not change
%  anything in term of energy consumption, but it significantly increase
%  the schedulability, in particular when the utilization is high.
%  This require to have a model of the round length:
% 
%    T_round(B) = T_per_round + B * T_per_slot
%
%  This model can be calibrated very precisely. The `loadRoundModel()`
%  function outputs `T_per_round` and `T_per_slot` values for our TTW
%  implementation based on Baloo.
%  - B is capped to a to B_max
%  - The maximum payload size is given by L_max
%
%  The synthesis now explores all possible numbers of rounds for each
%  round. This sensibly increases the solving time, but improves the
%  schedulability.
%
% 16.06.19:
%  + added support for custom constraints


%% Selective clean to compare the different schedule inheriance modes
if exist('comparison_flag','var')
    % Script launched from 'main_multimode_comparison.m'
    clearvars -except   round_counts ...
                        HP ...
                        inheritance_flag ...
                        comparison_flag ...
                        modeID ...
                        modeNb ...
                        solvingTimes ...
                        no_inheritance ...
                        minimal_inheritance ...
                        full_inheritance   ...
                        print_plot ...
                        configuration
                    
else
    clear;
    clc;
    close all;
    inheritance_flag = '';
    modeID=0;
end

% mfilename

%% Enable/disable printing of schedules
print = 0;

%% Schedule to compute
% Uncomment the configuration you wish to compute schedule for.
% See `loadConfig.m` for details

if exist('comparison_flag','var')
    % Script launched from 'main_multimode_comparison.m'
    % Configuration is defined there
else
    configuration = 'simple_example';   % Simple example configuration
    % configuration = 'pendulums_TCPS';   % Pendulums use case
    % configuration = 'example';          % Default configuration
end

%% Enable/disable the computation of the Irreducible Inconsistent Subsystem
% Read more: http://www.gurobi.com/documentation/8.1/refman/matlab_gurobi_iis.html
compute_iis = 0;

%% Define globally used indices
globalVarDef;

%% Define logging configuration
% LOG_SIMPLE - Simple log (only structural information)
% LOG_VERBOSE - Verbose log (all information)

global LOG_SIMPLE LOG_VERBOSE;

LOG_SIMPLE  = true;
LOG_VERBOSE = true;

%% Loading inputs to the schedule systhesis

% Load configuration (scheduling problem to solve)
% and round model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[APPs, APs, Tasks, Msgs, CustomConstaints, ...
    ModeApps, ModeTransitionMatrix] = ...
    loadConfig(configuration, inheritance_flag, modeID);

% A round composed of B slots as the following length:
%   T_round(B) = T_per_round + B * T_per_slot

global T_per_slot T_per_round B_max L_max N H;

%% configuration preprocessing
[APPs, Tasks, Msgs, ModeApps, APs, CustomConstaints] = ...
    configPreprocessing(APPs, Tasks, Msgs, ModeApps, APs, CustomConstaints);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOG BLOCK
if true == LOG_SIMPLE
    fprintf('========================================\n');
    fprintf('=== Scheduling Problem Loaded ===\n');
    fprintf('%d PUs, %d Apps, %d Tasks, %d Messages\n', ...
        size(APs,2),size(APPs,2),size(Tasks,2),size(Msgs,2));
    if true == LOG_VERBOSE
        
        fprintf('\n');
        fprintf('APs:\n');
        for i = 1:size(APs,2)
            fprintf('%s, ', APs{i}{API_NM});
        end
        fprintf('\n\n');
        
        fprintf('Apps:\n');
        for i = 1:size(APPs,2)
            fprintf('[%d]%s:PD = %.2f, DL = %.2f, TC = ', ...
                APPs{i}{AI_ID},APPs{i}{AI_NM},APPs{i}{AI_PD},APPs{i}{AI_DL});
            for j = 1:size(APPs{i}{AI_TC},2)
                fprintf('%s, ', APPs{i}{AI_TC}{j});
            end
            fprintf('\n');
        end
        fprintf('\n');
        
        fprintf('Tasks:\n');
        for i = 1:size(Tasks,2)
            fprintf('[%d]%s:PD = %.2f, ET = %.2f, MP = %s\n', ...
                Tasks{i}{TI_ID},Tasks{i}{TI_NM},Tasks{i}{TI_PD},Tasks{i}{TI_ET},Tasks{i}{TI_MP});
        end
        fprintf('\n');
        
        fprintf('Messages:\n');
        for i = 1:size(Msgs,2)
            fprintf('[%d]%s:PD = %.2f, LD = %.2f\n', ...
                Msgs{i}{MI_ID},Msgs{i}{MI_NM},Msgs{i}{MI_PD},Msgs{i}{MI_LD});
        end
        fprintf('\n');
        
        fprintf('Round model:\n');
        fprintf('T_round(B) = T_per_round + B * T_per_slot\n');
        fprintf('where \tT_per_round = %.2f ms\n', T_per_round);
        fprintf('\tT_per_slot  = %.2f ms\n', T_per_slot);
        fprintf('for \tL = %d bytes\n', L_max);
        fprintf('\tN = %d\n', N);
        fprintf('\tH = %d\n', H);
        
        fprintf('B_max set to %d, which leads to \n', B_max);
        fprintf('T_round(B_max) = %.2f ms\n', B_max*T_per_slot+T_per_round);
        fprintf('\n');
        
        fprintf('Custom constraints:\n');
        for cc = 1:numel(CustomConstaints)
            for term = 1:numel(CustomConstaints{cc}{CCI_LHS})-1
                fprintf('%g * %s \t+ ',...
                    CustomConstaints{cc}{CCI_LHS}{term}{CCI_COEF},...
                    CustomConstaints{cc}{CCI_LHS}{term}{CCI_VAR});
            end
            fprintf('%g * %s \t%s %g \n',...
                CustomConstaints{cc}{CCI_LHS}{end}{CCI_COEF},...
                CustomConstaints{cc}{CCI_LHS}{end}{CCI_VAR},...
                CustomConstaints{cc}{CCI_SGN},...
                CustomConstaints{cc}{CCI_RHS});
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Perform the scheduling domain decomposition
% obtain mode app sets
%scheduling domains decompositions

[ModeAppSets, CommonApps, APPs, Tasks, Msgs, CustomConstaints] = ...
    generateModeAppSet(APPs, Tasks, Msgs, ModeApps, ModeTransitionMatrix, CustomConstaints);
[CommonTasks, CommonMsgs] = ...
    findCommonTasksAndMessagesFull(APPs,CommonApps);

% log modes
%%
% LOG BLOCK
if true == LOG_SIMPLE
    fprintf('========================================\n');
    fprintf('=== Synthesis Flow Generated ===\n');
    fprintf('--- Augmented system with app domains ---\n');
    fprintf('%d PUs, %d Apps, %d Tasks, %d Messages\n', ...
        size(APs,2),size(APPs,2),size(Tasks,2),size(Msgs,2));
    if true == LOG_VERBOSE
        fprintf('PUs:\n');
        for i = 1:size(APs,2)
            fprintf('%s, ', APs{i}{API_NM});
        end
        fprintf('\n');
        fprintf('Apps:\n');
        for i = 1:size(APPs,2)
            fprintf('[%d]%s:PD = %.2f, DL = %.2f, TC = ', ...
                APPs{i}{AI_ID},APPs{i}{AI_NM},APPs{i}{AI_PD},APPs{i}{AI_DL});
            for j = 1:size(APPs{i}{AI_TC},2)
                fprintf('%s, ', APPs{i}{AI_TC}{j});
            end
            fprintf('\n');
        end
        fprintf('\n');
        fprintf('Tasks:\n');
        for i = 1:size(Tasks,2)
            fprintf('[%d]%s:PD = %.2f, ET = %.2f, MP = %s\n', ...
                Tasks{i}{TI_ID},Tasks{i}{TI_NM},Tasks{i}{TI_PD},Tasks{i}{TI_ET},Tasks{i}{TI_MP});
        end
        fprintf('\n');
        fprintf('Messages:\n');
        for i = 1:size(Msgs,2)
            fprintf('[%d]%s:PD = %.2f, LD = %.2f\n', ...
                Msgs{i}{MI_ID},Msgs{i}{MI_NM},Msgs{i}{MI_PD},Msgs{i}{MI_LD});
        end
    end
    fprintf('--- Synthesis modes ---\n');
    for i = 1:size(ModeAppSets,2)
        fprintf('-- Mode[%d], Prio = %d\n', ModeAppSets{i}{MAI_ID}, ModeAppSets{i}{MAI_PR});
        for j = 1:size(ModeAppSets{i}{MAI_TA},2)
            fprintf('%s, ', ModeAppSets{i}{MAI_TA}{j});
        end
        fprintf('\n');
        fprintf('FA = ');
        for j = 1:size(ModeAppSets{i}{MAI_FA},2)
            fprintf('%s, ', ModeAppSets{i}{MAI_FA}{j});
        end
        fprintf('\n');
        fprintf('LA = ');
        for j = 1:size(ModeAppSets{i}{MAI_LA},2)
            fprintf('%s, ', ModeAppSets{i}{MAI_LA}{j});
        end
        fprintf('\n');
        fprintf('VA = ');
        for j = 1:size(ModeAppSets{i}{MAI_VA},2)
            fprintf('%s, ', ModeAppSets{i}{MAI_VA}{j});
        end
        fprintf('\n');
    end
    fprintf('========================================\n');
end


%%
% initialize outputFormat
[CommonTaskSchedules,CommonMsgSchedules,ModeSchedules] = initializeOutputFormatFull(Tasks, Msgs, CommonTasks, CommonMsgs);

   
%% main synthesis loop (synthesis for each mode)
for i = 1:size(ModeAppSets,2)
    %%
    % preprocessing for synthesis
    [AppsSingleMode,        TasksSingleMode,    MsgsSingleMode,...
    LegAppTaskSchedules,    VirtLegAppTasks,    VirtLegAppTaskSchedules, ...
    LegAppMsgSchedules,     VirtLegAppMsgs,     VirtLegAppMsgSchedules, ...
    VirtCollisionAppPairs, VirtCollisionTaskPairs, CustomConstaintsSingleMode] ...
    = preSynthesisProcessingFull(ModeAppSets, i, APPs, Tasks, Msgs, CommonTaskSchedules, CommonMsgSchedules,CustomConstaints);

    %%
    % synthesize schedules
    [solved, iis, roundSchedulesSingleMode, taskSchedulesSingleMode, msgSchedulesSingleMode, hyperPeriodSingleMode, solvingTime] ...
    = synthesizeSchedulesMultiModeFull(APs, AppsSingleMode, TasksSingleMode, MsgsSingleMode, CustomConstaintsSingleMode, ...
    LegAppTaskSchedules, VirtLegAppTasks, VirtLegAppTaskSchedules, ...
    LegAppMsgSchedules, VirtLegAppMsgs, VirtLegAppMsgSchedules, VirtCollisionTaskPairs, CommonMsgs, compute_iis);
    assert(true == solved, 'No solution found');
    %%
    % post synthesis processing
    [ModeSchedules, CommonTaskSchedules, CommonMsgSchedules]...
    = postSynthesisProcessingFull(ModeAppSets, ModeSchedules, i, ...
    CommonTaskSchedules, CommonMsgSchedules, roundSchedulesSingleMode,taskSchedulesSingleMode, msgSchedulesSingleMode, hyperPeriodSingleMode, solvingTime);

end


%%
% log scheduling result
%%
% LOG BLOCK
if true == LOG_SIMPLE
    fprintf('========================================\n');
    fprintf('=== Scheduling Results ===\n');
    fprintf('--- Mode Schedules ---\n');
    for i = 1:size(ModeSchedules,2)
        fprintf('Mode %d, Prio = %d, HP = %.2f\n', ModeSchedules{i}{MSDI_ID}, ModeSchedules{i}{MSDI_PR}, ModeSchedules{i}{MSDI_HP});
        fprintf('Task schedules:\n');
        for j = 1:size(ModeSchedules{i}{MSDI_TS},2)
            fprintf('%s = %.2f, ', ModeSchedules{i}{MSDI_TS}{j}{TSI_NM}, ModeSchedules{i}{MSDI_TS}{j}{TSI_OS});
            if 0 == mod(j,10)
                fprintf('\n');
            end
        end
        fprintf('\n');
        fprintf('Message schedules:\n');
        for j = 1:size(ModeSchedules{i}{MSDI_MS},2)
            fprintf('%s - OS = %.2f, DL = %.2f, ', ModeSchedules{i}{MSDI_MS}{j}{MSI_NM}, ModeSchedules{i}{MSDI_MS}{j}{MSI_OS}, ModeSchedules{i}{MSDI_MS}{j}{MSI_DL});
            if 0 == mod(j,5)
                fprintf('\n');
            end
        end
        fprintf('\n');
        fprintf('Round schedules:\n');
        for j = 1:size(ModeSchedules{i}{MSDI_RS},2)
            fprintf('R[%d] - OS = %.2f, FL = %.0f, MSGs = ', j, ModeSchedules{i}{MSDI_RS}{j}{RSI_OS}, ModeSchedules{i}{MSDI_RS}{j}{RSI_FL});
            for k = 1:size(ModeSchedules{i}{MSDI_RS}{j}{RSI_MS},2)
                fprintf('%s, ', ModeSchedules{i}{MSDI_RS}{j}{RSI_MS}{k});
            end
            fprintf('\n');
        end
    end
    fprintf('--- Common Task Schedules ---\n');
    for i = 1:size(CommonTaskSchedules,2)
        fprintf('%s: %.2f, ', CommonTaskSchedules{i}{TSI_NM}, CommonTaskSchedules{i}{TSI_OS});
        if 0 == mod(i,10)
            fprintf('\n');
        end
    end
    fprintf('\n');
    fprintf('========================================\n');
end
%%
% Visualization

if print
    numHyperperiod = 2;

    scheduleVisualizationResourceFull(APs, APPs, Tasks, Msgs, CustomConstaints, ...
        CommonTaskSchedules, CommonMsgSchedules, ModeSchedules, ModeAppSets, ...
        numHyperperiod);
    scheduleVisualizationAppFull(APs, APPs, Tasks, Msgs, CustomConstaints, ...
        CommonTaskSchedules, CommonMsgSchedules, ModeSchedules, ModeAppSets, ...
        numHyperperiod);
end



