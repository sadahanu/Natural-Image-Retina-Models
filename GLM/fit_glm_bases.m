
%% fit GLM to data using basis vectors

% clearvars -except prs
fid = '/Users/alisonweber/Dropbox (uwamath)/Woods_Hole_Project'; % root directory for project

saveFlag = 0; % 0 or 1, save fit GLM

cellType = 4;  % choose from cell types below (as in Izhikevich)
noise = 0;  % 0 or 1, with or without noise
jitter = 0;
softRect = 1;  % 0 or 1, exponential NL is default (0), soft rect is log(1+e^x) (1)

maxIter = 100;  % maximum number of iterations for fminunc
maxFunEvals = maxIter;
tolFun = 1e-12; % function tolerance for fminunc
tolX = 1e-12;  % tolerance for step size
L2pen = 0;  % penalty on L2 norm

% 1. tonic spiking
% 2. phasic spiking
% 3. tonic bursting
% 4. phasic bursting
% 5. mixed mode
% 6. spike frequency adaptation
% 7. Class 1
% 8. Class 2
% 9. spike latency
% 10. subthreshold oscillations
% 11. resonator
% 12. integrator
% 13. rebound spike
% 14. rebound burst
% 15. threshold variability
% 16. bistability
% 17. DAP
% 18. accomodation
% 19. inhibition-induced spiking
% 20. inhibition-induced bursting


%% load izhikevich data
cids = {'RS' 'PS' 'TB' 'PB' 'MM' 'FA' 'E1' 'E2' 'SL' 'SO' 'R' 'I' 'ES' 'EB' 'TV' 'B' 'DA' 'A' 'IS' 'IB' 'B2' 'RS2'};  
cid = cids{cellType};
if noise
    cid = [cid '_noise'];
end
if jitter
    cid = [cid '_jitter'];
end

load([fid '/izhikevich_data/' cid '_iz.mat'])


%%

refreshRate = 1000/dt; % stimulus in ms, sampled at dt from izhikevich model

x = I;
y = spikes;



%% create basis functions and initialize parameters
% IMPORTANT NOTE: Stimulus filter is in same time units as the stimulus.
% Post-spike filter is in same time units as spikes.  
% Stimulus has units of 1, and spikes has units of dt.

nkt = 100;  % 100, number of ms in stim filter

%%% arbitrary number of basis functions for stimulus filter 
kbasprs.neye = 0; % Number of "identity" basis vectors near time of spike;
kbasprs.ncos = 9; % Number of raised-cosine vectors to use  
kbasprs.kpeaks = [0 round(nkt/1.2)];  % nkt/1.2, Position of first and last bump (relative to identity bumps)
kbasprs.b = 10; % 10, Offset for nonlinear scaling (larger -> more linear)
kbasisTemp = makeBasis_StimKernel(kbasprs,nkt); % need to rescale by dt
nkb = size(kbasisTemp,2);
lenkb = size(kbasisTemp,1);
kbasis = zeros(lenkb/dt,nkb);
for bNum = 1:nkb
    kbasis(:,bNum) = interp1([1:lenkb]',kbasisTemp(:,bNum),linspace(1,lenkb,lenkb/dt)');
end

%%% basis functions for post-spike kernel
ihbasprs.ncols = 9;  % Number of basis vectors for post-spike kernel
ihbasprs.hpeaks = [.1 100];  % [.1 100], Peak location for first and last vectors
ihbasprs.b = 6;  % How nonlinear to make spacings
ihbasprs.absref = 0; % absolute refractory period 
[ht,hbas,hbasis] = makeBasis_PostSpike(ihbasprs,dt); % dt of izhikevich data should determine relevant timescale of this basis
hbasis = [zeros(1,ihbasprs.ncols); hbasis]; % enforce causality: post-spike filter only affects future time points

nkbasis = size(kbasis,2); % number of basis functions for k
nhbasis = size(hbasis,2); % number of basis functions for h

prs = zeros(nkbasis+nhbasis+1,1); % initialize parameters

xconvki = zeros(size(y,1),nkbasis);
yconvhi = zeros(size(y,1),nhbasis);

for knum = 1:nkbasis
    xconvki(:,knum) = sameconv(x,kbasis(:,knum));
end

for hnum = 1:nhbasis
    yconvhi(:,hnum) = sameconv(y,flipud(hbasis(:,hnum)));
end

%% minimization (assumes exponential nonlinearity)

warning('off','optim:fminunc:SwitchingMethod') 
if softRect
    opts = optimset('gradobj','on','hessian','off','display','iter','maxfunevals',maxFunEvals,'maxiter',maxIter,'tolfun',tolFun,'tolX',tolX);
else
    opts = optimset('gradobj','on','hessian','on','display','iter','maxfunevals',maxFunEvals,'maxiter',maxIter,'tolfun',tolFun,'tolX',tolX);
end
if softRect
    NL = @logexp1;
    fneglogli = @(prs) negloglike_glm_basis_softRect(prs,NL,xconvki,yconvhi,y,1,refreshRate);
else
    NL = @exp;
    fneglogli = @(prs) negloglike_glm_basis(prs,NL,xconvki,yconvhi,y,1,refreshRate,L2pen);
end

%% optimization
prs = fminunc(fneglogli,prs,opts);
nll_at_min = fneglogli(prs);  % negative log likelihood at minimum found by fminunc
%%
%%% calculate filters from basis fcns/weights
k = kbasis*prs(1:nkbasis); % k basis functions weighted by given parameters
h = hbasis*prs(nkbasis+1:end-1); % k basis functions weighted by given parameters
dc = prs(end); % dc current (accounts for mean spike rate)
 
%% plot results
figure; 
subplot(2,2,1); hold on;
for i = 1:size(kbasis,2)
    plot(kbasis(:,i))
end
xlim([1 length(k)])
subplot(2,2,3)
plot(k)
xlim([1 length(k)])
set(gca,'xtick',0:25/dt:length(k),'xticklabel',-length(k)*dt:25:0)
xlabel('time (ms)')
title('stimulus filter')

subplot(2,2,2); hold on;
for i = 1:size(hbasis,2)
    plot(hbasis(:,i))
end
xlim([1 length(h)])
subplot(2,2,4)
plot(h)
xlim([1 length(h)])
set(gca,'xtick',0:25/dt:length(h),'xticklabel',0:25:length(h)*dt)
xlabel('time (ms)')
title('post-spike filter')

%% save
tag = '';
if softRect
    tag = [tag '_sr'];
end
if saveFlag
    save([fid '/glm_fits/' cid tag '_glmfit.mat'],'maxIter','maxFunEvals','tolFun','tolX','cellType','cid','refreshRate','x','y','prs','NL','kbasis','hbasis','kbasprs','ihbasprs')
    disp(['saved: ' fid '/glm_fits/' cid tag '_glmfit.mat'])
end
