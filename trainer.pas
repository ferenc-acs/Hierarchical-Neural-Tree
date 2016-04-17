unit Trainer;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, datau, neuron, StdCtrls, Buttons;

type

TrainMode = (OSSU,OSWU,ESPU);

  TTrain = class(TForm)
    PlayButton: TSpeedButton;
    CheckBox1: TCheckBox;
    RecordButton: TSpeedButton;
    StopButton: TSpeedButton;
    Label1: TLabel;
    EpocheAnz: TLabel;
    OSSUButton: TSpeedButton;
    OSWUButton: TSpeedButton;
    ESPUButton: TSpeedButton;
    CheckBox2: TCheckBox;
    procedure RecordButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure OSSUButtonClick(Sender: TObject);
    procedure OSWUButtonClick(Sender: TObject);
    procedure ESPUButtonClick(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure PlayButtonClick(Sender: TObject);
  private
    epc : LongInt; {Epochenz‰hler}
    tmode : TrainMode;
    function readepc : LongInt;
    procedure writeepc (value : LongInt);
  public
    learn : Boolean; {Soll das Netz trainiert werden ?}
    runanimation : Boolean;
    doanimation  : Boolean;
    zeichnen : Boolean;
    winlist : TList; {List der Gewinner der aktuellen Epoche}
    constructor create;
    destructor done;
    property epoche : LongInt read readepc write writeepc;
    procedure OSSU_OSWU_Epoche; {1 Epoche mit dem OSSU oder
                                OSWU Algoritmus rechnen}
    procedure ESPU_Epoche; {1 Epoche mit dem ESPU Algorithmus rechnen}
    procedure TestRun; {Die Gewinner werden ermittelt,
                        ohne daﬂ die Gewichte ver‰ndert werden}
  end;

var
  Train: TTrain;

implementation
uses param, vecmat,graph;

{$R *.DFM}

constructor TTrain.create;
begin
end;

destructor TTrain.done;
begin
end;

procedure TTrain.OSSU_OSWU_Epoche;
var
   lev,pc,i,i2,i3,cc,curlevel : LongInt;
   winner, curwinner, kind, kindwin : TNeuron;
   error,errorlow : double;
   actvec : TVector;
   childlist,bufferlist : TList; {Liste der Kinder eines Neurons}
   exit : boolean;
begin
     childlist := TList.create;
     bufferlist := TList.create;
     bufferlist.clear;
     childlist.clear;
     exit := false;
     {Winner <- root}
     winner := neurons.items[0];
     {Lev <- 1}
     lev := 0; {root liegt auf Level 0 !}

     repeat {step 3}
           {FOR every training pattern ... DO}
           pc := vectors.count;
           for i := 0 to pc-1 do
           begin
                {curwinner <- root}
                curwinner := neurons.items[0];
                {FOR curlevel = 1 to Lev DO}
                {curwinner <- the child of curwinner wich has minimum error}
                {This is accomplished through competition
                among the children nodes}
                for curlevel := 0 to lev do
                begin
                     cc := curwinner.kinder.count-1;
                     for i2 := 0 to cc do
                     begin
                          kind := curwinner.kinder[i2];
                          actvec := vectors.items[i];
                          error := kind.error(actvec);
                          if i2 = 0 then
                          begin
                               errorlow := error;
                               kindwin := kind;
                          end;
                          if error < errorlow then
                          begin
                               errorlow := error;
                               kindwin := kind;
                          end;
                     end;
                     curwinner := kindwin;
                end; {FOR curlevel...}
                winner := curwinner;
                if tmode=OSSU then
                begin
                     {Update the weights of every node in the subtree of winner}
                     cc := winner.kinder.count-1;
                     for i2 :=0 to cc do childlist.add(winner.kinder.items[i2]);
                     repeat
                           cc := childlist.count - 1;
                           for i2 := 0 to cc do
                           begin
                                kind := childlist.items[i2];
                                actvec := vectors.items[i];
                                kind.update(actvec);

                                i3 := 0;
                                while(i3 < kind.kinder.count) do
                                begin
                                     bufferlist.add(kind.kinder.items[i3]);
                                     inc(i3);
                                end;
                           end;
                     childlist.clear;
                     childlist := bufferlist;
                     bufferlist.clear;
                     until(childlist.count = 0); {Keine Kinder mehr im Subbtree}
                end; {OSSU Mode}
                {Update the weights of the winner node;}
                {increment the frequency of the winner node by 1}
                actvec := vectors.items[i];
                winner.update(actvec);
                winner.frequency := winner.frequency + 1.0;
                winlist.add(winner);
           end; {FOR every pattern...}
           {IF lev < DP, THEN Lev <- Lev+1; GO TO step3;}
           {ELSE Stop,training is finished}
           if lev < ParamForm.DP then inc(lev)
           else exit := true;
     until(exit);
     epoche := epoche + 1;
end;

procedure TTrain.ESPU_Epoche;
var
   lev,pc,i,i2,i3,cc,curlevel : LongInt;
   winner, curwinner, kind, kindwin : TNeuron;
   error,errorlow : double;
   actvec : TVector;
   childlist,bufferlist : TList; {Liste der Kinder eines Neurons}
   exit,firsttime : boolean;
begin
     childlist := TList.create;
     bufferlist := TList.create;
     bufferlist.clear;
     childlist.clear;
     exit := false;
     {Winner <- root}
     winner := neurons.items[0];
     {Lev <- 1}
     lev := 0; {root liegt auf Level 0 !}

     repeat {step 3}
           {FOR every training pattern ... DO}
           pc := vectors.count;
           for i := 0 to pc-1 do
           begin
                {FOR every node on level LEV DO compute error(n,i)}
                {winner <- the node on level Lev with the minimum error}
                firsttime := true;
                for  i2 := 0 to neurons.count-1 do
                begin
                     curwinner := neurons.items[i2];
                     if curwinner.level = lev then
                     begin
                          actvec := vectors.items[i];
                          error := curwinner.error(actvec);
                          if firsttime then
                          begin
                               errorlow := error;
                               winner := curwinner;
                               firsttime := false;
                          end;
                          if error < errorlow then
                          begin
                               errorlow := error;
                               winner := curwinner;
                          end;
                     end;
                end; {FOR every node...}

                     {Update the weights of every node in the subtree of winner}
                     cc := winner.kinder.count-1;
                     for i2 :=0 to cc do childlist.add(winner.kinder.items[i2]);
                     repeat
                           cc := childlist.count - 1;
                           for i2 := 0 to cc do
                           begin
                                kind := childlist.items[i2];
                                actvec := vectors.items[i];
                                kind.update(actvec);

                                i3 := 0;
                                while(i3 < kind.kinder.count) do
                                begin
                                     bufferlist.add(kind.kinder.items[i3]);
                                     inc(i3);
                                end;
                           end;
                     childlist.clear;
                     childlist := bufferlist;
                     bufferlist.clear;
                     until (childlist.count = 0); {Keine Kinder mehr im Subtree}

                {Update the weights of the winner node;}
                {increment the frequency of the winner node by 1}
                actvec := vectors.items[i];
                winner.update(actvec);
                winner.frequency := winner.frequency + 1.0;
                winlist.add(winner);
                {Update the weight of the nodes on the path from the}
                {root to the winner}
                curwinner := winner;
                if not(curwinner.eltern.count=0) then
                   repeat
                         curwinner := curwinner.eltern.items[0]; {Nur 1 Vorfahr}
                         curwinner.update(actvec);
                   until (curwinner.eltern.count = 0);
           end; {FOR every pattern...}
           {IF lev < DP, THEN Lev <- Lev+1; GO TO step3;}
           {ELSE Stop,training is finished}
           if lev < ParamForm.DP then inc(lev)
           else exit := true;
     until(exit);
     epoche := epoche + 1;
end;

procedure TTrain.RecordButtonClick(Sender: TObject);
begin
     learn := true;
     runanimation := true;
     repeat
          winlist.clear;
          if ((tmode=OSSU) or (tmode=OSWU)) then OSSU_OSWU_Epoche;
          if tmode=ESPU then ESPU_Epoche;
          if zeichnen then Diagramm.PaintBoxPaint(self);
          Application.ProcessMessages;
     until (not(runanimation and doanimation))
end;

procedure TTrain.FormCreate(Sender: TObject);
begin
     width := 180;
     height := 200;
     epc := strtoint(EpocheAnz.Caption);
     runanimation := false;
     doanimation := false;
     tmode := OSSU;
     zeichnen := true;
     winlist := TList.create;
end;

function TTrain.readepc : LongInt;
begin
     result := epc;
end;

procedure TTrain.writeepc (value : LongInt);
begin
    epc := value;
    EpocheAnz.Caption := inttostr(epc);
end;
procedure TTrain.CheckBox1Click(Sender: TObject);
begin
     if checkbox1.checked then
        doanimation := true
     else
         doanimation := false;
end;

procedure TTrain.StopButtonClick(Sender: TObject);
begin
     runanimation := false;
end;

procedure TTrain.OSSUButtonClick(Sender: TObject);
begin
     tmode := OSSU;
end;

procedure TTrain.OSWUButtonClick(Sender: TObject);
begin
     tmode := OSWU;
end;

procedure TTrain.ESPUButtonClick(Sender: TObject);
begin
     tmode := ESPU;
end;

procedure TTrain.CheckBox2Click(Sender: TObject);
begin
     if checkbox2.checked then
     begin
          zeichnen := true;
          Diagramm.PaintBoxPaint(self);
     end
     else
     begin
          zeichnen := false;
     end;
end;

procedure TTrain.PlayButtonClick(Sender: TObject);
begin
     learn := false;
     TestRun;
end;

procedure TTrain.TestRun;
var
   pc,i : LongInt;
begin
     pc := vectors.count;
     for i := 0 to pc-1 do
     begin
        {ACHTUNG LEER !!!!}
     end
end;


end.
