% frames_to_take: 0 - all, 1 - odd frames (green channel), 2 - even frames (red channel)

function [ImageStack,InfoImage] = loadTiffStack_single(filename,frames_to_take,MaxNumFrames)

if nargin<2
    frames_to_take=0;
end
if nargin<3
    MaxNumFrames=Inf;
end

InfoImage=imfinfo(filename);
mImage=InfoImage(1).Width;
nImage=InfoImage(1).Height;
imagemode = 'single';

switch frames_to_take
    case 0
        inds_to_take = 1:length(InfoImage);
    case 1
        inds_to_take = 1:2:length(InfoImage);
    case 2
        inds_to_take = 2:2:length(InfoImage);
end

NumberImages=min(length(inds_to_take),MaxNumFrames);
ImageStack=zeros(nImage,mImage,NumberImages,imagemode);
for i=1:NumberImages
    ImageStack(:,:,i)=imread(filename,inds_to_take(i));
end
InfoImage=InfoImage(inds_to_take(1:NumberImages));
