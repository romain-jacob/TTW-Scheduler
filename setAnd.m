function set = setAnd(set1, set2)

set = {};
for i = 1:size(set2,2)
    found = false;
    for j = 1:size(set1,2)
        if strcmp(set1{j},set2{i})
            found = true;
            break;
        end
    end
    if (true == found)
        set{size(set,2)+1} = set2{i};
    end
end


