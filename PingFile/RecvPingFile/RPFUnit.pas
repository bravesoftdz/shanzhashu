unit RPFUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, FileCtrl, WinSock2, Buttons;

const
  ICMPDLL = 'icmp.dll';
  WS2_32DLL = 'WS2_32.DLL';
  MAXIPNOTE = 255;
  IPJOIN = '.';
  IPADDRFORMAT = '%0:D.%1:D.%2:D.%3:D';
  SIO_GET_INTERFACE_LIST = $4004747F;
  IFF_UP = $00000001;
  IFF_BROADCAST = $00000002;
  IFF_LOOPBACK = $00000004;
  IFF_POINTTOPOINT = $00000008;
  IFF_MULTICAST = $00000010;
  IPNOTE1 = $FF000000;
  IPNOTE2 = $00FF0000;
  IPNOTE3 = $0000FF00;
  IPNOTE4 = $000000FF;

type
  TRPFForm = class(TForm)
    lblDir: TLabel;
    edtDir: TEdit;
    btnBrowse: TButton;
    btnRecv: TButton;
    pbRecv: TProgressBar;
    lblRecvFrom: TLabel;
    cbbIP: TComboBox;
    lblLocal: TLabel;
    edtFromIp: TEdit;
    lblTimeout: TLabel;
    edtTimeout: TEdit;
    udTimeout: TUpDown;
    btnCopy: TSpeedButton;
    lblProgress: TLabel;
    procedure btnBrowseClick(Sender: TObject);
    procedure btnRecvClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
  private
    FRecving: Boolean;
    FSnifSock: Integer;
    procedure UpdateButtonState;
    procedure StartSniff;
    procedure StopSniff;
  public
    { Public declarations }
  end;

  TIpInfo = record
    Address: Int64;
    IP: string;
    Host: string;
  end;

  TIP_NetType = (iptNone, iptANet, iptBNet, iptCNet, iptDNet, iptENet,
    iptBroadCast, iptKeepAddr);

  TIPNotes = array[1..4] of Byte;

  TIP_Info = packed record
    IPAddress: Cardinal;                 // IP地址,此处用整形存储
    SubnetMask: Cardinal;                // 子网掩码,此处用整形存储
    Broadcast: Cardinal;                 // 广播地址,此处用整形存储
    HostName: array[0..255] of AnsiChar; // 主机名
    NetType: TIP_NetType;                // IP地址的网络类型
    Notes: TIPNotes;                     // IP地址的各子节点
    UpState: Boolean;                    // 启用状态
    Loopback: Boolean;                   // 是否环回地址
    SupportBroadcast: Boolean;           // 是否支持广播
  end;

  TIPGroup = array of TIP_Info; //IP地址组

  sockaddr_gen = packed record
    AddressIn: sockaddr_in;
    filler: packed array[0..7] of AnsiChar;
  end;

  TINTERFACE_INFO = packed record
    iiFlags: u_long; // Interface flags
    iiAddress: sockaddr_gen; // Interface address
    iiBroadcastAddress: sockaddr_gen; // Broadcast address
    iiNetmask: sockaddr_gen; // Network mask
  end;

  TWSAIoctl = function(s: TSocket; cmd: DWORD; lpInBuffer: PByte; dwInBufferLen:
    DWORD; lpOutBuffer: PByte; dwOutBufferLen: DWORD; lpdwOutBytesReturned:
    LPDWORD; lpOverLapped: POINTER; lpOverLappedRoutine: POINTER): Integer; stdcall;

var
  RPFForm: TRPFForm;

implementation

{$R *.dfm}

const
  SEL_DIR_CAPTION = 'Select a Directory:';
  RECV_CAPTION = 'Recv!';
  STOP_CAPTION = 'Stop!';
  SIO_RCVALL = IOC_IN or IOC_VENDOR or 1;

type
  TIPHeader = packed record
    iph_verlen: Byte;           // 版本和长度
    iph_tos: Byte;              // 服务类型
    iph_length: Word;           // 总长度,2个无符号字节所以只能65535
    iph_id: Word;               // 标识
    iph_offset: Word;           // 标志和片偏移
    iph_ttl: Byte;              // 生存时间
    iph_protocol: Byte;         // 协议
    iph_xsum: Word;             // 头校验和
    iph_src: LongWord;          // 源地址
    iph_dest: LongWord;         // 目的地址
  end;
  PIPHeader = ^TIPHeader;

var
  WSAIoctl: TWSAIoctl = nil;
  WS2_32DllHandle: THandle = 0;

