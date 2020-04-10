%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% synthesizeSchedulesMultiMode.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to synthesize schedules for each single mode. It does the
% following:
% - preprocess the input to obtain all the constraints
% - compute the minimal and maximal number of round needed
% - go through each discrete number of rounds and synthesize the feasible
% schedules, break if a valid schedule set can be found
% - formulate an ILP problem based on the constraints and fill the A,
% B(rhs) matrices
% - call the solver to solve the problem
% - format output if a valid schedule set can be found
% 
% - to minimize the constraints in lower-priority modes, the messages
% schedules are made as "wide" as possible. This is realized by setting the
% sum of the message deadlines as objective function.
%
% CURRENTLY ASSUMES ONE CHAIN PER APPLICATION!!!
%   + 31.05-19: It is not clear is it makes sense to try to change this, or
%   if we just rename "applications" as "chains" and be done with it...
% 
% Comments
% - Demand function is now defined as a ceil function. This induces that
% finishing at the deadline is considered meeting the deadline. It concels
% the need for the Cnet- trick, and makes explanations neater.
% 
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input:
% - APs - set of processors
% - APPs - application set for the current mode
% - Tasks - task set for the current mode
% - Msgs - message set for the current mode
% - LegAppTaskSchedules - legacy apps including the task schedules
% - VirtLegAppTasks - set of virtual legacy app tasks
% - VirtLegAppTaskSchedules - task schedules for the virtual legacy apps
% - LegAppMsgSchedules - legacy apps including the message schedules
% - VirtLegAppMsgs - set of virtual legacy app messages
% - VirtLegAppMsgSchedules - message schedules for the virtual legacy apps
% - VirtCollisionTaskPairs - set of tasks belonging to one colliding app
% pairs, which are mapped on the same processing unit
% - CommonMsgs - set of common messages
% Output:
% - solved - whether the problem is solved
% - roundSchedulesSingleMode - round schedules for the current mode
% - taskSchedulesSingleMode - task schedules for the current mode
% - msgSchedulesSingleMode - message schedules for the current mode
% - hyperPeriodSingleMode - hyper period for the current mode
% - runtimeSolver - global solving time for the mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, Romain Jacob, last update 03.06.19
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% TODO
%   - Update top file description

%% Log
% 
% 07.04.2020 
%  + round offset changed to integer (for compatibility with the implementation)
% 
% 19.06.19:
%  + added support for custom constraints
% 
% 18.06.19:
%  + Supressed the constraint of forcing one round to start at t=0. This
%  may add an (useless) extra round due to inheritance.
% 
% 03.06.19:
%  + Improved support for modes without messages to send.
%    - A "keep-alive" application is run by all the nodes. In practive,
%    this is used to maintain time synchronization in the network. The
%    periodicity of this APP is set to T_max: the maximal inter-round
%    interval. The load of the keep-alive message is then set to 0.
%    - TODO: debug to get it working with ANY load. At the moment, works
%    only with load of 1 and 0.
%
% 31.05.19: 
%  + added support for single-task application
%  + added support for modes without message transfer 
% (to be improved -> currently schedule one per the hyperperiod...) DONE,
% see log of (03.06.19)

%%
function [solved, iis, roundSchedulesSingleMode, taskSchedulesSingleMode, msgSchedulesSingleMode, hyperPeriodSingleMode, runtimeSolver] = synthesizeSchedulesMultiModeFull(APs, APPs, Tasks, Msgs, CCs, LegAppTaskSchedules, VirtLegAppTasks, VirtLegAppTaskSchedules, LegAppMsgSchedules, VirtLegAppMsgs, VirtLegAppMsgSchedules, VirtCollisionTaskPairs, CommonMsgs, compute_iis)
%%
% global index declaration
globalVarDec;


%%
% initialize output
solved = false;
roundSchedulesSingleMode = {};
taskSchedulesSingleMode = {};
msgSchedulesSingleMode = {};
hyperPeriodSingleMode = -1;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Preprocessing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
% preprocess for co-scheduling
%% find the LCM of the system and the number of instances for each application within the hyperperiod
% Note: The instance values are not returned...
periods = [];
for i = 1:size(APPs,2)
    periods(i) = APPs{i}{AI_PD};
end
LCM = lcmVec(periods);
hyperPeriodSingleMode = LCM;
for i = 1:size(APPs,2)
    APPs{i}{AI_NI} = LCM/APPs{i}{AI_PD};
end
%% collect legacy task schedules
% Double vector countaining [legTask ID, legTask offset]
legTaskSchedules = [];
for i = 1:size(LegAppTaskSchedules,2)   % i : index of the legTask
    for j = 1:size(Tasks,2)             % j : index of the corresponding Task
        if strcmp(Tasks{j}{TI_NM},LegAppTaskSchedules{i}{TSI_NM});
            legTaskSchedules(i,:) = [j,LegAppTaskSchedules{i}{TSI_OS}];
            break;
        end
    end
end

numLegTasks = size(legTaskSchedules,1);

%% collect virtual legacy tasks
% Both VirtLegAppTasks and VirtLegAppTaskSchedules are outputs from the
% preprocessing step. This test verifies that each task marked as VL as
% been scheduled previously.
assert(size(VirtLegAppTasks,2) == size(VirtLegAppTaskSchedules,2));
VirTasks = VirtLegAppTasks;

%% add virtual tasks into the task list
%
numNormalTasks = size(Tasks,2);
numVirTasks = size(VirTasks,2);
% Double vector countaining [virtTask ID, virtTask offset]
virTaskSchedules = [];
for i = 1:size(VirTasks,2)
%     Appends the virtual tasks to the task list of the current mode
    Tasks{numNormalTasks+i} = VirTasks{i};
%     Fill virTaskSchedules
    virTaskSchedules(i,:) = [numNormalTasks+i, VirtLegAppTaskSchedules{i}{TSI_OS}];
end

