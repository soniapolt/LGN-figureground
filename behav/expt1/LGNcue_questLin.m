function LGNcue_questLin(subjNum,questBoth,numTrials,feedback)
% quest to estimate subject's threshold at doing cued, incongruent task
% off-center
% clear all; questBoth = 0; subjNum = 99; numTrials = 40; feedback = 1;
% input('Hit enter to proceed.');

%%% basic naming set-up
expt.subject = subjNum;
displayQuest = 0; % for debugging, show the quest params after each trial

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% QUEST parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

quest.pThresh = 0.84; % threshold criterion expressed as probability of response==1
quest.beta = 3.5; % steepness of the psychometric function - value set from Pelli paper
quest.delta = 0.05; % proportion of 'blind guess' trials
quest.gamma = 0.5; % fraction of trials that will generate response 1 when intensity==-inf
quest.tGuess = 1.6; % starting threshold
quest.tGuessSd = 0.6; % SD of starting threshold
quest.range = [];   % range that quest will search: [tGuess+(-range/2:grain:range/2)]; for our purposes it makes sense to use 0 to ++
quest.grain = []; % increment by which quest steps
quest.min = 1.001; % restrict range (negative values will flip increment/decrement relationship). this isn't used in questcreate, just when actually telling the script what val to use
quest.both = questBoth;

