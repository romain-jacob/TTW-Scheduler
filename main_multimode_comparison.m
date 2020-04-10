%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main_multimode_comparison.m
% Main script file for comparing the performance of 
% - Single mode without inheritance 
% - Multimode with minimal inheritance
% - Multimode with full inheritance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Romain Jacob, last update 03.04.17
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
tic
clc
clear all
close all

%% Schedule to compute
% Uncomment the configuration you wish to compute schedule for.
% See `loadConfig.m` for details

% configuration = 'simple_example';   % Simple example configuration
% configuration = 'pendulums_TCPS';   % Pendulums use case
configuration = 'example';          % Default configuration

%% Initialization of data structure
% get the max number of modes
[~, ~, ~, ~, ~, ...
    ModeApps, ~] = ...
    loadConfig(configuration, '', 0);

modeNb = size(ModeApps,2);
clearvars -except modeNb configuration main_script

% flag for multimode_main 
comparison_flag = true;

% define results storing array
round_counts = zeros(3,modeNb);
HP = zeros(3,modeNb);
solvingTimes = zeros(3,modeNb);

%% choose what to run
no_inheritance          = 1;
minimal_inheritance     = 1;
full_inheritance        = 1;
print_plot              = 0;

%% Run multimode_main without inheritance
% essentially, redefine mode_configuration to get only one mode and run
% multimode_main

if no_inheritance
    % flag for the type of inheritance requested
    inheritance_flag = 'none';  % This triggers to load only one mode 
                                % configuration, defined by 'modeID'
    for modeID=1:modeNb
        main_multimode
        round_counts(1,modeID)  = size(ModeSchedules{1}{MSDI_RS},2);
        HP(1,modeID)            = ModeSchedules{1}{MSDI_HP};
        solvingTimes(1,modeID)  = ModeSchedules{1}{MSDI_ST};
    end
end

%% Run multimode_main with minimal inheritance
% Standard case

if minimal_inheritance
    % flag for the type of inheritance requested
    inheritance_flag = 'mini';  % Necessary and sufficient inheritance
    modeID = 0;                 % required variable in main_multimode
    main_multimode
    for modeID=1:modeNb
        round_counts(2,modeID)  = size(ModeSchedules{modeID}{MSDI_RS},2);
        HP(2,modeID)            = ModeSchedules{modeID}{MSDI_HP};
        solvingTimes(2,modeID)  = ModeSchedules{modeID}{MSDI_ST};
    end
end


%% Run multimode_main with full inheritance
% All higher mode applications are added to the spec of the lower priority
% ones. The mode graph is fully connected, to get only one schedule
% domain per application.

if full_inheritance
    % flag for the type of inheritance requested
    inheritance_flag = 'full';  % Full and naive inheritance
    modeID = 0;                 % required variable in main_multimode
    main_multimode
    for modeID=1:modeNb
        round_counts(3,modeID)  = size(ModeSchedules{modeID}{MSDI_RS},2);
        HP(3,modeID)            = ModeSchedules{modeID}{MSDI_HP};
        solvingTimes(3,modeID)  = ModeSchedules{modeID}{MSDI_ST};
    end
end

%%
round_counts
HP
solvingTimes
averageSolvingTime = mean(solvingTimes(:))

%%

HP_max = max(HP(:));
for i = 1:3
    normalized_round_counts(i,:) = round_counts(i,:) .* (HP_max ./ HP(i,:)) ;
end

normalized_round_counts

%% Save the data in CSV file

headers = { ...
    'modeID', ...
    'inheritance_type', ...
    'solving_time[s]', ...
    'nb_rounds', ...
    'hyperperiod', ...
    'nb_rounds_norm', ...
    'hyperperiod_norm', ...
    };
fid = fopen('outputs/inheritance_evaluation.csv', 'w' );
for col = 1:length(headers)-1 
    fprintf( fid, '%s,', headers{col} );
end
fprintf( fid, '%s', headers{end} );
fprintf( fid, '\n');
fclose( fid );

% inheritance_type = {'none', 'mini', 'full'};
for mode=1:modeNb
    for inheritance=1:3
        data = [
            mode, ... 
            inheritance, ...
            solvingTimes(inheritance, mode), ...
            round_counts(inheritance, mode), ...
            HP(inheritance, mode), ...
            normalized_round_counts(inheritance, mode), ...
            HP_max
            ];
        dlmwrite('outputs/inheritance_evaluation.csv', data, '-append')
    end
end

%%

if print_plot

    close all
    figure
    hold on
    %Defines the colors to use
    colorsRBG = [192 144 0 ; 226 170 0 ; 255 192 0 ; 255 209 132];
    colors01 = colorsRBG / 255 ;
    
    round_counts = normalized_round_counts;

    rounds = bar(round_counts', 'EdgeColor', 'none');
    rounds(1).FaceColor = colors01(4,:);
    rounds(2).FaceColor = colors01(3,:);
    rounds(3).FaceColor = colors01(1,:);
    set(gca,'XTickLabel',['1';'2';'3';'4';'5'])
    set(gca,'XTick',[1:5])
    xlabel('Mode priority','FontSize',12)
    ylabel('Number of rounds scheduled','FontSize',12)
    legend('No inheritance', 'Mininal inheritance', 'Full inheritance', ...
            'Location', 'northwest')

    offset = 0.22;

    for i=1:5  
        text(i-offset,round_counts(1,i),num2str(round_counts(1,i),'%d'),...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom') 
        text(i,round_counts(2,i),num2str(round_counts(2,i),'%d'),...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom') 
        text(i+offset,round_counts(3,i),num2str(round_counts(3,i),'%d'),...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom') 
    end

    hold off

end 

toc

%%
% close all
% HP = round_counts(1,:) ./ round_counts(3,:);
% normalized_round_counts(1,:) = round_counts(1,:) ./ HP
% normalized_round_counts(2,:) = round_counts(2,:) ./ HP
% bar(normalized_round_counts')






