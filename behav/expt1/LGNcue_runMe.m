%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run-me file for SP's LGN figure/ground cue experiment, dec 2018     %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% before starting: check that screen parameters in each of the scripts
%%% (_practice.m, _quest2.m, and _expt.m) are set for the tong lab displays:
%%% params.screenWidth, params.viewingDist, params.gammaCorrect, 
%%% params.whichCLUT, and Screen('Preference', 'SkipSyncTests',0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% step 1: instructions                                                %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Screen('Preference', 'SkipSyncTests', 1);
%%% show subject the powerpoint titled LGNcue_instructions.ppt!
subjNum = 12;    % entered by experimenter

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% step 2: run practice trials                                         %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numTrials = 8;  % multiples of 8
feedback = 1;

%%% these are easier AND slower than the actual task
trialLength = 3; flicker = .5;
LGNcue_practice(subjNum,numTrials,feedback,trialLength,flicker);

%%% mean hit rate is printed to command line - is it fairly high?

%%% these are easier but NOT slower than the actual task
trialLength = 2; flicker = .2;
LGNcue_practice(subjNum,numTrials,feedback,trialLength,flicker);

%%% mean hit rate is printed to command line - is it fairly high?

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% step 3: run quest staircase                                         %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% explain the basic premise of quest to the subject - if you get trials
% right, the task gets harder; if you get trials wrong, it gets easier.
% it's really important for us to find your threshold - the size of change
% at which you're ~85% correct on the task

numTrials = 32; % multiples of 8, per each questwho staircase
feedback = 1;
questBoth = 1;  % if 1, run two concurrent quest staircases on incongurent/congruent. 
                % if 0, just run quest on incongruent

%%% run linear version of dual-quest procedure
LGNcue_questLin(subjNum,questBoth,numTrials,feedback);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% step 4: run the study                                               %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cpdMult = 1.405     % entered by experimenter; the 'cpd factor' printed in
                    % the command line. should be >1.
                    % for now, use the estimate from the (incongruent + congruent thresh)/2
                    
numBlocks = [2:3];   % on day 2, run blocks [4:6], etc
numTrials = 120;     % multiples of 8
feedback = 1;
LGNcue_expt(subjNum,cpdMult,numBlocks,numTrials,feedback);





