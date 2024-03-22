unit hackterm;

{$mode objfpc}
{$modeswitch externalclass}

interface

uses
  Classes, SysUtils, libjquery, jsterm, p2jsres, Web, JS, Types, timer;

type

  TGameState = (stGreeting, stShell, stJump, stMail, stHRSearch, stReps);

  THRRecord = Class external name 'Object' (TJSObject)
    LastName: string; external name 'last';
    Birthday: string; external name 'dob';
    MiddleName: string; external name 'middle';
    FirstName: string; external name 'employee';
    Position: string; external name 'position';
    Status: string; external name 'type';
  end;

  TMail = Class external name 'Object' (TJSObject)
    Item: string; external name 'item';
    Body: string; external name 'body';
    Status: string; external name 'status';
  end;

  TMailbox = array of TMail;

  TArrayMap = class external name 'Map' (TJSMap)
    function &set(key: string; value: TStringDynArray): TArrayMap; reintroduce;
    function get(key : string): TStringDynArray; reintroduce;
    function has(key: string): Boolean; reintroduce;
    function delete(key: string): Boolean; reintroduce;
  end;

  TStringMap = class external name 'Map' (TJSMap)
    function &set(key: string; value: string): TStringMap; reintroduce;
    function get(key : string): string; reintroduce;
    function has(key: string): Boolean; reintroduce;
    function delete(key: string): Boolean; reintroduce;
  end;

  { THackTerminal }

  THackTerminal = class(TObject)
    constructor Create(term: TJQuery);
    destructor Destroy; override;
  private
    FTerm: TJQuery;
    FState: TGameState;
    FHRDB, FScenario: TJSObject;
    FCommandList, FFileList: TArrayMap;
    FLoginMap: TStringMap;
    FProgress, FAttempts: integer;
    FUsername: string;
    FLocalMail: TMailbox;
    FTimer: TTimer;
    FOnWake: TNotifyEvent;
    procedure SetupScenario;
    procedure ScenarioLoaded(const LoadedResources : Array of String);
    procedure ScenarioError(const aError : string);
    procedure onCommand(command: string; term: TJQuery);
    procedure ShowFile(FileName: string);
    procedure DoGreeting;
    procedure InvalidGameState;
    procedure NewState(name: string; state: TGameState);
    procedure NewState(name: string; state: TGameState; loginCB: TLoginCallback);
    procedure DoShell(cmdline: string);
    procedure ListFiles;
    procedure TypeFile(FileName: string);
    function CommandAvail(cmd: string): Boolean;
    function FileAvail(FileName: string): Boolean;
    procedure AddCommand(name, cmd: string);
    procedure NewMail(item: string);
    procedure UpdateProgress(cmdline: string);
    procedure RunCommand;
    procedure OnRunCommand(Sender: TObject);
    procedure GatewayCommand;
    procedure OnGatewayCommand(Sender: TObject);
    procedure JumpCommand(Username: string);
    procedure OnJumpCommand(Sender: TObject);
    procedure GateLogin(user, password: string; callback: TLoginEvent);
    procedure DoJump(Password: string);
    procedure MailCommand;
    procedure DoMailCommand(Sender: TObject);
    procedure DoMail(cmdline: string);
    procedure ListMail;
    function GetMailFor(Username: string): TMailbox;
    procedure ShowMail(item: string);
    procedure CheckState(term: TJQuery);
    procedure ShowHelp;
    procedure HRCommand;
    procedure DoHRCommand(Sender: TObject);
    procedure HRLogin(user, password: string; callback: TLoginEvent);
    procedure HRSearchCommand;
    procedure HRSearch(username: string);
    procedure RepsCommand;
    procedure DoRepsCommand(Sender: TObject);
    procedure RepsLogin(user, password: string; callback: TLoginEvent);
    procedure ShellHelp;
    procedure MailHelp;
    procedure Sleep(secs: integer; NextProc: TNotifyEvent);
    procedure OnWake(Sender: TObject);
  end;

implementation

{$R gamedata/bootup.txt}
{$R gamedata/greeting.txt}
{$R gamedata/scenario.json}
{$R gamedata/hrdb.json}
{$R gamedata/localhost/readme.txt}
{$R gamedata/localhost/solution.txt}
{$R gamedata/hack/atip.txt}
{$R gamedata/hack/note.txt}
{$R gamedata/gateway/welcome.txt}
{$R gamedata/mail/localhost/hr.txt}
{$R gamedata/mail/localhost/sales.txt}

