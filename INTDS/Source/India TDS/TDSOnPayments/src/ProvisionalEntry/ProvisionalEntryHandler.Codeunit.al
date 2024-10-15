codeunit 18768 "Provisional Entry Handler"
{
    procedure ReverseProvisionalEntries(Number: Integer)
    var
        ReversalPost: Codeunit "Reversal-Post";
    begin
        InsertReversalProvisionalEntry(Number);
        TempReversalEntry.SETCURRENTKEY("Document No.", "Posting Date", "Entry Type", "Entry No.");
        if not HideDialog then
            page.RunModal(PAGE::"Reverse Entries", TempReversalEntry)
        else begin
            ReversalPost.SetPrint(FALSE);
            ReversalPost.RUN(TempReversalEntry);
        end;
        TempReversalEntry.DeleteAll();
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure InsertReversalProvisionalEntry(Number: Integer)
    var
        TempRevertTransactionNo: Record Integer temporary;
        GLSetup: Record "General Ledger Setup";
        PostApplied: Boolean;
        NextLineNo: Integer;
    begin
        GLSetup.Get();
        TempReversalEntry.DeleteAll();
        NextLineNo := 1;
        TempRevertTransactionNo.Number := Number;
        TempRevertTransactionNo.Insert();
        SetReverseFilterProvisionalEntry(Number);

        InsertFromGLEntryProvisional(TempRevertTransactionNo, NextLineNo);
    end;

    local procedure SetReverseFilterProvisionalEntry(Number: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SETCURRENTKEY("Transaction No.");
        GLEntry.SETRANGE("Transaction No.", Number);
    end;

    local procedure InsertFromGLEntryProvisional(VAR TempRevertTransactionNo: Record Integer temporary; VAR NextLineNo: Integer)
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        TransReverseErr: Label 'The transaction cannot be reversed, because the %1 has been compressed or a %2 has been deleted.', Comment = '%1= GL Entry Table Name,%2=G/L Account Table Name';
    begin
        TempRevertTransactionNo.FindSet();
        REPEAT
            GLEntry.SETRANGE("Transaction No.", TempRevertTransactionNo.Number);
            GLEntry.SETFILTER("Bal. Account No.", '<>%1', '');
            IF GLEntry.FindSet() then
                REPEAT
                    CLEAR(TempReversalEntry);
                    TempReversalEntry."Reversal Type" := TempReversalEntry."Reversal Type"::Transaction;
                    TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::"G/L Account";
                    TempReversalEntry."Entry No." := GLEntry."Entry No.";
                    IF NOT GLAccount.GET(GLEntry."G/L Account No.") then
                        ERROR(TransReverseErr, GLEntry.TABLECAPTION, GLAccount.TABLECAPTION);
                    TempReversalEntry."Account No." := GLAccount."No.";
                    TempReversalEntry."Account Name" := GLAccount.Name;
                    TempReversalEntry."Posting Date" := GLEntry."Posting Date";
                    TempReversalEntry."Source Code" := GLEntry."Source Code";
                    TempReversalEntry."Journal Batch Name" := GLEntry."Journal Batch Name";
                    TempReversalEntry."Transaction No." := GLEntry."Transaction No.";
                    TempReversalEntry."Source Type" := GLEntry."Source Type";
                    TempReversalEntry."Source No." := GLEntry."Source No.";
                    TempReversalEntry.Description := GLEntry.Description;
                    TempReversalEntry."Amount (LCY)" := GLEntry.Amount;
                    TempReversalEntry."Debit Amount (LCY)" := GLEntry."Debit Amount";
                    TempReversalEntry."Credit Amount (LCY)" := GLEntry."Credit Amount";
                    TempReversalEntry."VAT Amount" := GLEntry."VAT Amount";
                    TempReversalEntry."Document Type" := GLEntry."Document Type";
                    TempReversalEntry."Document No." := GLEntry."Document No.";
                    TempReversalEntry."Bal. Account Type" := GLEntry."Bal. Account Type";
                    TempReversalEntry."Bal. Account No." := GLEntry."Bal. Account No.";
                    TempReversalEntry."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 1;
                    TempReversalEntry.Insert();
                UNTIL GLEntry.Next() = 0;
        UNTIL TempRevertTransactionNo.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterRunWithoutCheck', '', false, false)]
    local procedure PostVendorEntry(var GenJnlLine: Record "Gen. Journal Line"; sender: Codeunit "Gen. Jnl.-Post Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
        TaxTransactionValue: Record "Tax Transaction Value";
        Vendor: Record Vendor;
        TDSAmount, TDSAmountLCY : Decimal;
        AmtNegativeErr: Label 'Amount must be negative.';
    begin
        TaxTransactionValue.SetRange("Tax Record ID", GenJnlLine.RecordId);
        if (GenJnlLine."TDS Section Code" = '') or (Not GenJnlLine."Provisional Entry") or (TaxTransactionValue.IsEmpty) then
            exit;
        GenJnlLine.testfield("Party Type", GenJnlLine."Party Type"::Vendor);
        GenJnlLine.TestField("Party Code");
        Vendor.GET(GenJnlLine."Party Code");
        Vendor.TestField("Vendor Posting Group");
        GenJnlLine.TestField("Document Type", GenJnlLine."Document Type"::Invoice);
        GenJnlLine.TestField("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.TestField("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.TestField("Party Code");
        GenJnlLine.TestField("Party Type", GenJnlLine."Party Type"::Vendor);
        GenJnlLine.TestField("TDS Section Code");
        IF GenJnlLine.Amount <= 0 THEN
            Error(AmtNegativeErr);

        TDSAmount := GetTDSAmount(GenJnlLine);
        if GenJnlLine."Currency Code" <> '' then
            TDSAmountLCY := GetTDSAmountLCY(GenJnlLine, TDSAmount)
        else
            TDSAmountLCY := TDSAmount;

        GenJournalLine := GenJnlLine;
        Clear(GenJournalLine."Tax ID");
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::" ";
        GenJournalLine."System-Created Entry" := true;
        Clear(GenJournalLine."Bal. Account Type");
        GenJournalLine."Bal. Account No." := '';
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Account No." := GenJnlLine."Party Code";
        GenJournalLine.Validate(Amount, TDSAmount);
        GenJournalLine.Validate("Amount (LCY)", TDSAmountLCY);
        InsertProvisionalEntry(GenJnlLine, sender);
        sender.RunWithCheck(GenJournalLine);
    end;

    local procedure InsertProvisionalEntry(var GenJnlLine: Record "Gen. Journal Line"; sender: Codeunit "Gen. Jnl.-Post Line")
    var
        ProvisionalEntry: Record "Provisional Entry";
        TaxTransactionValue: Record "Tax Transaction Value";
    begin
        if (GenJnlLine."Party Code" = '') or (GenJnlLine."TDS Section Code" = '') then
            exit;
        ProvisionalEntry.Init();
        ProvisionalEntry."Entry No." := GetNextProvisionalEntryNo();
        ProvisionalEntry."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        ProvisionalEntry."Journal Template Name" := GenJnlLine."Journal Template Name";
        ProvisionalEntry."Document Type" := GenJnlLine."Document Type"::Invoice;
        ProvisionalEntry."Posted Document No." := GenJnlLine."Document No.";
        ProvisionalEntry."Document Date" := GenJnlLine."Document Date";
        ProvisionalEntry."Posting Date" := GenJnlLine."Posting Date";
        ProvisionalEntry."Party Type" := GenJnlLine."Party Type";
        ProvisionalEntry."Party Code" := GenJnlLine."Party Code";
        ProvisionalEntry."Account Type" := GenJnlLine."Account Type";
        ProvisionalEntry."Account No." := GenJnlLine."Bal. Account No.";
        ProvisionalEntry."TDS Section Code" := GenJnlLine."TDS Section Code";
        ProvisionalEntry.Amount := -GenJnlLine.Amount;
        ProvisionalEntry."Amount LCY" := -GenJnlLine."Amount (LCY)";
        if ProvisionalEntry.Amount > 0 then
            ProvisionalEntry."Debit Amount" := Abs(ProvisionalEntry.Amount)
        else
            ProvisionalEntry."Credit Amount" := Abs(ProvisionalEntry.Amount);
        ProvisionalEntry."Bal. Account Type" := GenJnlLine."Bal. Account Type";
        ProvisionalEntry."Bal. Account No." := GenJnlLine."Account No.";
        ProvisionalEntry."Location Code" := GenJnlLine."Location Code";
        ProvisionalEntry."Externl Document No." := GenJnlLine."External Document No.";
        ProvisionalEntry."Currency Code" := GenJnlLine."Currency Code";
        ProvisionalEntry."User ID" := CopyStr(UserId, 1, 50);
        ProvisionalEntry.Open := TRUE;
        ProvisionalEntry."Transaction No." := sender.GetNextTransactionNo();
        ProvisionalEntry.Insert(true)
    end;

    local procedure GetTDSAmount(GenJnlLine: Record "Gen. Journal Line"): Decimal
    var
        TaxTransactionValue: Record "Tax Transaction Value";
        TDSSetup: Record "TDS Setup";
        TaxComponents: Record "Tax Component";
        TDSAmount: Decimal;
    begin
        if not TDSSetup.Get() then
            exit;
        TDSSetup.TestField("Tax Type");

        TaxComponents.SetRange("Tax Type", TDSSetup."Tax Type");
        TaxComponents.SetRange("Skip Posting", false);
        if TaxComponents.FindSet() then
            repeat
                TaxTransactionValue.SetRange("Tax Record ID", GenJnlLine.RecordId);
                TaxTransactionValue.SetRange("Value Type", TaxTransactionValue."Value Type"::COMPONENT);
                TaxTransactionValue.SetRange("Value ID", TaxComponents.ID);
                if TaxTransactionValue.FindSet() then
                    repeat
                        TDSAmount += TaxTransactionValue.Amount;
                    until TaxTransactionValue.Next() = 0;
            until TaxComponents.Next() = 0;
        exit(TDSAmount);
    end;

    local procedure GetTDSAmountLCY(GenJnlLine: Record "Gen. Journal Line"; TDSAmount: Decimal): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        TDSAmt: Decimal;
    begin
        TDSAmt := CurrExchRate.ExchangeAmtFCYToLCY(GenJnlLine."Posting Date", GenJnlLine."Currency Code", TDSAmount, GenJnlLine."Currency Factor");
        exit(RoundTDSAmount(TDSAmt));
    end;

    Local procedure RoundTDSAmount(TDSAmount: Decimal): Decimal
    var
        TaxComponent: Record "Tax Component";
        TDSSetup: Record "TDS Setup";
        TDSRoundingDirection: Text;
    begin
        if not TDSSetup.get() then
            exit;
        TDSSetup.TestField("Tax Type");

        TaxComponent.SetRange("Tax Type", TDSSetup."Tax Type");
        TaxComponent.SetRange(Name, TDSSetup."Tax Type");
        TaxComponent.FindFirst();
        case TaxComponent.Direction of
            TaxComponent.Direction::Nearest:
                TDSRoundingDirection := '=';
            TaxComponent.Direction::Up:
                TDSRoundingDirection := '>';
            TaxComponent.Direction::Down:
                TDSRoundingDirection := '<';
        end;
        exit(ROUND(TDSAmount, TaxComponent."Rounding Precision", TDSRoundingDirection));
    end;

    local procedure GetNextProvisionalEntryNo(): Integer
    var
        ProvisionalEntry: Record "Provisional Entry";
    begin
        if ProvisionalEntry.FindLast() then
            exit(ProvisionalEntry."Entry No." + 1)
        else
            exit(1);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', false, false)]
    local procedure FindTCSEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    var
        ProvisionalEntry: Record "Provisional Entry";
        Navigate: page Navigate;
    begin
        if ProvisionalEntry.ReadPermission() then begin
            ProvisionalEntry.Reset();
            ProvisionalEntry.SetCurrentKey("Posted Document No.", "Posting Date");
            ProvisionalEntry.SetFilter("Posted Document No.", DocNoFilter);
            ProvisionalEntry.SetFilter("Posting Date", PostingDateFilter);
            Navigate.InsertIntoDocEntry(DocumentEntry, DATABASE::"Provisional Entry", 0, Copystr(ProvisionalEntry.TableCaption(), 1, 1024), ProvisionalEntry.Count());
        end;
    end;

    [EventSubscriber(ObjectType::Page, page::Navigate, 'OnAfterNavigateShowRecords', '', false, false)]
    local procedure ShowEntries(TableID: Integer; DocNoFilter: Text; PostingDateFilter: Text; var TempDocumentEntry: Record "Document Entry")
    var
        ProvisionalEntry: Record "Provisional Entry";
    begin
        ProvisionalEntry.Reset();
        ProvisionalEntry.SetFilter("Posted Document No.", DocNoFilter);
        ProvisionalEntry.SetFilter("Posting Date", PostingDateFilter);
        if TableID = Database::"Provisional Entry" then
            PAGE.Run(page::"Provisional Entries Preview", ProvisionalEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterRunWithoutCheck', '', false, false)]
    local procedure CreateReverseProvisionalEntry(var GenJnlLine: Record "Gen. Journal Line"; sender: Codeunit "Gen. Jnl.-Post Line")
    var
        ProvisionalEntry: Record "Provisional Entry";
        ProvJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        VendLedgerEntryNo: Integer;
    begin
        if GenJnlLine."Applied Provisional Entry" = 0 then
            exit;
        CheckMultiLineProvisionalEntry(GenJnlLine);
        VendLedgerEntryNo := sender.GetNextEntryNo();

        ProvisionalEntry.Get(GenJnlLine."Applied Provisional Entry");
        ProvisionalEntry.TestField(Reversed, FALSE);
        ProvisionalEntry.TestField(Open, TRUE);
        ProvisionalEntry.TestField("Reversed After TDS Paid", FALSE);
        ProvisionalEntry."Actual Invoice Posting Date" := GenJnlLine."Posting Date";

        GLEntry.SetRange("Posting Date", ProvisionalEntry."Posting Date");
        GLEntry.SetRange("Document No.", ProvisionalEntry."Posted Document No.");
        GLEntry.SetFilter("Bal. Account No.", '<>%1', '');
        GLEntry.FindFirst();

        ProvJournalLine."Posting Date" := GenJnlLine."Posting Date";
        ProvJournalLine."Journal Template Name" := GenJnlLine."Journal Template Name";
        ProvJournalLine."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        ProvJournalLine."Document Date" := GenJnlLine."Document Date";
        ProvJournalLine."Document Type" := ProvJournalLine."Document Type"::Invoice;
        ProvJournalLine."Document No." := GenJnlLine."Document No.";
        ProvJournalLine."External Document No." := GenJnlLine."External Document No.";
        ProvJournalLine.Validate("Account Type", ProvJournalLine."Account Type"::"G/L Account");
        ProvJournalLine."Account No." := GLEntry."G/L Account No.";
        ProvJournalLine.Validate("Bal. Account Type", ProvJournalLine."Bal. Account Type"::"G/L Account");
        ProvJournalLine."Bal. Account No." := GLEntry."Bal. Account No.";
        ProvJournalLine.Validate("Currency Code", GenJnlLine."Currency Code");
        ProvJournalLine.Validate(Amount, -GLEntry.Amount);
        ProvJournalLine.Validate("Amount (LCY)", -GLEntry.Amount);
        ProvJournalLine."Currency Factor" := 1;
        ProvJournalLine."Source Currency Code" := GenJnlLine."Source Currency Code";
        ProvJournalLine."Gen. Posting Type" := GLEntry."Gen. Posting Type";
        ProvJournalLine."Gen. Bus. Posting Group" := GLEntry."Gen. Bus. Posting Group";
        ProvJournalLine."Gen. Prod. Posting Group" := GLEntry."Gen. Prod. Posting Group";
        ProvJournalLine."Shortcut Dimension 1 Code" := GLEntry."Global Dimension 1 Code";
        ProvJournalLine."Shortcut Dimension 2 Code" := GLEntry."Global Dimension 2 Code";
        ProvJournalLine.Validate("Dimension Set ID", GLEntry."Dimension Set ID");
        ProvJournalLine."Posting No. Series" := GenJnlLine."Posting No. Series";
        ProvJournalLine."Location Code" := GenJnlLine."Location Code";
        ProvJournalLine."Source Code" := GenJnlLine."Source Code";
        ProvJournalLine."Reason Code" := GenJnlLine."Reason Code";
        ProvJournalLine."Provisional Entry" := GenJnlLine."Provisional Entry";
        sender.RunWithCheck(ProvJournalLine);

        ProvisionalEntry.Open := FALSE;
        ProvisionalEntry."Purchase Invoice No." := '';
        ProvisionalEntry."Applied User ID" := '';
        ProvisionalEntry."Invoice Jnl Batch Name" := '';
        ProvisionalEntry."Invoice Jnl Template Name" := '';
        ProvisionalEntry."Applied Invoice No." := GenJnlLine."Document No.";
        ProvisionalEntry."Original Invoice Posted" := TRUE;
        ProvisionalEntry."Applied by Vendor Ledger Entry" := VendLedgerEntryNo;
        ProvisionalEntry."Original Invoice Reversed" := false;
        ProvisionalEntry.Modify();
    end;

    local procedure CheckMultiLineProvisionalEntry(GenJournalLine: Record "Gen. Journal Line")
    var
        LineCount: Integer;
        ProvEntryMultiLineErr: Label 'Multi Line transactions are not allowed for Provisional Entries.';
    begin
        LineCount := GetTotalDocLinesProvisionalEntry(GenJournalLine);
        if LineCount > 1 then
            ERROR(ProvEntryMultiLineErr);
    end;

    local procedure GetTotalDocLinesProvisionalEntry(GenJournalLine: Record "Gen. Journal Line"): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Document No.", "Line No.");
        GenJnlLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJnlLine.SetRange("System-Created Entry", FALSE);
        if GenJournalLine."Document No." = GenJournalLine."Old Document No." then
            GenJnlLine.SetRange("Document No.", GenJournalLine."Document No.")
        else
            GenJnlLine.SetRange("Document No.", GenJournalLine."Old Document No.");
        exit(GenJnlLine.Count);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnAfterReverseGLEntry', '', false, false)]
    local procedure CheckAndUpdateProvisionalEntry(var GLEntry: Record "G/L Entry")
    begin
        CheckProvisionalEntryIfApplied(GLEntry);
        CheckProvisionalEntryOpenAndReversed(GLEntry);
        ;
        UpdateProvisionalEntry(GLEntry);
        UpdateProvisionalEntryOnActualInvReversal(GLEntry);
    end;

    local procedure UpdateProvisionalEntry(GLEntry: Record "G/L Entry")
    var
        ProvisionalEntry: Record "Provisional Entry";
    Begin
        ProvisionalEntry.SetRange("Posted Document No.", GLEntry."Document No.");
        ProvisionalEntry.SetRange("Posting Date", GLEntry."Posting Date");
        ProvisionalEntry.SetRange("Account No.", GLEntry."G/L Account No.");
        ProvisionalEntry.SetRange("Bal. Account No.", GLEntry."Bal. Account No.");
        ProvisionalEntry.SetRange(Reversed, FALSE);
        if ProvisionalEntry.FindFirst() then begin
            ProvisionalEntry.Reversed := true;
            ProvisionalEntry.Open := false;
            ProvisionalEntry."Original Invoice Reversed" := false;
            ProvisionalEntry.Modify();
        end;
    end;

    local procedure UpdateProvisionalEntryOnActualInvReversal(GLEntry: Record "G/L Entry")
    var
        ProvisionalEntry: Record "Provisional Entry";
    begin
        ProvisionalEntry.SetRange("Applied Invoice No.", GLEntry."Document No.");
        ProvisionalEntry.SetRange("Actual Invoice Posting Date", GLEntry."Posting Date");
        ProvisionalEntry.SetRange("Original Invoice Posted", TRUE);
        if ProvisionalEntry.FindFirst() then begin
            ProvisionalEntry."Applied Invoice No." := '';
            ProvisionalEntry."Original Invoice Posted" := FALSE;
            ProvisionalEntry."Original Invoice Reversed" := TRUE;
            ProvisionalEntry."Applied by Vendor Ledger Entry" := 0;
            ProvisionalEntry."Purchase Invoice No." := '';
            ProvisionalEntry."Applied User ID" := '';
            ProvisionalEntry."Invoice Jnl Batch Name" := '';
            ProvisionalEntry."Invoice Jnl Template Name" := '';
            ProvisionalEntry.Open := TRUE;
            ProvisionalEntry.Modify();
        end;
    end;

    local procedure CheckProvisionalEntryIfApplied(GLEntry: Record "G/L Entry")
    var
        ProvisionalEntry: Record "Provisional Entry";
        ProvisionalEntryAlreadyAppliedErr: Label 'Provisional Entry is already applied against Document No. %1 on purchase journals.', Comment = '%1= Purchase Invoice No.';
    begin

        ProvisionalEntry.SetRange("Posted Document No.", GLEntry."Document No.");
        ProvisionalEntry.SetRange("Posting Date", GLEntry."Posting Date");
        ProvisionalEntry.SetRange("Account No.", GLEntry."G/L Account No.");
        ProvisionalEntry.SetRange("Bal. Account No.", GLEntry."Bal. Account No.");
        ProvisionalEntry.SetFilter("Purchase Invoice No.", '<>%1', '');
        if ProvisionalEntry.FindFirst() then
            Error(ProvisionalEntryAlreadyAppliedErr, ProvisionalEntry."Purchase Invoice No.");
    end;

    local procedure CheckProvisionalEntryOpenAndReversed(GLEntry: Record "G/L Entry")
    var
        ProvisionalEntry: Record "Provisional Entry";
    begin
        ProvisionalEntry.SetRange("Posted Document No.", GLEntry."Document No.");
        ProvisionalEntry.SetRange("Posting Date", GLEntry."Posting Date");
        ProvisionalEntry.SetRange("Account No.", GLEntry."G/L Account No.");
        ProvisionalEntry.SetRange("Bal. Account No.", GLEntry."Bal. Account No.");
        ProvisionalEntry.SetRange(Open, false);
        if ProvisionalEntry.FindFirst() then
            ProvisionalEntry.TestField(Open, true);

        ProvisionalEntry.SetRange(Open);
        ProvisionalEntry.SetRange(Reversed, true);
        if ProvisionalEntry.FindFirst() then
            ProvisionalEntry.TestField(Reversed, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnNextTransactionNoNeeded', '', false, false)]
    local procedure OnNextTransactionNoNeeded(GenJnlLine: Record "Gen. Journal Line"; var NewTransaction: Boolean)
    begin
        if GenJnlLine."Provisional Entry" and GenJnlLine."System-Created Entry" then
            NewTransaction := false;
    end;

    var
        TempReversalEntry: Record "Reversal Entry" temporary;
        HideDialog: Boolean;
}