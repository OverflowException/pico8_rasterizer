pico-8 cartridge // http://www.pico-8.com
version 38
__lua__

#include linal.lua
#include line.lua

vertices = {
--       position    |    uv
    {-1.0, -1.0, -1.0, 0.0, 0.0}, --0 
    { 1.0, -1.0, -1.0, 1.0, 0.0}, --1
    { 1.0,  1.0, -1.0, 1.0, 1.0}, --2
    {-1.0,  1.0, -1.0, 0.0, 1.0}, --3

    {-1.0, -1.0,  1.0, 0.0, 0.0}, --4
    { 1.0, -1.0,  1.0, 1.0, 0.0}, --5
    { 1.0,  1.0,  1.0, 1.0, 1.0}, --6
    {-1.0,  1.0,  1.0, 0.0, 1.0}, --7

    {-1.0, -1.0,  1.0, 0.0, 0.0}, --4 --8 
    {-1.0, -1.0, -1.0, 1.0, 0.0}, --0 --9
    { 1.0, -1.0, -1.0, 1.0, 1.0}, --1 --10
    { 1.0, -1.0,  1.0, 0.0, 1.0}, --5 --11

    {-1.0,  1.0,  1.0, 0.0, 0.0}, --7 --12
    {-1.0,  1.0, -1.0, 1.0, 0.0}, --3 --13
    {-1.0, -1.0, -1.0, 1.0, 1.0}, --0 --14
    {-1.0, -1.0,  1.0, 0.0, 1.0}, --4 --15

    { 1.0,  1.0,  1.0, 0.0, 0.0}, --6 --16
    { 1.0,  1.0, -1.0, 1.0, 0.0}, --2 --17
    {-1.0,  1.0, -1.0, 1.0, 1.0}, --3 --18
    {-1.0,  1.0,  1.0, 0.0, 1.0}, --7 --19

    { 1.0, -1.0,  1.0, 0.0, 0.0}, --5 --20
    { 1.0, -1.0, -1.0, 1.0, 0.0}, --1 --21
    { 1.0,  1.0, -1.0, 1.0, 1.0}, --2 --22
    { 1.0,  1.0,  1.0, 0.0, 1.0} --6 --23
}

indices = {
    { 0,  3,  1}, { 3,  2,  1},
    {21, 22, 20}, {22, 23, 20},
    { 5,  6,  4}, { 6,  7,  4},
    {15, 12, 14}, {12, 13, 14},
    {18, 19, 17}, {19, 16, 17},
    { 8,  9, 11}, { 9, 10, 11}
}

function rasterize(v0, v1, v2)
    local ndc_v0 = world2ndc({v0[1], v0[2], v0[3], 1.0})
    local ndc_v1 = world2ndc({v1[1], v1[2], v1[3], 1.0})
    local ndc_v2 = world2ndc({v2[1], v2[2], v2[3], 1.0})
    -- back face culling
    if cross_v3(minus(ndc_v1, ndc_v0), minus(ndc_v2, ndc_v0))[3] <= 0.0 then
        return
    end

    -- front face
    local sv0 = ndc2screen(ndc_v0)
    local sv1 = ndc2screen(ndc_v1)
    local sv2 = ndc2screen(ndc_v2)
    local line01 = line_coords(sv0, sv1)
    local line02 = line_coords(sv0, sv2)
    local line12 = line_coords(sv1, sv2)

    -- merge lines
    local lines = {line01, line02, line12}
    local frag_buffer = {}
    local y_min = 127
    local y_max = 0
    for il, l in ipairs(lines) do -- traverse lines
        for ip, p in pairs(l) do  -- traverse points
            local x = p[1]
            local y = p[2]
            if frag_buffer[y] == nil then
                frag_buffer[y] = {}
            end
            add(frag_buffer[y], x)

            if y < y_min then
                y_min = y
            end
            if y > y_max then
                y_max = y
            end
        end
    end

    -- fill
    for y = y_min, y_max, 1 do
        local x_min = 127
        local x_max = 0
        for xi, x in ipairs(frag_buffer[y]) do
            if x < x_min then
                x_min = x
            end
            if x > x_max then
                x_max = x
            end            
        end
        frag_buffer[y] = {}
        for x = x_min, x_max, 1 do
            add(frag_buffer[y], x)
            -- pset(x, y)
        end
    end

    local uv0 = {v0[4], v0[5]}
    local uv1 = {v1[4], v1[5]}
    local uv2 = {v2[4], v2[5]}
    -- get perspective-correct barycentric
    for y = y_min, y_max, 1 do
        local first_p = {frag_buffer[y][1], y}
        local p_count = #frag_buffer[y]
        local last_p = {frag_buffer[y][p_count], y}

        local first_p_bary = barycentric_v2(vec2(ndc_v0), vec2(ndc_v1), vec2(ndc_v2), screen2ndc(first_p))
        local last_p_bary = barycentric_v2(vec2(ndc_v0), vec2(ndc_v1), vec2(ndc_v2), screen2ndc(last_p))
        local last_p = frag_buffer[y][p_count]
        for i, x in ipairs(frag_buffer[y]) do
            -- pset(x, y)
            local p_bary = lerp(first_p_bary, last_p_bary, (x - first_p[1]) / p_count) 

            -- correct perspective
            p_bary[1] = p_bary[1] * ndc_v0[4]
            p_bary[2] = p_bary[2] * ndc_v1[4]
            p_bary[3] = p_bary[3] * ndc_v2[4]
            local sum = p_bary[1] + p_bary[2] + p_bary[3]
            p_bary[1] = p_bary[1] / sum
            p_bary[2] = p_bary[2] / sum
            p_bary[3] = p_bary[3] / sum

            -- interpolate uv
            local u = uv0[1] * p_bary[1] + uv1[1] * p_bary[2] + uv2[1] * p_bary[3]
            local v = uv0[2] * p_bary[1] + uv1[2] * p_bary[2] + uv2[2] * p_bary[3]
            pset(x, y, flr(u * 4) + flr(v * 4) * 4) -- draw something
        end
    end

    -- draw outline
    local line01 = line(sv0[1], sv0[2], sv1[1], sv1[2], 6)
    local line02 = line(sv0[1], sv0[2], sv2[1], sv2[2], 6)
    local line12 = line(sv1[1], sv1[2], sv2[1], sv2[2], 6)
