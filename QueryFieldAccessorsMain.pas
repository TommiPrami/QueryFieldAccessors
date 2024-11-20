unit QueryFieldAccessorsMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Stan.Intf, System.Diagnostics,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error,
  FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async,
  FireDAC.DApt, FireDAC.UI.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.VCLUI.Wait, Vcl.StdCtrls, Data.DB, FireDAC.Comp.Client,
  FireDAC.Comp.DataSet, FireDAC.Phys.SQLiteVDataSet, Vcl.Samples.Spin,
  FireDAC.Stan.StorageBin, FireDAC.Comp.UI, Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    btnDesignTimeFields: TButton;
    btnFieldByName: TButton;
    btnFieldReferences: TButton;
    btnGenerate: TButton;
    btnIndexedFields: TButton;
    FDConnection: TFDConnection;
    FDGUIxWaitCursor: TFDGUIxWaitCursor;
    FDLocalSQL: TFDLocalSQL;
    FDMemTable: TFDMemTable;
    FDQueryData: TFDQuery;
    FDQueryData_id: TLargeintField;
    FDQueryData_name: TWideStringField;
    FDQueryData_x0: TFloatField;
    FDQueryData_y0: TFloatField;
    FDQueryData_z0: TFloatField;
    FDQueryData2: TFDQuery;
    FDQueryData2cnt: TLargeintField;
    ListBoxData: TListBox;
    MemoLog: TMemo;
    PanelButtons: TPanel;
    SpinEditRowCount: TSpinEdit;
    SplitterLog: TSplitter;
    TimerAfterShow: TTimer;
    procedure btnDesignTimeFieldsClick(Sender: TObject);
    procedure btnFieldByNameClick(Sender: TObject);
    procedure btnFieldReferencesClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnIndexedFieldsClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure TimerAfterShowTimer(Sender: TObject);
  strict private
    { Private declarations }
    FStopWatch: TStopWatch;
    procedure Log(const ALogMessage: string; const AIndent: Integer = 0);
    procedure StartTimer(const ASender: TObject);
    procedure EndTimer;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  System.Math;

const
  DATABASE_FILENAME = '..\..\QueryFieldData.db';

function GenerateAlienText(const ACharCount: Integer): string;
const
  ALIEN_ALPHABETS: array[0..1] of string = (
    '⏣⎌⛫⎋⎉⎅⎇⎀⎁⏢⏦⏧⏥⏠⏞⏜⏛⏚⏕⎔⎊⎉⌽⍙⍘⍗⍖⍕⍔⛶⛕⛖⛋⛌⛍⛐⛒⛣⌤⌙⌭⌮⌯⌰⌱⌲⌳⌴',
    '░▒▓█♡♥♦♣♠▪▫➢∞✩✪✫✬✭✮✯✰⁂⌘ૐ࿃࿄࿅࿆࿇࿈࿉࿊࿋࿇࿈࿎࿏࿐࿑࿒࿓࿔᠀᠁᠂᠃᠄᠅᠆᠇᠈᠉᠊᠋᠌᠍᠎᠏᠐᠑᠒᠓᠔᠕᠖᠗᠘᠙');
  ALIEN_ALPHABET_3CODES: array[0..49] of Word = (
      $2591, $2592, $2593, $2588, $2580, $2584, $258C, $2590, $25A0, $25A1,  // Block Elements
      $25CB, $25CF, $25C6, $25D8, $25D9, $2665, $2660, $2666, $2663, $2605,  // Geometric Shapes and Misc. Symbols
      $2701, $2702, $2703, $2704, $2706, $2707, $2708, $2709, $2710, $2711,  // Dingbats
      $2712, $2713, $2714, $2715, $2716, $2717, $2718, $2719, $2720, $2721,  // Dingbats
      $2722, $2723, $2724, $2725, $2726, $2727, $2736, $2729, $2744, $2745   // Dingbats and Misc. Symbols
    );

begin
  Result := '';

  var LChosenAlphabetIndex := Random(3);

  for var LIndex := 1 to ACharCount do
  case LChosenAlphabetIndex of
    0,1: Result := Result + ALIEN_ALPHABETS[LChosenAlphabetIndex][Random(Length(ALIEN_ALPHABETS[LChosenAlphabetIndex])) + 1];
    2: Result := Result + Chr(ALIEN_ALPHABET_3CODES[Random(Length(ALIEN_ALPHABET_3CODES))]);
  end;
end;

