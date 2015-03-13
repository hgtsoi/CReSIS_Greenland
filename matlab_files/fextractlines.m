function [ success_ratio ] = fextractlines( varargin )

filename=varargin{1};
elines=varargin{2};
if isequal(elines, [0 0])
    display('No lines to extract, exiting...');
    return;
end
fidin=fopen(filename);
if (size(varargin,2)==3)
    fidout=fopen([varargin{3}], 'w');
else
    fidout=fopen([filename '.extract'], 'w');
end
lines_extracted=0;
lin_num=1;
line_str=fgetl(fidin);
elines=sortrows(elines);
for lineset=1:size(elines,1)
    if elines(lineset,1)>elines(lineset,2)
        disp(['Invalid line set: lines ' elines(lineset,1) ' to ' ...
            elines(lineset,2) ' are ignored.'])
    else
        %get to the target line
        lineset
        eatnum=elines(lineset, 1)-lin_num;
        if eatnum<50000
            for i=1:eatnum
                line_str=fgetl(fidin);
                lin_num=lin_num+1;
            end
        else
            segsize=eatnum+lin_num-1;
            [status, result] = system( ['split -d -a 5 -l ' num2str(segsize) ' ' filename ' ' filename '.TMP1']);
            if status
                faulty_eatnum=eatnum
                faulty_segsize=segsize
                error(['split error: ' result]);
            else
                disp('Split success!');
            end
            [status, result] = system( ['ls ' filename '.TMP1* | wc -l']);
            if status
                error(['wc/ls error: ' result]);
            end
            numsplit=str2double(result);
            lastsplit=floor(elines(size(elines,1),2)/eatnum)+1;
            [status, result] = system( ['rm ' filename '.TMP100000']);
            if status
                error(['rm error: ' result]);
            end
            for i=numsplit:lastsplit
                [status, result] = system( ['rm ' filename '.TMP' num2str(i+99999)]);
                if status
                    error(['rm error: ' result]);
                end
            end
            fpath=pathname(filename);
            [status, result] = system( ['cat ' filename '.TMP1* > '...
                fpath 'EXTRACTTMP.txt']);
            if status
                error(['cat error: ' result]);
            end
            [status, result] = system( ['rm ' filename '.TMP1*']);
            if status
                error(['rm error: ' result]);
            end
            fclose(fidin);
            filename=[fpath 'EXTRACTTMP.txt'];
            fidin=fopen(filename);
            lin_num=1;
            line_str=fgetl(fidin);
            elines=elines-segsize
            lineset
        end
        %read the given line set
        fprintf(fidout, '%s\n', line_str);
        lines_extracted=lines_extracted+1;
        readnum=elines(lineset,2)-elines(lineset,1);        
        for i=1:readnum
            line_str=fgetl(fidin);
            lin_num=lin_num+1;
            lines_extracted=lines_extracted+1;
            fprintf(fidout, '%s\n', line_str);
        end
    end
end
planned_extractions=sum(elines(:,2))-sum(elines(:,1))+size(elines,1);
success_ratio=lines_extracted/planned_extractions;
fclose(fidin);
fclose(fidout);
if isequal(filename, [fpath 'EXTRACTTMP.txt']')
    [status, result] = system( ['rm ' fpath 'EXTRACTTMP.txt']);
    if status
        display(['rm error: ' result]);
    end
end
end