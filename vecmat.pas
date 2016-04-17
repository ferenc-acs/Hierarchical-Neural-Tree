unit vecmat;

interface

uses
    classes,graphics,extctrls,neuron_e;


const
     VALID_ID : Integer = 4321;


type

  TWeight = double;
  TWeightPtr = ^double;
{---------------------------------------------------------------}
{                      TVector Klasse                           }
{---------------------------------------------------------------}

{Gültige Vektorindizes sind 1 bis Max(LongInt) -> 2147483647) }

  TVectorPtr = ^TVector;
  TVector = class
  private
        Element : TList;


  public
        valid : Integer;   {Prüfvariable für das Objekt -> VALID_ID}

        constructor Create;
        destructor Done;
        function read (index:LongInt) : TWeight;
        procedure  read_all (var weights : array of TWeight);
        procedure write (index:LongInt; weight:TWeight);
        procedure write_all (weights : array of TWeight);
        function GetDim : LongInt;
        procedure SetDim (dim:LongInt); {Verändert die Dimensionalität}
        procedure Clean;
        procedure plus(b : TVector; var erg : TVector);
        procedure minus(b : TVector; var erg : TVector);
        function skalar(b : TVector) : TWeight;
        procedure mult(b : TWeight; var erg : TVector);
  end;



implementation


{**********************************************************************}
{                            TVector Implementation                    }
{**********************************************************************}

constructor TVector.Create;
begin
     Element := TList.Create;
     valid := VALID_ID;
end;

destructor TVector.done;
var
   w : TWeight;
begin
     while Element.count > 0 do
     begin
          dispose(TWeightPtr(Element.items[0]));
          Element.delete(0);
     end;
end;

function TVector.GetDim : LongInt;
begin
     GetDim := Element.Count;
end;

procedure TVector.Clean;
begin
     Element.clear;
end;

function TVector.read (index:LongInt) : TWeight;
begin
     if (index > GetDim) or (index < 1) then
        raise EGewichte_Bereichsverletzung.create
              ('Bereichsverletzung beim Lesezugriff auf Elemente')
        else
        begin
             index := index - 1; {Auf das Listenformat bringen}
             result := TWeightPtr(Element.items[index])^
        end;
end;

procedure  TVector.read_all (var weights : array of TWeight);
var
   count : LongInt;
   i : LongInt;
   lo : LongInt;
begin
     count := GetDim;
     lo := low(weights);
     if ((high(weights)-lo)+1) <> count then
        raise EGewichte_Bereichsverletzung.create
              ('Falsche Dimensionalität beim Vector lesezugriff')
        else
     begin
          for i := 0 to count do
          begin
               weights[lo+i] := TWeightPtr(Element.Items[i])^;
          end;
     end;
end;


procedure TVector.write (index:LongInt; weight:TWeight);
var
   erg : TWeight;
begin
     if index > GetDim then
        raise EGewichte_Bereichsverletzung.create
              ('Falsche Dimensionalität beim Vector schreibzugriff')
        else
        begin
             index := index-1; {Auf das Listenformat}
             TWeightPtr(Element.Items[index])^ := weight;
        end;
end;


procedure TVector.write_all (weights : array of TWeight);
var
   count,i,x,lo : LongInt;
begin
     {Alte Liste aus dem Speicher entfernen}
     while Element.count > 0 do
     begin
          dispose(TWeightPtr(Element.items[0]));
          Element.delete(0);
     end;

     {Neue Liste schreiben}
     lo := low(weights);
     count := high(weights) - lo;
     for i := 0 to count-1 do
     begin
          x := Element.Add(new(TWeightPtr));
          TWeightPtr(Element.Items[x])^ := weights[lo+i];
     end;
end;

procedure TVector.setdim (dim : LongInt);
var
   diff,i,x,cnt : LongInt;
begin
     cnt := Element.count;
     if dim < 1 then dim := cnt; {Nichts verändern, da Unsinn}

     if dim > cnt then
     begin
          diff := dim-cnt;
          for i := 1 to diff do
          begin
               x := Element.Add(new(TWeightPtr));
               TWeightPtr(Element.Items[x])^ := 0.0; {Neue Elemente init.}
          end;
     end; {dim > count}

     if dim < cnt then {Die letzten Elemente werden gelöscht}
     begin
          diff := cnt-dim;
          for i := 1 to diff do
          begin
               dispose(TWeightPtr(Element.Items[Element.count-1]));
               element.delete(Element.count-1);
          end;
     end; {dim < count}
end;

procedure TVector.plus(b : TVector; var erg : TVector);
var
   i,dim : LongInt;
   sum : TWeight;
begin
     dim := b.getdim;
     erg.setdim(dim);

     for i := 1 to dim do
     begin
          sum := self.read(i) + b.read(i);
          erg.write(i,sum);
     end;
end;

procedure TVector.minus(b : TVector; var erg : TVector) ;
var
   i,dim : LongInt;
begin
     dim := b.getdim;
     erg.setdim(dim);

     for i := 1 to dim do
     begin
          erg.write(i, self.read(i) - b.read(i));
     end;
end;

function TVector.skalar(b : TVector) : TWeight;
var
   i,dim : LongInt;
   erg : TWeight;
begin
     erg := 0.0;
     dim := b.getdim;

     for i := 1 to dim do
     begin
          erg := erg+(self.read(i) * b.read(i));
     end;

     result := erg;
end;

procedure TVector.mult(b : TWeight; var erg : TVector);
var
   i,dim : LongInt;
   mul : TWeight;
begin
     dim := getdim;
     erg.setdim(dim);

     for i := 1 to dim do
     begin
          mul := self.read(i) * b;
          erg.write(i,mul);
     end
end;


end.
