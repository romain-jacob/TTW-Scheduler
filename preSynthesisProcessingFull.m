%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% preSynthesisProcessing.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to preporcess for each single mode before the schedule
% synthesis. It does the following:
% - obtain the applications, tasks and messages that are relevant
% for this mode
% - obtain the task schedules for the legacy apps
% - obtain the task schedules for the virtual legacy apps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input:
% - ModeAppSets - application sets for all modes
% - priority - priority of the mode
% - APPs - total application set
% - Tasks - total task set
% - Msgs - total message set
% - CommonTaskSchedules - the current common task schedules (containing synthesized
% task schedules)
% - CommonMsgSchedules - the current common message schedules (containing synthesized
% message schedules)
% Output:
% - AppsSingleMode - application set for the current mode
% - TasksSingleMode - task set for the current mode
% - MsgsSingleMode - message set for the current mode
% - LegAppTaskSchedules - legacy apps including the task schedules
% - VirtLegAppTasks - set of virtual legacy apps
% - VirtLegAppTaskSchedules - task schedules for the virtual legacy apps
% - VirtCollisionAppPairs - set of pairs {virtApp, freeApp} that may be
% colliding in a lower priority modes
% - VirtCollisionTaskPairs - set of tasks belonging to one colliding app
% pairs, which are mapped on the same processing unit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, Romain Jacob, last update 31.05.19
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Log
% 
% 19.06.16:
%  + added support for custom constraints
% 31.05.19: 
%  + added support for same task/message in different applications

%% TODO
% - update file description


function [AppsSingleMode, TasksSingleMode, MsgsSingleMode,...
    LegAppTaskSchedules, VirtLegAppTasks, VirtLegAppTaskSchedules, ...
    LegAppMsgSchedules, VirtLegAppMsgs, VirtLegAppMsgSchedules, ...
    VirtCollisionAppPairs, VirtCollisionTaskPairs, ...
    CustomConstaintsSingleMode] ...
    = preSynthesisProcessingFull(ModeAppSets, priority,...
    APPs, Tasks, Msgs, CommonTaskSchedules, CommonMsgSchedules,CustomConstaints)
%%
% global index declaration
globalVarDec;

%%
% obtain the apps, tasks and messages for this mode
% -> Must ensure that entries are unique!
AppsSingleMode = {};
TasksSingleMode = {};
MsgsSingleMode = {};

% Temporary arrays for convenience
taskList = [];  
msgList  = [];   

for j = 1:size(ModeAppSets{priority}{MAI_TA},2)
    appId = findAppByName(ModeAppSets{priority}{MAI_TA}{j}, APPs, 1);
    AppsSingleMode{size(AppsSingleMode,2)+1} = APPs{appId};
    for k = 1:size(APPs{appId}{AI_TC},2)
        if strncmp(APPs{appId}{AI_TC}{k},'T',1)
            taskId = findTaskByName(APPs{appId}{AI_TC}{k}, Tasks, 1);
            % if new task, add it to the task list
            if(isempty(intersect(taskList,taskId)))
                TasksSingleMode{size(TasksSingleMode,2)+1} = Tasks{taskId};
                taskList = [taskList taskId];
            end
        elseif strncmp(APPs{appId}{AI_TC}{k},'M',1)
            msgId = findMsgByName(APPs{appId}{AI_TC}{k}, Msgs, 1);
            % if new msg, add it to the msg list
            if(isempty(intersect(msgList,msgId)))
                MsgsSingleMode{size(MsgsSingleMode,2)+1} = Msgs{msgId};
                msgList = [msgList msgId];
            end
        end
    end
end

%% 
% Obtain the custom constraint for this mode
CustomConstaintsSingleMode = {};

for cc = 1:numel(CustomConstaints)
%     [CustomConstaints{cc}{CCI_LHS}{1}{CCI_VAR} CustomConstaints{cc}{CCI_LHS}{2}{CCI_VAR}]
    assign_cc = 1;
    for term = 1:numel(CustomConstaints{cc}{CCI_LHS})
        var = CustomConstaints{cc}{CCI_LHS}{term}{CCI_VAR};
        % Look for var in the tasks and messages of this mode
        if (~findTaskByName(var, TasksSingleMode, 0) && ...
            ~findMsgByName( var, MsgsSingleMode,  0))
            % 'var' is not part of this mode
            assign_cc = 0;
            break
        end
    end
    % if all var of the custom constraint are part of this mode, 
    % save that custom constraint
    if assign_cc
        CustomConstaintsSingleMode{numel(CustomConstaintsSingleMode)+1} = ...
            CustomConstaints{cc};
    end
