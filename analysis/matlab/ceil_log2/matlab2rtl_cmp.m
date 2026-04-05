% Compare SV ceil_log2 results against MATLAB reference
% Input files:
%   ceil_log2_test_values.txt
%   ceil_log2_sv_results.txt

clear;
clc;

%% Read original test values
test_vals = readmatrix('ceil_log2_test_values.txt', 'FileType', 'text');
test_vals = test_vals(:);

%% Read SV results CSV
T = readtable('ceil_log2_sv_results.txt', 'Delimiter', ',');

% Assume third column is DUT output
dut_vals = T{1:length(test_vals),3};

%% MATLAB reference: ceil(log2(x))
ref_vals = zeros(size(test_vals));

for k = 1:numel(test_vals)
    x = test_vals(k);

    if x <= 1
        ref_vals(k) = 0;
    else
        ref_vals(k) = ceil(log2(double(x)));
    end
end

%% Check lengths
if numel(dut_vals) ~= numel(ref_vals)
    error('Mismatch in number of results: test file has %d values, SV file has %d values.', ...
        numel(ref_vals), numel(dut_vals));
end

%% Compare
match = (dut_vals == ref_vals);
num_err = sum(~match);

fprintf('Total tests    : %d\n', numel(ref_vals));
fprintf('Mismatches     : %d\n', num_err);

if num_err == 0
    fprintf('All RTL results match MATLAB ceil(log2()).\n');
else
    fprintf('\nFirst mismatches:\n');
    idx = find(~match);

    for i = 1:min(20, numel(idx))
        k = idx(i);
        fprintf('Index %d: x = %u, RTL = %u, REF = %u\n', ...
            k, test_vals(k), dut_vals(k), ref_vals(k));
    end
end