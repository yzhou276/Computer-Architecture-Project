function [y, iter, hist] = isqrt_newton(x)
% Integer square root using Newton-Raphson
% Returns floor(sqrt(x))
%
% Input:
%   x : nonnegative integer
%
% Output:
%   y    : floor(sqrt(x))
%   iter : number of iterations
%   hist : iteration history

    if x < 0 || floor(x) ~= x
        error('Input must be a nonnegative integer.');
    end

    x = uint64(x);

    if x == 0
        y = uint32(0);
        iter = 0;
        hist = [];
        return;
    end

    % Initial guess
    % A simple safe guess is x itself, but this converges slowly for large x.
    % A better guess is based on bit length.
    yk = uint64(65535);

    iter = 0;
    hist = [];

    while true
        iter = iter + 1;

        ynext = idivide(yk + idivide(x, yk, 'floor'), uint64(2), 'floor');

        hist(iter).iter  = iter;
        hist(iter).yk    = yk;
        hist(iter).ynext = ynext;

        if ynext >= yk
            break;
        end

        yk = ynext;
    end

    % Newton may stop slightly above or at the floor root depending on the stopping rule,
    % so do a final correction to guarantee floor(sqrt(x)).
    yk = ynext;

    while uint64(yk) * uint64(yk) > x
        yk = yk - 1;
    end

    while uint64(yk + 1) * uint64(yk + 1) <= x
        yk = yk + 1;
    end

    y = uint32(yk);
end