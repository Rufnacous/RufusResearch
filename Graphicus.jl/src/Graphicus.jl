module Graphicus
    using Printf, GR, EzXML, ForwardDiff, LinearAlgebra
    import Base.write, Base.getindex

    include("core.jl");
    include("interp.jl");
    include("graphics.jl");
    include("axis.jl");
    include("eps.jl");
    include("svg.jl");

    export Graphic, Box, Axis, LogAxis, Scatter, LineGraph;
    export save_to_eps, save_to_svg;

    function contourtest()
        fig = Graphic(1000,1000);

        xs = collect(LinRange(0,1, 10));
        ys = collect(LinRange(0,1, 10));
        data = zeros(length(xs), length(ys))
        for xi in eachindex(xs)
            for yi in eachindex(ys)
                data[xi,yi] = (xs[xi] ^ 2)  * (ys[yi])
            end
        end

        ax = fig(Axis(0.1,0.1,0.8,0.8))

        ax(ContourMarchingSquares(xs, ys, data, -0.9:0.2:0.9))

        
        save_to_svg("contour.svg", fig);


        
        fig = Graphic(1000,1000);

        ax = fig(Axis(0.1,0.1,0.8,0.8))

        ax(Heatmap(xs, ys, data))

        
        save_to_svg("heatmap.svg", fig);
    end
    

    function svgtest()
        box1 = Box(0.0, 0.0, 1.0, 1.0);
        
        ax = box1( Axis(0.0, 0.0, 1.0, 1.0));
        ax.xlim = (-pi,pi)
        ax.ylim = (-1.2,1.2)
        xs = collect(LinRange(-pi, pi, 40));
        ys = sin.(xs);
        ax(Scatter(xs, ys, SquarePoint(1, true)));

        box1(Text(0.5,0.5,"Text test",10,:center))


        
        box2 = Box(0.0, 0.0, 1.0, 1.0);
        
        ax = box2( Axis(0.0, 0.0, 1.0, 1.0));
        ax.xlim = (-pi,pi)
        ax.ylim = (-1.2,1.2)
        xs = collect(LinRange(-pi, pi, 40));
        ys = cos.(xs);
        ax(Scatter(xs, ys, SquarePoint(1, true)));

        box2(Text(0.5,0.5,"Test 2",10,:center))


        
        embed_in_svg("example.svg","C:/Users/PhD/Downloads/drawing.svg",[box1,box2])
        return
    end



end # module Graphicus
