%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generateModeAppSet.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to generate the app sets of different modes
% accoding to mode configuration. It does the following
% - obtain the application domains (applications with same initial schedules)
% - augment application, task and message set according to app domains
% - derive the synthesis flow, i.e., the set of free apps, legacy apps and
% virtual legacy apps
% - if the inheritance_flag is set to 'full', the decomposition into
% scheduling domain is not done
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input:
% - APPs - applications
% - Tasks - tasks
% - Msgs - messages
% - ModeApps - specification of applications in each mode
% - ModeTransitionMatrix - mode transition metrix
% - inheritance_flag - defines the type inheritance for VL, ie '', 'none',
% or 'full'
% Output:
% - ModeAppSets - Set specifying the synthesis flow
% - CommonApps - set of common apps
% - APPs - processed applications (augmented)
% - Tasks - processed tasks
% - Msgs - processed messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, 
% Romain Jacob, last update 04.04.17
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Comments from Romain, Update 03.04.17
% 
% + 'Application domains' are called 'scheduling domains' in the paper.
% 
% + It is not clear to me why we duplicate ModeApps into ModeAppSets
% instead of directly using the defined structure of ModeApps...
% 
% + The current version of the code uses the notion of Common Apps, ie apps
% which are specified in more than one mode. I don't really like this as it
% introduce a distinction which is not necessary in the problem
% description. Unless the rest of the code structure really benefit from
% it, I would like to get rid of it.
% 
% % % % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Log
% 19.06.16:
%  + added support for custom constraints

%% TODO
%   - Update top file description

function [ModeAppSets, CommonApps, APPs, Tasks, Msgs, CCs] = generateModeAppSet(APPs, Tasks, Msgs, ModeApps, ModeTransitionMatrix, CCs)

%%
% ModeApps = {Mode1, Mode2, ...}
% Modei = {Mode id, apps}
% apps = {'A1','A2',...}
ModeAppSets = {};
%%
% global index declaration
globalVarDec;

%%
% obtain the app domains 
numModes = size(ModeApps,2);
numTotalApps = size(APPs,2);
% make ModeConnectionMatrix
% -> Same as ModeTransitionMatrix but converted in upper-diagonal form
ModeConnectionMatrix = eye(size(ModeTransitionMatrix));
for i = 1:numModes
    for j = i+1:numModes
        if ModeTransitionMatrix(i,j) == 1 || ModeTransitionMatrix(j,i) == 1
            ModeConnectionMatrix(i,j) = 1;
        end
    end
end

% establish the mode app matrix
% Ultimately, the numbers in column i of ModeAppMatrix will indicates
% the scheduling domains of application i. In the first row, the numbers
% indicate the number of distinct scheduling domains.

% Step 1: fills the matrix with the modes specification.
% -> ModeAppMatrix(1,k) indicates the number of modes in which app k runs
% -> ModeAppMatrix(1+i,k) = j indicates that mode i is the
% jth mode in which app i runs.
ModeAppMatrix = zeros(numModes+1,numTotalApps);
for i = 1:numModes
    for j = 1:size(ModeApps{i}{MAI_TA},2)
        for k = 1:size(APPs,2)
            if strcmp(APPs{k}{AI_NM},ModeApps{i}{MAI_TA}{j})
                % count the number of modes in which app k runs
                ModeAppMatrix(1,k) = ModeAppMatrix(1,k) + 1;
                % mark that app k runs in mode i
                ModeAppMatrix(1+i,k) = ModeAppMatrix(1,k);
            end
        end
    end
