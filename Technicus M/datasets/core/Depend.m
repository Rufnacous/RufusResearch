classdef Depend
    %DEPEND Summary of this class goes here
    %   Detailed explanation goes here

    properties
        task
        is_on_upstream
        upstream
        tag_filters
    end

    methods
        function obj = Depend(task, varargin)

            % Depend(task_locate_uvp(), "locator", "locator_type", "image-based")

            obj.task = task;
            obj.is_on_upstream = false;
            obj.upstream = [];

            if mod(numel(varargin), 2) == 1
                obj.is_on_upstream = true;
                obj.upstream = varargin{1};
                varargin(1) = [];
            end

            obj.tag_filters = {};
            for i = 1:2:numel(varargin)
                name = varargin{i};
                value = varargin{i+1};
                obj.tag_filters(end+1) = struct("tag", name, "value", value);
            end
        end

    end
end