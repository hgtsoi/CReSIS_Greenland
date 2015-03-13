function printcresisyearkml(years, varargin)
%PRINTCRESISYEARKML saves CRESIS tracks in Greenland as a txt file
%years specifies which years to save, the second argument specifies the
%output directory and/or fileheader, the third argument specifies the
%whether a waitbar should be used, and the fourth bar specifies the cresis
%data portal
%might need to run curlftpfs data.cresis.ku.edu/data/rds/ /home/chenpa/cresisportal
if nargin<4
    cresisroot='/home/chenpa/cresisportal/';
else
    cresisroot=varargin{3};
end
if nargin<3
    wait_bar=1;
else
    wait_bar=varargin{2};
end
if nargin<2
    outputroot='/data/phil/searise/cresisdata';
else
    outputroot=varargin{1};
end
if ischar(years)
    years=str2num(years); %#ok<ST2NM>
end
%collect filelength data for a waitbar
if wait_bar
    charsum=0;
    for cur_year=years
        str_cell=ls2strlist(['-d ' cresisroot num2str(cur_year) '_Greenland*']);
        if (iscell(str_cell)&&wait_bar)
            for i=1:size(str_cell, 2)
                [~, dirname]=fileparts(str_cell{i});
                if exist([cresisroot dirname '/kml_good/Browse_' dirname '.kml'], 'file')
                    [status, result]=system(['wc -m ' cresisroot dirname '/kml_good/Browse_' dirname '.kml']);
                    if status
                        disp(['warning--' result])
                        disp('waitbar deactivated')
                        wait_bar=0;
                        break;
                    else
                        result=sscanf(result, '%d', 1);
                        charsum=charsum+result;
                    end
                end
            end
        end
    end
    wbh=waitbar(0, '0% done');
    progresssum=0;
    tic
end
for cur_year=years
    str_cell=ls2strlist(['-d ' cresisroot num2str(cur_year) '_Greenland*']);
    if iscell(str_cell)
        for i=1:size(str_cell, 2)
            if exist([cresisroot dirname '/kml_good/Browse_' dirname '.kml'], 'file')
                [~, dirname]=fileparts(str_cell{i});
                fid=fopen([outputroot 'temptxt.txt'], 'w+');
                xdoc=xmlread([cresisroot dirname '/kml_good/Browse_' dirname '.kml']);
                kmlstring=xmlwrite(xdoc);
                parsekmlstr;
                fclose(fid);
                %if you want polar stereographic
                [status result]=system(['python /home/chenpa/documents/pythonscripts/deg2pst.py -f '...
                    outputroot 'temptxt.txt -o ' outputroot dirname '.pst']);
                %For UTM
                %lonlatz2xyz([outputroot 'temptxt.txt'], [outputroot dirname '.utm']);
                if status
                    error(['error--' result])
                end
                [status result]=system(['rm ' outputroot 'temptxt.txt']);
                if status
                    error(['error--' result])
                end
                disp([outputroot dirname '.pst created'])
            end
        end
    end
end

if wait_bar
    close(wbh)
    etime=toc;
    esecs=mod(etime, 60);
    emins=mod(etime-esecs,3600)/60;
    ehours=etime-esecs-emins*60;
    disp(['Data parsed and copied from CRESIS portal in '...
        num2str(ehours) ' hours, ' num2str(emins) ' minutes, and ' num2str(esecs) ' seconds']);
end