end
% derive the app domain
% Step 2: for each app, two modes which are linked by the ModeConnectionMatrix
% are marked as belonging to the same scheduling domain. The smaller index
% is kept.
for i = 1:numTotalApps
    if ModeAppMatrix(1,i) > 1
        for j = 1:numModes
            for k = j+1:numModes
                if ModeAppMatrix(j+1,i) ~= 0 && ModeAppMatrix(k+1,i) ~= 0 && ModeConnectionMatrix(j,k) == 1
                    if (ModeAppMatrix(j+1,i) <= ModeAppMatrix(k+1,i))
                        ModeAppMatrix(k+1,i) = ModeAppMatrix(j+1,i);
                    else
                        ModeAppMatrix(j+1,i) = ModeAppMatrix(k+1,i);
                    end
                end
            end
        end
    end
end
% simplify the index - making more compact
% Step 3: for each app, the indexes of scheduling domains are reduced to be
% a continuous series of intergers starting by 1.
% Eg, [1,3,4] is turned into [1,2,3]
for i = 1:numTotalApps
%     Prun the 0's from each column
    appModes = ModeAppMatrix(2:numModes+1,i);
    appModesCompact = [];
    for j = 1:size(appModes,1)
        if appModes(j) > 0
            appModesCompact(size(appModesCompact,1)+1,1) = appModes(j);
        end
    end
%     Sort and remove duplicates (unique() includes sorting)
    appModesCompact = unique(appModesCompact);
%     Reduce the indexes of the scheduling domains, eg [1,3] is turned into
%     [1,2]
    for j = 2:numModes+1
        for k = 1:size(appModesCompact,1)
            if ModeAppMatrix(j,i) == appModesCompact(k)
                ModeAppMatrix(j,i) = k;
                break;
            end
        end
    end
end

% Step 4: Update the first row to indicate the number of scheduling domains
for i = 1:numTotalApps
    ModeAppMatrix(1,i) = max(ModeAppMatrix(1+1:1+numModes,i));
end
%%
% augment APPs, Tasks and Msgs
% Based on ModeAppMatrix, new applications are defined, along with new
% messages and tasks, added to the respective lists and allocated to the
% corresponding modes.
NewApps  = {};
NewTasks = {};
NewMsgs  = {};
NewCCs   = {};