%% collect legacy msg schedules
% Three columns vector countaining [legMsg ID, legMsg offset, legMsg deadline]
legMsgSchedules = [];
for i = 1:size(LegAppMsgSchedules,2)
    for j = 1:size(Msgs,2)
        if strcmp(Msgs{j}{MI_NM},LegAppMsgSchedules{i}{MSI_NM})
            legMsgSchedules(i,:) = [j,LegAppMsgSchedules{i}{MSI_OS}, LegAppMsgSchedules{i}{MSI_DL}];
            break;
        end
    end
end
numLegMsgs = size(legMsgSchedules,1);

%% assign the periods and num of instances to tasks and messages
%
for i = 1:size(APPs,2)
    for j = 1:size(APPs{i}{AI_TC},2)
        if (true == strncmp('T',APPs{i}{AI_TC}{j},1))
            for k = 1:size(Tasks,2)
                if (true == strcmp(APPs{i}{AI_TC}{j},Tasks{k}{TI_NM}))
                    Tasks{k}{TI_PD} = APPs{i}{AI_PD};
                    Tasks{k}{TI_NI} = APPs{i}{AI_NI};
                    break;
                end
            end
        elseif (true == strncmp('M',APPs{i}{AI_TC}{j},1))
            for k = 1:size(Msgs,2)
                if (true == strcmp(APPs{i}{AI_TC}{j},Msgs{k}{MI_NM}))
                    Msgs{k}{MI_PD} = APPs{i}{AI_PD};
                    Msgs{k}{MI_NI} = APPs{i}{AI_NI};
                    break;
                end
            end
        end
    end
end

%% map tasks onto APs
% For each task, look for the AP on which the task has been mapped. Once
% found, add the task to the AP mapping list.
for i = 1:numNormalTasks
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

%% find collision pairs
% If more than one task is mapped to the same AP, the task jobs must not
% collide
for i = 1:size(APs,2)
    for j = 1:size(APs{i}{API_MP},2)
        for k = j+1:size(APs{i}{API_MP},2)
            %current ID of the first colliding task
            ctj_id = APs{i}{API_MP}{j};
            %current ID of the second colliding task
            ctk_id = APs{i}{API_MP}{k};
            taskPairLCM = lcm(Tasks{ctj_id}{TI_PD},Tasks{ctk_id}{TI_PD});
            
            %instances number of colliding tasks 
%             There will be two constraints to formulate in the ILP 
%             per pairs of job of colliding tasks
            ctj_ni = taskPairLCM/Tasks{ctj_id}{TI_PD};
            ctk_ni = taskPairLCM/Tasks{ctk_id}{TI_PD};
            for p = 1:ctj_ni
                for q = 1:ctk_ni
                    APs{i}{API_CP}{size(APs{i}{API_CP},2)+1} = [ctj_id, p, ctk_id, q];
                end
            end
        end
    end
end

%% collect collision pairs and task chains
% CP = [task 1 id, task 1 instance, task 2 id, task 2 instance]
% Browse all APs and store all collision pairs in a single array for ease 
% of access later on
CPs = {};
for i = 1:size(APs,2)
    for j = 1:size(APs{i}{API_CP},2)
        CPs{size(CPs,2)+1} = APs{i}{API_CP}{j};
    end
end

%% add also potential task collision between VA tasks and FA tasks
% VirtCollisionTaskPairs as a list of tuples of form
%     { Task ID from the virtual legacy app, previously scheduled ,
%       Task ID from the free app, about to be scheduled ,
%       Processing unit on which the two are colliding }
numNormalCPs = size(CPs,2);
for i = 1:size(VirtCollisionTaskPairs,2)
%     Find the index of the colliding tasks in the current mode
    tid1 = -1;
    tid2 = -1;
%     .. the virtual app task
    for j = 1:size(Tasks,2)
        if strcmp(VirtCollisionTaskPairs{i}{1},Tasks{j}{TI_NM})
            tid1 = j;
            break;
        end
    end
%     .. the free app task
    for j = 1:size(Tasks,2)
        if strcmp(VirtCollisionTaskPairs{i}{2},Tasks{j}{TI_NM})
            tid2 = j;
            break;
        end
    end
    
%instances number of colliding tasks 
%       There will be two constraints to formulate in the ILP 
%       per pairs of job of colliding tasks
    taskPairLCM = lcm(Tasks{tid1}{TI_PD},Tasks{tid2}{TI_PD});
    tni1 = taskPairLCM/Tasks{tid1}{TI_PD};
    tni2 = taskPairLCM/Tasks{tid2}{TI_PD};
    for p = 1:tni1
        for q = 1:tni2
            CPs{size(CPs,2)+1} = [tid1, p, tid2, q];
        end
    end
end

%% Extract the task chains of the current applications to be scheduled
% Used to formulate the precedence constraints in the ILP
% TC = {current type, current id, following type, following id}.
% Type: 1->task, 2->message
TCs = {};
for i = 1:size(APPs,2)
    TC = {};
    
    if (size(APPs{i}{AI_TC},2) == 1)
        
        % Single task case
        t_nm = APPs{i}{AI_TC}{1};
        t_id = 0;
        t_type = 1;
        for k = 1:size(Tasks,2)
            if (true == strcmp(Tasks{k}{TI_NM},t_nm))
                t_id = k;
                break;
            end
        end    
        TC{1} = [t_type, t_id];
        
    else
        
        % Standard case: sequence of tasks and message(s)
        for j = 1:size(APPs{i}{AI_TC},2)-1
            t1_nm = APPs{i}{AI_TC}{j};
            t2_nm = APPs{i}{AI_TC}{j+1};
            t1_id = 0;
            t2_id = 0;
            t1_type = 0;
            t2_type = 0;
            if (true == strncmp('T',t1_nm,1))
                t1_type = 1;
                for k = 1:size(Tasks,2)
                    if (true == strcmp(Tasks{k}{TI_NM},t1_nm))
                        t1_id = k;
                        break;
                    end
                end
            elseif (true == strncmp('M',t1_nm,1))
                t1_type = 2;
                for k = 1:size(Msgs,2)
                    if (true == strcmp(Msgs{k}{MI_NM},t1_nm))
                        t1_id = k;
                        break;
                    end
                end
            end
            if (true == strncmp('T',t2_nm,1))
                t2_type = 1;
                for k = 1:size(Tasks,2)
                    if (true == strcmp(Tasks{k}{TI_NM},t2_nm))
                        t2_id = k;
                        break;
                    end
                end
            elseif (true == strncmp('M',t2_nm,1))
                t2_type = 2;
                for k = 1:size(Msgs,2)
                    if (true == strcmp(Msgs{k}{MI_NM},t2_nm))
                        t2_id = k;
                        break;
                    end
                end
            end
            TC{size(TC,2)+1} = [t1_type, t1_id, t2_type, t2_id];
        end
    end
    
    % Store the TC info
    TCs{size(TCs,2)+1} = TC;
    
