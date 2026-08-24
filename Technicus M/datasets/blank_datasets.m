function blank_datasets(db, number, base_name, labelling_func)
%BLANK_DATASETS Summary of this function goes here
%   Detailed explanation goes here

    for ds_i = 1:number

        name = sprintf("%s_%05d",base_name, ds_i);
        folder_name = fullfile(db, name);

        if ~isfolder(folder_name)
            mkdir(folder_name)
        end

        labels = labelling_func(ds_i);
        label_dataset(db, name, labels);

    end

end