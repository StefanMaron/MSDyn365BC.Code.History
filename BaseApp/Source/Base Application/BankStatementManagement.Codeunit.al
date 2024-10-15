#if not CLEAN19
codeunit 11705 "Bank Statement Management"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure BankStatementSelection(var BankStmtHdr: Record "Bank Statement Header"; var StatSelected: Boolean)
    var
        BankAcc: Record "Bank Account";
        GLSetup: Record "General Ledger Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBankStatementSelection(BankStmtHdr, StatSelected, IsHandled);
        if IsHandled then
            exit;

        StatSelected := true;

        BankAcc.Reset();

        case BankAcc.Count of
            0:
                BankAcc.FindFirst();
            1:
                BankAcc.FindFirst();
            else
                StatSelected := PAGE.RunModal(PAGE::"Bank List", BankAcc) = ACTION::LookupOK;
        end;

        if StatSelected then begin
            GLSetup.Get();
            BankStmtHdr.FilterGroup := 2;
            BankStmtHdr.SetRange("Bank Account No.", BankAcc."No.");
            BankStmtHdr.FilterGroup := 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure IssuedBankStatementSelection(var IssuedBankStmtHdr: Record "Issued Bank Statement Header"; var StatSelected: Boolean)
    var
        BankAcc: Record "Bank Account";
        GLSetup: Record "General Ledger Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIssuedBankStatementSelection(IssuedBankStmtHdr, StatSelected, IsHandled);
        if IsHandled then
            exit;

        StatSelected := true;

        BankAcc.Reset();

        case BankAcc.Count of
            0:
                BankAcc.FindFirst();
            1:
                BankAcc.FindFirst();
            else
                StatSelected := PAGE.RunModal(PAGE::"Bank List", BankAcc) = ACTION::LookupOK;
        end;

        if StatSelected then begin
            GLSetup.Get();
            IssuedBankStmtHdr.FilterGroup := 2;
            IssuedBankStmtHdr.SetRange("Bank Account No.", BankAcc."No.");
            IssuedBankStmtHdr.FilterGroup := 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBankStatementSelection(var BankStmtHdr: Record "Bank Statement Header"; var StatSelected: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedBankStatementSelection(var IssuedBankStmtHdr: Record "Issued Bank Statement Header"; var StatSelected: Boolean; var IsHandled: Boolean)
    begin
    end;
}
#endif
