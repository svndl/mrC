function DefaultVal = mrC_DefaultChartVals( ChartFieldName, ItemFlag )
% DefaultVal = mrC_DefaultChartVals( ChartFieldName, ItemFlag )
% ItemFlag = true for Item, false for Sel

switch ChartFieldName
case 'ROItypes'
	if ItemFlag
		DefaultVal = { 'Mean', 'SVD' };
	else
		DefaultVal = 1;
	end
case 'Hems'
	if ItemFlag
		DefaultVal = { 'Bilat', 'Left', 'Right' };
	else
		DefaultVal = 2:3;
	end
otherwise
	DefaultVal = [];
end

