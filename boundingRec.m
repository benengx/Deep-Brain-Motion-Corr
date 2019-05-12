% coordinates = [top left height width];

function [im_b,coordinates,roi_h,roi_w]=boundingRec(im)

v1=find(sum(abs(im),2),1,'first');
v2=find(sum(abs(im),2),1,'last' );
h1=find(sum(abs(im),1),1,'first');
h2=find(sum(abs(im),1),1,'last' );

im_b = im(v1:v2,h1:h2);

coordinates = [v1 h1];
roi_h = v2-v1+1;
roi_w = h2-h1+1;
