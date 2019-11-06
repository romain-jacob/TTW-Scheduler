%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loadModeConfig.m
% Function to load the mode according to the inheritance required.
% Only one mode configuration when multiple have been defined. 
% Used only to compare single vs multimode schedules on the same
% configurations.
% Input:
% - inheritance_flag - Defines the type inheritance 
%   + 'none': load a single mode
%   + 'mini': load the mode as specified, standard case
%   + 'full': expand the mode specification such that all previous app are
%   in legacy
%       -> This is a bit bruttal but the best way to go to be compatible
%       with the rest of the code.
% - ModeID - Identifier of the mode to load.
% Output:
% - Mode configuration to use
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Romain Jacob, last update 03.04.17
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ModeAppsLoaded, ModeTransitionMatrixLoaded] = loadModeConfig(inheritance_flag, ModeID, configuration )
% global index declaration
globalVarDec;

% Load the full mode configuration
if configuration == 0
    configurations/modes_configuration;
elseif configuration == 1
    configurations/modes_configuration_pendulums;
end

if strcmp(inheritance_flag , 'none')

    % Return only the configuration of 'ModeID'
    ModeAppsLoaded{1} = ModeApps{ModeID};
    ModeAppsLoaded{1}{MAI_PR} = 1;  % Bugs if the mode priority is not 1

    ModeTransitionMatrixLoaded = ones(1);
    
elseif strcmp(inheritance_flag , 'mini')
    
    % Nothing more to do
    ModeAppsLoaded = ModeApps;
    ModeTransitionMatrixLoaded = ModeTransitionMatrix;
    
elseif strcmp(inheritance_flag , 'full')
    
    % Add all higher priority mode application to the lower priority ones
    ModeAppsLoaded = ModeApps;
    for i = 2:size(ModeAppsLoaded, 2)
        ModeAppsLoaded{i}{MAI_TA} = ...
            setOr(  ModeAppsLoaded{i}{MAI_TA} , ...
                    ModeAppsLoaded{i - 1}{MAI_TA} ) ;
    end
    ModeTransitionMatrixLoaded = ones(size(ModeApps,2));
    
    
else
    
    error('The type of inheritance requested is not properly defined!')
    
end
    
    

end
