function build_pipeline(yamlfile)
    db = Database();

    if ~exist("yamlfile","var")
        yamlfile = which("technicus.yaml");
        if isempty(yamlfile)
            error('technicus.yaml not found on the MATLAB path.');
        end
    end
    y = readyaml(yamlfile).database;

    for r_i = db.repo_index()
        reponame = db.repo_names(r_i);
        repopath = db.repositories.(reponame);

        repo_def = y.(reponame);
        partition_names = string(fieldnames(repo_def));
        for p_i = 1:length(partition_names)
            partname = partition_names(p_i);
            part_def = repo_def.(partname);
            partpath = fullfile(repopath, partname);

            if ~isfolder(partpath)
                mkdir(partpath)
            end

            dataset_names = string(fieldnames(part_def));
            for d_i = 1:length(dataset_names)
                dataset_name_fundamental = dataset_names(d_i);
                dataset_def = part_def.(dataset_name_fundamental);

                count = 1;
                if isfield(dataset_def, "count")
                    count = dataset_def.count;
                end

                for c_i = 1:count
                    dataset_name = dataset_name_fundamental;
                    if count > 1
                        dataset_name = sprintf("%s_%05d", dataset_name_fundamental, c_i);
                    end
                    dataset_path = fullfile(partpath, dataset_name);
                    if ~isfolder(dataset_path)
                        mkdir( dataset_path );
                    end
                    
                    labels = struct();
                    if isfield(dataset_def, "tags")
                        tagnames = string(fieldnames(dataset_def.tags));
                        for t_i = 1:length(tagnames)
                            labels.(tagnames(t_i)) = dataset_def.tags.(tagnames(t_i));
                        end
                    end
                    label_dataset(dataset_path, labels)
                    
                    links = struct();
                    if isfield(dataset_def, "dependencies")
                        depnames = string(fieldnames(dataset_def.dependencies));
                        for d_i = 1:length(depnames)
                            linkvalue = dataset_def.dependencies.(depnames(d_i));

                            [s1,e1] = regexp(linkvalue, "\$\(\d+-\d+\)"); % a-b
                            [s2,e2] = regexp(linkvalue, "\$\((\d+,)+\d+\)"); % a,b,c,d,e
                            if contains(linkvalue, "$(count)")
                                linkvalue = strrep(linkvalue, "$(count)", sprintf("%05d", c_i));
                            elseif ~isempty(s1)
                                hyphenrange = string(extractBetween(linkvalue, s1+2,e1-1));
                                hyphenrange = double(split(hyphenrange, "-"));
                                linkvalue = arrayfun( @(i) sprintf("%s%05d", string(extractBetween(linkvalue, 1,s1-1)), i), hyphenrange(1):hyphenrange(2) );
                            elseif ~isempty(s2)
                                commarange = string(extractBetween(linkvalue, s2+2,e2-1));
                                commarange = double(split(commarange, ","));
                                linkvalue = arrayfun( @(i) sprintf("%s%05d", string(extractBetween(linkvalue, 1,s2-1)), i), commarange );
                            end
                            links.(depnames(d_i)) = linkvalue;

                        end
                    end
                    link_dataset(dataset_path, links)
                end

            end



            % 
            % 
            % 
            % 
            % 
            % 


        end

    end

end