function s = minScale(f1,f2)
    s= fminsearch(@(x) sum ( abs (f1-f2.*x)),0);
end
