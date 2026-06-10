unit ReqLib32;

{ ***************************************************************************
  Minimal placeholder for the ReqLib32 unit name found in PACKAGEINFO.
  The original unit likely wrapped host-library request/notification helpers
  
  Approximate reconstruction of the unit DEDHost found in PACKAGEINFO.

  It is NOT a byte-for-byte decompilation.  Names, field layout and several
  corner cases are reconstructed from strings, exports and protocol knowledge.

  Copyright Dr. Pedro E. Colla (LU7DZ) 1999-2026 <pedro.colla@gmail.com>

*************************************************************************** }

interface

uses Windows;

procedure SafePostMessage(Wnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM);

implementation

procedure SafePostMessage(Wnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM);
begin
  if Wnd <> 0 then
    PostMessage(Wnd, Msg, WParam, LParam);
end;

end.
