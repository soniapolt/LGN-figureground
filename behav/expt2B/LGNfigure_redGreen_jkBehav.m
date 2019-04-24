%function LGNfigure_redGreen_jkBehav

%  1/25/18, SP: A control experiment to test observers' awareness of
%  figure stimuli while doing our challenging J/K detection task.
% 
%  It is accompanied by a ppt explaining the task to obsevers:
%  LGNrsvpbehav_instruction.ppt. Please show this to participants!
% 
%  expt.numTrials is coded at the top of the script. 
%  expt. figTrials is the number of those trials that will also ask about the
%  figure orientation, currently set to 20%. these will not occur in the
%  first 25% of the experiment

clear all; atScanner = 0;
input('Hit enter to proceed.');

%%%% scales all of the stimuli in DVA to the screensize
%params.screenWidth = 28;             % in cm; %7t = 17, laptop=33 at normal res, 28 at lower res
%params.viewingDist = 36;             % in cm; %7t=48, laptop = 36
params.screenWidth = 40.0;                            % in cm; %laptop=27.5,  office=43, %19=%T3b, miniHelm=39;
params.viewingDist = 43.0; 
%%%% collect some demographic info on subject
expt.demo = inputdlg({'Subject Number:','Gender (M/F/O):', 'Age:'});

try expt.subject = expt.demo{1};
catch
    expt.subject = 'test'; end % in case i've commented out the demo info

expt.feedback = 0;
expt.numTrials = 120; % in multiple of 8
expt.figTrials = round(expt.numTrials *.2);  % number of trials that we'll ask the identity of the figure; all occur in last 75% of trials
expt.scanNum = 1+round(rand); % 1 or 2, for randomization of eye conditions
expt.breakAt = [.33 .67]; % stop for a break halfway (can be set to =  [.33 .66] if you want to break into thirds), etc

Screen('Preference', 'SkipSyncTests',1);
params.gammaCorrect = 0;       % make sure this = 1 when you're at the scanner!
params.whichCLUT = 'linearizedCLUT_SoniaMPB.mat';%'7T_Sam.mat'; %

% in this study resolution will be super important for timing!!
% ResolutionTest
try expt.oldRes = SetResolution(max(Screen('Screens')),1024,768,60);
catch
    expt.oldRes = SetResolution(max(Screen('Screens')),1024,768,0); end

params.redMax = 256; % fixed - red is always darker at 7T
params.greenMax = 200; % 2 X matched green!

[keyboardIndices, productNames, ~] = GetKeyboardIndices;
deviceNumber = keyboardIndices(1);

%%%% input this at the beginning of the scan session for 7T
params.vertOffset = 0;    % vertical offset from FindScreenSize.m

%%%% set-up rand
rand('twister', sum(100*clock));
expt.rand = rand;

%%%% files and things
expt.root = pwd; %'/Users/Sonia/Desktop/ObjectRF/';
if ~exist('data') mkdir('data');end
expt.date = datestr(now,30);

%%%% timing
params.trialLength = 4;%4+.16*6;        % in seconds
params.RSVPpre = .16*6;                 % start the RSVP X seconds before the textures start
params.repsPerBlock = expt.numTrials/8; % multiples of 8, repetitions of each condition (orientation x attend L/R x figure L/R)
params.timeRoot = .16;                  % in seconds, the least denominator of our timing changes

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
params.littleFixDeg = params.fixRadDeg* .2;    % proportion of the fixSizeDeg occupied by the smaller black dot
params.outerFixPixels = 2;          % in pixels, the black ring around fixation

%%%% screen
params.mids = [params.redMax/2 params.greenMax/2]; % red, green
params.backgroundColor = [params.mids 0];  % color
params.fontSize = 20;

%%%% task - detect contrast decrement on fusion fixation
params.task.flicker = [1];          % on/off rate of letters, in timeRoot units
params.task.prob = .05;             % proportion of letters that are the target
params.task.rate = params.timeRoot * length(params.task.flicker); % in seconds
params.task.buffer = 2;             % no targets in the first X flips
params.task.repCheck = 2;           % no targets within X flips of each other
params.task.responseBack = 4;       % the response is correct if the preceding N letters were the target
params.task.alpha = upper({'a';'b';'c';'d';'e';'f';'g';'h';'i';'l';'m';'n';'o';'p';'q';'r';'s';'t';'u';'v';'w';'x';'y';'z'});
params.task.targs = {'J' 'K'};


