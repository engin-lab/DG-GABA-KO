%%Decision area between the intersection of arms 2 - 3 and the end of arm 1.
%Xmin-Xmax determined as where the line from arms 2-3 intersection hits the
%outer edges of these arms. "in arm" for arms 1 and 4 determined based on
%x> max decision area x (for arm 1), x< min decision area x (for arm 4).
%For arms 2 and 3, in-arm determined based on y< min decision area y.
%In-arm for home arm determined based on y> max decision area y.
%0=decision area
%1=home arm
%2=target arm
%-1=other location

animID='EE27';
animInd=12;
animDir='F:\EE27_direct';
task=1;
%arms=[0;1;2;3;4]; %0=home well
%--------------------------------------------------------------------------
dXmin=453.7524;
dXmax=631.8924;
dYmin=470.7084;
dYmax=584.2296;

taskList = ee_createTaskList(animID);
taskList=taskList{task};

for epochs=1:size(taskList,1)
    day=taskList(epochs,1);
    epoch=taskList(epochs, 2);
    linposFile=sprintf('%s/%slinpos%02i.mat', animDir, animID, day); 
    load(linposFile);
    for ind=1:length(linpos{day}{epoch}.data)
        targetWell=linpos{day}{epoch}.data(ind,6);
        if linpos{day}{epoch}.data(ind,2)>dXmin && linpos{day}{epoch}.data(ind,2)<dXmax && linpos{day}{epoch}.data(ind,3)>dYmin && linpos{day}{epoch}.data(ind,3)<dYmax
            linpos{day}{epoch}.data(ind,10)=0;
        elseif linpos{day}{epoch}.data(ind,3)>dYmax
            linpos{day}{epoch}.data(ind,10)=1;
        elseif targetWell==1 && linpos{day}{epoch}.data(ind,2)>dXmax
            linpos{day}{epoch}.data(ind,10)=2;
        elseif targetWell==2 && linpos{day}{epoch}.data(ind,3)<dYmin
            linpos{day}{epoch}.data(ind,10)=2;
        elseif targetWell==3 && linpos{day}{epoch}.data(ind,3)<dYmin
            linpos{day}{epoch}.data(ind,10)=2;
        elseif targetWell==4 && linpos{day}{epoch}.data(ind,2)<dXmin
            linpos{day}{epoch}.data(ind,10)=2;
        else
            linpos{day}{epoch}.data(ind,10)=-1;
        end
    end
    save(linposFile);
end

%clearvars except linpos and save the linpos file at the end to get rid of
%the workspace vars in linpos