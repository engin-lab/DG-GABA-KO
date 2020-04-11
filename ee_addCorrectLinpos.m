function ee_addCorrectLinpos(datadir, anim)

%Adds a new column (Column 8) to the data in linpos struct for all epochs in a day; 
%Correct trajectory = 1
%Incorrect trajectory = 0
%Takes correct arm info from taskinfo struct

cd(datadir)

cellinf=sprintf('%scellinfo.mat', anim);
load(cellinf);

days=length(cellinfo);

for day=1:days

    task_data= sprintf('%s/%stask%02i.mat',datadir,anim,day);
    load(task_data);

    correct=[];

    %---Create a correct/incorrect vector for each epoch
    for epoch=1:length(task{day})
        linpos_data= sprintf('%s/%slinpos%02i.mat',datadir,anim,day);
        load(linpos_data);
        linpos{day}{epoch}.field=linpos{day}{epoch}.field + ' Correct?'; %Add new field to linpos struct for correctness
        if strcmp(task{day}{epoch}.env, '4-Arm Maze') == 1 %only for 4-arm tasks
             correct_arm=task{day}{epoch}.correct_arm; %find correct arm for task
             for i=1:length(linpos{day}{epoch}.data) %make a correct/incorrect variable with each cell=an epoch
                if linpos{day}{epoch}.data(i,6) == correct_arm
                    correct{epoch}(i,1)=1;
                else
                    correct{epoch}(i,1)=0;
                end
             end
           
        end
   
     end

    %----Add the correct? column to linpos struct.data
    for epoch=1:length(task{day})
        if strcmp(task{day}{epoch}.env, '4-Arm Maze') == 1;
            linpos{day}{epoch}.data(:,8)=correct{epoch}(:,1);
            save linpos
        end
    end

save(linpos_data)

end


end



