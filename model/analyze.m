% TODO: take into account timeouts (plot 'em, then ignore 'em)
% plot correct answers somehow, perhaps as f'n of time 
%

subjects = 2;
roundsPerContext = 3; % = blocks per context = runs per context = runs / 3
trialsNReps = 5; % = trials per run / 4

contextRoles = {'irrelevant', 'modulatory', 'additive'};

format = '%s %s %s %d %s %s %s %d %d %s %s %s %f %d %s %s %d %d %d';

[participant, session, mriMode, isPractice, restaurantsReshuffled, foodsReshuffled, contextRole, contextId, cueId, sick, corrAns, response.keys, response.rt, response.corr, restaurant, food, isTrain, roundId, trialId] = ...
    textread('pilot.csv', format, 'delimiter', ',', 'headerlines', 1);

%% Simulate

human_correct = [];
model_correct = [];

model.keys = {}; % equivalent to response.keys but for the model (i.e. the responses)

for who = unique(participant)'
    for condition = unique(contextRole)'
        which_runs = strcmp(participant, who) & strcmp(contextRole, condition);
        runs = unique(roundId(which_runs))';
        for run = runs
            which_train = isTrain & roundId == run & which_runs;
            which_test = ~isTrain & roundId == run & which_runs;
            
            % For a given run of a given subject, run the model on the same
            % sequence of stimuli and see what it does.
            %
            cues = cueId(which_train);
            N = length(cues); % # of trials
            D = 3; % # of stimuli
            x = zeros(N, D);
            x(sub2ind(size(x), 1:N, cues' + 1)) = 1;
            c = contextId(which_train) + 1;
            r = strcmp(sick(which_train), 'Yes');
            [choices, P_n, ww_n, P, ww] = train(x, c, r, false);
            model_choices = choices > 0.5;
            model_response_keys = {};
            model_response_keys(model_choices) = {'left'};
            model_response_keys(~model_choices) = {'right'};
            model.keys(which_train) = model_response_keys;
            
            % Get the subject's responses too.
            %
            resp = response.keys(which_train);
            human_choices = strcmp(resp, 'left'); % sick == 1
            
            % Keep track of correct responses
            %
            human_correct = [human_correct; (human_choices == r)'];
            model_correct = [model_correct; (model_choices == r)'];
        end
    end
end

model.keys = model.keys';

% Slice and dice the data
%

human_correct = [];
model_correct = [];

for n = 1:N
    which = isTrain & trialId == n;
    
    human_corr_n = strcmp(response.keys(which), corrAns(which));
    model_corr_n = strcmp(model.keys(which), corrAns(which));
    human_correct = [human_correct mean(human_corr_n)];
    model_correct = [model_correct mean(model_corr_n)];
end


figure;
plot(model_correct, 'o-', 'LineWidth', 2);
hold on;
plot(human_correct, 'o-', 'LineWidth', 2);
hold off;
legend({'model', 'subject'});

title('Per-trial accuracy');
xlabel('trial #');
ylabel('accuracy');


%{

sick = strcmp(response.keys, 'left');
notsick = strcmp(response.keys, 'right');
timeout = strcmp(response.keys, 'None');
assert(sum(sick) + sum(timeout) + sum(notsick) == length(sick));

sickCorr = strcmp(corrAns, 'left');
notsickCorr = strcmp(corrAns, 'right');
noCorr = strcmp(corrAns, 'None');
assert(sum(sickCorr) + sum(noCorr) + sum(notsickCorr) == length(sick));
%assert(sum(noCorr) == 4 * roundsPerContext * length(contexts));
assert(sum(noCorr(isTrain == 1)) == 0);


figure;

%% Outcome probabilities training phase

Ms = [];
SEMs = [];
for context = contexts
    x1c1 = sickCorr(isTrain == 1 & strcmp(contextRole, context) & cueId == 0 & contextId == 0);
    x1c2 = sickCorr(isTrain == 1 & strcmp(contextRole, context) & cueId == 0 & contextId == 1);
    x2c1 = sickCorr(isTrain == 1 & strcmp(contextRole, context) & cueId == 1 & contextId == 0);
    x2c2 = sickCorr(isTrain == 1 & strcmp(contextRole, context) & cueId == 1 & contextId == 1);

    assert(length(x1c1) == roundsPerContext * trialsNReps * subjects);
    assert(length(x1c2) == roundsPerContext * trialsNReps * subjects);
    assert(length(x2c1) == roundsPerContext * trialsNReps * subjects);
    assert(length(x2c2) == roundsPerContext * trialsNReps * subjects);

    M = mean([x1c1 x1c2 x2c1 x2c2]);
    SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end

subplot(2, 3, 1);

barweb(Ms, SEMs, 1, contexts, 'Outcome probabilities in training phase');
ylabel('Sick probability');
legend({'x_1c_1', 'x_1c_2', 'x_2c_1', 'x_2c_2'});




%% Sick probabilities in training phase

Ms = [];
SEMs = [];
for context = contexts
    x1c1 = sick(isTrain == 1 & strcmp(contextRole, context) & cueId == 0 & contextId == 0);
    x1c2 = sick(isTrain == 1 & strcmp(contextRole, context) & cueId == 0 & contextId == 1);
    x2c1 = sick(isTrain == 1 & strcmp(contextRole, context) & cueId == 1 & contextId == 0);
    x2c2 = sick(isTrain == 1 & strcmp(contextRole, context) & cueId == 1 & contextId == 1);

    assert(length(x1c1) == roundsPerContext * trialsNReps * subjects);
    assert(length(x1c2) == roundsPerContext * trialsNReps * subjects);
    assert(length(x2c1) == roundsPerContext * trialsNReps * subjects);
    assert(length(x2c2) == roundsPerContext * trialsNReps * subjects);

    M = mean([x1c1 x1c2 x2c1 x2c2]);
    SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end

subplot(2, 3, 2);

barweb(Ms, SEMs, 1, contexts, 'Choice probabilities in training phase');
ylabel('Sick probability');
legend({'x_1c_1', 'x_1c_2', 'x_2c_1', 'x_2c_2'});




%% Not sick probabilities in training phase

Ms = [];
SEMs = [];
for context = contexts
    x1c1 = notsick(isTrain == 1 & strcmp(contextRole, context) & cueId == 0 & contextId == 0);
    x1c2 = notsick(isTrain == 1 & strcmp(contextRole, context) & cueId == 0 & contextId == 1);
    x2c1 = notsick(isTrain == 1 & strcmp(contextRole, context) & cueId == 1 & contextId == 0);
    x2c2 = notsick(isTrain == 1 & strcmp(contextRole, context) & cueId == 1 & contextId == 1);

    assert(length(x1c1) == roundsPerContext * trialsNReps * subjects);
    assert(length(x1c2) == roundsPerContext * trialsNReps * subjects);
    assert(length(x2c1) == roundsPerContext * trialsNReps * subjects);
    assert(length(x2c2) == roundsPerContext * trialsNReps * subjects);

    M = mean([x1c1 x1c2 x2c1 x2c2]);
    SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end

subplot(2, 3, 3);

barweb(Ms, SEMs, 1, contexts, 'Choice probabilities in training phase');
ylabel('Not sick probability');
legend({'x_1c_1', 'x_1c_2', 'x_2c_1', 'x_2c_2'});






%% Sick probabilities in test phase
% This is the final figure we care about

Ms = [];
SEMs = [];
for context = contexts
    x1c1 = sick(isTrain == 0 & strcmp(contextRole, context) & cueId == 0 & contextId == 0);
    x1c2 = sick(isTrain == 0 & strcmp(contextRole, context) & cueId == 0 & contextId == 2);
    x2c1 = sick(isTrain == 0 & strcmp(contextRole, context) & cueId == 2 & contextId == 0);
    x2c2 = sick(isTrain == 0 & strcmp(contextRole, context) & cueId == 2 & contextId == 2);

    assert(length(x1c1) == roundsPerContext * subjects);
    assert(length(x1c2) == roundsPerContext * subjects);
    assert(length(x2c1) == roundsPerContext * subjects);
    assert(length(x2c2) == roundsPerContext * subjects);

    M = mean([x1c1 x1c2 x2c1 x2c2]);
    SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
%    M = [mean(x1c1) mean(x1c2) mean(x2c1) mean(x2c2)];
%    SEM = [std(x1c1) / sqrt(length(x1c1)) std(x1c2) / sqrt(length(x1c2)) std(x2c1) / sqrt(length(x2c1)) std(x2c2) / sqrt(length(x2c2))];
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end
    
subplot(2, 3, 4);

barweb(Ms, SEMs, 1, contexts, 'Choice probabilities in test phase');
ylabel('Sick probability');
legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'});





%% Not sick in test phase

Ms = [];
SEMs = [];
for context = contexts
    x1c1 = notsick(isTrain == 0 & strcmp(contextRole, context) & cueId == 0 & contextId == 0);
    x1c2 = notsick(isTrain == 0 & strcmp(contextRole, context) & cueId == 0 & contextId == 2);
    x2c1 = notsick(isTrain == 0 & strcmp(contextRole, context) & cueId == 2 & contextId == 0);
    x2c2 = notsick(isTrain == 0 & strcmp(contextRole, context) & cueId == 2 & contextId == 2);

    assert(length(x1c1) == roundsPerContext * subjects);
    assert(length(x1c2) == roundsPerContext * subjects);
    assert(length(x2c1) == roundsPerContext * subjects);
    assert(length(x2c2) == roundsPerContext * subjects);

    M = mean([x1c1 x1c2 x2c1 x2c2]);
    SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
%    M = [mean(x1c1) mean(x1c2) mean(x2c1) mean(x2c2)];
%    SEM = [std(x1c1) / sqrt(length(x1c1)) std(x1c2) / sqrt(length(x1c2)) std(x2c1) / sqrt(length(x2c1)) std(x2c2) / sqrt(length(x2c2))];
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end
    
subplot(2, 3, 5);

barweb(Ms, SEMs, 1, contexts, 'Choice probabilities in test phase');
ylabel('Not sick probability');
legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'});

%}