classdef Dataset
    %DATASET Handling object for a dataset.

    properties
        folderpath
        upstream
    end

    methods
        function obj = Dataset(identifier)
            %DATASET Construct a handle for a dataset of a given path
            db = Database();

            if ~isfolder(identifier)

                identifier = strrep(identifier, "\", "/");
                identifiers = string(split(identifier,'/'));
                if length(identifiers) ~= 3
                    error("Incorrectly formatted dataset input.");
                end
                reponame = identifiers(1);
                partname = identifiers(2);
                set_name = identifiers(3);
    
                if ~isfield(db.repositories, reponame)
                    error("Specified repository does not exist in db.");
                end
                repopath = db.repositories.(reponame);
    
                partpath = fullfile(repopath, partname);
                if ~isfolder(partpath)
                    error("Specified partition does not exist.")
                end
                datasetpath = fullfile(partpath, set_name);
                if ~isfolder(datasetpath)
                    error("Specified dataset does not exist as folder.")
                end
            else
                datasetpath = identifier;
            end

            obj.folderpath = datasetpath;
            obj.upstream = {};

            upstreamjson = load_upstream(datasetpath);

            sources = fields(upstreamjson);
            for s_i = 1:length(sources)
                link = sources{s_i};
                source = upstreamjson.(link);
                if ischar(source.dataset(1))
                    obj.upstream.(link) = Dataset(fullfile(source.repo, source.partition, source.dataset));
                else
                    sss = {};
                    for s_j = 1:length(source.dataset)
                        sss{end+1} = Dataset(fullfile(source.repo, source.partition, source.dataset(s_j)));
                    end
                    obj.upstream.(link) = sss;
                end
            end
        
        end

        function bool = isfile(obj, path)
            %ISFILE Wraps isfile for the dataset.
            bool = isfile(fullfile(obj.folderpath, path));
        end

        function bool = isfolder(obj, path)
            %ISFILE Wraps isfolder for the dataset.
            bool = isfolder(fullfile(obj.folderpath, path));
        end

        function save(obj, path, value)
            %SAVE Wraps save (for .mat files) for the dataset.
            save(fullfile(obj.folderpath, path), "value");
        end

        function s = read_json(obj, path)
            %READ_JSON Reads a json file to a struct
            json_file = fullfile(obj.folderpath, path);
            fid = fopen(json_file, "r");
            s = jsondecode(char(fread(fid, inf)'));
            fclose(fid);
        end

        function write_json(obj, path, s)
            %WRITE_JSON Writes a struct as a json file
            json_file = fullfile(obj.folderpath, path);
            fid = fopen(json_file, "w+");
            json_text = jsonencode(s, "PrettyPrint",true);
            fwrite(fid, json_text);
            fclose(fid);  
        end

        function value = load(obj, path)
            %LOAD Either returns the contents of a saved .mat, or returns
            %the filepath of any other file type.
            if endsWith(path, ".mat")
                load(fullfile(obj.folderpath, path));
            else
                value = fullfile(obj.folderpath, path);
            end
        end

        function f = dir(obj, pattern)
            %DIR Wraps dir for the dataset.
            f = dir(fullfile(obj.folderpath, pattern));
        end

        function file = find(obj, pattern)
            %FIND Search for a file based on a pattern like "* mask.png"
            file = obj.load(  dir(fullfile(obj.folderpath, pattern)).name  );
        end

        function value = tag(obj, name)
            %TAG Retrieve the tag value for a given tag name.
            tags = load_tags(obj.folderpath);
            value = tags.(name);
        end

        function bool = tagvalueis(obj, name, value)
            try
                bool = strcmp(obj.tag(name), value);
            catch
                bool = false;
            end
        end

        function savefig(obj, fig, name, format)
            %SAVEFIG Wraps saveas for the dataset.
            saveas(fig, fullfile(obj.folderpath, name), format);
        end

        function imsave(obj, im, name)
            %IMSAVE Wraps imwrite for the dataset.
            imwrite(im, fullfile(obj.folderpath, name));
        end

        function im = imread(obj, name)
            %IMREAD Wraps imread for the dataset.
            im = imread(fullfile(obj.folderpath, name));
        end

        function f = mkdir(obj, name)
            %MKDIR Wraps mkdir for the dataset.
            f = fullfile(obj.folderpath, name);
            mkdir(f);
        end

        function f = folder(obj)
            %FOLDER Returns folderpath
            f = obj.folderpath;
        end

        function n = name(obj)
            % NAME Returns name of dataset folder
            [~,n] = fileparts(obj.folderpath);
        end

        % Discontinuing
        % function f = repository_folder(obj)
        %     %REPOSITORY_FOLDER Returns folder of repository
        %     [f] = fileparts(obj.folderpath);
        % end

        % Discontinuing
        % function f = in_repository(obj, file)
        %     %IN_REPOSITORY Returns the filepath of a file stored in the
        %     %dataset's repsository.
        %     f = fullfile(obj.repository_folder(), file);
        % end
    end
end
