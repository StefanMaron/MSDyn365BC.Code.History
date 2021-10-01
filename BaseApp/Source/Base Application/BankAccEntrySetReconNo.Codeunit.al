codeunit 375 "Bank Acc. Entry Set Recon.-No."
{
    Permissions = TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        CheckLedgEntry: Record "Check Ledger Entry";

    procedure ApplyEntries(var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var BankAccLedgEntry: Record "Bank Account Ledger Entry"; Relation: Option "One-to-One","One-to-Many","Many-to-One"): Boolean
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        NextMatchID: Integer;
    begin
        OnBeforeApplyEntries(BankAccReconLine, BankAccLedgEntry, Relation);

        BankAccLedgEntry.LockTable();
        CheckLedgEntry.LockTable();
        BankAccReconLine.LockTable();
        BankAccReconLine.Find;

        case Relation of
            Relation::"One-to-One":
                begin
                    if BankAccReconLine."Applied Entries" > 0 then
                        exit(false);
                    if BankAccLedgEntry.IsApplied() then
                        exit(false);

                    BankAccReconLine.TestField(Type, BankAccReconLine.Type::"Bank Account Ledger Entry");
                    BankAccReconLine."Ready for Application" := true;
                    SetReconNo(BankAccLedgEntry, BankAccReconLine);
                    BankAccReconLine."Applied Amount" += BankAccLedgEntry."Remaining Amount";
                    BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" + 1;
                    BankAccReconLine.Validate("Statement Amount");
                    ModifyBankAccReconLine(BankAccReconLine);
                end;
            Relation::"One-to-Many":
                begin
                    if BankAccLedgEntry.IsApplied() then
                        exit(false);

                    BankAccReconLine.TestField(Type, BankAccReconLine.Type::"Bank Account Ledger Entry");
                    BankAccReconLine."Ready for Application" := true;
                    SetReconNo(BankAccLedgEntry, BankAccReconLine);
                    BankAccReconLine."Applied Amount" += BankAccLedgEntry."Remaining Amount";
                    BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" + 1;
                    BankAccReconLine.Validate("Statement Amount");
                    ModifyBankAccReconLine(BankAccReconLine);
                end;
            Relation::"Many-to-One":
                begin
                    if (BankAccReconLine."Applied Entries" > 0) then
                        exit(false); //Many-to-many is not supported

                    NextMatchID := GetNextMatchID(BankAccReconLine, BankAccLedgEntry);
                    BankAccRecMatchBuffer.Init();
                    BankAccRecMatchBuffer."Ledger Entry No." := BankAccLedgEntry."Entry No.";
                    BankAccRecMatchBuffer."Statement No." := BankAccReconLine."Statement No.";
                    BankAccRecMatchBuffer."Statement Line No." := BankAccReconLine."Statement Line No.";
                    BankAccRecMatchBuffer."Bank Account No." := BankAccReconLine."Bank Account No.";
                    BankAccRecMatchBuffer."Match ID" := NextMatchID;
                    BankAccRecMatchBuffer.Insert();

                    BankAccReconLine.TestField(Type, BankAccReconLine.Type::"Bank Account Ledger Entry");
                    BankAccReconLine."Ready for Application" := true;
                    if BankAccLedgEntry."Statement Line No." <> -1 then begin
                        SetReconNo(BankAccLedgEntry, BankAccReconLine);
                        BankAccLedgEntry."Statement Line No." := -1;
                        BankAccLedgEntry.Modify();
                    end;

                    BankAccReconLine."Applied Amount" += BankAccLedgEntry."Remaining Amount";
                    if System.Abs(BankAccReconLine."Statement Amount") < System.Abs(BankAccLedgEntry."Remaining Amount") then
                        BankAccReconLine."Applied Amount" := BankAccReconLine."Statement Amount";

                    BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" + 1;
                    BankAccReconLine.Validate("Statement Amount");
                    ModifyBankAccReconLine(BankAccReconLine);
                end;
        end;

        exit(true);
    end;

    local procedure GetNextMatchID(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; BankAccLedgEntry: Record "Bank Account Ledger Entry"): Integer
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
    begin
        BankAccRecMatchBuffer.SetRange("Statement No.", BankAccReconLine."Statement No.");
        BankAccRecMatchBuffer.SetRange("Bank Account No.", BankAccReconLine."Bank Account No.");
        BankAccRecMatchBuffer.SetRange("Ledger Entry No.", BankAccLedgEntry."Entry No.");
        if BankAccRecMatchBuffer.FindLast() then
            exit(BankAccRecMatchBuffer."Match ID");

        BankAccRecMatchBuffer.Reset();
        BankAccRecMatchBuffer.SetRange("Statement No.", BankAccReconLine."Statement No.");
        BankAccRecMatchBuffer.SetRange("Bank Account No.", BankAccReconLine."Bank Account No.");
        if BankAccRecMatchBuffer.FindLast() then
            exit(BankAccRecMatchBuffer."Match ID" + 1)
        else
            exit(1);
    end;

    local procedure RemoveManyToOneMatch(var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccRecMatchBuffer.SetRange("Ledger Entry No.", BankAccLedgEntry."Entry No.");
        if BankAccRecMatchBuffer.FindSet() then
            repeat
                BankAccReconLine.SetRange("Statement Line No.", BankAccRecMatchBuffer."Statement Line No.");
                BankAccReconLine.SetRange("Statement No.", BankAccRecMatchBuffer."Statement No.");
                BankAccReconLine.SetRange("Bank Account No.", BankAccRecMatchBuffer."Bank Account No.");
                if BankAccReconLine.FindFirst() then
                    RemoveReconNo(BankAccLedgEntry, BankAccReconLine, false);

                BankAccReconLine."Applied Amount" := 0;
                BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" - 1;
                BankAccReconLine.Validate("Statement Amount");
                ModifyBankAccReconLine(BankAccReconLine);
                DeletePaymentMatchDetails(BankAccReconLine);

            until BankAccRecMatchBuffer.Next() = 0;

        BankAccRecMatchBuffer.DeleteAll();
    end;

    procedure RemoveApplication(var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        OnBeforeRemoveApplication(BankAccLedgEntry);

        RemoveManyToOneMatch(BankAccLedgEntry);

        BankAccLedgEntry.LockTable();
        CheckLedgEntry.LockTable();
        BankAccReconLine.LockTable();

        if BankAccReconLine.Get(
             BankAccReconLine."Statement Type"::"Bank Reconciliation",
             BankAccLedgEntry."Bank Account No.",
             BankAccLedgEntry."Statement No.", BankAccLedgEntry."Statement Line No.")
        then begin
            BankAccReconLine.TestField("Statement Type", BankAccReconLine."Statement Type"::"Bank Reconciliation");
            BankAccReconLine.TestField(Type, BankAccReconLine.Type::"Bank Account Ledger Entry");
            RemoveReconNo(BankAccLedgEntry, BankAccReconLine, true);

            BankAccReconLine."Applied Amount" -= BankAccLedgEntry."Remaining Amount";
            BankAccReconLine."Applied Entries" := BankAccReconLine."Applied Entries" - 1;
            BankAccReconLine.Validate("Statement Amount");
            ModifyBankAccReconLine(BankAccReconLine);
            DeletePaymentMatchDetails(BankAccReconLine);
        end;
    end;

    local procedure DeletePaymentMatchDetails(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
    begin
        PaymentMatchingDetails.SetRange("Statement Type", BankAccReconciliationLine."Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
        PaymentMatchingDetails.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
        PaymentMatchingDetails.DeleteAll(true);
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
            until CheckLedgEntry.Next() = 0;
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
            until CheckLedgEntry.Next() = 0;
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

