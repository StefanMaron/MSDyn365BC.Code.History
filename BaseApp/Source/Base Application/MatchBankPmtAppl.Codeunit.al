codeunit 1254 "Match Bank Pmt. Appl."
{
    TableNo = "Bank Acc. Reconciliation";

    trigger OnRun()
    var
        MatchBankPayments: Codeunit "Match Bank Payments";
    begin
        BankAccReconciliationLine.FilterBankRecLines(Rec);
        if BankAccReconciliationLine.FindFirst then begin
            MatchBankPayments.SetApplyEntries(true);
            MatchBankPayments.Run(BankAccReconciliationLine);
        end;
        OnAfterMatchBankPayments(Rec);
    end;

    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";

    [IntegrationEvent(false, false)]
    local procedure OnAfterMatchBankPayments(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;

    [EventSubscriber(ObjectType::Table, 8631, 'OnDoesTableHaveCustomRuleInRapidStart', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckBankAccRecOnDoesTableHaveCustomRuleInRapidStart(TableID: Integer; var Result: Boolean)
    begin
        if TableID = DATABASE::"Bank Acc. Reconciliation" then
            Result := true;
    end;
}

