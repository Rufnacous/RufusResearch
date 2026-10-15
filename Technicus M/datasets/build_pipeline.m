function build_pipeline(yamlfile)
    db = Database();

    if ~exist("var","yamlfile")
        yamlfile = which("technicus.yaml");
        if isempty(yamlfile)
            error('technicus.yaml not found on the MATLAB path.');
        end
    end
    y = readyaml(yamlfile).database;


end