procedure InitWSAIoctl;
begin
  WS2_32DllHandle := LoadLibrary(WS2_32DLL);
  if WS2_32DllHandle <> 0 then
  begin
    @WSAIoctl := GetProcAddress(WS2_32DllHandle, 'WSAIoctl');
  end;
end;

procedure FreeWSAIoctl;
begin
  if WS2_32DllHandle <> 0 then
    FreeLibrary(WS2_32DllHandle);
end;

function SetIP(aIPAddr: string; var aIP: TIpInfo): Boolean;
var
  pIPAddr: PAnsiChar;
begin
  Result := False;
  aIP.Address := INADDR_NONE;
  aIP.IP := aIPAddr;
  aIP.Host := '';
  if aIP.IP = '' then
    Exit;

  GetMem(pIPAddr, Length(aIP.IP) + 1);
  try
    ZeroMemory(pIPAddr, Length(aIP.IP) + 1);
    StrPCopy(pIPAddr, {$IFDEF UNICODE}AnsiString{$ENDIF}(aIP.IP));
    aIP.Address := inet_addr(PAnsiChar(pIPAddr)); // IP转换成无点整型
  finally
    FreeMem(pIPAddr); // 释放申请的动态内存
  end;
  Result := aIP.Address <> INADDR_NONE;
end;

function GetIPNotes(const aIP: string; var aResult: TIPNotes): Boolean;
var
  iPos, iNote: Integer;
  sIP: string;

  function CheckIpNote(aNote: string): Byte;
  begin
    iNote := StrToInt(aNote);
    if (iNote < 0) or (iNote > MAXIPNOTE) then
      raise Exception.Create(aNote + ' Error Range.');
    Result := iNote;
  end;

begin
  iPos := Pos(IPJOIN, aIP);
  aResult[1] := CheckIpNote(Copy(aIP, 1, iPos - 1));
  sIP := Copy(aIP, iPos + 1, 20);
  iPos := Pos(IPJOIN, sIP);
  aResult[2] := CheckIpNote(Copy(sIP, 1, iPos - 1));
  sIP := Copy(sIP, iPos + 1, 20);
  iPos := Pos(IPJOIN, sIP);
  aResult[3] := CheckIpNote(Copy(sIP, 1, iPos - 1));
  aResult[4] := CheckIpNote(Copy(sIP, iPos + 1, 20));
  Result := aResult[1] > 0;
end;

function IPTypeCheck(const aIP: string): TIP_NetType;
var
  FNotes: TIPNotes;
begin
  Result := iptNone;
  if GetIPNotes(aIP, FNotes) then
  begin
    case FNotes[1] of
      1..126:
        Result := iptANet;
      127:
        Result := iptKeepAddr;
      128..191:
        Result := iptBNet;
      192..223:
        Result := iptCNet;
      224..239:
        Result := iptDNet;
      240..255:
        Result := iptENet;
    else
      Result := iptNone;
    end;
  end;
end;

function IPToInt(const aIP: string): Cardinal;
var
  FNotes: TIPNotes;
begin
  Result := 0;
  if IPTypeCheck(aIP) = iptNone then
  begin
    //raise Exception.Create(SCnErrorAddress);
    Exit;
  end;
  if GetIPNotes(aIP, FNotes) then
  begin
    Result := Result or FNotes[1] shl 24 or FNotes[2] shl 16 or FNotes[3] shl 8
      or FNotes[4];
  end;
end;

function IntToIP(const aIP: Cardinal): string;
var
  FNotes: TIPNotes;
begin
  FNotes[1] := aIP and IPNOTE1 shr 24;
  FNotes[2] := aIP and IPNOTE2 shr 16;
  FNotes[3] := aIP and IPNOTE3 shr 8;
  FNotes[4] := aIP and IPNOTE4;
  Result := Format(IPADDRFORMAT, [FNotes[1], FNotes[2], FNotes[3], FNotes[4]]);
end;

function EnumLocalIP(var aLocalIP: TIPGroup): Integer;
var
  skLocal: TSocket;
  iIP: Integer;
  PtrA: pointer;
  BytesReturned, SetFlags: u_long;
  pAddrInet: Sockaddr_IN;
  Buffer: array[0..20] of TINTERFACE_INFO;
  FWSAData: TWSAData;
