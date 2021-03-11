unit tariff;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, entityUtils, dateUtils, sqlDB;
{TTariff - represents tariff data}
type
  TTariff = class(TEntity)
  private
    FValidFrom: TDateTime;
    FValidTo: TDateTime;
    FExVat: Double;
    FIncVat: Double;
  public
    constructor Create; overload;
    constructor Create(tariffItem: TJSONObject); overload;
    destructor Destroy; override;
    function getFindSql:string; override;
    function writeToDatabase(sqlQuery: TSQLQuery):boolean; override;
  published
    property ValidFrom: TDateTime read FValidFrom write FValidFrom;
    property ValidTo: TDateTime read FValidTo write FValidTo;
    property ExVat: Double read FExVat write FExVat;
    property IncVat: Double read FIncVat write FIncVat;
  end;

implementation

constructor TTariff.Create;
begin
  inherited;
  end;

constructor TTariff.Create(tariffItem: TJSONObject);
var
  dValidFrom,dValidTo: TDateTime;
begin
  inherited Create(tariffItem);
  TryISOStrToDateTime(tariffItem.get('valid_from'), dValidFrom);
  TryISOStrToDateTime(tariffItem.get('valid_to'), dValidTo);
  FValidFrom:=dValidFrom;
  FValidTo:=dValidTo;
  FExVat:=strToFloat(tariffItem.get('value_exc_vat'));
  FIncVat:=strToFloat(tariffItem.get('value_inc_vat'));
end;

destructor TTariff.Destroy;
begin

end;

function TTariff.getFindSql: string;
begin
  result:='SELECT * FROM tariff where valid_from = '''+formatDateTime('yyyy-mm-dd hh:nn:ss',FValidFrom)+'''';
end;

function TTariff.writeToDatabase(sqlQuery: TSQLQuery): boolean;
begin
  sqlQuery.params.ParamByName('V_FROM').AsDateTime:=FValidFrom;
  sqlQuery.params.ParamByName('V_TO').AsDateTime:=FValidTo;
  sqlQuery.params.ParamByName('EX_VAT').AsFloat :=FexVat;
  sqlQuery.params.ParamByName('INC_VAT').AsFloat:=FincVat;
  sqlQuery.ExecSQL;
end;



end.

