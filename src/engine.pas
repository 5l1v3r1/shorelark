{$mode objfpc}{$H+}
Unit Engine;

Interface

Uses
  zglHeader, Classes, SysUtils,
  Logger, Colors, SimulationEngine, SimulationAbstractObject;

Procedure InitGame;

Const
  // wersja gry
  GameVersion = '0.1a';

  // szerokość i wysokość okna
  GameWidth = 1200;
  GameHeight = 800;

Var
  // główna czcionka
  fntMain: zglPFont;

  // silnik symulacji
  SimEngine: TSimulationEngine;

Procedure DrawArc(cX, cY, Radius, StartAngle, EndAngle: Double; const Color: TColor = $ffffff; const Alpha: Byte = 255; const SegmentCount: Integer = 32; const FX: Integer = 0);
Function GetObjects: TSimulationAbstractObjectList;
Function GetTurnCount: uint64;

Implementation
Uses
  Math,
  SimulationFood, SimulationAnimal, MyMath;
Var isPaused: Boolean = False;

(* Rysuje wycinek koła *)
Procedure DrawArc(cX, cY, Radius, StartAngle, EndAngle: Double; const Color: TColor = $ffffff; const Alpha: Byte = 255; const SegmentCount: Integer = 32; const FX: Integer = 0);
Var Theta, TanFactor, RadFactor, X, Y, tX, tY: Double;
    Pixels: Array of TVector2;
    P1, P2: TVector2;
    I: Integer;
Begin
  StartAngle *= (pi / 180);
  EndAngle *= (pi / 180);

  Theta := EndAngle / (SegmentCount - 1);

  TanFactor := tan(Theta);
  RadFactor := cos(Theta);

  X := Radius * cos(StartAngle);
  Y := Radius * sin(StartAngle);

  // przygotuj listę pikseli
  SetLength(Pixels, SegmentCount);

  For I := 0 To SegmentCount-1 Do
  Begin
    Pixels[I] := TVector2.Create(X + cX, Y + cY);

    tX := -Y;
    tY := X;

    X += tX * TanFactor;
    Y += tY * TanFactor;

    X *= RadFactor;
    Y *= RadFactor;
  End;

  // narysuj linie
  For I := 0 To SegmentCount-2 Do
  Begin
    P1 := Pixels[I];
    P2 := Pixels[I+1];

    pr2d_Line(P1.fX, P1.fY, P2.fX, P2.fY, Color, Alpha, FX);
  End;
End;

(* Zwraca listę wszystkich obiektów uczestniczących w symulacji *)
Function GetObjects: TSimulationAbstractObjectList;
Begin
  Result := SimEngine.GetBoard().GetObjects();
End;

(* Zwraca aktualny numer tury *)
Function GetTurnCount: uint64;
Begin
  Result := SimEngine.GetBoard().GetTurnCount();
End;

// ------------- //

(*	Wczytuje zasoby *)
Procedure OnInit;
Var I: Integer;
Begin
  AppLogger.Info('OnInit()');
  AppLogger.Info('Shorelack v. %s by Patryk Wychowaniec', [GameVersion]);

  // wczytaj główną czcionkę
  fntMain := font_LoadFromFile('data/main.zfi');

  if (fntMain = nil) Then
    raise Exception.Create('Nie udało się wczytać czcionki z pliku `main.zfi`!');

  // utwórz silnik symulacji
  SimEngine := TSimulationEngine.Create(GameWidth, GameHeight);

  For I := 1 To 80 Do
    SimEngine.GetBoard().AddObject(TSimulationFood.Create(TVector2.Create(Random(GameWidth), Random(GameHeight)), sfkInfany, 10));

//  For I := 1 To 30 Do
//    SimEngine.GetBoard().AddObject(TSimulationFood.Create(TVector2.Create(Random(GameWidth), Random(GameHeight)), sfkSlate, 10));

  For I := 1 To 30 Do
    SimEngine.GetBoard().AddObject(TSimulationAnimal.Create(TVector2.Create(10 + Random(GameWidth - 20), 10 + Random(GameHeight - 20))));

  // wszystko ok
  AppLogger.Info('Aplikacja gotowa do działania!');
End;

(* Renderuje grę *)
Procedure OnDraw;
Begin
  batch2d_Begin();

  SimEngine.OnDraw();

  if (isPaused) Then
  Begin
    text_DrawEx(fntMain, GameWidth div 2, 70, 1, 0, '[ PAUZA ]', 255, Colors.FriendlyRed, TEXT_HALIGN_CENTER);
  End;

  pr2d_Circle(mouse_X(), mouse_Y(), 50, $FF0000);

  batch2d_End();
End;

(* Aktualizuje stan gry *)
Procedure OnUpdate;
Begin
  if (not isPaused) Then
    SimEngine.OnUpdate();
End;

(*	Obsługuje mysz oraz klawiaturę *)
Procedure OnInput;

  // Obsługa klawiatury
	Procedure ProcessKeyboard;
	Begin
	  // esc
	  if (key_Press(K_ESCAPE)) Then
	    zgl_Exit();

	  // spacja
	  if (key_Press(K_SPACE)) Then
	    isPaused := not isPaused;

    // f
    if (key_Press(K_F)) Then
      SimEngine.SwitchFastMode();

    // x
    if (key_Press(K_X)) Then
      SimulationAnimal.MagicTmp := not SimulationAnimal.MagicTmp;
	End;

  // Obsługa myszy
  Procedure ProcessMouse;
  Begin
    if (mouse_Click(M_BLEFT) or mouse_Down(M_BLEFT)) Then
    Begin
  //    SimEngine.GetBoard().CreateFood(mouse_X(), mouse_Y(), 50, bkLivingGreenFood);
    End;
  End;

Begin
  // obsłuż
  ProcessKeyboard();
  ProcessMouse();

  // wyczyść stany
  key_ClearState();
  mouse_ClearState();
End;

(* Wywoływane przy wychodzeniu z gry *)
Procedure OnQuit;
Begin
  AppLogger.Info('OnQuit()');
  SimEngine.Free();
  font_Del(fntMain);
End;

(*	Inicjuje grę *)
Procedure InitGame;
Begin
	zglLoad(libZenGL);

  timer_Add(@OnInput, 8);

  zgl_Reg(SYS_LOAD, @OnInit);
  zgl_Reg(SYS_DRAW, @OnDraw);
  zgl_Reg(SYS_UPDATE, @OnUpdate);
  zgl_Reg(SYS_EXIT, @OnQuit);

  wnd_SetCaption('Shorelack');
  wnd_ShowCursor(True);

  scr_SetOptions(GameWidth, GameHeight, REFRESH_MAXIMUM, False, True);

  zgl_Init();
End;

End.
