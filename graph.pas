unit Graph;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, ExtCtrls, neuron, Menus, StdCtrls,vecmat, Buttons;



type

  TMode = (Info,Drag,Zoom,Cut); {Modi der Benutzerinteraktion}

  TListPtr = ^TList;
  TNeuronPtr = ^TNeuron;

  TDiagramm = class(TForm)
    PaintBox: TPaintBox;
    Panel1: TPanel;
    ToolPanel: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    ZoomComboBox: TComboBox;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    GewinnerCheckBox: TCheckBox;
    LevFracEdit: TEdit;
    AbstaendeCheckBox: TCheckBox;
    procedure PaintBoxPaint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure ZoomComboBoxChange(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure GewinnerCheckBoxClick(Sender: TObject);
    procedure LevFracEditChange(Sender: TObject);
    procedure AbstaendeCheckBoxClick(Sender: TObject);
  private
    PBwidthF, PBheightF : double; {Breite & Höhe im Gleitkommaformat}
    PBwidthval, PBheightval : Integer; {Breite & Höhe der Paintbox}
    MausTasteLinks : Boolean; {Status der Maustaste}
    buffer : TBitmap;
    InteractionMode : TMode; {Welches der Speedbuttons ist ausgewählt ?}
    ZoomRate : double; {Die vom Benutzer ausgewählte Zoomrate}
    isdrag : Boolean; {'Draggd' der Benutzer gerade ?}
    dragx,dragy : Integer; {Bildschirmkoordinaten an denen drag begann}
    circle_diag : boolean; {Kreisdiagramm ?}
    draw_winners : boolean; {Gewinner zeichnen ?}
    selected_neuron:LongInt;{Nummer des Neurons auf das die Maus zeigt 0->keins}
    levfrac : double; {Abstände der Level im Diagramm}
    LevAnz : LongInt; {Anzahl der Level in dem Netz} {<- circlediag}
    distdraw : Boolean; {Sollen die Abstande im Kreisdiag
                        berücksichtigt werden ?}
    {Die folgenden Funktionen wandeln die Vorgaben}
    {in Bildschirmwerte um}
    function transform_x (val : TWeight) : LongInt;
    function transform_y (val : TWeight) : LongInt;
    function transformxf (val : Integer) : TWeight;
    function transformyf (val : Integer) : TWeight;
    function getPBw : Integer;
    procedure setPBw (val : Integer);
    function getPBh : Integer;
    procedure setPBh (val : Integer);
  public
    Dataoriginx, Dataoriginy : TWeight; {Nullpunkte des Datenraumes}
    Datawidth, Dataheight : TWeight; {Breite und Höhe des Datenraumes}
    property PBwidth : Integer read getPBw write setPBw; {Hoehe der Paintbox}
    property PBheight : Integer read getPBh write setPBh; {Breite der Paintbox}
              {Diese Routine initialisiert die Koordinatenfelder so, daß eine}
              {kreisförmige Anordung der Neurone entsteht, Abstände entsprechen}
              {den euklidischen Distanzen in n-dimensionalen Raum}
    procedure circlediagramm;
    procedure draw_diagramm (const canv : TCanvas);
  end;

var
  Diagramm: TDiagramm;

implementation

{$R *.DFM}
uses datau, neuron_e, polaru, inspektr, printers, trainer, Param;

const MinInt = MaxInt * -1;


procedure TDiagramm.PaintBoxPaint(Sender: TObject);
begin
     if not(Printer.printing) then
     begin
           diagramm.PBwidth := Paintbox.width;
           diagramm.PBheight := Paintbox.height;
           buffer.width := PBwidth;
           buffer.height := PBheight;

           draw_diagramm(buffer.canvas);

           BitBlt(PaintBox.Canvas.handle,0,0,
                  PBwidth,PBheight,buffer.canvas.handle,0,0,SRCCOPY);
     end;

end;

procedure TDiagramm.FormCreate(Sender: TObject);
begin
     PBwidth := PaintBox.width;
     PBheight := PaintBox.height;
     buffer := TBitmap.create;
     MausTasteLinks := False;
     Dataoriginx := 0.0;
     Dataoriginy := 0.0;
     Datawidth := 1.0;
     Dataheight := 1.0;
     InteractionMode := Info;
     ZoomRate := 1.5; {150% Zoomrate}
     IsDrag := false;
     circle_diag := false;
     draw_winners := false;
     selected_neuron := 0;
     levfrac := 0.1;
     LevAnz := 0;
     distdraw := TRUE;
end;

procedure TDiagramm.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
const
     HOT : Integer = 6; {Kantenlänge des Hotzone Quadrats}
var
   hotzone : TRECT; {Sensitive Zone um den Mauszeiger}
   hoth : Integer; {Zum rechnen}
   numn,nc : LongInt;
   k : array [1..3] of TWeight;
   p : TNeuron;
   success : Boolean;
   x1,y1 : Integer;

begin
     if (InteractionMode = Info) or (InteractionMode = Cut) then
     begin
          success := FALSE;
          if MausTasteLinks then {Der Benutzer hält die linke Maustaste}
          begin {gedrückt, Neurone in der Nähe sollen angezeigt werden.}
                hoth := HOT div 2;
                with hotzone do
                begin
                     left  :=x-hoth;
                     top   :=y-hoth;
                     right :=x+hoth;
                     bottom:=y+hoth;
                end;

                numn := 0;
                nc := neurons.count-1;

                while (numn < nc) do
                begin
                     p := neurons.items[numn];
                     p.readkoords(k);
                     if circle_diag then
                     begin
                          x1:=transform_x(p.koords[1]);
                          y1:=transform_y(p.koords[2]);
                     end
                     else
                     begin
                          x1:=transform_x(p.weight.read(1));
                          y1:=transform_y(p.weight.read(2));
                     end;
                     if (hotzone.left < x1)
                     and (hotzone.right > x1)
                     and (hotzone.top < y1)
                     and (hotzone.bottom > y1)
                        then success := TRUE;
                     if success then break; {Schleife vorzeitig verlassen}
                     inc(numn);
                end; {while}

                if success then
                begin
                     selected_neuron := numn+1;
                     Panel1.caption := p.name+', '+inttostr(numn+1);
                     Panel1.caption := Panel1.caption+',Level: '+inttostr(p.getlev);
                end
                else
                begin
                    Panel1.caption := '';
                    selected_neuron := 0;
                end;
          end; {Wenn mbLeft}
     end; {if Interaction...}
end;

procedure TDiagramm.PaintBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
   buffer : array [1..4] of TWeight;
begin
     if button = mbleft then
     begin
          case InteractionMode of
               zoom:
               begin
                    buffer[3] := Datawidth / ZoomRate;
                    buffer[4] := Dataheight / ZoomRate;
                    buffer[1] := transformxf(x)-buffer[3]/2;
                    buffer[2] := transformyf(y)-buffer[4]/2;
                    Dataoriginx := buffer[1];
                    Dataoriginy := buffer[2];
                    Datawidth := buffer[3];
                    Dataheight := buffer[4];
                    PaintBoxPaint(self);
               end;
               info: MausTasteLinks := TRUE;
               drag:
               begin
                    isdrag := TRUE;
                    dragx := x;
                    dragy := y;
               end;
               cut: MausTasteLinks := TRUE;
          else
              begin
               InteractionMode := info;
               SpeedButton1.Down := true;
               PaintBoxMouseDown(self,button,shift,x,y);
              end;
          end; {case}
     end;

     if button = mbRight then
     begin
          case InteractionMode of
               zoom:
               begin
                    buffer[3] := Datawidth * ZoomRate;
                    buffer[4] := Dataheight * ZoomRate;
                    buffer[1] := transformxf(x)-buffer[3]/2;
                    buffer[2] := transformyf(y)-buffer[4]/2;
                    Dataoriginx := buffer[1];
                    Dataoriginy := buffer[2];
                    Datawidth := buffer[3];
                    Dataheight := buffer[4];
                    PaintBoxPaint(self);
               end;
          end; {case}
     end;

end;

procedure TDiagramm.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
   xdiff,ydiff : TWeight;
   p : TNeuron;
begin
     if button = mbLeft then
     begin
          case InteractionMode of
               info:
               begin
                    MausTasteLinks := false;
                    if (selected_neuron <> 0) then
                    begin
                         neuroninspektor.aktneuronbox.text := inttostr(selected_neuron);
                         neuroninspektor.aktneuronboxchange(self);
                         neuroninspektor.show;
                    end;
               end;
               zoom: begin end; {Nichts tun}
               drag:
               begin
                    if isdrag then
                    begin
                         isdrag := false;
                         xdiff := transformxf(dragx) - transformxf(x);
                         ydiff := transformyf(dragy) - transformyf(y);
                         Dataoriginx := Dataoriginx + xdiff;
                         Dataoriginy := Dataoriginy + ydiff;
                         PaintBoxPaint(self);
                    end;
               end;
               cut:
               begin
                    if (selected_neuron <> 0) then
                    begin
                         p := neurons.items[selected_neuron-1];
                         neurons.delete(selected_neuron-1);
                         p.done;
                         PaintBoxPaint(self);
                    end;
               end;
          else
              begin
                   InteractionMode := info;
                   SpeedButton1.Down := true;
                   PaintBoxMouseUp(self,button,shift,x,y);
              end;
          end; {case}
     end;
end;


function TDiagramm.transform_x (val : TWeight) : LongInt;
var
   x : LongInt;
   xf,frac: TWeight;
begin
     xf := val-Dataoriginx;
     frac := xf/Datawidth;
     xf := frac * PBWidthF;
     x := round(xf);
     if x > MaxInt-1 then x := MaxInt-1;
     if x < MinInt-1 then x := MinInt-1;
     result := x;
end;

function TDiagramm.transform_y (val : TWeight) : LongInt;
var
   y : LongInt;
   yf,frac: TWeight;
begin
     yf := val-Dataoriginy;
     frac := yf/Dataheight;
     yf := frac * PBHeightF;
     y := PBHeightval-round(yf);
     if y > MaxInt-1 then y := MaxInt-1;
     if y < MinInt-1 then y := MinInt-1;
     result := y;
end;

function TDiagramm.transformxf (val : Integer) : TWeight;
var
   x,frac : TWeight;
begin
     x := strtofloat(inttostr(val));
     frac := val / PBwidthval;
     x := frac * Datawidth;
     result := Dataoriginx + x;
end;

function TDiagramm.transformyf (val : Integer) : TWeight;
var
   y,frac : TWeight;
begin
     val := PBheightval - val;
     y := strtofloat(inttostr(val));
     frac := val / PBheightval;
     y := frac * Dataheight;
     result := Dataoriginy + y;
end;

function TDiagramm.getPBw : Integer;
begin
     result := PBwidthval;
end;

procedure TDiagramm.setPBw (val : Integer);
begin
     PBwidthval := val;
     PBwidthF := strtofloat(inttostr(val));
end;

function TDiagramm.getPBh : Integer;
begin
     result := PBheightval;
end;

procedure TDiagramm.setPBh (val : Integer);
begin
     PBheightval := val;
     PBheightF := strtofloat(inttostr(val));
end;


procedure TDiagramm.SpeedButton1Click(Sender: TObject);
begin
     InteractionMode := Info;
end;

procedure TDiagramm.SpeedButton2Click(Sender: TObject);
begin
     InteractionMode := Zoom;
end;

procedure TDiagramm.SpeedButton3Click(Sender: TObject);
begin
     InteractionMode := Drag;
end;

procedure TDiagramm.ZoomComboBoxChange(Sender: TObject);
var
   z : double;
begin
     if length(ZoomComboBox.Text) > 0 then
     begin
          try
             z := strtofloat(ZoomComboBox.Text);
             ZoomRate := z / 100.0;
          except
             on EConvertError
                do ZoomComboBox.Text := floattostrf(ZoomRate*100.0,fffixed,3,0);
          end;
     end;
end;

procedure TDiagramm.circlediagramm;
var
   llist : TList; {Liste einer Liste von Neuronen, nach Leveln sortiert}
   nlist : TList; {Liste der Neurone auf einem Level}
   n,p : TNeuron;
   vec : TVector;
   pp,pn : TPolar;
   nc,i,i2,vr,n_lev,maxanz,maxlev : LongInt;
   k : array[1..3] of TWeight;
   {kl_winkel: Kleinster Winkel zur Darstellung der Neurone}
   kl_winkel,winkel,length,rhop : TDataFormat;
begin
     try
     pp := TPolar.create;
     pn := TPolar.create;
     vec := TVector.create;
     llist := TList.create;
     nc := neurons.count -1;

     {Eine sortierte Liste der Neurone pro Level erstellen}
     for i := 0 to nc do
     begin
          n := neurons.items[i];
          {TEST}
          if n.valid <> VALID_ID then
             raise ENeuron_defekt.create('Ungültiges Neuron aufgerufen !');
          {TEST  Ende}
          n_lev := n.getlev;

          {Wenn der Level noch nicht geführt wird, muss man ihn anhängen}
          if (n_lev+1) > llist.count then
          begin
               vr := n_lev - (llist.count-1);
               for i2 := 1 to vr do
               begin
                    nlist := TList.create;
                    llist.add(nlist);
               end;
          end; {Wenn Level noch nicht geführt....}
          nlist := llist.items[n_lev];
          nlist.add(n);
     end;

     levanz := llist.count;
     {Finde die maximale Anzahl der Neurone auf einem Level heraus}
     vr := llist.count-1;
     maxanz := 0;
     for i2 := 0 to vr do
     begin
          nlist := llist.items[i2];
          if nlist.count > maxanz then
          begin
               maxanz := nlist.count;
               maxlev := i2;
          end;
     end;
     {Die Maximale Anzahl bestimmt den kleinsten Winkel}
     kl_winkel := (2*pi) / maxanz;

     {Rechne die Koordinatenwerte der Levelreihenfolge nach aus}
     vr := llist.count-1;
     for i := 0 to vr do
     begin
          nlist := llist.items[i];
          nc := nlist.count;
          winkel := (2*pi) / nc;
          for i2 := 0 to nc-1 do
          begin
               n := nlist.items[i2];
               if distdraw then
               begin
                    {Abstand zum Elternteil berechnen}
                    if n.eltern.count > 0 then
                    begin
                         p := n.eltern[0];
                         n.weight.minus(p.weight,vec);
                         length := vec.skalar(vec);
                         pp.xyset(p.koords[1],p.koords[2]);
                    end
                    else
                    begin
                        length := 0.0;
                        pp.phi:=0.0;
                        pp.rho:=0.0;
                    end;
               end {distdraw}
               else
                   length := 1.0; {Wenn kein distdraw}
               pn.phi := i2*winkel;
               pn.rho := pp.rho+length+levfrac;
               n.koords[1] := pn.x;
               n.koords[2] := pn.y;
          end; {for i2}
     end;

     {Listen freigeben}

     while llist.count > 0 do
     begin
          nlist := llist.items[0];
          while nlist.count > 0 do
          begin
                nlist.delete(0);
          end;
          llist.delete(0);
          nlist.free;
     end;
     llist.free;

     except
           {on EGPFAult do circle_diag := FALSE;}
           on ENeuron_defekt do circle_diag := FALSE;
           on EZerodivide do circle_diag := FALSE;
     end; {Exception Behandlung}
     pp.free;
     pn.free;
end;

procedure TDiagramm.SpeedButton4Click(Sender: TObject);
begin
     if not circle_diag then
        circle_diag := TRUE
     else
        circle_diag := FALSE;
end;

procedure TDiagramm.draw_diagramm (const canv : TCanvas);
const
     CIRCLFRAC = 40; {Divisionsfaktor für den Kreisradius}
var
   zu,i,i2,wdim,a,b,c,d : LongInt;
   p,p2 : TNeuron;
   z : TNeuronPtr;
   diam : LongInt; {Kreisdurchmesser}
   k,k2 : array [1..3] of TWeight;
   x,y : LongInt;
   colordiv : LongInt; {Divisionsfaktor für die Verbindungsfarbe}
   vec : TVector;
   anz : LongInt;
   polar : TPolar;
begin
     polar := TPolar.create;
     {evtl. Kreiswerte berechnen}
     if circle_diag then circlediagramm;


     {buffer löschen}
     with canv do
     begin
          brush.color := clwhite;
          pen.color := clwhite;
          rectangle (0,0,PBwidth,PBheight);
     end;

     {Reize Zeichnen}
     if (vectors.count > 0) and (circle_diag = FALSE) then
     begin
          vec := vectors.items[0];
          if vec.getdim < 3 then
               begin
               diam := PBheight;
               if diam > PBwidth then diam := PBwidth;
               diam := diam div CIRCLFRAC;
               diam := diam div 4;
               canv.brush.color := clgreen;
               canv.pen.color := clgreen;
               anz := vectors.count-1;
               for i := 0 to anz do
               begin
                    vec := vectors.items[i];
                    x:=transform_x(vec.read(1));
                    y:=transform_y(vec.read(2));
                    a := x-diam; if a < minint then a:=x;
                    b := y-diam; if b < minint then b:=y;
                    c := x+diam; if c > maxint then c:=x;
                    d := y+diam; if d > maxint then d:=y;
                    canv.ellipse(a,b,c,d);
               end;
          end; {dim < 3}
     end;


     canv.pen.color := clred;
     canv.brush.color := clblue;

     {Divisionsfaktor fuer die Verbindungsfarbe festlegen}
     colordiv := $00FF00FF div ParamForm.arity;

     {Verbindungen zu den Eltern zeichnen}
     anz := neurons.count;
     for i := 0 to (anz-1) do
     begin
          p := neurons.items[i];
          p.readkoords(k);

          if not(p.eltern.count = 0) then
          begin
               p2 := p.eltern.items[0];
               p2.readkoords(k2);
               if circle_diag then
               begin
                    x:=transform_x(p.koords[1]);
                    y:=transform_y(p.koords[2]);
               end
               else
               begin
                    x:=transform_x(p.weight.read(1));
                    y:=transform_y(p.weight.read(2));
               end;
               canv.MoveTo (x,y);
                    if circle_diag then
                    begin
                         x:=transform_x(p2.koords[1]);
                         y:=transform_y(p2.koords[2]);
                    end
                    else
                    begin
                         x:=transform_x(p2.weight.read(1));
                         y:=transform_y(p2.weight.read(2));
                    end;
                        canv.Pen.Color := colordiv * p.level + $02000000;
                        canv.LineTo (x,y);
          end;
     end;

     diam := PBheight;
     if diam > PBwidth then diam := PBwidth;
     diam := diam div CIRCLFRAC;
     diam := diam div 2;

     anz := neurons.count;
     for i := 0 to (anz-1) do
     begin
          p := neurons.items[i];
          if not (p.weight.GetDim = 0) then
          begin
               if circle_diag then
               begin
                    x:=transform_x(p.koords[1]);
                    y:=transform_y(p.koords[2]);
               end
               else
               begin
                    x:=transform_x(p.weight.read(1));
                    y:=transform_y(p.weight.read(2));
               end;
               a := x-diam; if a < minint then a:=x;
               b := y-diam; if b < minint then b:=y;
               c := x+diam; if c > maxint then c:=x;
               d := y+diam; if d > maxint then d:=y;
               canv.ellipse(a,b,c,d);
          end;
     end;

     if draw_winners then
     begin
          {Gewinner markieren}
          canv.pen.color := clyellow;
          canv.brush.color := clyellow;

          diam := PBheight;
          if diam > PBwidth then diam := PBwidth;
          diam := diam div CIRCLFRAC;
          diam := diam div 4;

          anz := train.winlist.count;
          if anz > 0 then
          begin
               for i := 0 to (anz-1) do
               begin
                    p := train.winlist.items[i];
                    if not (p.weight.GetDim = 0) then
                    begin
                         if circle_diag then
                         begin
                              x:=transform_x(p.koords[1]);
                              y:=transform_y(p.koords[2]);
                         end
                         else
                         begin
                              x:=transform_x(p.weight.read(1));
                              y:=transform_y(p.weight.read(2));
                         end;
                         a := x-diam; if a < minint then a:=x;
                         b := y-diam; if b < minint then b:=y;
                         c := x+diam; if c > maxint then c:=x;
                         d := y+diam; if d > maxint then d:=y;
                         canv.ellipse(a,b,c,d);
                    end;
               end;
          end;
     end; {if draw_winners}

end;

procedure TDiagramm.SpeedButton5Click(Sender: TObject);
begin
     InterActionMode := Cut;
end;

procedure TDiagramm.GewinnerCheckBoxClick(Sender: TObject);
begin
     if GewinnerCheckBox.checked then
     begin
        Draw_Winners := true;
        PaintBoxPaint(self);
     end
     else
     begin
        Draw_Winners := false;
        PaintBoxPaint(self);
     end;
end;

procedure TDiagramm.LevFracEditChange(Sender: TObject);
begin
     if length(LevFracEdit.Text) > 0 then
     begin
          try
             levfrac := strtofloat(LevFracEdit.Text);
          except
             on EConvertError do
                begin
                     levfrac := 0.1;
                     LevFracEdit.Text := '0,1';
                end;
          end;
     end;
end;

procedure TDiagramm.AbstaendeCheckBoxClick(Sender: TObject);
begin
     if Abstaendecheckbox.checked then
        distdraw := true
     else
        distdraw := false;
end;

end.
