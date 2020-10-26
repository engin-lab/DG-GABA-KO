%-------------------------------------------------------------------------
%Add to linpos, column 9, 0=not well area; 1=home-well area; 2=target-well
%area

animID='EE27';
distance=50; %distance from well in mm that is to be considered "well area"
task=1; %task number to be analyzed

taskList = ee_createTaskList(animID);
taskList = taskList{task};
coords = ee_wellAreas(distance);

for epochs=1:size(taskList,1)
    day=taskList(epochs,1);
    epoch=taskList(epochs, 2);
    linposFile=sprintf('%slinpos%02i.mat', animID, day); 
    load(linposFile);
    for ind=1:length(linpos{day}{epoch}.data)
        targetWell=linpos{day}{epoch}.data(ind,6);
        if targetWell>0
            wellInd=targetWell+1;
            if linpos{day}{epoch}.data(ind,2)>=coords(wellInd,1) && linpos{day}{epoch}.data(ind,2)<=coords(wellInd,2) && linpos{day}{epoch}.data(ind,3)>=coords(wellInd,3) && linpos{day}{epoch}.data(ind,3)<=coords(wellInd,4)
                linpos{day}{epoch}.data(ind,9)=2;
            elseif linpos{day}{epoch}.data(ind,3)>=coords(1,3) 
                linpos{day}{epoch}.data(ind,9)=1;
            else
                linpos{day}{epoch}.data(ind,9)=0;
            end
        else
            if linpos{day}{epoch}.data(ind,3)>=coords(1,3)
                linpos{day}{epoch}.data(ind,9)=1;
            else
                linpos{day}{epoch}.data(ind,9)=-1;
            end
        end
    end
    clearvars -except taskList coords animID linposFile linpos
    save(linposFile);
end


%clearvars except linpos and save the linpos file at the end to get rid of
%the workspace vars in linpos

