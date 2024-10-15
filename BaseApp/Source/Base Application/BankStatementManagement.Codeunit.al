codeunit 11705 "Bank Statement Management"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure BankStatementSelection(var BankStmtHdr: Record "Bank Statement Header"; var StatSelected: Boolean)
    var
        BankAcc: Record "Bank Account";
        GLSetup: Record "General Ledger Setup";
        UserSetupLine: Record "User Setup Line";
        UserSetupAdvMgt: Codeunit "User Setup Adv. Management";
    begin
        StatSelected := true;

        BankAcc.Reset;

        case BankAcc.Count of
            0:
                BankAcc.FindFirst;
            1:
                BankAcc.FindFirst;
            else
                StatSelected := PAGE.RunModal(PAGE::"Bank List", BankAcc) = ACTION::LookupOK;
        end;

        if StatSelected then begin
            GLSetup.Get;
            if GLSetup."User Checks Allowed" then
                UserSetupAdvMgt.CheckBankAccountNo(UserSetupLine.Type::"Bank Stmt", BankAcc."No.");
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
        UserSetupLine: Record "User Setup Line";
        UserSetupAdvMgt: Codeunit "User Setup Adv. Management";
    begin
        StatSelected := true;

        BankAcc.Reset;

        case BankAcc.Count of
            0:
                BankAcc.FindFirst;
            1:
                BankAcc.FindFirst;
            else
                StatSelected := PAGE.RunModal(PAGE::"Bank List", BankAcc) = ACTION::LookupOK;
        end;

        if StatSelected then begin
            GLSetup.Get;
            if GLSetup."User Checks Allowed" then
                UserSetupAdvMgt.CheckBankAccountNo(UserSetupLine.Type::"Bank Stmt", BankAcc."No.");
            IssuedBankStmtHdr.FilterGroup := 2;
            IssuedBankStmtHdr.SetRange("Bank Account No.", BankAcc."No.");
            IssuedBankStmtHdr.FilterGroup := 0;
        end;
    end;
}

