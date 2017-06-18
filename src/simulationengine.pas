{$mode objfpc}{$H+}
Unit SimulationEngine;

Interface

Uses
  Windows, Classes, SysUtils,
  Logger, SimulationBoard, Chart;

{ Klasa opakowująca silnik symulacji }
Type TSimulationEngine =
  Class
    Private
      fLogger: TLogger;

      fBoard: TSimulationBoard;
      fFitnessChart: TChart;

      fDrawTime, fUpdateTime: Single;
      fTurnCount: uint64;

      fFastMode: Boolean;

    Public
      Constructor Create(const Width, Height: Integer);
      Destructor Destroy; override;

      Procedure SwitchFastMode;

      Procedure OnDraw;
      Procedure OnUpdate;

      Function GetBoard: TSimulationBoard;
    End;

Implementation
Uses
  zglHeader,
  Colors, Engine, SimulationFood, SimulationAnimal, GeneticAlgorithm;

(* Konstruuje silnik symulacji *)
Constructor TSimulationEngine.Create(const Width, Height: Integer);
Begin
  fLogger := TLogger.Create('SimEngine');
  fLogger.Info('Tworzenie silnika symulacji dla planszy %dx%d...', [Width, Height]);

  fBoard := TSimulationBoard.Create(Width, Height);

  fDrawTime := 0;
  fUpdateTime := 0;
  fTurnCount := 0;

  fFastMode := False;

  fFitnessChart := TChart.Create(5, 175, 270, 120);
End;

(* Destruktor *)
Destructor TSimulationEngine.Destroy;
Begin
  fLogger.Info('Niszczenie silnika symulacji...');
  fLogger.Free;

  fBoard.Free;
End;

(* Przełącza tryb szbyki *)
Procedure TSimulationEngine.SwitchFastMode;
Begin
  fFastMode := not fFastMode;
  scr_SetVSync(not fFastMode);
End;

(* Rysuje symulację *)
Procedure TSimulationEngine.OnDraw;
Var Y: Integer = 8;

  Procedure Print(const Format: String; const Args: Array of Const);
  Begin
    text_Draw(fntMain, 5, Y, SysUtils.Format(Format, Args));
    Inc(Y, 15);
  End;

  Procedure Print(const Text: String);
	Begin
		Print(Text, []);
  End;

Var BeginTime, EndTime, Frequency: TLargeInteger;
    GenAlgo: TGeneticAlgorithm;
Begin
  BeginTime := 0;
  EndTime := 0;
  Frequency := 0;

  QueryPerformanceFrequency(Frequency);
  QueryPerformanceCounter(BeginTime);

  if (fFastMode) Then
    text_DrawEx(fntMain, GameWidth div 2, 70, 1, 0, '[ TRYB SZYBKI ]', 255, Colors.FriendlyRed, TEXT_HALIGN_CENTER) Else
    fBoard.OnDraw();

  if (SimulationAnimal.MagicTmp) Then
    text_DrawEx(fntMain, GameWidth div 2, 70, 1, 0, '[ PRZYCIĄGANIE DO MYSZY ]', 255, Colors.FriendlyRed, TEXT_HALIGN_CENTER);

  QueryPerformanceCounter(EndTime);

  fDrawTime := (EndTime - BeginTime) / (Frequency / 1000);

  // wyrenderuj panel informacyjny
  GenAlgo := fBoard.GetGeneticAlgorithm();

	Print('Shorelack v. %s', [GameVersion]);
  Print('FPS: %d', [zgl_Get(RENDER_FPS)]);
  Print('Czas renderowania: %f ms', [fDrawTime]);
  Print('Czas aktualizacji: %f ms', [fUpdateTime]);
  Print('Tura: %d', [fTurnCount]);
  Print('Generacja: %d', [GenAlgo.GetGenerationNumber()]);
  Print('Szansa na mutację: %f', [GenAlgo.GetMutationChance()]);
  Print('Szansa na crossover: %f', [GenAlgo.GetCrossoverChance()]);
  Print('Współczynnik perturbacji: %f', [GenAlgo.GetPerturbationCoeff()]);
  Print('Indeksy dopasowania: %d/%d/%d', [Round(GenAlgo.GetBestFitness()), Round(GenAlgo.GetWorstFitness()), Round(GenAlgo.GetAverageFitness())]);
  Print('Pozycja myszki: %d, %d', [mouse_X(), mouse_Y()]);

  fFitnessChart.OnDraw();
End;

(* Aktualizuje symulację *)
Procedure TSimulationEngine.OnUpdate;
Var BeginTime, EndTime, Frequency: TLargeInteger;
    ChartItem: TChartItem;
    GenAlgo: TGeneticAlgorithm;
Begin
  BeginTime := 0;
  EndTime := 0;
  Frequency := 0;

  QueryPerformanceFrequency(Frequency);
  QueryPerformanceCounter(BeginTime);

  fBoard.OnUpdate();

  QueryPerformanceCounter(EndTime);

  fUpdateTime := (EndTime - BeginTime) / (Frequency / 1000);
  Inc(fTurnCount);

  // uzuepłnij wykres
  if (fTurnCount mod 2000 = 0) Then
  Begin
	  GenAlgo := fBoard.GetGeneticAlgorithm();

	  ChartItem.fMin := GenAlgo.GetWorstFitness();
	  ChartItem.fMax := GenAlgo.GetBestFitness();
	  ChartItem.fValue := GenAlgo.GetAverageFitness();

	  fFitnessChart.AddItem(ChartItem);
  End;
End;

(* Zwraca planszę *)
Function TSimulationEngine.GetBoard: TSimulationBoard;
Begin
  Result := fBoard;
End;
End.
