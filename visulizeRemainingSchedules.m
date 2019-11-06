function visulizeRemainingSchedules(APs)

globalVarDec;

figure;
for i = 1:size(APs,2)
    text(0,i-1,APs{i}{API_NM}, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
    for j = 1:size(APs{i}{API_MP},2)
        taskName = APs{i}{API_MP}{j}{1};
        taskTime = APs{i}{API_MP}{j}{2};
        rectangle('Position', [taskTime(1),i-1,taskTime(2)-taskTime(1),0.5], 'FaceColor', 'g');
        text(taskTime(1),i-1,taskName, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
    end
end