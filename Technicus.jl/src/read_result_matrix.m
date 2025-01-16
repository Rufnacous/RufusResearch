function A = read_result_matrix(filename)
    fid = fopen(filename,"r");
    version = fread(fid, 1, "uint64");
    ndims = fread(fid, 1, "uint64");
    dims = fread(fid, [1,ndims], "uint64");

    
    // if dimfix
    //     fread(fid, 3, "uint64");
    // end


    A = zeros(dims(end:-1:1));
    A = read_result_matrix_inner(fid, A, [], dims(end:-1:1));
    %A = fread(fid, dims(end:-1:1), "float64");
    fclose(fid);
end

function A = read_result_matrix_inner(fid, A, ijk, dims)
    if isempty(dims)
        A(ijk) = fread(fid,1,"float64");
        return
    end
    for l = 1:dims(1)
        A = read_result_matrix_inner(fid, A, [ijk l], dims(2:end));
    end
end

