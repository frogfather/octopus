unit octopus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, MaskEdit,
  EditBtn, ExtCtrls, ComCtrls, DBGrids, fphttpclient, opensslsockets, fpjson,
  jsonparser, dm, dateutils, entityUtils, tariff, forecast, weather, fileUtil;

type
  TariffEM = TEntityListManager;
  ForecastEM = TEntityListManager;
  { ToctopusForm }

  ToctopusForm = class(TForm)
    bPoll: TButton;
    bSave: TButton;
    ckTariff: TCheckBox;
    ckForecast: TCheckBox;
    ckWeather: TCheckBox;
    DBGrid1: TDBGrid;
    eNextPoll: TEdit;
    eOctopusApi: TEdit;
    eOpenWeatherApi: TEdit;
    eOpenWeatherApiKey: TEdit;
    eOpenWeatherCity: TEdit;
    ePollInterval: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lFeelsLike: TLabel;
    lSunset: TLabel;
    lForecastTime: TLabel;
    lTimeNow: TLabel;
    lVisibility: TLabel;
    lPressure: TLabel;
    lHumidity: TLabel;
    lCloud: TLabel;
    lSunrise: TLabel;
    lWindDegrees: TLabel;
    lWindGust: TLabel;
    lWind: TLabel;
    lTempMin: TLabel;
    lHeadline: TLabel;
    lSummary: TLabel;
    lGeneral: TLabel;
    lat: TLabel;
    lbResults: TListBox;
    lDescription: TLabel;
    lTemperature: TLabel;
    lTempMax: TLabel;
    lWeatherPollMinutes: TLabel;
    lWeatherPoll: TLabel;
    lOpenWeatherApi: TLabel;
    lOpenWeatherApiKey: TLabel;
    lOpenWeatherCity: TLabel;
    lPoll: TLabel;
    pbTariff: TPaintBox;
    pOtherData: TPanel;
    pHeadline: TPanel;
    pCurrentWeather: TPanel;
    pTimers: TPanel;
    pWeatherSub: TPanel;
    pTariffSettings: TPanel;
    PWeatherSettings: TPanel;
    pDisplay: TPageControl;
    PWeather: TTabSheet;
    PSettings: TTabSheet;
    PForecast: TTabSheet;
    PTariff: TTabSheet;
    MainTimer: TTimer;
    PLog: TTabSheet;
    tePoll: TTimeEdit;
    WeatherTimer: TTimer;
    procedure bPollClick(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure ckWeatherChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pbTariffPaint(Sender: TObject);
    procedure PForecastShow(Sender: TObject);
    procedure tePollEditingDone(Sender: TObject);
    procedure MainTimerTimer(Sender: TObject);
    procedure WeatherTimerTimer(Sender: TObject);
  private
    function readStream(fnam: string): string;
    procedure writeStream(fnam: string; txt: string);
    procedure readSettings;
    procedure writeSettings;
    procedure pollAndSave;
    function queryApi(api: string):string;
    procedure processOctopusData(data: TJSONObject);
    procedure processOpenWeatherForecastData(data: TJSONObject);
    procedure processOpenWeatherCurrentData(data: TJSONObject);
    procedure updateCurrentWeatherDisplay;
    procedure getCurrentWeather;
    procedure getTodaysTariffs(em: TEntityListManager);
    procedure renderTodaysTariffs;
    procedure emptyManager(manager: TEntityListManager);
    function getOctopusAgile: string;
    function getOpenWeatherCurrent: string;
    function getOpenWeatherForecast: string;
    function stringToJSON(input: string):TJSONObject;
    function priceToYPos(price, priceMin, priceMax, stepHeight: double): integer;
    function findDirectories(path:string):TStringlist;
    function getUserDir:string;
  public

  end;

var
  octopusForm: ToctopusForm;
  fileName: string;
  tariffs: TariffEM;
  forecasts: ForecastEM;
  tariffRender: TariffEM;
  currentWeather: TWeather;
implementation

{$R *.lfm}

{ ToctopusForm }

procedure ToctopusForm.FormShow(Sender: TObject);
var
  userDir:string;
begin
  userDir:=getUserDir;
  fileName:=userDir+'/.octopus.csv';
  readSettings;
  getCurrentWeather;
end;

//This complete mess is required because getUserDir on MacOS Catalina returns '/'
function ToctopusForm.getUserDir: string;
var
  userDir:string;
  directoryList:TStringlist;
  index:integer;
begin
  directoryList:=TStringlist.create;
  userDir:=getCurrentDir;
  if (userDir <> '/') then result:=userDir else
    begin
     directoryList:= findDIrectories('/');
     if (directoryList.IndexOf('Users') > -1) then
       chdir('Users');
       directoryList:=findDirectories('Users/');
       if (directoryList.IndexOf('Shared') > -1) then directoryList.Delete(directorylist.IndexOf('Shared'));
       //now if we have one user we can select it, otherwise we need to ask
       if (directoryList.Count = 1) then userDir := directoryList[0] else
         for index:=0 to directoryList.count -1 do
         begin
         if (messagedlg('','Are you user '+directoryList[index],mtConfirmation,[mbYes,mbNo],'') = mrYes) then
           begin
             userDir:= directoryList[index];
             exit;
           end;
         end;
       result:='/Users/'+userDir;
    end;

end;


function ToctopusForm.findDirectories(path:string):TStringlist;
Var Info : TSearchRec;
    Count : Longint;
begin
result:=TStringlist.Create;
Count:=0;
  If FindFirst ('*',faAnyFile and faDirectory,Info)=0 then
    begin
    Repeat
      Inc(Count);
      With Info do
        begin
        If ((Attr and faDirectory) = faDirectory) and (Name <> '.') and (Name <> '..')  then
          result.Add(Name);
        end;
    Until FindNext(info)<>0;
    end;
  FindClose(Info);

end;


procedure ToctopusForm.pbTariffPaint(Sender: TObject);
begin
  emptyManager(tariffRender);
  getTodaysTariffs(tariffRender);
  renderTodaysTariffs;
end;

procedure ToctopusForm.PForecastShow(Sender: TObject);

begin
  dm1.displayForecast(now);
end;

procedure ToctopusForm.bSaveClick(Sender: TObject);
begin
  try
  writeSettings;
  MainTimer.Enabled:=true;
  WeatherTimer.Interval:=(strToInt(epollInterval.text)*60000);
  WeatherTimer.Enabled:=ckWeather.Enabled;
  Messagedlg('','Settings saved',mtInformation,[mbOK],'');
  except
  Messagedlg('','Error saving settings',mtError,[mbOK],'');
  end;
end;

procedure ToctopusForm.ckWeatherChange(Sender: TObject);
begin
  pWeatherSub.Visible:=ckWeather.Checked;
  WeatherTimer.Enabled:=ckWeather.checked;
end;

procedure ToctopusForm.FormCreate(Sender: TObject);
begin
  DefaultFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  Tariffs := TariffEM.create('INSERT into tariff (valid_from, valid_to, ex_vat, inc_vat) values (:V_FROM, :V_TO, :EX_VAT, :INC_VAT)');
  Forecasts := ForecastEM.Create('INSERT into forecast (date_for, temp, temp_like, temp_min, temp_max, pressure, pressure_sea, pressure_ground, humidity, cloud, wind_speed, wind_degrees, visibility, precip_prob) values (:D_FOR, :TMP, :TMP_LK, :TMP_MIN, :TMP_MAX, :PRESS, :PRESS_SEA, :PRESS_GRND, :HUM, :CLD, :WIND_SPD, :WIND_DEG, :VIS, :PREC_PROP)');
  TariffRender:= TariffEM.Create;
end;

procedure ToctopusForm.bPollClick(Sender: TObject);
begin
  pollAndSave;
end;

procedure ToctopusForm.tePollEditingDone(Sender: TObject);
begin
  bSave.Enabled:= (tePoll.Text <> '') and (eOctopusApi.Text <> '');
end;

procedure ToctopusForm.MainTimerTimer(Sender: TObject);
var
  secondsUntilPoll:integer;
  nextPollTime,timeUntilPoll: TDatetime;

begin
  //if the poll time is before timeof now add a day to it
  lTimeNow.Caption:='Time now: '+formatDateTime('ddd dd mmm yyyy hh:nn:ss',now);
  if (timeOf(now) > tePoll.time) then nextPollTime:= incDay(tePoll.time) else nextPollTime:=tePoll.time;
  secondsUntilPoll:=secondsBetween(nextPollTime, timeOf(now));
  timeUntilPoll := nextPollTime - timeOf(now);
  enextpoll.text:='Next poll in '+formatDateTime('hh:nn:ss', timeUntilPoll);
  if (MainTimer.Enabled) then enextpoll.Color:=clLime else enextpoll.Color:=cldefault;
  if (secondsUntilPoll = 0) then
    begin
    eNextPoll.Text:='Polling';
    pollAndSave;
    end;
end;

procedure ToctopusForm.WeatherTimerTimer(Sender: TObject);
begin
  getCurrentWeather;
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
          'tariff-enabled': ckTariff.checked:=strToBool(value);
          'forecast-enabled': ckWeather.Checked:=strToBool(value);
          'weather-enabled': ckWeather.Enabled:=strToBool(value);
          'weather-poll-interval': epollInterval.Text:=value;
          end;
        end;
      //TODO check it's a valid url rather than just checking if it's not empty
      if (epollinterval.Text = '') then epollInterval.Text:='5';
      MainTimer.Enabled:=(length(eOctopusApi.text) > 0) or (length(eOpenWeatherApi.Text)> 0);
      WeatherTimer.Interval:=(strToInt(epollInterval.text)*60000);
      WeatherTimer.Enabled:=ckWeather.Enabled;
    except
      on e: Exception do messagedlg('','Error loading settings '+e.Message, mtError, [mbOK],'');
    end;
  end else
  begin
  mainTimer.Enabled:=false;
  weatherTimer.Enabled:=false;
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
  +#$0A+'open-weather-api-key,'+eOpenWeatherApiKey.text
  +#$0A+'tariff-enabled,'+BoolToStr(ckTariff.checked)
  +#$0A+'forecast-enabled,'+BoolToStr(ckForecast.checked)
  +#$0A+'weather-enabled,'+BoolToStr(ckWeather.checked)
  +#$0A+'weather-poll-interval,'+epollInterval.Text;
  writeStream(fileName, settings);
end;

procedure ToctopusForm.pollAndSave;
begin
  //Get Octopus data first
  if (ckTariff.checked) then processOctopusData(stringToJSON(getOctopusAgile));
  //Open weather forecast
  if (ckForecast.checked) then processOpenWeatherForecastData(stringToJSON(getOpenWeatherForecast));
end;

function ToctopusForm.queryApi(api: string): string;
Var
  HTTP : TFPHttpClient;
begin
  result:='';
  HTTP := TFPHttpClient.Create(nil);
  HTTP.AllowRedirect:=True;
  HTTP.AddHeader('User-Agent', 'Mozilla/5.0 (compatible; fpweb)');
  HTTP.AddHeader('Content-Type', 'application/json');
  try
    result:=HTTP.Get(api);
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
  lbresults.items.add('['+formatDateTime('yyyy-mm-dd hh:nn:ss', now)+'] Added '+inttostr(dm1.saveData(tariffs))+' records');
end;

procedure ToctopusForm.processOpenWeatherForecastData(data: TJSONObject);
var
  jForecastItem: TJSONObject;
  resultArray:TJSONArray;
  resultIndex: Integer;
  id: TGUID;
  newForecast: TForecast;
begin
  resultArray:=data.Arrays['list'];
  for resultIndex := 0 to resultArray.count -1 do
    begin
    createGuid(id);
    jForecastItem:=TJSONObject(resultArray[resultIndex]);
    jForecastItem.Add('entityId', GuidToString(id));
    jForecastItem.Add('entityType', 'TForecast');
    newForecast:=TForecast.create(JForecastItem);
    forecasts.AddEntity(newForecast);
    end;
  lbresults.items.add('['+formatDateTime('yyyy-mm-dd hh:nn:ss', now)+'] Added '+inttostr(dm1.saveData(forecasts))+' records');
end;

procedure ToctopusForm.processOpenWeatherCurrentData(data: TJSONObject);
var
  id: TGUID;
begin
  CreateGUID(id);
  if (currentWeather <> nil) then currentWeather.Free;
  data.Add('entityId',GuidToString(id));
  data.Add('entityType','TWeather');
  currentWeather:= TWeather.Create(data);
end;

procedure ToctopusForm.updateCurrentWeatherDisplay;
begin
  //take the data from the Weather object and display something pretty
  lheadline.Caption:='Weather for '+currentWeather.city;
  lSummary.Caption:='Current weather: '+currentWeather.weatherSummary;
  lDescription.Caption:=currentWeather.weatherDescription;
  ltemperature.Caption:='Temperature: '+formatFloat('0.00',currentWeather.temp - 273)+' C';
  lfeelsLike.Caption:='Feels like: '+formatFloat('0.00',currentWeather.tempFeelsLike - 273)+' C';
  lTempMin.Caption:='Min: '+formatFloat('0.00',currentWeather.tempMin - 273)+' C';
  lTempMax.Caption:='Max: '+formatFloat('0.00',currentWeather.tempMax - 273)+' C';
  lWind.Caption:='Wind speed: '+formatFloat('0.00',currentWeather.windSpeed)+' m/s';
  lwindDegrees.Caption:='Wind degrees: '+inttostr(currentweather.windAngle)+' degrees';
  lwindGust.Visible:=currentWeather.windGust > 0;
  lcloud.Caption:='Cloud %age: '+intToStr(currentWeather.weatherCloudPercent);
  if (currentWeather.windGust > 0) then
     lwindGust.Caption:='Wind gust: '+formatFloat('0.00',currentWeather.windGust)+' m/s';
  lpressure.Caption:='Pressure: '+inttostr(currentWeather.pressure)+' hPa';
  lhumidity.Caption:='Humidity: '+inttostr(currentweather.humidity)+' %';
  lvisibility.caption:='Visibility: '+inttostr(currentWeather.visibility)+' m';
  lsunrise.Caption:='Sunrise: '+formatDateTime('hh:nn:ss',currentWeather.sunrise);
  lsunset.Caption:='Sunset: '+formatDateTime('hh:nn:ss',currentWeather.sunset);
  lForecastTime.Caption:='Forecast time: '+formatDateTime('ddd dd mmm yyyy hh:nn:ss',currentWeather.date);
end;

procedure ToctopusForm.getCurrentWeather;
begin
 //Open weather current
if (ckWeather.checked) then
   begin
   processOpenWeatherCurrentData(stringToJSON(getOpenWeatherCurrent));
   updateCurrentWeatherDisplay;
   end;
end;

procedure ToctopusForm.getTodaysTariffs(em: TEntityListManager);
begin
  dm1.getTariffData(em);
end;

procedure ToctopusForm.renderTodaysTariffs;
var
  pbWidth, pbHeight, marginx, marginy, itemcount, barGap, barWidth:integer;
  barNo, xStart,xEnd,yStart,yEnd : integer;
  priceMax, priceMin: double;
  priceStep: integer;
  yaxisStepHeight: double;
  yaxisStep:integer;
  price:double;
  yOffset:integer;
  segmentDate:TDateTime;
  resultId:integer;
  resultPrice:Double;
begin
//set some constants
marginx:=30;
marginy:=50;
pbWidth:=pbTariff.Width;
pbHeight:=pbTariff.Height;
//space between bars
barGap:=4;
itemCount:=tariffRender.Count;
//how wide each bar is
barWidth:=((pbWidth - marginx) div itemCount) - barGap;
xStart:=barGap;
yEnd:=pbTariff.Height - marginy;
//find the largest and smallest value of inc_vat in the list.
priceMin:=0;
priceMax:=0;
for resultId := 0 to itemCount - 1 do
  begin
  resultPrice:= (tariffRender.FindByPosition(resultId) as TTariff).IncVat;
  if (resultPrice < priceMin ) then priceMin:= resultPrice;
  if (resultPrice > priceMax ) then priceMax:= resultPrice;
  end;

//Max 10 steps to avoid a cluttered display
priceStep:=round((PriceMax-PriceMin)/10);
//draw the graph axes
pbTariff.Canvas.MoveTo(marginx,0);
pbTariff.canvas.LineTo(marginx, pbHeight - marginy);
pbTariff.Canvas.LineTo(pbTariff.Width, pbHeight - marginy);
//draw the y axis markings
pbTariff.Canvas.Font.Orientation:=0;
yAxisStepHeight:=(pbHeight - marginy)/(priceMax/priceStep);
for yaxisStep:=0 to 10 do
  begin
  yOffset:=priceToYpos(yAxisStep*priceStep, priceMin, priceMax, yAxisStepHeight);
  pbTariff.Canvas.TextOut(0, pbheight - marginy - yoffset, inttostr(yAxisStep * priceStep));
  if (yaxisStep > 0) then
  //draw grid lines
    begin
    pbTariff.Canvas.Pen.Style:=psDash;
    pbTariff.Canvas.MoveTo(marginx, pbHeight - marginy - yOffset);
    pbTariff.Canvas.LineTo(pbWidth, pbHeight - marginy - yOffset);
    end;
  end;
for barNo:=0 to itemCount - 1 do with pbTariff.canvas do
  begin
  //ystart is the top :(
  xStart:=((barWidth + barGap) * barNo) + (barGap div 2) +marginx;
  xEnd:=xStart+barWidth;
  //ystart depends on the value of inc_vat
  price:=(tariffRender.FindByPosition(barNo) as TTariff).IncVat;
  segmentDate:=(tariffRender.FindByPosition(barNo) as TTariff).ValidFrom;

  yoffset:=priceToYPos(price, priceMin, priceMax, yAxisStepHeight);
  ystart:=pbHeight - marginy - yOffset;
  Brush.Color:=$000000A0;
  Rectangle(xStart,yStart,xEnd,yEnd);
  //Draw the times at the bottom
  Brush.Color:=clDefault;
  Font.Orientation:=900;
  TextOut(xstart+(barwidth div 4) , pbHeight, formatDateTime('ddd dd mmm hh:nn',segmentDate));
  end;
end;

//TODO EntityListManager should have a delete all method
procedure ToctopusForm.emptyManager(manager: TEntityListManager);
var
  entityToRemove:IEntity;
begin
  while manager.Count > 0 do
  begin
  entityToRemove:=manager.FindByPosition(0);
  manager.RemoveEntity(entityToRemove);
  end;
end;




function ToctopusForm.getOctopusAgile: string;
begin
  result:= queryApi(eOctopusApi.Text);
end;

function ToctopusForm.getOpenWeatherCurrent: string;
begin
  result:= queryApi('https://'+eOpenWeatherApi.text+'weather?q='+eOpenWeatherCity.text+'&appid='+eOpenWeatherApiKey.text);
end;

function ToctopusForm.getOpenWeatherForecast: string;
begin
  result:= queryApi('https://'+eOpenWeatherApi.text+'forecast?q='+eOpenWeatherCity.text+'&appid='+eOpenWeatherApiKey.text);
end;

function ToctopusForm.stringToJSON(input: string): TJSONObject;
begin
  result:=TJSONObject(getJSON(input));
end;

function ToctopusForm.priceToYPos(price, priceMin, priceMax, stepHeight: double
  ): integer;
begin
  result := round((price - PriceMin)/(PriceMax - priceMin) * (10 * StepHeight));
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

