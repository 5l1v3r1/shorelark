(*
  Implementacja na podstawie http://www.ai-junkie.com/ann/evolved/nnt1.html
*)
{$mode objfpc}{$H+}
Unit GeneticAlgorithm;

Interface

Uses
  Classes, SysUtils, FGL,
  Logger, NeuralNetwork, SimulationAnimal;

{ Klasa reprezentująca pojedynczy genom }
Type TGenome =
  Class
    Private
      fAnimal: TSimulationAnimal;

      fWeights: TNeuronWeights;
      fFitness: Double;

    Public
      Constructor Create(const Animal: TSimulationAnimal);
      Constructor Create(const Animal: TSimulationAnimal; const Weights: TNeuronWeights; const Fitness: Double);

      Function Clone: TGenome;
    End;

Type TGenomeList = specialize TFPGList<TGenome>;

{ Klasa reprezentująca genetyczny algorythm przystosowany do współpracy z grą }
Type TGeneticAlgorithm =
  Class
    Private
      fLogger: TLogger;

      // cała populacja
      fPopulation: TGenomeList;

      // długość chromosomu
      fChromosomeLength: Integer;

      // łączne przystosowanie populacji
      fTotalFitness: Double;

      // najlepsze przystosowanie
      fBestFitness: Double;

      // średnie przystosowanie
      fAverageFitness: Double;

      // najgorsze przystosowanie
      fWorstFitness: Double;

      // szansa na mutację
      fMutationChance: Double;

      // szansa na skrzyżowanie chromosomów
      fCrossoverChance: Double;

      // współczynnik perturbacji wag
      fPerturbationCoeff: Double;

      // licznik generacji
      fGenerationNumber: Integer;

      Function GenomeRoulette: TGenome;
      Procedure DoCrossover(const ParentA, ParentB: TGenome; out BabyA, BabyB: TGenome);
      Procedure DoMutate(const Genome: TGenome);

    Public
      Constructor Create(const ChromosomeLength: Integer);

      Procedure Step;
      Procedure AddAnimal(const Animal: TSimulationAnimal);
      Procedure RemoveAnimal(const Animal: TSimulationAnimal);

      Function GetGenerationNumber: Integer;
      Function GetMutationChance: Double;
      Function GetCrossoverChance: Double;
      Function GetPerturbationCoeff: Double;
      Function GetBestFitness: Double;
      Function GetWorstFitness: Double;
      Function GetAverageFitness: Double;
    End;

Implementation

(* Funkcja wykorzystywana do sortowania populacji *)
Function SortPopulationFunc(const A, B: TGenome): Integer;
Begin
  if (A.fFitness < B.fFitness) Then
    Result := 1 Else

  if (A.fFitness > B.fFitness) Then
    Result := -1 Else

    Result := 0;
End;

// ----- TGenome ----- //

(* Konstruktor *)
Constructor TGenome.Create(const Animal: TSimulationAnimal);
Begin
  fAnimal := Animal;
  fWeights := Animal.GetNetwork().GetTotalWeights();
  fFitness := 0;
End;

(* Konstruktor *)
Constructor TGenome.Create(const Animal: TSimulationAnimal; const Weights: TNeuronWeights; const Fitness: Double);
Begin
  fAnimal := Animal;
  fWeights := Weights;
  fFitness := Fitness;
End;

(* Klonuje genom *)
Function TGenome.Clone: TGenome;
Begin
  Result := TGenome.Create(fAnimal, fWeights, fFitness);
End;

// ----- TGeneticAlgorithm ----- //

(* Wybiera genom z populacji *)
Function TGeneticAlgorithm.GenomeRoulette: TGenome;
Var Slice, Fitness: Double;
    I: Integer;
Begin
  Slice := Random() * fTotalFitness;
  Fitness := 0;

  // przeiteruj całą populację
  For I := fPopulation.Count-1 Downto 0 Do
  Begin
    Fitness += fPopulation[I].fFitness;

    if (Fitness >= Slice) Then
      Exit(fPopulation[I]);
  End;

  // jeśli nie wyszło, próbuj ponownie
  Result := self.GenomeRoulette();
