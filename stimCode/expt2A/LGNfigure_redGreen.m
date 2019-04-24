function LGNfigure_redGreen(subject,runNum,offset,deviceNumber)
% this version gets rid of the congruent condition
% 136 TRs
% clear all;
Screen('Preference', 'SkipSyncTests',0);
params.gammaCorrect = 1;       % make sure this = 1 when you're at the scanner!
hz = 60;     % at scanner this is 60, on LED displays it is 128

input('Hit enter to proceed.');

% in this study resolution will be super important for timing!!
% ResolutionTest
experiment.oldRes = SetResolution(max(Screen('Screens')),1024,768,hz);

params.redMax = 256; % fixed - red is always darker at 7T
params.greenMax = 200; % 2 X matched green!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%take these out for the actual scan!

%offset = -30;
%[keyboardIndices, productNames, ~] = GetKeyboardIndices;
%deviceNumber =keyboardIndices;
%runNum = 15;
%subject = 'test';
%experiment.subjectNum = 1;
%Screen('Preference', 'SkipSyncTests', 1);
%params.gammaCorrect = 1;       % make sure this = 1 when you're at the scanner!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% input this at the beginning of the scan session for 7T
params.vertOffset = offset;    % vertical offset from FindScreenSize.m
params.whichCLUT = '7T_Sam.mat'; %'linearizedCLUT_SoniaMPB.mat';

%%% basic naming set-up
experiment.subject = subject;
experiment.scanNum = runNum; % to keep both of these structs labeled

%%%% scales all of the stimuli in DVA to the screensize
params.screenWidth = 17;             % in cm; %laptop=27.5,office=43, %19=%T3b, miniHelm=39;
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
params.stim.contrast =  1;                                                % in %, maybe??
params.stim.orientations = [45 135];                                        % in degrees
params.stim.gaborSizeDeg = 4;                                               % in degrees, diameter
params.stim.fromFixation = 1;                                               % in degrees, edge of stimulus annulus
params.stim.gapDeg = 0.15;                                                   % in pixels, thickness of greyscale ring separating
params.stim.orientNoise = 10;                                               % in degrees, +/- width of the filter
params.stim.fLowCPD =  .25;  % orig .25                                               % in cycles per degree
params.stim.fHighCPD = 8;    % orig 8                                               % in cycles per degree
params.stim.fTaskCPD = 3;  % orig 3                                                 % in cpd, change of spatial frequency that marks a target
params.stim.flicker = [1 1];                                                % [1 1] for constant motion [1 0] for flicker

%%%% conditions & layout
params.numOrientations = length(params.stim.orientations);
params.incongLocs = [1 2];   % attend L or R
params.numConds = params.numOrientations * length(params.incongLocs);
params.fixSizeDeg =  .5;            % in degrees, the diameter of the biggest white dot in the fixation
params.littleFixDeg = params.fixSizeDeg* .7;    % proportion of the fixSizeDeg occupied by the smaller black dot
params.outerFixPixels = 2;          % in pixels, the black ring around fixation
params.TRlength = 2;                % in seconds
params.repsPerRun = 1;              % repetitions of each object type x location
experiment.totalTime = params.initialFixation+(params.numConds*2*params.repsPerRun*params.blockLength)+((params.numConds*2*params.repsPerRun-1)*params.betweenBlocks)+params.finalFixation;
experiment.totalMins = experiment.totalTime/60;

%%%% screen
params.mids = [params.redMax/2 params.greenMax/2]; % red, green
params.backgroundColor = [params.mids 0];  % color
params.fontSize = 20;

%%%% task - detect contrast decrement on fusion fixation
params.task.prob = .05;             % proportion of intervals where the target appears
params.task.rate = .2;               % duration of color change
params.task.buffer = 4;              % no targets in the first/last X flips
params.task.repCheck = 2;           % no targets within X flips of each other
params.task.responseBack = 4;            % the response is correct if the preceding N letters were the target
params.task.contrastDec = .5;
params.task.offset =  round([params.redMax params.greenMax 0]-([params.redMax params.greenMax 0].*((params.task.contrastDec+1)./2)));

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
dummyIncong = repmat(Expand(params.incongLocs,2,1),1,2);

%%% important - in this version, the irrelevant orientation conditions are
%%% randomized, but the relevant eye-presentation conditions are hardcoded

for n = 1:length(dummySurround)
    conditions(n).surround = dummySurround(n);
    conditions(n).incongLoc = dummyIncong(n);
    if conditions(n).incongLoc == 1
        conditions(n).leftO = abs(conditions(n).surround-3);
        conditions(n).rightO = conditions(n).surround;
    else conditions(n).leftO = conditions(n).surround;
        conditions(n).rightO = abs(conditions(n).surround-3);end
    conditions(n).startTimes = [];
