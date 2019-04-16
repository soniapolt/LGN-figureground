function LGNfigure_attn(subject,runNum,subjectNum,offset,deviceNumber)
% this version gets rid of the congruent condition
% 136 TRs

Screen('Preference', 'SkipSyncTests',0);
params.gammaCorrect = 1;       % make sure this = 1 when you're at the scanner!
experiment.subjectNum = subjectNum;
hz = 60;     % at scanner this is 60, on LED displays it is 0

input('Hit enter to proceed.');

% in this study resolution will be super important for timing!!
% ResolutionTest
% hz = 0;
experiment.oldRes = SetResolution(max(Screen('Screens')),1024,768,hz);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%take these out for the actual scan!
% clear all;
% offset = +50;
% [keyboardIndices, productNames, ~] = GetKeyboardIndices;
% deviceNumber =keyboardIndices;
% runNum = 2;
% subject = 'test';
% Screen('Preference', 'SkipSyncTests', 1);
% params.gammaCorrect = 0;       % make sure this = 1 when you're at the scanner!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% input this at the beginning of the scan session for 7T
params.vertOffset = offset;    % vertical offset from FindScreenSize.m
params.whichCLUT = '7T_Sam.mat'; %'linearizedCLUT_SoniaMPB.mat';

%%% basic naming set-up
experiment.subject = subject;
experiment.scanNum = runNum; % to keep both of these structs labeled
%%%% scales all of the stimuli in DVA to the screensize
params.screenWidth = 19;             % in cm; %laptop=27.5,office=43, %19=%T3b, miniHelm=39;
params.viewingDist = 48;             % in cm; 3Tb/office=43, miniHelm=57;


%%%% set-up rand
rand('twister', sum(100*clock));
experiment.rand = rand;

%%%% files and things
experiment.root = pwd; %'/Users/Sonia/Desktop/ObjectRF/';
experiment.date = datestr(now,30);

