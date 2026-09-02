function perform_task(dataset_or_sets, task)
%PERFORM_TASK Perform a task on either a dataset or a set of datasets.

    if iscell(dataset_or_sets)
        datasets = dataset_or_sets;
    else
        datasets = {dataset_or_sets};
    end

    for set_i = 1:length(datasets)
        dataset = datasets{set_i};

        for dep_i = 1:length(task.dependencies)
            dep = task.dependencies{dep_i};
            
            if ~dep.validator(Dataset(dataset))
                perform_task(dataset, dep);
            end
        end

        task.operator(Dataset(dataset));

    end

end