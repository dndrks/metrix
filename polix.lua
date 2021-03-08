--
--
-- polix
-- metropolix for norns
--
--
g = grid.connect()
g:rotation(45)

-- page selector
local maxPages = 4
local selectedPage = 2

-- momentary pressed keys
local momentary = {}
for x = 1, 8 do
    momentary[x] = {}
    for y = 1, 16 do
        momentary[x][y] = false
    end
end

-- voices data
local selectedVoice = 1
local notSelectedVoice = 2
local voice = include('lib/voice')
local voices = {}
voice[1] = voice:new({
    loop = {
        start = 1,
        stop = 6
    }
})
voice[2] = voice:new({
    loop = {
        start = 5,
        stop = 8
    }
})

-- grid state helpers
local loopWasSelected = false
local voiceWasSelected = false

function init()
    redrawGrid()
end

function redrawGrid()
    g:all(0)

    drawLoopSelector()
    drawPageSelector()
    drawShift()

    -- pulse matrix
    if selectedPage == 1 then
        drawPulseMatrix()
        drawGateTypeMatrix()
    elseif selectedPage == 2 then
        drawPitchMatrix()
        drawOctaveMatrix()
    end

    g:refresh()
end

function drawPageSelector()
    y = 16
    for x = 1, maxPages do
        g:led(x, y, 3)
    end
    g:led(selectedPage, 16, 15)
end

function drawShift()
    g:led(8, 16, 3)
end

function drawLoopSelector()
    for y = 1, 2 do
        for x = 1, 8 do
            if y == selectedVoice then
                local start = voice[selectedVoice].loop.start
                local stop = voice[selectedVoice].loop.stop

                if (x >= start and x <= stop) then
                    g:led(x, y, 15)
                else
                    g:led(x, y, 3)
                end
            else
                local start = voice[notSelectedVoice].loop.start
                local stop = voice[notSelectedVoice].loop.stop

                if (x >= start and x <= stop) then
                    g:led(x, y, 7)
                else
                    g:led(x, y, 0)
                end
            end
        end
    end
end

function drawPulseMatrix()
    local voice = getSelectedVoice()

    for x = 1, 8 do
        for y = 3, 10 do
            local pulse = voice.steps[x].pulses[11 - y]

            if stepInLoop(x, voice) then
                if pulse then
                    g:led(x, y, 15)
                else
                    g:led(x, y, 0)
                end
            else
                if pulse then
                    g:led(x, y, 3)
                else
                    g:led(x, y, 0)
                end
            end
        end
    end
end

function drawGateTypeMatrix()
    local voice = getSelectedVoice()

    for x = 1, 8 do
        local gateType = voice.steps[x].gateType

        for y = 12, 15 do
            if stepInLoop(x, voice) then
                if gateType == "hold" and y == 12 then
                    g:led(x, y, 15)
                elseif gateType == "multiple" and y == 13 then
                    g:led(x, y, 15)
                elseif gateType == "single" and y == 14 then
                    g:led(x, y, 15)
                elseif gateType == "rest" and y == 15 then
                    g:led(x, y, 5)
                else
                    if gateType == "rest" then
                        g:led(x, y, 0)
                    else
                        g:led(x, y, 3)
                    end
                end
            else
                g:led(x, y, 3)
            end
        end
    end
end

function drawPitchMatrix()
    local voice = getSelectedVoice()

    for x = 1, 8 do
        for y = 3, 10 do
            if stepInLoop(x, voice) then
                local note = voice.steps[x].note;
                if 11 - y == note then
                    g:led(x, y, 15)
                elseif 11 - y > note then
                    g:led(x, y, 0)
                else
                    g:led(x, y, 3)
                end
            else
                g:led(x, y, 0)
            end
        end
    end
end

function drawOctaveMatrix()
    local voice = getSelectedVoice()

    for x = 1, 8 do
        local octave = voice.steps[x].octave

        for y = 12, 15 do
            if stepInLoop(x, voice) then
                if octave == 0 and y == 15 then
                    g:led(x, y, 15)
                elseif octave == 1 and y == 14 then
                    g:led(x, y, 15)
                elseif octave == 2 and y == 13 then
                    g:led(x, y, 15)
                elseif octave == 3 and y == 12 then
                    g:led(x, y, 15)
                else
                    g:led(x, y, 3)
                end
            else
                g:led(x, y, 0)
            end
        end
    end
end

function stepInLoop(step, voice)
    return step >= voice.loop.start and step <= voice.loop.stop
end

function g.key(x, y, z)
    local on, off = z == 1, z == 0
    local voice = getSelectedVoice()

    if on then
        momentary[x][y] = true
    else
        momentary[x][y] = false
    end

    -- row 1 & 2: set seq length / loop
    if y <= 2 then
        if selectedVoice ~= y then
            selectVoice(y)
        else
            local held, tapped = getMomentaryInRow(y), x

            if on then
                if held and held ~= tapped then
                    voice:setLoop(held, tapped)
                    loopWasSelected = true
                end
            else
                if held == false then
                    if loopWasSelected == false and voiceWasSelected == false then
                        if tapped == 1 and voice.loop.start == 1 and voice.loop.stop == 1 then
                            voice:setLoop(1, 8)
                        else
                            voice:setLoop(tapped, tapped)
                        end
                    end

                    loopWasSelected = false
                    voiceWasSelected = false
                end
            end
        end
    end

    -- row 3-10: pulse pitch matrix
    if selectedPage == 1 and on then
        local step = x

        if y >= 3 and y <= 10 then
            local length = 11 - y
            voice:setStepLength(step, length)
        elseif y == 12 then
            voice:setGateType(step, 'hold')
        elseif y == 13 then
            voice:setGateType(step, 'multiple')
        elseif y == 14 then
            voice:setGateType(step, 'single')
        elseif y == 15 then
            voice:setGateType(step, 'rest')
        end
    end

    -- row 16: select page
    if on and y == 16 and x <= maxPages then
        selectPage(x)
    end

    redrawGrid()
end

function getMomentaryInRow(y)
    for x = 1, 8 do
        if momentary[x][y] then
            return x
        end
    end

    return false
end

function shiftIsHeld()
    return momentary[8][16];
end

function getSelectedVoice(voiceNumber)
    return voice[selectedVoice]
end

function selectPage(pageNumber)
    selectedPage = pageNumber or 1
end

function selectVoice(voiceNumber)
    selectedVoice = voiceNumber or 1

    if selectedVoice == 1 then
        notSelectedVoice = 2
    else
        notSelectedVoice = 1
    end

    voiceWasSelected = true
end
