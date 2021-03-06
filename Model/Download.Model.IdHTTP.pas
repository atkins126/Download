unit Download.Model.IdHTTP;

interface

uses
  Download.Model.Interfaces, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, System.Threading,
  Download.Download.Tipos, Download.Controller.Interfaces,
  System.Generics.Collections, IdAuthentication, IdAntiFreezeBase,
  IdAntiFreeze, Download.Model.Dados, IdIOHandler, IdIOHandlerStack,
  IdIOHandlerSocket, IdSSL, IdSSLOpenSSL;

type

  TModelIdHTTP = class(TInterfacedObject, iModelIdHTTP, iDownloadSubjet)
  private
    FIdDatabase: LongInt;
    FIdHTTP: TIdHTTP;
    FIdSSHandler: TIdSSLIOHandlerSocketOpenSSL;
    FDatabase: TDados;
    FTask: iTask;
    IdAntiFreeze: TIdAntiFreeze;
    FDownloadNotificacao: TResultadoDownload;
    FResFuture: IFuture<TResultadoDownload>;
    FObservers: TList<iDownloadObserver>;
    procedure FIdHTTPWork(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCount: Int64);
    procedure FIdHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCountMax: Int64);
    procedure FIdHTTPWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
    function Porcentagem(intValorMaximo, intValorAtual: real): real;
    function KiloBytes(intValorAtual: real): real;
  public
    constructor Create;
    destructor Destroy; Override;
    class function New: iModelIdHTTP;
    procedure FazerDownloadDoArquivo(strUrl, strDestino: String);
    procedure PararDownload;
    procedure AdicionarObserver(Observer: iDownloadObserver);
    procedure RemoverObserver(Observer: iDownloadObserver);
    procedure Notificar(ResultadoDownload: TResultadoDownload);
    function RetornarOBserver: iDownloadSubjet;
    function EstaExecutando: Boolean;
  end;

implementation

uses
  System.SysUtils, System.Classes;


{ TModelIdHTTP }

constructor TModelIdHTTP.Create;
begin

  FIdHTTP                        := TIdHTTP.Create(nil);
  FIdSSHandler                   := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  FIdSSHandler.SSLOptions.Method := sslvSSLv23;
  FIdHTTP.IOHandler              := FIdSSHandler;

  FIdHTTP.OnWork      := FIdHTTPWork;
  FIdHTTP.OnWorkBegin := FIdHTTPWorkBegin;
  FIdHTTP.OnWorkEnd   := FIdHTTPWorkEnd;

  FDatabase:= TDados.Create(nil);
  FIdDatabase := 0;

  FDownloadNotificacao.ProgressoKiloBytes := 0;
  FDownloadNotificacao.ProgressoPorcentagem := 0;
  FDownloadNotificacao.ProgressoMaximo := 0;

  IdAntiFreeze := TIdAntiFreeze.Create(nil);
  FObservers := TList<iDownloadObserver>.Create;
end;

destructor TModelIdHTTP.Destroy;
begin
  FreeAndNil(FObservers);
  FreeAndNil(FIdSSHandler);
  FreeAndNil(FIdHTTP);
  FreeAndNil(IdAntiFreeze);
  FreeAndNil(FDatabase);
  inherited;
end;

function TModelIdHTTP.EstaExecutando: Boolean;
begin
  Result := False;

  if Assigned(FTask) then
    result := (FTask.Status = TTaskStatus.Running);
end;

procedure TModelIdHTTP.AdicionarObserver(Observer: iDownloadObserver);
begin
  FObservers.Add(Observer);
end;

procedure TModelIdHTTP.FIdHTTPWork(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
begin
  FTask.CheckCanceled;
  FDownloadNotificacao.Status := stEstaExecutando;
  FDownloadNotificacao.ProgressoKiloBytes := KiloBytes(AWorkCount);
  FDownloadNotificacao.ProgressoPorcentagem := Porcentagem(FDownloadNotificacao.ProgressoMaximo, AWorkCount);
  FDownloadNotificacao.Progresso := AWorkCount;
  Notificar(FDownloadNotificacao);
end;

function TModelIdHTTP.Porcentagem(intValorMaximo, intValorAtual: real): real;
begin
  Result := ((intValorAtual * 100) / intValorMaximo);
end;

function TModelIdHTTP.KiloBytes(intValorAtual: real): real;
begin
  Result := ((intValorAtual / 1024) / 1024);
end;

procedure TModelIdHTTP.FIdHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCountMax: Int64);
begin
  FDownloadNotificacao.Status := stEstaExecutando;
  FDownloadNotificacao.ProgressoMaximo := AWorkCountMax;
  Notificar(FDownloadNotificacao);
end;

procedure TModelIdHTTP.FIdHTTPWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
  if not (FTask.Status = TTaskStatus.Canceled) then
  begin
    FDatabase.SalvarFim(FIdDatabase, Now);
    FDownloadNotificacao.ProgressoPorcentagem := 100;
    FDownloadNotificacao.ProgressoMaximo := 0;
    FDownloadNotificacao.Status := stFinalizadoComSucesso;
    Notificar(FDownloadNotificacao);
  end;
end;

procedure TModelIdHTTP.FazerDownloadDoArquivo(strUrl, strDestino: String);
begin
  if strUrl.IsEmpty or strDestino.isEmpty then
    raise EDownloadException.Create('Parāmetros vazios em TModelIdHTTP.FazerDownloadDoArquivo');

  FIdDatabase := FDatabase.SalvarInicio(strUrl, Now);

  FTask := TTask.Create(
    procedure
    begin
      TThread.Synchronize(TThread.CurrentThread,
      procedure
      var
        FileDownload : TFileStream;
      begin
        FileDownload := TFileStream.Create(strDestino, fmCreate);
        try
          FIdHTTP.CleanupInstance;
          try
            FIdHTTP.Get(strUrl, fileDownload);
          except
            on E:Exception do
            begin
              FDownloadNotificacao.Status := stFinalizado;
              if Lowercase(e.Message) <> 'operation cancelled' then
                FDownloadNotificacao.MsgErro := e.Message;
              Notificar(FDownloadNotificacao);
            end;
          end;
        finally
          FreeAndNil(fileDownload);
        end;
      end
      );
    end
  );

  try
    FTask.Start;
  except
    on E:Exception do
    begin
      FDownloadNotificacao.MsgErro := 'Erro ao rodar thread: ' + e.Message;
      FDownloadNotificacao.Status := stFinalizado;
      Notificar(FDownloadNotificacao);
    end;
  end;

end;

class function TModelIdHTTP.New: iModelIdHTTP;
begin
  Result := Self.Create;
end;

procedure TModelIdHTTP.Notificar(ResultadoDownload: TResultadoDownload);
var
  Observer: iDownloadObserver;
begin
  for Observer in FObservers do
  begin
    Observer.Atualizar(ResultadoDownload);
  end;
end;

procedure TModelIdHTTP.PararDownload;
begin
  FTask.Cancel;
end;

procedure TModelIdHTTP.RemoverObserver(Observer: iDownloadObserver);
begin
  FObservers.Delete(FObservers.IndexOf(Observer));
end;

function TModelIdHTTP.RetornarOBserver: iDownloadSubjet;
begin
  Result := Self;
end;

end.
