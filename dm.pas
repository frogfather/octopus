unit dm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, PQConnection, SQLDB, fpjson, jsonparser, dateutils, entityUtils;

type

  { Tdm1 }

  Tdm1 = class(TDataModule)
    pqConn: TPQConnection;
    sqlLookup: TSQLQuery;
    sqlAdd: TSQLQuery;
    sqlTrans: TSQLTransaction;
  private
    procedure setParameterAndQuery(pName: string; pValue: TDateTime);
  public
    function saveData(manager: TEntityListManager):integer;
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

function Tdm1.saveData(manager: TEntityListManager):integer;
var
  recordCount: Integer;
  entity: IEntity;
  index:Integer;
begin
  recordCount:=0;
  sqlAdd.SQL.Text:=manager.AddSql;
  for index := 0 to manager.Count -1 do
    begin
      entity:=manager.findByPosition(index);
      //look for the item
      sqlLookup.Active:=false;
      sqlLookup.SQL.Text:=entity.getFindSql;
      sqlLookup.Active:=true;
      if sqlLookup.recordCount = 0 then
        begin
        entity.writeToDatabase(sqlAdd);
        recordCount:=recordCount+1;
        sqlTrans.Commit;
        end;
    end;
  result:=recordCount;
end;

end.

