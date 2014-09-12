classdef CoherentCube < handle
    %CoherentCube communicates with a Coherent Cube laser via RS-232
    % When constructed it opens the serial connection, when closed it
    % removes it. It can be used to set the power to some fraction of the
    % maximum power
    
    properties (SetAccess = private)
        SerialConnection;
        MaxPower;
        
        TEST_MODE = 0;
        NUM_ATTEMPT = 5
    end
    
    methods
        % CONSTRUCTOR
        function obj = CoherentCube(portString)
            if strcmp(portString,'TEST')
                obj.TEST_MODE = 1;
            end
            
            % portString specifies the COM port to connect over e.g. 'COM1'
            
            if ~obj.TEST_MODE
                obj.SerialConnection = serial(portString,'BaudRate',19200,'Terminator','CR');
                fopen(obj.SerialConnection);
            end
            % we now have an open connection, and have to check that it
            % understands us
            for ii = 1:obj.NUM_ATTEMPT
                statusString = obj.sendAndRec('?STA');
                if strcmp(statusString,'2') || strcmp(statusString,'3')
                    % if the laser is idle or on
                    break % we are ok
                end
                fprintf('\nError communicating with red laser (attempr %i)\n',ii);
            end
            
            obj.MaxPower = str2double(obj.sendAndRec('?MAXLP'));
            
            % Set some default settings
            obj.sendAndRec('P=0');
            obj.sendAndRec('L=0'); % laser off
            obj.sendAndRec('CW=0'); % TTL control active
            obj.sendAndRec('ANA=0'); % no analog or external power control
            obj.sendAndRec('EXT=0');
        end
        
        function setPower(obj,powerFraction)
            obj.sendAndRec('L=1');
            powerFraction = min(powerFraction,1);
            powerFraction = max(powerFraction,0);
            obj.sendAndRec(sprintf('P=%.1f',powerFraction*obj.MaxPower));
        end
        
        function close(obj)
            fprintf('\nDisconnecting from red laser\n')
            try
                obj.sendAndRec('L=0');
                if ~obj.TEST_MODE
                    fclose(obj.SerialConnection);
                end
            catch
                fprintf('\nRed laser disconnect error\n');
            end
        end
    end
    
    methods (Access = private)
        function stringResponse = sendAndRec(obj,stringSend)
            if obj.TEST_MODE
                fprintf('\nSending %s to red laser\n',stringSend);
                stringResponse = '2';
            else
                % send the query
                fprintf(obj.SerialConnection,stringSend);
                % receive the answer
                stringResponse = fscanf(obj.SerialConnection,'%s');
            end
        end
    end
end

