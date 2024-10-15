// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

codeunit 535 "IC Sync. Completed JR"
{
    trigger OnRun()
    var
        ICOutgoingNotification: Record "IC Outgoing Notification";
    begin
        ICOutgoingNotification.SetFilter(Status, '=%1|=%2', ICOutgoingNotification.Status::"Scheduled for deletion", ICOutgoingNotification.Status::"Scheduled for deletion failed");
        if not ICOutgoingNotification.FindSet() then
            exit;

        repeat
            CleanSyncronizedData(ICOutgoingNotification);
        until ICOutgoingNotification.Next() = 0;
    end;

    local procedure CleanSyncronizedData(var ICOutgoingNotification: Record "IC Outgoing Notification")
    var
        Success: Boolean;
    begin
        OnCleanupTransactionData(ICOutgoingNotification, Success);
        if not Success then begin
            ICOutgoingNotification.Status := ICOutgoingNotification.Status::"Scheduled for deletion failed";
            ICOutgoingNotification.SetErrorMessage(GetLastErrorText());
            ICOutgoingNotification.Modify();
            ClearLastError();
            exit;
        end;
        Commit();
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    internal procedure CleanupBufferRecords(ICOutgoingNotification: Record "IC Outgoing Notification")
    var
        BufferICInboxTransaction: Record "Buffer IC Inbox Transaction";
        BufferICInboxJnlLine: Record "Buffer IC Inbox Jnl. Line";
        BufferICInboxPurchHeader: Record "Buffer IC Inbox Purch Header";
        BufferICInboxPurchaseLine: Record "Buffer IC Inbox Purchase Line";
        BufferICInboxSalesHeader: Record "Buffer IC Inbox Sales Header";
        BufferICInboxSalesLine: Record "Buffer IC Inbox Sales Line";
        BufferICInOutJnlLineDim: Record "Buffer IC InOut Jnl. Line Dim.";
        BufferICDocumentDimension: Record "Buffer IC Document Dimension";
        BufferICCommentLine: Record "Buffer IC Comment Line";
    begin
        BufferICInboxTransaction.SetRange("Operation ID", ICOutgoingNotification."Operation ID");
        if not BufferICInboxTransaction.IsEmpty() then
            BufferICInboxTransaction.DeleteAll();

        BufferICInboxJnlLine.SetRange("Operation ID", ICOutgoingNotification."Operation ID");
        if not BufferICInboxJnlLine.IsEmpty() then
            BufferICInboxJnlLine.DeleteAll();

        BufferICInboxPurchHeader.SetRange("Operation ID", ICOutgoingNotification."Operation ID");
        if not BufferICInboxPurchHeader.IsEmpty() then
            BufferICInboxPurchHeader.DeleteAll();

        BufferICInboxPurchaseLine.SetRange("Operation ID", ICOutgoingNotification."Operation ID");
        if not BufferICInboxPurchaseLine.IsEmpty() then
            BufferICInboxPurchaseLine.DeleteAll();

        BufferICInboxSalesHeader.SetRange("Operation ID", ICOutgoingNotification."Operation ID");
        if not BufferICInboxSalesHeader.IsEmpty() then
            BufferICInboxSalesHeader.DeleteAll();

        BufferICInboxSalesLine.SetRange("Operation ID", ICOutgoingNotification."Operation ID");
        if not BufferICInboxSalesLine.IsEmpty() then
            BufferICInboxSalesLine.DeleteAll();

        BufferICInOutJnlLineDim.SetRange("Operation ID", ICOutgoingNotification."Operation ID");
        if not BufferICInOutJnlLineDim.IsEmpty() then
            BufferICInOutJnlLineDim.DeleteAll();

        BufferICDocumentDimension.SetRange("Operation ID", ICOutgoingNotification."Operation ID");
        if not BufferICDocumentDimension.IsEmpty() then
            BufferICDocumentDimension.DeleteAll();

        BufferICCommentLine.SetRange("Operation ID", ICOutgoingNotification."Operation ID");
        if not BufferICCommentLine.IsEmpty() then
            BufferICCommentLine.DeleteAll();
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    internal procedure CleanupICOutgoingNotification(var ICOutgoingNotification: Record "IC Outgoing Notification")
    begin
        if not ICOutgoingNotification.IsEmpty() then
            ICOutgoingNotification.Delete();
    end;

    [InternalEvent(false, true)]
    internal procedure OnCleanupTransactionData(ICOutgoingNotification: Record "IC Outgoing Notification"; var Success: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"IC Sync. Completed JR", 'OnCleanupTransactionData', '', false, false)]
    local procedure HandledOnCleanupTransactionData(ICOutgoingNotification: Record "IC Outgoing Notification"; var Success: Boolean)
    begin
        CleanupBufferRecords(ICOutgoingNotification);
        CleanupICOutgoingNotification(ICOutgoingNotification);
        Success := true;
    end;
}
