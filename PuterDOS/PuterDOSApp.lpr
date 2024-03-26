program PuterDOSApp;

{$mode objfpc}

uses
  browserapp, JS, Classes, SysUtils, Web;

type

  { TPuterDOSApp }

  TPuterDOSApp = class(TBrowserApplication)
    procedure doRun; override;
  end;

{ TPuterDOSApp }

procedure TPuterDOSApp.doRun;
begin

end;

var
  Application : TPuterDOSApp;

begin
  Application:=TPuterDOSApp.Create(nil);
  Application.Initialize;
  Application.Run;
end.
