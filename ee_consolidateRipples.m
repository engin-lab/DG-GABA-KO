%Consolidate ripples from all tetrodes into a single array. Count any
%rippples within 30ms of each other as a single ripple. Region = brain
%region ('CA1' or 'PFC'). rippleTet is a x*3 array with ripple start ind,
%end ind and pos ind as columns.

function rippleTet = ee_consolidateRipples(prefix,day,epoch,region)

%find tetrodes for prefix/day/epoch/region 


animInd=ee_findAnimInd(prefix);
load('F:/animal_metadata_190415.mat');

tetlist=[];
for i=1:size(animDB(animInd).recording_data(day).tet_info,2)
    if strcmp(animDB(animInd).recording_data(day).tet_info(i).target,region) && (animDB(animInd).recording_data(day).tet_info(i).ref==0)
        tetlist=[tetlist,i];
    end
end

rippleFile=sprintf('F:/%s_direct/%sripples%02i.mat',prefix, prefix, day);
load(rippleFile);

%30ms in number of indices:
tet=tetlist(1);
diff=ripples{day}{epoch}{tet}.samprate*0.03;

rippleTet=[];
for i=1:length(tetlist)
    tet=tetlist(i);
    rippleT=[ripples{day}{epoch}{tet}.startind ripples{day}{epoch}{tet}.endind ripples{day}{epoch}{tet}.posind];
    rippleTet=[rippleTet;rippleT];
end

rippleTet=sortrows(rippleTet);

indices=[1];
for i=1:(size(rippleTet,1)-1)
    difference=rippleTet(i+1,1)-rippleTet(i,2);
    if difference<=45
        indices(i+1)=0;
    else
        indices(i+1)=1;
    end
end

indices=find(indices);
rippleTet=rippleTet(indices,:);


end
