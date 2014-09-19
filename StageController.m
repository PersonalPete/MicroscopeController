classdef StageController < handle
    %StageController uses the PI GCS SDK (C/C++) to connect and control
    %stages.
    % On creation it connects to a USB daisy chain and waits for all the
    % stages to be ready before returning.
    
    properties (SetAccess = private)
        NumControllers; % should be 4
        Connected; % 1 = true, 0 = false
        DaisyChainID;
        ControllerID; % array of controller ids
        
        TIMEOUT = 5;
    end
    
    methods
        function obj = StageController(expectedNumControllers)
            if nargin < 1
                expectedNumControllers = 4;
            end
            
            % connect to the stage and the 4 axes (checking there are
            % indeed 4
            [obj.DaisyChainID, obj.NumControllers] = connectDaisyChainUSB();
            if obj.NumControllers ~= expectedNumControllers
                MException('MScope:PIErr:ConnectionErr','Incorrect number of controllers detected').throw;
            end
            try
                % connect to the controllers
                for controllerNumber = 1:obj.NumControllers
                    fprintf('\nStage %i ... ',controllerNumber);
                    obj.ControllerID(controllerNumber) = connectDaisyChainController(obj.DaisyChainID,controllerNumber);
                    fprintf('Connected ...');
                    % make sure it isn't busy
                    timeoutStart = tic;
                    while ~getReady(obj.ControllerID(controllerNumber))
                        pause(0.01);
                        if toc(timeoutStart) > obj.TIMEOUT;
                            MException('MScope:PIErr:Timeout','Timeout while waiting for ready').throw;
                        end
                    end
                    % make sure servo mode is engaged
                    servoOn(obj.ControllerID(controllerNumber));
                    fprintf(' in servo mode\n');
                end
            catch
                closeDaisyChain(obj.DaisyChainID);
            end
        end
        
        function disconnect(obj)
            % disconnect correctly
            closeDaisyChain(obj.DaisyChainID);
        end
        
        function position = getPosition(obj,controller)
            % UNITS ARE MILLIMETERS
            position = getPos(obj.ControllerID(controller));
        end
        
        function setPosition(obj,controller,position)
            % UNITS ARE MILLIMETERS
            setPos(obj.ControllerID(controller),position); 
        end
        
        function errCode = getError(obj,controller)
            errCode = getError(obj.ControllerID(controller));
        end
        
    end
    
end