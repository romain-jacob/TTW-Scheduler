%%
%generate the modes
appsAvailableRange = [1,20]; % keep the 1 unchanged
numModes = 5;
numAppsPerModeRange = [4,8];
Modes = {};
for i = 1:numModes
    Modes{i} = [];
    numApps = randi(numAppsPerModeRange);
    for j = 1:numApps
        newApp = randi(appsAvailableRange);
        while (sum(Modes{i}==newApp)>0)
            newApp = randi(appsAvailableRange);
        end
        Modes{i}(j) = newApp;
    end
end

%%
% collect all common applications
appCount = zeros(1,appsAvailableRange(2));
for i = 1:numModes
    for j = 1:size(Modes{i},2)
        appCount(Modes{i}(j)) = appCount(Modes{i}(j)) + 1; 
    end
end
commonApps = [];
for i = 1:size(appCount,2)
    if (appCount(i) > 1)
        commonApps(size(commonApps,2)+1) = i;
    end
end

%%
% generate mode priorities
prios = 1:numModes;
priosPerm = perms(prios);
prioModes = priosPerm(randi([1,size(priosPerm,1)]),:);
modeOrder = [1:numModes;prioModes];
modeOrder = sortrows(modeOrder',2)';
modeOrder = modeOrder(1,:);

%%
% synthesis flow
synFlow = {};
legacyAppsPool = [];
% synFlow = {Mode id, legacy app, free app, virtual legacy app}
for i = 1:size(modeOrder,2)
    synFlow{i}{1} = modeOrder(i);
    legApps = intersect(Modes{modeOrder(i)},legacyAppsPool);
    freeApps = setdiff(Modes{modeOrder(i)},legApps);
    virLegApps = setdiff(legacyAppsPool,legApps);
    synFlow{i}{2} = legApps;
    synFlow{i}{3} = freeApps;
    synFlow{i}{4} = virLegApps;
    legacyAppsPool = union(legacyAppsPool,intersect(Modes{modeOrder(i)},commonApps));
end

%%
% mode transitions
% modeTrans = {old mode, new mode, unchanged apps, completed apps, added apps}
modeTrans = {};
for i = 1:numModes
    for j = 1:numModes
        if (j~=i)
            ucApps = intersect(Modes{i},Modes{j});
            comApps = setdiff(Modes{i}, ucApps);
            addApps = setdiff(Modes{j}, ucApps);
            modeTrans{size(modeTrans,2)+1} = {i,j,ucApps,comApps,addApps};
        end
    end
end

%%
% generate inputs for the synthesis
% configModes = {mode id, APs, APPs, Tasks, Msgs}
configModes = {};
for i = 1:numModes
    smApps = {};
    smTasks = {};
    smMsgs = {};
    for j = 1:size(Modes{i},2) % create the applications
        smApps{j} = APPsSet{Modes{i}(j)};
    end
    for j = 1:size(smApps,2)
        for k = 1:size(smApps{j}{AI_TC},2)
            if (strncmp(smApps{j}{AI_TC}{k},'T',1))
                tid = findTaskByName(smApps{j}{AI_TC}{k},TasksSet);
                smTasks{size(smTasks,2)+1} = TasksSet{tid};
            elseif (strncmp(smApps{j}{AI_TC}{k},'M',1))
                mid = findMsgByName(smApps{j}{AI_TC}{k},MsgsSet);
                smMsgs{size(smMsgs,2)+1} = MsgsSet{mid};
            end
        end
    end
    configModes{i} = {i, APsSet,smApps,smTasks,smMsgs};
end


