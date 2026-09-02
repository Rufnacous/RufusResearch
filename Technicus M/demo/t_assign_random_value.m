function task = t_assign_random_value()
    task.operator = @assign_random_value;
    task.validator = @is_random_value_saved;
    task.dependencies = {};
end

function assign_random_value(dataset)
    x = rand();

    dataset.save("random_value.mat", x);
    % save(fullfile(folder, "random_value.mat"), "x");
end

function bool = is_random_value_saved(dataset)
    bool = dataset.isfile("random_value.mat");
    % bool = isfile(fullfile(folder, "random_value.mat"));
end