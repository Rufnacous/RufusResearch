mutable struct Axis <: GraphicPart
    x::Number
    y::Number
    width::Number
    height::Number
    xlim::Tuple{Number,Number}
    ylim::Tuple{Number,Number}
    parts::Array{GraphicPart}
end
Axis() = Axis(0,0,1,1,(0.0,1.0),(0.0,1.0),[])
Axis(x,y,w,h) = Axis(x,y,w,h,(0.0,1.0),(0.0,1.0),[])

function draw_graphic_traverse(o::GraphicsOutput, g::Axis, t::Transform)
    xwidth = g.xlim[2] - g.xlim[1]; ywidth = g.ylim[2] - g.ylim[1];

    inner_t = t(Affine(BoxSDF(g), (g.x - (g.xlim[1]*g.width/xwidth), g.y - (g.ylim[1]*g.height/ywidth)), (g.width/xwidth, g.height/ywidth)));

    [draw_graphic_traverse(o, p, inner_t) for p in g.parts]
end

function BoxSDF(a::Axis)
    return BoxSDF(a.xlim[1], a.ylim[1], a.xlim[2], a.ylim[2]);
end



mutable struct LogAxis <: GraphicPart
    x::Number
    y::Number
    width::Number
    height::Number
    xlim::Tuple{Number,Number}
    ylim::Tuple{Number,Number}
    parts::Array{GraphicPart}
end
LogAxis() = LogAxis(0,0,1,1,(0.0,1.0),(0.0,1.0),[])
LogAxis(x,y,w,h) = LogAxis(x,y,w,h,(0.0,1.0),(0.0,1.0),[])

function draw_graphic_traverse(o::GraphicsOutput, g::LogAxis, t::Transform)
    base = (10, 10);
    xwidth = log(base[1], g.xlim[2] / g.xlim[1]); ywidth = log(base[2], g.ylim[2] / g.ylim[1]);

    m = ( g.width/xwidth, g.height/ywidth )
    c = ( g.x - (m[1]*log(base[1], g.xlim[1])), g.y - (m[2]*log(base[2],g.ylim[1])) )
    inner_t = t(LogarithmicAffine(BoxSDF(g), c, m, base));

    [draw_graphic_traverse(o, p, inner_t) for p in g.parts]
end

function BoxSDF(a::LogAxis)
    return BoxSDF(a.xlim[1], a.ylim[1], a.xlim[2], a.ylim[2]);
end



mutable struct SpecialLogAxis <: GraphicPart
    x::Number
    y::Number
    width::Number
    height::Number
    xlim::Tuple{Number,Number}
    ylim::Tuple{Number,Number}
    parts::Array{GraphicPart}
end
SpecialLogAxis() = SpecialLogAxis(0,0,1,1,(0.0,1.0),(0.0,1.0),[])
SpecialLogAxis(x,y,w,h) = SpecialLogAxis(x,y,w,h,(0.0,1.0),(0.0,1.0),[])

function draw_graphic_traverse(o::GraphicsOutput, g::SpecialLogAxis, t::Transform)
    xwidth = log(10, g.xlim[2] / g.xlim[1]);
    
    ywidth = speciallogfunc( g.ylim[2] ) - speciallogfunc( g.ylim[1]);

    m = ( g.width/xwidth, g.height/ywidth )
    c = ( g.x - (m[1]*log(10, g.xlim[1])), g.y - (m[2]*speciallogfunc(g.ylim[1])) )

    inner_t = t(SpecialLogAffine(BoxSDF(g), c, m));

    [draw_graphic_traverse(o, p, inner_t) for p in g.parts]
end

function BoxSDF(a::SpecialLogAxis)
    return BoxSDF(a.xlim[1], a.ylim[1], a.xlim[2], a.ylim[2]);
end


struct AxisLines <: GraphicPart
    parent_axis::Axis
    linewidth::Number
end
function draw_graphic(file::GraphicsOutput, lines::AxisLines, t::Transform)

    draw_multiline(file,  [t(xy[1],xy[2]) for xy in [
        (lines.parent_axis.xlim[1], 0), (lines.parent_axis.xlim[2], 0)
    ]], lines.linewidth, (0,0,0));
    
    draw_multiline(file,  [t(xy[1],xy[2]) for xy in [
        (0, lines.parent_axis.ylim[1]), (0, lines.parent_axis.ylim[2])
    ]], lines.linewidth, (0,0,0));