%%%% response listening - so we don't read in scanner triggers!
responseKeys = zeros(1,256);
responseKeys(KbName({'1!';'2@';'Space'}))=1; % records button box presses 1/2/spacebar
params.responseKeys = {'1!';'2@'};

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
expt.condShuffle = Shuffle(repmat([1:params.numConds],1,params.repsPerBlock*2));
expt.numTrials = length(expt.condShuffle);

% now, the hardcoded eye conditions
if mod(expt.scanNum,2) ==1
    expt.surrEye = ones(1,expt.numTrials); % surround in red eye
    if mod(expt.scanNum,3) == 1;
        expt.figEye = repmat([1 2],1,expt.numTrials/2);
    else expt.figEye = repmat([2 1],1,expt.numTrials/2); end
else
    expt.surrEye = 2*ones(1,expt.numTrials);
    if mod(expt.scanNum,4) == 2;
        expt.figEye = repmat([2 1],1,expt.numTrials/2);
    else expt.figEye = repmat([1 2],1,expt.numTrials/2); end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TASK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

expt.condShuffle = Shuffle(repmat([1:params.numConds],1,params.repsPerBlock*2));
figTrials = [zeros(1,expt.numTrials/4) Shuffle([ones(1,expt.figTrials) zeros(1,expt.numTrials*.75-expt.figTrials)])];
i = Shuffle(find(figTrials));
order = figTrials; order(i(1:expt.figTrials/2))=2;

flip.time = (0:params.timeRoot:params.trialLength);
flip.tex = [zeros(1,int64(params.RSVPpre/params.timeRoot)) ones(1,int64((params.trialLength-params.RSVPpre)/params.timeRoot))];
% generate specs for each trial
trial = struct('cond',num2cell(expt.condShuffle),'figTrial',num2cell(figTrials),...
    'figLoc',[],'JorK',[],'char',[],'order',num2cell(order),...
    'target',zeros(1,length(flip.time)),...
    'JKresponse',[],'figResponse',[]);

% prep -  first and second face/letter can't be a target, by def of 2-back

% which flip will be the target? is this a J/K trial?
for n = 1:expt.numTrials
    trial(n).numTargs = length(find(rand(1,length(flip.time))<params.task.prob));
    if trial(n).numTargs == 0 trial(n).numTargs = 1; end
    while 1
        maybeTarget= params.task.buffer+Randi(length(flip.time)-2*params.task.buffer);
        if sum(trial(n).target(maybeTarget-params.task.repCheck:maybeTarget-1)) == 0 && sum(trial(n).target(maybeTarget+1:maybeTarget+params.task.repCheck)) == 0
            trial(n).target(maybeTarget) = 1+(rand>.5); % 1 = J, 2 = K
        end
        if length(find(trial(n).target)) == trial(n).numTargs
            break
        end
    end
    trial(n).JorK = trial(n).target(maybeTarget); % 1/2 ID of last target
    trial(n).figLoc = conditions(trial(n).cond).incongLoc;
    
    % set letters for this block
    trial(n).rand = datasample([1:length(params.task.alpha)],length(flip.time));
    for k = 1:length(trial(n).rand)
        % get rid of random repeats
        if k>2 && trial(n).rand(k)==trial(n).rand(k-1)
            s = [1:length(params.task.alpha)]; s(trial(n).rand(k)) = [];
            trial(n).rand(k) = datasample(s,1);
        end
        trial(n).char(k) = params.task.alpha{trial(n).rand(k)};
        if  trial(n).target(k)>0
            trial(n).char(k) = params.task.targs{trial(n).target(k)};
        end
    end
end

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
if atScanner Screen(win, 'TextSize', 24);
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
yc = rect(4)/2;

