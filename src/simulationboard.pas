{$mode objfpc}{$H+}
Unit SimulationBoard;

Interface

Uses
  Classes, SysUtils,
  Logger, MyMath, SimulationAbstractObject, GeneticAlgorithm;

{ Klasa opakowująca planszę }
Type TSimulationBoard =
  Class
    Private
      fLogger: TLogger;

      fWidth, fHeight: Integer;

      fObjects: TSimulationAbstractObjectList;
      fObjectsToRemove: TSimulationAbstractObjectList;

      fDuringUpdate: Boolean;

      fGeneticAlgorithm: TGeneticAlgorithm;

      fTurnCount: uint64;

    Public
      Constructor Create(const Width, Height: Integer);
      Destructor Destroy; override;

      Procedure AddObject(const Obj: TSimulationAbstractObject);
      Procedure RemoveObject(const Obj: TSimulationAbstractObject);

      Function GetObjects: TSimulationAbstractObjectList;
      Function GetGeneticAlgorithm: TGeneticAlgorithm;

      Procedure OnDraw;
      Procedure OnUpdate;

      Function GetTurnCount: uint64;
    End;

Implementation
Uses SimulationAnimal;

// ----- TSimulationBoard ----- //

(* Konstruktor *)
Constructor TSimulationBoard.Create(const Width, Height: Integer);
Var SampleAnimal: TSimulationAnimal;
Begin
  // sprawdź czy wymiary są poprawne
  if ((Width < 0) or (Height < 0)) Then
    raise Exception.CreateFmt('Nieprawidłowe wymiary planszy: %d, %d', [Width, Height]);

  fLogger := TLogger.Create('SimBoard');

  fWidth := Width;
  fHeight := Height;

  fObjects := TSimulationAbstractObjectList.Create();
  fObjectsToRemove := TSimulationAbstractObjectList.Create();

  fDuringUpdate := False;
  fTurnCount := 0;

  // aby utworzyć algorytm genetyczny, potrzebujemy znać ilość wag w 'mózgu' zwierzęcia
  SampleAnimal := TSimulationAnimal.Create(TVector2.Create(0, 0));

  Try
    fGeneticAlgorithm := TGeneticAlgorithm.Create(SampleAnimal.GetNetwork().GetTotalWeightCount());
  Finally
    SampleAnimal.Free;
  End;
End;

(* Destruktor *)
Destructor TSimulationBoard.Destroy;
Var I: Integer;
Begin
  fLogger.Info('Zwalnianie planszy...');
  fLogger.Info('Mamy %d obiektów do usunięcia.', [fObjects.Count]);

  For I := 0 To fObjects.Count-1 Do
    fObjects[I].Free();

  fObjects.Free();
  fObjectsToRemove.Free();
  fLogger.Free();
End;

(* Dodaje obiekt do symulacji *)
Procedure TSimulationBoard.AddObject(const Obj: TSimulationAbstractObject);
Begin
  fLogger.Info('Dodawanie nowego obiektu do symulacji: %s (%f, %f)', [Obj.GetName(), Obj.GetPosition().fX, Obj.GetPosition().fY]);

  if (fObjects.IndexOf(Obj) > -1) Then
  Begin
    fLogger.Warn('Obiekt już na liście, pomijanie!');
    Exit;
  End;

  fObjects.Add(Obj);

  if (Obj is TSimulationAnimal) Then
    fGeneticAlgorithm.AddAnimal(Obj as TSimulationAnimal);
End;

(* Usuwa obiekt z symulacji *)
Procedure TSimulationBoard.RemoveObject(const Obj: TSimulationAbstractObject);
Begin
  fLogger.Info('Usuwanie obiektu z symulacji: %s (%f, %f)', [Obj.GetName(), Obj.GetPosition().fX, Obj.GetPosition().fY]);

  if (fDuringUpdate) Then
    fObjectsToRemove.Add(Obj) Else
    fObjects.Remove(Obj);

  if (Obj is TSimulationAnimal) Then
    fGeneticAlgorithm.RemoveAnimal(Obj as TSimulationAnimal);
End;

(* Zwraca listę wszystkich obiektów uczestniczących w symulacji *)
Function TSimulationBoard.GetObjects: TSimulationAbstractObjectList;
Begin
  Result := fObjects;
End;

(* Zwraca instancję algorytmu genetycznego *)
Function TSimulationBoard.GetGeneticAlgorithm: TGeneticAlgorithm;
Begin
  Result := fGeneticAlgorithm;
End;

(* Rysuje planszę *)
Procedure TSimulationBoard.OnDraw;
Var I: Integer;
Begin
  For I := 0 To fObjects.Count-1 Do
    fObjects[I].OnDraw();
End;

(* Aktualizuje planszę *)
Procedure TSimulationBoard.OnUpdate;
Var I, J: Integer;
Begin
  fDuringUpdate := True;

  Inc(fTurnCount);

  if (fTurnCount mod 2000 = 0) Then
    fGeneticAlgorithm.Step();

  // zaktualizuj obiekty
  For I := 0 To fObjects.Count-1 Do
    fObjects[I].OnUpdate();

  // zaktualizuj modele kolizji
  For I := 0 To fObjects.Count-1 Do
  Begin
    For J := 0 To fObjects.Count-1 Do
    Begin
      // pomiń kolizję z samym sobą
      if (I = J) Then
        Continue;

      // sprawdź kolizję
      if (fObjects[I].CheckCollision(fObjects[J])) Then
      Begin
        fObjects[I].OnCollision(fObjects[J]);
        fObjects[J].OnCollision(fObjects[I]);
      End;
    End;
  End;

  fDuringUpdate := False;

  // usuń obiekty oznaczone do usunięcia
  For I := 0 To fObjectsToRemove.Count-1 Do
    fObjects.Remove(fObjectsToRemove[I]);

  fObjectsToRemove.Clear();
End;

(* Zwraca aktualny numer tury *)
Function TSimulationBoard.GetTurnCount: uint64;
Begin
  Result := fTurnCount;
End;

End.
