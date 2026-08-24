function match = match_dataset(db, name, filter)
    parameters = fields(filter);
    tags = load_tags(db, name);
    for p_i = 1:length(parameters)
        param = parameters{p_i};
        if ~( tags.(param) == filter.(param) )
            match = false;
            return
        end
    end
    match = true;
end