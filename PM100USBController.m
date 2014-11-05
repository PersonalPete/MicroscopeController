classdef PM100USBController < handle
    properties (SetAccess = private)
        VisaConnection;
        LastRead = NaN;
        READ_DELAY = 0.2; % read no faster than every 1 seconds
        LastPower = NaN;
        LastWave = NaN;
        
        CAL_FACTOR = 4.72; % because there is a roughly 70:30 beamsplitter directing light onto the powermeter
        
    end
    methods (Access = public)
        function obj = PM100USBController()
            % Create the USB connection
            obj.VisaConnection = visa('ni','USB0::0x1313::0x8072::P2003799::INSTR');
            fopen(obj.VisaConnection); % open the connection
            fprintf(obj.VisaConnection,'*IDN?'); % get the identification of the object we connected to
            idnResponse = fgetl(obj.VisaConnection);
            if isempty(idnResponse)
                MException('MScope:THORLABSPMError','Can''t connect to power meter').throw;
            end
            fprintf('\nConnected to:\n%s\n',idnResponse); % print it to standard output
            fprintf(obj.VisaConnection,'CON:POW');
        end
        function power = measurePower(obj,wavelength)
            warning('off','instrument:fgetl:unsuccessfulRead');
            wavelength = round(wavelength); % must be a whole number
            % enforce the waiting before taking a new reading
            if isnan(obj.LastRead) || toc(obj.LastRead) > obj.READ_DELAY
                obj.LastRead = tic;
                % set the wavelength
                if obj.LastWave ~= wavelength
                    fprintf(obj.VisaConnection,'CORR:WAV %i',wavelength);
                    obj.LastWave = wavelength;
                end
                % take the measurement
                fprintf(obj.VisaConnection,'INIT');
                % request the answer (in W)
                fprintf(obj.VisaConnection,'FETC?');
                % read the answer
                readPower = str2double(fgetl(obj.VisaConnection));
                if ~isnan(readPower)
                    obj.LastPower = readPower*obj.CAL_FACTOR;
                end
            end
            power = obj.LastPower;
            warning('on','instrument:fgetl:unsuccessfulRead');
        end
        function delete(obj)
            fclose(obj.VisaConnection);
            
        end
    end
end


