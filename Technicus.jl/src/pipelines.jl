
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

abstract type DependencyException <: Exception end
struct ExternalDependencyException <: DependencyException
    node::ExternalInputNode
end
struct UnfulfilledDependencyException <: DependencyException
    node::PipelineNode
end
Base.showerror(io::IO, err::DependencyException) = print(io, "Dependency unfulfilled ", err.node.name)



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
function (node::Union{OperationNode,OperationOutputNode})(channel::String,params::PipeParams; force::Bool=false, do_dependencies::Bool=true, kwargs...)
    verify_dependencies(node, channel, params, do_dependencies; kwargs...)
    

    if (!force) && prevent_re_execution(node, channel, params)
        return
    end

    channel_folder = joinpath(node.network.folder, channel)
    
    return node.perform(channel_folder, params; kwargs...);
end
function (node::PipelineNode)(channels::AbstractArray{String};force::Bool=false, do_dependencies::Bool=true, threaded::Bool=false, kwargs...)
    if threaded
        Threads.@threads for channel in channels
            println(channel)
            try
                node(channel, force=force, do_dependencies=do_dependencies; kwargs...)
            catch e
                if e isa DependencyException
                    println("Dependencies failed for ",channel," on node ",e.node.name)
                else rethrow(e) end
            end
        end
    else
        for channel in channels
            println(channel)
            try
                node(channel, force=force, do_dependencies=do_dependencies; kwargs...)
            catch e
                if e isa DependencyException
                    println("Dependencies failed for ",channel," on node ",e.node.name)
                else rethrow(e) end
            end
        end
    end
end
# function (node::PipelineNode)(channels::AbstractArray{String},params::PipeParams;force::Bool=false, do_dependencies::Bool=true, threaded::Bool=true, kwargs...)
#     for channel in channels
#         println(channel)
#         node(channel, params, force=force, do_dependencies=do_dependencies; kwargs...)
#     end
# end

function verify_dependencies(node, channel, params, do_dependencies; kwargs...)
    for dep in node.dependencies

        verify_dependencies(dep, channel, params, do_dependencies; kwargs...)

        # if all of dep's dependencies are fulfilled
        # but it is not
        if !verify(dep.network, dep.verification, channel, params; kwargs...)
            if do_dependencies
                # println(error_msg(channel, dep.verification))
                # execute it
                # try
                dep(channel, params; kwargs...);
                # catch
                #     println("Fatal dependency fail on ",dep.name)
                #     return false
                # end
            else
                throw(UnfulfilledDependencyException(dep))
            end
        end

    end

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

function error_msg(channel, method::SpecificCheck)
    return method.error_msg
end
function error_msg(channel, method::FileCheck)
    return @sprintf("Required path not found %s for %s", method.paths, channel)
end







