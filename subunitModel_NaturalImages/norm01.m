function y = norm01(x,p)
 % normalize so that p percentile is 1 
 yp = prctile(x,p);
 y = (x-min(x))./(yp-min(x));
end
