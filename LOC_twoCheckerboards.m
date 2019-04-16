
function LOC_twoCheckerboards(subject,runNum,offset,deviceNumber)
% in this version:
% Left/Right circular checkerboards, no blank periods between
% 144 TRs, usually

Screen('Preference', 'SkipSyncTests', 0); 
%clear all;
input('Hit enter to proceed.');

%%%% input this at the beginning of the scan session for 7T
loc.vertOffset = offset;       % vertical offset from FindScreenSize.m
%   % [keyboardIndices, productNames, ~] = GetKeyboardIndices;
% deviceNumber = keyboardIndices;
%%%% basic naming set-up
loc.scanNum = runNum;
loc.subject = subject;
loc.gammaCorrect = 1; % make sure this is on at the scanner!

%%%% set-up rand
rand('twister', sum(100*clock));
loc.rand = rand;

%%%% files and things
loc.root = pwd; %'/Users/Sonia/Desktop/ObjectRF/';
loc.date = datestr(now,30);
loc.screenWidth = 19;             % in cm; %laptop=27.5,office=43, %19=%T3b, miniHelm=39;
loc.viewingDist = 48;             % in cm; 3Tb/office=43, miniHelm=57;

%%%%%%%%%%%%%%%%%
% loc params    %
%%%%%%%%%%%%%%%%%

% size and offset from fixation
loc.offFixDeg = 1;                                                 % in degrees, to edge of stim
loc.sizeDeg = 4;                                       % in degrees
loc.spatialFreqDeg = 1;         % deg per cycle
loc.fixSizeDeg =  .25;            % in degrees, the size of the biggest white dot in the fixation
loc.littleFixDeg = loc.fixSizeDeg* .2;    % proportion of the fixSizeDeg occupied by the smaller black dot
loc.outerFixPixels = 2;          % in pixels, the black ring around fixation

% in this version - no between block time

if mod(loc.scanNum,2) ==1
    loc.conditions = [1 2];
elseif mod(loc.scanNum,2) ==0
    loc.conditions = [2 1];
end

loc.initialFixation = 16;
loc.finalFixation = 16;
loc.blockLength = 16;
loc.TRlength = 2;
loc.numReps = 8;
loc.totalTime = loc.initialFixation + loc.numReps *length(loc.conditions)*loc.blockLength + loc.finalFixation;
loc.flickerRate = .1; % in seconds
loc.allFlips = (0:loc.flickerRate:loc.totalTime);
loc.backgroundColor = [126 126 126];

%%%%%%%%%%%%%%%%%
% timing model  %
%%%%%%%%%%%%%%%%%

