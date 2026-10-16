classdef Database
    %DATABASE A set of repositories, which each contain dataset folders.

    properties
        repositories
        repo_names
    end

    methods
        function obj = Database()
            %DATABASE Construct a database. Requires a database.env to be
            %located somewhere in MATLAB's path.
            envfile = which("technicus.env");
            if isempty(envfile)
                error('technicus.env not found on the MATLAB path.');
            end
            obj.repositories = readyaml(envfile);
            obj.repo_names = string(fieldnames(obj.repositories));

            for r_i = obj.repo_index()
                if ~isfolder(obj.repositories.(obj.repo_names(r_i)))
                    mkdir(obj.repositories.(obj.repo_names(r_i)))
                end
            end
        end

        function idx = repo_index(obj)
            %IDX Returns the 1:N vector to iterate over repositories.
            idx = 1:length(obj.repo_names);
        end
    end
end