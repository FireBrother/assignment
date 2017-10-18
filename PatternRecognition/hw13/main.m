data = load('swiss-data.txt');
row1 = find(data(:,1)==1);
row2 = find(data(:,1)==2);
row3 = find(data(:,1)==3);
figure(1)
plot3(data(row1,2), data(row1,3), data(row1,4), 'ro');
hold on
plot3(data(row2,2), data(row2,3), data(row2,4), 'go');
hold on
plot3(data(row3,2), data(row3,3), data(row3,4), 'bo');
title('3d');
print -dpng '3d.png'

% pca_by_package
pkg load statistics % octave needs an additional package named statistics
[COEFF,SCORE,latent] = princomp(data(:,2:4));
figure(2)
plot(SCORE(row1,1), SCORE(row1,2), 'rx');
hold on
plot(SCORE(row2,1), SCORE(row2,2), 'gx');
hold on
plot(SCORE(row3,1), SCORE(row3,2), 'bx');
title('pca_by_package');
print -dpng 'pca_by_package.png'

%pca_by_svd
mu = mean(data(:,2:4));
Xm = bsxfun(@minus, data(:,2:4), mu);
C = Xm'*Xm;
[V, D] = eig(C);
[D, i] = sort(diag(D), 'descend');
V = V(:,i);
proj = Xm * V(:,[1,2]);
figure(3)
plot(proj(row1,1), proj(row1,2), 'rx');
hold on
plot(proj(row2,1), proj(row2,2), 'gx');
hold on
plot(proj(row3,1), proj(row3,2), 'bx');
title('pca_by_svd');
print -dpng 'pca_by_svd.png'

%lda
mu_total = mean(data(:,2:4));
mu = [mean(data(row1,2:4)); mean(data(row2,2:4)); mean(data(row3,2:4))];
Sw = (data(:,2:4) - mu(data(:,1),:))'*(data(:,2:4) - mu(data(:,1),:));
Sb = (ones(3,1) * mu_total - mu)' * (ones(3,1) * mu_total - mu);
[V, D] = eig(Sw\Sb);
[D, i] = sort(diag(D), 'descend');
V = V(:,i);
Xm = bsxfun(@minus, data(:,2:4), mu_total);
proj = Xm*V(:,[1,2]);
figure(4)
plot(proj(row1,1), proj(row1,2), 'rx');
hold on
plot(proj(row2,1), proj(row2,2), 'gx');
hold on
plot(proj(row3,1), proj(row3,2), 'bx');
title('lda');
print -dpng 'lda.png'
