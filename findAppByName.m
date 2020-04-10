function appid = findAppByName(appnm, APPs, assertFlag)

% app indices
AI_ID = 1;AI_NM = 2;AI_PD = 3;AI_DL = 4;AI_TC = 5;AI_NI = 6;
% init output
appid = -1;

for i = 1:size(APPs,2)
    if (strcmp(appnm,APPs{i}{AI_NM}))
        appid = i;
        return;
    end
end

if (assertFlag)
    assert(false,'App can not be found: %s', appnm)
end