loc.condsSec = [zeros(loc.initialFixation,1);repmat(kron(loc.conditions',ones(loc.blockLength,1)),loc.numReps,1); zeros(loc.finalFixation,1)];
loc.condsLong = kron(loc.condsSec,ones(1/loc.flickerRate,1));
loc.flickerCond = repmat([1 2],1,round(length(loc.allFlips)/2));

% TR-timed model for analysis
loc.condsTRall = loc.condsSec(1:loc.TRlength:length(loc.condsSec));

loc.condsTRlocLeft = zeros(1,length(loc.condsTRall));
loc.condsTRlocLeft(find(loc.condsTRall==1)) = 1;

loc.condsTRlocRight = zeros(1,length(loc.condsTRall));
loc.condsTRlocRight(find(loc.condsTRall==2)) = 1;

%%%%%%%%%%%%%%%
% open screen %
%%%%%%%%%%%%%%%

HideCursor;
Priority(9);

%%%% open screen
screen=max(Screen('Screens'));
[win, rect]=Screen('OpenWindow',screen,loc.backgroundColor);
Screen(win, 'TextSize', 20);
Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


xc = rect(3)/2;% rect and center, with the flixibility to resize & shift center - change vars to zero if not used.
yc = rect(4)/2+loc.vertOffset;

%%% size and locations 
loc.ppd = pi* rect(3) / (atan(loc.screenWidth/loc.viewingDist/2)) / 360;
loc.size = round(loc.sizeDeg*loc.ppd);                 % in degrees, the size of our objects
loc.offFix = round(loc.offFixDeg*loc.ppd);
loc.fixSize = round(loc.fixSizeDeg*loc.ppd);
loc.littleFix = round(loc.littleFixDeg*loc.ppd);

loc.targetLoc{1} = CenterRectOnPoint([0 0 loc.size loc.size],(xc-loc.offFix-floor(loc.size/2)),yc);
loc.targetLoc{2} = CenterRectOnPoint([0 0 loc.size loc.size],(xc+loc.offFix+floor(loc.size/2)),yc);

%%%%%%%%%%%%%%%%
% checkerboard %
%%%%%%%%%%%%%%%%

loc.checkerboardPix = round(loc.spatialFreqDeg*loc.ppd); % pixels per 1 cycle of checkerboard (B and W square)
loc.checkerboardSize = round(loc.size/loc.checkerboardPix);
loc.gaussHSize = 1;

basicCheck = checkerboard(ceil(loc.checkerboardPix/4),loc.checkerboardSize,loc.checkerboardSize)>.5;
checkSize = size(basicCheck);

[x y] = meshgrid(-checkSize(1)/2+1:checkSize(1)/2, -checkSize(1)/2+1:checkSize(1)/2);

% slice checkerboard for either left side or right side
circle = x.^2 + y.^2 <= (loc.size/2)^2;
%circle = filter2(fspecial('gaussian', loc.gaussHSize, params.stim.guassianSpaceConstant*params.ppd), circle);
loc.checkerboard{1} = (basicCheck*2-1).*circle;
loc.checkerboard{2} = (imcomplement(basicCheck)*2-1).*circle;

%%%% gamma correction
if loc.gammaCorrect > 0
load 7T_Sam.mat
Screen('LoadNormalizedGammaTable', screen, linearizedCLUT);
end

%%%% timing optimization
flipInt = Screen('GetFlipInterval',win);
slack = flipInt/2;Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%%%% initial window - wait for backtick
Screen('FillRect',win,loc.backgroundColor)
Screen(win, 'DrawText', 'Waiting for Backtick.', 10,10,[0 0 0]);
Screen(win, 'Flip', 0);

%%%% make textures
loc.checkTexture{1} = Screen('MakeTexture',win,uint8(loc.backgroundColor(1)+loc.backgroundColor(1)*loc.checkerboard{1}));
loc.checkTexture{2} = Screen('MakeTexture',win,uint8(loc.backgroundColor(1)+loc.backgroundColor(1)*loc.checkerboard{2}));



aperture=Screen('OpenOffscreenwindow', win,loc.backgroundColor(1));

    % First we clear out the alpha channel of the aperture disk to zero -
    % In this area the noise stimulus will shine through:
    Screen('FillOval', aperture, [255 255 255 0], loc.targetLoc{1});
    Screen('FillOval', aperture, [255 255 255 0], loc.targetLoc{2});


KbTriggerWait(53, deviceNumber);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %                         localizer                       % %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%% START LOC LIPPING
for n = 1:(length(loc.allFlips)-1)
    thisCond = loc.condsLong(n);
    if thisCond > 0
    Screen('DrawTexture', win, loc.checkTexture{loc.flickerCond(n)}, [], loc.targetLoc{thisCond});
    %Screen('DrawTexture',win,loc.backTex);
    Screen('DrawTexture', win, aperture, [], [], [], 0);
    end
    
    %%%% draw fixation and RSVP letter
    Screen('FillOval', win,[0 0 0], [xc-round(loc.fixSize/2+loc.outerFixPixels ) yc-round(loc.fixSize/2+loc.outerFixPixels ) xc+round(loc.fixSize/2+loc.outerFixPixels ) yc+round(loc.fixSize/2+loc.outerFixPixels )]); % black fixation ring
    Screen('FillOval', win,[255 255 255], [xc-round(loc.fixSize/2) yc-round(loc.fixSize/2) xc+round(loc.fixSize/2) yc+round(loc.fixSize/2)]); % white fixation ring
    Screen('FillOval', win,[0 0 0], [xc-round(loc.littleFix/2) yc-round(loc.littleFix/2) xc+round(loc.littleFix/2) yc+round(loc.littleFix/2)]); % black fixation dot
    
    %%%%% FLIP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if n == 1 [VBLT loc.startRun FlipT missed] = Screen(win, 'Flip', 0);
    else [VBLT loc.flipTime(n) FlipT missed] = Screen(win, 'Flip', loc.startRun + loc.allFlips(n) - slack); end

end

%%%% to show the very last flip screen for its 100ms
[VBLT experiment.flipTime(length(loc.allFlips)) FlipT missed] = Screen(win, 'Flip', loc.startRun + loc.allFlips(length(loc.allFlips)) - slack);

%%%%%%%%%%%%%%%%%%
% done! wrap up  %
%%%%%%%%%%%%%%%%%%

loc.runTime = GetSecs - loc.startRun;

eval(['save data/loc_' loc.subject '_run' num2str(loc.scanNum) '_' loc.date '.mat loc']);


ShowCursor;
Screen('Close');
Screen('CloseAll');

clear all;

end


