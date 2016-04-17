unit neuron;

interface


uses
    classes,graphics,extctrls,neuron_e,param,vecmat,polaru;

const
     NEURON_DURCHMESSER : Integer = 5; {5 % Der Zeichenfläche}
     DEFAULT_NAME : string = 'Nobody'; {für Neurone}

type

{---------------------------------------------------------------}
{                      TNeuron Klasse                           }
{---------------------------------------------------------------}

  TListPtr = ^TList;
  doublePtr = ^double;
  IntegerPtr = ^Integer;
  TNeuronPtr = ^TNeuron;


  TNeuron = class
    private

    public
    valid : Integer;   {Prüfvariable für das Objekt -> VALID_ID}
    weight : TVector;
    err : double; {Accumulated average Error}
    freq_ut : double; {Frequency of Utilisation during Test runs}
    err_vec : TVector; {Vector of accumulated average errors}
    relerr_vec : TVector; {Accumulated average relative Vector}
    selprob : double; {Probability of selection for one Neuron}
    kinder : TList;
    eltern : TList; {Im aktuellen Modell nur 1 Elternteil }
    koords : array [1..3] of TWeight; {Nur 3D Koordinaten !}
    name   : string; {Name des Neurons z.B. für Labels}
    number : Longint; {Nummer des Neurons}
    level : LongInt;
    rwinkel : TDataFormat; {Winkel den das Neuron+Nachkommen einnehmen dürfen}
    frequency : double;
    function getlev : LongInt;  {Ermittelt den Level anhand der Vorfahren}
    procedure writekoords (k: array of TWeight);
    procedure readkoords  (var k : array  of TWeight);
    procedure setweights (var k : array of TWeight);
    procedure readweights (var k : array of TWeight);
    constructor Create(Gewichtsdimensionen,Zeichendimensionen,Nummer : LongInt);
    function RandomNumber(min,max : TWeight) : TWeight;
    function error(vec : TVector) : double; {Fehler des Neurons zum Eingabereiz}
    function ischild(n : TNeuron) : boolean; {Bin ich das Kind von n?}
    procedure update(vec : TVector); {Aktualisiert das Gewicht}
    function save(F : TFileStream) : integer;
    destructor Done;
  end;

var
   Neurons : TList;  {Die Liste der Neuronen}

implementation

uses sysutils;


{**********************************************************************}
{                            TNeuron Implementation                    }
{**********************************************************************}

constructor TNeuron.Create(Gewichtsdimensionen,Zeichendimensionen,
            Nummer : LongInt);
var h,w : Integer;
    count : LongInt;
    d : TWeightPtr;
    i : ^Integer;
begin
     weight := TVector.Create;
     kinder := TList.create;
     eltern := TList.create;
     name := DEFAULT_NAME;
     frequency := 0;
     number := Nummer;

     err := 0.0;
     freq_ut := 0.0;
     err_vec := TVector.create;
     relerr_vec := TVector.create;
     selprob := 0.0;

     weight.setdim(Gewichtsdimensionen);

     valid := VALID_ID;
end;

destructor TNeuron.Done; {Die Routinen sind nur für den Fall jeweils}
var                      {eines Elternneurons geschrieben !}
   kc,i,ndx : LongInt;
   k,e : TNeuron;
begin
     kc := kinder.count;
     if kc > 0 then
     begin
          if eltern.count > 0 then {Kinder & Eltern}
          begin
               {Sich selbst aus der elterlichen Liste löschen}
               e := eltern.items[0];
               ndx:=e.kinder.indexof(self);
               e.kinder.delete(ndx);
               for i := 0 to kc-1 do
               begin
                    {Dem Kind neue Eltern geben.}
                    k := kinder.items[i];
                    k.eltern.items[0] := eltern.items[0];
                    {Die Eltern mit dem Kind bekanntmachen.}
                    e.kinder.add(k);
               end;
          end
          else
          begin      {nur Kinder}
               for i := 0 to kc-1 do
               begin
                    k := kinder.items[i];
                    k.eltern.delete(0);
               end;
          end;
     end
     else
     begin  {nur Eltern}
          if eltern.count > 0 then
          begin
               e:=eltern.items[0];
               ndx:=e.kinder.indexof(self);
               e.kinder.delete(ndx);
          end;
     end;
     weight.done;
end;


