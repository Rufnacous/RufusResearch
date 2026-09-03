function ensure_task(dataset_or_sets, task)
%ENSURE_TASK Operates a task only if it hasn't been done already.
    perform_task(dataset_or_sets, task, false)
end