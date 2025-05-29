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
    
    draw_text(file, t(txt.x, txt.y) .- rotate(t, (txt.x, txt.y), (txt.xoffset, txt.yoffset)), txt.s, txt.fontsize, txt.align, txt.rot*180/pi);
end
function vertical_align!(t::Text)
    t.yoffset += t.fontsize/2;
end

function add_title(g::GraphicPart, t::String; fontsize::Number=30, offset::Number=-60)
    return g(Text(0.5, 1, t, fontsize, :center,0,offset,0))
end

function add_labels(g::GraphicPart, xlabel::String, ylabel::String; fontsize::Number=30, x_pos::Tuple=(0.5,0), y_pos::Tuple=(0,0.5), x_offset::Tuple=(0,0), y_offset::Tuple=(0,0))
    return (g(Text(x_pos..., xlabel, fontsize, :center,x_offset...,0)), g(Text(y_pos..., ylabel, fontsize, :center, y_offset..., pi/2)))
end

mutable struct Multiline <: GraphicPart
    xs::Array{Number}
    ys::Array{Number}
    linewidth::Number
    color#::Union{Tuple{Number, Number, Number}, Vector{Tuple{Number, Number, Number}}}
    linestyle::Symbol
end
Multiline(xs,ys,lw) = Multiline(xs,ys,lw, (0,0,0),:solid);
function draw_graphic(file::GraphicsOutput, line::Multiline, t::Transform)
    
    draw_group_start(file);

    points = [t(line.xs[i], line.ys[i]) for i in eachindex(line.xs)]
    sdfs = [t[points[i]...] for i in eachindex(points)]
    if typeof(line.color) <: Tuple
        colors = [line.color for i in eachindex(line.xs)]
    else
        colors = line.color[:]
    end

    lastpoint = nothing; lastcolor = nothing
    currentpoints = points[1:0]
    colorpoints = colors[1:0];
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
                colorstep = colors[i] .- colorpoints[end];
                push!(colorpoints, colorpoints[end] .+ (s .* colorstep))

                draw_multiline(file, currentpoints, line.linewidth, colorpoints, linestyle=line.linestyle)
            end

            
            currentpoints = points[1:0]
            colorpoints = colors[1:0]
            lastpoint = points[i]; lastcolor = colors[i];
            continue
        elseif i > 1
            if sdfs[i-1] > 0

                step = points[i] .- lastpoint;
                colorstep = colors[i] .- lastcolor;
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
                pushfirst!(colorpoints, lastcolor .+ (s .* colorstep))

            end
        end
        lastpoint = points[i]
        push!(currentpoints, lastpoint)
        lastcolor = colors[i]
        push!(colorpoints, lastcolor)
    end
    if length(currentpoints) > 0
        draw_multiline(file, currentpoints, line.linewidth, ifelse(typeof(line.color) <: Tuple,line.color,colorpoints), linestyle=line.linestyle)
    end
    
    draw_group_end(file);
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
function Boxes(x,y,w,h, nw::Integer, nh::Integer; wspacing=0, hspacing=0,borderless=false)

    wspacing_ = ifelse(nw>1,wspacing / (nw-1),0)
    hspacing_ = ifelse(nh>1,hspacing / (nh-1),0)

    ws = [((1 - (wspacing_*(nw-1))) / nw) for i = 1:nw]
    hs = [((1 - (hspacing_*(nh-1))) / nh) for i = 1:nh]
    return Boxes(x,y,w,h, ws, hs, wspacing=wspacing, hspacing=hspacing, borderless=borderless)

end
function Boxes(x,y,w,h, widths::AbstractArray{<:Number}, heights::AbstractArray{<:Number}; wspacing=0, hspacing=0, borderless=false)
    nw = length(widths); nh = length(heights)

    boxes = GraphicSum([]);

    wspacing = ifelse(nw>1,wspacing / (nw-1),0)
    hspacing = ifelse(nh>1,hspacing / (nh-1),0)

    btype = ifelse(borderless, BorderlessBox, Box);

    for coli = 1:nw, rowi = nh:-1:1
        boxes += btype(
            x + sum(w .* widths[1:(coli-1)]) + (coli-1)*wspacing,
            y + sum(h .* heights[1:(rowi-1)]) + (rowi-1)*hspacing,
            w*widths[coli],h*heights[rowi]
        )
    end
    return boxes

