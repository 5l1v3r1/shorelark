(*
  Shorelark - symulator życia i ewolucji
  (C) 2015 Patryk Wychowaniec
*)
{$apptype console}
Program Shorelark;
Uses
  Windows, SysUtils,
  Logger, Engine;
Begin
  DefaultFormatSettings.DecimalSeparator := '.';
  SetConsoleOutputCP(CP_UTF8);

  Try
    Randomize();
    Engine.InitGame();
	Except
    On E: Exception Do
    Begin
      Logger.ReportException(E);
      Readln;
      Halt;
    End;
  End;

  Writeln('-- done --');
  Readln;
End.

