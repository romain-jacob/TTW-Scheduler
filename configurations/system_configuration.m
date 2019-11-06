%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% system_configuration.m
% Configuration file for the whole system, including
% processors, applications, tasks, messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Licong Zhang, last update 18.12.16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
% configuration of processors
% Tuple: 
% - API_ID = 1: ID 
% - API_NM = 2: Name
% - API_MP = 3: Mapping - ***empty by initial configuration
% - API_CP = 4: Collision Pairs - ***empty by initial configuration
AP1 = {1,'AP1',{},{}};
AP2 = {2,'AP2',{},{}};
AP3 = {3,'AP3',{},{}};
AP4 = {4,'AP4',{},{}};
AP5 = {5,'AP5',{},{}};
AP6 = {6,'AP6',{},{}};
AP7 = {7,'AP7',{},{}};
AP8 = {8,'AP8',{},{}};
AP9 = {9,'AP9',{},{}};
AP10 = {10,'AP10',{},{}};
AP11 = {11,'AP11',{},{}};
AP12 = {12,'AP12',{},{}};
AP13 = {13,'AP13',{},{}};
AP14 = {14,'AP14',{},{}};
APs = {AP1,AP2,AP3,AP4,AP5,AP6,AP7,...
       AP8,AP9,AP10,AP11,AP12,AP13,AP14,...
       };
   
%%
% configuration of tasks
% Tuple: 
% - TI_ID = 1: ID 
% - TI_NM = 2: Name
% - TI_MP = 3: Mapping
% - TI_ET = 4: Execution Time
% - TI_PD = 5: Period - ***-1 by initial configuration
% - TI_NI = 6: Number of Instances - ***-1 by initial configuration
T1 = {1,'T1','AP1',1,-1,-1};
T2 = {2,'T2','AP6',1,-1,-1};
T3 = {3,'T3','AP1',1,-1,-1};
T4 = {4,'T4','AP1',1,-1,-1};
T5 = {5,'T5','AP7',1,-1,-1};
T6 = {6,'T6','AP1',1,-1,-1};
T7 = {7,'T7','AP2',1,-1,-1};
T8 = {8,'T8','AP6',1,-1,-1};
T9 = {9,'T9','AP2',1,-1,-1};
T10 = {10,'T10','AP2',1,-1,-1};
T11 = {11,'T11','AP7',1,-1,-1};
T12 = {12,'T12','AP2',1,-1,-1};
T13 = {13,'T13','AP3',1,-1,-1};
T14 = {14,'T14','AP6',1,-1,-1};
T15 = {15,'T15','AP3',1,-1,-1};
T16 = {16,'T16','AP3',1,-1,-1};
T17 = {17,'T17','AP7',1,-1,-1};
T18 = {18,'T18','AP3',1,-1,-1};
T19 = {19,'T19','AP4',1,-1,-1};
T20 = {20,'T20','AP6',1,-1,-1};
T21 = {21,'T21','AP4',1,-1,-1};
T22 = {22,'T22','AP4',1,-1,-1};
T23 = {23,'T23','AP7',1,-1,-1};
T24 = {24,'T24','AP4',1,-1,-1};
% T25 = {25,'T25','AP5',1,-1,-1};
% T26 = {26,'T26','AP6',1,-1,-1};
% T27 = {27,'T27','AP5',1,-1,-1};
T25 = {25,'T25','AP1',1,-1,-1}; %1
T26 = {26,'T26','AP7',1,-1,-1};
T27 = {27,'T27','AP1',1,-1,-1};
T28 = {28,'T28','AP5',1,-1,-1}; %10
T29 = {29,'T29','AP7',1,-1,-1}; %10
T30 = {30,'T30','AP5',1,-1,-1}; %10
T31 = {31,'T31','AP8',1,-1,-1};
T32 = {32,'T32','AP13',1,-1,-1};
T33 = {33,'T33','AP8',1,-1,-1};
T34 = {34,'T34','AP8',1,-1,-1};
T35 = {35,'T35','AP14',1,-1,-1};
T36 = {36,'T36','AP8',1,-1,-1};
T37 = {37,'T37','AP9',1,-1,-1};
T38 = {38,'T38','AP13',1,-1,-1};
T39 = {39,'T39','AP9',1,-1,-1};
T40 = {40,'T40','AP9',1,-1,-1};
T41 = {41,'T41','AP14',1,-1,-1};
T42 = {42,'T42','AP9',1,-1,-1};
T43 = {43,'T43','AP10',1,-1,-1};
T44 = {44,'T44','AP13',1,-1,-1};
T45 = {45,'T45','AP10',1,-1,-1};
T46 = {46,'T46','AP10',1,-1,-1};
T47 = {47,'T47','AP14',1,-1,-1};
T48 = {48,'T48','AP10',1,-1,-1};
T49 = {49,'T49','AP11',1,-1,-1};
T50 = {50,'T50','AP13',1,-1,-1};
T51 = {51,'T51','AP11',1,-1,-1};
T52 = {52,'T52','AP11',1,-1,-1};
T53 = {53,'T53','AP14',1,-1,-1};
T54 = {54,'T54','AP11',1,-1,-1};
T55 = {55,'T55','AP12',1,-1,-1};
T56 = {56,'T56','AP13',1,-1,-1};
T57 = {57,'T57','AP12',1,-1,-1};
T58 = {58,'T58','AP12',1,-1,-1};
T59 = {59,'T59','AP14',1,-1,-1};
T60 = {60,'T60','AP12',1,-1,-1};
Tasks = {T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,...
         T11,T12,T13,T14,T15,T16,T17,T18,T19,T20,...
         T21,T22,T23,T24,T25,T26,T27,T28,T29,T30,...
         T31,T32,T33,T34,T35,T36,T37,T38,T39,T40,...
         T41,T42,T43,T44,T45,T46,T47,T48,T49,T50,...
         T51,T52,T53,T54,T55,T56,T57,T58,T59,T60,...
         };  
     
     

