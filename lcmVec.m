function LCM = lcmVec(vec)

assert(size(vec,2) ~= 0, 'empty vec');
max_size = max(size(vec));
min_size = min(size(vec));

assert(min_size == 1, 'imput is not a vector');

LCM = 1;
for i = 1:max_size
    LCM = lcm(LCM,vec(i));
end