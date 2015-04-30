%this program reads in a jpeg image into matlab and plots the red channel (of
%rgb) values with a 256 point colourmap. Doing this allows you to check
%whether the camera is saturating at the current settings.

%read in the image - put your file path here
filename = '/Logitech Webcam/Picture 19.jpg';
path = [fileparts(mfilename('fullpath')), filename];
data=imread(path ,'jpg');


%takes the red channel only
spot=data(:,:,1)';

% Find maximum intensity
maxIntensity = 0;
[imgWidth, imgHeight] = size(spot);
for i = 1:imgWidth,
    for j = 1:imgHeight,
        if spot(i, j) > maxIntensity
            maxIntensity = spot(i, j);
        end  
    end
end

% Display coverage % of maximum intensity value
coverage = sum(spot(:) == maxIntensity) / (imgHeight * imgWidth);

maxIntensity
coverage 

% Calculate a bounding rect of the high intensity area
top = 1;
bottom = imgHeight - 1;
left = 1;
right = imgWidth - 1;
threshold = 0.05 * maxIntensity;

maxLine = 0;
while maxLine < threshold
    % Do top
    maxLine = 0;
    for i = 1:imgWidth,
        maxLine = max(spot(i, top), maxLine);
    end
    if maxLine < threshold
        top = top + 1;
    end
end

maxLine = 0;
while maxLine < threshold
    % Do bottom
    maxLine = 0;
    for i = 1:imgWidth,
        maxLine = max(spot(i, bottom), maxLine);
    end
    if maxLine < threshold
        bottom = bottom - 1;
    end
end

maxLine = 0;
while maxLine < threshold
    % Do left
    maxLine = 0;
    for i = 1:imgHeight,
        maxLine = max(spot(left, i), maxLine);
    end
    if maxLine < threshold
        left = left + 1;
    end
end

maxLine = 0;
while maxLine < threshold
    % Do right
    maxLine = 0;
    for i = 1:imgHeight,
        maxLine = max(spot(right, i), maxLine);
    end
    if maxLine < threshold
        right = right - 1;
    end
end

% Estimate radius

radiusEstimateX = [];
radiusEstimateY = [];

for i = 1:(right - left),
    x1 = left + i;
    x2 = right - i;
    y1 = top;
    y2 = bottom;
    
    m = (x2 - x1) / (bottom - top);
    
    maxLine = 0;
    x = 0;
    y = 0;
    for j = 1:(bottom - top),
        y = j + top;
        x = floor( j * m + x1 );
        maxLine = max(spot(x, y), maxLine);
        if (maxLine > threshold), break; end
    end
    
    radiusEstimateX = [radiusEstimateX x];
    radiusEstimateY = [radiusEstimateY y];
    
        
    maxLine = 0;
    x = 0;
    y = 0;
    for j = 1:(bottom - top),
        y = bottom - j;
        x = floor( j * m + x1 );
        maxLine = max(spot(x, y), maxLine);
        if (maxLine > threshold), break; end
    end
    
    radiusEstimateX = [radiusEstimateX x];
    radiusEstimateY = [radiusEstimateY y];
    
end

for i = 1:(bottom - top),
        
    x1 = left;
    x2 = right;
    y1 = top + i;
    y2 = bottom - i;
    
    m = (y2 - y1) / (right - left);
    
    maxLine = 0;
    x = 0;
    y = 0;
    for j = 1:(right - left),
        y = floor( j * m + y1 );
        x = left + j;
        maxLine = max(spot(x, y), maxLine);
        if (maxLine > threshold), break; end
    end
    
    radiusEstimateX = [radiusEstimateX x];
    radiusEstimateY = [radiusEstimateY y];
    
        
    maxLine = 0;
    x = 0;
    y = 0;
    for j = 1:(right - left),
        y = floor( j * m + y1 );
        x = right - j;
        maxLine = max(spot(x, y), maxLine);
        if (maxLine > threshold), break; end
    end
    
    radiusEstimateX = [radiusEstimateX x];
    radiusEstimateY = [radiusEstimateY y];
    
end

% Least squares regression
uc = mean(radiusEstimateX);
vc = mean(radiusEstimateY);
u = radiusEstimateX - uc;
v = radiusEstimateY - vc;
%Su = sum(u);
%Sv = sum(v);
Suu = sum(u.^2);
Svv = sum(v.^2);
Suv = sum(u.*v);
Suuu = sum(u.^3);
Svvv = sum(v.^3);
Suvv = sum(u.*v.^2);
Svuu = sum(v.*u.^2);

b = [0.5 * (Suuu + Suvv), 0.5 * (Svvv + Svuu)];
A = [Suu  Suv,...
     Suv  Svv];

x = A \ b; 

cx = x(1) + uc; 
cy = x(2) + vc;
a = x(1)^2 + x(2)^2 + (Suu + Svv) / size(radiusEstimateX, 2);
radius = sqrt(a);
radius

% std dev
%s = sqrt(...
%    sum(...
%    (sqrt((radiusEstimateX - cx).^2 + (radiusEstimateY - cy).^2) - radius).^2) / ...
%    (size(radiusEstimateX, 2) - 1));
s = std(sqrt((radiusEstimateX - cx).^2 + (radiusEstimateY - cy).^2) - radius);
uncertainty = s / sqrt(size(radiusEstimateX, 2));
uncertainty

%plot image of red channel counts
figure(1)
image(spot')
colormap(hot(256))
colorbar
grid on
hold on
xlabel('pixels')
ylabel('pixels')
title('Red intensity image of output spot.')

xdata = [left, right, right, left];
ydata = [top, top, bottom, bottom];
cdata = [0, 0, 0, 0];
p = patch(xdata,ydata,cdata,'Marker','o',...
          'MarkerFaceColor','flat',...
          'FaceColor','none');
set(p,'EdgeColor','g');

plot(radiusEstimateX, radiusEstimateY, '+');

rectangle(...
    'Position',[cx - radius, cy - radius, radius*2, radius*2],...
    'Curvature',[1,1], ...
    'EdgeColor', 'w');
