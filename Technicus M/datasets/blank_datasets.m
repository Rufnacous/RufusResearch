function blank_datasets(repo, number, base_name, labelling_func, linking_func)
%BLANK_DATASETS Create new dataset folders in the specified repository
%   repo: Choose the repo db.repository(i) where i is the i'th folder
%   listed in the env file. number: How many new dataset folders?
%   base_name: String for naming the folders. labelling_func: Lambda
%   function over i that returns a struct of tags. linking_func: Lambda
%   over i that returns a struct of upstream references (each with a repo
%   and a dataset).

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