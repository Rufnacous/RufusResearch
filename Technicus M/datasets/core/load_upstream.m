function [upstream] = load_upstream(dataset)
%LOAD_UPSTREAM Retrieve a list of upstream sources for a dataset.
    json_file = fullfile(dataset, 'upstream.json');
    fid = fopen(json_file, "r");
    upstream = jsondecode(char(fread(fid, inf)'));
    fclose(fid);
    if length(upstream) == 0
        upstream = struct();
    end
end