for i = 1:numTotalApps
    if ModeAppMatrix(1,i) >= 2
        for j = ModeAppMatrix(1,i):-1:1
            if j ~= 1 % app belongs to multiple scheduling domains
                appName = APPs{i}{AI_NM};
                newAppDomain = APPs{i};
                newAppDomain{AI_NM} = strcat(newAppDomain{AI_NM},'_',num2str(j));
                newAppDomain{AI_ID} = size(APPs,2)+size(NewApps,2)+1;
                for k = 1:size(newAppDomain{AI_TC},2)
                    if strncmp(newAppDomain{AI_TC}{k},'T',1)
                        newTask = Tasks{findTaskByName(newAppDomain{AI_TC}{k},Tasks,1)};
                        currentTaskName = newTask{TI_NM};
                        newTask{TI_NM} = strcat(currentTaskName,'_',num2str(j));
                        % Verify that the newTask has not been created
                        % already (case of the same task belonging to
                        % multiple applications)
                        if ~findTaskByName(newTask{TI_NM},NewTasks,0) % Task not found
                            newTask{TI_ID} = size(Tasks,2)+size(NewTasks,2)+1;
                            NewTasks{size(NewTasks,2)+1} = newTask;
                            % Check whether the original task belongs to
                            % some custom constraints
                            for cc = 1:numel(CCs)
                                for term = 1:numel(CCs{cc}{CCI_LHS})
                                    if strcmp(...
                                            CCs{cc}{CCI_LHS}{term}{CCI_VAR}, ...
                                            currentTaskName)
                                        % Task found in CC, create a new
                                        newCC = CCs{cc};
                                        newCC{CCI_LHS}{term}{CCI_VAR} = newTask{TI_NM};
                                        CCs{numel(CCs)+1} = newCC;
                                    end
                                end
                            end
                        end
                    elseif strncmp(newAppDomain{AI_TC}{k},'M',1)
                        newMsg = Msgs{findMsgByName(newAppDomain{AI_TC}{k},Msgs,1)};
                        currentMsgName = newMsg{MI_NM};
                        newMsg{MI_NM} = strcat(currentMsgName,'_',num2str(j));
                        % Verify that the newMsg has not been created
                        % already (case of the same msg belonging to
                        % multiple applications)
                        if ~findMsgByName(newMsg{MI_NM},NewMsgs,0) % Msg not found
                            newMsg{MI_ID} = size(Msgs,2)+size(NewMsgs,2)+1;
                            NewMsgs{size(NewMsgs,2)+1} = newMsg;
                            % Check whether the original msg belongs to
                            % some custom constraints
                            for cc = 1:numel(CCs)
                                for term = 1:numel(CCs{cc}{CCI_LHS})
                                    if strcmp(...
                                            CCs{cc}{CCI_LHS}{term}{CCI_VAR}, ...
                                            currentMsgName)
                                        % Msg found in CC, create a new
                                        newCC = CCs{cc};
                                        newCC{CCI_LHS}{term}{CCI_VAR} = newMsg{MI_NM};
                                        CCs{numel(CCs)+1} = newCC;
                                    end
                                end
                            end
                        end
                    end
                    newAppDomain{AI_TC}{k} = strcat(newAppDomain{AI_TC}{k},'_',num2str(j));
                end
                NewApps{size(NewApps,2)+1} = newAppDomain;
                for k = 2:size(ModeAppMatrix,1)
                    if ModeAppMatrix(k,i) == j
                        for l = 1:size(ModeApps{k-1}{MAI_TA},2)
                            if strcmp(ModeApps{k-1}{MAI_TA}{l}, appName)
                                % Update the application name in ModeApps
                                ModeApps{k-1}{MAI_TA}{l} = strcat(appName,'_',num2str(j));
                                break;
                            end
                        end
                    end
                end
            elseif j == 1 % app belongs to a single scheduling domain
                
                % Don't add any new app/task/msg, just update the names
                % But is it needed? Messes up with my life if tasks/msgs
                % belong to more than one app...
                % -> Seems that it can be removed... 
                
%                 APPs{i}{AI_NM} = strcat(APPs{i}{AI_NM},'_',num2str(j));
%                 for k = 2:size(ModeAppMatrix,1)
%                     if ModeAppMatrix(k,i) == j
%                         for l = 1:size(ModeApps{k-1}{MAI_TA},2)
%                             if strcmp(ModeApps{k-1}{MAI_TA}{l}, appName)
%                                 % Update the application name in ModeApps
%                                 ModeApps{k-1}{MAI_TA}{l} = strcat(appName,'_',num2str(j));
%                                 break;
%                             end
%                         end
%                     end
%                 end
%                 for k = 1:size(APPs{i}{AI_TC},2)
%                     if strncmp(APPs{i}{AI_TC}{k},'T',1)
%                         tid = findTaskByName(APPs{i}{AI_TC}{k},Tasks,1);
%                         Tasks{tid}{TI_NM} = strcat(Tasks{tid}{TI_NM},'_',num2str(j));
%                     elseif strncmp(APPs{i}{AI_TC}{k},'M',1)
%                         mid = findMsgByName(APPs{i}{AI_TC}{k},Msgs,1);
%                         Msgs{mid}{MI_NM} = strcat(Msgs{mid}{MI_NM},'_',num2str(j));
%                     end
%                     APPs{i}{AI_TC}{k} = strcat(APPs{i}{AI_TC}{k},'_',num2str(j));
%                 end
            end
        end
    end
end
% Append new app/task/msg/cc to the list
for i = 1:size(NewApps,2)
    APPs{size(APPs,2)+1} = NewApps{i};
end
for i = 1:size(NewTasks,2)
    Tasks{size(Tasks,2)+1} = NewTasks{i};
end
for i = 1:size(NewMsgs,2)
    Msgs{size(Msgs,2)+1} = NewMsgs{i};
