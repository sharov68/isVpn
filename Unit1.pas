﻿unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.RegularExpressions,
  Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, Vcl.Menus;

type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    Memo1: TMemo;
    Timer1: TTimer;
    TrayIcon1: TTrayIcon;
    ImageList1: TImageList;
    PopupMenu1: TPopupMenu;
    CloseApp1: TMenuItem;
    ShowForm1: TMenuItem;
    Timer2: TTimer;
    procedure Timer1Timer(Sender: TObject);
    procedure CloseApp1Click(Sender: TObject);
    procedure ShowForm1Click(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
  private
    { Private declarations }
    procedure WMSysCommand(var Msg: TMessage); message WM_SYSCOMMAND;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.WMSysCommand(var Msg: TMessage);
begin
  // Проверяем, что команда — это SC_MINIMIZE (сворачивание)
  if (Msg.WParam = SC_MINIMIZE) then
  begin
    Form1.Hide;
  end
  else
    inherited; // Обрабатываем остальные команды стандартным образом
end;

function ExtractLastIPAddress(const Input: string): string;
var
  Regex: TRegEx;
  Matches: TMatchCollection;
begin
  Result := '';
  Regex := TRegEx.Create('\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', [roIgnoreCase]);
  Matches := Regex.Matches(Input);
  if Matches.Count > 0 then
    Result := Matches[Matches.Count - 1].Groups[1].Value; // Берём последнее совпадение и очищаем
end;

function ExecuteCmdCommand(const ACommand: string): string;
var
  SecurityAttributes: TSecurityAttributes;
  ReadPipe, WritePipe: THandle;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Buffer: array [0..1023] of AnsiChar;
  BytesRead: DWORD;
  CommandLine: string;
  Output: TStringList;
begin
  Result := '';
  Output := TStringList.Create;
  // Configure security attributes for the pipes
  SecurityAttributes.nLength := SizeOf(TSecurityAttributes);
  SecurityAttributes.bInheritHandle := True;
  SecurityAttributes.lpSecurityDescriptor := nil;
  // Create the pipes
  if not CreatePipe(ReadPipe, WritePipe, @SecurityAttributes, 0) then
    RaiseLastOSError;
  try
    // Initialize the startup info
    ZeroMemory(@StartupInfo, SizeOf(TStartupInfo));
    StartupInfo.cb := SizeOf(TStartupInfo);
    StartupInfo.hStdOutput := WritePipe;
    StartupInfo.hStdError := WritePipe;
    StartupInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    StartupInfo.wShowWindow := SW_HIDE;
    // Build the command line
    CommandLine := 'cmd.exe /C ' + ACommand;
    // Create the process
    if not CreateProcess(nil, PChar(CommandLine), nil, nil, True, 0, nil, nil, StartupInfo, ProcessInfo) then
      RaiseLastOSError;
    CloseHandle(WritePipe); // Close the write end of the pipe
    try
      // Read output from the read end of the pipe
      while ReadFile(ReadPipe, Buffer, SizeOf(Buffer) - 1, BytesRead, nil) and (BytesRead > 0) do
      begin
        Buffer[BytesRead] := #0;
        Output.Add(string(Buffer));
      end;
      Result := Output.Text;
    finally
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);
    end;
  finally
    CloseHandle(ReadPipe);
    Output.Free;
  end;
end;

procedure TForm1.CloseApp1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.ShowForm1Click(Sender: TObject);
begin
  Timer2.Enabled := false;
  Form1.Show;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  CmdOutput, IPAddress, row: string;
begin
  CmdOutput := ExecuteCmdCommand('powershell "(Invoke-WebRequest -Uri ''https://ifconfig.me'').Content"');
  IPAddress := ExtractLastIPAddress(CmdOutput);
  row := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '  ' +IPAddress;
  Memo1.Lines.Add(row);
  while Memo1.Lines.Count > 20 do
    Memo1.Lines.Delete(0); // Удаляем самую старую строку (первую)
  if IPAddress = '137.220.60.13' then
  begin
    TrayIcon1.IconIndex := 0;
    Form1.Color := clLime;
  end
  else
  begin
    TrayIcon1.IconIndex := 1;
    Form1.Color := clRed;
  end;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  Form1.Hide;
end;

end.
