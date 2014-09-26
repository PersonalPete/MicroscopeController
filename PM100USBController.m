classdef PM100USBController < handle
    properties (SetAccess = private)
        VisaConnection;
        LastRead = NaN;
        READ_DELAY = 2; % read no faster than every 2 seconds
        LastPower = NaN;
    end
    methods (Access = public)
        function obj = PM100USBController()
            % Create the USB connection
            obj.VisaConnection = visa('ni','USB0::0x1313::0x8072::P2001130::INSTR');
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
            % enforce the waiting before taking a new reading
            if isnan(obj.LastRead) || toc(obj.LastRead) > obj.READ_DELAY
                obj.LastRead = tic;
                % set the wavelength
                fprintf(obj.VisaConnection,'ABOR'); % abort measurement at previous wavlength
                fprintf(obj.VisaConnection,'CORR:WAV %i',round(wavelength));
                % take the measurement
                fprintf(obj.VisaConnection,'INIT');
                % request the answer (in W)
                fprintf(obj.VisaConnection,'FETC?');
                % read the answer
                readPower = str2double(fgetl(obj.VisaConnection));
                if ~isnan(readPower)
                    obj.LastPower = readPower;
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


