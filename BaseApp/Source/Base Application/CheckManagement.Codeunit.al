codeunit 367 CheckManagement
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rim,
                  TableData "Employee Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        GenJnlLine2: Record "Gen. Journal Line";
        BankAcc: Record "Bank Account";
        BankAccLedgEntry2: Record "Bank Account Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        VendorLedgEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        FALedgEntry: Record "FA Ledger Entry";
        BankAccLedgEntry3: Record "Bank Account Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        NextCheckEntryNo: Integer;
        AppliesIDCounter: Integer;

        CheckAlreadyExistsErr: Label 'Check %1 already exists for this %2.', Comment = '%1=The check number., %2=The Bank Account table name.';
        VoidingCheckMsg: Label 'Voiding check %1.', Comment = '%1=The check number being voided.';
        VoidingCheckErr: Label 'You cannot Financially Void checks posted in a non-balancing transaction.';
        PaymentOrRefundErr: Label '%1 must be either %2 or %3.', Comment = '%1=Document Type for the payment., %2=Payment Document Type., %3=Refund Document Type.';
        BankAccountTypeErr: Label 'Either the %1 or the %2 must refer to a Bank Account.', Comment = '%1=Account type., %2=Balancing Account type.';
        NoAppliedEntryErr: Label 'Cannot find an applied entry within the specified filter.';

    procedure InsertCheck(var CheckLedgEntry: Record "Check Ledger Entry"; RecordIdToPrint: RecordID)
    var
        CheckLedgEntry2: Record "Check Ledger Entry";
    begin
        CheckLedgEntry2.SetCurrentKey("Bank Account No.", "Entry Status", "Check No.");
        CheckLedgEntry2.SetRange("Bank Account No.", CheckLedgEntry."Bank Account No.");
        CheckLedgEntry2.SetFilter(
          "Entry Status", '%1|%2|%3',
          CheckLedgEntry2."Entry Status"::Printed,
          CheckLedgEntry2."Entry Status"::Posted,
          CheckLedgEntry2."Entry Status"::"Financially Voided");
        CheckLedgEntry2.SetRange("Check No.", CheckLedgEntry."Document No.");
        if CheckLedgEntry2.FindFirst() then
            Error(CheckAlreadyExistsErr, CheckLedgEntry."Document No.", BankAcc.TableCaption());

        if NextCheckEntryNo = 0 then begin
            CheckLedgEntry2.LockTable();
            CheckLedgEntry2.Reset();
            if CheckLedgEntry2.FindLast() then
                NextCheckEntryNo := CheckLedgEntry2."Entry No." + 1
            else
                NextCheckEntryNo := 1;
        end;

        CheckLedgEntry.Open := CheckLedgEntry.Amount <> 0;
        CheckLedgEntry."User ID" := UserId;
        CheckLedgEntry."Entry No." := NextCheckEntryNo;
        CheckLedgEntry."Record ID to Print" := RecordIdToPrint;
        OnInsertCheckOnBeforeCheckLedgEntryInsert(CheckLedgEntry);
        CheckLedgEntry.Insert();
        OnInsertCheckOnAfterCheckLedgEntryInsert(CheckLedgEntry);
        NextCheckEntryNo := NextCheckEntryNo + 1;
    end;

    procedure VoidCheck(var GenJnlLine: Record "Gen. Journal Line")
    var
        Currency: Record Currency;
        CheckLedgEntry2: Record "Check Ledger Entry";
        CheckAmountLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVoidCheck(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.TestField("Bank Payment Type", GenJnlLine2."Bank Payment Type"::"Computer Check");
        GenJnlLine.TestField("Check Printed", true);
        GenJnlLine.TestField("Document No.");

        if GenJnlLine."Bal. Account No." = '' then begin
            GenJnlLine."Check Printed" := false;
            GenJnlLine.Delete(true);
        end;

        CheckAmountLCY := GenJnlLine."Amount (LCY)";
        if GenJnlLine."Currency Code" <> '' then
            Currency.Get(GenJnlLine."Currency Code");

        GenJnlLine2.Reset();
        GenJnlLine2.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
        GenJnlLine2.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlLine2.SetRange("Posting Date", GenJnlLine."Posting Date");
        GenJnlLine2.SetRange("Document No.", GenJnlLine."Document No.");
        if GenJnlLine2.Find('-') then
            repeat
                if (GenJnlLine2."Line No." > GenJnlLine."Line No.") and
                   (CheckAmountLCY = -GenJnlLine2."Amount (LCY)") and
                   (GenJnlLine2."Currency Code" = '') and (GenJnlLine."Currency Code" <> '') and
                   (GenJnlLine2."Account Type" = GenJnlLine2."Account Type"::"G/L Account") and
                   (GenJnlLine2."Account No." in
                    [Currency."Conv. LCY Rndg. Debit Acc.", Currency."Conv. LCY Rndg. Credit Acc."]) and
                   (GenJnlLine2."Bal. Account No." = '') and not GenJnlLine2."Check Printed"
                then
                    GenJnlLine2.Delete() // Rounding correction line
                else begin
                    if GenJnlLine."Bal. Account No." = '' then begin
                        if GenJnlLine2."Account No." = '' then begin
                            GenJnlLine2."Account Type" := GenJnlLine2."Account Type"::"Bank Account";
                            GenJnlLine2."Account No." := GenJnlLine."Account No.";
                        end else begin
                            GenJnlLine2."Bal. Account Type" := GenJnlLine2."Account Type"::"Bank Account";
                            GenJnlLine2."Bal. Account No." := GenJnlLine."Account No.";
                        end;
                        GenJnlLine2.Validate(Amount);
                        GenJnlLine2."Bank Payment Type" := GenJnlLine."Bank Payment Type";
                    end;
                    GenJnlLine2."Document No." := '';
                    GenJnlLine2."Document Date" := 0D;
                    GenJnlLine2."Check Printed" := false;
                    GenJnlLine2.UpdateSource();
                    OnBeforeVoidCheckGenJnlLine2Modify(GenJnlLine2, GenJnlLine);
                    GenJnlLine2.Modify();
                    OnVoidCheckOnAfterGenJnlLine2Modify(GenJnlLine2, GenJnlLine);
                end;
            until GenJnlLine2.Next() = 0;

        CheckLedgEntry2.Reset();
        CheckLedgEntry2.SetCurrentKey("Bank Account No.", "Entry Status", "Check No.");
        if GenJnlLine.Amount <= 0 then
            CheckLedgEntry2.SetRange("Bank Account No.", GenJnlLine."Account No.")
        else
            CheckLedgEntry2.SetRange("Bank Account No.", GenJnlLine."Bal. Account No.");
        CheckLedgEntry2.SetRange("Entry Status", CheckLedgEntry2."Entry Status"::Printed);
        CheckLedgEntry2.SetRange("Check No.", GenJnlLine."Document No.");
        OnVoidCheckOnAfterCheckLedgEntry2SetFilters(CheckLedgEntry2);
        CheckLedgEntry2.FindFirst();
        CheckLedgEntry2."Original Entry Status" := CheckLedgEntry2."Entry Status";
        CheckLedgEntry2."Entry Status" := CheckLedgEntry2."Entry Status"::Voided;
        CheckLedgEntry2."Positive Pay Exported" := false;
        CheckLedgEntry2.Open := false;
        CheckLedgEntry2.Modify();

        OnAfterVoidCheck(GenJnlLine, CheckLedgEntry2);
    end;

    procedure FinancialVoidCheck(var CheckLedgEntry: Record "Check Ledger Entry")
    var
        ConfirmFinancialVoid: Page "Confirm Financial Void";
        AmountToVoid: Decimal;
        CheckAmountLCY: Decimal;
        BalanceAmountLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinancialVoidCheck(CheckLedgEntry, IsHandled);
        if IsHandled then
            exit;

        FinancialVoidCheckPreValidation(CheckLedgEntry);

        Clear(ConfirmFinancialVoid);
        ConfirmFinancialVoid.SetCheckLedgerEntry(CheckLedgEntry);
        if ConfirmFinancialVoid.RunModal() <> ACTION::Yes then
            exit;

        AmountToVoid := CalcAmountToVoid(CheckLedgEntry);

        InitGenJnlLine(
          GenJnlLine2, CheckLedgEntry."Document No.", ConfirmFinancialVoid.GetVoidDate(),
          GenJnlLine2."Account Type"::"Bank Account", CheckLedgEntry."Bank Account No.",
          StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No."));
        GenJnlLine2.Validate(Amount, AmountToVoid);
        CheckAmountLCY := GenJnlLine2."Amount (LCY)";
        BalanceAmountLCY := 0;
        GenJnlLine2."Shortcut Dimension 1 Code" := BankAccLedgEntry2."Global Dimension 1 Code";
        GenJnlLine2."Shortcut Dimension 2 Code" := BankAccLedgEntry2."Global Dimension 2 Code";
        GenJnlLine2."Dimension Set ID" := BankAccLedgEntry2."Dimension Set ID";
        GenJnlLine2."Allow Zero-Amount Posting" := true;
        GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
        GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
        OnFinancialVoidCheckOnBeforePostVoidCheckLine(GenJnlLine2, CheckLedgEntry, BankAccLedgEntry2);
        GenJnlPostLine.RunWithCheck(GenJnlLine2);
        OnFinancialVoidCheckOnAfterPostVoidCheckLine(GenJnlLine2, GenJnlPostLine);

        // Mark newly posted entry as cleared for bank reconciliation purposes.
        if ConfirmFinancialVoid.GetVoidDate() = CheckLedgEntry."Check Date" then
            ClearBankLedgerEntry(BankAccLedgEntry3);

        InitGenJnlLine(
          GenJnlLine2, CheckLedgEntry."Document No.", ConfirmFinancialVoid.GetVoidDate(),
          CheckLedgEntry."Bal. Account Type", CheckLedgEntry."Bal. Account No.",
          StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No."));
        GenJnlLine2.Validate("Currency Code", BankAcc."Currency Code");
        GenJnlLine2."Allow Zero-Amount Posting" := true;
        OnFinancialVoidCheckOnBeforeCheckBalAccountType(GenJnlLine2, CheckLedgEntry, BankAccLedgEntry3);
        case CheckLedgEntry."Bal. Account Type" of
            CheckLedgEntry."Bal. Account Type"::"G/L Account":
                FinancialVoidPostGLAccount(GenJnlLine2, BankAccLedgEntry2, CheckLedgEntry, BalanceAmountLCY);
            CheckLedgEntry."Bal. Account Type"::Customer:
                begin
                    if ConfirmFinancialVoid.GetVoidType() = 0 then   // Unapply entry
                        if UnApplyCustInvoices(CheckLedgEntry, ConfirmFinancialVoid.GetVoidDate()) then
                            GenJnlLine2."Applies-to ID" := CheckLedgEntry."Document No.";
                    with CustLedgEntry do begin
                        SetCurrentKey("Transaction No.");
                        SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
                        SetRange("Document No.", BankAccLedgEntry2."Document No.");
                        SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
                        if FindSet() then
                            repeat
                                OnFinancialVoidCheckOnBeforePostCust(GenJnlLine2, CustLedgEntry, BalanceAmountLCY);
                                CalcFields("Original Amount");
                                SetGenJnlLine(
                                  GenJnlLine2, -"Original Amount", "Currency Code", CheckLedgEntry."Document No.",
                                  "Global Dimension 1 Code", "Global Dimension 2 Code", "Dimension Set ID");
                                BalanceAmountLCY := BalanceAmountLCY + GenJnlLine2."Amount (LCY)";
                                GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                                GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                                OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine2, CheckLedgEntry);
                                GenJnlPostLine.RunWithCheck(GenJnlLine2);
                                OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
                            until Next() = 0;
                    end;
                end;
            CheckLedgEntry."Bal. Account Type"::Vendor:
                begin
                    if ConfirmFinancialVoid.GetVoidType() = 0 then // Unapply entry
                        if UnApplyVendInvoices(CheckLedgEntry, ConfirmFinancialVoid.GetVoidDate()) then
                            GenJnlLine2."Applies-to ID" := CheckLedgEntry."Document No.";
                    with VendorLedgEntry do begin
                        SetCurrentKey("Transaction No.");
                        SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
                        SetRange("Document No.", BankAccLedgEntry2."Document No.");
                        SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
                        OnFinancialVoidCheckOnAfterVendorLedgEntrySetFilters(VendorLedgEntry, BankAccLedgEntry2);
                        if FindSet() then
                            repeat
                                OnFinancialVoidCheckOnBeforePostVend(GenJnlLine2, VendorLedgEntry, BalanceAmountLCY);
                                CalcFields("Original Amount");
                                SetGenJnlLine(
                                  GenJnlLine2, -"Original Amount", "Currency Code", CheckLedgEntry."Document No.",
                                  "Global Dimension 1 Code", "Global Dimension 2 Code", "Dimension Set ID");
                                BalanceAmountLCY := BalanceAmountLCY + GenJnlLine2."Amount (LCY)";
                                GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                                GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                                OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine2, CheckLedgEntry);
                                GenJnlPostLine.RunWithCheck(GenJnlLine2);
                                OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
                            until Next() = 0;
                    end;
                end;
            CheckLedgEntry."Bal. Account Type"::"Bank Account":
                with BankAccLedgEntry3 do begin
                    SetCurrentKey("Transaction No.");
                    SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
                    SetRange("Document No.", BankAccLedgEntry2."Document No.");
                    SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
                    SetFilter("Entry No.", '<>%1', BankAccLedgEntry2."Entry No.");
                    if FindSet() then
                        repeat
                            OnFinancialVoidCheckOnBeforePostBankAccount(GenJnlLine2, BankAccLedgEntry3);
                            GenJnlLine2.Validate(Amount, -Amount);
                            BalanceAmountLCY := BalanceAmountLCY + GenJnlLine2."Amount (LCY)";
                            GenJnlLine2."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
                            GenJnlLine2."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
                            GenJnlLine2."Dimension Set ID" := "Dimension Set ID";
                            GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                            GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                            OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine2, CheckLedgEntry);
                            GenJnlPostLine.RunWithCheck(GenJnlLine2);
                            OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
                        until Next() = 0;
                end;
            CheckLedgEntry."Bal. Account Type"::"Fixed Asset":
                with FALedgEntry do begin
                    SetCurrentKey("Transaction No.");
                    SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
                    SetRange("Document No.", BankAccLedgEntry2."Document No.");
                    SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
                    if FindSet() then
                        repeat
                            OnFinancialVoidCheckOnBeforePostFixedAsset(GenJnlLine2, FALedgEntry);
                            GenJnlLine2.Validate(Amount, -Amount);
                            BalanceAmountLCY := BalanceAmountLCY + GenJnlLine2."Amount (LCY)";
                            GenJnlLine2."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
                            GenJnlLine2."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
                            GenJnlLine2."Dimension Set ID" := "Dimension Set ID";
                            GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                            GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                            OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine2, CheckLedgEntry);
                            GenJnlPostLine.RunWithCheck(GenJnlLine2);
                            OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
                        until Next() = 0;
                end;
            CheckLedgEntry."Bal. Account Type"::Employee:
                begin
                    if ConfirmFinancialVoid.GetVoidType() = 0 then // Unapply entry
                        if UnApplyEmpInvoices(CheckLedgEntry, ConfirmFinancialVoid.GetVoidDate()) then
                            GenJnlLine2."Applies-to ID" := CheckLedgEntry."Document No.";
                    with EmployeeLedgerEntry do begin
                        SetCurrentKey("Transaction No.");
                        SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
                        SetRange("Document No.", BankAccLedgEntry2."Document No.");
                        SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
                        if FindSet() then
                            repeat
                                OnFinancialVoidCheckOnBeforePostEmp(GenJnlLine2, EmployeeLedgerEntry);
                                CalcFields("Original Amount");
                                SetGenJnlLine(
                                  GenJnlLine2, -"Original Amount", "Currency Code", CheckLedgEntry."Document No.",
                                  "Global Dimension 1 Code", "Global Dimension 2 Code", "Dimension Set ID");
                                BalanceAmountLCY := BalanceAmountLCY + GenJnlLine2."Amount (LCY)";
                                OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine2, CheckLedgEntry);
                                GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                                GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                                GenJnlPostLine.RunWithCheck(GenJnlLine2);
                                OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
                            until Next() = 0;
                    end;
                end;
            else begin
                    GenJnlLine2."Bal. Account Type" := CheckLedgEntry."Bal. Account Type";
                    GenJnlLine2.Validate("Bal. Account No.", CheckLedgEntry."Bal. Account No.");
                    GenJnlLine2."Shortcut Dimension 1 Code" := '';
                    GenJnlLine2."Shortcut Dimension 2 Code" := '';
                    GenJnlLine2."Dimension Set ID" := 0;
                    GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                    GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                    OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine2, CheckLedgEntry);
                    GenJnlPostLine.RunWithCheck(GenJnlLine2);
                    OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
                end;
        end;

        if ConfirmFinancialVoid.GetVoidDate() = CheckLedgEntry."Check Date" then begin
            BankAccLedgEntry2.Open := false;
            BankAccLedgEntry2."Remaining Amount" := 0;
            BankAccLedgEntry2."Statement Status" := BankAccLedgEntry2."Statement Status"::Closed;
            BankAccLedgEntry2.Modify();
        end;

        // rounding error from currency conversion
        if CheckAmountLCY + BalanceAmountLCY <> 0 then
            PostRoundingAmount(BankAcc, CheckLedgEntry, ConfirmFinancialVoid.GetVoidDate(), -(CheckAmountLCY + BalanceAmountLCY));

        MarkCheckEntriesVoid(CheckLedgEntry, ConfirmFinancialVoid.GetVoidDate());
        Commit();
        UpdateAnalysisView.UpdateAll(0, true);

        OnAfterFinancialVoidCheck(CheckLedgEntry);
    end;

    local procedure FinancialVoidPostGLAccount(var GenJnlLine: Record "Gen. Journal Line"; BankAccLedgEntry2: Record "Bank Account Ledger Entry"; CheckLedgEntry: Record "Check Ledger Entry"; var BalanceAmountLCY: Decimal)
    var
        GLEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with GLEntry do begin
            SetCurrentKey("Transaction No.");
            SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
            SetRange("Document No.", BankAccLedgEntry2."Document No.");
            SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
            SetFilter("Entry No.", '<>%1', BankAccLedgEntry2."Entry No.");
            SetRange("G/L Account No.", CheckLedgEntry."Bal. Account No.");
            if FindSet() then
                repeat
                    OnFinancialVoidPostGLAccountOnBeforeGLEntryLoop(GLEntry, CheckLedgEntry);
                    GenJnlLine.Validate("Account No.", "G/L Account No.");
                    GenJnlLine.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
                    GenJnlLine.Validate(Amount, -Amount - "VAT Amount");
                    BalanceAmountLCY := BalanceAmountLCY + GenJnlLine."Amount (LCY)";
                    GenJnlLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
                    GenJnlLine."Dimension Set ID" := "Dimension Set ID";
                    GenJnlLine."Gen. Posting Type" := "Gen. Posting Type";
                    GenJnlLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
                    GenJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
                    GenJnlLine."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
                    GenJnlLine."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
                    if VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                        GenJnlLine."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                    GenJnlLine."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                    GenJnlLine."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                    OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine, CheckLedgEntry);
                    GenJnlPostLine.RunWithCheck(GenJnlLine);
                    OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine, CheckLedgEntry, GenJnlPostLine);
                until Next() = 0;
        end;
    end;

    local procedure UnApplyVendInvoices(var CheckLedgEntry: Record "Check Ledger Entry"; VoidDate: Date): Boolean
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        OrigPaymentVendorLedgerEntry: Record "Vendor Ledger Entry";
        PayDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine3: Record "Gen. Journal Line";
        AppliesID: Code[50];
    begin
        // first, find first original payment line, if any
        BankAccountLedgerEntry.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
        if CheckLedgEntry."Bal. Account Type" = CheckLedgEntry."Bal. Account Type"::Vendor then
            with OrigPaymentVendorLedgerEntry do begin
                SetCurrentKey("Transaction No.");
                SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
                SetRange("Document No.", BankAccountLedgerEntry."Document No.");
                SetRange("Posting Date", BankAccountLedgerEntry."Posting Date");
                if not FindFirst() then
                    exit(false);
            end
        else
            exit(false);

        AppliesID := CheckLedgEntry."Document No.";

        PayDetailedVendorLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        PayDetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", OrigPaymentVendorLedgerEntry."Entry No.");
        PayDetailedVendorLedgEntry.SetRange(Unapplied, false);
        PayDetailedVendorLedgEntry.SetFilter("Applied Vend. Ledger Entry No.", '<>%1', 0);
        PayDetailedVendorLedgEntry.SetRange("Entry Type", PayDetailedVendorLedgEntry."Entry Type"::Application);
        if not PayDetailedVendorLedgEntry.FindSet() then
            Error(NoAppliedEntryErr);
        repeat
            GenJournalLine3.CopyFromPaymentVendLedgEntry(OrigPaymentVendorLedgerEntry);
            GenJournalLine3."Posting Date" := VoidDate;
            GenJournalLine3.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
            GenJournalLine3."Source Code" := SourceCodeSetup."Financially Voided Check";
            OnUnApplyVendInvoicesOnBeforePost(GenJournalLine3, VendorLedgEntry, PayDetailedVendorLedgEntry);
            GenJnlPostLine.UnapplyVendLedgEntry(GenJournalLine3, PayDetailedVendorLedgEntry);
        until PayDetailedVendorLedgEntry.Next() = 0;

        with OrigPaymentVendorLedgerEntry do begin
            FindSet(true, false);  // re-get the now-modified payment entry.
            repeat                // set up to be applied by upcoming voiding entry.
                MakeAppliesID(AppliesID, CheckLedgEntry."Document No.");
                "Applies-to ID" := AppliesID;
                CalcFields("Remaining Amount");
                "Amount to Apply" := "Remaining Amount";
                "Accepted Pmt. Disc. Tolerance" := false;
                "Accepted Payment Tolerance" := 0;
                Modify();
            until Next() = 0;
        end;
        exit(true);
    end;

    local procedure UnApplyCustInvoices(var CheckLedgEntry: Record "Check Ledger Entry"; VoidDate: Date): Boolean
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        OrigPaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        PayDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine3: Record "Gen. Journal Line";
        AppliesID: Code[50];
    begin
        // first, find first original payment line, if any
        BankAccountLedgerEntry.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
        if CheckLedgEntry."Bal. Account Type" = CheckLedgEntry."Bal. Account Type"::Customer then
            with OrigPaymentCustLedgerEntry do begin
                SetCurrentKey("Transaction No.");
                SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
                SetRange("Document No.", BankAccountLedgerEntry."Document No.");
                SetRange("Posting Date", BankAccountLedgerEntry."Posting Date");
                if not FindFirst() then
                    exit(false);
            end
        else
            exit(false);

        AppliesID := CheckLedgEntry."Document No.";

        PayDetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        PayDetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", OrigPaymentCustLedgerEntry."Entry No.");
        PayDetailedCustLedgEntry.SetRange(Unapplied, false);
        PayDetailedCustLedgEntry.SetFilter("Applied Cust. Ledger Entry No.", '<>%1', 0);
        PayDetailedCustLedgEntry.SetRange("Entry Type", PayDetailedCustLedgEntry."Entry Type"::Application);
        if not PayDetailedCustLedgEntry.FindSet() then
            Error(NoAppliedEntryErr);
        repeat
            GenJournalLine3.CopyFromPaymentCustLedgEntry(OrigPaymentCustLedgerEntry);
            GenJournalLine3."Posting Date" := VoidDate;
            GenJournalLine3.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
            GenJournalLine3."Source Code" := SourceCodeSetup."Financially Voided Check";
            OnUnApplyCustInvoicesOnBeforePost(GenJournalLine3, CustLedgEntry, PayDetailedCustLedgEntry);
            GenJnlPostLine.UnapplyCustLedgEntry(GenJournalLine3, PayDetailedCustLedgEntry);
        until PayDetailedCustLedgEntry.Next() = 0;

        with OrigPaymentCustLedgerEntry do begin
            FindSet(true, false);  // re-get the now-modified payment entry.
            repeat                // set up to be applied by upcoming voiding entry.
                MakeAppliesID(AppliesID, CheckLedgEntry."Document No.");
                "Applies-to ID" := AppliesID;
                CalcFields("Remaining Amount");
                "Amount to Apply" := "Remaining Amount";
                "Accepted Pmt. Disc. Tolerance" := false;
                "Accepted Payment Tolerance" := 0;
                Modify();
            until Next() = 0;
        end;
        exit(true);
    end;

    local procedure UnApplyEmpInvoices(var CheckLedgEntry: Record "Check Ledger Entry"; VoidDate: Date): Boolean
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        OrigPaymentEmployeeLedgerEntry: Record "Employee Ledger Entry";
        PayDetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        GenJournalLine3: Record "Gen. Journal Line";
        AppliesID: Code[50];
    begin
        // first, find first original payment line, if any
        BankAccountLedgerEntry.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
        if CheckLedgEntry."Bal. Account Type" <> CheckLedgEntry."Bal. Account Type"::Employee then
            exit(false);

        with OrigPaymentEmployeeLedgerEntry do begin
            SetCurrentKey("Transaction No.");
            SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
            SetRange("Document No.", BankAccountLedgerEntry."Document No.");
            SetRange("Posting Date", BankAccountLedgerEntry."Posting Date");
            if not FindFirst() then
                exit(false);
        end;

        AppliesID := CheckLedgEntry."Document No.";

        PayDetailedEmployeeLedgEntry.SetCurrentKey("Employee Ledger Entry No.", "Entry Type", "Posting Date");
        PayDetailedEmployeeLedgEntry.SetRange("Employee Ledger Entry No.", OrigPaymentEmployeeLedgerEntry."Entry No.");
        PayDetailedEmployeeLedgEntry.SetRange(Unapplied, false);
        PayDetailedEmployeeLedgEntry.SetFilter("Applied Empl. Ledger Entry No.", '<>%1', 0);
        PayDetailedEmployeeLedgEntry.SetRange("Entry Type", PayDetailedEmployeeLedgEntry."Entry Type"::Application);
        if not PayDetailedEmployeeLedgEntry.FindSet() then
            Error(NoAppliedEntryErr);
        repeat
            GenJournalLine3.CopyFromPaymentEmpLedgEntry(OrigPaymentEmployeeLedgerEntry);
            GenJournalLine3."Posting Date" := VoidDate;
            GenJournalLine3.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
            GenJournalLine3."Source Code" := SourceCodeSetup."Financially Voided Check";
            GenJnlPostLine.UnapplyEmplLedgEntry(GenJournalLine3, PayDetailedEmployeeLedgEntry);
        until PayDetailedEmployeeLedgEntry.Next() = 0;

        with OrigPaymentEmployeeLedgerEntry do begin
            FindSet(true, false);  // re-get the now-modified payment entry.
            repeat                // set up to be applied by upcoming voiding entry.
                MakeAppliesID(AppliesID, CheckLedgEntry."Document No.");
                "Applies-to ID" := AppliesID;
                CalcFields("Remaining Amount");
                "Amount to Apply" := "Remaining Amount";
                Modify();
            until Next() = 0;
        end;
        exit(true);
    end;

    local procedure MarkCheckEntriesVoid(var OriginalCheckLedgerEntry: Record "Check Ledger Entry"; VoidDate: Date)
    var
        RelatedCheckLedgerEntry: Record "Check Ledger Entry";
        RelatedCheckLedgerEntry2: Record "Check Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMarkCheckEntriesVoid(OriginalCheckLedgerEntry, VoidDate, IsHandled);
        if IsHandled then
            exit;

        with RelatedCheckLedgerEntry do begin
            Reset();
            SetCurrentKey("Bank Account No.", "Entry Status", "Check No.");
            SetRange("Bank Account No.", OriginalCheckLedgerEntry."Bank Account No.");
            SetRange("Entry Status", OriginalCheckLedgerEntry."Entry Status"::Posted);
            SetRange("Statement Status", OriginalCheckLedgerEntry."Statement Status"::Open);
            SetRange("Check No.", OriginalCheckLedgerEntry."Check No.");
            SetRange("Check Date", OriginalCheckLedgerEntry."Check Date");
            SetFilter("Entry No.", '<>%1', OriginalCheckLedgerEntry."Entry No.");
            if FindSet() then
                repeat
                    RelatedCheckLedgerEntry2 := RelatedCheckLedgerEntry;
                    RelatedCheckLedgerEntry2."Original Entry Status" := "Entry Status";
                    RelatedCheckLedgerEntry2."Entry Status" := "Entry Status"::"Financially Voided";
                    RelatedCheckLedgerEntry2."Positive Pay Exported" := false;
                    if VoidDate = OriginalCheckLedgerEntry."Check Date" then begin
                        RelatedCheckLedgerEntry2.Open := false;
                        RelatedCheckLedgerEntry2."Statement Status" := RelatedCheckLedgerEntry2."Statement Status"::Closed;
                    end;
                    OnMarkCheckEntriesVoidOnBeforeRelatedCheckLedgerEntry2Modify(RelatedCheckLedgerEntry2, VoidDate);
                    RelatedCheckLedgerEntry2.Modify();
                until Next() = 0;
        end;

        with OriginalCheckLedgerEntry do begin
            "Original Entry Status" := "Entry Status";
            "Entry Status" := "Entry Status"::"Financially Voided";
            "Positive Pay Exported" := false;
            if VoidDate = "Check Date" then begin
                Open := false;
                "Statement Status" := "Statement Status"::Closed;
            end;
            OnMarkCheckEntriesVoidOnBeforeOriginalCheckLedgerEntryModify(OriginalCheckLedgerEntry, VoidDate);
            Modify();
        end;
    end;

    local procedure MakeAppliesID(var AppliesID: Code[50]; CheckDocNo: Code[20])
    begin
        if AppliesID = '' then
            exit;
        if AppliesID = CheckDocNo then
            AppliesIDCounter := 0;
        AppliesIDCounter := AppliesIDCounter + 1;
        AppliesID :=
          CopyStr(Format(AppliesIDCounter) + CheckDocNo, 1, MaxStrLen(AppliesID));
    end;

    local procedure CalcAmountToVoid(CheckLedgEntry: Record "Check Ledger Entry") AmountToVoid: Decimal
    var
        CheckLedgEntry2: Record "Check Ledger Entry";
    begin
        with CheckLedgEntry2 do begin
            Reset();
            SetRange("Bank Account No.", CheckLedgEntry."Bank Account No.");
            SetRange("Entry Status", CheckLedgEntry."Entry Status"::Posted);
            SetRange("Statement Status", CheckLedgEntry."Statement Status"::Open);
            SetRange("Check No.", CheckLedgEntry."Check No.");
            SetRange("Check Date", CheckLedgEntry."Check Date");
            CalcSums(Amount);
            AmountToVoid := Amount;
        end;

        OnAfterCalcAmountToVoid(CheckLedgEntry, AmountToVoid);
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Description: Text[50])
    begin
        GenJnlLine.Init();
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Financial Void" := true;
        GenJnlLine."Document No." := DocumentNo;
        GenJnlLine."Account Type" := AccountType;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine.Validate("Account No.", AccountNo);
        GenJnlLine.Description := Description;
        GenJnlLine."Source Code" := SourceCodeSetup."Financially Voided Check";
    end;

    local procedure SetGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; OriginalAmount: Decimal; CurrencyCode: Code[10]; DocumentNo: Code[20]; Dim1Code: Code[20]; Dim2Code: Code[20]; DimSetID: Integer)
    begin
        GenJnlLine.Validate(Amount, OriginalAmount);
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        MakeAppliesID(GenJnlLine."Applies-to ID", DocumentNo);
        GenJnlLine."Shortcut Dimension 1 Code" := Dim1Code;
        GenJnlLine."Shortcut Dimension 2 Code" := Dim2Code;
        GenJnlLine."Dimension Set ID" := DimSetID;
        GenJnlLine."Source Currency Code" := CurrencyCode;
    end;

    local procedure IsElectronicBankPaymentType(BankPaymentType: Enum "Bank Payment Type") IsElectronicPaymentType: Boolean
    begin
        IsElectronicPaymentType := BankPaymentType in [BankPaymentType::"Electronic Payment", BankPaymentType::"Electronic Payment-IAT"];

        OnAfterIsElectronicBankPaymentType(BankPaymentType, IsElectronicPaymentType);
    end;

    procedure ProcessElectronicPayment(var GenJournalLine: Record "Gen. Journal Line"; WhichProcess: Option ,Void,Transmit)
    var
        CheckLedgEntry2: Record "Check Ledger Entry";
        CheckLedgEntry3: Record "Check Ledger Entry";
        BankAccountNo: Code[20];
    begin
        if not IsElectronicBankPaymentType(GenJournalLine."Bank Payment Type") then
            GenJournalLine.FieldError("Bank Payment Type");
        GenJournalLine.TestField("Exported to Payment File", true);
        if not (GenJournalLine."Document Type" in [GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund]) then
            Error(PaymentOrRefundErr, GenJournalLine.FieldCaption("Document Type"), GenJournalLine."Document Type"::Payment,
              GenJournalLine."Document Type"::Refund);
        GenJournalLine.TestField("Document No.");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Bank Account" then begin
            GenJournalLine.TestField("Account No.");
            BankAccountNo := GenJournalLine."Account No.";
        end else
            if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Bank Account" then begin
                GenJournalLine.TestField("Bal. Account No.");
                BankAccountNo := GenJournalLine."Bal. Account No.";
            end else
                Error(BankAccountTypeErr, GenJournalLine.FieldCaption("Account Type"), GenJournalLine.FieldCaption("Bal. Account Type"));

        CheckLedgEntry2.Reset();
        CheckLedgEntry2.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgEntry2.SetRange("Entry Status", CheckLedgEntry2."Entry Status"::Exported);
        CheckLedgEntry2.SetRange("Check No.", GenJournalLine."Document No.");
        if CheckLedgEntry2.FindSet() then
            repeat
                CheckLedgEntry3 := CheckLedgEntry2;
                CheckLedgEntry3."Original Entry Status" := CheckLedgEntry3."Entry Status";
                case WhichProcess of
                    WhichProcess::Void:
                        begin
                            CheckLedgEntry3."Entry Status" := CheckLedgEntry3."Entry Status"::Voided;
                            CheckLedgEntry3."Positive Pay Exported" := false;
                        end;
                    WhichProcess::Transmit:
                        CheckLedgEntry3."Entry Status" := CheckLedgEntry3."Entry Status"::Transmitted;
                end;
                OnProcessElectronicPaymentOnBeforeCheckLedgEntry3Modify(CheckLedgEntry3, WhichProcess);
                CheckLedgEntry3.Modify();
            until CheckLedgEntry2.Next() = 0;

        if WhichProcess = WhichProcess::Void then begin
            RemoveCreditTransfers(GenJournalLine);
            ClearApplnLedgerEntries(GenJournalLine);
        end;
    end;

    local procedure ClearApplnLedgerEntries(GenJournalLine: Record "Gen. Journal Line")
    begin
        case GenJournalLine."Account Type" of
            "Gen. Journal Account Type"::Customer:
                ClearApplnCustLedgerEntries(GenJournalLine);
            "Gen. Journal Account Type"::Vendor:
                ClearApplnVendorLedgerEntries(GenJournalLine);
            "Gen. Journal Account Type"::Employee:
                ClearApplnEmployeeLedgerEntries(GenJournalLine);
        end
    end;

    local procedure ClearApplnCustLedgerEntries(GenJournalLine: Record "Gen. Journal Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
    begin
        CustLedgerEntry.SetRange("Applies-to ID", GenJournalLine."Document No.");
        if CustLedgerEntry.FindSet() then
            repeat
                CustEntrySetApplID.SetApplId(CustLedgerEntry, ApplyingCustLedgerEntry, '');
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure ClearApplnVendorLedgerEntries(GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry";
        VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
    begin
        VendorLedgerEntry.SetRange("Applies-to ID", GenJournalLine."Document No.");
        if VendorLedgerEntry.FindSet() then
            repeat
                VendEntrySetApplID.SetApplId(VendorLedgerEntry, ApplyingVendorLedgerEntry, '');
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure ClearApplnEmployeeLedgerEntries(GenJournalLine: Record "Gen. Journal Line")
    var
        EmplLedgerEntry: Record "Employee Ledger Entry";
        ApplyingEmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmplEntrySetApplID: Codeunit "Empl. Entry-SetAppl.ID";
    begin
        EmplLedgerEntry.SetRange("Applies-to ID", GenJournalLine."Document No.");
        if EmplLedgerEntry.FindSet() then
            repeat
                EmplEntrySetApplID.SetApplId(EmplLedgerEntry, ApplyingEmployeeLedgerEntry, '');
            until EmplLedgerEntry.Next() = 0;
    end;

    local procedure RemoveCreditTransfers(var GenJournalLine: Record "Gen. Journal Line")
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferEntry: Record "Credit Transfer Entry";
        GenJnlShowCTEntries: Codeunit "Gen. Jnl.-Show CT Entries";
    begin
        GenJnlShowCTEntries.SetFiltersOnCreditTransferEntry(GenJournalLine, CreditTransferEntry);
        if CreditTransferEntry.FindLast() then begin
            if CreditTransferRegister.Get(CreditTransferEntry."Credit Transfer Register No.") then
                CreditTransferRegister.Delete(true);
            // For journal entries with multiple lines, the register would have already been deleted,
            // but subsequent lines still need to be deleted.
            Commit();
        end;
    end;

    local procedure PostRoundingAmount(BankAcc: Record "Bank Account"; CheckLedgEntry: Record "Check Ledger Entry"; PostingDate: Date; RoundingAmount: Decimal)
    var
        GenJnlLine2: Record "Gen. Journal Line";
        Currency: Record Currency;
    begin
        Currency.Get(BankAcc."Currency Code");
        GenJnlLine2.Init();
        GenJnlLine2."System-Created Entry" := true;
        GenJnlLine2."Financial Void" := true;
        GenJnlLine2."Document No." := CheckLedgEntry."Document No.";
        GenJnlLine2."Account Type" := GenJnlLine2."Account Type"::"G/L Account";
        GenJnlLine2."Posting Date" := PostingDate;
        if RoundingAmount > 0 then
            GenJnlLine2.Validate("Account No.", Currency.GetConvLCYRoundingDebitAccount())
        else
            GenJnlLine2.Validate("Account No.", Currency.GetConvLCYRoundingCreditAccount());
        GenJnlLine2.Validate("Currency Code", BankAcc."Currency Code");
        GenJnlLine2.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
        GenJnlLine2."Source Code" := SourceCodeSetup."Financially Voided Check";
        GenJnlLine2."Allow Zero-Amount Posting" := true;
        GenJnlLine2.Validate(Amount, 0);
        GenJnlLine2."Amount (LCY)" := RoundingAmount;
        GenJnlLine2."Shortcut Dimension 1 Code" := BankAccLedgEntry2."Global Dimension 1 Code";
        GenJnlLine2."Shortcut Dimension 2 Code" := BankAccLedgEntry2."Global Dimension 2 Code";
        GenJnlLine2."Dimension Set ID" := BankAccLedgEntry2."Dimension Set ID";
        GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
        GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
        OnPostRoundingAmountOnBeforeGenJnlPostLine(GenJnlLine2, CheckLedgEntry, BankAccLedgEntry2);
        GenJnlPostLine.RunWithCheck(GenJnlLine2);
        OnPostRoundingAmountOnAfterGenJnlPostLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure CleanRecordIDToPrintOnAfterDeleteEventGenJournalLine(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        DummyRecordID: RecordID;
    begin
        if Rec.IsTemporary then
            exit;
        CheckLedgerEntry.SetRange("Record ID to Print", Rec.RecordId);
        if not CheckLedgerEntry.IsEmpty() then
            CheckLedgerEntry.ModifyAll("Record ID to Print", DummyRecordID);
    end;

    local procedure FinancialVoidCheckPreValidation(var CheckLedgEntry: Record "Check Ledger Entry")
    var
        TransactionBalance: Decimal;
    begin
        CheckLedgEntry.TestField("Entry Status", CheckLedgEntry."Entry Status"::Posted);
        CheckLedgEntry.TestField("Statement Status", CheckLedgEntry."Statement Status"::Open);
        CheckLedgEntry.TestField("Bal. Account No.");
        BankAcc.Get(CheckLedgEntry."Bank Account No.");
        BankAccLedgEntry2.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
        SourceCodeSetup.Get();
        with GLEntry do begin
            SetCurrentKey("Transaction No.");
            SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
            SetRange("Document No.", BankAccLedgEntry2."Document No.");
            CalcSums(Amount);
            TransactionBalance := Amount;
        end;
        if TransactionBalance <> 0 then
            Error(VoidingCheckErr);
        OnAfterFinancialVoidCheckPreValidation(CheckLedgEntry, BankAccLedgEntry2);
    end;

    local procedure ClearBankLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        BankAccountLedgerEntry.Reset();
        BankAccountLedgerEntry.FindLast();
        BankAccountLedgerEntry.Open := false;
        BankAccountLedgerEntry."Remaining Amount" := 0;
        BankAccountLedgerEntry."Statement Status" := BankAccLedgEntry2."Statement Status"::Closed;
        BankAccountLedgerEntry.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcAmountToVoid(var CheckLedgerEntry: Record "Check Ledger Entry"; var AmountToVoid: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVoidCheck(var GenJnlLine: Record "Gen. Journal Line"; var CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinancialVoidCheck(var CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinancialVoidCheckPreValidation(CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVoidCheck(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMarkCheckEntriesVoid(var OriginalCheckLedgerEntry: Record "Check Ledger Entry"; VoidDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinancialVoidCheck(var CheckLedgerEntry: Record "Check Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVoidCheckGenJnlLine2Modify(var GenJournalLine2: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMarkCheckEntriesVoidOnBeforeRelatedCheckLedgerEntry2Modify(var CheckLedgerEntry: Record "Check Ledger Entry"; var VoidDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMarkCheckEntriesVoidOnBeforeOriginalCheckLedgerEntryModify(var CheckLedgerEntry: Record "Check Ledger Entry"; var VoidDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVoidCheckOnAfterGenJnlLine2Modify(var GenJournalLine2: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVoidCheckOnAfterCheckLedgEntry2SetFilters(var CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostCust(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var BalanceAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforeCheckBalAccountType(var GenJournalLine: Record "Gen. Journal Line"; var CheckLedgerEntry: Record "Check Ledger Entry"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostBankAccount(var GenJournalLine: Record "Gen. Journal Line"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostFixedAsset(var GenJournalLine: Record "Gen. Journal Line"; var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostVend(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var BalanceAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostEmp(var GenJournalLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnAfterPostVoidCheckLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnAfterVendorLedgEntrySetFilters(var VendorLedgEntry: Record "Vendor Ledger Entry"; BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostVoidCheckLine(var GenJournalLine: Record "Gen. Journal Line"; var CheckLedgEntry: Record "Check Ledger Entry"; var BankAccLedgEntry2: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnAfterPostBalAccLine(var GenJournalLine: Record "Gen. Journal Line"; CheckLedgerEntry: Record "Check Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostBalAccLine(var GenJournalLine: Record "Gen. Journal Line"; CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidPostGLAccountOnBeforeGLEntryLoop(var GLEntry: Record "G/L Entry"; var CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCheckOnAfterCheckLedgEntryInsert(var CheckLedgEntry: Record "Check Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCheckOnBeforeCheckLedgEntryInsert(var CheckLedgEntry: Record "Check Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostRoundingAmountOnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; CheckLedgerEntry: Record "Check Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessElectronicPaymentOnBeforeCheckLedgEntry3Modify(var CheckLedgerEntry: Record "Check Ledger Entry"; var WhichProcess: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostRoundingAmountOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; CheckLedgerEntry: Record "Check Ledger Entry"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnApplyCustInvoicesOnBeforePost(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnApplyVendInvoicesOnBeforePost(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsElectronicBankPaymentType(BankPaymenType: Enum "Bank Payment Type"; var IsElectronicPaymentType: Boolean)
    begin
    end;

}

