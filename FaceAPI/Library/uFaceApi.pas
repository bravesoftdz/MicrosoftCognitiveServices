unit uFaceApi;

interface

uses
  { TStream }
  System.Classes,
  { THTTPClient }
  System.Net.HttpClient,
  { TNetHeaders }
  System.Net.URLClient,
  { TFaceApiServer }
  uFaceApi.Servers.Types,
  { TContentType }
  uFaceApi.Content.Types,
  { TFaceApiBase }
  uFaceApi.Base,
  { IFaceApi }
  uIFaceApi,
  { TDetectOptions }
  uFaceApi.FaceDetectOptions;

type
  TFaceApi = class(TFaceApiBase, IFaceApi)
    function Detect(ARequestType: TContentType; AData: String; AStreamData: TBytesStream; ADetectOptions: TDetectOptions): String;
  public
    function DetectURL(AURL: String; ADetectOptions: TDetectOptions): String;
    function DetectFile(AFileName: String; ADetectOptions: TDetectOptions): String;
    function DetectStream(AStream: TBytesStream; ADetectOptions: TDetectOptions): String;

    function ListPersonGroups(AStart: String = ''; ATop: Integer = 1000): String;

    function ListPersonsInPersonGroup(APersonGroup: String): String;

    constructor Create(const AAccessKey: String; const AAccessServer: TFaceApiServer = fasGeneral);
  end;

implementation

uses
  { Format }
  System.SysUtils,
  { StringHelper }
  uFunctions.StringHelper;

constructor TFaceApi.Create(const AAccessKey: String; const AAccessServer: TFaceApiServer = fasGeneral);
begin
  inherited Create;

  AccessKey := AAccessKey;

  AccessServer := AAccessServer;
end;

function TFaceApi.Detect(ARequestType: TContentType; AData: String; AStreamData: TBytesStream; ADetectOptions: TDetectOptions): String;
var
  LHTTPClient: THTTPClient;
	LStream: TStream;
  LURL: String;
  LHeaders: TNetHeaders;
  LRequestContent: TBytesStream;
begin
  if ARequestType = rtFile then
    if not FileExists(AData) then
      Exit;

  LRequestContent := nil;

  LHTTPClient := PrepareHTTPClient(LHeaders, CONST_CONTENT_TYPE[ARequestType]);
  try
    LURL := Format(
      '%s/detect?returnFaceId=%s&returnFaceLandmarks=%s&returnFaceAttributes=%s',
      [
        ServerBaseUrl(AccessServer),
        BoolToStr(ADetectOptions.FaceId, True).ToLower,
        BoolToStr(ADetectOptions.FaceLandmarks, True).ToLower,
        ADetectOptions.FaceAttributesToString
      ]
    );

    if ARequestType = rtFile then
      LStream := LHTTPClient.Post(LURL, AData, nil, LHeaders).ContentStream
    else
      begin
        if ARequestType = rtStream then
          LRequestContent := AStreamData
        else
          LRequestContent := TBytesStream.Create(StringHelper.StringToBytesArray(Format('{ "url":"%s" }', [AData])));

        LStream := LHTTPClient.Post(LURL, LRequestContent, nil, LHeaders).ContentStream;
      end;

    Result := ProceedHttpClientData(LHTTPClient, LStream);
  finally
    LRequestContent.Free;
  end;
end;

function TFaceApi.DetectFile(AFileName: String; ADetectOptions: TDetectOptions): String;
begin
  Result := Detect(rtFile, AFileName, nil, ADetectOptions);
end;

function TFaceApi.DetectStream(AStream: TBytesStream; ADetectOptions: TDetectOptions): String;
begin
  Result := Detect(rtStream, '', AStream, ADetectOptions);
end;

function TFaceApi.DetectURL(AURL: String; ADetectOptions: TDetectOptions): String;
begin
  Result := Detect(rtUrl, AURL, nil, ADetectOptions);
end;

function TFaceApi.ListPersonGroups(AStart: String; ATop: Integer): String;
var
  LHTTPClient: THTTPClient;
	LStream: TStream;
  LURL: String;
  LHeaders: TNetHeaders;
begin
  LHTTPClient := PrepareHTTPClient(LHeaders, CONST_CONTENT_TYPE_JSON);

  LURL := Format(
    '%s/persongroups?start=%s&top=%s',
    [
      ServerBaseUrl(AccessServer),
      AStart,
      ATop.ToString
    ]
  );

  LStream := LHTTPClient.Get(LURL, nil, LHeaders).ContentStream;

  Result := ProceedHttpClientData(LHTTPClient, LStream);
end;

function TFaceApi.ListPersonsInPersonGroup(APersonGroup: String): String;
var
  LHTTPClient: THTTPClient;
	LStream: TStream;
  LURL: String;
  LHeaders: TNetHeaders;
begin
  LHTTPClient := PrepareHTTPClient(LHeaders, CONST_CONTENT_TYPE_JSON);

  LURL := Format(
    '%s/persongroups/%s/persons',
    [
      ServerBaseUrl(AccessServer),
      APersonGroup
    ]
  );

  LStream := LHTTPClient.Get(LURL, nil, LHeaders).ContentStream;

  Result := ProceedHttpClientData(LHTTPClient, LStream);
end;

end.