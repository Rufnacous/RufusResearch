function blank_datasets(repo, number, base_name, labelling_func, linking_func)
%BLANK_DATASETS Summary of this function goes here
%   Detailed explanation goes here

    for ds_i = 1:number

        if number == 1
            name = base_name;
        else
            name = sprintf("%s_%05d",base_name, ds_i);
        end
        folder_name = fullfile(repo, name);

        if ~isfolder(folder_name)
            mkdir(folder_name)
        end
    
        if number == 1
            labels = labelling_func;
        else
            labels = labelling_func(ds_i);
        end
        label_dataset(folder_name, labels);

        if number == 1
            links = linking_func;
        else
            links = linking_func(ds_i);
        end
        link_dataset(folder_name, links);

    end

end