%%%% timing
params.blockLength = 16;            % in seconds
params.betweenBlocks = 16;          % in seconds
params.initialFixation = 16;        % in seconds
params.finalFixation = 16;          % in seconds
params.phaseFlicker = .2;           % in seconds (on for Xs, off for Xs, phase changes

%%%% noise
params.stim.contrast =  1;%.50;                                                % in %, maybe??
params.stim.orientations = [45 135];                                        % in degrees
params.stim.gaborSizeDeg = 4;                                               % in degrees, diameter
params.stim.fromFixation = 1;                                               % in degrees, edge of stimulus annulus
params.stim.gapDeg = 0.25;                                                   % in pixels, thickness of greyscale ring separating
params.stim.orientNoise = 10;                                               % in degrees, +/- width of the filter
params.stim.fLowCPD =  .25;                                                 % in cycles per degree
params.stim.fHighCPD = 8;                                                   % in cycles per degree
params.stim.fTaskCPD = 3;                                                   % in cpd, change of spatial frequency that marks a target
params.stim.flicker = [1 1];                                                % [1 1] for constant motion [1 0] for flicker

%%%% conditions & layout
params.numOrientations = length(params.stim.orientations);
params.attendLocs = [1 2];   % attend L or R
params.incongLocs = [1 2];   % attend L or R
params.numConds = params.numOrientations * length(params.attendLocs) * length(params.incongLocs);
params.fixSizeDeg =  .33;            % in degrees, the diameter of the biggest white dot in the fixation
params.littleFixDeg = params.fixSizeDeg* .5;    % proportion of the fixSizeDeg occupied by the smaller black dot
params.outerFixPixels = 2;          % in pixels, the black ring around fixation
params.TRlength = 2;                % in seconds
params.repsPerRun = 1;              % repetitions of each object type x location
experiment.totalTime = params.initialFixation+(params.numConds*params.repsPerRun*params.blockLength)+((params.numConds*params.repsPerRun-1)*params.betweenBlocks)+params.finalFixation;
experiment.totalMins = experiment.totalTime/60;

%%%% screen
params.backgroundColor = [127 127 127];  % color
params.fontSize = 20;


%%%% task - detect SF change in either the left or right figure
params.task.prob = .05;             % proportion of intervals where the target appears
params.task.rate = .2;               % duration of color change
params.task.buffer = 4;              % no targets in the first/last X flips
params.task.repCheck = 2;           % no targets within X flips of each other
params.task.responseBack = 4;            % the response is correct if the preceding N letters were the target
params.task.cueBefore = 1;               % in seconds, how far ahead of block start do we show the attention cue?
params.task.cueSizeDeg = params.fixSizeDeg*.4;
params.task.cueOffsetDeg = params.fixSizeDeg/2 + .2; % how far off center the cues appear

%%%% subject performs task on either left or right targets
experiment.task = 'attend L/R';
if mod(experiment.subjectNum,2) ==1
    experiment.cueColor = [255 255 255];
    experiment.notCueColor = [0 0 0];
    experiment.cueText = 'white';
else experiment.cueColor = [0 0 0];
    experiment.notCueColor = [255 255 255];
    experiment.cueText = 'black';
end

%%%% final few structs
experiment.performance = [];
experiment.allFlips = (0:params.phaseFlicker:experiment.totalTime);

%%%% response listening - so we don't read in scanner triggers!
responseKeys = zeros(1,256);
responseKeys(KbName('1!'))=1; % button box 1
responseKeys(KbName('2@'))=1; % button box 2


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CONDITIONS & TIMING MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% set up our structs
dummySurround = (kron([1:params.numOrientations]', ones(params.numConds/params.numOrientations,1)))';
dummyAttend = repmat(params.attendLocs,[1,params.numConds/length(params.attendLocs)]);
dummyIncong = repmat(Expand(params.incongLocs,2,1),1,2);

for n = 1:length(dummySurround)
    conditions(n).attendLoc = dummyAttend(n);
    conditions(n).incongLoc = dummyIncong(n);
    conditions(n).surround = dummySurround(n);
    if conditions(n).incongLoc == 1
        conditions(n).leftO = abs(conditions(n).surround-3);
        conditions(n).rightO = conditions(n).surround;
    else conditions(n).leftO = conditions(n).surround;
        conditions(n).rightO = abs(conditions(n).surround-3);end
    conditions(n).startTimes = [];
end

experiment.condShuffle = Shuffle(repmat([1:params.numConds],1,params.repsPerRun));
experiment.numBlocks = length(experiment.condShuffle);

%%%% longform condition timing, which aligns with the flicker timing
experiment.longFormConds = zeros(params.initialFixation/params.phaseFlicker,1);
for n = (1:experiment.numBlocks-1)
    experiment.longFormConds = [experiment.longFormConds; repmat(experiment.condShuffle(n),params.blockLength/params.phaseFlicker,1)]; % blocks
    experiment.longFormConds = [experiment.longFormConds; zeros(params.betweenBlocks/params.phaseFlicker,1)]; % inter-block blanks
end
experiment.longFormConds = [experiment.longFormConds; repmat(experiment.condShuffle(experiment.numBlocks),params.blockLength/params.phaseFlicker,1); zeros(params.finalFixation/params.phaseFlicker,1)]; % the last block

%%%% create the timing model for this particular run
counter = params.initialFixation;
for n=1:experiment.numBlocks
    experiment.startBlock(n) = counter; % timestamp (s) of when each block should start
    conditions(experiment.condShuffle(n)).startTimes = [conditions(experiment.condShuffle(n)).startTimes counter]; % add timestamps to the condition struct
    counter = counter + params.blockLength + params.betweenBlocks; % and progress the counter
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TASK AND CUES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% find the target positioning for this run
experiment.numTargets = 0;
for n = params.attendLocs
    targetInd = zeros(1,params.initialFixation/params.task.rate);
    for m = 1:experiment.numBlocks
        blockTargets(m,n) = length(find(rand(1,params.blockLength/params.task.rate)<params.task.prob));
        if blockTargets(m,n) == 0 blockTargets(m,n) = 1; end
        thisBlock =  zeros(1,params.blockLength/params.task.rate);
        while 1
            maybeTarget= params.task.buffer+Randi(length(thisBlock)-2*params.task.buffer);
            if sum(thisBlock(maybeTarget-params.task.repCheck:maybeTarget-1)) == 0 && sum(thisBlock(maybeTarget+1:maybeTarget+params.task.repCheck)) == 0
                thisBlock(maybeTarget) = 1;
            end
            if sum(thisBlock) == blockTargets(m,n)
                break
            end
        end
        if conditions(experiment.condShuffle(m)).attendLoc == n
        experiment.numTargets = experiment.numTargets + blockTargets(m,n); end
        targetInd = [targetInd thisBlock];
        % between blocks - no targets
        if m < experiment.numBlocks;
            targetInd = [targetInd zeros(1,params.betweenBlocks/params.task.rate)];
        end
    end
    % final fixation - no targets
    targetInd = [targetInd zeros(1,params.finalFixation/params.task.rate)];
    % expand
    experiment.longTargets(n,:) = Expand(targetInd,params.task.rate/params.phaseFlicker,1);
end

% set up cues for the task (attend L or R)
experiment.cueConds = [conditions(experiment.condShuffle).attendLoc];
cueInSeconds = [zeros(1,params.initialFixation-params.task.cueBefore)];
for n = 1:experiment.numBlocks-1
    cueInSeconds = [cueInSeconds kron(experiment.cueConds(n),ones(1,params.blockLength+params.task.cueBefore))]; % add cue
    cueInSeconds = [cueInSeconds zeros(1,params.betweenBlocks-params.task.cueBefore)];
end

% last block
cueInSeconds = [cueInSeconds kron(experiment.cueConds(experiment.numBlocks),ones(1,params.blockLength+params.task.cueBefore))]; % add last block
cueInSeconds = [cueInSeconds zeros(1,params.finalFixation)]; % add final fix
experiment.longCues = kron(cueInSeconds',ones(round(1/params.phaseFlicker),1));

experiment.longFlicker = repmat(params.stim.flicker,1,length(experiment.longTargets)/2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% OPEN SCREEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
HideCursor;
Priority(9);

%%%% open screen
screen=max(Screen('Screens'));
[win, rect]=Screen('OpenWindow',screen,params.backgroundColor,[],[],[],[],[],kPsychNeed32BPCFloat);
Screen(win, 'TextSize', params.fontSize);
Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%%%% gamma correction
if params.gammaCorrect > 0
    load(params.whichCLUT);
    Screen('LoadNormalizedGammaTable', screen, linearizedCLUT);
end

%%%% timing optimization
flipInt = Screen('GetFlipInterval',win);
slack = flipInt/2;

%%%% scale the stims for the screen
params.ppd = pi* rect(3) / (atan(params.screenWidth/params.viewingDist/2)) / 360;
params.gaborSize = round(params.stim.gaborSizeDeg*params.ppd);                 % in degrees, the size of our objects
params.fixSize = round(params.fixSizeDeg*params.ppd);
params.littleFix = round(params.littleFixDeg*params.ppd);
params.gapPix = params.stim.gapDeg*params.ppd;
params.task.cueSize= round(params.task.cueSizeDeg*params.ppd);
params.task.cueOffset = round(params.task.cueOffsetDeg*params.ppd);

%%% filtering properties
params.filtSize = rect(4);
params.fLow = params.stim.fLowCPD * params.filtSize/params.ppd;
params.fHigh = params.stim.fHighCPD * params.filtSize/params.ppd;
params.fNyquist = params.filtSize/2;
params.fTask = params.stim.fTaskCPD * params.filtSize/params.ppd;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% WAIT FOR BACKTICK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xc = rect(3)/2; % rect and center, with the flixibility to resize & shift center - change vars to zero if not used.
yc = rect(4)/2+params.vertOffset;

%%%% initial window - wait for backtick
Screen(win, 'DrawText', 'Waiting for Backtick.', 10,10,[0 0 0]);
[width,height] = RectSize(Screen('TextBounds',win,['Attend ' experiment.cueText]));
Screen(win, 'DrawText', ['Attend ' experiment.cueText], xc-width/2, yc-height/2,experiment.cueColor);
Screen(win, 'Flip', 0);

KbTriggerWait(53, deviceNumber);
KbQueueCreate(deviceNumber,responseKeys);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LOCATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% locations of things
params.dispRect = CenterRectOnPoint([0 0 rect(4) rect(4)],xc,yc);
% left figure
params.targetRect{1}  = CenterRectOnPoint([0 0 params.gaborSize params.gaborSize],xc-params.stim.fromFixation*params.ppd-params.gaborSize/2,yc);
% right figure
params.targetRect{2} =  CenterRectOnPoint([0 0 params.gaborSize params.gaborSize],xc+params.stim.fromFixation*params.ppd+params.gaborSize/2,yc);

for n = 1:length(params.targetRect)
    if params.filtSize == rect(4)
        params.apertureRect{n} = OffsetRect(params.targetRect{n},-(rect(3)-rect(4))/2,-params.vertOffset);
    elseif params.filtSize == rect(3)
        params.apertureRect{n} = OffsetRect(params.targetRect{n},-params.vertOffset,(rect(3)-rect(4))/2);
    end
    % adjust so gap is outside the target dimensions
    params.gapRect{n} = params.targetRect{n} + [-params.gapPix -params.gapPix params.gapPix params.gapPix];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% FILTERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SURROUND-sized gaussian filter
params.stim.gaussSD = round(params.filtSize*.005);params.stim.gaussSize = round(params.filtSize*.1);
gFilt = customgauss([params.stim.gaussSize params.stim.gaussSize], params.stim.gaussSD, params.stim.gaussSD, 0, 0, 1, [0,0]);

%%% two bandpass filters
for n = 1:length(params.stim.orientations)
    orientFilter=OrientationBandpass(params.filtSize,(params.stim.orientations(n))-params.stim.orientNoise,(params.stim.orientations(n))+params.stim.orientNoise);
    bandpassFilter = Bandpass2(params.filtSize, params.fLow/params.fNyquist,params.fHigh/params.fNyquist); % create 2d bandpass filter
    targetFilter = Bandpass2(params.filtSize, (params.fLow+params.fTask)/params.fNyquist,(params.fHigh+params.fTask)/params.fNyquist); % create 2d bandpass filter
    filtSFO = bandpassFilter.*orientFilter;
    targfiltSFO = targetFilter.*orientFilter;
    smoothSFO{n} = filter2(gFilt,filtSFO);
    targSFO{n} = filter2(gFilt,targfiltSFO);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                         experiment                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% start recording the response
KbQueueStart();
experiment.numCorrect = 0;
experiment.correctTarget = [];
experiment.numFA = 0;
experiment.FATarget = [];
flipCount = 1;

%%%%%%% START task TASK/FLIPPING
for n = 1:(length(experiment.allFlips)-1)
    thisCond = experiment.longFormConds(n);
    
    %%%% draw gabors
    if thisCond > 0 && experiment.longFlicker(n)>0 % zeros correspond to blanks, in which case we skip this next section
        
        %tic
        % generate this center left & right stims
        left=rand(params.filtSize); right = rand(params.filtSize);
        % apply filter to noise in fourier space
        if experiment.longTargets(1,n) == 1 % if left is target
            left=targSFO{conditions(thisCond).leftO}.*fftshift(fft2(left));
        else
            left=smoothSFO{conditions(thisCond).leftO}.*fftshift(fft2(left)); end
        if experiment.longTargets(2,n) == 1 % if right is target
            right=targSFO{conditions(thisCond).rightO}.*fftshift(fft2(right));
        else
            right=smoothSFO{conditions(thisCond).rightO}.*fftshift(fft2(right)); end
        
        % tranform back to real domain
        left=real(ifft2(ifftshift(left))); right=real(ifft2(ifftshift(right)));
        
        % varying the contrast/intensity range)
        left = (left-mean(left(:)) ) / ( max(left(:)) - min(left(:)) ); % [min(tmp(:))  max(tmp(:))]
        left = left/max( abs([min(left(:))  max(left(:))] ) ) * max( [params.backgroundColor(1)-0  255-params.backgroundColor(1)]) + params.backgroundColor(1); % [min(tmp(:))  max(tmp(:))]
        left = (left-params.backgroundColor(1)).*params.stim.contrast + params.backgroundColor(1);
        
        right = (right-mean(right(:)) ) / ( max(right(:)) - min(right(:)) ); % [min(tmp(:))  max(tmp(:))]
        right = right/max( abs([min(right(:))  max(right(:))] ) ) * max( [params.backgroundColor(1)-0  255-params.backgroundColor(1)]) + params.backgroundColor(1); % [min(tmp(:))  max(tmp(:))]
        right = (right-params.backgroundColor(1)).*params.stim.contrast + params.backgroundColor(1);
        
        
        %toc
        
        leftTex = Screen('MakeTexture',win,left);
        Screen('DrawTexture', win, leftTex,[],params.dispRect); % draw left
        rightTex = Screen('MakeTexture',win,right);
        Screen('FillOval', rightTex, [255 255 255 0],params.apertureRect{1}); % left aperture
        Screen('DrawTexture', win, rightTex,[],params.dispRect); % draw right, make left visible through it
        
        % surround
        surround=rand(params.filtSize);
        % apply filter to noise in fourier space
        surround=smoothSFO{conditions(thisCond).surround}.*fftshift(fft2(surround));
        % tranform back to real domain
        surround=real(ifft2(ifftshift(surround)));
        
        % varying the contrast/intensity range)
        surround = ( surround-mean(surround(:)) ) / ( max(surround(:)) - min(surround(:)) ); % [min(tmp(:))  max(tmp(:))]
        surround = surround/max( abs([min(surround(:))  max(surround(:))] ) ) * max( [params.backgroundColor(1)-0  255-params.backgroundColor(1)]) + params.backgroundColor(1); % [min(tmp(:))  max(tmp(:))]
        surround = (surround-params.backgroundColor(1)).*params.stim.contrast + params.backgroundColor(1);
        
        sTex = Screen('MakeTexture',win,surround);
        Screen('FillOval', sTex, [255 255 255 0],params.apertureRect{1}); % left aperture
        Screen('FillOval', sTex, [255 255 255 0],params.apertureRect{2}); % right aperture
        Screen('DrawTexture', win, sTex,[],params.dispRect);
        Screen('Close', sTex);
        
        
        % add outline - outside figure dims
        Screen('FrameOval',win,params.backgroundColor,params.gapRect{1},params.gapPix,params.gapPix);
        Screen('FrameOval',win,params.backgroundColor,params.gapRect{2},params.gapPix,params.gapPix);
        Screen('Close', leftTex);Screen('Close', rightTex);
    end
    
    %%%% draw fixation big circle
    Screen('FillOval', win,[0 0 0], [xc-round(params.fixSize/2+params.outerFixPixels ) yc-round(params.fixSize/2+params.outerFixPixels ) xc+round(params.fixSize/2+params.outerFixPixels ) yc+round(params.fixSize/2+params.outerFixPixels )]); % black fixation ring
    Screen('FillOval', win,[255 255 255], [xc-round(params.fixSize/2) yc-round(params.fixSize/2) xc+round(params.fixSize/2) yc+round(params.fixSize/2)]); % white fixation ring
    
    if experiment.longCues(n)==1 % cue left
        % left circle
        Screen('FillOval',win,experiment.cueColor,[xc-params.task.cueOffset-round(params.task.cueSize/2) yc-round(params.task.cueSize/2) xc-params.task.cueOffset+round(params.task.cueSize/2) yc+round(params.task.cueSize/2)]);
        % right circle
        Screen('FillOval',win,experiment.notCueColor,[xc+params.task.cueOffset-round(params.task.cueSize/2) yc-round(params.task.cueSize/2) xc+params.task.cueOffset+round(params.task.cueSize/2) yc+round(params.task.cueSize/2)]);
    elseif experiment.longCues(n)==2 % cue right
        % left circle
        Screen('FillOval',win,experiment.notCueColor,[xc-params.task.cueOffset-round(params.task.cueSize/2) yc-round(params.task.cueSize/2) xc-params.task.cueOffset+round(params.task.cueSize/2) yc+round(params.task.cueSize/2)]);
        % right circle
        Screen('FillOval',win,experiment.cueColor,[xc+params.task.cueOffset-round(params.task.cueSize/2) yc-round(params.task.cueSize/2) xc+params.task.cueOffset+round(params.task.cueSize/2) yc+round(params.task.cueSize/2)]);
    end
    % little fixation dot
    Screen('FillOval', win,[0 0 0], [xc-round(params.littleFix/2) yc-round(params.littleFix/2) xc+round(params.littleFix/2) yc+round(params.littleFix/2)]); % black fixation dot
    
    %%%%%%%%%%% FLIP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if n == 1 [VBLT experiment.startRun FlipT missed] = Screen(win, 'Flip', 0);
        experiment.flipTime(n) = experiment.startRun;
    else [VBLT experiment.flipTime(n) FlipT missed] = Screen(win, 'Flip', experiment.startRun + experiment.allFlips(n) - slack);end
    
    % listen for response  - correct if you respond to previous 3 letters
    if thisCond > 0
        [pressed, firstPress]= KbQueueCheck();
            %         if pressed == 1 presses = [presses n]; end
            targetRange = experiment.longTargets(conditions(thisCond).attendLoc,n - params.task.responseBack-1:n-1);
            if (pressed ==1) && (sum(targetRange)>0)
                experiment.numCorrect = experiment.numCorrect + 1;
                experiment.correctTarget = [experiment.correctTarget n];
            elseif (pressed ==1) && (sum(targetRange)==0)
                experiment.numFA = experiment.numFA + 1;
                experiment.FATarget = [experiment.FATarget n];
            end % then it's correct
            KbQueueFlush();
    end
end
%%%% to show the very last flip screen for its 200ms
[VBLT experiment.flipTime(n+1) FlipT missed] = Screen(win, 'Flip', experiment.startRun + experiment.allFlips(length(experiment.allFlips)) - slack);

%%%%%%%%%%%%%%%%%%
% done! wrap up  %
%%%%%%%%%%%%%%%%%%

experiment.runTime = GetSecs - experiment.startRun;
experiment.performance = experiment.numCorrect/experiment.numTargets;

eval(['save data/LGNfigureAttn_' experiment.subject '_run' num2str(experiment.scanNum) '_' experiment.date '.mat params conditions experiment']);
eval(['save data/runOutput_' num2str(experiment.scanNum) '.mat params conditions experiment']);


KbQueueRelease();
ShowCursor;
Screen('Close');
Screen('CloseAll');
fprintf('Hit rate this run: %.2f%%\n',100*experiment.performance)
fclose all;
clear all;

%end


