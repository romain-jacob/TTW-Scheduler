function result = isInSet(element, set)

result = false;
for i = 1:size(set,2)
    if strcmp(element,set{i})
        result = true;
        break;
    end
end