function download_from_across(filepathprefix, imgname)

    [~,basename,extension] = fileparts(imgname);

    dirmatches = dir(sprintf("%s*", filepathprefix));
    
    [file,location] = uiputfile(imgname);

    for i = 1:length(dirmatches)
        match = fullfile(dirmatches(i).folder, dirmatches(i).name);

        if isfile(fullfile(match, imgname))
            newimgname = sprintf("%s_%05d%s", basename, i,extension);
            copyfile(fullfile(match, imgname), fullfile(location, newimgname))
        end
    end
    
    

    
end

