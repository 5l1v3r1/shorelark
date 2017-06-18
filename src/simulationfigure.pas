{$mode objfpc}{$H+}
Unit SimulationFigure;

Interface
Uses MyMath, Colors, Ray;

{ Rodzaj figury }
Type TSimulationFigureKind = (sfkCircle);

{ Struktura zawierająca dane o zderzeniu }
Type THitData =
  Record
    fDistance: Double;
    fColor: TColor;
    fObject: TObject; // TSimulationAbstractObject
  End;

{ Klasa opisująca pojedynczą figurę geometryczną }
Type TSimulationFigure =
  Class
    Private
      // rodzaj figury
      fKind: TSimulationFigureKind;

      // kolor figury
      fColor: TColor;

      // relatywna pozycja figury
      fRelPosition: TVector2;

      // absolutna pozycja figury (ustawiana automatycznie w TSimulationShape)
      fAbsPosition: TVector2;

      // parametry figury (zależne od rodzaju)
      fParams: Array of Double;

    Private
      Function CheckCollision_CircleCircle(const Figure: TSimulationFigure): Boolean;
      Function HitTest_Circle(const Ray: TRay; out Hit: THitData): Boolean;

    Public
      Constructor CreateCircle(const Color: TColor; const Center: TVector2; const Radius: Double);

			Procedure UpdateAbsolutePosition(const BasePosition: TVector2);

			Function CheckCollision(const Figure: TSimulationFigure): Boolean;
      Function HitTest(const Ray: TRay; out Hit: THitData): Boolean;
    End;

Implementation
Uses SysUtils;

Const
  CIRCLE_RADIUS = 0;

(* Test zderzenia koło - koło *)
Function TSimulationFigure.CheckCollision_CircleCircle(const Figure: TSimulationFigure): Boolean;
Begin
  Result :=
    sqr(fAbsPosition.fX - Figure.fAbsPosition.fX) + sqr(fAbsPosition.fY - Figure.fAbsPosition.fY) <= sqr(fParams[CIRCLE_RADIUS] + Figure.fParams[CIRCLE_RADIUS]);
End;

(* Test kolizji promień - koło *)
Function TSimulationFigure.HitTest_Circle(const Ray: TRay; out Hit: THitData): Boolean;
Var T, A, B, C, Disc, DiscSq, Denom: Double;
    Distance: TVector2;
Begin
  Distance := Ray.GetOrigin() - fAbsPosition;
  A := Ray.GetDirection().GetSquaredLength();
  B := (Distance * 2).GetDotProduct(Ray.GetDirection());
  C := Distance.GetSquaredLength() - sqr(fParams[CIRCLE_RADIUS]);
  Disc := sqr(B) - 4 * A * C;

  if (Disc < 0) Then
    Exit(False);

  DiscSq := sqrt(Disc);
  Denom := 2 * A;

  T := (-B - DiscSq) / Denom;

  if (T < 0) Then
    T := (-B + DiscSq) / Denom;

  if (T < 0) Then
    Exit(False);

  // mamy zderzenie!
  Hit.fColor := self.fColor;
  Hit.fDistance := T;

  Result := True;
End;

(* Konstruktor koła *)
Constructor TSimulationFigure.CreateCircle(const Color: TColor; const Center: TVector2; const Radius: Double);
Begin
  fKind := sfkCircle;
  fColor := Color;
  fRelPosition := Center;

  SetLength(fParams, 1);
  fParams[CIRCLE_RADIUS] := Radius;
End;

(* Aktualizuje absolutną pozycję *)
Procedure TSimulationFigure.UpdateAbsolutePosition(const BasePosition: TVector2);
Begin
  fAbsPosition := BasePosition + fRelPosition;
End;

(* Wykonuje test kolizji *)
Function TSimulationFigure.CheckCollision(const Figure: TSimulationFigure): Boolean;
Begin
  Result := False;

	Case fKind of
    // koło - ...
    sfkCircle:
    Begin
			Case Figure.fKind of
        sfkCircle: Result := CheckCollision_CircleCircle(Figure);
      End;
    End;
  End;
End;

(* Wykonuje test zderzenia *)
Function TSimulationFigure.HitTest(const Ray: TRay; out Hit: THitData): Boolean;
Begin
  Result := False;

  if (fKind = sfkCircle) Then
    Result := self.HitTest_Circle(Ray, Hit);
End;

End.
