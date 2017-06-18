{$mode objfpc}{$H+}
Unit Logger;

Interface

Uses
  Classes, SysUtils;

{ Klasa odpowiedzialna za zarządzanie logiem }
Type TLogger =
  Class
    Private
      fMessageClass: String;

      Procedure WriteMessage(const Kind, Msg: String);

    Public
      Constructor Create(const MessageClass: String);
      Destructor Destroy; override;

      Procedure Info(const Msg: String);
      Procedure Info(const Fmt: String; const Args: Array of Const);

      Procedure Warn(const Msg: String);
      Procedure Warn(const Fmt: String; const Args: Array of Const);

      Procedure Fatal(const Msg: String);
      Procedure Fatal(const Fmt: String; const Args: Array of Const);
    End;

Procedure ReportException(const E: Exception);

// główny log
Var AppLogger: TLogger;

Implementation
Uses zglHeader;

(* Wpisuje wyjątek do głównego logu *)
Procedure ReportException(const E: Exception);
var Frames: PPointer;
    I: Integer;
Begin
  AppLogger.Fatal('!!! WYJĄTEK !!!');

  if (E <> nil) Then
  Begin
    AppLogger.Fatal('Klasa wyjątku: %s', [E.ClassName]);
    AppLogger.Fatal('Wiadomość: %s', [E.Message]);
  End;

  AppLogger.Fatal('Stos wywołań:');
  AppLogger.Fatal('[0] %s', [BacktraceStrFunc(ExceptAddr)]);

  Frames := ExceptFrames;
  For I := 0 To ExceptFrameCount - 1 Do
    AppLogger.Fatal('[%d] %s', [I+1, BacktraceStrFunc(Frames[I])]);

  AppLogger.Fatal('------------------');
  AppLogger.Fatal('Aplikacja zostanie zamknięta.');
End;

// ----- TLogger ----- //

(* Zapisuje wiadomość do logu *)
Procedure TLogger.WriteMessage(const Kind, Msg: String);
Var Message: String;
Begin
  Message := Format('%s %s [%s] <%s> %s', [DateToStr(Now), TimeToStr(Time), fMessageClass, Kind, Msg]);

  Writeln(Message);

  if (log_Add <> nil) Then
    log_Add(Message);
End;

(* Konstruktor *)
Constructor TLogger.Create(const MessageClass: String);
Begin
  fMessageClass := MessageClass;
End;

(* Destruktor *)
Destructor TLogger.Destroy;
Begin
  self.Info('Zamykanie loggera...');
End;

(* Wyświetla informację *)
Procedure TLogger.Info(const Msg: String);
Begin
  self.WriteMessage('info', Msg);
End;

(* Wyświetla informację *)
Procedure TLogger.Info(const Fmt: String; const Args: Array of Const);
Begin
  self.Info(Format(Fmt, Args));
End;

(* Wyświetla ostrzeżenie *)
Procedure TLogger.Warn(const Msg: String);
Begin
  self.WriteMessage('warn', Msg);
End;

(* Wyświetla ostrzeżenie *)
Procedure TLogger.Warn(const Fmt: String; const Args: Array of Const);
Begin
  self.Warn(Format(Fmt, Args));
End;

(* Wyświetla fatalny błąd *)
Procedure TLogger.Fatal(const Msg: String);
Begin
  self.WriteMessage('fatal', Msg);
End;

(* Wyświetla fatalny błąd *)
Procedure TLogger.Fatal(const Fmt: String; const Args: Array of Const);
Begin
  self.Fatal(Format(Fmt, Args));
End;

initialization
  AppLogger := TLogger.Create('app');

End.
