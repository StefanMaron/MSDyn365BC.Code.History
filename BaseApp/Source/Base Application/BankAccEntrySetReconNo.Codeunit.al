codeunit 375 "Bank Acc. Entry Set Recon.-No."
{
    Permissions = TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        CheckLedgEntry: Record "Check Ledger Entry";

    procedure ApplyEntries(var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var BankAccLedgEntry: Record "Bank Account Ledger Entry"; Relation: Option "One-to-One","One-to-Many"): Boolean
    begin
        OnBeforeApplyEntries(BankAccReconLine, BankAccLedgEntry, Relation);

        BankAccLedgEntry.LockTable();
        CheckLedgEntry.LockTable();
        BankAccReconLine.LockTable();
        BankAccReconLine.Find;

        if BankAccLedgEntry.IsApplied then
            exit(false);

        if (Relation = Relation::"One-to-One") and (BankAccReconLine."Applied Entries" > 0) then
            exit(false);

        BankAccReconLine.TestField(Type, BankAccReconLine.Type::"Bank Account Ledger Entry");
        BankAccReconLine."Ready for Application" := true;
        SetReconNo(BankAccLedgEntry, BankAccReconLine);
        BankAccReconLine."Applied Amount" += BankAccLedgEntry."Remaining Amount";
        BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" + 1;
        BankAccReconLine.Validate("Statement Amount");
        ModifyBankAccReconLine(BankAccReconLine);
        exit(true);
    end;

    procedure RemoveApplication(var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        OnBeforeRemoveApplication(BankAccLedgEntry);

        BankAccLedgEntry.LockTable();
        CheckLedgEntry.LockTable();
        BankAccReconLine.LockTable();

        if not BankAccReconLine.Get(
             BankAccReconLine."Statement Type"::"Bank Reconciliation",
             BankAccLedgEntry."Bank Account No.",
             BankAccLedgEntry."Statement No.", BankAccLedgEntry."Statement Line No.")
        then
            exit;

        BankAccReconLine.TestField("Statement Type", BankAccReconLine."Statement Type"::"Bank Reconciliation");
        BankAccReconLine.TestField(Type, BankAccReconLine.Type::"Bank Account Ledger Entry");
        RemoveReconNo(BankAccLedgEntry, BankAccReconLine, true);

        BankAccReconLine."Applied Amount" -= BankAccLedgEntry."Remaining Amount";
        BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" - 1;
        BankAccReconLine.Validate("Statement Amount");
        ModifyBankAccReconLine(BankAccReconLine);
    end;

    local procedure ModifyBankAccReconLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        OnBeforeModifyBankAccReconLine(BankAccReconciliationLine);
        BankAccReconciliationLine.Modify();
    end;

    procedure SetReconNo(var BankAccLedgEntry: Record "Bank Account Ledger Entry"; var BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    begin
        BankAccLedgEntry.TestField(Open, true);
        BankAccLedgEntry.TestField("Statement Status", BankAccLedgEntry."Statement Status"::Open);
        BankAccLedgEntry.TestField("Statement No.", '');
        BankAccLedgEntry.TestField("Statement Line No.", 0);
        BankAccLedgEntry.TestField("Bank Account No.", BankAccReconLine."Bank Account No.");
        BankAccLedgEntry."Statement Status" :=
          BankAccLedgEntry."Statement Status"::"Bank Acc. Entry Applied";
        BankAccLedgEntry."Statement No." := BankAccReconLine."Statement No.";
        BankAccLedgEntry."Statement Line No." := BankAccReconLine."Statement Line No.";
        BankAccLedgEntry.Modify();

        CheckLedgEntry.Reset();
        CheckLedgEntry.SetCurrentKey("Bank Account Ledger Entry No.");
        CheckLedgEntry.SetRange("Bank Account Ledger Entry No.", BankAccLedgEntry."Entry No.");
        CheckLedgEntry.SetRange(Open, true);
        if CheckLedgEntry.Find('-') then
            repeat
                CheckLedgEntry.TestField("Statement Status", CheckLedgEntry."Statement Status"::Open);
                CheckLedgEntry.TestField("Statement No.", '');
                CheckLedgEntry.TestField("Statement Line No.", 0);
                CheckLedgEntry."Statement Status" :=
                  CheckLedgEntry."Statement Status"::"Bank Acc. Entry Applied";
                CheckLedgEntry."Statement No." := '';
                CheckLedgEntry."Statement Line No." := 0;
                CheckLedgEntry.Modify();
            until CheckLedgEntry.Next = 0;
    end;

    procedure RemoveReconNo(var BankAccLedgEntry: Record "Bank Account Ledger Entry"; var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; Test: Boolean)
    begin
        BankAccLedgEntry.TestField(Open, true);
        if Test then begin
            BankAccLedgEntry.TestField(
              "Statement Status", BankAccLedgEntry."Statement Status"::"Bank Acc. Entry Applied");
            BankAccLedgEntry.TestField("Statement No.", BankAccReconLine."Statement No.");
            BankAccLedgEntry.TestField("Statement Line No.", BankAccReconLine."Statement Line No.");
        end;
        BankAccLedgEntry.TestField("Bank Account No.", BankAccReconLine."Bank Account No.");
        BankAccLedgEntry."Statement Status" := BankAccLedgEntry."Statement Status"::Open;
        BankAccLedgEntry."Statement No." := '';
        BankAccLedgEntry."Statement Line No." := 0;
        BankAccLedgEntry.Modify();

        CheckLedgEntry.Reset();
        CheckLedgEntry.SetCurrentKey("Bank Account Ledger Entry No.");
        CheckLedgEntry.SetRange("Bank Account Ledger Entry No.", BankAccLedgEntry."Entry No.");
        CheckLedgEntry.SetRange(Open, true);
        if CheckLedgEntry.Find('-') then
            repeat
                if Test then begin
                    CheckLedgEntry.TestField(
                      "Statement Status", CheckLedgEntry."Statement Status"::"Bank Acc. Entry Applied");
                    CheckLedgEntry.TestField("Statement No.", '');
                    CheckLedgEntry.TestField("Statement Line No.", 0);
                end;
                CheckLedgEntry."Statement Status" := CheckLedgEntry."Statement Status"::Open;
                CheckLedgEntry."Statement No." := '';
                CheckLedgEntry."Statement Line No." := 0;
                CheckLedgEntry.Modify();
            until CheckLedgEntry.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyEntries(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var Relation: Option "One-to-One","One-to-Many")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyBankAccReconLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRemoveApplication(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;
}

