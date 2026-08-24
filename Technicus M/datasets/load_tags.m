function [tags] = load_tags(db, name)
    json_file = fullfile(db, name, 'tags.json');
    fid = fopen(json_file, "r");
    tags = jsondecode(char(fread(fid, inf)'));
    fclose(fid);
end