const
  STATIC_DIR = '/';

{ THackTerminal }

constructor THackTerminal.Create(term: TJQuery);
var
  info: TResourceInfo;
  params: TTerminalState;
begin
  { TODO : Update to allow proper resource loading from a new HTML file }
  FProgress:=0;
  FTimer:=TTimer.Create(Nil);
  FTimer.Enabled:=False;
  FTimer.OnTimer:=@OnWake;
  params:=SimpleState('hackterm', 'Press Enter to Accept offer...');
  FState:=stGreeting;
  FTerm:=term;
  FTerm.Push(@onCommand, params);
  FTerm.Enabled:=False;
  if not GetResourceInfo(rsHTML, 'greeting', info) then
    LoadHTMLLinkResources(STATIC_DIR+'hackterm-res.html', @ScenarioLoaded, @ScenarioError)
  else
    SetupScenario;
end;

destructor THackTerminal.Destroy;
begin
  inherited Destroy;
end;

procedure THackTerminal.SetupScenario;
var
  info: TResourceInfo;
  cmdlist: TJSObject;
  cmd: string;
begin
  ShowFile('greeting');
  if GetResourceInfo(rsHTML, 'hrdb', info) then
    FHRDB:=TJSJSON.parseObject(window.atob(info.data));
  if GetResourceInfo(rsHTML, 'scenario', info) then
  begin
    FScenario:=TJSJSON.parseObject(window.atob(info.data));
    FCommandList:=TArrayMap.new;
    cmdlist:=TJSObject(FScenario.Properties['command_lists']);
    for cmd in TJSObject.keys(cmdlist) do
      FCommandList.&set(cmd, TStringDynArray(cmdlist.Properties[cmd]));
    FFileList:=TArrayMap.new;
    cmdlist:=TJSObject(FScenario.Properties['file_lists']);
    for cmd in TJSObject.keys(cmdlist) do
      FFileList.&set(cmd, TStringDynArray(cmdlist.Properties[cmd]));
    FLoginMap:=TStringMap.new;
    cmdlist:=TJSObject(FScenario.Properties['login_map']);
    for cmd in TJSObject.keys(cmdlist) do
      FLoginMap.&set(cmd, String(cmdlist.Properties[cmd]));
  end;
  FTerm.Enabled:=True;
end;

procedure THackTerminal.ScenarioLoaded(const LoadedResources: array of String);
begin
  FTerm.Echo('Scenario Loaded, starting...');
  SetupScenario;
end;

procedure THackTerminal.ScenarioError(const aError: string);
begin
  FTerm.Error(' * Error loading scenario data: '+aError);
  FTerm.Pop;
end;

procedure THackTerminal.onCommand(command: string; term: TJQuery);
begin
  case FState of
    stGreeting: DoGreeting;
    stShell: DoShell(command);
    stJump: DoJump(command);
    stMail: DoMail(command);
    stHRSearch: HRSearch(command);
    stReps: DoShell(command);
  else
    InvalidGameState;
  end;
  UpdateProgress(command);
end;

procedure THackTerminal.ShowFile(FileName: string);
var
  info: TResourceInfo;
begin
  if not GetResourceInfo(rsHTML, FileName, info) then
  begin
    FTerm.Echo('Missing resource: '+FileName);
    Exit;
  end;
  FTerm.Echo(window.atob(info.data));
end;

procedure THackTerminal.DoGreeting;
var
  dtstring: string;
begin
  ShowFile('bootup');
  dtstring:=TJSDate.New(TJSDate.now).toISOString;
  FTerm.Echo('Started: '+dtstring);
  FTerm.Echo('type "help" for help');
  NewState('localhost', stShell);
end;

procedure THackTerminal.InvalidGameState;
begin
  FTerm.Error('Invalid Game State detected!');
  FTerm.Pop;
end;

procedure THackTerminal.NewState(name: string; state: TGameState);
var
  params: TTerminalState;
begin
  params:=SimpleState(name, name+' >');
  params.onExit:=@CheckState;
  FTerm.Push(@onCommand, params);
  FState:=state;
end;

procedure THackTerminal.NewState(name: string; state: TGameState;
  loginCB: TLoginCallback);
var
  params: TTerminalState;
begin
  params:=LoginState(name, name+' >', loginCB);
  FTerm.Push(@onCommand, params);
  FState:=state;
end;

procedure THackTerminal.DoShell(cmdline: string);
var
  cmd: string;
