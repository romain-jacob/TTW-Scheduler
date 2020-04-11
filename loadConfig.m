%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loadConfig.m
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
% Romain Jacob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [APPs, APs, Tasks, Msgs, CustomConstaints, ... 
    ModeAppsLoaded, ModeTransitionMatrixLoaded] = ... 
    loadConfig(configuration, inheritance_flag, ModeID )

% global index declaration
globalVarDec;
% add the configurations folder to path
addpath('configurations');

%% Load the complete configuration
if strcmp(configuration , 'simple_example')
    simple_example;
elseif strcmp(configuration , 'pendulums_TCPS')
    pendulums_TCPS;
elseif strcmp(configuration , 'evaluation')
    evaluation;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add you own configuration here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% elseif strcmp(configuration , 'your-name')
%     your-name;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else
    error('configuration unknown')
end

%% If we are comparing inheritance strategies, overwrite the mode infos
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
    
    
elseif strcmp(inheritance_flag , '')
    
    % Nothing more to do
    ModeAppsLoaded = ModeApps;
    ModeTransitionMatrixLoaded = ModeTransitionMatrix;
    
else
    
    error('The type of inheritance requested is not properly defined!')
    
end
    
    

end
