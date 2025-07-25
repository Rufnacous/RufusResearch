module Technicus
    using Printf, Plots, Dates, JSON;
    using CSV, Tables, DataFrames;
    include("lab_book.jl");
    include("result_arrays.jl");
    include("parameter_sets.jl");
    include("resumable_tasks.jl");
    include("whilepools.jl");
    include("pipelines.jl");


    export OperationNode, OperationOutputNode, ExternalInputNode, CollectionNode, SpecificCheck, FileCheck, PipeParams, add_node, @construct
end
