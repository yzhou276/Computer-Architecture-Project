function [pos, valid] = leading_one_detector(x)
% leading_one_detector
% Returns the position of the most significant 1 bit in a uint32 input.
%
% Input:
%   x     - uint32 input
%
% Output:
%   pos   - 0-based position of MSB '1' from LSB side
%   valid - true if x /= 0, false if x == 0
%
% Examples:
%   x = uint32(8)   -> pos = 3, valid = true
%   x = uint32(18)  -> pos = 4, valid = true
%   x = uint32(0)   -> pos = 0, valid = false

    x = uint32(x);

    if x == 0
        pos = uint32(0);
        valid = false;
        return;
    end

    valid = true;
    pos = uint32(0);

    for i = 31:-1:0
        if bitget(x, i+1) == 1
            pos = uint32(i);
            return;
        end
    end
end