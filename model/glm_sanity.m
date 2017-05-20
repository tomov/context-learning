
sss = getGoodSubjects();
for glm = 124:124
    for subj = sss  %sss
        for run = 1:9 %  1:9
            multi = context_create_multi(glm, subj, run);
        end
    end
end

