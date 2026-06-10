unit HDEDVC;

{***************************************************************************
  Approximate reconstruction of the unit name HDEDVC found in PACKAGEINFO.
  It models a DED virtual channel mapped to AGWPE frames.

  Copyright Dr. Pedro E. Colla (LU7DZ) 1999-2026 <pedro.colla@gmail.com>

***************************************************************************}

interface

uses
  Windows, SysUtils, Classes;

const
  MAX_TF_CHANNELS = 10;
  MAX_AGW_PORTS = 16;
  MAX_FRAME_DATA = 256;

  AGW_HEADER_SIZE = 36;

  AGW_KIND_VERSION       = 'R';
  AGW_KIND_PORT_INFO     = 'G';
  AGW_KIND_REGISTER      = 'X';
  AGW_KIND_UNREGISTER    = 'x';
  AGW_KIND_CONNECT       = 'C';
  AGW_KIND_DISCONNECT    = 'D';
  AGW_KIND_DATA          = 'D';
  AGW_KIND_MONITOR       = 'K';
  AGW_KIND_FRAMES_QUEUED = 'Y';
  AGW_KIND_TX_QUEUE      = 'y';

  AX25_CTL_SABM = $2F;
  AX25_CTL_DISC = $43;
  AX25_CTL_UA   = $63;
  AX25_CTL_DM   = $0F;
  AX25_CTL_FRMR = $87;
  AX25_PID_NONE = $F0;

  WM_TF2AGW_DATA = WM_USER + $2A0;

type
  TAGWHeader = packed record
    Port: Byte;
    Reserved1: Byte;
    Reserved2: Byte;
    Reserved3: Byte;
    DataKind: AnsiChar;
    Reserved4: Byte;
    PID: Byte;
    Reserved5: Byte;
    FromCall: array[0..9] of AnsiChar;
    ToCall: array[0..9] of AnsiChar;
    DataLen: Integer;
    User: Integer;
  end;

  TLinkState = (lsDisconnected, lsConnecting, lsConnected, lsDisconnecting);

  TAX25Frame = record
    Port: Integer;
    FromCall: string;
    ToCall: string;
    Via: string;
    Control: Byte;
    PID: Byte;
    Data: AnsiString;
  end;

  TDEDVC = class(TObject)
  private
    FChannel: Integer;
    FAGWPort: Integer;
    FMyCall: string;
    FPeerCall: string;
    FVia: string;
    FLinkState: TLinkState;
    FTxFrames: Integer;
    FRxFrames: Integer;
    FInfoBuffer: AnsiString;
  public
    constructor Create(AChannel: Integer);
    procedure Reset;
    function IsFree: Boolean;
    function Matches(const AMyCall, APeerCall: string; APort: Integer): Boolean;
    procedure Connected(const APeerCall: string; APort: Integer; const AVia: string);
    procedure Disconnected;
    procedure QueueInfo(const S: AnsiString);
    function PopInfo(var Ch: Byte): Boolean;

    property Channel: Integer read FChannel;
    property AGWPort: Integer read FAGWPort write FAGWPort;
    property MyCall: string read FMyCall write FMyCall;
    property PeerCall: string read FPeerCall write FPeerCall;
    property Via: string read FVia write FVia;
    property LinkState: TLinkState read FLinkState write FLinkState;
    property TxFrames: Integer read FTxFrames write FTxFrames;
    property RxFrames: Integer read FRxFrames write FRxFrames;
  end;

function NormalizeCall(const S: string): string;
function PackAGWCall(const S: string): string;
function AX25CallToText(const Buf: AnsiString): string;
function MakeAGWHeader(APort: Integer; AKind: AnsiChar; APID: Byte;
  const AFrom, ATo: string; ADataLen: Integer): TAGWHeader;
function HeaderKindName(Kind: AnsiChar): string;

implementation

constructor TDEDVC.Create(AChannel: Integer);
begin
  inherited Create;
  FChannel := AChannel;
  Reset;
end;

procedure TDEDVC.Reset;
begin
  FAGWPort := 0;
  FMyCall := '';
  FPeerCall := '';
  FVia := '';
  FLinkState := lsDisconnected;
  FTxFrames := 0;
  FRxFrames := 0;
  FInfoBuffer := '';
end;

function TDEDVC.IsFree: Boolean;
begin
  Result := FLinkState = lsDisconnected;
end;

function TDEDVC.Matches(const AMyCall, APeerCall: string; APort: Integer): Boolean;
begin
  Result := (FAGWPort = APort) and
            (CompareText(FMyCall, AMyCall) = 0) and
            (CompareText(FPeerCall, APeerCall) = 0);
end;

procedure TDEDVC.Connected(const APeerCall: string; APort: Integer; const AVia: string);
begin
  FAGWPort := APort;
  FPeerCall := NormalizeCall(APeerCall);
  FVia := AVia;
  FLinkState := lsConnected;
end;

procedure TDEDVC.Disconnected;
begin
  FPeerCall := '';
  FVia := '';
  FLinkState := lsDisconnected;
end;

procedure TDEDVC.QueueInfo(const S: AnsiString);
begin
  FInfoBuffer := FInfoBuffer + S;
end;

function TDEDVC.PopInfo(var Ch: Byte): Boolean;
begin
  Result := Length(FInfoBuffer) > 0;
  if Result then
  begin
    Ch := Ord(FInfoBuffer[1]);
    Delete(FInfoBuffer, 1, 1);
  end;
end;

function NormalizeCall(const S: string): string;
var
  P: Integer;
begin
  Result := UpperCase(Trim(S));
  P := Pos(#0, Result);
  if P > 0 then
    Delete(Result, P, MaxInt);
end;

function PackAGWCall(const S: string): string;
begin
  Result := Copy(NormalizeCall(S) + StringOfChar(#0, 10), 1, 10);
end;

function AX25CallToText(const Buf: AnsiString): string;
var
  I: Integer;
  C: Char;
  SSID: Integer;
begin
  Result := '';
  if Length(Buf) < 7 then
    Exit;

  for I := 1 to 6 do
  begin
    C := Chr(Ord(Buf[I]) shr 1);
    if C <> ' ' then
      Result := Result + C;
  end;

  SSID := (Ord(Buf[7]) shr 1) and $0F;
  if SSID <> 0 then
    Result := Result + '-' + IntToStr(SSID);
end;

function MakeAGWHeader(APort: Integer; AKind: AnsiChar; APID: Byte;
  const AFrom, ATo: string; ADataLen: Integer): TAGWHeader;
var
  S: AnsiString;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Port := APort;
  Result.DataKind := AKind;
  Result.PID := APID;
  S := PackAGWCall(AFrom);
  Move(S[1], Result.FromCall[0], 10);
  S := PackAGWCall(ATo);
  Move(S[1], Result.ToCall[0], 10);
  Result.DataLen := ADataLen;
end;

function HeaderKindName(Kind: AnsiChar): string;
begin
  case Kind of
    'C': Result := 'Connect';
    'D': Result := 'Disconnect/Data';
    'G': Result := 'Port information';
    'K': Result := 'Monitor frame';
    'R': Result := 'Version';
    'X': Result := 'Register callsign';
    'x': Result := 'Unregister callsign';
    'Y': Result := 'Outstanding frames';
    'y': Result := 'Transmitted frame';
  else
    Result := 'Unknown';
  end;
end;

end.
