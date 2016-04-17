unit Datau;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, Grids, DBGrids, DB, DBTables, Menus, neuron, vecmat;

type
  Tdata = class(TForm)
    MainMenu1: TMainMenu;
    Daten1: TMenuItem;
    Einlesen1: TMenuItem;
    Schreiben1: TMenuItem;
    daten: TTable;
    DBGrid: TDBGrid;
    OpenDialog1: TOpenDialog;
    DataSource: TDataSource;
    SaveDialog1: TSaveDialog;
    procedure Einlesen1Click(Sender: TObject);
    procedure Schreiben1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    vec_min : TWeight; {Minimalwert der Daten}
    vec_max : TWeight; {Maximalwert der Daten}


    constructor create;
    destructor done;
    procedure DatenInVektoren; {Schreibt die TTable Daten in TList}
  end;

var
  data: Tdata;
  Vectors : TList; {Trainigsvektoren TList of TVector}

implementation

{$R *.DFM}
uses param;

procedure Tdata.Einlesen1Click(Sender: TObject);
begin
     if OpenDialog1.Execute = TRUE then
     begin
          daten.active := FALSE;
          daten.tablename := OpenDialog1.Filename;
          daten.active := TRUE;
          DataSource.DataSet := daten;
          DBGrid.datasource := DataSource;
          DatenInVektoren;
     end;
end;

procedure Tdata.Schreiben1Click(Sender: TObject);
begin
     if SaveDialog1.Execute = TRUE then
     begin
        daten.active := false;
     end;
end;

constructor Tdata.create;
begin

end;

destructor Tdata.done;
var
   i, count : LongInt;
   vec : TVector;
begin
     while vectors.count > 0 do
     begin
          vec:=vectors.items[0];
          vec.done;
          vectors.delete(0);
     end;
end;

procedure Tdata.FormCreate(Sender: TObject);
begin
     Vectors := TList.create;
     vec_min := 0.0; {Damit wenigstens halbwegs vernünftige}
     vec_max := 1.0; {Werte in diesen Variablen stehen}
end;

procedure Tdata.DatenInVektoren;
var
   i : LongInt;
   felder, dimensionen : LongInt;
   k : double;
   vec : TVector;
begin
     felder := daten.fieldcount;
     dimensionen := felder-1; {Das erste Feld beeinhaltet Labels}

     {Alte Liste löschen}
     while vectors.count > 0 do
     begin
          vec := vectors.items[0];
          vec.done;
          vectors.delete(0);
     end;

     daten.first; {Auf den Anfang der Tabelle positionieren}
     vec_min := TFloatField(daten.fields[1]).value;
     vec_max := TFloatField(daten.fields[1]).value;

     while not(daten.eof) do
     begin
     vec := TVector.create;
     vec.setdim(dimensionen);
     for i := 1 to felder-1 do {erstes Feld mit den Labeln überspr.}
     begin
          k := TFloatField(daten.fields[i]).value;
          vec.write(i,k);
          if k < vec_min then vec_min := k;
          if k > vec_max then vec_max := k;
     end;
     vectors.add(vec);
     daten.next; {Muß am Ende dieses Blocks bleiben !}
     end; {daten.eof}

     ParamForm.GewDimensionen := dimensionen; {Gewichtsdimensionen auf Daten}
     ParamForm.Button1Click(self);
     ParamForm.Button2Click(self);
end;

end.
