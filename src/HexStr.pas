unit HexStr;

interface

uses SysUtils;

function ByteToHex(B: Byte): string;
function DumpHex(const S: AnsiString): string;

implementation

function ByteToHex(B: Byte): string;
const
  H: array[0..15] of Char = '0123456789ABCDEF';
begin
  Result := H[B shr 4] + H[B and $0F];
end;

function DumpHex(const S: AnsiString): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    if I > 1 then
      Result := Result + ' ';
    Result := Result + ByteToHex(Ord(S[I]));
  end;
end;

end.
