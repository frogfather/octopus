unit utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  TUtilities = class(TObject);
  class function getPreferencesFolder:String; static;
implementation

// -----------------------------------------------------------------------------
// Platform-independend method to search for the location of preferences folder}
// -----------------------------------------------------------------------------
class function getPreferencesFolder: String;
const kMaxPath = 1024;
var {$IFDEF LCLCarbon}
    theError: OSErr;
    theRef: FSRef;
    {$ENDIF}
    pathBuffer: PChar;
begin
  {$IFDEF LCLCarbon}
    try
      pathBuffer := Allocmem(kMaxPath);
    except on exception do exit;
    end;  // try
    try
      Fillchar(pathBuffer^, kMaxPath, #0);
      Fillchar(theRef, Sizeof(theRef), #0);
      theError := FSFindFolder(kOnAppropriateDisk, kPreferencesFolderType, kDontCreateFolder, theRef);
      if (pathBuffer <> nil) and (theError = noErr) then
      begin
        theError := FSRefMakePath(theRef, pathBuffer, kMaxPath);
        if theError = noErr then GetPreferencesFolder := UTF8ToAnsi(StrPas(pathBuffer)) + '/';
      end;  // if
    finally
      Freemem(pathBuffer);
    end; // try
  {$ELSE}
    GetPreferencesFolder := GetAppConfigDir(false);
  {$ENDIF}
end;     // GetPreferencesFolder

end.

