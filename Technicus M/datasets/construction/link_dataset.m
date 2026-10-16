function link_dataset(dataset, upstream_sources_to_add)
%LINK_DATASET Link other datasets as upstream sources to a dataset.

   

    json_file = fullfile(dataset, 'upstream.json');
    % if isfile(json_file)
    %     upstream = load_upstream(dataset);
    % else
    %     upstream = {};
    % end
    upstream = {};


    usa_fields = fields(upstream_sources_to_add);
    for f_i = 1:length(usa_fields)
        field_name = usa_fields{f_i};
        source = string(upstream_sources_to_add.(field_name));
        if length(source) == 1

            [repo_partition,dataset] = fileparts(source);
            [repo,partition] = fileparts(repo_partition);

            upstream.(field_name).repo = repo;
            upstream.(field_name).partition = partition;
            upstream.(field_name).dataset = dataset;
        else
            [repo_partition,~] = fileparts(source(1));
            [repo,partition] = fileparts(repo_partition);

            upstream.(field_name).repo = repo;
            upstream.(field_name).partition = partition;
            upstream.(field_name).dataset = {};
            for j = 1:length(source)
                [~,dataset] = fileparts(source(j));
                upstream.(field_name).dataset{end+1} = dataset;
            end
        end
    end

    fid = fopen(json_file, "w+");
    json_text = jsonencode(upstream, "PrettyPrint",true);
    fwrite(fid, json_text);
    fclose(fid);    

end