end

%% force the common msgs to be released and served in the same hyperperiod
% CM classifies the messages as Common messages or not. CM(i) = 1 indicates
% a common message. 
% In the ILP formulation, all common messages are constrained to be
% released and served within the same hyperperiod, in order to enable a
% safe switch between different modes.
CM = zeros(1,size(Msgs,2));
for i = 1:size(Msgs,2)
    isCommonMsg = false;
    for j = 1:size(CommonMsgs,2)
        if strcmp(Msgs{i}{MI_NM}, CommonMsgs{j})
            isCommonMsg = true;
            break;
        end
    end
    if true == isCommonMsg
        CM(i) = 1;
    end
end

%% compute the minimal and maximal number of rounds

% The minimal number of rounds is defined by
% - The total number of messages to send in the hyperperiod
% - The total number of message instances in the mode
% - The maximal time interval between two consecutive rounds (T_max)
 
% Collect and sum up all the message jobs and instances
% within the hyperperiod
numInsts = [];
numMsgs  = [];
for i = 1:size(Msgs,2)
    numInsts(i) = Msgs{i}{MI_NI};
    numMsgs(i) = Msgs{i}{MI_NI} * Msgs{i}{MI_LD};
end
% Compute the min number of rounds based on the load
R_min_load = ceil(sum(numMsgs)/B_max);

% Compute the min number of rounds based on the number of instances
% -> As deadline are smaller than period, for a given message, 
% each job must be scheduled in a different round
R_min_inst = max(numInsts);
if (isempty(R_min_inst ))
    R_min_inst = 0;
end

% Compute the min number of rounds based on the max inter-round interval
R_min_Tmax = ceil(LCM/T_max);

% Take the max
R_min = max(R_min_load, R_min_Tmax);
R_min = max(R_min, R_min_inst);

% Make sure there is at least one round
% -> This should be always the case, due to R_min_Tmax
if (isempty(R_min))
    R_min = 1; 
    fprintf('/!\\\n/!\\\n/!\\ Strange! There should be at least ')
    fprintf('one round due to the T_max constraint...\n/!\\\n/!\\\n')
end

% The maximal number of rounds is defined by 
% - The total number of messages to send in the hyperperiod, which sets the
% maximal number of rounds needed in case we have only one-slot rounds
% - The maximal time interval between two consecutive rounds (T_max)
% 
% Taking the sum of these two values is a safe upper-bound. In other words,
% if the problem is schedulable, a solution exists with at most 
% R_min_Tmax + R_min_load
R_max_load = sum(numMsgs);
R_max = R_min_Tmax + R_max_load;

% log min/max rounds
%%
% LOG BLOCK
if true == LOG_SIMPLE
    fprintf('========================================\n');
    fprintf('=== Synthesize Schedules ===\n');
    fprintf('--- Min/Max Rounds ---\n');
    fprintf('Min Rounds %d, Max Rounds %d\n', R_min, R_max);
end

%%
%&
%&
%&
%&
%&
%&
%&
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main synthesis loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%&
%&
%&
%&
%&
%&
%&
%%
% main loop
R = R_min;
runtimeSolver = 0;
while (R <= R_max)
    %%
    % LOG BLOCK
    if true == LOG_SIMPLE
        fprintf('--- Try for %d rounds ---\n', R);
    end
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % model formulation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    % the big M and small mm
    M = 10*LCM;     % used for the colliding tasks constraints 
                    % (required to capture the OR between the two
                    % constraints)
    mm = 0.0001;    % used for expressing strict inequalities 
                    % (the default behavior is '<=' )
%     mmm = 0.0001;   % used for Cnet^-

    %% computation of the matrix sizes
    % 
    N_t = size(Tasks,2);    % num tasks
    N_m = size(Msgs,2);     % num messages
    N_a = size(APPs,2);     % num applications
    N_cp = size(CPs,2);     % num collision pairs
    N_tc = 0;               % num elementary task chains, ie the number
                            % sequences [task,msg] or [msg,task] that
                            % belong to a task chained to be scheduled. For
                            % each of such basic chain, there is a
                            % precedence constraint to be formulated.
    for i = 1:size(TCs,2)
        if (size(TCs{i},2) ~= 1) % exclude the single task case (no precedence constraint)
            N_tc = N_tc + size(TCs{i},2);
        end
    end
    N_r = R; % num rounds
        
    %% number of variables
    NX_AT = N_t;    % task offset
    NX_CT = 2*N_m;  % msg offset and deadlines
    NX_DL = N_tc;   % sigma, capturing if the two components of an elementary 
                    % task chain starts in the same application period 
                    % (sigma = 0), or not (sigma = 1).