end

function world2ndc(v4)
    local vc = mul_m4_v4(persp, mul_m4_v4(view, v4)) -- clip space
    local inv_w = 1 / vc[4]
    local v_ndc = {vc[1]*inv_w, vc[2]*inv_w, vc[3]*inv_w, inv_w}
    return v_ndc
end

function ndc2screen(v)
    local screen = {v[1]*63.5 + 63.5, v[2]*63.5 + 63.5}
    screen[2] = 127.0 - screen[2] -- invert y
    local screen_snap = snap_v2(screen)
    return screen_snap
end

function screen2ndc(v)
    local y = 127 - v[2]
    local ndc = {v[1]/63.5 - 1, y/63.5 - 1}
    return ndc
end

function _init()
    eye = {3, 2, 3}
    center = {0.0, 0.0, 0.0}
    up = {0.0, 1.0, 0.0}
    view = look_at(eye, center, up)
    persp = perspective(1.0/6.0, 1.0, 0.1, 100)
    -- local test = {}
    -- test[2] = 1234
    -- test[5] = 987
    -- printh(test[1])
    -- printh(test[2])
    -- printh(test[3])
    -- printh(test[4])
    -- printh(test[5])

    -- for i = 1, 128, 1 do
    --     depth_buffer_init[i] = {}
    --     color_buffer_init[i] = {}
    --     for j = 1, 128, 1 do
    --         depth_buffer_init[i][j] = 1.0
    --         color_buffer_init[i][j] = 0
    --     end
    -- end
    -- local v = {4.6, 3.5, 2.1}
    -- local axis = {1.3, 0.2, 2.9}
    -- local q = rot_quat(axis, 1.0/6.0)
    -- local vr = apply_quat(v, q)
    -- printh_v4(q)
    -- printh_v3(vr)

    -- local a = {0.5, 0.4}
    -- local b = {0.3, 0.7}
    -- local c = {0.2, 0.1}
    -- local p = {0.4, 0.4}
    -- local bari = barycentric_v2(a, b, c, p)
    -- printh(bari[1])
    -- printh(bari[2])
end

rot = {1, 0, 0, 0}
function _update()
    local x = {1.0, 0.0, 0.0}
    local y = {0.0, 1.0, 0.0}
    local step = 1.0/36.0
    local rot_delta = {1.0, 0.0, 0.0, 0.0}
    if btnp(0) then -- left
        rot_delta = rot_quat(y, -1.0/36.0)
    end
    if btnp(1) then -- right
        rot_delta = rot_quat(y,  1.0/36.0)
    end
    if btnp(2) then -- up
        rot_delta = rot_quat(x, -1.0/36.0)
    end
    if btnp(3) then -- down
        rot_delta = rot_quat(x,  1.0/36.0)
    end

    new_rot = mul_hamilton(rot_delta, rot)
    rot = new_rot

    world_vertices = {}
    for i, v in ipairs(vertices) do
        local pos = {v[1], v[2], v[3]}
        local world_pos = apply_quat(v, rot)
        world_vertices[i] = {world_pos[1], world_pos[2], world_pos[3], v[4], v[5]}
    end
    -- local x =  5.0 * cos(t() * 0.23) * cos(t() * 0.33)
    -- local z = -5.0 * sin(t() * 0.23) * cos(t() * 0.33)
    -- local y = -5.0 * sin(t() * 0.33)
    -- -- local eye = {x, y, z}
    
    -- local center = {0.0, 0.0, 0.0}
    -- local up = {0.0, 1.0, 0.0}
    -- view = look_at(eye, center, up)
end

function _draw()
    cls()
    color(10)

    -- map(0, 0, 16, 16, 7, 7)
    for t = 1, 12, 1 do
        -- traverse triangles
        rasterize(world_vertices[indices[t][1] + 1],
                  world_vertices[indices[t][2] + 1],
                  world_vertices[indices[t][3] + 1])
    end

    -- push to screen
    -- copy_color_buffer()

end

__gfx__
000000000000b00000aaaaa000cccc0000eeee000044444000888880000000000000000000000000000000000000000000000000000000000000000000000000
00000000000bb00000a000aa0cc00cc000e00ee00040000000800000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000b0b0000a0aaa00c0000c000e000ee0040000000800000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000b00bb00a0aaaaacc0000000e00000e0444440008888800000000000000000000000000000000000000000000000000000000000000000000000000
0007700000bbbbb00a00000acc0000000e0000e00400000008000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000bb000b00a00000a0c0000000e0000e00400000008000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000b0000bbaa0000aa0cc00cc0ee000ee04400000088000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bb00000baaaaaaa000cccc00eeeeee004444440088000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010204010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000050306010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000020602040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000050306030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
