function [root, rem, iter] = isqrt_nonrestoring_nbit(x, N)
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

    num_groups = ceil(N / 2);
    P = int64(0);
    root = uint64(0);
    iter = 0;

    fprintf('\nNon-restoring integer sqrt trace\n');
    fprintf('Input x = %d, N = %d\n\n', x, N);
    fprintf('%5s %8s %8s %12s %12s %12s\n', ...
            'Iter', 'Group', 'Op', 'F', 'P/rem', 'Q/root');
    fprintf('%5s %8s %8s %12s %12s %12s\n', ...
            '----', '-----', '--', '-', '-----', '------');

    for k = num_groups-1 : -1 : 0
        iter = iter + 1;

        shift_amt = 2 * k;
        next2 = bitand(bitshift(x, -shift_amt), uint64(3));

        P = bitshift(P, 2) + int64(next2);

        if P >= 0
            F = int64(bitshift(root, 2) + uint64(1));
            P = P - F;
            op = "SUB";
        else
            F = int64(bitshift(root, 2) + uint64(3));
            P = P + F;
            op = "ADD";
        end

        if P >= 0
            root = bitshift(root, 1) + uint64(1);
        else
            root = bitshift(root, 1);
        end

        fprintf('%5d %8s %8s %12d %12d %12d\n', ...
                iter, dec2bin(double(next2), 2), op, F, P, root);
    end

    if P < 0
        correction = int64(bitshift(root, 1) + uint64(1));
        fprintf('\nFinal correction: P = P + (2Q + 1) = %d + %d\n', ...
                P, correction);
        P = P + correction;
    end

    rem = uint64(P);

    while root * root > x
        root = root - 1;
    end

    while (root + 1) * (root + 1) <= x
        root = root + 1;
    end

    rem = x - root * root;

    fprintf('\nFinal result:\n');
    fprintf('root = %d\n', root);
    fprintf('rem  = %d\n', rem);
    fprintf('iter = %d\n\n', iter);
end