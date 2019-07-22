function LSS_stabilized = StabilizedLSS(LSS, AbsoluteLSS_threshold, medfiltValue)

LSS_stabilized = LSS;

for n = 1:size(LSS, 2)
    
DLSS = abs(diff(LSS(:, n)));

ShiftedPoints = find(abs(LSS(:, n))>AbsoluteLSS_threshold);

LSS_stabilized(ShiftedPoints, n) = LSS(ShiftedPoints, n) - median(LSS(end - 10,n));

OvershootPoint = find(diff(LSS_stabilized(:, n)) > AbsoluteLSS_threshold/2);

LSS_stabilized(OvershootPoint, n) = 0;

LSS_stabilized(:, n) = medfilt1(LSS_stabilized(:, n), medfiltValue);

end

