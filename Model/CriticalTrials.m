% This script is going to look for critical trials

subjMarkers = getSubjMarkers(id);
numSubjects = length(subjMarkers);

countLowProbs = 0;
countCrits = 0;
distance = [];
distance_cutoff = 1;

% The important data
lowProbRewards = []; % reward from low-prob transition trial
relativeValues = []; % true value of the critical option  - true value of other option (in critical trial)
choices = []; % the actual choice made in critical trial (0 = didn't choose critical option, 1 = chose critical option)

% Loop through subjects
for thisSubj = 1:numSubjects
    subjID = id(subjMarkers(thisSubj));
    % Are we not tossing this person?  Is this person not already done?
    if ~any(tosslist == subjID)
        % Get the appropriate index
        if thisSubj < length(subjMarkers)
            index = subjMarkers(thisSubj):(subjMarkers(thisSubj + 1) - 1);
        else
            index = subjMarkers(thisSubj):length(id);
        end
        
        % Walk through rounds
        for thisRound = index
            % Criteria for unusual transition:
            %   (1) Low probability
            %   (2) Can't have been a 5
            %   (3) Must be to a different goal (i.e. can't be from 1 to 3
            %       in a color trial)
            if (Action(thisRound) ~= (S2(thisRound)-1)) && (Action(thisRound) ~= 5) && (features(Action(thisRound)+1,Type(thisRound)) ~= features(S2(thisRound),Type(thisRound)))
                
                % Updat the count
                countLowProbs = countLowProbs + 1;
                
                % Get the critical info
                
                % What's the critical option for the critical trial? It
                %   should be the same goal option, but a different
                %   symbol, as the action chosen in the low-prob transition
                if Type(thisRound) == 1 % shape trial
                    if Action(thisRound) == 1 % square
                        critOption = 2;
                    elseif Action(thisRound) == 2 % square
                        critOption = 1;
                    elseif Action(thisRound) == 3 % circle
                        critOption = 4;
                    elseif Action(thisRound) == 4 % circle
                        critOption = 3;
                    end
                else % color trial
                    if Action(thisRound) == 1 % blue
                        critOption = 3;
                    elseif Action(thisRound) == 3 % blue
                        critOption = 1;
                    elseif Action(thisRound) == 2 % red
                        critOption = 4;
                    elseif Action(thisRound) == 4 % red
                        critOption = 2;
                    end
                end
                
                % Walk through more rounds until we get our critical trial
                %   or hit the distance cutoff
                counter = 1;
                while counter > 0 && (thisRound+counter) <= index(end) && counter <= distance_cutoff
                    
                    % The critical trial, then, is the next round after it that
                    %   (a) is the same trial type
                    %   (b) has the same goal option, but a different
                    %       symbol choice, as the one the subject choice (aka
                    %       contains critOption)
                    %   (c) is within a distance cutoff
                    % We also need that other criterion, that the other
                    %   option can't be the option we chose in the low-prob
                    %   transition, because I messed up (and thus that's
                    %   possible)
                    
                    if (Type(thisRound) == Type(thisRound+counter)) && ((Opt1(thisRound+counter) == critOption && Opt2(thisRound+counter) ~= Action(thisRound)) || (Opt2(thisRound+counter) == critOption && Opt1(thisRound+counter) ~= Action(thisRound)))
                        % We have a critical trial!
                        
                        % Update count & get distance
                        countCrits = countCrits+1;
                        distance(end+1) = counter;
                        
                        if features(critOption,Type(thisRound)) == features(otherOption,Type(thisRound))
                        end
                        
                        % Figure out what the other option is
                        if Opt1(thisRound+counter) == critOption
                            otherOption = Opt2(thisRound+counter);
                        else
                            otherOption = Opt1(thisRound+counter);
                        end
                        
                        % Get important info
                        lowProbRewards(end+1) = Re(thisRound);
                        relativeValues(end+1) = rewards(43,(thisRound+counter-index(1)+1),Type(thisRound),features(critOption+1,Type(thisRound))) - rewards(43,(thisRound+counter-index(1)+1),Type(thisRound),features(otherOption+1,Type(thisRound)));
                        choices(end+1) = (Action(thisRound+counter)==critOption);
                        
                        % Reset counter
                        counter = 0;
                    else
                        counter = counter + 1;
                    end
                end
            end
        end
    end
end