end

% Log the task/message IDs
for cc = 1:numel(CustomConstaintsSingleMode)
    for term = 1:numel(CustomConstaintsSingleMode{cc}{CCI_LHS})
        var = CustomConstaintsSingleMode{cc}{CCI_LHS}{term}{CCI_VAR};
        var_id = max(   findTaskByName(var, TasksSingleMode, 0) ,...
                        findMsgByName( var, MsgsSingleMode,  0) );
        if var_id == 0
            assert(false,'Constraint variable not found: %s', var)
        else
            CustomConstaintsSingleMode{cc}{CCI_LHS}{term}{CCI_VID} = var_id;
        end
    end
end

%%
% obtain legacy app task and msg schedules
LegAppTaskSchedules = {};
LegAppMsgSchedules = {};
for j = 1:size(ModeAppSets{priority}{MAI_LA},2)
    appId = findAppByName(ModeAppSets{priority}{MAI_LA}{j}, APPs, 1);
    for l = 1:size(APPs{appId}{AI_TC},2)
        if strncmp(APPs{appId}{AI_TC}{l},'T',1)
            taskId = findTaskByName(APPs{appId}{AI_TC}{l}, Tasks, 1);
            tid = Tasks{taskId}{TI_ID};
            for k = 1:size(CommonTaskSchedules,2)
                if CommonTaskSchedules{k}{TSI_ID} == tid
%                     Verifies that the task offset has been defined/computed
%                     in a previous step. If it is still -1, the task
%                     should not belong to the legacy.
                    assert(-1~=CommonTaskSchedules{k}{TSI_OS}, 'Error');
                    LegAppTaskSchedules{size(LegAppTaskSchedules,2)+1} = CommonTaskSchedules{k};
                    break;
                end
            end
        elseif strncmp(APPs{appId}{AI_TC}{l},'M',1)
            msgId = findMsgByName(APPs{appId}{AI_TC}{l}, Msgs, 1);
            mid = Msgs{msgId}{MI_ID};
            for k = 1:size(CommonMsgSchedules,2)
                if CommonMsgSchedules{k}{MSI_ID} == mid
%                     Verifies that the message offset and deadline have been defined/computed
%                     in a previous step. If it is still -1, the message
%                     should not belong to the legacy.
                    assert(-1~=CommonMsgSchedules{k}{MSI_OS} && -1~=CommonMsgSchedules{k}{MSI_DL}, 'Error');
                    LegAppMsgSchedules{size(LegAppMsgSchedules,2)+1} = CommonMsgSchedules{k};
                    break;
                end
            end
        end
    end
end
%%
% obtain virtual legacy app tasks, msgs and schedules
% NOTE: So far, the virtual legacy apps are taken all the same for all apps
% in one mode. This is not what is described in the paper right now.
% ->    But not an issue, the constraint is defined afterwards in the ILP just
%       on the concerned applications
VirtLegAppTasks = {};
VirtLegAppTaskSchedules = {};
VirtLegAppMsgs = {};
VirtLegAppMsgSchedules = {};
for j = 1:size(ModeAppSets{priority}{MAI_VA},2)
    appId = findAppByName(ModeAppSets{priority}{MAI_VA}{j}, APPs, 1);
    for l = 1:size(APPs{appId}{AI_TC},2)
        if strncmp(APPs{appId}{AI_TC}{l},'T',1)
            taskId = findTaskByName(APPs{appId}{AI_TC}{l}, Tasks, 1);
            tid = Tasks{taskId}{TI_ID};
            VirtLegAppTasks{size(VirtLegAppTasks,2)+1} = Tasks{taskId};
            for k = 1:size(CommonTaskSchedules,2)
                if CommonTaskSchedules{k}{TSI_ID} == tid