%                     This is necessary to formulate the precedence
%                     constraints, based on relative time offsets and not
%                     absolute time.
    NX_CP = N_cp;   % There are two constraints, and one of the two must be 
                    % satisfied. This boolean variable is used to describe
                    % which one of the two will be satisfied.
    NX_RD = N_r*(1+N_m)+N_m; 
                    % N_r*(offset, allocation vector),
                    % r_0, one per message
%                     r_j, B_{i,j}, B_{0,j}
    NX_EV = 2*N_r*N_m; 
                    % The help variable k^a_{i,j} and k^d_{i,j}, with i the
                    % messages and j the number or rounds
%                     ka(i,j), kd(i,j), ka(i+1,j), kd(i+1,j), ...
    NX = NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+NX_EV;
% Print for debugging purposes
%     NX, NX_AT,NX_CT,NX_DL,NX_CP,NX_RD,NX_EV;
    
    %% number of constraints
    MX_DL = N_tc+N_a;   % Deadline constraints. 
                        % One end-to-end per application, one precedence
                        % constraint per elementary task chain
    MX_CP = 2*N_cp;     % Colliding tasks on the same AP. One out of the two
                        % must be satisfied.
    MX_RD = 2*(N_r-1);  % Time difference between two rounds.
%                         One for lower bound, one for upper bound.
    MX_EV = N_r*(6*N_m+1); % Event Bound Constraints, for each round
%                         Upper and lower bound on the number of message
%                         jobs arrived up to the current round [2 const/msg]
%                         Upper and lower bound on the number of message
%                         jobs served up to the previous round [2 const/msg]
%                         Service after arrival [1 const/msg]
%                         Service before deadline [1 const/msg]
%                         No more slots allocated than available [1 const]
    MX_EC = N_m ;        % The correct number of message jobs are scheduled
    MX_LGT = numLegTasks + numVirTasks;
                    % For all tasks in legacy of virtual legacy, the offset
                    % must be set
%                     Why do we not need two constraints?
    MX_LGM = 2*numLegMsgs;
                    % For all msgs in legacy of virtual legacy, the offset
                    % and deadlines must be set
    MX_CM = sum(CM);    % Forcing the messages to be released and served 
                        % in the same hyperperiod
%                     CM classifies the messages as Common messages or not. 
%                     CM(i) = 1 indicates a common message. 
    MX_CC = numel(CCs);
    MX = MX_DL+MX_CP+MX_RD+MX_EV+MX_EC+MX_LGT+MX_LGM+MX_CM+MX_CC;
    
    
%     MX,MX_DL,MX_CP,MX_RD,MX_EV,MX_EC,MX_LGT,MX_LGM,MX_CM,MX_CC
    
    
    % initialize A and rhs
    A = zeros(MX,NX);
    rhs = zeros(MX,1);
    
    %
    %% formulating the constraints
    %
    NR_CONST_ACCU = 0;
    
    %% deadline constraint
    %
    constLocalAccu = 0;
    sigmaCount = 0;
    for i = 1:size(TCs,2)
        for j = 1:size(TCs{i},2)
            
            % precedence constraints ()
            
            if (size(TCs{i},2) == 1) 
                % Single task case -> no precendence constaints
                continue
            end
            
            sigmaCount = sigmaCount +1;
            if (1 == TCs{i}{j}(1) && 2 == TCs{i}{j}(3))
                tid = TCs{i}{j}(2);
                mid = TCs{i}{j}(4);
                constLocalAccu = constLocalAccu +1;
                A(NR_CONST_ACCU+constLocalAccu,tid) = 1;
                A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(mid-1)+1) = -1;
                A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+sigmaCount) = -Tasks{tid}{TI_PD};
                rhs(NR_CONST_ACCU+constLocalAccu) = -Tasks{tid}{TI_ET};
            elseif (2 == TCs{i}{j}(1) && 1 == TCs{i}{j}(3))
                mid = TCs{i}{j}(2);
                tid = TCs{i}{j}(4);
                constLocalAccu = constLocalAccu +1;
                A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(mid-1)+1) = 1;
                A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(mid-1)+2) = 1;
                A(NR_CONST_ACCU+constLocalAccu,tid) = -1;
                A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+sigmaCount) = -Msgs{mid}{MI_PD};
                rhs(NR_CONST_ACCU+constLocalAccu) = 0;
            else
                TCs{i}{j}(1) 
                TCs{i}{j}(3) 
                TCs{i}
                TCs{i}{j}
                i
                j
                assert(false,'Error');
            end
        end
        
        % end-to-end deadline constraint ()
        
        if (size(TCs{i},2) == 1)
            % Single task case
            tid = TCs{i}{1}(2);
            constLocalAccu = constLocalAccu +1;
    %         Deadline loose (t <= D)
            rhs(NR_CONST_ACCU+constLocalAccu) = APPs{i}{AI_DL} - Tasks{tid}{TI_ET};
    %         Deadline strict (t < D)
    %         rhs(NR_CONST_ACCU+constLocalAccu) = APPs{i}{AI_DL} - Tasks{tlid}{TI_ET} - mm;
    
        else
            % Regular task chain
            tfid = TCs{i}{1}(2);
            tlid = TCs{i}{size(TCs{i},2)}(4);
            constLocalAccu = constLocalAccu +1;
            A(NR_CONST_ACCU+constLocalAccu,tfid) = -1;
            A(NR_CONST_ACCU+constLocalAccu,tlid) = 1;
            for j = 1:size(TCs{i},2)
                A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+sigmaCount-size(TCs{i},2)+j) = APPs{i}{AI_PD}; % sigmas
            end
    %         Deadline loose (t <= D)
            rhs(NR_CONST_ACCU+constLocalAccu) = APPs{i}{AI_DL} - Tasks{tlid}{TI_ET};
    %         Deadline strict (t < D)
    %         rhs(NR_CONST_ACCU+constLocalAccu) = APPs{i}{AI_DL} - Tasks{tlid}{TI_ET} - mm;
            
        end
    end
    assert(constLocalAccu == MX_DL, 'Error: wrong number of constraints');
    assert(sigmaCount == NX_DL, 'Error: wrong number of variables');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    
    %% collision pair constraint
    %
    constLocalAccu = 0;
    for i = 1:size(CPs,2)
        ti_id = CPs{i}(1);
        k_i = CPs{i}(2);
        tj_id = CPs{i}(3);
        k_j = CPs{i}(4);
        
        %o_i + e_i + p_i*(k_i-1) + M*(lambda - 1) < o_j + p_j*(k_j-1)
        constLocalAccu = constLocalAccu + 1;
        A(NR_CONST_ACCU+constLocalAccu,ti_id) = 1;
        A(NR_CONST_ACCU+constLocalAccu,tj_id) = -1;
        A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+i) = M;
        rhs(NR_CONST_ACCU+constLocalAccu) = -Tasks{ti_id}{TI_ET}-Tasks{ti_id}{TI_PD}*(k_i-1)+Tasks{tj_id}{TI_PD}*(k_j-1)+M;
        
        %o_j + e_j + p_j*(k_j-1) < o_i + p_i*(k_i-1) + M*lambda
        constLocalAccu = constLocalAccu + 1;
        A(NR_CONST_ACCU+constLocalAccu,ti_id) = -1;
        A(NR_CONST_ACCU+constLocalAccu,tj_id) = 1;
        A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+i) = -M;
        rhs(NR_CONST_ACCU+constLocalAccu) = -Tasks{tj_id}{TI_ET}+Tasks{ti_id}{TI_PD}*(k_i-1)-Tasks{tj_id}{TI_PD}*(k_j-1);
        
    end
    assert(constLocalAccu == MX_CP, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    
    %% round constraints
    %
    constLocalAccu = 0;
    for j = 1:N_r-1
        constLocalAccu = constLocalAccu + 1;
        A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = 1;
        A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*j+1) = -1;
        % Replace Cnet by the dynamic round length
