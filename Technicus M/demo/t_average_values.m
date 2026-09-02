function task = t_average_values()
    task.operator = @do_thing;
    task.validator = @check_thing;
    task.dependencies = {};
end

function do_thing(dataset)
    s = 0;
    for i = 1:5
        s = s + dataset.upstream.test1{i}.load('random_value_2.mat');
    end
    s = s / 5;
    dataset.save('average_val.mat', s);
end

function bool = check_thing(dataset)
    bool = dataset.isfile("average_val.mat");
end