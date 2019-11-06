%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% modes_configuration.m
% Configuration file for the modes. It specifies 
% - Priority of the modes
% - Apps running in each mode
% - Transitions between modes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, last update 18.12.16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Comments from Romain, 12.03.17
% + Why 'directed' transitions? I would say it is just a typo in the comment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
% ModeApps
% Tuple:
% - MAI_ID = 1: ID
% - MAI_PR = 2: Priority
% - MAI_TA = 3: Total applications running
% - MAI_FA = 4: Free applications - ***empty by initial configuration
% - MAI_LA = 5: Legacy applications - ***empty by initial configuration
% - MAI_VA = 6: Virtual legacy applications - ***empty by initial configuration
ModeApps = {};
ModeApps{1} = {1, 1, {'A1','A2'},{},{},{}};

% ModeApps{2} = {2, 2, {'A1','A3','A4','A6','A13'},{},{},{}};
% ModeApps{3} = {3, 4, {'A3','A9','A10','A11','A14','A18'},{},{},{}};
% ModeApps{4} = {4, 5, {'A2','A3','A5','A6','A9','A12','A13','A19'},{},{},{}};
% ModeApps{5} = {5, 3, {'A2','A4','A12','A13'},{},{},{}};

%%
% ModeTransitionMatrix
% defines transition between modes. 
% - ModeTransitionMatrix(i,j) = 1 - directed transition from i to j
% - ModeTransitionMatrix(i,j) = 0 - no directed transition from i to j
ModeTransitionMatrix = eye(5);
% ModeTransitionMatrix(1,2) = 1;
% ModeTransitionMatrix(1,3) = 1;
% ModeTransitionMatrix(1,4) = 1;
% ModeTransitionMatrix(1,5) = 1;
% ModeTransitionMatrix(2,1) = 1;
ModeTransitionMatrix(2,3) = 1;
% ModeTransitionMatrix(2,4) = 1;
% ModeTransitionMatrix(2,5) = 1;
% ModeTransitionMatrix(3,1) = 1;
% ModeTransitionMatrix(3,2) = 1;
ModeTransitionMatrix(3,4) = 1;
% ModeTransitionMatrix(3,5) = 1;
% ModeTransitionMatrix(4,1) = 1;
% ModeTransitionMatrix(4,2) = 1;
% ModeTransitionMatrix(4,3) = 1;
ModeTransitionMatrix(4,5) = 1;
ModeTransitionMatrix(5,1) = 1;
% ModeTransitionMatrix(5,2) = 1;
% ModeTransitionMatrix(5,3) = 1;
% ModeTransitionMatrix(5,4) = 1;