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
    constructor Create(query:TSqlQuery); overload;
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
  //create from a JSON object
  inherited Create(tariffItem);
  TryISOStrToDateTime(tariffItem.get('valid_from'), dValidFrom);
  TryISOStrToDateTime(tariffItem.get('valid_to'), dValidTo);
  FValidFrom:=dValidFrom;
  FValidTo:=dValidTo;
  FExVat:=strToFloat(tariffItem.get('value_exc_vat'));
  FIncVat:=strToFloat(tariffItem.get('value_inc_vat'));
end;

constructor TTariff.Create(query: TSqlQuery);
begin
  //create new entity from queryData
  if (query.RecordCount > 0) then
  begin
    FValidFrom:=query.FieldByName('valid_from').AsDateTime;
    FValidTo:=query.FieldByName('valid_to').AsDateTime;
    FExVat:=query.FieldByName('ex_vat').AsFloat;
    FIncVat:=query.FieldByName('inc_vat').AsFloat;
  end;
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
  try
    try
    sqlQuery.params.ParamByName('V_FROM').AsDateTime:=FValidFrom;
    sqlQuery.params.ParamByName('V_TO').AsDateTime:=FValidTo;
    sqlQuery.params.ParamByName('EX_VAT').AsFloat :=FexVat;
    sqlQuery.params.ParamByName('INC_VAT').AsFloat:=FincVat;
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

