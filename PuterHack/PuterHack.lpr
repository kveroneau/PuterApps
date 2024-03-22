program PuterHack;

{$mode objfpc}

uses
  browserapp, JS, Classes, SysUtils, libjquery, Web, jsterm, hackterm;

type

  { TPuterHack }

  TPuterHack = class(TBrowserApplication)
    procedure doRun; override;
  private
    FTerm: TJQuery;
    FHackTerm: THackTerminal;
    procedure OnCommand(command: string; term: TJQuery);
    procedure OnInit(term: TJQuery);
  end;

{ TPuterHack }

procedure TPuterHack.doRun;
begin
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
begin
  term.echo(' *** Prepare for a fun hacking game simulation! ***');
  term.echo('This entire game engine has been written 100% in ObjectPascal, ');
  term.echo('and transpiled to JavaScript, much like how other transpilers');
  term.echo('work like the GWT, or perhaps TypeScript.');
  term.Prompt:='Press enter to begin...';
end;

var
  Application : TPuterHack;

begin
  Application:=TPuterHack.Create(nil);
  Application.Initialize;
  Application.Run;
end.
