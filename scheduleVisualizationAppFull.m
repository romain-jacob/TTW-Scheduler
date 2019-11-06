%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% scheduleVisualizationApp.m
% Function to visualize the schedules according to applications
% Input:
% - APs - processors
% - APPs - total application set
% - Tasks - total task set
% - Msgs - total message set
% - CommonTaskSchedules - common task schedules
% - ModeSchedules - schedules of all modes
% - ModeAppSets - applications of all modes
% - numLCM - number of hyper periods to be plotted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, last update 05.01.16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function scheduleVisualizationAppFull(APs, APPs, Tasks, Msgs, CCs, CommonTaskSchedules, CommonMsgSchedules, ModeSchedules, ModeAppSets, numLCM)
%%
% global index declaration
globalVarDec;
%%
% plot schedules for each mode
for i = 1:size(ModeSchedules,2)
    %%
    % preprocessing
    [AppsSingleMode, TasksSingleMode, MsgsSingleMode,...
    LegAppTaskSchedules, VirtLegAppTasks, VirtLegAppTaskSchedules,...
    LegAppMsgSchedules, VirtLegAppMsgs, VirtLegAppMsgSchedules] ...
    = preSynthesisProcessingFull(ModeAppSets, ModeSchedules{i}{MSDI_PR},...
    APPs, Tasks, Msgs, CommonTaskSchedules, CommonMsgSchedules, CCs);
    %%
    % plot schedules
    scheduleVisualizationAppSingleMode(ModeSchedules{i}{MSDI_ID}, ModeSchedules{i}{MSDI_PR}, ...
        ModeSchedules{i}{MSDI_TS}, ModeSchedules{i}{MSDI_MS}, ModeSchedules{i}{MSDI_RS}, ...
        APs, AppsSingleMode, TasksSingleMode, MsgsSingleMode, ...
        ModeSchedules{i}{MSDI_HP}, numLCM);
end