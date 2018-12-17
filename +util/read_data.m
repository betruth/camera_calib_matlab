function data = read_data(file_path)
    % Reads "names" from data file. Data file must have format:
    %   % comment
    %   name =
    %   array
    %   name = num
    %   name = string
    %   ...
    % It returns everything as a struct with fields corresponding to the
    % name(s). If multiple names are found, then struct field will be a
    % cell array. It is assumed all "num" are those strings convertable to
    % a logical or double through str2num(); if not, they are assumed to be
    % a string.
    %
    % Inputs:
    %   file_path - string; path to data file to read from.
    %
    % Outputs:
    %   data - struct;

    % Check to make sure data file exists
    if exist(file_path, 'file') ~= 2
        error(['Data file: "' file_path '" does not exist.']);
    end

    % Initialize
    data = struct();

    % Go through line by line; treat all names as cell arrays for now (for
    % simplicity) and "uncell" names with single entries afterwards.
    f = fopen(file_path);
    line = fgetl(f);
    line_num = 1;
    in_array = false; % Gets set to true for lines in array
    while ischar(line)
        % Trim leading and trailing white spaces
        line = strtrim(line);

        % Make sure line isn't blank or a comment
        if ~isempty(line) && line(1) ~= '%'
            % Splitting string with equal sign should either result in 2 or
            % 1 parts.
            line_split = strsplit(line, '=');
            if numel(line_split) == 2
                % This line has a name; initialize cell if name doesn't exist
                name = strtrim(line_split{1});
                if ~isfield(data, name)
                    data.(name) = {};
                end

                % Test if name is a num, string, or array
                param = strtrim(line_split{2});
                if ~isempty(param)
                    % This is either a num or string
                    num = str2doubleorlogical(param);
                    if ~isempty(num)
                        % number
                        data.(name){end+1} = num;
                    else
                        % string
                        data.(name){end+1} = param;
                    end

                    % We are definitely no longer in an array
                    in_array = false;
                else
                    % This is an array; initialize it
                    data.(name){end+1} = [];
                    in_array = true;
                end
            elseif numel(line_split) == 1
                % We must be "in" an array for this to be the case.
                if in_array
                    % Use name from previous iteration; attempt to
                    % concatenate array row.
                    num_line = str2doubleorlogical(line);

                    % Check to make sure line contains double or logical
                    if ~isempty(num_line)
                        % Check to make sure number of elements allows it
                        % to be vertically concatenated
                        if isempty(data.(name){end}) || ...
                           size(data.(name){end}, 2) == size(num_line, 2)
                            data.(name){end} = vertcat(data.(name){end}, ...
                                                       num_line);
                        else
                            error(['Failed to concatenate line: "' ...
                                    num2str(line_num) '" for array with ' ...
                                   'name: "' name '" and value: "' line ...
                                   '" because the number of elements do ' ...
                                   'not match the previous row.']);
                        end
                    else
                        error(['Failed to concatenate line: "' ...
                                num2str(line_num) '" for array with ' ...
                               'name: "' name '" and value: "' line ...
                               '" because it is not a double or logical ' ...
                               'number.']);
                    end
                else
                    error(['Unknown line: "' num2str(line_num) '" ' ...
                           'with value: "' line '". A line without an ' ...
                           '"=" is only valid for an array.']);
                end
            else
                error(['Multiple assignments on line: "' num2str(line_num) ...
                       '" with value: "' line '".']);
            end
        end

        % Get next line
        line = fgetl(f);
        line_num = line_num+1;
    end
    fclose(f);

    % "Uncell" names with single entries.
    data_fields = fields(data);
    for i = 1:numel(data_fields)
        if numel(data.(data_fields{i})) == 1
            data.(data_fields{i}) = data.(data_fields{i}){1};
        end
    end
end

function num = str2doubleorlogical(str)
    num = str2num(str); %#ok<ST2NM>
    if ~isempty(num)
        % Note that if string is a function name, then this can cause
        % str2num to have issues, hence why the double and logical check
        % are done here
        if ~any(strcmp(class(num), {'double', 'logical'}))
            num = [];
        end
    end
end