%         rhs(NR_CONST_ACCU+constLocalAccu) = -Cnet;
        rhs(NR_CONST_ACCU+constLocalAccu) = -T_per_round;
        for i = 1:N_m
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+i) = T_per_slot;
        end
                
        constLocalAccu = constLocalAccu + 1;
        A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = -1;
        A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*j+1) = 1;
        rhs(NR_CONST_ACCU+constLocalAccu) = T_max;
    end
    assert(constLocalAccu == MX_RD, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    
    %% event bound constraint
    % 
    constLocalAccu = 0;
    for j = 1:N_r
        for i = 1:N_m
            
            %% Served in round starting after arrival
            %rhs
            constLocalAccu = constLocalAccu+1;
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = 1; % r_j
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+1) = -1; % o_i
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+1) = -Msgs{i}{MI_PD}; % k^a_{i,j}*p_i
            rhs(NR_CONST_ACCU+constLocalAccu) = -mm;
            
            %lhs
            constLocalAccu = constLocalAccu+1;
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = -1; % r_j
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+1) = 1; % o_i
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+1) = Msgs{i}{MI_PD}; % k^a_{i,j}*p_i
            rhs(NR_CONST_ACCU+constLocalAccu) = Msgs{i}{MI_PD};
            
            %% Served in round finishing before deadline
            %rhs
%             constLocalAccu = constLocalAccu+1;
%             A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = 1; % r_j
%             A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+1) = -1; % o_i
%             A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+2) = -1; % d_i
%             A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+2) = -Msgs{i}{MI_PD}; % k^d_{i,j}*p_i
%             rhs(NR_CONST_ACCU+constLocalAccu) = - (Cnet-mmm) - mm;

% Test with a different definition of the demand function (in order to avoid the artefact of Cnet-)
% Demand function is defined as a ceil function. This induces that
% finishing at the deadline is considered meeting the deadline.
            constLocalAccu = constLocalAccu+1;
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = 1; % r_j
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+1) = -1; % o_i
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+2) = -1; % d_i
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+2) = -Msgs{i}{MI_PD}; % k^d_{i,j}*p_i
            % Replace Cnet by the dynamic round length
%         rhs(NR_CONST_ACCU+constLocalAccu) = -Cnet;
            rhs(NR_CONST_ACCU+constLocalAccu) = -T_per_round;
%             A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+NX_EV+j) = T_per_slot;
            for k = 1:N_m
                A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+k) = T_per_slot;
            end
            
            %lhs
%             constLocalAccu = constLocalAccu+1;
%             A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = -1; % r_j
%             A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+1) = 1; % o_i
%             A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+2) = 1; % d_i
%             A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+2) = Msgs{i}{MI_PD}; % k^d_{i,j}*p_i
%             rhs(NR_CONST_ACCU+constLocalAccu) = Msgs{i}{MI_PD} + (Cnet-mmm);
            
% Test with a different definition of the demand function (in order to avoid the artefact of Cnet-)
% Demand function is defined as a ceil function. This induces that
% finishing at the deadline is considered meeting the deadline.
            constLocalAccu = constLocalAccu+1;
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = -1; % r_j
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+1) = 1; % o_i
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+2) = 1; % d_i
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+2) = Msgs{i}{MI_PD}; % k^d_{i,j}*p_i
            % Replace Cnet by the dynamic round length
%             rhs(NR_CONST_ACCU+constLocalAccu) = Msgs{i}{MI_PD} + Cnet - mm;
            rhs(NR_CONST_ACCU+constLocalAccu) = Msgs{i}{MI_PD} + T_per_round - mm;
