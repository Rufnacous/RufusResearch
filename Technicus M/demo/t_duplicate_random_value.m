function task = t_duplicate_random_value()
    task.operator = @duplicate_random_value;
    task.validator = @is_random_value_doubled;
    task.dependencies = {t_assign_random_value};
end

function duplicate_random_value(dataset)
    x = dataset.load("random_value.mat");
    y = 2 * x;
    dataset.save("random_value_2.mat", y);
end

function bool = is_random_value_doubled(dataset)
    bool = dataset.isfile("random_value_2.mat");
end