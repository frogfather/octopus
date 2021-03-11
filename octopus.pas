unit octopus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, MaskEdit,
  EditBtn, ExtCtrls, fphttpclient, opensslsockets, fpjson, jsonparser, dm, dateutils, entityUtils, tariff;

type
  TariffEM = TEntityListManager;
  TStringArray = Array of string;
  { ToctopusForm }

  ToctopusForm = class(TForm)
    bSave: TButton;
    bPoll: TButton;
    eOpenWeatherCity: TEdit;
    eOctopusApi: TEdit;
    eNextPoll: TEdit;
    eOpenWeatherApi: TEdit;
    eOpenWeatherApiKey: TEdit;
    lOpenWeatherApi: TLabel;
    lOpenWeatherCity: TLabel;
    lOpenWeatherApiKey: TLabel;
    lat: TLabel;
    lbResults: TListBox;
    lPoll: TLabel;
    tePoll: TTimeEdit;
    Timer1: TTimer;
    procedure bPollClick(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tePollEditingDone(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    function readStream(fnam: string): string;
    procedure writeStream(fnam: string; txt: string);
    procedure readSettings;
    procedure writeSettings;
    procedure pollAndSave;
    function queryApi(api: string):string;
    procedure processOctopusData(data: TJSONObject);
    function getOctopusAgile: string;
    function getOpenWeatherCurrent: string;
    function getOpenWeatherForecast: string;
  public

  end;

var
  octopusForm: ToctopusForm;
  fileName: string;
  tariffs: TariffEM;
implementation

{$R *.lfm}

{ ToctopusForm }

procedure ToctopusForm.FormShow(Sender: TObject);
begin
  fileName:='/Users/cloudsoft/Code/octopus/settings.csv';
  readSettings;
end;

procedure ToctopusForm.bSaveClick(Sender: TObject);
begin
  writeSettings;
  timer1.Enabled:=true;
end;

procedure ToctopusForm.FormCreate(Sender: TObject);
begin
  DefaultFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  Tariffs := TariffEM.create;
end;

procedure ToctopusForm.bPollClick(Sender: TObject);
begin
  pollAndSave;
end;

procedure ToctopusForm.tePollEditingDone(Sender: TObject);
begin
  bSave.Enabled:= (tePoll.Text <> '') and (eOctopusApi.Text <> '');
end;

procedure ToctopusForm.Timer1Timer(Sender: TObject);
var
  secondsUntilPoll:integer;
  nextPollTime,timeUntilPoll: TDatetime;

begin
  //if the poll time is before timeof now add a day to it
  if (timeOf(now) > tePoll.time) then nextPollTime:= incDay(tePoll.time) else nextPollTime:=tePoll.time;
  secondsUntilPoll:=secondsBetween(nextPollTime, timeOf(now));
  timeUntilPoll := nextPollTime - timeOf(now);
  enextpoll.text:='Next poll in '+formatDateTime('hh:nn:ss', timeUntilPoll);
  if (timer1.Enabled) then enextpoll.Color:=clLime else enextpoll.Color:=cldefault;
  if (secondsUntilPoll = 0) then
    begin
    eNextPoll.Text:='Polling';
    pollAndSave;
    end;
end;

procedure ToctopusForm.readSettings;
var
  contents: string;
  lines: TStringArray;
  lineNo:integer;
  key,value:string;
begin
  if FileExists(fileName) then
  begin
    contents := readStream(fileName);
    //separate into array
    lines := contents.Split(#$0A);
    //get the poll time setting and the api setting
    if (length(lines) > 1) then
    try
      for lineNo := 0 to length(lines)-1 do
        begin
        key:=lines[lineNo].split(',')[0];
        value:=lines[lineNo].split(',')[1];
          case key of
          'poll-time': tePoll.time:=strToDateTime(value);
          'octopus-api': eOctopusApi.Text:=value;
          'open-weather-api': eOpenWeatherApi.Text:=value;
          'open-weather-city': eOpenWeatherCity.Text:=value;
          'open-weather-api-key': eOpenWeatherApiKey.Text:=value;
          end;
        end;
      //TODO check it's a valid url rather than just checking if it's not empty
      timer1.Enabled:=(length(eOctopusApi.text) > 0) or (length(eOpenWeatherApi.Text)> 0);
    except
      on e: Exception do messagedlg('','Oops '+e.Message, mtError, [mbOK],'');
    end;
  end;
end;

procedure ToctopusForm.writeSettings;
var
  apiPollString: string;
  settings: string;
begin
  try
    apiPollString:=formatDateTime('hh:nn:ss',tePoll.Time);
  except
    apiPollString:=formatDateTime('hh:nn:ss',now);
  end;
  settings:= 'poll-time,'+apiPollString
  +#$0A+'octopus-api,'+eOctopusApi.text
  +#$0A+'open-weather-api,'+eOpenWeatherApi.text
  +#$0A+'open-weather-city,'+eOpenWeatherCity.text
  +#$0A+'open-weather-api-key,'+eOpenWeatherApiKey.text;
  writeStream(fileName, settings);
end;

procedure ToctopusForm.pollAndSave;
var
  results: String;
  jData : TJSONData;
  jObject : TJSONObject;
begin
  //Get Octopus data first
  results:=getOctopusAgile;
  jData := GetJSON(results);
  jObject := TJSONObject(jData);
  processOctopusData(jObject);
  //Open weather current

  results:=getOpenWeatherCurrent;
  //Open weather forecast

  results:=getOpenWeatherForecast;
end;

function ToctopusForm.queryApi(api: string): string;
Var S    : string;
  HTTP : TFPHttpClient;
begin
  result:='';
  HTTP := TFPHttpClient.Create(nil);
  HTTP.AllowRedirect:=True;
  HTTP.AddHeader('User-Agent', 'Mozilla/5.0 (compatible; fpweb)');
  HTTP.AddHeader('Content-Type', 'application/json');
  try
    S := HTTP.Get(api);
    writeln(s);
    result:=s;
  finally
    http.free;
  end;

end;

procedure ToctopusForm.processOctopusData(data: TJSONObject);
var
  jTariffItem:TJSONObject;
  resultArray: TJSONArray;
  resultIndex: Integer;
  id: TGUID;
  newTariff:TTariff;
begin
  resultArray:=data.Arrays['results'];
  for resultIndex := 0 to resultArray.Count - 1 do
    begin
    createGuid(id);
    jTariffItem := TJSONObject(resultArray[resultIndex]);
    jTariffItem.Add('entityId', GuidToString(id));
    JTariffItem.Add('entityType','TTariff');
    newTariff:=TTariff.create(jTariffItem);
    tariffs.AddEntity(newTariff);
    end;
  lbresults.items.add('Added '+inttostr(dm1.saveFromJson(data))+' records');
end;

function ToctopusForm.getOctopusAgile: string;
begin
  result:= queryApi(eOctopusApi.Text);
end;

function ToctopusForm.getOpenWeatherCurrent: string;
begin
  result:= queryApi(eOpenWeatherApi.text+'weather?q='+eOpenWeatherCity.text+'&appid='+eOpenWeatherApiKey.text);
end;

function ToctopusForm.getOpenWeatherForecast: string;
begin
  result:= queryApi(eOpenWeatherApi.text+'forecast?q='+eOpenWeatherCity.text+'&appid='+eOpenWeatherApiKey.text);
end;

function ToctopusForm.readStream(fnam: string): string;
var
  strm: TFileStream;
  n: longint;
  txt: string;
  begin
    txt := '';
    strm := TFileStream.Create(fnam, fmOpenRead);
    try
      n := strm.Size;
      SetLength(txt, n);
      strm.Read(txt[1], n);
    finally
      strm.Free;
    end;
    result := txt;
  end;

procedure ToctopusForm.writeStream(fnam: string; txt: string);
var
  strm: TFileStream;
  n: longint;
begin
  try
    strm := TFileStream.Create(fnam, fmCreate);
    n := Length(txt);
    strm.Position := 0;
    strm.Write(txt[1], n);
  finally
    strm.Free;
  end;
end;

end.

