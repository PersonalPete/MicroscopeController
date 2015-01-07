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
        
        function setExpFrame(obj, expTime, frameRate)
            obj.ExpTime = expTime; obj.FrameRate = frameRate;
            afSetExpFrame(obj.CamH,obj.ExpTime,obj.FrameRate);
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
        
        function [hCent, vCent] = centroidLastFrame(obj)
            % centroid calculated as Sum_i{x_i*i}/Sum_i{x_i}
            lastImage = getLastFrame(obj);
            roi = obj.Roi; % extract only a region of interest
            lastImageCrop = double(lastImage(roi(1):roi(2),roi(3):roi(4)));
            % compute the centroids
            normConst = sum(sum(lastImageCrop,1),2); 
            hNum = sum(sum(bsxfun(@times,lastImageCrop,(roi(1):roi(2))'),1),2);
            hCent = hNum/normConst;
            if nargout > 1
                vNum = sum(sum(bsxfun(@times,lastImageCrop,roi(3):roi(4)),2),1);
                vCent = vNum/normConst;
            end                      
            
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