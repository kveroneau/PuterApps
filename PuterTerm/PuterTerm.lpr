program PuterTerm;

{$mode objfpc}

uses
  browserapp, JS, Classes, SysUtils, Web;

type

  { TPuterTerm }

  TPuterTerm = class(TBrowserApplication)
    procedure doRun; override;
  end;

{ TPuterTerm }

procedure TPuterTerm.doRun;
begin

end;

var
  Application : TPuterTerm;

begin
  Application:=TPuterTerm.Create(nil);
  Application.Initialize;
  Application.Run;
end.