%                     Verifies that the task offset has been defined/computed
%                     in a previous step. If it is still -1, the task
%                     should not belong to the legacy.
                    assert(-1~=CommonTaskSchedules{k}{TSI_OS}, 'Error');
                    VirtLegAppTaskSchedules{size(VirtLegAppTaskSchedules,2)+1} = CommonTaskSchedules{k};
                    break;
                end
            end
        elseif strncmp(APPs{appId}{AI_TC}{l},'M',1)
            msgId = findMsgByName(APPs{appId}{AI_TC}{l}, Msgs, 1);
            mid = Msgs{msgId}{MI_ID};
            VirtLegAppMsgs{size(VirtLegAppMsgs,2)+1} = Msgs{msgId};
            for k = 1:size(CommonMsgSchedules,2)
                if CommonMsgSchedules{k}{MSI_ID} == mid
%                     Verifies that the message offset and deadline have been defined/computed
%                     in a previous step. If it is still -1, the message
%                     should not belong to the legacy.
                    assert(-1~=CommonMsgSchedules{k}{MSI_OS} && -1~=CommonMsgSchedules{k}{MSI_DL}, 'Error');
                    VirtLegAppMsgSchedules{size(VirtLegAppMsgSchedules,2)+1} = CommonMsgSchedules{k};
                    break;
                end
            end
        end
    end
end
%%
% derive the colliding app pairs
% For each application being in the virtual legacy of the current mode,
% looks up in the lower priority modes with which of the free app of the
% current mode there can be a conflict, ie when both the free and the
% legacy app are in the legacy app of the same mode.
VirtCollisionAppPairs = {};
for i = 1:size(ModeAppSets{priority}{MAI_VA},2)
    virtApp = ModeAppSets{priority}{MAI_VA}{i};
    found = false;
    for j = 1:size(ModeAppSets{priority}{MAI_FA},2)
        freeApp = ModeAppSets{priority}{MAI_FA}{j};
        appPair = {virtApp, freeApp};
        for k = priority+1:size(ModeAppSets,2)
            if (size(setAnd(appPair,ModeAppSets{k}{MAI_LA}),2) == 2)
                VirtCollisionAppPairs{size(VirtCollisionAppPairs,2)+1} = appPair;
                found = true;
                break;
            end
        end
    end
%     Verifies that if an app is in the virtual legacy of a mode, it must
%     be colliding with at least on of the free app of the mode.
    assert(found == true, 'Error');
end
%%
% derive the collision free task pairs
% For any pair of applications that may be colliding, an actual issue may
% occur only if some tasks, belonging to both apps, are mapped to the same
% processing unit. If that's the case, the info is saved into 
% VirtCollisionTaskPairs as a tuple of the form
%     { Task ID from the virtual legacy app, previously scheduled ,
%       Task ID from the free app, about to be scheduled ,
%       Processing unit on which the two are colliding }
  
VirtCollisionTaskPairs = {};
for i = 1:size(VirtCollisionAppPairs,2)
    % find the apps
    app1 = {};
    app2 = {};
    for j = 1:size(APPs,2)
        if strcmp(VirtCollisionAppPairs{i}{1},APPs{j}{API_NM})
            app1 = APPs{j};
            break;
        end
    end
    for j = 1:size(APPs,2)
        if strcmp(VirtCollisionAppPairs{i}{2},APPs{j}{API_NM})
            app2 = APPs{j};
            break;
        end
    end
    % find the tasks
    for j = 1:size(app1{AI_TC},2)
        for k = 1:size(app2{AI_TC},2)
            if strncmp(app1{AI_TC}{j},'T',1) && strncmp(app2{AI_TC}{k},'T',1)
                ap1 = {};
                ap2 = {};
                for l = 1:size(Tasks,2)
                    if strcmp(app1{AI_TC}{j},Tasks{l}{TI_NM})
                        ap1 = Tasks{l}{TI_MP};
                        break;
                    end
                end
                for l = 1:size(Tasks,2)
                    if strcmp(app2{AI_TC}{k},Tasks{l}{TI_NM})
                        ap2 = Tasks{l}{TI_MP};
                        break;
                    end
                end
                if strcmp(ap1,ap2)
%                     VirtCollisionTaskPairs contains the groups
%                     {Task, Task, AP} with the two task indexes and the
%                     processors on which they collide.
                    VirtCollisionTaskPairs{size(VirtCollisionTaskPairs,2)+1} = {app1{AI_TC}{j}, app2{AI_TC}{k}, ap1};
                end
            end
        end
    end
end