begin
  cmd:=getToken(cmdline);
  if cmd = 'help' then
  begin
    ShowHelp;
    Exit;
  end;
  if not CommandAvail(cmd) then
  begin
    FTerm.Error('Command not found.');
    Exit;
  end;
  case cmd of
    'ls': ListFiles;
    'type': TypeFile(getToken(cmdline));
    'run': RunCommand;
    'atip': ShowFile('atip');
    'note': ShowFile('note');
    'gate': GatewayCommand;
    'jump': JumpCommand(getToken(cmdline));
    'mail': MailCommand;
    'hr': HRCommand;
    'search': HRSearchCommand;
    'reps': RepsCommand;
  end;
end;

procedure THackTerminal.ListFiles;
var
  i: integer;
  flist: TStringDynArray;
begin
  FTerm.Echo('File list:');
  flist:=FFileList.get(FTerm.Name);
  for i:=0 to Length(flist)-1 do
    FTerm.Echo(' '+flist[i]+'    1k    -rw wwr r-x');
end;

procedure THackTerminal.TypeFile(FileName: string);
begin
  if FileAvail(FileName) then
    ShowFile(FileName)
  else
    FTerm.Error('No file: '+FileName);
end;

function THackTerminal.CommandAvail(cmd: string): Boolean;
var
  s: string;
  cmdlist: TStringDynArray;
  ctx: string;
begin
  ctx:=FTerm.Name;
  if FState = stReps then
    ctx:=FUsername;
  if not FCommandList.has(ctx) then
    Exit;
  cmdlist:=FCommandList.get(ctx);
  for s in cmdlist do
    if cmd = s then
      Result:=True;
end;

function THackTerminal.FileAvail(FileName: string): Boolean;
var
  s: string;
  flist: TStringDynArray;
begin
  if not FFileList.has(FTerm.Name) then
    Exit;
  flist:=FFileList.get(FTerm.Name);
  for s in flist do
    if FileName = s then
      Result:=True;
end;

procedure THackTerminal.AddCommand(name, cmd: string);
var
  cmdlist: TStringDynArray;
  i: integer;
begin
  cmdlist:=FCommandList.get(name);
  i:=Length(cmdlist);
  SetLength(cmdlist, i+1);
  cmdlist[i]:=cmd;
  FCommandList.&set(name, cmdlist);
end;

procedure THackTerminal.NewMail(item: string);
var
  i: integer;
  mail: TMail;
begin
  FTerm.Echo(' * You just received a message from your employer.');
  FTerm.Echo(' * Return to your localhost to view it.');
  i:=Length(FLocalMail);
  SetLength(FLocalMail, i+1);
  mail:=TMail.new;
  mail.Status:='Inbox';
  mail.Item:=item;
  mail.Body:='RSRC';
  FLocalMail[i]:=mail;
end;

procedure THackTerminal.UpdateProgress(cmdline: string);
var
  triggers: TJSObject;
  trigger: TJSArray;
begin
  triggers:=TJSObject(FScenario.Properties['progress_triggers']);
  if not triggers.hasOwnProperty(cmdline) then
    Exit;
  trigger:=TJSArray(triggers.Properties[cmdline]);
  if FProgress = Integer(trigger.Elements[0]) then
  begin
    if FTerm.Name = String(trigger.Elements[1]) then
    begin
      WriteLn('Triggered!');
      Inc(FProgress);
      if FProgress = 1 then
      begin
        AddCommand('localhost', 'run');
      end
      else if FProgress = 2 then
      begin
        AddCommand('localhost', 'mail');
        AddCommand('hack', 'hr');
        NewMail('hr');
      end
      else if FProgress = 3 then
      begin
        AddCommand('hack', 'reps');
        NewMail('sales');
      end
      else if FProgress = 4 then
      begin
        FTerm.Echo('*******************************************');
        FTerm.Echo('And that concludes the demo!');
        FTerm.Echo('Please stay tuned for an update in the near');
        FTerm.Echo('future!');
        FTerm.Echo('===========================================');
        FTerm.Enabled:=False;
      end;
    end;
  end;
end;

procedure THackTerminal.RunCommand;
begin
  FTerm.Echo('running the hack routine...');
  Sleep(1, @OnRunCommand);
end;

procedure THackTerminal.OnRunCommand(Sender: TObject);
begin
  FTerm.Echo('successfully launched');
  FTerm.Echo('type "help" for help');
  NewState('hack', stShell);
end;

