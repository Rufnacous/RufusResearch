function [queryset] = get_datasets(db, query)
    all_datasets = {};
    for r_i = db.index()
        repo_sets = dir(db.repository(r_i));
        for s_i = 3:length(repo_sets)
            all_datasets{end+1} = fullfile(repo_sets(s_i).folder, repo_sets(s_i).name);
        end
    end
    
    filter_lambda = @(name) match_dataset(name{1}, query.filter);
    filter_mask = arrayfun(filter_lambda, all_datasets);

    queryset = all_datasets(filter_mask);
    
end