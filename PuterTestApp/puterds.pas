unit PuterDS;

{$mode ObjFPC}

interface

uses
  Classes, SysUtils, JS, jsontable, Web, puterjs;

type

  { TPuterDS }

  TPuterDS = Class(TComponent)
  private
    FPuterDB: TJSONTable;
    FApp: TJSHTMLDivElement;
    procedure AppRun;
    function SaveClick(AEvent: TJSMouseEvent): Boolean;
    function LoadClick(AEvent: TJSMouseEvent): Boolean;
    function AddRecord(AEvent: TJSMouseEvent): Boolean;
    procedure OpenDataset(AFile: TPuterFSItem);
  public
    constructor Create(AOwner: TComponent); override;
    procedure RunApp(ADiv: TJSHTMLDivElement);
  end;

implementation

function MakeButton(title: string; onclick: THTMLClickEventHandler): TJSHTMLButtonElement;
begin
  Result:=TJSHTMLButtonElement(document.createElement('button'));
  Result.innerText:=title;
  Result.onclick:=onclick;
end;

{ TPuterDS }

procedure TPuterDS.AppRun;
var
  btn: TJSHTMLButtonElement;
begin
  FApp.innerHTML:=FPuterDB.Strings['Message']+'<br/>';
  btn:=MakeButton('Save Dataset', @SaveClick);
  FApp.appendChild(btn);
  btn:=MakeButton('Load Dataset', @LoadClick);
  FApp.appendChild(btn);
  FApp.appendChild(MakeButton('Append Record', @AddRecord));
end;

function TPuterDS.SaveClick(AEvent: TJSMouseEvent): Boolean;
begin
  Puter.SaveFileDialog(FPuterDB.GetJSON);
end;

function TPuterDS.LoadClick(AEvent: TJSMouseEvent): Boolean;
begin
  Puter.OnOpenFileSuccess:=@OpenDataset;
  puter.OpenFileDialog;
end;

function TPuterDS.AddRecord(AEvent: TJSMouseEvent): Boolean;
begin
  FPuterDB.DataSet.Append;
  FPuterDB.Ints['Id']:=2;
  FPuterDB.Strings['Message']:='A new record added in ObjectPascal!';
  FPuterDB.DataSet.Post;
end;

procedure TPuterDS.OpenDataset(AFile: TPuterFSItem);
begin
  FPuterDB.Active:=False;
  FPuterDB.Free;
  FPuterDB:=TJSONTable.Create(Self);
  FPuterDB.ParseTable(AFile.content);
  FApp.innerHTML:=FPuterDB.Strings['Message'];
end;

constructor TPuterDS.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPuterDB:=TJSONTable.Create(Self);
  FPuterDB.OnSuccess:=@AppRun;
  FPuterDB.Datafile:='sample';
end;

procedure TPuterDS.RunApp(ADiv: TJSHTMLDivElement);
begin
  FApp:=ADiv;
  FPuterDB.Active:=True;
end;

end.

