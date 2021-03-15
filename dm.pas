unit dm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, PQConnection, SQLDB, DB, fpjson, jsonparser, dateutils,
  entityUtils, tariff;

type

  { Tdm1 }

  Tdm1 = class(TDataModule)
    dsForecast: TDataSource;
    pqConn: TPQConnection;
    sqlLookup: TSQLQuery;
    sqlAdd: TSQLQuery;
    sqlForecast: TSQLQuery;
    sqlTrans: TSQLTransaction;
  private

  public
    procedure getTariffData(em: TEntityListManager);
    function saveData(manager: TEntityListManager):integer;
    procedure displayForecast(dDate: TDateTime);
  end;

var
  dm1: Tdm1;

implementation

{$R *.lfm}

{ Tdm1 }

procedure Tdm1.getTariffData(em: TEntityListManager);
var
  startTime: TDateTime;
  sqlRender:TSqlQuery;
  newTariff: TTariff;
begin
  startTime:=now;
  incHour(startTime,-1);
  sqlRender:=TSqlQuery.Create(self);
  sqlRender.DataBase:=pqConn;
  sqlRender.Transaction:=sqlTrans;
  sqlRender.SQL.Text:='SELECT * FROM tariff where valid_from > '''+formatDateTime('yyyy-mm-dd hh:nn:ss',startTime)+''' order by valid_from';
  sqlRender.Active:=true;
  sqlRender.First;
  while not sqlRender.EOF do
    begin
    //create a new tariff entity for each
    newTariff:=TTariff.Create(sqlRender);
    newTariff.setId(sqlRender.FieldByName('id').AsAnsiString);
    newTariff.setType('TTariff');
    em.AddEntity(newTariff);
    sqlRender.Next;
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

procedure Tdm1.displayForecast(dDate:TDateTime);
begin
  sqlForecast.Active:=false;
  sqlForecast.SQL.Text:='SELECT * FROM forecast where date_for > '''+formatDateTime('yyyy-mm-dd hh:nn:ss', dDate)+'''';
  sqlForecast.Active:=true;
end;

end.