end
add_axis_lines(ax::Axis) = ax(AxisLines(ax, 1));

mutable struct ManualAxisTicks <: GraphicPart
    parent_axis #::Axis
    linewidth::Number
    tickheight::Number
    xticks::Vector{<: Number}
    yticks::Vector{<: Number}
    align::Tuple{Symbol, Symbol}
end
function draw_graphic(file::GraphicsOutput, ticks::ManualAxisTicks, t::Transform)
    ax = ticks.parent_axis;

    for tx = ticks.xticks
        # y1 = -ticks.tickheight*(ax.ylim[2] - ax.ylim[1]);
        # y2 = ticks.tickheight*(ax.ylim[2] - ax.ylim[1]);

        # if ticks.align[1] == :left
        #     y1 = 0;
        #     y2 = ticks.tickheight;
        # end
        
        tickstart = t(tx, ax.ylim[1]);        
        tickend = tickstart .+ rotate(t, (tx, ax.ylim[1]), (0,ticks.tickheight));

        draw_multiline(file,  [
            tickstart, tickend
        ], ticks.linewidth, (0,0,0));
    end
    
    for ty = ticks.yticks
        # x1 = -ticks.tickheight*(ax.xlim[2] - ax.xlim[1]);
        # x2 = ticks.tickheight*(ax.xlim[2] - ax.xlim[1]);

        # if ticks.align[2] == :bottom
        #     x1 = ax.xlim[1];
        #     x2 = ticks.tickheight;
        # end

        tickstart = t(ax.xlim[1],ty);
        tickend = tickstart .+ rotate(t, (ax.xlim[1],ty), (ticks.tickheight,0));
        draw_multiline(file,  [ 
            t(ax.xlim[1],ty), tickend
            ], ticks.linewidth, (0,0,0));
    end

end
function add_axis_ticks(ax::Axis, xgap::Number, ygap::Number)
    x1 = ceil(ax.xlim[1] / xgap) * xgap;
    y1 = ceil(ax.ylim[1] / ygap) * ygap;
    return ax(ManualAxisTicks(ax, 1, 10, collect(x1:xgap:ax.xlim[2]), collect(y1:ygap:ax.ylim[2]), (:left, :bottom)))
end
function add_axis_ticks(ax::LogAxis)

    if any([ax.xlim..., ax.ylim...] .<= 0)
        throw(InexactError("Error generating ticks. Have you set nonzero, positive lims yet?"))
    end

    x1 = 10 ^ ceil(log(10,ax.xlim[1]))
    y1 = 10 ^ ceil(log(10,ax.ylim[1]))
    
    xs = 10 .^ collect(log(10,x1):1:log(10,ax.xlim[2]+0.0000001))
    ys = 10 .^ collect(log(10,y1):1:log(10,ax.ylim[2]+0.0000001))

    a1 = ax(ManualAxisTicks(ax, 1, 10, xs, ys, (:left, :bottom)));
    for m = 0.1:0.1:0.9
        a2 = ax(ManualAxisTicks(ax, 1, 10, m*xs, m*ys, (:left, :bottom)));
        a2.tickheight *= m
    end

    return a1
end
function add_axis_ticks(ax::SpecialLogAxis, ygap::Number)
    x1 = 10 ^ ceil(log(10,ax.xlim[1]))
    xs = 10 .^ collect(log(10,x1):1:log(10,ax.xlim[2]))

    y1 = ceil(ax.ylim[1] / ygap) * ygap;
    ys = collect(y1:ygap:ax.ylim[2]);
    

    return ax(ManualAxisTicks(ax, 1, 10, xs, ys, (:left, :bottom)))
end


mutable struct SuperAxisTicks <: GraphicPart
    parent_axis #::Axis
    linewidth::Number
    tickheight::Number
    xticks::Vector{<: Number}
    yticks::Vector{<: Number}
    align::Tuple{Symbol, Symbol}
    parts_x::Array{GraphicPart}
    parts_y::Array{GraphicPart}
end