end
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
    # if t[xy...] > 0
    #     return
    # end
    draw_point(file, xy, p.pointsize, filled=p.filled)
end

mutable struct TrianglePoint <: GraphicPart
    size::Number
    filled::Bool
end
function draw_graphic(file::GraphicsOutput, p::TrianglePoint, t::Transform)
    println("  ",t(0,0))
    draw_multiline(file, [t(0,0) .+ (xy[1],xy[2]) for xy in [
        (0, -1.5p.size/sqrt(3)),
        (-1.5p.size/2, 1.5p.size/2sqrt(3)),
        (1.5p.size/2, 1.5p.size/2sqrt(3)),
        (0, -1.5p.size/sqrt(3))
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
    draw_group_start(o);
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
    draw_group_end(o);
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
    
    draw_group_start(file);
    for p_i in 1:length(scatter.xs)
        draw_point(file, t(scatter.xs[p_i], scatter.ys[p_i], scatter.zs[p_i]), scatter.pointsize)
    end
    
    draw_group_end(file);
end

mutable struct Multiline3D <: GraphicPart
    xs::Array{Number}
    ys::Array{Number}
    zs::Array{Number}
    linewidth::Number
    color::Tuple{Number, Number, Number}
    linestyle::Symbol
    filled::Bool
end
Multiline3D(xs,ys,zs,lw) = Multiline3D(xs,ys,zs,lw, (0,0,0),:solid,false);

function draw_graphic(file::GraphicsOutput, line::Multiline3D, t::Transform)
    draw_multiline(file, [t(line.xs[i], line.ys[i], line.zs[i]) for i in eachindex(line.xs)], line.linewidth, line.color, linestyle=line.linestyle,filled=line.filled)
end






mutable struct Heatmap <: GraphicPart
    xs::Array{Number}
    ys::Array{Number}
    cs::Matrix{Number}
    colormap::Function
    clims::Tuple{Number,Number}
end
Heatmap(cs) = Heatmap(LinRange(0,1,size(cs,1)), LinRange(0,1,size(cs,2)), cs, (c)->(c,c,c),(minimum(cs),maximum(cs)))
Heatmap(xs,ys,cs) = Heatmap(xs,ys,cs,(c) -> (c,c,c),(minimum(cs),maximum(cs)))
function draw_graphic(file::GraphicsOutput, hm::Heatmap, t::Transform)
    draw_group_start(file);
    xborders = (hm.xs[2:end] + hm.xs[1:end-1]) ./ 2
    x0 = hm.xs[1]-(xborders[1]-hm.xs[1]);
    xend = hm.xs[end]+(hm.xs[end]-xborders[end]);
    xborders = [x0, xborders..., xend];
    
    yborders = (hm.ys[2:end] + hm.ys[1:end-1]) ./ 2
    y0 = hm.ys[1]-(yborders[1]-hm.ys[1]);
    yend = hm.ys[end]+(hm.ys[end]-yborders[end]);
    yborders = [y0, yborders..., yend];

    for xi in eachindex(hm.xs), yi in eachindex(hm.ys)
        xl = xborders[xi]; xr = xborders[xi+1];
        yb = yborders[yi]; yt = yborders[yi+1];
        if xi < length(hm.xs)
            xr = (xborders[xi+1] + xborders[xi+2])/2;
        end
        if yi < length(hm.ys)
            yt = (yborders[yi+1] + yborders[yi+2])/2;
        end
        boxcolor = hm.colormap((hm.cs[xi,yi]-hm.clims[1]) ./ (hm.clims[2]-hm.clims[1]))
        boxcorners = [t(x,y) for (x,y) in [
            (xl,yb),
            (xr,yb),
            (xr,yt),
            (xl,yt)
        ]]
        draw_multiline(file, boxcorners, 0, boxcolor, filled=true)
    end
    draw_group_end(file);

end

mutable struct Colorbar <: GraphicPart
    colormap
    clims
end

function Colorbar(h::Heatmap)
    return Colorbar(h.colormap, h.clims)
end

function draw_graphic(file::GraphicsOutput, cb::Colorbar, t::Transform)
    # rungs = LinRange(0,1, 100)
    # boxes = [
    #     [ t(x,y) for (x,y) in [(0,bottom), (0,top), (1,top), (1,bottom), (0,bottom)] ]
    #     for (bottom,top) in
    #     [ (rungs[i-1],rungs[i]) for i in 2:length(rungs)]
    # ]
    
    xys = [t(xy...) for xy in zip(LinRange(0.499,0.5,100),LinRange(cb.clims[2],cb.clims[1],100))];
    cs = [cb.colormap(c) for c in LinRange(1,0,length(xys))]
    draw_multiline( file, xys, t(1,0)[1] - t(0,0)[1], cs , gradient=:vertical)
    # for i in eachindex(boxes)
    #     box = boxes[i]
    #     draw_multiline(file, box, 0, (cb.colormap(cs[i]).r, cb.colormap(cs[i]).g, cb.colormap(cs[i]).b), filled=true)
    # end
end



# mutable struct ContourMarchingSquares <: GraphicPart
#     xs::Array{Number}
#     ys::Array{Number}
#     cs::Matrix{Number}
#     levels::Array{Number}
#     linewidth::Number
#     filled::Bool
#     colormap::Function
#     clims::Tuple{Number,Number}
# end

# function Colorbar(h::ContourMarchingSquares)
#     return Colorbar(h.colormap, h.clims)
# end
# # ContourMarchingSquares(cs) = ContourMarchingSquares(LinRange(0,1,size(cs,1)), LinRange(0,1,size(cs,2)), cs, (c)->(c,c,c),(minimum(cs),maximum(cs)))
# # ContourMarchingSquares(xs,ys,cs) = ContourMarchingSquares(xs,ys,cs,(c) -> (c,c,c),(minimum(cs),maximum(cs)))
# function draw_graphic(file::GraphicsOutput, contour::ContourMarchingSquares, t::Transform)
#     draw_group_start(file);

#     for li in 1:length(contour.levels)-1
#         l = contour.levels[li]
#         draw_group_start(file);
        
#         for xi in 1:(length(contour.xs)-1), yi in 1:(length(contour.ys)-1)
#             xl = contour.xs[xi]; xr = contour.xs[xi+1]; xm = (xl+xr)/2;
#             yb = contour.ys[yi]; yt = contour.ys[yi+1]; ym = (yb+yt)/2;

#             bl = contour.cs[xi,yi] > l
#             br = contour.cs[xi+1,yi] > l
#             tl = contour.cs[xi,yi+1] > l
#             tr = contour.cs[xi+1,yi+1] > l

#             caseN = sum([8,4,2,1] .* [bl,br,tl,tr])

            
#             if contour.filled
#                 # if caseN == 0
#                 # shape = []
#                 shape = [(0,0.0)]
#                 if caseN == 1
#                     shape = [(xr,ym),(xm,yt),(xr,yt)]
#                 elseif caseN == 2
#                     shape = [(xl,ym),(xm,yt),(xl,yt)]
#                 elseif caseN == 3
#                     shape = [(xl,ym),(xr,ym),(xr,yt),(xl,yt)]
#                 elseif caseN == 4
#                     shape = [(xm,yb), (xr,ym), (xr,yb)]
#                 elseif caseN == 5
#                     shape = [(xm,yb),(xm,yt),(xr,yt),(xr,yb)]
#                 elseif caseN == 6
#                     shape = [(xl,yt),(xm,yt),(xr,ym),(xr,yb),(xm,yb),(xl,ym)]
#                 elseif caseN == 7
#                     shape = [(xm,yb),(xl,ym),(xl,yt),(xr,yt),(xr,yb)]
#                 elseif caseN == 8
#                     shape = [(xl,ym), (xm,yb), (xl,yb)]
#                 elseif caseN == 9
#                     shape = [(xl,ym),(xl,yb),(xm,yb),(xr,ym),(xr,yt),(xm,yt)]
#                 elseif caseN == 10
#                     shape = [(xm,yb),(xm,yt),(xl,yt),(xl,yb)]
#                 elseif caseN == 11
#                     shape = [(xr,ym),(xm,yb),(xl,yb),(xl,yt),(xr,yt)]
#                 elseif caseN == 12
#                     shape = [(xl,ym), (xr,ym), (xr,yb), (xl,yb)]
#                 elseif caseN == 13
#                     shape = [(xm,yt),(xl,ym),(xl,yb),(xr,yb),(xr,yt)]
#                 elseif caseN == 14
#                     shape = [(xm,yt), (xr,ym),(xr,yb),(xl,yb),(xl,yt)]
#                 elseif caseN == 15
#                     shape=  [(xl,yt),(xr,yt),(xr,yb),(xl,yb)]
                    
#                     bl = contour.cs[xi,yi] > contour.levels[li+1]
#                     br = contour.cs[xi+1,yi] > contour.levels[li+1]
#                     tl = contour.cs[xi,yi+1] > contour.levels[li+1]
#                     tr = contour.cs[xi+1,yi+1] > contour.levels[li+1]

#                     if bl & br & tl & tr
#                         shape = []
#                     end
#                 end
#                 if length(shape) > 2
#                     show_l = contour.levels[li+1]
#                     boxcolor = contour.colormap((show_l-contour.clims[1]) ./ (contour.clims[2]-contour.clims[1]))
#                     draw_multiline(file, [t(p...) for p in shape], 0.8, boxcolor,filled=true)
#                 end

#             end


#             # if caseN == 0
#             lines = [[(0.0,0.0)]][2:end]
#             if caseN == 4
#                 lines = [[(xm,yb), (xr,ym)]]
#             elseif caseN == 8
#                 lines = [[(xl,ym), (xm,yb)]]
#             elseif caseN == 12
#                 lines = [[(xl,ym), (xr,ym)]]
#             elseif caseN == 2
#                 lines = [[(xl,ym),(xm,yt)]]
#             elseif caseN == 6
#                 lines = [[(xl,ym),(xm,yt)],[(xm,yb),(xr,ym)]]
#             elseif caseN == 10
#                 lines = [[(xm,yb),(xm,yt)]]
#             elseif caseN == 14
#                 lines = [[(xm,yt), (xr,ym)]]
#             elseif caseN == 1
#                 lines = [[(xr,ym),(xm,yt)]]
#             elseif caseN == 5
#                 lines = [[(xm,yb),(xm,yt)]]
#             elseif caseN == 9
#                 lines = [[(xl,ym),(xm,yb)],[(xm,yt),(xr,ym)]]
#             elseif caseN == 13
#                 lines = [[(xm,yt),(xl,ym)]]
#             elseif caseN == 3
#                 lines = [[(xl,ym),(xr,ym)]]
#             elseif caseN == 7
#                 lines = [[(xm,yb),(xl,ym)]]
#             elseif caseN == 11
#                 lines = [[(xr,ym),(xm,yb)]]
#             # elseif caseN == 15
#                 # also draw no lines
#             end
#             for line in lines
#                 draw_multiline(file, [t(p...) for p in line], contour.linewidth, (0,0,0))
#             end

#         end
#         draw_group_end(file);
#     end
#     draw_group_end(file);

# end























mutable struct Contour <: GraphicPart
    data::Dataspace
    levels::Array{Number}
    sample_ponts::Array{Tuple{Number, Number}}
    linewidth::Number
    filled::Bool
    colormap::Function
    xlims::Tuple{Number,Number}
    ylims::Tuple{Number,Number}
    clims::Tuple{Number,Number}
    transform::Function
    detransform::Function
end
# Contour(xs::Array{Number},ys::Array{Number},cs::Matrix{Number},
#         levels,linewidth,filled,colormap,clims) = 
#         Contour(InverseDistanceWeightedSpace(xs,ys,cs),levels,linewidth,filled,colormap,(minimum(xs),maximum(xs)),(minimum(ys),maximum(ys)),clims);

function Colorbar(h::Contour)
    return Colorbar(h.colormap, h.clims)
end
function draw_graphic(file::GraphicsOutput, contour::Contour, t::Transform)
    draw_group_start(file);

    draw_group_start(file);
    boxcolor = contour.colormap(0.0)
    points = [
        (contour.xlims[1],contour.ylims[1]),
        (contour.xlims[2],contour.ylims[1]),
        (contour.xlims[2],contour.ylims[2]),
        (contour.xlims[1],contour.ylims[2]),
    ]
    draw_multiline(file, transform_series(t,points), contour.linewidth, boxcolor, filled=contour.filled)
    draw_group_end(file);

    for li in eachindex(contour.levels)
        l = contour.levels[li]
        draw_group_start(file);
        for si in 1:(length(contour.sample_ponts)-1)
            contour_starts = look_for_contours(contour, l, contour.sample_ponts[si], contour.sample_ponts[si+1])
            for start in contour_starts
                draw_contour(file, contour, t, start, l)
            end
        end
        draw_group_end(file);
    end
    draw_group_end(file);
end


# p1 and p2 should be to-transform. contours should be to-transform
function look_for_contours(contour::Contour,level::Number, p1::Tuple{Number,Number}, p2::Tuple{Number,Number};log=false)

    p1 = contour.transform(p1...); p2 = contour.transform(p2...);

    dir = (p2 .- p1); dist = norm(p2 .- p1);
    data(s) = contour.data(contour.detransform((p1 .+ (s .* dir))...))

    # Walk carefully from p1 to p2.
    loc = 0;
    contours = [];
    while loc < 0.99
        steplength = min(1-loc,
             abs(0.01 * (data(loc) / ForwardDiff.derivative(data, loc)))
            );
        if steplength == 0
            break
        end

        newloc = loc+steplength;

        # If contour crossed
        loc_value = data(loc); newloc_value = data(newloc);
        if sign(loc_value-level) != sign(newloc_value-level)
            # Binary search for crossing
            a = loc; b = newloc; a_value = loc_value; b_value = newloc_value;
            searchloc = 0.5(a .+ b);
            searchloc_value = data(searchloc);
            while abs((searchloc_value - level) / level ) > 0.01
                if sign(searchloc_value - level) == sign(a_value-level)
                    a = searchloc; a_value = searchloc_value;
                else
                    b = searchloc; b_value = searchloc_value;
                end
                searchloc = 0.5(a + b);
                searchloc_value = data(searchloc);
            end
            crossing_point = searchloc;

            push!(contours, contour.detransform( (p1 .+ (crossing_point .* dir))... ))
        end

        loc = newloc;
    end

    return contours
end



# start is to-transform
function draw_contour(file::GraphicsOutput, contour::Contour, t::Transform, start::Tuple{Number, Number}, level)
    # data(xy) = contour.data(xy)
    data(xy) = contour.data(contour.detransform(xy...))


    ε = 0.0000000001

    start = contour.transform(start...);

    points = [start];
    

    border_bounces = 0;
    rotation = 1;
    while true
        loc = points[end];

        a = length(points)
        trace_border!(contour, contour.detransform(loc...), points, level)
        
        border_bounces += length(points) -a ;
        loc = points[end];

        dx,dy = ForwardDiff.gradient(data, [loc...])
        stepdir = [-dy,dx];
        stepdir = stepdir ./ norm(stepdir);

        if border_bounces > 4
            break
        end

        if length(points) > 10000
            break
            
        end
        if length(points) > 10
            # CARTESIAN ASSUMPTION
            # if norm((loc .- start) ./ (0.5 .* (loc .+ start))) < 0.1
            #     push!(points, start)
            #     break
            # end
            
            topleft = (contour.xlims[1], contour.ylims[2])
            bottomright = (contour.xlims[2], contour.ylims[1])
            domain = abs.(contour.transform(topleft...) .- contour.transform(bottomright...))
            dist = abs.(loc .- start) ./ domain
            
            if maximum(dist) < 0.015
                push!(points, start)
                break
            end
        end

        # Got this bullshit from chatgpt?
        # hess = ForwardDiff.hessian(data, [loc...])
        # fxx, fxy = hess[1, 1], hess[1, 2]
        # fyx, fyy = hess[2, 1], hess[2, 2]
        # kappa = (dx^2 * fyy - 2dx*dy*fxy + dy^2 * fxx) / (dy^2 + dy^2)^(3/2)
        # steplength = clamp(1 / (abs(kappa) + ε), abs(dot(stepdir, 0.001 .* loc)), abs(dot(stepdir, 0.003 .* loc)))


        # CARTESIAN ASSUMPTION
        # steplength = 0.1abs(dot(stepdir, loc))


        
        topleft = (contour.xlims[1], contour.ylims[2])
        bottomright = (contour.xlims[2], contour.ylims[1])
        domain = abs.(contour.transform(topleft...) .- contour.transform(bottomright...))

        stepdir = stepdir ./ norm(stepdir)
        steplength = dot(0.1 .* domain, stepdir);



        newpoint = [(loc .+ (steplength*stepdir))...,];
        newpoint[1] = min(max(newpoint[1], contour.xlims[1]), contour.xlims[2]);
        newpoint[2] = min(max(newpoint[2], contour.ylims[1]), contour.ylims[2]);
        push!(points, (newpoint...,));

        
    end

    println(data(start), " ",length(points), " ",border_bounces, " ",points[begin] == points[end])

    boxcolor = contour.colormap((level-contour.clims[1]) ./ (contour.clims[2]-contour.clims[1]))

    points = [contour.detransform(xy...) for xy in points];

    draw_multiline(file, transform_series(t,points), contour.linewidth, boxcolor, filled=contour.filled)
end

# loc should be to-transform, points should be transformed.
function trace_border!(contour::Contour, loc::Tuple{Number, Number}, points, level)
    data(xy) = contour.data(xy)

    nextcorners = [];
    if (loc[1] < 1.001contour.xlims[1])
        # println("low x")
        if dot(ForwardDiff.gradient(data, [loc...]),[0,1]) > 0
            nextcorners = [
                (contour.xlims[1], contour.ylims[2]),
                (contour.xlims[2], contour.ylims[2]),
                (contour.xlims[2], contour.ylims[1]),
                (contour.xlims[1], contour.ylims[1]),
                (contour.xlims[1], contour.ylims[2]) ];
        else
            nextcorners = [
                (contour.xlims[1], contour.ylims[1]),
                (contour.xlims[2], contour.ylims[1]),
                (contour.xlims[2], contour.ylims[2]),
                (contour.xlims[1], contour.ylims[2]),
                (contour.xlims[1], contour.ylims[1]) ];
        end
    elseif (loc[1] > 0.999contour.xlims[2])
        # println("hi x")
        if dot(ForwardDiff.gradient(data, [loc...]),[0,1]) < 0
            nextcorners = [
                (contour.xlims[2], contour.ylims[2]),
                (contour.xlims[2], contour.ylims[1]),
                (contour.xlims[1], contour.ylims[1]),
                (contour.xlims[1], contour.ylims[2]),
                (contour.xlims[2], contour.ylims[2]) ];
        else
            nextcorners = [
                (contour.xlims[2], contour.ylims[1]),
                (contour.xlims[2], contour.ylims[2]),
                (contour.xlims[1], contour.ylims[2]),
                (contour.xlims[1], contour.ylims[1]),
                (contour.xlims[2], contour.ylims[1]) ];
        end
    elseif (loc[2] < 1.0001contour.ylims[1])
        # println("low y")
        if dot(ForwardDiff.gradient(data, [loc...]),[1,0]) < 0
            nextcorners = [
                (contour.xlims[1], contour.ylims[1]),
                (contour.xlims[1], contour.ylims[2]),
                (contour.xlims[2], contour.ylims[2]),
                (contour.xlims[2], contour.ylims[1]),
                (contour.xlims[1], contour.ylims[1]) ];
        else
            nextcorners = [
                (contour.xlims[2], contour.ylims[1]),
                (contour.xlims[2], contour.ylims[2]),
                (contour.xlims[1], contour.ylims[2]),
                (contour.xlims[1], contour.ylims[1]),
                (contour.xlims[2], contour.ylims[1]) ];
        end
    elseif (loc[2] > 0.999contour.ylims[2])
        # println("hi y")
        if dot(ForwardDiff.gradient(data, [loc...]),[1,0]) < 0
            nextcorners = [
                (contour.xlims[1], contour.ylims[2]),
                (contour.xlims[1], contour.ylims[1]),
                (contour.xlims[2], contour.ylims[1]),
                (contour.xlims[2], contour.ylims[2]),
                (contour.xlims[1], contour.ylims[2]) ]
        else
            nextcorners = [
                (contour.xlims[2], contour.ylims[2]),
                (contour.xlims[2], contour.ylims[1]),
                (contour.xlims[1], contour.ylims[1]),
                (contour.xlims[1], contour.ylims[2]),
                (contour.xlims[2], contour.ylims[2]) ]
        end
    end
    whichtofind = 2;
    for nextcorner in nextcorners


        # dir = (nextcorner .- loc); dist = norm(nextcorner .- loc);
        # data2(s) = contour.data(loc .+ (s .* dir))

        # steplength = abs(0.001 * (data2(0) / ForwardDiff.derivative(data2, 0)))
        # println(steplength)

        contour_starts = look_for_contours(contour, level, loc , nextcorner,log=false) #.+ 0.01 .* (nextcorner .- loc)

        if length(contour_starts) < whichtofind
            push!(points, contour.transform(nextcorner...))
            loc = contour.detransform(points[end]...)
        else
            push!(points, contour.transform(contour_starts[whichtofind]...))
            break
        end
        whichtofind = 1;
        # print("fds")
        # readline()
    end
end











# function look_for_contours(contour::Contour,level::Number, p1::Tuple{Number,Number}, p2::Tuple{Number,Number};log=false)
#     dir = (p2 .- p1); dist = norm(p2 .- p1); # CARTESIAN ASSUMPTION
#     data(s) = contour.data(p1 .+ (s .* dir)) # CARTESIAN ASSUMPTION it's just not a straight line to move across

#     # Walk carefully from p1 to p2.
#     loc = 0;
#     contours = [];
#     while loc < 1
#         steplength = min(1-loc,abs(0.01 * (data(loc) / ForwardDiff.derivative(data, loc))));

#         newloc = loc+steplength;

#         # If contour crossed
#         loc_value = data(loc); newloc_value = data(newloc);
#         if sign(loc_value-level) != sign(newloc_value-level)
#             # Binary search for crossing
#             a = loc; b = newloc; a_value = loc_value; b_value = newloc_value;
#             searchloc = 0.5(a .+ b);
#             searchloc_value = data(searchloc);
#             while abs((searchloc_value - level) / level ) > 0.00001
#                 if sign(searchloc_value - level) == sign(a_value-level)
#                     a = searchloc; a_value = searchloc_value;
#                 else
#                     b = searchloc; b_value = searchloc_value;
#                 end
#                 searchloc = 0.5(a + b);
#                 searchloc_value = data(searchloc);
#             end
#             crossing_point = searchloc;

#             push!(contours, p1 .+ (crossing_point .* dir)) # CARTESIAN ASSUMPTION it's just not a straight line to move across
#         end

#         loc = newloc;
#     end

#     return contours
# end