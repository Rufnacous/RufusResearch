classdef Task
    properties
        hasoperator
        operator
        validator
        dependencies
        name
        weight
    end

    methods
        function obj = Task(name, validator, dependencies, operator, weight)
            if ~exist("weight", "var")
                weight = "light";
            end
            if ~exist("operator", "var")
                hasoperator = false;
                operator = [];
            else
                hasoperator = true;
            end

            obj.name = name;
            obj.validator = validator;
            obj.dependencies = dependencies;
            obj.operator = operator;
            obj.hasoperator = hasoperator;
            obj.weight = weight;
        end


        function [valid] = validate(obj, dataset_obj)
             if isstring(obj.validator)
                 valid = dataset_obj.isfile(obj.validator);
             else
                 valid = obj.validator(dataset_obj);
             end
        end
    end
end