procedure THackTerminal.GatewayCommand;
begin
  FTerm.Echo('Establishing a connection to the Gateway System...');
  Sleep(1, @OnGatewayCommand);
end;

procedure THackTerminal.OnGatewayCommand(Sender: TObject);
begin
  FTerm.Echo('Connection Established.');
  FTerm.Echo('Log in with your Gateway account');
  NewState('gateway', stShell, @GateLogin);
end;

procedure THackTerminal.JumpCommand(Username: string);
begin
  FTerm.Echo('Establishing a connection to '+Username+' Workstation...');
  FUsername:=Username;
  Sleep(2, @OnJumpCommand);
end;

procedure THackTerminal.OnJumpCommand(Sender: TObject);
begin
  if not FLoginMap.has(FUsername) then
  begin
    FTerm.Error('No route to host.');
    Exit;
  end;
  FTerm.Echo('Connection Established.');
  FTerm.Echo('Enter your Workstation password.');
  FAttempts:=3;
  NewState('password', stJump);
  FTerm.Mask:=True;
end;

procedure THackTerminal.GateLogin(user, password: string; callback: TLoginEvent
  );
var
begin
  if FLoginMap.has(user) and (password = FLoginMap.get(user)) then
  begin
    FTerm.Echo('Successful login!');
    FTerm.Echo('Welcome to the Gateway System');
    callback(user);
  end
  else
  begin
    callback('');
    FTerm.Echo('Type "atip" for a tip');
    FTerm.Error('Disconnected from the gateway system');
  end;
end;

procedure THackTerminal.DoJump(Password: string);
begin
  if FLoginMap.has(FUsername) and (Password = FLoginMap.get(FUsername)) then
  begin
    FTerm.Echo('Successful login!');
    FTerm.Echo('Logged into '+FUsername+' Workstation');
    FTerm.Pop;
    NewState(FUsername, stShell);
    Exit;
  end;
  Dec(FAttempts);
  if FAttempts = 0 then
  begin
    FTerm.Error('Disconnected from '+FUsername+' Workstation');
    FTerm.Pop;
    FState:=stShell;
  end
  else
    FTerm.Error('Invalid password');
end;

procedure THackTerminal.MailCommand;
begin
  FTerm.Echo('Launching '+FUsername+' mail...');
  Sleep(1, @DoMailCommand);
end;

procedure THackTerminal.DoMailCommand(Sender: TObject);
begin
  NewState(FUsername+'.mail', stMail);
end;

procedure THackTerminal.DoMail(cmdline: string);
var
  cmd: string;
begin
  cmd:=getToken(cmdline);
  case cmd of
    'list': ListMail;
    'show': ShowMail(getToken(cmdline));
    'help': ShowHelp;
  else
    FTerm.Error('Command not available.');
  end;
end;

procedure THackTerminal.ListMail;
var
  mail: TMailbox;
  i: integer;
  mbox: TMail;
begin
  FTerm.Echo('List of Messages:');
  mail:=GetMailFor(FUsername);
  if Length(mail) = 0 then
  begin
    FTerm.Error(' no files found');
    Exit;
  end;
  for i:=0 to Length(mail)-1 do
    FTerm.Echo(' '+mail[i].Item+'    <'+mail[i].Status+'>');
end;

function THackTerminal.GetMailFor(Username: string): TMailbox;
var
  mlist: TJSObject;
  mail: TJSArray;
  i: integer;
begin
  if Username = 'localhost' then
  begin
    Result:=FLocalMail;
    Exit;
  end;
  mlist:=TJSObject(FScenario.Properties['mailboxes']);
  if not mlist.hasOwnProperty(Username) then
    Exit;
  mail:=TJSArray(mlist.Properties[Username]);
  SetLength(Result, mail.Length);
  for i:=0 to mail.Length-1 do
    Result[i]:=TMail(mail.Elements[i]);
end;

procedure THackTerminal.ShowMail(item: string);
var
  mail: TMailbox;
  i: integer;
begin
  mail:=GetMailFor(FUsername);
  for i:=0 to Length(mail)-1 do
    if item = mail[i].Item then
    begin
      if mail[i].Body = 'RSRC' then
        ShowFile(mail[i].Item)
      else
        FTerm.Echo(mail[i].Body);
    end;
end;

procedure THackTerminal.CheckState(term: TJQuery);
begin
  if FState = stMail then
    FState:=stShell;
  if FState = stHRSearch then
    FState:=stShell;
  if FState = stReps then
    FState:=stShell;
  if FTerm.Name = 'localhost' then
    FUsername:='localhost';
  if FTerm.Name = 'hackterm' then
    FTerm.Pop;
