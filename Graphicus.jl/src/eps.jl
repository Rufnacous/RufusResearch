struct EPS_File <: GraphicsOutput
    stream::IOStream
end
write(f::EPS_File, args...; kwargs...) = write(f.stream, args...; kwargs...);
function save_to_eps(filepath::String, g::Graphic)
    fontpfa = read_pfa_file("../Graphicus.jl/cmunorm.pfa");
    
    open(filepath, "w") do file
        epsfile = EPS_File(file);
        write(file, "%%!PS-Adobe-3.0 EPSF-3.0\n");
        write(file, @sprintf("%%%%BoundingBox: 0 0 %.2f %.2f\n", g.width, g.height));
        write(file, @sprintf("%%%%PageBoundingBox: 0 0 %.2f %.2f\n\n", g.width, g.height));
        # write(file, "/Times-Roman findfont 48 scalefont setfont\n");

        write(file, @sprintf("%%%%BeginResource: font CMUSerif-Bold\n%s\n%%%%EndResource\n", fontpfa));

        write(file, "/CMUConcrete-Roman findfont 48 scalefont setfont\n");

        
        write(file, "newpath\n")
        write(file, @sprintf("%.2f %.2f moveto\n", 0, 0))
        write(file, @sprintf("%.2f %.2f lineto\n", g.width, 0))
        write(file, @sprintf("%.2f %.2f lineto\n", g.width, g.height))
        write(file, @sprintf("%.2f %.2f lineto\n", 0, g.height))
        write(file, "closepath\nclip\ngsave\n\n0 0 0 setrgbcolor\n\n")

        draw_graphic_traverse(epsfile, g, Identity()); #0, 0, 1, 1
    end

    return
end

function read_pfa_file(filepath::String)::String
    # Open the file and read its contents
    open(filepath, "r") do file
        return read(file, String)
    end
end

function draw_multiline(file::EPS_File, xys::Vector{Tuple{N, N}}, linewidth::Number, color::Tuple{Number, Number, Number}; filled::Bool=false, linestyle::Symbol=:solid) where N <: Number
    write(file, @sprintf("%.2f %.2f %.2f setrgbcolor\n",color...))
    write(file, @sprintf("%.2f setlinewidth\n",linewidth))
    if linestyle == :dashed
        write(file, "[10 5] 0 setdash\n");
    end
    write(file, "newpath\n");
    write(file, @sprintf("%.2f %.2f moveto\n", xys[1][1], xys[1][2]));
    for i = 2:length(xys)
        write(file, @sprintf("%.2f %.2f lineto\n", xys[i][1], xys[i][2]));
    end
    if filled
        write(file, "fill\n")
    end
    write(file, "stroke\n")
    if linestyle != :solid
        write(file, "[] 0 setdash\n");
    end
end

function draw_point(file::EPS_File, xy::Tuple{N, N}, pointsize::Number; filled::Bool=true) where N <: Number
    write(file, @sprintf("newpath\n%.2f %.2f %.2f 0 360 arc\nclosepath\n",xy[1],xy[2],pointsize));
    if filled
        write(file,"fill\n");
    end
    write(file,"stroke\n");
end

function draw_text(file::EPS_File, xy::Tuple{N, N}, text::String, fontsize::Number, alignment::Symbol, rotation::Number) where N <: Number
    write(file, @sprintf("/CMUConcrete-Roman findfont %.2f scalefont setfont\n",fontsize));
    write(file, "gsave\n");
    write(file, @sprintf("%.2f %.2f translate\n%.2f rotate\n",xy[1],xy[2],rotation));
    if alignment == :center
        write(file, @sprintf("(%s) stringwidth pop\n2 div neg 0 translate\n", text))
    end
    write(file, @sprintf("0 0 moveto\n(%s) show\n",text))
    write(file, "grestore\n")
end