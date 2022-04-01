codeunit 790 "IC Inbox Outbox Subscribers"
{
    TableNo = "IC Inbox Transaction";

    trigger OnRun()
    begin
        SetRecFilter;
        "Line Action" := "Line Action"::Accept;
        Modify;
        REPORT.Run(REPORT::"Complete IC Inbox Action", false, false, Rec);
        Reset;
    end;

    var
        ICOutboxExport: Codeunit "IC Outbox Export";

    local procedure IsICInboxTransactionReturnedByPartner(TransactionSource: Option): Boolean
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
    begin
        exit(TransactionSource = ICInboxTransaction."Transaction Source"::"Returned by Partner");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Move IC Trans. to Partner Comp", 'OnICInboxTransactionCreated', '', false, false)]
    local procedure AcceptOnAfterInsertICInboxTransaction(var Sender: Report "Move IC Trans. to Partner Comp"; var ICInboxTransaction: Record "IC Inbox Transaction"; PartnerCompanyName: Text)
    var
        ICSetup: Record "IC Setup";
        ICPartner: Record "IC Partner";
    begin
        ICSetup.Get();
        ICPartner.ChangeCompany(PartnerCompanyName);

        if not ICPartner.Get(ICSetup."IC Partner Code") then
            exit;

        if ICPartner."Auto. Accept Transactions" then
            if not IsICInboxTransactionReturnedByPartner(ICInboxTransaction."Transaction Source") then
                TaskScheduler.CreateTask(Codeunit::"IC Inbox Outbox Subscribers", 0,
                    true, PartnerCompanyName, 0DT, ICInboxTransaction.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ICInboxOutboxMgt", 'OnInsertICOutboxPurchDocTransaction', '', false, false)]
    local procedure AutoSendOnInsertICOutboxPurchDocTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICOutboxTransaction."Transaction No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ICInboxOutboxMgt", 'OnInsertICOutboxSalesDocTransaction', '', false, false)]
    local procedure AutoSendOnInsertICOutboxSalesDocTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICOutboxTransaction."Transaction No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ICInboxOutboxMgt", 'OnInsertICOutboxSalesInvTransaction', '', false, false)]
    local procedure AutoSendOnInsertICOutboxSalesInvTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICOutboxTransaction."Transaction No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ICInboxOutboxMgt", 'OnInsertICOutboxSalesCrMemoTransaction', '', false, false)]
    local procedure AutoSendOnInsertICOutboxSalesCrMemoTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICOutboxTransaction."Transaction No.");
    end;
}

