
function [datasets] = parse_dataset_input(dataset_or_sets)

    % Whether we've been passed one dataset or many, let's just process it
    %    as a cellarray of set(s) in the for loop.
    if iscell(dataset_or_sets)
        datasets = dataset_or_sets;
    else

        [s1,e1] = regexp(dataset_or_sets, "\$\(\d+-\d+\)"); % a-b
        [s2,e2] = regexp(dataset_or_sets, "\$\((\d+,)+\d+\)"); % a,b,c,d,e
        if contains(dataset_or_sets, "$(count)")

            db = Database();
            identifiers = string(split(dataset_or_sets,'/'));
            if length(identifiers) ~= 3
                error("Incorrectly formatted dataset input.");
            end
            reponame = identifiers(1);
            partname = identifiers(2);
            set_name = identifiers(3);
            count = length(dir(fullfile( db.repositories.(reponame), partname, strrep(set_name, "_$(count)", "_*") )));
            
            datasets = arrayfun( @(i) strrep(dataset_or_sets, "$(count)", string(i)), 1:count );
        elseif ~isempty(s1)
            hyphenrange = string(extractBetween(dataset_or_sets, s1+2,e1-1));
            hyphenrange = double(split(hyphenrange, "-"));
            datasets = arrayfun( @(i) sprintf("%s%05d", string(extractBetween(dataset_or_sets, 1,s1-1)), i), hyphenrange(1):hyphenrange(2) );
        elseif ~isempty(s2)
            commarange = string(extractBetween(dataset_or_sets, s2+2,e2-1));
            commarange = double(split(commarange, ","));
            datasets = arrayfun( @(i) sprintf("%s%05d", string(extractBetween(dataset_or_sets, 1,s2-1)), i), commarange );
        else
            datasets = {dataset_or_sets};
        end
    end


end