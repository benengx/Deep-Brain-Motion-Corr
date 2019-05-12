function p2 = make_gauss_square_image(numk,sigma)

if nargin<2
    sigma=1;
end

[X1,X2] = meshgrid(linspace(-3,3,numk)',linspace(-3,3,numk)');
X = [X1(:) X2(:)];
p = mvnpdf(X,[0 0],[sigma 0;0 sigma]);
p2 = reshape(p,numk,numk);
p2 = p2/sum(sum(p2));