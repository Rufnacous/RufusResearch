function [queryset] = select_dataset(db, query)
% SELECT_DATASET Retrieve a dataset from the database via a query
    queryset = get_datasets(db, query);
    if length(queryset) > 1
        error("Attempted to use select_dataset, but multiple datasets were found.")
    end
    queryset = queryset(1);
end