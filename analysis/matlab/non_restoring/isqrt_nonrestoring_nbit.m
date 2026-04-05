function [root, rem, iter] = isqrt_nonrestoring_nbit(x, N)
% Unsigned N-bit integer square root
% Returns:
%   root = floor(sqrt(x))
%   rem  = x - root^2
%   iter = number of iterations
%
% Inputs:
%   x : nonnegative integer
%   N : input bit width
%
% Notes:
% - x must satisfy 0 <= x < 2^N
% - works for odd or even N
% - processes 2 input bits per iteration from MSB to LSB

    % ----------------------------
    % Input checks
    % ----------------------------
    if x < 0 || floor(x) ~= x
        error('x must be a nonnegative integer.');
    end

    if N <= 0 || floor(N) ~= N
        error('N must be a positive integer.');
    end

    if x >= 2^N
        error('x must be less than 2^N.');
    end

    x = uint64(x);

    % Number of 2-bit groups
    num_groups = ceil(N / 2);

    % Pad width to even number of bits
    padded_N = 2 * num_groups;

    rem  = uint64(0);
    root = uint64(0);
    iter = 0;

    % ----------------------------
    % Main loop: one root bit per iteration
    % ----------------------------
    for k = num_groups-1 : -1 : 0
        iter = iter + 1;

        % Bring down next 2 bits from padded input
        next2 = bitand(bitshift(x, -2*k), uint64(3));

        % Shift remainder left by 2 and append next2
        rem = bitor(bitshift(rem, 2), next2);

        % Trial value
        trial = bitor(bitshift(root, 2), uint64(1));

        if rem >= trial
            rem  = rem - trial;
            root = bitor(bitshift(root, 1), uint64(1));
        else
            root = bitshift(root, 1);
        end
    end

    % Cast root back to a compact type if desired
    % Here I keep root as uint64 for generality
end