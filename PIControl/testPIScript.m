%% CONNECTS TO STAGES AND REFERENCES THEM
% Should be able to make sure that the mex works ok and references the
% stages for future use

%% CONNECT TO DAISY CHAIN
[daisyChainID, numStages] = connectDaisyChainUSB();
fprintf('\nDaisy Chain Connected with %i stages\n',numStages);

testPos = 3;

controllerID = zeros(numStages,1);

try % in a try-catch so we alway close the connection gracefully
    for controllerNumber = 1:numStages
        fprintf('\nStage %i:',controllerNumber);
        controllerID(controllerNumber) = connectDaisyChainController(daisyChainID,controllerNumber);
        fprintf('\nConnected...');
        % make sure it isn't busy
        while ~getReady(controllerID(controllerNumber))
            pause(0.01);
        end
        
        servoOn(controllerID(controllerNumber));
        fprintf('\nError code: %i',getError(controllerID(controllerNumber)));
        fprintf('\nServo mode activated...');
        refMove(controllerID(controllerNumber));
        fprintf('\nReference move started...\n');
        
        fprintf('\nPosition: ');
        deleteLength = 0;
        while ~getReady(controllerID(controllerNumber))
            fprintf(repmat('\b',1,deleteLength));
            posString = sprintf('%.5f mm',getPos(controllerID(controllerNumber)));
            deleteLength = length(posString);
            fprintf('%s',posString);
        end
        fprintf('\nReference done...');
        
        setPos(controllerID(controllerNumber),testPos);
        fprintf('\nMoving to position: %.5f mm',testPos);
        
        pause(2); % pause for 5 seconds to allow the position to settle
        
        fprintf('\nPosition: %.5f mm\n',getPos(controllerID(controllerNumber)));
        
    end
    % Set all positions to zero
    for controllerNumber = 1:numStages  
        setPos(controllerID(controllerNumber),0);
    end
    % disconnect
    closeDaisyChain(daisyChainID);
    fprintf('\nSuccessful disconnect\n');
catch
    closeDaisyChain(daisyChainID);
    fprintf('\nDisconnected because of error\n');
end


