function noConflict = detectConflict(APs)

globalVarDec;

noConflict = true;

for i = 1:size(APs,2)
    for j = 1:size(APs{i}{API_MP},2)-1
        for k = j+1:size(APs{i}{API_MP},2)
            if (APs{i}{API_MP}{j}{2}(2) > APs{i}{API_MP}{k}{2}(1) ...
            && APs{i}{API_MP}{k}{2}(2) > APs{i}{API_MP}{j}{2}(1))
            	noConflict = false;
                fprintf('Collision\n');
                APs{i}{API_NM}
                APs{i}{API_MP}{j}{1}
                APs{i}{API_MP}{j}{k}
            end
        end
    end
end