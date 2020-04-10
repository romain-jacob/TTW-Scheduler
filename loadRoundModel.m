%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loadRoundModel.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function that load a model of the round length:
% 
%    T_round(B) = T_per_round + B * T_per_slot
%
% The model can be calibrated very precisely for a given implementation of
% TTW. The values in this file are those of the implementation based on
% Baloo, openly available at [1]. 
%
% This model is very accurate (less than 0.5 ms error on the round time);
% the model validation is reported in [2].
%
% All time values are milli-seconds (ms).
%
% [1] XXX
% [2] XXX
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input:
% - L - The maximum payload size that can be sent in a data slot
% - N - The number of retransmissions for the Glossy floods
% - H - The provisioned network diameter;
%       i.e., if the network diameter is H or less, the data slots are long
%       enough for all nodes to receive and transmit the packets N times
%       during a Glossy flood.
%
% Output:
% - T_per_round - The time overhead per round
% - T_per_slot  - The time cost per data slot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Romain Jacob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% TODO
% - add the links and references once openly available

function [T_per_slot,T_per_round] = loadRoundModel(L,N,H)
%%
% All time values (T_... ) in milli-seconds.
%

T_guard     = 0.1;
L_header    = 5;    % bytes
L_beacon    = 2;    % bytes
Rbits       = 250;  % bit/ms
T_switch    = 0.3;
T_slack     = 0.25;
T_slot_base = 0.5;
T_gap       = 1.5;
T_gap_control = 1.5;
T_preprocess  = 2;
T_round_end   = 1.5;


T_beacon = T_guard + (H + 2*N -1) * (8*( L_header + L_beacon )/Rbits + T_switch) + T_slack;
T_slot_L = (H + 2*N -1) * (8*( L_header + L )/Rbits + T_switch) + T_slack;       
% round up to T_slot_base
T_slot_L = ceil(T_slot_L/T_slot_base) * T_slot_base;

T_per_slot  = T_slot_L + T_gap;
T_per_round = T_preprocess + T_beacon + T_gap_control  + T_round_end - T_gap;
end
