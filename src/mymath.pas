{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
Unit MyMath;

Interface

Uses
  Classes, SysUtils;

{ Struktura reprezentująca dwuwymiarowy wektor }
Type TVector2 =
  Record
    fX, fY: Double;

    Function Create(const X, Y: Double): TVector2; static;

    Function GetLength: Double;
    Function GetSquaredLength: Double;
    Function GetNormalized: TVector2;
    Function GetDistanceTo(const Vector: TVector2): Double;
    Function GetSquaredDistanceTo(const Vector: TVector2): Double;
    Function GetRotated(const Anchor: TVector2; const Angle: Double): TVector2;
    Function GetDotProduct(const Vector: TVector2): Double;
  End;

{ Struktura reprezentująca prostokąt }
Type TRectangle =
  Record
    fTopLeft, fBottomRight: TVector2;
  End;

Operator + (const A, B: TVector2): TVector2;
Operator - (const A, B: TVector2): TVector2;
Operator - (const A: TVector2): TVector2;
Operator * (const Vector: TVector2; const Coeff: Double): TVector2;
Operator / (const Vector: TVector2; const Coeff: Double): TVector2;

Function Intersects(const R1, R2: TRectangle): Boolean;

Implementation

(* TVector2 + TVector2 *)
Operator + (const A, B: TVector2): TVector2;
Begin
  Result.fX := A.fX + B.fX;
  Result.fY := A.fY + B.fY;
End;

(* TVector2 - TVector2 *)
Operator - (const A, B: TVector2): TVector2;
Begin
  Result.fX := A.fX - B.fX;
  Result.fY := A.fY - B.fY;
End;

(* - TVector2 *)
Operator - (const A: TVector2): TVector2;
Begin
  Result.fX := -A.fX;
  Result.fY := -A.fY;
End;

(* TVector2 * Double *)
Operator * (const Vector: TVector2; const Coeff: Double): TVector2;
Begin
  Result.fX := Vector.fX * Coeff;
  Result.fY := Vector.fY * Coeff;
End;

(* TVector2 * Double *)
Operator / (const Vector: TVector2; const Coeff: Double): TVector2;
Begin
  Result.fX := Vector.fX / Coeff;
  Result.fY := Vector.fY / Coeff;
End;

(* Sprawdza czy dwa prostokąty nachodzą na siebie *)
Function Intersects(const R1, R2: TRectangle): Boolean;
Begin
  Result :=
    ((R1.fTopLeft.fX < R2.fBottomRight.fX) and (R1.fBottomRight.fX > R2.fTopLeft.fX)) and
    ((R1.fTopLeft.fY < R2.fBottomRight.fY) and (R1.fBottomRight.fY > R2.fTopLeft.fY));
End;

// ----- TVector2 ----- //

(* Tworzy nowy dwuwymiarowy wektor *)
Function TVector2.Create(const X, Y: Double): TVector2; static;
Begin
  Result.fX := X;
  Result.fY := Y;
End;

(* Zwraca długość wektora *)
Function TVector2.GetLength: Double;
Begin
  Result := sqrt(sqr(fX) + sqr(fY));
End;

(* Zwraca długość wektora podniesioną do kwadratu *)
Function TVector2.GetSquaredLength: Double;
Begin
  Result := sqr(fX) + sqr(fY);
End;

(* Zwraca znormalizowany wektor *)
Function TVector2.GetNormalized: TVector2;
Begin
  Result := self / self.GetLength();
End;

(* Zwraca odległość do podanego wektora *)
Function TVector2.GetDistanceTo(const Vector: TVector2): Double;
Begin
  Result := sqrt(sqr(Vector.fX - fX) + sqr(Vector.fY - fY));
End;

(* Zwraca odległość do podanego wektora podniesioną do kwadratu *)
Function TVector2.GetSquaredDistanceTo(const Vector: TVector2): Double;
Begin
  Result := sqr(Vector.fX - fX) + sqr(Vector.fY - fY);
End;

(* Zwraca wektor obrócony względem Anchor o Angle stopni *)
Function TVector2.GetRotated(const Anchor: TVector2; const Angle: Double): TVector2;
Var TmpX, TmpY, RotatedX, RotatedY: Double;
Begin
  TmpX := fX - Anchor.fX;
  TmpY := fY - Anchor.fY;

  RotatedX := TmpX * cos(Angle) - TmpY * sin(Angle);
  RotatedY := TmpX * sin(Angle) + TmpY * cos(Angle);

  Result.fX := RotatedX + Anchor.fX;
  Result.fY := RotatedY + Anchor.fY;
End;

(* Zwraca iloczyn skalarny między naszym wektorem oraz Vector *)
Function TVector2.GetDotProduct(const Vector: TVector2): Double;
Begin
  Result := (fX * Vector.fX) + (fY * Vector.fY);
End;

End.
