classdef MetadataExtractor < handle
    
    methods (Static)
        
        function exifText = extractExifInfo(info)
            exifText = '';
            firstField = true;
            % Device Make
            make = [];
            if isfield(info, 'Make')
                make = info.Make;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'Make')
                make = info.DigitalCamera.Make;
            end
            if ~isempty(make)
                if firstField
                    exifText = sprintf('Device Make: %s', make);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nDevice Make: %s', make)];
                end
            end
            % Device Model
            model = [];
            if isfield(info, 'Model')
                model = info.Model;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'Model')
                model = info.DigitalCamera.Model;
            end
            if ~isempty(model)
                if firstField
                    exifText = sprintf('Device Model: %s', model);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nDevice Model: %s', model)];
                end
            end
            % ISO
            iso = [];
            if isfield(info, 'ISOSpeedRatings')
                iso = info.ISOSpeedRatings;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'ISOSpeedRatings')
                iso = info.DigitalCamera.ISOSpeedRatings;
            end
            if ~isempty(iso)
                if firstField
                    exifText = sprintf('ISO: %d', iso);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nISO: %d', iso)];
                end
            end
            % F-stop
            fnumber = [];
            if isfield(info, 'FNumber')
                fnumber = info.FNumber;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'FNumber')
                fnumber = info.DigitalCamera.FNumber;
            end
            if ~isempty(fnumber)
                if firstField
                    exifText = sprintf('F-stop: f/%.1f', fnumber);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nF-stop: f/%.1f', fnumber)];
                end
            end
            % Focal Length
            focallength = [];
            if isfield(info, 'FocalLength')
                focallength = info.FocalLength;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'FocalLength')
                focallength = info.DigitalCamera.FocalLength;
            end
            if ~isempty(focallength)
                if firstField
                    exifText = sprintf('Focal Length: %.1f mm', focallength);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nFocal Length: %.1f mm', focallength)];
                end
            end
            % Exposure Time
            exposuretime = [];
            if isfield(info, 'ExposureTime')
                exposuretime = info.ExposureTime;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'ExposureTime')
                exposuretime = info.DigitalCamera.ExposureTime;
            end
            if ~isempty(exposuretime)
                if firstField
                    exifText = sprintf('Exposure Time: 1/%.0f s', 1/exposuretime);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nExposure Time: 1/%.0f s', 1/exposuretime)];
                end
            end
            % Exposure Program
            exposureprogram = [];
            if isfield(info, 'ExposureProgram')
                exposureprogram = info.ExposureProgram;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'ExposureProgram')
                exposureprogram = info.DigitalCamera.ExposureProgram;
            end
            if ~isempty(exposureprogram)
                if firstField
                    exifText = sprintf('Exposure Program: %s', exposureprogram);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nExposure Program: %s', exposureprogram)];
                end
            end
            % Metering Mode
            meteringmode = [];
            if isfield(info, 'MeteringMode')
                meteringmode = info.MeteringMode;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'MeteringMode')
                meteringmode = info.DigitalCamera.MeteringMode;
            end
            if ~isempty(meteringmode)
                if firstField
                    exifText = sprintf('Metering Mode: %s', meteringmode);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nMetering Mode: %s', meteringmode)];
                end
            end
            % Lens info from XMP if available
            lens = [];
            if isfield(info, 'XMPData') && isfield(info.XMPData, 'aux') && isfield(info.XMPData.aux, 'Lens')
                lens = info.XMPData.aux.Lens;
            elseif isfield(info, 'XMPData') && isfield(info.XMPData, 'exifEX') && isfield(info.XMPData.exifEX, 'LensModel')
                lens = info.XMPData.exifEX.LensModel;
            end
            if ~isempty(lens)
                if firstField
                    exifText = sprintf('Lens: %s', lens);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nLens: %s', lens)];
                end
            end
            % Copyright
            copyright = [];
            if isfield(info, 'Copyright')
                copyright = info.Copyright;
            end
            if ~isempty(copyright)
                if firstField
                    exifText = sprintf('Copyright: %s', copyright);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nCopyright: %s', copyright)];
                end
            end
            % Artist
            artist = [];
            if isfield(info, 'Artist')
                artist = info.Artist;
            end
            if ~isempty(artist)
                if firstField
                    exifText = sprintf('Artist: %s', artist);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nArtist: %s', artist)];
                end
            end
            % Software
            software = [];
            if isfield(info, 'Software')
                software = info.Software;
            end
            if ~isempty(software)
                if firstField
                    exifText = sprintf('Software: %s', software);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nSoftware: %s', software)];
                end
            end
            % Date Taken
            datetimeoriginal = [];
            if isfield(info, 'DateTimeOriginal')
                datetimeoriginal = info.DateTimeOriginal;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'DateTimeOriginal')
                datetimeoriginal = info.DigitalCamera.DateTimeOriginal;
            end
            if ~isempty(datetimeoriginal)
                if firstField
                    exifText = sprintf('Date Taken: %s', datetimeoriginal);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nDate Taken: %s', datetimeoriginal)];
                end
            end
            % Image Description
            imagedescription = [];
            if isfield(info, 'ImageDescription')
                imagedescription = info.ImageDescription;
            end
            if ~isempty(imagedescription)
                if firstField
                    exifText = sprintf('Image Description: %s', imagedescription);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nImage Description: %s', imagedescription)];
                end
            end
            % White Balance
            whitebalance = [];
            if isfield(info, 'WhiteBalance')
                whitebalance = info.WhiteBalance;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'WhiteBalance')
                whitebalance = info.DigitalCamera.WhiteBalance;
            end
            if ~isempty(whitebalance)
                if firstField
                    exifText = sprintf('White Balance: %s', whitebalance);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nWhite Balance: %s', whitebalance)];
                end
            end
            % Flash
            flash = [];
            if isfield(info, 'Flash')
                flash = info.Flash;
            elseif isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'Flash')
                flash = info.DigitalCamera.Flash;
            end
            if ~isempty(flash)
                if firstField
                    exifText = sprintf('Flash: %s', flash);
                    firstField = false;
                else
                    exifText = [exifText sprintf('\nFlash: %s', flash)];
                end
            end
        end
        
    end
    
end