function perform_task(dataset_or_sets, task)
%PERFORM_TASK Perform a task on either a dataset or a set of datasets.

    % Whether we've been passed one dataset or many, let's just process it
    %    as a cellarray of set(s) in the for loop.
    if iscell(dataset_or_sets)
        datasets = dataset_or_sets;
    else
        datasets = {dataset_or_sets};
    end

    % For each set we're performing this task on
    for set_i = 1:length(datasets)
        dataset = datasets{set_i};
        dataset_obj = Dataset(dataset);

        % For each dependency of the task
        for dep_i = 1:length(task.dependencies)
            dep = task.dependencies{dep_i};

            % If this isn't a dependency on an upstream dataset
            if ~isfield(dep, 'upstream')
                % If the dependency isn't fulfilled
                if ~dep.task.validator(dataset_obj)
                    % If the dependency is an external one and isn't
                    % fulfilled, error
                    if ~isfield(dep.task, 'operator')
                        error(sprintf("%s hasn't been fulfilled for %s", dep.task.name, dataset));
                    end
                    % Run the dependent task here
                    perform_task(dataset, dep.task);
                end

            % If this dependency relies on an upstream dataset(s)
            else
                upstream = dataset_obj.upstream.(dep.upstream);
                % upstream may be one or multiple, let's just make it a
                %   cellarray as before
                if isscalar(upstream)
                    upstream = {upstream};
                end
                % For each upstream set for this dependency
                for u_i = 1:length(upstream)
                    if ~dep.task.validator(upstream{u_i})
                        % If the dependency is an external one and isn't
                        % fulfilled, error
                        if ~isfield(dep.task, 'operator')
                            error(sprintf("[%s] hasn't been fulfilled for %s", dep.task.name, upstream{u_i}.folderpath));
                        end
                        % Run the dependent task on the upstream if
                        % necessary.
                        perform_task(upstream{u_i}.folderpath, dep.task);
                    end
                end
            end
            
        end

        % If the task hasn't already been run here, run it
        if ~task.validator(dataset_obj)
            fprintf("Performing task [%s] on %s\n", task.name, dataset);
            task.operator(dataset_obj);
        end

    end

end