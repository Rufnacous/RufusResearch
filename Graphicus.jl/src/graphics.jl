mutable struct Text <: GraphicPart
    x::Number
    y::Number
    s::String
    fontsize::Number
    align::Symbol
    xoffset::Number
    yoffset::Number
    rot::Number #radians
end
Text(x,y,s,fs,a) = Text(x,y,s,fs,a,0,0,0);
function draw_graphic(file::GraphicsOutput, txt::Text, t::Transform)
    draw_text(file, t(txt.x, txt.y) .- (txt.xoffset, txt.yoffset), txt.s, txt.fontsize, txt.align, txt.rot*180/pi);
end
function vertical_align!(t::Text)
    t.yoffset += t.fontsize/2;
end


function add_labels(g::GraphicPart, xlabel::String, ylabel::String)
    return (g(Text(0.5, 0, xlabel, 30, :center,0,60,0)), g(Text(0, 0.5, ylabel, 30, :center, 60, 0, pi/2)))
end

mutable struct Multiline <: GraphicPart
    xs::Array{Number}
    ys::Array{Number}
    linewidth::Number
    color::Tuple{Number, Number, Number}
    linestyle::Symbol
end
Multiline(xs,ys,lw) = Multiline(xs,ys,lw, (0,0,0),:solid);
function draw_graphic(file::GraphicsOutput, line::Multiline, t::Transform)
    
    points = [t(line.xs[i], line.ys[i]) for i in eachindex(line.xs)]
    sdfs = [t[points[i]...] for i in eachindex(points)]

    lastpoint = nothing
    currentpoints = points[1:0]
    for i in eachindex(points)
        if sdfs[i] > 0
            if length(currentpoints) > 0

                step = points[i] .- currentpoints[end];
                s = 0;
                bestyet = 1;
                for sg in LinRange(0,1, 100)
                    thisyet = abs(t[(currentpoints[end] .+ (sg .* step))...]);
                    if thisyet < bestyet
                        s = sg;
                        bestyet = thisyet
                    end
                end
                push!(currentpoints, currentpoints[end] .+ (s .* step))

                draw_multiline(file, currentpoints, line.linewidth, line.color, linestyle=line.linestyle)
            end

            
            currentpoints = points[1:0]
            lastpoint = points[i]
            continue
        elseif i > 1
            if sdfs[i-1] > 0

                step = points[i] .- lastpoint;
                s = 0;
                bestyet = 1;
                for sg in LinRange(0,1, 100)
                    thisyet = abs(t[(lastpoint .+ (sg .* step))...]);
                    if thisyet < bestyet
                        s = sg;
                        bestyet = thisyet
                    end
                end
                pushfirst!(currentpoints, lastpoint .+ (s .* step))

            end
        end
        lastpoint = points[i]
        push!(currentpoints, lastpoint)
    end
    if length(currentpoints) > 0
        draw_multiline(file, currentpoints, line.linewidth, line.color, linestyle=line.linestyle)
    end
end
LineGraph(args...; kwargs...) = Multiline(args...; kwargs...);

mutable struct Box <: GraphicPart
    x::Number
    y::Number
    width::Number
    height::Number
    parts::Array{GraphicPart}
    linewidth::Number
    filled::Bool
    interpolated::Integer
end
Box(x,y,w,h) = Box(x,y,w,h,[], 1.0, false, 0)
function draw_graphic(file::GraphicsOutput, box::Box, t::Transform)
    xys = [
        (box.x, box.y),
        (box.x, box.y+box.height),
        (box.x+box.width, box.y+box.height),
        (box.x+box.width, box.y),
        (box.x, box.y)
    ];
    if box.interpolated == 0
        draw_multiline(file, transform_series(t, xys), box.linewidth, (0,0,0), filled=box.filled);
    else
        draw_multiline(file, interpolate_and_transform_series(t, xys, density=box.interpolated), box.linewidth, (0,0,0), filled=box.filled);
    end
end

mutable struct Circle <: GraphicPart
    x::Number
    y::Number
    width::Number
    height::Number
    parts::Array{GraphicPart}
    linewidth::Number
    filled::Bool
end
Circle(x,y,r) = Circle(x,y,r,r,[],1.0,false);
function draw_graphic(file::GraphicsOutput, circle::Circle, t::Transform)
    scaled_radius = t(circle.width,0)[1] - t(0,0)[1];
    draw_point(file, t(circle.x, circle.y), scaled_radius, filled=circle.filled);
end

