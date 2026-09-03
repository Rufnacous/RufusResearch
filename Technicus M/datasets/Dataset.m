classdef Dataset
    %DATASET Handling object for a dataset.

    properties
        folderpath
        upstream
    end

    methods
        function obj = Dataset(path)
            %DATASET Construct a handle for a dataset of a given path
            db = Database();
            obj.folderpath = path;
            obj.upstream = {};

            upstreamjson = load_upstream(path);

            sources = fields(upstreamjson);
            for s_i = 1:length(sources)
                label = sources{s_i};
                source = upstreamjson.(label);
                if ischar(source.dataset(1))
                    obj.upstream.(label) = Dataset(fullfile(db.repository(source.repo), source.dataset));
                else
                    sss = {};
                    for s_j = 1:length(source.dataset)
                        sss{end+1} = Dataset(fullfile(db.repository(source.repo), source.dataset(s_j)));
                    end
                    obj.upstream.(label) = sss;
                end
            end
        
        end

        function bool = isfile(obj, path)
            %ISFILE Wraps isfile for the dataset.
            bool = isfile(fullfile(obj.folderpath, path));
        end

        function save(obj, path, value)
            %SAVE Wraps save (for .mat files) for the dataset.
            save(fullfile(obj.folderpath, path), "value");
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

        function file = find(obj, pattern)
            %FIND Search for a file based on a pattern like "* mask.png"
            file = obj.load(  dir(fullfile(obj.folderpath, pattern)).name  );
        end

        function value = tag(obj, name)
            %TAG Retrieve the tag value for a given tag name.
            tags = load_tags(obj.folderpath);
            value = tags.(name);
        end

        function savefig(obj, fig, name, format)
            %SAVEFIG Wraps saveas for the dataset.
            saveas(fig, fullfile(obj.folderpath, name), format);
        end

        function f = folder(obj)
            %FOLDER Returns folderpath
            f = obj.folderpath;
        end

        function n = name(obj)
            % NAME Returns name of dataset folder
            [~,n] = fileparts(obj.folderpath);
        end

        function f = repository_folder(obj)
            %REPOSITORY_FOLDER Returns folder of repository
            [f] = fileparts(obj.folderpath);
        end

        function f = in_repository(obj, file)
            %IN_REPOSITORY Returns the filepath of a file stored in the
            %dataset's repsository.
            f = fullfile(obj.repository_folder(), file);
        end
    end
end
