function [tags] = load_tags(dataset)
%LOAD_TAGS Retrieve the .json tag values for a dataset.
    json_file = fullfile(dataset, 'tags.json');
    fid = fopen(json_file, "r");
    tags = jsondecode(char(fread(fid, inf)'));
    fclose(fid);
end