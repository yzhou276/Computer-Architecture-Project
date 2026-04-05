function [root, rem, iter] = isqrt_nonrestoring_nbit(x, N)
% Unsigned N-bit integer square root using non-restoring method
%
% Returns:
%   root = floor(sqrt(x))
%   rem  = x - root^2
%   iter = number of iterations
%
% Inputs:
%   x : nonnegative integer, 0 <= x < 2^N
%   N : input bit width
%
% Notes:
% - Processes the operand in 2-bit groups from MSB to LSB
% - Supports odd or even N
% - Internal remainder is signed

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

    % Number of root bits / number of 2-bit groups
    num_groups = ceil(N / 2);

    % For odd N, the top group is effectively zero-padded on the left
    total_bits = 2 * num_groups;

    % Signed partial remainder
    P = int64(0);

    % Partial root
    root = uint64(0);

    iter = 0;

    % ----------------------------
    % Main loop
    % ----------------------------
    for k = num_groups-1 : -1 : 0
        iter = iter + 1;

        % Bring down next 2 input bits from padded operand
        shift_amt = 2 * k;
        next2 = bitand(bitshift(x, -shift_amt), uint64(3));

        % Shift partial remainder left by 2 and append next2
        % Since P is signed, do the append arithmetically
        P = bitshift(P, 2) + int64(next2);

        % Non-restoring update
        if P >= 0
            % Trial subtract
            F = int64(bitshift(root, 2) + uint64(1));
            P = P - F;
        else
            % Trial add
            F = int64(bitshift(root, 2) + uint64(3));
            P = P + F;
        end

        % Update root bit
        if P >= 0
            root = bitshift(root, 1) + uint64(1);
        else
            root = bitshift(root, 1);
        end
    end

    % ----------------------------
    % Final remainder correction
    % ----------------------------
    if P < 0
        P = P + int64(bitshift(root, 1) + uint64(1));
    end

    % True mathematical remainder
    rem = uint64(P);

    % Safety correction in case you want guaranteed floor(sqrt(x))
    while root * root > x
        root = root - 1;
    end

    while (root + 1) * (root + 1) <= x
        root = root + 1;
    end

    rem = x - root * root;
end