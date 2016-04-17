unit Param;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, TabNotBk, StdCtrls, Buttons, ComCtrls;

type
  TParamForm = class(TForm)
    ParamTNotebook: TTabbedNotebook;
    Label1: TLabel;
    Labels: TLabel;
    AnzNeurEdit: TEdit;
    Label2: TLabel;
    AlphaEdit: TEdit;
    Button1: TButton;
    GewDimTxt: TLabel;
    Button2: TButton;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    KinderZahlEdit: TEdit;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    ArityEdit: TEdit;
    Label9: TLabel;
    Button3: TButton;
    Label10: TLabel;
    Label11: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure AlphaEditExit(Sender: TObject);
    procedure AlphaEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Button2Click(Sender: TObject);
    procedure KinderZahlEditChange(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ArityEditChange(Sender: TObject);
  private
    gewdim : LongInt;
    procedure SetGewDimensionen(wert : LongInt);
    procedure update_neuronenzahl;
    function spaceonlevel(level:LongInt) : LongInt;
  public
    DP : LongInt; {Tiefe des neuralen Baumes}
    AnzNeurone : LongInt;
    KinderZahl : LongInt;
    ZeichDimensionen : LongInt;
    alpha : double;  {Learning Rate}
    arity : LongInt; {Die Arität des Baumes}    

    property GewDimensionen : LongInt read gewdim write SetGewDimensionen;
    function save(f : TFileStream) : Integer;

  end;

var
  ParamForm: TParamForm;

implementation

{$R *.DFM}
uses neuron,neuron_e,datau,vecmat, Trainer;

procedure TParamForm.FormCreate(Sender: TObject);
begin
     AnzNeurone := strtoint(AnzNeurEdit.Text);
     KinderZahl := strtoint(KinderZahlEdit.Text);
     GewDimensionen := strtoint(GewDimTxt.Caption);
     alpha := strtofloat(AlphaEdit.Text);
     ZeichDimensionen := 2; {Noch nicht veränderbar}
     DP := 0; {Tiefe des Baumes}
     arity := 3;
     update_neuronenzahl;
end;

procedure TParamForm.Button1Click(Sender: TObject);
var
   i,i2,ndx,wdim : LongInt;
   p : TNeuron;
   z : TNeuron;
   result : Word;
   test : string[20];

begin

     result := messagedlg('Wollen Sie das alte Netz löschen ?',mtWarning,
               mbOkCancel,0);

     if result = mrOk then
     begin
          AnzNeurone := strtoint(AnzNeurEdit.Text);

          {Alte Neuronenliste löschen}

          while neurons.count > 0 do
          begin
               p := neurons.items[0]; {Erstes Element der Liste auswählen}
               if not(p.valid = VALID_ID) then
                  raise ENeuron_defekt.Create ('TParamForm.Button1Click');
               neurons.delete(0);  {Erstes Element löschen (Zeiger)}
               p.done;     {Objekt auf das gezeigt wurde löschen}
          end;



          {Neue Liste erstellen}
          for i := 1 to AnzNeurone do
          begin
                   {Neuron erstellen}
              p := TNeuron.create
                   (GewDimensionen,ZeichDimensionen,i);
              p.Writekoords ([Random(200),Random(200)]);
              ndx:=neurons.add (p);
              p.number := ndx+1;
              z := Neurons.items[ndx];
              wdim := z.weight.getdim;
              for i2 := 1 to wdim do
                  p.weight.write(i2,p.randomnumber(data.vec_min,data.vec_max));
              if not(z.valid = VALID_ID) then
                  raise ENeuron_defekt.Create ('TParamForm.Button1Click, 2');
          end;
     end; {Messageboxabfrage}

end;

procedure TParamForm.AlphaEditExit(Sender: TObject);
var
   alphanew : double;
   failure  : boolean;
begin
     failure := false;

     alphanew := strtofloat (AlphaEdit.Text);
     if alphanew > 1.0 then failure := TRUE;
     if alphanew < 0.0 then failure := TRUE;

     if not(failure) then alpha := alphanew;
end;

procedure TParamForm.AlphaEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
     if Key = VK_RETURN then AlphaEditExit(self);
end;

procedure TParamForm.SetGewDimensionen(wert : LongInt);
begin
     gewdim := wert;
     GewDimTxt.Caption := inttostr(wert);
end;

{Ausgehend von der Neuronenzahl wird ein}
{Neuraler Baum erstellt}
procedure TParamForm.Button2Click(Sender: TObject);
var
   i,i2,i3,anzneur,lc,lc2 : LongInt;
   noncurlevel,nonprilevel,eltern_count : LongInt;
   ne,nk : TNeuron;
   gefunden, alle_vergeben, alle_haben_kinder : Boolean;
begin
     anzneur := neurons.count-1;
     lc := 1;
     i := 0;
     DP := 0; {Tiefe des Baumes}
     nonprilevel:=0;
     noncurlevel:=0;
     alle_vergeben := FALSE;
     alle_haben_kinder := FALSE;
     eltern_count := 0;

     while ((anzneur >= 0) and (KinderZahl > 0)) do
     begin

          {ElternNeuron suchen & holen}
          if not(lc=1) then
          begin
               gefunden := false;
               i3 := 0;

               repeat
                    ne := neurons.items[i3];
                    if ne.level = lc-1 then {Level stimmt}
                    begin
                         if ne.kinder.count < KinderZahl then
                            begin
                                 gefunden := true;
                                 inc(eltern_count);
                            end;
                    end;
                    inc(i3);
               until ((gefunden) or (i3>anzneur));

               {Für den Fall der nicht eintreten dürfte}
               if (i3>anzneur) then alle_haben_kinder := TRUE;
          end
          else
          begin
               ne := neurons.items[0]; {Wurzel ist Neuron 0}
               ne.level := 0;
               inc(eltern_count);
               nonprilevel := 0;
          end;


                  {Die offenen Kinderstellen besetzen}
          while (ne.kinder.count < KinderZahl) do
          begin {}
               inc(i);
               if i > anzneur then alle_vergeben := TRUE;
               if alle_vergeben then break; {Keine Neurone mehr da !}

               nk := neurons.items[i];
               inc(noncurlevel);

               {Verwandtschaft bekanntmachen}
               nk.eltern.add(ne);
               ne.kinder.add(nk);
               nk.level := lc;
               if DP < lc then DP := lc; {Über die Tiefe Buch führen}
          end;     {}
          if alle_vergeben then break;
          Application.ProcessMessages;
          {Wenn alle Neurone auf dem Elternlevel Kinder haben -> nächster Level}

          if nonprilevel <= eltern_count then {Sind alle Neurone auf dem }
          begin                              {Level-1 Eltern ?}
               eltern_count := 0;            {<= wegen Neuron 0 !}
               alle_haben_kinder := TRUE;
          end;

          if alle_haben_kinder then
          begin
               inc(lc);
               nonprilevel := noncurlevel;
               alle_haben_kinder := false;
               noncurlevel := 0;
          end;
     end;
     {Epochencounter zurücksetzen}
     Train.epoche := 0;
end;

procedure TParamForm.KinderZahlEditChange(Sender: TObject);
begin
     if not(length(KinderZahlEdit.Text) = 0) then
     begin
          try
             KinderZahl := strtoint(KinderZahlEdit.Text);
          except
          on EConvertError do
             begin
                  kinderzahledit.text := '2';
                  kinderzahlEditChange(self);
             end;
          end;
          update_neuronenzahl;
     end;
end;

function TParamForm.spaceonlevel(level:LongInt) : LongInt;
var
   k,i : LongInt;
begin
     k := 1;
     for i := 1 to level do
     begin
          k := k * KinderZahl;
     end;
     result := k;
end;

procedure TParamForm.Button3Click(Sender: TObject);
var
   numneurons, numchilds, i : LongInt;
begin
     numchilds := kinderzahl;
     numneurons := 1;
     for i := 1 to arity do
     begin
          numneurons := numneurons + spaceonlevel(i);
     end;
     AnzNeurEdit.text := inttostr(numneurons);
     Button1Click(self);
     Button2Click(self);
end;

procedure TParamForm.ArityEditChange(Sender: TObject);
begin
     if length(arityedit.text) > 0 then
     begin
          try
             arity := strtoint(arityedit.text);
          except
          on EConvertError do
             begin
                  arityedit.text := '3';
                  ArityEditChange(self);
             end;
          end;
          update_neuronenzahl;
     end;
end;

procedure TParamForm.update_neuronenzahl;
var
   total,i : LongInt;
begin
     total := 0;
     for i := 0 to arity do
     begin
          total := total + spaceonlevel(i);
     end;

     label11.caption := inttostr(total) + ' Neurone';
end;

function TParamForm.save(f : TFileStream):Integer;
var
   s : string;
begin
          s := char(13) + 'NETZPARAMETER' + char(13);
          F.write(s,sizeof(s));
          F.write(DP,sizeof(DP));
          F.write(AnzNeurone,sizeof(AnzNeurone));
          F.write(KinderZahl,sizeof(KinderZahl));
          F.write(ZeichDimensionen,sizeof(ZeichDimensionen));
          F.write(alpha,sizeof(alpha));
          F.write(arity,sizeof(arity));
          save := 0;
end;


end.
