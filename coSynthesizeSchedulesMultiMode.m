%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to synthesize network schedules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, last update 24.09.16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [solved, roundSchedules, taskSchedules, networkSchedules, APs, Tasks, Msgs, APPs] = coSynthesizeSchedulesMultiMode(APs, Tasks, Msgs, APPs, legConst, virLegConst)

globalVarDec;

%%
% output init
solved = false;
roundSchedules = [];
taskSchedules = [];
networkSchedules = [];

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Preprocessing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
% preprocess for co scheduling
%%
% find the LCM of the system and the number of instances
periods = [];
for i = 1:size(APPs,2)
    periods(i) = APPs{i}{AI_PD};
end
LCM = lcmVec(periods);
for i = 1:size(APPs,2)
    APPs{i}{AI_NI} = LCM/APPs{i}{AI_PD};
end
%%
% assign the periods and num of instances to tasks and messages
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

%%
% collect legacy task schedules
legTaskSchedules = [];
for i = 1:size(legConst,2)
    legTaskSchedules(i,:) = legConst{i};
end
numLegTasks = size(legConst,2);
%%
% collect virtual tasks
VirTasks = {};
for i = 1:size(virLegConst,2)
    VirTasks{i} = {0, virLegConst{i}{1},virLegConst{i}{2},virLegConst{i}{5},virLegConst{i}{4},LCM/virLegConst{i}{4}};
end
% add virtual tasks into the task list
numNormalTasks = size(Tasks,2);
numVirTasks = size(VirTasks,2);
virTaskSchedules = [];
for i = 1:size(VirTasks,2)
    Tasks{numNormalTasks+i} = VirTasks{i};
    virTaskSchedules(i,:) = [numNormalTasks+i, virLegConst{i}{3}];
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
% find collision pairs
for i = 1:size(APs,2)
    for j = 1:size(APs{i}{API_MP},2)
        for k = j+1:size(APs{i}{API_MP},2)
            ctj_id = APs{i}{API_MP}{j};
            ctj_ni = Tasks{ctj_id}{TI_NI};
            ctk_id = APs{i}{API_MP}{k};
            ctk_ni = Tasks{ctk_id}{TI_NI};
            for p = 1:ctj_ni
                for q = 1:ctk_ni
                    APs{i}{API_CP}{size(APs{i}{API_CP},2)+1} = [ctj_id, p, ctk_id, q];
                end
            end
        end
    end
end
%%
% collect collision pairs and task chains
% CP = [task 1 id, task 1 instance, task 2 id, task 2 instance]
CPs = {};
for i = 1:size(APs,2)
    for j = 1:size(APs{i}{API_CP},2)
        CPs{size(CPs,2)+1} = APs{i}{API_CP}{j};
    end
end
% TC = {preceeding type, preceeding id, following type, foolowing id}.
% Type: 1->task, 2->message
TCs = {};
for i = 1:size(APPs,2)
    TC = {};
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
    TCs{size(TCs,2)+1} = TC;
end
%%
% compute the minimal and maximal number of rounds
numInsts = [];
for i = 1:size(Msgs,2)
    numInsts(i) = Msgs{i}{MI_NI};
end
N_min_load = ceil(sum(numInsts)/B);
N_min_inst = 2*max(numInsts);
N_min = max(N_min_load,N_min_inst);
N_max = floor(LCM/Cnet);

%%
% check input
fprintf('Cnet = %f, B = %d, Tmax = %f\n', Cnet, B, Tmax);
fprintf('Min Rounds %d, Max Rounds %d\n', N_min, N_max);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main synthesis loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
% main loop
N = N_min;
runtimeSolver = 0;
while (N <= N_max)
    fprintf('Try for %d rounds\n', N);
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % model formulation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    % the big M and small mm
    M = 10*LCM;
