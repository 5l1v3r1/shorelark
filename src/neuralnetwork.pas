(*
  Implementacja na podstawie: http://inkdrop.net/dave/docs/neural-net-tutorial-W.cpp
*)
{$mode objfpc}{$H+}
Unit NeuralNetwork;

Interface

Uses
  Classes, SysUtils, FGL,
  Logger;

Type ENeuralNetworkException = Class(Exception);
Type TNeuronWeights = Array of Double;
Type TNeuronLayer = class;

{ Klasa reprezentująca pojedynczy neuron }
Type TNeuron =
  Class
    Private
      fMyIndex: Integer;
      fWeights, fWeightsDelta: TNeuronWeights;

      fEta, fAlpha: Double;
      fGradient: Double;

      fOutputValue: Double;

      Function TransferFunction(const X: Double): Double;
      Function TransferFunctionDerivative(const X: Double): Double;

      Function SumGradients(const Layer: TNeuronLayer): Double;

    Public
      Constructor Create(const OutputCount, MyIndex: Integer);

      Procedure FeedForward(const Layer: TNeuronLayer);
      Procedure UpdateInputWeights(const Layer: TNeuronLayer);
      Procedure CalculateOutputGradients(const TargetValue: Double);
      Procedure CalculateHiddenGradients(const Layer: TNeuronLayer);
    End;

Type TNeuronArray = Array of TNeuron;

{ Klasa reprezentująca warstwę neuronów }
Type TNeuronLayer =
  Class
    Private
      fNeuronCount: Integer;
      fNeurons: TNeuronArray;

    Public
      Constructor Create(const NeuronCount, OutputCount: Integer);
    End;

Type TNeuronLayerArray = Array of TNeuronLayer;

{ Klasa reprezentująca całą sieć neuronową }
Type TNeuralNetwork =
  Class
    Private
      fLayers: TNeuronLayerArray;

    Public
      Constructor Create(const LayerTopology: Array of Integer);

      Function Propagate(const Data: TNeuronWeights): TNeuronWeights;

		  Procedure FeedForward(const Data: TNeuronWeights);
      Procedure BackPropagate(const TargetData: TNeuronWeights);
      Procedure DumpWeights(const FileName: String);
      Procedure LoadWeights(const FileName: String);

      Procedure SetTotalWeights(const Weights: TNeuronWeights);

      Function GetResults: TNeuronWeights;
      Function GetTotalWeightCount: Integer;
      Function GetTotalWeights: TNeuronWeights;
    End;

Implementation
Uses Math;

// ----- TNeuron ----- //
(* Funkcja aktywacji *)
Function TNeuron.TransferFunction(const X: Double): Double;
Begin
  Result := tanh(x); // 1 / ( 1 + exp(-X / 1));
End;

(* Pochodna funkcji aktywacji *)
Function TNeuron.TransferFunctionDerivative(const X: Double): Double;
Begin
  Result := 1.0 - X*X;
End;

(* Sumuje gradienty *)
Function TNeuron.SumGradients(const Layer: TNeuronLayer): Double;
Var I: Integer;
Begin
  Result := 0.0;

  For I := 0 To Layer.fNeuronCount-2 Do
    Result += fWeights[I] * Layer.fNeurons[I].fGradient;
End;

(* Tworzy nowy neuron z losowymi wagami *)
Constructor TNeuron.Create(const OutputCount, MyIndex: Integer);
Var I, S: Integer;
Begin
  fMyIndex := MyIndex;

  fEta := 0.15;
  fAlpha := 0.5;
  fGradient := 0;

  SetLength(fWeights, OutputCount);
  SetLength(fWeightsDelta, OutputCount);

  For I := 0 To OutputCount-1 Do
  Begin
    if (Random() < 0.5) Then
      S := -1 Else
      S := 1;

    fWeights[I] := Random() * S;
    fWeightsDelta[I] := 0;
  End;
End;

(* Przekazuje dane do neurona i zwraca jego odpowiedź *)
Procedure TNeuron.FeedForward(const Layer: TNeuronLayer);
Var I: Integer;
    Sum: Double = 0.0;
Begin
  For I := 0 To Layer.fNeuronCount-1 Do
    Sum += Layer.fNeurons[I].fOutputValue * Layer.fNeurons[I].fWeights[fMyIndex];

  fOutputValue := self.TransferFunction(Sum);
End;

(* Aktualizuje wagi wejściowe, część metody backpropagation *)
Procedure TNeuron.UpdateInputWeights(const Layer: TNeuronLayer);
Var I: Integer;
    Neuron: TNeuron;
    OldDelta, NewDelta: Double;
