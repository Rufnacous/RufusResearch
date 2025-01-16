abstract type ParameterSet end

function Base.open(params_type::DataType, filename::String)
    params_dict = JSON.parsefile(filename; use_mmap=false);
    params_fieldnames = fieldnames(params_type);
    return params_type([params_dict[String(f)] for f in params_fieldnames]...);
end
function Base.open(params_type::DataType, filename::String, run::LabRun)
    return open(params_type, get_book_path(run, filename));
end
function Base.open(params_type::DataType, filename::String, book::LabBook)
    return open(params_type, get_book_path(book, filename));
end

function json(params::ParameterSet)
    params_type = typeof(params);
    params_fieldnames = fieldnames(params_type);
    return JSON.json(Dict([(String(f),getfield(params, f)) for f in params_fieldnames]),4);
end

function save(run::LabRun, params::ParameterSet, title::String;log::Bool=true)
    if log
        println(run, " Using parameter file: **",title,".json**")
    end
    save(get_book_path(run, @sprintf("%s.json",title)), params);
end
function save(book::LabBook, params::ParameterSet, title::String)
    save(get_book_path(book, @sprintf("%s.json",title)), params);
end
function save(path::String, params::ParameterSet)
    parameter_json = json(params);
    Base.open(path, "w") do file
        write(file, parameter_json)
    end
end
