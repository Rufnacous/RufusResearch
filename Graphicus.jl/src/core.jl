macro writesprintf(file, format, args...)
    quote
        write($(esc(file)), @sprintf($(string(format)), $(esc.(args)...)))
    end
end


abstract type GraphicPart end;
abstract type GraphicsOutput end;




abstract type SDF end

struct BorderlessSDF <: SDF end;

mutable struct BoxSDF <: SDF
    x1::Number
    y1::Number
    x2::Number
    y2::Number
end

mutable struct CircleSDF <: SDF
    r1::Number
    r2::Number
end



struct ComposedSDF <: SDF
    outer::SDF
    inner::SDF
end;
function (outer::SDF)(inner::SDF)
    return ComposedSDF(outer, inner);
end




    
abstract type Transform end;
    
Base.getindex(t::Transform, xyz_args...) = t.sdf(t, xyz_args...);

struct ComposedTransform <: Transform
    sdf::SDF
    outer::Transform
    inner::Transform
end
function (outer::Transform)(inner::Transform)
    return ComposedTransform(outer.sdf(inner.sdf), outer, inner);
end

function (t::ComposedTransform)(x::Number, args...)
    return t.outer(t.inner(x, args...)...)
end

struct Identity <: Transform
    sdf::SDF
end
Identity() = Identity(BorderlessSDF());
function (transform::Identity)(x::Number, y::Number)
    return x, y
end

struct UpsideDown <: Transform
    sdf::SDF
    c::Number
end
UpsideDown(c) = UpsideDown(BorderlessSDF(),c);
function (transform::UpsideDown)(x::Number, y::Number)
    return x, transform.c-y
end

mutable struct Translate <: Transform
    sdf::SDF
    x::Number
    y::Number
end
Translate(x::Number, y::Number) = Translate(BorderlessSDF(), x, y);
function (transform::Translate)(x::Number, y::Number)
    return (transform.x + x, transform.y + y)
end

mutable struct Linear <: Transform
    sdf::SDF
    m::Tuple{Number,Number}
end#
Linear(m::Tuple{Number,Number}) = Linear(BorderlessSDF(), m);
function (transform::Linear)(x::Number, y::Number)
    return (transform.m[1]*x, transform.m[2]*y)
end

mutable struct Affine <: Transform
    sdf::SDF
    c::Tuple{Number, Number}
    m::Tuple{Number, Number}
end
Affine(c::Tuple{Number, Number}, m::Tuple{Number, Number}) = Affine(BorderlessSDF(), c, m);
function (transform::Affine)(x::Number, y::Number)
    return (transform.c[1] + transform.m[1]*x, transform.c[2] + transform.m[2]*y)
end


mutable struct LogarithmicAffine <: Transform
    sdf::SDF
    c::Tuple{Number, Number}
    m::Tuple{Number, Number}
    base::Tuple{Number, Number}
end
LogarithmicAffine(c::Tuple{Number, Number}, m::Tuple{Number, Number}, base::Tuple{Number, Number}) = LogarithmicAffine(BorderlessSDF(), c, m, base);
function (transform::LogarithmicAffine)(x::Number, y::Number)
    return (transform.c[1] + transform.m[1]*log(transform.base[1],max(1e-10, x)), transform.c[2] + transform.m[2]*log(transform.base[2],max(1e-10, y)))
end

mutable struct LogarithmicXAffine <: Transform
    sdf::SDF
    c::Tuple{Number, Number}
    m::Tuple{Number, Number}
    base::Number
end
LogarithmicXAffine(c::Tuple{Number, Number}, m::Tuple{Number, Number}, base::Number) = LogarithmicXAffine(BorderlessSDF(), c, m, base);
function (transform::LogarithmicXAffine)(x::Number, y::Number)
    
    unsafelog = -100000
    if x > 0
        unsafelog = log(transform.base[1],x)
    end
    return (transform.c[1] + transform.m[1]*unsafelog, transform.c[2] + transform.m[2]*y)
end

mutable struct SpecialLogAffine <: Transform
    sdf::SDF
    c::Tuple{Number, Number}
    m::Tuple{Number, Number}
end
SpecialLogAffine(c::Tuple{Number, Number}, m::Tuple{Number, Number}) = SpecialLogAffine(BorderlessSDF(), c, m);
function (transform::SpecialLogAffine)(x::Number, y::Number)
    return (transform.c[1] + transform.m[1]*log(10,x), transform.c[2] + transform.m[2]*speciallogfunc(y))
end

function speciallogfunc(x)
    if x < 0.5
        return log(10, 2x)
    else
        return -log(10, 2 - 2x)
    end
end



mutable struct Polar <: Transform
    sdf::SDF
end
Polar() = Polar(BorderlessSDF());
function (transform::Polar)(r::Number, theta::Number)
    return (r * sin(theta), r * cos(theta));
end


function (sdf::BorderlessSDF)(t::Transform, x::Number, y::Number)
    return -1
