
abstract type PipelineNode end;
abstract type DependablePipelineNode <: PipelineNode end;

abstract type PipelineVerification end;
struct SpecificCheck <: PipelineVerification
    fn::Function
    error_msg::String
end
struct FileCheck <: PipelineVerification
    paths::Vector{String}
end
FileCheck(paths::Vararg{String}) = FileCheck(collect(paths))

struct ExternalInputNode <: DependablePipelineNode
    network
    name::String
    dependencies::AbstractArray{DependablePipelineNode}
    verification::PipelineVerification
end
ExternalInputNode(n,name,dependencies::AbstractArray{String},v) = ExternalInputNode(n,name,[n[s] for s in dependencies], v)
struct OperationNode <: DependablePipelineNode
    network
    name::String
    dependencies::AbstractArray{DependablePipelineNode}
    verification::PipelineVerification
    perform::Function
end
OperationNode(n,name,dependencies::AbstractArray{String},v,p) = OperationNode(n,name,[n[s] for s in dependencies], v,p)
struct OperationOutputNode <: PipelineNode
    network
    name::String
    dependencies::AbstractArray{DependablePipelineNode}
    perform::Function
end
OperationOutputNode(n,name,dependencies::AbstractArray{String},p) = OperationOutputNode(n,name,[n[s] for s in dependencies],p)
struct CollectionNode <: PipelineNode
    network
    name::String
    items::AbstractArray{PipelineNode}
end

struct ExternalDependencyException <: Exception
    node::ExternalInputNode
end
Base.showerror(io::IO, err::ExternalDependencyException) = print(io, "External dependency unfulfilled ", err.node.name)



struct PipeNetwork
    folder::String
    nodes::Dict{String, PipelineNode}
end
PipeNetwork(folder) = PipeNetwork(folder, Dict{String, PipelineNode}());
Base.getindex(network::PipeNetwork,nodename::String) = network.nodes[nodename];

function add_node(network::PipeNetwork, nodetype::DataType, name::String, args...; kwargs...)
    node = nodetype(network, name, args...; kwargs...);
    network.nodes[name] = node;
    println("Added ",node.name, " to network.")
    return node;
end
macro construct(network, nodetype, name, args...)
    return quote
        add_node($(esc(network)), $(esc(nodetype)), $(esc(name)), $(esc.(args)...)).perform
    end
end

const PipeParams = Dict{String, Any};

function prevent_re_execution(node::OperationNode, channel::String, params::PipeParams)
    if verify(node.network, node.verification, channel, params)
        println("This node has already been executed.")
        return true
    end
    return false
end
function prevent_re_execution(node::OperationOutputNode, channel::String, params::PipeParams)
    return false
end


function (node::PipelineNode)(channel::String; kwargs...)
    node(channel, PipeParams(); kwargs...)
end
function (node::PipelineNode)(channel::String,params::PipeParams; kwargs...)
    println("No operation def given for type ", typeof(node)," of ",node.name)
end
function (node::ExternalInputNode)(channel::String,params::PipeParams; kwargs...)
    throw(ExternalDependencyException(node))
end
function (node::CollectionNode)(channel::String, params::PipeParams; kwargs...)
    for item in node.items
        item(channel, params; kwargs...);
    end
end
function (node::Union{OperationNode,OperationOutputNode})(channel::String,params::PipeParams; force::Bool=false, kwargs...)
    verify_dependencies(node, channel, params; kwargs...);
    

    if (!force) && prevent_re_execution(node, channel, params)
        return
    end

    channel_folder = joinpath(node.network.folder, channel)
    
    return node.perform(channel_folder, params; kwargs...);
end
function (node::PipelineNode)(channels::AbstractArray{String};force::Bool=false, kwargs...)
    for channel in channels
        try
            node(channel, force=force; kwargs...)
        catch e
            if e isa ExternalDependencyException
                println("Dependencies failed for ",channel," on node ",e.node.name)
            else rethrow(e) end
        end
    end
end
function (node::PipelineNode)(channels::AbstractArray{String},params::PipeParams;force::Bool=false, kwargs...)
    for channel in channels
        node(channel, params, force=force; kwargs...)
    end
end

function verify_dependencies(node, channel, params; kwargs...)
    for dep in node.dependencies

        if !verify_dependencies(dep, channel, params; kwargs...)
            return false
        end
        # if all of dep's dependencies are fulfilled
        # but it is not
        if !verify(dep.network, dep.verification, channel, params; kwargs...)
            println(error_msg(dep.verification))
            # execute it
            # try
            dep(channel, params; kwargs...);
            # catch
            #     println("Fatal dependency fail on ",dep.name)
            #     return false
            # end
        end

    end

    return true

end




function verify(network::PipeNetwork, method::SpecificCheck, channel::String, params::PipeParams; kwargs...)
    channel_folder = joinpath(network.folder, channel)
    return method.fn(channel_folder, params; kwargs...);
end
function verify(network::PipeNetwork, method::FileCheck, channel::String, params::PipeParams; kwargs...)
    return all(
        [ ispath( joinpath( network.folder, channel, path_to_check ) )
          for path_to_check in method.paths ]
        )
end

function error_msg(method::SpecificCheck)
    return method.error_msg
end
function error_msg(method::FileCheck)
    return @sprintf("Required path not found %s", method.paths)
end







