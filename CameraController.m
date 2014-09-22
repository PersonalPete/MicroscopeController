classdef CameraController < handle
    %CameraController uses the Andor SDK to setup and acquire using an
    %Andor iXon+
    %
    % NOTE: All C++ functions retun an Andor status code as their first
    % output. This is checked and an error is thrown if the code doesn't
    % indicate success
    
    properties (SetAccess = private)
        AcqMode; % 0: Internal Trigger, 1: External Trigger, 2: Fast External
        RepeatTime; % (\s) Time between exposure starts CURRENTLY set (only means anything for CW)
        SpoolPath; % The directory we are spooling to
        SpoolName; % The base file name we are spooling to
        Spooling; % boolean - true: spooling on, false: spooling off
        SpoolAppend = 0; % number to append as we spool so each file is new, starts at _0
        KineticFrames; % Number of frames to acquire
        Acquiring; % boolean - true: currently acquiring, false: not acquiring
        Connected; % boolean - true: intialised, false: has been closed
        ShutterOpen; % boolean - true: open, false: closed
        
        numXPix = 512;
        numYPix = 512;
    end
    
    properties (Access = public, Constant)
        % default camera settings
        DFT_KIN_MODE = 3; % (3 is regular kinetics) - 4 doesn't seem to work
        
        % Andor status codes
        DRV_SUCCESS = 20002;
        DRV_IDLE = 20073;
        DRV_ACQUIRING = 20072;
        
        DRV_NOT_INITIALIZED = 20075;
        DRV_ERROR_ACK = 20013;
        DRV_TEMP_OFF = 20034;
        DRV_TEMP_STABILIZED = 20036;
        DRV_TEMP_NOT_REACHED = 20037; 
        DRV_TEMP_DRIFT = 20040;
        DRV_TEMP_NOT_STABILIZED = 20035;
        
        SPOOL_FILE = 'fits';
        TEMP_MIN = -80; % we can set -120, but it will not actually do it
        TEMP_MAX = 20;
    end
    
    methods (Access = public)
        % Constructor
        function obj = CameraController()
            % We need to open the connection to the camera and set some
            % defaults
            fprintf('\nInitialising Camera...\n')
            if initialiseCamera == obj.DRV_SUCCESS
                fprintf('Success\n')
            else
                MException('MScope:AndorErr','Camera Connection failed\nRESTART MATLAB AND TRY AGAIN').throw;
            end
            % Apply default settings
            if initialSettings ~= obj.DRV_SUCCESS
                MException('MScope:AndorErr','Initialisation failed').throw;
            end
                    
            fprintf('\nCamera Status: %s\n',obj.getStatus);
            
            % Default to CW operation
            obj.setAcqMode(0);
            % Default to NOT SPOOLING
            obj.setSpool(); % don't spool
            
            obj.Connected = true; % we are connected
            
        end % constructor
        
        % set methods that affect the camera and update the object
        % properties
        function setAcqMode(obj,acqMode)
            % 0: Internal trigger, 1: External trigger, 2: Fast external
            obj.assertConnected; % error if we aren't connected
            obj.assertIdle; % error if it isn't idle
            switch acqMode
                case 0 % Internal
                    if setInternalTrigger ~= obj.DRV_SUCCESS;
                        MException('MScope:AndorErr','Internal trigger not set').throw;
                    end
                case 1 % external  - set the timings to no holdoff on exposure
                    if setExternalTrigger(false) ~= obj.DRV_SUCCESS;
                        MException('MScope:AndorErr','External trigger not set').throw;
                    end
                    setTimingsCode = setTimings(0,0);
                    if setTimingsCode ~= obj.DRV_SUCCESS;
                        MException('MScope:AndorErr',sprintf('External trigger timings error: %i',setTimingsCode)).throw;
                    end
                case 2 % fast external (which would be normal for ALEX) - set the timings to no holdoff on exposure
                    if setExternalTrigger(true) ~= obj.DRV_SUCCESS;
                        MException('MScope:AndorErr','Fast External trigger not set').throw;
                    end
                    if setTimings(0,0) ~= obj.DRV_SUCCESS;
                        MException('MScope:AndorErr','External trigger timings error').throw;
                    end
                otherwise
                    MException('MScope:AndorErr','Invalid trigger mode').throw;
            end
            obj.AcqMode = acqMode;
        end % setAcqMode
        
        function fullPathName = setSpool(obj,path,name,numFrames)
            % setup spooling (i.e. switch it on or off)
            % call with no arguments to switch spooling off, otherwise
            % turns it on
            obj.assertConnected; % error if we aren't connected
            obj.assertIdle; % error if it isn't idle
            if nargin < 4 % TURN OFF
                fullPathName = ''; % we still need to set the return value;
                if setAcqMode(5) ~= obj.DRV_SUCCESS % set continuous acquire (5)
                    MException('MScope:AndorErr','Continuous acquire error in spool off').throw;
                end
                if spoolOff ~= obj.DRV_SUCCESS
                    MException('MScope:AndorErr','Spool off error').throw;
                end
                obj.Spooling = false;
                obj.SpoolPath = '';
                obj.SpoolName = '';
                obj.KineticFrames = 0;
            elseif nargin == 4; % TURN ON SPOOLING
                % we have to spool to the next available name, so append _XXX
                % We assume an ABSOLUTE PATH
                if exist(path,'dir') ~= 7
                    MException('MScope:FileErr','Specified Folder doesn''t exist').throw;
                end
                
                % make a full file name with the appended counter
                fullPathName = fullfile(path,sprintf('%s_%i',name,obj.SpoolAppend));
                
                % check that no other files exist with the same name
                while exist(sprintf('%s.%s',fullPathName,obj.SPOOL_FILE),'file') == 2
                    obj.SpoolAppend = obj.SpoolAppend + 1; % try a new name then
                    fullPathName = fullfile(path,sprintf('%s_%i',name,obj.SpoolAppend));
                end
                
                % switch to kinetic series acquisition mode
                if setAcqMode(obj.DFT_KIN_MODE) ~= obj.DRV_SUCCESS
                    MException('MScope:AndorErr','Spool set error').throw;
                end
                
                % switch on spooling
                if spoolOn(fullPathName) ~= obj.DRV_SUCCESS
                    MException('MScope:AndorErr','Spool set error').throw;
                end

                % define how many frames to spool
                numFrames = floor(numFrames); % just in case we get asked to
                numFrames = max(numFrames,1); % spool a silly number of frames
                if setKineticLength(int32(numFrames)) ~= obj.DRV_SUCCESS
                    MException('MScope:AndorErr','Kinetic Length error').throw;
                end
                % set the corresponding object properties
                obj.Spooling = true;
                obj.SpoolPath = path;
                obj.SpoolName = name;
                obj.KineticFrames = numFrames;
            end % the if statement deciding whether to turn on or turn off spooling
        end % setSpool
        
        function setCwRepeatTime(obj,targetRepeatTime)
            % This method only makes sense for CW (internal trigger) mode
            % It tries to set as close a repeat time as possible with as
            % long an exposure time as possible - in SECONDS
            obj.assertConnected; % error if we aren't connected
            obj.assertIdle; % error if it isn't idle
            if obj.AcqMode > 0
                MException('MScope:WrongAcqMode','Repeat time can only be set in internal trigger mode').throw;
            end
            % don't try and set it faster than the fastest possible
            targetRepeatTime = max(targetRepeatTime, obj.getMinRepeatTime);
            err = zeros(2,1); % this will hold the responses from the Andor SDK
            [err(1), minExposureTime, minRepeatTime] = setTimings(0,0);
            delta = minRepeatTime - minExposureTime; % the time delay betwen end of exposure and start of next
            [err(2), ~, finalRepeatTime] = ...
                setTimings(targetRepeatTime - delta,targetRepeatTime);
            if (finalRepeatTime > targetRepeatTime*1.01) % allow a 1 percent margin
                MException('Mscope:AndorErr','Timing mismatch').throw;
            end
            if (any(err ~= obj.DRV_SUCCESS))
                MException('Mscope:AndorErr','SDK error').throw;
            end
        end % of set repeat time
        
        function [repeatTime, exposureTime] = getCwTimes(obj)
            % only makes sense for CW to care about actual set times
            obj.assertConnected; % error if we aren't connected
            obj.assertIdle; % error if it isn't idle
            if obj.AcqMode > 0
                MException('MScope:WrongAcqMode','Repeat time can only be set in internal trigger mode').throw;
            end
            [andorCode, exposureTime, repeatTime] = getTimings;
            if andorCode ~= obj.DRV_SUCCESS;
                MException('MScope:AndorErr','getTimings failed').throw;
            end
        end
        
        function minRepeatTime = getMinRepeatTime(obj)
            % calculates the minimum exposure time we could set in seconds
            % for internal triggering this is the minimum allowed value for
            % the kinetic cycle time with minimum exposure time
            obj.assertConnected; % error if we aren't connected
            obj.assertIdle; % error if it isn't idle
            if obj.AcqMode == 0 % we are in internal triggering, CW mode
                err = zeros(3,1); % this will hold the responses from the Andor SDK
                [err(1), initialExposureTime, initialRepeatTime] = getTimings;
                [err(2), ~, minRepeatTime] = setTimings(0,0);
                [err(3), finalExposureTime, finalRepeatTime] = ...
                    setTimings(initialExposureTime,initialRepeatTime);
                if (finalExposureTime ~= initialExposureTime && ...
                        finalRepeatTime ~= initialRepeatTime)
                    MException('Mscope:AndorErr','Timing mismatch').throw;
                end
                if (any(err ~= obj.DRV_SUCCESS))
                    MException('Mscope:AndorErr','SDK error').throw;
                end
            else    % what to do for external triggering - this is actually the same,
                % but I need to think about it a little more
                err = zeros(3,1); % this will hold the responses from the Andor SDK
                [err(1), initialExposureTime, initialRepeatTime] = getTimings;
                [err(2), ~, minRepeatTime] = setTimings(0,0);
                [err(3), finalExposureTime, finalRepeatTime] = ...
                    setTimings(initialExposureTime,initialRepeatTime);
                if (finalExposureTime ~= initialExposureTime && ...
                        finalRepeatTime ~= initialRepeatTime)
                    MException('Mscope:AndorErr','Timing mismatch').throw;
                end
                if (any(err ~= obj.DRV_SUCCESS))
                    MException('Mscope:AndorErr','SDK error').throw;
                end
            end % of if-else
        end % getMinRepeatTime
        
        function delete(obj)
            % closes the camera
            % first, check if it is acquiring and cancel this
            obj.assertConnected; % error if we aren't connected
            obj.stopIfAcquiring;
            obj.closeShutter; % close the shutter
            % then close the camera
            if closeCamera ~= obj.DRV_SUCCESS;
                MException('Msccope:AndorErr','Cannot Close camera').throw;
            end
            obj.Connected = false; % we are now disconnected
            fprintf('\nCamera disconnected...\n');
        end % disconnect
        
        function status = getStatus(obj)
            obj.assertConnected; % error if we aren't connected
            [err, response] = getStatus;
            if err ~= obj.DRV_SUCCESS;
                MException('MScope:AndorErr','Status get failed').throw;
            end
            % might as well update the statues now
            if response == obj.DRV_IDLE
                obj.Acquiring = false;
            end
            if response == obj.DRV_ACQUIRING
                obj.Acquiring = true;
            end
            % return the response
            status = response;
        end % getStatus
        
        function statString = getStringStatus(obj)
            statusInt = obj.getStatus;
            if statusInt == obj.DRV_IDLE;
                statString = 'IDLE';
            elseif statusInt == obj.DRV_ACQUIRING
                statString = 'ACQUIRE';
            else
                statString = 'ERROR';
            end
        end % getStringStatus
        
        function startAcquiring(obj)
            % start the acquisition
            obj.assertConnected; % error if we aren't connected
            obj.assertIdle;
            
            % make sure we don't overwrite an existing file
            if obj.Spooling == true
                obj.setSpool(obj.SpoolPath,obj.SpoolName,obj.KineticFrames);
            end
            
            startReturn = startAcquisition;
            if startReturn ~= obj.DRV_SUCCESS
                MException('MScope:AndorErr',sprintf('Acquisition failed: %i',startReturn)).throw;
            end
            obj.Acquiring = true;
        end % startAcquiring
        
        function stopIfAcquiring(obj)
            % stop the acquisition if there is one in progress
            obj.assertConnected; % error if we aren't connected
            andorCode = abortAcquisition;
            if andorCode ~= obj.DRV_SUCCESS && andorCode ~= obj.DRV_IDLE
                MException('MScope:AndorErr','Cannot abort acquisition').throw;
            end
            obj.Acquiring = false;
        end % stopIfAcquiring
        
        % SHUTTER %
        
        function openShutter(obj)
            % opens the shutter
            if openShutter ~= obj.DRV_SUCCESS
                MException('MScope:AndorErr','Shutter open problem').throw;
            end
            obj.ShutterOpen = true;
        end % openShutter
        
        function closeShutter(obj)
            if closeShutter ~= obj.DRV_SUCCESS
                MException('MScope:AndorErr','Shutter close problem').throw;
            end
            obj.ShutterOpen = false;
        end % closeShutter
        
        % TEMPERATURE %
        
        function [temp, tempStatString] = getTemp(obj)
            obj.assertConnected;
            [tempCode, temp] = getTemp;
            switch tempCode
                case {obj.DRV_NOT_INITIALIZED, obj.DRV_ERROR_ACK, obj.DRV_TEMP_OFF}
                    MException('MScope:AndorErr','Temp error').throw;
                case obj.DRV_TEMP_STABILIZED
                    tempStatString = 'STABLE';
                case {obj.DRV_TEMP_NOT_REACHED, obj.DRV_TEMP_DRIFT, obj.DRV_TEMP_NOT_STABILIZED}
                    tempStatString = 'UNSTABLE';
                case obj.DRV_ACQUIRING
                    tempStatString = 'ACQUIRE';
                    obj.Acquiring = true;
            end
        end % get temp
        
        function setTemp(obj,temp)
            % check now is a good time to set the temperature
            obj.assertConnected;
            obj.assertIdle;
            % check that we got a sensible temperature
            temp = min(temp,obj.TEMP_MAX);
            temp = max(temp,obj.TEMP_MIN);
            if setTemp(int32(temp)) ~= obj.DRV_SUCCESS
                MException('MScope:AndorErr','Error setting temp').throw;
            end
        end % setTemp
        
        function [codeStr, imageArray, mostRecentImNo] = getLatestData(obj)
            % retrieves the latest image taken by the camera and an
            % approximate number of total images acquired since start was
            % called
            [code, imageArray, mostRecentImNo] = getLastFrame16(obj.numXPix,obj.numYPix);
            if code == obj.DRV_SUCCESS
                codeStr = 'OK';
            else
                codeStr = 'ERR';
            end
        end
            
    end % of public methods
    
    
    
    methods (Access = private)
                function assertIdle(obj)
            obj.assertConnected; % error if we aren't connected
            if obj.getStatus ~= obj.DRV_IDLE
                MException('MScope:AndorErr',sprintf('Camera not idle: %s',getStatus)).throw;
            end
            obj.Acquiring = false; % update the status
        end % assertIdle
        
        function assertConnected(obj)
            if obj.Connected == false
                MException('MScope:ConnectionErr','Camera disconnected').throw;
            end
        end % assertconnected
    end % of private methods
end % of class