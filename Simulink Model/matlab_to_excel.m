%% Post-process logsout → RMS over 25 ms windows and export to Excel
% Assumes your simulation result is in variable out with out.logsout

% 1) Parameters
tStart   = 1.3;         % windowing start time (s)
dtWindow = 0.025;       % window length (s)
tEnd     = 2.5;         % windowing end time (s)

% 2) Grab logsout
logs   = out.logsout;
nSigs  = logs.numElements;

% 3) Time edges for windows
edges = tStart:dtWindow:tEnd;               % 1.3, 1.325, ..., 2.5
nWins = numel(edges)-1;                     % number of windows

% 4) Prepare feature names by probing first window
firstSig = logs.get(1);
Tfull    = firstSig.Values.Time;
Yfull    = firstSig.Values.Data;
nChans   = size(Yfull,2);

featNames = {};
for i = 1:nSigs
    sig  = logs.get(i);
    base = matlab.lang.makeValidName(sig.Name);
    nC   = size(sig.Values.Data,2);
    for c = 1:nC
        featNames{end+1} = sprintf('%s_C%d_RMS', base, c);
    end
end

% 5) Preallocate output
% Columns: WindowIdx, WindowEndTime, then all RMS features
data = zeros(nWins, 2 + numel(featNames));

% 6) Compute RMS for each window
for w = 1:nWins
    t0 = edges(w);
    t1 = edges(w+1);
    % record window end time
    data(w,1) = w;
    data(w,2) = t1;
    
    col = 3;  % column index in data
    for i = 1:nSigs
        sig = logs.get(i);
        T   = sig.Values.Time;
        Y   = squeeze(sig.Values.Data);  % [nTime × nCh]
        mask = (T >= t0) & (T < t1);
        for c = 1:size(Y,2)
            ywin = Y(mask,c);
            data(w,col) = sqrt(mean(ywin.^2));  % RMS
            col = col + 1;
        end
    end
end

% 7) Build table and export
varNames = [{'WindowIdx','WindowEnd_s'}, featNames];
T = array2table(data, 'VariableNames', varNames);
writetable(T, 'DC_13_0.01.xlsx'); % edit the file name as per the fault parameters

fprintf('Exported %d windows × %d features → HVDC_RMS_25ms_1p3_2p5.xlsx\n', ...
        nWins, size(data,2));