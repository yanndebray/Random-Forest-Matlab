% forestdemo.m
% ------------------------------------------------------------
% Random-forest demo on a three-class spiral, coloured with parula
% ------------------------------------------------------------

%% 1. Generate data
prettySpiral = true;   % switch to false for Gaussian blobs

if ~prettySpiral
    % ----- three Gaussian clusters -----
    rng('default');                                 % reproducible
    N = 50;  D = 2;
    X1 = mgd(N, D, [4  3], [2 -1; -1 2]);
    X2 = mgd(N, D, [1  1], [2  1;  1 1]);
    X3 = mgd(N, D, [3 -3], [1  0;  0 4]);
    X  = [X1; X2; X3];
else
    % ----- pretty three-arm spiral -----
    N = 50;
    t  = linspace(0.5, 2*pi, N);
    x1 = t .* cos(t);      y1 = t .* sin(t);
    x2 = t .* cos(t+2);    y2 = t .* sin(t+2);
    x3 = t .* cos(t+4);    y3 = t .* sin(t+4);
    X  = [[x1' y1']; [x2' y2']; [x3' y3']];
end

% Centre & rescale (optional, helps RF heuristics)
X = (X - mean(X)) ./ var(X);

% Labels 1-3
Y = [ones(N,1); 2*ones(N,1); 3*ones(N,1)];

% Quick preview (optional)
% scatter(X(:,1), X(:,2), 20, Y, 'filled');

%% 2. Train a random forest
rng('default');
opts.depth         = 9;
opts.numTrees      = 100;
opts.numSplits     = 5;
opts.verbose       = true;
opts.classifierID  = 2;     % randomised weak learner id

tic
m = forestTrain(X, Y, opts);
timetrain = toc;

tic
yhatTrain = forestTest(m, X);
timetest  = toc;

%% 3. Prepare a grid for visualisation
xrange = [-1.5 1.5];
yrange = [-1.5 1.5];
inc    = 0.02;

[xg, yg]   = meshgrid(xrange(1):inc:xrange(2), yrange(1):inc:yrange(2));
image_size = size(xg);
xy         = [xg(:) yg(:)];

% Hard labels & soft probabilities on the grid
[yhatGrid, ysoftGrid] = forestTest(m, xy);
decmapHard = reshape(yhatGrid, image_size);          % H×W
decmapSoft = reshape(ysoftGrid, [image_size 3]);     % H×W×3  (will re-mix)

%% 4. Parula colour map setup
paru = parula(3);    % three discrete hues

% Blend soft probabilities into RGB using parula rows
RGBsoft = reshape(ysoftGrid * paru, [image_size 3]); % H×W×3 true colour

%% 5. Plot
figure('Position',[100 100 1000 600]);

% ----- (a) Hard decision regions ---------------------------------
subplot(1,2,1);
imagesc(xrange, yrange, decmapHard);
set(gca,'YDir','normal');
colormap(gca, paru);         % map class 1-3 to parula rows
clim([1 3]);                % ensure correct mapping
hold on;
plot(X(Y==1,1), X(Y==1,2), 'o', ...
     'MarkerFaceColor', paru(1,:), 'MarkerEdgeColor','k');
plot(X(Y==2,1), X(Y==2,2), 'o', ...
     'MarkerFaceColor', paru(2,:), 'MarkerEdgeColor','k');
plot(X(Y==3,1), X(Y==3,2), 'o', ...
     'MarkerFaceColor', paru(3,:), 'MarkerEdgeColor','k');
hold off;
axis equal tight            % <-- ISO VIEW
title(sprintf('%d trees  |  Train: %.2fs  |  Test: %.2fs', ...
               opts.numTrees, timetrain, timetest));
xlabel('x'); ylabel('y');

% ----- (b) Soft-probability blend --------------------------------
subplot(1,2,2);
imagesc(xrange, yrange, RGBsoft);         % already true-colour
set(gca,'YDir','normal');
hold on;
plot(X(Y==1,1), X(Y==1,2), 'o', ...
     'MarkerFaceColor', paru(1,:), 'MarkerEdgeColor','k');
plot(X(Y==2,1), X(Y==2,2), 'o', ...
     'MarkerFaceColor', paru(2,:), 'MarkerEdgeColor','k');
plot(X(Y==3,1), X(Y==3,2), 'o', ...
     'MarkerFaceColor', paru(3,:), 'MarkerEdgeColor','k');
hold off;
axis equal tight            % <-- ISO VIEW
title(sprintf('Train accuracy: %.3f', mean(yhatTrain==Y)));
xlabel('x'); ylabel('y');

% ------------------------------------------------------------
% End of script
% ------------------------------------------------------------
