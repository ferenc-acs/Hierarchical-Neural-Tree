unit Inspektr;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  StdCtrls, ExtCtrls, Forms, TabNotBk, neuron, vecmat, ComCtrls;

type
  TListPtr = ^TList;

  TNeuroninspektor = class(TForm)
    TabbedNotebook1: TTabbedNotebook;
    AnzNeurone: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    AktNeuronBox: TEdit;
    GewListBox: TListBox;
    GewEdit: TEdit;
    DimEdit: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    procedure FormActivate(Sender: TObject);
    procedure GewListBoxEnter(Sender: TObject);
    procedure GewListBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure GewListBoxClick(Sender: TObject);
    procedure GewListBoxKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure GewEditExit(Sender: TObject);
    procedure AktNeuronBoxChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    private

    aktneuron : LongInt;
    aktwghtstr, aktdimstr : string;

    public

  end;

var
  Neuroninspektor: TNeuroninspektor;

implementation

{$R *.DFM}

procedure TNeuroninspektor.FormActivate(Sender: TObject);
begin
     AnzNeurone.Caption := inttostr(neurons.count);
end;

procedure TNeuroninspektor.GewListBoxEnter(Sender: TObject);
var
   neur,dim,c : Longint;
   str : String;
   wght : TWeight;
   failure : Boolean;
   p : TNeuron;
begin
     failure := FALSE;

     neur := aktneuron-1; {Auf die Listenindizes konvertieren}
     p := neurons.items[neur];
     if p.valid = VALID_ID then
        begin
             dim := p.Weight.getdim;
        end
     else
         failure := TRUE;

     if not(failure) then
     begin
          GewListBox.items.clear;
          for c := 1 to dim do
          begin
               str := inttostr(c) + ' : ';
               wght := p.weight.read(c);
               str := str + floattostrf(wght,ffGeneral,15,0);
               GewListBox.items.add(str);
          end;
     end;

end;


procedure TNeuroninspektor.GewListBoxKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
     GewListBoxClick(self);
end;

procedure TNeuroninspektor.GewListBoxClick(Sender: TObject);
var
   n : TNeuron;
begin
     n := neurons.items[aktneuron-1]; {-1 : Auf Listenindex konv.}

     aktwghtstr := floattostrf(n.weight.read(GewListBox.itemindex+1)
                   ,ffGeneral,15,0);
     aktdimstr := inttostr(GewListBox.itemindex+1);

     GewEdit.Text := aktwghtstr;
     DimEdit.Text := aktdimstr;
end;

procedure TNeuroninspektor.GewListBoxKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
     GewListBoxClick(self);
end;

procedure TNeuroninspektor.GewEditExit(Sender: TObject);
var
     n : TNeuron;
     w : TWeight;
begin
     n := neurons.items[aktneuron-1];
     w := strtofloat(GewEdit.Text);
     n.weight.write(gewlistbox.itemindex+1,w);
     GewListBoxEnter(self);
end;

procedure TNeuroninspektor.AktNeuronBoxChange(Sender: TObject);
begin
     if length(aktneuronbox.text) > 0 then
     begin
          try
               aktneuron := StrToInt(AktNeuronBox.Text);
          except
          on EConvertError do
             begin
                  AktNeuronBox.Text := '1';
                  aktneuron := 1;
             end;
          end;

          if aktneuron <= 0 then
          begin
               AktNeuronBox.Text := '1';
               aktneuron := 1;
          end;

          if aktneuron > neurons.count then
          begin
               AktNeuronBox.Text := IntToStr(neurons.count);
               aktneuron := neurons.count;
          end;

          GewListBoxEnter(self);
     end;
end;

procedure TNeuroninspektor.FormCreate(Sender: TObject);
begin
     {aktneuronbox.text:='1';}
end;

end.