quest.names = {'Incongruent' 'Congruent'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% screen & keyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% scale all of the stimuli in DVA
params.screenWidth = 40;                            % in cm; %laptop=27.5,  office=43, %19=%T3b, miniHelm=39;
params.viewingDist = 43;                            % in cm; %laptop=27.5,  office=43, %19=%T3b, miniHelm=39;params.viewingDist = 43;                            % in cm; 3Tb/office=43, miniHelm=57;

Screen('Preference', 'SkipSyncTests',0);
params.gammaCorrect = 1;                            % make sure this = 1 during experiment!
params.whichCLUT = 'linearizedCLUT_SoniaMPB.mat';   %'7T_Sam.mat'; %
params.resSet = 0;                                  % adjust monitor resolution

if params.resSet
    try                                                 % large monitors may not render filtered noise conditions in <200ms
        expt.oldRes = SetResolution(max(Screen('Screens')),1024,768,0);         % LCD monitors
    catch
        expt.oldRes = SetResolution(max(Screen('Screens')),1024,768,60); end    % other monitors; ResolutionTest.m to confirm
end

% response listening
[deviceNumber, productNames, ~] = GetKeyboardIndices;
if size(deviceNumber>1)
    deviceNumber = deviceNumber(1) %for use with external keyboard
end
responseKeys = zeros(1,256);
params.responseKeys = {'1!';'2@'};
responseKeys(KbName({'1!';'2@';'Space'}))=1; % records button box presses 1/2/spacebar

% set-up rand
rand('twister', sum(100*clock)); expt.rand = rand;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% expt details
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% basics for the block
params.feedback = feedback;                             % beep or no beep
params.repsPerBlock = numTrials/4;                      % multiples of 4, repetitions of each condition (orientation x attend L/R x figure L/R)

%%%% files and things
expt.root = pwd;
expt.date = datestr(now,30);

%%%% timing
params.trialLength = 2;       % in seconds
params.flicker = .2;          % in seconds; also the target length

%%%% noise
params.stim.contrast =  1;                                                  % full contrast
params.stim.orientations = [45 135];                                        % in degrees
params.stim.gaborSizeDeg = 4;                                               % in degrees, diameter
params.stim.fromFixation = 1;                                               % in degrees, edge of stimulus annulus
params.stim.surrDeg = 2*(params.stim.gaborSizeDeg+params.stim.fromFixation+6);      % in degrees, extent of surrounding texture; must be square for filtering, specified as full width
params.stim.gapDeg = 0.25;                                                  % in pixels, thickness of greyscale ring separating
params.stim.orientNoise = 10;                                               % in degrees, +/- width of the filter
params.stim.cpd =  [.25 8];                                                 % range of noise, in cycles per degree
params.stim.flicker = [1 1];                                                % [1 1] for constant motion [1 0] for flicker

%%%% conditions & layout
params.numOrientations = length(params.stim.orientations);
params.attendLocs = [1 2];   % attend L or R (change to 2 to do whole task on
params.incongLocs = params.attendLocs;   % incong figure
if quest.both params.numConds = params.numOrientations * length(params.attendLocs) * length(params.incongLocs);
else params.numConds = params.numOrientations * length(params.attendLocs); end

%%%% screen
params.backgroundColor = [127 127 127];             % color
params.fontSize = 20;                               % for instructions, etc
params.fix.sizeDeg =  .33;                          % in degrees, the diameter of the biggest white dot in the fixation
params.fix.littleDeg = params.fix.sizeDeg* .5;      % proportion of the fixSizeDeg occupied by the smaller black dot
params.fix.outerPix = 2;                            % in pixels, the black ring around fixation

%%%% task - detect whether SF change is increment or decrement
params.task.cueVal = 1;                % validity of the cue
params.task.rate = params.stim.flicker; % duration of color change
params.task.buffer = 2;                 % no targets in the first/last X flips
params.task.cueBefore = 1;              % in seconds, how far ahead of block start do we show the attention cue?
params.task.cueSizeDeg = params.fix.sizeDeg*.4;
params.task.cueOffsetDeg = params.fix.sizeDeg/2 + .2; % how far off center the cues appear

%%%% subject performs task on either left or right targets
if mod(subjNum,2)
expt.cueColor = [255 255 255];
expt.notCueColor = [0 0 0];
expt.cueText = 'white';
else expt.cueColor = [0 0 0];
expt.notCueColor = [255 255 255];
expt.cueText = 'black';
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CONDITIONS & TRIAL GENERATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if quest.both
condition = struct('surround',num2cell((kron([1:params.numOrientations]', ones(params.numConds/params.numOrientations,1)))'),...
    'attendLoc',num2cell(repmat(params.attendLocs,[1,params.numConds/length(params.attendLocs)])),...
    'incongLoc',num2cell(repmat(Expand(params.incongLocs,2,1),1,2)));
else
% for the quest trials, attendloc always == incongloc
condition = struct('surround',num2cell((kron([1:params.numOrientations]', ones(params.numConds/params.numOrientations,1)))'),...
    'attendLoc',num2cell(repmat(params.attendLocs,[1,params.numConds/length(params.attendLocs)])),...
    'incongLoc',num2cell(repmat(params.attendLocs,[1,params.numConds/length(params.attendLocs)])));
end

for n = 1:length(condition)
    if condition(n).incongLoc == 1
        condition(n).leftO = abs(condition(n).surround-3);
        condition(n).rightO = condition(n).surround;
    else condition(n).leftO = condition(n).surround;
        condition(n).rightO = abs(condition(n).surround-3);end
end

% generate random ordering
expt.trialOrder = Shuffle(repmat([1:params.numConds],1,params.repsPerBlock));
expt.numTrials = length(expt.trialOrder);
flip.time = (0:params.flicker:params.task.cueBefore+params.trialLength);
flip.trial = [zeros(1,params.task.cueBefore/params.flicker) ones(1,params.trialLength/params.flicker)];

% generate specs for each trial
trial = struct('cond',num2cell(expt.trialOrder),'targLoc',[],'cueValid',[],...
    'target',zeros(1,length(flip.trial)),...
    'decrm',[],'response',[]);

% prep -  first and second face/letter can't be a target, by def of 2-back
targPoss = find(flip.trial);
targPoss(1:params.task.buffer)=[]; targPoss(end-params.task.buffer+1:end)=[];

% which flip will be the target? is this a valid/invalid trial?
for n = 1:expt.numTrials
    if rand<params.task.cueVal % determine if cue is value
        trial(n).cueValid = 1; trial(n).targLoc = condition(trial(n).cond).attendLoc; % assign cue figure accordingly
    else    trial(n).cueValid = 2; trial(n).targLoc = abs(condition(trial(n).cond).attendLoc-3); end
    trial(n).target(Sample(targPoss)) = 1; % determine which flip will contain the cue
    % either randomly generate the s.f. change type, or set to a single one
    trial(n).decrm = 1+round(rand); % % 1 = increment 2 = decrement
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% QUEST init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for n =  1:(quest.both+1)
% q{n}=QuestCreate(quest.tGuess,quest.tGuessSd,quest.pThresh,quest.beta,quest.delta,quest.gamma,quest.grain,quest.range);
q{n}=QuestCreate(quest.tGuess,quest.tGuessSd,quest.pThresh,quest.beta,quest.delta,quest.gamma);
qStair{n} = struct('count',0);
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
params.fix.size = round(params.fix.sizeDeg*params.ppd);
params.fix.little = round(params.fix.littleDeg*params.ppd);
params.gapPix = params.stim.gapDeg*params.ppd;
params.task.cueSize= round(params.task.cueSizeDeg*params.ppd);
params.task.cueOffset = round(params.task.cueOffsetDeg*params.ppd);

%%% filtering properties
params.filtSize = min(round(params.stim.surrDeg*params.ppd),rect(4));
params.fCPD = params.stim.cpd * params.filtSize/params.ppd;
params.fNyquist = params.filtSize/2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% WAIT FOR BACKTICK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xc = rect(3)/2; % rect and center, with the flixibility to resize & shift center - change vars to zero if not used.
yc = rect(4)/2;

%%%% initial window - wait for backtick
DrawFormattedText(win,['Attend to the side with the ' expt.cueText ' dot\n The change will happen on the cued side on ' num2str(100*params.task.cueVal) '% of trials\n\nPress 1 to report S.F. increase (thinner stripes)\n Press 2 to report S.F. decrease (wider stripes) \n\nPress Space to Advance']...
    , 'center', 'center',expt.cueColor);

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
%params.vertOffset = 0; % we used this in the scanner

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

% SURROUND-sized gaussian filter
params.stim.gaussSD = round(params.filtSize*.005);params.stim.gaussSize = round(params.filtSize*.1);
gFilt = customgauss([params.stim.gaussSize params.stim.gaussSize], params.stim.gaussSD, params.stim.gaussSD, 0, 0, 1, [0,0]);

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
    c = trial(t).cond;
    % is this a congruent or incongruent trial
    if condition(c).attendLoc == condition(c).incongLoc
        whichQ = 1; else whichQ = 2; end
    qStair{whichQ}.count = qStair{whichQ}.count+1;
    tt = qStair{whichQ}.count;
    
    %%% assign bandpass filters - before trial starts
            %%% quest recommended cpdChange amount
            qStair{whichQ}.cpdChange(tt,1)=QuestQuantile(q{whichQ});	% Recommended by Pelli (1987)
            qStair{whichQ}.t(tt)=QuestMean(q{whichQ});                  % Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
            qStair{whichQ}.sd(tt)=QuestSd(q{whichQ});
            
            qStair{whichQ}.cpdChange(tt,2)=max(qStair{whichQ}.cpdChange(tt,1),quest.min); % negative numbers will flip our incr/decr relationship
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% FILTERS
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            qStair{whichQ}.lowCPD(tt,:) = params.stim.cpd./(qStair{whichQ}.cpdChange(tt,2)); %[0.1667 5.3333];                                          % target increment - in scan, this was [3.25 11]
            qStair{whichQ}.highCPD(tt,:) = params.stim.cpd.*(qStair{whichQ}.cpdChange(tt,2)); %[0.3750 12];    
            
            %%%%%%%%%%%%%%%%
            % TO DEBUG
            if displayQuest && t>1
            txt = sprintf('Prev. response: %d. Next trial: %s. \n\nSuggested cpdCh = %2.3f, using %2.3f. Current thresh(sd) = %2.3f(%2.3f). \n\nHigh cpd: %2.3f-%2.3f, low cpd: %2.3f-%2.3f',...
                trial(t-1).hit,quest.names{whichQ},...
                qStair{whichQ}.cpdChange(tt,1),qStair{whichQ}.cpdChange(tt,2),...
                qStair{whichQ}.t(end),qStair{whichQ}.sd(end),...
                qStair{whichQ}.highCPD(tt,1),qStair{whichQ}.highCPD(tt,2),qStair{whichQ}.lowCPD(tt,1),qStair{whichQ}.lowCPD(tt,2));
            DrawFormattedText(win,txt, 'center', 'center'); Screen(win, 'Flip', 0);
            KbQueueWait;
            end
            %%%%%%%%%%%%%%%%
            
            fInc = qStair{whichQ}.highCPD(tt,:)  * params.filtSize/params.ppd;
            fDec = qStair{whichQ}.lowCPD(tt,:)  * params.filtSize/params.ppd;
            

            for n = 1:length(params.stim.orientations)
                orientFilter=OrientationBandpass(params.filtSize,(params.stim.orientations(n))-params.stim.orientNoise,(params.stim.orientations(n))+params.stim.orientNoise);
                bandpassFilter = Bandpass2(params.filtSize, params.fCPD(1)/params.fNyquist,params.fCPD(2)/params.fNyquist); % create 2d bandpass filter
                
                incFilter = Bandpass2(params.filtSize, fInc(1)/params.fNyquist,fInc(2)/params.fNyquist); % create 2d bandpass filter
                decFilter = Bandpass2(params.filtSize, fDec(1)/params.fNyquist,fDec(2)/params.fNyquist); % create 2d bandpass filter
                
                filtSFO = bandpassFilter.*orientFilter;
                incfiltSFO = incFilter.*orientFilter;
                decfiltSFO = decFilter.*orientFilter;
                
                smoothSFO{n} = filter2(gFilt,filtSFO);
                targSFO{n,1} = filter2(gFilt,incfiltSFO); % 1 = increment 2 = decrement
                targSFO{n,2} = filter2(gFilt,decfiltSFO);
            end
            
            
    for f = 1:(length(flip.time)-1)
        if flip.trial(f) % if we're out of the cue-only period
            %tic
            % generate this center left & right stims
            left=rand(params.filtSize); right = rand(params.filtSize);
            % apply filter to noise in fourier space
            if trial(t).targLoc == 1 && trial(t).target(f) % if left is target
                left=targSFO{condition(c).leftO,trial(t).decrm}.*fftshift(fft2(left));
            else
                left=smoothSFO{condition(c).leftO}.*fftshift(fft2(left)); end
            if trial(t).targLoc == 2 && trial(t).target(f) % if right is target
                right=targSFO{condition(c).rightO,trial(t).decrm}.*fftshift(fft2(right));
            else
                right=smoothSFO{condition(c).rightO}.*fftshift(fft2(right)); end
            
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
            surround=smoothSFO{condition(c).surround}.*fftshift(fft2(surround));
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
        Screen('FillOval', win,[0 0 0], [xc-round(params.fix.size/2+params.fix.outerPix ) yc-round(params.fix.size/2+params.fix.outerPix ) xc+round(params.fix.size/2+params.fix.outerPix ) yc+round(params.fix.size/2+params.fix.outerPix )]); % black fixation ring
        Screen('FillOval', win,[255 255 255], [xc-round(params.fix.size/2) yc-round(params.fix.size/2) xc+round(params.fix.size/2) yc+round(params.fix.size/2)]); % white fixation ring
        
        if condition(c).attendLoc==1% cue left
            % left circle
            Screen('FillOval',win,expt.cueColor,[xc-params.task.cueOffset-round(params.task.cueSize/2) yc-round(params.task.cueSize/2) xc-params.task.cueOffset+round(params.task.cueSize/2) yc+round(params.task.cueSize/2)]);
            % right circle
            Screen('FillOval',win,expt.notCueColor,[xc+params.task.cueOffset-round(params.task.cueSize/2) yc-round(params.task.cueSize/2) xc+params.task.cueOffset+round(params.task.cueSize/2) yc+round(params.task.cueSize/2)]);
        elseif condition(c).attendLoc==2 % cue right
            % left circle
            Screen('FillOval',win,expt.notCueColor,[xc-params.task.cueOffset-round(params.task.cueSize/2) yc-round(params.task.cueSize/2) xc-params.task.cueOffset+round(params.task.cueSize/2) yc+round(params.task.cueSize/2)]);
            % right circle
            Screen('FillOval',win,expt.cueColor,[xc+params.task.cueOffset-round(params.task.cueSize/2) yc-round(params.task.cueSize/2) xc+params.task.cueOffset+round(params.task.cueSize/2) yc+round(params.task.cueSize/2)]);
        end
        % little fixation dot
        Screen('FillOval', win,[0 0 0], [xc-round(params.fix.little/2) yc-round(params.fix.little/2) xc+round(params.fix.little/2) yc+round(params.fix.little/2)]); % black fixation dot
        
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
    Screen('FillOval', win,[0 0 0], [xc-round(params.fix.size/2+params.fix.outerPix ) yc-round(params.fix.size/2+params.fix.outerPix ) xc+round(params.fix.size/2+params.fix.outerPix ) yc+round(params.fix.size/2+params.fix.outerPix )]); % black fixation ring
    Screen('FillOval', win,[255 255 255], [xc-round(params.fix.size/2) yc-round(params.fix.size/2) xc+round(params.fix.size/2) yc+round(params.fix.size/2)]); % white fixation ring
    % little fixation dot
    Screen('FillOval', win,[0 0 0], [xc-round(params.fix.little/2) yc-round(params.fix.little/2) xc+round(params.fix.little/2) yc+round(params.fix.little/2)]); % black fixation dot
    Screen(win,'Flip',0);
    while 1
        [pressed, firstPress]= KbQueueCheck();
        if pressed
            trial(t).response = KbName(find(firstPress));
            if strcmp(trial(t).response,params.responseKeys{trial(t).decrm})
                trial(t).hit = 1;
                if params.feedback Beeper(1500, 0.5, 0.1); end
            else
                trial(t).hit = 0;
                if params.feedback Beeper(300,[0.2], 0.1); end
            end
            KbQueueFlush();
            q{whichQ}=QuestUpdate(q{whichQ},qStair{whichQ}.cpdChange(tt,2),trial(t).hit); % Add the new datum (actual test intensity and observer response) to the database.
            break
        end
    end
    
    %%%%%%%%%%% MOVE TO NEXT TRIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    WaitSecs(1);

end

%%%%%%%%%%%%%%%%%%
% done! wrap up  %
%%%%%%%%%%%%%%%%%%

KbQueueRelease();
ShowCursor;
Screen('CloseAll');

fprintf('\n\n');
for n = 1:(quest.both+1)
quest.name{n} = quest.names{n};
figure; subplot(1,4,1); 
plot(qStair{n}.cpdChange); title('cpdChange param (linear scale)'); legend({'suggested','used'});
subplot(1,4,2); 
plot(qStair{n}.t,'k'); title('threshold estimate'); xlabel('trial')
subplot(1,4,3); 
plot(qStair{n}.sd,'k'); title('sd estimate'); xlabel('trial')

subplot(1,4,4); plot(qStair{n}.lowCPD(:,1),'b'); hold on; 
plot(qStair{n}.highCPD(:,1),'r'); title('CPD ranges - lower bound'); legend({'decrement','increment'});


suptitle([quest.names{n} ' final estimate: ' num2str(qStair{n}.t(end)) '± ' num2str(qStair{n}.sd(end)) '(sd)']);%; corresponds to cpd multiplier of ' num2str(10^quest.t(n))]);

fprintf('*** %s final threshold estimate (mean±sd) is %.2f ± %.2f\n',quest.names{n},qStair{n}.t(end),qStair{n}.sd(end));
%fprintf('*** This corresponds to a cpd factor (10^term) of %.5f\n',10^quest.t(n));
end

% save once w/ timestamp to avoid overwriting, once for naming convenience
eval(['save data/questLin_s' num2str(expt.subject) '_' expt.date '.mat params condition trial expt quest qStair q']);
