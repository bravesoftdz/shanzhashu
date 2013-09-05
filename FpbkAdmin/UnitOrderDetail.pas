unit UnitOrderDetail;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Spin, ComCtrls, Buttons, ADODB, DB;

type
  TFormOrderDetail = class(TForm)
    grpDesign: TGroupBox;
    lblDesignName: TLabel;
    cbbDesignName: TComboBox;
    lblDesignSend: TLabel;
    dtpDesignSend: TDateTimePicker;
    lblRecvDesign: TLabel;
    dtpRecvDesign: TDateTimePicker;
    grpFactory: TGroupBox;
    lblFactoryName: TLabel;
    lblSendToFactory: TLabel;
    lblRecvFromFactory: TLabel;
    cbbFactoryName: TComboBox;
    dtpSendToFactory: TDateTimePicker;
    dtpRecvFromFactory: TDateTimePicker;
    grpBaby: TGroupBox;
    lblBabyName: TLabel;
    lblContactNum: TLabel;
    lblOrderDate: TLabel;
    lblShotDate: TLabel;
    lblHour1: TLabel;
    edtBabyName: TEdit;
    edtContactNum: TEdit;
    dtpOrderDate: TDateTimePicker;
    dtpShotDate: TDateTimePicker;
    seOrderDate: TSpinEdit;
    lblTaken: TLabel;
    dtpTakenDate: TDateTimePicker;
    edtAge: TEdit;
    lblAge: TLabel;
    grpContent: TGroupBox;
    lblPrice: TLabel;
    lblPayment: TLabel;
    lblContent: TLabel;
    edtPrice: TEdit;
    edtPayment: TEdit;
    mmoContent: TMemo;
    cbbStatus: TComboBox;
    lblStatus: TLabel;
    bvl1: TBevel;
    btnCancel: TBitBtn;
    btnOK: TBitBtn;
    lblOrderDetail: TLabel;
    btnFillSuite: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure cbbStatusChange(Sender: TObject);
    procedure dtpShotDateChange(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnFillSuiteClick(Sender: TObject);
  private
    FIsNew: Boolean;
    FID: Integer;
    FSaveSuc: Boolean;
    procedure InitListValues;
    procedure SetIsNew(const Value: Boolean);
    function ValidateFields: Boolean;
    procedure MakeDateTimePickerEmpty(Picker: TDateTimePicker);
    function IsDateTimePickerEmpty(Picker: TDateTimePicker): Boolean;
    procedure PutFieldToDateTimePicker(AVar: Variant; Picker: TDateTimePicker);
    procedure PutValuesToDataSetFields(DataSet: TDataSet);
  public
    property IsNew: Boolean read FIsNew write SetIsNew;
    property SaveSuc: Boolean read FSaveSuc;
    property ID: Integer read FID write FID;
    procedure FillValues(DataSet: TDataSet);
  end;

var
  FormOrderDetail: TFormOrderDetail;

implementation

uses UnitDataModule, UnitSuite;

{$R *.dfm}

{ TFormOrderDetail }

procedure TFormOrderDetail.InitListValues;
var
  I: TOrderStatus;
  AName: string;
begin
  cbbStatus.Clear;
  for I := Low(TOrderStatus) to High(TOrderStatus) do
    cbbStatus.Items.Add(OrderStatusStrings[I]);

  try
    cbbDesignName.Clear;
    DataModuleMain.tblDesignNames.Active := True;
    DataModuleMain.tblDesignNames.First;
    while not DataModuleMain.tblDesignNames.Eof do
    begin
      I := DataModuleMain.tblDesignNames.FieldValues['ID'];
      AName := VarToStr(DataModuleMain.tblDesignNames.FieldValues['DesignName']);
      cbbDesignName.Items.AddObject(AName, TObject(I));
      DataModuleMain.tblDesignNames.Next;
    end;
  finally
    DataModuleMain.tblDesignNames.Active := False;
  end;

  try
    cbbFactoryName.Clear;
    DataModuleMain.tblFactoryNames.Active := True;
    DataModuleMain.tblFactoryNames.First;
    while not DataModuleMain.tblFactoryNames.Eof do
    begin
      I := DataModuleMain.tblFactoryNames.FieldValues['ID'];
      AName := VarToStr(DataModuleMain.tblFactoryNames.FieldValues['FactoryName']);
      cbbFactoryName.Items.AddObject(AName, TObject(I));
      DataModuleMain.tblFactoryNames.Next;
    end;
  finally
    DataModuleMain.tblFactoryNames.Active := False;
  end;
end;

procedure TFormOrderDetail.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to ComponentCount - 1 do
    if Components[I] is TDateTimePicker then
      MakeDateTimePickerEmpty(Components[I] as TDateTimePicker);

  InitListValues;
end;

procedure TFormOrderDetail.SetIsNew(const Value: Boolean);
begin
  if FIsNew <> Value then
  begin
    FIsNew := Value;
    
  end;
end;

procedure TFormOrderDetail.cbbStatusChange(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := cbbStatus.ItemIndex;
  if (Idx <= Integer(High(TOrderStatus))) and (Idx >= Integer(Low(TOrderStatus))) then
    lblOrderDetail.Caption := OrderStatusDetailStrings[TOrderStatus(Idx)];
end;

procedure TFormOrderDetail.dtpShotDateChange(Sender: TObject);
begin
  dtpTakenDate.Date := IncMonth(dtpShotDate.Date);
end;

procedure TFormOrderDetail.btnOKClick(Sender: TObject);
var
  DataSet: TADODataSet;
begin
  if ValidateFields then
  begin
    if FIsNew then
    begin
      // ��ADODataSet��Post�¼�¼
      DataSet := TADODataSet.Create(Self);
      Screen.Cursor := crHourGlass;
      try
        DataSet.Connection := DataModuleMain.conDatabase;
        DataSet.CommandText := 'SELECT * FROM OrderForms WHERE 1 <> 1';
        DataSet.Open;
        DataSet.Append;

        PutValuesToDataSetFields(DataSet);
        DataSet.Post;
      finally
        Screen.Cursor := crDefault;
        DataSet.Close;
        DataSet.Free;
      end;
      InfoDlg('�¶�������ɹ���');
    end
    else
    begin
      // ���� ID �����¼�¼
      DataSet := TADODataSet.Create(Self);
      Screen.Cursor := crHourGlass;
      try
        DataSet.Connection := DataModuleMain.conDatabase;
        DataSet.CommandText := 'SELECT * FROM OrderForms WHERE ID = ' + IntToStr(FID);
        DataSet.Open;
        DataSet.First;
        DataSet.Edit;

        PutValuesToDataSetFields(DataSet);
        DataSet.Post;
      finally
        Screen.Cursor := crDefault;
        DataSet.Close;
        DataSet.Free;
      end;
      InfoDlg('�������³ɹ���');
    end;
    FSaveSuc := True;
    Close;
  end;
end;

function TFormOrderDetail.ValidateFields: Boolean;
var
  Status: TOrderStatus;
begin
  Result := False;
  if Trim(edtBabyName.Text) = '' then
  begin
    ErrorDlg('������������Ϊ�գ�');
    edtBabyName.SetFocus;
    Exit;
  end;

  if Trim(edtContactNum.Text) = '' then
  begin
    ErrorDlg('��ϵ��ʽ����Ϊ�գ�');
    edtContactNum.SetFocus;
    Exit;
  end;

  if Trim(edtAge.Text) = '' then
  begin
    ErrorDlg('�������䲻��Ϊ�գ�');
    edtAge.SetFocus;
    Exit;
  end;

  Status := TOrderStatus(cbbStatus.ItemIndex);
  if Status >= osOrdered then
  begin
    // �¶����������ڲ���Ϊ��
    if IsDateTimePickerEmpty(dtpOrderDate) then
    begin
      ErrorDlg('�����������¶����ڡ�');
      dtpOrderDate.SetFocus;
      Exit;
    end;
    if IsDateTimePickerEmpty(dtpShotDate) then
    begin
      ErrorDlg('�����������������ڡ�');
      dtpShotDate.SetFocus;
      Exit;
    end;
    if (seOrderDate.Value < 0) or (seOrderDate.Value > 24) then
    begin
      ErrorDlg('��ѡ����������ʱ�䡣');
      seOrderDate.SetFocus;
      Exit;
    end;
    if StrToIntDef(Trim(edtPrice.Text), -1) = -1 then
    begin
      ErrorDlg('��������ȷ���ײͽ�');
      edtPrice.SetFocus;
      Exit;
    end;
    if StrToIntDef(Trim(edtPayment.Text), -1) = -1 then
    begin
      ErrorDlg('��������ȷ���Ѹ���');
      edtPayment.SetFocus;
      Exit;
    end;
    if Trim(mmoContent.Text) = '' then
    begin
      ErrorDlg('��ѡ������������ײ����ݡ�');
      mmoContent.SetFocus;
      Exit;
    end;
  end;
  if Status >= osShot then
  begin
    if IsDateTimePickerEmpty(dtpTakenDate) then
    begin
      ErrorDlg('����������ȡ�����ڡ�');
      dtpTakenDate.SetFocus;
      Exit;
    end;
  end;
  if Status >= osSelected then
  begin
    // ѡƬ�ˣ�������͸��һ�£�����һ�¡�
     if Trim(edtPrice.Text) <> Trim(edtPayment.Text) then
    begin
      InfoDlg('�ײͽ�����Ѹ���һ�£���ע��ȷ�ϸ��������');
    end;
  end;
  if Status >= osDesignSent then
  begin
    // ��Ƴ��Ҳ���Ϊ�գ�������Ƶ����ڲ���Ϊ���Ҳ���������������
    if cbbDesignName.ItemIndex < 0 then
    begin
      ErrorDlg('��ѡ����Ʒ���������Ҫ����Ʒ������ڹ���ѡ�������á�');
      cbbDesignName.SetFocus;
      Exit;
    end;
    if IsDateTimePickerEmpty(dtpDesignSend) or (dtpDesignSend.Date < dtpShotDate.Date) then
    begin
      ErrorDlg('���������ķ��͸���Ʒ������ڡ�');
      dtpDesignSend.SetFocus;
      Exit;
    end;
  end;
  if Status >= osDesignOK then
  begin
    // �յ���Ƶ����ڲ���Ϊ���Ҳ������ڷ�����Ƶ�����
    if IsDateTimePickerEmpty(dtpRecvDesign) or (dtpRecvDesign.Date < dtpDesignSend.Date) then
    begin
      ErrorDlg('������������Ʒ��������ڡ�');
      dtpRecvDesign.SetFocus;
      Exit;
    end;
  end;
  if Status >= osSentToFactory then
  begin
    // �������Ҳ���Ϊ�գ��������ڲ���Ϊ���Ҳ�����������������
    if cbbFactoryName.ItemIndex < 0 then
    begin
      ErrorDlg('��ѡ���������ҡ�������Ҫ���������ң����ڹ���ѡ�������á�');
      cbbFactoryName.SetFocus;
      Exit;
    end;
    if IsDateTimePickerEmpty(dtpSendToFactory) or (dtpSendToFactory.Date < dtpRecvDesign.Date) then
    begin
      ErrorDlg('���������ķ��͸������������ڡ�');
      dtpSendToFactory.SetFocus;
      Exit;
    end;
  end;
  if Status >= osRecvFromFactory then
  begin
    // �յ����������ڲ���Ϊ���Ҳ������ڷ������ҵ�����
    if IsDateTimePickerEmpty(dtpRecvFromFactory) or (dtpRecvFromFactory.Date < dtpSendToFactory.Date) then
    begin
      ErrorDlg('�����������������������ڡ�');
      dtpRecvFromFactory.SetFocus;
      Exit;
    end;
  end;
  if Status >= osCustomerNotified then
  begin
    //
  end;
  if Status >= osCustomerTaken then
  begin
    // ȡ���������Ѹ��������ͬ
    if Trim(edtPrice.Text) <> Trim(edtPayment.Text) then
    begin
      ErrorDlg('�ײͽ�����Ѹ���һ�£��������');
      edtPayment.SetFocus;
      Exit;
    end;
  end;

  Result := True;
end;

procedure TFormOrderDetail.MakeDateTimePickerEmpty(
  Picker: TDateTimePicker);
begin
  if Picker <> nil then
    Picker.Date := EMPTY_DATETIME;
end;

function TFormOrderDetail.IsDateTimePickerEmpty(
  Picker: TDateTimePicker): Boolean;
begin
  Result := False;
  if Picker <> nil then
    Result := Trunc(Picker.Date) = EMPTY_DATETIME;
end;

procedure TFormOrderDetail.FormShow(Sender: TObject);
begin
  if FIsNew then
  begin
    dtpOrderDate.Date := Date;
    dtpShotDate.Date := Date;
    if Assigned(dtpShotDate.OnChange) then
      dtpShotDate.OnChange(dtpTakenDate);
  end;
end;

procedure TFormOrderDetail.FillValues(DataSet: TDataSet);
begin
  if DataSet = nil then
    Exit;

  FID := DataSet.FieldValues['ID'];
  edtBabyName.Text := Trim(VarToStr(DataSet.FieldValues['BabyName']));
  edtContactNum.Text := Trim(VarToStr(DataSet.FieldValues['ContactNum']));
  edtAge.Text := Trim(VarToStr(DataSet.FieldValues['Age']));
  edtPrice.Text := Trim(VarToStr(DataSet.FieldValues['Price']));
  edtPayment.Text := Trim(VarToStr(DataSet.FieldValues['Payment']));
  mmoContent.Text := Trim(VarToStr(DataSet.FieldValues['PicContent']));
  if not VarIsNull(DataSet.FieldValues['ShotTime']) then
    seOrderDate.Value := DataSet.FieldValues['ShotTime'];

  PutFieldToDateTimePicker(DataSet.FieldValues['OrderDate'], dtpOrderDate);
  PutFieldToDateTimePicker(DataSet.FieldValues['ShotDate'], dtpShotDate);
  PutFieldToDateTimePicker(DataSet.FieldValues['CustomerTakenDate'], dtpTakenDate);
  PutFieldToDateTimePicker(DataSet.FieldValues['DesignSendDate'], dtpDesignSend);
  PutFieldToDateTimePicker(DataSet.FieldValues['DesignReceiveDate'], dtpRecvDesign);
  PutFieldToDateTimePicker(DataSet.FieldValues['SendToFactoryDate'], dtpSendToFactory);
  PutFieldToDateTimePicker(DataSet.FieldValues['RecvFromFactoryDate'], dtpRecvFromFactory);

  cbbStatus.ItemIndex := DataSet.FieldValues['Status'];
  if Assigned(cbbStatus.OnChange) then
    cbbStatus.OnChange(cbbStatus);

  if VarIsNull(DataSet.FieldValues['DesignNameText']) then
    cbbDesignName.ItemIndex := -1
  else
    cbbDesignName.ItemIndex := cbbDesignName.Items.IndexOf(DataSet.FieldValues['DesignNameText']);

  if VarIsNull(DataSet.FieldValues['FactoryNameText']) then
    cbbFactoryName.ItemIndex := -1
  else
    cbbFactoryName.ItemIndex := cbbFactoryName.Items.IndexOf(DataSet.FieldValues['FactoryNameText']);
end;

procedure TFormOrderDetail.PutFieldToDateTimePicker(AVar: Variant; Picker: TDateTimePicker);
begin
  if not VarIsNull(AVar) then
  begin
    Picker.Date := AVar;
  end
  else
  begin
    MakeDateTimePickerEmpty(Picker);
  end;
end;

procedure TFormOrderDetail.PutValuesToDataSetFields(DataSet: TDataSet);
begin
  if DataSet = nil then
    Exit;

  DataSet.FieldValues['BabyName'] := Trim(edtBabyName.Text);
  DataSet.FieldValues['ContactNum'] := Trim(edtContactNum.Text);
  DataSet.FieldValues['Age'] := StrToInt(edtAge.Text);
  DataSet.FieldValues['Price'] := StrToInt(edtPrice.Text);
  DataSet.FieldValues['Payment'] := StrToInt(edtPayment.Text);
  DataSet.FieldValues['Status'] := cbbStatus.ItemIndex;

  if not IsDateTimePickerEmpty(dtpOrderDate) then
    DataSet.FieldValues['OrderDate'] := FormatDateTime('yyyy-mm-dd', dtpOrderDate.Date);
  if not IsDateTimePickerEmpty(dtpShotDate) then
  begin
    DataSet.FieldValues['ShotDate'] := FormatDateTime('yyyy-mm-dd', dtpShotDate.Date);
    DataSet.FieldValues['ShotTime'] := seOrderDate.Value;
  end;
  if not IsDateTimePickerEmpty(dtpTakenDate) then
    DataSet.FieldValues['CustomerTakenDate'] := FormatDateTime('yyyy-mm-dd', dtpTakenDate.Date);
  if not IsDateTimePickerEmpty(dtpDesignSend) then
    DataSet.FieldValues['DesignSendDate'] := FormatDateTime('yyyy-mm-dd', dtpDesignSend.Date);
  if not IsDateTimePickerEmpty(dtpRecvDesign) then
    DataSet.FieldValues['DesignReceiveDate'] := FormatDateTime('yyyy-mm-dd', dtpRecvDesign.Date);
  if not IsDateTimePickerEmpty(dtpSendToFactory) then
    DataSet.FieldValues['SendToFactoryDate'] := FormatDateTime('yyyy-mm-dd', dtpSendToFactory.Date);
  if not IsDateTimePickerEmpty(dtpRecvDesign) then
    DataSet.FieldValues['RecvFromFactoryDate'] := FormatDateTime('yyyy-mm-dd', dtpRecvFromFactory.Date);

  DataSet.FieldValues['PicContent'] := Trim(mmoContent.Text);

  if cbbDesignName.ItemIndex >= 0 then
    DataSet.FieldValues['DesignName'] := Integer(cbbDesignName.Items.Objects[cbbDesignName.ItemIndex]);
  if cbbFactoryName.ItemIndex >= 0 then
    DataSet.FieldValues['FactoryName'] := Integer(cbbFactoryName.Items.Objects[cbbFactoryName.ItemIndex]);
end;

procedure TFormOrderDetail.btnFillSuiteClick(Sender: TObject);
begin
  with TFormSuite.Create(Application) do
  begin
    Caption := 'ѡ��Ԥ���ײ�';
    lblDesc.Caption := '�������ڴ�ѡ��Ԥ�õ��ײ����ݡ�ѡ������ݽ����붩���С�';
    btnClose.Caption := 'ȡ��';
    btnOK.Visible := True;
    grpSuite.Enabled := False;
    dbnvgrSuite.Enabled := False;
    dbgrdPreContents.OnDblClick := dbgrdPreContentsDblClick;

    DataModuleMain.conDatabase.Connected := True;
    DataModuleMain.tblPreContents.Active := True;
    if ShowModal = mrOK then
    begin
      if not DataModuleMain.tblPreContents.Eof then
      begin
        edtPrice.Text := DataModuleMain.tblPreContents.FieldValues['PreContentPrice'];
        mmoContent.Text := DataModuleMain.tblPreContents.FieldValues['PreContentDescription'];
      end;
    end;
    DataModuleMain.tblPreContents.Active := False;
  end;
end;

end.
