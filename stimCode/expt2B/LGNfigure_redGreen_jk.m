function LGNfigure_redGreen_jk(subject,runNum,offset)
% this version asks observer to find j's and k's in the stream
% 136 TRs
%clear all;
atScanner = 1;
%offset = 100; subject = 'test'; runNum = 1;

Screen('Preference', 'SkipSyncTests',abs(atScanner-1));
params.gammaCorrect = atScanner;       % make sure this = 1 when you're at the scanner!
if atScanner hz = 60; else hz = 0; end    % at scanner this is 60, on LED displays it is 128

input('Hit enter to proceed.');

% in this study resolution will be super important for timing!!
% ResolutionTest
%if atScanner experiment.oldRes = SetResolution(max(Screen('Screens')),1024,768,hz); end
experiment.oldRes = SetResolution(max(Screen('Screens')),1024,768,hz);

params.redMax = 256; % fixed - red is always darker at 7T
params.greenMax = 200; % 2 X matched green!

[keyboardIndices, productNames, ~] = GetKeyboardIndices;
deviceNumber = keyboardIndices(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% params for testing
% if ~atScanner
%     offset = 0;
%     runNum = 15;
%     subject = 'test';
%     experiment.subjectNum = 1;
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% input this at the beginning of the scan session for 7T
params.vertOffset = offset;    % vertical offset from FindScreenSize.m
params.whichCLUT = '7T_Sam.mat'; %'linearizedCLUT_SoniaMPB.mat';

%%% basic naming set-up
experiment.subject = subject;
experiment.scanNum = runNum; % to keep both of these structs labeled

%%%% scales all of the stimuli in DVA to the screensize
params.screenWidth = 17;             % in cm; %7t = 17, laptop=33 at normal res, 28 at lower res
params.viewingDist = 48;             % in cm; %7t=48, laptop = 36

%%%% set-up rand
rand('twister', sum(100*clock));
experiment.rand = rand;

%%%% files and things
experiment.root = pwd; %'/Users/Sonia/Desktop/ObjectRF/';
experiment.date = datestr(now,30);

%%%% timing
params.blockLength = 16;             % in seconds
params.betweenBlocks = 16;           % in seconds
params.initialFixation = 16;         % in seconds
params.finalFixation = 16;           % in seconds
params.timeRoot = .16;              % in seconds, the least denominator of our timing changes

%%%% noise
params.stim.contrast =  1;                                                  % in %
params.stim.orientations = [45 135];                                        % in degrees
params.stim.gaborSizeDeg = 4;                                               % in degrees, diameter
params.stim.fromFixation = 1;                                               % in degrees, edge of stimulus annulus
params.stim.surrDeg = 2*(params.stim.gaborSizeDeg+params.stim.fromFixation+6);      % in degrees, extent of surrounding texture; must be square for filtering, specified as full width
params.stim.gapDeg = 0.15;                                                  % in pixels, thickness of greyscale ring separating
params.stim.orientNoise = 10;                                               % in degrees, +/- width of the filter
params.stim.fLowCPD =  .25;  % orig .25                                     % in cycles per degree
params.stim.fHighCPD = 8;    % orig 8                                       % in cycles per degree
params.stim.flicker = [1];                                                  % in units of timeRoot, regenerate the noise at == 1

%%%% conditions & layout
params.numOrientations = length(params.stim.orientations);
params.incongLocs = [1 2];   % attend L or R
params.numConds = params.numOrientations * length(params.incongLocs);
params.fixRadDeg =  .4;            % in degrees, the radius of the biggest white dot in the fixation
params.scannerFont = 30;
params.littleFixDeg = params.fixRadDeg* .2;    % proportion of the fixSizeDeg occupied by the smaller black dot
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
params.task.prob = .1;              % proportion of trials with 1back targets
params.task.flicker = [1];          % on/off rate of letters, in timeRoot units
params.task.rate = params.timeRoot * length(params.task.flicker); % in seconds
params.task.buffer = 4;             % no targets in the first/last X flips
params.task.repCheck = 2;           % no targets within X flips of each other
params.task.responseBack = 6;       % the response is correct if the preceding N letters were the target
params.task.alpha = upper({'a';'b';'c';'d';'e';'f';'g';'h';'i';'l';'m';'n';'o';'p';'q';'r';'s';'t';'u';'v';'w';'x';'y';'z'});
params.task.targs = {'J' 'K'};

%%%% final few structs
experiment.allFlips = (0:params.timeRoot:experiment.totalTime);

%%%% response listening - so we don't read in scanner triggers!
responseKeys = zeros(1,256);
responseKeys(KbName('1!'))=1; % button box 1
responseKeys(KbName('2@'))=1; % button box 2


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CONDITIONS & TIMING MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% set up our structs
conditions = struct('surround',num2cell((kron([1:params.numOrientations]', ones(params.numConds/params.numOrientations,1)))')...
    ,'incongLoc',num2cell(repmat(params.incongLocs,1,params.numConds/length(params.incongLocs),1)));

%%% important - in this version, the irrelevant orientation conditions are
%%% randomized, but the relevant eye-presentation conditions are hardcoded

for n = 1:length(conditions)
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

%%%% long condition timing, which is in units of timeRoot
long.conds = zeros(params.initialFixation/params.timeRoot,1);
long.surrEye = long.conds; long.figEye = long.conds; long.block = long.conds;

for n = (1:experiment.numBlocks-1)
    long.conds = [long.conds; repmat(experiment.condShuffle(n),params.blockLength/params.timeRoot,1);... % blocks
    zeros(params.betweenBlocks/params.timeRoot,1)]; % inter-block blanks
    long.block = [long.block; repmat(n,params.blockLength/params.timeRoot,1);... % blocks
    zeros(params.betweenBlocks/params.timeRoot,1)]; % inter-block blanks
    
    
    long.surrEye = [long.surrEye; repmat(experiment.surrEye(n),(params.betweenBlocks+params.blockLength)/params.timeRoot,1)]; % blocks & blanks (eye doesn't matter in blanks)
    long.figEye = [long.figEye; repmat(experiment.figEye(n),(params.betweenBlocks+params.blockLength)/params.timeRoot,1)]; % blocks & blanks (eye doesn't matter in blanks)
end

long.conds = [long.conds; repmat(experiment.condShuffle(experiment.numBlocks),params.blockLength/params.timeRoot,1); zeros(params.finalFixation/params.timeRoot,1)]; % the last block
long.block = [long.block; repmat(experiment.numBlocks,params.blockLength/params.timeRoot,1); zeros(params.finalFixation/params.timeRoot,1)]; % the last block
long.surrEye = [long.surrEye; repmat(experiment.surrEye(experiment.numBlocks),params.blockLength/params.timeRoot,1); zeros(params.finalFixation/params.timeRoot,1)]; % the last block
long.figEye = [long.figEye; repmat(experiment.figEye(experiment.numBlocks),params.blockLength/params.timeRoot,1); zeros(params.finalFixation/params.timeRoot,1)]; % the last block

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
task.targInd = zeros(1,experiment.totalTime/params.task.rate);
task.numTargs= length(find(rand(1,experiment.totalTime/params.task.rate)<params.task.prob));

while 1
    maybeTarget= params.task.buffer+Randi(length(task.targInd)-2*params.task.buffer);
    if sum(task.targInd(maybeTarget-params.task.repCheck:maybeTarget-1)) == 0 && sum(task.targInd(maybeTarget+1:maybeTarget+params.task.repCheck)) == 0
        task.targInd(maybeTarget) = 1+(rand>.5); % 1 = J, 2 = K
    end
    if length(find(task.targInd)) == task.numTargs
        break
    end
end

% set letters for this block
task.rand = datasample([1:length(params.task.alpha)],experiment.totalTime/params.task.rate);
for k = 1:length(task.rand)
    % get rid of random repeats
    if k>2 && task.rand(k)==task.rand(k-1)
        s = [1:length(params.task.alpha)]; s(task.rand(k)) = [];
        task.rand(k) = datasample(s,1);
    end
    task.char(k) = params.task.alpha{task.rand(k)};
    if task.targInd(k)>0
        task.char(k) = params.task.targs{task.targInd(k)};
    end
end


long.targs = Expand(task.targInd,length(params.task.flicker),1);
long.char = Expand(task.char,length(params.task.flicker),1);
long.trialNum = Expand([1:experiment.totalTime/params.task.rate],length(params.task.flicker),1);

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

%%% pick font size
if atScanner Screen(win, 'TextSize', params.scannerFont);
else Screen(win, 'TextSize', 14); end

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
params.fixRad = round(params.fixRadDeg*params.ppd);
params.littleFix = round(params.littleFixDeg*params.ppd);
params.gapPix = params.stim.gapDeg*params.ppd;

%%% filtering properties
params.filtSize = min(round(params.stim.surrDeg*params.ppd),rect(4));
params.fLow = params.stim.fLowCPD * params.filtSize/params.ppd;
params.fHigh = params.stim.fHighCPD * params.filtSize/params.ppd;
params.fNyquist = params.filtSize/2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% WAIT FOR BACKTICK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xc = rect(3)/2; % rect and center, with the flixibility to resize & shift center - change vars to zero if not used.
yc = rect(4)/2+params.vertOffset;

%%%% initial window - wait for backtick
Screen(win, 'DrawText', 'Waiting for Backtick.', 10,10,[0 0 0]);
DrawFormattedText(win,'Press 1 for J\n Press 2 for K', 'center', 'center', [0 0 0]);
Screen(win, 'Flip', 0);

KbTriggerWait(53, deviceNumber);
KbQueueCreate(deviceNumber,responseKeys);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LOCATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% locations of things
params.dispRect = CenterRectOnPoint([0 0 params.filtSize params.filtSize],xc,yc);
% left figure
params.targetRect{1}  = CenterRectOnPoint([0 0 params.gaborSize params.gaborSize],xc-params.stim.fromFixation*params.ppd-params.gaborSize/2,yc);
% right figure
params.targetRect{2} =  CenterRectOnPoint([0 0 params.gaborSize params.gaborSize],xc+params.stim.fromFixation*params.ppd+params.gaborSize/2,yc);

for n = 1:length(params.targetRect)
   params.apertureRect{n} = OffsetRect(params.targetRect{n},-(rect(3)-params.filtSize)/2,-(rect(4)-params.filtSize)/2-params.vertOffset);
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
task.pressFlip = [];
task.response = [];
flipCount = 1;


%%%%%%% START task TASK/FLIPPING
for n = 1:(length(experiment.allFlips)-1)
    thisCond = long.conds(n);
    
    %%%% draw gabors
    if thisCond > 0 
        figMid = params.mids(long.figEye(n)); otherMid = params.mids(abs(long.figEye(n)-3));
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
            colorStim(:,:,long.figEye(n)) = stim;
            colorStim(:,:,abs(long.figEye(n)-3)) = otherMid*ones(size(stim));
            
            eval(['color' stimNames{s} '= colorStim;']);
            %toc
        end
        leftTex = Screen('MakeTexture',win,colorleft);
        rightTex = Screen('MakeTexture',win,colorright);
        
        Screen('DrawTexture', win, leftTex,[],params.dispRect); % draw left
        Screen('FillOval', rightTex, [255 255 255 0],params.apertureRect{1}); % left aperture
        Screen('DrawTexture', win, rightTex,[],params.dispRect); % draw right, make left visible through it
        
        % surround
        surround=rand(params.filtSize);
        % apply filter to noise in fourier space
        surround=smoothSFO{conditions(thisCond).surround}.*fftshift(fft2(surround));
        % tranform back to real domain
        surround=real(ifft2(ifftshift(surround)));
        
        % varying the contrast/intensity range)
        surrMid = params.mids(long.surrEye(n)); otherMid = params.mids(abs(long.surrEye(n)-3));
        stim = ( surround-mean(surround(:)) ) / ( max(surround(:)) - min(surround(:)) );
        stim = stim/max( abs([min(stim(:))  max(stim(:))] ) ) * surrMid + surrMid;
        stim = (stim-surrMid).*params.stim.contrast + surrMid;
        
        colorS= cat(3,zeros(size(stim)),zeros(size(stim)),zeros(size(stim)));
        colorS(:,:,long.surrEye(n)) = stim;
        colorS(:,:,abs(long.surrEye(n)-3)) = otherMid*ones(size(stim));
        
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

    % constant fixation
    Screen('FillOval', win,[0 0 0], [xc-params.fixRad yc-params.fixRad xc+params.fixRad yc+params.fixRad]); % outer fixation ring
    Screen('FillOval', win,[255 255 255], [xc-params.fixRad+params.outerFixPixels yc-params.fixRad+params.outerFixPixels xc+params.fixRad-params.outerFixPixels yc+params.fixRad-params.outerFixPixels]); % white fixation disk
    
     %Screen('TextFont',win,params.task.fonts{long.font(n)});
     [w,h] = RectSize(Screen('TextBounds',win,long.char(n)));
     DrawFormattedText(win,long.char(n),'center',yc+h/4, [0 0 0]);   
  
    
    %%%%%%%%%%% FLIP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if n == 1 [VBLT experiment.startRun FlipT missed] = Screen(win, 'Flip', 0);
        experiment.flipTime(n) = experiment.startRun;
    else [VBLT experiment.flipTime(n) FlipT missed] = Screen(win, 'Flip', experiment.startRun + experiment.allFlips(n) - slack);end
    
    % listen for response  - correct if you respond to previous 3 letters
        [pressed, firstPress]= KbQueueCheck();
    if pressed
        task.pressFlip = [task.pressFlip n];
        task.response = [task.response {KbName(firstPress)}];
        KbQueueFlush();
    end
end

%%%% to show the very last flip screen for its 200ms
[VBLT experiment.flipTime(n+1) FlipT missed] = Screen(win, 'Flip', experiment.startRun + experiment.allFlips(length(experiment.allFlips)) - slack);
experiment.runTime = GetSecs - experiment.startRun;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% performance
perf = struct('hitRepeat',[],'hitID',[],'falseFlip',[]);

% for now, this only deals with hits, no false alarms...
for p = 1:length(task.pressFlip)
    pressTrial = task.pressFlip(p);
    targetRange = pressTrial-params.task.responseBack:pressTrial-1;
    if sum(task.targInd(targetRange)>0)
        targ = targetRange(find(task.targInd(targetRange),1,'last'));
        perf.hitRepeat = [perf.hitRepeat targ]; % participant detected a repeat (but may have pressed the wrong 1/2 key)
        if ~isempty(strfind(task.response{p},num2str(task.targInd(targ))))
            perf.hitID = [perf.hitID targ];
        end
    else
        perf.falseFlip = [perf.falseFlip pressTrial];
    end
end


%%%%%%%%%%%%%%%%%%
% done! wrap up  %
%%%%%%%%%%%%%%%%%%
if ~exist('data') mkdir('data');end
eval(['save data/LGNfigureRGjk_' experiment.subject '_run' num2str(experiment.scanNum) '_' experiment.date '.mat params conditions experiment task perf long']);
eval(['save data/runOutput_' num2str(experiment.scanNum) '.mat params conditions experiment task perf long']);

perfText = sprintf('Detected Repeat: %.2f%%\nIdentified J vs K: %.2f%%',100*length(unique([perf.hitRepeat]))/task.numTargs,100*length(unique([perf.hitID]))/task.numTargs);
DrawFormattedText(win,perfText, 'center', 'center', [0 0 0]);
Screen(win, 'Flip', 0);
WaitSecs(5);

KbQueueRelease();
ShowCursor;
Screen('Close');
Screen('CloseAll');
fprintf('Detected Repeat: %.2f%%\nIdentified J vs K: %.2f%%\n',100*length(unique([perf.hitRepeat]))/task.numTargs,100*length(unique([perf.hitID]))/task.numTargs);
fclose all;
%clear all;

%end
