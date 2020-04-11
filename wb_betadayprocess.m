function wb_betadayprocess(directoryname,fileprefix,days, varargin)
%------------------------
%%%%%% EE: I can't make it loop through days. Run for each day separately.
%%%%%% You can specify the tetrodes for all days in the daytetlist and keep
%%%%%% it as such when running for each day. No need to re-create it for
%%%%%% only that day.
%------------------------
%%%You can specify tetrodes you want to run in daytetlist or you can call
%%%ee_pickCellTet(directoryname, fileprefix) to pick tetrodes that have
%%%cells for that day.
%------------------------
%Applies a beta filter to all epochs for each day and saves the data
%in the EEG subdirectory of the directoryname folder.  
%
%directoryname - example '/data99/user/animaldatafolder/', a folder 
%                containing processed matlab data for the animal
%
%fileprefix -    animal specific prefix for each datafile (e.g. 'fre')
%
%days -          a vector of experiment day numbers 
%
%options -
%
%		'daytetlist', [day tet ; day tet ...]
%			specifies, for each day, the tetrodes for which beta
%			extraction should be done
%       'tetfilter', 'isequal($area,''CA1'')'
%           specifies the filter to use to determine which tetrodes 
%           beta extraction should be done. This assumes that a
%           tetinfostruct exists.
%		'f', filter
%			specifies the filter to use. This should be made specificially
%			for each animal based on individual cutoffs.
%		'assignphase', 0 or 1
%			specifices whether to ignore spike fields (0) or assign 
%			a beta phase to each spike and save the data (1).
%			Default 0
%       'nonreference', 0 or 1
%           specifies whether to use EEG or EEGnonreference
%           Default 0

[daytetlist] = ee_pickCellTet(directoryname, fileprefix);

if isempty(daytetlist)
    error('This animal has no cell tetrodes! Please manually specify the tetrodes to be used.')
end

%daytetlist = [1,1;1,4;1,5;1,8;2,1;2,2;2,4;2,7;2,8;3,1;3,2;3,7;3,8;4,1;4,7;4,8;5,1;5,7;6,7;7,1;7,7;7,8;8,1;8,2;8,3;8,7;8,8;9,1;9,7;9,8;10,1;10,2];

f = '';
defaultfilter = (['C:\Users\eengin\Documents\Code_Vault\Src_Matlab\Filters\betafilter.mat']);% change to where you save the filter

assignphase = 1;  
tetfilter = '';
dognd = 0;  %if EEG in reference to ground is needed
downsample = 10;
tmpflist=[];
eegflip=0;

%set variable options
for option = 1:2:length(varargin)-1
    switch varargin{option}
        case 'daytetlist'
            daytetlist = varargin{option+1};
        case 'f'
    	    f = varargin{option+1};
        case 'assignphase'
            assignphase = varargin{option+1};
        case 'tetfilter'
            tetfilter = varargin{option+1};
        case 'dognd'
            dognd = varargin{option+1};
        case 'eegflip'
            eegflip = varargin{option+1};
    end
end


% check to see if the directory has a trailing '/'
if (directoryname(end) ~= '/')
    warning('directoryname should end with a ''/'', appending one and continuing');
    directoryname(end+1) = '/';
end

minint = -32768;
days = days(:)';

% if the filter was not specified, load the default
if isempty(f)
    load(defaultfilter);
else
    eval(['load',f])
end

for day = days
    if (assignphase)
        %load up the spike file
        spikes = loaddatastruct(directoryname,fileprefix, 'spikes',day);
    end
    % create the list of files for this day that we should filter
    if isempty(daytetlist) && isempty(tetfilter)
        if dognd
            tmpflist = dir(sprintf('%s/EEG/*eeg%02d-*.mat', directoryname, day));
        else
            tmpflist = dir(sprintf('%s/EEG/*eegref%02d-*.mat', directoryname, day));
        end
        flist = cell(size(tmpflist));
        for i = 1:length(tmpflist)
            if dognd
                flist{i} = sprintf('%s/EEG/%s', directoryname, tmpflist(i).name);
            else
                flist{i} = sprintf('%s/EEG/%s', directoryname, tmpflist(i).name);
            end
        end
    elseif ~isempty(tetfilter)
        flist = {};
        load(sprintf('%s/%stetinfo.mat',directoryname,fileprefix));
        tmptetlist = evaluatefilter(tetinfo,tetfilter);
        tet = unique(tmptetlist(tmptetlist(:,1)==day,3));
        tmpflist = [];
        for t = 1:length(tet);
            if dognd
                tmp = dir(sprintf('%s/EEG/*eeg%02d-*-%02d.mat', ...
                    directoryname, day,tet(t)));
            else
                tmp = dir(sprintf('%s/EEG/*eegref%02d-*-%02d.mat', ...
                    directoryname, day,tet(t)));
            end
            tmpflist = [tmpflist; tmp];
        end
        for i = 1:length(tmpflist)
            if dognd
                flist{i} = sprintf('%s/EEG/%s', directoryname, tmpflist(i).name);
            else
                flist{i} = sprintf('%s/EEG/%s', directoryname, tmpflist(i).name);
            end
        end
    else
        % find the rows associated with this day
        flist = {};
        tet = daytetlist(find(daytetlist(:,1) == day),2);
        for t = 1:length(tet);
            if dognd
                tmp = dir(sprintf('%s/EEG/*eeg%02d-*-%02d.mat', ...
                    directoryname, day,tet(t)));
            else
                tmp = dir(sprintf('%s/EEG/*eegref%02d-*-%02d.mat', ...
                  directoryname, day,tet(t)));
                   
            end
           
            tmpflist = [tmpflist; tmp];
        end
        for i = 1:length(tmpflist)
            if dognd
                flist{i} = sprintf('%s/EEG/%s', directoryname, tmpflist(i).name);
            else
                flist{i} = sprintf('%s/EEG/%s', directoryname, tmpflist(i).name);
            end
        end
    end
    % go through each file in flist and filter it
    for fnum = 1:length(flist)
        % get the tetrode number and epoch
        % this is ugly, but it works
        dash = find(flist{fnum} == '-');
        epoch = str2num(flist{fnum}((dash(1)+1):(dash(2)-1)));
        tet = str2num(flist{fnum}((dash(2)+1):(dash(2)+3)));
	   
