function [queryset] = get_datasets(db, query)
    datasets = {dir(db).name};
    datasets = datasets(3:end);
    
    filter_lambda = @(name) match_dataset(db, name{1}, query.filter);
    filter_mask = arrayfun(filter_lambda, datasets);

    queryset = datasets(filter_mask);
    
end