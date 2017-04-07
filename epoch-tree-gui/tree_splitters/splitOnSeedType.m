function V = splitOnSeedType(epoch)

if epoch.stimuli.Amp_1.parameters.randSeed == 1
    V = 'repeated';
else
    V = 'nonrepeated';
end
