%% Representative test for integer sqrt using non-restoring algorithm
% Saves:
%   1) CSV with results
%   2) TXT with test values
%   3) TXT summary
%
% Main output:
%   nonrestoring_isqrt_representative_test.csv

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

% Around selected perfect squares
square_roots = uint64([ ...
    0 1 2 3 4 5 7 8 15 16 17 31 32 33 ...
    63 64 65 127 128 129 255 256 257 ...
    511 512 513 1023 1024 1025 ...
    2047 2048 2049 4095 4096 4097 ...
    8191 8192 8193 16383 16384 16385 ...
    32767 32768 32769 46338 46339 46340 46341 65535]);

for r = square_roots
    sq = r * r;
    for d = [-2 -1 0 1 2]
        v = int64(sq) + d;
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

% Random samples near random perfect squares
for k = 1:250
    r = uint64(randi([0, 65535], 1, 1));
    sq = r * r;
    offset = randi([-1000, 1000], 1, 1);
    v = int64(sq) + offset;
    if v >= 0 && v <= int64(hex2dec('FFFFFFFF'))
        tests(end+1) = uint64(v); %#ok<SAGROW>
    end
end

% Deduplicate and sort
tests = unique(tests);
tests = sort(tests);

%% Run test
n = numel(tests);

x_dec                 = zeros(n,1,'uint64');
x_hex                 = strings(n,1);
bit_length            = zeros(n,1);
nonrestoring_isqrt    = zeros(n,1,'uint32');
reference_isqrt       = zeros(n,1,'uint32');
remainder_val         = zeros(n,1,'uint32');
error_val             = zeros(n,1,'int32');
iterations            = zeros(n,1);
perfect_square        = false(n,1);
ok                    = false(n,1);

max_iter = -1;
max_iter_cases = uint64([]);

for i = 1:n
    x = tests(i);
    [y, rem, niter] = isqrt_nonrestoring_nbit(x,32);
    ref = uint32(floor(sqrt(double(x))));
    ref_rem = uint32(x - uint64(ref) * uint64(ref));

    x_dec(i)              = x;
    x_hex(i)              = sprintf('0x%08X', uint32(x));
    bit_length(i)         = bit_length_uint64(x);
    nonrestoring_isqrt(i) = y;
    reference_isqrt(i)    = ref;
    remainder_val(i)      = rem;
    error_val(i)          = int32(y) - int32(ref);
    iterations(i)         = niter;
    perfect_square(i)     = (uint64(ref) * uint64(ref) == x);
    ok(i)                 = (y == ref) && (rem == ref_rem);

    if niter > max_iter
        max_iter = niter;
        max_iter_cases = x;
    elseif niter == max_iter
        max_iter_cases(end+1) = x; %#ok<SAGROW>
    end
end

mismatches = sum(~ok);

%% Save CSV
T = table( ...
    x_dec, x_hex, bit_length, nonrestoring_isqrt, reference_isqrt, ...
    remainder_val, error_val, iterations, perfect_square, ok);

writetable(T, 'nonrestoring_isqrt_representative_test.csv');

%% Save test values
fid = fopen('nonrestoring_isqrt_test_values.txt', 'w');
for i = 1:n
    fprintf(fid, '%u\n', x_dec(i));
end
fclose(fid);

%% Save summary
fid = fopen('nonrestoring_isqrt_test_summary.txt', 'w');
fprintf(fid, 'Representative test count: %d\n', n);
fprintf(fid, 'Mismatches: %d\n', mismatches);
fprintf(fid, 'Max iterations observed: %d\n', max_iter);
fprintf(fid, 'Example max-iteration cases (up to 20 shown):\n');
for i = 1:min(20, numel(max_iter_cases))
    fprintf(fid, '  %u (0x%08X)\n', max_iter_cases(i), uint32(max_iter_cases(i)));
end
fclose(fid);

%% Print summary
fprintf('Representative test count: %d\n', n);
fprintf('Mismatches: %d\n', mismatches);
fprintf('Max iterations observed: %d\n', max_iter);

function nbits = bit_length_uint64(x)
% Returns number of bits needed to represent x
    if x == 0
        nbits = 0;
    else
        nbits = floor(log2(double(x))) + 1;
    end
end