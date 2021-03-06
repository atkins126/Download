unit Download.Controller.Tipos;

interface

uses
  System.SysUtils;

type

  EDownloadException = class(Exception);

  TStatus = (stFinalizadoComSucesso, stFinalizadoComErro,
             stEstaExecutando, stFinalizadoPeloUsuario);

  TResultadoDownload = record
    Progresso: Int64;
    ProgressoKiloBytes: Real;
    ProgressoPorcentagem: Real;
    ProgressoMaximo: Int64;
    MsgErro: String;
    Status: TStatus;
  end;

implementation

end.
