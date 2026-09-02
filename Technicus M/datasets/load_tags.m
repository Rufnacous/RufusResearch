function [tags] = load_tags(dataset)
    json_file = fullfile(dataset, 'tags.json');
    fid = fopen(json_file, "r");
    tags = jsondecode(char(fread(fid, inf)'));
    fclose(fid);
end