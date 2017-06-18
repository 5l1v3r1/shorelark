(*
  Implementacja na podstawie http://www.ai-junkie.com/ann/evolved/nnt1.html
*)
{$mode objfpc}{$H+}
Unit NeuralNetwork;

Interface

Uses
  Classes, SysUtils, FGL,
  Logger;

Type ENeuralNetworkException = Class(Exception);

Type TDoubleList = specialize TFPGList<Double>;
Type TNeuronWeights = Array of Double;

{ Klasa reprezentująca pojedynczy neuron }
Type TNeuron =
  Class
    Private
      // liczba wejść neuronu
      fInputCount: Integer;

      // wagi wejść plus współczynnik
      fWeights: TNeuronWeights;

    Public
      Constructor Create(const InputCount: Integer);
    End;

{ Klasa reprezentująca warstwę neuronów }
Type TNeuronLayer =
  Class
    Private
      fNeuronCount: Integer;
      fNeurons: Array of TNeuron;

    Public
      Constructor Create(const NeuronCount, InputsPerNeuron: Integer);
    End;

{ Klasa reprezentująca całą sieć neuronową }
Type TNeuralNetwork =
  Class
    Private
      fLogger: TLogger;

      fBias: Double;
      fActivationResponse: Double;

      fInputCount: Integer;
      fOutputCount: Integer;
      fHiddenLayerCount: Integer;
      fNeuronsPerHiddenLayer: Integer;

      fLayers: Array of TNeuronLayer;

      Function TransferFunction(const Value: Double): Double;

    Public
      Constructor Create;

      Procedure BuildNetwork;
      Procedure LoadWeightsFromFile(const FileName: String);

      Function Propagate(const InputData: TNeuronWeights): TNeuronWeights;

			Procedure SetInputCount(const Value: Integer);
      Procedure SetOutputCount(const Value: Integer);
      Procedure SetHiddenLayerCount(const Value: Integer);
      Procedure SetNeuronsPerHiddenLayer(const Value: Integer);
      Procedure SetTotalWeights(const Weights: TNeuronWeights);

      Function GetTopology: String;
      Function GetTotalWeights: TNeuronWeights;
      Function GetTotalWeightCount: Integer;
    End;

Implementation

// ----- TNeuron ----- //

(* Konstruktor *)
Constructor TNeuron.Create(const InputCount: Integer);
Var I: Integer;
Begin
  // sprawdź czy liczba wejść jest poprawna
  if (InputCount <= 0) Then
    raise ENeuralNetworkException.CreateFmt('Nieprawidłowa liczba wejść neuronu: %d', [InputCount]);

  // przygotuj pola
  fInputCount := InputCount+1;
  SetLength(fWeights, fInputCount);

  // wypełnij wagi losowymi wartościami
  For I := 0 To High(fWeights) Do
    fWeights[I] := Random() - Random();
End;

// ----- TNeuronLayer ----- //

(* Konstruktor *)
Constructor TNeuronLayer.Create(const NeuronCount, InputsPerNeuron: Integer);
Var I: Integer;
Begin
  // sprawdź czy liczba neuronów jest poprawna
  if (NeuronCount <= 0) Then
    raise ENeuralNetworkException.CreateFmt('Nieprawidłowa liczba neuronów w warstwie: %d', [NeuronCount]);

  // przygotuj pola
  fNeuronCount := NeuronCount;
  SetLength(fNeurons, NeuronCount);

  // utwórz losowe neurony
  For I := 0 To High(fNeurons) Do
    fNeurons[I] := TNeuron.Create(InputsPerNeuron);
End;

// ----- TNeuralNetwork ----- //

(* Funkcja aktywująca *)
Function TNeuralNetwork.TransferFunction(const Value: Double): Double;
Begin
  Result := 1 / ( 1 + exp(-Value / fActivationResponse));
End;

(* Konstruktor *)
Constructor TNeuralNetwork.Create;
Begin
  fLogger := TLogger.Create('NeuralNet');

  fBias := -1;
  fActivationResponse := 1;
End;

(* Buduje sieć *)
Procedure TNeuralNetwork.BuildNetwork;
Var I: Integer;
Begin
  fLogger.Info('Budowanie sieci neuronowej o topologii %s', [self.GetTopology()]);

  if (fHiddenLayerCount > 0) Then
  Begin
    // jeśli mamy jakieś warstwy ukryte
    SetLength(fLayers, 1 + fHiddenLayerCount);

    // pierwsza ukryta warstwa
    fLayers[0] := TNeuronLayer.Create(fNeuronsPerHiddenLayer, fInputCount);

    // reszta warstw ukrytych
    For I := 1 To fHiddenLayerCount-1 Do
      fLayers[I] := TNeuronLayer.Create(fNeuronsPerHiddenLayer, fNeuronsPerHiddenLayer);

    // warstwa wynikowa
    fLayers[High(fLayers)] := TNeuronLayer.Create(fOutputCount, fNeuronsPerHiddenLayer);
  End Else
  Begin
    // jeśli nie mamy żadnych warstw ukrytych
    SetLength(fLayers, 1);

    fLayers[0] := TNeuronLayer.Create(fOutputCount, fInputCount);
  End;
End;

(* Wczytuje sieć z podanego pliku *)
Procedure TNeuralNetwork.LoadWeightsFromFile(const FileName: String);
Var LayerId, NeuronId, WeightId: Integer;
    Tmp: Double;
    F: TextFile;
