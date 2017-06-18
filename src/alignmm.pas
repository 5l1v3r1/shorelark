(*
  Menedżer pamięci umożliwiający alokowanie miejsca z wyrównaniem.
*)
{$mode objfpc}{$H+}
Unit AlignMM;

Interface

Uses
  Classes, SysUtils;

Function GetAlignedBlock(const Size: uint32; const Alignment: uint32 = 16): Pointer;
Procedure FreeAlignedBlock(const P: Pointer);

Implementation
Uses FGL;

// zaalokowany block
Type
  PAllocatedBlock = ^TAllocatedBlock;
  TAllocatedBlock =
  Record
    BasePnt, Pnt: Pointer;
  End;

Type TAllocatedBlockList = specialize TFPGList<PAllocatedBlock>;

// lista zaalokowanych bloczków
Var AllocatedBlocks: TAllocatedBlockList;

{ Dokonuje alokacji pamięci }
Function GetAlignedBlock(const Size: uint32; const Alignment: uint32 = 16): Pointer;
Var Block: PAllocatedBlock;
Begin
  New(Block);

  // zaalokuj i wyrównaj pamięć
  Block^.BasePnt := GetMem(Size + Alignment);
  Block^.Pnt := Align(Block^.BasePnt, Alignment);

  // dodaj bloczek do listy bloczków
  AllocatedBlocks.Add(Block);

  // zwróć przydzielony blok pamięci
  Result := Block^.Pnt;
End;

{ Zwalnia zaalokowany blok pamięci }
Procedure FreeAlignedBlock(const P: Pointer);
Var I: Integer;
Begin
  For I := 0 To AllocatedBlocks.Count-1 Do
  Begin
    if (AllocatedBlocks[I]^.Pnt = P) Then
    Begin
      FreeMem(AllocatedBlocks[I]^.BasePnt);
      AllocatedBlocks.Delete(I);
      Exit;
    End;
  End;

  raise Exception.CreateFmt('Bloczek pamięci o adresie %x nie został odnaleziony!', [P]);
End;

initialization
  AllocatedBlocks := TAllocatedBlockList.Create();

finalization
  AllocatedBlocks.Free();

End.
