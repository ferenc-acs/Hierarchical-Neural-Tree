unit Main;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, Menus, graph, neuron, Printers, Inspektr,param, trainer,
  DB, DBTables, FileM;

const
     NUMNEURONS = 20;
     NETZDEFAULTEXT = 'net';
     NEURONSDEFAULTEXT = 'neu';


type
  TForm1 = class(TForm)
    PrintDialog: TPrintDialog;
    MainMenu1: TMainMenu;
    Drucken1: TMenuItem;
    Diagramm_Drucken1: TMenuItem;
    DiskDatenSource: TDataSource;
    DiskDaten: TTable;
    Datei1: TMenuItem;
    NetzLaden1: TMenuItem;
    NetzSpeichern1: TMenuItem;
    NetzLadenDialog: TOpenDialog;
    NetzSpeichernDialog: TSaveDialog;
    Hilfe1: TMenuItem;
    Copyright1: TMenuItem;
    procedure Diagramm_Drucken1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NetzSpeichern1Click(Sender: TObject);
    procedure Copyright1Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

uses vecmat;
{$R *.DFM}

procedure TForm1.Diagramm_Drucken1Click(Sender: TObject);
var
   a,b : LongInt;
begin
     if PrintDialog.execute then
     begin
          Printer.BeginDoc;
          a :=  diagramm.PBwidth;
          b :=  diagramm.PBheight;
          diagramm.PBwidth := Printer.PageWidth;
          diagramm.PBheight := Printer.Pageheight;
          diagramm.draw_diagramm(Printer.Canvas);
          Printer.EndDoc;
          diagramm.PBwidth := a;
          diagramm.PBheight := b;
     end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
   i : LongInt;
   p,p2 : TNeuron;
   z : TNeuronPtr;


begin
     neurons := TList.create;
     neurons.clear;
     randomize; {Zufallszahlengenerator initialisieren}
end;

procedure TForm1.FormDestroy(Sender: TObject);
var
   p : TNeuron;
begin

     while neurons.count > 0 do
     begin
          p := neurons.items[0]; {Erstes Element der Liste auswählen}
          neurons.delete(0);  {Erstes Element löschen (Zeiger)}
          p.done;       {Objekt auf das gezeigt wurde löschen}
     end;

     neurons.destroy; {Liste löschen}


end;



procedure TForm1.NetzSpeichern1Click(Sender: TObject);
var
   Dateiname : STRING;
begin
     NetzSpeichernDialog.DefaultExt := NETZDEFAULTEXT;
     if NetzSpeichernDialog.execute then
     begin
          DiskDaten.Active := FALSE;
          Dateiname := NetzSpeichernDialog.FileName;
          {FileName auf Netze einstellen}
          FileManager.save(Dateiname);
          {Netzeinstellungen Speichern}

          {Neurone und Gewichte Speichern}
     end;
end;

procedure TForm1.Copyright1Click(Sender: TObject);
begin
     Application.MessageBox('Ferenc Acs'#13'Eichendorffring. 76 * 35394 Gießen'#13'Tel: 0641-9303677 * Fax: 0641-9303678'#13'eMail: ferenc.acs@psychol.uni-giessen.de',
        '(c) 2000 Ferenc Acs',
        MB_OK)
end;

end.
