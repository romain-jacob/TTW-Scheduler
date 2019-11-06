function set = setOr(set1, set2)

set = set1;
for i = 1:size(set2,2)
    found = false;
    for j = 1:size(set1,2)
        if strcmp(set1{j},set2{i})
            found = true;
            break;
        end
    end
    if (false == found)
        set{size(set,2)+1} = set2{i};
    end
end