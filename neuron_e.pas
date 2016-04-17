unit Neuron_e;

interface

uses SysUtils;

type

EGewichte_Bereichsverletzung = class (exception)
end;

EVector_Bereichsverletzung = class (exception)
end;

EVector_Rechenfehler = class(exception)
end;


{Sollte eine 'Object as TNeuron' oder 'ObjectPtr as TNeuronPtr' Operation}
{den Wert false zurückgeben, sollte diese Exception verwendet werden.}
ENeuron_defekt = class (exception)
end;

implementation

end.
