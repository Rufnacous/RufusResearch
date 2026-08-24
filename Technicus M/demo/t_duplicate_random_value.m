function task = t_duplicate_random_value()
    task.operator = @duplicate_random_value;
    task.validator = @is_random_value_doubled;
    task.dependencies = {t_assign_random_value};
end

function duplicate_random_value(folder)
    load(fullfile(folder, "random_value.mat"), "x");
    y = 2 * x;
    save(fullfile(folder, "random_value_2.mat"), "y");
end

function bool = is_random_value_doubled(folder)
    bool = isfile(fullfile(folder, "random_value_2.mat"));
end