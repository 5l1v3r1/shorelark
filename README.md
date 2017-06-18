# Shorelark
*(old abandoned project, source code localization in polish)*

Simulation of life and evolution using neural networks.

# What is this project?

This game/application is a simple simulation of life evolution using feed forward neural networks.

In my game there are 'animals' and 'food'. Animals can see food (they have 360 degrees eyes) and are meant to eat it and their brain is the neural network: it 'can see' and decides where (angle, speed) the animal should go in the next turn. Each animal has its own brain.

After a few thousand turns, the best animals (the fitting factor is how much food each own ate) are chosen to be parents and next-turn animals are generated basing on their genome (their brain, that is: the neural network scheme).

After a few generations, most of the animals learn to find the food, but I've failed on teaching them to avoid some 'poisonous' ones. It seems that something more complicated that FFNN is required and that is beyond my current knowledge, that's why I've abandoned this project (also: lack of time).

# What is required to compile it?

Lazarus (x86 or x64, both should work) with Andorra 2D libraries (http://andorra.sourceforge.net).

# No screenshots?

Here ya go, pal:

![Screenshot](/docs/img/screenshot_0.png)

## Description of texts

`Czas renderowania` - `Rendering time`

`Czas aktualizacji` - `Updating time` (animals' processing time)

`Tura` - `Turn number`

`Generacja` - `Generation number`

`Szansa na mutację` - `Mutation chance` (when creating new generation)

`Szansa na crossover` - `Crossover chance` (when creating new generation)

`Współczynnik perturbacji` - `Perturbation factor`

`Indeksy dopasowania` - `Fitting indexes` (max, average, min); *fitting index = number of food eaten during the generation*

`Pozycja myszki` - `Cursor position`

## What's this chart?

The chart below shows the fitting indexes of each generation.

## What are the numbers on the screen?

The green lines describe angle where given animal is going, the white arcs show what it can seen and that number in the center says how much (many) food it has eaten during this generation (effectively: how much food it has eaten since it has been born).

## Some description of what's going on?

As you can see, the chart raises to some level and then stays on this average. That means that the animals, on average, learn that eating food is their destiny, but I was unable to teach them eg. to avoid poisonous food (you can see some examples in the code).