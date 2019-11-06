%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initializeOutputFormat.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to initialize the output format. It initializes
% output format for the task schedules, message schedules
% and mode schedules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input:
% - Tasks - tasks
% - Msgs - messages
% - CommonTasks - common tasks
% - CommonMsgs - common msgs
% Output:
% - CommonTaskSchedules - common task schedules
% - CommonMsgSchedules - common message schedules
% - ModeSchedules - task, message and round schedules for each mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, last update 18.12.16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Comments from Romain, 12.03.17
% 
% + CommonTask/MsgSchedules constains several fields
% ID : a number
% NM : the verbose name
% OS : offset
% DL : deadline
% But why only those common tasks and messages, and not all?
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CommonTaskSchedules,CommonMsgSchedules,ModeSchedules] = initializeOutputFormatFull(Tasks, Msgs, CommonTasks, CommonMsgs)
%%
% global index declaration
globalVarDec;

%%
% initialize containers for the schedules
CommonTaskSchedules = {};
CommonMsgSchedules = {};
ModeSchedules = {};
%%
% initialize TaskSchedules
for i = 1:size(CommonTasks,2)
    for j = 1:size(Tasks,2)
        if strcmp(CommonTasks{i},Tasks{j}{TI_NM})
            break;
        end
    end
    CommonTaskSchedules{i}{TSI_ID} = Tasks{j}{TI_ID};
    CommonTaskSchedules{i}{TSI_NM} = Tasks{j}{TI_NM};
    CommonTaskSchedules{i}{TSI_OS} = -1;
end
%%
% initialize MsgSchedules
CommonMsgSchedules = {};
for i = 1:size(CommonMsgs,2)
    for j = 1:size(Msgs,2)
        if strcmp(CommonMsgs{i},Msgs{j}{MI_NM})
            break;
        end
    end
    CommonMsgSchedules{i}{MSI_ID} = Msgs{j}{MI_ID};
    CommonMsgSchedules{i}{MSI_NM} = Msgs{j}{MI_NM};
    CommonMsgSchedules{i}{MSI_OS} = -1;
    CommonMsgSchedules{i}{MSI_DL} = -1;
end