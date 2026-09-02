function match = match_dataset(dataset, filter)
%MATCH_DATASET Check if a dataset matches a supplied filter struct.
    parameters = fields(filter);
    tags = load_tags(dataset);
    for p_i = 1:length(parameters)
        param = parameters{p_i};
        if ~strcmp( tags.(param), filter.(param) )
            match = false;
            return
        end
    end
    match = true;
end