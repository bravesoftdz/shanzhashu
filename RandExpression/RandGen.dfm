object FormGenRandom: TFormGenRandom
  Left = 262
  Top = 134
  BorderStyle = bsDialog
  Caption = '�������������'
  ClientHeight = 285
  ClientWidth = 440
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = '����'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClick = FormClick
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  object bvl1: TBevel
    Left = 16
    Top = 180
    Width = 409
    Height = 17
    Shape = bsTopLine
  end
  object btn10AddSub2: TButton
    Left = 16
    Top = 16
    Width = 409
    Height = 25
    Caption = '���� 10 ���ڵĶ���Ӽ��� 90 ��'
    TabOrder = 0
    OnClick = btn10AddSub2Click
  end
  object btn20AddSub2: TButton
    Left = 16
    Top = 56
    Width = 409
    Height = 25
    Caption = '���� 20 ���ڵĶ���Ӽ��� 90 ��'
    TabOrder = 1
    OnClick = btn20AddSub2Click
  end
  object btn10Add2: TButton
    Left = 16
    Top = 96
    Width = 193
    Height = 25
    Caption = '���� 10 ���ڵĶ���ӷ� 90 ��'
    TabOrder = 2
    OnClick = btn10Add2Click
  end
  object btn10Sub2: TButton
    Left = 232
    Top = 96
    Width = 193
    Height = 25
    Caption = '���� 10 ���ڵĶ������ 90 ��'
    TabOrder = 3
    OnClick = btn10Sub2Click
  end
  object btn20Add2: TButton
    Left = 16
    Top = 136
    Width = 193
    Height = 25
    Caption = '���� 20 ���ڵĶ���ӷ� 90 ��'
    TabOrder = 4
    OnClick = btn20Add2Click
  end
  object btn20Sub2: TButton
    Left = 232
    Top = 136
    Width = 193
    Height = 25
    Caption = '���� 20 ���ڵĶ������ 90 ��'
    TabOrder = 5
    OnClick = btn20Sub2Click
  end
  object btnCompare10Add2vs1: TButton
    Left = 16
    Top = 200
    Width = 409
    Height = 25
    Caption = '���� 10 ���ڵĶ���Ӽ�������ʽ 90 ��'
    TabOrder = 6
    OnClick = btnCompare10Add2vs1Click
  end
  object btnCompare20AddSub2vs1: TButton
    Left = 16
    Top = 240
    Width = 409
    Height = 25
    Caption = '���� 20 ���ڵĶ���Ӽ�������ʽ 90 ��'
    TabOrder = 7
    OnClick = btnCompare10Add2vs1Click
  end
end