%%%% initial window - wait for backtick
DrawFormattedText(win,['Each letter stream will contain some J and some K targets.\nAfter each trial, report the identity of the LAST target you saw: J (1) or K (2).\nOn some trials, you''ll also be asked to report whether the orthogonal patch appeared on the left (1) or right (2) side.\n\nPress Space to Advance']...
    ,'center', 'center',[0 0 0]);

Screen(win, 'Flip', 0);
KbTriggerWait(KbName('Space'), deviceNumber);
KbQueueCreate(deviceNumber,responseKeys);

DrawFormattedText(win,'.', 'center', 'center'); Screen(win, 'Flip', 0);
WaitSecs(1);
DrawFormattedText(win,'..', 'center', 'center'); Screen(win, 'Flip', 0);
WaitSecs(1);
DrawFormattedText(win,'...', 'center', 'center'); Screen(win, 'Flip', 0);
WaitSecs(1); Screen(win,'Flip',0);

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
    params.apertureRect{n} = OffsetRect(params.targetRect{n},-(rect(3)-params.filtSize)/2,-(rect(4)-params.filtSize)/2);
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
WaitSecs(1);
%%%% start recording the response
KbQueueStart();

%%%%%%% START task TASK/FLIPPING
for t = 1:length(trial)
    thisCond = trial(t).cond;
    for f = 1:(length(flip.time)-1)
        if flip.tex(f)
        %%%% draw gabors
        figMid = params.mids(expt.figEye(t)); otherMid = params.mids(abs(expt.figEye(t)-3));
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
            colorStim(:,:,expt.figEye(t)) = stim;
            colorStim(:,:,abs(expt.figEye(t)-3)) = otherMid*ones(size(stim));
            
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
        surrMid = params.mids(expt.surrEye(t)); otherMid = params.mids(abs(expt.surrEye(t)-3));
        stim = ( surround-mean(surround(:)) ) / ( max(surround(:)) - min(surround(:)) );
        stim = stim/max( abs([min(stim(:))  max(stim(:))] ) ) * surrMid + surrMid;
        stim = (stim-surrMid).*params.stim.contrast + surrMid;
        
        colorS= cat(3,zeros(size(stim)),zeros(size(stim)),zeros(size(stim)));
        colorS(:,:,expt.surrEye(t)) = stim;
        colorS(:,:,abs(expt.surrEye(t)-3)) = otherMid*ones(size(stim));
        
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
        [w,h] = RectSize(Screen('TextBounds',win,trial(t).char(f)));
        DrawFormattedText(win,trial(t).char(f),'center',yc+h/4, [0 0 0]);
        
        %%%%%%%%%%% FLIP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if f == 1 [VBLT startTrial FlipT missed] = Screen(win, 'Flip', 0);
            expt.flipTime(f) = startTrial;
        else [VBLT expt.flipTime(f) FlipT missed] = Screen(win, 'Flip', startTrial + flip.time(f) - slack);end
    end
    % to show the very last flip screen for its 200ms
    [VBLT expt.flipTime(f+1) FlipT missed] = Screen(win, 'Flip', startTrial + flip.time(end) - slack);
    
    %%%%%%%%%%% RESPONSE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % listen for response  - correct if you respond to previous 3 letters
    %%%% draw fixation big circle
    % constant fixation
    Screen('FillOval', win,[0 0 0], [xc-params.fixRad yc-params.fixRad xc+params.fixRad yc+params.fixRad]); % outer fixation ring
    Screen('FillOval', win,[255 255 255], [xc-params.fixRad+params.outerFixPixels yc-params.fixRad+params.outerFixPixels xc+params.fixRad-params.outerFixPixels yc+params.fixRad-params.outerFixPixels]); % white fixation disk
    Screen('FillOval', win,[128 128 128], [xc-3 yc-3 xc+3 yc+3]); % outer fixation ring
    Screen(win,'Flip',0);
    
    txt = {'J or K', 'L or R'};
    [w,h] = RectSize(Screen('TextBounds',win,txt{1}));
    %%%%% FIRST RESPONSE PROMPT
    if trial(t).order == 0 % order 0 = only ask j/k
        
        Screen('FillOval', win,[0 0 0], [xc-params.fixRad yc-params.fixRad xc+params.fixRad yc+params.fixRad]); % outer fixation ring
        Screen('FillOval', win,[255 255 255], [xc-params.fixRad+params.outerFixPixels yc-params.fixRad+params.outerFixPixels xc+params.fixRad-params.outerFixPixels yc+params.fixRad-params.outerFixPixels]); % white fixation disk
        Screen('FillOval', win,[128 128 128], [xc-3 yc-3 xc+3 yc+3]); % outer fixation ring
    
        DrawFormattedText(win,txt{1},'center',yc-h,[0 0 0]);
        Screen(win,'Flip',0);
        while 1
            [pressed, firstPress]= KbQueueCheck();
            if pressed
            trial(t).JKresponse = KbName(find(firstPress));
            if strcmp(trial(t).JKresponse,params.responseKeys{trial(t).JorK})
                trial(t).JKhit = 1; if expt.feedback Beeper(1500, 0.5, 0.1); end
            else
                trial(t).JKhit = 0; if expt.feedback Beeper(300,[0.2], 0.1); end
            end    
            KbQueueFlush();
            break
            end
        end
    elseif trial(t).order == 1 % ask j/k first
        Screen('FillOval', win,[0 0 0], [xc-params.fixRad yc-params.fixRad xc+params.fixRad yc+params.fixRad]); % outer fixation ring
        Screen('FillOval', win,[255 255 255], [xc-params.fixRad+params.outerFixPixels yc-params.fixRad+params.outerFixPixels xc+params.fixRad-params.outerFixPixels yc+params.fixRad-params.outerFixPixels]); % white fixation disk
        Screen('FillOval', win,[128 128 128], [xc-3 yc-3 xc+3 yc+3]); % outer fixation ring
    
        DrawFormattedText(win,txt{1},'center', yc-h,[0 0 0]);
        Screen(win,'Flip',0);
        while 1
            [pressed, firstPress]= KbQueueCheck();
            if pressed
            trial(t).JKresponse = KbName(find(firstPress));
            if strcmp(trial(t).JKresponse,params.responseKeys{trial(t).JorK})
                trial(t).JKhit = 1; if expt.feedback Beeper(1500, 0.5, 0.1); end
            else
                trial(t).JKhit = 0; if expt.feedback Beeper(300,[0.2], 0.1); end
            end    
            KbQueueFlush();
            break
            end
            
        end
        WaitSecs(1);
        Screen('FillOval', win,[0 0 0], [xc-params.fixRad yc-params.fixRad xc+params.fixRad yc+params.fixRad]); % outer fixation ring
        Screen('FillOval', win,[255 255 255], [xc-params.fixRad+params.outerFixPixels yc-params.fixRad+params.outerFixPixels xc+params.fixRad-params.outerFixPixels yc+params.fixRad-params.outerFixPixels]); % white fixation disk
        Screen('FillOval', win,[128 128 128], [xc-3 yc-3 xc+3 yc+3]); % outer fixation ring
    
        DrawFormattedText(win,txt{2},'center', yc-h,[0 0 0]);
        Screen(win,'Flip',0);
        while 1
            [pressed, firstPress]= KbQueueCheck();
            if pressed
            trial(t).figResponse = KbName(find(firstPress));
            if strcmp(trial(t).figResponse,params.responseKeys{trial(t).figLoc})
                trial(t).figHit = 1;
            else trial(t).figHit = 0;end    
            KbQueueFlush();
            break
            end
        end
    elseif trial(t).order == 2 % ask fig first
        Screen('FillOval', win,[0 0 0], [xc-params.fixRad yc-params.fixRad xc+params.fixRad yc+params.fixRad]); % outer fixation ring
        Screen('FillOval', win,[255 255 255], [xc-params.fixRad+params.outerFixPixels yc-params.fixRad+params.outerFixPixels xc+params.fixRad-params.outerFixPixels yc+params.fixRad-params.outerFixPixels]); % white fixation disk
        Screen('FillOval', win,[128 128 128], [xc-3 yc-3 xc+3 yc+3]); % outer fixation ring
    
        DrawFormattedText(win,txt{2},'center',yc-h,[0 0 0]);
        Screen(win,'Flip',0);
        while 1
            [pressed, firstPress]= KbQueueCheck();
            if pressed
            trial(t).figResponse = KbName(find(firstPress));
            if strcmp(trial(t).figResponse,params.responseKeys{trial(t).figLoc})
                trial(t).figHit = 1;
            else trial(t).figHit = 0;end    
            KbQueueFlush();
            break
            end
        end
        WaitSecs(1);
        Screen('FillOval', win,[0 0 0], [xc-params.fixRad yc-params.fixRad xc+params.fixRad yc+params.fixRad]); % outer fixation ring
        Screen('FillOval', win,[255 255 255], [xc-params.fixRad+params.outerFixPixels yc-params.fixRad+params.outerFixPixels xc+params.fixRad-params.outerFixPixels yc+params.fixRad-params.outerFixPixels]); % white fixation disk
        Screen('FillOval', win,[128 128 128], [xc-3 yc-3 xc+3 yc+3]); % outer fixation ring
    
        DrawFormattedText(win,txt{1},'center',yc-h,[0 0 0]);
        Screen(win,'Flip',0);
        while 1
            [pressed, firstPress]= KbQueueCheck();
            if pressed
            trial(t).JKresponse = KbName(find(firstPress));
            if strcmp(trial(t).JKresponse,params.responseKeys{trial(t).JorK})
                trial(t).JKhit = 1; if expt.feedback Beeper(1500, 0.5, 0.1); end
            else
                trial(t).JKhit = 0; if expt.feedback Beeper(300,[0.2], 0.1); end
            end    
            KbQueueFlush();
            break
            end
        end
    end

    %%%%%%%%%%% BLOCK BREAKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isempty(intersect(t,round(expt.numTrials*expt.breakAt)))
    DrawFormattedText(win,['Take a break! You''ve completed ' num2str(t) ' of ' num2str(expt.numTrials) ' trials.\n\nPress Space to Continue']...
    ,'center', 'center',[0 0 0]);
    Screen(win, 'Flip', 0); 
    KbWait;
    KbQueueFlush();
    WaitSecs(1);
    end
    
    %%%%%%%%%%% MOVE TO NEXT TRIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    KbQueueFlush();
    eval(['save data/jkBehav_S' expt.subject '.mat params conditions expt trial']);
    
    Screen('FillOval', win,[0 0 0], [xc-params.fixRad yc-params.fixRad xc+params.fixRad yc+params.fixRad]); % outer fixation ring
    Screen('FillOval', win,[255 255 255], [xc-params.fixRad+params.outerFixPixels yc-params.fixRad+params.outerFixPixels xc+params.fixRad-params.outerFixPixels yc+params.fixRad-params.outerFixPixels]); % white fixation disk
    Screen('FillOval', win,[128 128 128], [xc-3 yc-3 xc+3 yc+3]); % inner dot
    Screen(win,'Flip',0);
    WaitSecs(.75);
    Screen('FillOval', win,[0 0 0], [xc-params.fixRad yc-params.fixRad xc+params.fixRad yc+params.fixRad]); % outer fixation ring
    Screen('FillOval', win,[255 255 255], [xc-params.fixRad+params.outerFixPixels yc-params.fixRad+params.outerFixPixels xc+params.fixRad-params.outerFixPixels yc+params.fixRad-params.outerFixPixels]); % white fixation disk
    Screen(win,'Flip',0);
    WaitSecs(.5);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%
% done! wrap up  %
%%%%%%%%%%%%%%%%%%
eval(['save data/jkBehav_S' expt.subject '_' expt.date '.mat params conditions expt trial']);
eval(['save data/jkBehav_S' expt.subject '.mat params conditions expt trial']);

KbQueueRelease();
ShowCursor;
Screen('CloseAll');

fprintf('\n\nMean J/K detection: %s%%\nMean figure detection: %s%%\n',num2str(nanmean([trial.JKhit]*100)),num2str(nanmean([trial.figHit]*100)));

%clear all;