Begin
  For I := 0 To Layer.fNeuronCount-1 Do
  Begin
    Neuron := Layer.fNeurons[I];

    OldDelta := Neuron.fWeightsDelta[fMyIndex];
    NewDelta := fEta * Neuron.fOutputValue * fGradient + fAlpha * OldDelta;

    Neuron.fWeights[fMyIndex] += NewDelta;
    Neuron.fWeightsDelta[fMyIndex] := NewDelta;
  End;
End;

(* Oblicza wyjściowe gradienty, część metody backpropagation *)
Procedure TNeuron.CalculateOutputGradients(const TargetValue: Double);
Var Delta: Double;
Begin
  Delta := TargetValue - fOutputValue;
  fGradient := Delta * self.TransferFunctionDerivative(fOutputValue);
End;

(* Oblicza wyjściowe gradienty dla warstwy ukrytej, część metody backpropagation *)
Procedure TNeuron.CalculateHiddenGradients(const Layer: TNeuronLayer);
Var dow: Double;
Begin
  dow := self.SumGradients(Layer);
  fGradient := dow * self.TransferFunctionDerivative(fOutputValue);
End;

// ----- TNeuronLayer ----- //
(* Konstruktor *)
Constructor TNeuronLayer.Create(const NeuronCount, OutputCount: Integer);
Var I: Integer;
Begin
  // utwórz dodatkowy neuron służący jako bias
  fNeuronCount := NeuronCount + 1;
  SetLength(fNeurons, fNeuronCount);

  For I := 0 To High(fNeurons) Do
    fNeurons[I] := TNeuron.Create(OutputCount, I);

	// neuron biasowy
  fNeurons[High(fNeurons)].fOutputValue := 1.0;
End;

// ----- TNeuralNetwork ----- //
(* Konstruktor *)
Constructor TNeuralNetwork.Create(const LayerTopology: Array of Integer);
Var I, OutputCount: Integer;
Begin
  // jeśli sprecyzowano za mało warstw, rzuć wyjątek
  if (Length(LayerTopology) < 2) Then
    raise ENeuralNetworkException.CreateFmt('Sprecyzowano zbyt mało warstw neuronów (%d)!', [Length(LayerTopology)]);

  // utwórz warstwy
  SetLength(fLayers, Length(LayerTopology));

  For I := 0 To High(fLayers) Do
  Begin
    if (I = High(fLayers)) Then
      OutputCount := 0 Else
      OutputCount := LayerTopology[I+1];

    fLayers[I] := TNeuronLayer.Create(LayerTopology[I], OutputCount);
  End;
End;

(* Wprowadza dane do sieci, propaguje je i zwraca wyniki *)
Function TNeuralNetwork.Propagate(const Data: TNeuronWeights): TNeuronWeights;
Begin
  self.FeedForward(Data);
  Result := self.GetResults();
End;

(* Wykonuje feed forward na sieci *)
Procedure TNeuralNetwork.FeedForward(const Data: TNeuronWeights);
Var I, J: Integer;
    PrevLayer: TNeuronLayer;
Begin
  // sprawdź czy rozmiary danych są poprawne
  if (Length(Data) <> fLayers[0].fNeuronCount-1) Then
    raise ENeuralNetworkException.CreateFmt('Nie można wykonać feed forward, nieprawidłowy rozmiar paczki danych (oczekiwano %d, otrzymano %d)!', [fLayers[0].fNeuronCount-1, Length(Data)]);

  // ustaw dane dla warstwy wejściowej
  For I := 0 To High(Data) Do
    fLayers[0].fNeurons[I].fOutputValue := Data[I];

	// dokonaj propagacji
  For I := 1 To High(fLayers) Do
  Begin
    PrevLayer := fLayers[I-1];

    For J := 0 To fLayers[I].fNeuronCount-2 Do
      fLayers[I].fNeurons[J].FeedForward(PrevLayer);
  End;
End;

(* Wykonuje propagację wsteczną na całej sieci *)
Procedure TNeuralNetwork.BackPropagate(const TargetData: TNeuronWeights);
Var LastLayer, PrevLayer, NextLayer, Layer: TNeuronLayer;
    Error, Delta: Double;
    I, J: Integer;
