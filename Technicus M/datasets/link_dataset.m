function link_dataset(dataset, upstream_sources_to_add)

    json_file = fullfile(dataset, 'upstream.json');
    if isfile(json_file)
        upstream = load_upstream(dataset);
    else
        upstream = {};
    end

    usa_fields = fields(upstream_sources_to_add);
    for f_i = 1:length(usa_fields)
        field_name = usa_fields{f_i};
        source = upstream_sources_to_add.(field_name);
        if length(source) == 1
            upstream.(field_name) = source;
        else
            upstream.(field_name).repo = source(1).repo;
            upstream.(field_name).dataset = {};
            for j = 1:length(source)
                upstream.(field_name).dataset{end+1} = source(j).dataset;
            end
        end
    end

    fid = fopen(json_file, "w+");
    json_text = jsonencode(upstream, "PrettyPrint",true);
    fwrite(fid, json_text);
    fclose(fid);    

end