{$mode objfpc}{$H+}
Unit SimulationAbstractObject;

Interface

Uses
  Classes, SysUtils, FGL,
  MyMath, Colors, Ray, SimulationShape, SimulationFigure;

Type TSimulationAbstractObjectKind = (saokFood, saokAnimal);
Type TSimulationAbstractObject = class;

{ Klasa reprezentująca pojedynczy obiekt/jednostkę poddawaną symulacji }
Type
  TSimulationAbstractObject =
  Class abstract
    Private
      // indeks obiektu, unikalny dla każdego obiektu
      fId: Integer;

      // rodzaj obiektu (dzięki temu możemy szybko sprawdzić co jest czym bez zaprzęgania powolnego RTTI)
      fObjectKind: TSimulationAbstractObjectKind;

      // pozycja obiektu
      fPosition: TVector2;

    Protected
      // kształt obiektu
      fShape: TSimulationShape;

      // kolor oznaczenia (wykorzystywane do debugowania)
      fMarkColor: TColor;
      fIsMarked: Boolean;

    Public
      Constructor Create(const ObjectKind: TSimulationAbstractObjectKind; const Position: TVector2);

      Procedure Remove;

      Function CheckCollision(const Obj: TSimulationAbstractObject): Boolean;
      Function HitTest(const Ray: TRay; out Hit: THitData): Boolean;

      Procedure Mark(const Color: TColor);
      Procedure UnMark;

      Procedure SetPosition(const Position: TVector2);
      Function GetPosition: TVector2;

      Function IsFood: Boolean;
      Function IsAnimal: Boolean;

      Function GetName: String; virtual;
      Function GetPolishName: String; virtual;

      Procedure OnDraw; virtual abstract;
      Procedure OnUpdate; virtual abstract;
      Procedure OnCollision(const Obj: TSimulationAbstractObject); virtual;
    End;

Type TSimulationAbstractObjectList = specialize TFPGList<TSimulationAbstractObject>;

Implementation
Uses Engine;

Var CurrentObjectIndex: Integer = 0;

(* Konstruktor *)
Constructor TSimulationAbstractObject.Create(const ObjectKind: TSimulationAbstractObjectKind; const Position: TVector2);
Begin
  // przypisz id
  fId := CurrentObjectIndex;
  Inc(CurrentObjectIndex);

  // zapisz dane z parametrów
  fObjectKind := ObjectKind;
  fPosition := Position;

  // ustaw resztę
  fShape := TSimulationShape.Create();
  fShape.SetPosition(fPosition);

  fMarkColor := $000000;
  fIsMarked := False;
End;

(* Usuwa obiekt z symulacji *)
Procedure TSimulationAbstractObject.Remove;
Begin
  SimEngine.GetBoard().RemoveObject(self);
End;

(* Sprawdza czy nastąpiła kolizja między naszym obiektem oraz podanym w parametrze *)
Function TSimulationAbstractObject.CheckCollision(const Obj: TSimulationAbstractObject): Boolean;
Begin
  Result := fShape.CheckCollision(Obj.fShape);
End;

(* Wykonuje test zderzenia między nami a danym promieniem *)
Function TSimulationAbstractObject.HitTest(const Ray: TRay; out Hit: THitData): Boolean;
Begin
  Result := fShape.HitTest(Ray, Hit);
  Hit.fObject := self;
End;

(* Oznacza obiekt kolorem (wykorzystywane do debugowania) *)
Procedure TSimulationAbstractObject.Mark(const Color: TColor);
Begin
  fMarkColor := Color;
  fIsMarked := True;
End;

(* Usuwa oznazcenie kolorowe obiektu *)
Procedure TSimulationAbstractObject.UnMark;
Begin
  fMarkColor := $000000;
  fIsMarked := False;
End;

(* Zmienia pozycję obiektu *)
Procedure TSimulationAbstractObject.SetPosition(const Position: TVector2);
Begin
  fPosition := Position;
  fShape.SetPosition(self.fPosition);
End;

(* Zwraca pozycję obiektu *)
Function TSimulationAbstractObject.GetPosition: TVector2;
Begin
  Result := fPosition;
End;

(* Zwraca `true`, jeśli dany obiekt jest jedzeniem *)
Function TSimulationAbstractObject.IsFood: Boolean;
Begin
  Result := (fObjectKind = saokFood);
End;

(* Zwraca `true`, jeśli dany obiekt jest zwierzęciem *)
Function TSimulationAbstractObject.IsAnimal: Boolean;
Begin
  Result := (fObjectKind = saokAnimal);
End;

(* Zwraca angielską nazwę obiektu *)
Function TSimulationAbstractObject.GetName: String;
Begin
  Result := ClassName();
End;

(* Zwraca polską nazwę obiektu *)
Function TSimulationAbstractObject.GetPolishName: String;
Begin
  Result := ClassName();
End;

(* Wywoływane w trakcie zderzenia z obiektem, domyślnie nie robi nic *)
Procedure TSimulationAbstractObject.OnCollision(const Obj: TSimulationAbstractObject);
Begin
End;

End.
