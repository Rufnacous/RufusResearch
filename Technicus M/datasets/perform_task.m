function [return_value] = perform_task(task, dataset_or_sets, force_mode)
%PERFORM_TASK Perform a task on either a dataset or a set of datasets.
    if ~exist("dataset_or_sets")
        return_value = task;
        return
    end

    if (~exist("force_mode","var")) || (force_mode == "ensure")
        force = false; force_dependencies = false;
    elseif force_mode == "force"
        force = true; force_dependencies = false;
    elseif force_mode == "hard"
        force = true; force_dependencies = true;
    end

    datasets = parse_dataset_input(dataset_or_sets);
    dataset_stacks = prepare_stacks(task, datasets, force, force_dependencies);

    run_stacks(dataset_stacks);
    
    return_value = 0;
end


function [datasets] = parse_dataset_input(dataset_or_sets)

    % Whether we've been passed one dataset or many, let's just process it
    %    as a cellarray of set(s) in the for loop.
    if iscell(dataset_or_sets)
        datasets = dataset_or_sets;
    else

        [s1,e1] = regexp(dataset_or_sets, "\$\(\d+-\d+\)"); % a-b
        [s2,e2] = regexp(dataset_or_sets, "\$\((\d+,)+\d+\)"); % a,b,c,d,e
        if contains(dataset_or_sets, "$(count)")

            db = Database();
            identifiers = string(split(dataset_or_sets,'/'));
            if length(identifiers) ~= 3
                error("Incorrectly formatted dataset input.");
            end
            reponame = identifiers(1);
            partname = identifiers(2);
            set_name = identifiers(3);
            count = length(dir(fullfile( db.repositories.(reponame), partname, strrep(set_name, "_$(count)", "_*") )));
            
            datasets = arrayfun( @(i) strrep(dataset_or_sets, "$(count)", string(i)), 1:count );
        elseif ~isempty(s1)
            hyphenrange = string(extractBetween(dataset_or_sets, s1+2,e1-1));
            hyphenrange = double(split(hyphenrange, "-"));
            datasets = arrayfun( @(i) sprintf("%s%05d", string(extractBetween(dataset_or_sets, 1,s1-1)), i), hyphenrange(1):hyphenrange(2) );
        elseif ~isempty(s2)
            commarange = string(extractBetween(dataset_or_sets, s2+2,e2-1));
            commarange = double(split(commarange, ","));
            datasets = arrayfun( @(i) sprintf("%s%05d", string(extractBetween(dataset_or_sets, 1,s2-1)), i), commarange );
        else
            datasets = {dataset_or_sets};
        end
    end


end

function dataset_stacks = prepare_stacks(task, datasets, force, force_dependencies )
    % For each set we're performing this task on
    dataset_stacks = {};
    for set_i = 1:length(datasets)
        dataset = datasets{set_i};
        dataset_stacks{end+1} = apply_to_dataset(task, dataset, force, force_dependencies, {});
    end
end

function stack = apply_to_dataset(task, dataset, force, force_dependencies, stack)
    
    dataset_obj = Dataset(dataset);


    % If the task hasn't already been run here, run it
    if (force || (~task.validate(dataset_obj)))
        if task.hasoperator
            %fprintf("Performing task [%s] on %s\n", task.name, dataset);
            % task.operator(dataset_obj);
            stack{end+1} = struct("task", task, "dataset_obj", dataset_obj, "user_involvement", false);
        else
            stack{end+1} = struct("task", task, "dataset_obj", dataset_obj, "user_involvement", true);
            %fprintf("Skipping operatorless task [%s] on %s\n", task.name, dataset);
        end
    end


    % For each dependency of the task
    for dep_i = 1:length(task.dependencies)
        dep = task.dependencies{dep_i};

        % If this isn't a dependency on an upstream dataset
        if ~isfield(dep, 'upstream')
            % If the dependency isn't fulfilled
            if (force_dependencies && isfield(dep.task, 'operator')) || (~dep.task.validate(dataset_obj))
                % Run the dependent task here
                stack = apply_to_dataset(dep.task, dataset, force_dependencies, force_dependencies, stack);

                % % If the dependency is an external one and isn't
                % % fulfilled, error
                % if ~isfield(dep.task, 'operator')
                %     stack{end+1} = struct("task", dep.task, "dataset_obj", dataset_obj, "user_involvement", true);
                %     %error(sprintf("[%s] hasn't been fulfilled for %s", dep.task.name, dataset));
                % end
            end

        % If this dependency relies on an upstream dataset(s)
        else
            if ~isfield(dataset_obj.upstream, dep.upstream)
                error("Dataset: %s does not have upstream target set: %s", dataset_obj.name(),dep.upstream);
            end
            upstream = dataset_obj.upstream.(dep.upstream);
            % upstream may be one or multiple, let's just make it a
            %   cellarray as before
            if isscalar(upstream)
                upstream = {upstream};
            end
            % For each upstream set for this dependency
            for u_i = 1:length(upstream)
                if (force_dependencies && isfield(dep.task, 'operator')) || (~dep.task.validate(upstream{u_i}))
                    % Run the dependent task on the upstream if
                    % necessary.
                    stack = apply_to_dataset(dep.task, upstream{u_i}.folderpath, force_dependencies, force_dependencies, stack);
                    
                    % % If the dependency is an external one and isn't
                    % % fulfilled, error
                    % if ~isfield(dep.task, 'operator')
                    %     stack{end+1} = struct("task", dep.task, "dataset_obj", upstream{u_i}, "user_involvement", true);
                    %     error()
                    %     %error(sprintf("[%s] hasn't been fulfilled for %s", dep.task.name, upstream{u_i}.folderpath));
                    % end
                end
            end
        end
        
    end

end



function run_stacks(dataset_stacks)
    while any(cellfun(@(s) ~isempty(s), dataset_stacks)) % While we still have stacks with jobs in

        external_tasks_stuck_on = {};
        found_task_to_do = false;
        for s_i = 1:length(dataset_stacks)
            stack = dataset_stacks{s_i};
            if ~isempty(stack) % If there are tasks on this stack
                if ~( stack{end}.user_involvement )
                    task = stack{end}.task;
                    dataset_obj = stack{end}.dataset_obj;
                    fprintf("Performing task [%s] on %s\n", task.name, dataset_obj.name());
                    task.operator(dataset_obj);
                    dataset_stacks{s_i} = stack(1:(end-1));
                    found_task_to_do = true;
                    break
                else
                    external_tasks_stuck_on{end+1} = sprintf("[%s] for %s", task.name, dataset_obj.name());
                end
            end
        end
        if found_task_to_do
            continue
        end

        for mtso_i = 1:length(external_tasks_stuck_on)
            fprintf( external_tasks_stuck_on{mtso_i} );
        end
        error("Cannot proceed further; no operable tasks left - read printout above of manual.");

        % Todo: There are operable tasks and external tasks.
        % But some operable tasks require manual input. We have no way to
        % distinguish these so far; but also don't know what order to sort
        % them. Realistically we need task tags: normal/heavy/manual and
        % this would allow a reasonable sorting.


    end
end
