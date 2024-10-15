codeunit 18931 "Gen. Jnl. Post Line Subscriber"
{
    var
        GLSetup: Record "General Ledger Setup";
        DocNoMustBeEnteredErr: Label 'Document No. must be entered when Bank Payment Type is %1.', Comment = '%1 = GenJournalLine."Bank Payment Type"';
        CheckAlreadyExistsErr: Label 'Check %1 already exists for this Bank Account.', Comment = '%1= GenJournalLine."Cheque No."';

    procedure UpdtCheckLedgEnrtyComputerCheck(
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    var
        CheckLedgEntry: Record "Check Ledger Entry";
        CheckLedgEntry2: Record "Check Ledger Entry";
        DocumentNo: Code[20];
    begin
        GLSetup.Get();
        GenJournalLine.TestField("Check Printed", true);
        CheckLedgEntry.LockTable();
        CheckLedgEntry.Reset();
        CheckLedgEntry.SetCurrentKey("Bank Account No.", "Entry Status", "Check No.");
        CheckLedgEntry.SetRange("Bank Account No.", GenJournalLine."Account No.");
        CheckLedgEntry.SetRange("Entry Status", CheckLedgEntry."Entry Status"::Printed);
        if not GLSetup."Activate Cheque No." then
            CheckLedgEntry.SetRange("Check No.", GenJournalLine."Document No.")
        else
            CheckLedgEntry.SetRange("Check No.", GenJournalLine."Cheque No.");
        if CheckLedgEntry.FindSet() then
            repeat
                CheckLedgEntry2 := CheckLedgEntry;
                CheckLedgEntry2."Entry Status" := CheckLedgEntry2."Entry Status"::Posted;
                CheckLedgEntry2."Bank Account Ledger Entry No." := BankAccountLedgerEntry."Entry No.";
                if GLSetup."Activate Cheque No." then
                    CheckLedgEntry2."Document No." := BankAccountLedgerEntry."Document No.";
                CheckLedgEntry2.Modify();
            until CheckLedgEntry.Next() = 0;
        if GLSetup."Activate Cheque No." then begin
            CheckLedgEntry.LockTable();
            CheckLedgEntry.Reset();
            CheckLedgEntry.SetCurrentKey("Bank Account No.", "Entry Status", "Check No.");
            CheckLedgEntry.SetRange("Bank Account No.", GenJournalLine."Account No.");
            CheckLedgEntry.SetFilter("Entry Status", '%1|%2|%3', CheckLedgEntry."Entry Status"::Voided,
              CheckLedgEntry."Entry Status"::"Financially Voided", CheckLedgEntry."Entry Status"::"Test Print");
            CheckLedgEntry.SetRange("Document No.", DocumentNo);
            if CheckLedgEntry.Find('-') then
                repeat
                    CheckLedgEntry2 := CheckLedgEntry;
                    CheckLedgEntry2."Document No." := BankAccountLedgerEntry."Document No.";
                    CheckLedgEntry2.Modify();
                until CheckLedgEntry.Next() = 0;
        end;
    end;

    procedure InitCheckLedgEntry(
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        var CheckLedgEntry: Record "Check Ledger Entry")
    var
        NextCheckEntryNo: Integer;
    begin
        CheckLedgEntry.Init();
        CheckLedgEntry.CopyFromBankAccLedgEntry(BankAccLedgEntry);
        CheckLedgEntry."Entry No." := NextCheckEntryNo;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostBankAccOnBeforeBankAccLedgEntryInsert', '', false, false)]
    local procedure UpdateChequeDetails(
        BankAccount: Record "Bank Account";
        var BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        var GenJournalLine: Record "Gen. Journal Line")
    begin
        GLSetup.Get();
        if GLSetup."Activate Cheque No." then begin
            BankAccountLedgerEntry."Cheque No." := GenJournalLine."Cheque No.";
            BankAccountLedgerEntry."Cheque Date" := GenJournalLine."Cheque Date";
        end;
        if (not GLSetup."Activate Cheque No.") and (GenJournalLine."Bank Payment Type" in ["Bank Payment Type"::"Manual Check",
                                                                            "Bank Payment Type"::" ",
                                                                            "Bank Payment Type"::"Computer Check"])
        then begin
            BankAccountLedgerEntry."Cheque No." := CopyStr((GenJournalLine."Document No."), 1, 10);
            BankAccountLedgerEntry."Cheque Date" := GenJournalLine."Posting Date";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostBankAccOnAfterBankAccLedgEntryInsert', '', false, false)]
    local procedure UpdateCheckLedgerEntry(
        BankAccount: Record "Bank Account";
        var BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        var GenJournalLine: Record "Gen. Journal Line")
    begin
        if ((GenJournalLine.Amount <= 0) and (GenJournalLine."Bank Payment Type" = GenJournalLine."Bank Payment Type"::"Computer Check") and GenJournalLine."Check Printed") or
               ((GenJournalLine.Amount < 0) and (GenJournalLine."Bank Payment Type" = GenJournalLine."Bank Payment Type"::"Manual Check"))
            then
            case GenJournalLine."Bank Payment Type" of
                GenJournalLine."Bank Payment Type"::"Computer Check":
                    UpdtCheckLedgEnrtyComputerCheck(GenJournalLine, BankAccountLedgerEntry);
            end;
    end;

    local procedure UpdtCheckLedgEnrtyManualCheck(
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccount: Record "Bank Account")
    var
        CheckLedgEntry: Record "Check Ledger Entry";
        NextCheckEntryNo: Integer;
    begin
        GLSetup.Get();
        if GenJournalLine."Document No." = '' then
            Error(DocNoMustBeEnteredErr, GenJournalLine."Bank Payment Type");
        CheckLedgEntry.Reset();
        if NextCheckEntryNo = 0 then begin
            CheckLedgEntry.LockTable();
            if CheckLedgEntry.FindLast() then
                NextCheckEntryNo := CheckLedgEntry."Entry No." + 1
            else
                NextCheckEntryNo := 1;
        end;
        CheckLedgEntry.SetRange("Bank Account No.", GenJournalLine."Account No.");
        CheckLedgEntry.SetFilter(
          "Entry Status", '%1|%2|%3', CheckLedgEntry."Entry Status"::Printed, CheckLedgEntry."Entry Status"::Posted,
          CheckLedgEntry."Entry Status"::"Financially Voided");
        if not GLSetup."Activate Cheque No." then begin
            CheckLedgEntry.SetRange("Check No.", GenJournalLine."Document No.");
            if CheckLedgEntry.FindFirst() then
                Error(CheckAlreadyExistsErr, GenJournalLine."Document No.");
        end else begin
            CheckLedgEntry.SetRange("Check No.", GenJournalLine."Cheque No.");
            if CheckLedgEntry.Find('-') then
                Error(CheckAlreadyExistsErr, GenJournalLine."Cheque No.");
        end;
        InitCheckLedgEntry(BankAccountLedgerEntry, CheckLedgEntry);
        CheckLedgEntry."Bank Payment Type" := CheckLedgEntry."Bank Payment Type"::"Manual Check";
        CheckLedgEntry."Check Date" := BankAccountLedgerEntry."Posting Date";
        if not GLSetup."Activate Cheque No." then
            CheckLedgEntry."Check No." := BankAccountLedgerEntry."Document No."
        else begin
            CheckLedgEntry."Check No." := BankAccountLedgerEntry."Cheque No.";
            CheckLedgEntry."Check Date" := BankAccountLedgerEntry."Cheque Date";
        end;
        if BankAccount."Currency Code" <> '' then
            CheckLedgEntry.Amount := -BankAccountLedgerEntry.Amount
        else
            CheckLedgEntry.Amount := -BankAccountLedgerEntry."Amount (LCY)";
        CheckLedgEntry.Insert(true);
        NextCheckEntryNo := NextCheckEntryNo + 1;
    end;
}