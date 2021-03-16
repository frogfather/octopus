unit weather;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, forecast, dateUtils, sqlDB;
  {TWeather: Weather data}
  type
  TWeather = class(TForecast)
  private
  FSunrise: TDateTime;
  FSunset: TDateTime;
  FCity: String;
  FWindGust: Double;
  public
    constructor Create; overload;
    constructor Create(weatherItem: TJSONObject); overload;
    destructor Destroy; override;
    function getFindSql:string; override;
  published
    property sunrise: TDateTime read FSunrise;
    property sunset: TDateTime read FSunset;
    property city: string read FCity;
    property windGust: Double read FWindGust;
  end;
implementation

{ TForecast }

constructor TWeather.Create;
begin

end;

constructor TWeather.Create(weatherItem: TJSONObject);
var
  sys: TJSONObject;
  wind: TJSONObject;
begin
  inherited Create(weatherItem);
  sys:=weatherItem.Objects['sys'];
  wind:=weatherItem.Objects['wind'];
  FSunrise:= unixToDateTime(sys.Get('sunrise'));
  FSunset:= unixToDateTime(sys.Get('sunset'));
  FCity:=weatherItem.get('name');
  if (wind.IndexOfName('gust') > -1) and not (wind.FindPath('gust').IsNull) then
  FWindGust:=strToFloat(wind.Get('gust'));
end;

destructor TWeather.Destroy;
begin
  inherited Destroy;
end;

function TWeather.getFindSql: string;
begin
 //This is not persisted
  result:='';
end;


end.