end

% since we need all of these things once per our eye condition
experiment.condShuffle = Shuffle(repmat([1:params.numConds],1,params.repsPerRun*2));
experiment.numBlocks = length(experiment.condShuffle);

% now, the hardcoded eye conditions
if mod(experiment.scanNum,2) ==1
    experiment.surrEye = ones(1,experiment.numBlocks); % surround in red eye
    if mod(experiment.scanNum,3) == 1;
        experiment.figEye = repmat([1 2],1,experiment.numBlocks/2);
    else experiment.figEye = repmat([2 1],1,experiment.numBlocks/2); end
else
    experiment.surrEye = 2*ones(1,experiment.numBlocks);
    if mod(experiment.scanNum,4) == 2;
        experiment.figEye = repmat([2 1],1,experiment.numBlocks/2);
    else experiment.figEye = repmat([1 2],1,experiment.numBlocks/2); end
end

%%%% long condition timing, which aligns with the flicker timing
experiment.longConds = zeros(params.initialFixation/params.phaseFlicker,1);
experiment.longSurrEye = experiment.longConds; experiment.longFigEye = experiment.longConds;
for n = (1:experiment.numBlocks-1)
    experiment.longConds = [experiment.longConds; repmat(experiment.condShuffle(n),params.blockLength/params.phaseFlicker,1)]; % blocks
    experiment.longConds = [experiment.longConds; zeros(params.betweenBlocks/params.phaseFlicker,1)]; % inter-block blanks
    experiment.longSurrEye = [experiment.longSurrEye; repmat(experiment.surrEye(n),(params.betweenBlocks+params.blockLength)/params.phaseFlicker,1)]; % blocks & blanks (eye doesn't matter in blanks)
    experiment.longFigEye = [experiment.longFigEye; repmat(experiment.figEye(n),(params.betweenBlocks+params.blockLength)/params.phaseFlicker,1)]; % blocks & blanks (eye doesn't matter in blanks)
end
experiment.longConds = [experiment.longConds; repmat(experiment.condShuffle(experiment.numBlocks),params.blockLength/params.phaseFlicker,1); zeros(params.finalFixation/params.phaseFlicker,1)]; % the last block
experiment.longSurrEye = [experiment.longSurrEye; repmat(experiment.surrEye(experiment.numBlocks),params.blockLength/params.phaseFlicker,1); zeros(params.finalFixation/params.phaseFlicker,1)]; % the last block
experiment.longFigEye = [experiment.longFigEye; repmat(experiment.figEye(experiment.numBlocks),params.blockLength/params.phaseFlicker,1); zeros(params.finalFixation/params.phaseFlicker,1)]; % the last block

%%%% create the timing model for this particular run
counter = params.initialFixation;
for n=1:experiment.numBlocks
    experiment.startBlock(n) = counter; % timestamp (s) of when each block should start
    conditions(experiment.condShuffle(n)).startTimes = [conditions(experiment.condShuffle(n)).startTimes counter]; % add timestamps to the condition struct
    counter = counter + params.blockLength + params.betweenBlocks; % and progress the counter
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TASK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% find the target positioning for this run
experiment.numTargets = 0;
targetInd = zeros(1,params.initialFixation/params.task.rate);
for m = 1:experiment.numBlocks
    blockTargets(m) = length(find(rand(1,params.blockLength/params.task.rate)<params.task.prob));
    if blockTargets(m) == 0 blockTargets(m) = 1; end
    thisBlock =  zeros(1,params.blockLength/params.task.rate);
    while 1
        maybeTarget= params.task.buffer+Randi(length(thisBlock)-2*params.task.buffer);
        if sum(thisBlock(maybeTarget-params.task.repCheck:maybeTarget-1)) == 0 && sum(thisBlock(maybeTarget+1:maybeTarget+params.task.repCheck)) == 0
            thisBlock(maybeTarget) = 1;
        end
        if sum(thisBlock) == blockTargets(m)
            break
        end
    end
    experiment.numTargets = experiment.numTargets + blockTargets(m);
    targetInd = [targetInd thisBlock];
    % between blocks - no targets
    if m < experiment.numBlocks;
        targetInd = [targetInd zeros(1,params.betweenBlocks/params.task.rate)];
    end
end
% final fixation - no targets
targetInd = [targetInd zeros(1,params.finalFixation/params.task.rate)];
% expand
experiment.longTargets = Expand(targetInd,params.task.rate/params.phaseFlicker,1);

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
    filtSFO = bandpassFilter.*orientFilter;
    smoothSFO{n} = filter2(gFilt,filtSFO);
end
stimNames = {'left','right'};

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
    thisCond = experiment.longConds(n);
    
    %%%% draw gabors
    if thisCond > 0 && experiment.longFlicker(n)>0 % zeros correspond to blanks, in which case we skip this next section
        figMid = params.mids(experiment.longFigEye(n)); otherMid = params.mids(abs(experiment.longFigEye(n)-3));
        % generate left & right stims
        for s = 1:length(stimNames)
            stim=rand(params.filtSize);
            % apply filter to noise in fourier space
            % stim=smoothSFO{conditions(thisCond).rightO}.*fftshift(fft2(stim));
            eval(['stim=smoothSFO{conditions(thisCond).' stimNames{s} 'O}.*fftshift(fft2(stim));']);
            % tranform back to real domain
            stim=real(ifft2(ifftshift(stim)));
            % varying the contrast/intensity range)
            stim = (stim-mean(stim(:)) ) / ( max(stim(:)) - min(stim(:)) );
            stim = stim/max( abs([min(stim(:))  max(stim(:))] ) ) * figMid + figMid;
            stim = (stim-figMid).*params.stim.contrast +figMid;
            
            % right is 0 to 255
            colorStim = cat(3,zeros(size(stim)),zeros(size(stim)),zeros(size(stim)));
            colorStim(:,:,experiment.longFigEye(n)) = stim;
            colorStim(:,:,abs(experiment.longFigEye(n)-3)) = otherMid*ones(size(stim));
        
            eval(['color' stimNames{s} '= colorStim;']);
            %toc
        end
        
        leftTex = Screen('MakeTexture',win,colorleft);
        Screen('DrawTexture', win, leftTex,[],params.dispRect); % draw left
        rightTex = Screen('MakeTexture',win,colorright);
        Screen('FillOval', rightTex, [255 255 255 0],params.apertureRect{1}); % left aperture
        Screen('DrawTexture', win, rightTex,[],params.dispRect); % draw right, make left visible through it
        
        % surround
        surround=rand(params.filtSize);
        % apply filter to noise in fourier space
        surround=smoothSFO{conditions(thisCond).surround}.*fftshift(fft2(surround));
        % tranform back to real domain
        surround=real(ifft2(ifftshift(surround)));
        
        % varying the contrast/intensity range)
        surrMid = params.mids(experiment.longSurrEye(n)); otherMid = params.mids(abs(experiment.longSurrEye(n)-3));
        stim = ( surround-mean(surround(:)) ) / ( max(surround(:)) - min(surround(:)) );
        stim = stim/max( abs([min(stim(:))  max(stim(:))] ) ) * surrMid + surrMid;
        stim = (stim-surrMid).*params.stim.contrast + surrMid;
        
        colorS= cat(3,zeros(size(stim)),zeros(size(stim)),zeros(size(stim)));
        colorS(:,:,experiment.longSurrEye(n)) = stim;
        colorS(:,:,abs(experiment.longSurrEye(n)-3)) = otherMid*ones(size(stim));
        
        sTex = Screen('MakeTexture',win,colorS);
        Screen('FillOval', sTex, [255 255 255 0],params.apertureRect{1}); % left aperture
        Screen('FillOval', sTex, [255 255 255 0],params.apertureRect{2}); % right aperture
        Screen('DrawTexture', win, sTex,[],params.dispRect);
        Screen('Close', sTex);
        
        
        % add outline - outside figure dims
        Screen('FrameOval',win,params.backgroundColor,params.gapRect{1},params.gapPix,params.gapPix);
        Screen('FrameOval',win,params.backgroundColor,params.gapRect{2},params.gapPix,params.gapPix);
        Screen('Close', leftTex);Screen('Close', rightTex);
    end
    
    redGreenFix(win,params,xc,yc,experiment.longTargets(n));
    %%%%%%%%%%% FLIP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if n == 1 [VBLT experiment.startRun FlipT missed] = Screen(win, 'Flip', 0);
        experiment.flipTime(n) = experiment.startRun;
    else [VBLT experiment.flipTime(n) FlipT missed] = Screen(win, 'Flip', experiment.startRun + experiment.allFlips(n) - slack);end
    
    % listen for response  - correct if you respond to previous 3 letters
    if thisCond > 0
        [pressed, firstPress]= KbQueueCheck();
        %         if pressed == 1 presses = [presses n]; end
        targetRange = experiment.longTargets(n - params.task.responseBack-1:n-1);
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

eval(['save data/LGNfigureRG_' experiment.subject '_run' num2str(experiment.scanNum) '_' experiment.date '.mat params conditions experiment']);
eval(['save data/runOutput_' num2str(experiment.scanNum) '.mat params conditions experiment']);


KbQueueRelease();
ShowCursor;
Screen('Close');
Screen('CloseAll');
fprintf('Hit rate this run: %.2f%%\n',100*experiment.performance)
fclose all;
clear all;

%end


