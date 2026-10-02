mk () 
{ 
    name=$1;
    W=$2;
    H=$3;
    walls=$4;
    L=$5;
    objs=$6;
    { 
        echo "L=$L";
        python3 build/l7j/grid.py $W $H "$walls";
        echo;
        echo "$objs";
        echo;
        echo '{ name = "без переходника", remove = "ada" }';
        echo '{ name = "без угольника", remove = "elb" }'
    } > build/l7j/specs/$name.txt;
    python3 build/l7j/mk7.py $name
}
ev () 
{ 
    luajit -e 'package.path="./?.lua;"..package.path; local M=dofile("build/l7j/met.lua"); local r=M.eval(dofile("'$1'")); print(r.err or "", r.opt, string.format("скр %.1f", r.hid or 0), "шир", r.width, "прог", r.walk, "глуб", r.deep, "двери", r.doorSteps, r.ncfg)' 2>&1 | tail -1
}
