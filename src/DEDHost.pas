unit DEDHost;

{***************************************************************************
  Approximate reconstruction of the unit DEDHost found in PACKAGEINFO.

  This unit implements the public behavior suggested by recovered strings:
  - Reads TF2AGW.INI / section AGWPE / IP_ADDRESS / TCP_PORT / TRACE.
  - Maintains virtual TNC channels.
  - Translates host commands resembling DED/TF host mode into AGWPE TCP frames.
  - Receives AGWPE frames and exposes bytes through TfGet/TfChck.

  It is NOT a byte-for-byte decompilation.  Names, field layout and several
  corner cases are reconstructed from strings, exports and protocol knowledge.

  Copyright Dr. Pedro E. Colla (LU7DZ) 1999-2026 <pedro.colla@gmail.com>
***************************************************************************}

interface

uses
  Windows, Messages, SysUtils, Classes, IniFiles, ScktComp,
  HDEDVC;

type
  TDEDTNC = class(TObject)
  private
    FChannels: array[0..MAX_TF_CHANNELS - 1] of TDEDVC;
    FAGWClient: TClientSocket;
    FHostWindow: HWND;
    FToHost: AnsiString;
    FCommandBuffer: AnsiString;
    FIncoming: AnsiString;
    FIPAddress: string;
    FTCPPort: Integer;
    FTrace: Boolean;
    FDebug: Boolean;
    FDRSIFormat: Boolean;
    FConnected: Boolean;
    FDefaultCall: string;
    FLogFile: string;

    procedure LoadConfig;
    procedure Log(const S: string);
    procedure PostHostNotification;
    function FirstFreeChannel: Integer;
    function ValidChannel(Channel: Integer): Boolean;
    function ParseHostCommand(const Line: AnsiString): Boolean;
    procedure QueueToHost(const S: AnsiString);
    procedure QueueLineToHost(Channel: Integer; const S: string);
    procedure EnsureSocket;
    procedure CloseSocket;
    procedure SendAGWFrame(APort: Integer; AKind: AnsiChar; APID: Byte;
      const AFrom, ATo: string; const Payload: AnsiString);
    procedure RequestInitInformation;
    procedure RegisterCallsign(const Call: string);
    procedure UnregisterCallsign(const Call: string);
    procedure DecodeAGWFrame(const Header: TAGWHeader; const Payload: AnsiString);
    procedure DecodeMonitorFrame(APort: Integer; const Payload: AnsiString);
    procedure DecodeDataFrame(APort: Integer; const FromCall, ToCall: string;
      const Payload: AnsiString);
    function FindChannel(const MyCall, PeerCall: string; APort: Integer): Integer;

    procedure SocketConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure SocketDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure SocketRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure SocketError(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    function RegisterHostWindow(Wnd: HWND): Boolean;
    function PutFromHost(Ch: Byte): Boolean;
    function GetToHost: Byte;
    function HasDataForHost: Boolean;
    procedure Shutdown;
  end;

implementation

const
  CR = #13;
  LF = #10;

constructor TDEDTNC.Create;
var
  I: Integer;
begin
  inherited Create;
  FHostWindow := 0;
  FToHost := '';
  FCommandBuffer := '';
  FIncoming := '';
  FDefaultCall := '';
  FConnected := False;
  LoadConfig;

  Log('Virtual The Firmware Channels created');
  for I := Low(FChannels) to High(FChannels) do
    FChannels[I] := TDEDVC.Create(I);

  EnsureSocket;
end;

destructor TDEDTNC.Destroy;
var
  I: Integer;
begin
  Log('Entering Destroy of AGWClient');
  Shutdown;
  for I := Low(FChannels) to High(FChannels) do
    FChannels[I].Free;
  inherited Destroy;
end;

procedure TDEDTNC.LoadConfig;
var
  Ini: TIniFile;
  Path: string;
begin
  Path := ExtractFilePath(ParamStr(0)) + 'TF2AGW.INI';
  Ini := TIniFile.Create(Path);
  try
    FIPAddress := Ini.ReadString('AGWPE', 'IP_ADDRESS', '127.0.0.1');
    FTCPPort := Ini.ReadInteger('AGWPE', 'TCP_PORT', 8000);
    FDebug := SameText(Ini.ReadString('AGWPE', 'DEBUG', 'NOT'), 'YES');
    FTrace := SameText(Ini.ReadString('AGWPE', 'TRACE', 'NOT'), 'YES');
    FDRSIFormat := SameText(Ini.ReadString('AGWPE', 'DRSI_FORMAT', 'OFF'), 'YES');
    FLogFile := ExtractFilePath(ParamStr(0)) + 'TF2AGW.LOG';
  finally
    Ini.Free;
  end;

  Log('*** TF2AGW Version 1.8 Build# 07 (c) LU7DID 1999,2000');
  Log('Data from TF2AGW.INI is IP:' + FIPAddress + ' Port:' + IntToStr(FTCPPort));
  if FDRSIFormat then
    Log('*** DRSI Compatibility mode activated');
end;

procedure TDEDTNC.Log(const S: string);
var
  F: TextFile;
begin
  if not (FTrace or FDebug) then
    Exit;
  AssignFile(F, FLogFile);
  if FileExists(FLogFile) then
    Append(F)
  else
    Rewrite(F);
  try
    Writeln(F, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' -- ' + S);
  finally
    CloseFile(F);
  end;
end;

procedure TDEDTNC.EnsureSocket;
begin
  if Assigned(FAGWClient) then
    Exit;

  Log('Creating the Client object');
  FAGWClient := TClientSocket.Create(nil);
  FAGWClient.ClientType := ctNonBlocking;
  FAGWClient.Host := FIPAddress;
  FAGWClient.Port := FTCPPort;
  FAGWClient.OnConnect := SocketConnect;
  FAGWClient.OnDisconnect := SocketDisconnect;
  FAGWClient.OnRead := SocketRead;
  FAGWClient.OnError := SocketError;

  Log('Creating the Socket connection');
  try
    FAGWClient.Active := True;
    Log('Socket creation completed');
  except
    on E: Exception do
      Log('Sentry: Trying to connect with ' + FIPAddress + ':' + IntToStr(FTCPPort) + ' failed: ' + E.Message);
  end;
end;

procedure TDEDTNC.CloseSocket;
begin
  if Assigned(FAGWClient) then
  begin
    Log('Entering Close of AGWClient');
    try
      FAGWClient.Active := False;
    except
    end;
    FreeAndNil(FAGWClient);
  end;
  FConnected := False;
end;

procedure TDEDTNC.Shutdown;
begin
  CloseSocket;
end;

function TDEDTNC.RegisterHostWindow(Wnd: HWND): Boolean;
begin
  Result := FHostWindow = 0;
  if Result then
    FHostWindow := Wnd;
end;

procedure TDEDTNC.PostHostNotification;
begin
  if FHostWindow <> 0 then
    PostMessage(FHostWindow, WM_TF2AGW_DATA, 0, 0);
end;

procedure TDEDTNC.QueueToHost(const S: AnsiString);
begin
  if S = '' then
    Exit;
  FToHost := FToHost + S;
  PostHostNotification;
end;

procedure TDEDTNC.QueueLineToHost(Channel: Integer; const S: string);
begin
  { Reconstructed DED host response convention: channel-prefixed text line. }
  QueueToHost(AnsiString(Chr(Channel) + S + CR));
end;

function TDEDTNC.HasDataForHost: Boolean;
begin
  Result := Length(FToHost) > 0;
end;

function TDEDTNC.GetToHost: Byte;
begin
  if Length(FToHost) = 0 then
    Result := 0
  else
  begin
    Result := Ord(FToHost[1]);
    Delete(FToHost, 1, 1);
  end;
end;

function TDEDTNC.PutFromHost(Ch: Byte): Boolean;
begin
  Result := True;
  FCommandBuffer := FCommandBuffer + AnsiChar(Ch);

  if (Ch = Ord(CR)) or (Ch = Ord(LF)) then
  begin
    while (Length(FCommandBuffer) > 0) and
          (FCommandBuffer[Length(FCommandBuffer)] in [CR, LF]) do
      Delete(FCommandBuffer, Length(FCommandBuffer), 1);

    if FCommandBuffer <> '' then
      ParseHostCommand(FCommandBuffer);
    FCommandBuffer := '';
  end;
end;

function TDEDTNC.ValidChannel(Channel: Integer): Boolean;
begin
  Result := (Channel >= Low(FChannels)) and (Channel <= High(FChannels));
end;

function TDEDTNC.FirstFreeChannel: Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := Low(FChannels) to High(FChannels) do
    if FChannels[I].IsFree then
    begin
      Result := I;
      Break;
    end;
end;

function TDEDTNC.FindChannel(const MyCall, PeerCall: string; APort: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := Low(FChannels) to High(FChannels) do
    if FChannels[I].Matches(MyCall, PeerCall, APort) then
    begin
      Result := I;
      Break;
    end;
end;

function TDEDTNC.ParseHostCommand(const Line: AnsiString): Boolean;
var
  Cmd: Char;
  Args, A, B, C: string;
  Channel, PortNo, P: Integer;
begin
  Result := True;
  if Line = '' then
    Exit;

  Log('Host->TNC Raw Command Buffer Received');
  Cmd := UpCase(Char(Line[1]));
  Args := Trim(string(Copy(Line, 2, MaxInt)));
  Channel := 0;

  case Cmd of
    'J':
      begin
        QueueLineToHost(0, 'JHOST');
      end;

    'I':
      begin
        Log('I Command with ArgN=' + Args);
        FDefaultCall := NormalizeCall(Args);
        if FDefaultCall = '' then
          Log('Entering empty MYCALL')
        else
          Log('MYCall Set');
        RegisterCallsign(FDefaultCall);
        QueueLineToHost(0, 'MYCALL ' + FDefaultCall);
      end;

    'G':
      begin
        Log('<G> ArgN=' + Args);
        QueueLineToHost(0, '*** Available ports at AGWPE:');
      end;

    'C':
      begin
        { Approximate command: C <channel> <port> <call> [via ...] }
        Log('C Command with ArgN=' + Args);
        Channel := FirstFreeChannel;
        PortNo := 0;
        A := Args;
        B := '';
        C := '';

        P := Pos(' ', A);
        if P > 0 then
        begin
          B := Trim(Copy(A, P + 1, MaxInt));
          A := Trim(Copy(A, 1, P - 1));
        end;
        P := Pos(' ', B);
        if P > 0 then
        begin
          C := Trim(Copy(B, P + 1, MaxInt));
          B := Trim(Copy(B, 1, P - 1));
        end;

        if A <> '' then
          PortNo := StrToIntDef(A, 0);
        if B = '' then
          B := A;

        if Channel < 0 then
        begin
          QueueLineToHost(0, 'TNC BUSY - LINE IGNORED');
          Exit;
        end;

        FChannels[Channel].AGWPort := PortNo;
        FChannels[Channel].MyCall := FDefaultCall;
        FChannels[Channel].PeerCall := NormalizeCall(B);
        FChannels[Channel].Via := C;
        FChannels[Channel].LinkState := lsConnecting;

        Log('C Command Arguments Ch=' + IntToStr(Channel) +
          ' Port=' + IntToStr(PortNo) + ' CallSign=' + B + ' VIA=' + C);
        SendAGWFrame(PortNo, AGW_KIND_CONNECT, 0, FDefaultCall, B, AnsiString(C));
        QueueLineToHost(Channel, 'C Command -- Connect Ok --');
      end;

    'D':
      begin
        Channel := StrToIntDef(Args, 0);
        Log('D Command with ArgN=' + Args);
        if not ValidChannel(Channel) then
        begin
          QueueLineToHost(0, 'INVALID CHANNEL NUMBER');
          Exit;
        end;
        if FChannels[Channel].LinkState = lsDisconnected then
        begin
          QueueLineToHost(Channel, 'CHANNEL NOT CONNECTED');
          Exit;
        end;
        SendAGWFrame(FChannels[Channel].AGWPort, AGW_KIND_DISCONNECT, 0,
          FChannels[Channel].MyCall, FChannels[Channel].PeerCall, '');
        FChannels[Channel].Disconnected;
        QueueLineToHost(Channel, 'DISCONNECTED fm ' + FDefaultCall);
      end;

  else
    Log('TNC BUSY - LINE IGNORED');
    QueueLineToHost(0, 'TNC BUSY - LINE IGNORED');
  end;
end;

procedure TDEDTNC.SendAGWFrame(APort: Integer; AKind: AnsiChar; APID: Byte;
  const AFrom, ATo: string; const Payload: AnsiString);
var
  Header: TAGWHeader;
  OutBuf: AnsiString;
begin
  if not FConnected then
  begin
    Log('AGWPE Not connected, ignoring Write request');
    Exit;
  end;

  Header := MakeAGWHeader(APort, AKind, APID, AFrom, ATo, Length(Payload));
  SetLength(OutBuf, SizeOf(Header) + Length(Payload));
  Move(Header, OutBuf[1], SizeOf(Header));
  if Payload <> '' then
    Move(Payload[1], OutBuf[SizeOf(Header) + 1], Length(Payload));

  Log('SEND to AGWPE:Port {' + IntToStr(APort) + '} DataKind (' + AKind +
    ') From <' + AFrom + '> To <' + ATo + '> Len (' + IntToStr(Length(Payload)) + ')');
  FAGWClient.Socket.SendBuf(OutBuf[1], Length(OutBuf));
end;

procedure TDEDTNC.RequestInitInformation;
begin
  Log('Requesting init information from AGWPE');
  SendAGWFrame(0, AGW_KIND_VERSION, 0, '', '', '');
  SendAGWFrame(0, AGW_KIND_PORT_INFO, 0, '', '', '');
end;

procedure TDEDTNC.RegisterCallsign(const Call: string);
begin
  if Call = '' then
    Exit;
  Log('Registering callsign ' + Call);
  SendAGWFrame(0, AGW_KIND_REGISTER, 0, Call, '', '');
end;

procedure TDEDTNC.UnregisterCallsign(const Call: string);
begin
  if Call = '' then
    Exit;
  Log('Unregistering callsign ' + Call);
  SendAGWFrame(0, AGW_KIND_UNREGISTER, 0, Call, '', '');
end;

procedure TDEDTNC.SocketConnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  FConnected := True;
  Log('TCP/IP Socket established with AGWPE <event>');
  QueueToHost('*** Linked with AGWPE at address ' + AnsiString(FIPAddress) + CR);
  if FDefaultCall <> '' then
    RegisterCallsign(FDefaultCall);
  RequestInitInformation;
end;

procedure TDEDTNC.SocketDisconnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  FConnected := False;
  Log('Socket disconnect from AGWPE <event>');
  QueueToHost('*** Link with AGWPE is broken.' + CR);
end;

procedure TDEDTNC.SocketError(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  Log('Socket error from AGWPE error=' + IntToStr(ErrorCode) + ' Type=<event>');
  ErrorCode := 0;
  FConnected := False;
end;

procedure TDEDTNC.SocketRead(Sender: TObject; Socket: TCustomWinSocket);
var
  Buf: array[0..2047] of AnsiChar;
  N: Integer;
  Header: TAGWHeader;
  Payload: AnsiString;
begin
  N := Socket.ReceiveBuf(Buf, SizeOf(Buf));
  if N <= 0 then
    Exit;
  FIncoming := FIncoming + Copy(AnsiString(Buf), 1, N);

  while Length(FIncoming) >= AGW_HEADER_SIZE do
  begin
    Move(FIncoming[1], Header, SizeOf(Header));
    if Header.DataLen < 0 then
    begin
      Log('Garbage detected on AGWPE Message ' + Header.DataKind + ':');
      FIncoming := '';
      Exit;
    end;
    if Length(FIncoming) < AGW_HEADER_SIZE + Header.DataLen then
      Exit;

    Payload := Copy(FIncoming, AGW_HEADER_SIZE + 1, Header.DataLen);
    Delete(FIncoming, 1, AGW_HEADER_SIZE + Header.DataLen);
    DecodeAGWFrame(Header, Payload);
  end;
end;

procedure TDEDTNC.DecodeAGWFrame(const Header: TAGWHeader; const Payload: AnsiString);
var
  FromCall, ToCall: string;
begin
  FromCall := NormalizeCall(string(Header.FromCall));
  ToCall := NormalizeCall(string(Header.ToCall));
  Log('Decoded Port{' + IntToStr(Header.Port) + '} DataKind[' + Header.DataKind +
    '] <' + FromCall + '> <' + ToCall + '> Len=(' + IntToStr(Header.DataLen) + ')');

  case Header.DataKind of
    'K': DecodeMonitorFrame(Header.Port, Payload);
    'D': DecodeDataFrame(Header.Port, FromCall, ToCall, Payload);
    'C': QueueToHost('CONNECTED With ' + AnsiString(FromCall) + CR);
    'd': QueueToHost('DISCONNECTED From ' + AnsiString(FromCall) + CR);
    'G': QueueToHost('*** Available ports at AGWPE:' + CR + Payload + CR);
    'R': QueueToHost('*** AGWPE Version ' + Payload + CR);
    'X': QueueToHost('*** Registered with AGWPE the callsign ' + AnsiString(FromCall) + CR);
    'x': QueueToHost('*** Unregistered with AGWPE the callsign ' + AnsiString(FromCall) + CR);
    'Y', 'y': Log('Detected Frame <' + Header.DataKind + '> Frames');
  else
    Log('ERROR Unknown type after Decode');
  end;
end;

procedure TDEDTNC.DecodeMonitorFrame(APort: Integer; const Payload: AnsiString);
begin
  Log('AGW Message <K>');
  QueueToHost('<KissDecode> Received Frame' + CR + Payload + CR);
end;

procedure TDEDTNC.DecodeDataFrame(APort: Integer; const FromCall, ToCall: string;
  const Payload: AnsiString);
var
  Ch: Integer;
begin
  Ch := FindChannel(ToCall, FromCall, APort);
  if Ch < 0 then
  begin
    Log('Looking for a match szMyCall=' + ToCall + ' szYourCall=' + FromCall);
    Exit;
  end;

  Inc(FChannels[Ch].FRxFrames);
  Log('Data being sent to Host len(' + IntToStr(Length(Payload)) + ') is');
  QueueToHost(AnsiString(Chr(Ch)) + Payload + CR);
end;

end.
