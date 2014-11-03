unit ce_cdbcmd;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  process, Menus, StdCtrls, ce_widget, ce_project, ce_interfaces, ce_observer,
  asyncprocess, ComCtrls, Buttons, ce_common;

type

  { TCECdbWidget }
  TCECdbWidget = class(TCEWidget, ICEProjectObserver)
    btnGo: TSpeedButton;
    btnStep: TSpeedButton;
    btnDisasm: TSpeedButton;
    btnStop: TSpeedButton;
    btnStart: TSpeedButton;
    txtCdbCmd: TEdit;
    lstCdbOut: TListView;
    Panel1: TPanel;
    procedure btnDisasmClick(Sender: TObject);
    procedure btnGoClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStepClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure txtCdbCmdKeyPress(Sender: TObject; var Key: char);
  private
    fCdbProc: TAsyncProcess;
    fProject: TCEProject;
    procedure cdbOutput(sender: TObject);
    procedure cdbTerminate(sender: TObject);
    procedure cdbOutputToGui;
    procedure cdbFree;
  public
    constructor create(aOwner: TComponent); override;
    destructor destroy; override;
    //
    procedure projNew(const aProject: TCEProject);
    procedure projClosing(const aProject: TCEProject);
    procedure projFocused(const aProject: TCEProject);
    procedure projChanged(const aProject: TCEProject);
  end;

implementation
{$R *.lfm}

uses
  ce_main;

{$REGION Standard Comp/Obj------------------------------------------------------}
constructor TCECdbWidget.create(aOwner: TComponent);
begin
  inherited;
  Enabled := exeInSysPath('cdb');
  if Enabled then
    EntitiesConnector.addObserver(self);
end;

destructor TCECdbWidget.destroy;
begin
  if Enabled then begin
    cdbFree;
    EntitiesConnector.removeObserver(self);
  end;
  inherited;
end;
{$ENDREGION --------------------------------------------------------------------}

{$REGION ICEProjectMonitor -----------------------------------------------------}
procedure TCECdbWidget.projNew(const aProject: TCEProject);
begin
  fProject := aProject;
end;

procedure TCECdbWidget.projClosing(const aProject: TCEProject);
begin
  fProject := nil;
end;

procedure TCECdbWidget.projFocused(const aProject: TCEProject);
begin
  fProject := aProject;
end;

procedure TCECdbWidget.projChanged(const aProject: TCEProject);
begin
  fProject := aProject;
end;
{$ENDREGION --------------------------------------------------------------------}

procedure TCECdbWidget.btnStartClick(Sender: TObject);
var
  outname: string;
begin
  if fProject = nil then exit;
  outname := fProject.outputFilename;
  if not fileExists(outname) then exit;
  //
  cdbFree;
  fCdbProc := TAsyncProcess.create(nil);
  fCdbProc.Executable := 'cdb';
  fCdbProc.Parameters.Add('-c');
  fCdbProc.Parameters.Add('"l+*;.lines"');
  fCdbProc.Parameters.Add(outname);
  fCdbProc.CurrentDirectory := extractFilePath(outname);
  fCdbProc.Options := [poNoConsole, poStderrToOutPut, poUsePipes];
  fCdbProc.OnReadData := @cdbOutput;
  fCdbProc.OnTerminate := @cdbTerminate;
  //
  fCdbProc.Execute;
end;

procedure TCECdbWidget.btnStepClick(Sender: TObject);
const
  cmd = 'p'#13#10;
begin
  if fCdbProc = nil then exit;
  fCdbProc.Input.Write(cmd[1], length(cmd));
end;

procedure TCECdbWidget.btnGoClick(Sender: TObject);
const
  cmd = 'g'#13#10;
begin
  if fCdbProc = nil then exit;
  fCdbProc.Input.Write(cmd[1], length(cmd));
end;

procedure TCECdbWidget.btnDisasmClick(Sender: TObject);
const
  cmd = 'u'#13#10;
begin
  if fCdbProc = nil then exit;
  fCdbProc.Input.Write(cmd[1], length(cmd));
end;

procedure TCECdbWidget.btnStopClick(Sender: TObject);
begin
  cdbFree;
end;

procedure TCECdbWidget.Button2Click(Sender: TObject);
begin

end;

procedure TCECdbWidget.txtCdbCmdKeyPress(Sender: TObject; var Key: char);
var
  inp: string;
begin
  if (fCdbProc = nil) or (key <> #13) then
    exit;
  //
  inp := CEMainForm.expandSymbolicString(txtCdbCmd.Text) + LineEnding;
  fCdbProc.Input.Write(inp[1], length(inp));
  //
  inp := lstCdbOut.Items.Item[lstCdbOut.Items.Count-1].Caption;
  inp += CEMainForm.expandSymbolicString(txtCdbCmd.Text);
  lstCdbOut.Items.Item[lstCdbOut.Items.Count-1].Caption := inp;
  //
  txtCdbCmd.Text := '';
end;

procedure TCECdbWidget.cdbOutputToGui;
var
  str: TMemoryStream;
  lst: TStringList;
  cnt: Integer;
  sum: Integer;
begin
  if fCdbProc = nil then exit;

  cnt := 0;
  sum := 0;
  str := TMemoryStream.Create;
  lst := TStringList.Create;

  while fCdbProc.Output.NumBytesAvailable <> 0 do
  begin
    str.Size := str.Size + 1024;
    cnt := fCdbProc.Output.Read((str.Memory + sum)^, 1024);
    sum += cnt;
  end;

  str.Size := sum;
  lst.LoadFromStream(str);

  for cnt := 0 to lst.Count-1 do
    lstCdbOut.AddItem(lst.Strings[cnt], nil);
  lstCdbOut.Items[lstCdbOut.Items.Count-1].MakeVisible(true);

  lst.Free;
  str.Free;
end;

procedure TCECdbWidget.cdbOutput(sender: TObject);
begin
  cdbOutputToGui;
end;

procedure TCECdbWidget.cdbTerminate(sender: TObject);
begin
  cdbOutputToGui;
  cdbFree;
end;

procedure TCECdbWidget.cdbFree;
begin
  if fCdbProc = nil then
    exit;
  //
  if fCdbProc.Running then
    fCdbProc.Terminate(0);
  fCdbProc.Free;
    fCdbProc := nil;
end;

end.
