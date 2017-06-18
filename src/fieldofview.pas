{$mode objfpc}{$H+}
Unit FieldOfView;

Interface

Uses
  Classes, SysUtils,
  SimulationAbstractObject, SimulationFigure, Colors, MyMath, Ray;

{ Klasa opakowująca pole widzenia }
Type TFieldOfView =
  Class
    Private
      fObjects: TSimulationAbstractObjectList;
      fObjectsInFov: TSimulationAbstractObjectList;

      fAngle: Single;
      fAngleRad: Single;
      fAngleCos: Single;
      fMaxDistance, fMaxDistanceSq: Single;

      fPosition: TVector2;
      fLookAt: TVector2;

    Public
      Constructor Create(const Angle, MaxDistance: Double);
      Destructor Destroy; override;

      Procedure Process(const Position, LookAt: TVector2);
      Function GetObjectsInFov: TSimulationAbstractObjectList;
      Function GetColorsInFov(const Count: Integer; const Render: Boolean = False): TColorArray;
    End;

Implementation
Uses
  zglHeader, Math,
  Engine;

(* Konstruktor, przyjmuje kąty jako stopnie *)
Constructor TFieldOfView.Create(const Angle, MaxDistance: Double);
Begin
  fAngle := Angle;
  fAngleRad := Angle * pi / 180;
  fAngleCos := cos(fAngleRad / 2);

  fMaxDistance := MaxDistance;
  fMaxDistanceSq := sqr(MaxDistance);

  fObjects := nil;
  fObjectsInFov := TSimulationAbstractObjectList.Create();
End;

(* Destruktor *)
Destructor TFieldOfView.Destroy;
Begin
  fObjectsInFov.Destroy();
End;

(* Przetwarza pole widzenia dla podanych współrzędnych *)
Procedure TFieldOfView.Process(const Position, LookAt: TVector2);
Var Obj: TSimulationAbstractObject;
    ObjPos, VecDistance: TVector2;
    I: Integer;
    Angle: Double;
Begin
  if (fObjects = nil) Then
    fObjects := Engine.GetObjects();

  fObjectsInFov.Clear();

  fPosition := Position;
  fLookAt := LookAt;

  // dla każdego obiektu
  For I := 0 To fObjects.Count-1 Do
  Begin
    Obj := fObjects[I];

    // pomiń nie-jedzenie
    if (not Obj.IsFood) Then
      Continue;

    // pobierz pozycję
    ObjPos := Obj.GetPosition();

    // jeśli znajduje się za daleko, pomiń
    if (ObjPos.GetSquaredDistanceTo(Position) > fMaxDistanceSq) Then
      Continue;

    // sprawdź kąty
    VecDistance := (Position - ObjPos).GetNormalized();

    if ((VecDistance.fX = 0) and (VecDistance.fY = 0)) Then
      Continue;

    Angle := fLookAt.GetDotProduct(VecDistance);

    if (Angle < fAngleCos) Then
      Continue;

    // yay, w polu widzenia!
    fObjectsInFov.Add(Obj);
  End;
End;

(* Zwraca obiekty w widoku *)
Function TFieldOfView.GetObjectsInFov: TSimulationAbstractObjectList;
Begin
  Result := fObjectsInFov;
End;

(* Zwraca kolory obiektów będące w widoku *)
Function TFieldOfView.GetColorsInFov(const Count: Integer; const Render: Boolean): TColorArray;
Var Samples: TColorArray;

    AngleRad, AngleRadPerStep: Single;

    BestHit, LastHit: THitData;
    Color: TColor;
    Ray: TRay;

    I, J: Integer;
Begin
  SetLength(Result, Count);
  SetLength(Samples, Count * 9);

  // policz liczbę kroków na każde dodanie, aby promienie były rozłożone równomiernie
  AngleRadPerStep := fAngleRad / High(Samples);
  AngleRad := arctan2(fLookAt.fY, fLookAt.fX) - (AngleRadPerStep * (High(Samples) / 2));

  Ray := TRay.Create(fPosition, TVector2.Create(0, 0));

  if (Render) Then
  Begin
	  fObjects := Engine.GetObjects();
	  For I := 0 To fObjects.Count-1 Do
 	    fObjects[I].UnMark();
  End;

  // dla każdego kąta
  For I := 0 To High(Samples) Do
  Begin
    Ray.SetDirection(TVector2.Create(-cos(AngleRad), -sin(AngleRad)));

    if (Render) Then
      pr2d_Line(fPosition.fX, fPosition.fY, fPosition.fX + Ray.GetDirection().fX * fMaxDistance, fPosition.fY + Ray.GetDirection().fY * fMaxDistance, $00FF00);

    Color := $000000;
    BestHit.fDistance := 100000;
    BestHit.fObject := nil;

    // sprawdź czy promień zderzy się z jakimś obiektem będącym w polu widzenia
    For J := 0 To fObjectsInFov.Count-1 Do
    Begin
      if (fObjectsInFov[J].HitTest(Ray, LastHit) and (LastHit.fDistance < BestHit.fDistance)) Then
      Begin
        BestHit := LastHit;
        Color := BestHit.fColor;
      End;
    End;

    if (Render) Then
      if (BestHit.fObject <> nil) Then
        TSimulationAbstractObject(BestHit.fObject).Mark($FF0000);

    // zapisz kolor
    Samples[I] := Color;

    // idźmy dalej
    AngleRad += AngleRadPerStep;
  End;

  // przelicz próbki
  J := 0;

  For I := 0 To High(Result) Do
  Begin
    Result[I] :=
      BlurColors(
        BlurColors(Samples[J], Samples[J+1], Samples[J+2]),
        BlurColors(Samples[J+3], Samples[J+4], Samples[J+5]),
        BlurColors(Samples[J+6], Samples[J+7], Samples[J+8])
      );

    Inc(J, 9);
  End;

  Ray.Free();
End;
End.
