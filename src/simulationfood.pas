{$mode objfpc}{$H+}
Unit SimulationFood;

Interface

Uses
  Classes, SysUtils,
  Colors, MyMath, SimulationAbstractObject, SimulationFigure, Ray;

{ Rodzaje jedzenia }
Type TSimulationFoodKind =
(
  sfkInfany,
  sfkAzurelid,
  sfkSlate
);

{ Struktura definiująca stałe atrybuty jedzenia }
Type TSimulationFoodAttributes =
  Record
    fName, fPolishName: String;
    fColor: TColor;
    fQuality: Integer;
  End;

Const SimulationFoodAttributes:
  Array[TSimulationFoodKind] of TSimulationFoodAttributes =
(
  (fName: 'Infany'; fPolishName: 'Kwiat nowu'; fColor: $ffffff; fQuality: 10),
  (fName: 'Azurelid'; fPolishName: 'Lazurasz'; fColor: $5ea9de; fQuality: 3),
  (fName: 'Slate'; fPolishName: 'Łupek'; fColor: $ff0000; fQuality: -10)
);

{ Klasa reprezentująca jedzenie }
Type TSimulationFood =
  Class (TSimulationAbstractObject)
    Private
      // rodzaj jedzenia
      fKind: TSimulationFoodKind;

      // promień, w jakim jedzenie jest dostępne od pozycji
      fRadius: Single;

      // @note: podczas jedzenia zmniejsza się promień, aż w końcu znika

    Public
      Constructor Create(const Position: TVector2; const Kind: TSimulationFoodKind; const Radius: Single);

      Function GetName: String; override;
      Function GetPolishName: String; override;

      Procedure OnDraw; override;
      Procedure OnUpdate; override;
      Procedure OnCollision(const Obj: TSimulationAbstractObject); override;

      Function GetKind: TSimulationFoodKind;
    End;

Implementation
Uses
  zglHeader,
  Engine, SimulationAnimal;

(* Konstruktor *)
Constructor TSimulationFood.Create(const Position: TVector2; const Kind: TSimulationFoodKInd; const Radius: Single);
Begin
	inherited Create(saokFood, Position);

  fKind := Kind;
  fRadius := Radius;

  fShape.AddFigure(TSimulationFigure.CreateCircle(SimulationFoodAttributes[Kind].fColor, TVector2.Create(0, 0), Radius));
End;

(* Zwraca nazwę pożywienia *)
Function TSimulationFood.GetName: String;
Begin
  Result := SimulationFoodAttributes[fKind].fName;
End;

(* Zwraca nazwę pożywienia *)
Function TSimulationFood.GetPolishName: String;
Begin
  Result := SimulationFoodAttributes[fKind].fPolishName;
End;

(* Renderuje jedzenie *)
Procedure TSimulationFood.OnDraw;
Var Color: TColor;
    Pos: TVector2;
Begin
  Color := SimulationFoodAttributes[fKind].fColor;

  if (fIsMarked) Then
    Color := fMarkColor;

  Pos := self.GetPosition();

  pr2d_Circle(Pos.fX, Pos.fY, fRadius, Color, 255, 32, PR2D_SMOOTH);
  pr2d_Circle(Pos.fX, Pos.fY, fRadius, Color, 255, 32, PR2D_FILL);
End;

(* Aktualizuje stan jedzenia *)
Procedure TSimulationFood.OnUpdate;
Begin
  if (SimulationAnimal.MagicTmp and (fKind = sfkInfany)) Then
    self.SetPosition(TVector2.Create(mouse_X(), mouse_Y()));
End;

(* Wywoływane podczas kolizji *)
Procedure TSimulationFood.OnCollision(const Obj: TSimulationAbstractObject);
Begin
  if ((fKind = sfkSlate) or (not SimulationAnimal.MagicTmp)) Then
    self.SetPosition(TVector2.Create(Random(GameWidth), Random(GameHeight)));
End;

(* Zwraca rodzaj jedzenia *)
Function TSimulationFood.GetKind: TSimulationFoodKind;
Begin
	Result := fKind;
End;
End.
