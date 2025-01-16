
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
    return (transform.c[1] + transform.m[1]*log(transform.base[1],x), transform.c[2] + transform.m[2]*log(transform.base[2],y))
end

mutable struct SpecialLogAffine <: Transform
    sdf::SDF
    c::Tuple{Number, Number}
    m::Tuple{Number, Number}
end
SpecialLogAffine(c::Tuple{Number, Number}, m::Tuple{Number, Number}) = SpecialLogAffine(BorderlessSDF(), c, m);
function (transform::SpecialLogAffine)(x::Number, y::Number)
    return (transform.c[1] + transform.m[1]*x, transform.c[2] + transform.m[2]*speciallogfunc(y))
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
function (box::BoxSDF)(t::Transform, x::Number, y::Number)
    x1, y1 = t(box.x1, box.y1);
    x2, y2 = t(box.x2, box.y2);
    xmid = 0.5(x1 + x2);
    ymid = 0.5(y1 + y2);
    return max( 2abs(x - xmid)/(x2 - x1), 2abs(y - ymid)/(y2 - y1) ) - 1;
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
    draw_graphic(o, g, t);
    try
        g.parts
    catch
        return
    end
    # (x+g.x*w), (y+g.y*h), (w*g.width), (h*g.height)

    # SHOULD BE IN A LET BLOCK
    [draw_graphic_traverse(o, p, 
        t(Affine((g.x, g.y), (g.width, g.height)))
        ) for p in g.parts]
end
function draw_graphic(o::GraphicsOutput, g::GraphicPart, t::Transform)
    throw(ErrorException(@sprintf("Draw graphic not implemented for type %s:%s",typeof(o),typeof(g))))
end
function (g_parent::GraphicPart)(g_child::GraphicPart)
    try
        g_parent.parts
    catch
        throw(ErrorException(@sprintf("Append graphic not implemented for type %s",typeof(g_child))))
    end

    push!(g_parent.parts, g_child)
    return g_child;
end










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