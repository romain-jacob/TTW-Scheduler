%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% globalVarDef.m
% Definition of global indices and configuration parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, Romain Jacob
% last update 26.06.19
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Log
% 
% 27.06.19:
%  + Moved network parameters to multimode_main.m
%  + Moved logging parameters to multimode_main.m
% 
% 19.06.16:
%  + added support for custom constraints


%% global indices
% processor indices
% API_ID - ID
% API_NM - Name
% API_MP - Mapping
% API_CP - Collision pairs
global API_ID API_NM API_MP API_CP;
API_ID = 1;API_NM = 2;API_MP = 3;API_CP = 4;
%%
% task indices
% TI_ID - ID
% TI_NM - Name
% TI_MP - Mapping
% TI_ET - Execution time
% TI_PD - Period
% TI_NI - Number of instances (in a hyper period)
global TI_ID TI_NM TI_MP TI_ET TI_PD TI_NI;
TI_ID = 1;TI_NM = 2;TI_MP = 3;TI_ET = 4;TI_PD = 5;TI_NI = 6;
%%
% message indices
% MI_ID - ID
% MI_NM - Name
% MI_PD - Period
% MI_NI - Number of instances (in a hyper period)
% MI_LD - Load (number of slots in a period)
global MI_ID MI_NM MI_PD MI_NI MI_LD;
MI_ID = 1;MI_NM = 2;MI_PD = 3;MI_NI = 4;MI_LD = 5;
%%
% application indices
% AI_ID - ID
% AI_NM - Name
% AI_PD - Period
% AI_DL - Deadline
% AI_TC - Task chain (task, msg, task, msg, task,...)
% AI_NI - Number of instances (in a hyper period)
global AI_ID AI_NM AI_PD AI_DL AI_TC AI_NI;
AI_ID = 1;AI_NM = 2;AI_PD = 3;AI_DL = 4;AI_TC = 5;AI_NI = 6;
%%
% mode app indices
% MAI_ID - ID
% MAI_PR - Priority
% MAI_TA - Total applications (active in this mode)
% MAI_FA - Free applications
% MAI_LA - Legacy applications
% MAI_VA - Virtual legacy applications
global MAI_ID MAI_PR MAI_TA MAI_FA MAI_LA MAI_VA;
MAI_ID = 1;MAI_PR = 2;MAI_TA = 3;MAI_FA = 4;MAI_LA = 5;MAI_VA = 6;
%%
% mode schedule indices
% MSDI_ID - ID
% MSDI_PR - Priority
% MSDI_TS - Task schedules
% MSDI_MS - Message schedules
% MSDI_RS - Round schedules
% MSDI_HP - Length of hyperperiod
% MSDI_ST - Total mode synthesis solving time
global MSDI_ID MSDI_PR MSDI_TS MSDI_MS MSDI_RS MSDI_HP MSDI_ST;
MSDI_ID = 1;MSDI_PR = 2;MSDI_TS = 3;MSDI_MS = 4;MSDI_RS = 5;MSDI_HP = 6;MSDI_ST = 7;
%%
% task schedule indices
% TSI_ID - ID
% TSI_NM - Name
% TSI_OS - Offset (schedule)
global TSI_ID TSI_NM TSI_OS;
TSI_ID = 1;TSI_NM = 2;TSI_OS = 3;
%%
% message schedule indices
% MSI_ID - ID
% MSI_NM - Name
% MSI_OS - Offset (schedule)
% MSI_DL - Deadline
global MSI_ID MSI_NM MSI_OS MSI_DL;
MSI_ID = 1;MSI_NM = 2;MSI_OS = 3;MSI_DL = 4;
%%
% custom constraint indices
% CCI_LHS  - Left-hand side of constraint
% CCI_SGN  - Sign of constraint
% CCI_RHS  - Right-hand side of constraint
% CCI_VAR  - Variable name in constraint terms
% CCI_COEF - Multiplicative coeficient in constraint terms
% CCI_VID  - ID of the term variable (either task or message)
global CCI_LHS CCI_SGN CCI_RHS CCI_VAR CCI_COEF CCI_VID;
CCI_LHS = 1;CCI_SGN = 2;CCI_RHS = 3;CCI_VAR=1;CCI_COEF=2;CCI_VID=3;
%%
% round schedule indices
% RSI_ID - ID
% RSI_NM - Name
% RSI_OS - Offset (schedule)
% RSI_FL - Fill status (how many slots are occupied)
% RSI_MS - Messages (which messages are sent in this round)
global RSI_ID RSI_NM RSI_OS RSI_FL RSI_MS;
RSI_ID = 1;RSI_NM = 2;RSI_OS = 3;RSI_FL = 4;RSI_MS = 5;
