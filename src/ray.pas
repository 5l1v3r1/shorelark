{$mode objfpc}{$H+}
Unit Ray;

Interface

Uses
  Classes, SysUtils,
  MyMath, Colors;

{ Generyczny promień }
Type TRay =
  Class
    Private
      fOrigin: TVector2;
      fDirection: TVector2;

    Public
      Constructor Create(const Origin, Direction: TVector2);

      Procedure SetDirection(const Direction: TVector2);

      Function GetOrigin: TVector2;
      Function GetDirection: TVector2;
    End;

Implementation

(* Konstruktor *)
Constructor TRay.Create(const Origin, Direction: TVector2);
Begin
  fOrigin := Origin;
  fDirection := Direction;
End;

(* Zmienia kierunek promienia *)
Procedure TRay.SetDirection(const Direction: TVector2);
Begin
  fDirection := Direction;
End;

(* Zwraca źródło promienia *)
Function TRay.GetOrigin: TVector2;
Begin
  Result := fOrigin;
End;

(* Zwraca kierunek promienia *)
Function TRay.GetDirection: TVector2;
Begin
  Result := fDirection;
End;
End.