End;

(* Dokonuje krzyżowania *)
Procedure TGeneticAlgorithm.DoCrossover(const ParentA, ParentB: TGenome; out BabyA, BabyB: TGenome);
Var Point, I: Integer;
    WeightsA, WeightsB: TNeuronWeights;
Begin
  // utwórz tablice nowych wag
  SetLength(WeightsA, fChromosomeLength);
  SetLength(WeightsB, fChromosomeLength);

  // wyznacz puknt przecięcia
  Point := Random(fChromosomeLength - 1);

  // dokonaj mieszania
  For I := 0 To Point Do
  Begin
    WeightsA[I] := ParentA.fWeights[I];
    WeightsB[I] := ParentB.fWeights[I];
  End;

  For I := Point+1 To fChromosomeLength-1 Do
  Begin
    WeightsA[I] := ParentB.fWeights[I];
    WeightsB[I] := ParentA.fWeights[I];
  End;

  // utwórz nowe genomy
  BabyA := TGenome.Create(ParentA.fAnimal, WeightsA, 0);
  BabyB := TGenome.Create(ParentB.fAnimal, WeightsB, 0);
End;

(* Dokonuje mutacji *)
Procedure TGeneticAlgorithm.DoMutate(const Genome: TGenome);
Var I, S: Integer;
Begin
  // dla każdego genu
  For I := 0 To High(Genome.fWeights) Do
  Begin
    // jeśli trafi na mutację
    if (Random() < fMutationChance) Then
    Begin
      // wylosuj znak
      if (Random() < 0.5) Then
        S := -1 Else
        S := 1;

      Genome.fWeights[I] += Random() * S * fPerturbationCoeff;
    End;
  End;
End;

(* Konstruktor *)
Constructor TGeneticAlgorithm.Create(const ChromosomeLength: Integer);
Begin
  fLogger := TLogger.Create('GenAlg');
  fLogger.Info('Tworzenie instancji algorytmu genetycznego (długość chromosomu = %d)...', [ChromosomeLength]);

  fPopulation := TGenomeList.Create();
  fChromosomeLength := ChromosomeLength;
  fTotalFitness := 0.0;
  fBestFitness := 0.0;
  fAverageFitness := 0.0;
  fWorstFitness := 0.0;
  fMutationChance := 0.1;
  fCrossoverChance := 0.6;
  fPerturbationCoeff := 0.5;
  fGenerationNumber := 0;
End;

(* Dokonuje naturalnej selekcji oraz ewolucji zwierząt *)
Procedure TGeneticAlgorithm.Step;

	{ Aktualizuje indeksy przystosowania }
  Procedure UpdateFitnesses;
  Var Genome: TGenome;
  Begin
    fTotalFitness := 0.0;

    For Genome in fPopulation Do
    Begin
      Genome.fFitness := Genome.fAnimal.GetFitness();
      fTotalFitness += Genome.fFitness;
    End;
  End;

  { Sortuje populację }
  Procedure SortPopulation;
  Begin
    fPopulation.Sort(@SortPopulationFunc);
  End;

  { Tworzy nową populację }
  Procedure CreateNewPopulation;
  Var NewPopulation: TGenomeList;
      GenA, GenB, BabyA, BabyB: TGenome;
      I: Integer;
  Begin
    // przygotuj nową populację
    NewPopulation := TGenomeList.Create();

    // czterech najlepszych weź na ślepo (@todo to powinno być modyfikowalne)
   // For I := 0 To 11 Do
    For I := 0 To 3 Do
		  NewPopulation.Add(fPopulation[I].Clone());

    // dokonaj mieszania
    While (NewPopulation.Count < fPopulation.Count) Do
    Begin
      GenA := self.GenomeRoulette();
      GenB := self.GenomeRoulette();

      // wykonajmy mieszanie genów
      if (Random() < fCrossoverChance) Then
      Begin
        self.DoCrossover(GenA, GenB, BabyA, BabyB);
      End Else
      Begin
        BabyA := GenA.Clone();
        BabyB := GenB.Clone();
      End;

      // mutacje
      self.DoMutate(BabyA);
      self.DoMutate(BabyB);

      // yay
      NewPopulation.Add(BabyA);
      NewPopulation.Add(BabyB);
    End;

    // ustaw prawidłowe wskaźniki na zwierzęta
    // (jeden chromosom może być wielokrotnie wybrany w ruletce, stąd potrzeba przywracania wskaźników)
    For I := 0 To fPopulation.Count-1 Do
      NewPopulation[I].fAnimal := fPopulation[I].fAnimal;

    // zwolnij poprzednią populację
    For I := 0 To fPopulation.Count-1 Do
      fPopulation[I].Free();
    fPopulation.Free();

    fPopulation := NewPopulation;

    // zapisz nowe mózgi
    For I := 0 To fPopulation.Count-1 Do
    Begin
      fPopulation[I].fAnimal.GetNetwork().SetTotalWeights(fPopulation[I].fWeights);
      fPopulation[I].fAnimal.ResetFitness();
    End;
  End;

  { Aktualizuje statystyki }
  Procedure UpdateStats;
  Var I: Integer;
  Begin
    fBestFitness := fPopulation.First.fFitness;
    fWorstFitness := fPopulation.Last.fFitness;

    // policz średni indeks dostosowania
    fAverageFitness := 0.0;

    For I := 0 To fPopulation.Count-1 Do
      fAverageFitness += fPopulation[I].fFitness;

    fAverageFitness /= fPopulation.Count;
  End;

