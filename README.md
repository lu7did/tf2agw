# tf2agw.dll

##  Brief History 

This is a proxy hack to enable, the then early 32-bit Windows programs, willing to use AX.25 TNCs 
"The Firmware" (DED Protocol) to use the then novel and much more veratile AGW Packet Engine firmware.

The AGWPE firmware supported a wide range of TNC hardware models as well as a superb
(and then very marevelous) soft TNC using the sound card.

The timeframe was the late 90's, some 30sh years ago.

However, at the time, a very limited number of programs used or supported the AGW PE
firmware, so this Dynamic Linked Library came as a stop gap solution to expand, then
considerably, the then very limited horizon of applications that could take advantage
of the AGW Packet Engine (basically the demo program written by George SV2AGW).

George (SV2AGW) introduced an external API that allows a high level interaction with 
the AGW PE from other programs. The protocol then was documented and open, anyone could
use it as long as the AGW Packet Engine firmware program was properly licensed. At the time
AGW PE was essentially free for AX.25, native, applications but requires a licence to enable the operation using AX.25 TCP/IP. However, even if the API uses TCP/IP to connect 
between an external program and the engine it doesn't require AX.25 TCP/IP, therefore the 
API was completely free for all practical purposes.

As a bonus, AGWPE implemented then a virtual TNC called "loopback" which can be used 
by external programs to communicate among themselves as if it were using "on-the-air" links.

White and Jar means milk, I wrote tf2agw.dll to take advantage of that.

The program is really a simple one, it sits in one side listening with exports implementing
what a program using "The Firmware" (TF) would expect and for every call received 
map it to the corresponding API on the AGW PE, and also map the response from the AGWPE
back to the caller program when needed.

The program works surprinsingly well and got a wide acceptance then. 

## What was my stake at it

Although, as almost all the material I wrote for ham radio applications, was placed in the
public domain as **freeware** it was not my intention to write a product for general use, but 
something to help me on my specific needs although written with a generalistic perspective in
the (high) hopes that it might be useful for other similar situations.