%         if mod(epoch,2)
            %load the eeg file
            load(flist{fnum});
            
            if dognd == 0, 
                eeg = eegref; 
            end
            % flip eeg
            if eegflip == 1, 
                eeg{day}{epoch}{tet}.data = eeg{day}{epoch}{tet}.data.*-1;
            end
            a = find(eeg{day}{epoch}{tet}.data < -30000);
            if ~isempty(a)
                [lo,hi]= findcontiguous(a);  %find contiguous NaNs
                for i = 1:length(lo) 
                    if lo(i) > 1 & hi(i) < length(eeg{day}{epoch}{tet}.data)
                        fill = linspace(eeg{day}{epoch}{tet}.data(lo(i)-1), ...
                            eeg{day}{epoch}{tet}.data(hi(i)+1), hi(i)-lo(i)+1);
                        eeg{day}{epoch}{tet}.data(lo(i):hi(i)) = fill;
                    end
                end
            end

            % filter and save the result as int16
            temp = filtfilt(betagammafilter,1,eeg{day}{epoch}{tet}.data');
            hdata = hilbert(temp);
            env = abs(hdata);
            phase = angle(hdata);

            beta{day}{epoch}{tet}.samprate = eeg{day}{epoch}{tet}.samprate;
            beta{day}{epoch}{tet}.starttime = eeg{day}{epoch}{tet}.starttime;

            beta{day}{epoch}{tet}.data(:,1) = int16(temp);
            beta{day}{epoch}{tet}.data(:,2) = int16(phase*10000);
            beta{day}{epoch}{tet}.data(:,3) = int16(env);
            beta{day}{epoch}{tet}.fields = ...
            'filtered_amplitude instantaneous_phase*10000 envelope_magnitude';
            beta{day}{epoch}{tet}.data = ...
                beta{day}{epoch}{tet}.data(1:downsample:end, :);
            beta{day}{epoch}{tet}.samprate = ...
                beta{day}{epoch}{tet}.samprate / downsample;
            clear eegrec
            % replace the filtered invalid entries with the minimum int16 value of
            % -32768
            if ~isempty(a)
                for i = 1:length(lo)
                    if lo(i) > 1 && hi(i) < length(beta{day}{epoch}{tet}.data)
                        beta{day}{epoch}{tet}.data(lo(i):hi(i)) = minint;
                    end
                end
            end

            % save the resulting file
            if dognd
                betafile = sprintf('%sEEG/%sbetagnd%02d-%d-%02d.mat', ...
                    directoryname, fileprefix, day, epoch, tet);
                betagnd = beta;
                save(betafile, 'betagnd');
                
            else
                betafile = sprintf('%sEEG/%sbeta%02d-%d-%02d.mat', ...
                    directoryname, fileprefix, day, epoch, tet);
                save(betafile, 'beta');

            end
%         end
    end
    if assignphase && ~isempty(spikes) && ~mod(epoch,2)
        %check to see if there are spikes on this tetrode
        s = [];
        try
            s = spikes{day}{epoch}{tet};
        end
        if ~isempty(s)
            g = beta{day}{epoch}{tet};
            gtimes = g.starttime:(1/g.samprate):(g.starttime+ ... 
                (length(g.data)-1)/g.samprate);
            for c = 1:length(s)
                data = [];
                try
                    data = s{c}.data;
                end
                if ~isempty(data)
                    ind = lookup(data(:,1),gtimes);
                    spikes{day}{epoch}{tet}{c}.betaphase = ...
                        double(g.data(ind,2))/10000;
                end
            end
        end
    end
    clear beta
    clear betagnd
    if assignphase
        savedatastruct(spikes,directoryname,fileprefix,'spikes');
    end
end