Begin
  LastLayer := fLayers[High(fLayers)];

  // policz błąd wyjściowy
  Error := 0;

  For I := 0 To LastLayer.fNeuronCount-2 Do
  Begin
    Delta := TargetData[I] - LastLayer.fNeurons[I].fOutputValue;
    Error += Delta * Delta;
  End;

  Error /= LastLayer.fNeuronCount - 1;
  Error := sqrt(Error);

  // przelicz gradienty dla warstwy wyjściowej
  For I := 0 To LastLayer.fNeuronCount-2 Do
    LastLayer.fNeurons[I].CalculateOutputGradients(TargetData[I]);

  // przelicz gradienty dla warstw ukrytych
  For I := High(fLayers) - 1 Downto 1 Do
  Begin
    Layer := fLayers[I];
    NextLayer := fLayers[I+1];

    For J := 0 To Layer.fNeuronCount-1 Do
      Layer.fNeurons[J].CalculateHiddenGradients(NextLayer);
  End;

  // zaktualizuj wagi dla wszystkich warstw, poza wejściową
  For I := High(fLayers) Downto 1 Do
  Begin
    Layer := fLayers[I];
    PrevLayer := fLayers[I-1];

    For J := 0 To Layer.fNeuronCount-2 Do
      Layer.fNeurons[J].UpdateInputWeights(PrevLayer);
  End;
End;

Procedure TNeuralNetwork.DumpWeights(const FileName: String);
Var I, J, K: Integer;
    F: TextFile;
Begin
  AssignFile(F, FileName);
  Rewrite(F);

  For I := 0 To High(fLayers) Do
  Begin
    For J := 0 To High(fLayers[I].fNeurons) Do
    Begin
      For K := 0 To High(fLayers[I].fNeurons[J].fWeights) Do
      Begin
        Writeln(F, I);
        Writeln(F, J);
        Writeln(F, K);
        Writeln(F, fLayers[I].fNeurons[J].fWeights[K]);
      End;
    End;
  End;

  Flush(F);
  CloseFile(F);
End;

Procedure TNeuralNetwork.LoadWeights(const FileName: String);
Var I, J, K: Integer;
    F: TextFile;
Begin
  AssignFile(F, FileName);
  Reset(F);

  While (not Eof(F)) Do
  Begin
    Readln(F, I);
    Readln(F, J);
    Readln(F, K);
    Readln(F, fLayers[I].fNeurons[J].fWeights[K]);
  End;

  CloseFile(F);
End;

(* Zmienia wszystkie wagi w całej sieci *)
Procedure TNeuralNetwork.SetTotalWeights(const Weights: TNeuronWeights);
Var LayerId, NeuronId, WeightId, Id: Integer;
Begin
  Id := 0;

  For LayerId := 0 To High(fLayers) Do
  Begin
    For NeuronId := 0 To High(fLayers[LayerId].fNeurons)-1 Do
    Begin
      For WeightId := 0 To High(fLayers[LayerId].fNeurons[NeuronId].fWeights) Do
      Begin
        fLayers[LayerId].fNeurons[NeuronId].fWeights[WeightId] := Weights[Id];
        Inc(Id);
      End;
    End;
  End;
End;

(* Zwraca wynik działania sieci *)
Function TNeuralNetwork.GetResults: TNeuronWeights;
Var Layer: TNeuronLayer;
    I: Integer;
Begin
  Layer := fLayers[High(fLayers)];

  SetLength(Result, Layer.fNeuronCount-1);

  For I := 0 To Layer.fNeuronCount-2 Do
    Result[I] := Layer.fNeurons[I].fOutputValue;
End;

(* Zwraca łączną liczbę wag w całej sieci *)
Function TNeuralNetwork.GetTotalWeightCount: Integer;
Var LayerId, NeuronId: Integer;
Begin
  Result := 0;

  For LayerId := 0 To High(fLayers) Do
  Begin
    For NeuronId := 0 To High(fLayers[LayerId].fNeurons)-1 Do
      Result += Length(fLayers[LayerId].fNeurons[NeuronId].fWeights);
  End;
End;

(* Zwraca wszystkie wagi z sieci *)
Function TNeuralNetwork.GetTotalWeights: TNeuronWeights;
Var LayerId, NeuronId, WeightId, ResultId: Integer;
Begin
  SetLength(Result, self.GetTotalWeightCount());
  ResultId := 0;

  For LayerId := 0 To High(fLayers) Do
  Begin
    For NeuronId := 0 To High(fLayers[LayerId].fNeurons)-1 Do
    Begin
      For WeightId := 0 To High(fLayers[LayerId].fNeurons[NeuronId].fWeights) Do
      Begin
        Result[ResultId] := fLayers[LayerId].fNeurons[NeuronId].fWeights[WeightId];
        Inc(ResultId);
      End;
    End;
  End;
End;

End.