%             A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+NX_EV+j) = -T_per_slot;
            for k = 1:N_m
                A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+k) = -1*T_per_slot;
            end
            
            
            %%
            constLocalAccu = constLocalAccu+1;
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+2) = 1; % k^d
            for k = 1:j-1
                A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(k-1)+1+i) = -1; % sum B_{i,j}, 1...j-1
            end
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*N_r+i) = -1; % B_{i,0}
            rhs(NR_CONST_ACCU+constLocalAccu) = 0;
            
            constLocalAccu = constLocalAccu+1;
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+1) = -1; % k^a
            for k = 1:j
                A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(k-1)+1+i) = 1; % sum B_{i,j}, 1...j
            end
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*N_r+i) = 1; % B_{i,0}
            rhs(NR_CONST_ACCU+constLocalAccu) = 0;
        end
        
        constLocalAccu = constLocalAccu+1;
        for i = 1:N_m
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+i) = 1;
        end
%         A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+NX_EV+j) = 1;
        rhs(NR_CONST_ACCU+constLocalAccu) = B_max;
        
    end
    assert(constLocalAccu == MX_EV, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    
    %% event count constraint
    % All message jobs must have been allocated to a round.
    constLocalAccu = 0;
    for i = 1:N_m
        constLocalAccu = constLocalAccu+1;
        for j = 1:N_r
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+i) = 1;
        end
        rhs(NR_CONST_ACCU+constLocalAccu) = Msgs{i}{MI_NI}*Msgs{i}{MI_LD};
    end
    
