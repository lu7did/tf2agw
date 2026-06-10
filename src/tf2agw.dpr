library tf2agw;

{***************************************************************************
  Approximate reconstruction of tf2agw.dll from the PE32 Delphi 5 binary.

  Original source was not available during reconstruction.  This file is
  intentionally conservative: it recreates the public ABI observed in the DLL
  export table and delegates behavior to TDEDTNC in DEDHost.pas.

  Observed exports in the binary:
    TfClose    ordinal 1
    TfOpen     ordinal 2
    TfPut      ordinal 3
    TfGet      ordinal 4
    TfChck     ordinal 5
    TfRegister ordinal 6

  The binary stubs use stdcall-style stack cleanup for functions with one
  argument, and no cleanup for functions with no argument.

  Compliance with AGWPE API protocol reflects the status at the writting
  of the original software (year 2000).

  As the original writer of the code I do have all pertinent copyright override
  over the content. The code was compliant with the license arrangements of The
  involved packages at the time of the writting.

  This work is licensed under a Creative Commons Attribution 4.0 International License.
  Permissions beyond the scope of this license may be available at
  Dr. Pedro E. Colla (LU7DZ) 2026 <pedro.colla@gmail.com>
***************************************************************************}

uses
  Windows,
  SysUtils,
  Classes,
  DEDHost in 'DEDHost.pas',
  HDEDVC in 'HDEDVC.pas',
  HexStr in 'HexStr.pas',
  ReqLib32 in 'ReqLib32.pas';

var
  GDEDHost: TDEDTNC = nil;

function TfClose: Boolean; stdcall;
begin
  if Assigned(GDEDHost) then
  begin
    GDEDHost.Free;
    GDEDHost := nil;
  end;
  Result := True;
end;

function TfOpen(Reserved: Integer): Boolean; stdcall;
begin
  { The original export accepts one 32-bit argument but the recovered stub
    does not appear to use it directly. }
  if not Assigned(GDEDHost) then
    GDEDHost := TDEDTNC.Create;
  Result := True;
end;

function TfPut(Ch: Byte): Boolean; stdcall;
begin
  if not Assigned(GDEDHost) then
    TfOpen(0);
  Result := GDEDHost.PutFromHost(Ch);
end;

function TfGet: Byte; stdcall;
begin
  if Assigned(GDEDHost) then
    Result := GDEDHost.GetToHost
  else
    Result := 0;
end;

function TfChck: Boolean; stdcall;
begin
  Result := Assigned(GDEDHost) and GDEDHost.HasDataForHost;
end;

function TfRegister(Wnd: HWND): Boolean; stdcall;
begin
  Result := False;
  if Assigned(GDEDHost) then
    Result := GDEDHost.RegisterHostWindow(Wnd);
end;

exports
  TfClose    index 1,
  TfOpen     index 2,
  TfPut      index 3,
  TfGet      index 4,
  TfChck     index 5,
  TfRegister index 6;

begin
end.
