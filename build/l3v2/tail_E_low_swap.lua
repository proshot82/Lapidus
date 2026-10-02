local d = dofile('build/l3d/s8.lua')
d.grid[3] = "#####.....#"
d.grid[2] = "###########"
for _, o in ipairs(d.objects) do if o.kind == 'source' then o.at = {6,3}; o.ports = {right = 'V'} end if o.kind == 'fixture' then o.at = {10,4}; o.ports = {up = 'N'} end end
return d
