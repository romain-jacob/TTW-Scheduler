function scheduleVisualizationResourceReservedTasks(APs, TotalTasks, CommonTaskSchedules, taskBase, LCM, numLCM)

globalVarDec;

for i = 1:size(CommonTaskSchedules,2)
    tid = CommonTaskSchedules{i}{TSI_ID};
    tnm = CommonTaskSchedules{i}{TSI_NM};
    tni = -1;
    tpd = -1;
    tet = -1;
    tmp = '';
    taxis = -1;
    for j = 1:size(TotalTasks,2)
        if strcmp(TotalTasks{j}{TI_NM},CommonTaskSchedules{i}{TSI_NM});
            tni = LCM/TotalTasks{j}{TI_PD};
            if tni < 1 % in case the period is larger than LCM of the mode
                tni = 1;
            end
            tpd = TotalTasks{j}{TI_PD};
            tet = TotalTasks{j}{TI_ET};
            tmp = TotalTasks{j}{TI_MP};
            break;
        end
    end
    for j = 1:size(APs,2)
        if strcmp(APs{j}{API_NM}, tmp)
            taxis = taskBase + j - 1;
            break;
        end
    end
    for p = 1:numLCM
        for k = 1:tni
            rectangle('Position', [LCM*(p-1)+CommonTaskSchedules{i}{TSI_OS}+(k-1)*tpd,taxis+0.5,tet,0.5], 'FaceColor', 'r');
            text(LCM*(p-1)+CommonTaskSchedules{i}{TSI_OS}+(k-1)*tpd,taxis+0.5,strcat(CommonTaskSchedules{i}{TSI_NM},'(', num2str(k),')'), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
        end
    end
end
