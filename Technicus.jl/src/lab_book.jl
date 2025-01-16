

struct LabBook
    name::String
    project
end
struct Project
    folderpath::String
    books::Dict{String, LabBook}
end
function Project(folderpath::String, books::Array{String})
    proj = Project(folderpath, Dict{String,LabBook}());
    for b in books
        proj.books[b] = LabBook(b, proj);
    end
    return proj;
end
function Base.getindex(proj::Project, lbname::String)
    return proj.books[lbname];
end


struct LabRun
    lab_book::LabBook
    book_io
    run_name::String
end

function Base.println(run::LabRun, args...; color="black")
    print(run, args..., color=color);
    println(run.book_io,"");
end
function Base.print(run::LabRun, args...; color="black")
    println("To book: ",args...);
    if color != "black"
        print(run.book_io,"<span style=\"color:",color,"\">")
    end
    print(run.book_io, args...);
    if color != "black"
        print(run.book_io,"</span>")
    end
    println(run.book_io,"");
end
function Base.readline(run::LabRun, prompt::String)
    print(prompt);
    println(run.book_io, " *User note: ",readline(),"*");
end
function Plots.savefig(run::LabRun, args...;embed=true)
    Plots.savefig(get_book_path(run, args...));
    if embed
        println(run.book_io,"![figure](",joinpath(run.run_name, args...),")")
    end
end

function new_run(book::LabBook)
    runnumber = 1;
    while ispath(get_book_path(book,@sprintf("run_%03d",runnumber)))
        runnumber += 1;
    end
    mkpath(get_book_path(book,@sprintf("run_%03d",runnumber)));
    return @sprintf("run_%03d",runnumber);
end

function get_book_path(book::LabBook, args...)
    return joinpath(book.project.folderpath, book.name, args...);
end
function get_book_path(run::LabRun, args...)
    return get_book_path(run.lab_book, run.run_name, args...);
end

function open_lab_book(f::Function, book::LabBook; catch_me=false)
    completelynew = !isfile(get_book_path(book, "lab_book.md"));
    book_io = open(get_book_path(book, "lab_book.md"),"a+");
    errored = false;
    try
        if completelynew
            println(book_io, "# ",book.name);
        end
        labrun = LabRun(
            book,
            book_io,
            new_run(book) );
        seekend(labrun.book_io);
        println(labrun, "\n## ", labrun.run_name, " ",now())
        f(labrun);
    catch e
        errored = true;
        if catch_me
            Base.printstyled("ERROR: "; color=:red, bold=true)
            Base.showerror(stdout, e)
            Base.show_backtrace(stdout, Base.catch_backtrace())
            println()
            # stktrc = stacktrace(catch_backtrace())
            # show_backtrace(stdout, stktrc); println()
            # [println(s) for s in stktrc]
        else
            rethrow(e)
        end
    finally
        if catch_me & errored
            print(book_io, "<span style=\"color:red\">Lab run crashed! Error notes: ")
            println("Provide user comments on error: ")
            notes = readline();
            println(book_io, notes,"</span>")
        end
        close(book_io);
    end
end
function open_lab_book(f::Function, book::LabBook, resumerun::String; catch_me=false)
    book_io = open(get_book_path(book, "lab_book.md"),"a+");
    
    appendafter = "";
    errored = false;
    try
        labrun = LabRun(
            book,
            book_io,
            resumerun );

        seek(labrun.book_io, 0);
        writtenline = readline(labrun.book_io);
        while !eof(labrun.book_io) & (writtenline != @sprintf("## %s",labrun.run_name))
            writtenline = readline(labrun.book_io);
        end
        up_to = position(labrun.book_io);
        writtenline = readline(labrun.book_io);
        while !eof(labrun.book_io) & (@sprintf("%s  ",writtenline)[1:3] != "## ")
            up_to = position(labrun.book_io);
            writtenline = readline(labrun.book_io);
        end
        seek(labrun.book_io, up_to);
        appendafter = read(labrun.book_io);
        seek(labrun.book_io, up_to);

        f(labrun);
    catch e
        errored = true;
        if catch_me
            showerror(stdout, e)
        else
            rethrow(e)
        end
    finally
        if catch_me & errored
            print(book_io, "Lab run crashed! Error notes: ")
            println("Provide user comments on error: ")
            notes = readline();
            println(book_io, notes)
        end
        println(book_io,"");
        write(book_io, appendafter);
        close(book_io);
    end
end




# test_project = Technicus.Project("./test_project", ["test_book"]);


# function start_test()
#     Technicus.open_lab_book(test_project["test_book"]) do lab_run
#         do_test(lab_run);
#     end
# end

# function resume_test()
#     Technicus.open_lab_book(test_project["test_book"], "run_004") do lab_run
#         do_test(lab_run);
#     end
# end

# function do_test(lab_run)
#     readline(lab_run, "For lab book: What has changed?")
#     println(lab_run, "Eigenfrequencies = 6.3, 7.4Hz"); #; style="bold"
#     # savefig(lab_run, "plot.png")
# end