%%
% configuration of messages
% Tuple: 
% - MI_ID = 1: ID 
% - MI_NM = 2: Name
% - MI_PD = 3: Period - ***-1 for initial configuration
% - MI_NI = 4: Number of instances - ***-1 for initial configuration
% - MI_LD = 5: Load(numer of slots needed)
M1 = {1,'M1',-1,-1,1};
M2 = {2,'M2',-1,-1,1};
M3 = {3,'M3',-1,-1,1};
M4 = {4,'M4',-1,-1,1};
M5 = {5,'M5',-1,-1,1};
M6 = {6,'M6',-1,-1,1};
M7 = {7,'M7',-1,-1,1};
M8 = {8,'M8',-1,-1,1};
M9 = {9,'M9',-1,-1,1};
M10 = {10,'M10',-1,-1,1};
M11 = {11,'M11',-1,-1,1};
M12 = {12,'M12',-1,-1,1};
M13 = {13,'M13',-1,-1,1};
M14 = {14,'M14',-1,-1,1};
M15 = {15,'M15',-1,-1,1};
M16 = {16,'M16',-1,-1,1};
M17 = {17,'M17',-1,-1,1};
M18 = {18,'M18',-1,-1,1};
M19 = {19,'M19',-1,-1,1};
M20 = {20,'M20',-1,-1,1};
M21 = {21,'M21',-1,-1,1};
M22 = {22,'M22',-1,-1,1};
M23 = {23,'M23',-1,-1,1};
M24 = {24,'M24',-1,-1,1};
M25 = {25,'M25',-1,-1,1};
M26 = {26,'M26',-1,-1,1};
M27 = {27,'M27',-1,-1,1};
M28 = {28,'M28',-1,-1,1};
M29 = {29,'M29',-1,-1,1};
M30 = {30,'M30',-1,-1,1};
M31 = {31,'M31',-1,-1,1};
M32 = {32,'M32',-1,-1,1};
M33 = {33,'M33',-1,-1,1};
M34 = {34,'M34',-1,-1,1};
M35 = {35,'M35',-1,-1,1};
M36 = {36,'M36',-1,-1,1};
M37 = {37,'M37',-1,-1,1};
M38 = {38,'M38',-1,-1,1};
M39 = {39,'M39',-1,-1,1};
M40 = {40,'M40',-1,-1,1};
Msgs = {M1,M2,M3,M4,M5,M6,M7,M8,M9,M10,M11,M12,M13,M14,M15,M16,M17,M18,M19,M20,...
        M21,M22,M23,M24,M25,M26,M27,M28,M29,M30,M31,M32,M33,M34,M35,M36,M37,M38,M39,M40,...
        };    

%%
% configuration of applications
% Tuple: 
% - AI_ID = 1: ID 
% - AI_NM = 2: Name
% - AI_PD = 3: Period
% - AI_DL = 4: Deadline
% - AI_TC = 5: Task chain
% - AI_NI = 6: Numer of instances - ***empty by initial configuration
% A1 = {1,'A1',20,20,{'T1','M1','T2','M2','T3'}};
A1 = {1,'A1',20,20,{'T1','M1','T2','M2','T3'}};
A2 = {2,'A2',20,20,{'T4','M3','T5','M4','T6'}};
A3 = {3,'A3',20,10,{'T7','M5','T8','M6','T9'}};
A4 = {4,'A4',20,20,{'T10','M7','T11','M8','T12'}};
A5 = {5,'A5',20,10,{'T13','M9','T14','M10','T15'}};
A6 = {6,'A6',10,10,{'T16','M11','T17','M12','T18'}};
A7 = {7,'A7',40,40,{'T19','M13','T20','M14','T21'}};
A8 = {8,'A8',40,40,{'T22','M15','T23','M16','T24'}};
A9 = {9,'A9',80,80,{'T25','M17','T26','M18','T27'}};
A10 = {10,'A10',80,80,{'T28','M19','T29','M20','T30'}};
A11 = {11,'A11',20,20,{'T31','M21','T32','M22','T33'}};
A12 = {12,'A12',20,20,{'T34','M23','T35','M24','T36'}};
A13 = {13,'A13',20,20,{'T37','M25','T38','M26','T39'}};
A14 = {14,'A14',10,10,{'T40','M27','T41','M28','T42'}};
A15 = {15,'A15',20,20,{'T43','M29','T44','M30','T45'}};
A16 = {16,'A16',40,40,{'T46','M31','T47','M32','T48'}};
A17 = {17,'A17',40,30,{'T49','M33','T50','M34','T51'}};
A18 = {18,'A18',40,40,{'T52','M35','T53','M36','T54'}};
A19 = {19,'A19',80,40,{'T55','M37','T56','M38','T57'}};
A20 = {20,'A20',80,40,{'T58','M39','T59','M40','T60'}};
% APPs = {A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,...
%            A11,A12,A13,A14,A15,A16,A17,A18,A19,A20,...
%            }; 
APPs = {A1,A2,A3,A4,A5,A6,A8,A9,A10,...
           A11,A12,A13,A14,A18,A19...
           }; 
% Convert to ms
for i=1:numel(APPs)
    APPs{i}{3} = APPs{i}{3}*1000;
    APPs{i}{4} = APPs{i}{4}*1000;
end

%%
% Custom constraints
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
% Valid: '=' or '<'
% /!\ the inequality contraints are interpreted as loose!
% /!\ '<' actually means '<='
% - CCI_RHS = 3: Right-hand side of constraint, must be a constant

CustomConstaints = {};       
