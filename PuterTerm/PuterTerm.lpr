program PuterTerm;

{$mode objfpc}

uses
  browserapp, JS, Classes, SysUtils, Web, libjquery, jsterm, puterjs, p2jsres;

type

  TAppArgs = class(TJSObject)
  public
    title: string;
    message: string;
    okay: boolean;
    num: integer;
  end;

  { TPuterTerm }

  TPuterTerm = class(TBrowserApplication)
    procedure doRun; override;
  private
    FTerm: TJQuery;
    FPath: string;
    FPathParts: Array of string;
    procedure OnCommand(command: string; term: TJQuery);
    procedure OnInit(term: TJQuery);
    function WindowResize(aEvent: TJSUIEvent): Boolean;
    procedure ShowPuterError(AError: TPuterErrorMsg);
    procedure ShowDirectory(ADirList: TPuterDirList);
    procedure ShowContent(AContent: string);
    procedure ListDirectory(command: string);
    procedure ChangeDirectory(command: string);
    procedure DisplayFile(command: string);
    procedure MakeDirectory(command: string);
    procedure RenameFile(command: string);
    procedure CopyFile(command: string);
    procedure ShowHelp;
    function GetPath: string;
    function GetPrompt: string;
  end;

const
  VERSION = '0.1';

{$R help.txt}

{ TPuterTerm }

procedure TPuterTerm.doRun;
var
  params: TJSTerminalOptions;
begin
  Puter.WindowTitle:='PuterTerm v'+VERSION;
  Puter.OnPuterError:=@ShowPuterError;
  Puter.OnDirListSuccess:=@ShowDirectory;
  puter.OnReadSuccess:=@ShowContent;
  FPath:='./';
  SetLength(FPathParts, 1);
  FPathParts[0]:='.';
  params:=TJSTerminalOptions.new;
  params.prompt:=GetPrompt;
  FTerm:=InitTerminal('terminal', @OnCommand, params, @OnInit);
end;

procedure TPuterTerm.OnCommand(command: string; term: TJQuery);
var
  cmd: string;
begin
  if command = '' then
    Exit;
  cmd:=getToken(command);
  case cmd of
    'help': ShowHelp;
    'hacker': Puter.LaunchApp('puterhack-pv0wh0r3l3');
    {$IFDEF UNIXCMD}
    'ls': ListDirectory(command);
    'pwd': FTerm.echo(GetPath);
    'cd': ChangeDirectory(command);
    'cat': DisplayFile(command);
    'clear': FTerm.Clear;
    'mkdir': MakeDirectory(command);
    'mv': RenameFile(command);
    'cp': CopyFile(command);
    'vim': Puter.LaunchApp('editor');
    {$ENDIF}
    {$IFDEF DOSCMD}
    'dir': ListDirectory(command);
    'cd': ChangeDirectory(command);
    'type': DisplayFile(command);
    'cls': FTerm.Clear;
    'md': MakeDirectory(command);
    'ren': RenameFile(command);
    'copy': CopyFile(command);
    'notepad': Puter.LaunchApp('editor');
    {$ENDIF}
  else
    term.echo('?SYNTAX ERROR');
  end;
end;

procedure TPuterTerm.OnInit(term: TJQuery);
begin
  WindowResize(Nil);
end;

function TPuterTerm.WindowResize(aEvent: TJSUIEvent): Boolean;
begin
  with GetHTMLElement('terminal').style do
  begin
    Properties['width']:=IntToStr(window.innerWidth-20)+'px';
    Properties['height']:=IntToStr(window.innerHeight-20)+'px';
  end;
end;

procedure TPuterTerm.ShowPuterError(AError: TPuterErrorMsg);
begin
  FTerm.Echo(AError.message);
  FTerm.Enabled:=True;
end;

procedure TPuterTerm.ShowDirectory(ADirList: TPuterDirList);
var
  i: integer;
begin
  for i:=0 to Length(ADirList)-1 do
    FTerm.echo(ADirList[i].name);
  FTerm.Enabled:=True;
end;

procedure TPuterTerm.ShowContent(AContent: string);
begin
  FTerm.echo(AContent);
  FTerm.Enabled:=True;
end;

procedure TPuterTerm.ListDirectory(command: string);
begin
  FTerm.Enabled:=False;
  if command = '' then
    Puter.GetDirectory(GetPath)
  else
    Puter.GetDirectory(getToken(command));
end;

procedure TPuterTerm.ChangeDirectory(command: string);
var
  i: integer;
begin
  if command = '' then
  begin
    SetLength(FPathParts, 1);
    Fterm.Prompt:=GetPrompt;
    Exit;
  end;
  i:=Length(FPathParts);
  SetLength(FPathParts, i+1);
  FPathParts[i]:=getToken(command);
  Fterm.Prompt:=GetPrompt;
end;

procedure TPuterTerm.DisplayFile(command: string);
begin
  if command = '' then
    Exit;
  Puter.ReadFile(GetPath+getToken(command));
  FTerm.Enabled:=False;
end;

procedure TPuterTerm.MakeDirectory(command: string);
begin
  if command = '' then
    Exit;
  Puter.MakeDirectory(getToken(command));
end;

procedure TPuterTerm.RenameFile(command: string);
var
  file1, file2: string;
begin
  if command = '' then
    Exit;
  file1:=getToken(command);
  file2:=getToken(command);
  if (file1 = '') or (file2 = '') then
    Exit;
  Puter.RenameFile(file1, file2);
end;

procedure TPuterTerm.CopyFile(command: string);
var
  file1, file2: string;
begin
  if command = '' then
    Exit;
  file1:=getToken(command);
  file2:=getToken(command);
  if (file1 = '') or (file2 = '') then
    Exit;
  Puter.CopyFile(file1, file2);
end;

procedure TPuterTerm.ShowHelp;
var
  info: TResourceInfo;
begin
  if not GetResourceInfo(rsHTML, 'help', info) then
    FTerm.echo(' * Help missing!')
  else
    Fterm.echo(window.atob(info.data));
end;

function TPuterTerm.GetPath: string;
var
  i: integer;
begin
  Result:='';
  for i:=0 to Length(FPathParts)-1 do
    Result:=Result+FPathParts[i]+'/';
end;

function TPuterTerm.GetPrompt: string;
begin
  {$IFDEF UNIXCMD}
  Result:='Puter:'+GetPath+'>';
  {$ENDIF}
  {$IFDEF DOSCMD}
  Result:='P:'+GetPath+'>';
  {$ENDIF}
end;

var
  Application : TPuterTerm;

begin
  Application:=TPuterTerm.Create(nil);
  Application.Initialize;
  Application.Run;
end.
