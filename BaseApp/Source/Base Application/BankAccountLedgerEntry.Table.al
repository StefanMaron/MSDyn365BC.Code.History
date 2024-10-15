table 271 "Bank Account Ledger Entry"
{
    Caption = 'Bank Account Ledger Entry';
    DrillDownPageID = "Bank Account Ledger Entries";
    LookupPageID = "Bank Account Ledger Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
        }
        field(17; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(22; "Bank Acc. Posting Group"; Code[20])
        {
            Caption = 'Bank Acc. Posting Group';
            TableRelation = "Bank Account Posting Group";
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(25; "Our Contact Code"; Code[20])
        {
            Caption = 'Our Contact Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(36; Open; Boolean)
        {
            Caption = 'Open';
        }
        field(43; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(44; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(45; "Closed at Date"; Date)
        {
            Caption = 'Closed at Date';
        }
        field(48; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(49; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(50; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(51; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(52; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF ("Bal. Account Type" = CONST(Employee)) Employee;
        }
        field(53; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(55; "Statement Status"; Option)
        {
            Caption = 'Statement Status';
            OptionCaption = 'Open,Bank Acc. Entry Applied,Check Entry Applied,Closed';
            OptionMembers = Open,"Bank Acc. Entry Applied","Check Entry Applied",Closed;
        }
        field(56; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
#if not CLEAN21
            TableRelation = IF ("Statement Status" = FILTER("Bank Acc. Entry Applied" | "Check Entry Applied")) "Bank Rec. Header"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."))
            ELSE
            IF ("Statement Status" = CONST(Closed)) "Posted Bank Rec. Header"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."));
#else
            TableRelation = "Bank Acc. Reconciliation Line"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."));
            ValidateTableRelation = false;
#endif
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(57; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
#if not CLEAN21
            TableRelation = IF ("Statement Status" = FILTER("Bank Acc. Entry Applied" | "Check Entry Applied")) "Bank Rec. Line"."Line No." WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                                                                                               "Statement No." = FIELD("Statement No."))
            ELSE
            IF ("Statement Status" = CONST(Closed)) "Posted Bank Rec. Line"."Line No." WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                                                                                                                                                                                    "Statement No." = FIELD("Statement No."));
#else
            TableRelation = "Bank Acc. Reconciliation Line"."Statement Line No." WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                                        "Statement No." = FIELD("Statement No."));
#endif
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(58; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
        }
        field(59; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
        }
        field(60; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount (LCY)';
        }
        field(61; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount (LCY)';
        }
        field(62; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;
        }
        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(64; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(65; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(66; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(70; "Check Ledger Entries"; Integer)
        {
            CalcFormula = Count("Check Ledger Entry" WHERE("Bank Account Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Check Ledger Entries';
            FieldClass = FlowField;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Posting Date")
        {
            SumIndexFields = Amount, "Amount (LCY)", "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)";
        }
        key(Key3; "Bank Account No.", Open)
        {
        }
        key(Key4; "Document Type", "Bank Account No.", "Posting Date")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount;
        }
        key(Key5; "Document No.", "Posting Date")
        {
        }
        key(Key6; "Transaction No.")
        {
        }
        key(Key7; "Bank Account No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date")
        {
            Enabled = false;
            SumIndexFields = Amount, "Amount (LCY)", "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)";
        }
        key(Key8; "Bank Account No.", "Posting Date", "Statement Status")
        {
        }
        key(Key9; "External Document No.", "Posting Date")
        {
            Enabled = false;
        }
        key(key10; "Statement No.", "Statement Line No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Bank Account No.", "Posting Date", "Document Type", "Document No.")
        {
        }
    }
    trigger OnInsert()
    begin
        UpdateBankAccReconciliationLine();
    end;

    var
        DimMgt: Codeunit DimensionManagement;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    procedure CopyFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        "Bank Account No." := GenJnlLine."Account No.";
        "Posting Date" := GenJnlLine."Posting Date";
        "Document Date" := GenJnlLine."Document Date";
        "Document Type" := GenJnlLine."Document Type";
        "Document No." := GenJnlLine."Document No.";
        "External Document No." := GenJnlLine."External Document No.";
        Description := GenJnlLine.Description;
        "Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := GenJnlLine."Dimension Set ID";
        "Our Contact Code" := GenJnlLine."Salespers./Purch. Code";
        "Source Code" := GenJnlLine."Source Code";
        "Journal Templ. Name" := GenJnlLine."Journal Template Name";
        "Journal Batch Name" := GenJnlLine."Journal Batch Name";
        "Reason Code" := GenJnlLine."Reason Code";
        "Currency Code" := GenJnlLine."Currency Code";
        "User ID" := UserId;
        "Bal. Account Type" := GenJnlLine."Bal. Account Type";
        "Bal. Account No." := GenJnlLine."Bal. Account No.";
        if GenJnlLine."Linked Table ID" <> 0 then
            SetBankAccReconciliationLine(GenJnlLine);

        OnAfterCopyFromGenJnlLine(Rec, GenJnlLine);
    end;

    Local procedure SetBankAccReconciliationLine(GenJnlLine: Record "Gen. Journal Line")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if GenJnlLine."Linked Table ID" <> Database::"Bank Acc. Reconciliation Line" then
            exit;
        if IsNullGuid(GenJnlLine."Linked System ID") then
            exit;
        if not BankAccReconciliationLine.GetBySystemId(GenJnlLine."Linked System ID") then
            exit;
        if "Bank Account No." <> BankAccReconciliationLine."Bank Account No." then
            exit;
        BankAccountLedgerEntry.SetCurrentKey("Statement No.", "Statement Line No.");
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
        BankAccountLedgerEntry.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
        if not BankAccountLedgerEntry.IsEmpty() then
            exit;
        "Statement Status" := "Statement Status"::"Bank Acc. Entry Applied";
        "Statement No." := BankAccReconciliationLine."Statement No.";
        "Statement Line No." := BankAccReconciliationLine."Statement Line No.";
    end;

    local procedure UpdateBankAccReconciliationLine()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        if "Statement No." = '' then
            exit;
        if not BankAccReconciliationLine.Get(BankAccReconciliationLine."Statement Type"::"Bank Reconciliation", "Bank Account No.", "Statement No.", "Statement Line No.") then
            exit;
        if BankAccReconciliationLine."Statement Amount" = Amount then begin
            BankAccReconciliationLine."Applied Amount" += Amount;
            BankAccReconciliationLine.Difference := BankAccReconciliationLine."Statement Amount" - BankAccReconciliationLine."Applied Amount";
            BankAccReconciliationLine."Applied Entries" += 1;
            BankAccReconciliationLine.Modify();
        end else begin
            "Statement Status" := "Statement Status"::Open;
            "Statement No." := '';
            "Statement Line No." := 0;
        end;
    end;

    procedure UpdateDebitCredit(Correction: Boolean)
    begin
        if (Amount > 0) and (not Correction) or
           (Amount < 0) and Correction
        then begin
            "Debit Amount" := Amount;
            "Credit Amount" := 0;
            "Debit Amount (LCY)" := "Amount (LCY)";
            "Credit Amount (LCY)" := 0;
        end else begin
            "Debit Amount" := 0;
            "Credit Amount" := -Amount;
            "Debit Amount (LCY)" := 0;
            "Credit Amount (LCY)" := -"Amount (LCY)";
        end;
    end;

    procedure IsApplied() IsApplied: Boolean
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", "Bank Account No.");
        CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", "Entry No.");
        CheckLedgerEntry.SetRange(Open, true);
        CheckLedgerEntry.SetRange("Statement Status", CheckLedgerEntry."Statement Status"::"Check Entry Applied");
        CheckLedgerEntry.SetFilter("Statement No.", '<>%1', '');
        CheckLedgerEntry.SetFilter("Statement Line No.", '<>%1', 0);
        IsApplied := not CheckLedgerEntry.IsEmpty();

        IsApplied := IsApplied or
          (("Statement Status" = "Statement Status"::"Bank Acc. Entry Applied") and
           ("Statement No." <> '') and ("Statement Line No." <> 0));

        exit(IsApplied);
    end;

    procedure SetStyle(): Text
    begin
        if IsApplied() then
            exit('Favorable');

        exit('');
    end;

    procedure SetFilterBankAccNoOpen(BankAccNo: Code[20])
    begin
        Reset();
        SetCurrentKey("Bank Account No.", Open);
        SetRange("Bank Account No.", BankAccNo);
        SetRange(Open, true);
    end;

#if NOT CLEAN20
    [Obsolete('Please use the ResetStatementFields(BankAccountNo, StatementNo, StatementType) instead, as we can have payment and bank reconciliations with the same bank account no and statement no and we might be resetting too many ledger entries with this function', '20.0')]
    procedure ResetStatementFields(BankAccountNo: Code[20]; StatementNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccLedgEntryReset: Codeunit "Bank Acc. Ledg. Entry-Reset";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Statement No.", StatementNo);
        if BankAccountLedgerEntry.FindSet() then
            repeat
                BankAccLedgEntryReset.Run(BankAccountLedgerEntry);
            until BankAccountLedgerEntry.Next() = 0;
    end;
#endif

    procedure ResetStatementFields(BankAccountNo: Code[20]; StatementNo: Code[20]; StatementType: Option)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccLedgEntryReset: Codeunit "Bank Acc. Ledg. Entry-Reset";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Statement No.", StatementNo);
        if BankAccountLedgerEntry.FindSet() then
            repeat
                // we can have payment and bank reconciliations with the same bank account no and statement no, 
                // so unless we also filter by statement type we might be resetting too many ledger entries
                if BankAccReconciliationLine.Get(StatementType, BankAccountNo,
                    StatementNo, BankAccountLedgerEntry."Statement Line No.")
                then
                    BankAccLedgEntryReset.Run(BankAccountLedgerEntry);
            until BankAccountLedgerEntry.Next() = 0;
    end;

    procedure CopyFromBankAccLedgerEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; StatementNo: Code[20])
    begin
        Init();
        "Entry No." := BankAccountLedgerEntry."Entry No.";
        "Posting Date" := BankAccountLedgerEntry."Posting Date";
        "Document Type" := BankAccountLedgerEntry."Document Type";
        "Document No." := BankAccountLedgerEntry."Document No.";
        "Bank Account No." := BankAccountLedgerEntry."Bank Account No.";
        Description := BankAccountLedgerEntry.Description;
        Amount := BankAccountLedgerEntry.Amount;
        "Statement No." := StatementNo;
        Insert();
    end;

    internal procedure SetBankReconciliationCandidatesFilter(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        FilterDate: Date;
    begin
        Rec.Reset();
        Rec.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        Rec.SetRange("Statement Status", Rec."Statement Status"::Open);
        Rec.SetFilter("Remaining Amount", '<>%1', 0);
        Rec.SetRange("Reversed", false); // PR 30730

        FilterDate := BankAccReconciliation.MatchCandidateFilterDate();
        if FilterDate <> 0D then
            Rec.SetFilter("Posting Date", '<=%1', FilterDate);

        // Records sorted by posting date to optimize matching
        Rec.SetCurrentKey("Posting Date");
        Rec.SetAscending("Posting Date", true);
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCopyFromGenJnlLine(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

