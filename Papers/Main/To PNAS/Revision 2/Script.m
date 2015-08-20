eps = .17;
n = 100000;
lr = .01;

Q = zeros(2,1);
QO = zeros(2,1);
reward = 0;
action = 0;
option = 0;

for i = 1:n
    % Choose option
    if rand() > eps
        option = 2;
        % We've chosen option 2
        % Choose action
        if rand() > eps
            % Action 1
            action = 1;
            % Transition
            if rand() < .1
                % S2
                reward = 100;
            else
                % S1
                reward = 0;
            end
        else
            % Action 2
            action = 2;
            % Transition
            if rand() < .01
                reward = 100;
            else
                reward = 0;
            end
        end
    else
        option = 1;
        % Option 1
        % Choose action
        if rand() > eps
            % Action 2
            action = 2;
            if rand() < .01
                reward = 100;
            else
                reward = 0;
            end
        else
            % Action 1
            action = 1;
            if rand() < .1
                % S2
                reward = 100;
            else
                % S1
                reward = 0;
            end
        end
    end
    
    QO(option) = QO(option) + lr/sqrt(i)*(reward - QO(option));
    Q(action) = Q(action) + lr/sqrt(i)*(reward - Q(action));
end