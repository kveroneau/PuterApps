program PuterTest1;

{$mode objfpc}

uses
  browserconsole, browserapp, JS, Classes, SysUtils, Web, puterjs, PuterDS;

type

  TAppArgs = class(TJSObject)
  public
    title: string;
    message: string;
    okay: boolean;
    num: integer;
  end;

  { TMyApplication }

  TMyApplication = class(TBrowserApplication)
  private
    FFileInput: TJSHTMLInputElement;
    FPuterApp: TJSHTMLDivElement;
    procedure ShowPuterError(AError: TPuterErrorMsg);
    procedure ShowContent(AContent: string);
    procedure ShowFile(AFile: TPuterFSItem);
    procedure ShowDirectory(ADirList: TPuterDirList);
    function UploadFile(AEvent: TEventListenerEvent): boolean;
    procedure UploadSuccess(AFiles: TPuterFSItem);
    procedure KVTests; async;
    function SelectOpenFile(AEvent: TJSMouseEvent): Boolean;
    function SelectSaveFile(AEvent: TJSMouseEvent): Boolean;
    function SelectDirectory(AEvent: TJSMouseEvent): Boolean;
    function DoPuterAuth(AEvent: TJSMouseEvent): Boolean;
    function DoPuterAlert(AEvent: TJSMouseEvent): Boolean;
    function DoCreateWindow(AEvent: TJSMouseEvent): Boolean;
    function DoExit(AEvent: TJSMouseEvent): Boolean;
    function DoLaunchApp(AEvent: TJSMouseEvent): Boolean;
    function DoColorPick(AEvent: TJSMouseEvent): Boolean;
    function DoFontPick(AEvent: TJSMouseEvent): Boolean;
    function DoOpenBlog(AEvent: TJSMouseEvent): Boolean;
    function DoOpenBlogWin(AEvent: TJSMouseEvent): Boolean;
    function DoPrompt(AEvent: TJSMouseEvent): Boolean;
    function DoArgsTest(AEvent: TJSMouseEvent): Boolean;
    function DoPuterHack(AEvent: TJSMouseEvent): Boolean;
    function DoPuterDS(AEvent: TJSMouseEvent): Boolean;
    procedure HandleAuth;
  protected
    procedure doRun; override;
  end;

const
  APP_NAME = 'puter-test-app-c3elb65v5lv';

procedure TMyApplication.ShowPuterError(AError: TPuterErrorMsg);
begin
  writeln('Puter Error: ',AError.message);
end;

procedure TMyApplication.ShowContent(AContent: string);
begin
  Writeln(AContent);
end;

procedure TMyApplication.ShowFile(AFile: TPuterFSItem);
begin
  writeln(AFile.path);
  writeln(AFile.content);
end;

procedure TMyApplication.ShowDirectory(ADirList: TPuterDirList);
var
  i: integer;
begin
  writeln(Length(ADirList));
  for i:=0 to Length(ADirList)-1 do
    writeln(ADirList[i].name);
end;

function TMyApplication.UploadFile(AEvent: TEventListenerEvent): boolean;
begin
  Puter.UploadFile(FFileInput.files);
end;

procedure TMyApplication.UploadSuccess(AFiles: TPuterFSItem);
begin
  writeln(AFiles.path);
end;

procedure TMyApplication.KVTests;
var
  r: Boolean;
  s: string;
  i: Integer;
  items: TJSArray;
begin
  r:=AWait(Boolean, PuterAPI.kv._set('test-key-1', 'Hello World from Pascal!'));
  if r then
    writeln('Result was true!');
  s:=AWait(String, PuterAPI.kv.get('test-key-1'));
  writeln('Value of key: ',s);
  r:=AWait(Boolean, PuterAPI.kv._set('test-key-2', 42));
  if r then
    writeln('Result was true!');
  i:=AWait(Integer, PuterAPI.kv.get('test-key-2'));
  writeln('Value of key: ',i);
  i:=AWait(Integer, puterAPI.kv.incr('test-key-2'));
  writeln('Value of key after incr: ',i);
  items:=AWait(TJSArray, puterAPI.kv.list);
  writeln('Key count: ',items.Length);
end;

function TMyApplication.SelectOpenFile(AEvent: TJSMouseEvent): Boolean;
begin
  Puter.OpenFileDialog;
end;

function TMyApplication.SelectSaveFile(AEvent: TJSMouseEvent): Boolean;
begin
  Puter.SaveFileDialog('This content was created from ObjectPascal!');
end;

function TMyApplication.SelectDirectory(AEvent: TJSMouseEvent): Boolean;
var
  p: TJSPromise;
begin
  p:=PuterAPI.ui.showDirectoryPicker;

end;

function TMyApplication.DoPuterAuth(AEvent: TJSMouseEvent): Boolean;
begin
  Puter.OnAuthSuccess:=@HandleAuth;
  Puter.AuthenticateWithPuter;
end;

function TMyApplication.DoPuterAlert(AEvent: TJSMouseEvent): Boolean;
begin
  Puter.Alert('Hello World from Puter Alert in ObjectPascal!');
end;

function TMyApplication.DoCreateWindow(AEvent: TJSMouseEvent): Boolean;
var
  options: TPuterWindowOptions;
