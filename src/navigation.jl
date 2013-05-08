### GUI controls for play forward/backward, up/down, and frame stepping ###

## Type for specifying a particular 2d slice from a possibly-4D image
type NavigationSlice
    # Dimensions:
    zmax::Int    # = 1 if only 2 spatial dims
    tmax::Int    # = 1 if only a single image
    # Current selection:
    z::Int
    t::Int
end

## Type for holding "handles" to GUI controls
# Don't put anything in here that this GUI doesn't "own"
type NavigationControls
    stepup                            # buttons...
    stepdown
    playup
    playdown
    stepback
    stepfwd
    playback
    playfwd
    stop
    editz                             # edit boxes
    editt
    textz                             # static text (information)
    textt
    isplaying::Bool                   # GUI state
end
NavigationControls() = NavigationControls(nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing, false)

# f is a TkFrame
function create_navigation_buttons!(f, ctrls::NavigationControls, curframe::NavigationSlice, showframe::Function)
    btnsz, pad = navigation_controls_size()
    stop = trues(btnsz)
    mask = copy(stop)
    stop[[1,btnsz[1]],:] = false
    stop[:,[1,btnsz[2]]] = false
    bkg = "gray70"
    icon = Tk.Image(stop, mask, bkg, "black")
    ctrls.stop = Tk.Button(f, icon)
    Tk.tk_bind(ctrls.stop, "command", path -> ctrls.isplaying = false)
    local zindex
    local tindex
    local stopindex
    havez = curframe.zmax > 1
    havet = curframe.tmax > 1
    zindex = 1:6
    stopindex = 7
    tindex = 8:13
    if !havez
        stopindex = 1
        tindex = 2:7
    end
    Tk.grid(ctrls.stop,1,stopindex,{:padx => 3*pad, :pady => pad})
    if havez
        callback = (path->stepup(ctrls,curframe,showframe), path->playup(ctrls,curframe,showframe), 
            path->playdown(ctrls,curframe,showframe), path->stepdown(ctrls,curframe,showframe),
            path->setz(ctrls,curframe,showframe))
        ctrls.stepup, ctrls.playup, ctrls.playdown, ctrls.stepdown, ctrls.textz, ctrls.editz = 
            addbuttons(f, btnsz, bkg, pad, zindex, "z", callback)
        Tk.set_value(ctrls.editz, string(curframe.z))
    end
    if havet
        callback = (path->stepback(ctrls,curframe,showframe), path->playback(ctrls,curframe,showframe), 
            path->playfwd(ctrls,curframe,showframe), path->stepfwd(ctrls,curframe,showframe),
            path->sett(ctrls,curframe,showframe))
        ctrls.stepback, ctrls.playback, ctrls.playfwd, ctrls.stepfwd, ctrls.textt, ctrls.editt = 
            addbuttons(f, btnsz, bkg, pad, tindex, "t", callback)
        Tk.set_value(ctrls.editt, string(curframe.t))
    end
end

function navigation_controls_size()
    btnsz = (21, 21)
    pad = 5
    return btnsz, pad
end

# Functions for drawing icons
function arrowheads(sz, vert::Bool)
    datasm = icondata(sz, 0.5)
    datalg = icondata(sz, 0.8)
    if vert
        return datasm[:,end:-1:1], datalg[:,end:-1:1], datalg, datasm
    else
        datasm = datasm'
        datalg = datalg'
        return datasm[end:-1:1,:], datalg[end:-1:1,:], datalg, datasm
    end
end

function icondata(iconsize, frac)
    center = iceil(iconsize[1]/2)
    data = Bool[ 2abs(i-center)< iconsize[2]-(j-1)/frac for i = 1:iconsize[1], j = 1:iconsize[2] ]
    data .== true
end

# index contains the grid position of each object
# orientation is "t" or "z"
# callback is an array of 5 entries, the 5th being the edit box
function addbuttons(f, sz, bkg, pad, index, orientation, callback)
    rotflag = orientation == "z"
    ctrl = Array(Any, 6)
    ctrl[1], ctrl[2], ctrl[3], ctrl[4] = arrowheads(sz, rotflag)
    mask = trues(sz)
    const color = ("black", "green", "green", "black")
    ibutton = [1,2,5,6]
    for i = 1:4
        icon = Tk.Image(ctrl[i], mask, bkg, color[i])
        b = Tk.Button(f, icon)
        Tk.grid(b,1,index[ibutton[i]],{:padx => pad, :pady => pad})
        Tk.tk_bind(b, "command", callback[i])
        ctrl[i] = b
    end
    ctrl[5] = Tk.Label(f, orientation*":")
    Tk.grid(ctrl[5],1,index[3], {:padx => pad, :pady => pad})
    ctrl[6] = Tk.Entry(f, "1")
    Tk.tk_configure(ctrl[6], {:width => 5})
    Tk.grid(ctrl[6],1,index[4],{:padx => pad, :pady => pad})
    Tk.tk_bind(ctrl[6], "<Return>", callback[5])
    tuple(ctrl...)
end

updatez(ctrls,curframe) = Tk.set_value(ctrls.editz, string(curframe.z))
updatet(ctrls,curframe) = Tk.set_value(ctrls.editt, string(curframe.t))

function stepup(ctrls,curframe,showframe)
    if curframe.z < curframe.zmax
        curframe.z += 1
        updatez(ctrls,curframe)
        showframe(curframe)
    end
end

function playup(ctrls,curframe,showframe)
    ctrls.isplaying = true
    while curframe.z < curframe.zmax && ctrls.isplaying
        curframe.z += 1
        updatez(ctrls,curframe)
        showframe(curframe)
    end
    ctrls.isplaying = false
end

function playdown(ctrls,curframe,showframe)
    ctrls.isplaying = true
    while curframe.z > 1 && ctrls.isplaying
        curframe.z -= 1
        updatez(ctrls,curframe)
        showframe(curframe)
    end
    ctrls.isplaying = false
end

function stepdown(ctrls,curframe,showframe)
    if curframe.z > 1
        curframe.z -= 1
        updatez(ctrls,curframe)
        showframe(curframe)
    end
end

function setz(ctrls,curframe,showframe)
    zstr = Tk.get_value(ctrls.editz)
    local val
    try
        val = int(zstr)
        curframe.z = val
        showframe(curframe)
    catch
    end
end

function stepback(ctrls,curframe,showframe)
    if curframe.t > 1
        curframe.t -= 1
        updatet(ctrls,curframe)
        showframe(curframe)
    end
end

function playback(ctrls,curframe,showframe)
    ctrls.isplaying = true
    while curframe.t > 1 && ctrls.isplaying
        curframe.t -= 1
        updatet(ctrls,curframe)
        showframe(curframe)
    end
    ctrls.isplaying = false
end

function playfwd(ctrls,curframe,showframe)
    ctrls.isplaying = true
    while curframe.t < curframe.tmax && ctrls.isplaying
        curframe.t += 1
        updatet(ctrls,curframe)
        showframe(curframe)
    end
    ctrls.isplaying = false
end

function stepfwd(ctrls,curframe,showframe)
    if curframe.t < curframe.tmax
        curframe.t += 1
        updatet(ctrls,curframe)
        showframe(curframe)
    end
end

function sett(ctrls,curframe,showframe)
    tstr = Tk.get_value(ctrls.editt)
    local val
    try
        val = int(tstr)
        curframe.t = val
        showframe(curframe)
    catch
    end
end
