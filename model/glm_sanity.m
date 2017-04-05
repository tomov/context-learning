
sss = getGoodSubjects();
for glm = 89:97
    for subj = sss
        for run = 1:9
            multi = context_create_multi(glm, subj, run);
        end
    end
end

