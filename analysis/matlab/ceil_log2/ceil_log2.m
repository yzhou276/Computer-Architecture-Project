function y = ceil_log2(N)
% ceil_log2
% Returns ceil(log2(N)) for uint32 input.
%
% Input:
%   N - uint32 input
%
% Output:
%   y - uint32 result
%
% Examples:
%   ceil_log2(uint32(1)) = 0
%   ceil_log2(uint32(2)) = 1
%   ceil_log2(uint32(3)) = 2
%   ceil_log2(uint32(4)) = 2
%   ceil_log2(uint32(9)) = 4

    N = uint32(N);

    if N <= 1
        y = uint32(0);
        return;
    end

    [pos, valid] = leading_one_detector(N - 1);

    if valid
        y = pos + uint32(1);
    else
        y = uint32(0);
    end
end