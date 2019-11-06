function set = setDiff(set1, set2)

set = {};
for i = 1:size(set1,2)
    found = false;
    for j = 1:size(set2,2)
        if strcmp(set1{i},set2{j})
            found = true;
            break;
        end
    end
    if (false == found)
        set{size(set,2)+1} = set1{i};
    end
end