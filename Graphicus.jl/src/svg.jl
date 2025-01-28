struct SVG_File <: GraphicsOutput
    stream::IOStream
end
write(f::SVG_File, args...; kwargs...) = write(f.stream, args...; kwargs...);
function save_to_svg(filepath::String, g::Graphic)
    # fontpfa = read_pfa_file("../Graphicus.jl/fonts/cmunorm.pfa");
    
    open(filepath, "w") do file
        svgfile = SVG_File(file);

        # write(file, @sprintf("<svg height=\"%.2f\" width=\"%.2f\">",g.width, g.height ))
        @writesprintf(file, "<svg height=\"%.2f\" width=\"%.2f\" xmlns=\"http://www.w3.org/2000/svg\">\n", g.height, g.width);

        # # write(file, "/Times-Roman findfont 48 scalefont setfont\n");
        # @writesprintf(file, "%%%%BeginResource: font CMUSerif-Bold\n%s\n%%%%EndResource\n", fontpfa)
        # write(file, "/CMUConcrete-Roman findfont 48 scalefont setfont\n");
        draw_graphic_traverse(svgfile, g, Identity()); #0, 0, 1, 1

        
        write(file,"</svg>")
    end

    return
end

function draw_multiline(file::SVG_File, xys::Vector{Tuple{N, N}}, linewidth::Number, color::Tuple{Number, Number, Number}; filled::Bool=false, linestyle::Symbol=:solid) where N <: Number

    write(file, "<polyline points=\"");
    @writesprintf(file, "%.2f,%.2f", xys[1][1], xys[1][2])
    for i = 2:length(xys)
        @writesprintf(file, " %.2f,%.2f", xys[i][1], xys[i][2])
    end
    color_string = @sprintf("rgb(%.2f,%.2f,%.2f)", color...);
    fill = "none"
    if filled
        fill = color_string;
    end
    dasharray = "";
    if linestyle == :dashed
        dasharray = @sprintf("%d,%d",2linewidth,2linewidth);
    end
    @writesprintf(file, "\" style=\"fill:%s;stroke:%s;stroke-width:%.2f;stroke-dasharray:%s\"/>\n",fill,color_string,linewidth,dasharray)

end


function draw_point(file::SVG_File, xy::Tuple{N, N}, pointsize::Number; filled::Bool=true) where N <: Number
    radius = pointsize / 2  # SVG uses the radius for circles
    if filled
        write(file, @sprintf("<circle cx=\"%.2f\" cy=\"%.2f\" r=\"%.2f\" fill=\"black\" />\n", xy[1], xy[2], radius))
    else
        write(file, @sprintf("<circle cx=\"%.2f\" cy=\"%.2f\" r=\"%.2f\" fill=\"none\" stroke=\"black\" />\n", xy[1], xy[2], radius))
    end
end

function draw_text(file::SVG_File, xy::Tuple{N, N}, text::String, fontsize::Number, alignment::Symbol, rotation::Number) where N <: Number
    write(file, @sprintf("<text x=\"%.2f\" y=\"%.2f\" fill=\"black\">%s</text>",xy[1],xy[2],text))

    # @writesprintf(file, "/CMUConcrete-Roman findfont %.2f scalefont setfont\n",fontsize)
    # write(file, "gsave\n");
    # @writesprintf(file, "%.2f %.2f translate\n%.2f rotate\n",xy[1],xy[2],rotation)
    # if alignment == :center
    #     write(file, @sprintf("(%s) stringwidth pop\n2 div neg 0 translate\n", text))
    # end
    # write(file, @sprintf("0 0 moveto\n(%s) show\n",text))
    # write(file, "grestore\n")
    return
end