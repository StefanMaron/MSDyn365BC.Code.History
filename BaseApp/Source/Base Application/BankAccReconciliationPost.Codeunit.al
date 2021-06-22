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

        Commit();
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
        TotalDiff: Decimal;
        Lines: Integer;
        Difference: Decimal;
        ExcessiveAmtErr: Label 'You must apply the excessive amount of %1 %2 manually.', Comment = '%1 a decimal number, %2 currency code';
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
                        SourceCodeSetup.Get();
                        SourceCode := SourceCodeSetup."Payment Reconciliation Journal";
                        PostPaymentsOnly := "Post Payments Only";
                    end;
            end;
    end;

    local procedure Post(BankAccRecon: Record "Bank Acc. Reconciliation")
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
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
            Lines := 0;
            if BankAccReconLine.IsEmpty then
                Error(Text002);
            BankAccLedgEntry.LockTable();
            CheckLedgEntry.LockTable();

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
                until BankAccReconLine.Next = 0;

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
                    AppliedPmtEntry.DeleteAll();

                    BankAccReconLine.Delete();
                    BankAccReconLine.ClearDataExchEntries;
                until BankAccReconLine.Next = 0;

            Find;
            Delete;
        end;
        OnAfterFinalizePost(BankAccRecon);
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

        BankAccLedgEntry.Reset();
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
                BankAccLedgEntry.Modify();

                CheckLedgEntry.Reset();
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
                        CheckLedgEntry.Modify();
                    until CheckLedgEntry.Next = 0;
            until BankAccLedgEntry.Next = 0;
    end;

    local procedure CloseCheckLedgEntry(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var AppliedAmount: Decimal)
    var
        CheckLedgEntry2: Record "Check Ledger Entry";
    begin
        CheckLedgEntry.Reset();
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
                CheckLedgEntry.Modify();

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
                    CheckLedgEntry2.Reset();
                    CheckLedgEntry2.SetCurrentKey("Bank Account Ledger Entry No.");
                    CheckLedgEntry2.SetRange("Bank Account Ledger Entry No.", BankAccLedgEntry."Entry No.");
                    CheckLedgEntry2.SetRange(Open, true);
                    CheckLedgEntry2.SetRange("Check Type", CheckLedgEntry2."Check Type"::"Partial Check");
                    CheckLedgEntry2.SetRange(
                      "Statement Status", CheckLedgEntry2."Statement Status"::"Check Entry Applied");
                    if not CheckLedgEntry2.FindFirst then
                        BankAccLedgEntry."Statement Status" := BankAccLedgEntry."Statement Status"::Open;
                end;
                BankAccLedgEntry.Modify();
            until CheckLedgEntry.Next = 0;
    end;

    local procedure PostPaymentApplications(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var AppliedAmount: Decimal)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        CurrExchRate: Record "Currency Exchange Rate";
        AppliedPmtEntry: Record "Applied Payment Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        DimensionManagement: Codeunit DimensionManagement;
        PaymentLineAmount: Decimal;
        RemainingAmount: Decimal;
        IsApplied: Boolean;
    begin
        if BankAccReconLine.IsTransactionPostedAndReconciled then
            Error(TransactionAlreadyReconciledErr, BankAccReconLine."Transaction Date", BankAccReconLine."Transaction Text");

        with GenJnlLine do begin
            if BankAccReconLine."Account No." = '' then
                Error(LineNoTAppliedErr, BankAccReconLine."Transaction Date", BankAccReconLine."Transaction Text");
            BankAcc.Get(BankAccReconLine."Bank Account No.");

            Init;
            SetSuppressCommit(true);
            "Document Type" := "Document Type"::Payment;

            if IsRefund(BankAccReconLine) then
                "Document Type" := "Document Type"::Refund;

            "Account Type" := BankAccReconLine.GetAppliedToAccountType;
            BankAccReconciliation.Get(
              BankAccReconLine."Statement Type", BankAccReconLine."Bank Account No.", BankAccReconLine."Statement No.");
            "Copy VAT Setup to Jnl. Lines" := BankAccReconciliation."Copy VAT Setup to Jnl. Line";
            Validate("Account No.", BankAccReconLine.GetAppliedToAccountNo);
            "Dimension Set ID" := BankAccReconLine."Dimension Set ID";
            DimensionManagement.UpdateGlobalDimFromDimSetID(
              BankAccReconLine."Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

            "Posting Date" := BankAccReconLine."Transaction Date";
            Description := BankAccReconLine.GetDescription;

            "Document No." := BankAccReconLine."Statement No.";
            "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
            "Bal. Account No." := BankAcc."No.";

            "Source Code" := SourceCode;
            "Allow Zero-Amount Posting" := true;

            "Applies-to ID" := BankAccReconLine.GetAppliesToID;
        end;

        OnPostPaymentApplicationsOnAfterInitGenJnlLine(GenJnlLine, BankAccReconLine);

        IsApplied := false;
        with AppliedPmtEntry do
            if AppliedPmtEntryLinesExist(BankAccReconLine) then
                repeat
                    AppliedAmount += "Applied Amount" - "Applied Pmt. Discount";
                    PaymentLineAmount += "Applied Amount" - "Applied Pmt. Discount";
                    TestField("Account Type", BankAccReconLine."Account Type");
                    TestField("Account No.", BankAccReconLine."Account No.");
                    if "Applies-to Entry No." <> 0 then begin
                        case "Account Type" of
                            "Account Type"::Customer:
                                ApplyCustLedgEntry(
                                  AppliedPmtEntry, GenJnlLine."Applies-to ID", GenJnlLine."Posting Date", 0D, 0D, "Applied Pmt. Discount");
                            "Account Type"::Vendor:
                                ApplyVendLedgEntry(
                                  AppliedPmtEntry, GenJnlLine."Applies-to ID", GenJnlLine."Posting Date", 0D, 0D, "Applied Pmt. Discount");
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
                                                    BankAccountLedgerEntry.Modify();
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
                        IsApplied := true;
                    end;
                until Next = 0;

        if PaymentLineAmount <> 0 then begin
            if not IsApplied then
                GenJnlLine."Applies-to ID" := '';
            if (GenJnlLine."Account Type" <> GenJnlLine."Account Type"::"Bank Account") or
               (GenJnlLine."Currency Code" = BankAcc."Currency Code")
            then begin
                GenJnlLine.Validate("Currency Code", BankAcc."Currency Code");
                GenJnlLine.Amount := -PaymentLineAmount;
                if GenJnlLine."Currency Code" <> '' then
                    GenJnlLine."Amount (LCY)" := Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Posting Date", GenJnlLine."Currency Code",
                          GenJnlLine.Amount, GenJnlLine."Currency Factor"));
                GenJnlLine.Validate("VAT %");
                GenJnlLine.Validate("Bal. VAT %")
            end else begin
                GLSetup.Get();
                Error(ExcessiveAmtErr, PaymentLineAmount, GLSetup.GetCurrencyCode(BankAcc."Currency Code"));
            end;

            OnPostPaymentApplicationsOnBeforeValidateApplyRequirements(BankAccReconLine, GenJnlLine, AppliedAmount);

            GenJnlLine.ValidateApplyRequirements(GenJnlLine);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
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

    local procedure UpdateBank(BankAccRecon: Record "Bank Acc. Reconciliation"; Amt: Decimal)
    begin
        with BankAcc do begin
            LockTable();
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
        BankAccStmt.Init();
        BankAccStmt.TransferFields(BankAccRecon);
        if BankAccStmtExists then
            BankAccStmt."Statement No." := GetNextStatementNoAndUpdateBankAccount(BankAccRecon."Bank Account No.");
        if BankAccReconLine.LinesExist(BankAccRecon) then
            repeat
                BankAccStmtLine.TransferFields(BankAccReconLine);
                BankAccStmtLine."Statement No." := BankAccStmt."Statement No.";
                BankAccStmtLine.Insert();
                BankAccReconLine.ClearDataExchEntries;
            until BankAccReconLine.Next = 0;

        OnBeforeBankAccStmtInsert(BankAccStmt, BankAccRecon);
        BankAccStmt.Insert();
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

                PostedPmtReconLine.Insert();
                BankAccReconLine.ClearDataExchEntries;
            until BankAccReconLine.Next = 0;

        PostedPmtReconHdr.TransferFields(BankAccRecon);
        OnBeforePostedPmtReconInsert(PostedPmtReconHdr, BankAccRecon);
        PostedPmtReconHdr.Insert();
    end;

    procedure ApplyCustLedgEntry(AppliedPmtEntry: Record "Applied Payment Entry"; AppliesToID: Code[50]; PostingDate: Date; PmtDiscDueDate: Date; PmtDiscToleranceDate: Date; RemPmtDiscPossible: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        with CustLedgEntry do begin
            Get(AppliedPmtEntry."Applies-to Entry No.");
            TestField(Open);
            BankAcc.Get(AppliedPmtEntry."Bank Account No.");
            if AppliesToID = '' then begin
                "Pmt. Discount Date" := PmtDiscDueDate;
                "Pmt. Disc. Tolerance Date" := PmtDiscToleranceDate;

                "Remaining Pmt. Disc. Possible" := RemPmtDiscPossible;
                if BankAcc.IsInLocalCurrency then
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
            BankAcc.Get(AppliedPmtEntry."Bank Account No.");
            if AppliesToID = '' then begin
                "Pmt. Discount Date" := PmtDiscDueDate;
                "Pmt. Disc. Tolerance Date" := PmtDiscToleranceDate;

                "Remaining Pmt. Disc. Possible" := RemPmtDiscPossible;
                if BankAcc.IsInLocalCurrency then
                    "Remaining Pmt. Disc. Possible" :=
                      CurrExchRate.ExchangeAmount("Remaining Pmt. Disc. Possible", '', "Currency Code", PostingDate);
            end else begin
                "Applies-to ID" := AppliesToID;
                "Amount to Apply" := AppliedPmtEntry.CalcAmountToApply(PostingDate);
            end;

            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
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

            CheckLedgerEntry.Reset();
            CheckLedgerEntry.SetCurrentKey("Bank Account Ledger Entry No.");
            CheckLedgerEntry.SetRange(
              "Bank Account Ledger Entry No.", "Entry No.");
            CheckLedgerEntry.SetRange(Open, true);
            if CheckLedgerEntry.FindSet then
                repeat
                    CheckLedgerEntry.Open := false;
                    CheckLedgerEntry."Statement Status" := CheckLedgerEntry."Statement Status"::Closed;
                    CheckLedgerEntry.Modify();
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
    local procedure OnAfterFinalizePost(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
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

