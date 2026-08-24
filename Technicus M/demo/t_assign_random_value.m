function task = t_assign_random_value()
    task.operator = @assign_random_value;
    task.validator = @is_random_value_saved;
    task.dependencies = {};
end

function assign_random_value(folder)
    x = rand();
    save(fullfile(folder, "random_value.mat"), "x");
end

function bool = is_random_value_saved(folder)
    bool = isfile(fullfile(folder, "random_value.mat"));
end