Begin
  Inc(fGenerationNumber);
  fLogger.Info('Przygotowywanie generacji #%d...', [fGenerationNumber]);

  UpdateFitnesses();
  SortPopulation();
  UpdateStats();
  CreateNewPopulation();
  SortPopulation();
  UpdateStats();

  fMutationChance /= 1.2;
  fCrossoverChance /= 1.15;
  fPerturbationCoeff /= 1.2;

  if (fMutationChance <= 0.01) Then
    fMutationChance := 0.01;

  if (fCrossoverChance <= 0.02) Then
    fCrossoverChance := 0.02;

  if (fPerturbationCoeff <= 0.01) Then
    fPerturbationCoeff := 0.01;
End;

(* Obejmuje zwierzę symulacją genetyki *)
Procedure TGeneticAlgorithm.AddAnimal(const Animal: TSimulationAnimal);
Begin
  fPopulation.Add(TGenome.Create(Animal));
End;

(* Zwalnia zwierzę z symulacji genetyki *)
Procedure TGeneticAlgorithm.RemoveAnimal(const Animal: TSimulationAnimal);
Var I: Integer;
Begin
  For I := 0 To fPopulation.Count-1 Do
  Begin
    if (fPopulation[I].fAnimal = Animal) Then
    Begin
      fPopulation.Delete(I);
      Exit;
    End;
  End;
End;

(* Zwraca numer aktualnej generacji *)
Function TGeneticAlgorithm.GetGenerationNumber: Integer;
Begin
  Result := fGenerationNumber;
End;

(* Zwraca szansę na mutację *)
Function TGeneticAlgorithm.GetMutationChance: Double;
Begin
  Result := fMutationChance;
End;

(* Zwraca szansę na crossover genów *)
Function TGeneticAlgorithm.GetCrossoverChance: Double;
Begin
  Result := fCrossoverChance;
End;

(* Zwraca współczynnik perturbacji wag *)
Function TGeneticAlgorithm.GetPerturbationCoeff: Double;
Begin
  Result := fPerturbationCoeff;
End;

(* Zwraca najlepszy indeks przystosowania *)
Function TGeneticAlgorithm.GetBestFitness: Double;
Begin
  Result := fBestFitness;
End;

(* Zwraca najgorszy indeks przystosowania *)
Function TGeneticAlgorithm.GetWorstFitness: Double;
Begin
  Result := fWorstFitness;
End;

(* Zwraca średni indeks przystosowania *)
Function TGeneticAlgorithm.GetAverageFitness: Double;
Begin
  Result := fAverageFitness;
End;
End.
