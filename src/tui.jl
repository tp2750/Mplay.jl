module Mplay

using Printf

include("midi.jl")
include("smf.jl")
include("console.jl")

using .smf
using .console

const intensities = (
    "        ",
    "█       ",
    "██      ",
    "███     ",
    "████    ",
    "█████   ",
    "██████  ",
    "███████ ",
    "████████"
)

function update(smf)
    outtextxy(1, 1, fileinfo(smf))
    outtextxy(1, 2, songinfo(smf))
    outtextxy(1, 4, "Midi Channel    Name/Family  Instrument   Ch Ins Var Vol Pan Rev Cho Del Sen +/-")
    for ch in 1:16
        info = channelinfo(smf, ch-1)
        if info[:used]
            program, variation = getprogram(info[:instrument])
            pan = string(info[:pan] < 64 ? "L" : info[:pan] > 64 ? "R" : " ", abs(info[:pan] - 64))
            s = @sprintf "%-2d %-8s %15s: %-12s %2d %3d %3d %3d %3s %3d %3d %3d %3d %3d" ch intensities[div(info[:intensity],15)+1] info[:family] info[:name] info[:channel] program variation info[:level] pan info[:reverb] info[:chorus] info[:delay] info[:sense] info[:shift]-64;
            outtextxy(1, ch + 4, s)
        end
    end

    beat = beatinfo(smf) % 4
    s = rpad(string(repeat(" ", beat*20), repeat("█", 20)), 80)
    outtextxy(1, 21, s)
    outtextxy(1, 22, lyrics(smf))
    chord, notes = chordinfo(smf)
    outtextxy(1, 24, chord)
end

function mplay(path, device="")
    smf = readsmf(path)
    loadarrangement(smf, path)

    settty()
    cls()
    while true
        delta = play(smf, device)
        update(smf)
        if delta > 0
            sleep(delta)
        end
        if kbhit()
            if readchar() == Int('\e')
                for channel in 0:15 allnotesoff(smf, channel) end
                cls();
                break
            end
        end
        if smf.at >= smf.atend
            break
        end
    end
    resettty()
end

export mplay

function main()
    if length(ARGS) > 0
        device = length(ARGS) > 1 ? ARGS[2] : ""
        mplay(ARGS[1], device)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end #module