function GenerateStarName: string;
const
  PREFIXES: array[0..9] of string = ('Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 'Eta', 'Theta', 'Iota', 'Kappa');
  SUFFIXES: array[0..9] of string = ('Prime', 'Major', 'Minor', 'Nebula', 'Abyss', 'Nexus', 'Forge', 'Sentinel', 'Crucible', 'Beacon');
  CONSTELLATIONS: array[0..9] of string = ('Cygnus', 'Orion', 'Draco', 'Ursa Major', 'Ursa Minor', 'Lyra', 'Aquila', 'Cassiopeia', 'Pegasus', 'Hydra');
  SCIFI_THEMES: array[0..9] of string = ('Sol Invictus', 'Terra Nova', 'Eden Prime', 'Arcturus Station', 'Luminara', 'Xandar', 'Krypton', 'Vega Prime', 'Reach', 'New Eden');
begin
  var LPrefix := PREFIXES[Random(Length(PREFIXES))];
  var LSuffix := SUFFIXES[Random(Length(SUFFIXES))];
  var LNumberString := '';

  if Random(4) = 0 then
    Exit(GenerateAlienText(Random(20) + 5));

  if Random(3) = 0 then
    LNumberString := IntToStr(Random(1000)); // Random number between 0 and 999

  LPrefix := LPrefix + LNumberString;

  if Random(2) = 0 then
  begin
    var LConstellationOrTheme: string;

    if Random(2) = 0 then
      LConstellationOrTheme := SCIFI_THEMES[Random(Length(SCIFI_THEMES))]
    else
      LConstellationOrTheme := CONSTELLATIONS[Random(Length(CONSTELLATIONS))];

    Result := LPrefix + ' ' + LSuffix + ' (' + LConstellationOrTheme + ')';
  end
  else
   Result := LPrefix + ' ' + LSuffix;
end;

procedure TForm1.btnFieldByNameClick(Sender: TObject);
begin
  StartTimer(Sender);
  try
    while not FDQueryData.Eof do
    begin
      var LCalculatedDistance := Sqrt(
          Sqr(FDQueryData.FieldByName('x0').AsFloat) +
          Sqr(FDQueryData.FieldByName('y0').AsFloat) +
          Sqr(FDQueryData.FieldByName('z0').AsFloat));

      if LCalculatedDistance > 1000.00 then
        ListBoxData.Items.Add(FDQueryData.FieldByName('Name').AsString);

      FDQueryData.Next;
    end;
  finally
    EndTimer;
  end;
end;

procedure TForm1.btnIndexedFieldsClick(Sender: TObject);
begin
  StartTimer(Sender);
  try
    while not FDQueryData.Eof do
    begin
      var LCalculatedDistance := Sqrt(
          Sqr(FDQueryData.Fields[2].AsFloat) +
          Sqr(FDQueryData.Fields[3].AsFloat) +
          Sqr(FDQueryData.Fields[4].AsFloat));

      if LCalculatedDistance > 1000.00 then
        ListBoxData.Items.Add(FDQueryData.Fields[1].AsString);

      FDQueryData.Next;
    end;
  finally
    EndTimer;
  end;
end;

procedure TForm1.btnGenerateClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    Enabled := False;
    FDQueryData.Close;
    FDQueryData.CreateDataSet;

    for var Index := 1 to SpinEditRowCount.Value do
      FDQueryData.InsertRecord(
        [Index, GenerateStarName,
         Random * Random(900),
         Random * Random(900),
         Random * Random(900)]);

    FDMemTable.SaveToFile(DATABASE_FILENAME, sfBinary);
    FDLocalSQL.Active := True;

    FDQueryData.Open; // pre-cache
    FDQueryData2.Open;

    Log(FormatFloat('#,##0', SpinEditRowCount.Value) + ' records generated', 1);
  finally
    Screen.Cursor := crDefault;
    Enabled := True;
  end;
end;

procedure TForm1.btnFieldReferencesClick(Sender: TObject);
begin
  StartTimer(Sender);
  try
    var x0_field := FDQueryData.FieldByName('x0');
    var y0_field := FDQueryData.FieldByName('y0');
    var z0_field := FDQueryData.FieldByName('z0');
    var name_field := FDQueryData.FieldByName('name');

    while not FDQueryData.Eof do
    begin
      var LCalculatedDistance := Sqrt(
          Sqr(x0_field.AsFloat) +
          Sqr(y0_field.AsFloat) +
          Sqr(z0_field.AsFloat));

      if LCalculatedDistance > 1000.00 then
        ListBoxData.Items.Add(name_field.AsString);

      FDQueryData.Next;
    end;
  finally
    EndTimer;
  end;
end;

procedure TForm1.btnDesignTimeFieldsClick(Sender: TObject);
begin
  StartTimer(Sender);
  try
    while not FDQueryData.Eof do
    begin
      var LCalculatedDistance := Sqrt(
          Sqr(FDQueryData_x0.AsFloat) +
          Sqr(FDQueryData_y0.AsFloat) +
          Sqr(FDQueryData_z0.AsFloat));

      if LCalculatedDistance > 1000.00 then
        ListBoxData.Items.Add(FDQueryData_Name.AsString);

      FDQueryData.Next;
    end;
  finally
    EndTimer;
  end;
end;

procedure TForm1.EndTimer;
begin
  FStopWatch.Stop;

  FDQueryData.Close;

  Log('Count: ' + ListBoxData.Count.ToString, 1);
  Log('Elapsed time: ' + FormatFloat('#,##0.00 ms', FStopWatch.Elapsed.Milliseconds), 1);
  Log('-----');

  ListBoxData.Items.EndUpdate;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  FDQueryData.Close;

  FDLocalSQL.Active := False;

  FDMemTable.Close;
  FDConnection.Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Randomize;
end;

procedure TForm1.Log(const ALogMessage: string; const AIndent: Integer);
begin
  MemoLog.Lines.Add(StringOfChar(' ', AIndent * 2) + ALogMessage);
end;

procedure TForm1.StartTimer(const ASender: TObject);
begin
  FDQueryData.Open;

  ListBoxData.Clear;
  Log((ASender as TButton).Caption);

  ListBoxData.Items.BeginUpdate;

  FStopWatch := TStopwatch.StartNew;
end;

procedure TForm1.TimerAfterShowTimer(Sender: TObject);
begin
  TimerAfterShow.Enabled := False;

  Screen.Cursor := crHourGlass;
  try
    if FileExists(DATABASE_FILENAME) then
    begin
      FDMemTable.LoadFromFile(DATABASE_FILENAME, sfBinary);

      FDQueryData.Open; // pre-cache
      FDQueryData2.Open;
      Log(FormatFloat('#,##0', FDQueryData2cnt.AsInteger) + ' records loaded', 1);
    end
    else
      Log('NO records loaded!', 1);

    Log('-----');
  finally
    Screen.Cursor := crDefault;
  end;
end;

end.
