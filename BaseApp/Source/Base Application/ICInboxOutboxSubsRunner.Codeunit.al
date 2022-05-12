codeunit 791 "IC Inbox Outbox Subs. Runner"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
    begin
        ICInboxTransaction.Get("Record ID to Process");
        Codeunit.Run(Codeunit::"IC Inbox Outbox Subscribers", ICInboxTransaction)
    end;
}