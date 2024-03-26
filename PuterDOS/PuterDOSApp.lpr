program PuterDOSApp;

{$mode objfpc}

uses
  browserapp, JS, Classes, SysUtils, Web, jsonlib, ajaxlib, jsdosbox, puterjs;

type

  { TPuterDOSApp }

  TPuterDOSApp = class(TBrowserApplication)
  private
    FRequest: TJSONRequest;
    FDOSBox: TDOSBox;
    procedure DataLoaded(json: TJSONData);
  protected
    procedure doRun; override;
  end;

{ TPuterDOSApp }

procedure TPuterDOSApp.DataLoaded(json: TJSONData);
begin
  Puter.WindowTitle:=json.Strings['title'];
  FDOSBox:=TDOSBox.Create(Self, json.Strings['image'], json.Strings['exe'], json.Strings['mount']);
end;

procedure TPuterDOSApp.doRun;
begin
  FRequest:=TJSONRequest.Create(Self, 'get', 'settings.json');
  FRequest.OnJSON:=@DataLoaded;
  FRequest.DoRequest;
end;

var
  Application : TPuterDOSApp;

begin
  Application:=TPuterDOSApp.Create(nil);
  Application.Initialize;
  Application.Run;
end.
