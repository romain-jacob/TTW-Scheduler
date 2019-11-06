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
% ModeApps{1} = {1, 1, {'A1','A3','A4','A8','A10','A13'},{},{},{}};
% ModeApps{2} = {2, 2, {'A1','A3','A4','A6','A13'},{},{},{}};
% ModeApps{3} = {3, 3, {'A3','A9','A10','A11','A14','A18'},{},{},{}};
% ModeApps{4} = {4, 4, {'A2','A3','A5','A6','A9','A12','A13','A19'},{},{},{}};
% ModeApps{5} = {5, 5, {'A2','A4','A12','A13'},{},{},{}};

% % Simplier problem to make it feasible by the full-reservation
ModeApps{1} = {1, 1, {'A1','A3','A4','A8','A10'},{},{},{}};
ModeApps{2} = {2, 2, {'A1','A3','A4','A6'},{},{},{}};
ModeApps{3} = {3, 3, {'A3','A9','A10','A11','A14','A18'},{},{},{}};
ModeApps{4} = {4, 4, {'A2','A3','A5','A6','A9','A12','A19'},{},{},{}};
ModeApps{5} = {1, 5, {'A2','A4','A12','A13'},{},{},{}};


% Problem without common apps to test the global-synthesis
% ModeApps{1} = {1, 1, {'A1','A3','A4','A8','A10'},{},{},{}};
% ModeApps{2} = {2, 2, {'A2','A7','A6'},{},{},{}};
% ModeApps{3} = {3, 3, {'A5','A9','A11','A12','A14','A18'},{},{},{}};
% ModeApps{4} = {4, 4, {'A2','A3','A5','A6','A9','A12','A19'},{},{},{}};
% ModeApps{5} = {5, 5, {'A2','A4','A12','A13'},{},{},{}};


%% Extract all the tasks used in the modes
% Only used for presentation of the use case in the paper. Not used
% anywhere in the code.

if 0
    task_mapping = zeros(size(APs,2),1);
for i = 1:size(Tasks,2)
    % look for task Ti mapping
    % first reset the flag
    flag = false;
    for j = 1:size(ModeApps,2)
        % look in mode Mj
        for k = 1:size(ModeApps{j}{MAI_TA},2) %app_name
            % look in kth app of mode Mj
            % get the corresponding chain
            for kk = 1:size(APPs,2)
                if strcmp(  ModeApps{j}{MAI_TA}{k},...
                            APPs{kk}{AI_NM})
                    chain = APPs{kk}{AI_TC};
                    break
                end
            end
            for l = 1:size(chain,2)
                % look in the chain if task Ti is used
                if strcmp(Tasks{i}{TI_NM}, chain{l})
                %task is used, store and break
                    flag = true;
                    % get the mapped AP
                    mapped_ap_nm = Tasks{i}{TI_MP};
                    for ll = 1:size(APs,2)
                        if strcmp(mapped_ap_nm, APs{ll}{API_NM})
                            mapped_ap_id = APs{ll}{API_ID};
                            break
                        end
                    end
                    % first column counts the number of tasks found so far
                    task_mapping(mapped_ap_id,1) = task_mapping(mapped_ap_id,1) + 1;
                    task_mapping(   mapped_ap_id , ...
                                    task_mapping(mapped_ap_id,1) + 1 ...
                                    ) = Tasks{i}{TI_ID}; 
                    break
                end
            end
            % if tast Ti was not found in the chain, flag is still set to
            % false, we loop on k and check the following application of
            % mode Mj
            if flag
                break
            end
        end
        % if tast Ti was not found in mode Mj, flag is still set to
        % false, we loop on j and check the applications of the following
        % mode Mj
        if flag
            break
        end
    end
end
                   
task_mapping  

end


%%
% ModeTransitionMatrix
% defines transition between modes. 
% - ModeTransitionMatrix(i,j) = 1 - directed transition from i to j
% - ModeTransitionMatrix(i,j) = 0 - no directed transition from i to j
ModeTransitionMatrix = eye(5);
% ModeTransitionMatrix(1,2) = 1;
ModeTransitionMatrix(1,3) = 1;
% ModeTransitionMatrix(1,4) = 1;
% ModeTransitionMatrix(1,5) = 1;
% ModeTransitionMatrix(2,1) = 1;
ModeTransitionMatrix(2,3) = 1;
% ModeTransitionMatrix(2,4) = 1;
% ModeTransitionMatrix(2,5) = 1;
% ModeTransitionMatrix(3,1) = 1;
% ModeTransitionMatrix(3,2) = 1;
ModeTransitionMatrix(3,4) = 1;
ModeTransitionMatrix(3,5) = 1;
% ModeTransitionMatrix(4,1) = 1;
% ModeTransitionMatrix(4,2) = 1;
% ModeTransitionMatrix(4,3) = 1;
ModeTransitionMatrix(4,5) = 1;
ModeTransitionMatrix(5,1) = 1;
% ModeTransitionMatrix(5,2) = 1;
% ModeTransitionMatrix(5,3) = 1;
% ModeTransitionMatrix(5,4) = 1;