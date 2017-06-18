# Shorelark
*(old abandoned project, source code localization in polish)*

Simulation of life and evolution using neural networks.

# What is this project?

This game/application is a simple simulation of life evolution using feed forward neural networks.

In my game there are 'animals' and 'food'. Animals can see food (they have 360 degrees eyes) and are meant to eat it and their brain is the neural network: it 'can see' and decides where (angle, speed) the animal should go in the next turn. Each animal has its own brain.

After a few thousand turns, the best animals (the fitting factor is how much food each own ate) are chosen to be parents and next-turn animals are generated basing on their genome (their brain, that is: the neural network scheme).

After a few cycles, most of the animals learn to find the food, but I've failed on teaching them to avoid some 'poisonous' ones. It seems that something more complicated that FFNN is required and that is beyond my current knowledge, that's why I've abandoned this project (also: lack of time).

# What is required to compile it?

Lazarus (x86 or x64, both should work) with Andorra 2D libraries (http://andorra.sourceforge.net).