function draw_graphic_traverse(o::GraphicsOutput, ticks::SuperAxisTicks, t::Transform)

    ax = ticks.parent_axis;

    for ti in eachindex(ticks.xticks)
        # xy = t(ticks.xticks[ti], 0)
        draw_graphic_traverse(o, ticks.parts_x[ti], t( Translate(ticks.xticks[ti], ax.ylim[1]) )  )
    end
    
    for ti in eachindex(ticks.yticks)
        
        #ax.xlim[1]
        # xy = t(0, ticks.yticks[ti])
        draw_graphic_traverse(o, ticks.parts_y[ti], t( Translate(ax.xlim[1], ticks.yticks[ti]) )  )
    end

end

function add_axis_numbers(ax::Axis, xgap::Number, ygap::Number; x::Bool=true, y::Bool=true)

    x1 = ceil(ax.xlim[1] / xgap) * xgap;
    y1 = ceil(ax.ylim[1] / ygap) * ygap;

    xs, ys = collect(x1:xgap:ax.xlim[2]), collect(y1:ygap:ax.ylim[2]);
    xnums = [
        Graphicus.Text(0, 0, @sprintf("%.2f", xt), 22, :center, 0, 25, 0) 
        for xt in xs
    ]
    ynums = [
        Graphicus.Text(0, 0, @sprintf("%.2f", yt), 22, :center, 38, 5, 0) 
        for yt in ys
    ]
    if !x
        xs = [0][2:end];
    end
    if !y
        ys = [0][2:end];
    end
    return ax(SuperAxisTicks(ax, 1, 10, xs, ys, (:left, :bottom), xnums, ynums,x,y))
end
function add_axis_numbers(ax::LogAxis; x::Bool=true, y::Bool=true)

    x1 = 10 ^ ceil(log(10,ax.xlim[1])-0.0000001)
    y1 = 10 ^ ceil(log(10,ax.ylim[1])-0.0000001)
    
    xs = 10 .^ collect(log(10,x1):1:log(10,ax.xlim[2]+0.0000001))
    ys = 10 .^ collect(log(10,y1):1:log(10,ax.ylim[2]+0.0000001))


    xnums = [
        Graphicus.Text(0, 0, @sprintf("₁₀%d", log(10,xt)), 22, :center, 0, 25, 0) 
        for xt in xs
    ]
    ynums = [
        Graphicus.Text(0, 0, @sprintf("₁₀%d", log(10,yt)), 22, :center, 38, 5, 0) 
        for yt in ys
    ]
    if !x
        xs = [0][2:end];
    end
    if !y
        ys = [0][2:end];
    end
    return ax(SuperAxisTicks(ax, 1, 10, xs, ys, (:left, :bottom), xnums, ynums))
end
function add_axis_numbers(ax::SpecialLogAxis, ygap::Number; x::Bool=true, y::Bool=true)

    x1 = 10 ^ ceil(log(10,ax.xlim[1])-0.0000001)
    xs = 10 .^ collect(log(10,x1):1:log(10,ax.xlim[2]+0.0000001))
    
    y1 = ceil(ax.ylim[1] / ygap) * ygap;
    ys = collect(y1:ygap:ax.ylim[2]);


    xnums = [
        Graphicus.Text(0, 0, @sprintf("₁₀%d", log(10,xt)), 22, :center, 0, 25, 0) 
        for xt in xs
    ]
    ynums = [
        Graphicus.Text(0, 0, @sprintf("%.2f", yt), 22, :center, 38, 5, 0) 
        for yt in ys
    ]
    if !x
        xs = [0][2:end];
    end
    if !y
        ys = [0][2:end];
    end
    return ax(SuperAxisTicks(ax, 1, 10, xs, ys, (:left, :bottom), xnums, ynums))
end



# struct AxisTicks<: GraphicPart
#     parent_axis::Axis
#     linewidth::Number
#     tickheight::Number
# end
# function draw_graphic(file::GraphicsOutput, ticks::AxisTicks, t::Transform)
#     ax = ticks.parent_axis;

#     xgap = 10^floor(log(10, ax.xlim[2] - ax.xlim[1]) - 0.6);
#     ygap = 10^floor(log(10, ax.ylim[2] - ax.ylim[1]) - 0.6);

#     x1 = floor(ax.xlim[1] / xgap) * xgap;
#     y1 = floor(ax.ylim[1] / ygap) * ygap;
    