end
function (quad::BoxSDF)(t::Transform, x::Number, y::Number)
    # Transform the four corners
    p00 = t(quad.x1, quad.y1)
    p10 = t(quad.x2, quad.y1)
    p11 = t(quad.x2, quad.y2)
    p01 = t(quad.x1, quad.y2)

    # Position of the four points
    x0, y0 = p00
    x1, y1 = p10
    x2, y2 = p11
    x3, y3 = p01

    # Bilinear interpolation to get (x,y) from (u,v):
    # P(u,v) = (1-u)(1-v)*p00 + u(1-v)*p10 + uv*p11 + (1-u)v*p01

    # We need to solve for (u,v) given (x,y)
    # Approximate (e.g., Newton's method, or a simple guess+1 iteration)

    # Initial guess
    u = 0.5
    v = 0.5
    for _ in 1:5  # 5 Newton iterations
        # Compute current position
        px = (1-u)*(1-v)*x0 + u*(1-v)*x1 + u*v*x2 + (1-u)*v*x3
        py = (1-u)*(1-v)*y0 + u*(1-v)*y1 + u*v*y2 + (1-u)*v*y3

        # Compute error
        ex = px - x
        ey = py - y

        # Partial derivatives
        dpx_du = -(1-v)*x0 + (1-v)*x1 + v*x2 - v*x3
        dpx_dv = -(1-u)*x0 - u*x1 + u*x2 + (1-u)*x3
        dpy_du = -(1-v)*y0 + (1-v)*y1 + v*y2 - v*y3
        dpy_dv = -(1-u)*y0 - u*y1 + u*y2 + (1-u)*y3

        # Jacobian inverse
        det = dpx_du*dpy_dv - dpx_dv*dpy_du
        if abs(det) < 1e-8
            break  # Avoid division by zero
        end

        du = ( dpy_dv*ex - dpx_dv*ey) / det
        dv = (-dpy_du*ex + dpx_du*ey) / det

        u -= du
        v -= dv
    end

    # Now (u,v) should roughly correspond to (x,y)
    du = max(abs(u - 0.5) * 2, abs(v - 0.5) * 2)
    sdf = du - 1

    return sdf
end
function (circle::CircleSDF)(t::Transform, x::Number, y::Number)
    xinner, yinner = t(0, 0);
    xouter, youter = t(circle.r2, 0);

    return sqrt(((x-xinner)^2) + ((y-yinner)^2)) - sqrt(((xouter-xinner)^2) + ((youter-yinner)^2)) ;
end
function (sdfs::ComposedSDF)(t::Transform, x::Number, y::Number)
    return max(sdfs.outer(t, x, y), sdfs.inner(t, x, y))
end



function draw_graphic_traverse(o::GraphicsOutput, g::GraphicPart, t::Transform)
    hasparts = false;
    try
        g.parts
        hasparts = true;
    catch
        hasparts = false;
    end
    # (x+g.x*w), (y+g.y*h), (w*g.width), (h*g.height)

    if hasparts
        draw_group_start(o);

        [draw_graphic_traverse(o, p, 
            t(Affine((g.x, g.y), (g.width, g.height)))
            ) for p in g.parts]

        draw_graphic(o, g, t);
        
        draw_group_end(o);
    else
        draw_graphic(o, g, t);
    end
    
end
function draw_graphic(o::GraphicsOutput, g::GraphicPart, t::Transform)
    throw(ErrorException(@sprintf("Draw graphic not implemented for type %s:%s",typeof(o),typeof(g))))
end
function (g_parent::GraphicPart)(g_child::GraphicPart)
    try
        g_parent.parts
    catch
        throw(ErrorException(@sprintf("Append graphic not implemented for type %s",typeof(g_parent))))
    end

    push!(g_parent.parts, g_child)
    return g_child;
end

struct GraphicSum
    graphics::Vector{GraphicPart}
end
function (g_parent::GraphicPart)(g_children::GraphicSum)
    try
        g_parent.parts
    catch
        throw(ErrorException(@sprintf("Append graphic not implemented for type %s",typeof(g_parent))))
    end

    append!(g_parent.parts, g_children.graphics)
    return g_children.graphics;
end
function Base.:(+)(g1::GraphicPart, g2::GraphicPart)
    return GraphicSum([g1,g2])
end
function Base.:(+)(g1::GraphicPart, gs::GraphicSum)
    return GraphicSum([g1, gs.graphics...])
end
function Base.:(+)(gs::GraphicSum, g2::GraphicPart)
    return GraphicSum([gs.graphics...,g2])
end
function Base.:(+)(gs1::GraphicSum, gs2::GraphicSum)
    return GraphicSum([gs1.graphics...,gs2.graphics...])
end
Base.getindex(gs::GraphicSum, i) = gs.graphics[i];


struct Graphic <: GraphicPart
    x::Number
    y::Number
    width::Number
    height::Number

    parts::Array{GraphicPart}
end
function Graphic(w, h)
    return Graphic(0,0,w,h,[]);
end
function draw_graphic(output::GraphicsOutput, g::Graphic, t::Transform)
    return
end



function transform_series(t::Transform, xys)
    return [t(xy...) for xy in xys];
end

function interpolate_and_transform_series(t::Transform, xys; density::Integer = 10)
    new_xys::Vector{Tuple{Float64, Float64}} = [];
    svals = collect(LinRange(0,1,density+2)[2:end-1]);
    for i in 1:(length(xys)-1)
        a = xys[i]; b = xys[i+1];

        push!(new_xys, t(a...));
        mx = b[1] - a[1]; my = b[2] - a[2];
        append!(new_xys, [
            t(a[1] + mx*s, a[2] + my*s) for s in svals
        ]);
    end
    push!(new_xys, t(xys[end]...));
    return new_xys;
end


function rotate(t::Transform, xy_o::Tuple{Number, Number}, xy::Tuple{Number, Number})
    ex = t(((0.001,0) .+ xy_o)...) .- t(xy_o...);
    ex = ex ./ sqrt(sum(ex.^2))
    ey = t(((0,0.001) .+ xy_o)...) .- t(xy_o...);
    ey = ey ./ sqrt(sum(ey.^2))
    return (([ex[1] ey[1]; ex[2] ey[2]] * [xy...])...,)
end








