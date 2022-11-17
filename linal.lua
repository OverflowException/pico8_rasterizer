-- conflict with add(table)
-- function add(a, b)
--     local c = {}
--     for i, v in ipairs(a) do
--         c[i] = a[i] + b[i]
--     end
--     return c
-- end

function vec2(v)
    return {v[1], v[2]}
end

function zero(n)
    local z = {}
    for i = 1, n, 1 do
        z[i] = 0.0
    end
    return z
end

function neg(a)
    local b = {}
    for i, v in ipairs(a) do
        b[i] = -v
    end
    return b
end

function minus(a, b)
    local c = {}
    for i, v in ipairs(a) do
        c[i] = a[i] - b[i]
    end
    return c
end

function dot(a, b)
    local d = 0.0
    for i, v in ipairs(a) do
        d = d + a[i] * b[i]
    end
    return d
end

function lerp(a, b, t)
    local c = {}
    for i, v in ipairs(a) do
        c[i] = a[i] * (1 - t) + b[i] * t
    end
    return c
end

function normalize(vec)
    local length = len(vec)
    local n = {}
    for i, v in ipairs(vec) do
        n[i] = v / length
    end
    return n
end

-- function dot_v4(v0, v1)
--     local v = 0
--     v = v0[1] * v1[1] + v0[2] * v1[2] + v0[3] * v1[3] + v0[4] * v1[4]
--     return v
-- end
-- 
-- function dot_v3(v0, v1)
--     local v = 0
--     v = v0[1] * v1[1] + v0[2] * v1[2] + v0[3] * v1[3]
--     return v
-- end

function cross_v3(v0, v1)
    local v = {
        v0[2] * v1[3] - v0[3] * v1[2],
        v0[3] * v1[1] - v0[1] * v1[3],
        v0[1] * v1[2] - v0[2] * v1[1]}
    return v
end

function cross_v2(v0, v1)
    local v = v0[1] * v1[2] - v0[2] * v1[1]
    return v
end

function row_m4(m, i)
    local row = {}
    for c = 1, 4, 1 do
        row[c] = m[c][i]
    end
    return row
end

function row_m3(m, i)
    local row = {}
    for c = 1, 3, 1 do
        row[c] = m[c][i]
    end
    return row
end

function transpose_m3(m)
    local mt = {}
    for r = 1, 3, 1 do
        mt[r] = row_m3(m, r)
    end
    return mt
end

function mul_m4_v4(m, v)
    local result = {}
    for r = 1, 4, 1 do
        result[r] = dot(row_m4(m, r), v)
    end
    return result
end

function mul_m3_v3(m, v)
    local result = {}
    for r = 1, 3, 1 do
        result[r] = dot(row_m3(m, r), v)
    end
    return result
end

function printh_v4(v)
    printh(v[1]..", "..v[2]..", "..v[3]..", "..v[4])
end

function printh_v3(v)
    printh(v[1]..", "..v[2]..", "..v[3])
end

function printh_v2(v)
    printh(v[1]..", "..v[2])
end

function printh_m4(m)
    for r = 1, 4, 1 do
        printh_v4(row_m4(m, r))
    end
end

function barycentric_v2(a, b, c, p)
    -- printh("abcp")
    -- printh_v2(a)
    -- printh_v2(b)
    -- printh_v2(c)
    -- printh_v2(p)

    local ab = minus(b, a)
    local ac = minus(c, a)
    local ap = minus(p, a)

    local d00 = dot(ab, ab)
    local d01 = dot(ac, ab)
    local d11 = dot(ac, ac)
    local d02 = dot(ap, ab)
    local d12 = dot(ap, ac)
    -- printh("ds")
    -- printh(d00)
    -- printh(d01)
    -- printh(d11)
    -- printh(d02)
    -- printh(d12)

    -- danger of overflow
    local denom = d00 * d11 - d01 * d01
    local det0 = d02 * d11 - d01 * d12
    local det1 = d00 * d12 - d02 * d01
    -- printh("dets")
    -- printh(denom)
    -- printh(det0)
    -- printh(det1)

    local v = det0 / denom
    local w = det1 / denom
    return {1 - v - w, v, w}
end

-- fovy: fov in y direction, 0.0-1.0
-- aspect: x/y aspect ratio
function perspective(fovy, aspect, near, far)
    local n = near
    local f = far
    local tan = -sin(fovy*0.5) / cos(fovy*0.5)
    local t = n * tan
    local r = t * aspect

    local p = {}
    p[1] = {n/r, 0, 0, 0}
    p[2] = {0, n/t, 0, 0}
    p[3] = {0, 0, -(f+n)/(f-n), -1}
    p[4] = {0, 0, -2*f*n/(f-n), 0}
    return p
end

function look_at(eye, center, up)
    local front = normalize(minus(center, eye))
    local z = neg(front)
    local x = normalize(cross_v3(front, up))
    local y = normalize(cross_v3(z, x))
    -- printh_v3(x)
    -- printh_v3(y)
    -- printh_v3(z)
    local t = neg(eye)

    local r = {x, y, z}
    local rt = transpose_m3(r)
    local ti = mul_m3_v3(rt, t)

    rt[1][4] = 0
    rt[2][4] = 0
    rt[3][4] = 0
    ti[4] = 1

    local view_mat = {rt[1], rt[2], rt[3], ti}
    return view_mat
end

function len(vec)
    local len2 = 0.0
    for i, v in ipairs(vec) do
        len2 = len2 + v * v
    end
    return sqrt(len2)
end

function rot_quat(v, a)
    local axis = normalize(v)
    local a2 = a * 0.5
    local cos = cos(a2)
    local sin = -sin(a2)

    local quat = {}
    quat[1] = cos
    quat[2] = sin * axis[1]
    quat[3] = sin * axis[2]
    quat[4] = sin * axis[3]
    return quat
end

function mul_hamilton(q1, q2)
    local q = {}
    q[1] = q1[1]*q2[1] - q1[2]*q2[2] - q1[3]*q2[3] - q1[4]*q2[4]
    q[2] = q1[1]*q2[2] + q1[2]*q2[1] + q1[3]*q2[4] - q1[4]*q2[3]
    q[3] = q1[1]*q2[3] - q1[2]*q2[4] + q1[3]*q2[1] + q1[4]*q2[2]
    q[4] = q1[1]*q2[4] + q1[2]*q2[3] - q1[3]*q2[2] + q1[4]*q2[1]
    return q
end

function conj(q)
    local qc = {q[1], -q[2], -q[3], -q[4]};
    return qc
end

-- vec3
function apply_quat(v, q)
    local vq = {0.0, v[1], v[2], v[3]}
    local vqr = mul_hamilton(mul_hamilton(q, vq), conj(q))
    return {vqr[2], vqr[3], vqr[4]}
end

-- function quat2mat4(q)
--     local x2 = 
--     m = {{}, {}, {}, {}}
-- 
-- end

function snap_v2(v)
    local s_v2 = {}
    s_v2[1] = flr(v[1] + 0.5)
    s_v2[2] = flr(v[2] + 0.5)
    return s_v2
end

function v2(v)
    local v2 = {}
    v2[1] = v[1]
    v2[2] = v[2]
    return v2
end