%     mm = 0.01;
    mm = 0.0001;

    %%
    % computation of the matrix sizes
    N_t = size(Tasks,2); % num tasks
    N_m = size(Msgs,2); % num messages
    N_a = size(APPs,2); % num applications
    N_cp = size(CPs,2); % num collision pairs
    N_tc = 0; % num unit task chains
    for i = 1:size(TCs,2)
        N_tc = N_tc + size(TCs{i},2);
    end
    N_r = N; % num rounds
    % number of variables
    NX_AT = N_t;
    NX_CT = 2*N_m;
    NX_DL = N_tc;
    NX_CP = N_cp;
    NX_RD = N_r*(1+N_m)+N_m; % t_j, B_{i,j}, B_{0,j}
    NX_EV = 2*N_r*N_m; % k^a_{i,j}, k^d_{i,j}, j is outter loop
    NX = NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+NX_EV;
    % number of constraints
    MX_DL = N_tc+N_a;
    MX_CP = 2*N_cp;
    MX_RD = 2*(N_r-1);
    MX_EV = N_r*(6*N_m+1);
    MX_EC = N_m;
    MX_LG = numLegTasks + numVirTasks;
    MX = MX_DL+MX_CP+MX_RD+MX_EV+MX_EC+MX_LG;
    % initialize A and rhs
    A = zeros(MX,NX);
    rhs = zeros(MX,1);
    %%
    % formulating the constraints
    NR_CONST_ACCU = 0;
    %%
    % deadline constraint
    constLocalAccu = 0;
    sigmaCount = 0;
    for i = 1:size(TCs,2)
        for j = 1:size(TCs{i},2)
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
                assert(false,'Error');
            end
        end
        tfid = TCs{i}{1}(2);
        tlid = TCs{i}{size(TCs{i},2)}(4);
        constLocalAccu = constLocalAccu +1;
        A(NR_CONST_ACCU+constLocalAccu,tfid) = -1;
        A(NR_CONST_ACCU+constLocalAccu,tlid) = 1;
        for j = 1:size(TCs{i},2)
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+sigmaCount-size(TCs{i},2)+j) = APPs{i}{AI_PD}; % sigmas
        end
        rhs(NR_CONST_ACCU+constLocalAccu) = APPs{i}{AI_DL} - Tasks{tlid}{TI_ET};
    end
    assert(constLocalAccu == MX_DL, 'Error: wrong number of constraints');
    assert(sigmaCount == NX_DL, 'Error: wrong number of variables');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    %%
    % collision pair constraint
    constLocalAccu = 0;
    for i = 1:size(CPs,2)
        ti_id = CPs{i}(1);
        k_i = CPs{i}(2);
        tj_id = CPs{i}(3);
        k_j = CPs{i}(4);
        constLocalAccu = constLocalAccu + 1;
        A(NR_CONST_ACCU+constLocalAccu,ti_id) = 1;
        A(NR_CONST_ACCU+constLocalAccu,tj_id) = -1;
        A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+i) = M;
        rhs(NR_CONST_ACCU+constLocalAccu) = -Tasks{ti_id}{TI_ET}-Tasks{ti_id}{TI_PD}*(k_i-1)+Tasks{tj_id}{TI_PD}*(k_j-1)+M;
        constLocalAccu = constLocalAccu + 1;
        A(NR_CONST_ACCU+constLocalAccu,ti_id) = -1;
        A(NR_CONST_ACCU+constLocalAccu,tj_id) = 1;
        A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+i) = -M;
        rhs(NR_CONST_ACCU+constLocalAccu) = -Tasks{tj_id}{TI_ET}+Tasks{ti_id}{TI_PD}*(k_i-1)-Tasks{tj_id}{TI_PD}*(k_j-1);
    end
    assert(constLocalAccu == MX_CP, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    %%
    % round constraints
    constLocalAccu = 0;
    for j = 1:N_r-1
        constLocalAccu = constLocalAccu + 1;
        A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = 1;
        A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*j+1) = -1;
        rhs(NR_CONST_ACCU+constLocalAccu) = -Cnet;
        constLocalAccu = constLocalAccu + 1;
        A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = -1;
        A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*j+1) = 1;
        rhs(NR_CONST_ACCU+constLocalAccu) = Tmax;
    end
    assert(constLocalAccu == MX_RD, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    %%
    % event bound constraint
    constLocalAccu = 0;
    for j = 1:N_r
        for i = 1:N_m
            constLocalAccu = constLocalAccu+1;
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = 1; % t_j
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+1) = -1; % o_i
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+1) = -Msgs{i}{MI_PD}; % k^a_{i,j}
            rhs(NR_CONST_ACCU+constLocalAccu) = -mm;
            constLocalAccu = constLocalAccu+1;
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = -1; % t_j
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+1) = 1; % o_i
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+1) = Msgs{i}{MI_PD}; % k^a_{i,j}
            rhs(NR_CONST_ACCU+constLocalAccu) = Msgs{i}{MI_PD};
            constLocalAccu = constLocalAccu+1;
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = 1; % t_j
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+1) = -1; % o_i
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+2) = -1; % d_i
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+2) = -Msgs{i}{MI_PD}; % k^d_{i,j}
            rhs(NR_CONST_ACCU+constLocalAccu) = - Cnet + mm;
            constLocalAccu = constLocalAccu+1;
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = -1; % t_j
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+1) = 1; % o_i
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+2*(i-1)+2) = 1; % d_i
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+2) = Msgs{i}{MI_PD}; % k^d_{i,j}
            rhs(NR_CONST_ACCU+constLocalAccu) = Msgs{i}{MI_PD} + Cnet - mm;

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
                A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(k-1)+1+i) = 1; % sum B_{i,j}, 1...j-1
            end
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*N_r+i) = 1; % B_{i,0}
            rhs(NR_CONST_ACCU+constLocalAccu) = 0;
        end
        constLocalAccu = constLocalAccu+1;
        for i = 1:N_m
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+i) = 1;
        end
        rhs(NR_CONST_ACCU+constLocalAccu) = B;
    end
    assert(constLocalAccu == MX_EV, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    %%
    % event count constraint
    constLocalAccu = 0;
    for i = 1:N_m
        constLocalAccu = constLocalAccu+1;
        for j = 1:N_r
            A(NR_CONST_ACCU+constLocalAccu,NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+i) = 1;
        end
        rhs(NR_CONST_ACCU+constLocalAccu) = Msgs{i}{MI_NI};
    end
    assert(constLocalAccu == MX_EC, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    %%
    % dealing with legacy tasks and virtual legacy tasks
    constLocalAccu = 0;
    for i = 1:numLegTasks
        constLocalAccu = constLocalAccu+1;
        A(NR_CONST_ACCU+constLocalAccu,legTaskSchedules(i,1)) = 1;
        rhs(NR_CONST_ACCU+constLocalAccu) = legTaskSchedules(i,2);
    end
    for i = 1:numVirTasks
        constLocalAccu = constLocalAccu+1;
        A(NR_CONST_ACCU+constLocalAccu,virTaskSchedules(i,1)) = 1;
        rhs(NR_CONST_ACCU+constLocalAccu) = virTaskSchedules(i,2);
    end
    assert(constLocalAccu == MX_LG, 'Error: wrong number of constraints');
    NR_CONST_ACCU = NR_CONST_ACCU + constLocalAccu;
    %%
    % upper and lower bounds, sense and vtypes
    lb = zeros(1,NX);
    ub = zeros(1,NX);
    % upper bounds
    % task offsets
    for i = 1:N_t
        ub(i) = Tasks{i}{TI_PD}-mm;
    end
    % message offsets and deadlines
    for i = 1:N_m
        ub(NX_AT+2*(i-1)+1) = Msgs{i}{MI_PD}-mm;
        ub(NX_AT+2*(i-1)+2) = Msgs{i}{MI_PD};
        lb(NX_AT+2*(i-1)+2) = Cnet;
    end
    % sigmas
    for i = 1:N_tc
%         ub(NX_AT+NX_CT+i) = 2;
        ub(NX_AT+NX_CT+i) = 1;
    end
    % lambdas
    for i = 1:N_cp
        ub(NX_AT+NX_CT+NX_DL+i) = 1;
    end
    % rounds
    for j = 1:N_r
        ub(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1) = LCM;
        for i = 1:N_m
            ub(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+i) = Msgs{i}{MI_LD};
        end
    end
    ub(NX_AT+NX_CT+NX_DL+NX_CP+1) = 0; % force the first round to start at 0
    for i = 1:N_m
        lb(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*N_r+i) = -1;
        ub(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*N_r+i) = 0;
    end
    % event variables
    for j = 1:N_r
        for i = 1:N_m
            ub(NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+1) = Msgs{i}{MI_NI};
            lb(NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+2) = -1; % k^d can take -1
            ub(NX_AT+NX_CT+NX_DL+NX_CP+NX_RD+2*N_m*(j-1)+2*(i-1)+2) = Msgs{i}{MI_NI};
        end
    end
    %%
    % vtype
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
    for i = MX_DL+MX_CP+MX_RD+MX_EV+1:MX
        sense = strcat(sense,'=');
    end
    %%
    % dummy objective
    obj = zeros(NX,1);
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % solve the model
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    try
        clear model;
        model.A = sparse(A);
        model.obj = obj;
        model.rhs = rhs;
        model.sense = sense;
        model.vtype = vtype;
        model.modelsense = 'min';
        model.lb = lb;
        model.ub = ub;

        clear params;
        params.outputflag = 1;
        params.Method = -1;

        result = gurobi(model,params);

    catch gurobiError
        fprintf('Error reported\n');
        gurobiError
    end
    %%
    % runtime
    runtimeSolver = runtimeSolver + result.runtime;
    fprintf('Runtime solver: single run = %f, accumulated = %f\n', result.runtime, runtimeSolver);
    %%
    % check if it is solved
    if (false == strcmp('INFEASIBLE',result.status))
        solved = true;
        fprintf('Solution found with %d rounds\n', N);
        break;
    end
    %%
    % increment round number
    N = N+1;
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% solve the model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (true == solved)
    roundSchedules = [];
    for j = 1:N_r
        roundSchedules(j,1:N_m+2) = [result.x(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1);...
                            sum(result.x(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+2:NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+N_m));...
                            result.x(NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+2:NX_AT+NX_CT+NX_DL+NX_CP+(1+N_m)*(j-1)+1+N_m)];
    end
    taskSchedules = result.x(1:NX_AT)';
    for j = 1:N_m
        networkSchedules(j,1:2) = [result.x(NX_AT+2*(j-1)+1),result.x(NX_AT+2*(j-1)+2)];
    end
    
else
    roundSchedules = [];
    taskSchedules = [];
    networkSchedules = [];
end
