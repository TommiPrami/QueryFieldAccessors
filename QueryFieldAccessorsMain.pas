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
    procedure btnDesignTimeFieldsClick(Sender: TObject);
    procedure btnFieldByNameClick(Sender: TObject);
    procedure btnFieldReferencesClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnIndexedFieldsClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
  strict private
    { Private declarations }
    FStopWatch: TStopWatch;
    procedure Log(const ALogMessage: string; const AIndent: Integer = 0);
    procedure StartTimer(Sender: TObject);
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
  C_SampleData = '..\..\QueryFieldData.db';

function GenerateAlienText(CharCount: Integer): string;
const
  AlienAlphabets: array[0..1] of string = (
    '⏣⎌⛫⎋⎉⎅⎇⎀⎁⏢⏦⏧⏥⏠⏞⏜⏛⏚⏕⎔⎊⎉⌽⍙⍘⍗⍖⍕⍔⛶⛕⛖⛋⛌⛍⛐⛒⛣⌤⌙⌭⌮⌯⌰⌱⌲⌳⌴',
    '░▒▓█♡♥♦♣♠▪▫➢∞✩✪✫✬✭✮✯✰⁂⌘ૐ࿃࿄࿅࿆࿇࿈࿉࿊࿋࿇࿈࿎࿏࿐࿑࿒࿓࿔᠀᠁᠂᠃᠄᠅᠆᠇᠈᠉᠊᠋᠌᠍᠎᠏᠐᠑᠒᠓᠔᠕᠖᠗᠘᠙');
  AlienAlphabet3Codes: array[0..49] of Word = (
      $2591, $2592, $2593, $2588, $2580, $2584, $258C, $2590, $25A0, $25A1,  // Block Elements
      $25CB, $25CF, $25C6, $25D8, $25D9, $2665, $2660, $2666, $2663, $2605,  // Geometric Shapes and Misc. Symbols
      $2701, $2702, $2703, $2704, $2706, $2707, $2708, $2709, $2710, $2711,  // Dingbats
      $2712, $2713, $2714, $2715, $2716, $2717, $2718, $2719, $2720, $2721,  // Dingbats
      $2722, $2723, $2724, $2725, $2726, $2727, $2736, $2729, $2744, $2745   // Dingbats and Misc. Symbols
    );

begin
  var ChosenAlphabetIndex := Random(3);

  Result := '';
  for var i := 1 to CharCount do
  case ChosenAlphabetIndex of
    0,1:  Result := Result + AlienAlphabets[ChosenAlphabetIndex][Random(Length(AlienAlphabets[ChosenAlphabetIndex])) + 1];
    2:  Result := Result + Chr(AlienAlphabet3Codes[random(Length(AlienAlphabet3Codes))]);
  end;
end;

function GenerateStarName: string;
const
  Prefixes: array[0..9] of string = ('Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 'Eta', 'Theta', 'Iota', 'Kappa');
  Suffixes: array[0..9] of string = ('Prime', 'Major', 'Minor', 'Nebula', 'Abyss', 'Nexus', 'Forge', 'Sentinel', 'Crucible', 'Beacon');
  Constellations: array[0..9] of string = ('Cygnus', 'Orion', 'Draco', 'Ursa Major', 'Ursa Minor', 'Lyra', 'Aquila', 'Cassiopeia', 'Pegasus', 'Hydra');
  ScifiThemes: array[0..9] of string = ('Sol Invictus', 'Terra Nova', 'Eden Prime', 'Arcturus Station', 'Luminara', 'Xandar', 'Krypton', 'Vega Prime', 'Reach', 'New Eden');
begin
  var Prefix := Prefixes[Random(Length(Prefixes))];
  var Suffix := Suffixes[Random(Length(Suffixes))];
  var NumberString := '';

  if random(4) = 0 then
    Exit(GenerateAlienText(Random(20)+5));

  if Random(3) = 0 then
    NumberString := IntToStr(Random(1000)); // Random number between 0 and 999

  Prefix := Prefix + NumberString;

  if Random(2) = 0 then
  begin
    var ConstellationOrTheme: String;
    if Random(2) = 0 then
      ConstellationOrTheme := ScifiThemes[Random(Length(ScifiThemes))]
    else
      ConstellationOrTheme := Constellations[Random(Length(Constellations))];

    Result := Prefix + ' ' + Suffix + ' (' + ConstellationOrTheme + ')';
  end else
   Result := Prefix + ' ' + Suffix;
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

    FDMemTable.SaveToFile(C_SampleData, sfBinary);
    FDLocalSQL.Active := True;

    FDQueryData.Open; // pre-cache
    FDQueryData2.Open;

    Log(FormatFloat('#,##0', FDQueryData2cnt.AsInteger) + ' records generated', 1);
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

  Screen.Cursor := crHourGlass;
  try
    if FileExists(C_SampleData) then
    begin
      FDMemTable.LoadFromFile(C_SampleData,sfBinary);

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

procedure TForm1.Log(const ALogMessage: string; const AIndent: Integer);
begin
  MemoLog.Lines.Add(StringOfChar(' ', AIndent * 2) + ALogMessage);
end;

procedure TForm1.StartTimer(Sender: TObject);
begin
  FDQueryData.Open;

  ListBoxData.Clear;
  Log((Sender as TButton).Caption);

  ListBoxData.Items.BeginUpdate;

  FStopWatch := TStopwatch.StartNew;
end;

end.
