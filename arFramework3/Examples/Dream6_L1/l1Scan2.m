% L1 scan
% jks       relative parameters to be investigated by L1 regularization
% linv      width, i.e. inverse slope of L1 penalty (Inf = no penalty; small values = large penalty)
% gradient  use a small gradient on L1 penalty ([-1 0 1]; default = 0)
%
% This script was used for Steiert et al. 2016. It is recommended to use
% this script only to reproduce the results. For your own project, please
% use D2Ds standard l1Scan.

function l1Scan2(jks, linv, gradient)

global ar

if(isempty(ar))
    error('please initialize by arInit')
end

if(~exist('jks','var') || isempty(jks))
    jks = find(ar.type == 3);
    if(isempty(jks))
        error('please initialize by l1Init')
    end
end

if(~exist('linv','var') || isempty(linv))
    linv = logspace(-4,4,49);
    linv = [linv Inf];
    linv = linv(end:-1:1);
end
ar.L1linv = linv;

if(~exist('gradient','var') || isempty(gradient))
    gradient = 0;
end

jks = sort(jks);
optim = ar.config.optimizer;
maxiter = ar.config.optim.MaxIter;

arWaitbar(0);
try
    arFit(true)
catch exception
    fprintf('%s\n', exception.message);
end

ps = nan(length(linv),length(ar.p));
chi2s = nan(1,length(linv));
chi2fits = nan(1,length(linv));

ps(1,:) = ar.p;
chi2s(1) = ar.chi2+ar.chi2err-ar.chi2prior;
chi2fits(1) = ar.chi2./ar.config.fiterrors_correction+ar.chi2err;
for i = 2:length(linv)
    arWaitbar(i, length(linv), sprintf('L1 scan'));
    ar.std(jks) = linv(i) * (1 + gradient * linspace(0,.001,length(jks)));
    try
        ar.config.optimizer = 1;
        ar.config.optim.MaxIter = 1000;
        arFit(true)
    catch exception
        fprintf('%s\n', exception.message);
    end
    ps(i,:) = ar.p;
    chi2s(i) = ar.chi2+ar.chi2err-ar.chi2prior;
    chi2fits(i) = ar.chi2./ar.config.fiterrors_correction+ar.chi2err;
    
    if sum(abs(ps(i,jks)) > 1e-6) == 0;
        ps(i+1:end,:) = repmat(ar.p,size(ps,1)-i,1);
        chi2s(i+1:end) = ar.chi2+ar.chi2err-ar.chi2prior;
        chi2fits(i+1:end) = ar.chi2./ar.config.fiterrors_correction+ar.chi2err;
        break
    end
    if i == length(linv)
        ar.p(jks) = 0;
        arChi2
        ps(i,:) = ar.p;
        chi2s(i) = ar.chi2+ar.chi2err-ar.chi2prior;
        chi2fits(i) = ar.chi2./ar.config.fiterrors_correction+ar.chi2err;
    end
end

arWaitbar(-1);

ar.L1ps = ps;
ar.L1chi2s = chi2s;
ar.L1chi2fits = chi2fits;

ar.config.optimizer = optim;
ar.config.optim.MaxIter = maxiter;