end;

procedure THackTerminal.ShowHelp;
begin
  case FState of
    stShell: ShellHelp;
    stMail: MailHelp;
    stReps: ShellHelp;
  else
    FTerm.Error(' * No help exists for this sub-system!');
  end;
end;

procedure THackTerminal.HRCommand;
begin
  FTerm.Echo('Connecting to the RUN Human Resources System...');
  Sleep(2, @DoHRCommand);
end;

procedure THackTerminal.DoHRCommand(Sender: TObject);
begin
  FTerm.Echo('Connection established.');
  NewState('hr', stShell, @HRLogin);
end;

procedure THackTerminal.HRLogin(user, password: string; callback: TLoginEvent);
var
  hrMap: TJSObject;
begin
  hrMap:=TJSObject(FScenario.Properties['hr_map']);
  if hrMap.hasOwnProperty(user) then
  begin
    if password = String(hrMap.Properties[user]) then
    begin
      FTerm.Echo('Welcome to the RUN Human Resources System');
      callback('HR-'+user);
      Exit;
    end;
  end;
  callback('');
  FTerm.Error('Disconnected from the RUN Human Resources System');
end;

procedure THackTerminal.HRSearchCommand;
begin
  FTerm.Echo('Searching the HR employee and associate database.');
  FTerm.Echo('Enter "exit" to exit.');
  FTerm.Echo('Enter username of employee or associate.');
  NewState('HR.search', stHRSearch);
end;

procedure THackTerminal.HRSearch(username: string);
var
  rec: THRRecord;
begin
  if FHRDB.hasOwnProperty(username) then
  begin
    rec:=THRRecord(FHRDB.Properties[username]);
    FTerm.Echo(' Employee: '+rec.FirstName);
    FTerm.Echo(' Middle Name: '+rec.MiddleName);
    FTerm.Echo(' Last Name: '+rec.LastName);
    FTerm.Echo(' '+rec.Status);
    FTerm.Echo(' DOB: '+rec.Birthday);
    FTerm.Echo(' Position: '+rec.Position);
  end
  else
    FTerm.Error('unknown employee or associate: "'+username+'"');
end;

procedure THackTerminal.RepsCommand;
begin
  FTerm.Echo('Establishing a connection to the RUN Sales Rep System');
  Sleep(1, @DoRepsCommand);
end;

procedure THackTerminal.DoRepsCommand(Sender: TObject);
begin
  FTerm.Echo('Connection Established');
  FTerm.Echo('Log in with your sales rep account');
  NewState('reps', stReps, @RepsLogin);
end;

procedure THackTerminal.RepsLogin(user, password: string; callback: TLoginEvent
  );
var
  repsMap: TJSObject;
begin
  repsMap:=TJSObject(FScenario.Properties['reps_map']);
  if repsMap.hasOwnProperty(user) then
  begin
    if password = String(repsMap.Properties[user]) then
    begin
      FTerm.Echo('Successfully logged into the RUN Sales Rep System as '+user);
      FUsername:=user;
      callback('REPS-'+user);
      FTerm.Prompt:=user+'$ ';
      Exit;
    end;
  end;
  callback('');
  FTerm.Error('Disconnected from the RUN Sales Rep System');
end;

procedure THackTerminal.ShellHelp;
var
  s: string;
  cmdlist: TStringDynArray;
  ctx: string;
begin
  FTerm.Echo('Available Commands:');
  ctx:=FTerm.Name;
  if FState = stReps then
    ctx:=FUsername;
  cmdlist:=FCommandList.get(ctx);
  for s in cmdlist do
    FTerm.Echo(' '+s);
end;

procedure THackTerminal.MailHelp;
begin
  FTerm.Echo('RUN Mail System Help:');
  FTerm.Echo(' list - List the contents of your mailbox.');
  FTerm.Echo(' show [message] - Show the contents of a mailbox item.');
  FTerm.Echo(' exit - Leaves the mail program.');
end;

procedure THackTerminal.Sleep(secs: integer; NextProc: TNotifyEvent);
begin
  FOnWake:=NextProc;
  FTerm.Enabled:=False;
  FTimer.Interval:=secs*1000;
  FTimer.Enabled:=True;
end;

procedure THackTerminal.OnWake(Sender: TObject);
begin
  FTimer.Enabled:=False;
  FTerm.Enabled:=True;
  FOnWake(Sender);
end;

end.

