function mid = findMsgByName(mnm, Msgs, assertFlag)

% msg indices
MI_ID = 1;MI_NM = 2;MI_PD = 3;MI_NI = 4;MI_LD = 5;

% init output
mid = 0;

for i = 1:size(Msgs,2)
    if (strcmp(mnm,Msgs{i}{MI_NM}))
        mid = i;
        return;
    end
    
end

if (assertFlag)
    assert(false,'Msg can not be found: %s', mnm);
end
end