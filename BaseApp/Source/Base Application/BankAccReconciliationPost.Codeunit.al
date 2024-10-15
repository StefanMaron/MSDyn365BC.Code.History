codeunit 370 "Bank Acc. Reconciliation Post"
{
    Permissions = TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm,
                  TableData "Bank Account Statement" = ri,
                  TableData "Bank Account Statement Line" = ri,
                  TableData "Posted Payment Recon. Hdr" = ri;
    TableNo = "Bank Acc. Reconciliation";

    trigger OnRun()
    begin
        Window.Open(
          '#1#################################\\' +
          Text000);
        Window.Update(1, StrSubstNo('%1 %2', "Bank Account No.", "Statement No."));

        InitPost(Rec);
        Post(Rec);
        FinalizePost(Rec);

        Window.Close;

        Commit;
    end;

    var
        Text000: Label 'Posting lines              #2######';
        Text001: Label '%1 is not equal to Total Balance.';
        Text002: Label 'There is nothing to post.';
        Text003: Label 'The application is not correct. The total amount applied is %1; it should be %2.';
        Text004: Label 'The total difference is %1. It must be %2.';
        BankAcc: Record "Bank Account";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Window: Dialog;
        SourceCode: Code[10];
        TotalAmount: Decimal;
        TotalAppliedAmount: Decimal;
        TotalCredit: Decimal;
        TotalDebit: Decimal;
        TotalDiff: Decimal;
        Lines: Integer;
        Difference: Decimal;
        ExcessiveAmtErr: Label 'You must apply the excessive amount of %1 %2 manually.', Comment = '%1 a decimal number, %2 currency code';
        PostPerLineQst: Label 'Post per line in %1 %2 is disabled.\\Do you want to continue?', Comment = '%1=BankAcc.TABLECAPTION,%2=BankAcc."No."';
        MustBeTheSameErr: Label '%1 must be the same for all lines.', Comment = '%1=FIELDCAPTION("Transaction Date")';
        MustBeEqualErr: Label '%1 must be equal to ''%2'' for all lines.', Comment = '%1=FIELDCAPTION("Transaction Date"),%2=BankAccRecon."Statement Date"';
        PostPaymentsOnly: Boolean;
        NotFullyAppliedErr: Label 'One or more payments are not fully applied.\\The sum of applied amounts is %1. It must be %2.', Comment = '%1 - total applied amount, %2 - total transaction amount';
        LineNoTAppliedErr: Label 'The line with transaction date %1 and transaction text ''%2'' is not applied. You must apply all lines.', Comment = '%1 - transaction date, %2 - arbitrary text';
        TransactionAlreadyReconciledErr: Label 'The line with transaction date %1 and transaction text ''%2'' is already reconciled.\\You must remove it from the payment reconciliation journal before posting.', Comment = '%1 - transaction date, %2 - arbitrary text';

    local procedure InitPost(BankAccRecon: Record "Bank Acc. Reconciliation")
    begin
        OnBeforeInitPost(BankAccRecon);
        with BankAccRecon do
            case "Statement Type" of
                "Statement Type"::"Bank Reconciliation":
                    begin
                        TestField("Statement Date");
                        CheckLinesMatchEndingBalance(BankAccRecon, Difference);
                    end;
                "Statement Type"::"Payment Application":
                    begin
                        SourceCodeSetup.Get;
                        SourceCode := SourceCodeSetup."Payment Reconciliation Journal";
                        PostPaymentsOnly := "Post Payments Only";
                    end;
            end;
    end;

    local procedure Post(BankAccRecon: Record "Bank Acc. Reconciliation")
    var
        BankAcc: Record "Bank Account";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        TempSalesLetterHeader: Record "Sales Advance Letter Header" temporary;
        TempPurchLetterHeader: Record "Purch. Advance Letter Header" temporary;
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        AppliedAmount: Decimal;
        TotalTransAmtNotAppliedErr: Text;
    begin
        OnBeforePost(BankAccRecon, BankAccReconLine);
        with BankAccRecon do begin
            // Run through lines
            BankAccReconLine.FilterBankRecLines(BankAccRecon);
            TotalAmount := 0;
            TotalAppliedAmount := 0;
            TotalDiff := 0;
            // NAVCZ
            TotalCredit := 0;
            TotalDebit := 0;
            // NAVCZ
            Lines := 0;
            if BankAccReconLine.IsEmpty then
                Error(Text002);
            // NAVCZ
            BankAcc.Get("Bank Account No.");
            if not BankAcc."Post Per Line" then begin
                if not Confirm(PostPerLineQst, true, BankAcc.TableCaption, BankAcc."No.") then
                    Error('');
                CheckBankAccRecon(BankAccRecon);
            end;
            // NAVCZ
            BankAccLedgEntry.LockTable;
            CheckLedgEntry.LockTable;

            if BankAccReconLine.FindSet then
                repeat
                    Lines := Lines + 1;
                    Window.Update(2, Lines);
                    AppliedAmount := 0;
                    // Adjust entries
                    // Test amount and settled amount
                    case "Statement Type" of
                        "Statement Type"::"Bank Reconciliation":
                            case BankAccReconLine.Type of
                                BankAccReconLine.Type::"Bank Account Ledger Entry":
                                    CloseBankAccLedgEntry(BankAccReconLine, AppliedAmount);
                                BankAccReconLine.Type::"Check Ledger Entry":
                                    CloseCheckLedgEntry(BankAccReconLine, AppliedAmount);
                                BankAccReconLine.Type::Difference:
                                    TotalDiff += BankAccReconLine."Statement Amount";
                            end;
                        "Statement Type"::"Payment Application":
                            PostPaymentApplications(BankAccReconLine, AppliedAmount);
                    end;
                    OnBeforeAppliedAmountCheck(BankAccReconLine, AppliedAmount);
                    BankAccReconLine.TestField("Applied Amount", AppliedAmount);
                    TotalAmount += BankAccReconLine."Statement Amount";
                    TotalAppliedAmount += AppliedAmount;
                    // NAVCZ
                    if BankAccReconLine."Statement Amount" > 0 then
                        TotalDebit += BankAccReconLine.GetAmountInBankAccCurrCode
                    else
                        TotalCredit += BankAccReconLine.GetAmountInBankAccCurrCode;
                    // NAVCZ
                until BankAccReconLine.Next = 0;

            // NAVCZ
            if "Statement Type" = "Statement Type"::"Payment Application" then begin
                if not BankAcc."Post Per Line" then
                    PostPaymentApplicationsSummary(BankAccRecon, TotalCredit, TotalDebit);

                GenJnlPostLine.xGetSalesLetterHeader(TempSalesLetterHeader);
                if not TempSalesLetterHeader.IsEmpty then begin
                    SalesPostAdvances.SetLetterHeader(TempSalesLetterHeader);
                    SalesPostAdvances.SetGenJnlPostLine(GenJnlPostLine);
                    SalesPostAdvances.AutoPostAdvanceInvoices;
                end;
                GenJnlPostLine.xGetPurchLetterHeader(TempPurchLetterHeader);
                if not TempPurchLetterHeader.IsEmpty then begin
                    PurchPostAdvances.SetLetterHeader(TempPurchLetterHeader);
                    PurchPostAdvances.SetGenJnlPostLine(GenJnlPostLine);
                    PurchPostAdvances.AutoPostAdvanceInvoices;
                end;
            end;
            // NAVCZ

            // Test amount
            if "Statement Type" = "Statement Type"::"Payment Application" then
                TotalTransAmtNotAppliedErr := NotFullyAppliedErr
            else
                TotalTransAmtNotAppliedErr := Text003;
            if TotalAmount <> TotalAppliedAmount + TotalDiff then
                Error(
                  TotalTransAmtNotAppliedErr,
                  TotalAppliedAmount + TotalDiff, TotalAmount);
            if Difference <> TotalDiff then
                Error(Text004, Difference, TotalDiff);

            // Get bank
            if not PostPaymentsOnly then
                UpdateBank(BankAccRecon, TotalAmount);

            case "Statement Type" of
                "Statement Type"::"Bank Reconciliation":
                    TransferToBankStmt(BankAccRecon);
                "Statement Type"::"Payment Application":
                    begin
                        UpdateIssuedBankStatement(BankAccRecon); // NAVCZ
                        TransferToPostPmtAppln(BankAccRecon);
                        if not "Post Payments Only" then
                            TransferToBankStmt(BankAccRecon);
                    end;
            end;
        end;
    end;

    local procedure FinalizePost(BankAccRecon: Record "Bank Acc. Reconciliation")
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        AppliedPmtEntry: Record "Applied Payment Entry";
    begin
        OnBeforeFinalizePost(BankAccRecon);
        with BankAccRecon do begin
            // Delete statement
            if BankAccReconLine.LinesExist(BankAccRecon) then
                repeat
                    AppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconLine);
                    AppliedPmtEntry.DeleteAll;

                    BankAccReconLine.Delete;
                    BankAccReconLine.ClearDataExchEntries;
                until BankAccReconLine.Next = 0;

            Find;
            Delete;
        end;
    end;

    local procedure CheckLinesMatchEndingBalance(BankAccRecon: Record "Bank Acc. Reconciliation"; var Difference: Decimal)
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        with BankAccReconLine do begin
            LinesExist(BankAccRecon);
            CalcSums("Statement Amount", Difference);

            if "Statement Amount" <>
               BankAccRecon."Statement Ending Balance" - BankAccRecon."Balance Last Statement"
            then
                Error(Text001, BankAccRecon.FieldCaption("Statement Ending Balance"));
        end;
        Difference := BankAccReconLine.Difference;
    end;

    local procedure CloseBankAccLedgEntry(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var AppliedAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        OnBeforeCloseBankAccLedgEntry(BankAccReconLine, AppliedAmount, IsHandled);
        if IsHandled then
            exit;

        BankAccLedgEntry.Reset;
        BankAccLedgEntry.SetCurrentKey("Bank Account No.", Open);
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccReconLine."Bank Account No.");
        BankAccLedgEntry.SetRange(Open, true);
        BankAccLedgEntry.SetRange(
          "Statement Status", BankAccLedgEntry."Statement Status"::"Bank Acc. Entry Applied");
        BankAccLedgEntry.SetRange("Statement No.", BankAccReconLine."Statement No.");
        BankAccLedgEntry.SetRange("Statement Line No.", BankAccReconLine."Statement Line No.");
        if BankAccLedgEntry.Find('-') then
            repeat
                AppliedAmount += BankAccLedgEntry."Remaining Amount";
                BankAccLedgEntry."Remaining Amount" := 0;
                BankAccLedgEntry.Open := false;
                BankAccLedgEntry."Statement Status" := BankAccLedgEntry."Statement Status"::Closed;
                OnCloseBankAccLedgEntryOnBeforeBankAccLedgEntryModify(BankAccLedgEntry, BankAccReconLine);
                BankAccLedgEntry.Modify;

                CheckLedgEntry.Reset;
                CheckLedgEntry.SetCurrentKey("Bank Account Ledger Entry No.");
                CheckLedgEntry.SetRange(
                  "Bank Account Ledger Entry No.", BankAccLedgEntry."Entry No.");
                CheckLedgEntry.SetRange(Open, true);
                if CheckLedgEntry.Find('-') then
                    repeat
                        CheckLedgEntry.TestField(Open, true);
                        CheckLedgEntry.TestField(
                          "Statement Status",
                          CheckLedgEntry."Statement Status"::"Bank Acc. Entry Applied");
                        CheckLedgEntry.TestField("Statement No.", '');
                        CheckLedgEntry.TestField("Statement Line No.", 0);
                        CheckLedgEntry.Open := false;
                        CheckLedgEntry."Statement Status" := CheckLedgEntry."Statement Status"::Closed;
                        CheckLedgEntry.Modify;
                    until CheckLedgEntry.Next = 0;
            until BankAccLedgEntry.Next = 0;
    end;

    local procedure CloseCheckLedgEntry(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var AppliedAmount: Decimal)
    var
        CheckLedgEntry2: Record "Check Ledger Entry";
    begin
        CheckLedgEntry.Reset;
        CheckLedgEntry.SetCurrentKey("Bank Account No.", Open);
        CheckLedgEntry.SetRange("Bank Account No.", BankAccReconLine."Bank Account No.");
        CheckLedgEntry.SetRange(Open, true);
        CheckLedgEntry.SetRange(
          "Statement Status", CheckLedgEntry."Statement Status"::"Check Entry Applied");
        CheckLedgEntry.SetRange("Statement No.", BankAccReconLine."Statement No.");
        CheckLedgEntry.SetRange("Statement Line No.", BankAccReconLine."Statement Line No.");
        if CheckLedgEntry.Find('-') then
            repeat
                AppliedAmount -= CheckLedgEntry.Amount;
                CheckLedgEntry.Open := false;
                CheckLedgEntry."Statement Status" := CheckLedgEntry."Statement Status"::Closed;
                CheckLedgEntry.Modify;

                BankAccLedgEntry.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
                BankAccLedgEntry.TestField(Open, true);
                BankAccLedgEntry.TestField(
                  "Statement Status", BankAccLedgEntry."Statement Status"::"Check Entry Applied");
                BankAccLedgEntry.TestField("Statement No.", '');
                BankAccLedgEntry.TestField("Statement Line No.", 0);
                BankAccLedgEntry."Remaining Amount" :=
                  BankAccLedgEntry."Remaining Amount" + CheckLedgEntry.Amount;
                if BankAccLedgEntry."Remaining Amount" = 0 then begin
                    BankAccLedgEntry.Open := false;
                    BankAccLedgEntry."Statement Status" := BankAccLedgEntry."Statement Status"::Closed;
                    BankAccLedgEntry."Statement No." := BankAccReconLine."Statement No.";
                    BankAccLedgEntry."Statement Line No." := CheckLedgEntry."Statement Line No.";
                end else begin
                    CheckLedgEntry2.Reset;
                    CheckLedgEntry2.SetCurrentKey("Bank Account Ledger Entry No.");
                    CheckLedgEntry2.SetRange("Bank Account Ledger Entry No.", BankAccLedgEntry."Entry No.");
                    CheckLedgEntry2.SetRange(Open, true);
                    CheckLedgEntry2.SetRange("Check Type", CheckLedgEntry2."Check Type"::"Partial Check");
                    CheckLedgEntry2.SetRange(
                      "Statement Status", CheckLedgEntry2."Statement Status"::"Check Entry Applied");
                    if not CheckLedgEntry2.FindFirst then
                        BankAccLedgEntry."Statement Status" := BankAccLedgEntry."Statement Status"::Open;
                end;
                BankAccLedgEntry.Modify;
            until CheckLedgEntry.Next = 0;
    end;

    local procedure PostPaymentApplications(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var AppliedAmount: Decimal)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        AppliedPmtEntry: Record "Applied Payment Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        BankAccountBal: Record "Bank Account";
        DimensionManagement: Codeunit DimensionManagement;
        PaymentLineAmount: Decimal;
        RemainingAmount: Decimal;
        PaymentWithoutApplies: Boolean;
    begin
        if BankAccReconLine.IsTransactionPostedAndReconciled then
            Error(TransactionAlreadyReconciledErr, BankAccReconLine."Transaction Date", BankAccReconLine."Transaction Text");

        with GenJnlLine do begin
            if BankAccReconLine."Account No." = '' then
                Error(LineNoTAppliedErr, BankAccReconLine."Transaction Date", BankAccReconLine."Transaction Text");
            BankAcc.Get(BankAccReconLine."Bank Account No.");

            Init;
            SetSuppressCommit(true);
            // NAVCZ
            "Document Type" := BankAccReconLine."Document Type";
            if "Document Type" = "Document Type"::" " then begin
                "Document Type" := "Document Type"::Payment;
                if IsRefund(BankAccReconLine) then
                    "Document Type" := "Document Type"::Refund;
            end;
            // NAVCZ
            "Account Type" := BankAccReconLine.GetAppliedToAccountType;
            BankAccReconciliation.Get(
              BankAccReconLine."Statement Type", BankAccReconLine."Bank Account No.", BankAccReconLine."Statement No.");
            "Copy VAT Setup to Jnl. Lines" := BankAccReconciliation."Copy VAT Setup to Jnl. Line";
            Validate("Account No.", BankAccReconLine.GetAppliedToAccountNo);
            "Posting Group" := BankAccReconLine."Posting Group"; // NAVCZ
            "Dimension Set ID" := BankAccReconLine."Dimension Set ID";
            DimensionManagement.UpdateGlobalDimFromDimSetID(
              BankAccReconLine."Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            "Posting Date" := BankAccReconLine."Transaction Date";
            "VAT Date" := BankAccReconLine."Transaction Date"; // NAVCZ
            "Original Document VAT Date" := BankAccReconLine."Transaction Date"; // NAVCZ
            Description := BankAccReconLine.GetDescription;

            "Document No." := BankAccReconLine."Statement No.";
            if BankAcc."Post Per Line" and (BankAccReconLine."Currency Code" = BankAcc."Currency Code") then begin // NAVCZ
                "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
                "Bal. Account No." := BankAcc."No.";
            end; // NAVCZ

            // NAVCZ
            "Currency Code" := BankAccReconLine."Currency Code";
            Validate("Currency Factor", BankAccReconLine."Currency Factor");
            // NAVCZ
            "Source Code" := SourceCode;
            "Allow Zero-Amount Posting" := true;

            "Applies-to ID" := BankAccReconLine.GetAppliesToID;

            // NAVCZ
            "Variable Symbol" := BankAccReconLine."Variable Symbol";
            "Specific Symbol" := BankAccReconLine."Specific Symbol";
            "Constant Symbol" := BankAccReconLine."Constant Symbol";
            "External Document No." := BankAccReconLine."External Document No.";
            Validate(Prepayment, BankAccReconLine.Prepayment);

            if BankAccReconLine."Advance Letter Link Code" <> '' then begin
                Prepayment := true;
                "Prepayment Type" := "Prepayment Type"::Advance;
            end;
            // NAVCZ
        end;

        PaymentWithoutApplies := true; // NAVCZ

        OnPostPaymentApplicationsOnAfterInitGenJnlLine(GenJnlLine, BankAccReconLine);

        with AppliedPmtEntry do
            if AppliedPmtEntryLinesExist(BankAccReconLine) then
                repeat
                    PaymentWithoutApplies := PaymentWithoutApplies and ("Applies-to Entry No." <= 0); // NAVCZ
                    AppliedAmount += "Applied Amount" - "Applied Pmt. Discount";
                    PaymentLineAmount += "Applied Amount" - "Applied Pmt. Discount";
                    TestField("Account Type", BankAccReconLine."Account Type");
                    TestField("Account No.", BankAccReconLine."Account No.");
                    if "Applies-to Entry No." > 0 then
                        case "Account Type" of
                            "Account Type"::Customer:
                                ApplyCustLedgEntry(
                                  AppliedPmtEntry, GenJnlLine."Applies-to ID", GenJnlLine."Posting Date", 0D, 0D, "Applied Pmt. Discount");
                            "Account Type"::Vendor:
                                ApplyVendLedgEntry(
                                  AppliedPmtEntry, GenJnlLine."Applies-to ID", GenJnlLine."Posting Date", 0D, 0D, "Applied Pmt. Discount");
                            // NAVCZ
                            "Account Type"::"G/L Account":
                                ApplyGenLedgEntry(
                                  AppliedPmtEntry, GenJnlLine."Applies-to ID");
                            // NAVCZ
                            "Account Type"::"Bank Account":
                                begin
                                    BankAccountLedgerEntry.Get("Applies-to Entry No.");
                                    RemainingAmount := BankAccountLedgerEntry."Remaining Amount";
                                    case true of
                                        RemainingAmount = "Applied Amount":
                                            begin
                                                if not PostPaymentsOnly then
                                                    CloseBankAccountLedgerEntry("Applies-to Entry No.", "Applied Amount");
                                                PaymentLineAmount -= "Applied Amount";
                                            end;
                                        Abs(RemainingAmount) > Abs("Applied Amount"):
                                            begin
                                                if not PostPaymentsOnly then begin
                                                    BankAccountLedgerEntry."Remaining Amount" -= "Applied Amount";
                                                    BankAccountLedgerEntry.Modify;
                                                end;
                                                PaymentLineAmount -= "Applied Amount";
                                            end;
                                        Abs(RemainingAmount) < Abs("Applied Amount"):
                                            begin
                                                if not PostPaymentsOnly then
                                                    CloseBankAccountLedgerEntry("Applies-to Entry No.", RemainingAmount);
                                                PaymentLineAmount -= RemainingAmount;
                                            end;
                                    end;
                                end;
                        end;
                until Next = 0;

        // NAVCZ
        if PaymentWithoutApplies then
            GenJnlLine."Applies-to ID" := '';
        // NAVCZ

        if PaymentLineAmount <> 0 then begin
            if (GenJnlLine."Account Type" <> GenJnlLine."Account Type"::"Bank Account") or
               BankAccountBal.Get(GenJnlLine."Account No.") and (BankAccountBal."Currency Code" = BankAcc."Currency Code")
            then begin
                GenJnlLine.Amount := -PaymentLineAmount;
                GenJnlLine.Validate(Amount); // NAVCZ
                GenJnlLine.Validate("VAT %");
                GenJnlLine.Validate("Bal. VAT %")
            end else begin
                GLSetup.Get;
                Error(ExcessiveAmtErr, PaymentLineAmount, GLSetup.GetCurrencyCode(BankAcc."Currency Code"));
            end;
            // NAVCZ
            GenJnlLine."Advance Letter Link Code" := BankAccReconLine."Advance Letter Link Code";
            if GenJnlLine."Advance Letter Link Code" <> '' then
                TestAdvLetter(GenJnlLine);
            GenJnlPostLine.SetPostAdvInvAfterBatch(true);
            // NAVCZ

            OnPostPaymentApplicationsOnBeforeValidateApplyRequirements(BankAccReconLine, GenJnlLine, AppliedAmount);

            GenJnlLine.ValidateApplyRequirements(GenJnlLine);
            GenJnlPostLine.RunWithCheck(GenJnlLine);

            // NAVCZ
            if BankAcc."Post Per Line" and (BankAccReconLine."Currency Code" <> BankAcc."Currency Code") then
                PostPaymentApplicationsBankAcc(BankAccReconLine);
            // NAVCZ

            if not PostPaymentsOnly then begin
                BankAccountLedgerEntry.SetRange(Open, true);
                BankAccountLedgerEntry.SetRange("Bank Account No.", BankAcc."No.");
                BankAccountLedgerEntry.SetRange("Document Type", GenJnlLine."Document Type");
                BankAccountLedgerEntry.SetRange("Document No.", BankAccReconLine."Statement No.");
                BankAccountLedgerEntry.SetRange("Posting Date", GenJnlLine."Posting Date");
                if BankAccountLedgerEntry.FindLast then
                    CloseBankAccountLedgerEntry(BankAccountLedgerEntry."Entry No.", BankAccountLedgerEntry.Amount);
            end;
        end;
    end;

    local procedure PostPaymentApplicationsBankAcc(BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    var
        BankAcc: Record "Bank Account";
    begin
        // NAVCZ
        BankAcc.Get(BankAccReconLine."Bank Account No.");
        with GenJnlLine do begin
            Init;
            SetSuppressCommit(true); // NAVCZ
            CopyFromBankAccReconLine(BankAccReconLine);
            "Advance Letter Link Code" := '';
            "Account Type" := "Account Type"::"Bank Account";
            "Account No." := BankAcc."No.";
            Validate("Currency Code", BankAcc."Currency Code");
            Validate("Amount (LCY)", BankAccReconLine."Statement Amount (LCY)");
            "Allow Zero-Amount Posting" := true;
            "Applies-to ID" := BankAccReconLine.GetAppliesToID;
            "Source Code" := SourceCode;

            GenJnlPostLine.RunWithCheck(GenJnlLine);
        end;
    end;

    local procedure PostPaymentApplicationsSummary(BankAccRecon: Record "Bank Acc. Reconciliation"; Credit: Decimal; Debit: Decimal)
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        BankAcc: Record "Bank Account";
        GenJnlLine: Record "Gen. Journal Line";
        StatementDate: Date;
    begin
        // NAVCZ
        BankAcc.Get(BankAccRecon."Bank Account No.");
        StatementDate := BankAccRecon."Statement Date";
        if StatementDate = 0D then begin
            BankAccReconLine.FilterBankRecLines(BankAccRecon);
            BankAccReconLine.FindFirst;
            StatementDate := BankAccReconLine."Transaction Date";
        end;

        with GenJnlLine do begin
            // post credit
            if Credit <> 0 then begin
                Init;
                SetSuppressCommit(true); // NAVCZ
                "Posting Date" := StatementDate;
                "VAT Date" := StatementDate;
                "Account Type" := "Account Type"::"Bank Account";
                "Account No." := BankAccRecon."Bank Account No.";
                "Document No." := BankAccRecon."Statement No.";
                Validate("Currency Code", BankAcc."Currency Code");
                Validate(Amount, Credit);
                "Source Code" := SourceCode;
                "Shortcut Dimension 1 Code" := BankAccRecon."Shortcut Dimension 1 Code";
                "Shortcut Dimension 2 Code" := BankAccRecon."Shortcut Dimension 2 Code";
                "Dimension Set ID" := BankAccRecon."Dimension Set ID";

                GenJnlPostLine.RunWithCheck(GenJnlLine);
            end;

            // post debit
            if Debit <> 0 then begin
                Init;
                SetSuppressCommit(true); // NAVCZ
                "Posting Date" := StatementDate;
                "VAT Date" := StatementDate;
                "Account Type" := "Account Type"::"Bank Account";
                "Account No." := BankAccRecon."Bank Account No.";
                "Document No." := BankAccRecon."Statement No.";
                Validate("Currency Code", BankAcc."Currency Code");
                Validate(Amount, Debit);
                "Source Code" := SourceCode;
                "Shortcut Dimension 1 Code" := BankAccRecon."Shortcut Dimension 1 Code";
                "Shortcut Dimension 2 Code" := BankAccRecon."Shortcut Dimension 2 Code";
                "Dimension Set ID" := BankAccRecon."Dimension Set ID";

                GenJnlPostLine.RunWithCheck(GenJnlLine);
            end;
        end;
    end;

    local procedure UpdateBank(BankAccRecon: Record "Bank Acc. Reconciliation"; Amt: Decimal)
    begin
        with BankAcc do begin
            LockTable;
            Get(BankAccRecon."Bank Account No.");
            TestField(Blocked, false);
            "Last Statement No." := BankAccRecon."Statement No.";
            "Balance Last Statement" := BankAccRecon."Balance Last Statement" + Amt;
            Modify;
        end;
    end;

    local procedure TransferToBankStmt(BankAccRecon: Record "Bank Acc. Reconciliation")
    var
        BankAccStmt: Record "Bank Account Statement";
        BankAccStmtLine: Record "Bank Account Statement Line";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        BankAccStmtExists: Boolean;
    begin
        BankAccStmtExists := BankAccStmt.Get(BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");
        BankAccStmt.Init;
        BankAccStmt.TransferFields(BankAccRecon);
        if BankAccStmtExists then
            BankAccStmt."Statement No." := GetNextStatementNoAndUpdateBankAccount(BankAccRecon."Bank Account No.");
        if BankAccReconLine.LinesExist(BankAccRecon) then
            repeat
                BankAccStmtLine.TransferFields(BankAccReconLine);
                BankAccStmtLine."Statement No." := BankAccStmt."Statement No.";
                BankAccStmtLine.Insert;
                BankAccReconLine.ClearDataExchEntries;
            until BankAccReconLine.Next = 0;

        OnBeforeBankAccStmtInsert(BankAccStmt, BankAccRecon);
        BankAccStmt.Insert;
    end;

    local procedure TransferToPostPmtAppln(BankAccRecon: Record "Bank Acc. Reconciliation")
    var
        PostedPmtReconHdr: Record "Posted Payment Recon. Hdr";
        PostedPmtReconLine: Record "Posted Payment Recon. Line";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        TypeHelper: Codeunit "Type Helper";
        FieldLength: Integer;
    begin
        if BankAccReconLine.LinesExist(BankAccRecon) then
            repeat
                PostedPmtReconLine.TransferFields(BankAccReconLine);

                FieldLength := TypeHelper.GetFieldLength(DATABASE::"Posted Payment Recon. Line",
                    PostedPmtReconLine.FieldNo("Applied Document No."));
                PostedPmtReconLine."Applied Document No." := CopyStr(BankAccReconLine.GetAppliedToDocumentNo, 1, FieldLength);

                FieldLength := TypeHelper.GetFieldLength(DATABASE::"Posted Payment Recon. Line",
                    PostedPmtReconLine.FieldNo("Applied Entry No."));
                PostedPmtReconLine."Applied Entry No." := CopyStr(BankAccReconLine.GetAppliedToEntryNo, 1, FieldLength);

                PostedPmtReconLine.Reconciled := not PostPaymentsOnly;

                PostedPmtReconLine.Insert;
                BankAccReconLine.ClearDataExchEntries;
            until BankAccReconLine.Next = 0;

        PostedPmtReconHdr.TransferFields(BankAccRecon);
        OnBeforePostedPmtReconInsert(PostedPmtReconHdr, BankAccRecon);
        PostedPmtReconHdr.Insert;
    end;

    procedure ApplyCustLedgEntry(AppliedPmtEntry: Record "Applied Payment Entry"; AppliesToID: Code[50]; PostingDate: Date; PmtDiscDueDate: Date; PmtDiscToleranceDate: Date; RemPmtDiscPossible: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        with CustLedgEntry do begin
            Get(AppliedPmtEntry."Applies-to Entry No.");
            TestField(Open);
            if AppliesToID = '' then begin
                "Pmt. Discount Date" := PmtDiscDueDate;
                "Pmt. Disc. Tolerance Date" := PmtDiscToleranceDate;

                "Remaining Pmt. Disc. Possible" := RemPmtDiscPossible;
                if AppliedPmtEntry.IsBankAccReconciliationLineLCY then // NAVCZ
                    "Remaining Pmt. Disc. Possible" :=
                      CurrExchRate.ExchangeAmount("Remaining Pmt. Disc. Possible", '', "Currency Code", PostingDate);
            end else begin
                "Applies-to ID" := AppliesToID;
                "Amount to Apply" := AppliedPmtEntry.CalcAmountToApply(PostingDate);
            end;

            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
        end;
    end;

    procedure ApplyVendLedgEntry(AppliedPmtEntry: Record "Applied Payment Entry"; AppliesToID: Code[50]; PostingDate: Date; PmtDiscDueDate: Date; PmtDiscToleranceDate: Date; RemPmtDiscPossible: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        with VendLedgEntry do begin
            Get(AppliedPmtEntry."Applies-to Entry No.");
            TestField(Open);
            if AppliesToID = '' then begin
                "Pmt. Discount Date" := PmtDiscDueDate;
                "Pmt. Disc. Tolerance Date" := PmtDiscToleranceDate;

                "Remaining Pmt. Disc. Possible" := RemPmtDiscPossible;
                if AppliedPmtEntry.IsBankAccReconciliationLineLCY then // NAVCZ
                    "Remaining Pmt. Disc. Possible" :=
                      CurrExchRate.ExchangeAmount("Remaining Pmt. Disc. Possible", '', "Currency Code", PostingDate);
            end else begin
                "Applies-to ID" := AppliesToID;
                "Amount to Apply" := AppliedPmtEntry.CalcAmountToApply(PostingDate);
            end;

            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
        end;
    end;

    [Scope('OnPrem')]
    procedure ApplyGenLedgEntry(AppliedPmtEntry: Record "Applied Payment Entry"; AppliesToID: Code[50])
    var
        GLEntry: Record "G/L Entry";
    begin
        // NAVCZ
        with GLEntry do begin
            Get(AppliedPmtEntry."Applies-to Entry No.");
            TestField(Closed, false);
            "Applies-to ID" := AppliesToID;
            "Amount to Apply" := AppliedPmtEntry."Applied Amount";

            CODEUNIT.Run(CODEUNIT::"G/L Entry - Edit CZ", GLEntry);
        end;
    end;

    local procedure CloseBankAccountLedgerEntry(EntryNo: Integer; AppliedAmount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        with BankAccountLedgerEntry do begin
            Get(EntryNo);
            TestField(Open);
            TestField("Remaining Amount", AppliedAmount);
            "Remaining Amount" := 0;
            Open := false;
            "Statement Status" := "Statement Status"::Closed;
            Modify;

            CheckLedgerEntry.Reset;
            CheckLedgerEntry.SetCurrentKey("Bank Account Ledger Entry No.");
            CheckLedgerEntry.SetRange(
              "Bank Account Ledger Entry No.", "Entry No.");
            CheckLedgerEntry.SetRange(Open, true);
            if CheckLedgerEntry.FindSet then
                repeat
                    CheckLedgerEntry.Open := false;
                    CheckLedgerEntry."Statement Status" := CheckLedgerEntry."Statement Status"::Closed;
                    CheckLedgerEntry.Modify;
                until CheckLedgerEntry.Next = 0;
        end;
    end;

    local procedure GetNextStatementNoAndUpdateBankAccount(BankAccountNo: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        with BankAccount do begin
            Get(BankAccountNo);
            if "Last Statement No." <> '' then
                "Last Statement No." := IncStr("Last Statement No.")
            else
                "Last Statement No." := '1';
            Modify;
        end;
        exit(BankAccount."Last Statement No.");
    end;

    local procedure IsRefund(BankAccReconLine: Record "Bank Acc. Reconciliation Line"): Boolean
    begin
        with BankAccReconLine do
            if ("Account Type" = "Account Type"::Customer) and ("Statement Amount" < 0) or
               ("Account Type" = "Account Type"::Vendor) and ("Statement Amount" > 0)
            then
                exit(true);
        exit(false);
    end;

    local procedure CheckBankAccRecon(BankAccRecon: Record "Bank Acc. Reconciliation")
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        // NAVCZ
        with BankAccReconLine do begin
            FilterBankRecLines(BankAccRecon);
            if BankAccRecon."Statement Date" <> 0D then begin
                SetFilter("Transaction Date", '<>%1', BankAccRecon."Statement Date");
                if not IsEmpty then
                    Error(MustBeEqualErr, FieldCaption("Transaction Date"), BankAccRecon."Statement Date");
            end else begin
                FindFirst;
                SetFilter("Transaction Date", '<>%1', "Transaction Date");
                if not IsEmpty then
                    Error(MustBeTheSameErr, FieldCaption("Transaction Date"));
            end;
        end;
    end;

    local procedure UpdateIssuedBankStatement(BankAccRecon: Record "Bank Acc. Reconciliation")
    var
        IssuedBankStmtHdr: Record "Issued Bank Statement Header";
    begin
        // NAVCZ
        if IssuedBankStmtHdr.Get(BankAccRecon."Statement No.") then
            IssuedBankStmtHdr.UpdatePaymentReconciliationStatus(IssuedBankStmtHdr."Payment Reconciliation Status"::Posted);
    end;

    local procedure TestAdvLetter(GenJournalLine: Record "Gen. Journal Line")
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        // NAVCZ
        with GenJournalLine do begin
            if "Advance Letter Link Code" = '' then
                exit;

            if (Prepayment and ("Prepayment Type" = "Prepayment Type"::Advance)) and
               ((("Account Type" in ["Account Type"::Customer]) and ("Account No." <> '')) or
                (("Bal. Account Type" in ["Bal. Account Type"::Customer]) and ("Bal. Account No." <> '')))
            then begin
                SalesAdvanceLetterLine.SetCurrentKey("Bill-to Customer No.");
                if "Account Type" = "Account Type"::Customer then
                    SalesAdvanceLetterLine.SetRange("Bill-to Customer No.", "Account No.")
                else
                    SalesAdvanceLetterLine.SetRange("Bill-to Customer No.", "Bal. Account No.");

                SalesAdvanceLetterLine.SetRange("Link Code", "Advance Letter Link Code");
                if SalesAdvanceLetterLine.FindSet(false, false) then
                    repeat
                        if SalesAdvanceLetterLine."Amount Linked To Journal Line" <> 0 then
                            TestField("Currency Code", SalesAdvanceLetterLine."Currency Code");
                    until SalesAdvanceLetterLine.Next = 0;
            end;

            if (Prepayment and ("Prepayment Type" = "Prepayment Type"::Advance)) and
               ((("Account Type" in ["Account Type"::Vendor]) and ("Account No." <> '')) or
                (("Bal. Account Type" in ["Bal. Account Type"::Vendor]) and ("Bal. Account No." <> '')))
            then begin
                PurchAdvanceLetterLine.SetCurrentKey("Pay-to Vendor No.");
                if "Account Type" = "Account Type"::Vendor then
                    PurchAdvanceLetterLine.SetRange("Pay-to Vendor No.", "Account No.")
                else
                    PurchAdvanceLetterLine.SetRange("Pay-to Vendor No.", "Bal. Account No.");

                PurchAdvanceLetterLine.SetRange("Link Code", "Advance Letter Link Code");
                if PurchAdvanceLetterLine.FindSet(false, false) then
                    repeat
                        if PurchAdvanceLetterLine."Amount Linked To Journal Line" <> 0 then
                            TestField("Currency Code", PurchAdvanceLetterLine."Currency Code");
                    until PurchAdvanceLetterLine.Next = 0;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAppliedAmountCheck(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var AppliedAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBankAccStmtInsert(var BankAccStatement: Record "Bank Account Statement"; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCloseBankAccLedgEntry(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var AppliedAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizePost(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPost(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedPmtReconInsert(var PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr"; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCloseBankAccLedgEntryOnBeforeBankAccLedgEntryModify(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPaymentApplicationsOnAfterInitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPaymentApplicationsOnBeforeValidateApplyRequirements(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var GenJournalLine: Record "Gen. Journal Line"; AppliedAmount: Decimal)
    begin
    end;
}

