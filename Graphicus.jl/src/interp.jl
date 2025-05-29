

abstract type Dataspace end;
# abstract function (space::Dataspace)(coord::Number) end

struct InverseDistanceWeightedSpaceSmoothed <: Dataspace
    coords::Matrix{Float64}
    values::Vector{Float64}
    smoothing::Number
    distfunc::Function
end
function InverseDistanceWeightedSpaceSmoothed(x::Vector{<:Real}, y::Vector{<:Real}, vals::Matrix{<:Real}, args...)
    @assert size(vals) == (length(x), length(y)) "vals must be of size (length(x), length(y))"
    coords = hcat([Float64[xi, yi] for xi in x, yi in y]...)'  # each row is a coordinate pair
    return InverseDistanceWeightedSpaceSmoothed(coords, vec(vals), args...)
end
function (space::InverseDistanceWeightedSpaceSmoothed)(coord::Tuple{Number,Number})
    return space([coord[1],coord[2]])
end
function (space::InverseDistanceWeightedSpaceSmoothed)(coord::AbstractArray{N}) where N <: Number
    # weights = 1 ./ sqrt.(sum(abs2, space.coords .- coord',dims=2))
    # return sum(weights .* space.values) ./ sum(weights)

    diffs = space.distfunc(space.coords, coord');
    dists2 = sum(abs2, diffs, dims=2)

    weights = exp.(-dists2 ./ (2 * space.smoothing))
    return sum(weights .* space.values) / sum(weights)
end










function lerp_2d(xs,ys,cs; count=1)
    xs_1 = zeros(length(xs) + (count * (length(xs)-1)))
    ys_1 = zeros(length(ys) + (count * (length(ys)-1)))
    cs_1 = zeros(length(xs_1), length(ys_1))
    for xi in eachindex(xs)
        for yi in eachindex(ys)

            xi_1 = ((xi-1)*(count+1))+1
            yi_1 = ((yi-1)*(count+1))+1
            
            xs_1[xi_1] = xs[xi]
            ys_1[yi_1] = ys[yi]

            if xi == length(xs)
                continue
            end
            if yi == length(ys)
                continue
            end

            for xi_c = 1:count
                xs_1[xi_1 + xi_c] = lerp_1d(xs[xi], xs[xi+1], xi_c/(count+1))
            end            
            for yi_c = 1:count
                ys_1[yi_1 + yi_c] = lerp_1d(ys[yi], ys[yi+1], yi_c/(count+1))
            end

            
            for xi_c = 0:(count+1)
                for yi_c = 0:(count+1)
                    cs_1[xi_1+xi_c,yi_1+yi_c] = lerp_1d(
                        lerp_1d(cs[xi,yi], cs[xi,yi+1], yi_c/(count+1)),
                        lerp_1d(cs[xi+1,yi], cs[xi+1,yi+1], yi_c/(count+1)),
                        xi_c/(count+1))
                end
            end

        end
    end

    return xs_1, ys_1, cs_1
end

function lerp_1d(a,b,x)
    return a + (b-a)*x
end