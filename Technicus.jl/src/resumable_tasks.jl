
abstract type ResumableTask end

abstract type IteratedResumableTask <: ResumableTask end

struct CallbackImplementedResumableTask <: ResumableTask
    task_setup::Function

    checkpoint_condition::Function
    checkpoint_write::Function
    checkpoint_read::Function
    checkpoint_folder::String
    checkpoint_file::String
    progress_datatype::DataType

    go_function::Function

end

struct ForLoopResumableTask <: IteratedResumableTask
    task_setup::Function

    checkpoint_condition::Function
    checkpoint_write::Function
    checkpoint_read::Function
    checkpoint_folder::String
    checkpoint_file::String

    iteration::Function

    iterator
end

struct WhileLoopResumableTask <: IteratedResumableTask
    task_setup::Function

    checkpoint_condition::Function
    checkpoint_write::Function
    checkpoint_read::Function
    checkpoint_folder::String
    checkpoint_file::String

    iteration::Function

    repeat_condition::Function
end

function SequenceResumableTask(
        checkpoint_write::Vector,
        checkpoint_read::Vector,
        checkpoint_folder::String,
        checkpoint_file::String,
        iterations::Vector    )

    function sequence_iteration(state, progress)
        if progress == 1
            return iterations[progress]();
        end
        return iterations[progress](state);
    end

    function select_of_checkpoint_read(progress_made, file)
        return checkpoint_read[progress_made](file);
    end
    function select_of_checkpoint_write(progress_made, chkpnt, state, file)
        return checkpoint_write[progress_made](state, file);
    end

    return ForLoopResumableTask(
        () -> nothing,
        (state, progress) -> true,
        select_of_checkpoint_write,
        select_of_checkpoint_read,
        checkpoint_folder,
        checkpoint_file,
        sequence_iteration,
        1:length(iterations)
    )
end



#############################################################################################################################################################################################
#############################################################################################################################################################################################


function prepare_to_start_task(task::ResumableTask)
    return task, 0, 0, task.task_setup();
end
function start_task(task::ResumableTask)
    return do_task(prepare_to_start_task(task)...)
end

function prepare_to_resume_task(task::ResumableTask)
    checkpoints = filter(contains(r".*chkpoint"), readdir(task.checkpoint_folder));
    if length(checkpoints) == 0
        throw(ArgumentError(@sprintf("No checkpoints found for resuming this task, in folder %s",task.checkpoint_folder)))
    end

    last_checkpoint_file = checkpoints[end];
    last_checkpoint = parse(Int64, split(last_checkpoint_file, ".")[end-1]);

    progress_made = read_checkpoint_progress(task, last_checkpoint);

    state = nothing;
    Base.open(joinpath(task.checkpoint_folder, last_checkpoint_file),"r") do file
        state = task.checkpoint_read(progress_made, file);
    end

    return task, last_checkpoint, progress_made, state;
end
function resume_task(task::ResumableTask)
    return do_task(prepare_to_resume_task(task)...)
end

function read_checkpoint_progress(task::IteratedResumableTask, last_checkpoint)
    progress_made = nothing;
    Base.open(joinpath(task.checkpoint_folder, @sprintf("%s.%05d.progress", task.checkpoint_file, last_checkpoint)),"r") do file
        progress_made = parse(Int64, readlines(file)[1]);
    end
    return progress_made;
end

function read_checkpoint_progress(task::CallbackImplementedResumableTask, last_checkpoint)
    progress_made = nothing;
    Base.open(joinpath(task.checkpoint_folder, @sprintf("%s.%05d.progress", task.checkpoint_file, last_checkpoint)),"r") do file
        progress_made = parse(task.progress_datatype, readlines(file)[1]);
    end
    return progress_made;
end


function handle_checkpoint(task::ResumableTask, state, progress, checkpoint_num)
    if task.checkpoint_condition(state, progress)
        checkpoint_num = checkpoint_num + 1;
        try

            filename = joinpath(task.checkpoint_folder, @sprintf("%s.%05d.chkpoint",task.checkpoint_file,checkpoint_num))
            Base.open(filename,"w") do file
                task.checkpoint_write(progress, checkpoint_num, state, file)
            end
            
            filename = joinpath(task.checkpoint_folder, @sprintf("%s.%05d.progress",task.checkpoint_file,checkpoint_num))
            Base.open(filename,"w") do file
                write(file, string(progress));
            end

        catch e1
            # rm(filename)
            rethrow(e1);
        end
    end
    return checkpoint_num
