function FPOR(argtxt)
%FilePlotOffsetRoughness returns the number of tracks in the pond data set 
%and matrices for coordinates of a graph of the satellite tracks along
%with roughness values offset perpendicularly from the tracks. The function 
%reads its arguments from a text file.

%The program reads the argument file skipping labels
fid=fopen(argtxt);

fscanf(fid, '%s', 1);
filename=fscanf(fid, '%s', 1);

fscanf(fid, '%s %[[]', 2);
tracks=fscanf(fid, '%f');
tracks=tracks';

fscanf(fid, '%s', 2);
graphtype=fscanf(fid, '%s', 1);

fscanf(fid, '%s', 1);
mirror=fscanf(fid, '%f', 1);

fscanf(fid, '%s', 1);
usertitle=fscanf(fid, '%s', 1);

fscanf(fid, '%s', 1);
scaling=fscanf(fid, '%f', 1);
if numel(scaling)<1
    scaling=fscanf(fid, '%s', 1);
elseif scaling==0
    scaling='default';
end

fscanf(fid, '%s%[ []', 2);
boundaries=fscanf(fid, '%f');
fscanf(fid, '%[] ]');

fscanf(fid, '%s %[[ ]', 2);
offsetRGB=fscanf(fid, '%f');
offsetRGB=offsetRGB';
fscanf(fid, '%[] ]');

fscanf(fid, '%s%[ []', 2);
jumpRGB=fscanf(fid, '%f');
jumpRGB=jumpRGB';
fscanf(fid, '%[] ]');

fscanf(fid, '%s%[ []',2);
trackRGB=fscanf(fid, '%f');
trackRGB=trackRGB';
fscanf(fid, '%[] ]');

fscanf(fid, '%s%[ []',2);
bgRGB=fscanf(fid, '%f');
bgRGB=bgRGB';
fclose(fid);


%Program checks that filename exists
fid=fopen(filename);                                 %opens the text file to file identification fid
if fid==-1
    errormsg=['File ' filename ' not found, check argument one.'];
    error(errormsg)     %Exits the program if file is not found.
else
    data=textscan(fid, '%f%f%f', 'CommentStyle', '#');       %reads the text file to a 1x3 cell array (x, y, and z) and ignores lines with # in front
    fclose(fid);                       %closes the text file
end
DataSize=size(data{1,1},1);       %records the number of x entries and assumes the number of total entries are the same
DataMatrix=zeros(DataSize,3);      %creates an nx3 matrix where n is the number of data points
DataMatrix(:,1)=data{1,1};              %inputs the x data into the matrix
DataMatrix(:,2)=data{1,2};              %inputs the y data into the matrix
DataMatrix(:,3)=data{1,3};          %inputs roughness data into matrix

%SlopeMatrix is the matrix with all the slopes of the tracks
SlopeMatrix=zeros(DataSize,3);
%The first element of SlopeMatrix is created seperately to have a reference
%to check further slopes against for the purpose of finding discontinuities
SlopeMatrix(1,1)=(DataMatrix(2,2)-DataMatrix(1,2))/(DataMatrix(2,1)-DataMatrix(1,1));
Breakpoints=1;			%Breakpoints keeps track of the number of discontinuities and counts the first point as a discontinuity
Jumppoints=1;
pathdistanceold=sqrt(((DataMatrix(2,2)-DataMatrix(1,2))^2)+(DataMatrix(2,1)-DataMatrix(1,1))^2);    %The distance between the first two points
%Here elements of SlopeMatrix are created by dividing the change in y by the change in x
for n=2:DataSize
    SlopeMatrix(n,1)=(DataMatrix(n,2)-DataMatrix(n-1,2))/(DataMatrix(n,1)-DataMatrix(n-1,1));
    pathdistance=sqrt(((DataMatrix(n,2)-DataMatrix(n-1,2))^2)+(DataMatrix(n,1)-DataMatrix(n-1,1))^2);
    %If the slope changes by more than 20%, it notes the number of breakpoints has increased and it notes there is a discontinuity within SlopeMatrix's second column with a 1
    if abs((SlopeMatrix(n,1)-SlopeMatrix(n-1,1))/(SlopeMatrix(n,1)))>.2
        Breakpoints=Breakpoints+1;
        SlopeMatrix(n,1)=(DataMatrix(n+1,2)-DataMatrix(n,2))/(DataMatrix(n+1,1)-DataMatrix(n,1));
        SlopeMatrix(n,2)=1;        
    end
    %If the distance between two points is more than twice that of the
    %previous distance, a jump is noted in SlopeMatrix and the number of
    %Jumppoints increases
    if abs(pathdistance-pathdistanceold)/pathdistanceold>1
        Jumppoints=Jumppoints+1;
        SlopeMatrix(n,3)=1;
    end
    pathdistanceold=pathdistance;
