codeunit 2023 "Image Analysis Wrapper V3.2" implements "Image Analysis Provider"
{
    Access = Internal;

    // https://westus.dev.cognitive.microsoft.com/docs/services/computer-vision-v3-2/operations/56f91f2e778daf14a499f21b

    var
        RequestIdTelemetryMsg: Label 'Call to Image Analysis succeeded. ID present: %1; Request ID: %2.', Locked = true;
        CognitiveServicesErr: Label 'Could not contact the %1. %2 Status code: %3.', Comment = '%1: Error returned from called API. %2: the error message. %3: HTTP status code of error';
        MediaTooLargeErr: Label 'The media file is too large. Only images up to 4 MB are supported.';
        MediaTooSmallErr: Label 'The media file is too small. It must be at least 50x50 pixels.';
        MediaWrongFormatErr: Label 'The media file is not supported. Only images of the following types are supported: JPEG, PNG, GIF, BMP.';
        UnsupportedLanguageErr: Label 'You are trying to run image analysis in a language (%1) that is not supported.', Comment = '%1: a language code, for example 1033';
        CheckingImageSupportedTelemetryMsg: Label 'Checking image supported. Bytes: %1, Size: %2, Format: %3.', Locked = true;
        ComputerVisionApiTxt: Label 'Computer Vision API';
        AnalyzePathTxt: Label '/vision/v3.2/analyze', Locked = true;
        LanguageCodeQueryParameterTxt: Label 'language', Locked = true;
        VisualFeaturesQueryParameterTxt: Label 'visualFeatures', Locked = true;
        LastError: Text;

    [NonDebuggable]
    procedure InvokeAnalysis(var JSONManagement: Codeunit "JSON Management"; BaseUrl: Text; ImageAnalysisKey: Text; ImagePath: Text; ImageAnalysisTypes: List of [Enum "Image Analysis Type"]; LanguageId: Integer): Boolean
    begin
        exit(TryInvokeAnalysisInternal(JSONManagement, BaseUrl, ImageAnalysisKey, ImagePath, ImageAnalysisTypes, LanguageId));
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryInvokeAnalysisInternal(var JSONManagement: Codeunit "JSON Management"; BaseUrl: Text; ImageAnalysisKey: Text; ImagePath: Text; ImageAnalysisTypes: List of [Enum "Image Analysis Type"]; LanguageId: Integer)
    var
        FileManagement: Codeunit "File Management";
        File: DotNet File;
        FileStream: DotNet FileStream;
        JsonResult: DotNet JObject;
        MessageText: Text;
        PostUrl: Text;
        Language: Text[10];
        HttpResponseMessage: HttpResponseMessage;
        HttpRequestMessage: HttpRequestMessage;
        ContentHttpHeaders: HttpHeaders;
        HttpHeaders: HttpHeaders;
        RequestHttpContent: HttpContent;
        ResponseHttpContent: HttpContent;
        HttpClient: HttpClient;
        HttpContentText: Text;
    begin
        If not TryGetImageAnalysisUserLanguage(LanguageId, Language, ImageAnalysisTypes) then
            Error(UnsupportedLanguageErr);

        HttpRequestMessage.Method('POST');
        PostUrl := BuildUri(BaseUrl, Language, ImageAnalysisTypes);
        HttpRequestMessage.SetRequestUri(PostUrl);

        HttpRequestMessage.GetHeaders(HttpHeaders);
        HttpHeaders.Add('Accept', 'application/json');
        HttpHeaders.Add('Ocp-Apim-Subscription-Key', ImageAnalysisKey);

        FileManagement.IsAllowedPath(ImagePath, false);
        FileStream := File.OpenRead(ImagePath);
        RequestHttpContent.WriteFrom(FileStream);
        HttpRequestMessage.Content := RequestHttpContent;
        HttpRequestMessage.Content.GetHeaders(ContentHttpHeaders);
        ContentHttpHeaders.Remove('Content-Type');
        ContentHttpHeaders.Add('Content-Type', 'application/octet-stream');

        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

        ResponseHttpContent := HttpResponseMessage.Content;
        ResponseHttpContent.ReadAs(HttpContentText);
        JSONManagement.InitializeObject(HttpContentText);

        FileStream.Dispose();

        if not HttpResponseMessage.IsSuccessStatusCode then begin
            JSONManagement.GetJSONObject(JsonResult);
            JSONManagement.GetStringPropertyValueFromJObjectByName(JsonResult, 'message', MessageText);
            LastError := StrSubstNo(CognitiveServicesErr, ComputerVisionApiTxt, MessageText, HttpResponseMessage.HttpStatusCode);
            Error('');
        end;

        LogCorrelationToTelemetry(JSONManagement);
    end;

    local procedure LogCorrelationToTelemetry(var JSONManagement: Codeunit "JSON Management")
    var
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        JsonResult: DotNet JObject;
        RequestIdAsGuid: Guid;
        RequestIdPresent: Boolean;
    begin
        JSONManagement.GetJSONObject(JsonResult);

        RequestIdPresent := JSONManagement.GetGuidPropertyValueFromJObjectByName(JsonResult, 'requestId', RequestIdAsGuid);

        Session.LogMessage('0000K10', StrSubstNo(RequestIdTelemetryMsg, RequestIdPresent, RequestIdAsGuid),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ImageAnalysisManagement.GetTelemetryCategory());
    end;

    procedure GetLastError(): Text
    begin
        exit(LastError);
    end;

    procedure IsMediaSupported(MediaID: Guid): Boolean
    var
        TenantMedia: Record "Tenant Media";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
    begin
        TenantMedia.Get(MediaID);

        TenantMedia.CalcFields(Content);

        Session.LogMessage('0000JYU',
            StrSubstNo(CheckingImageSupportedTelemetryMsg, TenantMedia.Content.Length() > 4 * 1024 * 1024, (TenantMedia.Height < 50) or (TenantMedia.Width < 50), not LowerCase(TenantMedia."Mime Type").StartsWith('image')),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ImageAnalysisManagement.GetTelemetryCategory());

        if TenantMedia.Content.Length() > 4 * 1024 * 1024 then begin
            LastError := MediaTooLargeErr;
            exit(false);
        end;

        if (TenantMedia.Height < 50) or (TenantMedia.Width < 50) then begin
            LastError := MediaTooSmallErr;
            exit(false);
        end;

        if not LowerCase(TenantMedia."Mime Type").StartsWith('image') then begin
            LastError := MediaWrongFormatErr;
            exit(false);
        end;

        exit(true);
    end;

    local procedure BuildUri(UriTxt: Text; LanguageCode: Text[10]; ImageAnalysisTypes: List of [Enum "Image Analysis Type"]): Text
    var
        Uri: Codeunit Uri;
        UriBuilder: Codeunit "Uri Builder";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
    begin
        UriBuilder.Init(UriTxt);
        UriBuilder.SetScheme('https');
        UriBuilder.SetPath(AnalyzePathTxt);
        UriBuilder.SetQuery('');
        if LanguageCode <> '' then
            UriBuilder.AddQueryParameter(LanguageCodeQueryParameterTxt, LanguageCode);

        UriBuilder.AddQueryParameter(VisualFeaturesQueryParameterTxt, ImageAnalysisManagement.ToCommaSeparatedList(ImageAnalysisTypes));
        UriBuilder.GetUri(Uri);
        exit(Uri.GetAbsoluteUri());
    end;

    procedure IsLanguageSupported(AnalysisTypes: List of [Enum "Image Analysis Type"]; LanguageId: Integer): Boolean
    var
        LanguageCode: Text[10];
    begin
        exit(TryGetImageAnalysisUserLanguage(LanguageId, LanguageCode, AnalysisTypes));
    end;

    [TryFunction]
    local procedure TryGetImageAnalysisUserLanguage(InputLanguageId: Integer; var OutputLanguageCode: Text[10]; InputAnalysisTypes: List of [Enum "Image Analysis Type"])
    var
        DotNetCultureInfo: Codeunit DotNet_CultureInfo;
        CultureCode: Text[10];
        IsoLanguage: Text[10];
        SupportedLanguages: List of [Text[10]];
        LocalAnalysisTypes: List of [Enum "Image Analysis Type"];
    begin
        LocalAnalysisTypes.AddRange(InputAnalysisTypes);
        LocalAnalysisTypes.Remove(Enum::"Image Analysis Type"::Adult); // Adult is language independent

        // https://aka.ms/cv-languages
        case true of
            LocalAnalysisTypes.Count = 0:
                Error('');
            (LocalAnalysisTypes.Count = 1) and (LocalAnalysisTypes.Get(1) = Enum::"Image Analysis Type"::Tags):
                SupportedLanguages.AddRange(
                        'ar', 'az', 'bg', 'bs', 'ca', 'cs', 'cy', 'da', 'de', 'el', 'en', 'es', 'et', 'eu',
                        'fi', 'fr', 'ga', 'gl', 'he', 'hi', 'hr', 'hu', 'id', 'it', 'ja',
                        'kk', 'ko', 'lt', 'lv', 'mk', 'ms', 'nb', 'nl',
                        'pl', 'prs', 'pt-BR', 'pt', 'pt-PT', 'ro', 'ru', 'sk', 'sl', 'sr-Cryl', 'sr-Latn', 'sv', 'th', 'tr',
                        'uk', 'vi', 'zh', 'zh-Hans', 'zh-Hant'
                    );
            else
                SupportedLanguages.Add('en');
        end;

        DotNetCultureInfo.GetCultureInfoById(InputLanguageId);

        CultureCode := CopyStr(DotNetCultureInfo.Name(), 1, MaxStrLen(CultureCode));
        IsoLanguage := CopyStr(DotNetCultureInfo.TwoLetterISOLanguageName(), 1, MaxStrLen(IsoLanguage));

        case true of
            SupportedLanguages.Contains(CultureCode):
                OutputLanguageCode := CultureCode;
            SupportedLanguages.Contains(IsoLanguage):
                OutputLanguageCode := IsoLanguage;
            else
                Error('');
        end;
    end;

}