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

    [EventSubscriber(ObjectType::Report, Report::"Move IC Trans. to Partner Comp", 'OnICInboxTransactionCreated', '', false, false)]
    local procedure AcceptOnAfterInsertICInboxTransaction(var Sender: Report "Move IC Trans. to Partner Comp"; var ICInboxTransaction: Record "IC Inbox Transaction"; PartnerCompanyName: Text)
    var
        CompanyInformation: Record "Company Information";
        ICPartner: Record "IC Partner";
    begin
        CompanyInformation.Get();
        ICPartner.ChangeCompany(PartnerCompanyName);

        if not ICPartner.Get(CompanyInformation."IC Partner Code") then
            exit;

        if ICPartner."Auto. Accept Transactions" then
            TASKSCHEDULER.CreateTask(CODEUNIT::"IC Inbox Outbox Subscribers", 0,
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

