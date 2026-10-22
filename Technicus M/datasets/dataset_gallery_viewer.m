function dataset_gallery_viewer(filepathprefix, imgname)

    dirmatches = dir(sprintf("%s*", filepathprefix));
    imgs = {};
    for i = 1:length(dirmatches)
        match = fullfile(dirmatches(i).folder, dirmatches(i).name);

        if isfile(fullfile(match, imgname))
            imgs{end+1} = imread(fullfile(match, imgname));
        end
        fprintf("%s\n", match);
    end
    
    fig = uifigure("Name",sprintf("Gallery of %s", imgname));
    
    g = uigridlayout(fig, [2,1]);
    g.RowHeight = {'5x', '1x'};
    g.ColumnWidth = {'1x'};
    
    p1 = uipanel(g);
    p1.Layout.Row = 1;
    p1.Layout.Column = 1;
    p1_inner = uigridlayout(p1, [1,1], 'Padding', 0);
    
    p2 = uipanel(g);
    p2.Layout.Row = 2;
    p2.Layout.Column = 1;
    p2_inner = uigridlayout(p2, [1,1], 'Padding', 0);
    
    ui_im = uiimage(p1_inner, "ImageSource",imgs{1});
    
    sld = uislider(p2_inner,"Limits",[1 length(imgs)],"Step",1,"ValueChangingFcn",@(src,event)updateGauge(event,ui_im, imgs),"MajorTicks",1:length(imgs));

    
end


function updateGauge(event,ui_im, imgs)
    
    ui_im.ImageSource = imgs{event.Value(1)};
    
end
