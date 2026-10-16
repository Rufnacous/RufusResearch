function print_litter(yamlfile)
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

            folders = dir( partpath );
            for f_i = 1:length(folders)
                if strcmp(folders(f_i).name, ".") || strcmp(folders(f_i).name, "..")
                    continue
                end
                if isfile(fullfile(partpath, folders(f_i).name))
                    continue
                end
                
                
                foldername = folders(f_i).name;
                [s1,e1] = regexp(foldername, "(.+)_\d{5}");
                folderpath = foldername;
                if ~isempty(s1)
                    folderpath = string(extractBetween(foldername, s1, e1-6));
                end

                if ~isfield(part_def, folderpath)
                    fprintf(" Litter: %s/%s/%s\n", reponame, partname, foldername);
                    pause(0.1);
                end
            end
        end
    end
end