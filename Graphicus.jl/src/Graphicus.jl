module Graphicus
    using Printf, GR
    import Base.write, Base.getindex

    include("core.jl");
    include("graphics.jl");
    include("axis.jl");
    include("eps.jl");
    include("svg.jl");

    
function test_lims()
    
    fig = Graphic(1500, 1500);
    bx1 = fig(Box(0, 0, 1, 1));
    bx2 = bx1(Box(0.1, 0.2, 0.4, 0.2));
    ax = bx2(Axis());

    xs = rand(10) * 2pi; xs = sort(xs);
    ys = 1.5sin.(xs);
    sc = ax(Multiline(xs, ys, 2));

    ax.xlim = (0, 2)

    save_to_eps("example.eps", fig);

end

function test_polar()
    fig = Graphic(1000,1000);
    circ = fig( Circle(0.5,0.5, 0.5) );
    box = fig( Box(0,0,1.0,1.0));
    polar = circ(PolarAxis());
    # thetas = collect(LinRange(0, 2pi, 73));
    # rs = (0.5 * (sin.(thetas)) .^ 2) .+ 0.7;
    # scatter = polar(LineGraph(rs,thetas,2));

    inner_box = polar(Box( 0.3, pi/6, 0.5, pi/2) );
    inner_box.interpolated = 20;
    xs2 = rand(50);
    ys2 = rand(50);
    ax = inner_box(Axis());
    ax(Scatter(xs2,ys2,10));

    
    inner_box = fig(Box(0.2, 0.2, 0.2, 0.2) );
    inner_box.interpolated = 20;
    ax = inner_box(Axis());
    ax(Scatter(xs2,ys2,10));
    
    save_to_eps("example.eps", fig);
    return

end

function test_3d()
    fig = Graphic(1500, 1500);
    box = fig( Box(0.05, 0.05, 0.9, 0.9));

    xs = rand(2500) .- 0.5;
    ys = rand(2500) .- 0.5;
    zs = 5 * (xs .* ys);

    ax1 = box( Axis3D(0.25, 0.25, 1.0, 1.0));
    ax1.projection.scale = 0.1;
    ax1.projection.azimuth = 0;
    ax1(Scatter3D(xs,ys,zs));
    

    ax2 = box( Axis3D(0.25, 0.75, 1.0, 1.0));
    ax2.projection.scale = 0.1;
    ax2.projection.azimuth = pi / 6;
    ax2(Scatter3D(xs,ys,zs));
    

    ax3 = box( Axis3D(0.75, 0.25, 1.0, 1.0));
    ax3.projection.scale = 0.1;
    ax3.projection.azimuth = 2pi / 6;
    ax3(Scatter3D(xs,ys,zs));
    

    ax4 = box( Axis3D(0.75, 0.75, 1.0, 1.0));
    ax4.projection.scale = 0.1;
    ax4.projection.azimuth = 3pi / 6;
    ax4(Scatter3D(xs,ys,zs));

    save_to_eps("example.eps", fig);
    return


end

  

function superscatter_test()
    fig = Graphic(1500, 1500);
    box = fig( Box(0.05, 0.05, 0.9, 0.9));
    ax = box( Axis(0.0, 0.0, 1.0, 1.0));
    ax.xlim = (-pi,pi)
    ax.ylim = (-pi,pi)

    xs = 2pi*rand(20) .- pi;
    ys = sin.(xs);
    ss = ax(Scatter(xs, ys, SquarePoint(20, false)));

    xs = 2pi*rand(20) .- pi;
    ys = -0.5xs
    ss = ax(Scatter(xs, ys, TrianglePoint(20, true)));

    xs = 2pi*rand(20) .- pi;
    ys = 0.5xs
    ss = ax(Scatter(xs, ys, 20));

    xs = 2pi*rand(20) .- pi;
    ys = 0.5xs
    ss = ax(Scatter(xs, ys, 20));

    
    xs = sort(2pi*rand(20) .- pi);
    ys = cos.(xs)
    lg = ax(LineGraph(xs, ys, 2));
    
    save_to_eps("example.eps", fig);
    return
