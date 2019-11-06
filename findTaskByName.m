function tid = findTaskByName(tnm, Tasks, assertFlag)

% task indices
TI_ID = 1;TI_NM = 2;TI_MP = 3;TI_ET = 4;TI_PD = 5;TI_NI = 6;

% init output
tid = 0;

for i = 1:size(Tasks,2)
    if (strcmp(tnm,Tasks{i}{TI_NM}))
        tid = i;
        return;
    end
end

if (assertFlag)
    assert(false,'Task can not be found: %s', tnm)
end

end