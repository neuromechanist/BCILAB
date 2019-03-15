function run_writedataset(varargin)
% Output a raw online stream into an EEGLAB dataset.
% run__writedataset(SourceStream,FileName,UpdateFrequency,StartDelay)
%
% This function does not do any processing, but just saves a stream to a file (possibly in parallel
% to some other operation processing it).
%
% In:
%   SourceStreamName : Optional name of the stream data structure in the MATLAB base workspace to
%                      take as the data source (previously created with onl_newstream).
%                      (default: 'laststream')
%
%   FileName : File name to write to (default: 'lastdata.set')
%
%   UpdateFrequency : The are at which new chunks of data are appended to the file, in Hz (default: 1)
%
%   StartDelay : Start-up delay before real-time operation begins; grace period until file is being
%                written to, in s. (default: 3)
%
% Examples:
%   % write an input stream (named 'mystream') to a file named 'recording.set' (EEGLAB dataset)
%   run_writedataset('mystream','recording.set')
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-11-19

declare_properties('name','File');

% define arguments
arg_define(varargin, ...
    arg({'in_stream','SourceStreamNames','SourceStream'}, 'laststream',[],'Input Matlab stream name(s). Optional names of stream data structures in the MATLAB base workspace to consider as possible data sources (previously created with onl_newstream); if a stream contains all channels that are needed by the predictor, or alternatively has the right number and type of channels it will be considered as a potential source stream unless ambiguous.'), ...
    arg({'out_filename','FileName'},'lastdata.set',[],'The file name to write to.'), ...
    arg({'update_freq','UpdateFrequency'},1,[0 Inf],'Update frequency. This is the rate at which new chunks of data are appended to the file.'), ...
    arg({'start_delay','StartDelay'}, 3, [0 Inf],'Start-up delay. Delay before real-time operation begins; grace period until file is written.'));

if ~any(out_filename=='/' | out_filename=='\') %#ok<NODEF>
    out_filename = ['bcilab:/userdata/' out_filename]; end
out_filename = env_translatepath(out_filename);

% open the stream and write the initial set file header...
stream = evalin('base',in_stream);
% create missing fields
stream.data = randn(stream.nbchan,1024);
stream.pnts = size(stream.data,2);
stream.xmax = stream.xmin + (stream.pnts-1)/stream.srate;
stream.timestamp_at_beginning = toc(uint64(0));

% prepare .set file for saving
[fp,fn,fe] = fileparts(out_filename); %#ok<ASGLU>
EEG = rmfield(stream,{'buffer','smax','buffer_len','timestamps','timestamps_len','tmax','streamid','timestamp_at_beginning'});
[EEG.data,EEG.datfile] = deal([fn,fe]);
io_save(out_filename,'-mat','-makedirs','-attributes','''+w'',''a''','EEG');

% create the .fdt file...
fid = fopen(fullfile(EEG.filepath, EEG.datfile),'wb','ieee-le');
if fid == -1
    error('Cannot write output file, check permission and space.'); end;

% create a temporary text file to store stream event markers
event_filename = env_translatepath(['bcilab:/userdata/', fn, '_events.txt']);
marker_fid = fopen(event_filename, 'w+');
if marker_fid == -1
    error('Cannot write marker output file, check permission and space.');
end
% write a basic header to the event marker file
fprintf(marker_fid, '%s\t%s\n', 'type', 'latency');

% create timer (which periodically writes to the stream)
t = timer('ExecutionMode','fixedRate', 'Name',[in_stream '_write_timer'], 'Period',1/update_freq, ...
    'StartDelay',start_delay, 'TimerFcn',@(obj,varargin) append_data(in_stream,fid,marker_fid,stream.streamid,obj,EEG));

% start timer
start(t);


% timer callback: visualization
function append_data(stream,fid,marker_fid,streamid,timerhandle,EEG)
try
    % check if the stream and the predictor are still there
    s = evalin('base',stream);
    if s.streamid ~= streamid
        error('Stream changed.'); end

    % get an updated chunk of data
    samples_to_get = min(s.buffer_len, s.smax-ftell(fid)/(4*s.nbchan));
    chunk = s.buffer(:, 1+mod(s.smax-samples_to_get:s.smax-1,s.buffer_len));    
        
    % and write it into the file
    fwrite(fid,chunk,'float');
    
    % check if this data chunk contains any event markers
    marker_chunk = s.marker_pos(:, 1+mod(s.smax-samples_to_get:s.smax-1,s.buffer_len));
        
    % if so, write them into the marker file
    if nnz(marker_chunk) > 0
        % find the sample(s) in this chunk with events
        [marker_pos_in_sample, marker_pos_in_chunk] = find(marker_chunk);

        % EEG samples which correspond to positions in the chunk
        chunk_samples = s.smax - (samples_to_get - 1) : s.smax;
        
        for m = 1:length(marker_pos_in_chunk)
            marker_idx = marker_chunk(marker_pos_in_sample(m), marker_pos_in_chunk(m));
            marker_type = s.marker_buffer(marker_idx).type;
            marker_sample_whole = chunk_samples(marker_pos_in_chunk(m));
            marker_sample_fractional = s.marker_buffer(marker_idx).latency;
            marker_sample = marker_sample_whole + marker_sample_fractional;
            fprintf(marker_fid, '%s\t%i\n', marker_type, marker_sample);
        end 
    end
    
catch e
     if ~strcmp(e.identifier,'MATLAB:UndefinedFunction')
        env_handleerror(e); end
    finalize_dataset(fid,marker_fid,EEG);
    % interrupted: make sure that the file gets closed
    stop(timerhandle);
    delete(timerhandle);
end


function finalize_dataset(fid,marker_fid,EEG)
samples = ftell(fid)/(4*EEG.nbchan);
fclose(fid);
EEG.pnts = samples;
EEG.data = EEG.datfile;
EEG.xmax = EEG.xmin + (EEG.pnts-1)/EEG.srate;
EEG.timestamp_at_end = toc(uint64(0));

% load the event marker file from disk and include the markers in the EEG .set
marker_file = [EEG.filepath, filesep, regexprep(EEG.filename, '.set', '_events.txt')];
frewind(marker_fid);
marker_data = textscan(marker_fid, '%s%d', 'Delimiter', '\t', 'HeaderLines', 1);
if ~isempty(marker_data{1})
   EEG.event = struct('type', marker_data{1}', 'latency', num2cell(marker_data{2}'), ...
        'urevent', num2cell((1:length(marker_data{1}))));
end
fclose(marker_fid);
delete(marker_file);

save(fullfile(EEG.filepath, EEG.filename), '-v6', '-mat', 'EEG');



