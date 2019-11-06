%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% postSynthesisProcessing.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to preporcess for each single mode after the schedule
% synthesis. It does the following:
% - writes the schedules for each mode in ModeSchedules
% - writes the task and message schedules in TaskSchedules and MsgSchedules
% respectively
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input:
% - ModeAppSets - set specifying the synthesis flow
% - ModeSchedules - set to store the schedules for each mode
% - priority - priority
% - CommonTaskSchedules - set of common task schedules
% - roundSchedulesSingleMode - round schedules for the current mode
% - taskSchedulesSingleMode - task schedules for the current mode
% - msgSchedulesSingleMode - message schedules for the current mode
% - solvingTime - global solving time for the mode
% Output:
% - ModeSchedules - set to store the schedules for each mode
% - CommonTaskSchedules - set of common task schedules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang
% Romain Jacob, last update 30.03.17
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [ModeSchedules, CommonTaskSchedules, CommonMsgSchedules]...
    = postSynthesisProcessingFull(ModeAppSets, ModeSchedules, priority, ...
    CommonTaskSchedules, CommonMsgSchedules, roundSchedulesSingleMode, taskSchedulesSingleMode, msgSchedulesSingleMode, hyperperiodSingleMode, solvingTime)
%%
% global index declaration
globalVarDec;

%%

% write schedules into mode schedules
ModeSchedules{priority}{MSDI_ID} = ModeAppSets{priority}{MAI_ID};
ModeSchedules{priority}{MSDI_PR} = ModeAppSets{priority}{MAI_PR};
ModeSchedules{priority}{MSDI_TS} = taskSchedulesSingleMode;
ModeSchedules{priority}{MSDI_MS} = msgSchedulesSingleMode;
ModeSchedules{priority}{MSDI_RS} = roundSchedulesSingleMode;
ModeSchedules{priority}{MSDI_HP} = hyperperiodSingleMode;
ModeSchedules{priority}{MSDI_ST} = solvingTime;
%%
% write task schedules into general schedules
for j = 1:size(taskSchedulesSingleMode,2)
    for k = 1:size(CommonTaskSchedules,2)
        if strcmp(taskSchedulesSingleMode{j}{TSI_NM},CommonTaskSchedules{k}{TSI_NM}) && CommonTaskSchedules{k}{TSI_OS} == -1
            CommonTaskSchedules{k}{TSI_OS} = taskSchedulesSingleMode{j}{TSI_OS};
            break;
        end
    end
end
%%
% write msg schedules into general schedules
for j = 1:size(msgSchedulesSingleMode,2)
    for k = 1:size(CommonMsgSchedules,2)
        if strcmp(msgSchedulesSingleMode{j}{MSI_NM},CommonMsgSchedules{k}{MSI_NM}) && CommonMsgSchedules{k}{MSI_OS} == -1 && CommonMsgSchedules{k}{MSI_DL} == -1
            CommonMsgSchedules{k}{MSI_OS} = msgSchedulesSingleMode{j}{MSI_OS};
            CommonMsgSchedules{k}{MSI_DL} = msgSchedulesSingleMode{j}{MSI_DL};
            break;
        end
    end
end