end

if tracks==0
    tracks=1:Breakpoints;
end
trackentries=size(tracks,2);
%Creates the BreakArray which is a vector with all the row numbers of discontinuities including row 1 and the last row
BreakArray=zeros(Breakpoints+1,1);      %The +1 is to add room to count the very last datapoint as a breakpoint
BreakArray(1)=1;
BreakArray(Breakpoints+1)=DataSize;
JumpMatrix=zeros(Jumppoints,2);        %If the very first or last data point is a jumppoint, this could be a problem
JumpMatrix(1,2)=1;
BreakPlace=0;		%This keeps track of the row within the for loop
BreakNumber=1;		%This keeps track of the number of slope discontinuities logged
JumpNumber=1;      %This keeps track of the number of position discontinuities logged
%A JumpMatrix is created that contains the row numbers of each jump point
%in the first column; a BreakArray is created that contains the row numbers
%of each break point. Every break point is a jump point, and the second
%column of the JumpMatrix notes which jump points are also break points and
%which break point they are.
for n=1:DataSize
    BreakPlace=BreakPlace+1;
    if SlopeMatrix(n,3)==1
        JumpNumber=JumpNumber+1;
        JumpMatrix(JumpNumber,1)=BreakPlace;
        if SlopeMatrix(n,2)==1
            BreakNumber=BreakNumber+1;
            BreakArray(BreakNumber)=BreakPlace;
            JumpMatrix(JumpNumber,2)=BreakNumber;
        end        
    end  
end
JumpMatrix(size(JumpMatrix,1),2)=Breakpoints+1;
%The OffsetArray keeps track of the ratio the y coordinates need to be offset compared to the x coordinates. I.E. y offset = (x offset)*OffsetArray
OffsetArray=zeros(DataSize,1);
%Uses trigonometry to find the ratio; see Day 3 notes for a diagram
for n=1:DataSize
    OffsetArray(n)=tan((pi/2)-atan(SlopeMatrix(n,1)));
end

%Here is where the scaling coefficient is determined; the SampleMatrix is a
%matrix including all the data actually being used
SampleMatrix=zeros(size(DataMatrix,1), 3);
sampleend=0;
for m=tracks
    samplestart=sampleend+1;
    sampleend=sampleend+BreakArray(m+1)-BreakArray(m);
    SampleMatrix(samplestart:sampleend, :)=DataMatrix(BreakArray(m):BreakArray(m+1)-1, :);
end
SampleMatrix=SampleMatrix(1:sampleend, :);
RoughnessAverage=mean(SampleMatrix(:, 3));
xlength=max(SampleMatrix(:,1))-min(SampleMatrix(:,1));
%RoughnessAverage=mean(roughness);
%xlength=max(DataMatrix(:,1))-min(DataMatrix(:,1));
if strcmp(scaling, 'default')
    if strcmp(graphtype, 'values')
        scaling=(1/200);
    elseif strcmp(graphtype, 'sqrt')
        scaling=(1/50);
    elseif strcmp(graphtype, 'log')
        scaling=(1/40);
    end
end
if scaling<1
if strcmp(graphtype, 'values')
        coefficient=scaling*xlength/RoughnessAverage;
elseif strcmp(graphtype, 'sqrt')
        coefficient=scaling*xlength/sqrt(RoughnessAverage);
