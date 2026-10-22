function dataset_gallery_viewer(filepathprefix, varargin)

    imgnames = {};
    for i = 1:numel(varargin)
        imgnames{i} = varargin{i};
    end


    dirmatches = dir(sprintf("%s*", filepathprefix));
    imgsets = {};
    for i = 1:length(dirmatches)
        match = fullfile(dirmatches(i).folder, dirmatches(i).name);
        imgs = {};
        for j = 1:length(imgnames)
            imgname = imgnames{j};
            if isfile(fullfile(match, imgname))
                imgs{end+1} = imread(fullfile(match, imgname));
            end
            fprintf("%s\n", match);
        end
        imgsets{i} = imgs;
    end
    
    fig = uifigure("Name","Gallery");
    
    g = uigridlayout(fig, [2,1]);
    g.RowHeight = {'5x', '1x', '1x'};
    g.ColumnWidth = {'1x'};
    
    p1 = uipanel(g);
    p1.Layout.Row = 1;
    p1.Layout.Column = 1;
    p1_inner = uigridlayout(p1, [1,1], 'Padding', 0);
    
    p2 = uipanel(g);
    p2.Layout.Row = 2;
    p2.Layout.Column = 1;
    p2_inner = uigridlayout(p2, [1,1], 'Padding', 0);
    
    p3 = uipanel(g);
    p3.Layout.Row = 3;
    p3.Layout.Column = 1;
    p3_inner = uigridlayout(p3, [1,1], 'Padding', 0);
    
    imgset1 = imgsets{1};
    ui_im = uiimage(p1_inner, "ImageSource",imgset1{1});
    
    setappdata(fig, 'slidervalue', 1);
    setappdata(fig, 'imgset', 1)
    sld = uislider(p2_inner,"Limits",[1 length(dirmatches)],"Step",1,"ValueChangingFcn",@(src,event)updateGauge(fig, event,ui_im, imgsets),"MajorTicks",1:length(dirmatches));


    t = uigridlayout(p3_inner, [1,numel(imgnames)]);
    %g.RowHeight = {'1x'};
    %g.ColumnWidth = {'1x'};
    for i = 1:numel(imgnames)

        pt = uipanel(t);
        pt.Layout.Row = 1;
        pt.Layout.Column = i;
        pt_inner = uigridlayout(pt, [1,1], 'Padding', 0);

        uibutton(pt_inner, "Text", imgnames{i}, "ButtonPushedFcn", @(src,event) updateBtn(fig, event, ui_im, imgsets, i));
    end

end


function updateGauge(fig, event,ui_im, imgsets)

    setappdata(fig, 'slidervalue', event.Value(1));

    imgset = imgsets{getappdata(fig, 'slidervalue')};

    ui_im.ImageSource = imgset{getappdata(fig, 'imgset')};
    
end

function updateBtn(fig, event, ui_im, imgsets, i)
    setappdata(fig, 'imgset', i);
    
    imgset = imgsets{getappdata(fig, 'slidervalue')};

    ui_im.ImageSource = imgset{getappdata(fig, 'imgset')};
end