%% Representative test for integer ceil_log2
% Saves:
%   1) CSV with results
%   2) TXT with test values
%   3) TXT summary
%
% Main output:
%   ceil_log2_representative_test.csv

clear;
clc;

%% Build representative 32-bit test set
tests = uint64([]);

% Small exhaustive range
tests = [tests, uint64(0:256)];

% Around powers of two
for k = 0:32
    p = uint64(2)^k;
    for d = [-2 -1 0 1 2]
        v = int64(p) + d;
        if v >= 0 && v <= int64(hex2dec('FFFFFFFF'))
            tests(end+1) = uint64(v); %#ok<SAGROW>
        end
    end
end

% Pattern / edge values
pattern_values = uint64([ ...
    hex2dec('0000FFFF'), hex2dec('00010000'), hex2dec('00010001'), ...
    hex2dec('00FFFFFF'), hex2dec('01000000'), hex2dec('01000001'), ...
    hex2dec('0FFFFFFF'), hex2dec('10000000'), hex2dec('10000001'), ...
    hex2dec('3FFFFFFF'), hex2dec('40000000'), hex2dec('40000001'), ...
    hex2dec('7FFFFFFE'), hex2dec('7FFFFFFF'), hex2dec('80000000'), hex2dec('80000001'), ...
    hex2dec('FFFFFFFC'), hex2dec('FFFFFFFD'), hex2dec('FFFFFFFE'), hex2dec('FFFFFFFF'), ...
    hex2dec('AAAAAAAA'), hex2dec('55555555'), hex2dec('33333333'), hex2dec('CCCCCCCC'), ...
    hex2dec('F0F0F0F0'), hex2dec('0F0F0F0F'), hex2dec('12345678'), hex2dec('87654321')]);
tests = [tests, pattern_values];

% Random full-range samples
rng(20260329);
tests = [tests, uint64(randi([0, intmax('uint32')], 1, 400))];

% Random samples near top end
for k = 1:150
    v = uint64(hex2dec('FFFFFFFF') - randi([0, 200000], 1, 1));
    tests(end+1) = v; %#ok<SAGROW>
end

% Random samples near powers of two
for k = 1:250
    r = randi([0, 31], 1, 1);
    p = uint64(2)^r;
    offset = randi([-1000, 1000], 1, 1);
    v = int64(p) + offset;
    if v >= 0 && v <= int64(hex2dec('FFFFFFFF'))
        tests(end+1) = uint64(v); %#ok<SAGROW>
    end
end

% Deduplicate and sort
tests = unique(tests);
tests = sort(tests);

%% Run test
n = numel(tests);

x_dec            = zeros(n,1,'uint64');
x_hex            = strings(n,1);
bit_length       = zeros(n,1);
dut_ceil_log2    = zeros(n,1,'uint32');
reference_result = strings(n,1);
reference_uint32 = zeros(n,1,'uint32');
error_val        = zeros(n,1,'int32');
is_power_of_two  = zeros(n,1,'logical');
valid_input      = zeros(n,1,'logical');
ok               = zeros(n,1,'logical');

for i = 1:n
    x = tests(i);

    dut = ceil_log2(uint32(x));

    x_dec(i)         = x;
    x_hex(i)         = sprintf('0x%08X', uint32(x));
    dut_ceil_log2(i) = dut;
    valid_input(i)   = (x >= 1);

    if x >= 1
        ref = uint32(ceil(log2(double(x))));
        reference_uint32(i) = ref;
        reference_result(i) = string(ref);
        error_val(i)        = int32(dut) - int32(ref);
        ok(i)               = (dut == ref);
    else
        reference_uint32(i) = uint32(0);
        reference_result(i) = "undefined";
        error_val(i)        = int32(0);
        ok(i)               = true;   % do not count N=0 as mismatch
    end

    is_power_of_two(i) = (x >= 1) && bitand(x, x - 1) == 0;
end

mismatches = sum(~ok);

%% Save CSV
T = table( ...
    x_dec, x_hex, dut_ceil_log2, reference_result, ...
    reference_uint32, error_val, is_power_of_two, valid_input, ok);

writetable(T, 'ceil_log2_representative_test.csv');

%% Save test values
fid = fopen('ceil_log2_test_values.txt', 'w');
for i = 1:n
    fprintf(fid, '%u\n', x_dec(i));
end
fclose(fid);

%% Save summary
fid = fopen('ceil_log2_test_summary.txt', 'w');
fprintf(fid, 'Representative test count: %d\n', n);
fprintf(fid, 'Valid inputs tested (N >= 1): %d\n', sum(valid_input));
fprintf(fid, 'Invalid inputs (N = 0): %d\n', sum(~valid_input));
fprintf(fid, 'Mismatches: %d\n', mismatches);

if mismatches > 0
    fprintf(fid, 'Example mismatches (up to 20 shown):\n');
    shown = 0;
    for i = 1:n
        if ~ok(i)
            fprintf(fid, '  %u (0x%08X): dut=%u ref=%u\n', ...
                x_dec(i), uint32(x_dec(i)), dut_ceil_log2(i), reference_uint32(i));
            shown = shown + 1;
            if shown >= 20
                break;
            end
        end
    end
end
fclose(fid);

%% Print summary
fprintf('Representative test count: %d\n', n);
fprintf('Valid inputs tested (N >= 1): %d\n', sum(valid_input));
fprintf('Invalid inputs (N = 0): %d\n', sum(~valid_input));
fprintf('Mismatches: %d\n', mismatches);