#     for tx = x1:xgap:ax.xlim[2]
#         draw_multiline(file,  [t(xy[1],xy[2]) for xy in [
#             (tx, -ticks.tickheight*(ax.ylim[2] - ax.ylim[1])), (tx, ticks.tickheight*(ax.ylim[2] - ax.ylim[1]))
#         ]], ticks.tickheight);
#     end
    
#     for ty = y1:ygap:ax.ylim[2]
#         draw_multiline(file,  [t(xy[1],xy[2]) for xy in [
#             (-ticks.tickheight*(ax.xlim[2] - ax.xlim[1]), ty), (ticks.tickheight*(ax.xlim[2] - ax.xlim[1]), ty)
#         ]], ticks.tickheight);
#     end

# end
# add_axis_ticks(ax::Axis) = ax(AxisTicks(ax, 1, 0.0125));


abstract type Projection <: Transform end;

mutable struct OrthogonalCamera <: Projection
    sdf::SDF
    azimuth::Number #radians
    elevation::Number #radians
    scale::Number
end
OrthogonalCamera(a::Number, e::Number, s::Number) = OrthogonalCamera(BorderlessSDF(), a, e, s);

function (camera::OrthogonalCamera)(x::Number, y::Number, z::Number)

    # Rotation matrices for azimuth and elevation
    R_azimuth = [
        cos(camera.azimuth) -sin(camera.azimuth) 0;
        sin(camera.azimuth)  cos(camera.azimuth) 0;
        0                   0                    1
    ]

    R_elevation = [
        1  0                  0;
        0  cos(camera.elevation) -sin(camera.elevation);
        0  sin(camera.elevation)  cos(camera.elevation)
    ]

    # Combined rotation matrix
    R = R_elevation * R_azimuth

    # Rotate the 3D point
    rotated_xyz = R * [x, y, z]

    # Orthogonal projection: Drop the z-coordinate
    xy = (rotated_xyz[1]*camera.scale, rotated_xyz[2]*camera.scale)
    return xy
end

mutable struct Axis3D <: GraphicPart
    x::Number
    y::Number
    width::Number
    height::Number
    projection::Projection
    xlim::Tuple{Number,Number}
    ylim::Tuple{Number,Number}
    zlim::Tuple{Number,Number}
    origin::Tuple{Number, Number}
    parts::Array{GraphicPart}
end
Axis3D() = Axis3D(0,0,1,1)
Axis3D(x,y,w,h) = Axis3D(x,y,w,h,OrthogonalCamera(-pi/4, pi/4,0.1),(0.0,1.0),(0.0,1.0),(0.0,1.0),(0,0),[]);

function draw_graphic_traverse(o::GraphicsOutput, g::Axis3D, t::Transform)

    # xwidth = g.xlim[2] - g.xlim[1]; ywidth = g.ylim[2] - g.ylim[1];

    # inner_t = t(Affine(BoxSDF(g), (g.x - (g.xlim[1]*g.width/xwidth), g.y - (g.ylim[1]*g.height/ywidth)), (g.width/xwidth, g.height/ywidth)));
    
    [draw_graphic_traverse(o, p,
        t(Affine((g.x + (g.origin[1]*g.width), g.y + (g.origin[2]*g.height)), (g.width, -g.height))(g.projection))
        # (x,y,z) -> transform( 
        #     g.x + project((x,y,z), g.projection)[1]*g.width,
        #     g.y - project((x,y,z), g.projection)[2]*g.height     )
    ) for p in g.parts]
end


mutable struct PolarAxis <: GraphicPart
    x::Number
    y::Number
    width::Number
    height::Number
    rlim::Tuple{Number,Number}
    parts::Array{GraphicPart}
end
PolarAxis() = PolarAxis(0,0,1,1,(0.0,1.0),[])
PolarAxis(x,y,w,h) = PolarAxis(x,y,w,h,(0.0,1.0),[])

function draw_graphic_traverse(o::GraphicsOutput, g::PolarAxis, t::Transform)
    inner_t = t( Polar(CircleSDF(g)) );
    [draw_graphic_traverse(o, p, inner_t) for p in g.parts]
end
function CircleSDF(a::PolarAxis)
    return CircleSDF(a.rlim...);
end