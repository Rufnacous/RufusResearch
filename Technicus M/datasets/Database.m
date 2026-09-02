classdef Database
    %DATABASE A set of repositories, which each contain dataset folders.

    properties
        repositories
    end

    methods
        function obj = Database()
            %DATABASE Construct a database. Requires a database.env to be
            %located somewhere in MATLAB's path.
            envfile = which("database.env");
            if isempty(envfile)
                error('database.env not found on the MATLAB path.');
            end
        
            obj.repositories = readlines(envfile);

            for r_i = obj.index()
                if ~isfolder(obj.repositories(r_i))
                    mkdir(obj.repositories(r_i))
                end
            end
        end

        function repo = repository(obj,i)
            %REPOSITORY Retrieve the i'th repository
            repo = obj.repositories(i);
        end
        function idx = index(obj)
            %IDX Returns the 1:N vector to iterate over repositories.
            idx = 1:length(obj.repositories);
        end
    end
end