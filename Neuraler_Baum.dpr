program Neuraler_Baum;

uses
  Forms,
  Main in 'Main.pas' {Form1},
  Graph in 'graph.pas' {Diagramm},
  neuron in 'neuron.pas',
  Neuron_e in 'neuron_e.pas',
  Inspektr in 'inspektr.pas' {Neuroninspektor},
  Param in 'param.pas' {ParamForm},
  Datau in 'datau.pas' {data},
  Trainer in 'trainer.pas' {Train},
  vecmat in 'vecmat.pas',
  polaru in 'polaru.pas',
  FileM in 'FileM.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Neural Tree';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TDiagramm, Diagramm);
  Application.CreateForm(TNeuroninspektor, Neuroninspektor);
  Application.CreateForm(TParamForm, ParamForm);
  Application.CreateForm(Tdata, data);
  Application.CreateForm(TTrain, Train);
  Application.Run;
end.