Begin
  AssignFile(F, FileName);
  Reset(F);

  While (not EOF(F)) Do
  Begin
    Readln(F, LayerId);
    Readln(F, NeuronId);
    Readln(F, WeightId);

    if (LayerId > High(fLayers)) Then
      raise Exception.CreateFmt('Nieprawidłowe id warstwy: %d > %d', [LayerId, High(fLayers)]);

    if (NeuronId > High(fLayers[LayerId].fNeurons)) Then
      raise Exception.CreateFmt('Nieprawidłowe id neuronu: %d > %d (warstwa %d)', [NeuronId, High(fLayers[LayerId].fNeurons), LayerId]);

    if (WeightId > High(fLayers[LayerId].fNeurons[NeuronId].fWeights)) Then
    Begin
//      raise Exception.CreateFmt('Nieprawidłowe id wagi: %d > %d', [WeightId, High(fLayers[LayerId].fNeurons[NeuronId].fWeights)]);
      Readln(F, Tmp);
      Continue;
End;

    Readln(F, fLayers[LayerId].fNeurons[NeuronId].fWeights[WeightId]);
  End;

  CloseFile(F);
End;

(* Propaguje dane przez sieć *)
Function TNeuralNetwork.Propagate(const InputData: TNeuronWeights): TNeuronWeights;
Var LayerId, NeuronId, WeightId: Integer;

    CurrentLayer: TNeuronLayer;
    CurrentNeuron: TNeuron;

    Inputs: TNeuronWeights;

    NetInput: Double;
    WeightCount: Integer;
Begin
  // upewnij się, że mamy dokładną liczbę danych wejściowych
  if (Length(InputData) <> fInputCount) Then
    raise Exception.CreateFmt('Nie można dokonać propagacji danych przez sieć neuronową - niezgodna liczba danych wejściowych (otrzymano %d, oczekiwano %d)', [Length(InputData), fInputCount]);

	SetLength(Result, 0);
  Inputs := InputData;

  // dla każdej warstwy
  For LayerId := 0 To High(fLayers) Do
  Begin
    if (LayerId > 0) Then
      Inputs := Result;

    CurrentLayer := fLayers[LayerId];

		SetLength(Result, 0);

    // dla każdego neuronu w tej warstwie
    For NeuronId := 0 To CurrentLayer.fNeuronCount-1 Do
    Begin
      CurrentNeuron := CurrentLayer.fNeurons[NeuronId];

      NetInput := 0.0;
      WeightCount := CurrentNeuron.fInputCount;

      // dla każdej wagi wejściowej, oprócz biasu
      For WeightId := 0 To WeightCount-2 Do
        NetInput += CurrentNeuron.fWeights[WeightId] * Inputs[WeightId];

      // dodaj bias
      NetInput += CurrentNeuron.fWeights[WeightCount-1] * fBias;

      // zapisz wynik
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := self.TransferFunction(NetInput);
    End;
  End;
End;

(* Ustawia liczbę wejść sieci *)
Procedure TNeuralNetwork.SetInputCount(const Value: Integer);
Begin
  fInputCount := Value;
End;

(* Ustawia liczbę wyjść sieci *)
Procedure TNeuralNetwork.SetOutputCount(const Value: Integer);
Begin
  fOutputCount := Value;
End;

(* Ustawia liczbę warstw ukrytych *)
Procedure TNeuralNetwork.SetHiddenLayerCount(const Value: Integer);
Begin
  fHiddenLayerCount := Value;
End;

(* Ustawia liczbę neuronów przypadającą na każdą ukrytą warstwę *)
Procedure TNeuralNetwork.SetNeuronsPerHiddenLayer(const Value: Integer);
Begin
  fNeuronsPerHiddenLayer := Value;
End;

(* Ustawia wagi w całej sieci *)
Procedure TNeuralNetwork.SetTotalWeights(const Weights: TNeuronWeights);
Var I, J, K, WeightId: Integer;
Begin
	WeightId := 0;

  For I := 0 To High(fLayers) Do
  Begin
    For J := 0 To fLayers[I].fNeuronCount-1 Do
    Begin
      For K := 0 To fLayers[I].fNeurons[J].fInputCount-1 Do
      Begin
        fLayers[I].fNeurons[J].fWeights[K] := Weights[WeightId];
        Inc(WeightId);
      End;
    End;
  End;
End;

(* Zwraca topologię sieci *)
Function TNeuralNetwork.GetTopology: String;
Var I: Integer;
Begin
  Result := Format('[%d', [fInputCount]);

  For I := 1 To fHiddenLayerCount Do
    Result += Format(', %d', [fNeuronsPerHiddenLayer]);

  Result += Format(', %d]', [fOutputCount]);
End;

(* Zwraca wagi w całej sieci *)
Function TNeuralNetwork.GetTotalWeights: TNeuronWeights;
Var I, J, K, Id: Integer;
Begin
  SetLength(Result, self.GetTotalWeightCount());

  Id := 0;

  For I := 0 To High(fLayers) Do
  Begin
    For J := 0 To fLayers[I].fNeuronCount-1 Do
    Begin
      For K := 0 To fLayers[I].fNeurons[J].fInputCount-1 Do
      Begin
        Result[Id] := fLayers[I].fNeurons[J].fWeights[K];
        Inc(Id);
      End;
    End;
  End;
End;

(* Zwraca liczbę wag w całej sieci *)
Function TNeuralNetwork.GetTotalWeightCount: Integer;
Var I, J: Integer;
Begin
  Result := 0;

  For I := 0 To High(fLayers) Do
  Begin
    For J := 0 To fLayers[I].fNeuronCount-1 Do
      Result += fLayers[I].fNeurons[J].fInputCount;
  End;
End;

End.
