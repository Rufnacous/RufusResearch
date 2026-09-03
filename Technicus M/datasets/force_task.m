function force_task(dataset_or_sets, task)
%FORCE_TASK Forces operation of a task regardless of if it has been done
%already.
    perform_task(dataset_or_sets, task, true)
end