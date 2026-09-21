function [return_value] = perform_task(task, dataset_or_sets, force_mode)
%PERFORM_TASK Perform a task on either a dataset or a set of datasets.
    if ~exist("dataset_or_sets")
        return_value = task;
        return
    end
    if force_mode == "ensure"
        perform_task_inner(task, dataset_or_sets, false, false)
    elseif force_mode == "force"
        perform_task_inner(task, dataset_or_sets, true, false)
    elseif force_mode == "hard"
        perform_task_inner(task, dataset_or_sets, true, true)
    end
    return_value = 0;
end


function perform_task_inner(task, dataset_or_sets, force, force_dependencies)

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
                if (force_dependencies && isfield(dep.task, 'operator')) || (~validate(dep.task, dataset_obj))
                    % Run the dependent task here
                    perform_task_inner(dep.task, dataset, force_dependencies, force_dependencies);

                    % If the dependency is an external one and isn't
                    % fulfilled, error
                    if ~isfield(dep.task, 'operator')
                        error(sprintf("[%s] hasn't been fulfilled for %s", dep.task.name, dataset));
                    end
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
                    if (force_dependencies && isfield(dep.task, 'operator')) || (~validate(dep.task, upstream{u_i}))
                        % Run the dependent task on the upstream if
                        % necessary.
                        perform_task_inner(dep.task, upstream{u_i}.folderpath, force_dependencies, force_dependencies);
                        
                        % If the dependency is an external one and isn't
                        % fulfilled, error
                        if ~isfield(dep.task, 'operator')
                            error(sprintf("[%s] hasn't been fulfilled for %s", dep.task.name, upstream{u_i}.folderpath));
                        end
                    end
                end
            end
            
        end

        % If the task hasn't already been run here, run it
        if (force || (~validate(task,dataset_obj)))
            if isfield(task, "operator")
                fprintf("Performing task [%s] on %s\n", task.name, dataset);
                task.operator(dataset_obj);
            else
                fprintf("Skipping operatorless task [%s] on %s\n", task.name, dataset);
            end
        end

    end

end

function [valid] = validate(task, dataset_obj)
     if isstring(task.validator)
         valid = dataset_obj.isfile(task.validator);
     else
         valid = task.validator(dataset_obj);
     end
end