end

function svgtest()
    fig = Graphic(500, 250);
    box = fig( Box(0.01, 0.01, 0.98,0.98));
    ax = box( Axis(0.0, 0.0, 1.0, 1.0));
    ax.xlim = (-pi,pi)
    ax.ylim = (-1,1)
    xs = collect(LinRange(-pi, pi, 40));
    ys = sin.(xs);
    ax(Scatter(xs, ys, SquarePoint(5, true)));

    box(Text(0.5,0.5,"Text test",50,:center))
    
    save_to_svg("example.svg", fig);
    return
end




function superscatter_stresstest()
    fig = Graphic(1500, 1500);
    box = fig( Box(0.05, 0.05, 0.9, 0.9));
    ax = box( Axis(0.0, 0.0, 1.0, 1.0));
    ax.xlim = (-pi,pi)
    ax.ylim = (-pi,pi)
    add_axis_lines(ax)
    add_axis_ticks(ax)

    xs = 30rand(5) .- 15;
    ys = 30rand(5) .- 15;
    ss = ax(SuperScatter(
        xs, ys, 10.0, 10.0, []
    ));

    for i in eachindex(xs)
        box1 = ss(Box(-0.5,-0.5,1,1));
        ax1 = box1( Axis(0.0, 0.0, 1.0, 1.0));
        ax1.xlim = (0,2pi)
        ax1.ylim = (-1,1)
        add_axis_lines(ax1);
        ax1.xlim = (-pi,pi)
        ax1.ylim = (-pi,pi)

        xs1 = 30rand(2) .- 15;
        ys1 = 30rand(2) .- 15;
        ss1 = ax1(SuperScatter(
            xs1, ys1, 10.0, 10.0, []
        ));

        for j in eachindex(xs1)
            box2 = ss1(Box(-0.5,-0.5,1,1));
            ax2 = box2( Axis(0.0, 0.0, 1.0, 1.0));
            ax2.xlim = (-pi,pi)
            ax2.ylim = (-pi,pi)
    
            xs2 = 30rand(10) .- 15;
            ys2 = 30rand(10) .- 15;
            ss2 = ax2(Scatter(
                xs2, ys2
            ));
        end

    end
    

    save_to_eps("example.eps", fig);
    return
end



function schematic()
    fig = Graphic(2000,1000);
    box0 = fig(Box(0,0,1,1));
    margin = 15 / fig.height;
    box1 = fig( Box(fig.height*margin/fig.width, margin, (fig.height*(1-3margin)/2fig.width), (1-3margin)/2));
    box2 = fig( Box(fig.height*margin/fig.width, 2margin + (1-3margin)/2, box1.width, (1-3margin)/2));

    vertical_align!(box2(Text(0.5,0.5,"SUBJECT",50,:center)));
    vertical_align!(box1(Text(0.5,0.5,"FLUID",50,:center)));
    


    # ax = box( Axis(0.0, 0.0, 1.0, 1.0));
    # ax.xlim = (-pi,pi)
    # ax.ylim = (-pi,pi)

    # xs = 2pi*rand(20) .- pi;
    # ys = sin.(xs);
    # ss = ax(Scatter(xs, ys, SquarePoint(20, false)));

    # xs = 2pi*rand(20) .- pi;
    # ys = -0.5xs
    # ss = ax(Scatter(xs, ys, TrianglePoint(20, true)));

    # xs = 2pi*rand(20) .- pi;
    # ys = 0.5xs
    # ss = ax(Scatter(xs, ys, 20));

    # xs = 2pi*rand(20) .- pi;
    # ys = 0.5xs
    # ss = ax(Scatter(xs, ys, 20));

    
    # xs = sort(2pi*rand(20) .- pi);
    # ys = cos.(xs)
    # lg = ax(LineGraph(xs, ys, 2));
    
    save_to_eps("example.eps", fig);
    return
end

end # module Graphicus
