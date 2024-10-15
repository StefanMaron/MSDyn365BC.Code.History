// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Integration.Graph;

using System.RestClient;

codeunit 135142 "Mock Http Client Handler" implements "Http Client Handler"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        _httpRequestMessage: Codeunit System.RestClient."Http Request Message";
        _httpResponseMessage: Codeunit System.RestClient."Http Response Message";
        _responseMessageSet: Boolean;
        _sendError: Text;


    procedure Send(HttpClient: HttpClient; HttpRequestMessage: Codeunit System.RestClient."Http Request Message"; var HttpResponseMessage: Codeunit System.RestClient."Http Response Message") Success: Boolean;
    begin

        ClearLastError();
        exit(TrySend(HttpRequestMessage, HttpResponseMessage));
    end;

    procedure ExpectSendToFailWithError(SendError: Text)
    begin
        _sendError := SendError;
    end;

    procedure SetResponse(var NewHttpResponseMessage: Codeunit System.RestClient."Http Response Message")
    begin
        _httpResponseMessage := NewHttpResponseMessage;
        _responseMessageSet := true;
    end;

    procedure GetHttpRequestMessage(var OutHttpRequestMessage: Codeunit System.RestClient."Http Request Message")
    begin
        OutHttpRequestMessage := _httpRequestMessage;
    end;

    [TryFunction]
    local procedure TrySend(HttpRequestMessage: Codeunit System.RestClient."Http Request Message"; var HttpResponseMessage: Codeunit System.RestClient."Http Response Message")
    begin
        _httpRequestMessage := HttpRequestMessage;
        if _sendError <> '' then
            Error(_sendError);

        if _responseMessageSet then
            HttpResponseMessage := _httpResponseMessage;
    end;
}