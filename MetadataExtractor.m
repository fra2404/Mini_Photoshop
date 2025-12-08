classdef MetadataExtractor < handle
    
    methods (Static)
        
        function exifText = extractExifInfo(info)
            exifText = '';
            % Device Make
            make = [];
            if isfield(info, 'Make')
                make = info.Make;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'Make')
                make = info.DigitalCamera.Make;
            end
            if ~isempty(make)
                exifText = [exifText sprintf('\nDevice Make: %s', make)];
            end
            % Device Model
            model = [];
            if isfield(info, 'Model')
                model = info.Model;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'Model')
                model = info.DigitalCamera.Model;
            end
            if ~isempty(model)
                exifText = [exifText sprintf('\nDevice Model: %s', model)];
            end
            % ISO
            iso = [];
            if isfield(info, 'ISOSpeedRatings')
                iso = info.ISOSpeedRatings;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'ISOSpeedRatings')
                iso = info.DigitalCamera.ISOSpeedRatings;
            end
            if ~isempty(iso)
                exifText = [exifText sprintf('\nISO: %d', iso)];
            end
            % F-stop
            fnumber = [];
            if isfield(info, 'FNumber')
                fnumber = info.FNumber;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'FNumber')
                fnumber = info.DigitalCamera.FNumber;
            end
            if ~isempty(fnumber)
                exifText = [exifText sprintf('\nF-stop: f/%.1f', fnumber)];
            end
            % Focal Length
            focallength = [];
            if isfield(info, 'FocalLength')
                focallength = info.FocalLength;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'FocalLength')
                focallength = info.DigitalCamera.FocalLength;
            end
            if ~isempty(focallength)
                exifText = [exifText sprintf('\nFocal Length: %.1f mm', focallength)];
            end
            % Exposure Time
            exposuretime = [];
            if isfield(info, 'ExposureTime')
                exposuretime = info.ExposureTime;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'ExposureTime')
                exposuretime = info.DigitalCamera.ExposureTime;
            end
            if ~isempty(exposuretime)
                exifText = [exifText sprintf('\nExposure Time: 1/%.0f s', 1/exposuretime)];
            end
            % Exposure Program
            exposureprogram = [];
            if isfield(info, 'ExposureProgram')
                exposureprogram = info.ExposureProgram;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'ExposureProgram')
                exposureprogram = info.DigitalCamera.ExposureProgram;
            end
            if ~isempty(exposureprogram)
                exifText = [exifText sprintf('\nExposure Program: %s', exposureprogram)];
            end
            % Metering Mode
            meteringmode = [];
            if isfield(info, 'MeteringMode')
                meteringmode = info.MeteringMode;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'MeteringMode')
                meteringmode = info.DigitalCamera.MeteringMode;
            end
            if ~isempty(meteringmode)
                exifText = [exifText sprintf('\nMetering Mode: %s', meteringmode)];
            end
            % Lens info from XMP if available
            lens = [];
            if isfield(info, 'XMPData') && isfield(info.XMPData, 'aux') && isfield(info.XMPData.aux, 'Lens')
                lens = info.XMPData.aux.Lens;
            elseif isfield(info, 'XMPData') && isfield(info.XMPData, 'exifEX') && isfield(info.XMPData.exifEX, 'LensModel')
                lens = info.XMPData.exifEX.LensModel;
            end
            if ~isempty(lens)
                exifText = [exifText sprintf('\nLens: %s', lens)];
            end
            % Copyright
            copyright = [];
            if isfield(info, 'Copyright')
                copyright = info.Copyright;
            end
            if ~isempty(copyright)
                exifText = [exifText sprintf('\nCopyright: %s', copyright)];
            end
            % Artist
            artist = [];
            if isfield(info, 'Artist')
                artist = info.Artist;
            end
            if ~isempty(artist)
                exifText = [exifText sprintf('\nArtist: %s', artist)];
            end
            % Software
            software = [];
            if isfield(info, 'Software')
                software = info.Software;
            end
            if ~isempty(software)
                exifText = [exifText sprintf('\nSoftware: %s', software)];
            end
            % Date Taken
            datetimeoriginal = [];
            if isfield(info, 'DateTimeOriginal')
                datetimeoriginal = info.DateTimeOriginal;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'DateTimeOriginal')
                datetimeoriginal = info.DigitalCamera.DateTimeOriginal;
            end
            if ~isempty(datetimeoriginal)
                exifText = [exifText sprintf('\nDate Taken: %s', datetimeoriginal)];
            end
            % Image Description
            imagedescription = [];
            if isfield(info, 'ImageDescription')
                imagedescription = info.ImageDescription;
            end
            if ~isempty(imagedescription)
                exifText = [exifText sprintf('\nImage Description: %s', imagedescription)];
            end
            % White Balance
            whitebalance = [];
            if isfield(info, 'WhiteBalance')
                whitebalance = info.WhiteBalance;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'WhiteBalance')
                whitebalance = info.DigitalCamera.WhiteBalance;
            end
            if ~isempty(whitebalance)
                exifText = [exifText sprintf('\nWhite Balance: %s', whitebalance)];
            end
            % Flash
            flash = [];
            if isfield(info, 'Flash')
                flash = info.Flash;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'Flash')
                flash = info.DigitalCamera.Flash;
            end
            if ~isempty(flash)
                exifText = [exifText sprintf('\nFlash: %s', flash)];
            end
        end
        
    end
    
end