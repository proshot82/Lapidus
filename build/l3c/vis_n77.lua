-- узкое честное правило для раскладок со ступенькой в (7,7)
package.path = "./?.lua;" .. package.path
return dofile("build/l3c/vis.lua").make({ { 7, 7 } }, false)
