lattice = require('lattice')
voice = include('lib/voice')

local sequencer = {}

local directions = {
    [1] = 'forward',
    [2] = 'reverse',
    [3] = 'alternate',
    [4] = 'random'
}

function sequencer:new(onPulseAdvance)
    local t = setmetatable({}, {
        __index = sequencer
    })

    t.lattice = lattice:new()
    t.voices = {}
    t.probabilities = {}
    t.stepIndex = {}
    t.pulseCount = {}
    t.activePulse = {}
    t.direction = directions[1]

    t.onPulseAdvance = onPulseAdvance or function()
    end

    return t
end

function sequencer:addVoices(voiceCount)
    for i = 1, voiceCount do
        self:addVoice()
    end
end

function sequencer:addVoice(args)
    local voice = voice:new(args)
    table.insert(self.voices, voice)
    local voiceIndex = #self.voices
    self:addPattern(voice.division, voiceIndex)
    self:resetStepIndex(voiceIndex)
    self:resetPulseCount(voiceIndex)
end

function sequencer:resetVoices()
    self.voices = {}
    self.lattice = lattice:new()
end

function sequencer:getVoice(voiceIndex)
    return self.voices[voiceIndex]
end

function sequencer:addPattern(division, action)
    local voiceIndex = #self.voices;
    local pattern = self.lattice:new_pattern({
        action = function()
            self:advanceToNextPulse(voiceIndex)
            self.onPulseAdvance()
        end,
        division = division
    })
end

function sequencer:playPause()
    if self.lattice.enabled then
        self.lattice:stop()
    else
        self:reset()
        self.lattice:start()
    end
end

function sequencer:reset()
    self:refreshProbabilities()
    for i = 1, #self.voices do
        self:resetStepIndex(i)
        self:resetPulseCount(i)
    end
end

function sequencer:refreshProbabilities()
    math.randomseed(self.lattice.transport)

    for voiceIndex = 1, #self.voices do
        local probabilities = {}
        for i = 1, 8 do
            table.insert(probabilities, math.random(1, 100) / 100)
        end
        self.probabilities[voiceIndex] = probabilities
    end

    local prob = self.probabilities[1]
end

function sequencer:resetStepIndex(voiceIndex)
    local voice = self:getVoice(voiceIndex)
    self.stepIndex[voiceIndex] = voice.loop.start
end

function sequencer:resetPulseCount(voiceIndex)
    self.pulseCount[voiceIndex] = 1
end

function sequencer:advanceToNextPulse(voiceIndex)
    self:setActivePulse(voiceIndex)

    local voice = self:getVoice(voiceIndex)
    local stepIndex = self.stepIndex[voiceIndex]
    local pulseCount = self.pulseCount[voiceIndex]
    local pulse = voice:getPulse(stepIndex, pulseCount)

    if pulse == nil then
        self:resetPulseCount(voiceIndex)
        self:advanceToNextStep(voiceIndex)
        self:advanceToNextPulse(voiceIndex)
        return
    end

    local pulseProbability = pulse.probability or 1
    local stepProbability = self.probabilities[voiceIndex][stepIndex]
    local skip = pulseProbability < stepProbability

    print('PULSE on ' .. self.lattice.transport)
    if (skip) then
        print('v' .. voiceIndex, 's' .. stepIndex, 'p' .. pulseCount, 'skipped')
    else
        print('v' .. voiceIndex, 's' .. stepIndex, 'p' .. pulseCount, pulse.gateType)
    end

    self:increasePulseCount(voiceIndex)

    if pulse == nil or pulse.last then
        self:resetPulseCount(voiceIndex)
        self:advanceToNextStep(voiceIndex)
    end
end

function sequencer:increasePulseCount(voiceIndex)
    self.pulseCount[voiceIndex] = self.pulseCount[voiceIndex] + 1
end

function sequencer:advanceToNextStep(voiceIndex)
    local voice = self:getVoice(voiceIndex)
    self.stepIndex[voiceIndex] = self.stepIndex[voiceIndex] + 1;

    if (self.stepIndex[voiceIndex] > voice.loop.stop) then
        self:resetStepIndex(voiceIndex)
    end
end

function sequencer:setActivePulse(voiceIndex)
    self.activePulse[voiceIndex] = {
        x = self.stepIndex[voiceIndex],
        y = self.pulseCount[voiceIndex]
    }
end

function sequencer:getDirections()
    return directions
end

function sequencer:setDirection(direction)
    self.direction = direction
end

return sequencer