end


#############################################################################################################################################################################################
#############################################################################################################################################################################################


function iterate_task(task::IteratedResumableTask, state, progress, last_checkpoint)
    state = task.iteration(state, progress);
    last_checkpoint = handle_checkpoint(task, state, progress, last_checkpoint);
    return state, last_checkpoint;
end

function do_task(task::ForLoopResumableTask, last_checkpoint::Int64, progress_made::Int64, state)
    
    for progress in eachindex(task.iterator)
        if progress <= progress_made
            continue
        end

        state, last_checkpoint = iterate_task(task, state, progress, last_checkpoint)
    end

    return state;
end


function do_task(task::WhileLoopResumableTask, last_checkpoint::Int64, progress_made::Int64, state)
    
    while task.repeat_condition(progress_made, state)
        progress_made = progress_made + 1;

        state, last_checkpoint = iterate_task(task, state, progress_made, last_checkpoint)
    end

    return state;
end


function do_task(task::CallbackImplementedResumableTask, last_checkpoint::Int64, progress_made, state)
    
    last_checkpoint_store = [last_checkpoint];

    function callback(progress_at_callback, state_at_callback)
        last_checkpoint_store[1] = handle_checkpoint(task, state_at_callback, progress_at_callback, last_checkpoint_store[1])
    end

    state = task.go_function(state, progress_made, callback);

    return state;
end



#############################################################################################################################################################################################
#############################################################################################################################################################################################



function test_callback_task(;resume=false)

    summation_terms = 1:100000000;

    function go_func(state, progressmade, callback)
    
        summation = state;
        if summation == nothing
            summation = 0;
        end
        iters = max(1,progressmade):length(summation_terms);

        for i in iters
            callback(i, summation);
            summation += summation_terms[i];
        end

        return summation
    end


    function save_function(i, chkpnt, sum_state, file)
        write(file, string(sum_state));
    end

    function read_function(i, file)
        return parse(Int64, readlines(file)[1]);
    end

    sum_sequence = CallbackImplementedResumableTask(
        () -> nothing,

        (sum_state, i) -> mod(i,10000000)==0,
        save_function,
        read_function,
        ".",
        "summation_callbacktask",

        Int64,

        go_func
    );

    if resume
        resume_task( sum_sequence );
    else
        start_task( sum_sequence );
    end
end


function test_forloop_task(;resume=false)

    summation = 1:100000000;


    function save_function(i, chkpnt, sum_state, file)
        write(file, string(sum_state));
    end

    function read_function(i, file)
        return parse(Int64, readlines(file)[1]);
    end

    sum_sequence = ForLoopResumableTask(
        () -> 0,

        (sum_state, i) -> mod(i,10000000)==0,
        save_function,
        read_function,
        ".",
        "summation_fortask",

        (sum_state, i) -> sum_state + summation[i],

        summation
    );

    if resume
        resume_task( sum_sequence );
    else
        start_task( sum_sequence );
    end

end


function test_whileloop_task(;resume=false)

    summation = 1:100000000;


    function save_function(i, chkpnt, sum_state, file)
        write(file, string(sum_state));
    end

    function read_function(i, file)
        return parse(Int64, readlines(file)[1]);
    end

    sum_sequence = WhileLoopResumableTask(
        () -> 0,

        (sum_state, i) -> mod(i,100000)==0,
        save_function,
        read_function,
        ".",
        "summation_whiletask",

        (sum_state, i) -> sum_state + i,

        (i, sum_state) -> sum_state < 100000000000
    );

    if resume
        resume_task( sum_sequence );
    else
        start_task( sum_sequence );
    end

end






function test_sequential_task(;resume=false)

    function step1()
        sleep(5)
        return 10;
    end
    function step2(n)
        sleep(5)
        return n+5;
    end
    function step3(n)
        sleep(5)
        return n+2;
    end
    
    function write_function(value, file)
        write(file, string(value));
    end

    function read_function(file)
        return parse(Float64, readlines(file)[1]);
    end

    task = SequenceResumableTask(
        [write_function, write_function, write_function],
        [read_function, read_function, read_function],
        ".",
        "math_sequencetask",
        [step1, step2, step3]
    );
    
    if resume
        resume_task( task );
    else
        start_task( task );
    end

end














