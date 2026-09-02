classdef Dataset
    %DATASET Summary of this class goes here
    %   Detailed explanation goes here

    properties
        folderpath
        upstream
    end

    methods
        function obj = Dataset(path)
            %DATASET Construct an instance of this class
            %   Detailed explanation goes here
            db = Database();
            obj.folderpath = path;
            obj.upstream = {};

            upstreamjson = load_upstream(path);

            sources = fields(upstreamjson);
            for s_i = 1:length(sources)
                label = sources{s_i};
                source = upstreamjson.(label);
                if length(source.dataset) == 1
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
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            bool = isfile(fullfile(obj.folderpath, path));
        end

        function save(obj, path, value)
            save(fullfile(obj.folderpath, path), "value");
        end

        function value = load(obj, path)
            if strcmp( path.name(end-3:end), ".mat")
                load(fullfile(obj.folderpath, path));
            else
                value = fopen(fullfile(obj.folderpath, path.name), "r");
            end
        end

        function file = find(obj, pattern)
            file = obj.load(  dir(fullfile(obj.folderpath, pattern))  );
        end
    end
end
