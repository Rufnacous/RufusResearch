function [upstream] = load_upstream(dataset)
    json_file = fullfile(dataset, 'upstream.json');
    fid = fopen(json_file, "r");
    upstream = jsondecode(char(fread(fid, inf)'));
    fclose(fid);
    if length(upstream) == 0
        upstream = struct();
    end
end