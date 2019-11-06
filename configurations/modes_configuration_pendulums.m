%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% modes_configuration.m
% Configuration file for the modes. It specifies 
% - Priority of the modes
% - Apps running in each mode
% - Transitions between modes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TTW use case: pendulum network
% - 5 pendulums with one remote controller (6 nodes)
% - 2 "real-time-processes" with one remote controller (3 nodes)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Romain Jacob, last update 18.06.19
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Log
%
% 18.06.19:
%  + Modify the format of the file for better usability

%%
% ModeApps
% Tuple:
% - MAI_ID = 1: ID ***empty by initial configuration
% - MAI_PR = 2: Priority
% - MAI_TA = 3: Total applications running
% - MAI_FA = 4: Free applications - ***empty by initial configuration
% - MAI_LA = 5: Legacy applications - ***empty by initial configuration
% - MAI_VA = 6: Virtual legacy applications - ***empty by initial configuration
ModeApps = {...
    ... Local stabilization
    { [], 2, {...
            'a_loc_stab1','a_loc_stab2','a_loc_stab3','a_loc_stab4','a_loc_stab5',...
            'a_rt_in1','a_rt_in2'...
                        },{},{},{}}, ...
    ... Remote stabilization                  
    { [], 1, {...
            'a_rmt_stab1', ... 
            'a_loc_stab2','a_loc_stab3','a_loc_stab4','a_loc_stab5',...
            'a_rt_in1','a_rt_in2'...
            },{},{},{} }, ...  
    ... Synchronization (control is done locally)
    { [], 3, {...
            'a_sync1','a_sync2','a_sync3', ...
            ... 'a_sync1','a_sync2','a_sync3','a_sync4','a_sync5',...
            'a_rt_in1','a_rt_in2'...
            },{},{},{}}, ...
};
%%
% ModeTransitionMatrix
% defines transition between modes. 
% - ModeTransitionMatrix(i,j) = 1 - transition from i to j
% - ModeTransitionMatrix(i,j) = 0 - no transition from i to j
ModeTransitionMatrix = ones(numel(ModeApps));
% ModeTransitionMatrix = eye(numel(ModeApps));