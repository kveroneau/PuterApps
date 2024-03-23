program PuterHack;

{$mode objfpc}

uses
  browserapp, JS, Classes, SysUtils, libjquery, Web, jsterm, hackterm, puterjs;

type

  TAppArgs = class(TJSObject)
  public
    title: string;
    message: string;
    okay: boolean;
    num: integer;
  end;

  { TPuterHack }

  TPuterHack = class(TBrowserApplication)
    procedure doRun; override;
  private
    FTerm: TJQuery;
    FHackTerm: THackTerminal;
    procedure OnCommand(command: string; term: TJQuery);
    procedure OnInit(term: TJQuery);
    function WindowResize(aEvent: TJSUIEvent): Boolean;
  end;

{ TPuterHack }

procedure TPuterHack.doRun;
begin
  window.onresize:=@WindowResize;
  FHackTerm:=Nil;
  FTerm:=InitTerminal('terminal', @OnCommand, SimpleTerm, @OnInit);
end;

procedure TPuterHack.OnCommand(command: string; term: TJQuery);
begin
  if Assigned(FHackTerm) then
    FHackTerm.Free;
  FHackTerm:=THackTerminal.Create(term);
end;

procedure TPuterHack.OnInit(term: TJQuery);
var
  args: TAppArgs;
begin
  WindowResize(Nil);
  with term do
  begin
    args:=TAppArgs(PuterAPI.args);
    if args.okay then
      echo('#######  This has been launched through Puter Test App!!!');
    echo(' *** Prepare for a fun hacking game simulation! ***');
    echo('This entire game engine has been written 100% in ObjectPascal, ');
    echo('and transpiled to JavaScript, much like how other transpilers');
    echo('work like the GWT, or perhaps TypeScript.');
    Prompt:='Press enter to begin...';
  end;
end;

function TPuterHack.WindowResize(aEvent: TJSUIEvent): Boolean;
begin
  with GetHTMLElement('terminal').style do
  begin
    Properties['width']:=IntToStr(window.innerWidth-20)+'px';
    Properties['height']:=IntToStr(window.innerHeight-20)+'px';
  end;
end;

var
  Application : TPuterHack;

begin
  Application:=TPuterHack.Create(nil);
  Application.Initialize;
  Application.Run;
end.
