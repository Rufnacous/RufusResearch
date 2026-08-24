function label_dataset(db, name, tags_to_add)

    if ~isfolder(fullfile(db, name))
        error('Attempted to label a non-existent dataset!')
    end

    json_file = fullfile(db, name, 'tags.json');
    if isfile(json_file)
        tags = load_tags(db, name);
    else
        tags = {};
    end

    tta_fields = fields(tags_to_add);
    for f_i = 1:length(tta_fields)
        field_name = tta_fields{f_i};
        tags.(field_name) = tags_to_add.(field_name);
    end

    fid = fopen(json_file, "w+");
    json_text = jsonencode(tags, "PrettyPrint",true);
    fwrite(fid, json_text);
    fclose(fid);    

end