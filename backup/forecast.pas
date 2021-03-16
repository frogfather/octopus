unit forecast;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, entityUtils, dateUtils, sqlDB;
  {TForecast: Weather forecast data}
  type
  TForecast = class(TEntity)
  private
  FDate: TDateTime;
  FTemp: Double;
  FTempFeelsLike: Double;
  FTempMax: Double;
  FTempMin: Double;
  FPressure: Integer;
  FPressureSeaLevel: Integer;
  FPressureGroundLevel: Integer;
  FHumidity: Integer;
  FWeatherSummary: String;
  FWeatherDescription: String;
  FWeatherCloudPercent: integer;
  FWindSpeed: Double;
  FWindAngle: integer;
  FVisibility: integer;
  FPrecipitationProb: Double;
  FForecasted: TDateTime;
  public
    constructor Create; overload;
    constructor Create(forecastItem: TJSONObject); overload;
    destructor Destroy; override;
    function getFindSql:string; override;
    function writeToDatabase(sqlQuery: TSQLQuery):boolean; override;
  published
    property date: TDateTime read FDate;
    property temp: Double read Ftemp;
    property tempFeelsLike: Double read FTempFeelsLike;
    property tempMax: Double read FTempMax;
    property tempMin: Double read FTempMin;
    property pressure: integer read FPressure;
    property pressureSeaLevel: integer read FPressureSeaLevel;
    property pressureGroundLevel: integer read FPressureGroundLevel;
    property humidity: integer read FHumidity;
    property weatherSummary: string read FWeatherSummary;
    property weatherDescription: string read FWeatherDescription;
    property weatherCloudPercent: integer read FWeatherCloudPercent;
    property windSpeed: Double read FWindSpeed;
    property windAngle: integer read FWindAngle;
    property visibility: integer read FVisibility;
    property precipitaionProb: Double read FPrecipitationProb;
    property forecastDate: TDateTime read FForecasted;
  end;
implementation

{ TForecast }

constructor TForecast.Create;
begin

end;

constructor TForecast.Create(forecastItem: TJSONObject);
var
  main, clouds, wind: TJSONObject;
begin
  inherited Create(forecastItem);
  main:=forecastItem.Objects['main'];
  clouds:=forecastItem.Objects['clouds'];
  wind:=forecastItem.Objects['wind'];
  FDate:= unixToDateTime(forecastItem.Get('dt'));
  FTemp:= strToFloat(main.Get('temp'));
  FTempFeelsLike := strToFloat(main.get('feels_like'));
  FTempMax:=strToFloat(main.get('temp_max'));
  FTempMin:=strToFloat(main.get('temp_min'));
  FPressure:= strToInt(main.get('pressure'));
  if (main.IndexOfName('sea_level') > -1) and not (main.FindPath('sea_level').IsNull) then
  FPressureSeaLevel:=strToInt(main.get('sea_level'));
  if (main.IndexOfName('grnd_level') > -1) and not (main.FindPath('grnd_level').IsNull) then
  FPressureGroundLevel:=strToInt(main.get('grnd_level'));
  FHumidity:=strToInt(main.get('humidity'));
  //weather is an array of standard objects
  FVisibility:=strToInt(forecastItem.get('visibility'));
  if (forecastItem.IndexOfName('pop') > -1) and not (forecastItem.FindPath('pop').IsNull) then
  FPrecipitationProb:= strToFloat(forecastItem.get('pop'));
  if (forecastItem.IndexOfName('dt_txt') > -1) and not (forecastItem.FindPath('dt_txt').IsNull) then
  FForecasted:=strToDateTime(forecastItem.Get('dt_txt'));
  FWindSpeed:=strToFloat(wind.Get('speed'));
  FWindAngle:=strToInt(wind.get('deg'));
  FWeatherCloudPercent:=strToInt(clouds.get('all'));
end;

destructor TForecast.Destroy;
begin
  inherited Destroy;
end;

function TForecast.getFindSql: string;
begin
 result:='SELECT * FROM forecast where date_for = '''+formatDateTime('yyyy-mm-dd hh:nn:ss',FDate)+'''';
end;

function TForecast.writeToDatabase(sqlQuery: TSQLQuery): boolean;
begin
  try
    try
    sqlQuery.params.ParamByName('D_FOR').asDateTime:=FDate;
    sqlQuery.params.ParamByName('TMP').AsFloat:=Ftemp;
    sqlQuery.params.ParamByName('TMP_LK').asFloat:=FTempFeelsLike;
    sqlQuery.params.ParamByName('TMP_MIN').asFloat:=FTempMin;
    sqlQuery.params.ParamByName('TMP_MAX').asFloat:=FTempMax;
    sqlQuery.params.ParamByName('PRESS').asInteger:=FPressure;
    sqlQuery.params.ParamByName('PRESS_SEA').asInteger:=FPressureSeaLevel;
    sqlQuery.params.ParamByName('PRESS_GRND').asInteger:=FPressureGroundLevel;
    sqlQuery.params.ParamByName('HUM').asInteger:=FHumidity;
    sqlQuery.params.ParamByName('CLD').asInteger:=FWeatherCloudPercent;
    sqlQuery.params.ParamByName('WIND_SPD').asFloat:=FWindSpeed;
    sqlQuery.params.ParamByName('WIND_DEG').asInteger:=FWindAngle;
    sqlQuery.params.ParamByName('VIS').asInteger:=FVisibility;
    sqlQuery.params.ParamByName('PREC_PROP').asFloat:=FPrecipitationProb;
    sqlQuery.ExecSQL;
    result:=true;
    except
      on E: Exception do
      begin
        result:=false;
      end;
    end;
  finally
  end;
end;

end.







