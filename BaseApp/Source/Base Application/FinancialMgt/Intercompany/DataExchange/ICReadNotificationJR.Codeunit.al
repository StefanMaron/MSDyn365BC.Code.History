// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany.Partner;

codeunit 534 "IC Read Notification JR"
{
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
        ICDataExchangeAPI: Codeunit "IC Data Exchange API";
        CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
        JsonResponse: JsonObject;
        Success: Boolean;
    begin
        ICPartner.Get(ICIncomingNotification."Source IC Partner Code");
        if not CrossIntercompanyConnector.RequestICPartnerICOutgoingNotification(ICPartner, ICIncomingNotification."Operation ID", JsonResponse) then begin
            LogError(ICIncomingNotification);
            exit;
        end;

        ICDataExchangeAPI.OnPopulateTransactionDataFromICOutgoingNotification(JsonResponse, Success);
        if not Success then begin
            LogError(ICIncomingNotification);
            exit;
        end;

        Commit();
        ICIncomingNotification.Status := ICIncomingNotification.Status::Processed;
        ICIncomingNotification."Notified DateTime" := CurrentDateTime();
        ICIncomingNotification.Modify();
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
}

