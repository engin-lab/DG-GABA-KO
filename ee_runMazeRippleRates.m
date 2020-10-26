%ee_runMazeRippleRates
%---------------
%Run this after you add area information for each pos in linpos files!!
%linpos{day}{epoch}.data(:,9) should be in-well info (0=not well,
%1=home-well, 2=target-well). 
%linpos{day}{epoch}.data(:,10) should be %in-area info (0=decision area, 
%1=home-arm, 2=target-arm, -1=none).
%---------------
%rippleRates (RR) consolidated from all valid tetrodes in different maze areas
%(see below) for task (t) in a single cell array for all animals where each cell is an
%animal (same order as animDB) and the columns of each cell are:
%1.home-well, correct trials
%2.target-well, correct trials
%3. elsewhere, correct trials
%4. home-well, incorrect trials
%5.target-well, incorrect trials
%6. elsewhere, incorrect trials
%7. stem (home-arm), correct trials
%8. target-arm, correct trials
%9. decision area, correct trials
%10. stem (home-arm), incorrect trials
%11. target-arm, incorrect trials
%12. decision area, incorrect trials

prefix='EE27';
animInd=12;
task=1;
framerate=25;
samprate=1500;
region='CA1';


%find day/epochs for task
taskList=ee_createTaskList(prefix);

%find number of ripples in each part of the maze in correct/incorrect trials for each epoch
%find time spent in each part of the maze in correct/incorrect trials for each epoch
%find ripple rate for correct/incorrect trials in each part of the maze for each epoch
%average ripple rate in each part across epochs of the task
tr=1;
for i=1:size(taskList{task},1)
    day=taskList{task}(i,1);
    epoch=taskList{task}(i,2);
    linposFile=sprintf('F:/%s_direct/%slinpos%02i.mat', prefix,prefix,day);
    load(linposFile);
    epochRipples = ee_consolidateRipples(prefix,day,epoch,region);
    for r=1:size(epochRipples,1)
        %epochRipples 4th column is: In well area? 1=home-well,
        %2=target-well, 0=elsewhere
        if ~isnan(epochRipples(r,3))
            epochRipples(r,4)=linpos{day}{epoch}.data(epochRipples(r,3),9); 
            %epochRipples 5th column is: In area? 0=stem (home-arm), 1=target
            %arm, 2=decision area
            epochRipples(r,5)=linpos{day}{epoch}.data(epochRipples(r,3),10);
        end
    end
    
    %amount of time spent in each area
    for t=1:max(linpos{day}{epoch}.data(:,7))
        triallinpos=find(linpos{day}{epoch}.data(:,7)==t);
        trialLims=[min(triallinpos) max(triallinpos)];
        triallinpos=linpos{day}{epoch}.data(triallinpos,:);
        numhomewell=find(triallinpos(:,9)==1);
        numhomewell=length(numhomewell);
        lengthHomewell=numhomewell/framerate; %time spent in home-well area in seconds
        numtargetwell=find(triallinpos(:,9)==2);
        numtargetwell=length(numtargetwell);
        lengthTargetwell=numtargetwell/framerate;
        numelsewhere=find(triallinpos(:,9)==0);
        numelsewhere=length(numelsewhere);
        lengthElsewhere=numelsewhere/framerate;
        numhomearm=find(triallinpos(:,10)==1);
        numhomearm=length(numhomearm);
        lengthHomearm=numhomearm/framerate;
        numtargetarm=find(triallinpos(:,10)==2);
        numtargetarm=length(numtargetarm);
        lengthTargetarm=numtargetarm/framerate;
        numdecision=find(triallinpos(:,10)==0);
        numdecision=length(numdecision);
        lengthDecision=numdecision/framerate;
                
        trialRipples=[];
        for j=1:size(epochRipples,1)
            if epochRipples(j,3)>=trialLims(1) && epochRipples(j,3)<=trialLims(2)
                trialRipples=[trialRipples; epochRipples(j,:)];
            end
        end
        if ~isempty(trialRipples)
            homewellRipples=numel(find(trialRipples(:,4)==1));
            targetwellRipples=numel(find(trialRipples(:,4)==2));
            elsewhereRipples=numel(find(trialRipples(:,4)==0));
            homearmRipples=numel(find(trialRipples(:,5)==1));
            targetarmRipples=numel(find(trialRipples(:,5)==2));
            decisionRipples=numel(find(trialRipples(:,5)==0));
        else
            homewellRipples=0;
            targetwellRipples=0;
            elsewhereRipples=0;
            homearmRipples=0;
            targetarmRipples=0;
            decisionRipples=0;
        end
        taskTrial{tr}.correct=linpos{day}{epoch}.data(trialLims(1),8);
        taskTrial{tr}.homewellrate=homewellRipples/lengthHomewell;
        taskTrial{tr}.targetwellrate=targetwellRipples/lengthTargetwell;
        taskTrial{tr}.elsewhererate=elsewhereRipples/lengthElsewhere;
        taskTrial{tr}.homearmrate=homearmRipples/lengthHomearm;
        taskTrial{tr}.targetarmrate=targetarmRipples/lengthTargetarm;
        taskTrial{tr}.decisionarearate=decisionRipples/lengthDecision;
        
        tr=tr+1;
    end
end
   clearvars -except animInd taskTrial rippRate;     
        
            
rippRate(animInd).trials=taskTrial;
clearvars -except rippRate      
        
        