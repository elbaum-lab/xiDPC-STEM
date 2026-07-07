%% run_xDPC_batch.m
% Interactive MATLAB replacement for the Python + xDPC.conf launcher.
% Press Enter at any prompt to use the default value.
% Requires the matlab function panther_xDPC.m 

clear;
clc;

matlab_function = 'panther_xDPC';
search_pattern = 'BF-S_Inner1';

%% ---------------- User inputs with defaults --------------
parent_directory = uigetdir('*','Fetch a folder that either contains the files to analyze or contains subfolders of those');% uigetfile(['*' search_pattern '*'],'Fetch a representative file from the folder');
%parent_directory = inputWithDefault('Parent directory','/path/to/your/data/folder');

tilt_step = inputWithDefaultNumeric( ...
    'Tilt step [deg]', ...
    2.0);

semi_angle = inputWithDefaultNumeric( ...
    'Semi-convergence angle [mrad]:', ...
    1.2);

wavelength = inputWithDefaultNumeric( ...
    'Wavelength [nm]', ...
    0.0025);

bf_disk_location = inputWithDefault( ...
    'BF disk covers up to which detector [BF_Inner / DF_Inner / DF_Outer]', ...
    'BF_Inner');

overwrite = 1;% inputWithDefaultLogical('Overwrite? 1-true/0-false',1);

%% ---------------- Basic checks ----------------

if ~isfolder(parent_directory)
    error('Parent directory does not exist: %s', parent_directory);
end


allowed_disks = {'BF_Inner', 'DF_Inner', 'DF_Outer'};
if ~ismember(bf_disk_location, allowed_disks)
    error('Invalid BF disk detector location: %s', bf_disk_location);
end


%% ---------------- Process folders ----------------

disp('Off I go');

file_names = findMatchingFiles(parent_directory, search_pattern);
if size(file_names)>0
    flag_single_folder=true;
    folder_count=1;
else
    flag_single_folder=false;
    folder_list = dir(parent_directory);
    folder_count=numel(folder_list);
end



for k = 1:folder_count

    if flag_single_folder
        folder_name='';
    else
        folder_name = folder_list(k).name;
        if ~folder_list(k).isdir
            continue;
        end
        if strcmp(folder_name, '.') || strcmp(folder_name, '..')
            continue;
        end
    end

    work_dir = fullfile(parent_directory, folder_name);

    fprintf('Processing folder: %s\n', work_dir);

    %% Search in main work directory

    file_names = findMatchingFiles(work_dir, search_pattern);

    tilt_000_file = findTilt000File(file_names);

    tilt_000_path = '';

    if ~isempty(tilt_000_file)
        tilt_000_path = fullfile(work_dir, tilt_000_file);
    end

    %% If not found, optionally search in Segments subfolder

    if isempty(tilt_000_path) && overwrite>0

        segments_work_dir = fullfile(work_dir, 'Segments');

        if isfolder(segments_work_dir)

            file_names = findMatchingFiles(segments_work_dir, search_pattern);
            tilt_000_file = findTilt000File(file_names);

            if ~isempty(tilt_000_file)
                tilt_000_path = fullfile(segments_work_dir, tilt_000_file);
            end
        end
    end

    %% Skip if no tilt000 file was found

    if isempty(tilt_000_path)
        fprintf("No file matching 'tilt000.mrc' found in %s or its 'Segments' subfolder. Skipping this folder.\n", work_dir);
        continue;
    end

    %% Extract tilt parameters

    [pos_tilt, neg_tilt] = extractTiltParameters(file_names);

    if isempty(pos_tilt) || isempty(neg_tilt)
        fprintf('Could not determine positive or negative tilt limits in folder: %s. Skipping.\n', work_dir);
        continue;
    end

    fprintf('Positive tilt: %g\n', pos_tilt);
    fprintf('Negative tilt: %g\n', neg_tilt);
    fprintf('0 deg file: %s\n', tilt_000_file);

    feval( ...
        matlab_function, ...
        tilt_000_path, ...
        work_dir, ...
        num2str(neg_tilt), ...
        num2str(pos_tilt), ...
        num2str(tilt_step), ...
        num2str(semi_angle), ...
        num2str(wavelength), ...
        bf_disk_location ...
    );

end

disp('Finished.');

%% ========================================================================
% Local helper functions
% ========================================================================

function value = inputWithDefault(prompt_text, default_value)

    user_value = input(sprintf('%s [%s]: ', prompt_text, default_value), 's');

    if isempty(user_value)
        value = default_value;
    else
        value = user_value;
    end

end


function value = inputWithDefaultNumeric(prompt_text, default_value)

    user_value = input(sprintf('%s [%g]: ', prompt_text, default_value), 's');

    if isempty(user_value)
        value = default_value;
    else
        value = str2double(user_value);

        if isnan(value)
            error('Invalid numeric value entered for: %s', prompt_text);
        end
    end

end


function value = inputWithDefaultLogical(prompt_text, default_value)

    if default_value
        default_string = 'true';
    else
        default_string = 'false';
    end

    user_value = input(sprintf('%s [%s]: ', prompt_text, default_string), 's');

    if isempty(user_value)
        value = default_value;
        return;
    end

    user_value = lower(strtrim(user_value));

    if any(strcmp(user_value, {'true', 't', 'yes', 'y', '1'}))
        value = true;
    elseif any(strcmp(user_value, {'false', 'f', 'no', 'n', '0'}))
        value = false;
    else
        error('Invalid logical value. Use true/false, yes/no, or 1/0.');
    end

end


function file_names = findMatchingFiles(folder_path, search_pattern)

    d = dir(folder_path);
    file_names = {};

    for i = 1:numel(d)

        if d(i).isdir
            continue;
        end

        if contains(d(i).name, search_pattern)
            file_names{end + 1} = d(i).name; %#ok<AGROW>
        end
    end

    file_names = sort(file_names);

end


function tilt_000_file = findTilt000File(file_names)

    tilt_000_file = '';

    for i = 1:numel(file_names)
        if contains(file_names{i}, 'tilt000.mrc')
            tilt_000_file = file_names{i};
            return;
        end
    end

end


function [max_pos_tilt, min_neg_tilt] = extractTiltParameters(file_names)

    pos_values = [];
    neg_values = [];

    for i = 1:numel(file_names)

        name = file_names{i};

        pos_match = regexp(name, 'tilt(\d{3})\.mrc', 'tokens', 'once');
        neg_match = regexp(name, 'tilt-(\d{2})\.mrc', 'tokens', 'once');

        if ~isempty(pos_match)
            pos_values(end + 1) = str2double(pos_match{1}); %#ok<AGROW>
        end

        if ~isempty(neg_match)
            neg_values(end + 1) = str2double(neg_match{1}); %#ok<AGROW>
        end
    end

    if isempty(pos_values)
        max_pos_tilt = [];
    else
        max_pos_tilt = max(pos_values);
    end

    if isempty(neg_values)
        min_neg_tilt = [];
    else
        min_neg_tilt = -max(neg_values);
    end

end