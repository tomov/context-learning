
    behav = getBehavMaster(subj,run,0);
    count=1;
    tempOnsets{count} = [];

    % calculate mean reward
    meanReward = mean(behav.reward);
    %meanReward = median(behav.reward);

    % toggle between different input General Linear Models
    switch glmodel
        % GLM == 1
        case 1


            % --- Stimulus Event --- %

            tempOnsets{count} = [];

            % populate onsets array
            % for each trial
            for i = 1:length(behav.isImagine)

                switch behav.isImagine(i)

                    % terminal state A: i.e., subject didn't make any decisions
                    case 1001
                        % do nothing...
                    % terminal state B,C: i.e., subj made 1 decision but not 2
                    case or(1002,1003)
                        % do nothing...
                    % a regular RL trial, not imagined
                    case 0
                      % append onsets for first decision (-8 sec) and second
%                         % decision (-4 seconds) based on trial end
                        tempOnsets{count} = cat(1,tempOnsets{count},behav.seconds(i)-8,behav.seconds(i)-4);
                    % imagined trial
                    case 1
                        % need to do something here eventually... first
                        % figure out corresponding onset time
                    otherwise
                        % error!
                end

%                     % if it's not an imagined trial
%                     if (behav.isImagine(i)==0)
%                         % append onsets for first decision (-8 sec) and second
%                         % decision (-4 seconds) based on trial end
%                         tempOnsets{count} = cat(1,tempOnsets{count},behav.seconds(i)-8,behav.seconds(i)-4);
%                     end
            end

            % if the onsets aren't empty, then let's store this event
            if (~isempty(tempOnsets{count}))
                names{count} = 'RL_STIM';
                onsets{count} = tempOnsets{count};
                durations{count} = ones(1,length(onsets{count}))*2.5;
                count=count+1;
            end

            tempOnsets{count} = [];

            % --- Positive Reward --- %

            % populate onsets
            % for each trial
            for i = 1:length(behav.reward)
                % if reward is positive
                if ((behav.reward(i)>meanReward) && (behav.isImagine(i)<1000))
                    % then append seconds -1.5 from end of trial
                    tempOnsets{count}=cat(1,tempOnsets{count},behav.seconds(i)-1.5);
                end
            end

            if (~isempty(tempOnsets{count}))
                names{count} = 'RL_POS_REW';
                onsets{count} = tempOnsets{count};
                % duration = 1.5 sec
                durations{count} = ones(1,length(onsets{count}))*1.5;
                count=count+1;
            end

            tempOnsets{count} = [];

            % --- Negative Reward --- %

            % populate onsets
            % for each trial
            for i = 1:length(behav.reward)
                % if reward is positive
                if ((behav.reward(i)<meanReward) && (behav.isImagine(i)<1000))
                    % then append seconds -1.5 from end of trial
                    tempOnsets{count}=cat(1,tempOnsets{count},behav.seconds(i)-1.5);
                end
            end

            if (~isempty(tempOnsets{count}))
                names{count} = 'RL_NEG_REW';
                onsets{count} = tempOnsets{count};
                % duration = 1.5 sec
                durations{count} = ones(1,length(onsets{count}))*1.5;
                count=count+1;
            end

            tempOnsets{count} = [];

            % --- Optimal path --- %
            % for first RL trial immediately following imagined,
            % did they choose optimal path?


            % populate onsets
            % for each trial (note: first five should always be RL)
            % start index at three because it needs looking retrospectively
            for i = 3:length(behav.optimal)
                % if previous trial was imagined
                if ((behav.isImagine(i-1)==1) && (behav.isImagine(i)<1000))
                    % and if current trial was optimal
                    if (behav.optimal(i)==1)
                        % then append onset, which is sum of:
                        % (1) the seconds at the end of the RL trial before the
                        % imagined trial (that is, i-2) and (2) the jitter at the end of
                        % that same RL trial (i.e., begin of imagine trial)
                        tempOnsets{count} = cat(1,tempOnsets{count},behav.seconds(i-2)+behav.jitter(i-2));
                    end
                end
            end

            if (~isempty(tempOnsets{count}))
                names{count} = 'IM_OPT';
                onsets{count} = tempOnsets{count};
                % duration = 4 sec
                durations{count} = ones(1,length(onsets{count}))*4;
                count=count+1;
            end

            tempOnsets{count} = [];

            % --- Imagined path --- %
            % for first RL trial immediately following imagined,
            % did they choose imagined path?

            % populate onsets
            % for each trial (note: first five should always be RL)
            % start index at three because it needs looking retrospectively
            for i = 3:length(behav.imagined)
                % if previous trial was imagined
                if ((behav.isImagine(i-1)==1) && (behav.isImagine(i)<1000))
                    % and if current trial was optimal
                    if (behav.imagined(i)==1)
                        % then append onset, which is sum of:
                        % (1) the seconds at the end of the RL trial before the
                        % imagined trial (that is, i-2) and (2) the jitter at the end of
                        % that same RL trial (i.e., start of imagine trial)
                        tempOnsets{count} = cat(1,tempOnsets{count},behav.seconds(i-2)+behav.jitter(i-2));
                    end
                end
            end


            if (~isempty(tempOnsets{count}))
                names{count} = 'IM_IMAG';
                onsets{count} = tempOnsets{count};
                % duration = 4 sec
                durations{count} = ones(1,length(onsets{count}))*4;
                count=count+1;
            end

            tempOnsets{count} = [];

            % --- Other path --- %
            % for first RL trial immediately following imagined,
            % did they choose other path? (i.e., not optial, imagined)

            % populate onsets
            % for each trial (note: first five should always be RL)
            % start index at three because it needs looking retrospectively
            for i = 3:length(behav.other)
                % if previous trial was imagined
                if ((behav.isImagine(i-1)==1) && (behav.isImagine(i)<1000))
                    % and if current trial was optimal
                    if (behav.other(i)==1)
                        % then append onset, which is sum of:
                        % (1) the seconds at the end of the RL trial before the
                        % imagined trial (that is, i-2) and (2) the jitter at the end of
                        % that same RL trial (i.e., start of imagine trial)
                        tempOnsets{count} = cat(1,tempOnsets{count},behav.seconds(i-2)+behav.jitter(i-2));
                    end
                end
            end

            if (~isempty(tempOnsets{count}))
                names{count} = 'IM_OTHER';
                onsets{count} = tempOnsets{count};
                % duration = 4 sec
                durations{count} = ones(1,length(onsets{count}))*4;
                count=count+1;
            end

            % create the multi structure

            multi.names = names;
            multi.onsets = onsets;
            multi.durations = durations;
    end

