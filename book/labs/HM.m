function [ hm ] = HM(fn)

%  HM unpacks the CSV files from rtl_power
%
%     d = HM('scan_file.csv')
%
%  where scan_file.csv was produced by rtl_power
%
%  d is a 2D array with time on the vertical axis, and frequency on the
%  horizontal axis
%
%  Value in d are in dBm and typically range from -40 to zero
%
%  Display with
%
%     imshow(d,[-40 0]);
%


% skip the first two text columns that matlab can't deal with
% read the rest into d
d = csvread(fn,0,2);

% dimension of the csv array
[nr nc] = size(d);

% find how many rows there are per timepoint, and the frequency range
nrb = 1;
minf = d(1,1);
maxf = minf;
for jj = 2:nr,
    if d(jj,1) >  maxf,
        maxf = d(jj,1);
        nrb = jj;
    else
        break;
    end
end

% Find the dimension of the heatmap image.  The data starts in column 5
nrh = floor(nr/nrb);
nc1 = (nc-4);
nch = nc1*nrb;

% allocate the space for the heatmat image
hm = zeros(floor(nr/nrb), nc1*nrb);

% Put the data for each row of the csv file in the right place in the
% heatmap image
for ii=1:nrh,
    for jj = 1:nrb,
        hm(ii, (1 + (jj-1)*nc1):(jj*nc1)) = d((ii-1)*nrb+jj, (5:nc));
    end;
end;


end

