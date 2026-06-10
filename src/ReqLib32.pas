unit ReqLib32;

{ Minimal placeholder for the ReqLib32 unit name found in PACKAGEINFO.
  The original unit likely wrapped host-library request/notification helpers. }

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
