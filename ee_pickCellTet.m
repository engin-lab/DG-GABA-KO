function [daytetlist] = ee_pickCellTet(directoryname, fileprefix)

%Pick the tetrodes that have cells for each day and make a daytetlist
%matrix 

%animal='EE27';
file=sprintf('%s%scellinfo.mat', directoryname,fileprefix);
load(file);
day=[];
epoch=[];
tet=[];
daytetlist=[];
i=1;
for day=1:length(cellinfo)
    for epoch=1:size(cellinfo{day})
        for tet=1:length(cellinfo{day}{epoch})
            if ~isempty(cellinfo{day}{epoch}{tet})
                daytetlist(i,1)=day;
                daytetlist(i,2)=tet;
                i=i+1;
            end
        end
    end
end

end


