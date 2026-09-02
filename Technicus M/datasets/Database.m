classdef Database
    %DATABASE Summary of this class goes here
    %   Detailed explanation goes here

    properties
        repositories
    end

    methods
        function obj = Database()
            %DATABASE Construct an instance of this class
            %   Detailed explanation goes here
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
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            repo = obj.repositories(i);
        end
        function idx = index(obj)
            idx = 1:length(obj.repositories);
        end
    end
end