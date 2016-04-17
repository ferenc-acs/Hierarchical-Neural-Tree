unit polaru;
{Diese Unit soll ein paar Tools zum Umgang mit Polarkoordinaten}
{zur Verfügung stellen. 2 Dimensionen sind ausreichend}
interface

type
    TDataformat = double; {Genauigkeit}

    {Ein Punkt im kartesischem Koordinatensystem}
    TRPoint = class
            x : TDataFormat; {Wert der Abszisse}
            y : TDataFormat; {Wert der Ordinate}
    end;

    {Ein Punkt im polaren Koordinatensystem}
    TPolar = class
          private
          function phidegread : TDataFormat;
          procedure phidegwrite (deg : TDataFormat);
          function xread : TDataFormat;
          function yread : TDataFormat;
          function xypointread : TRPoint;
          procedure xypointwrite (p : TRPoint);

          public
          phi   : TDataFormat; {0 < Winkel < Pi}
          rho : TDataFormat;   {Strecke}
          {Dies nur damit das Objekt auch mit dem (0-360)° System arbeiten kann}
          property phideg : TDataFormat read phidegread write phidegwrite;
          property x : TDataFormat read xread; {Abszissenwert}
          property y : TDataFormat read yread; {Ordinatenwert}
          property xypoint : TRPoint read xypointread write xypointwrite;
          procedure xyset (x,y : TDataFormat);
          function arcsin (val:TDataFormat) : TDataFormat;
    end;

implementation

function Tpolar.phidegread : TDataFormat;
begin
     {=pi/360*phi, führt aber zu genaueren Ergebnissen}
     result := pi * (phi*2) / 360;
end;

procedure Tpolar.phidegwrite (deg : TDataFormat);
begin

     phi := (360 * deg) / (pi*2)
end;

function Tpolar.xread : TDataFormat;
begin
     result := rho * cos(phi);
end;

function Tpolar.yread : TDataFormat;
begin
     result := rho * sin(phi);
end;

function Tpolar.xypointread : TRPoint;
begin
     result.x := rho * cos(phi);
     result.y := rho * sin(phi);
end;

procedure Tpolar.xypointwrite (p : TRPoint);
begin
     rho := sqrt(sqr(p.x)+sqr(p.y));
     if rho = 0.0 then
        phi := 0.0 {eigentlich phi -> unbestimmt, ist aber praktisch egal}
     else
        phi := arcsin(p.y/rho);
end;

function Tpolar.arcsin (val:TDataFormat) : TDataFormat;
var
   arg : TDataFormat;
begin
     arg := sqrt (1-sqr (val));
     if arg = 0.0 then
     begin
          arg := 0.00000000000001;
     end;
     result := ArcTan (val/arg);
end;

procedure Tpolar.xyset (x,y : TDataFormat);
begin
     rho := sqrt(sqr(x)+sqr(y));
     if rho = 0.0 then
     begin
        phi := 0.0; {eigentlich phi -> unbestimmt, ist aber praktisch egal}
     end
     else
     begin
        phi := arcsin(y/rho);
     end;
end;

end.
