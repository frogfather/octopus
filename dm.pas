unit dm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, PQConnection, SQLDB, fpjson, jsonparser, dateutils;

type

  { Tdm1 }

  Tdm1 = class(TDataModule)
    pqConn: TPQConnection;
    sqlLookup: TSQLQuery;
    sqlAdd: TSQLQuery;
    sqlTrans: TSQLTransaction;
  private
    procedure  setParameterAndQuery(pName: string; pValue: TDateTime);
  public
    function saveFromJson(data: TJSONObject):integer;
  end;

var
  dm1: Tdm1;

implementation

{$R *.lfm}

{ Tdm1 }

procedure Tdm1.setParameterAndQuery(pName: string; pValue: TDateTime);
begin
  if (sqlLookup.Params.Count > 0) then
    begin
    sqlLookup.Params.ParamByName(pName).AsDateTime:=pValue;
    sqlLookup.ExecSQL;
    end;
end;

function Tdm1.saveFromJson(data: TJSONObject): integer;
var
  resultArray: TJSONArray;
  resultIndex: integer;
  resultItem: TJSONObject;
  validFrom,validTo: String;
  exVat, incVat: double;
  dValidFrom, dValidTo: TDatetime;
  recordCount: integer;
begin
  recordCount:=0;
  if(data.IndexOfName('results') > -1) and not (data.FindPath('results').IsNull) then
  //should be an array
    try
      resultArray:=data.Arrays['results'];
      sqlAdd.SQL.Text:='INSERT into tariff (valid_from, valid_to, ex_vat, inc_vat) values (:V_FROM, :V_TO, :EX_VAT, :INC_VAT)';
      for resultIndex := 0 to resultArray.Count -1 do
        begin
          resultItem:=TJSONObject(resultArray[resultIndex]);
          validFrom:=resultItem.Get('valid_from');
          validTo:=resultItem.Get('valid_to');
          exVat:= resultItem.Get('value_exc_vat');
          incVat:= resultItem.Get('value_inc_vat');
          TryISOStrToDateTime(validFrom, dValidFrom);
          TryISOStrToDateTime(validTo, dValidTo);
          sqlLookup.Active:=false;
          sqlLookup.SQL.Text:='SELECT * FROM tariff where valid_from = '''+formatDateTime('yyyy-mm-dd hh:nn:ss',dValidFrom)+'''';
          sqlLookup.Active:=true;
          if sqlLookup.recordCount = 0 then
            begin
            sqlAdd.params.ParamByName('V_FROM').AsDateTime:=dValidFrom;
            sqlAdd.params.ParamByName('V_TO').AsDateTime:=dValidTo;
            sqlAdd.params.ParamByName('EX_VAT').AsFloat :=exVat;
            sqlAdd.params.ParamByName('INC_VAT').AsFloat:=incVat;
            sqlAdd.ExecSQL;
            sqlTrans.Commit;
            recordCount:=recordCount+1;
            end;
        end;
    except
      on E: Exception do
      begin
        //something
      end;
    end;
    result:=recordCount;
end;

end.

