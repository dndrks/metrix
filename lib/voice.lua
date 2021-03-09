local voice = {}

local gateTypes = {
    [1] = 'hold',
    [2] = 'multiple',
    [3] = 'single',
    [4] = 'rest'
}

local gateLengths = {
    [1] = 1,
    [2] = 0.75,
    [3] = 0.5,
    [4] = 0.1
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

function voice:new(args)
    local t = setmetatable({}, {
        __index = voice
    })

    args = args or {}

    t.loop = args.loop or {
        start = 1,
        stop = 8
    }

    if args.steps then
        t.steps = args.steps
    else
        local steps = {};
        for i = 1, 8 do
            steps[i] = {
                pulseCount = i,
                ratchetCount = 1,
                gateType = gateTypes[2],
                gateLength = gateLengths[3],
                interval = i,
                octave = octaves[4],
                probability = probabilities[1]
            }
        end
        t.steps = steps
    end

    return t
end

function voice:randomize(params)
    math.randomseed(util.time())
    for i = 1, #params do
        local key = params[i]
        for step = 1, 8 do
            if key == 'pulseCount' then
                self:setPulseCount(step, math.random(1, 8))
            end
            if key == 'interval' then
                self:setInterval(step, math.random(1, 8))
            end
            if key == 'octave' then
                self:setOctave(step, octaves[math.random(1, 4)])
            end
            if key == 'gateType' then
                self:setGateType(step, gateTypes[math.random(1, 4)])
            end
            if key == 'gateLength' then
                self:setGateLength(step, gateLengths[math.random(1, 4)])
            end
            if key == 'ratchetCount' then
                self:setRatchetCount(step, math.random(1, 8))
            end
            if key == 'probability' then
                self:setProbability(step, probabilities[math.random(1, 4)])
            end
        end
    end

end

function voice:setLoop(start, stop)
    self.loop.start = start or 1
    self.loop.stop = stop or 8
end

function voice:setPulseCount(step, pulseCount)
    self.steps[step].pulseCount = pulseCount
end

function voice:setRatchetCount(step, ratchetCount)
    self.steps[step].ratchetCount = ratchetCount
end

function voice:setGateType(step, gateType)
    self.steps[step].gateType = gateType
end

function voice:setGateLength(step, gateLength)
    self.steps[step].gateLength = gateLength
end

function voice:setInterval(step, interval)
    self.steps[step].interval = interval
end

function voice:setOctave(step, octave)
    self.steps[step].octave = octave
end

function voice:setProbability(step, probability)
    self.steps[step].probability = probability
end

function voice:getGateTypes()
    return gateTypes
end

function voice:getGateLengths()
    return gateLengths
end

function voice:getProbabilities()
    return probabilities
end

function voice:getOctaves()
    return octaves
end

function voice:getPulses()
    return {}
end

return voice