mutable struct BorderlessBox <: GraphicPart
    x::Number
    y::Number
    width::Number
    height::Number
    parts::Array{GraphicPart}
end
BorderlessBox(x,y,w,h) = BorderlessBox(x,y,w,h,[])
function draw_graphic(file::GraphicsOutput, box::BorderlessBox, t::Transform)
    return
end

mutable struct Point <: GraphicPart
    x::Number
    y::Number
    pointsize::Number
    filled::Bool
end
function draw_graphic(file::GraphicsOutput, p::Point, t::Transform)
    xy = t(p.x, p.y);
    if t[xy...] > 0
        return
    end
    draw_point(file, xy, p.pointsize, filled=p.filled)
end

mutable struct TrianglePoint <: GraphicPart
    size::Number
    filled::Bool
end
function draw_graphic(file::GraphicsOutput, p::TrianglePoint, t::Transform)
    draw_multiline(file, [t(0,0) .+ (xy[1],xy[2]) for xy in [
        (0, 1.5p.size/sqrt(3)),
        (-1.5p.size/2, -1.5p.size/2sqrt(3)),
        (1.5p.size/2, -1.5p.size/2sqrt(3)),
        (0, 1.5p.size/sqrt(3))
    ]], 1, (0,0,0), filled=p.filled);
end
mutable struct SquarePoint <: GraphicPart
    size::Number
    filled::Bool
end
function draw_graphic(file::GraphicsOutput, p::SquarePoint, t::Transform)
    draw_multiline(file, [t(0,0) .+ (xy[1],xy[2]) for xy in [
        (-p.size/2, p.size/2),
        (p.size/2, p.size/2),
        (p.size/2, -p.size/2),
        (-p.size/2, -p.size/2),
        (-p.size/2, p.size/2)
    ]], 1, (0,0,0), filled=p.filled);
end


mutable struct PointScatter <: GraphicPart
    xs::Array{Number}
    ys::Array{Number}
    pointsize::Number
    filled::Bool
end
function draw_graphic(file::GraphicsOutput, scatter::PointScatter, t::Transform)
    for p_i in 1:length(scatter.xs)
        
        xy = t(scatter.xs[p_i], scatter.ys[p_i]);
        if t[xy...] > 0
            continue
        end
        draw_point(file, xy, scatter.pointsize, filled=scatter.filled)
    end
end


mutable struct SuperScatter <: GraphicPart
    xs::Array{Number}
    ys::Array{Number}

    parts::Array{GraphicPart}
end
SuperScatter(xs::Array{Number}, ys::Array{Number}) = SuperScatter(xs,ys,[]);
function draw_graphic_traverse(o::GraphicsOutput, ssc::SuperScatter, t::Transform)
    for p_i in 1:length(ssc.xs)
        try
            ssc.parts
        catch
            return
        end

        if length(ssc.parts) > 1
            draw_graphic_traverse(o, ssc.parts[p_i], t( Translate(ssc.xs[p_i],ssc.ys[p_i]) )  )
        else
            draw_graphic_traverse(o, ssc.parts[1], t( Translate(ssc.xs[p_i],ssc.ys[p_i]) )  )
        end
    end
end


Scatter(xs::Array{N}, ys::Array{N}, pointsize::Number;filled::Bool=true) where N <: Number = PointScatter(xs,ys, pointsize/2,filled);
Scatter(xs::Array{N}, ys::Array{N}, marker::GraphicPart) where N <: Number = SuperScatter(xs, ys, [marker]);
Scatter(xs::Array{N}, ys::Array{N}, markers::Array{GraphicPart}) where N <: Number = SuperScatter(xs, ys, markers);






mutable struct Scatter3D <: GraphicPart
    xs::Array{Number}
    ys::Array{Number}
    zs::Array{Number}
    pointsize::Number
end
function draw_graphic(file::GraphicsOutput, scatter::Scatter3D, t::Transform)
    
    for p_i in 1:length(scatter.xs)
        draw_point(file, t(scatter.xs[p_i], scatter.ys[p_i], scatter.zs[p_i]), scatter.pointsize)
    end
end

mutable struct Multiline3D <: GraphicPart
    xs::Array{Number}
    ys::Array{Number}
    zs::Array{Number}
    linewidth::Number
end
function draw_graphic(file::GraphicsOutput, line::Multiline3D, t::Transform)
    draw_multiline(file, [t(line.xs[i], line.ys[i], line.zs[i]) for i in eachindex(line.xs)], line.linewidth, (0,0,0))
end


