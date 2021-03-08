local Voice = {}

local gateTypes = {
    [1] = 'hold',
    [2] = 'multiple',
    [3] = 'single',
    [4] = 'rest'
}

local probabilities = {
    [1] = 1,
    [2] = 0.75,
    [3] = 0.5,
    [4] = 0.25
}

local octaves = {
    [1] = 3,
    [2] = 2,
    [3] = 1,
    [4] = 0
}

function Voice:new(args)
    local t = setmetatable({}, {
        __index = Voice
    })

    t.loop = args.loop or {
        start = 1,
        stop = 8
    }

    local steps = {};
    for i = 1, 8 do
        steps[i] = {
            pulses = i,
            ratchets = 1,
            gateType = gateTypes[2],
            note = i,
            octave = octaves[4],
            probability = probabilities[1]
        }
    end
    t.steps = steps

    return t
end

function Voice:setLoop(start, stop)
    self.loop.start = start or 1
    self.loop.stop = stop or 8
end

function Voice:setPulses(step, pulseCount)
    self.steps[step].pulses = pulseCount
end

function Voice:setRatchets(step, ratchetCount)
    self.steps[step].ratchets = ratchetCount
end

function Voice:setGateType(step, gateType)
    self.steps[step].gateType = gateType
end

function Voice:setNote(step, note)
    self.steps[step].note = note
end

function Voice:setOctave(step, octave)
    self.steps[step].octave = octave
end

function Voice:setProbability(step, probability)
    self.steps[step].probability = probability
end

function Voice:getGateTypes()
    return gateTypes
end

function Voice:getProbabilities()
    return probabilities
end

function Voice:getOctaves()
    return octaves
end

return Voice