end
% for i = 1:size(NewCCs,2)
%     CCs{size(CCs,2)+1} = NewCCs{i};
% end

%%
% derive the synthesis flow
% Create the complete description of the modes, including
% - the applications specified, possibly duplicated ones from previous step
% - the sets of free, legacy, and virtual legacy for each mode

% Step 1: initialize with a copy of the extended ModeApps
ModeAppSets = {}; 
% ModeAppSets is a copy of ModeApps with modes ordered by priority
for i = 1:numModes % prios
    for j = 1:numModes
        if ModeApps{j}{MAI_PR} == i
            ModeAppSets{i} = ModeApps{j};
        end
    end
end

%%
% generate free apps, legacy apps and virtual legacy apps

% Look for the applications that are specified in more than one mode.
% Such apps are called CommonApp
% (done after the reduction to single scheduling domains has ben performed)
% -> See notes in the header
TotalApps = {};         % List all app running in the different modes
TotalAppsCount= [];     % Count in how many modes it appears
for i = 1:size(ModeAppSets,2)
    for j = 1:size(ModeAppSets{i}{MAI_TA},2)
        appName = ModeAppSets{i}{MAI_TA}{j};
        found = false;
        for k = 1:size(TotalApps,2)
            if strcmp(appName,TotalApps{k})
                TotalAppsCount(k) = TotalAppsCount(k)+1;
                found = true;
                break;
            end
        end
        if false == found
            TotalAppsCount(size(TotalApps,2)+1) = 1;
            TotalApps{size(TotalApps,2)+1} = appName;
        end
    end
end

%% note: TotalApps is not 'ordered', APPs is. 
%%

CommonApps = {};       
% Keep only the app appearing more than once
for i = 1:size(TotalApps,2)
    if TotalAppsCount(i) > 1
        CommonApps{size(CommonApps,2)+1} = TotalApps{i};
    end
end
%%
% generate synthesis sequence
% Computation of the Free, Legacy and Virtual legacy application sets
% (based on the notion of Common App)
CommonAppsKnown = {};

% Standard case, use the concept of virtual legacy
for i = 1:size(ModeAppSets,2)
    ModeAppSets{i}{MAI_LA} = setAnd(ModeAppSets{i}{MAI_TA},CommonAppsKnown);
    ModeAppSets{i}{MAI_FA} = setDiff(ModeAppSets{i}{MAI_TA},ModeAppSets{i}{MAI_LA});
    ModeAppSets{i}{MAI_VA} = setDiff(CommonAppsKnown,ModeAppSets{i}{MAI_LA});
    CommonAppsKnown = setOr(CommonAppsKnown, setAnd(CommonApps,ModeAppSets{i}{MAI_FA}));
end


%% reductions of virtual apps
for i = 1:size(ModeAppSets,2)
    for j = 1:size(ModeAppSets{i}{MAI_VA},2)
        virtApp = ModeAppSets{i}{MAI_VA}{j};
        remain = false;
        for k = 1:size(ModeAppSets{i}{MAI_FA},2)
            freeApp = ModeAppSets{i}{MAI_FA}{k};
            appPair = {virtApp, freeApp};
            for l = i+1:size(ModeAppSets,2)
                if (size(setAnd(appPair,ModeAppSets{l}{MAI_LA}),2) == 2)
                    remain = true;
                    break;
                end
            end
        end
        if false == remain
            ModeAppSets{i}{MAI_VA}{j} = {};
        end
    end
    reducedVA = {};
    for j = 1:size(ModeAppSets{i}{MAI_VA},2)
        if false == isempty(ModeAppSets{i}{MAI_VA}{j})
            reducedVA{size(reducedVA,2)+1} = ModeAppSets{i}{MAI_VA}{j};
        end
    end
    ModeAppSets{i}{MAI_VA} = reducedVA;
end

end % end of function
