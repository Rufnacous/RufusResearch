struct SVG_File <: GraphicsOutput
    stream::IO
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
        draw_graphic_traverse(svgfile, g, UpsideDown(g.height)); #0, 0, 1, 1

        
        write(file,"</svg>")
    end

    return
end

function embed_in_svg(filepath::String, templatepath::String, gs::AbstractArray{G}) where G <: GraphicPart

    template = EzXML.readxml(templatepath)

    docwidth, docheight = parse.(Float64, split(template.root["viewBox"]))[3:4]


    for (gi, g) in enumerate(gs)

        target_rect = findfirst(@sprintf("//x:rect[@id='graphicus_%d']",gi), template.root, ["x"=>namespace(template.root)])
        inner_svg = SVG_File(IOBuffer())
        
        x = parse(Float64, target_rect["x"])
        y = parse(Float64, target_rect["y"])
        w = parse(Float64, target_rect["width"])
        h = parse(Float64, target_rect["height"])
        
        rect_box = BorderlessBox(x,y, w, h);
        rect_box(g)
        draw_graphic_traverse(inner_svg, rect_box, Identity());

        seekstart(inner_svg.stream)
        new_node_string = String(take!(inner_svg.stream))
        new_node = EzXML.readxml(IOBuffer(new_node_string)).root
        EzXML.unlink!(new_node)
        EzXML.linkprev!(target_rect,new_node)
        EzXML.unlink!(target_rect)

    end

    
    open(filepath, "w") do file
        EzXML.prettyprint(file, template)
    end
end

function draw_group_start(file::SVG_File)
    write(file, "<g>");
end
function draw_group_end(file::SVG_File)
    write(file, "</g>");
end

function draw_multiline(file::SVG_File, xys::AbstractArray{Tuple{N, N1}}, linewidth::Number, color::Tuple{Number, Number, Number}; filled::Bool=false, linestyle::Symbol=:solid) where N <: Number where N1 <: Number

    write(file, "<polyline points=\"");
    @writesprintf(file, "%.2f,%.2f", xys[1][1], xys[1][2])
    for i = 2:length(xys)
        @writesprintf(file, " %.2f,%.2f", xys[i][1], xys[i][2])
    end
    color_string = @sprintf("rgb(%.2f,%.2f,%.2f)", (255 .* color)...);
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
function draw_multiline(file::SVG_File, xys::AbstractArray, linewidth::Number, color::AbstractArray; filled::Bool=false, linestyle::Symbol=:solid, gradient=:horizontal) 
    # for seg_i in 1:length(color)-1
    #     meancolor = (color[seg_i] .+ color[seg_i+1]) ./ 2
    #     draw_multiline(file, xys[seg_i:seg_i+1], linewidth, meancolor, filled=filled, linestyle=linestyle)
    # end

    # stop_percents = cumsum([0.0; hypot.(diff(first.(xys)), diff(last.(xys)))])
    # stop_percents .*=  100 / last(stop_percents)

    defid = abs(rand(Int64));

    if gradient == :horizontal
        stop_percents = first.(xys) .- minimum(first.(xys))
        stop_percents = 100stop_percents ./ maximum(stop_percents)
        write(file, "<defs><linearGradient id=\"def$defid\" x1=\"0%\" y1=\"0%\" x2=\"100%\" y2=\"0%\">")
    else
        stop_percents = last.(xys) .- minimum(last.(xys))
        stop_percents = 100stop_percents ./ maximum(stop_percents)
        write(file, "<defs><linearGradient id=\"def$defid\" x1=\"0%\" y1=\"0%\" x2=\"0%\" y2=\"100%\">")
    end
    for i in eachindex(stop_percents)
        color_string = @sprintf("rgb(%.2f,%.2f,%.2f)", (255 .* color[i])...);
        @writesprintf(file, "<stop offset=\"%d%%\" style=\"stop-color:%s;\"/>",stop_percents[i],color_string)
    end
    write(file, "</linearGradient></defs>")



    write(file, "<polyline points=\"");
    @writesprintf(file, "%.2f,%.2f", xys[1][1], xys[1][2])
    for i = 2:length(xys)
        @writesprintf(file, " %.2f,%.2f", xys[i][1], xys[i][2])
    end
    dasharray = "";
    if linestyle == :dashed
        dasharray = @sprintf("%d,%d",2linewidth,2linewidth);
    end
    @writesprintf(file, "\" style=\"stroke-width:%.2f;stroke-dasharray:%s\" fill=\"none\" stroke=\"url(#def%d)\"/>\n",linewidth,dasharray,defid)


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
    xalign = 0;
    if alignment == :center
        xalign = -15;
    end
    write(file, @sprintf("<text x=\"%.2f\" y=\"%.2f\" dx=\"%.2f\" fill=\"black\" font-size=\"%.2f\" style=\"font-family:'CMU Serif'\">%s</text>",xy[1],xy[2],xalign,fontsize,text))

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