unit octopus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, MaskEdit,
  EditBtn, fphttpclient, opensslsockets;

type

  TStringArray = Array of string;
  { ToctopusForm }

  ToctopusForm = class(TForm)
    bSave: TButton;
    bPoll: TButton;
    eapi: TEdit;
    lat: TLabel;
    lbResults: TListBox;
    lPoll: TLabel;
    tePoll: TTimeEdit;
    procedure bPollClick(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tePollEditingDone(Sender: TObject);
  private
    function readStream(fnam: string): string;
    procedure writeStream(fnam: string; txt: string);
    procedure readSettings;
    procedure writeSettings;
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
  fileName:='/Users/cloudsoft/Code/octopus/settings.csv';
  readSettings;
end;

procedure ToctopusForm.bSaveClick(Sender: TObject);
begin
  writeSettings;
end;

procedure ToctopusForm.bPollClick(Sender: TObject);
begin
  lbresults.Items.add(queryApi(eapi.text));
end;

procedure ToctopusForm.tePollEditingDone(Sender: TObject);
begin
  bSave.Enabled:= (tePoll.Text <> '') and (eapi.Text <> '');
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

function ToctopusForm.queryApi(api: string): string;
Var S    : string;
  HTTP : TFPHttpClient;
begin
  result:='';
  HTTP := TFPHttpClient.Create(nil);
  HTTP.AllowRedirect:=True;
  HTTPClient.AddHeader('User-Agent', 'Mozilla/5.0 (compatible; fpweb)');
  HTTPClient.AddHeader('Content-Type', 'application/json');
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

