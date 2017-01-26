function [errVal] = jackKnifeErr(subsampleValues)
% [errVal] = jackKnifeErr(subsampleValues)
% 
% calculate the jackknifed error value on a statistic, using its values 
% calculated on all possible leave-one-out subsets, which should be supplied
% in subsampleValues. This statistic could be, for example, the mean of a
% dataset. To construct subsampleValues, you would calculate the mean for
% each subset where a single participant has been removed and store the
% subset means in subsampleValues. In this context, a more likely statistic
% would be the onset value. To get a jackknifed error estimate on the onset
% time for an ERP, you would calculate onset times for each average ERP
% where one participant was left out and supply those onset times in
% subsampleValues.
% 
% For an experiment with N subjects, there should be N entries in subsampleValues,
% one statistic for each leave-one-out subset.
%
% This code is based on Equation 2 of Miller, Ulrich, & Schwartz (2009),
% Why jackknifing yields good latency estimates, Psychophysiology, 46,
% 300-312.

errVal = nan;
grandMean = mean(subsampleValues);
if any(isnan(subsampleValues))
    fprintf('subsampleValues may not contain NaN. Returning NaN for jack knife error estimate...\n');
else
    N = length(subsampleValues);
    errVal = sqrt( ((N-1)/N) * sum( (subsampleValues - grandMean).^2 ) );
end