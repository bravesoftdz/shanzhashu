object FormGenRandom: TFormGenRandom
  Left = 192
  Top = 107
  Width = 696
  Height = 480
  Caption = 'Generate Random Expressions'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnPreset: TButton
    Left = 16
    Top = 24
    Width = 75
    Height = 25
    Caption = 'Preset'
    TabOrder = 0
  end
  object btnGen: TButton
    Left = 568
    Top = 24
    Width = 75
    Height = 25
    Caption = '����'
    TabOrder = 1
    OnClick = btnGenClick
  end
  object mmoRes: TMemo
    Left = 24
    Top = 64
    Width = 641
    Height = 369
    Lines.Strings = (
      'mmoRes')
    TabOrder = 2
  end
end