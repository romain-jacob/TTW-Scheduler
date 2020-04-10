%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% system_configuration_sample.m
% Configuration file for the whole system, including
% processors, applications, tasks, messages, custom contraints and modes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simple configuration example
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Romain Jacob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Round model 
% 
% A round composed of B slots as the following length:
%   T_round(B) = T_per_round + B * T_per_slot

global T_per_slot T_per_round B_max T_max L_max N H;

L_max   = 8;    % Maximum payload size
N       = 2;    % Number of retransmissions for the Glossy floods
H       = 4;    % Provisioned network diameter
B_max   = 5;    % Maximum number of slots per round
T_max   = 30000; % Maximum inter-round interval 
                % to preserve time synchronization (30s)
                
[T_per_slot , T_per_round] = loadRoundModel(L_max, N, H) ;

%% Applications
% Tuple: 
% - AI_ID = 1: ID *** leave empty
% - AI_NM = 2: Name
% - AI_PD = 3: Period (ms)
% - AI_DL = 4: Deadline (ms) 
% - AI_TC = 5: Task chain
% - AI_NI = 6: Numer of instances - *** empty by initial configuration

APPs = { ...
 { [],  'a_ctrl1', 1000,1000, {'T_sens1',   'M_sens1',      'T_ctrl1',   'M_act1',      'T_act1'}}, ...
 { [],  'a_ctrl2', 500,200,   {'T_sens2',   'M_sens2',      'T_ctrl2'}}, ...
 { [],  'a_alert', 50,50,   {'T_alert',   'M_alert',      'T_action'}}, ...
 { [],  'a_ping1', 500,100, {'T_ping',    'M_broadcast',  'T_update1',    'M_ack1',  'T_ack1'}}, ...
 { [],  'a_ping2', 500,100, {'T_ping',    'M_broadcast',  'T_update2',    'M_ack2',  'T_ack2'}}, ...
 };      

%% Processors
% Tuple: 
% - API_ID = 1: ID                  *** leave empty
% - API_NM = 2: Name
% - API_MP = 3: Mapping             *** leave empty
% - API_CP = 4: Collision Pairs     *** leave empty

APs = {...
    { [],'Sensor1',{},{} }, ...
    { [],'Sensor2',{},{} }, ...
    { [],'Actuator',{},{} }, ...
    { [],'Controler',{},{} }, ...
    };

%% Tasks
% Tuple: 
% - TI_ID = 1: ID                   *** leave empty
% - TI_NM = 2: Name                 *** /!\ --- MUST START WITH 'T' --- /!\
% - TI_MP = 3: Mapping              *** Node executing the task running this task
% - TI_ET = 4: Execution Time       *** in ms
% - TI_PD = 5: Period               *** leave -1 
% - TI_NI = 6: Number of Instances  *** leave -1 

Tasks = { ...
 { [],  'T_sens1',  'Sensor1',   5,-1,-1}, ...
 { [],  'T_update1','Sensor1',   5,-1,-1}, ...
 { [],  'T_sens2',  'Sensor2',   5,-1,-1}, ...
 { [],  'T_update2','Sensor2',   5,-1,-1}, ...
 { [],  'T_act1',   'Actuator',  5,-1,-1}, ...
 { [],  'T_alert',  'Actuator',  5,-1,-1}, ...
 { [],  'T_ctrl1',  'Controler', 5,-1,-1}, ...
 { [],  'T_ctrl2',  'Controler', 5,-1,-1}, ...
 { [],  'T_action', 'Controler', 5,-1,-1}, ...
 { [],  'T_ping',   'Controler', 5,-1,-1}, ...
 { [],  'T_ack1',   'Controler', 5,-1,-1}, ...
 { [],  'T_ack2',   'Controler', 5,-1,-1}, ...
 };

%% Messages
% Tuple: 
% - MI_ID = 1: ID                   *** leave empty 
% - MI_NM = 2: Name                 *** /!\ --- MUST START WITH 'M' --- /!\
% - MI_PD = 3: Period               *** leave -1 
% - MI_NI = 4: Number of instances  *** -1 for initial configuration
% - MI_LD = 5: Load                 *** Number of slots needed to send the message

Msgs = { ...
 { [],  'M_sens1',      -1,-1,1}, ...
 { [],  'M_sens2',      -1,-1,1}, ...
 { [],  'M_act1',       -1,-1,1}, ...
 { [],  'M_alert',      -1,-1,1}, ...
 { [],  'M_broadcast',  -1,-1,1}, ...
 { [],  'M_ack1',       -1,-1,1}, ...
 { [],  'M_ack2',       -1,-1,1}, ...
 };

%% Custom constraints
% (Must be defined, even if empty)
%
% Usage: 
% - Custom contraints can be set between the offsets of any tasks and
% messages. 
% - Only linear constraints are supported.
% - Both equality and inequality are possible.
% - The left-hand-side of the constraint is a set of terms. Each term
% contains the variable name (either a task or a message) and a
% multiplicative coefficient (any real number).
% - The scheduler automatically parses the user-defined constraints and add
% them to the synthesis problem.
% 
% Example use case:
% - Forcing the synchronization of multiple tasks
%
% Tuple:
% - CCI_LHS = 1: Left-hand side of constraint
%   Tuple:
%   + CCI_VAR  = 1 - Variable name in constraint terms
%   + CCI_COEF = 2 - Multiplicative coeficient in constraint terms
%   + CCI_VID  = 3 - ID of the variable (task=1 or message=2) *** empty by initial configuration
% - CCI_SGN = 2: Sign of constraint 
% 
% Valid: '=' or '<'
% /!\ the inequality contraints are interpreted as loose!
% /!\ '<' actually means '<='
% - CCI_RHS = 3: Right-hand side of constraint, must be a constant
CustomConstaints = {};

%% Modes
% Tuple:
% - MAI_ID = 1: ID                              *** leave empty 
% - MAI_PR = 2: Mode priority
% - MAI_TA = 3: List of applications running in the mode
% - MAI_FA = 4: Free applications               *** leave empty
% - MAI_LA = 5: Legacy applications             *** leave empty
% - MAI_VA = 6: Virtual legacy applications     *** leave empty

ModeApps = {...
    ... Emergency                 
    { [], 2, {'a_alert'},{},{},{} }, ...  
    ... Control loops
    { [], 1, {'a_ctrl1','a_ctrl2'},{},{},{}}, ...
    ... Update loops
    { [], 3, {'a_ctrl1','a_ctrl2', 'a_ping1', 'a_ping2'},{},{},{}}, ...
};

%% Mode Transition Matrix
% defines transition between modes. 
% - ModeTransitionMatrix(i,j) = 1 - transition from i to j
% - ModeTransitionMatrix(i,j) = 0 - no transition from i to j

% Fully connected mode graph
% -> transition between all modes possible
ModeTransitionMatrix = ones(numel(ModeApps));
