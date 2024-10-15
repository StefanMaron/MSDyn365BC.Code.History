// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany.Partner;

codeunit 533 "IC New Notification JR"
{
    trigger OnRun()
    var
        ICOutgoingNotification: Record "IC Outgoing Notification";
    begin
        ICOutgoingNotification.SetFilter(Status, '=%1|=%2', ICOutgoingNotification.Status::Created, ICOutgoingNotification.Status::Failed);
        if not ICOutgoingNotification.FindSet() then
            exit;

        repeat
            SendNotification(ICOutgoingNotification);
        until ICOutgoingNotification.Next() = 0;
    end;

    local procedure SendNotification(var ICOutgoingNotification: Record "IC Outgoing Notification")
    var
        ICPartner: Record "IC Partner";
        TempICIncomingNotification: Record "IC Incoming Notification" temporary;
        ICDataExchangeAPI: Codeunit "IC Data Exchange API";
        CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
        ContentJsonText: Text;
    begin
        ICPartner.Get(ICOutgoingNotification."Target IC Partner Code");
        TempICIncomingNotification."Operation ID" := ICOutgoingNotification."Operation ID";
        TempICIncomingNotification."Source IC Partner Code" := ICOutgoingNotification."Source IC Partner Code";
        TempICIncomingNotification."Target IC Partner Code" := ICOutgoingNotification."Target IC Partner Code";
        TempICIncomingNotification."Notified DateTime" := ICOutgoingNotification."Notified DateTime";
        ICDataExchangeAPI.CreateJsonContentFromICIncomingNotification(TempICIncomingNotification, ContentJsonText);
        if CrossIntercompanyConnector.SubmitRecordsToICPartnerFromEntityName(ICPartner, ContentJsonText, 'intercompanyIncomingNotification', 'id', TempICIncomingNotification."Operation ID") then begin
            ICOutgoingNotification.Status := ICOutgoingNotification.Status::Notified;
            ICOutgoingNotification."Notified DateTime" := CurrentDateTime();
            ICOutgoingNotification.Modify();
        end
        else begin
            ICOutgoingNotification.Status := ICOutgoingNotification.Status::Failed;
            ICOutgoingNotification.SetErrorMessage(GetLastErrorText());
            ICOutgoingNotification.Modify();
            ClearLastError();
        end;
    end;
}