begin
  Result := 0;

  WSAStartup($101, FWSAData);
  try
    skLocal := socket(AF_INET, SOCK_STREAM, 0); // Open a socket
    if (skLocal = INVALID_SOCKET) then
      Exit;

    try // Call WSAIoCtl
      PtrA := @bytesReturned;
      if (WSAIoCtl(skLocal, SIO_GET_INTERFACE_LIST, nil, 0, @Buffer, 1024, PtrA,
        nil, nil) <> SOCKET_ERROR) then
      begin // If ok, find out how
        Result := BytesReturned div SizeOf(TINTERFACE_INFO);
        SetLength(aLocalIP, Result);
        for iIP := 0 to Result - 1 do // For every interface
        begin
          pAddrInet := Buffer[iIP].iiAddress.AddressIn;
          aLocalIP[iIP].IPAddress := IPToInt({$IFDEF UNICODE}string{$ENDIF}(inet_ntoa
            (pAddrInet.sin_addr)));
          pAddrInet := Buffer[iIP].iiNetMask.AddressIn;
          aLocalIP[iIP].SubnetMask := IPToInt({$IFDEF UNICODE}string{$ENDIF}(inet_ntoa
            (pAddrInet.sin_addr)));
          pAddrInet := Buffer[iIP].iiBroadCastAddress.AddressIn;
          aLocalIP[iIP].Broadcast := IPToInt({$IFDEF UNICODE}string{$ENDIF}(inet_ntoa
            (pAddrInet.sin_addr)));
          SetFlags := Buffer[iIP].iiFlags;
          aLocalIP[iIP].UpState := (SetFlags and IFF_UP) = IFF_UP;
          aLocalIP[iIP].Loopback := (SetFlags and IFF_LOOPBACK) = IFF_LOOPBACK;
          aLocalIP[iIP].SupportBroadcast := (SetFlags and IFF_BROADCAST) = IFF_BROADCAST;
        end;
      end;
    except
      ;
    end;
    closesocket(skLocal);
  finally
    WSACleanup;
  end;
end;

