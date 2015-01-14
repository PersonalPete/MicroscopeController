classdef AfCamController < handle
    
    properties (SetAccess = private)
        CamH
        MemID
        MemPtr
        ExpTime = 10; % (/ms)
        FrameRate = 100; % (/Hz)
        Roi = [1, 1280, 1, 1024]; 
        
        USE_RING = 1
        HOR_MAX = 1280/4; % 4x subsampling
        VER_MAX = 1024/4; % 4x subsampling
    end
    
    methods (Access = public)
        function obj = AfCamController()
            if obj.USE_RING
                [camH, memID, memPtr] = afInitialiseCameraRing();
                obj.MemPtr = memPtr; % store the pointers to the image memory
            else
                [camH, memID] = afInitialiseCamera();
            end
            obj.CamH = camH; obj.MemID = memID;
            afSetExpFrame(obj.CamH,obj.ExpTime,obj.FrameRate); % i.e. defaults
        end % constructor
        
        function frameData = getLastFrame(obj)
            if obj.USE_RING
                frameData = afGetLastImage(obj.CamH, obj.MemID, obj.MemPtr);
            else
                frameData = afGetLastImage(obj.CamH, obj.MemID);
            end
            frameData = frameData(1:obj.HOR_MAX,1:obj.VER_MAX);
        end % getLastFrame
        
        function roiIntensity = getRoiIntensity(obj)
            frameData = obj.getLastFrame;
            roi = obj.Roi;
            frameData = frameData(roi(1):roi(2),roi(3):roi(4));
            roiIntensity = sum(double(frameData(:)));
        end % getRoiIntensity
        
        function [trueExpTime, trueFrameRate] = setExpFrame(obj, expTime, frameRate)
            [trueExpTime, trueFrameRate] = afSetExpFrame(obj.CamH,expTime,frameRate);
            obj.ExpTime = trueExpTime; obj.FrameRate = trueFrameRate;
        end % setExpFrame
        
        function setRoi(obj, roi)
            % make inputs sensible
            roi = round(roi);
            roi(1) = max(roi(1),1); 
            roi(2) = min(roi(2),obj.HOR_MAX);
            roi(2) = max(roi(2),roi(1) + 1);
            roi(3) = max(roi(3),1);
            roi(4) = min(roi(4),obj.VER_MAX);
            roi(4) = max(roi(4),roi(3) + 1);
            obj.Roi = roi;
        end % setRoi
        
        function hCent = centroidLast(obj,framesToAverage)
            roi = obj.Roi;
            hCent = afCentroidImages(obj.CamH, obj.MemPtr,...
                roi(1), roi(2), roi(3), roi(4),...
                framesToAverage);           
        end % centroidLastFrame
            
        function delete(obj)
            if obj.USE_RING
                afCloseCameraRing(obj.CamH, obj.MemID, obj.MemPtr)
            else
                afCloseCamera(obj.CamH,obj.MemID);
            end
        end % destructor
    end
end