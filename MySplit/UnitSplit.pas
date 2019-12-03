unit UnitSplit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Edit,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListBox, FMX.ScrollBox, FMX.Memo;

type
  TFormSplit = class(TForm)
    lblSplit: TLabel;
    edtFile: TEdit;
    btnBrowse: TButton;
    edtBlockSize: TEdit;
    cbbUnit: TComboBox;
    lblBy: TLabel;
    lblTo: TLabel;
    dlgOpen: TOpenDialog;
    lblSize: TLabel;
    lblPick: TLabel;
    edtStart: TEdit;
    lblPickEnd: TLabel;
    edtEnd: TEdit;
    btnSave: TButton;
    mmoResult: TMemo;
    procedure btnBrowseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbbUnitChange(Sender: TObject);
    procedure edtBlockSizeChange(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    FBlockSize: Int64; // ���С���ֽ�
    FBlockCount: Integer; // ������1 ��ʼ
    FOutputDir: string;   // ��дĿ¼����/
    procedure UpdateBlockSize;
    procedure UpdateFileSize;
    procedure LogMsg(const M: string);
    procedure SaveOneBlock(F: TFileStream; BlockIndex: Integer);
  public
    { Public declarations }
  end;

var
  FormSplit: TFormSplit;

implementation

{$R *.fmx}

var
  Buf: array[1..1024*1024] of Byte;

procedure TFormSplit.btnBrowseClick(Sender: TObject);
begin
  if dlgOpen.Execute then
  begin
    edtFile.Text := dlgOpen.FileName;
    UpdateFileSize;
    edtStart.Text := '1';
    edtEnd.Text := IntToStr(FBlockCount);
  end;
end;

procedure TFormSplit.btnSaveClick(Sender: TObject);
var
  I, A, B: Integer;
  F: TFileStream;
begin
  if not SelectDirectory('', '/', FOutputDir) then
    Exit;
  mmoResult.Lines.Clear;

  LogMsg(FOutputDir);
  UpdateFileSize;
  UpdateBlockSize;

  A := StrToInt(edtStart.Text);
  B := StrToInt(edtEnd.Text);
  if A > B then
    raise Exception.Create('Index Error');
  if B > FBlockCount then
    raise Exception.Create('Index Out of Range');

  F := TFileStream.Create(edtFile.Text, fmOpenRead);
  try
    for I := A to B do
    begin
      SaveOneBlock(F, I);
    end;
  finally
    F.Free;
  end;
end;

procedure TFormSplit.cbbUnitChange(Sender: TObject);
begin
  UpdateBlockSize;
end;

procedure TFormSplit.edtBlockSizeChange(Sender: TObject);
begin
  UpdateBlockSize;
end;

procedure TFormSplit.FormCreate(Sender: TObject);
begin
  UpdateBlockSize;
end;

procedure TFormSplit.LogMsg(const M: string);
begin
  mmoResult.Lines.Add(M);
end;

procedure TFormSplit.SaveOneBlock(F: TFileStream; BlockIndex: Integer);
var
  O: string;
  B: TFileStream;
  Sum, C, BufSize, ToReadSize: Integer;
begin
  // �� F �ļ����еĵ� BlockIndex ��д���ļ�
  O := IncludeTrailingPathDelimiter(FOutputDir) + Format('%4.4d', [BlockIndex]);
  if FileExists(O) then
    DeleteFile(O);

  B := TFileStream.Create(O, fmOpenWrite or fmCreate);
  Sum := 0;
  try
    F.Position := FBlockSize * (BlockIndex - 1);   // �Ӹ�λ�ö���Ҫ���ܹ� FBlockSize �����ļ�β
    LogMsg('Read from Offset: ' + IntToStr(F.Position));

    // ��������С 1 M��ÿ�ζ���� 1 M��Ҳ���� 1 M �� FBlockSize �еĽ�С��
    BufSize := 1024 * 1024;
    if BufSize > FBlockSize then  // һ�ξͶ��꣬�������ļ�β��ʵ������û�� FBlockSize ��ô��
    begin
      BufSize := FBlockSize;
      C := F.Read(Buf, BufSize);
      // if C <> R then
      //   raise Exception.Create('Read Error');
      B.Write(Buf, C);
      Inc(Sum, C);
      B.Free;
    end
    else
    begin
      ToReadSize := FBlockSize;
      if F.Size - F.Position < ToReadSize then
        ToReadSize := F.Size - F.Position;

      while ToReadSize > 0 do
      begin
        C := F.Read(Buf, BufSize);   // BufSize ��һ�ν����ǻ�������С��
        Dec(ToReadSize, C);
        B.Write(Buf, C);
        Inc(Sum, C);
      end;
    end;
  finally
    B.Free;
  end;
  LogMsg('Write ' + IntToStr(C) + ' Bytes to ' + O);
end;

procedure TFormSplit.UpdateBlockSize;
begin
  FBlockSize := StrToInt(edtBlockSize.Text);
  case cbbUnit.ItemIndex of
    0:
      begin
        FBlockSize := FBlockSize * 1024;
      end;
    1:
      begin
        FBlockSize := FBlockSize * 1024 * 1024;
      end;
    2:
      begin
        FBlockSize := FBlockSize * 1024 * 1024 * 1024
      end;
  end;
end;

procedure TFormSplit.UpdateFileSize;
var
  F: TFileStream;
  T: Int64;
begin
  F := TFileStream.Create(edtFile.Text, fmOpenRead);
  T := F.Size;
  lblSize.Text := IntToStr(T);
  FBlockCount := (T div FBlockSize) + 1;
  lblTo.Text := 'To 1 ~ ' + IntToStr(FBlockCount) + ' Blocks.';
  F.Free;
end;

end.