procedure TNeuron.writekoords (k : array of TWeight);
var i : LongInt;
    p : IntegerPtr;
    c : LongInt;
begin
     c := (high(k) - low(k)) + 1;{+1 da mindestens 1 Element !}

     for i := 1 to c do koords [i] := k[low(k)+(i-1)];

end;

procedure TNeuron.readkoords  (var k : array of TWeight);
var
   c : Integer;
begin
     for c := 1 to 3 do k[low(k)+(c-1)] := koords[c];
end;

procedure TNeuron.setweights (var k : array of TWeight);
var
   i : Longint;
begin
     {Stimmt die Dimensionalität ?}
     if (high(k)-low(k))+1 > weight.getdim then
        begin
             raise EGewichte_Bereichsverletzung.Create
                   ('An das Neuron übergebene Werte haben zuviele Dimensionen');
        end
     else
         begin

         end;
end;

procedure TNeuron.readweights (var k : array of TWeight);
begin
end;

function TNeuron.RandomNumber(min,max : TWeight) : TWeight;
var
   zahl : TWeight;
   range : real;
   vorkomma : LongInt;
   buffer : string;
begin
     range := max-min;
     zahl := 0.0;

     if range > 1.0 then
     begin
        buffer := floattostrf(range,fffixed,15,0);
        vorkomma := random(strtoint(buffer)); {Vorkommastellen}
        zahl := strtofloat(inttostr(vorkomma));
     end;

     zahl := zahl+random; {Nachkommastellen}

     zahl := zahl+min;
     RandomNumber := zahl;
end;

function TNeuron.getlev : LongInt; {Liefert den aktuellen Level des}
var                                {Neurons zurück}
   p : TNeuron;
   count : LongInt;
begin
     p := self;
     count := 0;
     while not(p.eltern.count = 0) do
     begin
          inc(count);
          p := p.eltern.items[0];
     end;
     result := count;
end;

function TNeuron.error(vec : TVector) : double;
var
   i,cc : LongInt;
   sum :double;
begin
     cc := vec.GetDim;
     sum := 0.0;

     for i := 1 to cc do
     begin
          sum := sum + sqr(vec.read(i)-weight.read(i))
     end;

     result := frequency * sum;
end;

procedure TNeuron.update(vec : TVector);
var
   alpha : double;
   i,cc : Longint;
   w : TWeight;
begin
     cc := vec.GetDim;

     for i := 1 to cc do
     begin
          w := weight.read(i) + ParamForm.alpha * (vec.read(i)-weight.read(i));
          weight.write(i,w);
     end;
end;

function TNeuron.ischild(n : TNeuron) : boolean; {Bin ich das Kind von n?}
var
   p : TNeuron;
   am_i : Boolean;
begin
     am_i := FALSE;
     p := self;

     while (not (p.eltern.count=0)) do
     begin
          p := p.eltern.items[0];
          if p = n then am_i := TRUE;
          if am_i then break;
     end;

     result := am_i;
end;

function TNeuron.save(F : TFileStream) : integer;
var
   o : ^TNeuron;
   j : LongInt;
   s : string;
begin
            s := char(13) + 'NEURON ' + inttostr(number) + char(13);
            F.write(s,sizeof(s));
            F.write(valid,sizeof(valid));
            F.write(weight,sizeof(weight));
            F.write(err,sizeof(err));
            F.write(freq_ut,sizeof(freq_ut));
            F.write(err_vec,sizeof(err_vec));
            F.write(relerr_vec,sizeof(relerr_vec));
            F.write(selprob,sizeof(selprob));

            {Kinder speichern}
            F.write(kinder.count,sizeof(kinder.count)); {Anzahl Kinder}
            for j := 0 to (kinder.count-1) do {Liste der Kindnummern}
            begin
                 o := kinder.items[j];
                 F.Write(o.number, sizeof(o.number));
            end;

            {Eltern speichern}
            F.write(eltern.count,sizeof(eltern.count)); {Anzahl Eltern}
            for j := 0 to (eltern.count-1) do {Liste der Elternnummern}
            begin
                 o := eltern.items[j];
                 F.Write(o.number, sizeof(o.number));
            end;

            F.write(koords,sizeof(koords));
            F.write(name,sizeof(name));
            F.write(level,sizeof(level));
            F.write(rwinkel,sizeof(rwinkel));
            F.write(frequency,sizeof(frequency));

            save:=0; {Kein Fehler}
end;


end.