elseif strcmp(graphtype, 'log')
        coefficient=scaling*xlength/log2(RoughnessAverage);
end
else
    coefficient=scaling;
end
%OffsetMatrix keeps track of the x and y displacements from the path
OffsetMatrix=zeros(size(DataMatrix));
%OffsetMatrix x values are processed here to create one of three
%linearization methods: values, square root, log
if strcmp(graphtype,'values')    
    OffsetMatrix(:,1)=coefficient*DataMatrix(:,3);
elseif strcmp(graphtype, 'sqrt')
    OffsetMatrix(:,1)=coefficient*sqrt(DataMatrix(:,3));
elseif strcmp(graphtype, 'log')
    minimum=min(log2(SampleMatrix(:,3)));
    OffsetMatrix(:,1)=coefficient*(log2(DataMatrix(:,3))-minimum);
end
for n=1:DataSize
    OffsetMatrix(n,2)=OffsetMatrix(n,1)*-1*OffsetArray(n);
end


%Prevents plots from overwriting eachother and creates a figure with a
%given size
if mirror<3
figure('Position', [1 512 640 512]);
set(gca, 'Color', bgRGB);
elseif mirror==3
    mirror=1;
end
hold on
%function plots tracks based on user inputted values starttrack and endtrack

for m=tracks+1
    %PlotMatrix2 plots the offset values by adding the offset matrix to the
    %path matrix; BreakArray is compared against its previous value to find
    %number of data points of the current track   
    PlotMatrix2=zeros((BreakArray(m)-BreakArray(m-1)), 2);
    %Here the entries are entered into the plot matrix along with a mirror
    %if symmetry is on
    PlotMatrix2(1:BreakArray(m)-BreakArray(m-1),1)=DataMatrix(BreakArray(m-1):BreakArray(m)-1,1)...
        + OffsetMatrix(BreakArray(m-1):BreakArray(m)-1,1);
    PlotMatrix2(1:BreakArray(m)-BreakArray(m-1),2)=DataMatrix(BreakArray(m-1):BreakArray(m)-1,2)...
        +OffsetMatrix(BreakArray(m-1):BreakArray(m)-1,2);
    if mirror>1
        MirrorMatrix=zeros((BreakArray(m)-BreakArray(m-1)), 2);
        MirrorMatrix(1:BreakArray(m)-BreakArray(m-1),1)=DataMatrix(BreakArray(m-1):BreakArray(m)-1,1)-OffsetMatrix(BreakArray(m-1):BreakArray(m)-1,1);
        MirrorMatrix(1:BreakArray(m)-BreakArray(m-1),2)=DataMatrix(BreakArray(m-1):BreakArray(m)-1,2)-OffsetMatrix(BreakArray(m-1):BreakArray(m)-1,2);
        plot(MirrorMatrix(:,1), MirrorMatrix(:,2),'Color', offsetRGB)
    end
    if mirror~=4
    plot(PlotMatrix2(:,1), PlotMatrix2(:,2),'Color', offsetRGB);
    end
end

%Uses the second column of JumpMatrix to find which jump points correspond
%to the selected tracks and writes them into JumpArray, a jump equivalent 
%for the tracks variable
tracknumber=1;
writing=0;
JumpArray=zeros(1, Jumppoints);
for n=1:Jumppoints

    if JumpMatrix(n,2)==tracks(tracknumber)
        writing=1;
        if tracknumber~=trackentries
        tracknumber=tracknumber+1;
        end
    elseif tracknumber~=1 && JumpMatrix(n,2)==tracks(tracknumber-1)+1
        writing=0;
    elseif JumpMatrix(n,2)==tracks(tracknumber)+1
        writing=0;
    end
    if writing==1
        JumpArray(n)=n;
    end
end
JumpArray=sort(JumpArray);
count=0;
for n=1:Jumppoints
    if JumpArray(n)~=0
        count=count+1;
    end
end

JumpArray=JumpArray(Jumppoints+1-count:Jumppoints);

