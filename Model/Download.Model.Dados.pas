unit Download.Model.Dados;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.VCLUI.Wait,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Download.Model.Interfaces,
  FireDAC.Comp.UI;

type
  TDados = class(TDataModule)
    FDConnection1: TFDConnection;
    FDQuery1: TFDQuery;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function SalvarInicio(Url: String; DataInicio: TDateTime): LongInt;
    procedure SalvarFim(Codigo: LongInt; DataFim: TDateTime);
    function TodosOsDownloads: TDataSet;
  end;

var
  Dados: TDados;

implementation

uses
  Vcl.Forms;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TDados.DataModuleCreate(Sender: TObject);
begin
  FDConnection1.Connected := False;
  FDConnection1.Params.Database := ExtractFilePath(Application.ExeName) + 'Database\Banco.db';
  FDConnection1.Connected := True;
end;

procedure TDados.DataModuleDestroy(Sender: TObject);
begin
  FDQuery1.Close;
  FDConnection1.Connected := False;
end;

procedure TDados.SalvarFim(Codigo: LongInt; DataFim: TDateTime);
begin
  FDQuery1.Close;
  FDQuery1.SQL.Clear;
  FDQuery1.SQL.Text := 'update LOGDOWNLOAD set DATAFIM = :DATAFIM where CODIGO = :CODIGO';
  FDQuery1.ParamByName('DATAFIM').Value := DataFim;
  FDQuery1.ParamByName('CODIGO').Value := Codigo;
  FDQuery1.ExecSQL;
end;

function TDados.SalvarInicio(Url: String; DataInicio: TDateTime): LongInt;
begin
  FDQuery1.Close;
  FDQuery1.SQL.Clear;
  FDQuery1.SQL.Text := 'insert into LOGDOWNLOAD (URL, DATAINICIO) ' +
    'values (:URL, :DATAINICIO)';
  FDQuery1.ParamByName('URL').Value := Url;
  FDQuery1.ParamByName('DATAINICIO').Value := DataInicio;
  FDQuery1.ExecSQL;

  FDQuery1.Close;
  FDQuery1.SQL.Clear;
  FDQuery1.SQL.Text := 'select MAX(CODIGO) CODIGO from LOGDOWNLOAD';
  FDQuery1.Open;
  Result := FDQuery1.FieldByName('CODIGO').AsLargeInt;
end;

function TDados.TodosOsDownloads: TDataSet;
begin
  FDQuery1.Close;
  FDQuery1.SQL.Clear;
  FDQuery1.Open('Select CODIGO, cast(URL as Character Varying(600)) URL, ' +
    'DATAINICIO, DATAFIM from LOGDOWNLOAD order by DATAFIM DESC');
  Result := FDQuery1;
end;

end.
