codeunit 1299 "Web Request Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ConnectionErr: Label 'Connection to the remote service could not be established.\\';
        InvalidUriErr: Label 'The URI is not valid.';
        NonSecureUriErr: Label 'The URI is not secure.';
        ProcessingWindowMsg: Label 'Please wait while the server is processing your request.\This may take several minutes.';
        ServiceURLTxt: Label '\\Service URL: %1.', Comment = 'Example: ServiceURL: http://www.contoso.com/';
        GlobalHttpWebResponseError: DotNet HttpWebResponse;

    [TryFunction]
    procedure IsValidUri(Url: Text)
    var
        ResultUri: DotNet Uri;
        Uri: DotNet Uri;
        UriKind: DotNet UriKind;
    begin
        if not Uri.IsWellFormedUriString(Url, UriKind.Absolute) then
            if not Uri.TryCreate(Url, UriKind.Absolute, ResultUri) then
                Error(InvalidUriErr);
    end;

    [TryFunction]
    procedure IsValidUriWithoutProtocol(Url: Text)
    begin
        if not IsValidUri(Url) then
            if not IsValidUri('http://' + Url) then
                Error(InvalidUriErr);
    end;

    [TryFunction]
    procedure IsSecureHttpUrl(Url: Text)
    var
        Uri: DotNet Uri;
    begin
        IsValidUri(Url);
        Uri := Uri.Uri(Url);
        if Uri.Scheme <> 'https' then
            Error(NonSecureUriErr);
    end;

    [TryFunction]
    procedure IsHttpUrl(Url: Text)
    var
        Uri: DotNet Uri;
    begin
        IsValidUri(Url);
        Uri := Uri.Uri(Url);
        if (Uri.Scheme <> 'http') and (Uri.Scheme <> 'https') then
            Error(InvalidUriErr);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure GetWebResponse(var HttpWebRequest: DotNet HttpWebRequest; var HttpWebResponse: DotNet HttpWebResponse; var ResponseInStream: InStream; var HttpStatusCode: DotNet HttpStatusCode; var ResponseHeaders: DotNet NameValueCollection; ProgressDialogEnabled: Boolean)
    var
        ProcessingWindow: Dialog;
    begin
        if ProgressDialogEnabled then
            ProcessingWindow.Open(ProcessingWindowMsg);

        ClearLastError;
        HttpWebResponse := HttpWebRequest.GetResponse;
        HttpWebResponse.GetResponseStream.CopyTo(ResponseInStream);
        HttpStatusCode := HttpWebResponse.StatusCode;
        ResponseHeaders := HttpWebResponse.Headers;

        if ProgressDialogEnabled then
            ProcessingWindow.Close;
    end;

    [Scope('OnPrem')]
    procedure GetWebResponseError(var WebException: DotNet WebException; var ServiceURL: Text): Text
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        WebExceptionStatus: DotNet WebExceptionStatus;
        HttpStatusCode: DotNet HttpStatusCode;
        ErrorText: Text;
    begin
        DotNetExceptionHandler.Collect;

        if not DotNetExceptionHandler.CastToType(WebException, GetDotNetType(WebException)) then
            DotNetExceptionHandler.Rethrow;

        if not IsNull(WebException.Response) then
            if not IsNull(WebException.Response.ResponseUri) then
                ServiceURL := StrSubstNo(ServiceURLTxt, WebException.Response.ResponseUri.AbsoluteUri);

        ErrorText := ConnectionErr + WebException.Message + ServiceURL;
        if not WebException.Status.Equals(WebExceptionStatus.ProtocolError) then
            exit(ErrorText);

        if IsNull(WebException.Response) then
            DotNetExceptionHandler.Rethrow;

        GlobalHttpWebResponseError := WebException.Response;
        if not (GlobalHttpWebResponseError.StatusCode.Equals(HttpStatusCode.Found) or
                GlobalHttpWebResponseError.StatusCode.Equals(HttpStatusCode.InternalServerError))
        then
            exit(ErrorText);

        exit('');
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure GetResponseText(Method: Text; Url: Text; AccessToken: Text; var ResponseText: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        HttpWebRequest: DotNet HttpWebRequest;
        HttpWebResponse: DotNet HttpWebResponse;
        ResponseInputStream: InStream;
        ChunkText: Text;
    begin
        HttpWebRequest := HttpWebRequest.Create(Url);
        HttpWebRequest.Method := Method;
        HttpWebRequest.ContentLength := 0;
        // add the access token to the authorization bearer header
        HttpWebRequest.Headers.Add('Authorization', 'Bearer ' + AccessToken);
        HttpWebResponse := HttpWebRequest.GetResponse;

        TempBlob.CreateInStream(ResponseInputStream);
        HttpWebResponse.GetResponseStream.CopyTo(ResponseInputStream);

        // the READTEXT() function apparently only reads a single line, so we must loop through the stream to get the contents of every line.
        while not ResponseInputStream.EOS do begin
            ResponseInputStream.ReadText(ChunkText);
            ResponseText += ChunkText;
        end;

        HttpWebResponse.Close; // close connection
        HttpWebResponse.Dispose; // cleanup of IDisposable
    end;

    procedure GetHostNameFromUrl(Url: Text): Text
    var
        Uri: DotNet Uri;
    begin
        IsValidUri(Url);
        Uri := Uri.Uri(Url);
        exit(Uri.Host);
    end;
}

