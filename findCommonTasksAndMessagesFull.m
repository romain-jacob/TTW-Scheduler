%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% findCommonTasksAndMessages.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to find the common tasks and messages according
% to common apps. In the current version, it is considered
% that all tasks and messages of an app will have the same
% schedule in different modes.
% In particular, messages have the same offsets and deadlines! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input:
% - APPs - applications
% - CommonApps - common applications
% Output:
% - CommonTasks - set of common tasks
% - CommonMsgs - set of common messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, last update 15.01.16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Comments from Romain, 12.03.17
% 
% + Now we said we wanted to save the whole schedule, didn't we? Let us see
% what is in the code... Yeap, we save all tasks and messages! Good. The
% initial description has been updated.
% 
% + Here again, I would prefer remove 'common app' if the benefice is not obvious
% later on.
% 
% + In the current state, we do not support the same message/task being part of
% multiple chains (which would be nice to have eventually...). Then, it is
% no problem to inherit the strict offsets and deadlines for messages. If
% we want to be more general, the inheritance must be modified: the
% scheduling space of the messages can only decrease, but it does not have
% to stay the same.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CommonTasks, CommonMsgs] = findCommonTasksAndMessagesFull(APPs, CommonApps)
%%
% global index declaration
globalVarDef;
%%
% compute common tasks and messages
CommonTasks = {};
CommonMsgs = {};
for i = 1:size(CommonApps,2)
    for j = 1:size(APPs,2)
        if strcmp(APPs{j}{AI_NM},CommonApps{i})
            for k = 1:size(APPs{j}{AI_TC},2)
                if strncmp(APPs{j}{AI_TC}{k},'T',1)
                    CommonTasks{size(CommonTasks,2)+1} = APPs{j}{AI_TC}{k};
                elseif strncmp(APPs{j}{AI_TC}{k},'M',1)
                    CommonMsgs{size(CommonMsgs,2)+1} = APPs{j}{AI_TC}{k};
                end
            end
            break;
        end
    end
end

