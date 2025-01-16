mutable struct ResultMatrix{T,C} <: AbstractArray{T,C}
    data::AbstractArray{T,C}
    filepath::String
    save_every::Bool
end

function ResultMatrix(filepath::String, T::DataType, i::Vararg; save_every::Bool=true)::ResultMatrix
    return ResultMatrix(filepath, Array{T}(undef, i...), save_every=save_every);
end

function ResultMatrix(filepath::String, data::Array; save_every::Bool=true)::ResultMatrix
    resObj = ResultMatrix(data, filepath, save_every);
    save(resObj);
    return resObj;
end

function ResultMatrix(filepath::String; force_rm_format=true)::ResultMatrix
    if split(filepath,".")[end] == "csv"
        csvfile = CSV.read(filepath, DataFrame, header=false);
        m = Array(csvfile);
        return ResultMatrix(m, filepath, false);

    elseif (split(filepath,".")[end] == "resultmatrix") | force_rm_format
        return ResultMatrix(
            read_resultmatrix_format(filepath),
            filepath, false
        );
    end
end

function Base.size(A::ResultMatrix)
    return size(A.data);
end

function Base.length(A::ResultMatrix)
    return length(A.data);
end

function Base.getindex(A::ResultMatrix, i::Int)
    return A.data[i];
end

function Base.firstindex(A::ResultMatrix)
    return firstindex(A.data);
end

function Base.lastindex(A::ResultMatrix)
    return lastindex(A.data);
end

function Base.getindex(A::ResultMatrix, i::Vararg)
    return A.data[i...];
end

function Base.setindex!(A::ResultMatrix, v, i::Int)
    A.data[i] = v;
    save(A, i, forced=false);
end

function Base.setindex!(A::ResultMatrix, v, i::Vararg)
    A.data[i...] = v;
    save(A, i..., forced=false);
end

function Base.display(A::ResultMatrix)
    println("ResultMatrix ",size(A))
    display(A.data)
end

function save(A::ResultMatrix, i::Vararg; forced=true)
    if A.save_every | forced
        if split(A.filepath,".")[end] == "csv"
            CSV.write(A.filepath, Tables.table(A.data), writeheader=false);
        elseif split(A.filepath,".")[end] == "resultmatrix"
            save_resultmatrix_format(A, i...);
        end
    end
end

function save_resultmatrix_format(A::ResultMatrix)
    Base.open(A.filepath, read=true, write=true, create=true) do file
        save_resultmatrix_format(A, file)
    end
end
function save_resultmatrix_format(A::ResultMatrix, f)
    write_resultmatrix_header(f, A);
    save_resultmatrix_format_inner(f, A);
end
function save_resultmatrix_format(A::Matrix{Float64}, f)
    result_matrix = ResultMatrix("", Float64, 
        size(A)..., save_every=false)
    result_matrix.data = A;
    write_resultmatrix_header(f, result_matrix);
    save_resultmatrix_format_inner(f, result_matrix);
end

function write_resultmatrix_header(file, A::ResultMatrix)
    write_resultmatrix_header(file, A, repeat([0], length(size(A))));
end
function write_resultmatrix_header(file, A::ResultMatrix, lastindex::Vector{Int64})
    seek(file, 0);
    write(file, 1);
    ndims = length(size(A));

    seek(file, 1*8);
    write(file, ndims);

    for di = 1:ndims
        seek(file, (di+1)*8);
        write(file, size(A)[di]);
    end

    for di = 1:ndims
        seek(file, (di+ndims+1)*8);
        write(file, 0)
        # write(file, lastindex[di]);
    end
end

function save_resultmatrix_format(A::ResultMatrix, i::Vararg)
    Base.open(A.filepath, "r+") do file
        
        write_resultmatrix_header(file, A, [i...]);
        save_resultmatrix_format_inner(file, A, i...);
    end
end

function get_zero_index(dims, pos)
    multipliers = [prod([dims... 1][end-mi+1:end]) for mi in eachindex(dims)][end:-1:begin];
    matrixposition = 8*sum([multipliers[i] * (pos[i] .- 1) for i in eachindex(dims)]);

    # Header format
    #       ResultMatrix Version | N Dims | Dims...    | Last Written
    #        Int64                  Int64    N*Int64      N*Int64
    headerlength = 8 * (1 + 1 + 2length(dims));

    return headerlength + matrixposition;
end

function save_resultmatrix_format_inner(file, A::ResultMatrix, i::Vararg)
    dims = size(A);
    if length(i) == length(dims)
        seek(file, get_zero_index(dims, [i...]));
        write(file, A.data[i...]);
    else
        j_up_to = dims[length(i)+1];
        for j in 1:j_up_to
            save_resultmatrix_format_inner(file, A, i..., j);
        end
    end
end

function read_resultmatrix_format(filepath::String)
    data = Base.open(filepath, "r") do file
        return read_resultmatrix_format(file)
    end
    return data
end
function read_resultmatrix_format(file)
    seek(file, 0);
    resultmatrixversion = read(file, Int64);

    if resultmatrixversion == 1
        seek(file, 1*8);
        ndims = read(file, Int64);
        dims = Matrix{Int64}(zeros(ndims, 1));
        for di = 1:ndims
            seek(file, (di+1)*8);
            dims[di] = read(file, Int64);
        end
        data = zeros(dims...);

        read_resultmatrix_format_inner(file, data);
        return data
    else
        println("ERROR - COULD NOT PROCESS RESULTMATRIX VERSION ",resultmatrixversion);
    end
end

function get_last_written(A::ResultMatrix)
    lastindexread = nothing
    Base.open(A.filepath, "r") do file

        seek(file, 0);
        resultmatrixversion = read(file, Int64);

        if resultmatrixversion == 1

            seek(file, 1*8);
            ndims = read(file, Int64);

            dims = repeat([0], ndims);
            for di = 1:ndims
                seek(file, (di+1)*8);
                dims[di] = read(file, Int64);
            end

            lastindexread = repeat([0], ndims);
            for di = 1:ndims
                seek(file, (di+ndims+1)*8);
                lastindexread[di] = read(file, Int64);
            end
        else
            println("ERROR - COULD NOT PROCESS RESULTMATRIX VERSION ",resultmatrixversion);
        end
    end
    return lastindexread
end

function read_resultmatrix_format_inner(file, data::Array, i::Vararg)
    dims = size(data);
    if length(i) == length(dims)
        seek(file, get_zero_index(dims, [i...]));
        data[i...] = read(file, Float64);
    else
        j_up_to = dims[length(i)+1];
        for j in 1:j_up_to
            read_resultmatrix_format_inner(file, data, i..., j);
        end
    end
end
