unit mmUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

function priceToYPos(price, priceMin, priceMax, stepHeight: double): integer;
begin
  result := round((price - PriceMin)/(PriceMax - priceMin) * (10 * StepHeight));
end;
implementation

end.