begin
  options:=TPuterWindowOptions.new;
  options.title:='Hello World';
  options.content:='Hello World from Puter in ObjectPascal!';
  Puter.CreateWindow(options);
end;

function TMyApplication.DoExit(AEvent: TJSMouseEvent): Boolean;
begin
  Puter.Exit;
end;

function TMyApplication.DoLaunchApp(AEvent: TJSMouseEvent): Boolean;
begin
  Puter.LaunchApp('editor');
end;

function TMyApplication.DoColorPick(AEvent: TJSMouseEvent): Boolean;
begin
  Puter.ColorPicker;
end;

function TMyApplication.DoFontPick(AEvent: TJSMouseEvent): Boolean;
begin
  Puter.FontPicker;
end;

function TMyApplication.DoOpenBlog(AEvent: TJSMouseEvent): Boolean;
begin

end;

function TMyApplication.DoOpenBlogWin(AEvent: TJSMouseEvent): Boolean;
var
  options: TPuterWindowOptions;
begin
  options:=TPuterWindowOptions.new;
  options.title:='My Blog in a Puter Window!';
  options.uri:='https://kveroneau.github.io/';
  Puter.CreateWindow(options);
end;

function TMyApplication.DoPrompt(AEvent: TJSMouseEvent): Boolean;
begin
  Puter.Prompt('Please enter some text:', 'Some Prepopulared Text');
end;

function TMyApplication.DoArgsTest(AEvent: TJSMouseEvent): Boolean;
var
  args: TAppArgs;
begin
  args:=TAppArgs(TJSObject.new);
  with args do
  begin
    title:='Arg Test Title';
    message:='A message for the args test!';
    okay:=True;
    num:=42;
  end;
  PuterAPI.ui.launchApp(args);
end;

function TMyApplication.DoPuterHack(AEvent: TJSMouseEvent): Boolean;
var
  args: TAppArgs;
begin
  args:=TAppArgs(TJSObject.new);
  args.message:='Launching from Puter Test App!';
  args.okay:=True;
  PuterAPI.ui.launchApp('puterhack-pv0wh0r3l3', args);
end;

function TMyApplication.DoPuterDS(AEvent: TJSMouseEvent): Boolean;
var
  app: TPuterDS;
begin
  FPuterApp.innerHTML:='PuterDS Loading...';
  app:=TPuterDS.Create(Self);
  app.RunApp(FPuterApp);
end;

procedure TMyApplication.HandleAuth;
begin
  writeln('Auth was successful!');
end;

procedure TMyApplication.doRun;
var
  p: TJSPromise;
  args: TAppArgs;
begin
  FPuterApp:=TJSHTMLDivElement(GetHTMLElement('puter-app'));
  Puter.WindowTitle:='Puter Test Application';
  {Puter.WriteFile('test.txt', 'This was created using the new component.');}
  Puter.OnPuterError:=@ShowPuterError;
  puter.OnWriteSuccess:=@ShowFile;
  Puter.OnReadSuccess:=@ShowContent;
  Puter.OnDirListSuccess:=@ShowDirectory;
  Puter.OnUploadSuccess:=@UploadSuccess;
  puter.OnOpenFileSuccess:=@ShowFile;
  if PuterAPI.auth.isSignedIn then
    GetHTMLElement('puter-auth').hidden:=True;
  {puter.ReadFile('test.txt');
  puter.MakeDirectory('test-dir');
  puter.GetDirectory('/kveroneau');
  puter.RenameFile('test.txt', 'newname.txt');
  puter.CopyFile('newname.txt', 'test-dir/');
  puter.StatFile('test-dir/newname.txt');}
  FFileInput:=TJSHTMLInputElement(GetHTMLElement('file-input'));
  FFileInput.onchange:=@UploadFile;
  {KVTests;}
  GetHTMLElement('open-file').onclick:=@SelectOpenFile;
  GetHTMLElement('save-file').onclick:=@SelectSaveFile;
  GetHTMLElement('open-dir').onclick:=@SelectDirectory;
  GetHTMLElement('puter-auth').onclick:=@DoPuterAuth;
  GetHTMLElement('puter-alert').onclick:=@DoPuterAlert;
  GetHTMLElement('new-window').onclick:=@DoCreateWindow;
  GetHTMLElement('puter-exit').onclick:=@DoExit;
  GetHTMLElement('launch-app').onclick:=@DoLaunchApp;
  GetHTMLElement('pick-color').onclick:=@DoColorPick;
  GetHTMLElement('pick-font').onclick:=@DoFontPick;
  GetHTMLElement('github-blog').onclick:=@DoOpenBlog;
  GetHTMLElement('puter-prompt').onclick:=@DoPrompt;
  GetHTMLElement('args-test').onclick:=@DoArgsTest;
  GetHTMLElement('puter-hack').onclick:=@DoPuterHack;
  GetHTMLElement('puter-ds').onclick:=@DoPuterDS;
  writeln(PuterAPI.ui.env);
  args:=TAppArgs(PuterAPI.args);
  if args.okay then
    Writeln(args.message);
end;

var
  Application : TMyApplication;

begin
  Application:=TMyApplication.Create(nil);
  Application.Initialize;
  Application.Run;
end.
