%% Elif Wrapper script
%{

this wrapper will run the scripts that generate the data struct and then
create the figures and analyses that will ultimately get into the
manuscript

General organization of data:
Struct: SuperMouse
    name: the name of the animal
    mouse_meta: substruct with fields genotype, gender, dob, implant date etc.
    day_meta: substrauct fields: dasy, time, age, estrus
    daynum: recording number for that animal
    day: date of recording
    epochs: the metadata for each of the recording epochs that day
    tetinfo: the recording location of each tetrode
    taskTypes: quick name of all the task types ran that day
    unitdata; typical unit struct: tet, unitnum, ts, tag
    oldspikes: raw data for spikes (filter framework)
    rawtracking: raw tracking (filter framework)
    coords: ts, x, y, direction, head angle, velocity, epoch number
    sourcefiles: source for the position and spike data
    lincoords: ts linpos, distance from axis, dir,  vel, arm, trialnum,
        epoch ** NOTE: lincoords x and y are actual ts, you will need to
        linearize each trajectory separately (plot linpos dist gets a 2d
        map)
    rawlintracking
    lfpfiles

Data notes:
- the spike data will likely need to ve verified using autocorrelograms and,
ISI violations. We may also want to look at cross correlograms on the same
tetrode
- the linear coords data is segmented into trials, where a trial is an
outbound run and an inbound run to a far arm. The trajectory
-it looks like the linear coord data is basically just snapped to a grid of
trajectories.  an extra manipulation would need to be done to get the
linearized (path equivalent) coordinates of those trajectories)


So analyses types:

1. Behavioral analyses:
    a. overt differences in behavior? do kos run faster, longer, do they
    head pan more? do they wait at each well longer?
        Papers: Engin et al 2015 Tonic Inhibitory Control...
        No changes in locomotion, thigmotaxis, open arm entries or % time
    b. behavioral differences on tasks: two arm vs 4 arm, adjacent vs far,
    and trials to end criterion(5c in a row) and trials to statespace criterion
        Papers: Engin et al., Results: a5DG were worse at reversal of
        morris water maze, showed no latent inhibition (preexposire to fear
        ctx), and 
2. Place field analyses:
    a. is place field prevalence the same across phenotypes?
    b. are place fields shaped the same across phenotypes?
    c. do place fields colaesce at differnet places on maze?
    d. do place fields repeat across arms more in one phenotype?

3. LFP power and lfp events
    a. are ripples more common in one? do they occur at different places?
    b. is theta during run different across the phenotypes?
    c. is beta evident in any animal, and when does it occur?
    d. is theta nested gamma evident anywhere?

4. Spike LFP interactions
    a. is the preferred theta phase different across animals?
    b. is theta precession different (slope and intercept)
    c. can we see cell sequences during ripples? and are they different
    across animals?
    d. if there are interneurons do they cohere to gamma or beta at
    different levels across phenotypes


%}

%% to generate the data struct from raw files use the following

edit Elif_Struct_Builder

%% if you already have a struct, load it here
myfile='ElifData 3-11-2020.mat';
mydir='E:\Elif DG GABAa project Data';
load(fullfile(mydir,myfile));

%%
% 1. behavior analysis
% first, gather 2d running speeds, bouts of running, and occupancy maps


% first grab the raw coordinate data, is it valid?


startind=1; endind=startind+300;
coorddata=SuperMouse(7).coords; coorddata=coorddata(coorddata(:,7)==2,:);
colors=parula(300);

figure;
while endind<=length(coorddata)
    tempcoord=coorddata(startind:endind,:);
    startcoord=tempcoord(1:end-1,:);
    endcoord=tempcoord(2:end,:);
    plot([startcoord(1,2), endcoord(1,2)],[startcoord(1,3), endcoord(1,3)],'color',colors(1,:));
    hold on;
    for k=2:length(startcoord)
        plot([startcoord(k,2), endcoord(k,2)],[startcoord(k,3), endcoord(k,3)],'color',colors(k,:));
    end
    hold off;
    keyboard
    startind=startind+300; endind=startind+300;
end
% the raw coords look fine, the maze looks like it goes from about 
% x =65:1100, y=50:1100

% so we're looking at like 10 pixels per bin


%% what do the raw place fields look like? this is just a quick peek

savedir=uigetdir;
postfix='PlacePlot.tif';
%%
for i=132:length(SuperMouse)
    if ~isempty(SuperMouse(i).coords)
        % parse the epochs
        %figure;
        [epochs,~,epinds]=unique({SuperMouse(i).epochs.epoch_type});
        for k=1:length(epochs)
            if contains(epochs(k),'Track')
                % grab epoch indices that arent this epoch
                nanepochs=[SuperMouse(i).epochs(epinds~=k).epoch];
                tempcoords=SuperMouse(i).coords;
                for no=1:length(nanepochs), tempcoords(tempcoords(:,7)==nanepochs(no),:)=nan; end
                % now use that coordinate data to plot a cells firing fields
                tempcoords=tempcoords(~isnan(tempcoords(:,1)),1:3);
                for un=1:length(SuperMouse(i).unitdata)
                    tempunit=SuperMouse(i).unitdata(un);
                    [a,b,c]=SmoothPlacePlot2(tempcoords,tempunit,'VelocityData',SuperMouse(i).TrackVelData);
                    
                    loc=SuperMouse(i).tetinfo(find([SuperMouse(i).tetinfo.tetrode]== SuperMouse(i).unitdata(un).tet)).target;
                    sgtitle(sprintf('Mouse %s day %s, unit %d tet %d in %s',...
                        SuperMouse(i).name, SuperMouse(i).daynum,...
                        tempunit.unitnum, tempunit.tet, loc));
                    
                    unitname=sprintf('%s_d%s_un%d_tet%d_%s',...
                        SuperMouse(i).name, SuperMouse(i).daynum,...
                        tempunit.unitnum, tempunit.tet, loc);
                    if ~isempty(a)
                        saveas(gcf,fullfile(savedir,[unitname postfix]));
                    end
                    close(gcf);
                end
                
            end
        end
    end
    
end

% this function queries the video file to get the raw coordinate data

% function cmperpix= rn_cmperpix(rawDir, fileNameMask)

%% now we'd like to see if we can actually dissect the trial data:
% so in the linearized position data, we have trial data

% lets plot out a number of trials for a given trajectory
testsess=9;
lincoords=SuperMouse(testsess).lincoords;
coords=SuperMouse(testsess).coords;
runepochs=unique(lincoords(:,8));
% lets go by session, then by trial
figure;
% each run will have a single goal? or two?
sessgoals=cellfun(@(a) a.correct_arm, {SuperMouse(testsess).epochs.task_data});
for i=1:length(runepochs)
    subplot(1,length(runepochs),i);
    trialid=unique(lincoords(lincoords(:,8)==runepochs(i),7));
    colors=jet(length(trialid));
    for j=1:length(trialid)
        okcoords=lincoords(:,7)==trialid(j) & lincoords(:,8)==runepochs(i);
        plot(coords(okcoords,2),coords(okcoords,3),'color',colors(j,:));
        hold on;
    end
    title({sprintf('trials = %d',length(trialid));...
        sprintf('goals: %d',sessgoals(i))});
end
            

% Task Table has trial data in it:
% it has the attempted arm and whether it was rewarded or not***

%% to pull out the trial data for each animal, and tbhe correct arms...

mymice=unique({SuperMouse.name});

for i=1:length(mymice)
    thismouse=find(contains({SuperMouse.name},mymice{i}));
    behdata=[]; cumsum=1;
    for j=1:length(thismouse)
        runepochs=













