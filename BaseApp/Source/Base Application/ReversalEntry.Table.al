table 179 "Reversal Entry"
{
    Caption = 'Reversal Entry';
    PasteIsValid = false;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Entry Type"; Enum "Reversal Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            TableRelation = IF ("Entry Type" = CONST("G/L Account")) "G/L Entry"
            ELSE
            IF ("Entry Type" = CONST(Customer)) "Cust. Ledger Entry"
            ELSE
            IF ("Entry Type" = CONST(Vendor)) "Vendor Ledger Entry"
            ELSE
            IF ("Entry Type" = CONST("Bank Account")) "Bank Account Ledger Entry"
            ELSE
            IF ("Entry Type" = CONST("Fixed Asset")) "FA Ledger Entry"
            ELSE
            IF ("Entry Type" = CONST(Maintenance)) "Maintenance Ledger Entry"
            ELSE
            IF ("Entry Type" = CONST(VAT)) "VAT Entry"
            ELSE
            IF ("Entry Type" = CONST("Value Entry")) "Value Entry";
        }
        field(4; "G/L Register No."; Integer)
        {
            Caption = 'G/L Register No.';
            TableRelation = "G/L Register";
        }
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(6; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(7; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(8; "Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Source Type';
        }
        field(9; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Source Type" = CONST("Fixed Asset")) "Fixed Asset";
        }
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(13; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Debit Amount';
        }
        field(14; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Credit Amount';
        }
        field(15; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(16; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Debit Amount (LCY)';
        }
        field(17; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Credit Amount (LCY)';
        }
        field(18; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(19; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(20; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(21; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(22; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        field(23; "Account Name"; Text[100])
        {
            Caption = 'Account Name';
        }
        field(25; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(26; "Bal. Account No."; Code[20])
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
            IF ("Bal. Account Type" = CONST("Fixed Asset")) "Fixed Asset";
        }
        field(27; "FA Posting Category"; Option)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Category';
            OptionCaption = ' ,Disposal,Bal. Disposal';
            OptionMembers = " ",Disposal,"Bal. Disposal";
        }
        field(28; "FA Posting Type"; Enum "Reversal Entry FA Posting Type")
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Type';
        }
        field(30; "Reversal Type"; Option)
        {
            Caption = 'Reversal Type';
            OptionCaption = 'Transaction,Register';
            OptionMembers = Transaction,Register;
        }
        field(12483; "Corrected Period Date"; Date)
        {
            Caption = 'Corrected Period Date';
        }
        field(12490; "VAT Allocation"; Boolean)
        {
            Caption = 'VAT Allocation';
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Entry Type")
        {
        }
        key(Key3; "Document No.", "Posting Date", "Entry Type", "Entry No.")
        {
        }
        key(Key4; "Entry Type", "Entry No.")
        {
        }
        key(Key5; "Transaction No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        VATEntry: Record "VAT Entry";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        ValueEntry: Record "Value Entry";
        TaxDiffLedgEntry: Record "Tax Diff. Ledger Entry";
        GLItemLedgRelation: Record "G/L - Item Ledger Relation";
        GLReg: Record "G/L Register";
        Text000: Label 'You cannot reverse %1 No. %2 because the entry is either applied to an entry or has been changed by a batch job.';
        FAReg: Record "FA Register";
        TempGLReg: Record "G/L Register" temporary;
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        Text001: Label 'You cannot reverse %1 No. %2 because the posting date is not within the allowed posting period.';
        Text002: Label 'You cannot reverse the transaction because it is out of balance.';
        Text003: Label 'You cannot reverse %1 No. %2 because the entry has a related check ledger entry.';
        Text004: Label 'You can only reverse entries that were posted from a journal.';
        Text005: Label 'You cannot reverse %1 No. %2 because the %3 is not within the allowed posting period.';
        Text006: Label 'You cannot reverse %1 No. %2 because the entry is closed.';
        Text007: Label 'You cannot reverse %1 No. %2 because the entry is included in a bank account reconciliation line. The bank reconciliation has not yet been posted.';
        Text008: Label 'You cannot reverse the transaction because the %1 has been sold.';
        CannotReverseDeletedErr: Label 'The transaction cannot be reversed, because the %1 has been compressed or a %2 has been deleted.', Comment = '%1 and %2 = table captions';
        Text010: Label 'You cannot reverse %1 No. %2 because the register has already been involved in a reversal.';
        Text011: Label 'You cannot reverse %1 No. %2 because the entry has already been involved in a reversal.';
        PostedAndAppliedSameTransactionErr: Label 'You cannot reverse register number %1 because it contains customer or vendor or employee ledger entries that have been posted and applied in the same transaction.\\You must reverse each transaction in register number %1 separately.', Comment = '%1="G/L Register No."';
        Text013: Label 'You cannot reverse %1 No. %2 because the entry has an associated Realized Gain/Loss entry.';
        CannotReverseTaxDiffEntryErr: Label 'You cannot reverse tax difference entry %1 before reversing of entry %2.', Comment = '%1 = entry no., %2 = entry no.';
        Text1002: Label 'You cannot reverse %1 No. %2 because %3 No. %4 exists. This invoice should be deleted before reversing.';
        Text1003: Label '-AD';
        VATAllocOnCost: Boolean;
        UnrealizedVATReverseErr: Label 'You cannot reverse %1 No. %2 because the entry has an associated Unrealized VAT Entry.';

    protected var
        GLSetup: Record "General Ledger Setup";
        TempReversalEntry: Record "Reversal Entry" temporary;
        AllowPostingFrom: Date;
        AllowPostingto: Date;
        HideDialog: Boolean;
        HideWarningDialogs: Boolean;
        MaxPostingDate: Date;

    procedure ReverseTransaction(TransactionNo: Integer)
    begin
        ReverseEntries(TransactionNo, "Reversal Type"::Transaction);
    end;

    procedure ReverseRegister(RegisterNo: Integer)
    begin
        CheckRegister(RegisterNo);
        ReverseEntries(RegisterNo, "Reversal Type"::Register);
    end;

    local procedure ReverseEntries(Number: Integer; RevType: Option Transaction,Register)
    var
        ReversalPost: Codeunit "Reversal-Post";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReverseEntries(Number, RevType, IsHandled, HideDialog, Rec);
        if IsHandled then
            exit;

        VATEntry.SetRange("Transaction No.", Number);
        VATEntry.SetRange("VAT Allocation Type", VATEntry."VAT Allocation Type"::Charge);
        if not VATEntry.IsEmpty() then
            Error('');
        VATEntry.Reset();

        InsertReversalEntry(Number, RevType);
        TempReversalEntry.SetCurrentKey("Document No.", "Posting Date", "Entry Type", "Entry No.");
        if not HideDialog then
            PAGE.RunModal(PAGE::"Reverse Entries", TempReversalEntry)
        else begin
            ReversalPost.SetPrint(false);
            ReversalPost.SetHideDialog(HideWarningDialogs);
            ReversalPost.Run(TempReversalEntry);
        end;
        TempReversalEntry.DeleteAll();

        OnAfterReverseEntries(Number, RevType, HideDialog);
    end;

    local procedure InsertReversalEntry(Number: Integer; RevType: Option Transaction,Register)
    var
        TempRevertTransactionNo: Record "Integer" temporary;
        NextLineNo: Integer;
        GLReg2: Record "G/L Register";
        Completed: Boolean;
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertReversalEntry(Rec, Number, RevType, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        TempReversalEntry.DeleteAll();
        NextLineNo := 1;
        TempRevertTransactionNo.Number := Number;
        TempRevertTransactionNo.Insert();
        if VATAllocOnCost then begin
            SourceCodeSetup.Get();
            Completed := false;
            TempGLReg.DeleteAll();
            GLReg.Get(Number);
            GLReg2.Get(Number);
            repeat
                if GLReg2.Next(-1) <> 0 then
                    if (GLReg2."Source Code" = SourceCodeSetup."Inventory Post Cost") and
                       (GLReg2."Creation Date" = GLReg."Creation Date") and
                       (GLReg2."User ID" = GLReg."User ID")
                    then begin
                        TempGLReg := GLReg2;
                        TempGLReg.Insert();
                    end else
                        Completed := true;
            until Completed;
        end;

        SetReverseFilter(Number, RevType);

        InsertFromCustLedgEntry(TempRevertTransactionNo, Number, RevType, NextLineNo);
        InsertFromVendLedgEntry(TempRevertTransactionNo, Number, RevType, NextLineNo);
        InsertFromBankAccLedgEntry(TempRevertTransactionNo, Number, RevType, NextLineNo);
        InsertFromFALedgEntry(TempRevertTransactionNo, Number, RevType, NextLineNo);
        InsertFromMaintenanceLedgEntry(TempRevertTransactionNo, Number, RevType, NextLineNo);
        InsertFromVATEntry(TempRevertTransactionNo, Number, RevType, NextLineNo);
        InsertFromGLEntry(TempRevertTransactionNo, Number, RevType, NextLineNo);
        InsertFromTaxDiffEntry(TempRevertTransactionNo, Number, RevType, NextLineNo);
        if VATAllocOnCost then
            InsertFromVATAllocation(Number, RevType, NextLineNo);
        OnAfterInsertReversalEntry(TempRevertTransactionNo, Number, RevType, NextLineNo, TempReversalEntry);
        if TempReversalEntry.Find('-') then;
    end;

    procedure CheckEntries(IsVATAllocOnCost: Boolean)
    var
        GLAcc: Record "G/L Account";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DateComprReg: Record "Date Compr. Register";
        BalanceCheckAmount: Decimal;
        BalanceCheckAddCurrAmount: Decimal;
        SkipCheck: Boolean;
    begin
        DtldCustLedgEntry.LockTable();
        DtldVendLedgEntry.LockTable();
        GLEntry.LockTable();
        CustLedgEntry.LockTable();
        VendLedgEntry.LockTable();
        BankAccLedgEntry.LockTable();
        FALedgEntry.LockTable();
        MaintenanceLedgEntry.LockTable();
        ValueEntry.LockTable();
        VATEntry.LockTable();
        GLReg.LockTable();
        FAReg.LockTable();
        GLSetup.Get();
        MaxPostingDate := 0D;

        SkipCheck := false;
        OnBeforeCheckEntries(Rec, DATABASE::"G/L Entry", SkipCheck);
        if not SkipCheck then begin
            if GLEntry.IsEmpty() then
                Error(CannotReverseDeletedErr, GLEntry.TableCaption(), GLAcc.TableCaption);
            if GLEntry.Find('-') then begin
                CheckGLEntry(IsVATAllocOnCost);
                repeat
                    CheckGLAcc(GLEntry, BalanceCheckAmount, BalanceCheckAddCurrAmount);
                until GLEntry.Next() = 0;
            end;
            if (BalanceCheckAmount <> 0) or (BalanceCheckAddCurrAmount <> 0) then
                Error(Text002);
        end;

        if CustLedgEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"Cust. Ledger Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckCust(CustLedgEntry);
                until CustLedgEntry.Next() = 0;
        end;

        if VendLedgEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"Vendor Ledger Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckVend(VendLedgEntry);
                until VendLedgEntry.Next() = 0;
        end;

        if BankAccLedgEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"Bank Account Ledger Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckBankAcc(BankAccLedgEntry);
                until BankAccLedgEntry.Next() = 0;
        end;

        if FALedgEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"FA Ledger Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckFA(FALedgEntry);
                until FALedgEntry.Next() = 0;
        end;

        if MaintenanceLedgEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"Maintenance Ledger Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckMaintenance(MaintenanceLedgEntry);
                until MaintenanceLedgEntry.Next() = 0;
        end;

        if VATEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"VAT Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckVAT(VATEntry);
                until VATEntry.Next() = 0;
        end;

        if IsVATAllocOnCost then
            if ValueEntry.Find('-') then begin
                SkipCheck := false;
                OnBeforeCheckEntries(Rec, DATABASE::"VAT Entry", SkipCheck);
                if not SkipCheck then
                    repeat
                        CheckItem(ValueEntry);
                    until ValueEntry.Next() = 0;
            end;

        if TaxDiffLedgEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"Tax Diff. Ledger Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckTaxDiff(TaxDiffLedgEntry);
                until TaxDiffLedgEntry.Next() = 0;
        end;

        OnAfterCheckEntries(MaxPostingDate, Rec);

        DateComprReg.CheckMaxDateCompressed(MaxPostingDate, 1);
    end;

    local procedure CheckGLEntry(IsVATAllocOnCost: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLEntry(Rec, GLEntry, IsHandled);
        if IsHandled then
            exit;

        if (GLEntry."Journal Batch Name" = '') and not IsVATAllocOnCost then
            TestFieldError;
    end;

    local procedure CheckGLAcc(GLEntry: Record "G/L Entry"; var BalanceCheckAmount: Decimal; var BalanceCheckAddCurrAmount: Decimal)
    var
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        OnBeforeCheckGLAcc(GLEntry);

        GLAcc.Get(GLEntry."G/L Account No.");
        CheckPostingDate(GLEntry."Posting Date", GLEntry.TableCaption(), GLEntry."Entry No.");
        IsHandled := false;
        OnCheckGLAccOnBeforeTestFields(GLAcc, GLEntry, IsHandled);
        if not IsHandled then begin
            GLAcc.TestField(Blocked, false);
            GLEntry.TestField("Job No.", '');
        end;
        if GLEntry.Reversed then
            AlreadyReversedEntry(GLEntry.TableCaption(), GLEntry."Entry No.");
        BalanceCheckAmount := BalanceCheckAmount + GLEntry.Amount;
        if GLSetup."Additional Reporting Currency" <> '' then
            BalanceCheckAddCurrAmount := BalanceCheckAddCurrAmount + GLEntry."Additional-Currency Amount";

        OnAfterCheckGLAcc(GLAcc, GLEntry);
    end;

    local procedure CheckCust(CustLedgEntry: Record "Cust. Ledger Entry")
    var
        Cust: Record Customer;
    begin
        OnBeforeCheckCust(CustLedgEntry);

        Cust.Get(CustLedgEntry."Customer No.");
        CheckPostingDate(
          CustLedgEntry."Posting Date", CustLedgEntry.TableCaption(), CustLedgEntry."Entry No.");
        Cust.CheckBlockedCustOnJnls(Cust, CustLedgEntry."Document Type", false);
        if CustLedgEntry.Reversed then
            AlreadyReversedEntry(CustLedgEntry.TableCaption(), CustLedgEntry."Entry No.");
        CheckDtldCustLedgEntry(CustLedgEntry);

        OnAfterCheckCust(Cust, CustLedgEntry);
    end;

    local procedure CheckVend(VendLedgEntry: Record "Vendor Ledger Entry")
    var
        Vend: Record Vendor;
    begin
        OnBeforeCheckVend(VendLedgEntry);

        Vend.Get(VendLedgEntry."Vendor No.");
        CheckPostingDate(
          VendLedgEntry."Posting Date", VendLedgEntry.TableCaption(), VendLedgEntry."Entry No.");
        Vend.CheckBlockedVendOnJnls(Vend, VendLedgEntry."Document Type", false);
        if VendLedgEntry.Reversed then
            AlreadyReversedEntry(VendLedgEntry.TableCaption(), VendLedgEntry."Entry No.");
        CheckDtldVendLedgEntry(VendLedgEntry);

        OnAfterCheckVend(Vend, VendLedgEntry);
    end;

    local procedure CheckBankAcc(BankAccLedgEntry: Record "Bank Account Ledger Entry")
    var
        BankAcc: Record "Bank Account";
        CheckLedgEntry: Record "Check Ledger Entry";
    begin
        OnBeforeCheckBankAcc(BankAccLedgEntry);

        BankAcc.Get(BankAccLedgEntry."Bank Account No.");
        CheckPostingDate(
          BankAccLedgEntry."Posting Date", BankAccLedgEntry.TableCaption(), BankAccLedgEntry."Entry No.");
        BankAcc.TestField(Blocked, false);
        if BankAccLedgEntry.Reversed then
            AlreadyReversedEntry(BankAccLedgEntry.TableCaption(), BankAccLedgEntry."Entry No.");
        if not BankAccLedgEntry.Open then
            Error(
              Text006, BankAccLedgEntry.TableCaption(), BankAccLedgEntry."Entry No.");
        if BankAccLedgEntry."Statement No." <> '' then
            Error(
              Text007, BankAccLedgEntry.TableCaption(), BankAccLedgEntry."Entry No.");
        CheckLedgEntry.SetRange("Bank Account Ledger Entry No.", BankAccLedgEntry."Entry No.");
        if not CheckLedgEntry.IsEmpty() then
            Error(
              Text003, BankAccLedgEntry.TableCaption(), BankAccLedgEntry."Entry No.");

        OnAfterCheckBankAcc(BankAcc, BankAccLedgEntry);
    end;

    local procedure CheckFA(FALedgEntry: Record "FA Ledger Entry")
    var
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        DeprCalc: Codeunit "Depreciation Calculation";
    begin
        OnBeforeCheckFA(FALedgEntry);
        FA.Get(FALedgEntry."FA No.");
        CheckPostingDate(
          FALedgEntry."Posting Date", FALedgEntry.TableCaption(), FALedgEntry."Entry No.");
        CheckFAPostingDate(
          FALedgEntry."FA Posting Date", FALedgEntry.TableCaption(), FALedgEntry."Entry No.");
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        if FALedgEntry.Reversed then
            AlreadyReversedEntry(FALedgEntry.TableCaption(), FALedgEntry."Entry No.");
        FALedgEntry.TestField("Depreciation Book Code");
        FADeprBook.Get(FA."No.", FALedgEntry."Depreciation Book Code");
        if FADeprBook."Disposal Date" <> 0D then
            Error(Text008, DeprCalc.FAName(FA, FALedgEntry."Depreciation Book Code"));
        FALedgEntry.TestField("G/L Entry No.");
        FALedgEntry.CheckRealizedVAT(FALedgEntry."Entry No.");

        OnAfterCheckFA(FA, FALedgEntry);
    end;

    local procedure CheckMaintenance(MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    var
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
    begin
        OnBeforeCheckMaintenance(MaintenanceLedgEntry);
        FA.Get(MaintenanceLedgEntry."FA No.");
        CheckPostingDate(
          MaintenanceLedgEntry."Posting Date", MaintenanceLedgEntry.TableCaption(), MaintenanceLedgEntry."Entry No.");
        CheckFAPostingDate(
          MaintenanceLedgEntry."FA Posting Date", MaintenanceLedgEntry.TableCaption(), MaintenanceLedgEntry."Entry No.");
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        MaintenanceLedgEntry.TestField("Depreciation Book Code");
        if MaintenanceLedgEntry.Reversed then
            AlreadyReversedEntry(MaintenanceLedgEntry.TableCaption(), MaintenanceLedgEntry."Entry No.");
        FADeprBook.Get(FA."No.", MaintenanceLedgEntry."Depreciation Book Code");
        MaintenanceLedgEntry.TestField("G/L Entry No.");

        OnAfterCheckMaintenance(FA, MaintenanceLedgEntry);
    end;

    local procedure CheckVAT(VATEntry: Record "VAT Entry")
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        OnBeforeCheckVAT(VATEntry);

        CheckPostingDate(VATEntry."Posting Date", VATEntry.TableCaption(), VATEntry."Entry No.");
        if VATEntry.Closed then
            Error(
              Text006, VATEntry.TableCaption(), VATEntry."Entry No.");
        if VATEntry.Reversed then
            AlreadyReversedEntry(VATEntry.TableCaption(), VATEntry."Entry No.");
        if VATEntry."Unrealized VAT Entry No." <> 0 then
            if not VATEntry."Manual VAT Settlement" then
                Error(UnrealizedVATReverseError(VATEntry.TableCaption(), VATEntry."Entry No."));

        OnAfterCheckVAT(VATEntry);
    end;

    local procedure CheckDtldCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry")
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDtldCustLedgEntry(CustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DtldCustLedgEntry.SetFilter("Entry Type", '<>%1', DtldCustLedgEntry."Entry Type"::"Initial Entry");
        DtldCustLedgEntry.SetRange(Unapplied, false);
        if not DtldCustLedgEntry.IsEmpty() then
            Error(ReversalErrorForChangedEntry(CustLedgEntry.TableCaption(), CustLedgEntry."Entry No."));

        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Transaction No.", CustLedgEntry."Transaction No.");
        DtldCustLedgEntry.SetRange("Customer No.", CustLedgEntry."Customer No.");
        DtldCustLedgEntry.SetFilter("Entry Type", '%1|%2',
          DtldCustLedgEntry."Entry Type"::"Realized Gain", DtldCustLedgEntry."Entry Type"::"Realized Loss");
        if not DtldCustLedgEntry.IsEmpty() then
            Error(Text013, CustLedgEntry.TableCaption(), CustLedgEntry."Entry No.");

        OnAfterCheckDtldCustLedgEntry(DtldCustLedgEntry, CustLedgEntry);
    end;

    local procedure CheckDtldVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry")
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCCheckDtldVendLedgEntry(VendLedgEntry, IsHandled);
        if IsHandled then
            exit;

        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
        DtldVendLedgEntry.SetFilter("Entry Type", '<>%1', DtldVendLedgEntry."Entry Type"::"Initial Entry");
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if not DtldVendLedgEntry.IsEmpty() then
            Error(ReversalErrorForChangedEntry(VendLedgEntry.TableCaption(), VendLedgEntry."Entry No."));

        DtldVendLedgEntry.Reset();
        DtldVendLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Transaction No.", VendLedgEntry."Transaction No.");
        DtldVendLedgEntry.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
        DtldVendLedgEntry.SetFilter("Entry Type", '%1|%2',
          DtldVendLedgEntry."Entry Type"::"Realized Gain", DtldVendLedgEntry."Entry Type"::"Realized Loss");
        if not DtldVendLedgEntry.IsEmpty() then
            Error(Text013, VendLedgEntry.TableCaption(), VendLedgEntry."Entry No.");

        OnAfterCheckDtldVendLedgEntry(DtldVendLedgEntry, VendLedgEntry);
    end;

    local procedure CheckItem(ValueEntry: Record "Value Entry")
    var
        Item: Record Item;
    begin
        Item.Get(ValueEntry."Item No.");
        CheckPostingDate(ValueEntry."Posting Date", ValueEntry.TableCaption(), ValueEntry."Entry No.");
        Item.TestField(Blocked, false);
        if ValueEntry.Reversed then
            AlreadyReversedEntry(ValueEntry.TableCaption(), ValueEntry."Entry No.");
    end;

    local procedure CheckRegister(RegisterNo: Integer)
    var
        GLReg: Record "G/L Register";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRegister(RegisterNo, IsHandled, Rec);
        if IsHandled then
            exit;

        GLReg.Get(RegisterNo);
        if GLReg.Reversed then
            Error(Text010, GLReg.TableCaption(), GLReg."No.");
        VATEntry.SetRange("Entry No.", GLReg."From VAT Entry No.", GLReg."To VAT Entry No.");
        VATEntry.SetRange("VAT Allocation Type", VATEntry."VAT Allocation Type"::Charge);
        VATAllocOnCost := not VATEntry.IsEmpty();
        VATEntry.Reset();
        if (GLReg."Journal Batch Name" = '') and not VATAllocOnCost then
            TempReversalEntry.TestFieldError();
    end;

    procedure SetReverseFilter(Number: Integer; RevType: Option Transaction,Register)
    var
        FromTransactionNo: Integer;
        FromValueEntryNo: Integer;
        ToValueEntryNo: Integer;
    begin
        if RevType = RevType::Transaction then begin
            GLEntry.SetCurrentKey("Transaction No.");
            CustLedgEntry.SetCurrentKey("Transaction No.");
            VendLedgEntry.SetCurrentKey("Transaction No.");
            BankAccLedgEntry.SetCurrentKey("Transaction No.");
            FALedgEntry.SetCurrentKey("Transaction No.");
            MaintenanceLedgEntry.SetCurrentKey("Transaction No.");
            VATEntry.SetCurrentKey("Transaction No.");
            GLEntry.SetRange("Transaction No.", Number);
            CustLedgEntry.SetRange("Transaction No.", Number);
            VendLedgEntry.SetRange("Transaction No.", Number);
            BankAccLedgEntry.SetRange("Transaction No.", Number);
            FALedgEntry.SetRange("Transaction No.", Number);
            FALedgEntry.SetFilter("G/L Entry No.", '<>%1', 0);
            MaintenanceLedgEntry.SetRange("Transaction No.", Number);
            VATEntry.SetRange("Transaction No.", Number);
            TaxDiffLedgEntry.SetCurrentKey("Transaction No.");
            TaxDiffLedgEntry.SetRange("Transaction No.", Number);
            ValueEntry.SetRange("Entry No.", 0);
        end else begin
            GLReg.Get(Number);
            GLEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
            CustLedgEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
            VendLedgEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
            BankAccLedgEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
            FALedgEntry.SetCurrentKey("G/L Entry No.");
            FALedgEntry.SetRange("G/L Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
            MaintenanceLedgEntry.SetCurrentKey("G/L Entry No.");
            MaintenanceLedgEntry.SetRange("G/L Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
            VATEntry.SetRange("Entry No.", GLReg."From VAT Entry No.", GLReg."To VAT Entry No.");
            FromValueEntryNo := 0;
            ToValueEntryNo := 0;
            if VATAllocOnCost then begin
                GLItemLedgRelation.SetCurrentKey(GLItemLedgRelation."G/L Register No.");
                GLItemLedgRelation.SetRange("G/L Register No.", GLReg."No.");
                if GLItemLedgRelation.FindFirst() then
                    FromValueEntryNo := GLItemLedgRelation."Value Entry No.";
                if GLItemLedgRelation.FindLast() then
                    ToValueEntryNo := GLItemLedgRelation."Value Entry No.";
            end;
            ValueEntry.SetRange("Entry No.", FromValueEntryNo, ToValueEntryNo);
            TaxDiffLedgEntry.SetCurrentKey("Transaction No.");
            if not GLEntry.Find('-') then
                FromTransactionNo := GLEntry."Transaction No." + 1
            else begin
                FromTransactionNo := GLEntry."Transaction No.";
                GLEntry.Find('+')
            end;
            TaxDiffLedgEntry.SetRange("Transaction No.", FromTransactionNo, GLEntry."Transaction No.");
        end;

        OnAfterSetReverseFilter(Number, RevType, GLReg, Rec);
    end;

    procedure CopyReverseFilters(var GLEntry2: Record "G/L Entry"; var CustLedgEntry2: Record "Cust. Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var BankAccLedgEntry2: Record "Bank Account Ledger Entry"; var VATEntry2: Record "VAT Entry"; var FALedgEntry2: Record "FA Ledger Entry"; var MaintenanceLedgEntry2: Record "Maintenance Ledger Entry"; var TaxDiffLedgEntry2: Record "Tax Diff. Ledger Entry"; var ValueEntry2: Record "Value Entry")
    begin
        GLEntry2.Copy(GLEntry);
        CustLedgEntry2.Copy(CustLedgEntry);
        VendLedgEntry2.Copy(VendLedgEntry);
        BankAccLedgEntry2.Copy(BankAccLedgEntry);
        VATEntry2.Copy(VATEntry);
        FALedgEntry2.Copy(FALedgEntry);
        MaintenanceLedgEntry2.Copy(MaintenanceLedgEntry);
        TaxDiffLedgEntry2.Copy(TaxDiffLedgEntry);
        ValueEntry2.Copy(ValueEntry);
    end;

    procedure ShowGLEntries()
    begin
        PAGE.Run(0, GLEntry);
    end;

    procedure ShowCustLedgEntries()
    begin
        PAGE.Run(0, CustLedgEntry);
    end;

    procedure ShowVendLedgEntries()
    begin
        PAGE.Run(0, VendLedgEntry);
    end;

    procedure ShowBankAccLedgEntries()
    begin
        PAGE.Run(0, BankAccLedgEntry);
    end;

    procedure ShowFALedgEntries()
    begin
        PAGE.Run(0, FALedgEntry);
    end;

    procedure ShowMaintenanceLedgEntries()
    begin
        PAGE.Run(0, MaintenanceLedgEntry);
    end;

    procedure ShowVATEntries()
    begin
        PAGE.Run(0, VATEntry);
    end;

    [Scope('OnPrem')]
    procedure ShowValueEntries()
    begin
        PAGE.Run(0, ValueEntry);
    end;

    procedure Caption(): Text
    var
        GLAcc: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        Vend: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAcc: Record "Bank Account";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        FA: Record "Fixed Asset";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        VATEntry: Record "VAT Entry";
        TaxDiffLedgEntry: Record "Tax Diff. Ledger Entry";
        TaxDiff: Record "Tax Difference";
        NewCaption: Text;
    begin
        case "Entry Type" of
            "Entry Type"::"G/L Account":
                begin
                    if GLEntry.Get("Entry No.") then;
                    if GLAcc.Get(GLEntry."G/L Account No.") then;
                    exit(StrSubstNo('%1 %2 %3', GLAcc.TableCaption(), GLAcc."No.", GLAcc.Name));
                end;
            "Entry Type"::Customer:
                begin
                    if CustLedgEntry.Get("Entry No.") then;
                    if Cust.Get(CustLedgEntry."Customer No.") then;
                    exit(StrSubstNo('%1 %2 %3', Cust.TableCaption(), Cust."No.", Cust.Name));
                end;
            "Entry Type"::Vendor:
                begin
                    if VendLedgEntry.Get("Entry No.") then;
                    if Vend.Get(VendLedgEntry."Vendor No.") then;
                    exit(StrSubstNo('%1 %2 %3', Vend.TableCaption(), Vend."No.", Vend.Name));
                end;
            "Entry Type"::"Bank Account":
                begin
                    if BankAccLedgEntry.Get("Entry No.") then;
                    if BankAcc.Get(BankAccLedgEntry."Bank Account No.") then;
                    exit(StrSubstNo('%1 %2 %3', BankAcc.TableCaption(), BankAcc."No.", BankAcc.Name));
                end;
            "Entry Type"::"Fixed Asset":
                begin
                    if FALedgEntry.Get("Entry No.") then;
                    if FA.Get(FALedgEntry."FA No.") then;
                    exit(StrSubstNo('%1 %2 %3', FA.TableCaption(), FA."No.", FA.Description));
                end;
            "Entry Type"::Maintenance:
                begin
                    if MaintenanceLedgEntry.Get("Entry No.") then;
                    if FA.Get(MaintenanceLedgEntry."FA No.") then;
                    exit(StrSubstNo('%1 %2 %3', FA.TableCaption(), FA."No.", FA.Description));
                end;
            "Entry Type"::VAT:
                exit(StrSubstNo('%1', VATEntry.TableCaption));
            "Entry Type"::"Tax Difference":
                begin
                    if TaxDiffLedgEntry.Get("Entry No.") then;
                    if TaxDiff.Get(TaxDiffLedgEntry."Tax Diff. Code") then;
                    exit(StrSubstNo('%1 %2 %3', TaxDiff.TableCaption(), TaxDiff.Code, TaxDiff.Description));
                end;
            else begin
                    OnAfterCaption(Rec, NewCaption);
                    exit(NewCaption);
                end;
        end;
    end;

    local procedure CheckPostingDate(PostingDate: Date; Caption: Text[50]; EntryNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingDate(PostingDate, Caption, EntryNo, IsHandled, Rec);
        if IsHandled then
            exit;

        if "Corrected Period Date" <> 0D then
            PostingDate := "Posting Date";
        if GenJnlCheckLine.DateNotAllowed(PostingDate) then
            Error(Text001, Caption, EntryNo);
        if PostingDate > MaxPostingDate then
            MaxPostingDate := PostingDate;
    end;

    local procedure CheckFAPostingDate(FAPostingDate: Date; Caption: Text[50]; EntryNo: Integer)
    var
        UserSetup: Record "User Setup";
        FASetup: Record "FA Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFAPostingDate(FAPostingDate, Caption, EntryNo, IsHandled, Rec);
        if IsHandled then
            exit;

        if (AllowPostingFrom = 0D) and (AllowPostingto = 0D) then begin
            if UserId <> '' then
                if UserSetup.Get(UserId) then begin
                    AllowPostingFrom := UserSetup."Allow FA Posting From";
                    AllowPostingto := UserSetup."Allow FA Posting To";
                end;
            if (AllowPostingFrom = 0D) and (AllowPostingto = 0D) then begin
                FASetup.Get();
                AllowPostingFrom := FASetup."Allow FA Posting From";
                AllowPostingto := FASetup."Allow FA Posting To";
            end;
            if AllowPostingto = 0D then
                AllowPostingto := 99981231D;
        end;
        if (FAPostingDate < AllowPostingFrom) or (FAPostingDate > AllowPostingto) then
            Error(Text005, Caption, EntryNo, FALedgEntry.FieldCaption("FA Posting Date"));
        if FAPostingDate > MaxPostingDate then
            MaxPostingDate := FAPostingDate;
    end;

    procedure TestFieldError()
    begin
        Error(Text004);
    end;

    procedure AlreadyReversedEntry(Caption: Text[50]; EntryNo: Integer)
    begin
        Error(Text011, Caption, EntryNo);
    end;

    procedure VerifyReversalEntries(var ReversalEntry2: Record "Reversal Entry"; Number: Integer; RevType: Option Transaction,Register): Boolean
    begin
        InsertReversalEntry(Number, RevType);
        Clear(TempReversalEntry);
        Clear(ReversalEntry2);
        if ReversalEntry2.FindSet() then
            repeat
                if TempReversalEntry.Next() = 0 then
                    exit(false);
                if not TempReversalEntry.Equal(ReversalEntry2) then
                    exit(false);
            until ReversalEntry2.Next() = 0;
        exit(TempReversalEntry.Next() = 0);
    end;

    procedure Equal(ReversalEntry2: Record "Reversal Entry"): Boolean
    begin
        exit(
          ("Entry Type" = ReversalEntry2."Entry Type") and
          ("Entry No." = ReversalEntry2."Entry No."));
    end;

    procedure ReversalErrorForChangedEntry(TableName: Text[50]; EntryNo: Integer): Text[1024]
    begin
        exit(StrSubstNo(Text000, TableName, EntryNo));
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure CheckTaxDiff(TaxDiffLedgEntry: Record "Tax Diff. Ledger Entry")
    var
        TaxDiff: Record "Tax Difference";
        TaxDiffLedgEntry2: Record "Tax Diff. Ledger Entry";
    begin
        TaxDiff.Get(TaxDiffLedgEntry."Tax Diff. Code");
        CheckPostingDate(TaxDiffLedgEntry."Posting Date", TableCaption, TaxDiffLedgEntry."Entry No.");
        if TaxDiffLedgEntry.Reversed then
            AlreadyReversedEntry(TableCaption, TaxDiffLedgEntry."Entry No.");
        TaxDiffLedgEntry2.SetCurrentKey("Tax Diff. Code", "Source Type", "Source No.");
        TaxDiffLedgEntry2.SetRange("Tax Diff. Code", TaxDiffLedgEntry."Tax Diff. Code");
        TaxDiffLedgEntry2.SetRange("Source Type", TaxDiffLedgEntry."Source Type");
        TaxDiffLedgEntry2.SetRange("Source No.", TaxDiffLedgEntry."Source No.");
        TaxDiffLedgEntry2.SetFilter("Entry No.", '>%1', TaxDiffLedgEntry."Entry No.");
        TaxDiffLedgEntry2.SetRange(Reversed, false);
        if TaxDiffLedgEntry2.FindLast() then
            Error(CannotReverseTaxDiffEntryErr, TaxDiffLedgEntry."Entry No.", TaxDiffLedgEntry2."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure ShowTaxDiffEntries()
    begin
        PAGE.Run(0, TaxDiffLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure SetVATSettlReverseFilters(VATEntryNo: Integer; FirstGLEntryNo: Integer; LastGLEntryNo: Integer)
    begin
        VATEntry.SetRange("Entry No.", VATEntryNo);
        GLEntry.SetRange("Entry No.", FirstGLEntryNo, LastGLEntryNo);
        CustLedgEntry.SetRange("Entry No.", -1);
        VendLedgEntry.SetRange("Entry No.", -1);
        BankAccLedgEntry.SetRange("Entry No.", -1);
        FALedgEntry.SetCurrentKey("G/L Entry No.");
        FALedgEntry.SetRange("G/L Entry No.", -1);
        MaintenanceLedgEntry.SetCurrentKey("G/L Entry No.");
        MaintenanceLedgEntry.SetRange("G/L Entry No.", -1);
        TaxDiffLedgEntry.SetCurrentKey("Transaction No.");
        TaxDiffLedgEntry.SetRange("Transaction No.", -1);
    end;

    [Scope('OnPrem')]
    procedure VATAllocationExist(var VATEntry: Record "VAT Entry"): Boolean
    var
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.CopyFilters(VATEntry);
        VATEntry2.SetRange("VAT Allocation Type", VATEntry2."VAT Allocation Type"::Charge);
        exit(not VATEntry2.IsEmpty);
    end;

    procedure SetHideWarningDialogs()
    begin
        HideDialog := true;
        HideWarningDialogs := true;
    end;

    local procedure UnrealizedVATReverseError(TableName: Text[50]; EntryNo: Integer): Text
    begin
        exit(StrSubstNo(UnrealizedVATReverseErr, TableName, EntryNo));
    end;

    protected procedure InsertFromCustLedgEntry(var TempRevertTransactionNo: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        Cust: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");
        DtldCustLedgEntry.SetFilter(
          "Entry Type", '<>%1', DtldCustLedgEntry."Entry Type"::"Initial Entry");
        if CustLedgEntry.FindSet() then
            repeat
                DtldCustLedgEntry.SetRange("Transaction No.", CustLedgEntry."Transaction No.");
                DtldCustLedgEntry.SetRange("Customer No.", CustLedgEntry."Customer No.");
                if (not DtldCustLedgEntry.IsEmpty) and (RevType = RevType::Register) then
                    Error(PostedAndAppliedSameTransactionErr, Number);

                Clear(TempReversalEntry);
                if RevType = RevType::Register then
                    TempReversalEntry."G/L Register No." := Number;
                TempReversalEntry."Reversal Type" := RevType;
                TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::Customer;
                Cust.Get(CustLedgEntry."Customer No.");
                TempReversalEntry."Account No." := Cust."No.";
                TempReversalEntry."Account Name" := Cust.Name;
                TempReversalEntry.CopyFromCustLedgEntry(CustLedgEntry);
                TempReversalEntry."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                OnInsertFromCustLedgEntryOnBeforeTempReversalEntryInsert(TempReversalEntry, CustLedgEntry);
                TempReversalEntry.Insert();

                DtldCustLedgEntry.SetRange(Unapplied, true);
                if DtldCustLedgEntry.FindSet() then
                    repeat
                        InsertCustTempRevertTransNo(TempRevertTransactionNo, DtldCustLedgEntry."Unapplied by Entry No.");
                    until DtldCustLedgEntry.Next() = 0;
                DtldCustLedgEntry.SetRange(Unapplied);
            until CustLedgEntry.Next() = 0;

        OnAfterInsertFromCustLedgEntry(TempRevertTransactionNo, Number, RevType, NextLineNo, TempReversalEntry, CustLedgEntry);
    end;

    protected procedure InsertFromVendLedgEntry(var TempRevertTransactionNo: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        Vend: Record Vendor;
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
        DtldVendLedgEntry.SetFilter(
          "Entry Type", '<>%1', DtldVendLedgEntry."Entry Type"::"Initial Entry");
        if VendLedgEntry.FindSet() then
            repeat
                DtldVendLedgEntry.SetRange("Transaction No.", VendLedgEntry."Transaction No.");
                DtldVendLedgEntry.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
                if (not DtldVendLedgEntry.IsEmpty) and (RevType = RevType::Register) then
                    Error(PostedAndAppliedSameTransactionErr, Number);

                Clear(TempReversalEntry);
                if RevType = RevType::Register then
                    TempReversalEntry."G/L Register No." := Number;
                TempReversalEntry."Reversal Type" := RevType;
                TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::Vendor;
                Vend.Get(VendLedgEntry."Vendor No.");
                TempReversalEntry."Account No." := Vend."No.";
                TempReversalEntry."Account Name" := Vend.Name;
                TempReversalEntry.CopyFromVendLedgEntry(VendLedgEntry);
                TempReversalEntry."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                OnInsertFromVendLedgEntryOnBeforeTempReversalEntryInsert(TempReversalEntry, VendLedgEntry);
                TempReversalEntry.Insert();

                DtldVendLedgEntry.SetRange(Unapplied, true);
                if DtldVendLedgEntry.FindSet() then
                    repeat
                        InsertVendTempRevertTransNo(TempRevertTransactionNo, DtldVendLedgEntry."Unapplied by Entry No.");
                    until DtldVendLedgEntry.Next() = 0;
                DtldVendLedgEntry.SetRange(Unapplied);
            until VendLedgEntry.Next() = 0;

        OnAfterInsertFromVendLedgEntry(TempRevertTransactionNo, Number, RevType, NextLineNo, TempReversalEntry, VendLedgEntry);
    end;

    protected procedure InsertFromBankAccLedgEntry(TempRevertTransactionNo: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        BankAcc: Record "Bank Account";
    begin
        if BankAccLedgEntry.FindSet() then
            repeat
                Clear(TempReversalEntry);
                if RevType = RevType::Register then
                    TempReversalEntry."G/L Register No." := Number;
                TempReversalEntry."Reversal Type" := RevType;
                TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::"Bank Account";
                BankAcc.Get(BankAccLedgEntry."Bank Account No.");
                TempReversalEntry."Account No." := BankAcc."No.";
                TempReversalEntry."Account Name" := BankAcc.Name;
                TempReversalEntry.CopyFromBankAccLedgEntry(BankAccLedgEntry);
                TempReversalEntry."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                TempReversalEntry.Insert();
            until BankAccLedgEntry.Next() = 0;

        OnAfterInsertFromBankAccLedgEntry(TempRevertTransactionNo, Number, RevType, NextLineNo, TempReversalEntry, BankAccLedgEntry);
    end;

    protected procedure InsertFromFALedgEntry(TempRevertTransactionNo: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        FA: Record "Fixed Asset";
    begin
        if FALedgEntry.FindSet() then
            repeat
                Clear(TempReversalEntry);
                if RevType = RevType::Register then
                    TempReversalEntry."G/L Register No." := Number;
                TempReversalEntry."Reversal Type" := RevType;
                TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::"Fixed Asset";
                FA.Get(FALedgEntry."FA No.");
                TempReversalEntry."Account No." := FA."No.";
                TempReversalEntry."Account Name" := FA.Description;
                TempReversalEntry.CopyFromFALedgEntry(FALedgEntry);
                if FALedgEntry."FA Posting Type" <> FALedgEntry."FA Posting Type"::"Salvage Value" then begin
                    TempReversalEntry."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 1;
                    TempReversalEntry.Insert();
                end;
            until FALedgEntry.Next() = 0;

        OnAfterInsertFromFALedgEntry(TempRevertTransactionNo, Number, RevType, NextLineNo, TempReversalEntry, FALedgEntry);
    end;

    protected procedure InsertFromMaintenanceLedgEntry(TempRevertTransactionNo: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        FA: Record "Fixed Asset";
    begin
        if MaintenanceLedgEntry.FindSet() then
            repeat
                Clear(TempReversalEntry);
                if RevType = RevType::Register then
                    TempReversalEntry."G/L Register No." := Number;
                TempReversalEntry."Reversal Type" := RevType;
                TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::Maintenance;
                FA.Get(MaintenanceLedgEntry."FA No.");
                TempReversalEntry."Account No." := FA."No.";
                TempReversalEntry."Account Name" := FA.Description;
                TempReversalEntry.CopyFromMaintenanceEntry(MaintenanceLedgEntry);
                TempReversalEntry."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                TempReversalEntry.Insert();
            until MaintenanceLedgEntry.Next() = 0;

        OnAfterInsertFromMaintenanceLedgEntry(TempRevertTransactionNo, Number, RevType, NextLineNo, TempReversalEntry, MaintenanceLedgEntry);
    end;

    protected procedure InsertFromVATEntry(var TempRevertTransactionNo: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    begin
        TempRevertTransactionNo.FindSet();
        repeat
            if RevType = RevType::Transaction then
                VATEntry.SetRange("Transaction No.", TempRevertTransactionNo.Number);
            if VATEntry.FindSet() then
                repeat
                    Clear(TempReversalEntry);
                    if RevType = RevType::Register then
                        TempReversalEntry."G/L Register No." := Number;
                    TempReversalEntry."Reversal Type" := RevType;
                    TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::VAT;
                    TempReversalEntry.CopyFromVATEntry(VATEntry);
                    TempReversalEntry."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 1;
                    TempReversalEntry.Insert();
                until VATEntry.Next() = 0;
        until TempRevertTransactionNo.Next() = 0;

        OnAfterInsertFromVATEntry(TempRevertTransactionNo, Number, RevType, NextLineNo, TempReversalEntry, VATEntry);
    end;

    protected procedure InsertFromGLEntry(var TempRevertTransactionNo: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        GLAcc: Record "G/L Account";
    begin
        TempRevertTransactionNo.FindSet();
        repeat
            if RevType = RevType::Transaction then
                GLEntry.SetRange("Transaction No.", TempRevertTransactionNo.Number);
            if GLEntry.FindSet() then
                repeat
                    OnInsertFromGLEntryOnBeforeClearTempReversalEntry(GLEntry);
                    Clear(TempReversalEntry);
                    if RevType = RevType::Register then
                        TempReversalEntry."G/L Register No." := Number;
                    TempReversalEntry."Reversal Type" := RevType;
                    TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::"G/L Account";
                    if not GLAcc.Get(GLEntry."G/L Account No.") then
                        Error(CannotReverseDeletedErr, GLEntry.TableCaption(), GLAcc.TableCaption);
                    TempReversalEntry."Account No." := GLAcc."No.";
                    TempReversalEntry."Account Name" := GLAcc.Name;
                    TempReversalEntry.CopyFromGLEntry(GLEntry);
                    TempReversalEntry."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 1;
                    OnInsertFromGLEntryOnBeforeTempReversalEntryInsert(TempReversalEntry, GLEntry);
                    TempReversalEntry.Insert();
                until GLEntry.Next() = 0;
        until TempRevertTransactionNo.Next() = 0;

        OnAfterInsertFromGLEntry(TempRevertTransactionNo, Number, RevType, NextLineNo, TempReversalEntry, GLEntry);
    end;

    local procedure InsertFromTaxDiffEntry(var TempRevertTransactionNo: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        TaxDiff: Record "Tax Difference";
    begin
        TempRevertTransactionNo.FindSet();
        repeat
            if RevType = RevType::Transaction then
                TaxDiffLedgEntry.SetRange("Transaction No.", TempRevertTransactionNo.Number);
            if TaxDiffLedgEntry.FindSet() then
                repeat
                    Clear(TempReversalEntry);
                    if RevType = RevType::Register then
                        TempReversalEntry."G/L Register No." := Number;
                    TempReversalEntry."Reversal Type" := RevType;
                    TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::"Tax Difference";
                    if not TaxDiff.Get(TaxDiffLedgEntry."Tax Diff. Code") then
                        Error(CannotReverseDeletedErr, TaxDiffLedgEntry.TableCaption(), TaxDiff.TableCaption);
                    TempReversalEntry."Account No." := TaxDiff.Code;
                    TempReversalEntry."Account Name" := CopyStr(TaxDiff.Description, 1, MaxStrLen(TempReversalEntry."Account Name"));
                    TempReversalEntry.CopyFromTaxDiffEntry(TaxDiffLedgEntry);
                    TempReversalEntry."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 1;
                    TempReversalEntry.Insert();
                until TaxDiffLedgEntry.Next(1) = 0;
        until TempRevertTransactionNo.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InsertFromVATAllocation(Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        GLAcc: Record "G/L Account";
        Item: Record Item;
        FromValueEntryNo: Integer;
        ToValueEntryNo: Integer;
    begin
        FromValueEntryNo := 0;
        if TempGLReg.FindSet() then
            repeat
                GLEntry.SetRange("Entry No.", TempGLReg."From Entry No.", TempGLReg."To Entry No.");
                if GLEntry.FindSet() then
                    repeat
                        Clear(TempReversalEntry);
                        if RevType = RevType::Register then
                            TempReversalEntry."G/L Register No." := TempGLReg."No.";
                        TempReversalEntry."Reversal Type" := RevType;
                        TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::"G/L Account";
                        if not GLAcc.Get(GLEntry."G/L Account No.") then
                            Error(CannotReverseDeletedErr, GLEntry.TableCaption(), GLAcc.TableCaption());
                        TempReversalEntry."Account No." := GLAcc."No.";
                        TempReversalEntry."Account Name" := GLAcc.Name;
                        TempReversalEntry.CopyFromGLEntry(GLEntry);
                        TempReversalEntry."Line No." := NextLineNo;
                        TempReversalEntry."VAT Allocation" := VATAllocOnCost;
                        NextLineNo := NextLineNo + 1;
                        TempReversalEntry.Insert();

                        if GLEntry.Amount > 0 then begin
                            GLItemLedgRelation.Reset();
                            GLItemLedgRelation.SetRange("G/L Entry No.", GLEntry."Entry No.");
                            if GLItemLedgRelation.FindFirst() then begin
                                Clear(TempReversalEntry);
                                ValueEntry.Get(GLItemLedgRelation."Value Entry No.");
                                if FromValueEntryNo = 0 then
                                    FromValueEntryNo := ValueEntry."Entry No.";
                                ToValueEntryNo := ValueEntry."Entry No.";
                                if RevType = RevType::Register then
                                    TempReversalEntry."G/L Register No." := TempGLReg."No.";
                                TempReversalEntry."Reversal Type" := RevType;
                                TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::"Value Entry";
                                Item.Get(ValueEntry."Item No.");
                                TempReversalEntry."Account No." := Item."No.";
                                TempReversalEntry."Account Name" := Item.Description;
                                TempReversalEntry.CopyFromValueEntry(ValueEntry);
                                TempReversalEntry."Line No." := NextLineNo;
                                NextLineNo := NextLineNo + 1;
                                TempReversalEntry.Insert();
                            end;
                        end;
                    until GLEntry.Next() = 0;
            until TempGLReg.Next() = 0;
        ValueEntry.SetRange("Entry No.", FromValueEntryNo, ToValueEntryNo);
    end;

    procedure CopyFromCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        "Entry No." := CustLedgEntry."Entry No.";
        "Posting Date" := CustLedgEntry."Posting Date";
        "Source Code" := CustLedgEntry."Source Code";
        "Journal Batch Name" := CustLedgEntry."Journal Batch Name";
        "Transaction No." := CustLedgEntry."Transaction No.";
        "Currency Code" := CustLedgEntry."Currency Code";
        Description := CustLedgEntry.Description;
        CustLedgEntry.CalcFields(Amount, "Debit Amount", "Credit Amount",
          "Amount (LCY)", "Debit Amount (LCY)", "Credit Amount (LCY)");
        Amount := CustLedgEntry.Amount;
        "Debit Amount" := CustLedgEntry."Debit Amount";
        "Credit Amount" := CustLedgEntry."Credit Amount";
        "Amount (LCY)" := CustLedgEntry."Amount (LCY)";
        "Debit Amount (LCY)" := CustLedgEntry."Debit Amount (LCY)";
        "Credit Amount (LCY)" := CustLedgEntry."Credit Amount (LCY)";
        "Document Type" := CustLedgEntry."Document Type";
        "Document No." := CustLedgEntry."Document No.";
        "Bal. Account Type" := CustLedgEntry."Bal. Account Type";
        "Bal. Account No." := CustLedgEntry."Bal. Account No.";

        OnAfterCopyFromCustLedgEntry(Rec, CustLedgEntry);
    end;

    procedure CopyFromBankAccLedgEntry(BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
        "Entry No." := BankAccLedgEntry."Entry No.";
        "Posting Date" := BankAccLedgEntry."Posting Date";
        "Source Code" := BankAccLedgEntry."Source Code";
        "Journal Batch Name" := BankAccLedgEntry."Journal Batch Name";
        "Transaction No." := BankAccLedgEntry."Transaction No.";
        "Currency Code" := BankAccLedgEntry."Currency Code";
        Description := BankAccLedgEntry.Description;
        Amount := BankAccLedgEntry.Amount;
        "Debit Amount" := BankAccLedgEntry."Debit Amount";
        "Credit Amount" := BankAccLedgEntry."Credit Amount";
        "Amount (LCY)" := BankAccLedgEntry."Amount (LCY)";
        "Debit Amount (LCY)" := BankAccLedgEntry."Debit Amount (LCY)";
        "Credit Amount (LCY)" := BankAccLedgEntry."Credit Amount (LCY)";
        "Document Type" := BankAccLedgEntry."Document Type";
        "Document No." := BankAccLedgEntry."Document No.";
        "Bal. Account Type" := BankAccLedgEntry."Bal. Account Type";
        "Bal. Account No." := BankAccLedgEntry."Bal. Account No.";

        OnAfterCopyFromBankAccLedgEntry(Rec, BankAccLedgEntry);
    end;

    procedure CopyFromFALedgEntry(FALedgEntry: Record "FA Ledger Entry")
    begin
        "Entry No." := FALedgEntry."Entry No.";
        "Posting Date" := FALedgEntry."Posting Date";
        "FA Posting Category" := FALedgEntry."FA Posting Category";
        "FA Posting Type" := "Reversal Entry FA Posting Type".FromInteger(FALedgEntry."FA Posting Type".AsInteger() + 1);
        "Source Code" := FALedgEntry."Source Code";
        "Journal Batch Name" := FALedgEntry."Journal Batch Name";
        "Transaction No." := FALedgEntry."Transaction No.";
        Description := FALedgEntry.Description;
        "Amount (LCY)" := FALedgEntry.Amount;
        "Debit Amount (LCY)" := FALedgEntry."Debit Amount";
        "Credit Amount (LCY)" := FALedgEntry."Credit Amount";
        "VAT Amount" := FALedgEntry."VAT Amount";
        "Document Type" := FALedgEntry."Document Type";
        "Document No." := FALedgEntry."Document No.";
        "Bal. Account Type" := FALedgEntry."Bal. Account Type";
        "Bal. Account No." := FALedgEntry."Bal. Account No.";

        OnAfterCopyFromFALedgEntry(Rec, FALedgEntry);
    end;

    procedure CopyFromGLEntry(GLEntry: Record "G/L Entry")
    begin
        "Entry No." := GLEntry."Entry No.";
        "Posting Date" := GLEntry."Posting Date";
        "Source Code" := GLEntry."Source Code";
        "Journal Batch Name" := GLEntry."Journal Batch Name";
        "Transaction No." := GLEntry."Transaction No.";
        "Source Type" := GLEntry."Source Type";
        "Source No." := GLEntry."Source No.";
        Description := GLEntry.Description;
        "Amount (LCY)" := GLEntry.Amount;
        "Debit Amount (LCY)" := GLEntry."Debit Amount";
        "Credit Amount (LCY)" := GLEntry."Credit Amount";
        "VAT Amount" := GLEntry."VAT Amount";
        "Document Type" := GLEntry."Document Type";
        "Document No." := GLEntry."Document No.";
        "Bal. Account Type" := GLEntry."Bal. Account Type";
        "Bal. Account No." := GLEntry."Bal. Account No.";

        OnAfterCopyFromGLEntry(Rec, GLEntry);
    end;

    procedure CopyFromMaintenanceEntry(MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    begin
        "Entry No." := MaintenanceLedgEntry."Entry No.";
        "Posting Date" := MaintenanceLedgEntry."Posting Date";
        "Source Code" := MaintenanceLedgEntry."Source Code";
        "Journal Batch Name" := MaintenanceLedgEntry."Journal Batch Name";
        "Transaction No." := MaintenanceLedgEntry."Transaction No.";
        Description := MaintenanceLedgEntry.Description;
        "Amount (LCY)" := MaintenanceLedgEntry.Amount;
        "Debit Amount (LCY)" := MaintenanceLedgEntry."Debit Amount";
        "Credit Amount (LCY)" := MaintenanceLedgEntry."Credit Amount";
        "VAT Amount" := MaintenanceLedgEntry."VAT Amount";
        "Document Type" := MaintenanceLedgEntry."Document Type";
        "Document No." := MaintenanceLedgEntry."Document No.";
        "Bal. Account Type" := MaintenanceLedgEntry."Bal. Account Type";
        "Bal. Account No." := MaintenanceLedgEntry."Bal. Account No.";

        OnAfterCopyFromMaintenanceEntry(Rec, MaintenanceLedgEntry);
    end;

    procedure CopyFromVATEntry(VATEntry: Record "VAT Entry")
    begin
        "Entry No." := VATEntry."Entry No.";
        "Posting Date" := VATEntry."Posting Date";
        "Source Code" := VATEntry."Source Code";
        "Transaction No." := VATEntry."Transaction No.";
        Amount := VATEntry.Amount;
        "Amount (LCY)" := VATEntry.Amount;
        "Document Type" := VATEntry."Document Type";
        "Document No." := VATEntry."Document No.";

        OnAfterCopyFromVATEntry(Rec, VATEntry);
    end;

    procedure CopyFromVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        "Entry No." := VendLedgEntry."Entry No.";
        "Posting Date" := VendLedgEntry."Posting Date";
        "Source Code" := VendLedgEntry."Source Code";
        "Journal Batch Name" := VendLedgEntry."Journal Batch Name";
        "Transaction No." := VendLedgEntry."Transaction No.";
        "Currency Code" := VendLedgEntry."Currency Code";
        Description := VendLedgEntry.Description;
        VendLedgEntry.CalcFields(Amount, "Debit Amount", "Credit Amount",
          "Amount (LCY)", "Debit Amount (LCY)", "Credit Amount (LCY)");
        Amount := VendLedgEntry.Amount;
        "Debit Amount" := VendLedgEntry."Debit Amount";
        "Credit Amount" := VendLedgEntry."Credit Amount";
        "Amount (LCY)" := VendLedgEntry."Amount (LCY)";
        "Debit Amount (LCY)" := VendLedgEntry."Debit Amount (LCY)";
        "Credit Amount (LCY)" := VendLedgEntry."Credit Amount (LCY)";
        "Document Type" := VendLedgEntry."Document Type";
        "Document No." := VendLedgEntry."Document No.";
        "Bal. Account Type" := VendLedgEntry."Bal. Account Type";
        "Bal. Account No." := VendLedgEntry."Bal. Account No.";

        OnAfterCopyFromVendLedgEntry(Rec, VendLedgEntry);
    end;

    procedure CopyFromValueEntry(ValueEntry: Record "Value Entry")
    begin
        "Entry No." := ValueEntry."Entry No.";
        "Posting Date" := ValueEntry."Posting Date";
        "Source Code" := ValueEntry."Source Code";
        "Journal Batch Name" := ValueEntry."Journal Batch Name";
        "Transaction No." := GLEntry."Transaction No.";
        "Document Type" := GLEntry."Document Type";
        "Document No." := GLEntry."Document No.";
        Description := ValueEntry.Description;
        "Amount (LCY)" := ValueEntry."Cost Posted to G/L";
        if ("Amount (LCY)" > 0) xor ValueEntry."Red Storno" then
            "Debit Amount (LCY)" := "Amount (LCY)"
        else
            "Credit Amount (LCY)" := "Amount (LCY)";
    end;

    [Scope('OnPrem')]
    procedure CopyFromTaxDiffEntry(TaxDiffLedgEntry: Record "Tax Diff. Ledger Entry")
    begin
        "Entry No." := TaxDiffLedgEntry."Entry No.";
        "Posting Date" := TaxDiffLedgEntry."Posting Date";
        "Source Code" := TaxDiffLedgEntry."Source Code";
        "Journal Batch Name" := TaxDiffLedgEntry."Journal Batch Name";
        "Transaction No." := TaxDiffLedgEntry."Transaction No.";
        case TaxDiffLedgEntry."Source Type" of
            TaxDiffLedgEntry."Source Type"::"Future Expense":
                "Source Type" := "Source Type"::"Future Expense";
        end;
        "Source No." := TaxDiffLedgEntry."Source No.";
        Description := TaxDiffLedgEntry.Description;
        "Amount (LCY)" := TaxDiffLedgEntry."Tax Amount";
        "Debit Amount (LCY)" := TaxDiffLedgEntry."Asset Tax Amount";
        "Credit Amount (LCY)" := TaxDiffLedgEntry."Liability Tax Amount";
        "VAT Amount" := TaxDiffLedgEntry."Disposal Tax Amount";
        "Document No." := TaxDiffLedgEntry."Document No.";
    end;

    local procedure InsertCustTempRevertTransNo(var TempRevertTransactionNo: Record "Integer" temporary; CustLedgEntryNo: Integer)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.Get(CustLedgEntryNo);
        if DtldCustLedgEntry."Transaction No." <> 0 then begin
            TempRevertTransactionNo.Number := DtldCustLedgEntry."Transaction No.";
            if TempRevertTransactionNo.Insert then;
        end;
    end;

    local procedure InsertVendTempRevertTransNo(var TempRevertTransactionNo: Record "Integer" temporary; VendLedgEntryNo: Integer)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.Get(VendLedgEntryNo);
        if DtldVendLedgEntry."Transaction No." <> 0 then begin
            TempRevertTransactionNo.Number := DtldVendLedgEntry."Transaction No.";
            if TempRevertTransactionNo.Insert then;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCaption(ReversalEntry: Record "Reversal Entry"; var NewCaption: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckEntries(var MaxPostingDate: Date; var ReversalEntry: Record "Reversal Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBankAcc(BankAccount: Record "Bank Account"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGLAcc(var GLAccount: Record "G/L Account"; GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCust(Customer: Record Customer; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckVend(Vendor: Record Vendor; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFA(FixedAsset: Record "Fixed Asset"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckMaintenance(FixedAsset: Record "Fixed Asset"; MaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckVAT(var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDtldCustLedgEntry(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDtldVendLedgEntry(DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromBankAccLedgEntry(var ReversalEntry: Record "Reversal Entry"; BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromCustLedgEntry(var ReversalEntry: Record "Reversal Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromFALedgEntry(var ReversalEntry: Record "Reversal Entry"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromGLEntry(var ReversalEntry: Record "Reversal Entry"; GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromMaintenanceEntry(var ReversalEntry: Record "Reversal Entry"; MaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromVATEntry(var ReversalEntry: Record "Reversal Entry"; VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromVendLedgEntry(var ReversalEntry: Record "Reversal Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInsertFromBankAccLedgEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInsertFromCustLedgEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInsertFromFALedgEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInsertFromGLEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInsertFromMaintenanceLedgEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInsertReversalEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInsertFromVATEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInsertFromVendLedgEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverseEntries(Number: Integer; RevType: Integer; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReverseFilter(Number: Integer; RevType: Option Transaction,Register; GLRegister: Record "G/L Register"; var ReversalEntry: Record "Reversal Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEntries(ReversalEntry: Record "Reversal Entry"; TableID: Integer; var SkipCheck: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckFA(var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFAPostingDate(FAPostingDate: Date; Caption: Text[50]; EntryNo: Integer; var IsHandled: Boolean; var ReversalEntry: Record "Reversal Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckMaintenance(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckGLAcc(var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLEntry(var ReversalEntry: Record "Reversal Entry"; GLEntry: Record "G/L Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRegister(RegisterNo: Integer; var IsHandled: Boolean; var ReversalEntry: Record "Reversal Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReversalEntry(var ReversalEntry: Record "Reversal Entry"; Number: Integer; RevType: Option Transaction,Register; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReverseEntries(Number: Integer; RevType: Integer; var IsHandled: Boolean; HideDialog: Boolean; var ReversalEntry: Record "Reversal Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromCustLedgEntryOnBeforeTempReversalEntryInsert(var TempReversalEntry: Record "Reversal Entry" temporary; CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromGLEntryOnBeforeClearTempReversalEntry(GLEntry: Record "G/L Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromGLEntryOnBeforeTempReversalEntryInsert(var TempReversalEntry: Record "Reversal Entry" temporary; GLEntry: Record "G/L Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromVendLedgEntryOnBeforeTempReversalEntryInsert(var TempReversalEntry: Record "Reversal Entry" temporary; VendorLedgerEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckVAT(var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBankAcc(var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckVend(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckCust(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckGLAccOnBeforeTestFields(GLAcc: Record "G/L Account"; GLEntry: Record "G/L Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDate(PostingDate: Date; Caption: Text[50]; EntryNo: Integer; var IsHandled: Boolean; var ReversalEntry: Record "Reversal Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDtldCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCCheckDtldVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
}

