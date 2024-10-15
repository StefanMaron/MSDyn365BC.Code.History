// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Inbox;
using System.Globalization;

codeunit 534 "IC Read Notification JR"
{
    Permissions = tabledata "IC Incoming Notification" = md;

    var
        SyncronizationCompletedTok: Label 'SyncronizationCompleted', Locked = true;

    trigger OnRun()
    var
        ICIncomingNotification: Record "IC Incoming Notification";
    begin
        ICIncomingNotification.SetFilter(Status, '=%1|=%2', ICIncomingNotification.Status::Created, ICIncomingNotification.Status::Failed);
        if not ICIncomingNotification.FindSet() then
            exit;

        repeat
            ReadNotification(ICIncomingNotification);
            if ICIncomingNotification.Status = ICIncomingNotification.Status::Processed then
                CleanupNotifications(ICIncomingNotification);
        until ICIncomingNotification.Next() = 0;


        ICIncomingNotification.SetFilter(Status, '=%1|=%2', ICIncomingNotification.Status::Processed, ICIncomingNotification.Status::"Scheduled for deletion failed");
        if not ICIncomingNotification.FindSet() then
            exit;

        repeat
            CleanupNotifications(ICIncomingNotification);
        until ICIncomingNotification.Next() = 0;
    end;

    local procedure ReadNotification(var ICIncomingNotification: Record "IC Incoming Notification")
    var
        ICPartner: Record "IC Partner";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICDataExchangeAPI: Codeunit "IC Data Exchange API";
        CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
        Language: Codeunit Language;
        JsonResponse: JsonObject;
        Success: Boolean;
        CurrentGlobalLanguage: Integer;
    begin
        ICPartner.Get(ICIncomingNotification."Source IC Partner Code");
        if not CrossIntercompanyConnector.RequestICPartnerICOutgoingNotification(ICPartner, ICIncomingNotification."Operation ID", JsonResponse) then begin
            LogError(ICIncomingNotification);
            exit;
        end;

        CurrentGlobalLanguage := GlobalLanguage();
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        ICDataExchangeAPI.OnPopulateTransactionDataFromICOutgoingNotification(JsonResponse, Success);
        GlobalLanguage(CurrentGlobalLanguage);
        if not Success then begin
            LogError(ICIncomingNotification);
            exit;
        end;

        Commit();
        ICIncomingNotification.Status := ICIncomingNotification.Status::Processed;
        ICIncomingNotification."Notified DateTime" := CurrentDateTime();
        ICIncomingNotification.Modify();

        if ICPartner."Auto. Accept Transactions" then begin
            GetICInboxTransaction(JsonResponse, ICIncomingNotification, ICInboxTransaction);
            if not ICInboxTransaction.IsEmpty() then
                if ICInboxTransaction."Transaction Source" <> ICInboxTransaction."Transaction Source"::"Returned by Partner" then
                    ICDataExchangeAPI.EnqueueAutoAcceptedICInboxTransaction(ICPartner, ICInboxTransaction);
        end;
    end;

    local procedure LogError(var ICIncomingNotification: Record "IC Incoming Notification")
    begin
        ICIncomingNotification.Status := ICIncomingNotification.Status::Failed;
        ICIncomingNotification.SetErrorMessage(GetLastErrorText());
        ICIncomingNotification.Modify();
        ClearLastError();
    end;

    local procedure CleanupNotifications(var ICIncomingNotification: Record "IC Incoming Notification")
    var
        ICPartner: Record "IC Partner";
        TempICOutgoingNotification: Record "IC Outgoing Notification" temporary;
        ICDataExchangeAPI: Codeunit "IC Data Exchange API";
        CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
        ContentJsonText: Text;
    begin
        ICPartner.Get(ICIncomingNotification."Source IC Partner Code");
        TempICOutgoingNotification."Operation ID" := ICIncomingNotification."Operation ID";
        TempICOutgoingNotification."Source IC Partner Code" := ICIncomingNotification."Source IC Partner Code";
        TempICOutgoingNotification."Target IC Partner Code" := ICIncomingNotification."Target IC Partner Code";
        ICDataExchangeAPI.CreateJsonContentFromICOutgoingNotification(TempICOutgoingNotification, ContentJsonText);
        if CrossIntercompanyConnector.NotifyICPartnerFromBoundAction(ICPartner, ICIncomingNotification."Operation ID", SyncronizationCompletedTok) then
            ICIncomingNotification.Delete()
        else begin
            ICIncomingNotification.Status := ICIncomingNotification.Status::"Scheduled for deletion failed";
            ICIncomingNotification.SetErrorMessage(GetLastErrorText());
            ICIncomingNotification.Modify();
            ClearLastError();
        end;
    end;

    local procedure GetICInboxTransaction(JsonResponse: JsonObject; ICIncomingNotification: Record "IC Incoming Notification"; var ICInboxTransaction: Record "IC Inbox Transaction")
    var
        TempICInboxTransaction: Record "IC Inbox Transaction" temporary;
        ICDataExchangeAPI: Codeunit "IC Data Exchange API";
        AttributeToken: JsonToken;
        SelectedToken: JsonToken;
    begin
        JsonResponse.Get('id', AttributeToken);
        if AttributeToken.AsValue().AsText() = ICIncomingNotification."Operation ID" then begin
            JsonResponse.Get('bufferIntercompanyInboxTransactions', AttributeToken);
            foreach SelectedToken in AttributeToken.AsArray() do begin
                ICDataExchangeAPI.PopulateICInboxTransactionFromJson(SelectedToken, TempICInboxTransaction);
                TempICInboxTransaction.FindFirst();
                ICInboxTransaction.Get(TempICInboxTransaction."Transaction No.", TempICInboxTransaction."IC Partner Code", TempICInboxTransaction."Transaction Source", TempICInboxTransaction."Document Type");
                exit;
            end;
        end;
    end;
}

