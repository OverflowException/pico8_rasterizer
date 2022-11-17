--_ see http://members.chello.at/easyfilter/bresenham.html
function line_coords(p0, p1) -- color buffer, depth buffer, color
    local x0 = p0[1]
    local y0 = p0[2]
    local x1 = p1[1]
    local y1 = p1[2]
    local dx = abs(x1 - x0)
    local dy = -abs(y1 - y0)
    local sx = 0
    local sy = 0
    if x0 < x1 then
        sx = 1
    else
        sx = -1
    end
    if y0 < y1 then
        sy = 1
    else
        sy = -1
    end

    local err = dx + dy
    local e2 = 0

    local coords = {}
    while true do
        add(coords, {x0, y0})

        if (x0 == x1) and (y0 == y1) then
            break
        end
        e2 = err + err
        if e2 >= dy then
            err = err + dy
            x0 = x0 + sx
        end
        if e2 <= dx then
            err = err + dx
            y0 = y0 + sy
        end
    end

    return coords
end