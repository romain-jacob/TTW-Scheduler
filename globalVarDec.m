%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% globalVarDec.m
% Declaration of global indices and network parameters
% To keep consistant with globalVarDef.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, Romain Jacob
% last update 27.06.19
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Log
% 
% 27.06.19:
%  + added support for flexible round lengths
%       Removed Cnet (not used anymore)
%       Renamed Tmax -> T_max
%       Renamed B -> B_max
% 
% 19.06.16:
%  + added support for custom constraints


%% global indices
% processor indices
global API_ID API_NM API_MP API_CP;
% task indices
global TI_ID TI_NM TI_MP TI_ET TI_PD TI_NI;
% message indices
global MI_ID MI_NM MI_PD MI_NI MI_LD;
% application indices
global AI_ID AI_NM AI_PD AI_DL AI_TC AI_NI;
% mode app indices
global MAI_ID MAI_PR MAI_TA MAI_FA MAI_LA MAI_VA;
% mode schedule indices
global MSDI_ID MSDI_PR MSDI_TS MSDI_MS MSDI_RS MSDI_HP MSDI_ST;
% task schedule indices
global TSI_ID TSI_NM TSI_OS;
% message schedule indices
global MSI_ID MSI_NM MSI_OS MSI_DL;
% custom constraint indices
global CCI_LHS CCI_SGN CCI_RHS CCI_VAR CCI_COEF CCI_VID;
% round schedule indices
global RSI_ID RSI_NM RSI_OS RSI_FL RSI_MS;

%% network and round parameters;
global T_per_slot T_per_round B_max T_max;

%% log parameters
global LOG_SIMPLE LOG_VERBOSE;