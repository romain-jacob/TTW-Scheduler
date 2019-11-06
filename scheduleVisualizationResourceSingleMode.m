%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% scheduleVisualizationResourceSingleMode.m
% Function to visualize the schedules according to resource for each mode
% Input:
% - id - mode id
% - priority - mode priority
% - taskSchedules - task schedules of the current mode
% - msgSchedules - message schedules of the current mode
% - roundSchedules - round schedules of the current mode
% - APs - processors
% - APPs - set of applications of the current mode
% - Tasks - set of tasks of the current mode
% - Msgs - set of messages of the current mode
% - LCM - length of the hyper period for the current mode
% - numLCM - number of hyper periods to plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, last update 06.01.16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function scheduleVisualizationResourceSingleMode(id, priority, taskSchedules, msgSchedules, roundSchedules, APs, APPs, Tasks, Msgs, LCM, numLCM, TotalTasks, CommonTaskSchedules)
%%
% global index declaration
globalVarDec;
%%
% initialize figure
figure;
titleStr = strcat('Static schedule of mode[', num2str(id), '] of prio ', num2str(priority));
title(titleStr);
hold on;
%%
% axis bases
roundBase = -1;
msgBase = -1;
taskBase = -1;
axisCap = -1;
%%
% preprocessing
%%
% assign the periods and num of instances to tasks and messages
for i = 1:size(APPs,2)
    for j = 1:size(APPs{i}{AI_TC},2)
        if (true == strncmp('T',APPs{i}{AI_TC}{j},1))
            for k = 1:size(Tasks,2)
                if (true == strcmp(APPs{i}{AI_TC}{j},Tasks{k}{TI_NM}))
                    Tasks{k}{TI_PD} = APPs{i}{AI_PD};
                    break;
                end
            end
        elseif (true == strncmp('M',APPs{i}{AI_TC}{j},1))
            for k = 1:size(Msgs,2)
                if (true == strcmp(APPs{i}{AI_TC}{j},Msgs{k}{MI_NM}))
                    Msgs{k}{MI_PD} = APPs{i}{AI_PD};
                    break;
                end
            end
        end
    end
end
%%
% map tasks onto APs
for i = 1:size(Tasks,2)
    ap = Tasks{i}{TI_MP};
    found = false;
    for j = 1:size(APs,2)
        if (true == strcmp(ap,APs{j}{API_NM}))
            APs{j}{API_MP}{size(APs{j}{API_MP},2)+1} = i;
            found = true;
            break;
        end
    end
    assert(true == found,'Error: wrong mapping');
end
%%
% plot the rounds
roundBase = 0;
text(0,roundBase,'Rounds', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
for i = 1:size(roundSchedules,2)
    B = roundSchedules{i}{RSI_FL};
    for p = 1:numLCM
        if (B == 0)
            rectangle('Position', [LCM*(p-1)+roundSchedules{i}{RSI_OS}, roundBase, T_per_slot/10, 0.5], 'FaceColor', 'g');
        end
        for j = 1:B
            rectangle('Position', [LCM*(p-1)+roundSchedules{i}{RSI_OS}+(j-1)*T_per_slot, roundBase, T_per_slot, 0.5], 'FaceColor', 'b');
            roundLabel = '';
            for k = 1:size(roundSchedules{i}{RSI_MS},2)
                roundLabel = strcat(roundLabel,roundSchedules{i}{RSI_MS}{k},',');
            end
            text(LCM*(p-1)+roundSchedules{i}{RSI_OS},roundBase+0.5,roundLabel, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
        end
    end
end
%%
% plot the messages
msgBase = 1;
text(0,msgBase,'Msgs', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom','Interpreter', 'none');
for i = 1:size(Msgs,2)
    mid = i;
    mni = LCM/Msgs{mid}{MI_PD};
    mpd = Msgs{mid}{MI_PD};
%     fprintf(strcat(Msgs{mid}{MI_NM},'[',num2str(mni),'], PD = ',num2str(mpd), ', OS = ', num2str(msgSchedules{mid}{MSI_OS}) ,', DL = ', num2str(msgSchedules{mid}{MSI_DL}), '\n'));
    for p = 1:numLCM
        for k = 1:mni
            rectangle('Position', [LCM*(p-1)+msgSchedules{mid}{MSI_OS}+(k-1)*mpd,msgBase+i-1,msgSchedules{mid}{MSI_DL},0.5], 'FaceColor', 'c');
            text(LCM*(p-1)+msgSchedules{mid}{MSI_OS}+(k-1)*mpd,msgBase+i-1,strcat(Msgs{mid}{MI_NM},'(', num2str(k),')'), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
        end
    end
    if (msgSchedules{mid}{MSI_OS}+msgSchedules{mid}{MSI_DL}>mpd)
        rectangle('Position', [max(0,msgSchedules{mid}{MSI_OS}-mpd),msgBase+i-1,min(msgSchedules{mid}{MSI_DL},msgSchedules{mid}{MSI_OS}+msgSchedules{mid}{MSI_DL}-mpd),0.5], 'FaceColor', 'c');
        text(max(0,msgSchedules{mid}{MSI_OS}-mpd),msgBase+i-1,strcat(Msgs{mid}{MI_NM},'(', num2str(mni),')'), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
    end
end
%%
% plot the task schedules
taskBase = 1+size(Msgs,2);
for i = 1:size(APs,2)
    text(0,taskBase+i-1,APs{i}{API_NM}, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
    plot([0,numLCM*LCM],[taskBase+i-1,taskBase+i-1],'k:');
    for j = 1:size(APs{i}{API_MP},2)
        tid = APs{i}{API_MP}{j};
        tni = LCM/Tasks{tid}{TI_PD};
        tpd = Tasks{tid}{TI_PD};
        tet = Tasks{tid}{TI_ET};
        isCommonTask = false;
        for k = 1:size(CommonTaskSchedules,2)
            if strcmp(CommonTaskSchedules{k}{TSI_NM},Tasks{tid}{TI_NM})
                isCommonTask = true;
                break;
            end
        end
%         fprintf(strcat(Tasks{tid}{TI_NM},'[',num2str(tni),'], PD = ',num2str(mpd), ', OS = ', num2str(taskSchedules{tid}{TSI_OS}) , '\n'));
        for p = 1:numLCM
            for k = 1:tni
                rectangle('Position', [LCM*(p-1)+taskSchedules{tid}{TSI_OS}+(k-1)*tpd,taskBase+i-1,tet,0.5], 'FaceColor', 'g');
                text(LCM*(p-1)+taskSchedules{tid}{TSI_OS}+(k-1)*tpd,taskBase+i-1,strcat(Tasks{tid}{TI_NM},'(', num2str(k),')'), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
            end
        end
        if (taskSchedules{tid}{TSI_OS}+tet>tpd)
            rectangle('Position', [max(0,taskSchedules{tid}{TSI_OS}-tpd),taskBase+i-1,min(tet,taskSchedules{tid}{TSI_OS}+tet-tpd),0.5], 'FaceColor', 'g');
            text(max(0,taskSchedules{tid}{TSI_OS}-tpd),taskBase+i-1,strcat(Tasks{tid}{TI_NM},'(', num2str(tni),')'), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
        end
    end
end
%%
% plot hyperperiod
height = taskBase + size(APs,2);
for p = 0:numLCM
    plot([p*LCM,p*LCM],[0,height],'k:');
end
%%
% adjust axis
axisCap = taskBase + size(APs,2);
axis([0,LCM*numLCM,0,axisCap]);