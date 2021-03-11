unit entityUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, fpjson, jsonparser, sqlDb;

{ IEntity }
  //This is the interface that all the entities implement
  type
  IEntity = interface
    ['{0C8F4C5D-1898-4F24-91DA-63F1DD66A692}']
    function getType: String;
    function getId: String;
    function getFindSql: String;
    function writeToDatabase(query: TSQLQuery):boolean;
  end;

type
  TIEntityList = specialize TFPGInterfacedObjectList<IEntity>;

type

  { TEntityListManager }
  //This contains an EntityList and handles adding, deleting and finding entities
  TEntityListManager = class
  strict private
    FAddSql: string;
    FEntities: TIEntityList;
  public
    constructor Create; overload;
    constructor Create(addSql: string);
    destructor Destroy; override;
    procedure AddEntity(const AEntity: IEntity);
    procedure RemoveEntity(const AEntity: IEntity);
    function FindByPosition(const Position: Integer): IEntity;
    function FindById(const id:String): IEntity;
    function FindPositionById(const id:String): integer;
    function Count: integer;
    property AddSql: string read FAddSql;
  end;

type

  { TEntity }

  TEntity = class(TInterfacedObject, IEntity)
  strict private
    FEntityType: string;
    FEntityId: String;
  public
    constructor create(const inputObject: TJSONObject); reintroduce;
    constructor create(sqlQuery: TSqlQuery);
    function getType: String;
    function getId: String;
    function writeToDatabase(sqlQuery: TSqlQuery): boolean; virtual; abstract;
    function getFindSql: string; virtual; abstract;
  end;

implementation

{ TEntity }

constructor TEntity.Create(const inputObject: TJSONObject);
begin
  FEntityId:=inputObject.get('entityId');
  FEntityType:=inputObject.get('entityType');
end;

constructor TEntity.Create(sqlQuery: TSqlQuery);
begin

end;

function TEntity.GetType: String;
begin
  result:=FEntityType;
end;

function TEntity.GetId: String;
begin
  result:=FEntityId;
end;


{ TEntityListManager }

constructor TEntityListManager.Create;
begin
  inherited Create;
  FEntities := TIEntityList.Create;
end;

constructor TEntityListManager.Create(addSql: string);
begin
  inherited Create;
  FEntities := TIEntityList.Create;
  FAddSql:=addSql;
end;

destructor TEntityListManager.Destroy;
begin
  inherited Destroy;
end;

procedure TEntityListManager.AddEntity(const AEntity: IEntity);
begin
  if (FindPositionById(AEntity.getId) = -1) then FEntities.Add(AEntity);
end;

procedure TEntityListManager.RemoveEntity(const AEntity: IEntity);
begin
  FEntities.Remove(AEntity);
end;

function TEntityListManager.FindByPosition(const Position: Integer): IEntity;
begin
  if (position >= FEntities.Count) or (position < 0) then result:=nil;
  result:=FEntities[position];
end;

function TEntityListManager.FindPositionById(const id: String): integer;
var
  index: Integer;
begin
  result:= -1;
  for index := 0 to FEntities.Count - 1 do
    begin
      if FEntities[index].getId = id then
        begin
        result:=index;
        exit;
        end;
    end;
end;

function TEntityListManager.Count: integer;
begin
  result:=FEntities.Count;
end;

function TEntityListManager.FindById(const id: String): IEntity;
var
  index, entityCount: Integer;
begin
  result:= nil;
  entityCount:=FEntities.Count;
  for index := 0 to entityCount - 1 do
    begin
      if FEntities[index].getId = id then
        begin
        result:=FEntities[index];
        exit;
        end;
    end;
end;


end.

