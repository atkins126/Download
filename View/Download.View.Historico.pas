unit Download.View.Historico;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Data.DB,
  Vcl.Grids, Vcl.DBGrids, Download.Controller.Interfaces;

type
  TfmHistorico = class(TForm)
    pnCabecalho: TPanel;
    pnFundo: TPanel;
    pnRodape: TPanel;
    GridPanel2: TGridPanel;
    btFechar: TButton;
    DBGrid1: TDBGrid;
    DataSource1: TDataSource;
    procedure FormShow(Sender: TObject);
    procedure btFecharClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FControllerDados: iControllerDados;
  public
    { Public declarations }
  end;

var
  fmHistorico: TfmHistorico;

implementation

uses
  Download.Controller.Dados;

{$R *.dfm}

procedure TfmHistorico.btFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TfmHistorico.FormCreate(Sender: TObject);
begin
  FControllerDados := TControllerDados.New;
end;

procedure TfmHistorico.FormShow(Sender: TObject);
begin
  DataSource1.DataSet := FControllerDados.RetornaHistorico;
end;

end.