procedure TRPFForm.btnBrowseClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := 'C:\';
  if SelectDirectory(SEL_DIR_CAPTION, 'C:\', Dir) then
    edtDir.Text := Dir;
end;

procedure TRPFForm.UpdateButtonState;
begin
  if FRecving then
    btnRecv.Caption := STOP_CAPTION
  else
    btnRecv.Caption := RECV_CAPTION;
end;

procedure TRPFForm.btnRecvClick(Sender: TObject);
begin
  if FRecving then
  begin
    // Stop
    StopSniff;
    UpdateButtonState;
  end
  else
  begin
    // Start
    StartSniff;
    UpdateButtonState;
  end;

end;

procedure TRPFForm.FormCreate(Sender: TObject);
var
  Wsa: TWSAData;
  aLocalIP: TIPGroup;
  I: Integer;
begin
  if (WSAStartup(MakeWord(2, 2), Wsa) <> 0) then
    raise Exception.Create('WSAStartup');
  InitWSAIoctl;

  EnumLocalIP(aLocalIP);
  if Length(aLocalIP) > 0 then
  begin
    for I := 0 to Length(aLocalIP) - 1 do
      cbbIP.Items.Add(IntToIP(aLocalIP[I].IPAddress));
    cbbIP.ItemIndex := 0;
  end;
end;

procedure TRPFForm.FormDestroy(Sender: TObject);
begin
  WSACleanup;
  FreeWSAIoctl;
end;

procedure TRPFForm.StartSniff;
var
  RecvTimeout: Integer;
  Sa: TSockAddr;
  Opt, Ret: Integer;
  Buf: array[0..65535] of AnsiChar;
  BytesRet, InBufLen: Cardinal;
  CtlBuf: array[0..1023] of AnsiChar;
  DataLen, HdrLen, AllLen, SumLen, PackLen, Step: Integer;
  PIP: PIPHeader;
  ListeningIP, SrcIp: u_long;
  IGMPBuf, PFileName: PAnsiChar;
  PSeq, PLen, PFile: PCardinal;
  Content, PContent: PAnsiChar;
  AFileName: string;
  Stream: TMemoryStream;
begin
  if FRecving then
    Exit;

  pbRecv.Position := 0;
  FSnifSock := socket(AF_INET, SOCK_RAW, IPPROTO_IP);
  if FSnifSock = INVALID_SOCKET then
    raise Exception.Create('Create Socket Fail.');

  RecvTimeout := udTimeout.Position;
  if (setsockopt(FSnifSock, SOL_SOCKET, SO_RCVTIMEO, @RecvTimeout, SizeOf(RecvTimeout))
    = SOCKET_ERROR) then
  begin
    Ret := WSAGetLastError;
    closesocket(FSnifSock);
    raise Exception.CreateFmt('Set Socketopt Fail. %d', [Ret]);
  end;

  ListeningIP := inet_addr(PAnsiChar(cbbIP.Text));
  SrcIp := inet_addr(PAnsiChar(edtFromIp.Text));

  Sa.sin_family := AF_INET;
  Sa.sin_port := htons(0);
  Sa.sin_addr.s_addr := ListeningIP;
  if bind(FSnifSock, PSOCKADDR(@Sa), SizeOf(Sa)) = SOCKET_ERROR then
  begin
    Ret := WSAGetLastError;
    closesocket(FSnifSock);
    raise Exception.CreateFmt('Bind IP Fail. %d', [Ret]);
  end;

  InBufLen := 1;
  if WSAIoctl(FSnifSock, SIO_RCVALL, @InBufLen, SizeOf(InBufLen), @CtlBuf[0],
    SizeOf(CtlBuf), @BytesRet, nil, nil) = SOCKET_ERROR then
  begin
    Ret := WSAGetLastError;
    closesocket(FSnifSock);
    raise Exception.CreateFmt('WSAIoctl Fail. %d', [Ret]);
  end;

  FillChar(Buf[0], SizeOf(Buf), 0);
  FRecving := True;
  UpdateButtonState;
  lblProgress.Caption := '';
  Content := nil;
  Step := 0;
  SumLen := 0;

  Application.ProcessMessages;
  try
    while FRecving do
    begin
      DataLen := recv(FSnifSock, Buf[0], SizeOf(Buf), 0);
      if (DataLen <> SOCKET_ERROR) and (DataLen > 0) then
      begin
        // 解析 IP 包
        PIP := @Buf[0];
        if PIP^.iph_verlen and $F0 <> $40 then // IP must V4
          Continue;  
        if PIP^.iph_dest <> ListeningIP then   // 只抓目标是自己的
          Continue;
        if PIP^.iph_protocol <> 1 then         // 只抓 ICMP 的
          Continue;
        if (SrcIp <> INADDR_NONE) and (PIP^.iph_src <> SrcIp) then // 只抓指定源的
          Continue;

        HdrLen := (PIP^.iph_verlen and $0F) * SizeOf(DWORD);
        IGMPBuf := PAnsiChar(Integer(@Buf[0]) + HdrLen + 8); // 8 means IGMP Ping packet header len

        PSeq := PCardinal(IGMPBuf);
        PLen := PCardinal(Integer(IGMPBuf) + SizeOf(Cardinal));
        PFile := PCardinal(Integer(PLen) + SizeOf(Cardinal));

        if (PSeq^ = 0) and (Content = nil) then
        begin
          AllLen := PLen^;   // 总块数据量
          Content := GetMemory(AllLen);
          PContent := Content;
          PFileName := PAnsiChar(PFile);
          if StrLen(PFileName) < 128 then
            AFileName := StrNew(PFileName)
          else
            AFileName := 'NoName.txt';
          Step := 1;

          pbRecv.Min := 0;
          pbRecv.Max := AllLen;
          //pbRecv.Invalidate;
        end;

        if PSeq^ = Step then // 需要的块来了
        begin
          PackLen := PLen^;  // 本块数据量

          CopyMemory(PContent, PFile, PackLen); // 拼装文件内容

          Inc(Step);
          Inc(SumLen, PackLen);
          pbRecv.Position := SumLen;
          //pbRecv.Invalidate;

          PContent := Pointer(Integer(PContent) + PackLen);

          lblProgress.Caption := 'Got Seq: ' + IntToStr(Step - 1);
        end
        else
          lblProgress.Caption := 'Got Unexpected: ' + IntToStr(PSeq^) + '. Lack of ' + IntToStr(Step);

        if SumLen >= AllLen then // 数据满了
        begin
          // 保存 Content 到文件
          Stream := TMemoryStream.Create;
          Stream.Write(Content^, SumLen);
          Stream.SaveToFile(IncludeTrailingPathDelimiter(edtDir.Text) + AFileName);
          FreeMemory(Content);
          Content := nil;
          FRecving := False;
          pbRecv.Position := 0;

          ShowMessage('File ' + AFileName + ' Saved to ' + edtDir.Text);
          Exit;
        end;
      end
      else if DataLen = SOCKET_ERROR then
      begin
        Ret := WSAGetLastError;
        if Ret <> 10060 then // 10060 是超时无数据，继续接收
          raise Exception.CreateFmt('Recv Fail. %d', [Ret]);
      end;

      Application.ProcessMessages;
    end;
  finally
    closesocket(FSnifSock);
    if Content <> nil then
      FreeMemory(Content);
    UpdateButtonState;
  end;
end;

procedure TRPFForm.StopSniff;
begin
  if not FRecving then
    Exit;
  FRecving := False;
end;

procedure TRPFForm.btnCopyClick(Sender: TObject);
begin
  edtFromIp.Text := cbbIP.Text;
end;

end.


