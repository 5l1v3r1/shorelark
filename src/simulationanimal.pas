{$mode objfpc}{$H+}
Unit SimulationAnimal;

Interface

Uses
  Classes, SysUtils,
  SimulationAbstractObject, SimulationFigure, MyMath, Colors, NeuralNetwork, FieldOfView;

{ Klasa reprezentująca zwierzę }
Type
  TSimulationAnimal =
    Class (TSimulationAbstractObject)
      Private
        // 'mózg' zwierzęcia
        fNetwork: TNeuralNetwork;

        // w jakim kierunku patrzy
        fLookAt: TVector2;

        // obrót
        fRotation: Double;

        // prędkość
        fSpeed: Double;

        // prędkości
        fLeftSpeed, fRightSpeed: Double;

        // wynik dopasowania zwierzęcia
        fFitness: Double;

        // pole widzenia
        fFOV: TFieldOfView;

        // widok z oczu
        fEyes: TColorArray;

        fLastInput, fLastOutput: TNeuronWeights;

        Procedure UpdateNetwork;

      Public
        Constructor Create(const Position: TVector2);

        Procedure ResetFitness;

        Procedure OnDraw; override;
        Procedure OnUpdate; override;
        Procedure OnCollision(const Obj: TSimulationAbstractObject); override;

        Function GetNetwork: TNeuralNetwork;
        Function GetFitness: Double;
      End;

Var MagicTmp: Boolean = False;

Implementation
Uses
  Math,
  zglHeader,
  Engine, SimulationFood;

Const
  FOV_ANGLE = 180;
  FOV_DISTANCE = 150;
  FOV_SAMPLE_COUNT = 16;

(* Aktualizuje poruszanie się zwierzęcia danymi z sieci neuronowej *)
Procedure TSimulationAnimal.UpdateNetwork;
Var InputData, OutputData: TNeuronWeights;
    RotForce: Double;
    I, P: Integer;
    Position: TVector2;
Begin
  fEyes := fFOV.GetColorsInFov(FOV_SAMPLE_COUNT);

  // przygotuj dane wejściowe
  SetLength(InputData, FOV_SAMPLE_COUNT*3 + 2);

  // sensory oczu
  For I := 0 To FOV_SAMPLE_COUNT-1 Do
  Begin
		P := 2 + I*3;

    RGBtoLab(fEyes[I], InputData[P], InputData[P+1], InputData[P+2]);

    InputData[P] /= 10;
    InputData[P+1] /= 10;
    InputData[P+2] /= 10;
  End;

  // sensor kierunku
  I := High(InputData) - 1;

  InputData[I] := fLookAt.fX;
  InputData[I+1] := fLookAt.fY;

  fLastInput := InputData;

  // daj sieci je przetworzyć
  OutputData := fNetwork.Propagate(InputData);
  fLastOutput := OutputData;

  // przekształć dane z sieci na czytelną formę
  fLeftSpeed := abs(OutputData[0]);
  fRightSpeed := abs(OutputData[1]);

  RotForce := fLeftSpeed - fRightSpeed;

  if (RotForce < -0.3) Then
    RotForce := -0.3;

  if (RotForce > 0.3) Then
    RotForce := 0.3;

  fRotation += RotForce;
  fSpeed := fLeftSpeed + fRightSpeed;

	{ fRotation := arctan2(mouse_Y() - fPosition.fY , mouse_X() - fPosition.fX); // sterowanie myszką
  fSpeed := 2; }

  // zaktualizuj wektor patrzenia
  fLookAt.fX := cos(fRotation);
  fLookAt.fY := sin(fRotation);

  // zaktualizuj pozycję
  Position := self.GetPosition + fLookAt * fSpeed;

  // pilnuj, aby nie wyszedł poza mapę
  if (Position.fX < 0) Then
    Position.fX := GameWidth;

  if (Position.fY < 0) Then
    Position.fY := GameHeight;

  if (Position.fX > GameWidth) Then
    Position.fX := 0;

  if (Position.fY > GameHeight) Then
    Position.fY := 0;

  self.SetPosition(Position);

  // przetwórz pole widzenia
  fFOV.Process(Position, -fLookAt);
End;

(* Konstruktor *)
Constructor TSimulationAnimal.Create(const Position: TVector2);
Begin
  inherited Create(saokAnimal, Position);

  fShape.AddFigure(TSimulationFigure.CreateCircle($0000FF, TVector2.Create(0, 0), 20));

  fFitness := 0;
  fRotation := Random() * 2 * pi;
  fLookAt.fX := cos(fRotation);
  fLookAt.fY := sin(fRotation);

  SetLength(fEyes, 1);

  fFOV := TFieldOfView.Create(FOV_ANGLE, FOV_DISTANCE);

  fNetwork := TNeuralNetwork.Create([FOV_SAMPLE_COUNT*3 + 2, 64, 2]);

  SetLength(fLastInput, 0);
End;

(* Resetuje indeks przystosowania, wywoływane automatycznie z poziomu TGeneticAlgorithm *)
Procedure TSimulationAnimal.ResetFitness;
Begin
  self.SetPosition(TVector2.Create(Random(GameWidth), Random(GameHeight)));

  fFitness := 0;
  fRotation := Random() * 2 * pi;
  fLookAt.fX := cos(fRotation);
  fLookAt.fY := sin(fRotation);
End;

(* Wywoływane podczas renderowania zwierzęcia *)
Procedure TSimulationAnimal.OnDraw;
Var I, Deg, DegStep: Integer;
    Color: TColor;
    Pos: TVector2;
Begin
  // fFOV.GetColorsInFov(FOV_SAMPLE_COUNT, True);
  Pos := self.GetPosition();

  Color := $FFFFFF;

  pr2d_Line(Pos.fX, Pos.fY, Pos.fX + fLookAt.fX * 10, Pos.fY + fLookAt.fY * 10, $00FF00);
  text_DrawEx(fntMain, Pos.fX, Pos.fY, 1, 0, IntToStr(Round(fFitness)), 255, Color);

  // narysuj widok z oczu
  Deg := Round(arctan2(fLookAt.fY, fLookAt.fX) / pi * 180) - (FOV_ANGLE div 2);
  DegStep := FOV_ANGLE div Length(fEyes);

  For I := 0 To High(fEyes) Do
  Begin
    DrawArc(Pos.fX, Pos.fY, 20, Deg, DegStep, fEyes[I]);
    Inc(Deg, DegStep);
  End;
End;

(* Wywoływane podczas aktualizowania stanu zwierzęcia *)
Procedure TSimulationAnimal.OnUpdate;
Begin
  self.UpdateNetwork();
End;

(* Wywoływane podczas kolizji *)
Procedure TSimulationAnimal.OnCollision(const Obj: TSimulationAbstractObject);
Var Food: TSimulationFood;
Begin
  // jeśli napotkaliśmy jedzenie
  if (Obj.IsFood) Then
  Begin
    Food := (Obj as TSimulationFood);

    if (Food.GetKind = sfkInfany) Then
    Begin
      if (not MagicTmp) Then
    		fFitness += 1;
    End;
  End;
End;

(* Zwraca sieć neuronową danego zwierzęcia *)
Function TSimulationAnimal.GetNetwork: TNeuralNetwork;
Begin
  Result := fNetwork;
End;

(* Zwraca indeks przystosowania *)
Function TSimulationAnimal.GetFitness: Double;
Begin
  Result := fFitness;
End;
End.

