{$mode objfpc}{$H+}
Unit Chart;

Interface

Uses
  Classes, SysUtils, FGL;

Type
  PChartItem = ^TChartItem;
  TChartItem =
    Record
      fMin, fMax, fValue: Double;
    End;

Type TChartData = specialize TFPGList<PChartItem>;

{ Klasa reprezentująca generyczny wykres }
Type TChart =
  Class
    Private
      fData: TChartData;
      fX, fY, fWidth, fHeight: Single;

      fGlobalMin, fGlobalMax: Double;

      Procedure Recalculate;

    Public
      Constructor Create(const X, Y, Width, Height: Single);
      Destructor Destroy; override;

      Procedure AddItem(const Item: TChartItem);
      Procedure OnDraw;
    End;

Implementation
Uses zglHeader;

(* Przelicza dane potrzebne do narysowania wykresu *)
Procedure TChart.Recalculate;
Var Item: PChartItem;
Begin
  fGlobalMin := 100000;
  fGlobalMax := -100000;

  For Item in fData Do
  Begin
    // GlobalMin
    if (Item^.fMin < fGlobalMin) Then
      fGlobalMin := Item^.fMin;

    if (Item^.fValue < fGlobalMin) Then
      fGlobalMin := Item^.fValue;

    if (Item^.fMax < fGlobalMin) Then
      fGlobalMin := Item^.fMax;

    // GlobalMax
    if (Item^.fMin > fGlobalMax) Then
      fGlobalMax := Item^.fMin;

    if (Item^.fValue > fGlobalMax) Then
      fGlobalMax := Item^.fValue;

    if (Item^.fMax > fGlobalMax) Then
      fGlobalMax := Item^.fMax;
  End;
End;

(* Konstruktor *)
Constructor TChart.Create(const X, Y, Width, Height: Single);
Begin
  fData := TChartData.Create();
  fX := X;
  fY := Y;
  fWidth := Width;
  fHeight := Height;
  fGlobalMin := 0;
  fGlobalMax := 0;
End;

(* Destruktor *)
Destructor TChart.Destroy;
Var Item: PChartItem;
Begin
  For Item in fData Do
    FreeMem(Item);

  fData.Free();
End;

(* Dodaje daną do wykresu *)
Procedure TChart.AddItem(const Item: TChartItem);
Var ItemPnt: PChartItem;
Begin
  New(ItemPnt);
  ItemPnt^ := Item;

  fData.Add(ItemPnt);

  self.Recalculate();
End;

(* Renderuje wykres *)
Procedure TChart.OnDraw;
Var I: Integer;
    Delta, Coeff: Single;
    Item, Item2: TChartItem;
    X: Single;
Begin
  pr2d_Rect(fX, fY, fWidth, fHeight, $000000, 100, PR2D_FILL);
  pr2d_Rect(fX, fY, fWidth, fHeight);

  X := fX + 1;

  Delta := fGlobalMax - fGlobalMin;

  if (Delta = 0) Then
    Delta := 1;

  Coeff := (fHeight - 2) / Delta;

  // dla każdego elementu na wykresie
  For I := 0 To fData.Count-1 Do
  Begin
    Item := fData[I]^;

    // jeśli wyszliśmy poza ramy, zakończ rysowanie tu
    if (X >= fX + fWidth) Then
      Break;

    // narysuj dane
    pr2d_Line(X, fY + fHeight - (Item.fMin - fGlobalMin) * Coeff - 1, X, fY + fHeight - (Item.fMax - fGlobalMin) * Coeff - 1, $00FF00);
    pr2d_Pixel(X, fY + fHeight - (Item.fValue - fGlobalMin) * Coeff, $FF0000);

    // idź dalej
		X += 1;
  End;

  // połącz główne elementy liniami
  X := fX + 1;

  For I := 1 To fData.Count-1 Do
  Begin
    Item := fData[I-1]^;
    Item2 := fData[I]^;

    pr2d_Line(X, fY + fHeight - (Item.fValue - fGlobalMin) * Coeff - 1, X+1, fY + fHeight - (Item2.fValue - fGlobalMin) * Coeff - 1, $FF0000);
    X += 1;
  End;
End;

End.
