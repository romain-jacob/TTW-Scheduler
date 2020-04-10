%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% configPreprocessing.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to preprocess the configuration, it does the following
% - reduce the sets of APPs, Tasks and Msgs to what is actually used in the
% mode configuration loaded
% - assign periods to tasks and messages
% - assign IDs to APs, APPs, Tasks, Msgs and ModeApps
% - create the duplicates of APPs, Tasks, and Msgs that are neccessary to
% support periods that are larger than deadlines
%  - add the required custom constraints for the duplicates
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input:
% - APPs                - applications
% - Tasks               - tasks
% - Msgs                - messages
% - ModeApps            - the mode configuration
% - APs                 - the application processors
% - CustomConstaints    - the custom constraints 
% Output:
% - APPs                - scheduled applications
% - Tasks               - preprocessed tasks
% - Msgs                - preprocessed messages
% - ModeApps            - preprocessed modes
% - APs                 - application processors with IDs
% - CustomConstaints    - preprocessed custom constraints 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, Romain Jacob
% Last update 27.06.19
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Log
% 
% 27.06.19:
%  + Documentation completed
%
% 18.06.19:
%  + Automated assignment of IDs to APPs, Tasks, etc.
%  + Automated duplication of applications when deadline larger that
%  period, including the creation of constraints on the tasks offsets
%  between the copies

%% TODO
%   - Support conversion from chain -> graph

function [APPs, Tasks, Msgs, ModeApps, APs, CustomConstaints] = configPreprocessing(APPs, Tasks, Msgs, ModeApps, APs, CustomConstaints)
%% global index declaration
globalVarDec;

%% 
ScheduledAPPNames   = {};
ScheduledTaskNames  = {};
ScheduledMsgNames   = {};
ScheduledAPPs   = {};
ScheduledTasks  = {};
ScheduledMsgs   = {};

%% Assign IDs
for ap = 1:size(APs, 2)
    APs{ap}{API_ID} = ap;
end
for task = 1:size(Tasks, 2)
    Tasks{task}{TI_ID} = task;
end
for msg = 1:size(Msgs, 2)
    Msgs{msg}{MI_ID} = msg;
end
for app = 1:size(APPs, 2)
    APPs{app}{AI_ID} = app;
end
for mode = 1:size(ModeApps, 2)
    ModeApps{mode}{MAI_ID} = mode;
end

%% Get the list of scheduled app names
for mode = 1:size(ModeApps, 2)
    %add apps to the list of scheduled ones
    ScheduledAPPNames = union(ScheduledAPPNames, ModeApps{mode}{MAI_TA});
end

%% Create duplicate applications when deadline > period
for app = 1:numel(ScheduledAPPNames)
    appId = findAppByName(ScheduledAPPNames(app), APPs, 1);
    app_period = APPs{appId}{AI_PD};
    
    % Multiple the application period such that (new) P >= D
    multi_factor = ceil(APPs{appId}{AI_DL} / APPs{appId}{AI_PD});
    APPs{appId}{AI_PD} = multi_factor * APPs{appId}{AI_PD};
    
    for copy = 1:(multi_factor - 1)
        
        % Initialize application copy's parameters
        cp_app_name = strcat(APPs{appId}{AI_NM},'_cp_',num2str(copy));
        cp_app_chain = {};
        
        % Create copies of application tasks and messages
        for j = 1:size(APPs{appId}{AI_TC},2)
            if (true == strncmp('T',APPs{appId}{AI_TC}{j},1))
                taskId = findTaskByName(APPs{appId}{AI_TC}{j}, Tasks, 1);
                cp_task_name = strcat(Tasks{taskId}{TI_NM},'_cp_',num2str(copy));
                cp_app_chain{numel(cp_app_chain)+1} = cp_task_name;
                % Add the task copy to the list of tasks
                Tasks{numel(Tasks) + 1} = ...
                    { numel(Tasks)+1, cp_task_name, Tasks{taskId}{TI_MP}, Tasks{taskId}{TI_ET}, -1, -1 };
                % Add the corresponding custom constaint
                cc = { {{Tasks{taskId}{TI_NM}, 1},{cp_task_name, -1}}, '=', (copy*app_period) };
                CustomConstaints{end+1} = cc;
            elseif (true == strncmp('M',APPs{appId}{AI_TC}{j},1))
                msgId = findMsgByName(APPs{appId}{AI_TC}{j}, Msgs, 1);
                cp_msg_name = strcat(Msgs{msgId}{MI_NM},'_cp_',num2str(copy));
                cp_app_chain{numel(cp_app_chain)+1} = cp_msg_name;
                % Add the message copy to the list of messages
                Msgs{numel(Msgs) + 1} = ...
                    { numel(Msgs)+1, cp_msg_name, -1, -1, Msgs{msgId}{MI_LD} };
            end
        end
        
        % Add the app copy to the list of applications
        APPs{numel(APPs) + 1} = ...
            { numel(APPs)+1 , cp_app_name, APPs{appId}{AI_PD}, APPs{appId}{AI_DL}, cp_app_chain };
        
        % Add the app copy to the corresponding modes
        for mode = 1:numel(ModeApps)
            % Search if original app is in the mode
            for app = 1:numel(ModeApps{mode}{MAI_TA})
                if (true == strcmp(ModeApps{mode}{MAI_TA}{app},APPs{appId}{AI_NM}))
                    % Add app copy to the mode
                    k = numel(ModeApps{mode}{MAI_TA});
                    ModeApps{mode}{MAI_TA}{k+1} = cp_app_name;
                    break
                end
            end
        end
        
        % Add the app copy to the scheduled app
        ScheduledAPPNames = union(ScheduledAPPNames, cp_app_name);        
    end
end

%% Get ScheduledTaskNames and ScheduledMsgNames
for app = 1:numel(ScheduledAPPNames)
    appId = findAppByName(ScheduledAPPNames(app), APPs, 1);
    for j = 1:size(APPs{appId}{AI_TC},2)
        if (true == strncmp('T',APPs{appId}{AI_TC}{j},1))
            %add task to the list of scheduled ones
            ScheduledTaskNames = union(ScheduledTaskNames, APPs{appId}{AI_TC}{j});
            taskId = findTaskByName(APPs{appId}{AI_TC}{j}, Tasks, 1);
            %assign the period to task
            Tasks{taskId}{TI_PD} = APPs{appId}{AI_PD};
        elseif (true == strncmp('M',APPs{appId}{AI_TC}{j},1))
            %add message to the list of scheduled ones
            ScheduledMsgNames = union(ScheduledMsgNames, APPs{appId}{AI_TC}{j});
            msgId = findMsgByName(APPs{appId}{AI_TC}{j}, Msgs, 1);
            %assign the period to message
            Msgs{msgId}{MI_PD} = APPs{appId}{AI_PD};
        end
    end
end

% Fill ScheduledAPPs, ScheduledTasks, and ScheduledMsgs
for app = 1:numel(ScheduledAPPNames)
    appId = findAppByName(ScheduledAPPNames(app), APPs, 1);
    ScheduledAPPs{app} = APPs{appId};
end
for task = 1:numel(ScheduledTaskNames)
    taskId = findTaskByName(ScheduledTaskNames(task), Tasks, 1);
    ScheduledTasks{task} = Tasks{taskId};
end
for msg = 1:numel(ScheduledMsgNames)
    msgId = findMsgByName(ScheduledMsgNames(msg), Msgs, 1);
    ScheduledMsgs{msg} = Msgs{msgId};
end

APPs    = ScheduledAPPs;
Tasks   = ScheduledTasks;
Msgs    = ScheduledMsgs;