At the time I ran a 7x24 AX.25 BBS using the surprinsingly versatile  
[TSTHWin program](https://www.qsl.net/iw0fol/packet/packetuk.htm) which is still available
although IW0FOL himself isn't longer available. This program was very simple to setup and operate,
it came with forward facilities and a surprinsingly large number of add-on and servers. I expanded
his operation quite largely with code of my own into a BBS running for years without issues, I love
that one.

However, the main stream of users adopting tf2agw.dll come from another tribe, the then almighty
*F6FBB BBS* software which ran almost all the AX.25 BBS infrastructure of the time. This BBS also
was able to run the DED protocol but (at the time) got no support for the AGW PE firmware, so be 
it, tf2agw.dll was a nice fit and manyfold users took advantage of it.

At the time I struggle with requests or claims about the usage of the dll with F6FBB which I was
unable to help as I never really ran it in my node which at the time operate a full fledged
AX.25-TCP/IP gateway (yes, Internet in the 90s), a FidoNet to AX.25 bridge, the BBS itself, a 
G8BPQ NETROM Node, a JNOS AX.25/TCP-IP node, a XNet node and manyfold other experiments, in a
humble 386 machine with little memory. I also ran by the time a program called 
**pescador** (spanish for "fishermen") which were able to recover AX.25 BBS forward just listening
at the forward of other nearby BBS without actively using radio slots, at the time the AX.25
operation were at 1200 bps and the BBS struggle to perform the mail forward in a dense 
metropolitan area so less RFI were greatly appreciated. Good times, good memories.


## And then ....

A lot of machine migrations, some home moving, turbulent times, not able to work AX.25 anymore for several years, then when I setup my station again the AX.25 activity almost
vanished (exception given for, perhaps, APRS activity), so I didn't push the development
of software related to the AGWPE any further.

Over the time on the early 2000's a machine crash wipped out the build chain of tf2agw and
the backups turned out to be useless. So any possibility to further develop the program was gone.

This crash not only wipped out tf2agw but all the BBS environment I ran for years, gone for good.

I did thought that it's function was done and nobody would care about that, surely enough I didn't care as I was not interested on the actual usage of the AGWPE engine any further.

The program has been always published (in binary form), and it's purpose was pretty confined so no additional functions were really needed, and the quality was surprinsingly
good so no bugs repair were needed either.

The program remained a living fossil for the next 25 years.

## Now....

However, over the time, I keep receiving consults about the program. Either small features,
support for the (vast) changes in the running environment since it has been written or support for new features and hardware. I declined over the time these requests in grounds
of not having interest in the Ham Radio AX.25 operation anymore, having lost the build 
environment and having no practical way to test the software.

I'm an active ham radio operator till now, and I'm engaged into developing software for 
our hobby. But my interests shifted away from developing for the Windows environment towards using especialized embedded platforms (such as the Arduino or Raspberry boards),
not using Delphi Pascal any longer and replacing it by C/C++ or even Python.

On top of that, George (SV2AGW) changed his mind on the open nature of the API and his site
now shows the following statement

```
License Agreement
You must not reverse engineering the TCPIP protocol that Packet Engine uses to communicate with
client applications.
This protocol copyright belongs to me and you cannot emulate it.
You can only use it for writing client applications.
Your program is totally independent from Packet Engine.
You can disturb your program any way you like.
Freeware, Shareware or as commercial application.
Since AGW Packet Engine is self-standing application its license agreement is not applied
to your program.
However the end user must respect the Packet Engine License agreement.
```
It doesn't really affect me in any way, and unless the API has been changed (which I 
don't know) the tf2agw program has been developed prior to that change in the license
so it's not bound by it. In fact the tf2agw program and the full documentation of the
AGW PE API (written by me in collaboration with George) has been available at the SV2AGW
site for decades but has been removed completely at some point over the past decade.

## Therefore....

As a nice technical exercise I took over the rebuild of the build environment of tf2agw, basically
the structure of the Delphi project, with some modern tools for that.

The resulting source code might require some tweaks to actually work, and if changes are made
to the AGW PE API protocol these has to be introduced. However, if the original tf2agw.dll still 
works in binary form it's likely this source code once properly re-built will work as well.

Enjoy...

# Technical description

This package isn't an exact build, but a high level rebuild of the original Delphi source code 
project from the available binaries such as:


- Dll Export table.
- Embedded PACKAGEINFO Delphi/VCL information.
- Recovered ASCII/Unicode strings.
- Imports Win32/VCL (`ScktComp`, `IniFiles`, `WinSock`, `Messages`, etc.).
- Exported stubs dis-assembly.

## Collected evidence

DLL:

- PE32/i386 Windows GUI DLL.
- Tamaño: 366080 bytes.
- SHA-256: `cc8c3365424f7dda3a592332bc33ab7da43f6f84e07a0a2b8a0bf78fa53309fc`.

Exports:

| Ordinal | Name |
|---:|---|
| 1 | `TfClose` |
| 2 | `TfOpen` |
| 3 | `TfPut` |
| 4 | `TfGet` |
| 5 | `TfChck` |
| 6 | `TfRegister` |

Detected Delphi units documented at `PACKAGEINFO`:

- `tf2agw`
- `HDEDVC`
- `DEDHost`
- `HexStr`
- `ReqLib32`
- VCL/RTL: `System`, `SysUtils`, `Classes`, `Forms`, `Controls`, `ScktComp`, `IniFiles`, `WinSock`, `Messages`, etc.

Observed Domain classes and strings:

- `TDEDTNC`
- `TDEDVC`
- `VCFrame`, `PortData`, `AGWFrames`, `AX25Channel`
- `TF2AGW.INI`, sección `AGWPE`, claves `IP_ADDRESS`, `TCP_PORT`, `DEBUG`, `TRACE`, `DRSI_FORMAT`
- `TF2AGW.LOG`, `DEDHOST.LOG`, `DEDVC.LOG`
- `*** TF2AGW Version 1.8 Build# 07 (c) LU7DID 1999,2000`
- `*** Linked with AGWPE at address`
- `*** Available ports at AGWPE:`
- `*** AGWPE Version`
- `Registering callsign`, `Unregistering callsign`
- `KissDecode`, `KissHeader`, `ProcessKISS`
- `Connect Req`, `Disconnect Req`, `CONNECTED`, `DISCONNECTED`, `SABM`, `DISC`, `RNR`, `REJ`, `FRMR`, `CSID`

## Regenerated API

Exported stubs shows a global variable containing a static instance of the variable TDEDTNC whose
public functions (methods) wrappers are:

```pascal
function TfOpen(Reserved: Integer): Boolean; stdcall;
function TfClose: Boolean; stdcall;
function TfPut(Ch: Byte): Boolean; stdcall;
function TfGet: Byte; stdcall;
function TfChck: Boolean; stdcall;
function TfRegister(Wnd: HWND): Boolean; stdcall;
```

`TfRegister` stores a callback handle `HWND` within the object.

## Limitations

- Original variable name has not been recovered.
- No original comments or program documentation has been recovered.
- The logic for the commands supported by DEDHOST and KISS/AX.25 command is an approximation to what the AGWPE protocol needs (at least then).
- The `ReqLib32` unit was actually a larger toolset library I used at the time (long since lost too) and only functions related to this program has been regenerated.
- It's likely that the calling conventions requires some adjust if the type `register` was expected instead of  `stdcall`; however `ret 4` at the export seems to be consistent with a stack management of the type `stdcall`.

## Further steps

Compilation with a modern Delphi 5/7 (or equivalent) build environment is needed, then execution with logging enabled calling the functions:

1. `TfOpen(0)`
2. `TfRegister(hwnd)`
3. Sequences of  `TfPut(...)`
4. Polling and resulst of `TfChck`/`TfGet`
5. `TfClose`

With a small iteration with a little experimentation a full functional compliance might be achieved.

# Package

The latest version of the package (version 1.8) is included which contains:

* The **tf2agw.dll** binary.
* A sample **tf2agw.ini** configuration file.
* A rather extensive and detailed documentation of the library in HTML format.

All this material is contained in the *bin* directory of the repository.

```
The documentation uses, refers and points to documentation and other links available at the moment
of the construction of the package (circa the year 2000), it's likely few of these links might be
non-existent or otherwise broken by now. Your mileage might vary.
```

