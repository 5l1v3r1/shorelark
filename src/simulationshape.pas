{$mode objfpc}{$H+}
Unit SimulationShape;

Interface
Uses SimulationFigure, Ray, MyMath;

{ Klasa opisująca cały kształt }
Type TSimulationShape =
  Class
    Private
      // figury składające się na kształt
			fFigures: Array of TSimulationFigure;

      // pozycja kształtu
      fPosition: TVector2;

    Public
      Constructor Create();

      Procedure SetPosition(const Position: TVector2);
      Procedure AddFigure(const Figure: TSimulationFigure);

      Function CheckCollision(const Shape: TSimulationShape): Boolean;
      Function HitTest(const Ray: TRay; out Hit: THitData): Boolean;
    End;

Implementation

(* Konstruktor *)
Constructor TSimulationShape.Create;
Begin
  SetLength(fFigures, 0);
End;

(* Przemieszcza kształt *)
Procedure TSimulationShape.SetPosition(const Position: TVector2);
Var Fig: TSimulationFigure;
Begin
  fPosition := Position;

  // dokonaj aktualiacji pozycji absolutnych
  For Fig in fFigures Do
    Fig.UpdateAbsolutePosition(Position);
End;

(* Dodaje figurę do listy figur *)
Procedure TSimulationShape.AddFigure(const Figure: TSimulationFigure);
Begin
  SetLength(fFigures, Length(fFigures) + 1);
  fFigures[High(fFigures)] := Figure;

  Figure.UpdateAbsolutePosition(fPosition);
End;

(* Test kolizji *)
Function TSimulationShape.CheckCollision(const Shape: TSimulationShape): Boolean;
Var I, J: Integer;
Begin
  For I := 0 To High(fFigures) Do
  Begin
    For J := 0 To High(Shape.fFigures) Do
    Begin
      if (fFigures[I].CheckCollision(Shape.fFigures[J])) Then
        Exit(True);
    End;
  End;

	Exit(False);
End;

(* Test zderzenia *)
Function TSimulationShape.HitTest(const Ray: TRay; out Hit: THitData): Boolean;
Var I: Integer;
    TmpHit: THitData;
Begin
  Result := False;

	Hit.fDistance := 1000000;

  // wykonaj symulację zderzeń i wybierz najbliższe
  For I := 0 To High(fFigures) Do
  Begin
    if (fFigures[I].HitTest(Ray, TmpHit) and (TmpHit.fDistance < Hit.fDistance)) Then
    Begin
      Hit := TmpHit;
      Result := True;
    End;
  End;
End;

End.
