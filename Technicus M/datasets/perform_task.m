function perform_task(db, name_or_names, task)

    if iscell(name_or_names)
        names = name_or_names;
    else
        names = {name_or_names};
    end

    for name = names

        for dep_i = 1:length(task.dependencies)
            dep = task.dependencies{dep_i};
            
            if ~dep.validator(fullfile(db, name))
                perform_task(db, name, dep);
            end
        end

        task.operator(fullfile(db, name));

    end

end