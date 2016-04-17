unit FileM;

{Dies ist eine unvollständige Unit. Sie bildet eine Basisstruktur,}
{die zum Abspeichern von hierarchischen neuronalen Netzen dienen soll.}

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, Menus, graph, neuron, Printers, Inspektr,param, trainer,
  DB, DBTables;

type

    TFileManager = class
       private
       public
       function save(Dateiname : string):Boolean;
    end;

var
   FileManager : TFileManager;

implementation


function TFileManager.save(Dateiname : string):Boolean;
var
   success : Boolean;
   F : TFileStream;
   i,j : LongInt;
   p,o : Tneuron;
   size : integer;
begin
     success := FALSE;
     i := 0;
          {FileName auf Netze einstellen}
          if fileexists(Dateiname) then
             F := TFileStream.Create(Dateiname,
                  fmOpenWrite or fmShareExclusive)
          else
             F := TFileStream.Create(Dateiname,
                  fmCreate or fmShareExclusive);

          {Netzeinstellungen speichern}
          ParamForm.Save(F);

          {Neurone und Gewichte speichern}
          for i := 0 to (neurons.count-1) do
          begin
            p := neurons.items[i];
            p.save(F);
          end;
          success := TRUE;

          F.free;
     save := success; {Ergebnis zurückgeben}
end;



end.