%Creates different colored lines wherever the program has discovered jumps
for n=JumpArray
    index=JumpMatrix(n,1);
    if JumpMatrix(n,2)==0 && mirror~=3
        line([DataMatrix(index-1,1) + OffsetMatrix(index-1,1)...
         DataMatrix(index,1) + OffsetMatrix(index,1)],...
        [DataMatrix(index-1,2) + OffsetMatrix(index-1,2)...
         DataMatrix(index,2) + OffsetMatrix(index,2)],...
        'color', jumpRGB)
        if mirror>1                     %if symmetry is on, the lines are mirrored
         line([DataMatrix(index-1,1) - OffsetMatrix(index-1,1)...
         DataMatrix(index,1) - OffsetMatrix(index,1)],...
        [DataMatrix(index-1,2) - OffsetMatrix(index-1,2)...
         DataMatrix(index,2) - OffsetMatrix(index,2)],...
        'color', jumpRGB)
        end
    end
end

for m=tracks+1
    %PlotMatrix1 plots the track. BreakArray is checked against its
    %previous value to find the number of entries of the track
    PlotMatrix1=zeros((BreakArray(m)-BreakArray(m-1)), 2);
    %Here the entries are entered into the plot matrix
    %for n=1:BreakArray(m)-BreakArray(m-1)
        PlotMatrix1(1:BreakArray(m)-BreakArray(m-1),1)=DataMatrix(BreakArray(m-1):BreakArray(m)-1,1);
        PlotMatrix1(1:BreakArray(m)-BreakArray(m-1),2)=DataMatrix(BreakArray(m-1):BreakArray(m)-1,2);
    %end
    plot(PlotMatrix1(:,1), PlotMatrix1(:,2),'Color', trackRGB, 'LineWidth', 1.5);
    if strcmp(usertitle, 'label')
    text(PlotMatrix1(1,1),PlotMatrix1(1,2), num2str(m-1));
    end
end


%Allows new figures to overwrite the current figure again, and fixes the
%aspect ratio to be equal distances for x and y
hold off
axis equal
if size(boundaries,2)==4
   axis(boundaries)
elseif boundaries~=0
    disp(' ');
    disp('Insufficient axis boundaries given, default values used.')
end

%Creates the x and y labels and boxes the graph
words=[filename, '      ', date, '      ', graphtype];
variable_label = xlabel({'UTM East(m)', words});
ylabel('UTM North(m)');
set(variable_label, 'interpreter', 'none')
set(gca, 'Box', 'on');
%Checks whether the user has defined a title, and if not, titles the plot
%Jakobshavn Isbrae <year> GLAS Data pond
if strcmp(usertitle, 'default') || strcmp(usertitle, 'label')
    GraphTitle=strcat('Jakobshavn Isbrae 20', filename(7:8), ' GLAS Data pond');
    if trackentries~=1
        tracks=['tracks ', num2str(tracks),];
    else
        tracks=['track ', num2str(tracks)];
    end
    title({GraphTitle; tracks});
elseif strcmp(usertitle, 'image')~=1
    title(usertitle)
%If the title is 'image', the axes are removed and the plot is saved as an
%PostScript image and textfile with the name of the pond data as the name 
%of the file
else
    %without a user defined boundary, the image will be cropped as close as
    %possible
    if size(boundaries,2)~=4
    axis image              %crops the image so there is no empty space
    boundaries=axis;        %records the boundaries of the cropped image
    end
    axis off
    handle = gcf;
    print(handle, '-dpsc', '-r300', [filename '.ps'])
    disp(' ')
    disp(['Image created with name ', filename, '.ps']);
    txtid= fopen([filename '.txt'], 'wt');
    fprintf(txtid, '#xmin, xmax, ymin, ymax, linearization\n%f\n%f\n%f\n%f', boundaries);
    fprintf(txtid, '\n%s', graphtype);
    fclose(txtid);
    disp(['Text file created with name ', filename, '.txt']);
    close
end

%Outputs the number of tracks in a nice way
disp(' ');
disp([num2str(Breakpoints), ' track(s) detected.']);
disp(['Scaling coefficient of ', num2str(coefficient), ' used.'])
end