%     for j = 1:N_r
%         constLocalAccu = constLocalAccu + 1;
%         for i = 1:N_m
%             A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+i) = 1; %B_j(i)
%         end
%         A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+NX_EV+j) = -1; %\hat{B}_j
%         rhs(NR_CONST_ACCU+constLocalAccu) = 0;
%     end
    
    assert(constLocalAccu == MX_EC, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    
    %% dealing with legacy tasks and virtual legacy tasks
    % legTaskSchedules -> Double vector countaining [legTask ID, legTask offset]
    constLocalAccu = 0; 
    for i = 1:numLegTasks
        constLocalAccu = constLocalAccu+1;
        % The index in legTaskSchedules(i,1) corresponds to the tasks
        % offset in A, because as the task offsets have been defined as the
        % first variables in the matrix
        A(NR_CONST_ACCU+constLocalAccu,legTaskSchedules(i,1)) = 1;
        rhs(NR_CONST_ACCU+constLocalAccu) = legTaskSchedules(i,2);
        %
        %% One constraint is enough to represent equality
        % This is set later on: each constraint can have its own "sign"
        % i.e. '<' , '>' or '='
        % Note that the inequalities are loose (<= and >=)
        %
    end
    % virTaskSchedules -> Double vector countaining [virtTask ID, virtTask offset]
    for i = 1:numVirTasks
        constLocalAccu = constLocalAccu+1;
        A(NR_CONST_ACCU+constLocalAccu,virTaskSchedules(i,1)) = 1;
        rhs(NR_CONST_ACCU+constLocalAccu) = virTaskSchedules(i,2);
        %
        %% One constraint is enough to represent equality
        % This is set later on: each constraint can have its own "sign"
        % i.e. '<' , '>' or '='
        % Note that the inequalities are loose (<= and >=)
        %
    end
    
    assert(constLocalAccu == MX_LGT, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    
    %% dealing with legacy msgs and virtual legacy msgs
    % Offset and deadline of legacy msgs are saved. 
    % Nothing is done with the virtual legacy msgs
    constLocalAccu = 0;
    for i = 1:numLegMsgs
        constLocalAccu = constLocalAccu+1;
        A(NR_CONST_ACCU+constLocalAccu , NX_AT+2*(legMsgSchedules(i,1)-1)+1) = 1;
        rhs(NR_CONST_ACCU+constLocalAccu) = legMsgSchedules(i,2);
        %
        %% One constraint is enough to represent equality
        % This is set later on: each constraint can have its own "sign"
        % i.e. '<' , '>' or '='
        % Note that the inequalities are loose (<= and >=)
        %
        
        constLocalAccu = constLocalAccu+1;
        A(NR_CONST_ACCU+constLocalAccu , NX_AT+2*(legMsgSchedules(i,1)-1)+2) = 1;
        rhs(NR_CONST_ACCU+constLocalAccu) = legMsgSchedules(i,3);
        %
        %% One constraint is enough to represent equality
        % This is set later on: each constraint can have its own "sign"
        % i.e. '<' , '>' or '='
        % Note that the inequalities are loose (<= and >=)
        %
    end
    assert(constLocalAccu == MX_LGM, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    
    
    %% dealing with common msgs, that need to be released and served within the same HP 
    % CM classifies the messages as Common messages or not. CM(i) = 1 indicates
    % a common message. 
    constLocalAccu = 0;
    for i = 1:size(CM,2)
        if CM(i) == 1
            constLocalAccu = constLocalAccu+1;
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+N_r*(1+N_m)+i) = 1; %B_0
            rhs(NR_CONST_ACCU+constLocalAccu) = 0;
                    %
                    %% One constraint is enough to represent equality
                    % This is set later on: each constraint can have its own "sign"
                    % i.e. '<' , '>' or '='
                    % Note that the inequalities are loose (<= and >=)
                    %
        end
    end
    assert(constLocalAccu == MX_CM, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    
    %% custom constraints
    constLocalAccu = 0;
    for cc = 1:numel(CCs)
        constLocalAccu = constLocalAccu+1;
        for term = 1:numel(CCs{cc}{CCI_LHS})
            % Get the term variable
            var         = CCs{cc}{CCI_LHS}{term}{CCI_VAR};            
            var_coef    = CCs{cc}{CCI_LHS}{term}{CCI_COEF};
            var_id      = CCs{cc}{CCI_LHS}{term}{CCI_VID};
            if (true == strncmp('T',var,1))
                A(NR_CONST_ACCU+constLocalAccu,var_id) = var_coef; % t.o
            elseif (true == strncmp('M',var,1))
                A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*var_id-1) = var_coef; % m.o
            else
                assert(false, 'error');
            end
        end
        rhs(NR_CONST_ACCU+constLocalAccu) = CCs{cc}{CCI_RHS};
    end
    assert(constLocalAccu == MX_CC, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    
    %% upper and lower bounds, sense and vtypes
    lb = zeros(1,NX);
    ub = zeros(1,NX);
    %%
    % task offsets
    for i = 1:N_t
        ub(i) = Tasks{i}{TI_PD}-mm;
    end
    % message offsets and deadlines
    for i = 1:N_m
        ub(NX_AT+2*(i-1)+1) = Msgs{i}{MI_PD}-mm;
        ub(NX_AT+2*(i-1)+2) = Msgs{i}{MI_PD};
        lb(NX_AT+2*(i-1)+2) = T_per_round + 1*T_per_slot; % length a 1-slot round
    end
    % sigmas
    for i = 1:N_tc
        ub(NX_AT+NX_CT+i) = 1;
    end
    % lambdas
    for i = 1:N_cp
        ub(NX_AT+NX_CT+NX_DL+i) = 1;
    end
    % rounds
    for j = 1:N_r
        ub(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = LCM;%-(T_per_round + B_max * T_per_slot); % offsets
        for i = 1:N_m
            ub(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+i) = Msgs{i}{MI_LD}; % B_i values
        end
    end
    % force the first round to start at 0
    % -> Don't! May artificially add one round due to inheritance
    %ub(NX_AT+NX_CT+NX_DL+NX_CP+1) = 0; 
    
    for i = 1:N_m
        lb(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*N_r+i) = -1; % B_0 values
        ub(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*N_r+i) = 0;
    end
        
    % event variables
    for j = 1:N_r
        for i = 1:N_m
            % k^a
            ub(NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+1) = Msgs{i}{MI_NI}*Msgs{i}{MI_LD};
            % k^d
            lb(NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+2) = -1; % k^d can take -1
            ub(NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+2) = Msgs{i}{MI_NI}*Msgs{i}{MI_LD};
        end
    end
    
%     % event variables
%     for j = 1:N_r
%         ub(NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+NX_EV+j) = B_max; % \hat{B}
%     end
    
    %% vtype
    % I assume this is defined in Gurobi, and probably
    % C -> Continuous
    % B -> Binary
    % I -> Integer
    vtype = '';
    for i = 1:NX_AT+NX_CT
        vtype = strcat(vtype,'C');
    end
    for i = 1:NX_DL
        vtype = strcat(vtype,'B');
    end
    for i = 1:NX_CP
        vtype = strcat(vtype,'B');
    end
    for j = 1:N_r
        vtype = strcat(vtype, 'C');
        for i = 1:N_m
            vtype = strcat(vtype, 'I');
        end
    end
    for i = 1:N_m
        vtype = strcat(vtype, 'I');
    end
    for j = 1:N_r
        for i = 1:N_m
            vtype = strcat(vtype, 'II');
        end
    end
    %%
    % sense
    sense = '';
    for i = 1:MX_DL+MX_CP+MX_RD+MX_EV
        sense = strcat(sense,'<');
    end
    for i = MX_DL+MX_CP+MX_RD+MX_EV+1:(MX-MX_CC)
        sense = strcat(sense,'=');
    end
    for i = MX-MX_CC+1:MX
        cc = i - (MX-MX_CC);
        sense = strcat(sense, CCs{cc}{CCI_SGN});
    end
    %%
    % dummy objective
    obj = zeros(NX,1);
    % Trial: maximize the message deadlines
    obj2 = zeros(NX,1);
    for i= NX_AT+2 : 2 : NX_AT+NX_CT
        obj2(i)=1;
    end
    %%
    % log system size
    %%
    % LOG BLOCK
    if true == LOG_VERBOSE
        fprintf('--- System size ---\n');
        fprintf('Variables = %d, constraints = %d\n', size(A,2),size(A,1));
    end
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % solve the model
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    try
        clear model;
        model.A = sparse(A);
        model.obj = obj2;
        model.rhs = rhs;
        model.sense = sense;
        model.vtype = vtype;
        model.modelsense = 'max';
        model.lb = lb;
        model.ub = ub;

        clear params;
        params.outputflag = 0;
        params.Method = -1;
%         params.FeasibilityTol = 1e-5;
% Value ranging from 1e-2 to 1e-9. Defines the violation error for the
% constraints. Default is 1e-6.
%         params.Seed = randi(10000);

        result = gurobi(model,params);

    catch gurobiError
        fprintf('Error reported\n');
        gurobiError
    end
    %%
    % compute runtime
    runtimeSolver = runtimeSolver + result.runtime;
    %%
    % LOG BLOCK
    if true == LOG_VERBOSE
        fprintf('--- Synthesis time ---\n');
        fprintf('Runtime solver: single run = %f, accumulated = %f\n', result.runtime, runtimeSolver);
    end
    %%
    % check if it is solved
    if (false == strcmp('INFEASIBLE',result.status))
        solved = true;
        %%
        % LOG BLOCK
        if true == LOG_VERBOSE
            fprintf('--- Solution found with %d rounds ---\n', R);
            iis = 'Solution found, no IIS';
        end
        break;
    else
        if compute_iis
            iis = gurobi_iis(model);
            fprintf('--- IIS constraints ---\n');
            find(iis.constrs)        
            fprintf('--- IIS UB ---\n');
            find(iis.ub)
            fprintf('--- IIS LB ---\n');
            find(iis.lb)
        else
            iis = 'ISS computation disabled';
        end
    end
    %%
    % increment round number
    R = R+1;
end


%%
% definitions
% round schedules
% roundSchedules = {round1, round2,...}
% roundi = {start time, Msgs}
% task schedules
% taskSchedules = {task1, task2, ...}
% taski = {'task name', period, offset}
% network schedules
% networkSchedules = {msg1, msg2, ...}
% msgi = {'msg name', period, {rounds}}
%%
% format output
if (true == solved)
    %%
    % task schedules
    taskSchedules = result.x(1:numNormalTasks)';
    for j = 1:numNormalTasks
        taskSchedulesSingleMode{j}{TSI_ID} = Tasks{j}{TI_ID};
        taskSchedulesSingleMode{j}{TSI_NM} = Tasks{j}{TI_NM};
        taskSchedulesSingleMode{j}{TSI_OS} = taskSchedules(j);
    end
    %%
    % message schedules
    messageSchedules = [];
    for j = 1:N_m
        % original message offset and deadline returned by the ILP
        messageSchedules(j,1:2) = [result.x(NX_AT+2*(j-1)+1),result.x(NX_AT+2*(j-1)+2)];
    end
    for j = 1:size(Msgs,2)
        msgSchedulesSingleMode{j}{MSI_ID} = Msgs{j}{MI_ID};
        msgSchedulesSingleMode{j}{MSI_NM} = Msgs{j}{MI_NM};
        msgSchedulesSingleMode{j}{MSI_OS} = messageSchedules(j,1);
        msgSchedulesSingleMode{j}{MSI_DL} = messageSchedules(j,2);
       
% Romain: Currently unused part of code (must account for the sigma
% variable to work properly). The same objective is fullfiled by setting
% the maximization of message deadline as objective.
        %     given the tasks offset returned, the message schechules are 'inflated',
% to minimize the constraints in lower-priority modes
    
%         % initialize new offset and deadline values
%         msg_offset_lower = 0;
%         msg_deadline_bigger = inf;
%         % search for all preceeding tasks
%         for n_app = 1:size(APPs,2) 
%             % for all applications running 
%             % ASSUME ONLY ONE CHAIN PER APP!!
%             for n_comp = 2:size(APPs{n_app}{AI_TC},2)
%                 % if component is message j , get the offset from the
%                 % preceding task
%                 if (true == strcmp( Msgs{j}{MI_NM} , APPs{n_app}{AI_TC}{n_comp}))
%                     % find the current message,
%                     % get the pred task offset
%                     prev_task_nm = APPs{n_app}{AI_TC}{n_comp - 1};
%                     for n_task = 1:numNormalTasks
%                         if (true == strcmp( taskSchedulesSingleMode{n_task}{TSI_NM} , prev_task_nm ))
%                             % get the previous task offset and execution time 
%                             prev_task_os = taskSchedulesSingleMode{n_task}{TSI_OS};
%                             prev_task_id = findTaskByName( prev_task_nm, Tasks, 0);
%                             prev_task_et = Tasks{prev_task_id}{TI_ET};
%                             % update the message offset
%                             msg_offset_lower = max(msg_offset_lower, ...
%                                 prev_task_os + prev_task_et);
%                         end
%                     end    
%                 end         
%             end
%         end
%             
%         % search for all following tasks
%         for n_app = 1:size(APPs,2) 
%             % for all applications running 
%             % ASSUME ONLY ONE CHAIN PER APP!!
%             for n_comp = 1:size(APPs{n_app}{AI_TC},2)-1
%                 % if component is message j , get the offset from the
%                 % following task
%                 if (true == strcmp( Msgs{j}{MI_NM} , APPs{n_app}{AI_TC}{n_comp}))
%                     % find the current message,
%                     % get the following task offset
%                     foll_task_nm = APPs{n_app}{AI_TC}{n_comp + 1};
%                     for n_task = 1:numNormalTasks
%                         if (true == strcmp( taskSchedulesSingleMode{n_task}{TSI_NM} , foll_task_nm ))
%                             % get the following task offset 
%                             foll_task_os = taskSchedulesSingleMode{n_task}{TSI_OS};
%                             % update the message deadline bound
%                             msg_deadline_bigger = min(msg_deadline_bigger, ...
%                                 foll_task_os);
%                         end
%                     end    
%                 end         
%             end
%         end
%         % test and update offset
%         assert(msg_offset_lower <= messageSchedules(j,1),       'Error in deflating msg offset');
%         msgSchedulesSingleMode{j}{MSI_OS} = min(messageSchedules(j,1), msg_offset_lower);
%         
%         % test and updated deadline
%         msg_deadline_bigger = msg_deadline_bigger - msg_offset_lower
%         assert(msg_deadline_bigger >= messageSchedules(j,2),    'Error in inflating msg deadline');
%         msgSchedulesSingleMode{j}{MSI_DL} = max(messageSchedules(j,2),msg_deadline_bigger);
    end
    %%
    % round schedules
    roundSchedules = [];
    for j = 1:N_r
        % roundSchedules () = [ r_j.t , sum_i(r_j.B_i) , r_j.B_1 , r_j.B_2 , ...  r_j.B_N_m ]
        roundSchedules(j,1:N_m+2) = [result.x(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1);...
                            sum(result.x(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+2 : NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+N_m));...
                                result.x(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+2 : NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+N_m)];
    end
    for j = 1:N_r
        roundSchedulesSingleMode{j}{RSI_ID} = j;
        roundSchedulesSingleMode{j}{RSI_NM} = strcat('R',num2str(j));
        roundSchedulesSingleMode{j}{RSI_OS} = roundSchedules(j,1);
        roundSchedulesSingleMode{j}{RSI_FL} = roundSchedules(j,2);
        roundSchedulesSingleMode{j}{RSI_MS} = {};
        for k = 1:N_m
            if uint32(roundSchedules(j,k+2)) == 1
                roundSchedulesSingleMode{j}{RSI_MS}{ size(roundSchedulesSingleMode{j}{RSI_MS},2) + 1 } = Msgs{k}{MI_NM};
            end
        end
        assert(uint32(roundSchedulesSingleMode{j}{RSI_FL}) == size(roundSchedulesSingleMode{j}{RSI_MS},2), 'Error');
    end
end
%%
%%
% LOG BLOCK
if true == LOG_SIMPLE
    fprintf('--- Solved = %d ---\n', solved);
    fprintf('========================================\n');
end
