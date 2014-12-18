classdef AfCamController < handle
    
    properties (SetAccess = private)
        CamH
        MemID
        ExpTime = 10; % (/ms)
        FrameRate = 100; % (/Hz)
        Roi = [750, 950, 600, 750]; 
    end
    
    methods (Access = public)
        function obj = AfCamController()
            [camH, memID] = afInitialiseCamera();
            obj.CamH = camH; obj.MemID = memID;
            afSetExpFrame(obj.CamH,obj.ExpTime,obj.FrameRate); % i.e. defaults
        end % constructor
        
        function frameData = getLastFrame(obj)
            frameData = afGetLastImage(obj.CamH, obj.MemID);
        end % getLastFrame
        
        function setExpFrame(obj, expTime, frameRate)
            obj.ExpTime = expTime; obj.FrameRate = frameRate;
            afSetExpFrame(obj.CamH,obj.ExpTime,obj.FrameRate);
        end % setExpFrame
        
        function setRoi(obj, roi)
            % make inputs sensible
            roi = round(roi);
            roi(1) = max(roi(1),1); 
            roi(2) = min(roi(2),1280);
            roi(2) = max(roi(2),roi(1) + 1);
            roi(3) = max(roi(3),1);
            roi(4) = min(roi(4),1024);
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
            afCloseCamera(obj.CamH, obj.MemID)
        end % destructor
    end
end