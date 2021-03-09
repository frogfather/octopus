unit octopus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, MaskEdit,
  EditBtn, ExtCtrls, fphttpclient, opensslsockets, fpjson, jsonparser, dm;

type

  TStringArray = Array of string;
  { ToctopusForm }

  ToctopusForm = class(TForm)
    bSave: TButton;
    bPoll: TButton;
    eapi: TEdit;
    eNextPoll: TEdit;
    lNextPoll: TLabel;
    lat: TLabel;
    lbResults: TListBox;
    lPoll: TLabel;
    tePoll: TTimeEdit;
    Timer1: TTimer;
    procedure bPollClick(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tePollEditingDone(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    function readStream(fnam: string): string;
    procedure writeStream(fnam: string; txt: string);
    procedure readSettings;
    procedure writeSettings;
    procedure pollAndSave(api: string);
    function queryApi(api: string):string;
  public

  end;

var
  octopusForm: ToctopusForm;
  fileName: string;
implementation

{$R *.lfm}

{ ToctopusForm }

procedure ToctopusForm.FormShow(Sender: TObject);

begin
  fileName:='/home/johncampbell/Documents/coding/object_pascal/octopus/octopus/settings.csv';
  readSettings;
end;

procedure ToctopusForm.bSaveClick(Sender: TObject);
begin
  writeSettings;
  timer1.Enabled:=true;
end;

procedure ToctopusForm.bPollClick(Sender: TObject);
begin
  pollAndSave(eapi.Text);
end;

procedure ToctopusForm.tePollEditingDone(Sender: TObject);
begin
  bSave.Enabled:= (tePoll.Text <> '') and (eapi.Text <> '');
end;

procedure ToctopusForm.Timer1Timer(Sender: TObject);
begin
  if (tePoll.Time = now) then
    begin
    eNextPoll.Text:='Polling';
    pollAndSave(eapi.Text);
    end else
    begin

    //eNextPoll.Text:=IntToStr(tePoll.time - );
    end;
end;

procedure ToctopusForm.readSettings;
var
  contents: string;
  lines: TStringArray;
begin
  if FileExists(fileName) then
  begin
    contents := readStream(fileName);
    //separate into array
    lines := contents.Split(#$0A);
    //get the poll time setting and the api setting
    if (length(lines) > 1) then
    try
      eapi.text := lines[1].split(',')[1];
      tePoll.Time:=StrToDateTime(lines[0].split(',')[1]);
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
  settings:= 'poll-time,'+apiPollString+#$0A+'url,'+eapi.text;
  writeStream(fileName, settings);
end;

procedure ToctopusForm.pollAndSave(api: string);
var
  results: String;
  jData : TJSONData;
  jObject : TJSONObject;
begin
  results:=queryApi(api);
  jData := GetJSON(results);
  jObject := TJSONObject(jData);
  dm1.saveFromJson(jObject);
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

