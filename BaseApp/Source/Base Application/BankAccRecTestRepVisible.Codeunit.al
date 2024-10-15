codeunit 385 "Bank Acc.Rec.Test Rep. Visible"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Report, Report::"Bank Acc. Recon. - Test", 'OnBeforeInitReport', '', false, false)]
    local procedure OnBeforePrintDocument(var ShouldShowOutstandingBankTransactions: Boolean)
    begin
        ShouldShowOutstandingBankTransactions := true;
    end;

}