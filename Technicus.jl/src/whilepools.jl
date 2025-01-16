
# function open(f::Function, args...)
#     io = open(args...)
#     try
#         f(io)
#     finally
#         close(io)
#     end
# end

# open("outfile", "w") do io
#     write(io, data)
# end



# pool_params 
#  initial jobs
#  job respawner
#  job orderer
#  

# pool = Pool(pool_params)
# push!(pool.jobs, ...)
# pool(5) do jobspec
#   job = prepare(jobspec)
#   jobsspec.result = do(job)
# end


struct WhilePool
    jobs::Array{Tuple{Any, Number},1}
    poollk::ReentrantLock
    userlk::ReentrantLock
end
function WhilePool(jobs)
    return WhilePool(jobs, Threads.ReentrantLock(), Threads.ReentrantLock());
end
function (pool::WhilePool)(f::Function, nworkers::Int64)
    if nworkers == 1
        worker_thread(pool, f)
    else
        threads = [Threads.@spawn worker_thread(pool, f) for worker_i in 1:nworkers]
        fetch.(threads)
    end
end
function worker_thread(pool::WhilePool, f::Function)
    while true
        ## GET NEXT JOB, OR QUIT IF POOL IS EMPTY
        nextjob = nothing
        lock(pool.poollk)
        try
            nextjob = popfirst!(pool.jobs)
        catch
            unlock(pool.poollk)
            println("\n TECHNICUS : Thread quitting, empty pool.")
            break
        end
        unlock(pool.poollk)

        ## DO THE JOB
        newjob = nothing; priority = 0;
        try
            newjob, priority = f(pool.userlk, nextjob[1]...)
        catch e
            Base.printstyled("ERROR: "; color=:red, bold=true)
            Base.showerror(stdout, e)
            Base.show_backtrace(stdout, Base.catch_backtrace())

            println("\n TECHNICUS : Thread quitting.")
            break
        end
        ## RESPAWN NEXT JOB
        if newjob != nothing
            lock(pool.poollk)
            try
                insertloc = 0
                while insertloc < length(pool.jobs)
                    if priority > pool.jobs[insertloc+1][2]
                        break
                    end
                    insertloc += 1
                end
                insert!(pool.jobs, insertloc+1, (newjob, priority));
            finally
                unlock(pool.poollk)
            end
        end
    end
end

# function killthreads(pool::WhilePool)
#     lock(pool.poollk)
#     try
#         empty!(pool.jobs)
#     finally
#         unlock(pool.poollk)
#     end
# end