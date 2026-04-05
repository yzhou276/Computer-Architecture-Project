% Compare SV non-restoring integer sqrt results against MATLAB reference
% Input files:
%   nonrestoring_isqrt_test_values.txt
%   nonrestoring_isqrt_results.txt
%
% Expected CSV columns:
%   test_value,floor_sqrt,remainder,dut_root,dut_remainder,result

clear;
clc;

%% Read original test values
test_vals = readmatrix('nonrestoring_isqrt_test_values.txt', 'FileType', 'text');
test_vals = test_vals(:);

%% Read SV results
T = readtable('nonrestoring_isqrt_results.txt');
dut_root = T{1:length(test_vals), 4}; 
dut_rem  = T{1:length(test_vals), 5}; 

%% MATLAB reference
ref_root = zeros(size(test_vals), 'uint32');
ref_rem  = zeros(size(test_vals), 'uint32');

for k = 1:numel(test_vals)
    x = uint64(test_vals(k));
    r = uint32(floor(sqrt(double(x))));
    rem = uint32(x - uint64(r) * uint64(r));

    ref_root(k) = r;
    ref_rem(k)  = rem;
end

%% Check lengths
if numel(dut_root) ~= numel(ref_root)
    error('Mismatch in number of root results: test file has %d values, SV file has %d values.', ...
        numel(ref_root), numel(dut_root));
end

if numel(dut_rem) ~= numel(ref_rem)
    error('Mismatch in number of remainder results: test file has %d values, SV file has %d values.', ...
        numel(ref_rem), numel(dut_rem));
end

%% Compare
root_match = (uint32(dut_root) == ref_root);
rem_match  = (uint32(dut_rem)  == ref_rem);
match      = root_match & rem_match;

num_err = sum(~match);

fprintf('Total tests            : %d\n', numel(ref_root));
fprintf('Root mismatches        : %d\n', sum(~root_match));
fprintf('Remainder mismatches   : %d\n', sum(~rem_match));
fprintf('Total vector mismatches: %d\n', num_err);

if num_err == 0
    fprintf('All RTL non-restoring sqrt results match MATLAB reference.\n');
else
    fprintf('\nFirst mismatches:\n');
    idx = find(~match);

    for i = 1:min(20, numel(idx))
        k = idx(i);
        fprintf(['Index %d: x = %u, RTL root = %u, REF root = %u, ', ...
                 'RTL rem = %u, REF rem = %u\n'], ...
            k, test_vals(k), dut_root(k), ref_root(k), dut_rem(k), ref_rem(k));
    end
end