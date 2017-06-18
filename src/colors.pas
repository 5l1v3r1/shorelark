{$mode objfpc}{$H+}
Unit Colors;

Interface

Type
  PColor = ^TColor;
  TColor = uint32;
  TColorArray = Array of TColor;

{ Lista kolorów }
Const
  White = $ffffff;
  Red = $ff0000;
  FriendlyRed = $ff0033;

{ Klasa opakowująca szybki gradient (wykorzystuje tablicę lookupową) }
Type TFastGradient =
  Class
    Private
      fLookup: PColor;

    Public
      Constructor Create(const StartColor, EndColor: TColor; const EndValue: Integer = 100);
      Destructor Destroy; override;

      Function GetForValue(const Value: Integer): TColor;
      Function GetLookupTable: PColor;
    End;

Procedure GetColorComponents(const C: TColor; out R, G, B: uint8);
Function CreateColor(const R, G, B: uint8): TColor;
Function BlurColors(const C1, C2, C3: TColor): TColor;

Procedure RGBtoLab(const cR, cG, cB: uint8; out L, A, B: Double);
Procedure RGBtoLab(const Color: TColor; out L, A, B: Double);
Procedure RGBtoXYZ(const cR, cG, cB: uint8; out X, Y, Z: Double);
Procedure XYZtoLab(const cX, cY, cZ: Double; out L, A, B: Double);

Implementation
Uses AlignMM, Math;

// ----- TFastGradient ----- //

(* Konstruktor *)
Constructor TFastGradient.Create(const StartColor, EndColor: TColor; const EndValue: Integer = 100);
Var StartR, StartG, StartB, EndR, EndG, EndB: uint8;
    Value: Integer;
Begin
  EndR := EndColor;
  EndG := (EndColor >> 8);
  EndB := (EndColor >> 16);

  // zaalokuj tablicę
  fLookup := GetAlignedBlock(sizeof(TColor) * (EndValue + 1));

  // policz dla każdego wskaźnika
  For Value := 0 To EndValue Do
  Begin
	  StartR := StartColor;
	  StartG := (StartColor >> 8);
	  StartB := (StartColor >> 16);

	  StartR += Round((EndR - StartR) / EndValue * Value);
	  StartG += Round((EndG - StartG) / EndValue * Value);
	  StartB += Round((EndB - StartB) / EndValue * Value);

	  fLookup[Value] := (StartR << 16) + (StartG << 8) + StartB;
  End;
End;

(* Destruktor *)
Destructor TFastGradient.Destroy;
Begin
  FreeAlignedBlock(fLookup);
End;

(* Zwraca wartość gradientu dla danego wskaźnika *)
Function TFastGradient.GetForValue(const Value: Integer): TColor;
Begin
  Result := fLookup[Value];
End;

(* Zwraca tablicę lookupową gradientu *)
Function TFastGradient.GetLookupTable: PColor;
Begin
  Result := fLookup;
End;

// ---------- //

(* Wydziela komponenty koloru *)
Procedure GetColorComponents(const C: TColor; out R, G, B: uint8);
Begin
  R := C;
  G := (C >> 8);
  B := (C >> 16);
End;

(* Tworzy kolor z komponentów *)
Function CreateColor(const R, G, B: uint8): TColor;
Begin
  Result := (R << 16) + (G << 8) + B;
End;

(* Dokonuje zmieszania (blur) trzech kolorów *)
Function BlurColors(const C1, C2, C3: TColor): TColor;
Var R: Array[0..2] of uint8;
    G: Array[0..2] of uint8;
    B: Array[0..2] of uint8;
Begin
  GetColorComponents(C1, R[0], G[0], B[0]);
  GetColorComponents(C2, R[1], G[1], B[1]);
  GetColorComponents(C3, R[2], G[2], B[2]);

  Result := CreateColor
    (
      (R[0] + R[1] + R[2]) div 3,
      (G[0] + G[1] + G[2]) div 3,
      (B[0] + B[1] + B[2]) div 3
    );
End;

(* Zamienia kolor z przestrzeni RGB na Lab *)
Procedure RGBtoLab(const cR, cG, cB: uint8; out L, A, B: Double);
Var X, Y, Z: Double;
Begin
  RGBtoXYZ(cR, cG, cB, X, Y, Z);
  XYZtoLab(X, Y, Z, L, A, B);
End;

(* Zamienia kolor z przestrzeni RGB na Lab *)
Procedure RGBtoLab(const Color: TColor; out L, A, B: Double);
Var cR, cG, cB: uint8;
Begin
  GetColorComponents(Color, cR, cG, cB);
  RGBtoLAB(cR, cG, cB, L, A, B);
End;

(* Zamienia kolor z przestrzeni RGB na XYZ *)
Procedure RGBtoXYZ(const cR, cG, cB: uint8; out X, Y, Z: Double);

  Procedure Adjust(var Value: Double);
  Begin
   if (Value > 0.04045) Then
   Begin
    Value := (Value + 0.055) / 1.055;
    Value := Power(Value, 2.4);
   End Else
   Begin
    Value := Value / 12.92;
   End;
  End;

Var R, G, B: Double;
Begin
 R := cR / 255;
 G := cG / 255;
 B := cB / 255;

 Adjust(R);
 Adjust(G);
 Adjust(B);

 R *= 100;
 G *= 100;
 B *= 100;

 X := R*0.4124 + G*0.3576 + B*0.1805;
 Y := R*0.2126 + G*0.7152 + B*0.0722;
 Z := R*0.0193 + G*0.1192 + B*0.9505;
End;

(* Zamienia kolor z przestrzeni XYZ na Lab *)
Procedure XYZtoLab(const cX, cY, cZ: Double; out L, A, B: Double);

  Procedure Adjust(var Value: Double);
  Begin
   if (Value > 0.008856) Then
   Begin
    Value := Power(Value, 1/3);
   End Else
   Begin
    Value := 7.787*Value + 16/116;
   End;
  End;

Var X, Y, Z: Double;
Begin
 X := cX / 95.047;
 Y := cY / 100;
 Z := cZ / 108.883;

 Adjust(X);
 Adjust(Y);
 Adjust(Z);

 L := 116*Y - 16;
 A := 500*(X-Y);
 B := 200*(Y-Z);
End;
End.
