%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% scheduleVisualizationAppSingleMode.m
% Function to visualize the schedules according to applications for each
% mode
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
function scheduleVisualizationAppSingleMode(id, priority, taskSchedules, msgSchedules, roundSchedules, APs, APPs, Tasks, Msgs, LCM, numLCM)
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
% initialize axis bases
roundBase = -1;
appBase = -1;
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
% plot the applications
appBase = 1;
for i = 1:size(APPs,2)
    text(0,appBase+i-1,APPs{i}{AI_NM}, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
    for j = 1:size(APPs{i}{AI_TC},2)
        if (strncmp('T',APPs{i}{AI_TC}{j},1))
            tid = -1;
            tni = -1;
            tpd = -1;
            tet = -1;
            for q = 1:size(Tasks,2)
                if (strcmp(APPs{i}{AI_TC}{j},Tasks{q}{TI_NM}))
                    tid = q;
                    tni = LCM/Tasks{tid}{TI_PD};
                    tpd = Tasks{tid}{TI_PD};
                    tet = Tasks{tid}{TI_ET};
                    break;
                end
            end
%             fprintf('App [%d]: %s, %d chain comp: task [%d]: %s, pd = %f, et = %f, ni = %d\n', ...
%             i, APPs{i}{AI_NM}, j, tid, Tasks{tid}{TI_NM}, tpd, tet, tni);
            for p = 1:numLCM
                for k = 1:tni
                    rectangle('Position', [LCM*(p-1)+taskSchedules{tid}{TSI_OS}+(k-1)*tpd,appBase+i-1,tet,0.5], 'FaceColor', 'g');
                    text(LCM*(p-1)+taskSchedules{tid}{TSI_OS}+(k-1)*tpd,appBase+i-1,strcat(Tasks{tid}{TI_NM},'(', num2str(k),')'), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
                end
            end
            if (taskSchedules{tid}{TSI_OS}+tet>tpd)
                rectangle('Position', [max(0,taskSchedules{tid}{TSI_OS}-tpd),appBase+i-1,min(tet,taskSchedules{tid}{TSI_OS}+tet-tpd),0.5], 'FaceColor', 'g');
                text(max(0,taskSchedules{tid}{TSI_OS}-tpd),appBase+i-1,strcat(Tasks{tid}{TI_NM},'(', num2str(tni),')'), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
            end
            % plot start and end time
            if (1==j)
                for p = 1:numLCM
                    for k = 1:tni
                        plot([LCM*(p-1)+taskSchedules{tid}{TSI_OS}+(k-1)*tpd,LCM*(p-1)+taskSchedules{tid}{TSI_OS}+(k-1)*tpd],[appBase+i-0.5,appBase+i-0.25],'b','LineWidth',1);
                    end
                end
            elseif (size(APPs{i}{AI_TC},2)==j)
                for p = 1:numLCM
                    for k = 1:tni
                        plot([LCM*(p-1)+taskSchedules{tid}{TSI_OS}+(k-1)*tpd+tet,LCM*(p-1)+taskSchedules{tid}{TSI_OS}+(k-1)*tpd+tet],[appBase+i-1.25,appBase+i-1],'r','LineWidth',1)
                    end
                end
            end
        elseif (strncmp('M',APPs{i}{AI_TC}{j},1))
            mid = -1;
            mni = -1;
            mpd = -1;
            for q = 1:size(Msgs,2)
                if (strcmp(APPs{i}{AI_TC}{j},Msgs{q}{MI_NM}))
                    mid = q;
                    mni = LCM/Msgs{mid}{MI_PD};
                    mpd = Msgs{mid}{MI_PD};
                    break;
                end
            end
%             fprintf('App [%d]: %s, %d chain comp: msg [%d]: %s, pd = %f, ni = %d\n', ...
%             i, APPs{i}{AI_NM}, j, mid, Msgs{mid}{MI_NM}, mpd, mni);
            for p = 1:numLCM
                for k = 1:mni
                    rectangle('Position', [LCM*(p-1)+msgSchedules{mid}{MSI_OS}+(k-1)*mpd,appBase+i-1,msgSchedules{mid}{MSI_DL},0.5], 'FaceColor', 'c');
                    text(LCM*(p-1)+msgSchedules{mid}{MSI_OS}+(k-1)*mpd,appBase+i-1,strcat(Msgs{mid}{MI_NM},'(', num2str(k),')'), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
                end
            end
            if (msgSchedules{mid}{MSI_OS}+msgSchedules{mid}{MSI_DL}>mpd)
                rectangle('Position', [max(0,msgSchedules{mid}{MSI_OS}-mpd),appBase+i-1,min(msgSchedules{mid}{MSI_DL},msgSchedules{mid}{MSI_OS}+msgSchedules{mid}{MSI_DL}-mpd),0.5], 'FaceColor', 'c');
                text(max(0,msgSchedules{mid}{MSI_OS}-mpd),appBase+i-1,strcat(Msgs{mid}{MI_NM},'(', num2str(mni),')'), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
            end
        end
    end
end
%%
% plot hyperperiod
height = appBase + size(APPs,2);
for p = 0:numLCM
    plot([p*LCM,p*LCM],[0,height],'k:');
end
%%
% adjust axis
axisCap = appBase + size(APPs,2);
axis([0,LCM*numLCM,0,axisCap]);