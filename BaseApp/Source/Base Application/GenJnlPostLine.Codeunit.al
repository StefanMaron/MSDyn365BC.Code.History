﻿codeunit 12 "Gen. Jnl.-Post Line"
{
    Permissions = TableData "G/L Account" = r,
                  TableData "G/L Entry" = rimd,
                  TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "G/L Register" = imd,
                  TableData "G/L Entry - VAT Entry Link" = rimd,
                  TableData "VAT Entry" = imd,
                  TableData "Bank Account Ledger Entry" = imd,
                  TableData "Check Ledger Entry" = imd,
                  TableData "Detailed Cust. Ledg. Entry" = imd,
                  TableData "Detailed Vendor Ledg. Entry" = imd,
                  TableData "Line Fee Note on Report Hist." = rim,
                  TableData "FA Ledger Entry" = rimd,
                  TableData "FA Register" = imd,
                  TableData "Maintenance Ledger Entry" = rimd,
                  TableData "Tax Diff. Register" = imd,
                  TableData "Tax Diff. Ledger Entry" = rimd;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        GetGLSetup();
        RunWithCheck(Rec);
    end;

    var
        NeedsRoundingErr: Label '%1 needs to be rounded';
        PurchaseAlreadyExistsErr: Label 'Purchase %1 %2 already exists for this vendor.', Comment = '%1 = Document Type; %2 = Document No.';
        BankPaymentTypeMustNotBeFilledErr: Label 'Bank Payment Type must not be filled if Currency Code is different in Gen. Journal Line and Bank Account.';
        DocNoMustBeEnteredErr: Label 'Document No. must be entered when Bank Payment Type is %1.';
        CheckAlreadyExistsErr: Label 'Check %1 already exists for this Bank Account.';
        GLSetup: Record "General Ledger Setup";
        GlobalGLEntry: Record "G/L Entry";
        TempGLEntryBuf: Record "G/L Entry" temporary;
        TempGLEntryVAT: Record "G/L Entry" temporary;
        TempGLEntryPreview: Record "G/L Entry" temporary;
        GLReg: Record "G/L Register";
        AddCurrency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        VATEntry: Record "VAT Entry";
        TaxDetail: Record "Tax Detail";
        UnrealizedCustLedgEntry: Record "Cust. Ledger Entry";
        UnrealizedVendLedgEntry: Record "Vendor Ledger Entry";
        TempGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link" temporary;
        TempVATEntry: Record "VAT Entry" temporary;
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        InitialCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        VATEntryToRealize: Record "VAT Entry";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        PrepmtDiffMgt: Codeunit PrepmtDiffManagement;
        DeferralUtilities: Codeunit "Deferral Utilities";
        DeferralDocType: Enum "Deferral Document Type";
        LastDocType: Enum "Gen. Journal Document Type";
        AddCurrencyCode: Code[10];
        GLSourceCode: Code[10];
        LastDocNo: Code[20];
        FiscalYearStartDate: Date;
        CurrencyDate: Date;
        LastDate: Date;
        BalanceCheckAmount: Decimal;
        BalanceCheckAmount2: Decimal;
        BalanceCheckAddCurrAmount: Decimal;
        BalanceCheckAddCurrAmount2: Decimal;
        CurrentBalance: Decimal;
        TotalAddCurrAmount: Decimal;
        TotalAmount: Decimal;
        UnrealizedRemainingAmountCust: Decimal;
        UnrealizedRemainingAmountVend: Decimal;
        AmountRoundingPrecision: Decimal;
        AddCurrGLEntryVATAmt: Decimal;
        CurrencyFactor: Decimal;
        FirstEntryNo: Integer;
        NextEntryNo: Integer;
        NextVATEntryNo: Integer;
        FirstNewVATEntryNo: Integer;
        FirstTransactionNo: Integer;
        NextTransactionNo: Integer;
        NextConnectionNo: Integer;
        NextCheckEntryNo: Integer;
        InsertedTempGLEntryVAT: Integer;
        GLEntryNo: Integer;
        UseCurrFactorOnly: Boolean;
        NonAddCurrCodeOccured: Boolean;
        FADimAlreadyChecked: Boolean;
        ResidualRoundingErr: Label 'Residual caused by rounding of %1';
        DimensionUsedErr: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5.', Comment = 'Comment';
        OverrideDimErr: Boolean;
        JobLine: Boolean;
        CheckUnrealizedCust: Boolean;
        CheckUnrealizedVend: Boolean;
        GLSetupRead: Boolean;
        GLEntryInconsistent: Boolean;
        TransVATAccNo: Code[20];
        MustNotBeAfterErr: Label 'Posting date must not be after %1 in %2 entry no. %3.';
        MultipleEntriesApplnErr: Label 'Only application of one entry to several entries is allowed in Russian version.';
        CheckApplnDateCustErr: Label 'Check Application Date is not possible for Customer %1 if Application Method = Apply to Oldest.';
        CheckApplnDateVendErr: Label 'Check Application Date is not possible for Vendor %1 if Application Method = Apply to Oldest.';
        PrepmtCorrectionErr: Label 'Correction must be No in prepayment.';
        ThisIsSpecialRun: Boolean;
        FirstGLEntryNo: Integer;
        ApplnInDiffCurrencyErr: Label 'Application of %1 with currency code %2 to %3 with currency code %4 is not allowed.';
        ApplnPrepmtOnlyErr: Label 'Application is valid with Document Type Prepayment only.';
        PostedTaxDiffReverseErr: Label 'Posted Tax Difference already exists for transaction no. %1. You should reverse these entries before unapply operation.';
        PostedTaxDiffAlreadyExistErr: Label 'Posted Tax Difference already exists for transaction no. %1.';
        AgreementMustBeErr: Label 'Agreement must be %1 in document no. %2.';
        FinVoidedCheck: Boolean;
        PreviewMode: Boolean;
        VATAgentVATPayment: Boolean;
        VATAgentVATPmtAmount: Decimal;
        IsVendBackPrepmt: Boolean;
        InvalidPostingDateErr: Label '%1 is not within the range of posting dates for your company.', Comment = '%1=The date passed in for the posting date.';
        DescriptionMustNotBeBlankErr: Label 'When %1 is selected for %2, %3 must have a value.', Comment = '%1: Field Omit Default Descr. in Jnl., %2 G/L Account No, %3 Description';
        NoDeferralScheduleErr: Label 'You must create a deferral schedule if a deferral template is selected. Line: %1, Deferral Template: %2.', Comment = '%1=The line number of the general ledger transaction, %2=The Deferral Template Code';
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0. Line: %1, Deferral Template: %2.', Comment = '%1=The line number of the general ledger transaction, %2=The Deferral Template Code';
        IsGLRegInserted: Boolean;

    procedure GetGLReg(var NewGLReg: Record "G/L Register")
    begin
        NewGLReg := GLReg;
    end;

    procedure RunWithCheck(var GenJnlLine2: Record "Gen. Journal Line"): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        OnBeforeRunWithCheck(GenJnlLine, GenJnlLine2);

        GenJnlLine.Copy(GenJnlLine2);
        Code(GenJnlLine, true);
        OnAfterRunWithCheck(GenJnlLine);
        GenJnlLine2 := GenJnlLine;
        exit(GLEntryNo);
    end;

    procedure RunWithoutCheck(var GenJnlLine2: Record "Gen. Journal Line"): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        OnBeforeRunWithoutCheck(GenJnlLine, GenJnlLine2);

        GenJnlLine.Copy(GenJnlLine2);
        Code(GenJnlLine, false);
        OnAfterRunWithoutCheck(GenJnlLine);
        GenJnlLine2 := GenJnlLine;
        exit(GLEntryNo);
    end;

    local procedure "Code"(var GenJnlLine: Record "Gen. Journal Line"; CheckLine: Boolean)
    var
        Balancing: Boolean;
        IsTransactionConsistent: Boolean;
        IsPosted: Boolean;
    begin
        IsPosted := false;
        OnBeforeCode(GenJnlLine, CheckLine, IsPosted, GLReg);
        if IsPosted then
            exit;

        GetGLSourceCode;

        with GenJnlLine do begin
            if EmptyLine then begin
                InitLastDocDate(GenJnlLine);
                exit;
            end;

            if CheckLine then begin
                if OverrideDimErr then
                    GenJnlCheckLine.SetOverDimErr;
                GenJnlCheckLine.RunCheck(GenJnlLine);
            end;

            AmountRoundingPrecision := InitAmounts(GenJnlLine);

            if "Bill-to/Pay-to No." = '' then
                case true of
                    "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]:
                        "Bill-to/Pay-to No." := "Account No.";
                    "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]:
                        "Bill-to/Pay-to No." := "Bal. Account No.";
                end;
            if "Document Date" = 0D then
                "Document Date" := "Posting Date";
            if "Due Date" = 0D then
                "Due Date" := "Posting Date";

            FindJobLineSign(GenJnlLine);

            if "Prepmt. Diff." then begin
                "Document Type" := InitialCVLedgEntryBuf."Document Type";
                "Document No." := InitialCVLedgEntryBuf."Document No.";
            end;

            VATAgentVATPayment := IsVATAgentVATPayment(GenJnlLine);

            OnBeforeStartOrContinuePosting(GenJnlLine, LastDocType.AsInteger(), LastDocNo, LastDate, NextEntryNo);

            if NextEntryNo = 0 then
                StartPosting(GenJnlLine)
            else
                ContinuePosting(GenJnlLine);

            if "Account No." <> '' then begin
                if ("Bal. Account No." <> '') and
                   (not "System-Created Entry") and
                   ("Account Type" in
                    ["Account Type"::Customer,
                     "Account Type"::Vendor,
                     "Account Type"::"Fixed Asset"])
                then begin
                    CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);
                    OnCodeOnAfterRunExhangeAccGLJournalLine(GenJnlLine, Balancing);
                    Balancing := true;
                end;

                PostGenJnlLine(GenJnlLine, Balancing);
            end;

            if "Bal. Account No." <> '' then begin
                CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);
                OnCodeOnAfterRunExhangeAccGLJournalLine(GenJnlLine, Balancing);
                PostGenJnlLine(GenJnlLine, not Balancing);
            end;

            if GLSetup."Enable Russian Tax Accounting" and ("Tax. Diff. Dtld. Entry No." <> 0) then
                UpdateTaxDiff(GenJnlLine);

            CheckPostUnrealizedVAT(GenJnlLine, true);

            CreateDeferralScheduleFromGL(GenJnlLine, Balancing);

            OnCodeOnBeforeFinishPosting(GenJnlLine, Balancing);
            IsTransactionConsistent := FinishPosting(GenJnlLine);
            GLEntryInconsistent := not IsTransactionConsistent;
        end;

        OnAfterGLFinishPosting(
          GlobalGLEntry, GenJnlLine, IsTransactionConsistent, FirstTransactionNo, GLReg, TempGLEntryBuf, NextEntryNo, NextTransactionNo);
    end;

    internal procedure IsGLEntryInconsistent(): Boolean
    begin
        exit(GLEntryInconsistent);
    end;

    internal procedure ShowInconsistentEntries()
    begin
        Page.Run(Page::"G/L Entries Preview", TempGLEntryPreview);
    end;

    local procedure PostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; Balancing: Boolean)
    begin
        OnBeforePostGenJnlLine(GenJnlLine, Balancing);

        with GenJnlLine do
            case "Account Type" of
                "Account Type"::"G/L Account":
                    PostGLAcc(GenJnlLine, Balancing);
                "Account Type"::Customer:
                    PostCust(GenJnlLine, Balancing);
                "Account Type"::Vendor:
                    PostVend(GenJnlLine, Balancing);
                "Account Type"::"Bank Account":
                    PostBankAcc(GenJnlLine, Balancing);
                "Account Type"::"Fixed Asset":
                    PostFixedAsset(GenJnlLine);
                "Account Type"::"IC Partner":
                    PostICPartner(GenJnlLine);
            end;

        OnAfterPostGenJnlLine(GenJnlLine, Balancing);
    end;

    local procedure InitAmounts(var GenJnlLine: Record "Gen. Journal Line"): Decimal
    var
        Currency: Record Currency;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitAmounts(GenJnlLine, Currency, IsHandled);
        if IsHandled then
            exit(Currency."Amount Rounding Precision");

        with GenJnlLine do begin
            if "Currency Code" = '' then begin
                Currency.InitRoundingPrecision();
                "Amount (LCY)" := Amount;
                "VAT Amount (LCY)" := "VAT Amount";
                "VAT Base Amount (LCY)" := "VAT Base Amount";
            end else begin
                Currency.Get("Currency Code");
                Currency.TestField("Amount Rounding Precision");
                if not "System-Created Entry" then begin
                    "Source Currency Code" := "Currency Code";
                    "Source Currency Amount" := Amount;
                    "Source Curr. VAT Base Amount" := "VAT Base Amount";
                    "Source Curr. VAT Amount" := "VAT Amount";
                end;
            end;
            if "Additional-Currency Posting" = "Additional-Currency Posting"::None then begin
                IsHandled := false;
                OnInitAmountsOnAddCurrencyPostingNone(GenJnlLine, IsHandled);
                if not IsHandled then begin
                    if Amount <> Round(Amount, Currency."Amount Rounding Precision") then
                        FieldError(
                          Amount,
                          StrSubstNo(NeedsRoundingErr, Amount));
                    if "Amount (LCY)" <> Round("Amount (LCY)") then
                        FieldError(
                          "Amount (LCY)",
                          StrSubstNo(NeedsRoundingErr, "Amount (LCY)"));
                end;
            end;
            exit(Currency."Amount Rounding Precision");
        end;
    end;

    procedure InitLastDocDate(GenJnlLine: Record "Gen. Journal Line")
    begin
        with GenJnlLine do begin
            LastDocType := "Document Type";
            LastDocNo := "Document No.";
            LastDate := "Posting Date";
        end;

        OnAfterInitLastDocDate(GenJnlLine);
    end;

    local procedure InitNextEntryNo()
    var
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        GLEntry.LockTable();
        GLEntry.GetLastEntry(LastEntryNo, LastTransactionNo);
        NextEntryNo := LastEntryNo + 1;
        NextTransactionNo := LastTransactionNo + 1;
    end;

    procedure InitVAT(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        LCYCurrency: Record Currency;
        GenPostingSetup: Record "General Posting Setup";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitVAT(GenJnlLine, GLEntry, VATPostingSetup, IsHandled, LCYCurrency, AddCurrencyCode, AddCurrGLEntryVATAmt);
        if IsHandled then
            exit;

        LCYCurrency.InitRoundingPrecision();
        with GenJnlLine do
            if "Gen. Posting Type" <> "Gen. Posting Type"::" " then begin // None
                VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                IsHandled := false;
                OnInitVATOnBeforeVATPostingSetupCheck(GenJnlLine, GLEntry, VATPostingSetup, IsHandled);
                if not IsHandled then
                    TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type");
                case "VAT Posting" of
                    "VAT Posting"::"Automatic VAT Entry":
                        begin
                            GLEntry.CopyPostingGroupsFromGenJnlLine(GenJnlLine);
                            case "VAT Calculation Type" of
                                "VAT Calculation Type"::"Normal VAT":
                                    begin
                                        IsHandled := false;
                                        OnInitVATOnVATCalculationTypeNormal(GenJnlLine, IsHandled);
                                        if not IsHandled then
                                            if "VAT Difference" <> 0 then begin
                                                GLEntry.Amount := "VAT Base Amount (LCY)";
                                                GLEntry."VAT Amount" := "Amount (LCY)" - GLEntry.Amount;
                                                GLEntry."Additional-Currency Amount" := "Source Curr. VAT Base Amount";
                                                if "Source Currency Code" = AddCurrencyCode then
                                                    AddCurrGLEntryVATAmt := "Source Curr. VAT Amount"
                                                else
                                                    AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                            end else begin
                                                GLEntry."VAT Amount" :=
                                                  Round(
                                                    "Amount (LCY)" * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"),
                                                    LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection);
                                                GLEntry.Amount := "Amount (LCY)" - GLEntry."VAT Amount";
                                                if "Source Currency Code" = AddCurrencyCode then
                                                    AddCurrGLEntryVATAmt :=
                                                      Round(
                                                        "Source Currency Amount" * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"),
                                                        AddCurrency."Amount Rounding Precision", AddCurrency.VATRoundingDirection)
                                                else
                                                    AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                                GLEntry."Additional-Currency Amount" := "Source Currency Amount" - AddCurrGLEntryVATAmt;
                                            end;
                                    end;
                                "VAT Calculation Type"::"Reverse Charge VAT":
                                    case "Gen. Posting Type" of
                                        "Gen. Posting Type"::Purchase:
                                            if "VAT Difference" <> 0 then begin
                                                GLEntry."VAT Amount" := "VAT Amount (LCY)";
                                                if "Source Currency Code" = AddCurrencyCode then
                                                    AddCurrGLEntryVATAmt := "Source Curr. VAT Amount"
                                                else
                                                    AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                            end else begin
                                                GLEntry."VAT Amount" :=
                                                  Round(
                                                    GLEntry.Amount * VATPostingSetup."VAT %" / 100,
                                                    LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection);
                                                if "Source Currency Code" = AddCurrencyCode then
                                                    AddCurrGLEntryVATAmt :=
                                                      Round(
                                                        GLEntry."Additional-Currency Amount" * VATPostingSetup."VAT %" / 100,
                                                        AddCurrency."Amount Rounding Precision", AddCurrency.VATRoundingDirection)
                                                else
                                                    AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                            end;
                                        "Gen. Posting Type"::Sale:
                                            begin
                                                GLEntry."VAT Amount" := 0;
                                                AddCurrGLEntryVATAmt := 0;
                                            end;
                                    end;
                                "VAT Calculation Type"::"Full VAT":
                                    begin
                                        IsHandled := false;
                                        OnInitVATOnBeforeTestFullVATAccount(GenJnlLine, GLEntry, VATPostingSetup, IsHandled);
                                        if not IsHandled then
                                            case "Gen. Posting Type" of
                                                "Gen. Posting Type"::Sale:
                                                    TestField("Account No.", VATPostingSetup.GetSalesAccount(false));
                                                "Gen. Posting Type"::Purchase:
                                                    TestField("Account No.", VATPostingSetup.GetPurchAccount(false));
                                            end;
                                        GLEntry.Amount := 0;
                                        GLEntry."Additional-Currency Amount" := 0;
                                        GLEntry."VAT Amount" := "Amount (LCY)";
                                        if "Source Currency Code" = AddCurrencyCode then
                                            AddCurrGLEntryVATAmt := "Source Currency Amount"
                                        else
                                            AddCurrGLEntryVATAmt := CalcLCYToAddCurr("Amount (LCY)");
                                    end;
                                "VAT Calculation Type"::"Sales Tax":
                                    begin
                                        if ("Gen. Posting Type" = "Gen. Posting Type"::Purchase) and
                                           "Use Tax"
                                        then begin
                                            GLEntry."VAT Amount" :=
                                              Round(
                                                SalesTaxCalculate.CalculateTax(
                                                  "Tax Area Code", "Tax Group Code", "Tax Liable",
                                                  "Posting Date", "Amount (LCY)", Quantity, 0));
                                            OnAfterSalesTaxCalculateCalculateTax(GenJnlLine, GLEntry, LCYCurrency);
                                            GLEntry.Amount := "Amount (LCY)";
                                        end else begin
                                            GLEntry.Amount :=
                                              Round(
                                                SalesTaxCalculate.ReverseCalculateTax(
                                                  "Tax Area Code", "Tax Group Code", "Tax Liable",
                                                  "Posting Date", "Amount (LCY)", Quantity, 0));
                                            OnAfterSalesTaxCalculateReverseCalculateTax(GenJnlLine, GLEntry, LCYCurrency);
                                            GLEntry."VAT Amount" := "Amount (LCY)" - GLEntry.Amount;
                                        end;
                                        GLEntry."Additional-Currency Amount" := "Source Currency Amount";
                                        if "Source Currency Code" = AddCurrencyCode then
                                            AddCurrGLEntryVATAmt := "Source Curr. VAT Amount"
                                        else
                                            AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                    end;
                            end;
                        end;
                    "VAT Posting"::"Manual VAT Entry":
                        if "Gen. Posting Type" <> "Gen. Posting Type"::Settlement then begin
                            GLEntry.CopyPostingGroupsFromGenJnlLine(GenJnlLine);
                            GLEntry."VAT Amount" := "VAT Amount (LCY)";
                            if "Source Currency Code" = AddCurrencyCode then
                                AddCurrGLEntryVATAmt := "Source Curr. VAT Amount"
                            else
                                AddCurrGLEntryVATAmt := CalcLCYToAddCurr("VAT Amount (LCY)");
                        end;
                end;
                if GLSetup."Enable Russian Accounting" then
                    if ("Gen. Posting Type" <> "Gen. Posting Type"::Sale) or
                       ("VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT") or
                       (VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::" ")
                    then
                        TransVATAccNo := ''
                    else begin
                        if (GLEntry."G/L Account No." = '') and ("Gen. Posting Type" = "Gen. Posting Type"::Sale) then
                            if VATPostingSetup."Trans. VAT Type" <> VATPostingSetup."Trans. VAT Type"::" " then
                                VATPostingSetup.TestField("Trans. VAT Account");
                        if "VAT Posting" = "VAT Posting"::"Automatic VAT Entry" then begin
                            if VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax" then begin
                                GLEntry.Amount := "Amount (LCY)";
                                GLEntry."Additional-Currency Amount" := "Source Currency Amount";
                            end;
                            if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then begin
                                VATPostingSetup.TestField("Trans. VAT Account");
                                GLEntry."G/L Account No." := VATPostingSetup."Trans. VAT Account";
                            end;
                        end else begin
                            if VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax" then begin
                                GLEntry.Amount += GLEntry."VAT Amount";
                                GLEntry."Additional-Currency Amount" += AddCurrGLEntryVATAmt;
                            end;
                            if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then begin
                                GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                                GenPostingSetup.TestField("Sales Full Tax VAT Account");
                                GLEntry."G/L Account No." := GenPostingSetup."Sales Full Tax VAT Account";
                            end;
                        end;
                        if VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::" " then
                            TransVATAccNo := ''
                        else
                            if VATPostingSetup."Trans. VAT Account" <> '' then
                                TransVATAccNo := VATPostingSetup."Trans. VAT Account"
                            else
                                TransVATAccNo := GLEntry."G/L Account No.";
                    end;
            end;

        GLEntry."Additional-Currency Amount" :=
          GLCalcAddCurrency(GLEntry.Amount, GLEntry."Additional-Currency Amount", GLEntry."Additional-Currency Amount", true, GenJnlLine);

        OnAfterInitVAT(GenJnlLine, GLEntry, VATPostingSetup, AddCurrGLEntryVATAmt);
    end;

    procedure PostVAT(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; VATPostingSetup: Record "VAT Posting Setup")
    var
        TaxDetail2: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        VATAmount: Decimal;
        VATAmount2: Decimal;
        VATBase: Decimal;
        VATBase2: Decimal;
        SrcCurrVATAmount: Decimal;
        SrcCurrVATBase: Decimal;
        SrcCurrSalesTaxBaseAmount: Decimal;
        RemSrcCurrVATAmount: Decimal;
        SalesTaxBaseAmount: Decimal;
        TaxDetailFound: Boolean;
        IsHandled: Boolean;
        TransVATGLEntryAccNo: Code[20];
    begin
        IsHandled := false;
        OnBeforePostVAT(GenJnlLine, GLEntry, VATPostingSetup, IsHandled, AddCurrGLEntryVATAmt, NextConnectionNo);
        if IsHandled then
            exit;

        with GenJnlLine do
            // Post VAT
            // VAT for VAT entry
            case "VAT Calculation Type" of
                "VAT Calculation Type"::"Normal VAT",
                "VAT Calculation Type"::"Reverse Charge VAT",
                "VAT Calculation Type"::"Full VAT":
                    begin
                        if "VAT Posting" = "VAT Posting"::"Automatic VAT Entry" then
                            "VAT Base Amount (LCY)" := GLEntry.Amount;
                        if "Gen. Posting Type" = "Gen. Posting Type"::Settlement then
                            AddCurrGLEntryVATAmt := "Source Curr. VAT Amount";
                        InsertVAT(
                          GenJnlLine, VATPostingSetup,
                          GLEntry.Amount, GLEntry."VAT Amount", "VAT Base Amount (LCY)", "Source Currency Code",
                          GLEntry."Additional-Currency Amount", AddCurrGLEntryVATAmt, "Source Curr. VAT Base Amount");
                        NextConnectionNo := NextConnectionNo + 1;
                    end;
                "VAT Calculation Type"::"Sales Tax":
                    begin
                        case "VAT Posting" of
                            "VAT Posting"::"Automatic VAT Entry":
                                SalesTaxBaseAmount := GLEntry.Amount;
                            "VAT Posting"::"Manual VAT Entry":
                                SalesTaxBaseAmount := "VAT Base Amount (LCY)";
                        end;
                        if ("VAT Posting" = "VAT Posting"::"Manual VAT Entry") and
                           ("Gen. Posting Type" = "Gen. Posting Type"::Settlement)
                        then
                            InsertVAT(
                              GenJnlLine, VATPostingSetup,
                              GLEntry.Amount, GLEntry."VAT Amount", "VAT Base Amount (LCY)", "Source Currency Code",
                              "Source Curr. VAT Base Amount", "Source Curr. VAT Amount", "Source Curr. VAT Base Amount")
                        else begin
                            Clear(SalesTaxCalculate);
                            SalesTaxCalculate.InitSalesTaxLines(
                              "Tax Area Code", "Tax Group Code", "Tax Liable",
                              SalesTaxBaseAmount, Quantity, "Posting Date", GLEntry."VAT Amount");
                            OnAfterSalesTaxCalculateInitSalesTaxLines(GenJnlLine, GLEntry, SalesTaxBaseAmount);
                            SrcCurrVATAmount := 0;
                            SrcCurrSalesTaxBaseAmount := CalcLCYToAddCurr(SalesTaxBaseAmount);
                            RemSrcCurrVATAmount := AddCurrGLEntryVATAmt;
                            TaxDetailFound := false;
                            if GLSetup."Enable Russian Accounting" then
                                TransVATGLEntryAccNo := TransVATAccNo;
                            while SalesTaxCalculate.GetSalesTaxLine(TaxDetail2, VATAmount, VATBase) do begin
                                RemSrcCurrVATAmount := RemSrcCurrVATAmount - SrcCurrVATAmount;
                                if TaxDetailFound then
                                    InsertVAT(
                                      GenJnlLine, VATPostingSetup,
                                      SalesTaxBaseAmount, VATAmount2, VATBase2, "Source Currency Code",
                                      SrcCurrSalesTaxBaseAmount, SrcCurrVATAmount, SrcCurrVATBase);
                                TaxDetailFound := true;
                                TaxDetail := TaxDetail2;
                                VATAmount2 := VATAmount;
                                VATBase2 := VATBase;
                                SrcCurrVATAmount := CalcLCYToAddCurr(VATAmount);
                                SrcCurrVATBase := CalcLCYToAddCurr(VATBase);
                                if GLSetup."Enable Russian Accounting" then
                                    if "Gen. Posting Type" = "Gen. Posting Type"::Sale then
                                        if VATPostingSetup."Trans. VAT Type" <> VATPostingSetup."Trans. VAT Type"::" " then begin
                                            TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
                                            TaxJurisdiction.TestField("Trans. VAT Type", VATPostingSetup."Trans. VAT Type");
                                            if TaxJurisdiction."Trans. VAT Account" <> '' then
                                                TransVATAccNo := TaxJurisdiction."Trans. VAT Account"
                                            else
                                                TransVATAccNo := TransVATGLEntryAccNo;
                                        end;
                            end;
                            if TaxDetailFound then
                                InsertVAT(
                                  GenJnlLine, VATPostingSetup,
                                  SalesTaxBaseAmount, VATAmount2, VATBase2, "Source Currency Code",
                                  SrcCurrSalesTaxBaseAmount, RemSrcCurrVATAmount, SrcCurrVATBase);
                            InsertSummarizedVAT(GenJnlLine, VATPostingSetup);
                        end;
                    end;
            end;

        if GLSetup."Enable Russian Accounting" then
            TransVATAccNo := '';

        OnAfterPostVAT(GenJnlLine, GLEntry, VATPostingSetup, TaxDetail, NextConnectionNo, AddCurrGLEntryVATAmt, AddCurrencyCode, UseCurrFactorOnly);
    end;

    procedure InsertVAT(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; GLEntryAmount: Decimal; GLEntryVATAmount: Decimal; GLEntryBaseAmount: Decimal; SrcCurrCode: Code[10]; SrcCurrGLEntryAmt: Decimal; SrcCurrGLEntryVATAmt: Decimal; SrcCurrGLEntryBaseAmt: Decimal)
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        FA: Record "Fixed Asset";
        VATAmount: Decimal;
        VATBase: Decimal;
        SrcCurrVATAmount: Decimal;
        SrcCurrVATBase: Decimal;
        VATDifferenceLCY: Decimal;
        SrcCurrVATDifference: Decimal;
        UnrealizedVAT: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertVAT(
          GenJnlLine, VATEntry, UnrealizedVAT, AddCurrencyCode, VATPostingSetup, GLEntryAmount, GLEntryVATAmount, GLEntryBaseAmount,
          SrcCurrCode, SrcCurrGLEntryAmt, SrcCurrGLEntryVATAmt, SrcCurrGLEntryBaseAmt, IsHandled);
        if IsHandled then
            exit;

        with GenJnlLine do begin
            // Post VAT
            // VAT for VAT entry
            VATEntry.Init();
            VATEntry.CopyFromGenJnlLine(GenJnlLine);
            VATEntry."Entry No." := NextVATEntryNo;
            VATEntry."EU Service" := VATPostingSetup."EU Service";
            VATEntry."Transaction No." := NextTransactionNo;
            VATEntry."Sales Tax Connection No." := NextConnectionNo;
            if GLSetup."Enable Russian Accounting" then
                if Prepayment and ("VAT Calculation Type" = "VAT Calculation Type"::"Full VAT") then begin
                    TestField("Initial Entry No.");
                    VATEntry."CV Ledg. Entry No." := "Initial Entry No.";
                    GLEntryBaseAmount := "Advance VAT Base Amount";
                end;
            OnInsertVATOnAfterAssignVATEntryFields(GenJnlLine, VATEntry, CurrExchRate);

            if "VAT Difference" = 0 then
                VATDifferenceLCY := 0
            else
                if "Currency Code" = '' then
                    VATDifferenceLCY := "VAT Difference"
                else
                    VATDifferenceLCY :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code", "VAT Difference",
                          CurrExchRate.ExchangeRate("Posting Date", "Currency Code")));

            OnInsertVATOnAfterCalcVATDifferenceLCY(GenJnlLine, VATEntry, VATDifferenceLCY);

            if ("Account Type" = "Account Type"::"Fixed Asset") and ("Object Type" <> "Object Type"::"G/L Account") then begin
                "Account Type" := "Gen. Journal Account Type".FromInteger("Object Type");
                "Account No." := "Object No."
            end;

            if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then
                UpdateVATEntryTaxDetails(GenJnlLine, VATEntry, TaxDetail, TaxJurisdiction);

            if GLSetup."Enable Russian Accounting" then begin
                if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then
                    VATEntry."Tax Invoice Amount Type" := TaxJurisdiction."Sales Tax Amount Type"
                else
                    VATEntry."Tax Invoice Amount Type" := VATPostingSetup."Tax Invoice Amount Type";
                VATEntry."Manual VAT Settlement" := VATPostingSetup."Manual VAT Settlement";
                if VATEntry."Object Type" = VATEntry."Object Type"::"Fixed Asset" then
                    if FA.Get(VATEntry."Object No.") then
                        case FA."FA Type" of
                            FA."FA Type"::"Fixed Assets":
                                VATEntry."VAT Settlement Type" := VATEntry."VAT Settlement Type"::"by Act";
                            FA."FA Type"::"Future Expense":
                                VATEntry."VAT Settlement Type" := VATEntry."VAT Settlement Type"::"Future Expenses";
                        end;
            end;

            if AddCurrencyCode <> '' then
                if AddCurrencyCode <> SrcCurrCode then begin
                    SrcCurrGLEntryAmt := ExchangeAmtLCYToFCY2(GLEntryAmount);
                    SrcCurrGLEntryVATAmt := ExchangeAmtLCYToFCY2(GLEntryVATAmount);
                    SrcCurrGLEntryBaseAmt := ExchangeAmtLCYToFCY2(GLEntryBaseAmount);
                    SrcCurrVATDifference := ExchangeAmtLCYToFCY2(VATDifferenceLCY);
                end else
                    SrcCurrVATDifference := "VAT Difference";

            UnrealizedVAT :=
              (((VATPostingSetup."Unrealized VAT Type" > 0) and
                (VATPostingSetup."VAT Calculation Type" in
                 [VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                  VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
                  VATPostingSetup."VAT Calculation Type"::"Full VAT"])) or
               ((TaxJurisdiction."Unrealized VAT Type" > 0) and
                (VATPostingSetup."VAT Calculation Type" in
                 [VATPostingSetup."VAT Calculation Type"::"Sales Tax"]))) and
              IsNotPayment("Document Type");
            if GLSetup."Prepayment Unrealized VAT" and not GLSetup."Unrealized VAT" and
               (VATPostingSetup."Unrealized VAT Type" > 0)
            then
                UnrealizedVAT := Prepayment;

            if GLSetup."Enable Russian Accounting" then begin
                UnrealizedVAT := UnrealizedVAT or
                  (VATPostingSetup."Unrealized VAT Type" > 0) and Prepayment and
                  ("Document Type" = "Document Type"::Payment);
                UnrealizedVAT :=
                  UnrealizedVAT or
                  ((VATPostingSetup."Unrealized VAT Type" > 0) and VATAgentVATPayment);
            end;

            // VAT for VAT entry
            if "Gen. Posting Type" <> "Gen. Posting Type"::" " then begin
                case "VAT Posting" of
                    "VAT Posting"::"Automatic VAT Entry":
                        begin
                            VATAmount := GLEntryVATAmount;
                            VATBase := GLEntryBaseAmount;
                            SrcCurrVATAmount := SrcCurrGLEntryVATAmt;
                            SrcCurrVATBase := SrcCurrGLEntryBaseAmt;
                            if GLSetup."Enable Russian Accounting" then
                                if ("Gen. Posting Type" = "Gen. Posting Type"::Sale) and
                                   (VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax") and
                                   ("VAT Calculation Type" <> "VAT Calculation Type"::"Sales Tax")
                                then begin
                                    VATBase := VATBase - VATAmount;
                                    SrcCurrVATBase := SrcCurrVATBase - SrcCurrVATAmount;
                                end;
                        end;
                    "VAT Posting"::"Manual VAT Entry":
                        begin
                            if "Gen. Posting Type" = "Gen. Posting Type"::Settlement then begin
                                VATAmount := GLEntryAmount;
                                SrcCurrVATAmount := SrcCurrGLEntryVATAmt;
                                VATEntry.Closed := true;
                            end else begin
                                VATAmount := GLEntryVATAmount;
                                SrcCurrVATAmount := SrcCurrGLEntryVATAmt;
                            end;
                            VATBase := GLEntryBaseAmount;
                            SrcCurrVATBase := SrcCurrGLEntryBaseAmt;
                        end;
                end;

                if UnrealizedVAT then begin
                    VATEntry.Amount := 0;
                    VATEntry.Base := 0;
                    VATEntry."Unrealized Amount" := VATAmount;
                    VATEntry."Unrealized Base" := VATBase;
                    VATEntry."Remaining Unrealized Amount" := VATEntry."Unrealized Amount";
                    VATEntry."Remaining Unrealized Base" := VATEntry."Unrealized Base";
                end else begin
                    VATEntry.Amount := VATAmount;
                    VATEntry.Base := VATBase;
                    VATEntry."Unrealized Amount" := 0;
                    VATEntry."Unrealized Base" := 0;
                    VATEntry."Remaining Unrealized Amount" := 0;
                    VATEntry."Remaining Unrealized Base" := 0;
                end;

                if AddCurrencyCode = '' then begin
                    VATEntry."Additional-Currency Base" := 0;
                    VATEntry."Additional-Currency Amount" := 0;
                    VATEntry."Add.-Currency Unrealized Amt." := 0;
                    VATEntry."Add.-Currency Unrealized Base" := 0;
                end else
                    if UnrealizedVAT then begin
                        VATEntry."Additional-Currency Base" := 0;
                        VATEntry."Additional-Currency Amount" := 0;
                        VATEntry."Add.-Currency Unrealized Base" := SrcCurrVATBase;
                        VATEntry."Add.-Currency Unrealized Amt." := SrcCurrVATAmount;
                    end else begin
                        VATEntry."Additional-Currency Base" := SrcCurrVATBase;
                        VATEntry."Additional-Currency Amount" := SrcCurrVATAmount;
                        VATEntry."Add.-Currency Unrealized Base" := 0;
                        VATEntry."Add.-Currency Unrealized Amt." := 0;
                    end;
                VATEntry."Add.-Curr. Rem. Unreal. Amount" := VATEntry."Add.-Currency Unrealized Amt.";
                VATEntry."Add.-Curr. Rem. Unreal. Base" := VATEntry."Add.-Currency Unrealized Base";
                VATEntry."VAT Difference" := VATDifferenceLCY;
                VATEntry."Add.-Curr. VAT Difference" := SrcCurrVATDifference;
                if "System-Created Entry" then
                    VATEntry."Base Before Pmt. Disc." := "VAT Base Before Pmt. Disc."
                else
                    VATEntry."Base Before Pmt. Disc." := GLEntryAmount;
                if GLSetup."Enable Russian Accounting" then begin
                    VATEntry.Positive := VATEntry.Amount > 0;
                    VATEntry."Additional VAT Ledger Sheet" := "Additional VAT Ledger Sheet";
                    VATEntry."Corrected Document Date" := "Corrected Document Date";
                    VATEntry."Include In Other VAT Ledger" := "Include In Other VAT Ledger";
                    VATEntry."Prepmt. Diff." := "Prepmt. Diff.";
                    VATEntry."Document Line No." := "Document Line No.";
                    if VATEntry."Prepmt. Diff." then
                        if UnrealizedVAT then
                            VATEntry."Initial VAT Transaction No." := InitialCVLedgEntryBuf."Transaction No."
                        else
                            VATEntry."Initial VAT Transaction No." := InitialCVLedgEntryBuf."Entry No.";
                    VATEntry."VAT Agent" := VATAgentVATPayment;
                    VATEntry."Corrective Doc. Type" := GenJnlLine."Corrective Doc. Type";
                end;

                OnBeforeInsertVATEntry(VATEntry, GenJnlLine);
                VATEntry.Insert(true);
                TempGLEntryVATEntryLink.InsertLinkSelf(TempGLEntryBuf."Entry No.", VATEntry."Entry No.");
                NextVATEntryNo := NextVATEntryNo + 1;
                OnAfterInsertVATEntry(GenJnlLine, VATEntry, TempGLEntryBuf."Entry No.", NextVATEntryNo);
            end;

            if GLSetup."Enable Russian Accounting" and "Prepmt. Diff." and UnrealizedVAT then
                PostPrepmtDiffRealizedVAT(GenJnlLine, VATEntry);

            // VAT for G/L entry/entries
            InsertVATForGLEntry(
                GenJnlLine, VATPostingSetup, TaxJurisdiction,
                GLEntryVATAmount, SrcCurrGLEntryVATAmt, SrcCurrCode, UnrealizedVAT);
        end;

        OnAfterInsertVAT(
          GenJnlLine, VATEntry, UnrealizedVAT, AddCurrencyCode, VATPostingSetup, GLEntryAmount, GLEntryVATAmount, GLEntryBaseAmount,
          SrcCurrCode, SrcCurrGLEntryAmt, SrcCurrGLEntryVATAmt, SrcCurrGLEntryBaseAmt, AddCurrGLEntryVATAmt,
          NextConnectionNo, NextVATEntryNo, NextTransactionNo, TempGLEntryBuf."Entry No.");
    end;

    local procedure InsertVATForGLEntry(var GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; TaxJurisdiction: Record "Tax Jurisdiction"; GLEntryVATAmount: Decimal; SrcCurrGLEntryVATAmt: Decimal; SrcCurrCode: Code[10]; UnrealizedVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SavGLAccountNo: Code[20];
        GLEntryVATAmountNotEmpty: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertVATForGLEntry(GenJnlLine, VATPostingSetup, GLEntryVATAmount, SrcCurrGLEntryVATAmt, UnrealizedVAT, IsHandled, VATEntry);
        if IsHandled then
            exit;

        with GenJnlLine do begin
            GLEntryVATAmountNotEmpty := GLEntryVATAmount <> 0;
            OnInsertVATOnBeforeVATForGLEntry(GenJnlLine, GLEntryVATAmountNotEmpty);
            if GLEntryVATAmountNotEmpty or
               ((SrcCurrGLEntryVATAmt <> 0) and (SrcCurrCode = AddCurrencyCode))
            then
                case "Gen. Posting Type" of
                    "Gen. Posting Type"::Purchase:
                        case VATPostingSetup."VAT Calculation Type" of
                            VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                            VATPostingSetup."VAT Calculation Type"::"Full VAT":
                                if not GLSetup."Enable Russian Accounting" then
                                    CreateGLEntry(GenJnlLine, VATPostingSetup.GetPurchAccount(UnrealizedVAT),
                                      GLEntryVATAmount, SrcCurrGLEntryVATAmt, true)
                                else
                                    if UnrealizedVAT then begin
                                        VATPostingSetup.TestField("Purch. VAT Unreal. Account");
                                        if VATAgentVATPayment then begin
                                            InitGLEntry(GenJnlLine, GLEntry,
                                              VATPostingSetup."Purch. VAT Unreal. Account",
                                              GLEntryVATAmount, SrcCurrGLEntryVATAmt, true, true);
                                            InsertRUGLEntry(GenJnlLine, GLEntry,
                                              VATPostingSetup."Purchase VAT Account", true, true, false);
                                        end else
                                            CreateGLEntry(GenJnlLine, VATPostingSetup.GetPurchAccount(UnrealizedVAT),
                                              GLEntryVATAmount, SrcCurrGLEntryVATAmt, true);
                                    end else begin
                                        if VATPostingSetup."Trans. VAT Account" <> '' then begin
                                            CreateGLEntry(GenJnlLine, VATPostingSetup."Trans. VAT Account",
                                              GLEntryVATAmount, SrcCurrGLEntryVATAmt, true);
                                            CreateGLEntryBalAcc(GenJnlLine, VATPostingSetup."Trans. VAT Account",
                                              -GLEntryVATAmount, -SrcCurrGLEntryVATAmt, "Gen. Journal Account Type"::"G/L Account",
                                              VATPostingSetup."Purchase VAT Account");
                                        end;
                                        VATPostingSetup.TestField("Purchase VAT Account");
                                        InitGLEntry(GenJnlLine, GLEntry,
                                          VATPostingSetup."Purchase VAT Account",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, true, true);
                                        if VATPostingSetup."Trans. VAT Account" <> '' then
                                            GLEntry."Bal. Account No." := VATPostingSetup."Trans. VAT Account";
                                        if VATAgentVATPayment then begin
                                            InitGLEntry(GenJnlLine, GLEntry,
                                              GetPayablesAccountNo(GenJnlLine),
                                              GLEntryVATAmount, SrcCurrGLEntryVATAmt, true, true);
                                            InsertRUGLEntry(GenJnlLine, GLEntry,
                                              VATPostingSetup."Purchase VAT Account", true, true, false);
                                        end else
                                            InsertGLEntry(GenJnlLine, GLEntry, true);
                                    end;
                            VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                                if not GLSetup."Enable Russian Accounting" then begin
                                    CreateGLEntry(GenJnlLine, VATPostingSetup.GetPurchAccount(UnrealizedVAT),
                                      GLEntryVATAmount, SrcCurrGLEntryVATAmt, true);
                                    CreateGLEntry(GenJnlLine, VATPostingSetup.GetRevChargeAccount(UnrealizedVAT),
                                      -GLEntryVATAmount, -SrcCurrGLEntryVATAmt, true);
                                end else begin
                                    OnInsertVATOnBeforeCreateGLEntryForReverseChargeVATToPurchAcc(
                                      GenJnlLine, VATPostingSetup, UnrealizedVAT, GLEntryVATAmount, SrcCurrGLEntryVATAmt, true);
                                    CreateGLEntry(
                                      GenJnlLine, VATPostingSetup.GetPurchAccount(UnrealizedVAT), GLEntryVATAmount, SrcCurrGLEntryVATAmt, true);
                                    OnInsertVATOnBeforeCreateGLEntryForReverseChargeVATToRevChargeAcc(
                                      GenJnlLine, VATPostingSetup, UnrealizedVAT, GLEntryVATAmount, SrcCurrGLEntryVATAmt, true);
                                    CreateGLEntry(
                                      GenJnlLine, VATPostingSetup.GetRevChargeAccount(UnrealizedVAT), -GLEntryVATAmount, -SrcCurrGLEntryVATAmt, true);
                                end;
                            VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                                if "Use Tax" then begin
                                    InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetPurchAccount(UnrealizedVAT), '',
                                      GLEntryVATAmount, SrcCurrGLEntryVATAmt, true,
                                      VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                                    InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetRevChargeAccount(UnrealizedVAT), '',
                                      -GLEntryVATAmount, -SrcCurrGLEntryVATAmt, true,
                                      VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                                end else
                                    InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetPurchAccount(UnrealizedVAT), '',
                                      GLEntryVATAmount, SrcCurrGLEntryVATAmt, true,
                                      VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                        end;
                    "Gen. Posting Type"::Sale:
                        case VATPostingSetup."VAT Calculation Type" of
                            VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                          VATPostingSetup."VAT Calculation Type"::"Full VAT":
                                if not GLSetup."Enable Russian Accounting" then
                                    CreateGLEntry(GenJnlLine, VATPostingSetup.GetSalesAccount(UnrealizedVAT),
                                      GLEntryVATAmount, SrcCurrGLEntryVATAmt, true)
                                else begin
                                    if VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount & Tax" then
                                        CreateGLEntry(GenJnlLine, TransVATAccNo,
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, true);
                                    if UnrealizedVAT then begin
                                        VATPostingSetup.TestField("Sales VAT Unreal. Account");
                                        InitGLEntry(GenJnlLine, GLEntry,
                                          VATPostingSetup."Sales VAT Unreal. Account",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, true, true);
                                    end else begin
                                        VATPostingSetup.TestField("Sales VAT Account");
                                        InitGLEntry(GenJnlLine, GLEntry,
                                          VATPostingSetup."Sales VAT Account",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, true, true);
                                    end;
                                    InsertRUGLEntry(GenJnlLine, GLEntry,
                                      TransVATAccNo, TransVATAccNo <> '', true, false);
                                end;
                            VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                                ;
                            VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                                if not GLSetup."Enable Russian Accounting" then
                                    InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetSalesAccount(UnrealizedVAT), '',
                                      GLEntryVATAmount, SrcCurrGLEntryVATAmt, true, false)
                                else begin
                                    if TaxJurisdiction."Trans. VAT Type" = TaxJurisdiction."Trans. VAT Type"::"Amount & Tax" then begin
                                        InitGLEntry(GenJnlLine, GLEntry,
                                          TransVATAccNo, GLEntryVATAmount, SrcCurrGLEntryVATAmt, true, true);
                                        SummarizeVAT(GLSetup."Summarize G/L Entries", GLEntry, false);
                                    end;
                                    if UnrealizedVAT then begin
                                        TaxJurisdiction.TestField("Unreal. Tax Acc. (Sales)");
                                        InitGLEntry(GenJnlLine, GLEntry,
                                          TaxJurisdiction."Unreal. Tax Acc. (Sales)",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, true, true);
                                    end else begin
                                        TaxJurisdiction.TestField("Tax Account (Sales)");
                                        InitGLEntry(GenJnlLine, GLEntry,
                                          TaxJurisdiction."Tax Account (Sales)",
                                          GLEntryVATAmount, SrcCurrGLEntryVATAmt, true, true);
                                    end;
                                    GLEntry."Bal. Account No." := TransVATAccNo;
                                    if VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount & Tax" then begin
                                        SummarizeVAT(GLSetup."Summarize G/L Entries", GLEntry, false);
                                        SavGLAccountNo := GLEntry."G/L Account No.";
                                        InitGLEntry(GenJnlLine, GLEntry,
                                          TransVATAccNo, -GLEntry.Amount, -GLEntry."Additional-Currency Amount", true, true);
                                        GLEntry."Bal. Account No." := SavGLAccountNo;
                                    end;
                                    SummarizeVAT(
                                      GLSetup."Summarize G/L Entries", GLEntry,
                                      VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                                end;
                        end;
                end;
        end;
    end;

    procedure SummarizeVAT(SummarizeGLEntries: Boolean; GLEntry: Record "G/L Entry")
    begin
        SummarizeVAT(SummarizeGLEntries, GLEntry, false);
    end;

    local procedure SummarizeVAT(SummarizeGLEntries: Boolean; GLEntry: Record "G/L Entry"; TransVATTypeIsAmountPlusTax: Boolean)
    var
        InsertedTempVAT: Boolean;
    begin
        InsertedTempVAT := false;
        if SummarizeGLEntries then
            if TempGLEntryVAT.FindSet() then
                repeat
                    if (TempGLEntryVAT."G/L Account No." = GLEntry."G/L Account No.") and
                       (TempGLEntryVAT."Bal. Account No." = GLEntry."Bal. Account No.")
                    then begin
                        TempGLEntryVAT.Amount := TempGLEntryVAT.Amount + GLEntry.Amount;
                        TempGLEntryVAT."Additional-Currency Amount" :=
                          TempGLEntryVAT."Additional-Currency Amount" + GLEntry."Additional-Currency Amount";
                        TempGLEntryVAT.Modify();
                        InsertedTempVAT := true;
                    end;
                until (TempGLEntryVAT.Next() = 0) or InsertedTempVAT;
        if not InsertedTempVAT or not SummarizeGLEntries then begin
            TempGLEntryVAT := GLEntry;
            TempGLEntryVAT."Entry No." :=
              TempGLEntryVAT."Entry No." + InsertedTempGLEntryVAT;
            TempGLEntryVAT.Insert();
            InsertedTempGLEntryVAT := InsertedTempGLEntryVAT + 1;
            if GLSetup."Enable Russian Accounting" then
                if (TransVATAccNo <> '') and TransVATTypeIsAmountPlusTax then
                    InsertedTempGLEntryVAT := InsertedTempGLEntryVAT + 1;
        end;
    end;

    local procedure InsertSummarizedVAT(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        if TempGLEntryVAT.FindSet() then begin
            repeat
                if not GLSetup."Enable Russian Accounting" then
                    InsertGLEntry(GenJnlLine, TempGLEntryVAT, true)
                else
                    if (TransVATAccNo <> '') and
                       (VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax")
                    then
                        InsertRUGLEntry(GenJnlLine, TempGLEntryVAT, TempGLEntryVAT."Bal. Account No.", true, true, false)
                    else
                        InsertGLEntry(GenJnlLine, TempGLEntryVAT, true);
                OnInsertSummarizedVATOnAfterInsertGLEntry(GenJnlLine, TempGLEntryVAT, NextEntryNo);
            until TempGLEntryVAT.Next() = 0;
            TempGLEntryVAT.DeleteAll();
            InsertedTempGLEntryVAT := 0;
        end;
        NextConnectionNo := NextConnectionNo + 1;
    end;

    local procedure PostGLAcc(GenJnlLine: Record "Gen. Journal Line"; Balancing: Boolean)
    var
        GLAcc: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostGLAcc(GenJnlLine, GLEntry, GLEntryNo, IsHandled);

        if not IsHandled then
            with GenJnlLine do begin
                GLAcc.Get("Account No.");
                // G/L entry
                InitGLEntry(GenJnlLine, GLEntry,
                  "Account No.", "Amount (LCY)",
                  "Source Currency Amount", true, "System-Created Entry");
                CheckGLAccDirectPosting(GenJnlLine, GLAcc);
                if GLAcc."Omit Default Descr. in Jnl." then
                    if DelChr(Description, '=', ' ') = '' then
                        Error(
                          DescriptionMustNotBeBlankErr,
                          GLAcc.FieldCaption("Omit Default Descr. in Jnl."),
                          GLAcc."No.",
                          FieldCaption(Description));
                GLEntry."Gen. Posting Type" := "Gen. Posting Type";
                GLEntry."Bal. Account Type" := "Bal. Account Type";
                GLEntry."Bal. Account No." := "Bal. Account No.";
                GLEntry."No. Series" := "Posting No. Series";
                if "Additional-Currency Posting" =
                   "Additional-Currency Posting"::"Additional-Currency Amount Only"
                then begin
                    GLEntry."Additional-Currency Amount" := Amount;
                    GLEntry.Amount := 0;
                end;
                // Store Entry No. to global variable for return:
                GLEntryNo := GLEntry."Entry No.";
                InitVAT(GenJnlLine, GLEntry, VATPostingSetup);
                IsHandled := false;
                OnPostGLAccOnBeforeInsertGLEntry(GenJnlLine, GLEntry, IsHandled, Balancing);
                if not IsHandled then
                    InsertGLEntry(GenJnlLine, GLEntry, true);
                PostJob(GenJnlLine, GLEntry);
                PostVAT(GenJnlLine, GLEntry, VATPostingSetup);
                DeferralPosting("Deferral Code", "Source Code", "Account No.", GenJnlLine, Balancing);
            end;

        OnMoveGenJournalLine(GenJnlLine, GLEntry.RecordId);
        OnAfterPostGLAcc(GenJnlLine, TempGLEntryBuf, NextEntryNo, NextTransactionNo, Balancing);
    end;

    local procedure PostCust(var GenJnlLine: Record "Gen. Journal Line"; Balancing: Boolean)
    var
        LineFeeNoteOnReportHist: Record "Line Fee Note on Report Hist.";
        Cust: Record Customer;
        CustPostingGr: Record "Customer Posting Group";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SalesSetup: Record "Sales & Receivables Setup";
        ReceivablesAccount: Code[20];
        DtldLedgEntryInserted: Boolean;
    begin
        SalesSetup.Get();
        with GenJnlLine do begin
            Cust.Get("Account No.");
            Cust.CheckBlockedCustOnJnls(Cust, GenJnlLine, true);

            if "Posting Group" = '' then begin
                Cust.TestField("Customer Posting Group");
                "Posting Group" := Cust."Customer Posting Group";
            end;
            CustPostingGr.Get("Posting Group");
            ReceivablesAccount := GetCustomerReceivablesAccount(GenJnlLine, CustPostingGr);

            DtldCustLedgEntry.LockTable();
            CustLedgEntry.LockTable();
            OnPostCustOnBeforeInitCustLedgEntry(GenJnlLine, CustLedgEntry, CVLedgEntryBuf, TempDtldCVLedgEntryBuf, CustPostingGr);
            InitCustLedgEntry(GenJnlLine, CustLedgEntry);
            OnPostCustOnAfterInitCustLedgEntry(GenJnlLine, CustLedgEntry, Cust, CustPostingGr);
            if GLSetup."Enable Russian Accounting" then begin
                if "Prepayment Status" <> "Prepayment Status"::" " then begin
                    CustLedgEntry."Prepayment Document No." := "Prepayment Document No.";
                    LastDocType := "Document Type"::Payment;
                    LastDocNo := CustLedgEntry."Prepayment Document No.";
                end;
                CustLedgEntry.Validate("Prepmt. Diff. Appln. Entry No.", "Prepmt. Diff. Appln. Entry No.");
                IncrNextEntryNo();
            end;

            if not Cust."Block Payment Tolerance" then
                CalcPmtTolerancePossible(
                  GenJnlLine, CustLedgEntry."Pmt. Discount Date", CustLedgEntry."Pmt. Disc. Tolerance Date",
                  CustLedgEntry."Max. Payment Tolerance");

            TempDtldCVLedgEntryBuf.DeleteAll();
            TempDtldCVLedgEntryBuf.Init();
            OnPostCustOnBeforeTempDtldCVLedgEntryBufCopyFromGenJnlLine(GenJnlLine, CustLedgEntry, Cust, GLReg);
            TempDtldCVLedgEntryBuf.CopyFromGenJnlLine(GenJnlLine);
            OnPostCustOnAfterTempDtldCVLedgEntryBufCopyFromGenJnlLine(GenJnlLine, TempDtldCVLedgEntryBuf);
            TempDtldCVLedgEntryBuf."CV Ledger Entry No." := CustLedgEntry."Entry No.";
            TempDtldCVLedgEntryBuf."Agreement No." := CustLedgEntry."Agreement No.";
            CVLedgEntryBuf.CopyFromCustLedgEntry(CustLedgEntry);
            TempDtldCVLedgEntryBuf.InsertDtldCVLedgEntry(TempDtldCVLedgEntryBuf, CVLedgEntryBuf, true);
            CVLedgEntryBuf.Open := CVLedgEntryBuf."Remaining Amount" <> 0;
            CVLedgEntryBuf.Positive := CVLedgEntryBuf."Remaining Amount" > 0;
            OnPostCustOnAfterCopyCVLedgEntryBuf(CVLedgEntryBuf, GenJnlLine, Cust);

            CalcPmtDiscPossible(GenJnlLine, CVLedgEntryBuf);

            if "Currency Code" <> '' then begin
                TestField("Currency Factor");
                CVLedgEntryBuf."Original Currency Factor" := "Currency Factor"
            end else
                CVLedgEntryBuf."Original Currency Factor" := 1;
            CVLedgEntryBuf."Adjusted Currency Factor" := CVLedgEntryBuf."Original Currency Factor";
            OnPostCustOnAfterAssignCurrencyFactors(CVLedgEntryBuf, GenJnlLine);

            // Check the document no.
            if ("Recurring Method" = "Gen. Journal Recurring Method"::" ") and not "Prepmt. Diff." then
                if IsNotPayment("Document Type") then begin
                    GenJnlCheckLine.CheckSalesDocNoIsNotUsed(GenJnlLine);
                    if CustLedgEntry."Prepmt. Diff. Cust. Entry No." = 0 then
                        CheckSalesExtDocNo(GenJnlLine);
                end;

            // Post application
            if not "Prepmt. Diff." then
                ApplyCustLedgEntry(CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, Cust);

            // Post customer entry
            CustLedgEntry.CopyFromCVLedgEntryBuffer(CVLedgEntryBuf);
            CustLedgEntry."Amount to Apply" := 0;
            CustLedgEntry."Applies-to Doc. No." := '';
            CustLedgEntry."Applies-to ID" := '';
            if SalesSetup."Copy Customer Name to Entries" then
                CustLedgEntry."Customer Name" := Cust.Name;
            OnBeforeCustLedgEntryInsert(CustLedgEntry, GenJnlLine, GLReg, TempDtldCVLedgEntryBuf, NextEntryNo);
            if GLSetup."Enable Russian Accounting" and "Prepmt. Diff." then
                SetCVLedgEntryForVAT(NextTransactionNo, InitialCVLedgEntryBuf."Entry No.")
            else
                CustLedgEntry.Insert(true);

            // Post detailed customer entries
            DtldLedgEntryInserted := PostDtldCustLedgEntries(GenJnlLine, TempDtldCVLedgEntryBuf, CustPostingGr, true);

            OnAfterCustLedgEntryInsert(CustLedgEntry, GenJnlLine, DtldLedgEntryInserted);

            // Post Reminder Terms - Note About Line Fee on Report
            LineFeeNoteOnReportHist.Save(CustLedgEntry);

            if DtldLedgEntryInserted then
                if IsTempGLEntryBufEmpty then
                    DtldCustLedgEntry.SetZeroTransNo(NextTransactionNo);

            if GLSetup."Enable Russian Accounting" and not "Prepmt. Diff." then
                SetCVLedgEntryForVAT(NextTransactionNo, CustLedgEntry."Entry No.");

            DeferralPosting("Deferral Code", "Source Code", ReceivablesAccount, GenJnlLine, Balancing);
        end;

        OnMoveGenJournalLine(GenJnlLine, CustLedgEntry.RecordId);
        OnAfterPostCust(GenJnlLine, Balancing, TempGLEntryBuf, NextEntryNo, NextTransactionNo);
    end;

    local procedure PostVend(GenJnlLine: Record "Gen. Journal Line"; Balancing: Boolean)
    var
        Vend: Record Vendor;
        VendPostingGr: Record "Vendor Posting Group";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendAgreement: Record "Vendor Agreement";
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        VendorFunds: Boolean;
        PayablesAccount: Code[20];
        DtldLedgEntryInserted: Boolean;
        CheckExtDocNoHandled: Boolean;
    begin
        OnBeforePostVend(GenJnlLine);

        PurchSetup.Get();
        with GenJnlLine do begin
            Vend.Get("Account No.");
            Vend.CheckBlockedVendOnJnls(Vend, "Document Type", true);

            if "Posting Group" = '' then begin
                Vend.TestField("Vendor Posting Group");
                "Posting Group" := Vend."Vendor Posting Group";
            end;
            GetVendorPostingGroup(GenJnlLine, VendPostingGr);
            PayablesAccount := GetVendorPayablesAccount(GenJnlLine, VendPostingGr);

            DtldVendLedgEntry.LockTable();
            VendLedgEntry.LockTable();
            OnPostVendOnBeforeInitVendLedgEntry(GenJnlLine, VendLedgEntry, CVLedgEntryBuf, TempDtldCVLedgEntryBuf, VendPostingGr);
            InitVendLedgEntry(GenJnlLine, VendLedgEntry);
            if GLSetup."Enable Russian Accounting" then begin
                VendLedgEntry.Validate("Prepmt. Diff. Appln. Entry No.", "Prepmt. Diff. Appln. Entry No.");
                if "Prepmt. Diff. Appln. Entry No." <> 0 then begin
                    VendLedgEntry."Vendor VAT Invoice No." := "Document No.";
                    VendLedgEntry."Vendor VAT Invoice Date" := "Posting Date";
                    VendLedgEntry."Vendor VAT Invoice Rcvd Date" := "Posting Date";
                end;
                NextEntryNo += 1;
            end;

            OnPostVendOnAfterInitVendLedgEntry(GenJnlLine, VendLedgEntry);
            if not Vend."Block Payment Tolerance" then
                CalcPmtTolerancePossible(
                  GenJnlLine, VendLedgEntry."Pmt. Discount Date", VendLedgEntry."Pmt. Disc. Tolerance Date",
                  VendLedgEntry."Max. Payment Tolerance");

            TempDtldCVLedgEntryBuf.DeleteAll();
            TempDtldCVLedgEntryBuf.Init();
            TempDtldCVLedgEntryBuf.CopyFromGenJnlLine(GenJnlLine);
            TempDtldCVLedgEntryBuf."CV Ledger Entry No." := VendLedgEntry."Entry No.";
            TempDtldCVLedgEntryBuf."Agreement No." := VendLedgEntry."Agreement No.";
            OnPostVendAfterTempDtldCVLedgEntryBufInit(GenJnlLine, TempDtldCVLedgEntryBuf);

            CVLedgEntryBuf.CopyFromVendLedgEntry(VendLedgEntry);
            TempDtldCVLedgEntryBuf.InsertDtldCVLedgEntry(TempDtldCVLedgEntryBuf, CVLedgEntryBuf, true);
            CVLedgEntryBuf.Open := CVLedgEntryBuf."Remaining Amount" <> 0;
            CVLedgEntryBuf.Positive := CVLedgEntryBuf."Remaining Amount" > 0;
            OnPostVendOnAfterCopyCVLedgEntryBuf(CVLedgEntryBuf, GenJnlLine);

            CalcPmtDiscPossible(GenJnlLine, CVLedgEntryBuf);

            if "Currency Code" <> '' then begin
                TestField("Currency Factor");
                CVLedgEntryBuf."Adjusted Currency Factor" := "Currency Factor"
            end else
                CVLedgEntryBuf."Adjusted Currency Factor" := 1;
            CVLedgEntryBuf."Original Currency Factor" := CVLedgEntryBuf."Adjusted Currency Factor";
            OnPostVendOnAfterAssignCurrencyFactors(CVLedgEntryBuf, GenJnlLine);

            // Check the document no.
            if ("Recurring Method" = "Gen. Journal Recurring Method"::" ") and not "Prepmt. Diff." then
                if IsNotPayment("Document Type") then begin
                    GenJnlCheckLine.CheckPurchDocNoIsNotUsed(GenJnlLine);
                    OnBeforeCheckPurchExtDocNo(GenJnlLine, VendLedgEntry, CVLedgEntryBuf, CheckExtDocNoHandled);
                    if not CheckExtDocNoHandled then
                        CheckPurchExtDocNo(GenJnlLine, VendLedgEntry."Prepmt. Diff. Vend. Entry No." <> 0);
                end;

            // Post application
            if not "Prepmt. Diff." then
                ApplyVendLedgEntry(CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, Vend);

            // Post vendor entry
            VendLedgEntry.CopyFromCVLedgEntryBuffer(CVLedgEntryBuf);
            VendLedgEntry."Amount to Apply" := 0;
            VendLedgEntry."Applies-to Doc. Type" := VendLedgEntry."Applies-to Doc. Type"::" ";
            VendLedgEntry."Applies-to Doc. No." := '';
            VendLedgEntry."Applies-to ID" := '';
            if PurchSetup."Copy Vendor Name to Entries" then
                VendLedgEntry."Vendor Name" := Vend.Name;
            OnBeforeVendLedgEntryInsert(VendLedgEntry, GenJnlLine, GLReg);
            if GLSetup."Enable Russian Accounting" and "Prepmt. Diff." then
                SetCVLedgEntryForVAT(NextTransactionNo, InitialCVLedgEntryBuf."Entry No.")
            else
                if not VendPostingGr."Skip Posting" then
                    VendLedgEntry.Insert(true);

            // Post detailed vendor entries
            OnPostVendOnBeforePostDtldVendLedgEntries(VendLedgEntry, GenJnlLine, TempDtldCVLedgEntryBuf, NextEntryNo);
            DtldLedgEntryInserted := PostDtldVendLedgEntries(GenJnlLine, TempDtldCVLedgEntryBuf, VendPostingGr, true);

            OnAfterVendLedgEntryInsert(VendLedgEntry, GenJnlLine, DtldLedgEntryInserted);

            if DtldLedgEntryInserted then
                if IsTempGLEntryBufEmpty then
                    DtldVendLedgEntry.SetZeroTransNo(NextTransactionNo);

            if GLSetup."Enable Russian Accounting" then begin
                if not "Prepmt. Diff." and not VendPostingGr."Skip Posting" then
                    SetCVLedgEntryForVAT(NextTransactionNo, VendLedgEntry."Entry No.");

                if VATAgentVATPayment then begin
                    if VendLedgEntry."Agreement No." <> '' then begin
                        VendAgreement.Get(VendLedgEntry."Vendor No.", VendLedgEntry."Agreement No.");
                        VendorFunds :=
                          VendAgreement."VAT Payment Source Type" = VendAgreement."VAT Payment Source Type"::"Vendor Funds";
                    end else
                        VendorFunds := Vend."VAT Payment Source Type" = Vend."VAT Payment Source Type"::"Vendor Funds";
                    if VendorFunds then begin
                        NextEntryNo := NextEntryNo - 1;
                        UpdateVATAgentVendLedgEntry(VendLedgEntry);
                        InitVATAgentDtldVendLedgEntry(GenJnlLine, VendLedgEntry, DtldVendLedgEntry);
                        DtldVendLedgEntry.UpdateDebitCredit(Correction);
                        VendLedgEntry.Insert();
                        DtldVendLedgEntry.Insert();
                        IncrNextEntryNo();
                    end;
                end;
            end;
            DeferralPosting("Deferral Code", "Source Code", PayablesAccount, GenJnlLine, Balancing);
        end;

        OnMoveGenJournalLine(GenJnlLine, VendLedgEntry.RecordId);
        OnAfterPostVend(GenJnlLine, Balancing, TempGLEntryBuf, NextEntryNo, NextTransactionNo);
    end;

    local procedure PostBankAcc(var GenJnlLine: Record "Gen. Journal Line"; Balancing: Boolean)
    var
        BankAcc: Record "Bank Account";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";
        CheckLedgEntry2: Record "Check Ledger Entry";
        BankAccPostingGr: Record "Bank Account Posting Group";
        Cust: Record Customer;
        Vend: Record Vendor;
        StdRepMgt: Codeunit "Local Report Management";
        PayerCode: array[5] of Code[20];
        BeneficiaryCode: array[5] of Code[20];
        PayerText: array[6] of Text[100];
        BeneficiaryText: array[6] of Text[130];
        DocAmount: Decimal;
        CodeIndex: Option ,VATRegNo,BIC,CorrAccNo,BankAccNo,KPP;
        TextIndex: Option ,Name,Name2,Bank,Bank2,City,Branch;
        IsHandled: Boolean;
    begin
        with GenJnlLine do begin
            BankAcc.Get("Account No.");
            BankAcc.TestField(Blocked, false);
            if "Currency Code" = '' then
                BankAcc.TestField("Currency Code", '')
            else
                if BankAcc."Currency Code" <> '' then
                    TestField("Currency Code", BankAcc."Currency Code");

            BankAcc.TestField("Bank Acc. Posting Group");
            BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");

            BankAccLedgEntry.LockTable();

            OnPostBankAccOnBeforeInitBankAccLedgEntry(GenJnlLine, CurrencyFactor, NextEntryNo, NextTransactionNo, BankAccPostingGr);

            InitBankAccLedgEntry(GenJnlLine, BankAccLedgEntry);

            BankAccLedgEntry."Bank Acc. Posting Group" := BankAcc."Bank Acc. Posting Group";
            BankAccLedgEntry."Currency Code" := BankAcc."Currency Code";
            if BankAcc."Currency Code" <> '' then
                BankAccLedgEntry.Amount := Amount
            else
                BankAccLedgEntry.Amount := "Amount (LCY)";
            BankAccLedgEntry."Amount (LCY)" := "Amount (LCY)";
            BankAccLedgEntry.Open := Amount <> 0;
            BankAccLedgEntry."Remaining Amount" := BankAccLedgEntry.Amount;
            BankAccLedgEntry.Positive := Amount > 0;
            BankAccLedgEntry.UpdateDebitCredit(Correction);
            BankAccLedgEntry."Bal. Account Type" := "Bal. Account Type";
            BankAccLedgEntry."Bal. Account No." := "Bal. Account No.";
            BankAccLedgEntry."Agreement No." := "Agreement No.";
            OnPostBankAccOnBeforeBankAccLedgEntryInsert(BankAccLedgEntry, GenJnlLine, BankAcc, TempGLEntryBuf, NextTransactionNo);
            BankAccLedgEntry.Insert(true);
            OnPostBankAccOnAfterBankAccLedgEntryInsert(BankAccLedgEntry, GenJnlLine, BankAcc);

            if CheckLedgerEntryIsNeeded(BankAcc, GenJnlLine)
            then begin
                if BankAcc."Currency Code" <> "Currency Code" then
                    Error(BankPaymentTypeMustNotBeFilledErr);
                case "Bank Payment Type" of
                    "Bank Payment Type"::"Computer Check":
                        begin
                            TestField("Check Printed", true);
                            CheckLedgEntry.LockTable();
                            CheckLedgEntry.Reset();
                            CheckLedgEntry.SetCurrentKey("Bank Account No.", "Entry Status", "Check No.");
                            CheckLedgEntry.SetRange("Bank Account No.", "Account No.");
                            CheckLedgEntry.SetRange("Entry Status", CheckLedgEntry."Entry Status"::Printed);
                            CheckLedgEntry.SetRange("Check No.", "Document No.");
                            if CheckLedgEntry.FindSet() then
                                repeat
                                    CheckLedgEntry2 := CheckLedgEntry;
                                    CheckLedgEntry2."Entry Status" := CheckLedgEntry2."Entry Status"::Posted;
                                    CheckLedgEntry2."Bank Account Ledger Entry No." := BankAccLedgEntry."Entry No.";
                                    CheckLedgEntry2."Check Date" := "Document Date";
                                    CheckLedgEntry2."Posting Date" := "Posting Date";
                                    CheckLedgEntry2.Modify();
                                until CheckLedgEntry.Next() = 0;
                        end;
                    "Bank Payment Type"::"Manual Check":
                        begin
                            if "Document No." = '' then
                                Error(DocNoMustBeEnteredErr, "Bank Payment Type");
                            CheckLedgEntry.Reset();
                            if NextCheckEntryNo = 0 then begin
                                CheckLedgEntry.LockTable();
                                if CheckLedgEntry.FindLast then
                                    NextCheckEntryNo := CheckLedgEntry."Entry No." + 1
                                else
                                    NextCheckEntryNo := 1;
                            end;

                            CheckLedgEntry.SetRange("Bank Account No.", "Account No.");
                            CheckLedgEntry.SetFilter(
                              "Entry Status", '%1|%2|%3',
                              CheckLedgEntry."Entry Status"::Printed,
                              CheckLedgEntry."Entry Status"::Posted,
                              CheckLedgEntry."Entry Status"::"Financially Voided");
                            CheckLedgEntry.SetRange("Check No.", "Document No.");
                            if not CheckLedgEntry.IsEmpty() then
                                Error(CheckAlreadyExistsErr, "Document No.");

                            if not GLSetup."Enable Russian Accounting" then begin
                                InitCheckLedgEntry(BankAccLedgEntry, CheckLedgEntry);
                                if BankAcc."Currency Code" <> '' then
                                    CheckLedgEntry.Amount := -Amount
                                else
                                    CheckLedgEntry.Amount := -"Amount (LCY)";
                            end else begin
                                CheckLedgEntry.Init();
                                CheckLedgEntry.CopyFromBankAccLedgEntry(BankAccLedgEntry);
                                CheckLedgEntry."Entry No." := NextCheckEntryNo;
                                CheckLedgEntry."Check Date" := "Document Date";
                                CheckLedgEntry."Beneficiary Bank Code" := "Beneficiary Bank Code";
                                CheckLedgEntry."Payment Purpose" := "Payment Purpose";
                                CheckLedgEntry."Cash Order Including" := "Cash Order Including";
                                CheckLedgEntry."Cash Order Supplement" := "Cash Order Supplement";
                                CheckLedgEntry."Payment Method" := "Payment Method";
                                CheckLedgEntry."Payment Before Date" := "Payment Date";
                                CheckLedgEntry."Payment Subsequence" := "Payment Subsequence";
                                CheckLedgEntry."Payment Code" := "Payment Code";
                                CheckLedgEntry."Payment Assignment" := "Payment Assignment";
                                CheckLedgEntry."Payment Type" := "Payment Type";

                                if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then
                                    StdRepMgt.CheckAttributes(GenJnlLine, DocAmount,
                                      PayerCode, PayerText, BeneficiaryCode, BeneficiaryText);

                                CheckLedgEntry."Payer BIC" := PayerCode[CodeIndex::BIC];
                                CheckLedgEntry."Payer Corr. Account No." := PayerCode[CodeIndex::CorrAccNo];
                                CheckLedgEntry."Payer Bank Account No." := PayerCode[CodeIndex::BankAccNo];
                                CheckLedgEntry."Payer Name" :=
                                  CopyStr(PayerText[TextIndex::Name], 1, MaxStrLen(CheckLedgEntry."Payer Name"));
                                CheckLedgEntry."Payer Bank" :=
                                  CopyStr(PayerText[TextIndex::Bank], 1, MaxStrLen(CheckLedgEntry."Payer Bank"));
                                CheckLedgEntry."Payer VAT Reg. No." := PayerCode[CodeIndex::VATRegNo];
                                CheckLedgEntry."Payer KPP" := PayerCode[CodeIndex::KPP];
                                CheckLedgEntry."Beneficiary BIC" := BeneficiaryCode[CodeIndex::BIC];
                                CheckLedgEntry."Beneficiary Corr. Acc. No." := BeneficiaryCode[CodeIndex::CorrAccNo];
                                CheckLedgEntry."Beneficiary Bank Acc. No." := BeneficiaryCode[CodeIndex::BankAccNo];
                                CheckLedgEntry."Beneficiary Name" :=
                                  CopyStr(BeneficiaryText[TextIndex::Name], 1, MaxStrLen(CheckLedgEntry."Beneficiary Name"));
                                CheckLedgEntry."Beneficiary VAT Reg No." := BeneficiaryCode[CodeIndex::VATRegNo];
                                CheckLedgEntry."Beneficiary KPP" := BeneficiaryCode[CodeIndex::KPP];
                                CheckLedgEntry.Amount := Amount;
                                CheckLedgEntry.Positive := (Amount > 0);
                                if ((CheckLedgEntry.Amount > 0) and (not Correction)) or
                                   ((CheckLedgEntry.Amount < 0) and Correction)
                                then
                                    CheckLedgEntry."Debit Amount" := CheckLedgEntry.Amount
                                else
                                    CheckLedgEntry."Credit Amount" := -CheckLedgEntry.Amount;
                                CheckLedgEntry.KBK := KBK;
                                CheckLedgEntry.OKATO := OKATO;
                                CheckLedgEntry."Period Code" := "Period Code";
                                CheckLedgEntry."Payment Reason Code" := "Payment Reason Code";
                                CheckLedgEntry."Reason Document No." := "Reason Document No.";
                                CheckLedgEntry."Reason Document Type" := "Reason Document Type";
                                CheckLedgEntry."Reason Document Date" := "Reason Document Date";
                                CheckLedgEntry."Tax Payment Type" := "Tax Payment Type";
                                CheckLedgEntry."Tax Period" := "Tax Period";
                                CheckLedgEntry."Taxpayer Status" := "Taxpayer Status";
                                case CheckLedgEntry."Bal. Account Type" of
                                    CheckLedgEntry."Bal. Account Type"::Customer:
                                        begin
                                            Cust.Get(CheckLedgEntry."Bal. Account No.");
                                            Cust.TestField("Customer Posting Group");
                                            CheckLedgEntry."Posting Group" := Cust."Customer Posting Group";
                                        end;
                                    CheckLedgEntry."Bal. Account Type"::Vendor:
                                        begin
                                            Vend.Get(CheckLedgEntry."Bal. Account No.");
                                            Vend.TestField("Vendor Posting Group");
                                            CheckLedgEntry."Posting Group" := Vend."Vendor Posting Group";
                                        end;
                                end;
                            end;
                            CheckLedgEntry."Bank Payment Type" := CheckLedgEntry."Bank Payment Type"::"Manual Check";
                            OnPostBankAccOnBeforeCheckLedgEntryInsert(CheckLedgEntry, BankAccLedgEntry, GenJnlLine, BankAcc);
                            CheckLedgEntry.Insert(true);
                            OnPostBankAccOnAfterCheckLedgEntryInsert(CheckLedgEntry, BankAccLedgEntry, GenJnlLine, BankAcc);
                            NextCheckEntryNo := NextCheckEntryNo + 1;
                        end;
                end;
            end;

            BankAccPostingGr.TestField("G/L Account No.");
            IsHandled := false;
            OnPostBankAccOnBeforeCreateGLEntryBalAcc(GenJnlLine, BankAccPostingGr, BankAcc, NextEntryNo, IsHandled);
            if not IsHandled then
                CreateGLEntryBalAcc(
                  GenJnlLine, BankAccPostingGr."G/L Account No.", "Amount (LCY)", "Source Currency Amount",
                  "Bal. Account Type", "Bal. Account No.");
            DeferralPosting("Deferral Code", "Source Code", BankAccPostingGr."G/L Account No.", GenJnlLine, Balancing);
        end;
        OnMoveGenJournalLine(GenJnlLine, BankAccLedgEntry.RecordId);

        OnAfterPostBankAcc(GenJnlLine, Balancing, TempGLEntryBuf, NextEntryNo, NextTransactionNo);
    end;

    local procedure PostFixedAsset(GenJnlLine: Record "Gen. Journal Line")
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        TempFAGLPostBuf: Record "FA G/L Posting Buffer" temporary;
        FAGLPostBuf: Record "FA G/L Posting Buffer";
        VATPostingSetup: Record "VAT Posting Setup";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
        FAAutomaticEntry: Codeunit "FA Automatic Entry";
        ShortcutDim1Code: Code[20];
        ShortcutDim2Code: Code[20];
        Correction2: Boolean;
        NetDisposalNo: Integer;
        DimensionSetID: Integer;
        VATEntryGLEntryNo: Integer;
        IsHandled: Boolean;
    begin
        with GenJnlLine do begin
            InitGLEntry(GenJnlLine, GLEntry, '', "Amount (LCY)", "Source Currency Amount", true, "System-Created Entry");
            GLEntry."Gen. Posting Type" := "Gen. Posting Type";
            GLEntry."Bal. Account Type" := "Bal. Account Type";
            GLEntry."Bal. Account No." := "Bal. Account No.";
            InitVAT(GenJnlLine, GLEntry, VATPostingSetup);
            GLEntry2 := GLEntry;
            FAJnlPostLine.GenJnlPostLine(
                GenJnlLine, GLEntry2.Amount, GLEntry2."VAT Amount", NextTransactionNo, NextEntryNo, GLReg."No.");
            ShortcutDim1Code := "Shortcut Dimension 1 Code";
            ShortcutDim2Code := "Shortcut Dimension 2 Code";
            DimensionSetID := "Dimension Set ID";
            Correction2 := Correction;
            OnPostFixedAssetOnAfterSaveGenJnlLineValues(GenJnlLine);
        end;
        with TempFAGLPostBuf do
            if FAJnlPostLine.FindFirstGLAcc(TempFAGLPostBuf) then
                repeat
                    GenJnlLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
                    GenJnlLine."Dimension Set ID" := "Dimension Set ID";
                    GenJnlLine.Correction := Correction;

                    OnPostFixedAssetOnBeforeInitGLEntryFromTempFAGLPostBuf(GenJnlLine, TempFAGLPostBuf);
                    FADimAlreadyChecked := "FA Posting Group" <> '';
                    CheckDimValueForDisposal(GenJnlLine, "Account No.");
                    if "Original General Journal Line" then
                        InitGLEntry(GenJnlLine, GLEntry, "Account No.", Amount, GLEntry2."Additional-Currency Amount", true, true)
                    else begin
                        CheckNonAddCurrCodeOccurred('');
                        InitGLEntry(GenJnlLine, GLEntry, "Account No.", Amount, 0, false, true);
                    end;
                    FADimAlreadyChecked := false;
                    GLEntry.CopyPostingGroupsFromGLEntry(GLEntry2);
                    GLEntry."VAT Amount" := GLEntry2."VAT Amount";
                    GLEntry."Bal. Account Type" := GLEntry2."Bal. Account Type";
                    GLEntry."Bal. Account No." := GLEntry2."Bal. Account No.";
                    GLEntry."FA Entry Type" := "FA Entry Type";
                    GLEntry."FA Entry No." := "FA Entry No.";
                    if GenJnlLine."Bal. Account No." <> '' then begin
                        GLEntry."Bal. Account Type" := GenJnlLine."Bal. Account Type";
                        GLEntry."Bal. Account No." := GenJnlLine."Bal. Account No.";
                    end;
                    if "Net Disposal" then
                        NetDisposalNo := NetDisposalNo + 1
                    else
                        NetDisposalNo := 0;
                    if "Automatic Entry" and not "Net Disposal" then
                        FAAutomaticEntry.AdjustGLEntry(GLEntry);
                    if NetDisposalNo > 1 then
                        GLEntry."VAT Amount" := 0;
                    if "FA Posting Group" <> '' then begin
                        FAGLPostBuf := TempFAGLPostBuf;
                        FAGLPostBuf."Entry No." := NextEntryNo;
                        FAGLPostBuf.Insert();
                    end;
                    IsHandled := false;
                    OnPostFixedAssetOnBeforeInsertGLEntry(GenJnlLine, GLEntry, IsHandled, TempFAGLPostBuf, GLEntry2, NextEntryNo);
                    if not IsHandled then
                        InsertGLEntry(GenJnlLine, GLEntry, true);
                    if (VATEntryGLEntryNo = 0) and (GLEntry."Gen. Posting Type" <> GLEntry."Gen. Posting Type"::" ") then
                        VATEntryGLEntryNo := GLEntry."Entry No.";
                until FAJnlPostLine.GetNextGLAcc(TempFAGLPostBuf) = 0;
        GenJnlLine."Shortcut Dimension 1 Code" := ShortcutDim1Code;
        GenJnlLine."Shortcut Dimension 2 Code" := ShortcutDim2Code;
        OnPostFixedAssetOnAfterSetGenJnlLineShortcutDimCodes(GenJnlLine);
        GenJnlLine."Dimension Set ID" := DimensionSetID;
        GenJnlLine.Correction := Correction2;
        GLEntry := GLEntry2;
        if VATEntryGLEntryNo = 0 then
            VATEntryGLEntryNo := GLEntry."Entry No.";
        TempGLEntryBuf."Entry No." := VATEntryGLEntryNo; // Used later in InsertVAT(): GLEntryVATEntryLink.InsertLink(TempGLEntryBuf."Entry No.",VATEntry."Entry No.")
        OnPostFixedAssetOnBeforePostVAT(GenJnlLine);
        PostVAT(GenJnlLine, GLEntry, VATPostingSetup);
        FAJnlPostLine.UpdateRegNo(GLReg."No.");
        OnMoveGenJournalLine(GenJnlLine, GLEntry.RecordId);
    end;

    local procedure PostICPartner(GenJnlLine: Record "Gen. Journal Line")
    var
        ICPartner: Record "IC Partner";
        AccountNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostICPartner(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        with GenJnlLine do begin
            if "Account No." <> ICPartner.Code then
                ICPartner.Get("Account No.");
            if ("Document Type" = "Document Type"::"Credit Memo") xor (Amount > 0) then begin
                ICPartner.TestField("Receivables Account");
                AccountNo := ICPartner."Receivables Account";
            end else begin
                ICPartner.TestField("Payables Account");
                AccountNo := ICPartner."Payables Account";
            end;

            IsHandled := false;
            OnPostICPartnerOnBeforeCreateGLEntryBalAcc(GenJnlLine, NextEntryNo, IsHandled);
            if not IsHandled then
                CreateGLEntryBalAcc(
                  GenJnlLine, AccountNo, "Amount (LCY)", "Source Currency Amount",
                  "Bal. Account Type", "Bal. Account No.");
        end;
    end;

    local procedure FindJobLineSign(GenJnlLine: Record "Gen. Journal Line")
    begin
        JobLine := (GenJnlLine."Job No." <> '');
        OnAfterFindJobLineSign(GenJnlLine, JobLine);
    end;

    local procedure PostJob(GenJnlLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry")
    var
        JobPostLine: Codeunit "Job Post-Line";
    begin
        OnBeforePostJob(GenJnlLine, GLEntry, JobLine);

        if JobLine then begin
            JobLine := false;
            JobPostLine.PostGenJnlLine(GenJnlLine, GLEntry);
        end;
    end;

    procedure StartPosting(GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        CurrentDateTime: DateTime;
    begin
        OnBeforeStartPosting(GenJnlLine);

        with GenJnlLine do begin
            InitNextEntryNo();
            FirstTransactionNo := NextTransactionNo;

            InitLastDocDate(GenJnlLine);
            CurrentBalance := 0;

            FiscalYearStartDate := AccountingPeriodMgt.GetPeriodStartingDate;

            GetGLSetup();

            if not GenJnlTemplate.Get("Journal Template Name") then
                GenJnlTemplate.Init();

            VATEntry.LockTable();
            if VATEntry.FindLast then
                NextVATEntryNo := VATEntry."Entry No." + 1
            else
                NextVATEntryNo := 1;
            NextConnectionNo := 1;
            FirstNewVATEntryNo := NextVATEntryNo;

            GLReg.LockTable();
            if GLReg.FindLast then
                GLReg."No." := GLReg."No." + 1
            else
                GLReg."No." := 1;
            GLReg.Init();
            GLReg."From Entry No." := NextEntryNo;
            GLReg."From VAT Entry No." := NextVATEntryNo;
            if GetCurrentDateTimeInUserTimeZone(CurrentDateTime) then begin
                GLReg."Creation Date" := DT2Date(CurrentDateTime);
                GLReg."Creation Time" := DT2Time(CurrentDateTime);
            end else begin
                GLReg."Creation Date" := Today();
                GLReg."Creation Time" := Time();
            end;
            GLReg."Source Code" := "Source Code";
            GLReg."Journal Batch Name" := "Journal Batch Name";
            GLReg."User ID" := UserId;
            IsGLRegInserted := false;

            OnAfterInitGLRegister(GLReg, GenJnlLine);

            GetCurrencyExchRate(GenJnlLine);
            TempGLEntryBuf.DeleteAll();
            TempGLEntryPreview.DeleteAll();
            CalculateCurrentBalance(
              "Account No.", "Bal. Account No.", IncludeVATAmount, "Amount (LCY)", "VAT Amount");

            if GLSetup."Enable Russian Accounting" then
                PrepmtDiffMgt.Init();
        end;

        OnAfterStartPosting(GenJnlLine);
    end;

    [TryFunction]
    local procedure GetCurrentDateTimeInUserTimeZone(var CurrentDateTime: DateTime)
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        CurrentDateTime := TypeHelper.GetCurrentDateTimeInUserTimeZone();
    end;

    procedure ContinuePosting(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeContinuePosting(GenJnlLine, GLReg, NextEntryNo, NextTransactionNo);

        if NextTransactionNoNeeded(GenJnlLine) then begin
            CheckPostUnrealizedVAT(GenJnlLine, false);
            IsHandled := false;
            OnContinuePostingOnIncreaseNextTransactionNo(GenJnlLine, NextTransactionNo, IsHandled);
            if not IsHandled then
                NextTransactionNo := NextTransactionNo + 1;
            InitLastDocDate(GenJnlLine);
            FirstNewVATEntryNo := NextVATEntryNo;
        end;

        OnContinuePostingOnBeforeCalculateCurrentBalance(GenJnlLine, NextTransactionNo);

        GetCurrencyExchRate(GenJnlLine);
        TempGLEntryBuf.DeleteAll();
        CalculateCurrentBalance(
          GenJnlLine."Account No.", GenJnlLine."Bal. Account No.", GenJnlLine.IncludeVATAmount,
          GenJnlLine."Amount (LCY)", GenJnlLine."VAT Amount");

        if GLSetup."Enable Russian Accounting" then
            PrepmtDiffMgt.Init();
    end;

    local procedure NextTransactionNoNeeded(GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        LastDocTypeOption: Option;
        NewTransaction: Boolean;
    begin
        with GenJnlLine do begin
            NewTransaction :=
              (LastDocType <> "Document Type") or (LastDocNo <> "Document No.") or
              (LastDate <> "Posting Date") or ((CurrentBalance = 0) and (TotalAddCurrAmount = 0)) and not "System-Created Entry";
            NewTransaction := NewTransaction and not ThisIsSpecialRun;
            LastDocTypeOption := LastDocType.AsInteger();
            OnNextTransactionNoNeeded(GenJnlLine, LastDocTypeOption, LastDocNo, LastDate, CurrentBalance, TotalAddCurrAmount, NewTransaction);
            LastDocType := "Gen. Journal Document Type".FromInteger(LastDocTypeOption);
            exit(NewTransaction);
        end;
    end;

    procedure FinishPosting(GenJnlLine: Record "Gen. Journal Line") IsTransactionConsistent: Boolean
    var
        CostAccSetup: Record "Cost Accounting Setup";
        CorrGLEntry: Record "G/L Entry";
        SourceCodeSetup: Record "Source Code Setup";
        TransferGlEntriesToCA: Codeunit "Transfer GL Entries to CA";
        CorrespManagement: Codeunit "G/L Corresp. Management";
        HandleVATAllocDim: Boolean;
        BalAccNo: Code[20];
    begin
        OnBeforeFinishPosting(GenJnlLine, TempGLEntryBuf);

        IsTransactionConsistent :=
          (BalanceCheckAmount = 0) and (BalanceCheckAmount2 = 0) and
          (BalanceCheckAddCurrAmount = 0) and (BalanceCheckAddCurrAmount2 = 0);

        OnAfterSettingIsTransactionConsistent(GenJnlLine, IsTransactionConsistent);

        if TempGLEntryBuf.FindSet() then begin
            SourceCodeSetup.Get();
            repeat
                TempGLEntryPreview := TempGLEntryBuf;
                TempGLEntryPreview.Insert();
                GlobalGLEntry := TempGLEntryBuf;
                if AddCurrencyCode = '' then begin
                    GlobalGLEntry."Additional-Currency Amount" := 0;
                    GlobalGLEntry."Add.-Currency Debit Amount" := 0;
                    GlobalGLEntry."Add.-Currency Credit Amount" := 0;
                end;
                if GenJnlLine."Source Code" <> SourceCodeSetup.Reversal then
                    GlobalGLEntry."Agreement No." := GenJnlLine."Agreement No.";
                GlobalGLEntry."Prior-Year Entry" := GlobalGLEntry."Posting Date" < FiscalYearStartDate;
                OnBeforeInsertGlobalGLEntry(GlobalGLEntry, GenJnlLine, GLReg);
                GlobalGLEntry.Insert(true);
                if GLSetup."Enable Russian Accounting" then
                    if (FirstGLEntryNo = 0) or (FirstGLEntryNo > GlobalGLEntry."Entry No.") then
                        FirstGLEntryNo := GlobalGLEntry."Entry No.";
                OnAfterInsertGlobalGLEntry(GlobalGLEntry, TempGLEntryBuf, NextEntryNo, GenJnlLine);
            until TempGLEntryBuf.Next() = 0;

            GLReg."To VAT Entry No." := NextVATEntryNo - 1;
            GLReg."To Entry No." := GlobalGLEntry."Entry No.";
            UpdateGLReg(IsTransactionConsistent, GenJnlLine);
            SetGLAccountNoInVATEntries();
        end;

        GlobalGLEntry.Consistent(IsTransactionConsistent);

        if GLSetup."Enable Russian Accounting" then begin
            if IsTransactionConsistent then begin
                if GLSetup."Automatic G/L Correspondence" and (FirstGLEntryNo <> 0) then begin
                    CorrGLEntry.SetRange("Entry No.", FirstGLEntryNo, GlobalGLEntry."Entry No.");
                    CorrespManagement.CreateCorrespEntries(CorrGLEntry);
                    FirstGLEntryNo := 0;
                end;
                PrepmtDiffMgt.PrepmtDiffProcessing(false, PreviewMode);
            end;

            if (GenJnlLine."Source Type" = GenJnlLine."Source Type"::"Bank Account") and (GenJnlLine."Source No." <> '') then
                BalAccNo := GenJnlLine."Source No."
            else
                BalAccNo := GenJnlLine."Bal. Account No.";
        end;

        if CostAccSetup.Get() then
            if CostAccSetup."Auto Transfer from G/L" then
                TransferGlEntriesToCA.GetGLEntries;

        OnFinishPostingOnBeforeResetFirstEntryNo(GlobalGLEntry, NextEntryNo, FirstEntryNo);
        FirstEntryNo := 0;

        if IsTransactionConsistent then
            UpdateAppliedCVLedgerEntries();

        OnAfterFinishPosting(GlobalGLEntry, GLReg, IsTransactionConsistent, GenJnlLine);
    end;

    local procedure UpdateGLReg(IsTransactionConsistent: Boolean; var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateGLReg(IsTransactionConsistent, IsGLRegInserted, GLReg, IsHandled, GenJnlLine, GlobalGLEntry);
        if IsHandled then
            exit;

        if IsTransactionConsistent then
            if IsGLRegInserted then
                GLReg.Modify()
            else begin
                GLReg.Insert();
                IsGLRegInserted := true;
            end;
    end;

    local procedure UpdateAppliedCVLedgerEntries()
    var
        VendorLedgerEntryApplied: Record "Vendor Ledger Entry";
        CustLedgEntryApplied: Record "Cust. Ledger Entry";
    begin
        if TempVendorLedgerEntry.FindSet() then begin
            repeat
                if VendorLedgerEntryApplied.Get(TempVendorLedgerEntry."Entry No.") then begin
                    VendorLedgerEntryApplied."Applies-to ID" := '';
                    VendorLedgerEntryApplied."Amount to Apply" := 0;
                    VendorLedgerEntryApplied.Modify();
                end;
            until TempVendorLedgerEntry.Next() = 0;
            TempVendorLedgerEntry.DeleteAll();
        end;
        if TempCustLedgEntry.FindSet() then begin
            repeat
                if CustLedgEntryApplied.Get(TempCustLedgEntry."Entry No.") then begin
                    CustLedgEntryApplied."Applies-to ID" := '';
                    CustLedgEntryApplied."Amount to Apply" := 0;
                    CustLedgEntryApplied.Modify();
                end;
            until TempCustLedgEntry.Next() = 0;
            TempCustLedgEntry.DeleteAll();
        end;
    end;

    local procedure PostUnrealizedVAT(GenJnlLine: Record "Gen. Journal Line")
    begin
        if CheckUnrealizedCust then begin
            CustUnrealizedVAT(GenJnlLine, UnrealizedCustLedgEntry, UnrealizedRemainingAmountCust, 0, 0, 0);
            CheckUnrealizedCust := false;
        end;
        if CheckUnrealizedVend then begin
            VendUnrealizedVAT(GenJnlLine, UnrealizedVendLedgEntry, UnrealizedRemainingAmountVend, 0, 0, 0, 0);
            CheckUnrealizedVend := false;
        end;
    end;

    local procedure CheckPostUnrealizedVAT(GenJnlLine: Record "Gen. Journal Line"; CheckCurrentBalance: Boolean)
    begin
        if CheckCurrentBalance and (CurrentBalance = 0) or not CheckCurrentBalance then
            PostUnrealizedVAT(GenJnlLine)
    end;

    procedure InitGLEntry(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; GLAccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; UseAmountAddCurr: Boolean; SystemCreatedEntry: Boolean)
    var
        GLAcc: Record "G/L Account";
    begin
        OnBeforeInitGLEntry(GenJnlLine, GLAccNo, SystemCreatedEntry, Amount, AmountAddCurr);

        if GLAccNo <> '' then begin
            GLAcc.Get(GLAccNo);
            GLAcc.TestField(Blocked, false);
            GLAcc.TestField("Account Type", GLAcc."Account Type"::Posting);

            // Check the Value Posting field on the G/L Account if it is not checked already in Codeunit 11
            if (not
                ((GLAccNo = GenJnlLine."Account No.") and
                 (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account")) or
                ((GLAccNo = GenJnlLine."Bal. Account No.") and
                 (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"G/L Account"))) and
               not FADimAlreadyChecked
            then
                CheckGLAccDimError(GenJnlLine, GLAccNo);
        end;

        GLEntry.Init();
        GLEntry.CopyFromGenJnlLine(GenJnlLine);
        GLEntry."Entry No." := NextEntryNo;
        GLEntry."Transaction No." := NextTransactionNo;
        GLEntry."G/L Account No." := GLAccNo;
        GLEntry."System-Created Entry" := SystemCreatedEntry;
        GLEntry.Amount := Amount;
        GLEntry."Additional-Currency Amount" :=
          GLCalcAddCurrency(Amount, AmountAddCurr, GLEntry."Additional-Currency Amount", UseAmountAddCurr, GenJnlLine);

        OnAfterInitGLEntry(GLEntry, GenJnlLine, Amount, AmountAddCurr, UseAmountAddCurr, CurrencyFactor);
    end;

    procedure InitGLEntryVAT(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; BalAccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; UseAmtAddCurr: Boolean; TransVATTypeIsAmountPlusTax: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        OnBeforeInitGLEntryVAT(GenJnlLine, GLEntry);
        if UseAmtAddCurr then
            InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, AmountAddCurr, true, true)
        else begin
            InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, 0, false, true);
            GLEntry."Additional-Currency Amount" := AmountAddCurr;
            GLEntry."Bal. Account No." := BalAccNo;
        end;
        SummarizeVATFromInitGLEntryVAT(GLEntry, Amount, TransVATTypeIsAmountPlusTax);
        OnAfterInitGLEntryVAT(GenJnlLine, GLEntry);
    end;

    local procedure SummarizeVATFromInitGLEntryVAT(var GLEntry: Record "G/L Entry"; Amount: Decimal; TransVATTypeIsAmountPlusTax: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSummarizeVATFromInitGLEntryVAT(GLEntry, Amount, IsHandled);
        if IsHandled then
            exit;

        SummarizeVAT(GLSetup."Summarize G/L Entries", GLEntry, TransVATTypeIsAmountPlusTax);
    end;

    local procedure InitGLEntryVATCopy(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; BalAccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; VATEntry: Record "VAT Entry"; TransVATTypeIsAmountPlusTax: Boolean): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        OnBeforeInitGLEntryVATCopy(GenJnlLine, GLEntry, VATEntry);
        InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, 0, false, true);
        GLEntry."Additional-Currency Amount" := AmountAddCurr;
        GLEntry."Bal. Account No." := BalAccNo;
        GLEntry.CopyPostingGroupsFromVATEntry(VATEntry);
        SummarizeVAT(GLSetup."Summarize G/L Entries", GLEntry, TransVATTypeIsAmountPlusTax);
        OnAfterInitGLEntryVATCopy(GenJnlLine, GLEntry);

        exit(GLEntry."Entry No.");
    end;

    procedure InsertGLEntry(GenJnlLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; CalcAddCurrResiduals: Boolean)
    var
        IsHandled: Boolean;
    begin
        OnBeforeInsertGlEntry(GenJnlLine, GLEntry);
        with GLEntry do begin
            TestField("G/L Account No.");

            IsHandled := false;
            OnInsertGLEntryOnBeforeCheckAmountRounding(GLEntry, IsHandled, GenJnlLine);
            if not IsHandled then
                if Amount <> Round(Amount) then
                    FieldError(Amount, StrSubstNo(NeedsRoundingErr, Amount));

            UpdateCheckAmounts(
              "Posting Date", Amount, "Additional-Currency Amount",
              BalanceCheckAmount, BalanceCheckAmount2, BalanceCheckAddCurrAmount, BalanceCheckAddCurrAmount2);

            UpdateDebitCredit(GenJnlLine.Correction);
        end;

        OnInsertGLEntryOnBeforeAssignTempGLEntryBuf(GLEntry, GenJnlLine, GLReg);

        TempGLEntryBuf := GLEntry;

        OnBeforeInsertGLEntryBuffer(
            TempGLEntryBuf, GenJnlLine, BalanceCheckAmount, BalanceCheckAmount2, BalanceCheckAddCurrAmount, BalanceCheckAddCurrAmount2,
            NextEntryNo, TotalAmount, TotalAddCurrAmount, GLEntry);

        TempGLEntryBuf.Insert();

        if FirstEntryNo = 0 then
            FirstEntryNo := TempGLEntryBuf."Entry No.";
        IncrNextEntryNo();

        if CalcAddCurrResiduals then
            HandleAddCurrResidualGLEntry(GenJnlLine, GLEntry);

        OnAfterInsertGLEntry(GLEntry, GenJnlLine, TempGLEntryBuf);
    end;

    procedure CreateGLEntry(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; UseAmountAddCurr: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        if UseAmountAddCurr then
            InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, AmountAddCurr, true, true)
        else begin
            InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, 0, false, true);
            GLEntry."Additional-Currency Amount" := AmountAddCurr;
        end;
        InsertGLEntry(GenJnlLine, GLEntry, true);

        OnAfterCreateGLEntry(GenJnlLine, GLEntry, NextEntryNo);
    end;

    local procedure CreateGLEntryRU(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; UseAmountAddCurr: Boolean; BalAccountNo: Code[20]; IgnoreGLSetup: Boolean; CalcAddCurrResiduals: Boolean; RUCorrection: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        if UseAmountAddCurr then
            InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, AmountAddCurr, true, true)
        else begin
            InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, 0, false, true);
            GLEntry."Additional-Currency Amount" := AmountAddCurr;
        end;
        InsertRUGLEntry(GenJnlLine, GLEntry, BalAccountNo, IgnoreGLSetup, CalcAddCurrResiduals, RUCorrection);
    end;

    procedure CreateGLEntryBalAcc(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, AmountAddCurr, true, true);
        GLEntry."Bal. Account Type" := BalAccType;
        GLEntry."Bal. Account No." := BalAccNo;
        InsertGLEntry(GenJnlLine, GLEntry, true);
        OnMoveGenJournalLine(GenJnlLine, GLEntry.RecordId);
    end;

    local procedure CreateGLEntryGainLoss(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; UseAmountAddCurr: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, 0, UseAmountAddCurr, true);
        OnBeforeCreateGLEntryGainLossInsertGLEntry(GenJnlLine, GLEntry);
        InsertGLEntry(GenJnlLine, GLEntry, true);
    end;

    local procedure CreateGLEntryVAT(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; VATAmount: Decimal; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    var
        GLEntry: Record "G/L Entry";
    begin
        InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, 0, false, true);
        GLEntry."Additional-Currency Amount" := AmountAddCurr;
        GLEntry."VAT Amount" := VATAmount;
        GLEntry.CopyPostingGroupsFromDtldCVBuf(DtldCVLedgEntryBuf, DtldCVLedgEntryBuf."Gen. Posting Type".AsInteger());
        InsertGLEntry(GenJnlLine, GLEntry, true);
        InsertVATEntriesFromTemp(DtldCVLedgEntryBuf, GLEntry);
    end;

    local procedure CreateGLEntryVATRU(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; VATAmount: Decimal; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; BalAccountNo: Code[20]; IgnoreGLSetup: Boolean; CalcAddCurrResiduals: Boolean; RUCorrection: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, 0, false, true);
        GLEntry."Additional-Currency Amount" := AmountAddCurr;
        GLEntry."VAT Amount" := VATAmount;
        InsertRUGLEntry(GenJnlLine, GLEntry, BalAccountNo, IgnoreGLSetup, CalcAddCurrResiduals, RUCorrection);
        GLEntry.CopyPostingGroupsFromDtldCVBuf(DtldCVLedgEntryBuf, GenJnlLine."Gen. Posting Type".AsInteger());
        InsertVATEntriesFromTemp(DtldCVLedgEntryBuf, GLEntry);
    end;

    local procedure CreateGLEntryVATCollectAdj(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; VATAmount: Decimal; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var AdjAmount: array[4] of Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, 0, false, true);
        GLEntry."Additional-Currency Amount" := AmountAddCurr;
        GLEntry."VAT Amount" := VATAmount;
        GLEntry.CopyPostingGroupsFromDtldCVBuf(DtldCVLedgEntryBuf, DtldCVLedgEntryBuf."Gen. Posting Type".AsInteger());
        InsertGLEntry(GenJnlLine, GLEntry, true);
        CollectAdjustment(AdjAmount, GLEntry.Amount, GLEntry."Additional-Currency Amount");
        InsertVATEntriesFromTemp(DtldCVLedgEntryBuf, GLEntry);
    end;

    local procedure CreateGLEntryVATCollectAdjRU(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; VATAmount: Decimal; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var AdjAmount: array[4] of Decimal; BalAccountNo: Code[20]; IgnoreGLSetup: Boolean; CalcAddCurrResiduals: Boolean; RUCorrection: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, 0, false, true);
        GLEntry."Additional-Currency Amount" := AmountAddCurr;
        GLEntry."VAT Amount" := VATAmount;
        GLEntry.CopyPostingGroupsFromDtldCVBuf(DtldCVLedgEntryBuf, DtldCVLedgEntryBuf."Gen. Posting Type".AsInteger());
        InsertRUGLEntry(GenJnlLine, GLEntry, BalAccountNo, IgnoreGLSetup, CalcAddCurrResiduals, RUCorrection);
        CollectAdjustment(AdjAmount, GLEntry.Amount, GLEntry."Additional-Currency Amount");
        InsertVATEntriesFromTemp(DtldCVLedgEntryBuf, GLEntry);
    end;

    local procedure CreateGLEntryFromVATEntry(GenJnlLine: Record "Gen. Journal Line"; VATAccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; VATEntry: Record "VAT Entry"): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        InitGLEntry(GenJnlLine, GLEntry, VATAccNo, Amount, 0, false, true);
        GLEntry."Additional-Currency Amount" := AmountAddCurr;
        GLEntry.CopyPostingGroupsFromVATEntry(VATEntry);
        OnBeforeInsertGLEntryFromVATEntry(GLEntry, VATEntry);
        InsertGLEntry(GenJnlLine, GLEntry, true);
        exit(GLEntry."Entry No.");
    end;

    local procedure CreateDeferralScheduleFromGL(var GenJournalLine: Record "Gen. Journal Line"; IsBalancing: Boolean)
    begin
        with GenJournalLine do
            if ("Account No." <> '') and ("Deferral Code" <> '') then
                if (("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) and ("Source Code" = GLSourceCode)) or
                   ("Account Type" in ["Account Type"::"G/L Account", "Account Type"::"Bank Account"])
                then begin
                    if not IsBalancing then
                        CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJournalLine);
                    DeferralUtilities.CreateScheduleFromGL(GenJournalLine, FirstEntryNo);
                end;
    end;

    local procedure UpdateCheckAmounts(PostingDate: Date; Amount: Decimal; AddCurrAmount: Decimal; var BalanceCheckAmount: Decimal; var BalanceCheckAmount2: Decimal; var BalanceCheckAddCurrAmount: Decimal; var BalanceCheckAddCurrAmount2: Decimal)
    begin
        if PostingDate = NormalDate(PostingDate) then begin
            BalanceCheckAmount :=
              BalanceCheckAmount + Amount * ((PostingDate - 00000101D) mod 99 + 1);
            BalanceCheckAmount2 :=
              BalanceCheckAmount2 + Amount * ((PostingDate - 00000101D) mod 98 + 1);
        end else begin
            BalanceCheckAmount :=
              BalanceCheckAmount + Amount * ((NormalDate(PostingDate) - 00000101D + 50) mod 99 + 1);
            BalanceCheckAmount2 :=
              BalanceCheckAmount2 + Amount * ((NormalDate(PostingDate) - 00000101D + 50) mod 98 + 1);
        end;

        if AddCurrencyCode <> '' then
            if PostingDate = NormalDate(PostingDate) then begin
                BalanceCheckAddCurrAmount :=
                  BalanceCheckAddCurrAmount + AddCurrAmount * ((PostingDate - 00000101D) mod 99 + 1);
                BalanceCheckAddCurrAmount2 :=
                  BalanceCheckAddCurrAmount2 + AddCurrAmount * ((PostingDate - 00000101D) mod 98 + 1);
            end else begin
                BalanceCheckAddCurrAmount :=
                  BalanceCheckAddCurrAmount +
                  AddCurrAmount * ((NormalDate(PostingDate) - 00000101D + 50) mod 99 + 1);
                BalanceCheckAddCurrAmount2 :=
                  BalanceCheckAddCurrAmount2 +
                  AddCurrAmount * ((NormalDate(PostingDate) - 00000101D + 50) mod 98 + 1);
            end
        else begin
            BalanceCheckAddCurrAmount := 0;
            BalanceCheckAddCurrAmount2 := 0;
        end;
    end;

    local procedure CalcPmtDiscPossible(GenJnlLine: Record "Gen. Journal Line"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    var
        PaymentDiscountDateWithGracePeriod: Date;
        IsHandled: Boolean;
    begin
        IsHandled := FALSE;
        OnBeforeCalcPmtDiscPossible(GenJnlLine, CVLedgEntryBuf, IsHandled, AmountRoundingPrecision);
        if IsHandled then
            exit;

        with GenJnlLine do
            if "Amount (LCY)" <> 0 then begin
                PaymentDiscountDateWithGracePeriod := CVLedgEntryBuf."Pmt. Discount Date";
                GLSetup.GetRecordOnce();
                if PaymentDiscountDateWithGracePeriod <> 0D then
                    PaymentDiscountDateWithGracePeriod :=
                      CalcDate(GLSetup."Payment Discount Grace Period", PaymentDiscountDateWithGracePeriod);
                if (PaymentDiscountDateWithGracePeriod >= CVLedgEntryBuf."Posting Date") or
                   (PaymentDiscountDateWithGracePeriod = 0D)
                then begin
                    if GLSetup."Pmt. Disc. Excl. VAT" then begin
                        if "Sales/Purch. (LCY)" = 0 then
                            CVLedgEntryBuf."Original Pmt. Disc. Possible" :=
                              ("Amount (LCY)" + TotalVATAmountOnJnlLines(GenJnlLine)) * Amount / "Amount (LCY)"
                        else
                            CVLedgEntryBuf."Original Pmt. Disc. Possible" := "Sales/Purch. (LCY)" * Amount / "Amount (LCY)"
                    end else
                        CVLedgEntryBuf."Original Pmt. Disc. Possible" := Amount;
                    OnCalcPmtDiscPossibleOnBeforeOriginalPmtDiscPossible(GenJnlLine, CVLedgEntryBuf, AmountRoundingPrecision);
                    CVLedgEntryBuf."Original Pmt. Disc. Possible" :=
                      Round(
                        CVLedgEntryBuf."Original Pmt. Disc. Possible" * "Payment Discount %" / 100, AmountRoundingPrecision);
                end;
                CVLedgEntryBuf."Remaining Pmt. Disc. Possible" := CVLedgEntryBuf."Original Pmt. Disc. Possible";
            end;

        OnAfterCalcPmtDiscPossible(GenJnlLine, CVLedgEntryBuf);
    end;

    local procedure CalcPmtTolerancePossible(GenJnlLine: Record "Gen. Journal Line"; PmtDiscountDate: Date; var PmtDiscToleranceDate: Date; var MaxPaymentTolerance: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPmtTolerancePossible(GenJnlLine, PmtDiscountDate, PmtDiscToleranceDate, MaxPaymentTolerance, IsHandled);
        if IsHandled then
            exit;

        with GenJnlLine do
            if "Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"] then begin
                if PmtDiscountDate <> 0D then
                    PmtDiscToleranceDate :=
                      CalcDate(GLSetup."Payment Discount Grace Period", PmtDiscountDate)
                else
                    PmtDiscToleranceDate := PmtDiscountDate;

                case "Account Type" of
                    "Account Type"::Customer:
                        PaymentToleranceMgt.CalcMaxPmtTolerance(
                          "Document Type", "Currency Code", Amount, "Amount (LCY)", 1, MaxPaymentTolerance);
                    "Account Type"::Vendor:
                        PaymentToleranceMgt.CalcMaxPmtTolerance(
                          "Document Type", "Currency Code", Amount, "Amount (LCY)", -1, MaxPaymentTolerance);
                end;
            end;
    end;

    local procedure CalcPmtTolerance(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; var PmtTolAmtToBeApplied: Decimal; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer)
    var
        PmtTol: Decimal;
        PmtTolLCY: Decimal;
        PmtTolAddCurr: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPmtTolerance(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, PmtTolAmtToBeApplied, IsHandled);
        if IsHandled then
            exit;

        if OldCVLedgEntryBuf2."Accepted Payment Tolerance" = 0 then
            exit;

        PmtTol := -OldCVLedgEntryBuf2."Accepted Payment Tolerance";
        PmtTolAmtToBeApplied := PmtTolAmtToBeApplied + PmtTol;
        PmtTolLCY :=
            Round((NewCVLedgEntryBuf."Original Amount" + PmtTol) / NewCVLedgEntryBuf."Original Currency Factor") -
            NewCVLedgEntryBuf."Original Amt. (LCY)";

        OnCalcPmtToleranceOnAfterAssignPmtDisc(
            PmtTol, PmtTolLCY, PmtTolAmtToBeApplied, OldCVLedgEntryBuf, OldCVLedgEntryBuf2,
            NewCVLedgEntryBuf, DtldCVLedgEntryBuf, NextTransactionNo, FirstNewVATEntryNo);

        OldCVLedgEntryBuf."Accepted Payment Tolerance" := 0;
        OldCVLedgEntryBuf."Pmt. Tolerance (LCY)" := -PmtTolLCY;

        if NewCVLedgEntryBuf."Currency Code" = AddCurrencyCode then
            PmtTolAddCurr := PmtTol
        else
            PmtTolAddCurr := CalcLCYToAddCurr(PmtTolLCY);

        if not GLSetup."Pmt. Disc. Excl. VAT" and GLSetup."Adjust for Payment Disc." and (PmtTolLCY <> 0) then
            CalcPmtDiscIfAdjVAT(
                NewCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, PmtTolLCY, PmtTolAddCurr,
                NextTransactionNo, FirstNewVATEntryNo, DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)");

        DtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
            GenJnlLine, NewCVLedgEntryBuf, DtldCVLedgEntryBuf,
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance", PmtTol, PmtTolLCY, PmtTolAddCurr, 0, 0, 0);

        OnAfterCalcPmtTolerance(DtldCVLedgEntryBuf, OldCVLedgEntryBuf2, PmtTol, PmtTolLCY);
    end;

    local procedure CalcPmtDisc(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; PmtTolAmtToBeApplied: Decimal; ApplnRoundingPrecision: Decimal; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer)
    var
        PmtDisc: Decimal;
        PmtDiscLCY: Decimal;
        PmtDiscAddCurr: Decimal;
        MinimalPossibleLiability: Decimal;
        PaymentExceedsLiability: Boolean;
        ToleratedPaymentExceedsLiability: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, PmtTolAmtToBeApplied, IsHandled);
        if IsHandled then
            exit;

        MinimalPossibleLiability := Abs(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible");
        OnAfterCalcMinimalPossibleLiability(NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, MinimalPossibleLiability);

        PaymentExceedsLiability := Abs(OldCVLedgEntryBuf2."Amount to Apply") >= MinimalPossibleLiability;
        OnAfterCalcPaymentExceedsLiability(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, MinimalPossibleLiability, PaymentExceedsLiability);

        ToleratedPaymentExceedsLiability :=
            Abs(NewCVLedgEntryBuf."Remaining Amount" + PmtTolAmtToBeApplied) >= MinimalPossibleLiability;
        OnAfterCalcToleratedPaymentExceedsLiability(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, MinimalPossibleLiability,
            ToleratedPaymentExceedsLiability, PmtTolAmtToBeApplied);

        if (PaymentToleranceMgt.CheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, true, true) and
            ((OldCVLedgEntryBuf2."Amount to Apply" = 0) or PaymentExceedsLiability) or
            (PaymentToleranceMgt.CheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, false, false) and
             (OldCVLedgEntryBuf2."Amount to Apply" <> 0) and PaymentExceedsLiability and ToleratedPaymentExceedsLiability))
        then begin
            PmtDisc := -OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible";
            PmtDiscLCY :=
              Round(
                (NewCVLedgEntryBuf."Original Amount" + PmtDisc) / NewCVLedgEntryBuf."Original Currency Factor") -
              NewCVLedgEntryBuf."Original Amt. (LCY)";

            OnCalcPmtDiscOnAfterAssignPmtDisc(PmtDisc, PmtDiscLCY, OldCVLedgEntryBuf, OldCVLedgEntryBuf2);

            OldCVLedgEntryBuf."Pmt. Disc. Given (LCY)" := -PmtDiscLCY;

            if (NewCVLedgEntryBuf."Currency Code" = AddCurrencyCode) and (AddCurrencyCode <> '') then
                PmtDiscAddCurr := PmtDisc
            else
                PmtDiscAddCurr := CalcLCYToAddCurr(PmtDiscLCY);

            OnAfterCalcPmtDiscount(
                NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
                PmtTolAmtToBeApplied, PmtDisc, PmtDiscLCY, PmtDiscAddCurr);

            if not GLSetup."Pmt. Disc. Excl. VAT" and GLSetup."Adjust for Payment Disc." and (PmtDiscLCY <> 0) then
                CalcPmtDiscIfAdjVAT(
                  NewCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, PmtDiscLCY, PmtDiscAddCurr,
                  NextTransactionNo, FirstNewVATEntryNo, DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)");

            DtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
                GenJnlLine, NewCVLedgEntryBuf, DtldCVLedgEntryBuf,
                DtldCVLedgEntryBuf."Entry Type"::"Payment Discount", PmtDisc, PmtDiscLCY, PmtDiscAddCurr, 0, 0, 0);

            OnCalcPmtDiscOnAfterCalcPmtDisc(DtldCVLedgEntryBuf, OldCVLedgEntryBuf2, PmtDisc, PmtDiscLCY);
        end;
    end;

    local procedure CalcPmtDiscIfAdjVAT(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; var PmtDiscLCY2: Decimal; var PmtDiscAddCurr2: Decimal; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        VATEntry2: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DtldCVLedgEntryBuf2: Record "Detailed CV Ledg. Entry Buffer";
        OriginalAmountAddCurr: Decimal;
        PmtDiscRounding: Decimal;
        PmtDiscRoundingAddCurr: Decimal;
        PmtDiscFactorLCY: Decimal;
        PmtDiscFactorAddCurr: Decimal;
        VATBase: Decimal;
        VATBaseAddCurr: Decimal;
        VATAmount: Decimal;
        VATAmountAddCurr: Decimal;
        TotalVATAmount: Decimal;
        LastConnectionNo: Integer;
        VATEntryModifier: Integer;
    begin
        if OldCVLedgEntryBuf."Original Amt. (LCY)" = 0 then
            exit;

        if (AddCurrencyCode = '') or (AddCurrencyCode = OldCVLedgEntryBuf."Currency Code") then
            OriginalAmountAddCurr := OldCVLedgEntryBuf.Amount
        else
            OriginalAmountAddCurr := CalcLCYToAddCurr(OldCVLedgEntryBuf."Original Amt. (LCY)");

        PmtDiscRounding := PmtDiscLCY2;
        PmtDiscFactorLCY := PmtDiscLCY2 / OldCVLedgEntryBuf."Original Amt. (LCY)";
        if OriginalAmountAddCurr <> 0 then
            PmtDiscFactorAddCurr := PmtDiscAddCurr2 / OriginalAmountAddCurr
        else
            PmtDiscFactorAddCurr := 0;
        VATEntry2.Reset();
        VATEntry2.SetCurrentKey("Transaction No.");
        VATEntry2.SetRange("Transaction No.", OldCVLedgEntryBuf."Transaction No.");
        if OldCVLedgEntryBuf."Transaction No." = NextTransactionNo then
            VATEntry2.SetRange("Entry No.", 0, FirstNewVATEntryNo - 1);

        OnCalcPmtDiscIfAdjVATOnBeforeVATEntryFind(
            GenJnlLine, OldCVLedgEntryBuf, NewCVLedgEntryBuf, VATEntry2,
            PmtDiscLCY2, PmtDiscAddCurr2, PmtDiscFactorLCY, PmtDiscFactorAddCurr);

        if VATEntry2.FindSet() then begin
            TotalVATAmount := 0;
            LastConnectionNo := 0;
            repeat
                OnCalcPmtDiscAdjVATAmountsOnBeforeProcessVATEntry(GenJnlLine, OldCVLedgEntryBuf, NewCVLedgEntryBuf, VATEntry2);

                VATPostingSetup.Get(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                if VATEntry2."VAT Calculation Type" =
                   VATEntry2."VAT Calculation Type"::"Sales Tax"
                then begin
                    TaxJurisdiction.Get(VATEntry2."Tax Jurisdiction Code");
                    VATPostingSetup."Adjust for Payment Discount" :=
                      TaxJurisdiction."Adjust for Payment Discount";
                end;
                if VATPostingSetup."Adjust for Payment Discount" then begin
                    if LastConnectionNo <> VATEntry2."Sales Tax Connection No." then begin
                        if LastConnectionNo <> 0 then begin
                            DtldCVLedgEntryBuf := DtldCVLedgEntryBuf2;
                            DtldCVLedgEntryBuf."VAT Amount (LCY)" := -TotalVATAmount;
                            DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, false);
                            OnCalcPmtDiscIfAdjVATOnBeforeInsertSummarizedVATAdjForPaymentDiscount(DtldCVLedgEntryBuf, OldCVLedgEntryBuf);
                            InsertSummarizedVAT(GenJnlLine, VATPostingSetup);
                        end;

                        CalcPmtDiscVATBases(VATEntry2, VATBase, VATBaseAddCurr);

                        PmtDiscRounding := PmtDiscRounding + VATBase * PmtDiscFactorLCY;
                        VATBase := Round(PmtDiscRounding - PmtDiscLCY2);
                        PmtDiscLCY2 := PmtDiscLCY2 + VATBase;

                        PmtDiscRoundingAddCurr := PmtDiscRoundingAddCurr + VATBaseAddCurr * PmtDiscFactorAddCurr;
                        VATBaseAddCurr := Round(CalcLCYToAddCurr(VATBase), AddCurrency."Amount Rounding Precision");
                        PmtDiscAddCurr2 := PmtDiscAddCurr2 + VATBaseAddCurr;

                        DtldCVLedgEntryBuf2.Init();
                        DtldCVLedgEntryBuf2."Posting Date" := GenJnlLine."Posting Date";
                        DtldCVLedgEntryBuf2."Document Type" := GenJnlLine."Document Type";
                        DtldCVLedgEntryBuf2."Document No." := GenJnlLine."Document No.";
                        DtldCVLedgEntryBuf2.Amount := 0;
                        DtldCVLedgEntryBuf2."Amount (LCY)" := -VATBase;
                        DtldCVLedgEntryBuf2."Entry Type" := EntryType;
                        case EntryType of
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                                VATEntryModifier := 1000000;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                                VATEntryModifier := 2000000;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                                VATEntryModifier := 3000000;
                        end;
                        DtldCVLedgEntryBuf2.CopyFromCVLedgEntryBuf(NewCVLedgEntryBuf);
                        // The total payment discount in currency is posted on the entry made in
                        // the function CalcPmtDisc.
                        DtldCVLedgEntryBuf2."User ID" := UserId();
                        DtldCVLedgEntryBuf2."Additional-Currency Amount" := -VATBaseAddCurr;
                        OnCalcPmtDiscIfAdjVATCopyFields(DtldCVLedgEntryBuf2, OldCVLedgEntryBuf, GenJnlLine);
                        DtldCVLedgEntryBuf2.CopyPostingGroupsFromVATEntry(VATEntry2);
                        TotalVATAmount := 0;
                        LastConnectionNo := VATEntry2."Sales Tax Connection No.";
                    end;

                    OnBeforeCalcPmtDiscVATAmounts(VATEntry2, DtldCVLedgEntryBuf2, GenJnlLine);
                    CalcPmtDiscVATAmounts(
                        VATEntry2, VATBase, VATBaseAddCurr, VATAmount, VATAmountAddCurr,
                        PmtDiscRounding, PmtDiscFactorLCY, PmtDiscLCY2, PmtDiscAddCurr2);

                    TotalVATAmount := TotalVATAmount + VATAmount;

                    if (PmtDiscAddCurr2 <> 0) and (PmtDiscLCY2 = 0) then begin
                        VATAmountAddCurr := VATAmountAddCurr - PmtDiscAddCurr2;
                        PmtDiscAddCurr2 := 0;
                    end;

                    // Post VAT
                    // VAT for VAT entry
                    if VATEntry2.Type <> VATEntry2.Type::" " then
                        InsertPmtDiscVATForVATEntry(
                            GenJnlLine, TempVATEntry, VATEntry2, VATEntryModifier,
                            VATAmount, VATAmountAddCurr, VATBase, VATBaseAddCurr,
                            PmtDiscFactorLCY, PmtDiscFactorAddCurr);

                    OnCalcPmtDiscIfAdjVATOnBeforeInsertPmtDiscVATForGLEntry(VATEntry, VATEntry2, DtldCVLedgEntryBuf2);
                    // VAT for G/L entry/entries
                    InsertPmtDiscVATForGLEntry(
                        GenJnlLine, DtldCVLedgEntryBuf, NewCVLedgEntryBuf, VATEntry2,
                        VATPostingSetup, TaxJurisdiction, EntryType, VATAmount, VATAmountAddCurr, OldCVLedgEntryBuf);
                end;
            until VATEntry2.Next() = 0;

            if LastConnectionNo <> 0 then begin
                DtldCVLedgEntryBuf := DtldCVLedgEntryBuf2;
                DtldCVLedgEntryBuf."VAT Amount (LCY)" := -TotalVATAmount;
                DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, true);
                OnCalcPmtDiscIfAdjVATOnBeforeInsertSummarizedVATAfterLoop(DtldCVLedgEntryBuf, OldCVLedgEntryBuf);
                InsertSummarizedVAT(GenJnlLine, VATPostingSetup);
            end;
        end;
    end;

    local procedure CalcPmtDiscTolerance(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer)
    var
        PmtDiscTol: Decimal;
        PmtDiscTolLCY: Decimal;
        PmtDiscTolAddCurr: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPmtDiscTolerance(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if not OldCVLedgEntryBuf2."Accepted Pmt. Disc. Tolerance" then
            exit;

        PmtDiscTol := -OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible";
        PmtDiscTolLCY :=
          Round(
            (NewCVLedgEntryBuf."Original Amount" + PmtDiscTol) / NewCVLedgEntryBuf."Original Currency Factor") -
          NewCVLedgEntryBuf."Original Amt. (LCY)";

        OnAfterCalcPmtDiscTolerance(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
          PmtDiscTol, PmtDiscTolLCY, PmtDiscTolAddCurr);

        OldCVLedgEntryBuf."Pmt. Disc. Given (LCY)" := -PmtDiscTolLCY;

        if NewCVLedgEntryBuf."Currency Code" = AddCurrencyCode then
            PmtDiscTolAddCurr := PmtDiscTol
        else
            PmtDiscTolAddCurr := CalcLCYToAddCurr(PmtDiscTolLCY);

        if not GLSetup."Pmt. Disc. Excl. VAT" and GLSetup."Adjust for Payment Disc." and (PmtDiscTolLCY <> 0) then
            CalcPmtDiscIfAdjVAT(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, PmtDiscTolLCY, PmtDiscTolAddCurr,
              NextTransactionNo, FirstNewVATEntryNo, DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)");

        DtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
          GenJnlLine, NewCVLedgEntryBuf, DtldCVLedgEntryBuf,
          DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance", PmtDiscTol, PmtDiscTolLCY, PmtDiscTolAddCurr, 0, 0, 0);

        OnAfterCalcPmtDiscToleranceProc(DtldCVLedgEntryBuf, OldCVLedgEntryBuf, PmtDiscTol, PmtDiscTolLCY);
    end;

    local procedure CalcPmtDiscVATBases(VATEntry2: Record "VAT Entry"; var VATBase: Decimal; var VATBaseAddCurr: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        case VATEntry2."VAT Calculation Type" of
            VATEntry2."VAT Calculation Type"::"Normal VAT",
            VATEntry2."VAT Calculation Type"::"Reverse Charge VAT",
            VATEntry2."VAT Calculation Type"::"Full VAT":
                begin
                    VATBase :=
                      VATEntry2.Base + VATEntry2."Unrealized Base";
                    VATBaseAddCurr :=
                      VATEntry2."Additional-Currency Base" +
                      VATEntry2."Add.-Currency Unrealized Base";
                end;
            VATEntry2."VAT Calculation Type"::"Sales Tax":
                begin
                    VATEntry.Reset();
                    VATEntry.SetCurrentKey("Transaction No.");
                    VATEntry.SetRange("Transaction No.", VATEntry2."Transaction No.");
                    VATEntry.SetRange("Sales Tax Connection No.", VATEntry2."Sales Tax Connection No.");
                    VATEntry := VATEntry2;
                    repeat
                        if VATEntry.Base < 0 then
                            VATEntry.SetFilter(Base, '>%1', VATEntry.Base)
                        else
                            VATEntry.SetFilter(Base, '<%1', VATEntry.Base);
                    until not VATEntry.FindLast;
                    VATEntry.Reset();
                    VATBase :=
                      VATEntry.Base + VATEntry."Unrealized Base";
                    VATBaseAddCurr :=
                      VATEntry."Additional-Currency Base" +
                      VATEntry."Add.-Currency Unrealized Base";
                end;
        end;
    end;

    local procedure CalcPmtDiscVATAmounts(VATEntry2: Record "VAT Entry"; VATBase: Decimal; VATBaseAddCurr: Decimal; var VATAmount: Decimal; var VATAmountAddCurr: Decimal; var PmtDiscRounding: Decimal; PmtDiscFactorLCY: Decimal; var PmtDiscLCY2: Decimal; var PmtDiscAddCurr2: Decimal)
    begin
        case VATEntry2."VAT Calculation Type" of
            VATEntry2."VAT Calculation Type"::"Normal VAT",
          VATEntry2."VAT Calculation Type"::"Full VAT":
                if (VATEntry2.Amount + VATEntry2."Unrealized Amount" <> 0) or
                   (VATEntry2."Additional-Currency Amount" + VATEntry2."Add.-Currency Unrealized Amt." <> 0)
                then begin
                    if (VATBase = 0) and
                       (VATEntry2."VAT Calculation Type" <> VATEntry2."VAT Calculation Type"::"Full VAT")
                    then
                        VATAmount := 0
                    else begin
                        PmtDiscRounding :=
                          PmtDiscRounding +
                          (VATEntry2.Amount + VATEntry2."Unrealized Amount") * PmtDiscFactorLCY;
                        VATAmount := Round(PmtDiscRounding - PmtDiscLCY2);
                        PmtDiscLCY2 := PmtDiscLCY2 + VATAmount;
                    end;
                    if (VATBaseAddCurr = 0) and
                       (VATEntry2."VAT Calculation Type" <> VATEntry2."VAT Calculation Type"::"Full VAT")
                    then
                        VATAmountAddCurr := 0
                    else begin
                        VATAmountAddCurr := Round(CalcLCYToAddCurr(VATAmount), AddCurrency."Amount Rounding Precision");
                        PmtDiscAddCurr2 := PmtDiscAddCurr2 + VATAmountAddCurr;
                    end;
                end else begin
                    VATAmount := 0;
                    VATAmountAddCurr := 0;
                end;
            VATEntry2."VAT Calculation Type"::"Reverse Charge VAT":
                begin
                    VATAmount :=
                      Round((VATEntry2.Amount + VATEntry2."Unrealized Amount") * PmtDiscFactorLCY);
                    VATAmountAddCurr := Round(CalcLCYToAddCurr(VATAmount), AddCurrency."Amount Rounding Precision");
                    if PmtDiscLCY2 = 0 then
                        PmtDiscAddCurr2 := 0
                end;
            VATEntry2."VAT Calculation Type"::"Sales Tax":
                if (VATEntry2.Type = VATEntry2.Type::Purchase) and VATEntry2."Use Tax" then begin
                    VATAmount :=
                      Round((VATEntry2.Amount + VATEntry2."Unrealized Amount") * PmtDiscFactorLCY);
                    VATAmountAddCurr := Round(CalcLCYToAddCurr(VATAmount), AddCurrency."Amount Rounding Precision");
                end else
                    if (VATEntry2.Amount + VATEntry2."Unrealized Amount" <> 0) or
                       (VATEntry2."Additional-Currency Amount" + VATEntry2."Add.-Currency Unrealized Amt." <> 0)
                    then begin
                        if VATBase = 0 then
                            VATAmount := 0
                        else begin
                            PmtDiscRounding :=
                              PmtDiscRounding +
                              (VATEntry2.Amount + VATEntry2."Unrealized Amount") * PmtDiscFactorLCY;
                            VATAmount := Round(PmtDiscRounding - PmtDiscLCY2);
                            PmtDiscLCY2 := PmtDiscLCY2 + VATAmount;
                        end;

                        if VATBaseAddCurr = 0 then
                            VATAmountAddCurr := 0
                        else begin
                            VATAmountAddCurr := Round(CalcLCYToAddCurr(VATAmount), AddCurrency."Amount Rounding Precision");
                            PmtDiscAddCurr2 := PmtDiscAddCurr2 + VATAmountAddCurr;
                        end;
                    end else begin
                        VATAmount := 0;
                        VATAmountAddCurr := 0;
                    end;
        end;
    end;

    local procedure InsertPmtDiscVATForVATEntry(GenJnlLine: Record "Gen. Journal Line"; var TempVATEntry: Record "VAT Entry" temporary; VATEntry2: Record "VAT Entry"; VATEntryModifier: Integer; VATAmount: Decimal; VATAmountAddCurr: Decimal; VATBase: Decimal; VATBaseAddCurr: Decimal; PmtDiscFactorLCY: Decimal; PmtDiscFactorAddCurr: Decimal)
    var
        TempVATEntryNo: Integer;
    begin
        TempVATEntry.Reset();
        TempVATEntry.SetRange("Entry No.", VATEntryModifier, VATEntryModifier + 999999);
        if TempVATEntry.FindLast then
            TempVATEntryNo := TempVATEntry."Entry No." + 1
        else
            TempVATEntryNo := VATEntryModifier + 1;
        TempVATEntry := VATEntry2;
        TempVATEntry."Entry No." := TempVATEntryNo;
        TempVATEntry."Posting Date" := GenJnlLine."Posting Date";
        TempVATEntry."Document Date" := GenJnlLine."Document Date";
        TempVATEntry."Document No." := GenJnlLine."Document No.";
        TempVATEntry."External Document No." := GenJnlLine."External Document No.";
        TempVATEntry."Document Type" := GenJnlLine."Document Type";
        TempVATEntry."Source Code" := GenJnlLine."Source Code";
        TempVATEntry."Reason Code" := GenJnlLine."Reason Code";
        TempVATEntry."Transaction No." := NextTransactionNo;
        TempVATEntry."Sales Tax Connection No." := NextConnectionNo;
        TempVATEntry."Unrealized Amount" := 0;
        TempVATEntry."Unrealized Base" := 0;
        TempVATEntry."Remaining Unrealized Amount" := 0;
        TempVATEntry."Remaining Unrealized Base" := 0;
        TempVATEntry."User ID" := UserId;
        TempVATEntry."Closed by Entry No." := 0;
        TempVATEntry.Closed := false;
        TempVATEntry."Internal Ref. No." := '';
        TempVATEntry.Amount := VATAmount;
        TempVATEntry."Additional-Currency Amount" := VATAmountAddCurr;
        TempVATEntry."VAT Difference" := 0;
        TempVATEntry."Add.-Curr. VAT Difference" := 0;
        TempVATEntry."Add.-Currency Unrealized Amt." := 0;
        TempVATEntry."Add.-Currency Unrealized Base" := 0;
        if VATEntry2."Tax on Tax" then begin
            TempVATEntry.Base :=
              Round((VATEntry2.Base + VATEntry2."Unrealized Base") * PmtDiscFactorLCY);
            TempVATEntry."Additional-Currency Base" :=
              Round(
                (VATEntry2."Additional-Currency Base" +
                 VATEntry2."Add.-Currency Unrealized Base") * PmtDiscFactorAddCurr,
                AddCurrency."Amount Rounding Precision");
        end else begin
            TempVATEntry.Base := VATBase;
            TempVATEntry."Additional-Currency Base" := VATBaseAddCurr;
        end;
        TempVATEntry."Base Before Pmt. Disc." := VATEntry.Base;

        if AddCurrencyCode = '' then begin
            TempVATEntry."Additional-Currency Base" := 0;
            TempVATEntry."Additional-Currency Amount" := 0;
            TempVATEntry."Add.-Currency Unrealized Amt." := 0;
            TempVATEntry."Add.-Currency Unrealized Base" := 0;
        end;
        TempVATEntry.Positive := TempVATEntry.Amount > 0;
        TempVATEntry."G/L Acc. No." := '';
        OnBeforeInsertTempVATEntry(TempVATEntry, GenJnlLine, VATEntry2, VATAmount, VATBase);
        TempVATEntry.Insert();
    end;

    local procedure InsertPmtDiscVATForGLEntry(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; VATEntry2: Record "VAT Entry"; var VATPostingSetup: Record "VAT Posting Setup"; var TaxJurisdiction: Record "Tax Jurisdiction"; EntryType: Enum "Detailed CV Ledger Entry Type"; VATAmount: Decimal; VATAmountAddCurr: Decimal; OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
        DtldCVLedgEntryBuf.Init();
        DtldCVLedgEntryBuf.CopyFromCVLedgEntryBuf(NewCVLedgEntryBuf);
        case EntryType of
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                DtldCVLedgEntryBuf."Entry Type" :=
                  DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Adjustment)";
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                DtldCVLedgEntryBuf."Entry Type" :=
                  DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)";
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                DtldCVLedgEntryBuf."Entry Type" :=
                  DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Adjustment)";
        end;
        DtldCVLedgEntryBuf."Posting Date" := GenJnlLine."Posting Date";
        DtldCVLedgEntryBuf."Document Type" := GenJnlLine."Document Type";
        DtldCVLedgEntryBuf."Document No." := GenJnlLine."Document No.";
        OnInsertPmtDiscVATForGLEntryOnAfterCopyFromGenJnlLine(DtldCVLedgEntryBuf, GenJnlLine);
        DtldCVLedgEntryBuf.Amount := 0;
        DtldCVLedgEntryBuf."VAT Bus. Posting Group" := VATEntry2."VAT Bus. Posting Group";
        DtldCVLedgEntryBuf."VAT Prod. Posting Group" := VATEntry2."VAT Prod. Posting Group";
        DtldCVLedgEntryBuf."Tax Jurisdiction Code" := VATEntry2."Tax Jurisdiction Code";
        if GLSetup."Enable Russian Accounting" then
            DtldCVLedgEntryBuf."Applied CV Ledger Entry No." := OldCVLedgEntryBuf."Entry No.";
        // The total payment discount in currency is posted on the entry made in
        // the function CalcPmtDisc.
        DtldCVLedgEntryBuf."User ID" := UserId;
        DtldCVLedgEntryBuf."Use Additional-Currency Amount" := true;

        OnBeforeInsertPmtDiscVATForGLEntry(DtldCVLedgEntryBuf, GenJnlLine, VATEntry2, VATPostingSetup);

        case VATEntry2.Type of
            VATEntry2.Type::Purchase:
                case VATEntry2."VAT Calculation Type" of
                    VATEntry2."VAT Calculation Type"::"Normal VAT",
                    VATEntry2."VAT Calculation Type"::"Full VAT":
                        begin
                            InitGLEntryVAT(GenJnlLine, VATPostingSetup.GetPurchAccount(false), '',
                              VATAmount, VATAmountAddCurr, false,
                              VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                            DtldCVLedgEntryBuf."Amount (LCY)" := -VATAmount;
                            DtldCVLedgEntryBuf."Additional-Currency Amount" := -VATAmountAddCurr;
                            DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, true);
                        end;
                    VATEntry2."VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            InitGLEntryVAT(GenJnlLine, VATPostingSetup.GetPurchAccount(false), '',
                              VATAmount, VATAmountAddCurr, false,
                              VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                            InitGLEntryVAT(GenJnlLine, VATPostingSetup.GetRevChargeAccount(false), '',
                              -VATAmount, -VATAmountAddCurr, false,
                              VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                        end;
                    VATEntry2."VAT Calculation Type"::"Sales Tax":
                        if VATEntry2."Use Tax" then begin
                            InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetPurchAccount(false), '',
                              VATAmount, VATAmountAddCurr, false,
                              VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                            InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetRevChargeAccount(false), '',
                              -VATAmount, -VATAmountAddCurr, false,
                              VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                        end else begin
                            InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetPurchAccount(false), '',
                              VATAmount, VATAmountAddCurr, false,
                              VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                            DtldCVLedgEntryBuf."Amount (LCY)" := -VATAmount;
                            DtldCVLedgEntryBuf."Additional-Currency Amount" := -VATAmountAddCurr;
                            DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, true);
                        end;
                end;
            VATEntry2.Type::Sale:
                case VATEntry2."VAT Calculation Type" of
                    VATEntry2."VAT Calculation Type"::"Normal VAT",
                    VATEntry2."VAT Calculation Type"::"Full VAT":
                        begin
                            InitGLEntryVAT(
                              GenJnlLine, VATPostingSetup.GetSalesAccount(false), '',
                              VATAmount, VATAmountAddCurr, false,
                              VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                            DtldCVLedgEntryBuf."Amount (LCY)" := -VATAmount;
                            DtldCVLedgEntryBuf."Additional-Currency Amount" := -VATAmountAddCurr;
                            DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, true);
                        end;
                    VATEntry2."VAT Calculation Type"::"Reverse Charge VAT":
                        ;
                    VATEntry2."VAT Calculation Type"::"Sales Tax":
                        begin
                            InitGLEntryVAT(
                              GenJnlLine, TaxJurisdiction.GetSalesAccount(false), '',
                              VATAmount, VATAmountAddCurr, false,
                              VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                            DtldCVLedgEntryBuf."Amount (LCY)" := -VATAmount;
                            DtldCVLedgEntryBuf."Additional-Currency Amount" := -VATAmountAddCurr;
                            DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, true);
                        end;
                end;
        end;
    end;

    local procedure CalcCurrencyApplnRounding(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; ApplnRoundingPrecision: Decimal)
    var
        ApplnRounding: Decimal;
        ApplnRoundingLCY: Decimal;
    begin
        if not GLSetup."Enable Russian Accounting" then
            if NewCVLedgEntryBuf."Currency Code" = OldCVLedgEntryBuf."Currency Code" then
                exit;

        ApplnRounding := -(NewCVLedgEntryBuf."Remaining Amount" + OldCVLedgEntryBuf."Remaining Amount");
        ApplnRoundingLCY := Round(ApplnRounding / NewCVLedgEntryBuf."Adjusted Currency Factor");

        if (ApplnRounding = 0) or (Abs(ApplnRounding) > ApplnRoundingPrecision) then
            exit;

        DtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
          GenJnlLine, NewCVLedgEntryBuf, DtldCVLedgEntryBuf,
          DtldCVLedgEntryBuf."Entry Type"::"Appln. Rounding", ApplnRounding, ApplnRoundingLCY, ApplnRounding, 0, 0, 0);
    end;

    local procedure FindAmtForAppln(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var OldAppliedAmount: Decimal; ApplnRoundingPrecision: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindAmtForAppln(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, AppliedAmount, AppliedAmountLCY, OldAppliedAmount, IsHandled,
          ApplnRoundingPrecision);
        if IsHandled then
            exit;

        if OldCVLedgEntryBuf2.GetFilter(Positive) <> '' then begin
            if OldCVLedgEntryBuf2."Amount to Apply" <> 0 then begin
                if (PaymentToleranceMgt.CheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, false, false) and
                    (Abs(OldCVLedgEntryBuf2."Amount to Apply") >=
                     Abs(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible")))
                then
                    AppliedAmount := -OldCVLedgEntryBuf2."Remaining Amount"
                else
                    AppliedAmount := -OldCVLedgEntryBuf2."Amount to Apply"
            end else
                AppliedAmount := -OldCVLedgEntryBuf2."Remaining Amount";
        end else begin
            if OldCVLedgEntryBuf2."Amount to Apply" <> 0 then
                if (PaymentToleranceMgt.CheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, false, false) and
                    (Abs(OldCVLedgEntryBuf2."Amount to Apply") >=
                     Abs(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible")) and
                    (Abs(NewCVLedgEntryBuf."Remaining Amount") >=
                     Abs(
                       ABSMin(
                         OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible",
                         OldCVLedgEntryBuf2."Amount to Apply")))) or
                   OldCVLedgEntryBuf."Accepted Pmt. Disc. Tolerance"
                then begin
                    AppliedAmount := -OldCVLedgEntryBuf2."Remaining Amount";
                    OldCVLedgEntryBuf."Accepted Pmt. Disc. Tolerance" := false;
                end else
                    AppliedAmount := ABSMin(NewCVLedgEntryBuf."Remaining Amount", -OldCVLedgEntryBuf2."Amount to Apply")
            else
                AppliedAmount := ABSMin(NewCVLedgEntryBuf."Remaining Amount", -OldCVLedgEntryBuf2."Remaining Amount");
        end;

        if (Abs(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Amount to Apply") < ApplnRoundingPrecision) and
           (ApplnRoundingPrecision <> 0) and
           (OldCVLedgEntryBuf2."Amount to Apply" <> 0)
        then
            AppliedAmount := AppliedAmount - (OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Amount to Apply");

        if NewCVLedgEntryBuf."Currency Code" = OldCVLedgEntryBuf2."Currency Code" then begin
            AppliedAmountLCY := Round(AppliedAmount / OldCVLedgEntryBuf."Original Currency Factor");
            OldAppliedAmount := AppliedAmount;
        end else begin
            // Management of posting in multiple currencies
            if AppliedAmount = -OldCVLedgEntryBuf2."Remaining Amount" then
                OldAppliedAmount := -OldCVLedgEntryBuf."Remaining Amount"
            else
                OldAppliedAmount :=
                  CurrExchRate.ExchangeAmount(
                    AppliedAmount, NewCVLedgEntryBuf."Currency Code",
                    OldCVLedgEntryBuf2."Currency Code", NewCVLedgEntryBuf."Posting Date");

            if NewCVLedgEntryBuf."Currency Code" <> '' then
                // Post the realized gain or loss on the NewCVLedgEntryBuf
                AppliedAmountLCY := Round(OldAppliedAmount / OldCVLedgEntryBuf."Original Currency Factor")
            else
                // Post the realized gain or loss on the OldCVLedgEntryBuf
                AppliedAmountLCY := Round(AppliedAmount / NewCVLedgEntryBuf."Original Currency Factor");
        end;

        OnAfterFindAmtForAppln(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, AppliedAmount, AppliedAmountLCY, OldAppliedAmount);
    end;

    local procedure CalcCurrencyUnrealizedGainLoss(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; GenJnlLine: Record "Gen. Journal Line"; AppliedAmount: Decimal; RemainingAmountBeforeAppln: Decimal)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        UnRealizedGainLossLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCurrencyUnrealizedGainLoss(
          CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, AppliedAmount, RemainingAmountBeforeAppln, IsHandled);
        if IsHandled then
            exit;

        if (CVLedgEntryBuf."Currency Code" = '') or (RemainingAmountBeforeAppln = 0) then
            exit;

        // Calculate Unrealized GainLoss
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then
            UnRealizedGainLossLCY :=
              Round(
                DtldCustLedgEntry.GetUnrealizedGainLossAmount(CVLedgEntryBuf."Entry No.") *
                Abs(AppliedAmount / RemainingAmountBeforeAppln))
        else
            UnRealizedGainLossLCY :=
              Round(
                DtldVendLedgEntry.GetUnrealizedGainLossAmount(CVLedgEntryBuf."Entry No.") *
                Abs(AppliedAmount / RemainingAmountBeforeAppln));

        if UnRealizedGainLossLCY <> 0 then
            if UnRealizedGainLossLCY < 0 then
                TempDtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
                  GenJnlLine, CVLedgEntryBuf, TempDtldCVLedgEntryBuf,
                  TempDtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss", 0, -UnRealizedGainLossLCY, 0, 0, 0, 0)
            else
                TempDtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
                  GenJnlLine, CVLedgEntryBuf, TempDtldCVLedgEntryBuf,
                  TempDtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain", 0, -UnRealizedGainLossLCY, 0, 0, 0, 0);
    end;

    local procedure CalcCurrencyRealizedGainLoss(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; GenJnlLine: Record "Gen. Journal Line"; AppliedAmount: Decimal; AppliedAmountLCY: Decimal)
    var
        RealizedGainLossLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCurrencyRealizedGainLoss(
          CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, AppliedAmount, AppliedAmountLCY, IsHandled);
        if IsHandled then
            exit;

        if CVLedgEntryBuf."Currency Code" = '' then
            exit;

        if GLSetup."Enable Russian Accounting" and (NewCVLedgEntryBuf."Prepmt. Diff. Appln. Entry No." <> 0) then
            exit;

        RealizedGainLossLCY := AppliedAmountLCY - Round(AppliedAmount / CVLedgEntryBuf."Original Currency Factor");
        OnAfterCalcCurrencyRealizedGainLoss(CVLedgEntryBuf, AppliedAmount, AppliedAmountLCY, RealizedGainLossLCY);

        if RealizedGainLossLCY = 0 then
            exit;

        if not GLSetup."Enable Russian Accounting" then
            if RealizedGainLossLCY < 0 then
                TempDtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
                  GenJnlLine, CVLedgEntryBuf, TempDtldCVLedgEntryBuf,
                  TempDtldCVLedgEntryBuf."Entry Type"::"Realized Loss", 0, RealizedGainLossLCY, 0, 0, 0, 0)
            else
                TempDtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
                  GenJnlLine, CVLedgEntryBuf, TempDtldCVLedgEntryBuf,
                  TempDtldCVLedgEntryBuf."Entry Type"::"Realized Gain", 0, RealizedGainLossLCY, 0, 0, 0, 0);

        if GLSetup."Enable Russian Accounting" then begin
            TempDtldCVLedgEntryBuf.InitFromGenJnlLine(GenJnlLine);
            TempDtldCVLedgEntryBuf.CopyFromCVLedgEntryBuf(CVLedgEntryBuf);
            TempDtldCVLedgEntryBuf."Applied CV Ledger Entry No." := NewCVLedgEntryBuf."Entry No.";
            TempDtldCVLedgEntryBuf."Prepmt. Diff." := PrepmtDiffMgt.CheckCalcPrepDiff(CVLedgEntryBuf, NewCVLedgEntryBuf);
            if RealizedGainLossLCY < 0 then begin
                TempDtldCVLedgEntryBuf."Entry Type" := TempDtldCVLedgEntryBuf."Entry Type"::"Realized Loss";
                TempDtldCVLedgEntryBuf."Amount (LCY)" := RealizedGainLossLCY;
                TempDtldCVLedgEntryBuf.InsertDtldCVLedgEntry(TempDtldCVLedgEntryBuf, CVLedgEntryBuf, false);
            end else begin
                TempDtldCVLedgEntryBuf."Entry Type" := TempDtldCVLedgEntryBuf."Entry Type"::"Realized Gain";
                TempDtldCVLedgEntryBuf."Amount (LCY)" := RealizedGainLossLCY;
                TempDtldCVLedgEntryBuf.InsertDtldCVLedgEntry(TempDtldCVLedgEntryBuf, CVLedgEntryBuf, false);
            end;
            if TempDtldCVLedgEntryBuf."Prepmt. Diff." then
                CalcTaxAccRealizedGainLossAmt(
                  NewCVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, RealizedGainLossLCY, AppliedAmount, AppliedAmountLCY);
        end;
    end;

    local procedure CalcApplication(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; AppliedAmount: Decimal; AppliedAmountLCY: Decimal; OldAppliedAmount: Decimal; PrevNewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; PrevOldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var AllApplied: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAplication(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine,
          AppliedAmount, AppliedAmountLCY, OldAppliedAmount, PrevNewCVLedgEntryBuf, PrevOldCVLedgEntryBuf, AllApplied, IsHandled);
        if IsHandled then
            exit;

        if AppliedAmount = 0 then
            exit;

        if not GLSetup."Enable Russian Accounting" then
            DtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
              GenJnlLine, OldCVLedgEntryBuf, DtldCVLedgEntryBuf,
              DtldCVLedgEntryBuf."Entry Type"::Application, OldAppliedAmount, AppliedAmountLCY, 0,
              NewCVLedgEntryBuf."Entry No.", PrevOldCVLedgEntryBuf."Remaining Pmt. Disc. Possible",
              PrevOldCVLedgEntryBuf."Max. Payment Tolerance")
        else begin
            DtldCVLedgEntryBuf.InitFromGenJnlLine(GenJnlLine);
            DtldCVLedgEntryBuf.CopyFromCVLedgEntryBuf(OldCVLedgEntryBuf);
            DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::Application;
            if NewCVLedgEntryBuf."Prepmt. Diff. Appln. Entry No." <> 0 then begin
                PrepmtDiffMgt.UpdateCurrFactor(NewCVLedgEntryBuf, OldCVLedgEntryBuf);
                OldCVLedgEntryBuf."Currency Code" := NewCVLedgEntryBuf."Closed by Currency Code";
                DtldCVLedgEntryBuf."Currency Code" := NewCVLedgEntryBuf."Closed by Currency Code";
                if DtldCVLedgEntryBuf."Currency Code" <> '' then
                    OldAppliedAmount := 0;
            end;
            DtldCVLedgEntryBuf.Amount := OldAppliedAmount;
            DtldCVLedgEntryBuf."Amount (LCY)" := AppliedAmountLCY;
            DtldCVLedgEntryBuf."Applied CV Ledger Entry No." := NewCVLedgEntryBuf."Entry No.";
            DtldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" :=
              PrevOldCVLedgEntryBuf."Remaining Pmt. Disc. Possible";
            DtldCVLedgEntryBuf."Max. Payment Tolerance" := PrevOldCVLedgEntryBuf."Max. Payment Tolerance";
            DtldCVLedgEntryBuf."Applied Amount (LCY)" := AppliedAmountLCY;
            DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, OldCVLedgEntryBuf, false);
        end;

        OnAfterInitOldDtldCVLedgEntryBuf(
          DtldCVLedgEntryBuf, NewCVLedgEntryBuf, OldCVLedgEntryBuf, PrevNewCVLedgEntryBuf, PrevOldCVLedgEntryBuf, GenJnlLine);

        OldCVLedgEntryBuf.Open := OldCVLedgEntryBuf."Remaining Amount" <> 0;
        if GLSetup."Enable Russian Accounting" and (NewCVLedgEntryBuf."Prepmt. Diff. Appln. Entry No." <> 0) then
            OldCVLedgEntryBuf.Open := OldCVLedgEntryBuf."Remaining Amt. (LCY)" <> 0;
        if not OldCVLedgEntryBuf.Open then
            OldCVLedgEntryBuf.SetClosedFields(
              NewCVLedgEntryBuf."Entry No.", GenJnlLine."Posting Date",
              -OldAppliedAmount, -AppliedAmountLCY, NewCVLedgEntryBuf."Currency Code", -AppliedAmount)
        else
            AllApplied := false;

        DtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
          GenJnlLine, NewCVLedgEntryBuf, DtldCVLedgEntryBuf,
          DtldCVLedgEntryBuf."Entry Type"::Application, -AppliedAmount, -AppliedAmountLCY, 0,
          NewCVLedgEntryBuf."Entry No.", PrevNewCVLedgEntryBuf."Remaining Pmt. Disc. Possible",
          PrevNewCVLedgEntryBuf."Max. Payment Tolerance");

        OnAfterInitNewDtldCVLedgEntryBuf(
          DtldCVLedgEntryBuf, NewCVLedgEntryBuf, OldCVLedgEntryBuf, PrevNewCVLedgEntryBuf, PrevOldCVLedgEntryBuf, GenJnlLine);

        NewCVLedgEntryBuf.Open := NewCVLedgEntryBuf."Remaining Amount" <> 0;
        if not NewCVLedgEntryBuf.Open and not AllApplied then
            NewCVLedgEntryBuf.SetClosedFields(
              OldCVLedgEntryBuf."Entry No.", GenJnlLine."Posting Date",
              AppliedAmount, AppliedAmountLCY, OldCVLedgEntryBuf."Currency Code", OldAppliedAmount);

        OnAfterCalcApplication(GenJnlLine, DtldCVLedgEntryBuf);
    end;

    local procedure CalcAmtLCYAdjustment(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line")
    var
        AdjustedAmountLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAmtLCYAdjustment(CVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if CVLedgEntryBuf."Currency Code" = '' then
            exit;

        if GLSetup."Enable Russian Accounting" then begin
            if NewCVLedgEntryBuf."Prepmt. Diff. Appln. Entry No." <> 0 then
                exit;
            if GLSetup."Cancel Curr. Prepmt. Adjmt." and CVLedgEntryBuf.Prepayment then
                if (CVLedgEntryBuf."Adjusted Currency Factor" <> CVLedgEntryBuf."Original Currency Factor") and
                   CVLedgEntryBuf.Open
                then
                    exit;
        end;

        AdjustedAmountLCY :=
          Round(CVLedgEntryBuf."Remaining Amount" / CVLedgEntryBuf."Adjusted Currency Factor");

        if AdjustedAmountLCY <> CVLedgEntryBuf."Remaining Amt. (LCY)" then begin
            DtldCVLedgEntryBuf.InitFromGenJnlLine(GenJnlLine);
            DtldCVLedgEntryBuf.CopyFromCVLedgEntryBuf(CVLedgEntryBuf);
            DtldCVLedgEntryBuf."Entry Type" :=
              DtldCVLedgEntryBuf."Entry Type"::"Correction of Remaining Amount";
            DtldCVLedgEntryBuf."Amount (LCY)" := AdjustedAmountLCY - CVLedgEntryBuf."Remaining Amt. (LCY)";
            DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, false);
        end;
    end;

    local procedure InitBankAccLedgEntry(GenJnlLine: Record "Gen. Journal Line"; var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
        OnBeforeInitBankAccLedgEntry(BankAccLedgEntry, GenJnlLine);

        BankAccLedgEntry.Init();
        BankAccLedgEntry.CopyFromGenJnlLine(GenJnlLine);
        BankAccLedgEntry."Entry No." := NextEntryNo;
        BankAccLedgEntry."Transaction No." := NextTransactionNo;

        OnAfterInitBankAccLedgEntry(BankAccLedgEntry, GenJnlLine);
    end;

    local procedure InitCheckLedgEntry(BankAccLedgEntry: Record "Bank Account Ledger Entry"; var CheckLedgEntry: Record "Check Ledger Entry")
    begin
        OnBeforeInitCheckEntry(BankAccLedgEntry, CheckLedgEntry);

        CheckLedgEntry.Init();
        CheckLedgEntry.CopyFromBankAccLedgEntry(BankAccLedgEntry);
        CheckLedgEntry."Entry No." := NextCheckEntryNo;

        OnAfterInitCheckLedgEntry(CheckLedgEntry, BankAccLedgEntry);
    end;

    local procedure InitCustLedgEntry(GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        OnBeforeInitCustLedgEntry(CustLedgEntry, GenJnlLine);

        CustLedgEntry.Init();
        CustLedgEntry.CopyFromGenJnlLine(GenJnlLine);
        CustLedgEntry."Entry No." := NextEntryNo;
        CustLedgEntry."Transaction No." := NextTransactionNo;

        OnAfterInitCustLedgEntry(CustLedgEntry, GenJnlLine);
    end;

    local procedure InitVendLedgEntry(GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        OnBeforeInitVendLedgEntry(VendLedgEntry, GenJnlLine);

        VendLedgEntry.Init();
        VendLedgEntry.CopyFromGenJnlLine(GenJnlLine);
        VendLedgEntry."Entry No." := NextEntryNo;
        VendLedgEntry."Transaction No." := NextTransactionNo;

        OnAfterInitVendLedgEntry(VendLedgEntry, GenJnlLine);
    end;

    local procedure InsertDtldCustLedgEntry(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; Offset: Integer)
    begin
        if GenJnlLine."Prepmt. Diff." then
            exit;

        with DtldCustLedgEntry do begin
            Init;
            TransferFields(DtldCVLedgEntryBuf);
            "Entry No." := Offset + DtldCVLedgEntryBuf."Entry No.";
            "Journal Batch Name" := GenJnlLine."Journal Batch Name";
            "Reason Code" := GenJnlLine."Reason Code";
            "Source Code" := GenJnlLine."Source Code";
            "Transaction No." := NextTransactionNo;
            UpdateDebitCredit(GenJnlLine.Correction);
            "Customer Posting Group" := GenJnlLine."Posting Group";
            "Agreement No." := GenJnlLine."Agreement No.";
            if "Prepmt. Diff." then
                "Entry Type" := "Entry Type"::Application;
            OnBeforeInsertDtldCustLedgEntry(DtldCustLedgEntry, GenJnlLine, DtldCVLedgEntryBuf);
            Insert(true);
            OnAfterInsertDtldCustLedgEntry(DtldCustLedgEntry, GenJnlLine, DtldCVLedgEntryBuf, Offset);
        end;
    end;

    local procedure InsertDtldVendLedgEntry(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; Offset: Integer)
    begin
        if GenJnlLine."Prepmt. Diff." then
            exit;

        with DtldVendLedgEntry do begin
            Init;
            TransferFields(DtldCVLedgEntryBuf);
            "Entry No." := Offset + DtldCVLedgEntryBuf."Entry No.";
            "Journal Batch Name" := GenJnlLine."Journal Batch Name";
            "Reason Code" := GenJnlLine."Reason Code";
            "Source Code" := GenJnlLine."Source Code";
            "Transaction No." := NextTransactionNo;
            UpdateDebitCredit(GenJnlLine.Correction);
            "Vendor Posting Group" := GenJnlLine."Posting Group";
            "Agreement No." := GenJnlLine."Agreement No.";
            if "Prepmt. Diff." then
                "Entry Type" := "Entry Type"::Application;
            OnBeforeInsertDtldVendLedgEntry(DtldVendLedgEntry, GenJnlLine, DtldCVLedgEntryBuf);
            Insert(true);
            OnAfterInsertDtldVendLedgEntry(DtldVendLedgEntry, GenJnlLine, DtldCVLedgEntryBuf, Offset);
        end;
    end;

    procedure ApplyCustLedgEntry(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; Cust: Record Customer)
    var
        OldCustLedgEntry: Record "Cust. Ledger Entry";
        OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        NewCustLedgEntry: Record "Cust. Ledger Entry";
        NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
        TempOldCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        Completed: Boolean;
        AppliedAmount: Decimal;
        NewRemainingAmtBeforeAppln: Decimal;
        ApplyingDate: Date;
        PmtTolAmtToBeApplied: Decimal;
        AllApplied: Boolean;
        IsAmountToApplyCheckHandled: Boolean;
        AmtDiffDocToPrepayment: Boolean;
        ShouldUpdateCalcInterest: Boolean;
    begin
        OnBeforeApplyCustLedgEntry(NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, Cust, IsAmountToApplyCheckHandled);
        if not IsAmountToApplyCheckHandled then
            if NewCVLedgEntryBuf."Amount to Apply" = 0 then
                exit;

        AllApplied := true;
        if (GenJnlLine."Applies-to Doc. No." = '') and (GenJnlLine."Applies-to ID" = '') and
           not
           ((Cust."Application Method" = Cust."Application Method"::"Apply to Oldest") and
            GenJnlLine."Allow Application")
        then
            exit;

        SalesSetup.Get();
        if (Cust."Application Method" = Cust."Application Method"::"Apply to Oldest") and
           SalesSetup."Check Application Date"
        then
            Error(CheckApplnDateCustErr, Cust."No.");

        PmtTolAmtToBeApplied := 0;
        NewRemainingAmtBeforeAppln := NewCVLedgEntryBuf."Remaining Amount";
        NewCVLedgEntryBuf2 := NewCVLedgEntryBuf;

        ApplyingDate := GenJnlLine."Posting Date";

        OnApplyCustLedgEntryOnBeforePrepareTempCustLedgEntry(GenJnlLine, NewCVLedgEntryBuf, DtldCVLedgEntryBuf, NextEntryNo);
        if not PrepareTempCustLedgEntry(GenJnlLine, NewCVLedgEntryBuf, TempOldCustLedgEntry, Cust, ApplyingDate) then
            exit;

        GenJnlLine."Posting Date" := ApplyingDate;
        // Apply the new entry (Payment) to the old entries (Invoices) one at a time
        repeat
            if GLSetup."Enable Russian Accounting" then begin
                if SalesSetup."Check Application Date" and
                   (TempOldCustLedgEntry."Posting Date" > NewCVLedgEntryBuf."Posting Date")
                then
                    Error(MustNotBeAfterErr,
                      NewCVLedgEntryBuf."Posting Date", TempOldCustLedgEntry.TableCaption, TempOldCustLedgEntry."Entry No.");
                if SalesSetup."Check Application Period" then begin
                    if CalcDate('<CM>', TempOldCustLedgEntry."Posting Date") <> CalcDate('<CM>', NewCVLedgEntryBuf."Posting Date") then
                        if (TempOldCustLedgEntry."Document Type" in
                            [TempOldCustLedgEntry."Document Type"::" ", TempOldCustLedgEntry."Document Type"::Payment,
                             TempOldCustLedgEntry."Document Type"::Refund]) and
                           not TempOldCustLedgEntry.Prepayment
                        then
                            Error(ApplnPrepmtOnlyErr);
                end;
                CheckCustPrepmtApplPostingDate(GenJnlLine, NewCVLedgEntryBuf, TempOldCustLedgEntry);
            end;

            if Cust."Agreement Posting" = Cust."Agreement Posting"::Mandatory then
                if TempOldCustLedgEntry."Agreement No." <> NewCVLedgEntryBuf."Agreement No." then
                    Error(AgreementMustBeErr, NewCVLedgEntryBuf."Agreement No.", TempOldCustLedgEntry."Document No.");

            TempOldCustLedgEntry.CalcFields(
              Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
              "Original Amount", "Original Amt. (LCY)");
            TempOldCustLedgEntry.CopyFilter(Positive, OldCVLedgEntryBuf.Positive);
            OldCVLedgEntryBuf.CopyFromCustLedgEntry(TempOldCustLedgEntry);

            PostApply(
              GenJnlLine, DtldCVLedgEntryBuf, OldCVLedgEntryBuf, NewCVLedgEntryBuf, NewCVLedgEntryBuf2,
              Cust."Block Payment Tolerance", AllApplied, AppliedAmount, PmtTolAmtToBeApplied);

            ShouldUpdateCalcInterest := not OldCVLedgEntryBuf.Open;
            OnApplyCustLedgEntryOnAfterCalcShouldUpdateCalcInterestFromOldBuf(OldCVLedgEntryBuf, NewCVLedgEntryBuf, Cust, ShouldUpdateCalcInterest);
            if ShouldUpdateCalcInterest then begin
                UpdateCalcInterest(OldCVLedgEntryBuf);
                UpdateCalcInterest(OldCVLedgEntryBuf, NewCVLedgEntryBuf);
            end;

            TempOldCustLedgEntry.CopyFromCVLedgEntryBuffer(OldCVLedgEntryBuf);
            OldCustLedgEntry := TempOldCustLedgEntry;
            if OldCustLedgEntry."Amount to Apply" = 0 then
                OldCustLedgEntry."Applies-to ID" := ''
            else begin
                TempCustLedgEntry := OldCustLedgEntry;
                if TempCustLedgEntry.Insert() then;
            end;
            OldCustLedgEntry.Modify();

            OnAfterOldCustLedgEntryModify(OldCustLedgEntry, GenJnlLine);

            if not GLSetup."Enable Russian Accounting" and
               (GLSetup."Unrealized VAT" or
                (GLSetup."Prepayment Unrealized VAT" and TempOldCustLedgEntry.Prepayment))
            then
                if IsNotPayment(TempOldCustLedgEntry."Document Type") then begin
                    TempOldCustLedgEntry.RecalculateAmounts(
                      NewCVLedgEntryBuf."Currency Code", TempOldCustLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date");
                    OnApplyCustLedgEntryOnAfterRecalculateAmounts(TempOldCustLedgEntry, OldCustLedgEntry, NewCVLedgEntryBuf, GenJnlLine);
                    CustUnrealizedVAT(
                      GenJnlLine,
                      TempOldCustLedgEntry,
                      CurrExchRate.ExchangeAmount(
                        AppliedAmount, NewCVLedgEntryBuf."Currency Code",
                        TempOldCustLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date"), 0, 0, 0);
                end;

            if GLSetup."Enable Russian Accounting" and not AmtDiffDocToPrepayment and
               (GLSetup."Unrealized VAT" or
                (GLSetup."Prepayment Unrealized VAT" and TempOldCustLedgEntry.Prepayment))
            then begin
                if TempOldCustLedgEntry."Prepayment Document No." <> TempOldCustLedgEntry."Document No." then begin
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
                    GenJnlLine."Document No." := OldCustLedgEntry."Prepayment Document No.";
                end;

                OldCustLedgEntry.CalcFields(Amount, "Credit Amount", "Debit Amount");
                GenJnlLine.Correction :=
                  (OldCustLedgEntry.Amount > 0) and (OldCustLedgEntry."Credit Amount" < 0) or
                  (OldCustLedgEntry.Amount < 0) and (OldCustLedgEntry."Debit Amount" < 0);
                if OldCustLedgEntry."Currency Code" = '' then
                    CustUnrealizedVAT(GenJnlLine, OldCustLedgEntry, AppliedAmount, 0, 0, 0)
                else
                    CustUnrealizedVAT(
                      GenJnlLine,
                      TempOldCustLedgEntry,
                      CurrExchRate.ExchangeAmount(
                        AppliedAmount, NewCVLedgEntryBuf."Currency Code",
                        TempOldCustLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date"), 0, 0, 0);
            end;

            OnApplyCustLedgEntryOnBeforeTempOldCustLedgEntryDelete(TempOldCustLedgEntry, NewCVLedgEntryBuf, GenJnlLine, Cust, NextEntryNo, GLReg, AppliedAmount);
            TempOldCustLedgEntry.Delete();

            OnApplyCustLedgerEntryOnBeforeSetCompleted(GenJnlLine, OldCustLedgEntry, NewCVLedgEntryBuf);

            Completed := FindNextOldCustLedgEntryToApply(GenJnlLine, TempOldCustLedgEntry, NewCVLedgEntryBuf);
        until Completed;

        DtldCVLedgEntryBuf.SetCurrentKey("CV Ledger Entry No.", "Entry Type");
        DtldCVLedgEntryBuf.SetRange("CV Ledger Entry No.", NewCVLedgEntryBuf."Entry No.");
        DtldCVLedgEntryBuf.SetRange(
          "Entry Type",
          DtldCVLedgEntryBuf."Entry Type"::Application);
        DtldCVLedgEntryBuf.CalcSums("Amount (LCY)", Amount);

        CalcCurrencyUnrealizedGainLoss(
          NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, DtldCVLedgEntryBuf.Amount, NewRemainingAmtBeforeAppln);

        CalcAmtLCYAdjustment(NewCVLedgEntryBuf, OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine);

        NewCVLedgEntryBuf."Applies-to ID" := '';
        NewCVLedgEntryBuf."Amount to Apply" := 0;

        ShouldUpdateCalcInterest := not NewCVLedgEntryBuf.Open;
        OnApplyCustLedgEntryOnAfterCalcShouldUpdateCalcInterestFromNewBuf(OldCVLedgEntryBuf, NewCVLedgEntryBuf, Cust, ShouldUpdateCalcInterest);
        if ShouldUpdateCalcInterest then
            UpdateCalcInterest(NewCVLedgEntryBuf);

        if GLSetup."Enable Russian Accounting" and AmtDiffDocToPrepayment then
            exit;

        if GLSetup."Unrealized VAT" or
           (GLSetup."Prepayment Unrealized VAT" and NewCVLedgEntryBuf.Prepayment)
        then
            if (IsNotPayment(NewCVLedgEntryBuf."Document Type") or
               IsPrepayment(NewCVLedgEntryBuf."Document Type", NewCVLedgEntryBuf.Prepayment)) and
               (NewRemainingAmtBeforeAppln - NewCVLedgEntryBuf."Remaining Amount" <> 0)
            then begin
                NewCustLedgEntry.CopyFromCVLedgEntryBuffer(NewCVLedgEntryBuf);
                if GLSetup."Enable Russian Accounting" then begin
                    if GenJnlLine."Prepayment Status" <> GenJnlLine."Prepayment Status"::Set then
                        CheckUnrealizedCust := true;
                    if NewCustLedgEntry."Prepayment Document No." <> NewCustLedgEntry."Document No." then begin
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
                        GenJnlLine."Document No." := NewCustLedgEntry."Prepayment Document No.";
                    end;
                end else
                    CheckUnrealizedCust := true;
                UnrealizedCustLedgEntry := NewCustLedgEntry;
                UnrealizedCustLedgEntry.CalcFields("Amount (LCY)", "Original Amt. (LCY)");
                UnrealizedRemainingAmountCust := NewCustLedgEntry."Remaining Amount" - NewRemainingAmtBeforeAppln;
            end;

        OnAfterApplyCustLedgEntry(GenJnlLine, NewCVLedgEntryBuf, OldCustLedgEntry);
    end;

    local procedure FindNextOldCustLedgEntryToApply(GenJnlLine: Record "Gen. Journal Line"; var TempOldCustLedgEntry: Record "Cust. Ledger Entry" temporary; NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer") Completed: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeFindNextOldCustLedgEntryToApply(GenJnlLine, TempOldCustLedgEntry, NewCVLedgEntryBuf, Completed, IsHandled);
        if IsHandled then
            exit(Completed);

        if GenJnlLine."Applies-to Doc. No." <> '' then
            Completed := true
        else
            if TempOldCustLedgEntry.GetFilter(Positive) <> '' then
                if TempOldCustLedgEntry.Next = 1 then
                    Completed := false
                else begin
                    TempOldCustLedgEntry.SetRange(Positive);
                    TempOldCustLedgEntry.Find('-');
                    TempOldCustLedgEntry.CalcFields("Remaining Amount");
                    Completed := TempOldCustLedgEntry."Remaining Amount" * NewCVLedgEntryBuf."Remaining Amount" >= 0;
                end
            else
                if NewCVLedgEntryBuf.Open then
                    Completed := TempOldCustLedgEntry.Next() = 0
                else
                    Completed := true;
    end;

    procedure CustPostApplyCustLedgEntry(var GenJnlLinePostApply: Record "Gen. Journal Line"; var CustLedgEntryPostApply: Record "Cust. Ledger Entry")
    var
        Cust: Record Customer;
        CustPostingGr: Record "Customer Posting Group";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        GenJnlLine: Record "Gen. Journal Line";
        DtldLedgEntryInserted: Boolean;
    begin
        OnBeforeCustPostApplyCustLedgEntry(GenJnlLinePostApply);

        GenJnlLine := GenJnlLinePostApply;
        CustLedgEntry.TransferFields(CustLedgEntryPostApply);
        with GenJnlLine do begin
            "Source Currency Code" := CustLedgEntryPostApply."Currency Code";
            "Applies-to ID" := CustLedgEntryPostApply."Applies-to ID";

            GenJnlCheckLine.RunCheck(GenJnlLine);

            if NextEntryNo = 0 then
                StartPosting(GenJnlLine)
            else
                ContinuePosting(GenJnlLine);

            Cust.Get(CustLedgEntry."Customer No.");
            Cust.CheckBlockedCustOnJnls(Cust, "Document Type", true);

            OnCustPostApplyCustLedgEntryOnBeforeCheckPostingGroup(GenJnlLine, Cust);

            if "Posting Group" = '' then begin
                Cust.TestField("Customer Posting Group");
                "Posting Group" := Cust."Customer Posting Group";
            end;
            CustPostingGr.Get("Posting Group");
            CustPostingGr.GetReceivablesAccount();

            DtldCustLedgEntry.LockTable();
            CustLedgEntry.LockTable();

            // Post the application
            CustLedgEntry.CalcFields(
              Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
              "Original Amount", "Original Amt. (LCY)");
            CVLedgEntryBuf.CopyFromCustLedgEntry(CustLedgEntry);
            ApplyCustLedgEntry(CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, Cust);
            OnCustPostApplyCustLedgEntryOnAfterApplyCustLedgEntry(GenJnlLine, TempDtldCVLedgEntryBuf);
            CustLedgEntry.CopyFromCVLedgEntryBuffer(CVLedgEntryBuf);
            CustLedgEntry.Modify();

            // Post the Dtld customer entry
            OnCustPostApplyCustLedgEntryOnBeforePostDtldCustLedgEntries(CustLedgEntry);
            DtldLedgEntryInserted := PostDtldCustLedgEntries(GenJnlLine, TempDtldCVLedgEntryBuf, CustPostingGr, false);

            CheckPostUnrealizedVAT(GenJnlLine, true);

            if DtldLedgEntryInserted then
                if IsTempGLEntryBufEmpty then
                    DtldCustLedgEntry.SetZeroTransNo(NextTransactionNo);

            OnCustPostApplyCustLedgEntryOnBeforeFinishPosting(GenJnlLine, CustLedgEntry);

            FinishPosting(GenJnlLine);

            OnAfterCustPostApplyCustLedgEntry(GenJnlLine, GLReg);
        end;
    end;

    local procedure PrepareTempCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempOldCustLedgEntry: Record "Cust. Ledger Entry" temporary; Cust: Record Customer; var ApplyingDate: Date): Boolean
    var
        OldCustLedgEntry: Record "Cust. Ledger Entry";
        SalesSetup: Record "Sales & Receivables Setup";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        RemainingAmount: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforePrepareTempCustledgEntry(GenJnlLine, NewCVLedgEntryBuf);

        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            // Find the entry to be applied to
            OldCustLedgEntry.Reset();
            OldCustLedgEntry.SetCurrentKey("Document No.");
            OldCustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            OldCustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            OldCustLedgEntry.SetRange("Customer No.", NewCVLedgEntryBuf."CV No.");
            OldCustLedgEntry.SetRange(Open, true);
            if GLSetup."Enable Russian Accounting" then
                if (GenJnlLine."Prepayment Status" <> 0) and (GenJnlLine."Unrealized VAT Entry No." <> 0) then begin
                    OldCustLedgEntry.SetRange("Entry No.", GenJnlLine."Unrealized VAT Entry No.");
                    GenJnlLine."Unrealized VAT Entry No." := 0;
                end;
            OnPrepareTempCustLedgEntryOnAfterSetFilters(OldCustLedgEntry, GenJnlLine, NewCVLedgEntryBuf);
            OldCustLedgEntry.FindFirst();
            OnPrepareTempCustLedgEntryOnBeforeTestPositive(GenJnlLine, IsHandled);
            if not IsHandled then
                OldCustLedgEntry.TestField(Positive, not NewCVLedgEntryBuf.Positive);
            if OldCustLedgEntry."Posting Date" > ApplyingDate then
                ApplyingDate := OldCustLedgEntry."Posting Date";
            GenJnlApply.CheckAgainstApplnCurrency(
              NewCVLedgEntryBuf."Currency Code", OldCustLedgEntry."Currency Code", GenJnlLine."Account Type"::Customer, true);
            TempOldCustLedgEntry := OldCustLedgEntry;
            OnPrepareTempCustLedgEntryOnBeforeTempOldCustLedgEntryInsert(TempOldCustLedgEntry, GenJnlLine);
            TempOldCustLedgEntry.Insert();
        end else begin
            // Find the first old entry (Invoice) which the new entry (Payment) should apply to
            OldCustLedgEntry.Reset();
            OldCustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open, Positive, "Due Date");
            TempOldCustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open, Positive, "Due Date");
            OldCustLedgEntry.SetRange("Customer No.", NewCVLedgEntryBuf."CV No.");
            OldCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            OldCustLedgEntry.SetRange(Open, true);
            OldCustLedgEntry.SetFilter("Entry No.", '<>%1', NewCVLedgEntryBuf."Entry No.");
            if not (Cust."Application Method" = Cust."Application Method"::"Apply to Oldest") then
                OldCustLedgEntry.SetFilter("Amount to Apply", '<>%1', 0);
            if Cust."Agreement Posting" = Cust."Agreement Posting"::Mandatory then
                OldCustLedgEntry.SetRange("Agreement No.", GenJnlLine."Agreement No.");

            if Cust."Application Method" = Cust."Application Method"::"Apply to Oldest" then
                OldCustLedgEntry.SetFilter("Posting Date", '..%1', GenJnlLine."Posting Date");

            // Check Cust Ledger Entry and add to Temp.
            SalesSetup.Get();
            if SalesSetup."Appln. between Currencies" = SalesSetup."Appln. between Currencies"::None then
                OldCustLedgEntry.SetRange("Currency Code", NewCVLedgEntryBuf."Currency Code");
            OnPrepareTempCustLedgEntryOnAfterSetFiltersByAppliesToId(OldCustLedgEntry, GenJnlLine, NewCVLedgEntryBuf, Cust);
            if OldCustLedgEntry.FindSet(false, false) then
                repeat
                    if GenJnlApply.CheckAgainstApplnCurrency(
                         NewCVLedgEntryBuf."Currency Code", OldCustLedgEntry."Currency Code", GenJnlLine."Account Type"::Customer, false)
                    then begin
                        if (OldCustLedgEntry."Posting Date" > ApplyingDate) and (OldCustLedgEntry."Applies-to ID" <> '') then
                            ApplyingDate := OldCustLedgEntry."Posting Date";
                        TempOldCustLedgEntry := OldCustLedgEntry;
                        OnPrepareTempCustLedgEntryOnBeforeTempOldCustLedgEntryInsert(TempOldCustLedgEntry, GenJnlLine);
                        TempOldCustLedgEntry.Insert();
                    end;
                until OldCustLedgEntry.Next() = 0;

            if GLSetup."Enable Russian Accounting" and NewCVLedgEntryBuf.Prepayment and GenJnlLine.Correction then
                Error(PrepmtCorrectionErr);

            TempOldCustLedgEntry.SetRange(Positive, NewCVLedgEntryBuf."Remaining Amount" > 0);

            if GLSetup."Enable Russian Accounting" and SalesSetup."Check Application Date" and (TempOldCustLedgEntry.Count > 0) then begin
                TempOldCustLedgEntry.SetRange(Positive, not (NewCVLedgEntryBuf."Remaining Amount" > 0));
                if TempOldCustLedgEntry.Count > 0 then
                    Error(MultipleEntriesApplnErr);
                TempOldCustLedgEntry.SetRange(Positive, NewCVLedgEntryBuf."Remaining Amount" > 0);
            end;

            if TempOldCustLedgEntry.Find('-') then begin
                RemainingAmount := NewCVLedgEntryBuf."Remaining Amount";
                TempOldCustLedgEntry.SetRange(Positive);
                TempOldCustLedgEntry.Find('-');
                repeat
                    TempOldCustLedgEntry.CalcFields("Remaining Amount");
                    TempOldCustLedgEntry.RecalculateAmounts(
                      TempOldCustLedgEntry."Currency Code", NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                    if PaymentToleranceMgt.CheckCalcPmtDiscCVCust(NewCVLedgEntryBuf, TempOldCustLedgEntry, 0, false, false) then
                        TempOldCustLedgEntry."Remaining Amount" -= TempOldCustLedgEntry."Remaining Pmt. Disc. Possible";
                    RemainingAmount += TempOldCustLedgEntry."Remaining Amount";
                until TempOldCustLedgEntry.Next() = 0;
                TempOldCustLedgEntry.SetRange(Positive, RemainingAmount < 0);
            end else
                TempOldCustLedgEntry.SetRange(Positive);

            OnPrepareTempCustLedgEntryOnBeforeExit(GenJnlLine, NewCVLedgEntryBuf, TempOldCustLedgEntry);
            exit(TempOldCustLedgEntry.Find('-'));
        end;
        exit(true);
    end;

    procedure PostDtldCustLedgEntries(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; CustPostingGr: Record "Customer Posting Group"; LedgEntryInserted: Boolean) DtldLedgEntryInserted: Boolean
    var
#if not CLEAN19
        TempInvPostBuffer: Record "Invoice Post. Buffer" temporary;
#endif
        TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CorrDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        AdjAmount: array[4] of Decimal;
        DtldCustLedgEntryNoOffset: Integer;
        SaveEntryNo: Integer;
        IsHandled: Boolean;
    begin
        if GenJnlLine."Account Type" <> GenJnlLine."Account Type"::Customer then
            exit;

        if DtldCustLedgEntry.FindLast then
            DtldCustLedgEntryNoOffset := DtldCustLedgEntry."Entry No."
        else
            DtldCustLedgEntryNoOffset := 0;

        if GLSetup."Enable Russian Accounting" then begin
            SummarizeGainLoss(DtldCVLedgEntryBuf, CorrDtldCVLedgEntryBuf, false);
            FinVoidedCheck := IsCheckFinVoided(GenJnlLine, DtldCVLedgEntryBuf);
        end;
        DtldCVLedgEntryBuf.Reset();
        OnAfterSetDtldCustLedgEntryNoOffset(DtldCVLedgEntryBuf);
        if DtldCVLedgEntryBuf.FindSet() then begin
            if LedgEntryInserted then begin
                SaveEntryNo := NextEntryNo;
                IncrNextEntryNo();
            end;
            repeat
                InsertDtldCustLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, DtldCustLedgEntry, DtldCustLedgEntryNoOffset);
                if GLSetup."Enable Russian Accounting" then begin
                    GenJnlLine."Posting Date" := DtldCVLedgEntryBuf."Posting Date";
                    GenJnlLine."Document Type" := DtldCVLedgEntryBuf."Document Type";
                    GenJnlLine."Document No." := DtldCVLedgEntryBuf."Document No.";
                end;
                IsHandled := false;
                OnPostDtldCustLedgEntriesOnBeforeUpdateTotalAmounts(GenJnlLine, DtldCustLedgEntry, IsHandled);
                if not IsHandled then
                    UpdateTotalAmounts(TempDimPostingBuffer, GenJnlLine."Dimension Set ID", DtldCVLedgEntryBuf);
                if GLSetup."Enable Russian Accounting" then
                    UpdateGainLoss(DtldCVLedgEntryBuf, CorrDtldCVLedgEntryBuf);
                IsHandled := false;
                OnPostDtldCustLedgEntriesOnBeforePostDtldCustLedgEntry(DtldCVLedgEntryBuf, AddCurrencyCode, GenJnlLine, CustPostingGr, AdjAmount, IsHandled);
                if not IsHandled then
                    if ((DtldCVLedgEntryBuf."Amount (LCY)" <> 0) or
                        (DtldCVLedgEntryBuf."VAT Amount (LCY)" <> 0)) or
                       (GLSetup."Enable Russian Accounting" and
                        (DtldCVLedgEntryBuf."Entry Type" = DtldCVLedgEntryBuf."Entry Type"::"Initial Entry")) or
                       ((AddCurrencyCode <> '') and (DtldCVLedgEntryBuf."Additional-Currency Amount" <> 0))
                then begin
                        if GLSetup."Enable Russian Accounting" then
                            case DtldCVLedgEntryBuf."Entry Type" of
                                DtldCVLedgEntryBuf."Entry Type"::"Initial Entry":
                                    InsertCustGLEntry(GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr);
                                DtldCVLedgEntryBuf."Entry Type"::Application:
                                    PostCustBackPrepayment(GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr);
                            end;
                        PostDtldCustLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr, AdjAmount);
                    end;
            until DtldCVLedgEntryBuf.Next() = 0;
        end;

        if not GLSetup."Enable Russian Accounting" then begin
            IsHandled := false;
#if not CLEAN19
            CopyDimPostBufToInvPostBuf(TempDimPostingBuffer, TempInvPostBuffer);
            OnPostDtldCustLedgEntriesOnBeforeCreateGLEntriesForTotalAmounts(
                CustPostingGr, DtldCVLedgEntryBuf,
                GenJnlLine, TempInvPostBuffer, AdjAmount, SaveEntryNo, GetCustomerReceivablesAccount(GenJnlLine, CustPostingGr), LedgEntryInserted, AddCurrencyCode, IsHandled);
            CopyInvPostBufToDimPostBuf(TempInvPostBuffer, TempDimPostingBuffer);
#endif
            OnPostDtldCustLedgEntriesOnBeforeCreateGLEntriesForTotalAmountsV19(
                CustPostingGr, DtldCVLedgEntryBuf,
                GenJnlLine, TempDimPostingBuffer, AdjAmount, SaveEntryNo, GetCustomerReceivablesAccount(GenJnlLine, CustPostingGr), LedgEntryInserted, AddCurrencyCode, IsHandled);
            if not IsHandled then
                CreateGLEntriesForTotalAmounts(
                    GenJnlLine, TempDimPostingBuffer, AdjAmount, SaveEntryNo, GetCustomerReceivablesAccount(GenJnlLine, CustPostingGr), LedgEntryInserted);

            OnPostDtldCustLedgEntriesOnAfterCreateGLEntriesForTotalAmounts(TempGLEntryBuf, GlobalGLEntry, NextTransactionNo);
        end;

        DtldLedgEntryInserted := not DtldCVLedgEntryBuf.IsEmpty;
        DtldCVLedgEntryBuf.DeleteAll();
    end;

    local procedure PostDtldCustLedgEntry(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; CustPostingGr: Record "Customer Posting Group"; var AdjAmount: array[4] of Decimal)
    var
        AccNo: Code[20];
        BalAccNo: Code[20];
    begin
        AccNo := GetDtldCustLedgEntryAccNo(GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr, 0, false, BalAccNo);
        PostDtldCVLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, AccNo, BalAccNo, AdjAmount, false);
    end;

    local procedure PostDtldCustLedgEntryUnapply(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; CustPostingGr: Record "Customer Posting Group"; OriginalTransactionNo: Integer)
    var
        SavedGenJnlLine: Record "Gen. Journal Line";
        AdjAmount: array[4] of Decimal;
        AccNo: Code[20];
        BalAccNo: Code[20];
    begin
        if (DtldCVLedgEntryBuf."Amount (LCY)" = 0) and
           (DtldCVLedgEntryBuf."VAT Amount (LCY)" = 0) and
           ((AddCurrencyCode = '') or (DtldCVLedgEntryBuf."Additional-Currency Amount" = 0))
        then
            exit;

        if GLSetup."Enable Russian Accounting" then begin
            SavedGenJnlLine := GenJnlLine;
            GenJnlLine."Document Type" := DtldCVLedgEntryBuf."Document Type";
            GenJnlLine."Document No." := DtldCVLedgEntryBuf."Document No.";
        end;
        AccNo := GetDtldCustLedgEntryAccNo(GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr, OriginalTransactionNo, true, BalAccNo);
        DtldCVLedgEntryBuf."Gen. Posting Type" := DtldCVLedgEntryBuf."Gen. Posting Type"::Sale;
        PostDtldCVLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, AccNo, BalAccNo, AdjAmount, true);
        if GLSetup."Enable Russian Accounting" then begin
            if DtldCVLedgEntryBuf."Entry Type" = DtldCVLedgEntryBuf."Entry Type"::Application then
                PostCustBackPrepayment(GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr);
            GenJnlLine := SavedGenJnlLine;
        end;
    end;

    local procedure GetDtldCustLedgEntryAccNo(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; CustPostingGr: Record "Customer Posting Group"; OriginalTransactionNo: Integer; Unapply: Boolean; var BalAccNo: Code[20]) AccountNo: Code[20]
    var
        GenPostingSetup: Record "General Posting Setup";
        Currency: Record Currency;
        AmountCondition: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDtldCustLedgEntryAccNo(GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr, OriginalTransactionNo, Unapply, VATEntry, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        with DtldCVLedgEntryBuf do begin
            AmountCondition := IsDebitAmount(DtldCVLedgEntryBuf, Unapply);
            if GLSetup."Enable Russian Accounting" then
                BalAccNo := CustPostingGr.GetPrepaymentAccount(Prepayment);
            case "Entry Type" of
                "Entry Type"::"Initial Entry":
                    ;
                "Entry Type"::Application:
                    ;
                "Entry Type"::"Unrealized Loss",
                "Entry Type"::"Unrealized Gain":
                    begin
                        GetCurrency(Currency, "Currency Code");
                        CheckNonAddCurrCodeOccurred(Currency.Code);
                        exit(Currency.GetGainLossAccount(DtldCVLedgEntryBuf));
                    end;
                "Entry Type"::"Realized Loss",
                "Entry Type"::"Realized Gain":
                    begin
                        GetCurrency(Currency, "Currency Code");
                        CheckNonAddCurrCodeOccurred(Currency.Code);
                        if "Prepmt. Diff. in TA" then
                            exit(Currency.GetSalesPrepmtDiffAccount(DtldCVLedgEntryBuf));
                        if (not "Prepmt. Diff.") and
                           (not "Prepmt. Diff. in TA")
                        then
                            exit(Currency.GetGainLossAccount(DtldCVLedgEntryBuf));
                    end;
                "Entry Type"::"Payment Discount":
                    exit(CustPostingGr.GetPmtDiscountAccount(AmountCondition));
                "Entry Type"::"Payment Discount (VAT Excl.)":
                    begin
                        TestField("Gen. Prod. Posting Group");
                        GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                        exit(GenPostingSetup.GetSalesPmtDiscountAccount(AmountCondition));
                    end;
                "Entry Type"::"Appln. Rounding":
                    exit(CustPostingGr.GetApplRoundingAccount(AmountCondition));
                "Entry Type"::"Correction of Remaining Amount":
                    exit(CustPostingGr.GetRoundingAccount(AmountCondition));
                "Entry Type"::"Payment Discount Tolerance":
                    case GLSetup."Pmt. Disc. Tolerance Posting" of
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts":
                            exit(CustPostingGr.GetPmtToleranceAccount(AmountCondition));
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts":
                            exit(CustPostingGr.GetPmtDiscountAccount(AmountCondition));
                    end;
                "Entry Type"::"Payment Tolerance":
                    case GLSetup."Payment Tolerance Posting" of
                        GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts":
                            exit(CustPostingGr.GetPmtToleranceAccount(AmountCondition));
                        GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts":
                            exit(CustPostingGr.GetPmtDiscountAccount(AmountCondition));
                    end;
                "Entry Type"::"Payment Tolerance (VAT Excl.)":
                    begin
                        TestField("Gen. Prod. Posting Group");
                        GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                        case GLSetup."Payment Tolerance Posting" of
                            GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts":
                                exit(GenPostingSetup.GetSalesPmtToleranceAccount(AmountCondition));
                            GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts":
                                exit(GenPostingSetup.GetSalesPmtDiscountAccount(AmountCondition));
                        end;
                    end;
                "Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                    begin
                        GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                        case GLSetup."Pmt. Disc. Tolerance Posting" of
                            GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts":
                                exit(GenPostingSetup.GetSalesPmtToleranceAccount(AmountCondition));
                            GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts":
                                exit(GenPostingSetup.GetSalesPmtDiscountAccount(AmountCondition));
                        end;
                    end;
                "Entry Type"::"Payment Discount (VAT Adjustment)",
              "Entry Type"::"Payment Tolerance (VAT Adjustment)",
              "Entry Type"::"Payment Discount Tolerance (VAT Adjustment)":
                    if Unapply then
                        PostDtldCustVATAdjustment(GenJnlLine, DtldCVLedgEntryBuf, OriginalTransactionNo);
                else
                    FieldError("Entry Type");
            end;
        end;
    end;

    local procedure CustUnrealizedVAT(GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry2: Record "Cust. Ledger Entry"; SettledAmount: Decimal; VATEntryNo: Integer; UnrealVATPart: Decimal; VATAllocationLineNo: Integer)
    var
        VATEntry2: Record "VAT Entry";
        TaxJurisdiction: Record "Tax Jurisdiction";
        VATPostingSetup: Record "VAT Posting Setup";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        VATPart: Decimal;
        VATAmount: Decimal;
        VATBase: Decimal;
        VATAmountAddCurr: Decimal;
        VATBaseAddCurr: Decimal;
        PaidAmount: Decimal;
        TotalUnrealVATAmountLast: Decimal;
        TotalUnrealVATAmountFirst: Decimal;
        SalesVATAccount: Code[20];
        SalesVATUnrealAccount: Code[20];
        LastConnectionNo: Integer;
        GLEntryNo: Integer;
        IsHandled: Boolean;
    begin
        if GLSetup."Enable Russian Accounting" and (SettledAmount = 0) then
            exit;

        IsHandled := false;
        OnBeforeCustUnrealizedVAT(GenJnlLine, CustLedgEntry2, SettledAmount, IsHandled);
        if IsHandled then
            exit;

        PaidAmount := CustLedgEntry2."Amount (LCY)" - CustLedgEntry2."Remaining Amt. (LCY)";
        OnCustUnrealizedVATOnAfterCalcPaidAmount(GenJnlLine, CustLedgEntry2, SettledAmount, PaidAmount);
        VATEntry2.Reset();
        VATEntry2.SetCurrentKey("Transaction No.");
        VATEntry2.SetRange("Transaction No.", CustLedgEntry2."Transaction No.");
        if VATEntry2.FindSet() then
            repeat
                VATPostingSetup.Get(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                if VATPostingSetup."Unrealized VAT Type" in
                   [VATPostingSetup."Unrealized VAT Type"::Last, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)"]
                then
                    TotalUnrealVATAmountLast := TotalUnrealVATAmountLast - VATEntry2."Remaining Unrealized Amount";
                if VATPostingSetup."Unrealized VAT Type" in
                   [VATPostingSetup."Unrealized VAT Type"::First, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)"]
                then
                    TotalUnrealVATAmountFirst := TotalUnrealVATAmountFirst - VATEntry2."Remaining Unrealized Amount";
            until VATEntry2.Next() = 0;

        if GLSetup."Enable Russian Accounting" then
            if VATEntryNo <> 0 then begin
                if GenJnlLine."Prepmt. Diff." then
                    VATEntry2.Reset();
                VATEntry2.SetRange("Entry No.", VATEntryNo);
                if VATEntry2.Find('-') then
                    TotalUnrealVATAmountFirst := VATEntry2."Remaining Unrealized Amount"
                else
                    VATEntry2.SetRange("Entry No.");
            end;

        if VATEntry2.FindSet() then begin
            LastConnectionNo := 0;
            repeat
                VATPostingSetup.Get(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                if LastConnectionNo <> VATEntry2."Sales Tax Connection No." then begin
                    InsertSummarizedVAT(GenJnlLine, VATPostingSetup);
                    LastConnectionNo := VATEntry2."Sales Tax Connection No.";
                end;

                if not GLSetup."Enable Russian Accounting" then
                    VATPart :=
                      VATEntry2.GetUnrealizedVATPart(
                        Round(SettledAmount / CustLedgEntry2.GetAdjustedCurrencyFactor),
                        PaidAmount,
                        CustLedgEntry2."Amount (LCY)",
                        TotalUnrealVATAmountFirst,
                        TotalUnrealVATAmountLast)
                else
                    if not (VATSettlementMgt.VATIsPostponed(VATEntry2, GenJnlLine."VAT Settlement Part", GenJnlLine."Posting Date") or
                            VATSettlementMgt.PartiallyRealized(VATEntry2."Entry No.", GenJnlLine."VAT Settlement Part"))
                    then begin
                        if UnrealVATPart <> 0 then
                            VATPart := UnrealVATPart
                        else
                            VATPart :=
                              VATEntry2.GetUnrealizedVATPart(
                                Round(SettledAmount / CustLedgEntry2.GetOriginalCurrencyFactor),
                                PaidAmount,
                                CustLedgEntry2."Original Amt. (LCY)",
                                TotalUnrealVATAmountFirst,
                                TotalUnrealVATAmountLast);
                    end;

                OnCustUnrealizedVATOnAfterVATPartCalculation(
                  GenJnlLine, CustLedgEntry2, PaidAmount, TotalUnrealVATAmountFirst, TotalUnrealVATAmountLast, SettledAmount, VATEntry2);

                if VATPart > 0 then begin
                    case VATEntry2."VAT Calculation Type" of
                        VATEntry2."VAT Calculation Type"::"Normal VAT",
                        VATEntry2."VAT Calculation Type"::"Reverse Charge VAT",
                        VATEntry2."VAT Calculation Type"::"Full VAT":
                            begin
                                SalesVATAccount := VATPostingSetup.GetSalesAccount(false);
                                SalesVATUnrealAccount := VATPostingSetup.GetSalesAccount(true);
                            end;
                        VATEntry2."VAT Calculation Type"::"Sales Tax":
                            begin
                                TaxJurisdiction.Get(VATEntry2."Tax Jurisdiction Code");
                                SalesVATAccount := TaxJurisdiction.GetSalesAccount(false);
                                SalesVATUnrealAccount := TaxJurisdiction.GetSalesAccount(true);
                            end;
                    end;

                    OnCustUnrealizedVATOnAfterSetSalesVATAccounts(VATEntry2, VATPostingSetup, SalesVATAccount, SalesVATUnrealAccount);

                    if VATPart = 1 then begin
                        VATAmount := VATEntry2."Remaining Unrealized Amount";
                        VATBase := VATEntry2."Remaining Unrealized Base";
                        VATAmountAddCurr := VATEntry2."Add.-Curr. Rem. Unreal. Amount";
                        VATBaseAddCurr := VATEntry2."Add.-Curr. Rem. Unreal. Base";
                    end else begin
                        VATAmount := Round(VATEntry2."Remaining Unrealized Amount" * VATPart, GLSetup."Amount Rounding Precision");
                        VATBase := Round(VATEntry2."Remaining Unrealized Base" * VATPart, GLSetup."Amount Rounding Precision");
                        VATAmountAddCurr :=
                          Round(
                            VATEntry2."Add.-Curr. Rem. Unreal. Amount" * VATPart,
                            AddCurrency."Amount Rounding Precision");
                        VATBaseAddCurr :=
                          Round(
                            VATEntry2."Add.-Curr. Rem. Unreal. Base" * VATPart,
                            AddCurrency."Amount Rounding Precision");
                        if GLSetup."Enable Russian Accounting" then begin
                            if VATAllocationLineNo <> 0 then
                                VATBase := Round(VATAmount * GenJnlLine."VAT Base Amount" / GenJnlLine."VAT Amount")
                            else
                                AdjustVATAmount(VATEntry2, VATPart, VATBase, VATAmount, VATBaseAddCurr, VATAmountAddCurr, true);
                        end;
                    end;

                    if GLSetup."Enable Russian Accounting" then begin
                        if VATAllocationLineNo <> 0 then
                            SalesVATAccount := GenJnlLine."Account No.";

                        if VATEntry2.Prepayment then begin
                            GenJnlLine."Document Type" := VATEntry2."Document Type";
                            GenJnlLine."Document No." := VATEntry2."Document No.";
                        end;
                        if VATAllocationLineNo <> 0 then
                            GenJnlLine.Description := CustLedgEntry2.Description;
                    end;

                    IsHandled := false;
                    OnCustUnrealizedVATOnBeforeInitGLEntryVAT(
                      GenJnlLine, VATEntry2, VATAmount, VATBase, VATAmountAddCurr, VATBaseAddCurr, IsHandled, SalesVATUnrealAccount);
                    if not IsHandled then
                        InitGLEntryVAT(
                            GenJnlLine, SalesVATUnrealAccount, SalesVATAccount, -VATAmount, -VATAmountAddCurr, false,
                            VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");

                    GLEntryNo :=
                      InitGLEntryVATCopy(
                        GenJnlLine, SalesVATAccount, SalesVATUnrealAccount, VATAmount, VATAmountAddCurr, VATEntry2,
                        VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");

                    PostUnrealVATEntry(GenJnlLine, VATEntry2, VATAmount, VATBase, VATAmountAddCurr, VATBaseAddCurr, GLEntryNo);
                end;
            until VATEntry2.Next() = 0;

            InsertSummarizedVAT(GenJnlLine, VATPostingSetup);
        end;
    end;

    procedure ApplyVendLedgEntry(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; Vend: Record Vendor)
    var
        OldVendLedgEntry: Record "Vendor Ledger Entry";
        OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        NewVendLedgEntry: Record "Vendor Ledger Entry";
        NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
        TempOldVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        PurchSetup: Record "Purchases & Payables Setup";
        VendPostingGr: Record "Vendor Posting Group";
        Completed: Boolean;
        AppliedAmount: Decimal;
        NewRemainingAmtBeforeAppln: Decimal;
        ApplyingDate: Date;
        PmtTolAmtToBeApplied: Decimal;
        AllApplied: Boolean;
        IsAmountToApplyCheckHandled: Boolean;
        UnrealVATDate: Date;
        SavedPostingDate: Date;
        VendInvPostDate: Date;
        VendInvRcvdDate: Date;
    begin
        OnBeforeApplyVendLedgEntry(NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, Vend, IsAmountToApplyCheckHandled);
        if not IsAmountToApplyCheckHandled then
            if NewCVLedgEntryBuf."Amount to Apply" = 0 then
                exit;

        AllApplied := true;
        if (GenJnlLine."Applies-to Doc. No." = '') and (GenJnlLine."Applies-to ID" = '') and
           not
           ((Vend."Application Method" = Vend."Application Method"::"Apply to Oldest") and
            GenJnlLine."Allow Application")
        then
            exit;

        PurchSetup.Get();
        if (Vend."Application Method" = Vend."Application Method"::"Apply to Oldest") and
           PurchSetup."Check Application Date"
        then
            Error(CheckApplnDateVendErr, Vend."No.");

        PmtTolAmtToBeApplied := 0;
        NewRemainingAmtBeforeAppln := NewCVLedgEntryBuf."Remaining Amount";
        NewCVLedgEntryBuf2 := NewCVLedgEntryBuf;

        ApplyingDate := GenJnlLine."Posting Date";
        if GLSetup."Enable Russian Accounting" then
            SavedPostingDate := GenJnlLine."Posting Date";

        if not PrepareTempVendLedgEntry(GenJnlLine, NewCVLedgEntryBuf, TempOldVendLedgEntry, Vend, ApplyingDate) then
            exit;

        GenJnlLine."Posting Date" := ApplyingDate;
        // Apply the new entry (Payment) to the old entries (Invoices) one at a time
        repeat
            if GLSetup."Enable Russian Accounting" then begin
                CheckVendPrepmtApplPostingDate(GenJnlLine, NewCVLedgEntryBuf, TempOldVendLedgEntry);
                GetVendorPostingGroup(GenJnlLine, VendPostingGr);
                if VendPostingGr."VAT Invoice Mandatory" then
                    if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Invoice then
                        if Vend."Vendor Type" = Vend."Vendor Type"::Vendor then
                            if not NewVendLedgEntry.Get(NewCVLedgEntryBuf."Entry No.") then begin // autoapply
                                GenJnlLine.TestField("Vendor VAT Invoice No.");
                                GenJnlLine.TestField("Vendor VAT Invoice Date");
                                GenJnlLine.TestField("Vendor VAT Invoice Rcvd Date");
                                VendInvPostDate := GenJnlLine."Vendor VAT Invoice Date";
                                VendInvRcvdDate := GenJnlLine."Vendor VAT Invoice Rcvd Date";
                            end else begin
                                NewVendLedgEntry.TestField("Vendor VAT Invoice No.");
                                NewVendLedgEntry.TestField("Vendor VAT Invoice Date");
                                NewVendLedgEntry.TestField("Vendor VAT Invoice Rcvd Date");
                                VendInvPostDate := NewVendLedgEntry."Vendor VAT Invoice Date";
                                VendInvRcvdDate := NewVendLedgEntry."Vendor VAT Invoice Rcvd Date";
                            end
                        else
                            if OldVendLedgEntry."Document Type" = OldVendLedgEntry."Document Type"::Invoice then
                                if Vend."Vendor Type" = Vend."Vendor Type"::Vendor then begin
                                    OldVendLedgEntry.TestField("Vendor VAT Invoice No.");
                                    OldVendLedgEntry.TestField("Vendor VAT Invoice Date");
                                    OldVendLedgEntry.TestField("Vendor VAT Invoice Rcvd Date");
                                    VendInvPostDate := OldVendLedgEntry."Vendor VAT Invoice Date";
                                    VendInvRcvdDate := OldVendLedgEntry."Vendor VAT Invoice Rcvd Date";
                                end;
                UnrealVATDate := GetLastDate(ApplyingDate, VendInvPostDate, VendInvRcvdDate);
            end;

            if Vend."Agreement Posting" = Vend."Agreement Posting"::Mandatory then
                if TempOldVendLedgEntry."Agreement No." <> NewCVLedgEntryBuf."Agreement No." then
                    Error(AgreementMustBeErr, NewCVLedgEntryBuf."Agreement No.", TempOldVendLedgEntry."Document No.");

            TempOldVendLedgEntry.CalcFields(
              Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
              "Original Amount", "Original Amt. (LCY)");
            OldCVLedgEntryBuf.CopyFromVendLedgEntry(TempOldVendLedgEntry);
            TempOldVendLedgEntry.CopyFilter(Positive, OldCVLedgEntryBuf.Positive);

            PostApply(
              GenJnlLine, DtldCVLedgEntryBuf, OldCVLedgEntryBuf, NewCVLedgEntryBuf, NewCVLedgEntryBuf2,
              Vend."Block Payment Tolerance", AllApplied, AppliedAmount, PmtTolAmtToBeApplied);

            // Update the Old Entry
            TempOldVendLedgEntry.CopyFromCVLedgEntryBuffer(OldCVLedgEntryBuf);
            OldVendLedgEntry := TempOldVendLedgEntry;
            OldVendLedgEntry."Amount to Apply" := OldCVLedgEntryBuf."Amount to Apply";
            if OldVendLedgEntry."Amount to Apply" = 0 then
                OldVendLedgEntry."Applies-to ID" := ''
            else begin
                TempVendorLedgerEntry := OldVendLedgEntry;
                if TempVendorLedgerEntry.Insert() then;
            end;
            OnApplyVendLedgEntryOnBeforeOldVendLedgEntryModify(GenJnlLine, OldVendLedgEntry, NewCVLedgEntryBuf);
            OldVendLedgEntry.Modify();

            OnAfterOldVendLedgEntryModify(OldVendLedgEntry, GenJnlLine);

            if not GLSetup."Enable Russian Accounting" and
               (GLSetup."Unrealized VAT" or (GLSetup."Prepayment Unrealized VAT" and TempOldVendLedgEntry.Prepayment))
            then
                if IsNotPayment(TempOldVendLedgEntry."Document Type") then begin
                    TempOldVendLedgEntry.RecalculateAmounts(
                      NewCVLedgEntryBuf."Currency Code", TempOldVendLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date");
                    OnApplyVendLedgEntryOnAfterRecalculateAmounts(TempOldVendLedgEntry, OldVendLedgEntry, NewCVLedgEntryBuf, GenJnlLine);
                    VendUnrealizedVAT(
                      GenJnlLine,
                      TempOldVendLedgEntry,
                      CurrExchRate.ExchangeAmount(
                        AppliedAmount, NewCVLedgEntryBuf."Currency Code",
                        TempOldVendLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date"), 0, 0, 0, 0);
                end;

            if GLSetup."Enable Russian Accounting" and
               (GLSetup."Unrealized VAT" or (GLSetup."Prepayment Unrealized VAT" and TempOldVendLedgEntry.Prepayment))
            then begin
                GenJnlLine."Posting Date" := UnrealVATDate;
                GenJnlCheckLine.CheckDateAllowed(GenJnlLine);
                TempOldVendLedgEntry.CalcFields(Amount, "Credit Amount", "Debit Amount");
                GenJnlLine.Correction :=
                  ((TempOldVendLedgEntry.Amount > 0) and (TempOldVendLedgEntry."Credit Amount" < 0)) or
                  ((TempOldVendLedgEntry.Amount < 0) and (TempOldVendLedgEntry."Debit Amount" < 0));
                if TempOldVendLedgEntry."Currency Code" = '' then
                    VendUnrealizedVAT(GenJnlLine, TempOldVendLedgEntry, AppliedAmount, 0, 0, 0, 0)
                else
                    VendUnrealizedVAT(
                      GenJnlLine,
                      TempOldVendLedgEntry,
                      CurrExchRate.ExchangeAmount(
                        AppliedAmount, NewCVLedgEntryBuf."Currency Code",
                        TempOldVendLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date"), 0, 0, 0, 0);
                GenJnlLine."Posting Date" := ApplyingDate;
            end;

            OnApplyVendLedgEntryOnBeforeTempOldVendLedgEntryDelete(GenJnlLine, TempOldVendLedgEntry, AppliedAmount);
            TempOldVendLedgEntry.Delete();

            Completed := FindNextOldVendLedgEntryToApply(GenJnlLine, TempOldVendLedgEntry, NewCVLedgEntryBuf);
        until Completed;

        DtldCVLedgEntryBuf.SetCurrentKey("CV Ledger Entry No.", "Entry Type");
        DtldCVLedgEntryBuf.SetRange("CV Ledger Entry No.", NewCVLedgEntryBuf."Entry No.");
        DtldCVLedgEntryBuf.SetRange(
          "Entry Type",
          DtldCVLedgEntryBuf."Entry Type"::Application);
        DtldCVLedgEntryBuf.CalcSums("Amount (LCY)", Amount);

        CalcCurrencyUnrealizedGainLoss(
          NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, DtldCVLedgEntryBuf.Amount, NewRemainingAmtBeforeAppln);

        CalcAmtLCYAdjustment(NewCVLedgEntryBuf, OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine);

        NewCVLedgEntryBuf."Applies-to ID" := '';
        NewCVLedgEntryBuf."Amount to Apply" := 0;

        if GLSetup."Unrealized VAT" or
           (GLSetup."Prepayment Unrealized VAT" and NewCVLedgEntryBuf.Prepayment)
        then
            if (IsNotPayment(NewCVLedgEntryBuf."Document Type") or
               IsPrepayment(NewCVLedgEntryBuf."Document Type", NewCVLedgEntryBuf.Prepayment)) and
               (NewRemainingAmtBeforeAppln - NewCVLedgEntryBuf."Remaining Amount" <> 0) or
               (IsVATAgentVATPayment(GenJnlLine))
            then begin
                if GLSetup."Enable Russian Accounting" then begin
                    GenJnlLine."Posting Date" := UnrealVATDate;
                    GenJnlCheckLine.CheckDateAllowed(GenJnlLine);
                end;
                NewVendLedgEntry.CopyFromCVLedgEntryBuffer(NewCVLedgEntryBuf);
                CheckUnrealizedVend := true;
                UnrealizedVendLedgEntry := NewVendLedgEntry;
                UnrealizedVendLedgEntry.CalcFields("Amount (LCY)", "Original Amt. (LCY)");
                UnrealizedRemainingAmountVend := -(NewRemainingAmtBeforeAppln - NewVendLedgEntry."Remaining Amount");
            end;
        if GLSetup."Enable Russian Accounting" then
            GenJnlLine."Posting Date" := SavedPostingDate;

        OnAfterApplyVendLedgEntry(GenJnlLine, NewCVLedgEntryBuf, OldVendLedgEntry);
    end;

    local procedure FindNextOldVendLedgEntryToApply(GenJnlLine: Record "Gen. Journal Line"; var TempOldVendLedgEntry: Record "Vendor Ledger Entry" temporary; NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer") Completed: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeFindNextOldVendLedgEntryToApply(GenJnlLine, TempOldVendLedgEntry, NewCVLedgEntryBuf, Completed, IsHandled);
        if IsHandled then
            exit(Completed);

        if GenJnlLine."Applies-to Doc. No." <> '' then
            Completed := true
        else
            if TempOldVendLedgEntry.GetFilter(Positive) <> '' then
                if TempOldVendLedgEntry.Next = 1 then
                    Completed := false
                else begin
                    TempOldVendLedgEntry.SetRange(Positive);
                    TempOldVendLedgEntry.Find('-');
                    TempOldVendLedgEntry.CalcFields("Remaining Amount");
                    Completed := TempOldVendLedgEntry."Remaining Amount" * NewCVLedgEntryBuf."Remaining Amount" >= 0;
                end
            else
                if NewCVLedgEntryBuf.Open then
                    Completed := TempOldVendLedgEntry.Next() = 0
                else
                    Completed := true;
    end;

    procedure VendPostApplyVendLedgEntry(var GenJnlLinePostApply: Record "Gen. Journal Line"; var VendLedgEntryPostApply: Record "Vendor Ledger Entry")
    var
        Vend: Record Vendor;
        VendPostingGr: Record "Vendor Posting Group";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        GenJnlLine: Record "Gen. Journal Line";
        DtldLedgEntryInserted: Boolean;
    begin
        OnBeforeVendPostApplyVendLedgEntry(GenJnlLinePostApply);

        GenJnlLine := GenJnlLinePostApply;
        VendLedgEntry.TransferFields(VendLedgEntryPostApply);
        with GenJnlLine do begin
            "Source Currency Code" := VendLedgEntryPostApply."Currency Code";
            "Applies-to ID" := VendLedgEntryPostApply."Applies-to ID";

            GenJnlCheckLine.RunCheck(GenJnlLine);

            if NextEntryNo = 0 then
                StartPosting(GenJnlLine)
            else
                ContinuePosting(GenJnlLine);

            Vend.Get(VendLedgEntry."Vendor No.");
            Vend.CheckBlockedVendOnJnls(Vend, "Document Type", true);

            OnVendPostApplyVendLedgEntryOnBeforeCheckPostingGroup(GenJnlLine, Vend);
            if "Posting Group" = '' then begin
                Vend.TestField("Vendor Posting Group");
                "Posting Group" := Vend."Vendor Posting Group";
            end;
            GetVendorPostingGroup(GenJnlLine, VendPostingGr);
            VendPostingGr.GetPayablesAccount();

            DtldVendLedgEntry.LockTable();
            VendLedgEntry.LockTable();

            // Post the application
            VendLedgEntry.CalcFields(
              Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
              "Original Amount", "Original Amt. (LCY)");
            CVLedgEntryBuf.CopyFromVendLedgEntry(VendLedgEntry);
            ApplyVendLedgEntry(CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, Vend);
            OnVendPostApplyVendLedgEntryOnAfterApplyVendLedgEntry(GenJnlLine, TempDtldCVLedgEntryBuf);
            VendLedgEntry.CopyFromCVLedgEntryBuffer(CVLedgEntryBuf);
            VendLedgEntry.Modify(true);

            // Collect VAT Amounts for possible correction
            GetVATAmountsToRealize(TempDtldCVLedgEntryBuf);

            // Post Dtld vendor entry
            OnVendPostApplyVendLedgEntryOnBeforePostDtldVendLedgEntries(VendLedgEntry);
            DtldLedgEntryInserted := PostDtldVendLedgEntries(GenJnlLine, TempDtldCVLedgEntryBuf, VendPostingGr, false);

            CheckPostUnrealizedVAT(GenJnlLine, true);

            if DtldLedgEntryInserted then
                if IsTempGLEntryBufEmpty then
                    DtldVendLedgEntry.SetZeroTransNo(NextTransactionNo);

            OnVendPostApplyVendLedgEntryOnBeforeFinishPosting(GenJnlLine, VendLedgEntry);

            FinishPosting(GenJnlLine);
            OnAfterVendPostApplyVendLedgEntry(GenJnlLine, GLReg);
        end;
    end;

    local procedure PrepareTempVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempOldVendLedgEntry: Record "Vendor Ledger Entry" temporary; Vend: Record Vendor; var ApplyingDate: Date): Boolean
    var
        OldVendLedgEntry: Record "Vendor Ledger Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        RemainingAmount: Decimal;
    begin
        OnBeforePrepareTempVendLedgEntry(GenJnlLine, NewCVLedgEntryBuf);

        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            // Find the entry to be applied to
            OldVendLedgEntry.Reset();
            OldVendLedgEntry.SetCurrentKey("Document No.");
            OldVendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            OldVendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            OldVendLedgEntry.SetRange("Vendor No.", NewCVLedgEntryBuf."CV No.");
            OldVendLedgEntry.SetRange(Open, true);
            OnPrepareTempVendLedgEntryOnAfterSetFilters(OldVendLedgEntry, GenJnlLine, NewCVLedgEntryBuf);
            OldVendLedgEntry.FindFirst;
            OldVendLedgEntry.TestField(Positive, not NewCVLedgEntryBuf.Positive);
            if OldVendLedgEntry."Posting Date" > ApplyingDate then
                ApplyingDate := OldVendLedgEntry."Posting Date";
            GenJnlApply.CheckAgainstApplnCurrency(
              NewCVLedgEntryBuf."Currency Code", OldVendLedgEntry."Currency Code", GenJnlLine."Account Type"::Vendor, true);
            TempOldVendLedgEntry := OldVendLedgEntry;
            OnPrepareTempVendLedgEntryOnBeforeTempOldVendLedgEntryInsert(TempOldVendLedgEntry, GenJnlLine);
            TempOldVendLedgEntry.Insert();
        end else begin
            // Find the first old entry (Invoice) which the new entry (Payment) should apply to
            OldVendLedgEntry.Reset();
            OldVendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
            TempOldVendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
            OldVendLedgEntry.SetRange("Vendor No.", NewCVLedgEntryBuf."CV No.");
            OldVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            OldVendLedgEntry.SetRange(Open, true);
            OldVendLedgEntry.SetFilter("Entry No.", '<>%1', NewCVLedgEntryBuf."Entry No.");
            if not (Vend."Application Method" = Vend."Application Method"::"Apply to Oldest") then
                OldVendLedgEntry.SetFilter("Amount to Apply", '<>%1', 0);
            if Vend."Agreement Posting" = Vend."Agreement Posting"::Mandatory then
                OldVendLedgEntry.SetRange("Agreement No.", GenJnlLine."Agreement No.");

            if Vend."Application Method" = Vend."Application Method"::"Apply to Oldest" then
                OldVendLedgEntry.SetFilter("Posting Date", '..%1', GenJnlLine."Posting Date");

            // Check and Move Ledger Entries to Temp
            PurchSetup.Get();
            if PurchSetup."Appln. between Currencies" = PurchSetup."Appln. between Currencies"::None then
                OldVendLedgEntry.SetRange("Currency Code", NewCVLedgEntryBuf."Currency Code");
            OnPrepareTempVendLedgEntryOnAfterSetFiltersBlankAppliesToDocNo(OldVendLedgEntry, GenJnlLine, NewCVLedgEntryBuf);
            if OldVendLedgEntry.FindSet(false, false) then
                repeat
                    if GenJnlApply.CheckAgainstApplnCurrency(
                         NewCVLedgEntryBuf."Currency Code", OldVendLedgEntry."Currency Code", GenJnlLine."Account Type"::Vendor, false)
                    then begin
                        if (OldVendLedgEntry."Posting Date" > ApplyingDate) and (OldVendLedgEntry."Applies-to ID" <> '') then
                            ApplyingDate := OldVendLedgEntry."Posting Date";
                        TempOldVendLedgEntry := OldVendLedgEntry;
                        OnPrepareTempVendLedgEntryOnBeforeTempOldVendLedgEntryInsert(TempOldVendLedgEntry, GenJnlLine);
                        TempOldVendLedgEntry.Insert();
                    end;
                until OldVendLedgEntry.Next() = 0;

            TempOldVendLedgEntry.SetRange(Positive, NewCVLedgEntryBuf."Remaining Amount" > 0);

            if GLSetup."Enable Russian Accounting" then
                if PurchSetup."Check Application Date" and (TempOldVendLedgEntry.Count > 0) then begin
                    TempOldVendLedgEntry.SetRange(Positive, not (NewCVLedgEntryBuf."Remaining Amount" > 0));
                    if TempOldVendLedgEntry.Count > 0 then
                        Error(MultipleEntriesApplnErr);
                    TempOldVendLedgEntry.SetRange(Positive, NewCVLedgEntryBuf."Remaining Amount" > 0);
                end;

            if TempOldVendLedgEntry.Find('-') then begin
                RemainingAmount := NewCVLedgEntryBuf."Remaining Amount";
                TempOldVendLedgEntry.SetRange(Positive);
                TempOldVendLedgEntry.Find('-');
                repeat
                    TempOldVendLedgEntry.CalcFields("Remaining Amount");
                    TempOldVendLedgEntry.RecalculateAmounts(
                      TempOldVendLedgEntry."Currency Code", NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                    if PaymentToleranceMgt.CheckCalcPmtDiscCVVend(NewCVLedgEntryBuf, TempOldVendLedgEntry, 0, false, false) then
                        TempOldVendLedgEntry."Remaining Amount" -= TempOldVendLedgEntry."Remaining Pmt. Disc. Possible";
                    RemainingAmount += TempOldVendLedgEntry."Remaining Amount";
                until TempOldVendLedgEntry.Next() = 0;
                TempOldVendLedgEntry.SetRange(Positive, RemainingAmount < 0);
            end else
                TempOldVendLedgEntry.SetRange(Positive);

            OnPrepareTempVendLedgEntryOnBeforeExit(GenJnlLine, NewCVLedgEntryBuf, TempOldVendLedgEntry);
            exit(TempOldVendLedgEntry.Find('-'));
        end;
        exit(true);
    end;

    procedure PostDtldVendLedgEntries(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group"; LedgEntryInserted: Boolean) DtldLedgEntryInserted: Boolean
    var
        TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary;
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CorrDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        AdjAmount: array[4] of Decimal;
        DtldVendLedgEntryNoOffset: Integer;
        SaveEntryNo: Integer;
        IsHandled: Boolean;
    begin
        if GenJnlLine."Account Type" <> GenJnlLine."Account Type"::Vendor then
            exit;

        if DtldVendLedgEntry.FindLast then
            DtldVendLedgEntryNoOffset := DtldVendLedgEntry."Entry No."
        else
            DtldVendLedgEntryNoOffset := 0;

        if GLSetup."Enable Russian Accounting" then begin
            SummarizeGainLoss(DtldCVLedgEntryBuf, CorrDtldCVLedgEntryBuf, false);
            FinVoidedCheck := IsCheckFinVoided(GenJnlLine, DtldCVLedgEntryBuf);
        end;

        DtldCVLedgEntryBuf.Reset();
        OnAfterSetDtldVendLedgEntryNoOffset(DtldCVLedgEntryBuf);
        if DtldCVLedgEntryBuf.FindSet() then begin
            if LedgEntryInserted then begin
                SaveEntryNo := NextEntryNo;
                IncrNextEntryNo();
            end;
            repeat
                if not VendPostingGr."Skip Posting" then
                    InsertDtldVendLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, DtldVendLedgEntry, DtldVendLedgEntryNoOffset);
                if GLSetup."Enable Russian Accounting" then begin
                    GenJnlLine."Document Type" := DtldCVLedgEntryBuf."Document Type";
                    GenJnlLine."Document No." := DtldCVLedgEntryBuf."Document No.";
                    GenJnlLine."Posting Date" := DtldCVLedgEntryBuf."Posting Date";
                end;
                IsHandled := false;
                OnPostDtldVendLedgEntriesOnBeforeUpdateTotalAmounts(GenJnlLine, DtldVendLedgEntry, IsHandled);
                if not IsHandled then
                    UpdateTotalAmounts(TempDimPostingBuffer, GenJnlLine."Dimension Set ID", DtldCVLedgEntryBuf);
                if GLSetup."Enable Russian Accounting" then
                    UpdateGainLoss(DtldCVLedgEntryBuf, CorrDtldCVLedgEntryBuf);
                IsHandled := false;
                OnPostDtldVendLedgEntriesOnBeforePostDtldVendLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, VendPostingGr, AdjAmount, IsHandled);
                if not IsHandled then
                    if ((DtldCVLedgEntryBuf."Amount (LCY)" <> 0) or
                        (DtldCVLedgEntryBuf."VAT Amount (LCY)" <> 0)) or
                        (GLSetup."Enable Russian Accounting" and
                        (DtldCVLedgEntryBuf."Entry Type" = DtldCVLedgEntryBuf."Entry Type"::"Initial Entry")) or
                        ((AddCurrencyCode <> '') and (DtldCVLedgEntryBuf."Additional-Currency Amount" <> 0))
                    then begin
                        if GLSetup."Enable Russian Accounting" then
                            case DtldCVLedgEntryBuf."Entry Type" of
                                DtldCVLedgEntryBuf."Entry Type"::"Initial Entry":
                                    InsertVendGLEntry(GenJnlLine, DtldCVLedgEntryBuf, VendPostingGr);
                                DtldCVLedgEntryBuf."Entry Type"::Application:
                                    PostVendBackPrepayment(GenJnlLine, DtldCVLedgEntryBuf, VendPostingGr, false);
                            end;
                        PostDtldVendLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, VendPostingGr, AdjAmount);
                    end;
            until DtldCVLedgEntryBuf.Next() = 0;
        end;

        if not GLSetup."Enable Russian Accounting" then begin
            OnPostDtldVendLedgEntriesOnBeforeCreateGLEntriesForTotalAmounts(VendPostingGr, DtldCVLedgEntryBuf);
            CreateGLEntriesForTotalAmounts(
              GenJnlLine, TempDimPostingBuffer, AdjAmount, SaveEntryNo, GetVendorPayablesAccount(GenJnlLine, VendPostingGr), LedgEntryInserted);

            OnPostDtldVendLedgEntriesOnAfterCreateGLEntriesForTotalAmounts(TempGLEntryBuf, GlobalGLEntry, NextTransactionNo);
        end;

        DtldLedgEntryInserted := not DtldCVLedgEntryBuf.IsEmpty;
        DtldCVLedgEntryBuf.DeleteAll();
    end;

    local procedure PostDtldVendLedgEntry(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group"; var AdjAmount: array[4] of Decimal)
    var
        AccNo: Code[20];
        BalAccNo: Code[20];
    begin
        AccNo := GetDtldVendLedgEntryAccNo(GenJnlLine, DtldCVLedgEntryBuf, VendPostingGr, 0, false, BalAccNo);
        PostDtldCVLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, AccNo, BalAccNo, AdjAmount, false);
    end;

    local procedure PostDtldVendLedgEntryUnapply(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group"; OriginalTransactionNo: Integer)
    var
        SavedGenJnlLine: Record "Gen. Journal Line";
        AccNo: Code[20];
        AdjAmount: array[4] of Decimal;
        BalAccNo: Code[20];
    begin
        if (DtldCVLedgEntryBuf."Amount (LCY)" = 0) and
           (DtldCVLedgEntryBuf."VAT Amount (LCY)" = 0) and
           ((AddCurrencyCode = '') or (DtldCVLedgEntryBuf."Additional-Currency Amount" = 0))
        then
            exit;

        if GLSetup."Enable Russian Accounting" then begin
            SavedGenJnlLine := GenJnlLine;
            GenJnlLine."Document Type" := DtldCVLedgEntryBuf."Document Type";
            GenJnlLine."Document No." := DtldCVLedgEntryBuf."Document No.";
        end;
        AccNo := GetDtldVendLedgEntryAccNo(GenJnlLine, DtldCVLedgEntryBuf, VendPostingGr, OriginalTransactionNo, true, BalAccNo);
        DtldCVLedgEntryBuf."Gen. Posting Type" := DtldCVLedgEntryBuf."Gen. Posting Type"::Purchase;
        PostDtldCVLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, AccNo, BalAccNo, AdjAmount, true);
        if GLSetup."Enable Russian Accounting" then begin
            if DtldCVLedgEntryBuf."Entry Type" = DtldCVLedgEntryBuf."Entry Type"::Application then
                PostVendBackPrepayment(GenJnlLine, DtldCVLedgEntryBuf, VendPostingGr, true);
            GenJnlLine := SavedGenJnlLine;
        end;
    end;

    local procedure GetDtldVendLedgEntryAccNo(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group"; OriginalTransactionNo: Integer; Unapply: Boolean; var BalAccNo: Code[20]) AccountNo: Code[20]
    var
        Currency: Record Currency;
        GenPostingSetup: Record "General Posting Setup";
        AmountCondition: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDtldVendLedgEntryAccNo(GenJnlLine, DtldCVLedgEntryBuf, VendPostingGr, OriginalTransactionNo, Unapply, VATEntry, AccountNo, IsHandled);
        if IsHandled then
            exit;

        with DtldCVLedgEntryBuf do begin
            AmountCondition := IsDebitAmount(DtldCVLedgEntryBuf, Unapply);
            if GLSetup."Enable Russian Accounting" then
                BalAccNo := VendPostingGr.GetPrepaymentAccount(Prepayment);
            case "Entry Type" of
                "Entry Type"::"Initial Entry":
                    ;
                "Entry Type"::Application:
                    ;
                "Entry Type"::"Unrealized Loss",
                "Entry Type"::"Unrealized Gain":
                    begin
                        GetCurrency(Currency, "Currency Code");
                        CheckNonAddCurrCodeOccurred(Currency.Code);
                        exit(Currency.GetGainLossAccount(DtldCVLedgEntryBuf));
                    end;
                "Entry Type"::"Realized Loss",
                "Entry Type"::"Realized Gain":
                    begin
                        GetCurrency(Currency, "Currency Code");
                        CheckNonAddCurrCodeOccurred(Currency.Code);
                        if "Prepmt. Diff. in TA" then
                            exit(Currency.GetPurchPrepmtDiffAccount(DtldCVLedgEntryBuf));
                        if (not "Prepmt. Diff.") and
                           (not "Prepmt. Diff. in TA")
                        then
                            exit(Currency.GetGainLossAccount(DtldCVLedgEntryBuf));
                    end;
                "Entry Type"::"Payment Discount":
                    exit(VendPostingGr.GetPmtDiscountAccount(AmountCondition));
                "Entry Type"::"Payment Discount (VAT Excl.)":
                    begin
                        GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                        exit(GenPostingSetup.GetPurchPmtDiscountAccount(AmountCondition));
                    end;
                "Entry Type"::"Appln. Rounding":
                    exit(VendPostingGr.GetApplRoundingAccount(AmountCondition));
                "Entry Type"::"Correction of Remaining Amount":
                    exit(VendPostingGr.GetRoundingAccount(AmountCondition));
                "Entry Type"::"Payment Discount Tolerance":
                    case GLSetup."Pmt. Disc. Tolerance Posting" of
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts":
                            exit(VendPostingGr.GetPmtToleranceAccount(AmountCondition));
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts":
                            exit(VendPostingGr.GetPmtDiscountAccount(AmountCondition));
                    end;
                "Entry Type"::"Payment Tolerance":
                    case GLSetup."Payment Tolerance Posting" of
                        GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts":
                            exit(VendPostingGr.GetPmtToleranceAccount(AmountCondition));
                        GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts":
                            exit(VendPostingGr.GetPmtDiscountAccount(AmountCondition));
                    end;
                "Entry Type"::"Payment Tolerance (VAT Excl.)":
                    begin
                        GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                        case GLSetup."Payment Tolerance Posting" of
                            GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts":
                                exit(GenPostingSetup.GetPurchPmtToleranceAccount(AmountCondition));
                            GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts":
                                exit(GenPostingSetup.GetPurchPmtDiscountAccount(AmountCondition));
                        end;
                    end;
                "Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                    begin
                        GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                        case GLSetup."Pmt. Disc. Tolerance Posting" of
                            GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts":
                                exit(GenPostingSetup.GetPurchPmtToleranceAccount(AmountCondition));
                            GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts":
                                exit(GenPostingSetup.GetPurchPmtDiscountAccount(AmountCondition));
                        end;
                    end;
                "Entry Type"::"Payment Discount (VAT Adjustment)",
              "Entry Type"::"Payment Tolerance (VAT Adjustment)",
              "Entry Type"::"Payment Discount Tolerance (VAT Adjustment)":
                    if Unapply then
                        PostDtldVendVATAdjustment(GenJnlLine, DtldCVLedgEntryBuf, OriginalTransactionNo);
                else
                    FieldError("Entry Type");
            end;
        end;
    end;

    local procedure PostDtldCVLedgEntry(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; AccNo: Code[20]; BalAccNo: Code[20]; var AdjAmount: array[4] of Decimal; Unapply: Boolean)
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDtldCVLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, AccNo, Unapply, AdjAmount, IsHandled);
        if IsHandled then
            exit;

        with DtldCVLedgEntryBuf do
            case "Entry Type" of
                "Entry Type"::"Initial Entry":
                    ;
                "Entry Type"::Application:
                    ;
                "Entry Type"::"Unrealized Loss",
                "Entry Type"::"Unrealized Gain":
                    begin
                        if GLSetup."Currency Adjmt with Correction" then
                            GenJnlLine.Correction := "Amount (LCY)" < 0;
                        if GLSetup."Enable Russian Accounting" then
                            CreateGLEntryRU(GenJnlLine, AccNo, -"Amount (LCY)", 0, "Currency Code" = AddCurrencyCode, BalAccNo, false, true, false)
                        else
                            CreateGLEntry(GenJnlLine, AccNo, -"Amount (LCY)", 0, "Currency Code" = AddCurrencyCode);
                        if not Unapply then
                            CollectAdjustment(AdjAmount, -"Amount (LCY)", 0);
                    end;
                "Entry Type"::"Realized Loss",
                "Entry Type"::"Realized Gain":
                    if not GLSetup."Enable Russian Accounting" then begin
                        IsHandled := false;
                        OnPostDtldCVLedgEntryOnBeforeCreateGLEntryGainLoss(GenJnlLine, DtldCVLedgEntryBuf, Unapply, AccNo, IsHandled);
                        if not IsHandled then
                            CreateGLEntryGainLoss(GenJnlLine, AccNo, -"Amount (LCY)", "Currency Code" = AddCurrencyCode);
                        if not Unapply then
                            CollectAdjustment(AdjAmount, -"Amount (LCY)", 0);
                    end else begin
                        if GLSetup."Enable Russian Accounting" and not "Prepmt. Diff. in TA" then
                            case GenJnlLine."Account Type" of
                                GenJnlLine."Account Type"::Customer:
                                    GenJnlLine.Correction :=
                                      "Initial Entry Positive" xor
                                      ("Document Type" in ["Document Type"::Payment,
                                                           "Document Type"::"Credit Memo"]);
                                GenJnlLine."Account Type"::Vendor:
                                    GenJnlLine.Correction :=
                                      not "Initial Entry Positive" xor
                                      ("Document Type" in ["Document Type"::Payment,
                                                           "Document Type"::"Credit Memo"]);
                            end;
                        if "Prepmt. Diff." then
                            PrepmtDiffMgt.InsertPrepmtDiffBufEntry(
                              DtldCVLedgEntryBuf, GetGenPostingTypeFromAccType(GenJnlLine."Account Type").AsInteger(), "Transaction No.");
                        if "Prepmt. Diff. in TA" then begin
                            GetCurrency(Currency, "Currency Code");
                            Currency.TestField("PD Bal. Gain/Loss Acc. (TA)");
                            InitGLEntry(GenJnlLine, GLEntry, AccNo, -"Amount (LCY)",
                              0, "Currency Code" = GLSetup."Additional Reporting Currency", true);
                            CollectAdjustment(AdjAmount, GLEntry.Amount, GLEntry."Additional-Currency Amount");
                            InsertRUGLEntry(GenJnlLine, GLEntry, Currency."PD Bal. Gain/Loss Acc. (TA)", false, true, false);
                        end;
                        if (not "Prepmt. Diff.") and (not "Prepmt. Diff. in TA") then begin
                            if not GLSetup."Currency Adjmt with Correction" then
                                GenJnlLine.Correction := false;
                            InitGLEntry(GenJnlLine, GLEntry, AccNo, -"Amount (LCY)",
                              0, "Currency Code" = GLSetup."Additional Reporting Currency", true);
                            CollectAdjustment(AdjAmount, GLEntry.Amount, GLEntry."Additional-Currency Amount");
                            InsertRUGLEntry(GenJnlLine, GLEntry, BalAccNo, false, true, false);
                        end;
                    end;
                "Entry Type"::"Payment Discount",
                "Entry Type"::"Payment Tolerance",
                "Entry Type"::"Payment Discount Tolerance":
                    begin
                        PostDtldCVLedgEntryCreateGLEntryPmtDiscTol(GenJnlLine, DtldCVLedgEntryBuf, AccNo, BalAccNo, Unapply);
                        if not Unapply then
                            CollectAdjustment(AdjAmount, -"Amount (LCY)", -"Additional-Currency Amount");
                    end;
                "Entry Type"::"Payment Discount (VAT Excl.)",
                "Entry Type"::"Payment Tolerance (VAT Excl.)",
                "Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                    if not GLSetup."Enable Russian Accounting" then begin
                        if not Unapply then
                            CreateGLEntryVATCollectAdj(
                              GenJnlLine, AccNo, -"Amount (LCY)", -"Additional-Currency Amount", -"VAT Amount (LCY)", DtldCVLedgEntryBuf,
                              AdjAmount)
                        else
                            CreateGLEntryVAT(
                              GenJnlLine, AccNo, -"Amount (LCY)", -"Additional-Currency Amount", -"VAT Amount (LCY)", DtldCVLedgEntryBuf);
                    end else begin
                        if not Unapply then
                            CreateGLEntryVATCollectAdjRU(
                              GenJnlLine, AccNo, -"Amount (LCY)", -"Additional-Currency Amount", -"VAT Amount (LCY)", DtldCVLedgEntryBuf,
                              AdjAmount, '', false, true, false)
                        else
                            CreateGLEntryVATRU(
                              GenJnlLine, AccNo, -"Amount (LCY)", -"Additional-Currency Amount", -"VAT Amount (LCY)", DtldCVLedgEntryBuf,
                              '', false, true, false);
                        OnPostDtldCVLedgEntryOnAfterCreateGLEntryPmtDiscTolVATExcl(DtldCVLedgEntryBuf, TempGLEntryBuf);
                    end;
                "Entry Type"::"Appln. Rounding":
                    if "Amount (LCY)" <> 0 then begin
                        if GLSetup."Enable Russian Accounting" then
                            CreateGLEntryRU(GenJnlLine, AccNo, -"Amount (LCY)", -"Additional-Currency Amount", true, BalAccNo, false, true, false)
                        else
                            CreateGLEntry(GenJnlLine, AccNo, -"Amount (LCY)", -"Additional-Currency Amount", true);
                        if not Unapply then
                            CollectAdjustment(AdjAmount, -"Amount (LCY)", -"Additional-Currency Amount");
                    end;
                "Entry Type"::"Correction of Remaining Amount":
                    if "Amount (LCY)" <> 0 then
                        if GLSetup."Enable Russian Accounting" then begin
                            InitGLEntry(GenJnlLine, GLEntry, AccNo, -"Amount (LCY)", 0,
                              "Currency Code" = GLSetup."Additional Reporting Currency", true);
                            if not Unapply then
                                CollectAdjustment(AdjAmount, -"Amount (LCY)", 0);
                            InsertRUGLEntry(GenJnlLine, GLEntry, BalAccNo, false, true, false);
                        end else
                            if "Amount (LCY)" <> 0 then begin
                                CreateGLEntry(GenJnlLine, AccNo, -"Amount (LCY)", 0, false);
                                if not Unapply then
                                    CollectAdjustment(AdjAmount, -"Amount (LCY)", 0);
                            end;
                "Entry Type"::"Payment Discount (VAT Adjustment)",
                "Entry Type"::"Payment Tolerance (VAT Adjustment)",
                "Entry Type"::"Payment Discount Tolerance (VAT Adjustment)":
                    ;
                else
                    FieldError("Entry Type");
            end;

        OnAfterPostDtldCVLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, Unapply, AccNo, AdjAmount, NextEntryNo);
    end;

    local procedure PostDtldCVLedgEntryCreateGLEntryPmtDiscTol(var GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var AccNo: Code[20]; BalAccNo: Code[20]; var Unapply: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDtldCVLedgEntryCreateGLEntryPmtDiscTol(GenJnlLine, DtldCVLedgEntryBuf, Unapply, AccNo, IsHandled);
        if IsHandled then
            exit;

        if GLSetup."Enable Russian Accounting" then
            CreateGLEntryRU(GenJnlLine, AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount", false, BalAccNo, false, true, false)
        else
            CreateGLEntry(GenJnlLine, AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount", false);
        OnPostDtldCVLedgEntryOnAfterCreateGLEntryPmtDiscTol(DtldCVLedgEntryBuf, TempGLEntryBuf);
    end;

    local procedure PostDtldCustVATAdjustment(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; OriginalTransactionNo: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        with DtldCVLedgEntryBuf do begin
            FindVATEntry(VATEntry, OriginalTransactionNo);

            case VATPostingSetup."VAT Calculation Type" of
                VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                VATPostingSetup."VAT Calculation Type"::"Full VAT":
                    begin
                        VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                        VATPostingSetup.TestField("VAT Calculation Type", VATEntry."VAT Calculation Type");
                        CreateGLEntry(
                          GenJnlLine, VATPostingSetup.GetSalesAccount(false), -"Amount (LCY)", -"Additional-Currency Amount", false);
                    end;
                VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                    ;
                VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                    begin
                        TestField("Tax Jurisdiction Code");
                        TaxJurisdiction.Get("Tax Jurisdiction Code");
                        CreateGLEntry(
                          GenJnlLine, TaxJurisdiction.GetPurchAccount(false), -"Amount (LCY)", -"Additional-Currency Amount", false);
                    end;
            end;
        end;
    end;

    local procedure PostDtldVendVATAdjustment(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; OriginalTransactionNo: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        with DtldCVLedgEntryBuf do begin
            FindVATEntry(VATEntry, OriginalTransactionNo);
            OnPostDtldVendVATAdjustmentOnAfterFindVATEntry(DtldCVLedgEntryBuf, VATEntry);

            case VATPostingSetup."VAT Calculation Type" of
                VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                VATPostingSetup."VAT Calculation Type"::"Full VAT":
                    begin
                        VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                        VATPostingSetup.TestField("VAT Calculation Type", VATEntry."VAT Calculation Type");
                        CreateGLEntry(
                          GenJnlLine, VATPostingSetup.GetPurchAccount(false), -"Amount (LCY)", -"Additional-Currency Amount", false);
                    end;
                VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                    begin
                        VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                        VATPostingSetup.TestField("VAT Calculation Type", VATEntry."VAT Calculation Type");
                        CreateGLEntry(
                          GenJnlLine, VATPostingSetup.GetPurchAccount(false), -"Amount (LCY)", -"Additional-Currency Amount", false);
                        CreateGLEntry(
                          GenJnlLine, VATPostingSetup.GetRevChargeAccount(false), "Amount (LCY)", "Additional-Currency Amount", false);
                    end;
                VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                    begin
                        TaxJurisdiction.Get("Tax Jurisdiction Code");
                        if "Use Tax" then begin
                            CreateGLEntry(
                              GenJnlLine, TaxJurisdiction.GetPurchAccount(false), -"Amount (LCY)", -"Additional-Currency Amount", false);
                            CreateGLEntry(
                              GenJnlLine, TaxJurisdiction.GetRevChargeAccount(false), "Amount (LCY)", "Additional-Currency Amount", false);
                        end else
                            CreateGLEntry(
                              GenJnlLine, TaxJurisdiction.GetPurchAccount(false), -"Amount (LCY)", -"Additional-Currency Amount", false);
                    end;
            end;
        end;
        OnAfterPostDtldVendVATAdjustment(GenJnlLine, VATPostingSetup, DtldCVLedgEntryBuf, VATEntry);
    end;

    local procedure VendUnrealizedVAT(GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry2: Record "Vendor Ledger Entry"; SettledAmount: Decimal; VATEntryNo: Integer; UnrealVATPart: Decimal; NewTransactionNo: Integer; VATAllocationLineNo: Integer)
    var
        VATEntry2: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        VATPart: Decimal;
        VATAmount: Decimal;
        VATBase: Decimal;
        VATAmountAddCurr: Decimal;
        VATBaseAddCurr: Decimal;
        PaidAmount: Decimal;
        TotalUnrealVATAmountFirst: Decimal;
        TotalUnrealVATAmountLast: Decimal;
        PurchVATAccount: Code[20];
        PurchVATUnrealAccount: Code[20];
        PurchReverseAccount: Code[20];
        PurchReverseUnrealAccount: Code[20];
        LastConnectionNo: Integer;
        InitialVATFactor: Decimal;
        GLEntryNo: Integer;
        IsHandled: Boolean;
    begin
        if GLSetup."Enable Russian Accounting" and (SettledAmount = 0) then
            exit;

        IsHandled := false;
        OnBeforeVendUnrealizedVAT(GenJnlLine, VendLedgEntry2, SettledAmount, IsHandled);
        if IsHandled then
            exit;

        VATEntry2.Reset();
        VATEntry2.SetCurrentKey("Transaction No.");
        VATEntry2.SetRange("Transaction No.", VendLedgEntry2."Transaction No.");
        PaidAmount := -VendLedgEntry2."Amount (LCY)" + VendLedgEntry2."Remaining Amt. (LCY)";
        if VATEntry2.FindSet() then
            repeat
                VATPostingSetup.Get(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                if VATPostingSetup."Unrealized VAT Type" in
                   [VATPostingSetup."Unrealized VAT Type"::Last, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)"]
                then
                    TotalUnrealVATAmountLast := TotalUnrealVATAmountLast - VATEntry2."Remaining Unrealized Amount";
                if VATPostingSetup."Unrealized VAT Type" in
                   [VATPostingSetup."Unrealized VAT Type"::First, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)"]
                then
                    TotalUnrealVATAmountFirst := TotalUnrealVATAmountFirst - VATEntry2."Remaining Unrealized Amount";
            until VATEntry2.Next() = 0;

        OnVendUnrealizedVATOnAfterCalcTotalUnrealVATAmount(VATEntry2, TotalUnrealVATAmountFirst, TotalUnrealVATAmountLast);

        if GLSetup."Enable Russian Accounting" and (VATEntryNo <> 0) then begin
            if GenJnlLine."Prepmt. Diff." then
                VATEntry2.Reset();
            VATEntry2.SetRange("Entry No.", VATEntryNo);
            if VATEntry2.Find('-') then
                TotalUnrealVATAmountFirst := VATEntry2."Unrealized Amount"
            else
                VATEntry2.SetRange("Entry No.");
        end;

        if VATEntry2.FindSet() then begin
            LastConnectionNo := 0;
            repeat
                VATPostingSetup.Get(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                if LastConnectionNo <> VATEntry2."Sales Tax Connection No." then begin
                    InsertSummarizedVAT(GenJnlLine, VATPostingSetup);
                    LastConnectionNo := VATEntry2."Sales Tax Connection No.";
                end;

                if not GLSetup."Enable Russian Accounting" then
                    VATPart :=
                      VATEntry2.GetUnrealizedVATPart(
                        Round(SettledAmount / VendLedgEntry2.GetAdjustedCurrencyFactor),
                        PaidAmount,
                        VendLedgEntry2."Amount (LCY)",
                        TotalUnrealVATAmountFirst,
                        TotalUnrealVATAmountLast)
                else begin
                    if not (VATSettlementMgt.VATIsPostponed(VATEntry2, GenJnlLine."VAT Settlement Part", GenJnlLine."Posting Date") or
                            VATSettlementMgt.PartiallyRealized(VATEntry2."Entry No.", GenJnlLine."VAT Settlement Part"))
                    then begin
                        if UnrealVATPart <> 0 then
                            VATPart := UnrealVATPart
                        else
                            if VendLedgEntry2."Currency Code" = '' then
                                VATPart :=
                                  VATEntry2.GetUnrealizedVATPart(
                                    SettledAmount,
                                    PaidAmount,
                                    VendLedgEntry2."Original Amt. (LCY)",
                                    TotalUnrealVATAmountFirst,
                                    TotalUnrealVATAmountLast)
                            else
                                VATPart :=
                                  VATEntry2.GetUnrealizedVATPart(
                                    Round(SettledAmount / VendLedgEntry2.GetOriginalCurrencyFactor),
                                    PaidAmount,
                                    VendLedgEntry2."Original Amt. (LCY)",
                                    TotalUnrealVATAmountFirst,
                                    TotalUnrealVATAmountLast);
                    end;
                end;

                OnVendUnrealizedVATOnAfterVATPartCalculation(
                  GenJnlLine, VendLedgEntry2, PaidAmount, TotalUnrealVATAmountFirst, TotalUnrealVATAmountLast, SettledAmount, VATEntry2);

                if VATPart > 0 then begin
                    GetVendUnrealizedVATAccounts(VATEntry2, VATPostingSetup, PurchVATAccount, PurchVATUnrealAccount, PurchReverseAccount, PurchReverseUnrealAccount);

                    if VATPart = 1 then begin
                        VATAmount := VATEntry2."Remaining Unrealized Amount";
                        VATBase := VATEntry2."Remaining Unrealized Base";
                        VATAmountAddCurr := VATEntry2."Add.-Curr. Rem. Unreal. Amount";
                        VATBaseAddCurr := VATEntry2."Add.-Curr. Rem. Unreal. Base";
                        if GLSetup."Enable Russian Accounting" and (UnrealVATPart <> 0) and (UnrealVATPart <> 1) then begin
                            InitialVATFactor :=
                              VATEntry2."Unrealized Amount" / (VATEntry2."Unrealized Amount" + VATEntry2."Unrealized Base");
                            VATAmount := Round((VATAmount + VATBase) * UnrealVATPart * InitialVATFactor);
                            VATBase := Round(VATBase * UnrealVATPart);
                            VATAmountAddCurr := Round(VATAmountAddCurr * UnrealVATPart, AddCurrency."Amount Rounding Precision");
                            VATBaseAddCurr := Round(VATBaseAddCurr * UnrealVATPart, AddCurrency."Amount Rounding Precision");
                            AdjustVATAmount(VATEntry2, UnrealVATPart, VATBase, VATAmount, VATBaseAddCurr, VATAmountAddCurr, true);
                        end;
                    end else begin
                        VATAmount := Round(VATEntry2."Remaining Unrealized Amount" * VATPart, GLSetup."Amount Rounding Precision");
                        VATBase := Round(VATEntry2."Remaining Unrealized Base" * VATPart, GLSetup."Amount Rounding Precision");
                        VATAmountAddCurr :=
                          Round(
                            VATEntry2."Add.-Curr. Rem. Unreal. Amount" * VATPart,
                            AddCurrency."Amount Rounding Precision");
                        VATBaseAddCurr :=
                          Round(
                            VATEntry2."Add.-Curr. Rem. Unreal. Base" * VATPart,
                            AddCurrency."Amount Rounding Precision");
                        if GLSetup."Enable Russian Accounting" then begin
                            if IsVendBackPrepmt then
                                if (Abs(VATAmount - VATEntryToRealize.Amount) <> 0) and
                                   (Abs(VATAmount - VATEntryToRealize.Amount) <= GLSetup."Amount Rounding Precision")
                                then begin
                                    VATAmount := VATEntryToRealize.Amount;
                                    VATBase := VATEntryToRealize.Base;
                                    VATAmountAddCurr := VATEntryToRealize."Additional-Currency Amount";
                                    VATBaseAddCurr := VATEntryToRealize."Additional-Currency Base";
                                end;

                            if VATAllocationLineNo <> 0 then
                                VATBase := Round(VATAmount * GenJnlLine."VAT Base Amount" / GenJnlLine."VAT Amount")
                            else
                                AdjustVATAmount(VATEntry2, VATPart, VATBase, VATAmount, VATBaseAddCurr, VATAmountAddCurr, true);
                        end;
                    end;

                    if GLSetup."Enable Russian Accounting" then begin
                        if IsVendBackPrepmt then
                            with VATEntryToRealize do begin
                                Amount -= VATAmount;
                                Base -= VATBase;
                                "Additional-Currency Amount" -= VATAmountAddCurr;
                                "Additional-Currency Base" -= VATBaseAddCurr;
                            end;

                        if VATAllocationLineNo <> 0 then
                            PurchVATAccount := GenJnlLine."Account No.";

                        if NewTransactionNo <> 0 then begin
                            VendLedgEntry2."Transaction No." := NextTransactionNo;
                            NextTransactionNo := NewTransactionNo;
                        end;

                        if VATEntry2.Prepayment then begin
                            GenJnlLine."Document Type" := VATEntry2."Document Type";
                            GenJnlLine."Document No." := VATEntry2."Document No.";
                        end;
                        if VATAllocationLineNo <> 0 then
                            GenJnlLine.Description := VendLedgEntry2.Description;
                    end;

                    OnVendUnrealizedVATOnBeforeInitGLEntryVAT(GenJnlLine, VATEntry2, VATAmount, VATBase, VATAmountAddCurr, VATBaseAddCurr);

                    if (VATEntry2."VAT Calculation Type" = VATEntry2."VAT Calculation Type"::"Sales Tax") and
                       (VATEntry2.Type = VATEntry2.Type::Purchase) and VATEntry2."Use Tax"
                    then begin
                        InitGLEntryVAT(
                          GenJnlLine, PurchReverseUnrealAccount, PurchReverseAccount, -VATAmount, -VATAmountAddCurr, false,
                          VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                        GLEntryNo :=
                          InitGLEntryVATCopy(
                            GenJnlLine, PurchReverseAccount, PurchReverseUnrealAccount, VATAmount, VATAmountAddCurr, VATEntry2,
                            VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                    end else begin
                        InitGLEntryVAT(
                          GenJnlLine, PurchVATUnrealAccount, PurchVATAccount, -VATAmount, -VATAmountAddCurr, false,
                          VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                        GLEntryNo :=
                          InitGLEntryVATCopy(
                            GenJnlLine, PurchVATAccount, PurchVATUnrealAccount, VATAmount, VATAmountAddCurr, VATEntry2,
                            VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                    end;

                    if VATEntry2."VAT Calculation Type" = VATEntry2."VAT Calculation Type"::"Reverse Charge VAT" then begin
                        InitGLEntryVAT(
                          GenJnlLine, PurchReverseUnrealAccount, PurchReverseAccount, VATAmount, VATAmountAddCurr, false,
                          VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                        GLEntryNo :=
                          InitGLEntryVATCopy(
                            GenJnlLine, PurchReverseAccount, PurchReverseUnrealAccount, -VATAmount, -VATAmountAddCurr, VATEntry2,
                            VATPostingSetup."Trans. VAT Type" = VATPostingSetup."Trans. VAT Type"::"Amount + Tax");
                    end;

                    OnVendUnrealizedVATOnBeforePostUnrealVATEntry(GenJnlLine, VATEntry2, VATAmount, VATBase, VATAmountAddCurr, VATBaseAddCurr, GLEntryNo, VATPart);
                    PostUnrealVATEntry(GenJnlLine, VATEntry2, VATAmount, VATBase, VATAmountAddCurr, VATBaseAddCurr, GLEntryNo);
                end;
            until VATEntry2.Next() = 0;

            InsertSummarizedVAT(GenJnlLine, VATPostingSetup);
        end;
    end;

    local procedure GetVendUnrealizedVATAccounts(var VATEntry2: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; var PurchVATAccount: Code[20]; var PurchVATUnrealAccount: Code[20]; var PurchReverseAccount: Code[20]; var PurchReverseUnrealAccount: Code[20])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        case VATEntry2."VAT Calculation Type" of
            VATEntry2."VAT Calculation Type"::"Normal VAT",
            VATEntry2."VAT Calculation Type"::"Full VAT":
                begin
                    PurchVATAccount := VATPostingSetup.GetPurchAccount(false);
                    PurchVATUnrealAccount := VATPostingSetup.GetPurchAccount(true);
                end;
            VATEntry2."VAT Calculation Type"::"Reverse Charge VAT":
                begin
                    PurchVATAccount := VATPostingSetup.GetPurchAccount(false);
                    PurchVATUnrealAccount := VATPostingSetup.GetPurchAccount(true);
                    PurchReverseAccount := VATPostingSetup.GetRevChargeAccount(false);
                    PurchReverseUnrealAccount := VATPostingSetup.GetRevChargeAccount(true);
                end;
            VATEntry2."VAT Calculation Type"::"Sales Tax":
                if (VATEntry2.Type = VATEntry2.Type::Purchase) and VATEntry2."Use Tax" then begin
                    TaxJurisdiction.Get(VATEntry2."Tax Jurisdiction Code");
                    PurchVATAccount := TaxJurisdiction.GetPurchAccount(false);
                    PurchVATUnrealAccount := TaxJurisdiction.GetPurchAccount(true);
                    PurchReverseAccount := TaxJurisdiction.GetRevChargeAccount(false);
                    PurchReverseUnrealAccount := TaxJurisdiction.GetRevChargeAccount(true);
                end else begin
                    TaxJurisdiction.Get(VATEntry2."Tax Jurisdiction Code");
                    PurchVATAccount := TaxJurisdiction.GetPurchAccount(false);
                    PurchVATUnrealAccount := TaxJurisdiction.GetPurchAccount(true);
                end;
        end;

        OnAfterGetVendUnrealizedVATAccounts(VATEntry2, VATPostingSetup, PurchVATAccount, PurchVATUnrealAccount, PurchReverseAccount, PurchReverseUnrealAccount);
    end;

    local procedure PostUnrealVATEntry(GenJnlLine: Record "Gen. Journal Line"; var VATEntry2: Record "VAT Entry"; VATAmount: Decimal; VATBase: Decimal; VATAmountAddCurr: Decimal; VATBaseAddCurr: Decimal; GLEntryNo: Integer)
    var
        InitialVATEntry: Record "VAT Entry";
    begin
        OnBeforePostUnrealVATEntry(GenJnlLine, VATEntry);
        VATEntry.LockTable();
        VATEntry := VATEntry2;
        VATEntry."Entry No." := NextVATEntryNo;
        VATEntry."Posting Date" := GenJnlLine."Posting Date";
        VATEntry."Document No." := GenJnlLine."Document No.";
        VATEntry."External Document No." := GenJnlLine."External Document No.";
        VATEntry."Document Type" := GenJnlLine."Document Type";
        VATEntry.Amount := VATAmount;
        VATEntry.Base := VATBase;
        VATEntry."Additional-Currency Amount" := VATAmountAddCurr;
        VATEntry."Additional-Currency Base" := VATBaseAddCurr;
        VATEntry.SetUnrealAmountsToZero;
        VATEntry."User ID" := UserId;
        VATEntry."Source Code" := GenJnlLine."Source Code";
        VATEntry."Reason Code" := GenJnlLine."Reason Code";
        VATEntry."Closed by Entry No." := 0;
        VATEntry.Closed := false;
        VATEntry."Transaction No." := NextTransactionNo;
        VATEntry."Sales Tax Connection No." := NextConnectionNo;
        VATEntry."Unrealized VAT Entry No." := VATEntry2."Entry No.";
        VATEntry."Base Before Pmt. Disc." := VATEntry.Base;
        VATEntry."G/L Acc. No." := '';
        if GLSetup."Enable Russian Accounting" then begin
            VATEntry."Document Date" := GenJnlLine."Document Date";
            VATEntry.Positive := VATEntry.Amount > 0;
            VATEntry."VAT Settlement Part" := GenJnlLine."VAT Settlement Part";
            VATEntry.Correction := GenJnlLine.Correction;
            VATEntry."Additional VAT Ledger Sheet" := GenJnlLine."Additional VAT Ledger Sheet";
            VATEntry."Corrected Document Date" := GenJnlLine."Corrected Document Date";
            if GenJnlLine."Additional VAT Ledger Sheet" then
                FindAdjustingVATEntry(VATEntry, GenJnlLine."Corrected Document Date");
            if (GenJnlLine."Prepayment Status" = GenJnlLine."Prepayment Status"::Reset) and
               VATEntry."Additional VAT Ledger Sheet"
            then begin
                VATEntry.Reversed := true;
                VATEntry."Reversed Entry No." := VATEntry."Unrealized VAT Entry No.";
            end;
            VATEntry."Manual VAT Settlement" := VATEntry."VAT Settlement Part" <> 0;
            VATEntry."FA Ledger Entry No." := GenJnlLine."FA Error Entry No.";
            VATEntry."VAT Allocation Type" := GenJnlLine."VAT Allocation Type";
            if GenJnlLine."Initial VAT Entry No." <> 0 then begin
                InitialVATEntry.Get(GenJnlLine."Initial VAT Entry No.");
                VATEntry."Initial VAT Transaction No." := InitialVATEntry."Transaction No.";
                VATEntry."Document Line No." := InitialVATEntry."Document Line No.";
            end;
        end;
        if VATEntry."Prepmt. Diff." and VATEntry."Additional VAT Ledger Sheet" then begin
            InitialVATEntry.Reset();
            InitialVATEntry.SetCurrentKey("Transaction No.");
            InitialVATEntry.SetRange("Transaction No.", VATEntry."Initial VAT Transaction No.");
            if InitialVATEntry.FindSet() then
                repeat
                    if InitialVATEntry."Unrealized VAT Entry No." <> 0 then
                        if not PrepmtDiffMgt.IsDifferentTaxPeriod(InitialVATEntry."Posting Date", VATEntry."Posting Date") then begin
                            InitialVATEntry."Additional VAT Ledger Sheet" := VATEntry."Additional VAT Ledger Sheet";
                            InitialVATEntry."Corrected Document Date" := VATEntry."Corrected Document Date";
                            InitialVATEntry.Modify();
                        end;
                until InitialVATEntry.Next() = 0;
        end;
        OnBeforeInsertPostUnrealVATEntry(VATEntry, GenJnlLine, VATEntry2);
        VATEntry.Insert(true);
        TempGLEntryVATEntryLink.InsertLinkSelf(GLEntryNo + 1, NextVATEntryNo);
        NextVATEntryNo := NextVATEntryNo + 1;

        VATEntry2."Remaining Unrealized Amount" :=
          VATEntry2."Remaining Unrealized Amount" - VATEntry.Amount;
        VATEntry2."Remaining Unrealized Base" :=
          VATEntry2."Remaining Unrealized Base" - VATEntry.Base;
        VATEntry2."Add.-Curr. Rem. Unreal. Amount" :=
          VATEntry2."Add.-Curr. Rem. Unreal. Amount" - VATEntry."Additional-Currency Amount";
        VATEntry2."Add.-Curr. Rem. Unreal. Base" :=
          VATEntry2."Add.-Curr. Rem. Unreal. Base" - VATEntry."Additional-Currency Base";
        VATEntry2."VAT Settlement Part" := GenJnlLine."VAT Settlement Part";
        VATEntry2.Modify();
        OnAfterPostUnrealVATEntry(GenJnlLine, VATEntry2, VATAmount, VATBase);
    end;

    local procedure PostApply(var GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; BlockPaymentTolerance: Boolean; AllApplied: Boolean; var AppliedAmount: Decimal; var PmtTolAmtToBeApplied: Decimal)
    var
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf3: Record "CV Ledger Entry Buffer";
        OldRemainingAmtBeforeAppln: Decimal;
        ApplnRoundingPrecision: Decimal;
        AppliedAmountLCY: Decimal;
        OldAppliedAmount: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforePostApply(GenJnlLine, DtldCVLedgEntryBuf, OldCVLedgEntryBuf, NewCVLedgEntryBuf, NewCVLedgEntryBuf2);

        OldRemainingAmtBeforeAppln := OldCVLedgEntryBuf."Remaining Amount";
        OldCVLedgEntryBuf3 := OldCVLedgEntryBuf;

        // Management of posting in multiple currencies
        OldCVLedgEntryBuf2 := OldCVLedgEntryBuf;
        OldCVLedgEntryBuf.CopyFilter(Positive, OldCVLedgEntryBuf2.Positive);
        ApplnRoundingPrecision := GetApplnRoundPrecision(NewCVLedgEntryBuf, OldCVLedgEntryBuf);

        OldCVLedgEntryBuf2.RecalculateAmounts(
          OldCVLedgEntryBuf2."Currency Code", NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");

        OnPostApplyOnAfterRecalculateAmounts(OldCVLedgEntryBuf2, OldCVLedgEntryBuf, NewCVLedgEntryBuf, GenJnlLine);

        if not BlockPaymentTolerance then
            CalcPmtTolerance(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
              PmtTolAmtToBeApplied, NextTransactionNo, FirstNewVATEntryNo);

        CalcPmtDisc(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
          PmtTolAmtToBeApplied, ApplnRoundingPrecision, NextTransactionNo, FirstNewVATEntryNo);

        if not BlockPaymentTolerance then
            CalcPmtDiscTolerance(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
              NextTransactionNo, FirstNewVATEntryNo);

        IsHandled := false;
        OnBeforeCalcCurrencyApplnRounding(
          GenJnlLine, DtldCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, OldCVLedgEntryBuf3,
          NewCVLedgEntryBuf, NewCVLedgEntryBuf2, IsHandled);
        if not IsHandled then
            CalcCurrencyApplnRounding(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, ApplnRoundingPrecision);

        FindAmtForAppln(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2,
          AppliedAmount, AppliedAmountLCY, OldAppliedAmount, ApplnRoundingPrecision);

        if GLSetup."Enable Russian Accounting" then
            RUFindAmtForAppln(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf,
              AppliedAmount, AppliedAmountLCY, OldAppliedAmount, ApplnRoundingPrecision);

        CalcCurrencyUnrealizedGainLoss(
          OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, -OldAppliedAmount, OldRemainingAmtBeforeAppln);

        CalcCurrencyRealizedGainLoss(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, AppliedAmount, AppliedAmountLCY);

        CalcCurrencyRealizedGainLoss(
          OldCVLedgEntryBuf, NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, -OldAppliedAmount, -AppliedAmountLCY);

        CalcApplication(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, DtldCVLedgEntryBuf,
          GenJnlLine, AppliedAmount, AppliedAmountLCY, OldAppliedAmount,
          NewCVLedgEntryBuf2, OldCVLedgEntryBuf3, AllApplied);

        PaymentToleranceMgt.CalcRemainingPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, GLSetup);

        CalcAmtLCYAdjustment(OldCVLedgEntryBuf, NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine);

        OnAfterPostApply(GenJnlLine, DtldCVLedgEntryBuf, OldCVLedgEntryBuf, NewCVLedgEntryBuf, NewCVLedgEntryBuf2);
    end;

    procedure UnapplyCustLedgEntry(GenJnlLine2: Record "Gen. Journal Line"; DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        Cust: Record Customer;
        CustPostingGr: Record "Customer Posting Group";
        GenJnlLine: Record "Gen. Journal Line";
        SavedGenJnlLine: Record "Gen. Journal Line";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
        VATEntry: Record "VAT Entry";
        TempVATEntry2: Record "VAT Entry" temporary;
        CurrencyLCY: Record Currency;
        TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary;
#if not CLEAN19
        TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary;
#endif
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        CorrDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        AdjAmount: array[4] of Decimal;
        NextDtldLedgEntryNo: Integer;
        UnapplyVATEntries: Boolean;
        PmtDiscTolExists: Boolean;
        IsHandled: Boolean;
    begin
        GenJnlLine.TransferFields(GenJnlLine2);
        if GLSetup."Enable Russian Accounting" then
            GenJnlLine."Source Currency Code" := DtldCustLedgEntry."Currency Code";
        if GenJnlLine."Document Date" = 0D then
            GenJnlLine."Document Date" := GenJnlLine."Posting Date";

        if NextEntryNo = 0 then
            StartPosting(GenJnlLine)
        else
            ContinuePosting(GenJnlLine);

        ReadGLSetup(GLSetup);

        Cust.Get(DtldCustLedgEntry."Customer No.");
        Cust.CheckBlockedCustOnJnls(Cust, GenJnlLine2."Document Type"::Payment, true);

        OnUnapplyCustLedgEntryOnBeforeCheckPostingGroup(GenJnlLine, Cust);
        CustPostingGr.Get(GenJnlLine."Posting Group");
        CustPostingGr.GetReceivablesAccount();

        VATEntry.LockTable();
        DtldCustLedgEntry.LockTable();
        CustLedgEntry.LockTable();

        DtldCustLedgEntry.TestField("Entry Type", DtldCustLedgEntry."Entry Type"::Application);

        DtldCustLedgEntry2.Reset();
        DtldCustLedgEntry2.FindLast;
        NextDtldLedgEntryNo := DtldCustLedgEntry2."Entry No." + 1;
        if DtldCustLedgEntry."Transaction No." = 0 then begin
            DtldCustLedgEntry2.SetCurrentKey("Application No.", "Customer No.", "Entry Type");
            DtldCustLedgEntry2.SetRange("Application No.", DtldCustLedgEntry."Application No.");
        end else begin
            DtldCustLedgEntry2.SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");
            DtldCustLedgEntry2.SetRange("Transaction No.", DtldCustLedgEntry."Transaction No.");
        end;
        DtldCustLedgEntry2.SetRange("Customer No.", DtldCustLedgEntry."Customer No.");
        DtldCustLedgEntry2.SetFilter("Entry Type", '>%1', DtldCustLedgEntry."Entry Type"::"Initial Entry");
        OnUnapplyCustLedgEntryOnAfterDtldCustLedgEntrySetFilters(DtldCustLedgEntry2, DtldCustLedgEntry);
        if DtldCustLedgEntry."Transaction No." <> 0 then begin
            UnapplyVATEntries := false;
            if GLSetup."Enable Russian Accounting" then begin
                CreateCustUnapplyBuffer(DtldCustLedgEntry2, TempDtldCVLedgEntryBuf, NextDtldLedgEntryNo);
                SummarizeGainLoss(TempDtldCVLedgEntryBuf, CorrDtldCVLedgEntryBuf, true);
                FinVoidedCheck := IsCheckFinVoided(GenJnlLine2, TempDtldCVLedgEntryBuf);
            end;
            DtldCustLedgEntry2.FindSet();
            repeat
                DtldCustLedgEntry2.TestField(Unapplied, false);
                if GLSetup."Enable Russian Accounting" then begin
                    VATSettlementMgt.CheckForUnapplyByEntryNo(DtldCustLedgEntry2."Cust. Ledger Entry No.", 0);
                    if DtldCustLedgEntry2."Tax Diff. Transaction No." <> 0 then
                        Error(PostedTaxDiffReverseErr, DtldCustLedgEntry2."Tax Diff. Transaction No.");
                    if DtldCustLedgEntry2."Prepmt. Diff." then
                        VATSettlementMgt.CheckForPDUnapply(DtldCustLedgEntry2."Cust. Ledger Entry No.");
                end;
                if IsVATAdjustment(DtldCustLedgEntry2."Entry Type") then
                    UnapplyVATEntries := true;
                if not GLSetup."Pmt. Disc. Excl. VAT" and GLSetup."Adjust for Payment Disc." then
                    if IsVATExcluded(DtldCustLedgEntry2."Entry Type") then
                        UnapplyVATEntries := true;
                if DtldCustLedgEntry2."Entry Type" = DtldCustLedgEntry2."Entry Type"::"Payment Discount Tolerance (VAT Excl.)" then
                    PmtDiscTolExists := true;
            until DtldCustLedgEntry2.Next() = 0;

            OnUnapplyCustLedgEntryOnBeforePostUnapply(DtldCustLedgEntry, DtldCustLedgEntry2);

            PostUnapply(
              GenJnlLine, VATEntry, VATEntry.Type::Sale,
              DtldCustLedgEntry."Customer No.", DtldCustLedgEntry."Transaction No.", UnapplyVATEntries, TempVATEntry);

            if PmtDiscTolExists then
                ProcessTempVATEntryCust(DtldCustLedgEntry2, TempVATEntry)
            else begin
                DtldCustLedgEntry2.SetRange("Entry Type", DtldCustLedgEntry2."Entry Type"::"Payment Tolerance (VAT Excl.)");
                ProcessTempVATEntryCust(DtldCustLedgEntry2, TempVATEntry);
                DtldCustLedgEntry2.SetRange("Entry Type", DtldCustLedgEntry2."Entry Type"::"Payment Discount (VAT Excl.)");
                ProcessTempVATEntryCust(DtldCustLedgEntry2, TempVATEntry);
                DtldCustLedgEntry2.SetFilter("Entry Type", '>%1', DtldCustLedgEntry."Entry Type"::"Initial Entry");
            end;
        end;

        // Look one more time
        OnOnUnapplyCustLedgEntryOnBeforeSecondLook(DtldCustLedgEntry2, NextDtldLedgEntryNo);
        DtldCustLedgEntry2.FindSet();
        TempDimPostingBuffer.DeleteAll();
        repeat
            DtldCustLedgEntry2.TestField(Unapplied, false);
            InsertDtldCustLedgEntryUnapply(GenJnlLine, SavedGenJnlLine, NewDtldCustLedgEntry, DtldCustLedgEntry2, NextDtldLedgEntryNo, CustPostingGr);

            DtldCVLedgEntryBuf.Init();
            DtldCVLedgEntryBuf.TransferFields(NewDtldCustLedgEntry);
            OnUnapplyCustLedgEntryOnAfterFillDtldCVLedgEntryBuf(GenJnlLine, DtldCVLedgEntryBuf);
            if GLSetup."Enable Russian Accounting" then
                DtldCVLedgEntryBuf."Posting Date" := DtldCustLedgEntry2."Posting Date";
            if not (DtldCVLedgEntryBuf."Prepmt. Diff." or DtldCVLedgEntryBuf."Prepmt. Diff. in TA") then
                SetAddCurrForUnapplication(DtldCVLedgEntryBuf)
            else
                DtldCVLedgEntryBuf."Additional-Currency Amount" := 0;
            CurrencyLCY.InitRoundingPrecision();

            if (DtldCustLedgEntry2."Transaction No." <> 0) and IsVATExcluded(DtldCustLedgEntry2."Entry Type") then begin
                UnapplyExcludedVAT(
                  TempVATEntry2, DtldCustLedgEntry2."Transaction No.", DtldCustLedgEntry2."VAT Bus. Posting Group",
                  DtldCustLedgEntry2."VAT Prod. Posting Group", DtldCustLedgEntry2."Gen. Prod. Posting Group");
                DtldCVLedgEntryBuf."VAT Amount (LCY)" :=
                  CalcVATAmountFromVATEntry(DtldCVLedgEntryBuf."Amount (LCY)", TempVATEntry2, CurrencyLCY);
            end;
            IsHandled := false;
            OnOnUnapplyCustLedgEntryOnBeforeUpdateTotalAmounts(IsHandled);
            if not IsHandled then begin
                UpdateTotalAmounts(TempDimPostingBuffer, GenJnlLine."Dimension Set ID", DtldCVLedgEntryBuf);

                if not (DtldCVLedgEntryBuf."Entry Type" in [
                                                            DtldCVLedgEntryBuf."Entry Type"::"Initial Entry",
                                                            DtldCVLedgEntryBuf."Entry Type"::Application])
                then
                    CollectAdjustment(AdjAmount,
                      -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount");
            end;

            if GLSetup."Enable Russian Accounting" then begin
                DtldCVLedgEntryBuf."Posting Date" := GenJnlLine."Posting Date";
                DtldCVLedgEntryBuf."Initial Transaction No." := DtldCustLedgEntry."Transaction No.";
                UpdateGainLoss(DtldCVLedgEntryBuf, CorrDtldCVLedgEntryBuf);
            end;

            PostDtldCustLedgEntryUnapply(
              GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr, DtldCustLedgEntry2."Transaction No.");

            if GLSetup."Enable Russian Accounting" then
                GenJnlLine := SavedGenJnlLine;

            DtldCustLedgEntry2.Unapplied := true;
            DtldCustLedgEntry2."Unapplied by Entry No." := NewDtldCustLedgEntry."Entry No.";
            DtldCustLedgEntry2.Modify();

            OnUnapplyCustLedgEntryOnBeforeUpdateCustLedgEntry(DtldCustLedgEntry2, DtldCVLedgEntryBuf);
            UpdateCustLedgEntry(DtldCustLedgEntry2);
        until DtldCustLedgEntry2.Next() = 0;

        if not GLSetup."Enable Russian Accounting" then begin
	    IsHandled := false;
#if not CLEAN19
            CopyDimPostBufToInvPostBuf(TempDimPostingBuffer, TempInvoicePostBuffer);
            OnBeforeCreateGLEntriesForTotalAmountsUnapply(DtldCustLedgEntry, CustPostingGr, GenJnlLine, TempInvoicePostBuffer, IsHandled);
            CopyInvPostBufToDimPostBuf(TempInvoicePostBuffer, TempDimPostingBuffer);
#endif
            OnBeforeCreateGLEntriesForTotalAmountsUnapplyV19(DtldCustLedgEntry, CustPostingGr, GenJnlLine, TempDimPostingBuffer, IsHandled);
            if not IsHandled then
                CreateGLEntriesForTotalAmountsUnapply(GenJnlLine, TempDimPostingBuffer, GetCustomerReceivablesAccount(GenJnlLine, CustPostingGr));
        end;

        OnUnapplyCustLedgEntryOnAfterCreateGLEntriesForTotalAmounts(GenJnlLine2, DtldCustLedgEntry, GLReg);

        if IsTempGLEntryBufEmpty then
            DtldCustLedgEntry.SetZeroTransNo(NextTransactionNo);
        CheckPostUnrealizedVAT(GenJnlLine, true);

        FinishPosting(GenJnlLine);
    end;

    procedure UnapplyVendLedgEntry(GenJnlLine2: Record "Gen. Journal Line"; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        Vend: Record Vendor;
        VendPostingGr: Record "Vendor Posting Group";
        GenJnlLine: Record "Gen. Journal Line";
        SavedGenJnlLine: Record "Gen. Journal Line";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
        VATEntry: Record "VAT Entry";
        TempVATEntry2: Record "VAT Entry" temporary;
        CurrencyLCY: Record Currency;
        TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary;
#if not CLEAN19
        TempInvPostBuffer: Record "Invoice Post. Buffer" temporary;
#endif
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        CorrDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        AdjAmount: array[4] of Decimal;
        NextDtldLedgEntryNo: Integer;
        UnapplyVATEntries: Boolean;
        PmtDiscTolExists: Boolean;
        IsHandled: Boolean;
    begin
        GenJnlLine.TransferFields(GenJnlLine2);
        if GLSetup."Enable Russian Accounting" then
            GenJnlLine."Source Currency Code" := DtldVendLedgEntry."Currency Code";
        if GenJnlLine."Document Date" = 0D then
            GenJnlLine."Document Date" := GenJnlLine."Posting Date";

        if NextEntryNo = 0 then
            StartPosting(GenJnlLine)
        else
            ContinuePosting(GenJnlLine);

        ReadGLSetup(GLSetup);

        Vend.Get(DtldVendLedgEntry."Vendor No.");
        Vend.CheckBlockedVendOnJnls(Vend, GenJnlLine2."Document Type"::Payment, true);

        OnUnapplyVendLedgEntryOnBeforeCheckPostingGroup(GenJnlLine, Vend);
        GetVendorPostingGroup(GenJnlLine, VendPostingGr);
        VendPostingGr.GetPayablesAccount();

        VATEntry.LockTable();
        DtldVendLedgEntry.LockTable();
        VendLedgEntry.LockTable();

        DtldVendLedgEntry.TestField("Entry Type", DtldVendLedgEntry."Entry Type"::Application);

        if GLSetup."Enable Russian Accounting" then
            VATSettlementMgt.CheckForUnapplyByTransNo(DtldVendLedgEntry."Transaction No.");

        DtldVendLedgEntry2.Reset();
        DtldVendLedgEntry2.FindLast;
        NextDtldLedgEntryNo := DtldVendLedgEntry2."Entry No." + 1;
        if DtldVendLedgEntry."Transaction No." = 0 then begin
            DtldVendLedgEntry2.SetCurrentKey("Application No.", "Vendor No.", "Entry Type");
            DtldVendLedgEntry2.SetRange("Application No.", DtldVendLedgEntry."Application No.");
        end else begin
            DtldVendLedgEntry2.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
            DtldVendLedgEntry2.SetRange("Transaction No.", DtldVendLedgEntry."Transaction No.");
        end;
        DtldVendLedgEntry2.SetRange("Vendor No.", DtldVendLedgEntry."Vendor No.");
        DtldVendLedgEntry2.SetFilter("Entry Type", '>%1', DtldVendLedgEntry."Entry Type"::"Initial Entry");
        OnUnapplyVendLedgEntryOnAfterFilterSourceEntries(DtldVendLedgEntry, DtldVendLedgEntry2);
        if DtldVendLedgEntry."Transaction No." <> 0 then begin
            if GLSetup."Enable Russian Accounting" then begin
                CreateVendUnapplyBuffer(DtldVendLedgEntry2, TempDtldCVLedgEntryBuf, NextDtldLedgEntryNo);
                SummarizeGainLoss(TempDtldCVLedgEntryBuf, CorrDtldCVLedgEntryBuf, true);
                FinVoidedCheck := IsCheckFinVoided(GenJnlLine2, TempDtldCVLedgEntryBuf);
            end;
            UnapplyVATEntries := false;
            DtldVendLedgEntry2.FindSet();
            repeat
                DtldVendLedgEntry2.TestField(Unapplied, false);
                if IsVATAdjustment(DtldVendLedgEntry2."Entry Type") then
                    UnapplyVATEntries := true;
                if not GLSetup."Pmt. Disc. Excl. VAT" and GLSetup."Adjust for Payment Disc." then
                    if IsVATExcluded(DtldVendLedgEntry2."Entry Type") then
                        UnapplyVATEntries := true;
                if DtldVendLedgEntry2."Entry Type" = DtldVendLedgEntry2."Entry Type"::"Payment Discount Tolerance (VAT Excl.)" then
                    PmtDiscTolExists := true;
            until DtldVendLedgEntry2.Next() = 0;

            OnUnapplyVendLedgEntryOnBeforePostUnapply(DtldVendLedgEntry, DtldVendLedgEntry2);

            PostUnapply(
              GenJnlLine, VATEntry, VATEntry.Type::Purchase,
              DtldVendLedgEntry."Vendor No.", DtldVendLedgEntry."Transaction No.", UnapplyVATEntries, TempVATEntry);

            if PmtDiscTolExists then
                ProcessTempVATEntryVend(DtldVendLedgEntry2, TempVATEntry)
            else begin
                DtldVendLedgEntry2.SetRange("Entry Type", DtldVendLedgEntry2."Entry Type"::"Payment Tolerance (VAT Excl.)");
                ProcessTempVATEntryVend(DtldVendLedgEntry2, TempVATEntry);
                DtldVendLedgEntry2.SetRange("Entry Type", DtldVendLedgEntry2."Entry Type"::"Payment Discount (VAT Excl.)");
                ProcessTempVATEntryVend(DtldVendLedgEntry2, TempVATEntry);
                DtldVendLedgEntry2.SetFilter("Entry Type", '>%1', DtldVendLedgEntry2."Entry Type"::"Initial Entry");
            end;
        end;

        // Look one more time
        OnUnapplyVendLedgEntryOnBeforeSecondLook(DtldVendLedgEntry2, NextDtldLedgEntryNo);
        DtldVendLedgEntry2.FindSet();
        TempDimPostingBuffer.DeleteAll();
        repeat
            DtldVendLedgEntry2.TestField(Unapplied, false);
            if GLSetup."Enable Russian Accounting" then begin
                VATSettlementMgt.CheckForUnapplyByEntryNo(DtldVendLedgEntry2."Vendor Ledger Entry No.", 1);
                if DtldVendLedgEntry2."Tax Diff. Transaction No." <> 0 then
                    Error(PostedTaxDiffReverseErr, DtldVendLedgEntry2."Tax Diff. Transaction No.");
                if DtldVendLedgEntry2."Prepmt. Diff." then
                    VATSettlementMgt.CheckForPDUnapply(DtldVendLedgEntry2."Vendor Ledger Entry No.");
            end;
            InsertDtldVendLedgEntryUnapply(GenJnlLine, SavedGenJnlLine, NewDtldVendLedgEntry, DtldVendLedgEntry2, NextDtldLedgEntryNo);

            DtldCVLedgEntryBuf.Init();
            DtldCVLedgEntryBuf.TransferFields(NewDtldVendLedgEntry);
            OnUnapplyVendLedgEntryOnAfterFillDtldCVLedgEntryBuf(GenJnlLine, DtldCVLedgEntryBuf);
            if GLSetup."Enable Russian Accounting" then
                DtldCVLedgEntryBuf."Posting Date" := DtldVendLedgEntry2."Posting Date";
            if not (DtldCVLedgEntryBuf."Prepmt. Diff." or DtldCVLedgEntryBuf."Prepmt. Diff. in TA") then
                SetAddCurrForUnapplication(DtldCVLedgEntryBuf)
            else
                DtldCVLedgEntryBuf."Additional-Currency Amount" := 0;
            CurrencyLCY.InitRoundingPrecision();

            if (DtldVendLedgEntry2."Transaction No." <> 0) and IsVATExcluded(DtldVendLedgEntry2."Entry Type") then begin
                UnapplyExcludedVAT(
                  TempVATEntry2, DtldVendLedgEntry2."Transaction No.", DtldVendLedgEntry2."VAT Bus. Posting Group",
                  DtldVendLedgEntry2."VAT Prod. Posting Group", DtldVendLedgEntry2."Gen. Prod. Posting Group");
                DtldCVLedgEntryBuf."VAT Amount (LCY)" :=
                  CalcVATAmountFromVATEntry(DtldCVLedgEntryBuf."Amount (LCY)", TempVATEntry2, CurrencyLCY);
            end;
            IsHandled := false;
            OnUnapplyVendLedgEntryOnBeforeUpdateTotalAmounts(IsHandled);
            if not IsHandled then begin
                UpdateTotalAmounts(TempDimPostingBuffer, GenJnlLine."Dimension Set ID", DtldCVLedgEntryBuf);

                if not (DtldCVLedgEntryBuf."Entry Type" in [
                                                            DtldCVLedgEntryBuf."Entry Type"::"Initial Entry",
                                                            DtldCVLedgEntryBuf."Entry Type"::Application])
                then
                    CollectAdjustment(AdjAmount,
                      -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount");
            end;

            if GLSetup."Enable Russian Accounting" then begin
                DtldCVLedgEntryBuf."Posting Date" := GenJnlLine."Posting Date";
                DtldCVLedgEntryBuf."Initial Transaction No." := DtldVendLedgEntry."Transaction No.";
                UpdateGainLoss(DtldCVLedgEntryBuf, CorrDtldCVLedgEntryBuf);
            end;

            PostDtldVendLedgEntryUnapply(
              GenJnlLine, DtldCVLedgEntryBuf, VendPostingGr, DtldVendLedgEntry2."Transaction No.");

            if GLSetup."Enable Russian Accounting" then
                GenJnlLine := SavedGenJnlLine;

            DtldVendLedgEntry2.Unapplied := true;
            DtldVendLedgEntry2."Unapplied by Entry No." := NewDtldVendLedgEntry."Entry No.";
            DtldVendLedgEntry2.Modify();

            OnUnapplyVendLedgEntryOnBeforeUpdateVendLedgEntry(DtldVendLedgEntry2, DtldCVLedgEntryBuf);
            UpdateVendLedgEntry(DtldVendLedgEntry2);
        until DtldVendLedgEntry2.Next() = 0;

        if not GLSetup."Enable Russian Accounting" then begin
            IsHandled := false;	
#if not CLEAN19
            CopyDimPostBufToInvPostBuf(TempDimPostingBuffer, TempInvPostBuffer);
            OnBeforeCreateGLEntriesForTotalAmountsUnapplyVendor(DtldVendLedgEntry, VendPostingGr, GenJnlLine, TempInvPostBuffer, IsHandled);
            CopyInvPostBufToDimPostBuf(TempInvPostBuffer, TempDimPostingBuffer);
#endif
            OnBeforeCreateGLEntriesForTotalAmountsUnapplyVendorV19(DtldVendLedgEntry, VendPostingGr, GenJnlLine, TempDimPostingBuffer, IsHandled);
            if not IsHandled then
                CreateGLEntriesForTotalAmountsUnapply(GenJnlLine, TempDimPostingBuffer, GetVendorPayablesAccount(GenJnlLine, VendPostingGr));
        end;

        OnUnapplyVendLedgEntryOnAfterCreateGLEntriesForTotalAmounts(GenJnlLine2, DtldVendLedgEntry, GLReg);

        if IsTempGLEntryBufEmpty then
            DtldVendLedgEntry.SetZeroTransNo(NextTransactionNo);
        CheckPostUnrealizedVAT(GenJnlLine, true);

        FinishPosting(GenJnlLine);
    end;

    local procedure UnapplyExcludedVAT(var TempVATEntry: Record "VAT Entry" temporary; TransactionNo: Integer; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
        TempVATEntry.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        TempVATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        TempVATEntry.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        if not TempVATEntry.FindFirst then begin
            TempVATEntry.Reset();
            if TempVATEntry.FindLast then
                TempVATEntry."Entry No." := TempVATEntry."Entry No." + 1
            else
                TempVATEntry."Entry No." := 1;
            TempVATEntry.Init();
            TempVATEntry."VAT Bus. Posting Group" := VATBusPostingGroup;
            TempVATEntry."VAT Prod. Posting Group" := VATProdPostingGroup;
            TempVATEntry."Gen. Prod. Posting Group" := GenProdPostingGroup;
            VATEntry.SetCurrentKey("Transaction No.");
            VATEntry.SetRange("Transaction No.", TransactionNo);
            VATEntry.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
            VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
            VATEntry.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
            if VATEntry.FindSet() then
                repeat
                    if VATEntry."Unrealized VAT Entry No." = 0 then begin
                        TempVATEntry.Base := TempVATEntry.Base + VATEntry.Base;
                        TempVATEntry.Amount := TempVATEntry.Amount + VATEntry.Amount;
                    end;
                until VATEntry.Next() = 0;
            Clear(VATEntry);
            TempVATEntry.Insert();
        end;
    end;

    local procedure PostUnrealVATByUnapply(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; VATEntry: Record "VAT Entry"; NewVATEntry: Record "VAT Entry"): Integer
    var
        VATEntry2: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        AmountAddCurr: Decimal;
        GLEntryNoFromVAT: Integer;
        SavedPostingDate: Date;
    begin
        OnBeforePostUnrealVATByUnapply(GenJnlLine, VATPostingSetup, VATEntry, NewVATEntry);

        if GLSetup."Enable Russian Accounting" then begin
            SavedPostingDate := GenJnlLine."Posting Date";
            if VATEntry."Posting Date" > GenJnlLine."Posting Date" then
                GenJnlLine."Posting Date" := VATEntry."Posting Date";
        end;

        AmountAddCurr := CalcAddCurrForUnapplication(VATEntry."Posting Date", VATEntry.Amount);
        if not GLSetup."Enable Russian Accounting" then begin
            CreateGLEntry(
              GenJnlLine, GetPostingAccountNo(VATPostingSetup, VATEntry, true), VATEntry.Amount, AmountAddCurr, false);
            GLEntryNoFromVAT :=
              CreateGLEntryFromVATEntry(
                GenJnlLine, GetPostingAccountNo(VATPostingSetup, VATEntry, false), -VATEntry.Amount, -AmountAddCurr, VATEntry);
        end else begin
            InitGLEntry(GenJnlLine, GLEntry,
              GetPostingAccountNo(VATPostingSetup, VATEntry, true), VATEntry.Amount, 0, false, true);
            GLEntry."Additional-Currency Amount" :=
              CalcAddCurrForUnapplication(VATEntry."Posting Date", VATEntry.Amount);
            GLEntry.CopyPostingGroupsFromVATEntry(VATEntry);
            InsertRUGLEntry(GenJnlLine, GLEntry, GetPostingAccountNo(VATPostingSetup, VATEntry, false), true, true, false);
            GenJnlLine."Posting Date" := SavedPostingDate;
            GLEntryNoFromVAT := GLEntry."Entry No.";
        end;
        with VATEntry2 do begin
            Get(VATEntry."Unrealized VAT Entry No.");
            "Remaining Unrealized Amount" := "Remaining Unrealized Amount" - NewVATEntry.Amount;
            "Remaining Unrealized Base" := "Remaining Unrealized Base" - NewVATEntry.Base;
            "Add.-Curr. Rem. Unreal. Amount" :=
              "Add.-Curr. Rem. Unreal. Amount" - NewVATEntry."Additional-Currency Amount";
            "Add.-Curr. Rem. Unreal. Base" :=
              "Add.-Curr. Rem. Unreal. Base" - NewVATEntry."Additional-Currency Base";
            OnPostUnrealVATByUnapplyOnBeforeVATEntryModify(GenJnlLine, VATPostingSetup, VATEntry, NewVATEntry, VATEntry2, GLEntryNoFromVAT);
            Modify;
        end;

        OnAfterPostUnrealVATByUnapply(GenJnlLine, VATPostingSetup, VATEntry, NewVATEntry);

        exit(GLEntryNoFromVAT);
    end;

    local procedure PostPmtDiscountVATByUnapply(GenJnlLine: Record "Gen. Journal Line"; ReverseChargeVATAccNo: Code[20]; VATAccNo: Code[20]; VATEntry: Record "VAT Entry")
    var
        AmountAddCurr: Decimal;
    begin
        OnBeforePostPmtDiscountVATByUnapply(GenJnlLine, VATEntry);

        AmountAddCurr := CalcAddCurrForUnapplication(VATEntry."Posting Date", VATEntry.Amount);
        CreateGLEntry(GenJnlLine, ReverseChargeVATAccNo, VATEntry.Amount, AmountAddCurr, false);
        CreateGLEntry(GenJnlLine, VATAccNo, -VATEntry.Amount, -AmountAddCurr, false);

        OnAfterPostPmtDiscountVATByUnapply(GenJnlLine, VATEntry);
    end;

    local procedure PostUnapply(GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; VATEntryType: Enum "General Posting Type"; BilltoPaytoNo: Code[20]; var TransactionNo: Integer; UnapplyVATEntries: Boolean; var TempVATEntry: Record "VAT Entry" temporary)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SavedGenJnlLine: Record "Gen. Journal Line";
        VATEntry2: Record "VAT Entry";
        AccNo: Code[20];
        TempVATEntryNo: Integer;
        GLEntryNoFromVAT: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostUnapply(GenJnlLine, VATEntry, VATEntryType, BilltoPaytoNo, TransactionNo, UnapplyVATEntries, TempVATEntry, IsHandled, NextVATEntryNo);
        if IsHandled then
            exit;

        TempVATEntryNo := 1;
        VATEntry.SetCurrentKey(Type, "Bill-to/Pay-to No.", "Transaction No.");
        VATEntry.SetRange(Type, VATEntryType);
        VATEntry.SetRange("Bill-to/Pay-to No.", BilltoPaytoNo);
        VATEntry.SetRange("Transaction No.", TransactionNo);
        if GLSetup."Enable Russian Accounting" then begin
            VATEntry.SetRange("Unrealized Amount", 0);
            VATEntry.SetRange("Unrealized Base", 0);
        end;
        OnPostUnapplyOnAfterVATEntrySetFilters(VATEntry, GenJnlLine);
        if VATEntry.FindSet() then
            repeat
                VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                OnPostUnapplyOnBeforeUnapplyVATEntry(VATEntry, UnapplyVATEntries);
                if UnapplyVATEntries or (VATEntry."Unrealized VAT Entry No." <> 0) then begin
                    InsertTempVATEntry(GenJnlLine, VATEntry, TempVATEntryNo, TempVATEntry);
                    if VATEntry."Unrealized VAT Entry No." <> 0 then begin
                        if GLSetup."Enable Russian Accounting" then begin
                            SavedGenJnlLine := GenJnlLine;
                            case VATEntryType of
                                VATEntry.Type::Sale:
                                    GenJnlLine.Correction := VATEntry.Amount < 0;
                                VATEntry.Type::Purchase:
                                    GenJnlLine.Correction := VATEntry.Amount > 0;
                            end;
                            if VATEntry.Prepayment then begin
                                GenJnlLine."Document Type" := VATEntry."Document Type";
                                GenJnlLine."Document No." := VATEntry."Document No.";
                            end;
                        end;
                        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                        if VATPostingSetup."VAT Calculation Type" in
                           [VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                            VATPostingSetup."VAT Calculation Type"::"Full VAT"]
                        then
                            GLEntryNoFromVAT := PostUnrealVATByUnapply(GenJnlLine, VATPostingSetup, VATEntry, TempVATEntry)
                        else
                            if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then begin
                                GLEntryNoFromVAT := PostUnrealVATByUnapply(GenJnlLine, VATPostingSetup, VATEntry, TempVATEntry);
                                CreateGLEntry(
                                  GenJnlLine, VATPostingSetup.GetRevChargeAccount(true),
                                  -VATEntry.Amount, CalcAddCurrForUnapplication(VATEntry."Posting Date", -VATEntry.Amount), false);
                                CreateGLEntry(
                                  GenJnlLine, VATPostingSetup.GetRevChargeAccount(false),
                                  VATEntry.Amount, CalcAddCurrForUnapplication(VATEntry."Posting Date", VATEntry.Amount), false);
                            end else
                                GLEntryNoFromVAT := PostUnrealVATByUnapply(GenJnlLine, VATPostingSetup, VATEntry, TempVATEntry);
                        VATEntry2 := TempVATEntry;
                        VATEntry2."Entry No." := NextVATEntryNo;
                        if GLSetup."Enable Russian Accounting" then
                            NextVATEntryNo := NextVATEntryNo + 1;
                        OnPostUnapplyOnBeforeVATEntryInsert(VATEntry2, GenJnlLine, VATEntry);
                        VATEntry2.Insert();
                        OnPostUnapplyOnAfterVATEntryInsert(VATEntry2, GenJnlLine, VATEntry);
                        if GLEntryNoFromVAT <> 0 then
                            TempGLEntryVATEntryLink.InsertLinkSelf(GLEntryNoFromVAT, VATEntry2."Entry No.");
                        GLEntryNoFromVAT := 0;
                        TempVATEntry.Delete();
                        IncrNextVATEntryNo;
                        if GLSetup."Enable Russian Accounting" then
                            GenJnlLine := SavedGenJnlLine;
                    end;

                    if VATPostingSetup."Adjust for Payment Discount" and not IsNotPayment(VATEntry."Document Type") and
                       (VATPostingSetup."VAT Calculation Type" =
                        VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT") and
                       (VATEntry."Unrealized VAT Entry No." = 0) and UnapplyVATEntries and (VATEntry.Amount <> 0)
                    then begin
                        case VATEntryType of
                            VATEntry.Type::Sale:
                                AccNo := VATPostingSetup.GetSalesAccount(false);
                            VATEntry.Type::Purchase:
                                AccNo := VATPostingSetup.GetPurchAccount(false);
                        end;
                        PostPmtDiscountVATByUnapply(GenJnlLine, VATPostingSetup.GetRevChargeAccount(false), AccNo, VATEntry);
                    end;
                end;
            until VATEntry.Next() = 0;
    end;

    local procedure CalcAddCurrForUnapplication(Date: Date; Amt: Decimal): Decimal
    var
        AddCurrency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if AddCurrencyCode = '' then
            exit;

        AddCurrency.Get(AddCurrencyCode);
        AddCurrency.TestField("Amount Rounding Precision");

        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
              Date, AddCurrencyCode, Amt, CurrExchRate.ExchangeRate(Date, AddCurrencyCode)),
            AddCurrency."Amount Rounding Precision"));
    end;

    local procedure CalcVATAmountFromVATEntry(AmountLCY: Decimal; var VATEntry: Record "VAT Entry"; CurrencyLCY: Record Currency) VATAmountLCY: Decimal
    begin
        with VATEntry do
            if (AmountLCY = Base) or (Base = 0) then begin
                VATAmountLCY := Amount;
                Delete;
            end else begin
                VATAmountLCY :=
                  Round(
                    Amount * AmountLCY / Base,
                    CurrencyLCY."Amount Rounding Precision",
                    CurrencyLCY.VATRoundingDirection);
                Base := Base - AmountLCY;
                Amount := Amount - VATAmountLCY;
                Modify;
            end;
    end;

    local procedure InsertDtldCustLedgEntryUnapply(var GenJnlLine: Record "Gen. Journal Line"; var SavedGenJnlLine: Record "Gen. Journal Line"; var NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; OldDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var NextDtldLedgEntryNo: Integer; var CustomerPostingGroup: Record "Customer Posting Group")
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        NewDtldCustLedgEntry := OldDtldCustLedgEntry;
        with NewDtldCustLedgEntry do begin
            "Entry No." := NextDtldLedgEntryNo;
            "Posting Date" := GenJnlLine."Posting Date";
            "Transaction No." := NextTransactionNo;
            "Application No." := 0;
            Amount := -OldDtldCustLedgEntry.Amount;
            "Amount (LCY)" := -OldDtldCustLedgEntry."Amount (LCY)";
            "Debit Amount" := -OldDtldCustLedgEntry."Debit Amount";
            "Credit Amount" := -OldDtldCustLedgEntry."Credit Amount";
            "Debit Amount (LCY)" := -OldDtldCustLedgEntry."Debit Amount (LCY)";
            "Credit Amount (LCY)" := -OldDtldCustLedgEntry."Credit Amount (LCY)";
            Unapplied := true;
            "Unapplied by Entry No." := OldDtldCustLedgEntry."Entry No.";
            "Document No." := GenJnlLine."Document No.";
            "Source Code" := GenJnlLine."Source Code";
            "User ID" := UserId;
            if GLSetup."Enable Russian Accounting" then begin
                "Customer Posting Group" := OldDtldCustLedgEntry."Customer Posting Group";
                SavedGenJnlLine := GenJnlLine;
                if Prepayment then begin
                    CustLedgEntry2.Get("Cust. Ledger Entry No.");
                    "Document No." := CustLedgEntry2."Document No.";
                    GenJnlLine."Document No." := CustLedgEntry2."Document No.";
                    GenJnlLine.Description := CustLedgEntry2.Description;
                end;
            end;
            OnBeforeInsertDtldCustLedgEntryUnapply(NewDtldCustLedgEntry, GenJnlLine, OldDtldCustLedgEntry);
            Insert(true);
        end;
        NextDtldLedgEntryNo := NextDtldLedgEntryNo + 1;

        OnAfterInsertDtldCustLedgEntryUnapply(CustomerPostingGroup, OldDtldCustLedgEntry);
    end;

    local procedure InsertDtldVendLedgEntryUnapply(var GenJnlLine: Record "Gen. Journal Line"; var SavedGenJnlLine: Record "Gen. Journal Line"; var NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; OldDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var NextDtldLedgEntryNo: Integer)
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
    begin
        NewDtldVendLedgEntry := OldDtldVendLedgEntry;
        with NewDtldVendLedgEntry do begin
            "Entry No." := NextDtldLedgEntryNo;
            "Posting Date" := GenJnlLine."Posting Date";
            "Transaction No." := NextTransactionNo;
            "Application No." := 0;
            Amount := -OldDtldVendLedgEntry.Amount;
            "Amount (LCY)" := -OldDtldVendLedgEntry."Amount (LCY)";
            "Debit Amount" := -OldDtldVendLedgEntry."Debit Amount";
            "Credit Amount" := -OldDtldVendLedgEntry."Credit Amount";
            "Debit Amount (LCY)" := -OldDtldVendLedgEntry."Debit Amount (LCY)";
            "Credit Amount (LCY)" := -OldDtldVendLedgEntry."Credit Amount (LCY)";
            Unapplied := true;
            "Unapplied by Entry No." := OldDtldVendLedgEntry."Entry No.";
            "Document No." := GenJnlLine."Document No.";
            "Source Code" := GenJnlLine."Source Code";
            "User ID" := UserId;
            if GLSetup."Enable Russian Accounting" then begin
                "Vendor Posting Group" := OldDtldVendLedgEntry."Vendor Posting Group";
                SavedGenJnlLine := GenJnlLine;
                if Prepayment then begin
                    VendLedgEntry2.Get("Vendor Ledger Entry No.");
                    "Document No." := VendLedgEntry2."Document No.";
                    GenJnlLine."Document No." := VendLedgEntry2."Document No.";
                    GenJnlLine.Description := VendLedgEntry2.Description;
                end;
            end;
            OnBeforeInsertDtldVendLedgEntryUnapply(NewDtldVendLedgEntry, GenJnlLine, OldDtldVendLedgEntry);
            Insert(true);
        end;
        NextDtldLedgEntryNo := NextDtldLedgEntryNo + 1;
    end;

    local procedure InsertTempVATEntry(GenJnlLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; var TempVATEntryNo: Integer; var TempVATEntry: Record "VAT Entry" temporary)
    begin
        TempVATEntry := VATEntry;
        with TempVATEntry do begin
            "Entry No." := TempVATEntryNo;
            TempVATEntryNo := TempVATEntryNo + 1;
            "Closed by Entry No." := 0;
            Closed := false;
            CopyAmountsFromVATEntry(VATEntry, true);
            "Posting Date" := GenJnlLine."Posting Date";
            "Document Date" := GenJnlLine."Document Date";
            "Document No." := GenJnlLine."Document No.";
            "User ID" := UserId;
            "Transaction No." := NextTransactionNo;
            "G/L Acc. No." := '';
            if GLSetup."Enable Russian Accounting" then begin
                Positive := Amount > 0;
                "Additional VAT Ledger Sheet" := true;
                "Corrected Document Date" := VATEntry."Posting Date";
            end;
            OnInsertTempVATEntryOnBeforeInsert(TempVATEntry, GenJnlLine);
            Insert;
        end;
    end;

    local procedure SetGLAccountNoInVATEntries();
    var
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
    begin
        if TempGLEntryVATEntryLink.FindSet() then
            repeat
                GLEntryVATEntryLink.InsertLinkSelf(TempGLEntryVATEntryLink."G/L Entry No.", TempGLEntryVATEntryLink."VAT Entry No.");
            until TempGLEntryVATEntryLink.Next() = 0;

        TempGLEntryVATEntryLink.DeleteAll();
    end;

    local procedure ProcessTempVATEntry(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var TempVATEntry: Record "VAT Entry" temporary)
    var
        VATEntrySaved: Record "VAT Entry";
        VATBaseSum: array[3] of Decimal;
        DeductedVATBase: Decimal;
        EntryNoBegin: array[3] of Integer;
        i: Integer;
        SummarizedVAT: Boolean;
    begin
        if not (DtldCVLedgEntryBuf."Entry Type" in
                [DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)",
                 DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)",
                 DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)"])
        then
            exit;

        DeductedVATBase := 0;
        TempVATEntry.Reset();
        TempVATEntry.SetRange("Entry No.", 0, 999999);
        TempVATEntry.SetRange("Gen. Bus. Posting Group", DtldCVLedgEntryBuf."Gen. Bus. Posting Group");
        TempVATEntry.SetRange("Gen. Prod. Posting Group", DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
        TempVATEntry.SetRange("VAT Bus. Posting Group", DtldCVLedgEntryBuf."VAT Bus. Posting Group");
        TempVATEntry.SetRange("VAT Prod. Posting Group", DtldCVLedgEntryBuf."VAT Prod. Posting Group");
        if TempVATEntry.FindSet() then
            repeat
                case true of
                    SummarizedVAT and (VATBaseSum[3] + TempVATEntry.Base = DtldCVLedgEntryBuf."Amount (LCY)" - DeductedVATBase):
                        i := 4;
                    SummarizedVAT and (VATBaseSum[2] + TempVATEntry.Base = DtldCVLedgEntryBuf."Amount (LCY)" - DeductedVATBase):
                        i := 3;
                    SummarizedVAT and (VATBaseSum[1] + TempVATEntry.Base = DtldCVLedgEntryBuf."Amount (LCY)" - DeductedVATBase):
                        i := 2;
                    TempVATEntry.Base = DtldCVLedgEntryBuf."Amount (LCY)" - DeductedVATBase:
                        i := 1;
                    else
                        i := 0;
                end;
                if i > 0 then begin
                    TempVATEntry.Reset();
                    if i > 1 then begin
                        if EntryNoBegin[i - 1] < TempVATEntry."Entry No." then
                            TempVATEntry.SetRange("Entry No.", EntryNoBegin[i - 1], TempVATEntry."Entry No.")
                        else
                            TempVATEntry.SetRange("Entry No.", TempVATEntry."Entry No.", EntryNoBegin[i - 1]);
                    end else
                        TempVATEntry.SetRange("Entry No.", TempVATEntry."Entry No.");
                    TempVATEntry.FindSet();
                    repeat
                        VATEntrySaved := TempVATEntry;
                        case DtldCVLedgEntryBuf."Entry Type" of
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                                TempVATEntry.Rename(TempVATEntry."Entry No." + 3000000);
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                                TempVATEntry.Rename(TempVATEntry."Entry No." + 2000000);
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                                TempVATEntry.Rename(TempVATEntry."Entry No." + 1000000);
                        end;
                        TempVATEntry := VATEntrySaved;
                        DeductedVATBase += TempVATEntry.Base;
                    until TempVATEntry.Next() = 0;
                    for i := 1 to 3 do begin
                        VATBaseSum[i] := 0;
                        EntryNoBegin[i] := 0;
                        SummarizedVAT := false;
                    end;
                    TempVATEntry.SetRange("Entry No.", 0, 999999);
                end else begin
                    VATBaseSum[3] += TempVATEntry.Base;
                    VATBaseSum[2] := VATBaseSum[1] + TempVATEntry.Base;
                    VATBaseSum[1] := TempVATEntry.Base;
                    if EntryNoBegin[3] > 0 then
                        EntryNoBegin[3] := TempVATEntry."Entry No.";
                    EntryNoBegin[2] := EntryNoBegin[1];
                    EntryNoBegin[1] := TempVATEntry."Entry No.";
                    SummarizedVAT := true;
                end;
            until TempVATEntry.Next() = 0;
    end;

    local procedure ProcessTempVATEntryCust(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var TempVATEntry: Record "VAT Entry" temporary)
    var
        DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
    begin
        if not DetailedCustLedgEntry.FindSet() then
            exit;
        repeat
            DetailedCVLedgEntryBuffer.Init();
            DetailedCVLedgEntryBuffer.TransferFields(DetailedCustLedgEntry);
            ProcessTempVATEntry(DetailedCVLedgEntryBuffer, TempVATEntry);
            OnProcessTempVATEntryCustOnAfterProcessTempVATEntry(DetailedCVLedgEntryBuffer, TempVATEntry);
        until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure ProcessTempVATEntryVend(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var TempVATEntry: Record "VAT Entry" temporary)
    var
        DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
    begin
        if not DetailedVendorLedgEntry.FindSet() then
            exit;
        repeat
            DetailedCVLedgEntryBuffer.Init();
            DetailedCVLedgEntryBuffer.TransferFields(DetailedVendorLedgEntry);
            ProcessTempVATEntry(DetailedCVLedgEntryBuffer, TempVATEntry);
        until DetailedVendorLedgEntry.Next() = 0;
    end;

    local procedure UpdateCustLedgEntry(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if DtldCustLedgEntry."Entry Type" <> DtldCustLedgEntry."Entry Type"::Application then
            exit;

        CustLedgEntry.Get(DtldCustLedgEntry."Cust. Ledger Entry No.");
        CustLedgEntry."Remaining Pmt. Disc. Possible" := DtldCustLedgEntry."Remaining Pmt. Disc. Possible";
        CustLedgEntry."Max. Payment Tolerance" := DtldCustLedgEntry."Max. Payment Tolerance";
        CustLedgEntry."Accepted Payment Tolerance" := 0;
        if not CustLedgEntry.Open then begin
            CustLedgEntry.Open := true;
            CustLedgEntry."Closed by Entry No." := 0;
            CustLedgEntry."Closed at Date" := 0D;
            CustLedgEntry."Closed by Amount" := 0;
            CustLedgEntry."Closed by Amount (LCY)" := 0;
            CustLedgEntry."Closed by Currency Code" := '';
            CustLedgEntry."Closed by Currency Amount" := 0;
            CustLedgEntry."Pmt. Disc. Given (LCY)" := 0;
            CustLedgEntry."Pmt. Tolerance (LCY)" := 0;
            CustLedgEntry."Calculate Interest" := false;
        end;

        OnBeforeCustLedgEntryModify(CustLedgEntry, DtldCustLedgEntry);
        CustLedgEntry.Modify();

        OnAfterUpdateCustLedgEntry(DtldCustLedgEntry, TempGLEntryBuf, GlobalGLEntry, NextTransactionNo);
    end;

    local procedure UpdateVendLedgEntry(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if DtldVendLedgEntry."Entry Type" <> DtldVendLedgEntry."Entry Type"::Application then
            exit;

        VendLedgEntry.Get(DtldVendLedgEntry."Vendor Ledger Entry No.");
        VendLedgEntry."Remaining Pmt. Disc. Possible" := DtldVendLedgEntry."Remaining Pmt. Disc. Possible";
        VendLedgEntry."Max. Payment Tolerance" := DtldVendLedgEntry."Max. Payment Tolerance";
        VendLedgEntry."Accepted Payment Tolerance" := 0;
        if not VendLedgEntry.Open then begin
            VendLedgEntry.Open := true;
            VendLedgEntry."Closed by Entry No." := 0;
            VendLedgEntry."Closed at Date" := 0D;
            VendLedgEntry."Closed by Amount" := 0;
            VendLedgEntry."Closed by Amount (LCY)" := 0;
            VendLedgEntry."Closed by Currency Code" := '';
            VendLedgEntry."Closed by Currency Amount" := 0;
            VendLedgEntry."Pmt. Disc. Rcd.(LCY)" := 0;
            VendLedgEntry."Pmt. Tolerance (LCY)" := 0;
        end;

        OnBeforeVendLedgEntryModify(VendLedgEntry, DtldVendLedgEntry);
        VendLedgEntry.Modify();

        OnAfterUpdateVendLedgEntry(DtldVendLedgEntry, TempGLEntryBuf, GlobalGLEntry, NextTransactionNo);
    end;

    local procedure UpdateCalcInterest(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        with CVLedgEntryBuf do begin
            if CustLedgEntry.Get("Closed by Entry No.") then begin
                CVLedgEntryBuf2.TransferFields(CustLedgEntry);
                UpdateCalcInterest(CVLedgEntryBuf, CVLedgEntryBuf2);
            end;
            CustLedgEntry.SetCurrentKey("Closed by Entry No.");
            CustLedgEntry.SetRange("Closed by Entry No.", "Entry No.");
            OnUpdateCalcInterestOnAfterCustLedgEntrySetFilters(CustLedgEntry, CVLedgEntryBuf);
            if CustLedgEntry.FindSet() then
                repeat
                    CVLedgEntryBuf2.TransferFields(CustLedgEntry);
                    UpdateCalcInterest(CVLedgEntryBuf, CVLedgEntryBuf2);
                until CustLedgEntry.Next() = 0;
        end;
    end;

    local procedure UpdateCalcInterest(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var CVLedgEntryBuf2: Record "CV Ledger Entry Buffer")
    begin
        with CVLedgEntryBuf do
            if "Due Date" < CVLedgEntryBuf2."Document Date" then
                "Calculate Interest" := true;
    end;

    local procedure GLCalcAddCurrency(Amount: Decimal; AddCurrAmount: Decimal; OldAddCurrAmount: Decimal; UseAddCurrAmount: Boolean; GenJnlLine: Record "Gen. Journal Line") Result: Decimal
    var
        IsHandled: Boolean;
    begin
        if (AddCurrencyCode <> '') and
           (GenJnlLine."Additional-Currency Posting" = GenJnlLine."Additional-Currency Posting"::None) and
           (not GenJnlLine."Prepmt. Diff." or not GLSetup."Enable Russian Accounting")
        then begin
            if (GenJnlLine."Source Currency Code" = AddCurrencyCode) and UseAddCurrAmount then
                exit(AddCurrAmount);

            IsHandled := false;
            OnGLCalcAddCurrencyPostingNone(GenJnlLine, Amount, AddCurrency, Result, IsHandled);
            if IsHandled then
                exit(Result);
            exit(ExchangeAmtLCYToFCY2(Amount));
        end;
        exit(OldAddCurrAmount);
    end;

    local procedure HandleAddCurrResidualGLEntry(GenJnlLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry")
    var
        GLAcc: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        IsHandled: Boolean;
    begin
        if AddCurrencyCode = '' then
            exit;

        TotalAddCurrAmount := TotalAddCurrAmount + GLEntry2."Additional-Currency Amount";
        TotalAmount := TotalAmount + GLEntry2.Amount;

        if (GenJnlLine."Additional-Currency Posting" = GenJnlLine."Additional-Currency Posting"::None) and
           (TotalAmount = 0) and (TotalAddCurrAmount <> 0) and
           CheckNonAddCurrCodeOccurred(GenJnlLine."Source Currency Code")
        then begin
            GLEntry.Init();
            GLEntry.CopyFromGenJnlLine(GenJnlLine);
            GLEntry."External Document No." := '';
            GLEntry.Description :=
              CopyStr(
                StrSubstNo(
                  ResidualRoundingErr,
                  GLEntry.FieldCaption("Additional-Currency Amount")),
                1, MaxStrLen(GLEntry.Description));
            GLEntry."Source Type" := GLEntry."Source Type"::" ";
            GLEntry."Source No." := '';
            GLEntry."Job No." := '';
            GLEntry.Quantity := 0;
            GLEntry."Entry No." := NextEntryNo;
            GLEntry."Transaction No." := NextTransactionNo;
            if TotalAddCurrAmount < 0 then
                GLEntry."G/L Account No." := AddCurrency."Residual Losses Account"
            else
                GLEntry."G/L Account No." := AddCurrency."Residual Gains Account";
            GLEntry.Amount := 0;
            GLEntry."System-Created Entry" := true;
            GLEntry."Additional-Currency Amount" := -TotalAddCurrAmount;
            GLEntry."Source Type" := TempGLEntryBuf."Source Type";
            GLEntry."Source No." := TempGLEntryBuf."Source No.";
            GLAcc.Get(GLEntry."G/L Account No.");
            GLAcc.TestField(Blocked, false);
            GLAcc.TestField("Account Type", GLAcc."Account Type"::Posting);
            IsHandled := false;
            OnHandleAddCurrResidualGLEntryOnBeforeInsertGLEntry(GenJnlLine, GLEntry, TempGLEntryBuf, NextEntryNo, IsHandled);
            if not IsHandled then
                InsertGLEntry(GenJnlLine, GLEntry, false);

            CheckGLAccDimError(GenJnlLine, GLEntry."G/L Account No.");

            TotalAddCurrAmount := 0;
        end;

        OnAfterHandleAddCurrResidualGLEntry(GenJnlLine, GLEntry2);
    end;

    local procedure CalcLCYToAddCurr(AmountLCY: Decimal): Decimal
    begin
        if AddCurrencyCode = '' then
            exit;

        exit(ExchangeAmtLCYToFCY2(AmountLCY));
    end;

    local procedure GetCurrencyExchRate(GenJnlLine: Record "Gen. Journal Line")
    var
        NewCurrencyDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCurrencyExchRate(GenJnlLine, AddCurrencyCode, UseCurrFactorOnly, CurrencyDate, CurrencyFactor, IsHandled);
        if IsHandled then
            exit;

        if AddCurrencyCode = '' then
            exit;

        AddCurrency.Get(AddCurrencyCode);
        AddCurrency.TestField("Amount Rounding Precision");
        AddCurrency.TestField("Residual Gains Account");
        AddCurrency.TestField("Residual Losses Account");

        NewCurrencyDate := GenJnlLine."Posting Date";
        if GenJnlLine."Reversing Entry" then
            NewCurrencyDate := NewCurrencyDate - 1;
        OnGetCurrencyExchRateOnAfterSetNewCurrencyDate(GenJnlLine, NewCurrencyDate);
        if (NewCurrencyDate <> CurrencyDate) or
           UseCurrFactorOnly
        then begin
            UseCurrFactorOnly := false;
            CurrencyDate := NewCurrencyDate;
            CurrencyFactor :=
              CurrExchRate.ExchangeRate(CurrencyDate, AddCurrencyCode);
        end;
        if (GenJnlLine."FA Add.-Currency Factor" <> 0) and
           (GenJnlLine."FA Add.-Currency Factor" <> CurrencyFactor)
        then begin
            UseCurrFactorOnly := true;
            CurrencyDate := 0D;
            CurrencyFactor := GenJnlLine."FA Add.-Currency Factor";
        end;

        OnAfterGetCurrencyExchRate(GenJnlLine, NewCurrencyDate, CurrencyDate, UseCurrFactorOnly, CurrencyFactor);
    end;

    [Scope('OnPrem')]
    procedure PostVendVATSettlement(GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var GenJnlLine2: Record "Gen. Journal Line")
    var
        PrepmtDiffVATEntry: Record "VAT Entry";
        VATAllocationLine: Record "VAT Allocation Line";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        VATAllocationPost: Codeunit "VAT Allocation-Post";
        VATPart: Decimal;
        DeprAmount: Decimal;
        DeprBook: Code[10];
    begin
        GenJnlLine.Copy(GenJnlLine2);

        VATSettlementMgt.CheckFPE(GenJnlLine);

        StartPosting(GenJnlLine);

        VendLedgEntry2.CalcFields(Amount, "Amount (LCY)", "Remaining Amt. (LCY)", "Original Amt. (LCY)");
        VendLedgEntry2."Currency Code" := '';
        case GenJnlLine."VAT Settlement Part" of
            GenJnlLine."VAT Settlement Part"::" ":
                ;
            GenJnlLine."VAT Settlement Part"::Custom:
                begin
                    if GenJnlLine2."Paid Amount" = 0 then
                        VATPart := 0
                    else
                        VATPart := GenJnlLine.Amount / GenJnlLine2."Paid Amount";
                end;
            else
                VATPart := VATSettlementMgt.CalcUnrealVATPart(GenJnlLine);
        end;
        if VATSettlementMgt.IsLastOperation(GenJnlLine) then
            VATPart := 1;

        if GenJnlLine."VAT Settlement Part" <> GenJnlLine."VAT Settlement Part"::" " then
            GenJnlLine."VAT Transaction No." := 0
        else
            if VATPart <> 1 then begin
                VendLedgEntry2."Remaining Amt. (LCY)" := -GenJnlLine.Amount;
                VendLedgEntry2.Open := true;
            end;
        if GenJnlLine."Prepmt. Diff." then begin
            GenJnlLine.Correction := GenJnlLine.Amount > 0;
            VATPart := 1;
            PrepmtDiffVATEntry.Get(GenJnlLine."Unrealized VAT Entry No.");
            if GenJnlLine."Posting Date" < PrepmtDiffVATEntry."Posting Date" then
                GenJnlLine."Posting Date" := PrepmtDiffVATEntry."Posting Date";
        end;

        VATAllocationLine.Reset();
        VATAllocationLine.SetRange("VAT Entry No.", GenJnlLine."Unrealized VAT Entry No.");
        if VATAllocationLine.FindSet() then begin
            repeat
                if VATAllocationLine.Amount <> 0 then begin
                    GenJnlLine.Amount := VATAllocationLine.Amount;
                    if GenJnlLine2."Paid Amount" <> 0 then
                        VATPart := GenJnlLine.Amount / GenJnlLine2."Paid Amount"
                    else
                        VATPart := 0;
                    GenJnlLine."VAT Amount" := VATAllocationLine."VAT Amount";
                    GenJnlLine."VAT Base Amount" := VATAllocationLine."VAT Base Amount";
                    GenJnlLine."VAT Allocation Type" := VATAllocationLine.Type;
                    GenJnlLine."Account No." := VATAllocationLine."Account No.";
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                    if VATAllocationLine."FA No." = '' then begin
                        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
                        GenJnlLine."Source No." := VendLedgEntry2."Vendor No.";
                    end else begin
                        GenJnlLine."Source Type" := GenJnlLine."Source Type"::"Fixed Asset";
                        GenJnlLine."Source No." := VATAllocationLine."FA No.";
                    end;
                    GenJnlLine."Dimension Set ID" := VATAllocationLine."Dimension Set ID";
                    VendLedgEntry2.Description :=
                      CopyStr(GenJnlLine.Description + ' ' + VATAllocationLine.Description,
                        1, MaxStrLen(VendLedgEntry2.Description));

                    VendUnrealizedVAT(GenJnlLine,
                      VendLedgEntry2, GenJnlLine.Amount, GenJnlLine."Unrealized VAT Entry No.",
                      VATPart, GenJnlLine."VAT Transaction No.", VATAllocationLine."Line No.");

                    if VATAllocationLine."FA No." <> '' then begin
                        VATAllocationPost.PostFAAllocation(GenJnlLine2, VATAllocationLine, DeprAmount, DeprBook);
                        if DeprAmount <> 0 then
                            PostVATAllocDepreciation(GenJnlLine2, VATAllocationLine, DeprAmount, DeprBook);
                    end;
                    GenJnlLine2."Paid Amount" := GenJnlLine2."Paid Amount" - GenJnlLine.Amount;
                end;
            until VATAllocationLine.Next() = 0;
            VATEntry.Get(GenJnlLine."Unrealized VAT Entry No.");
            if VATEntry."Remaining Unrealized Base" = 0 then
                VATAllocationLine.DeleteAll(true);
        end else
            VendUnrealizedVAT(GenJnlLine,
              VendLedgEntry2, GenJnlLine.Amount, GenJnlLine."Unrealized VAT Entry No.",
              VATPart, GenJnlLine."VAT Transaction No.", 0);

        FinishPosting(GenJnlLine);
        GenJnlLine2 := GenJnlLine;
    end;

    [Scope('OnPrem')]
    procedure PostCustVATSettlement(GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry2: Record "Cust. Ledger Entry"; var GenJnlLine2: Record "Gen. Journal Line")
    var
        PrepmtDiffVATEntry: Record "VAT Entry";
        VATAllocationLine: Record "VAT Allocation Line";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        VATPart: Decimal;
    begin
        GenJnlLine.Copy(GenJnlLine2);

        StartPosting(GenJnlLine);

        CustLedgEntry2.CalcFields(Amount, "Amount (LCY)", "Remaining Amt. (LCY)", "Original Amt. (LCY)");
        CustLedgEntry2."Currency Code" := '';

        case GenJnlLine."VAT Settlement Part" of
            GenJnlLine."VAT Settlement Part"::" ":
                ;
            GenJnlLine."VAT Settlement Part"::Custom:
                begin
                    if GenJnlLine2."Paid Amount" = 0 then
                        VATPart := 0
                    else
                        VATPart := GenJnlLine.Amount / GenJnlLine2."Paid Amount";
                end;
            else
                VATPart := VATSettlementMgt.CalcUnrealVATPart(GenJnlLine);
        end;
        if VATSettlementMgt.IsLastOperation(GenJnlLine) then
            VATPart := 1;

        if GenJnlLine."VAT Settlement Part" <> GenJnlLine."VAT Settlement Part"::" " then
            GenJnlLine."VAT Transaction No." := 0;

        if GenJnlLine."Prepmt. Diff." then begin
            GenJnlLine.Correction := GenJnlLine.Amount < 0;
            VATPart := 1;
            PrepmtDiffVATEntry.Get(GenJnlLine."Unrealized VAT Entry No.");
            if GenJnlLine."Posting Date" < PrepmtDiffVATEntry."Posting Date" then
                GenJnlLine."Posting Date" := PrepmtDiffVATEntry."Posting Date";
        end;

        VATAllocationLine.Reset();
        VATAllocationLine.SetRange("VAT Entry No.", GenJnlLine."Unrealized VAT Entry No.");
        if VATAllocationLine.FindSet() then begin
            repeat
                if VATAllocationLine.Amount <> 0 then begin
                    GenJnlLine.Amount := VATAllocationLine.Amount;
                    if GenJnlLine2."Paid Amount" <> 0 then
                        VATPart := GenJnlLine.Amount / GenJnlLine2."Paid Amount"
                    else
                        VATPart := 0;
                    GenJnlLine."VAT Amount" := VATAllocationLine."VAT Amount";
                    GenJnlLine."VAT Base Amount" := VATAllocationLine."VAT Base Amount";
                    GenJnlLine."VAT Allocation Type" := VATAllocationLine.Type;
                    GenJnlLine."Account No." := VATAllocationLine."Account No.";
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                    GenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
                    GenJnlLine."Source No." := CustLedgEntry2."Customer No.";
                    GenJnlLine."Dimension Set ID" := VATAllocationLine."Dimension Set ID";
                    CustLedgEntry2.Description :=
                      CopyStr(GenJnlLine.Description + ' ' + VATAllocationLine.Description,
                        1, MaxStrLen(CustLedgEntry2.Description));

                    CustUnrealizedVAT(GenJnlLine,
                      CustLedgEntry2, GenJnlLine.Amount, GenJnlLine."Unrealized VAT Entry No.",
                      VATPart, VATAllocationLine."Line No.");

                    GenJnlLine2."Paid Amount" := GenJnlLine2."Paid Amount" - GenJnlLine.Amount;
                end;
            until VATAllocationLine.Next() = 0;
            VATEntry.Get(GenJnlLine."Unrealized VAT Entry No.");
            if VATEntry."Remaining Unrealized Base" = 0 then
                VATAllocationLine.DeleteAll(true);
        end else
            CustUnrealizedVAT(GenJnlLine,
              CustLedgEntry2, GenJnlLine.Amount, GenJnlLine."Unrealized VAT Entry No.", VATPart, 0);

        FinishPosting(GenJnlLine);
        GenJnlLine2 := GenJnlLine;
    end;

    [Scope('OnPrem')]
    procedure PostVendVATReinstatement(var GenJnlLine2: Record "Gen. Journal Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        UnrealizedVATEntry: Record "VAT Entry";
        SourceVATEntry: Record "VAT Entry";
        NewVATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        VATReinstMgt: Codeunit "VAT Reinstatement Management";
        ReinstatementAmount: Decimal;
        ReinstatementBaseAmount: Decimal;
        ReinstatementACAmount: Decimal;
        ReinstatementBaseACAmount: Decimal;
    begin
        VATReinstMgt.CheckAmount(GenJnlLine2);
        GenJnlLine.Copy(GenJnlLine2);

        StartPosting(GenJnlLine);

        SourceVATEntry.Get(GenJnlLine2."Reinstatement VAT Entry No.");
        SourceVATEntry.TestField("Unrealized VAT Entry No.");

        ReinstatementAmount := GenJnlLine2.Amount;
        VATPostingSetup.Get(SourceVATEntry."VAT Bus. Posting Group", SourceVATEntry."VAT Prod. Posting Group");
        VATPostingSetup.TestField("Trans. VAT Type", VATPostingSetup."Trans. VAT Type"::" ");
        VATPostingSetup.TestField("Trans. VAT Account", '');
        VATPostingSetup.TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        ReinstatementBaseAmount := Round(ReinstatementAmount / VATPostingSetup."VAT %" * 100);
        ReinstatementACAmount := CalcLCYToAddCurr(ReinstatementAmount);
        ReinstatementBaseACAmount := CalcLCYToAddCurr(ReinstatementBaseAmount);

        NewVATEntry := SourceVATEntry;
        NewVATEntry."Entry No." := NextVATEntryNo;
        NewVATEntry."Transaction No." := NextTransactionNo;
        NewVATEntry."Posting Date" := GenJnlLine2."Posting Date";
        NewVATEntry."Document Date" := GenJnlLine2."Document Date";
        NewVATEntry.Amount := -ReinstatementAmount;
        NewVATEntry.Base := -ReinstatementBaseAmount;
        NewVATEntry.Positive := false;
        NewVATEntry."VAT Reinstatement" := true;
        NewVATEntry."User ID" := UserId;
        NewVATEntry.Insert(true);

        NextVATEntryNo := NextVATEntryNo + 1;

        UnrealizedVATEntry.Get(SourceVATEntry."Unrealized VAT Entry No.");
        UnrealizedVATEntry."Remaining Unrealized Amount" :=
          UnrealizedVATEntry."Remaining Unrealized Amount" + ReinstatementAmount;
        UnrealizedVATEntry."Remaining Unrealized Base" :=
          UnrealizedVATEntry."Remaining Unrealized Base" + ReinstatementBaseAmount;
        UnrealizedVATEntry."Add.-Curr. Rem. Unreal. Amount" :=
          UnrealizedVATEntry."Add.-Currency Unrealized Amt." + ReinstatementACAmount;
        UnrealizedVATEntry."Add.-Currency Unrealized Base" :=
          UnrealizedVATEntry."Add.-Currency Unrealized Base" + ReinstatementBaseACAmount;
        UnrealizedVATEntry.Modify();

        VATPostingSetup.Get(SourceVATEntry."VAT Bus. Posting Group", SourceVATEntry."VAT Prod. Posting Group");

        VATPostingSetup.TestField("Purch. VAT Unreal. Account");
        InitGLEntry(GenJnlLine, GLEntry,
          VATPostingSetup."Purch. VAT Unreal. Account",
          ReinstatementAmount, ReinstatementACAmount, true, true);
        GLEntry."Bal. Account No." := VATPostingSetup."Purchase VAT Account";
        InsertGLEntry(GenJnlLine, GLEntry, true);

        VATPostingSetup.TestField("Purchase VAT Account");
        InitGLEntry(GenJnlLine, GLEntry,
          VATPostingSetup."Purchase VAT Account",
          -ReinstatementAmount, -ReinstatementACAmount, true, true);
        GLEntry."Bal. Account No." := VATPostingSetup."Purch. VAT Unreal. Account";
        GLEntry."Gen. Posting Type" := GLEntry."Gen. Posting Type"::Purchase;
        GLEntry."Gen. Bus. Posting Group" := SourceVATEntry."Gen. Bus. Posting Group";
        GLEntry."Gen. Prod. Posting Group" := SourceVATEntry."Gen. Prod. Posting Group";
        InsertGLEntry(GenJnlLine, GLEntry, true);

        FinishPosting(GenJnlLine);
        GenJnlLine2 := GenJnlLine;
    end;

    local procedure PostCustBackPrepayment(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; CustPostingGr: Record "Customer Posting Group")
    var
        GLEntry: Record "G/L Entry";
        UseAddCurrAmount: Boolean;
    begin
        if FinVoidedCheck then
            exit;

        if not DtldCVLedgEntryBuf.Prepayment then
            exit;

        if GenJnlLine."Prepayment Status" = GenJnlLine."Prepayment Status"::Reset then
            exit;

        if (DtldCVLedgEntryBuf."Amount (LCY)" <> 0) or (DtldCVLedgEntryBuf."Additional-Currency Amount" <> 0) then begin
            UseAddCurrAmount := DtldCVLedgEntryBuf."Currency Code" <> '';
            if UseAddCurrAmount and
               (DtldCVLedgEntryBuf."Currency Code" = AddCurrencyCode)
            then
                DtldCVLedgEntryBuf."Additional-Currency Amount" := DtldCVLedgEntryBuf.Amount;
            InitGLEntry(GenJnlLine, GLEntry,
              CustPostingGr."Receivables Account",
              -DtldCVLedgEntryBuf."Amount (LCY)",
              -DtldCVLedgEntryBuf."Additional-Currency Amount", UseAddCurrAmount, true);
            GLEntry."Bal. Account Type" := GLEntry."Bal. Account Type"::"G/L Account";
            GLEntry."Bal. Account No." := CustPostingGr."Prepayment Account";
            InsertRUGLEntry(GenJnlLine, GLEntry,
              CustPostingGr."Prepayment Account", true, UseAddCurrAmount, false);
        end;
    end;

    local procedure InsertCustGLEntry(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; CustPostingGr: Record "Customer Posting Group")
    var
        TempGenJnlLine: Record "Gen. Journal Line";
        SavedGenJnlLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        SalesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPrepmtPost: Codeunit "VAT Prepayment-Post";
    begin
        with GenJnlLine do begin
            InitGLEntry(GenJnlLine, GLEntry,
              CustPostingGr.GetPrepaymentAccount(DtldCVLedgEntryBuf.Prepayment),
              DtldCVLedgEntryBuf."Amount (LCY)",
              DtldCVLedgEntryBuf."Additional-Currency Amount", true, true);
            GLEntry."Entry No." := DtldCVLedgEntryBuf."CV Ledger Entry No.";
            GLEntry."Bal. Account Type" := "Bal. Account Type";
            GLEntry."Bal. Account No." := "Bal. Account No.";
            if "Prepayment Status" <> "Prepayment Status"::" " then
                GLEntry."Bal. Account No." := CustPostingGr.GetPrepaymentAccount(not DtldCVLedgEntryBuf.Prepayment);
            NextEntryNo := NextEntryNo - 1;

            if not DtldCVLedgEntryBuf.Prepayment or ("Prepayment Status" = "Prepayment Status"::Reset) then
                InsertGLEntry(GenJnlLine, GLEntry, true)
            else begin
                TempGenJnlLine.Init();
                TempGenJnlLine."Posting Date" := "Posting Date";
                TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                TempGenJnlLine."Document No." := "Document No.";
                TempGenJnlLine."External Document No." := "External Document No.";
                TempGenJnlLine.Prepayment := Prepayment;
                TempGenJnlLine.Validate("Account No.", CustPostingGr."Prepayment Account");
                TempGenJnlLine.Validate(Amount, DtldCVLedgEntryBuf."Amount (LCY)");
                TempGenJnlLine."Bill-to/Pay-to No." := "Bill-to/Pay-to No.";
                TempGenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                TempGenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                TempGenJnlLine."Source Code" := "Source Code";
                TempGenJnlLine."Source Type" := TempGenJnlLine."Source Type"::Customer;
                TempGenJnlLine."Source No." := DtldCVLedgEntryBuf."CV No.";
                TempGenJnlLine.Correction := Correction;
                TempGenJnlLine.Description := Description;
                TempGenJnlLine."Prepayment Status" := "Prepayment Status";
                TempGenJnlLine."Prepayment Document No." := "Prepayment Document No.";

                CustLedgerEntry.Get(DtldCVLedgEntryBuf."CV Ledger Entry No.");
                SalesSetup.Get();
                if SalesSetup."Create Prepayment Invoice" then
                    CustLedgerEntry."Prepayment Document No." :=
                      VATPrepmtPost.InsertSalesInvoice(TempGenJnlLine)
                else
                    CustLedgerEntry."Prepayment Document No." := "Document No.";
                CustLedgerEntry.Modify();

                SavedGenJnlLine := GenJnlLine;
                GenJnlLine := TempGenJnlLine;

                InitVAT(GenJnlLine, GLEntry, VATPostingSetup);
                InsertGLEntry(GenJnlLine, GLEntry, true);
                PostVAT(GenJnlLine, GLEntry, VATPostingSetup);
                GenJnlLine := SavedGenJnlLine;
            end;
        end;
    end;

    local procedure PostVendBackPrepayment(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group"; Unapply: Boolean)
    var
        UnrealizedVATEntry: Record "VAT Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        UseAddCurrAmount: Boolean;
    begin
        if not DtldCVLedgEntryBuf.Prepayment then
            exit;

        IsVendBackPrepmt := true;
        if not FinVoidedCheck then
            if GenJnlLine."Prepayment Status" <> GenJnlLine."Prepayment Status"::Reset then
                if (DtldCVLedgEntryBuf."Amount (LCY)" <> 0) or (DtldCVLedgEntryBuf."Additional-Currency Amount" <> 0)
                then begin
                    UseAddCurrAmount := DtldCVLedgEntryBuf."Currency Code" <> '';
                    if UseAddCurrAmount and
                       (DtldCVLedgEntryBuf."Currency Code" = AddCurrencyCode)
                    then
                        DtldCVLedgEntryBuf."Additional-Currency Amount" := DtldCVLedgEntryBuf.Amount;
                    InitGLEntry(GenJnlLine, GLEntry,
                      VendPostingGr."Payables Account",
                      -DtldCVLedgEntryBuf."Amount (LCY)",
                      -DtldCVLedgEntryBuf."Additional-Currency Amount", UseAddCurrAmount, true);
                    GLEntry."Bal. Account Type" := GLEntry."Bal. Account Type"::"G/L Account";
                    GLEntry."Bal. Account No." := VendPostingGr."Prepayment Account";
                    InsertGLEntry(GenJnlLine, GLEntry, true);

                    VendPostingGr.TestField("Prepayment Account");
                    InitGLEntry(GenJnlLine, GLEntry,
                      VendPostingGr."Prepayment Account",
                      DtldCVLedgEntryBuf."Amount (LCY)",
                      DtldCVLedgEntryBuf."Additional-Currency Amount", UseAddCurrAmount, true);
                    GLEntry."Bal. Account Type" := GLEntry."Bal. Account Type"::"G/L Account";
                    GLEntry."Bal. Account No." := VendPostingGr."Payables Account";
                    InsertGLEntry(GenJnlLine, GLEntry, true);
                end;

        if not Unapply then begin
            VendLedgEntry.Get(DtldCVLedgEntryBuf."CV Ledger Entry No.");
            VendLedgEntry."Currency Code" := '';
            UnrealizedVATEntry.SetCurrentKey("Transaction No.", "CV Ledg. Entry No.");
            UnrealizedVATEntry.SetRange("CV Ledg. Entry No.", DtldCVLedgEntryBuf."CV Ledger Entry No.");
            UnrealizedVATEntry.SetRange("Unrealized VAT Entry No.", 0);
            UnrealizedVATEntry.SetRange(Prepayment, true);
            if UnrealizedVATEntry.FindSet() then
                repeat
                    GenJnlLine."Document Type" := UnrealizedVATEntry."Document Type";
                    GenJnlLine."Document No." := UnrealizedVATEntry."Document No.";
                    VendLedgEntry."Transaction No." := UnrealizedVATEntry."Transaction No.";
                    if not VATSettlementMgt.VATIsPostponed(UnrealizedVATEntry, 0, GenJnlLine."Posting Date") then begin
                        VendLedgEntry.CalcFields(
                          "Amount (LCY)", "Original Amt. (LCY)", "Amount (LCY)", "Remaining Amt. (LCY)");
                        VendUnrealizedVAT(GenJnlLine,
                          VendLedgEntry, DtldCVLedgEntryBuf."Amount (LCY)", UnrealizedVATEntry."Entry No.", 0, 0, 0);
                        CheckUnrealizedVend := false;
                    end;
                until UnrealizedVATEntry.Next() = 0;
        end;
        IsVendBackPrepmt := false;
    end;

    local procedure InsertVendGLEntry(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group")
    var
        GLEntry: Record "G/L Entry";
    begin
        InitGLEntry(GenJnlLine, GLEntry,
          VendPostingGr.GetPrepaymentAccount(DtldCVLedgEntryBuf.Prepayment),
          DtldCVLedgEntryBuf."Amount (LCY)",
          DtldCVLedgEntryBuf."Additional-Currency Amount", true, true);
        GLEntry."Bal. Account Type" := GenJnlLine."Bal. Account Type";
        GLEntry."Bal. Account No." := GenJnlLine."Bal. Account No.";
        GLEntry."Source Type" := GLEntry."Source Type"::Vendor;
        GLEntry."Source No." := DtldCVLedgEntryBuf."CV No.";
        GLEntry."Entry No." := DtldCVLedgEntryBuf."CV Ledger Entry No.";
        NextEntryNo := NextEntryNo - 1;
        InsertGLEntry(GenJnlLine, GLEntry, true);

        InsertVATAgentVATPmtGLEntry(GenJnlLine, DtldCVLedgEntryBuf."Amount (LCY)");
    end;

    [Scope('OnPrem')]
    procedure RUFindAmtForAppln(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var OldAppliedAmount: Decimal; ApplnRoundingPrecision: Decimal)
    var
        PayEntryBuf: Record "CV Ledger Entry Buffer" temporary;
        InvEntryBuf: Record "CV Ledger Entry Buffer" temporary;
        SaveAmount: Decimal;
        InvAmount: Decimal;
        PayAmount: Decimal;
        ReplaceEntries: Boolean;
    begin
        if not GLSetup."Enable Russian Accounting" then
            exit;

        if (NewCVLedgEntryBuf."Currency Code" = '') and (OldCVLedgEntryBuf."Currency Code" = '') then
            exit;
        if (NewCVLedgEntryBuf."Currency Code" <> OldCVLedgEntryBuf."Currency Code") and
           (NewCVLedgEntryBuf."Currency Code" <> '') and (OldCVLedgEntryBuf."Currency Code" <> '')
        then
            exit;

        ReplaceEntries :=
          (NewCVLedgEntryBuf."Document Type" in [NewCVLedgEntryBuf."Document Type"::" ",
                                                 NewCVLedgEntryBuf."Document Type"::Payment,
                                                 NewCVLedgEntryBuf."Document Type"::Refund]);
        if not ReplaceEntries then begin
            InvEntryBuf := NewCVLedgEntryBuf;
            PayEntryBuf := OldCVLedgEntryBuf;
        end else begin
            PayEntryBuf := NewCVLedgEntryBuf;
            InvEntryBuf := OldCVLedgEntryBuf;
        end;

        if PayEntryBuf."Currency Code" = InvEntryBuf."Currency Code" then begin
            InvAmount := GetRemAmount(InvEntryBuf, ApplnRoundingPrecision);
            PayAmount := GetRemAmount(PayEntryBuf, ApplnRoundingPrecision);
            if Abs(InvAmount) <= Abs(PayAmount) then
                AppliedAmount := InvAmount
            else
                AppliedAmount := -PayAmount;
            OldAppliedAmount := AppliedAmount;
            if PayEntryBuf."Posting Date" > InvEntryBuf."Posting Date" then
                AppliedAmountLCY := Round(OldAppliedAmount / PayEntryBuf."Original Currency Factor")
            else
                AppliedAmountLCY := Round(OldAppliedAmount / InvEntryBuf."Original Currency Factor");
            if GLSetup."Cancel Curr. Prepmt. Adjmt." and PayEntryBuf.Prepayment then
                AppliedAmountLCY := Round(OldAppliedAmount / PayEntryBuf."Original Currency Factor");
        end else
            case true of
                PayEntryBuf."Currency Code" = '':
                    CalcAppliedAmounts(InvEntryBuf, PayEntryBuf, AppliedAmount, AppliedAmountLCY, OldAppliedAmount, ApplnRoundingPrecision, 1);
                InvEntryBuf."Currency Code" = '':
                    CalcAppliedAmounts(PayEntryBuf, InvEntryBuf, OldAppliedAmount, AppliedAmountLCY, AppliedAmount, ApplnRoundingPrecision, -1);
            end;

        if ReplaceEntries then begin
            SaveAmount := OldAppliedAmount;
            OldAppliedAmount := -AppliedAmount;
            AppliedAmount := -SaveAmount;
            AppliedAmountLCY := -AppliedAmountLCY;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckCalcAmtDiff(NewCVLedgCurrencyCode: Code[10]; OldCVLedgCurrencyCode: Code[10]): Boolean
    begin
        if not GLSetup."Enable Russian Accounting" then
            exit(false);

        // Amt Diff is only when one of currencies is LCY
        exit((NewCVLedgCurrencyCode = '') xor (OldCVLedgCurrencyCode = ''));
    end;

    [Scope('OnPrem')]
    procedure GetLastDate(Date1: Date; Date2: Date; Date3: Date) ReturnDate: Date
    begin
        if Date3 > LastDate then
            ReturnDate := Date3
        else begin
            if Date2 > Date1 then
                ReturnDate := Date2
            else
                ReturnDate := Date1;
        end;
    end;

    local procedure GetPayablesAccountNo(GenJnlLine: Record "Gen. Journal Line"): Code[20]
    var
        VendPostGroup: Record "Vendor Posting Group";
    begin
        with GenJnlLine do begin
            TestField("Posting Group");
            VendPostGroup.Get("Posting Group");
            exit(VendPostGroup.GetPrepaymentAccount(Prepayment));
        end;
    end;

    local procedure ExchangeAmtLCYToFCY2(Amount: Decimal): Decimal
    begin
        if UseCurrFactorOnly then
            exit(
              Round(
                CurrExchRate.ExchangeAmtLCYToFCYOnlyFactor(Amount, CurrencyFactor),
                AddCurrency."Amount Rounding Precision"));
        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
              CurrencyDate, AddCurrencyCode, Amount, CurrencyFactor),
            AddCurrency."Amount Rounding Precision"));
    end;

    local procedure CheckNonAddCurrCodeOccurred(CurrencyCode: Code[10]): Boolean
    begin
        NonAddCurrCodeOccured :=
          NonAddCurrCodeOccured or (AddCurrencyCode <> CurrencyCode);
        exit(NonAddCurrCodeOccured);
    end;

    local procedure TotalVATAmountOnJnlLines(GenJnlLine: Record "Gen. Journal Line") TotalVATAmount: Decimal
    var
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        with GenJnlLine2 do begin
            SetRange("Source Code", GenJnlLine."Source Code");
            SetRange("Document No.", GenJnlLine."Document No.");
            SetRange("Posting Date", GenJnlLine."Posting Date");
            CalcSums("VAT Amount (LCY)", "Bal. VAT Amount (LCY)");
            TotalVATAmount := "VAT Amount (LCY)" - "Bal. VAT Amount (LCY)";
        end;
        exit(TotalVATAmount);
    end;

    procedure SetGLRegReverse(var ReverseGLReg: Record "G/L Register")
    begin
        GLReg.Reversed := true;
        ReverseGLReg := GLReg;
    end;

    local procedure InsertVATEntriesFromTemp(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GLEntry: Record "G/L Entry")
    var
        Complete: Boolean;
        LinkedAmount: Decimal;
        FirstEntryNo: Integer;
        LastEntryNo: Integer;
    begin
        TempVATEntry.Reset();
        TempVATEntry.SetRange("Gen. Bus. Posting Group", GLEntry."Gen. Bus. Posting Group");
        TempVATEntry.SetRange("Gen. Prod. Posting Group", GLEntry."Gen. Prod. Posting Group");
        TempVATEntry.SetRange("VAT Bus. Posting Group", GLEntry."VAT Bus. Posting Group");
        TempVATEntry.SetRange("VAT Prod. Posting Group", GLEntry."VAT Prod. Posting Group");
        case DtldCVLedgEntryBuf."Entry Type" of
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                begin
                    FirstEntryNo := 1000000;
                    LastEntryNo := 1999999;
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                begin
                    FirstEntryNo := 2000000;
                    LastEntryNo := 2999999;
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                begin
                    FirstEntryNo := 3000000;
                    LastEntryNo := 3999999;
                end;
        end;
        TempVATEntry.SetRange("Entry No.", FirstEntryNo, LastEntryNo);
        if TempVATEntry.FindSet() then
            repeat
                VATEntry := TempVATEntry;
                VATEntry."Entry No." := NextVATEntryNo;
                OnInsertVATEntriesFromTempOnBeforeVATEntryInsert(VATEntry, TempVATEntry);
                VATEntry.Insert(true);
                NextVATEntryNo := NextVATEntryNo + 1;
                if VATEntry."Unrealized VAT Entry No." = 0 then
                    TempGLEntryVATEntryLink.InsertLinkSelf(GLEntry."Entry No.", VATEntry."Entry No.");
                LinkedAmount += VATEntry.Amount + VATEntry.Base;
                Complete := LinkedAmount = -(DtldCVLedgEntryBuf."Amount (LCY)" + DtldCVLedgEntryBuf."VAT Amount (LCY)");
                LastEntryNo := TempVATEntry."Entry No.";
            until Complete or (TempVATEntry.Next() = 0);

        TempVATEntry.SetRange("Entry No.", FirstEntryNo, LastEntryNo);
        TempVATEntry.DeleteAll();
    end;

    procedure ABSMin(Decimal1: Decimal; Decimal2: Decimal): Decimal
    begin
        if Abs(Decimal1) < Abs(Decimal2) then
            exit(Decimal1);
        exit(Decimal2);
    end;

    local procedure GetApplnRoundPrecision(NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"): Decimal
    var
        ApplnCurrency: Record Currency;
    begin
        if NewCVLedgEntryBuf."Currency Code" = OldCVLedgEntryBuf."Currency Code" then
            exit(0);

        ApplnCurrency.Initialize(NewCVLedgEntryBuf."Currency Code");
        if NewCVLedgEntryBuf."Currency Code" <> '' then
            exit(ApplnCurrency."Appln. Rounding Precision");

        GetGLSetup();
        exit(GLSetup."Appln. Rounding Precision");
    end;

    local procedure GetGLSetup()
    begin
        if GLSetupRead then
            exit;

        GLSetup.Get();
        GLSetupRead := true;

        AddCurrencyCode := GLSetup."Additional Reporting Currency";
    end;

    local procedure ReadGLSetup(var NewGLSetup: Record "General Ledger Setup")
    begin
        NewGLSetup := GLSetup;
    end;

    local procedure CheckSalesExtDocNo(GenJnlLine: Record "Gen. Journal Line")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesExtDocNo(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get();
        if not SalesSetup."Ext. Doc. No. Mandatory" then
            exit;

        if GenJnlLine."Document Type" in
           [GenJnlLine."Document Type"::Invoice,
            GenJnlLine."Document Type"::"Credit Memo",
            GenJnlLine."Document Type"::Payment,
            GenJnlLine."Document Type"::Refund,
            GenJnlLine."Document Type"::" "]
        then
            GenJnlLine.TestField("External Document No.");
    end;

    local procedure CheckPurchExtDocNo(GenJnlLine: Record "Gen. Journal Line"; IsAmtDiff: Boolean)
    var
        PurchSetup: Record "Purchases & Payables Setup";
        OldVendLedgEntry: Record "Vendor Ledger Entry";
        VendorMgt: Codeunit "Vendor Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchExtDocNoProcedure(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        PurchSetup.Get();
        if (not (PurchSetup."Ext. Doc. No. Mandatory" or (GenJnlLine."External Document No." <> ''))) or IsAmtDiff then
            exit;

        GenJnlLine.TestField("External Document No.");
        OldVendLedgEntry.Reset();
        VendorMgt.SetFilterForExternalDocNo(
          OldVendLedgEntry, GenJnlLine."Document Type", GenJnlLine."External Document No.",
          GenJnlLine."Account No.", GenJnlLine."Document Date");
        if not OldVendLedgEntry.IsEmpty() then
            Error(
              PurchaseAlreadyExistsErr,
              GenJnlLine."Document Type", GenJnlLine."External Document No.");
    end;

    local procedure CheckDimValueForDisposal(GenJnlLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
    begin
        if ((GenJnlLine.Amount = 0) or (GenJnlLine."Amount (LCY)" = 0)) and
           (GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::Disposal)
        then begin
            TableID[1] := DimMgt.TypeToTableID1(GenJnlLine."Account Type"::"G/L Account".AsInteger());
            AccNo[1] := AccountNo;
            if not DimMgt.CheckDimValuePosting(TableID, AccNo, GenJnlLine."Dimension Set ID") then
                Error(DimMgt.GetDimValuePostingErr);
        end;
    end;

    procedure SetOverDimErr()
    begin
        OverrideDimErr := true;
    end;

    local procedure CheckGLAccDimError(GenJnlLine: Record "Gen. Journal Line"; GLAccNo: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAccDimError(GenJnlLine, GLAccNo, IsHandled);
        if IsHandled then
            exit;

        if (GenJnlLine.Amount = 0) and (GenJnlLine."Amount (LCY)" = 0) then
            exit;

        TableID[1] := DATABASE::"G/L Account";
        AccNo[1] := GLAccNo;
        if DimMgt.CheckDimValuePosting(TableID, AccNo, GenJnlLine."Dimension Set ID") then
            exit;

        if GenJnlLine."Line No." <> 0 then
            Error(
              DimensionUsedErr,
              GenJnlLine.TableCaption, GenJnlLine."Journal Template Name",
              GenJnlLine."Journal Batch Name", GenJnlLine."Line No.",
              DimMgt.GetDimValuePostingErr);

        Error(DimMgt.GetDimValuePostingErr);
    end;

    local procedure CheckGLAccDirectPosting(GenJnlLine: Record "Gen. Journal Line"; GLAcc: Record "G/L Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAccDirectPosting(GenJnlLine, GLAcc, IsHandled);
        if IsHandled then
            exit;

        if not GenJnlLine."System-Created Entry" then
            if GenJnlLine."Posting Date" = NormalDate(GenJnlLine."Posting Date") then
                GLAcc.TestField("Direct Posting", true);
    end;

    local procedure CalculateCurrentBalance(AccountNo: Code[20]; BalAccountNo: Code[20]; InclVATAmount: Boolean; AmountLCY: Decimal; VATAmount: Decimal)
    begin
        if (AccountNo <> '') and (BalAccountNo <> '') then
            exit;

        if AccountNo = BalAccountNo then
            exit;

        if not InclVATAmount then
            VATAmount := 0;

        if BalAccountNo <> '' then
            CurrentBalance -= AmountLCY + VATAmount
        else
            CurrentBalance += AmountLCY + VATAmount;
    end;

    local procedure GetCurrency(var Currency: Record Currency; CurrencyCode: Code[10])
    begin
        if Currency.Code <> CurrencyCode then begin
            if CurrencyCode = '' then
                Clear(Currency)
            else
                Currency.Get(CurrencyCode);
        end;
    end;

    local procedure CollectAdjustment(var AdjAmount: array[4] of Decimal; Amount: Decimal; AmountAddCurr: Decimal)
    var
        Offset: Integer;
    begin
        Offset := GetAdjAmountOffset(Amount, AmountAddCurr);
        AdjAmount[Offset] += Amount;
        AdjAmount[Offset + 1] += AmountAddCurr;
    end;

    local procedure HandleDtldAdjustment(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; AdjAmount: array[4] of Decimal; TotalAmountLCY: Decimal; TotalAmountAddCurr: Decimal; GLAccNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        if not PostDtldAdjustment(
             GenJnlLine, GLEntry, AdjAmount,
             TotalAmountLCY, TotalAmountAddCurr, GLAccNo,
             GetAdjAmountOffset(TotalAmountLCY, TotalAmountAddCurr))
        then begin
            IsHandled := false;
            OnHandleDtldAdjustmentOnBeforeInitGLEntry(GenJnlLine, GLEntry, TotalAmountLCY, TotalAmountAddCurr, GLAccNo, IsHandled);
            if not IsHandled then
                InitGLEntry(GenJnlLine, GLEntry, GLAccNo, TotalAmountLCY, TotalAmountAddCurr, true, true);
        end;
    end;

    local procedure PostDtldAdjustment(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; AdjAmount: array[4] of Decimal; TotalAmountLCY: Decimal; TotalAmountAddCurr: Decimal; GLAcc: Code[20]; ArrayIndex: Integer): Boolean
    var
        IsHandled: Boolean;
    begin
        if (GenJnlLine."Bal. Account No." <> '') and
           ((AdjAmount[ArrayIndex] <> 0) or (AdjAmount[ArrayIndex + 1] <> 0)) and
           ((TotalAmountLCY + AdjAmount[ArrayIndex] <> 0) or (TotalAmountAddCurr + AdjAmount[ArrayIndex + 1] <> 0))
        then begin
            IsHandled := false;
            OnPostDtldAdjustmentOnBeforeCreateGLEntryBalAcc(GenJnlLine, GLAcc, AdjAmount, ArrayIndex, IsHandled, NextEntryNo);
            if not IsHandled then
                CreateGLEntryBalAcc(
                  GenJnlLine, GLAcc, -AdjAmount[ArrayIndex], -AdjAmount[ArrayIndex + 1],
                  GenJnlLine."Bal. Account Type", GenJnlLine."Bal. Account No.");
            InitGLEntry(GenJnlLine, GLEntry,
              GLAcc, TotalAmountLCY + AdjAmount[ArrayIndex],
              TotalAmountAddCurr + AdjAmount[ArrayIndex + 1], true, true);
            AdjAmount[ArrayIndex] := 0;
            AdjAmount[ArrayIndex + 1] := 0;
            exit(true);
        end;

        exit(false);
    end;

    local procedure GetAdjAmountOffset(Amount: Decimal; AmountACY: Decimal): Integer
    begin
        if (Amount > 0) or (Amount = 0) and (AmountACY > 0) then
            exit(1);
        exit(3);
    end;

    procedure GetNextEntryNo(): Integer
    begin
        exit(NextEntryNo);
    end;

    procedure GetNextTransactionNo(): Integer
    begin
        exit(NextTransactionNo);
    end;

    procedure GetNextVATEntryNo(): Integer
    begin
        exit(NextVATEntryNo);
    end;

    procedure IncrNextVATEntryNo()
    begin
        NextVATEntryNo := NextVATEntryNo + 1;
    end;

    procedure IncrNextEntryNo()
    begin
        NextEntryNo := NextEntryNo + 1;
    end;

    local procedure IsNotPayment(DocumentType: Enum "Gen. Journal Document Type") Result: Boolean
    begin
        Result := DocumentType in [DocumentType::Invoice,
                              DocumentType::"Credit Memo",
                              DocumentType::"Finance Charge Memo",
                              DocumentType::Reminder];

        OnAfterIsNotPayment(DocumentType, Result);
    end;

    local procedure IsTempGLEntryBufEmpty(): Boolean
    begin
        exit(TempGLEntryBuf.IsEmpty);
    end;

    local procedure IsVATAdjustment(EntryType: Enum "Detailed CV Ledger Entry Type"): Boolean
    var
        DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
    begin
        exit(EntryType in [DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Adjustment)",
                           DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Adjustment)",
                           DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)"]);
    end;

    local procedure IsVATExcluded(EntryType: Enum "Detailed CV Ledger Entry Type"): Boolean
    var
        DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
    begin
        exit(EntryType in [DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)",
                           DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)",
                           DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)"]);
    end;

    local procedure UpdateVATEntryTaxDetails(GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; TaxDetail: Record "Tax Detail"; var TaxJurisdiction: Record "Tax Jurisdiction")
    begin
        if TaxDetail."Tax Jurisdiction Code" <> '' then
            TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
        if GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::Settlement then begin
            VATEntry."Tax Group Used" := TaxDetail."Tax Group Code";
            VATEntry."Tax Type" := TaxDetail."Tax Type";
            VATEntry."Tax on Tax" := TaxDetail."Calculate Tax on Tax";
        end;
        VATEntry."Tax Jurisdiction Code" := TaxDetail."Tax Jurisdiction Code";

        OnAfterUpdateVATEntryTaxDetails(VATEntry, TaxDetail);
    end;

    local procedure UpdateGLEntryNo(var GLEntryNo: Integer; var SavedEntryNo: Integer)
    begin
        if SavedEntryNo <> 0 then begin
            GLEntryNo := SavedEntryNo;
            NextEntryNo := NextEntryNo - 1;
            SavedEntryNo := 0;
        end;
    end;

    local procedure UpdateTotalAmounts(var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; DimSetID: Integer; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    var
#if not CLEAN19
        TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary;
#endif
        IsHandled: Boolean;
    begin
#if not CLEAN19
        CopyDimPostBufToInvPostBuf(TempDimPostingBuffer, TempInvoicePostBuffer);
        OnBeforeUpdateTotalAmounts(
          TempInvoicePostBuffer, DimSetID, DtldCVLedgEntryBuf."Amount (LCY)", DtldCVLedgEntryBuf."Additional-Currency Amount", IsHandled,
          DtldCVLedgEntryBuf);
        CopyInvPostBufToDimPostBuf(TempInvoicePostBuffer, TempDimPostingBuffer);
#endif
        OnBeforeUpdateTotalAmountsV19(
          TempDimPostingBuffer, DimSetID, DtldCVLedgEntryBuf."Amount (LCY)", DtldCVLedgEntryBuf."Additional-Currency Amount", IsHandled,
          DtldCVLedgEntryBuf);
        if IsHandled then
            exit;

        with TempDimPostingBuffer do begin
            SetRange("Dimension Set ID", DimSetID);
            if FindFirst() then begin
                Amount += DtldCVLedgEntryBuf."Amount (LCY)";
                "Amount (ACY)" += DtldCVLedgEntryBuf."Additional-Currency Amount";
                Modify();
            end else begin
                Init();
                "Dimension Set ID" := DimSetID;
                Amount := DtldCVLedgEntryBuf."Amount (LCY)";
                "Amount (ACY)" := DtldCVLedgEntryBuf."Additional-Currency Amount";
                Insert();
            end;
        end;
    end;

    local procedure CreateGLEntriesForTotalAmountsUnapply(GenJnlLine: Record "Gen. Journal Line"; var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; GLAccNo: Code[20])
    var
#if not CLEAN19
        TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary;
#endif
        DimMgt: Codeunit DimensionManagement;
    begin
        with TempDimPostingBuffer do begin
            SetRange("Dimension Set ID");
            if FindSet() then
                repeat
                    if (Amount <> 0) or
                       ("Amount (ACY)" <> 0) and (GLSetup."Additional Reporting Currency" <> '')
                    then begin
                        DimMgt.UpdateGenJnlLineDim(GenJnlLine, "Dimension Set ID");
#if not CLEAN19
                        CopyDimPostBufToInvPostBuf(TempDimPostingBuffer, TempInvoicePostBuffer);
                        OnCreateGLEntriesForTotalAmountsUnapplyOnBeforeCreateGLEntry(GenJnlLine, TempInvoicePostBuffer, GLAccNo);
                        CopyInvPostBufToDimPostBuf(TempInvoicePostBuffer, TempDimPostingBuffer);
#endif
                        OnCreateGLEntriesForTotalAmountsUnapplyOnBeforeCreateGLEntryV19(GenJnlLine, TempDimPostingBuffer, GLAccNo);
                        CreateGLEntry(GenJnlLine, GLAccNo, Amount, "Amount (ACY)", true);
                    end;
                until Next() = 0;
        end;
    end;

    local procedure CreateGLEntriesForTotalAmounts(GenJnlLine: Record "Gen. Journal Line"; var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; AdjAmountBuf: array[4] of Decimal; SavedEntryNo: Integer; GLAccNo: Code[20]; LedgEntryInserted: Boolean)
    var
#if not CLEAN19
        TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary;
#endif
        DimMgt: Codeunit DimensionManagement;
        GLEntryInserted: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN19
        CopyDimPostBufToInvPostBuf(TempDimPostingBuffer, TempInvoicePostBuffer);
        OnBeforeCreateGLEntriesForTotalAmounts(TempInvoicePostBuffer, GenJnlLine, GLAccNo, IsHandled);
        CopyInvPostBufToDimPostBuf(TempInvoicePostBuffer, TempDimPostingBuffer);
#endif
        OnBeforeCreateGLEntriesForTotalAmountsV19(TempDimPostingBuffer, GenJnlLine, GLAccNo, IsHandled);
        if IsHandled then
            exit;

        GLEntryInserted := false;

        with TempDimPostingBuffer do begin
            Reset();
            if FindSet() then
                repeat
                    if (Amount <> 0) or ("Amount (ACY)" <> 0) and (AddCurrencyCode <> '') then begin
                        DimMgt.UpdateGenJnlLineDim(GenJnlLine, "Dimension Set ID");
#if not CLEAN19
                        CopyDimPostBufToInvPostBuf(TempDimPostingBuffer, TempInvoicePostBuffer);
                        OnBeforeCreateGLEntryForTotalAmountsForInvPostBuf(GenJnlLine, TempInvoicePostBuffer, GLAccNo);
                        CopyInvPostBufToDimPostBuf(TempInvoicePostBuffer, TempDimPostingBuffer);
#endif
                        OnBeforeCreateGLEntryForTotalAmountsForDimPostBuf(GenJnlLine, TempDimPostingBuffer, GLAccNo);
                        CreateGLEntryForTotalAmounts(GenJnlLine, Amount, "Amount (ACY)", AdjAmountBuf, SavedEntryNo, GLAccNo);
                        GLEntryInserted := true;
                    end;
                until Next() = 0;
        end;

        if not GLEntryInserted and LedgEntryInserted then
            CreateGLEntryForTotalAmounts(GenJnlLine, 0, 0, AdjAmountBuf, SavedEntryNo, GLAccNo);
    end;

#if not CLEAN19
    local procedure CopyDimPostBufToInvPostBuf(var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    var
        DimSetID: Integer;
    begin
        DimSetID := TempDimPostingBuffer."Dimension Set ID";
        TempInvoicePostBuffer.DeleteAll();
        TempDimPostingBuffer.Reset();
        if TempDimPostingBuffer.Find('-') then
            repeat
                TempInvoicePostBuffer.Init();
                TempInvoicePostBuffer."Dimension Set ID" := TempDimPostingBuffer."Dimension Set ID";
                TempInvoicePostBuffer.Amount := TempDimPostingBuffer.Amount;
                TempInvoicePostBuffer."Amount (ACY)" := TempDimPostingBuffer."Amount (ACY)";
                TempInvoicePostBuffer.Insert();
            until TempDimPostingBuffer.Next() = 0;
        if DimSetID <> 0 then begin
            TempInvoicePostBuffer."Dimension Set ID" := DimSetID;
            TempInvoicePostBuffer.Find();
        end;
    end;
#endif

#if not CLEAN19
    local procedure CopyInvPostBufToDimPostBuf(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary)
    var
        DimSetID: Integer;
    begin
        DimSetID := TempInvoicePostBuffer."Dimension Set ID";
        TempDimPostingBuffer.DeleteAll();
        TempInvoicePostBuffer.Reset();
        if TempInvoicePostBuffer.Find('-') then
            repeat
                TempDimPostingBuffer.Init();
                TempDimPostingBuffer."Dimension Set ID" := TempInvoicePostBuffer."Dimension Set ID";
                TempDimPostingBuffer.Amount := TempInvoicePostBuffer.Amount;
                TempDimPostingBuffer."Amount (ACY)" := TempInvoicePostBuffer."Amount (ACY)";
                TempDimPostingBuffer.Insert();
            until TempInvoicePostBuffer.Next() = 0;
        if DimSetID <> 0 then begin
            TempDimPostingBuffer."Dimension Set ID" := DimSetID;
            TempDimPostingBuffer.Find();
        end;
    end;
#endif

    local procedure CreateGLEntryForTotalAmounts(GenJnlLine: Record "Gen. Journal Line"; Amount: Decimal; AmountACY: Decimal; AdjAmountBuf: array[4] of Decimal; var SavedEntryNo: Integer; GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        IsHandled: Boolean;
    begin
        HandleDtldAdjustment(GenJnlLine, GLEntry, AdjAmountBuf, Amount, AmountACY, GLAccNo);
        GLEntry."Bal. Account Type" := GenJnlLine."Bal. Account Type";
        GLEntry."Bal. Account No." := GenJnlLine."Bal. Account No.";
        UpdateGLEntryNo(GLEntry."Entry No.", SavedEntryNo);

        IsHandled := false;
        OnCreateGLEntryForTotalAmountsOnBeforeInsertGLEntry(GenJnlLine, GLEntry, IsHandled);
        if IsHandled then
            exit;

        InsertGLEntry(GenJnlLine, GLEntry, true);
    end;

    local procedure SetAddCurrForUnapplication(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
        with DtldCVLedgEntryBuf do
            if not ("Entry Type" in ["Entry Type"::Application, "Entry Type"::"Unrealized Loss",
                                     "Entry Type"::"Unrealized Gain", "Entry Type"::"Realized Loss",
                                     "Entry Type"::"Realized Gain", "Entry Type"::"Correction of Remaining Amount"])
            then
                if ("Entry Type" = "Entry Type"::"Appln. Rounding") or
                   ((AddCurrencyCode <> '') and (AddCurrencyCode = "Currency Code"))
                then
                    "Additional-Currency Amount" := Amount
                else
                    "Additional-Currency Amount" := CalcAddCurrForUnapplication("Posting Date", "Amount (LCY)");
    end;

    [Scope('OnPrem')]
    procedure CalcAppliedAmounts(var EntryBuf1: Record "CV Ledger Entry Buffer"; var EntryBuf2: Record "CV Ledger Entry Buffer"; var AppliedAmount1: Decimal; var AppliedAmountLCY: Decimal; var AppliedAmount2: Decimal; ApplnRoundingPrecision: Decimal; Factor: Decimal)
    var
        UseOrigCurrencyFactor: Boolean;
        RemainingAmt: Decimal;
        RemAmt1: Decimal;
        RemAmt2: Decimal;
    begin
        RemAmt1 := GetRemAmount(EntryBuf1, ApplnRoundingPrecision);
        RemAmt2 := GetRemAmount(EntryBuf2, ApplnRoundingPrecision);
        UseOrigCurrencyFactor := EntryBuf1."Original Currency Factor" <>
          RoundCurrencyFactor(CurrExchRate.ExchangeRate(EntryBuf1."Posting Date", EntryBuf1."Currency Code"));
        if UseOrigCurrencyFactor then
            RemainingAmt := Round(RemAmt2 * EntryBuf1."Original Currency Factor")
        else
            RemainingAmt :=
              CurrExchRate.ExchangeAmount(RemAmt2, EntryBuf2."Currency Code", EntryBuf1."Currency Code", EntryBuf2."Posting Date");
        if Abs(RemAmt1) < Abs(RemainingAmt) then begin
            AppliedAmount1 := Factor * RemAmt1;
            if UseOrigCurrencyFactor then
                AppliedAmount2 := Round(AppliedAmount1 / EntryBuf1."Original Currency Factor")
            else
                AppliedAmount2 :=
                  CurrExchRate.ExchangeAmount(AppliedAmount1, EntryBuf1."Currency Code", EntryBuf2."Currency Code", EntryBuf2."Posting Date");
        end else begin
            AppliedAmount1 := Factor * -RemainingAmt;
            AppliedAmount2 := Factor * -RemAmt2;
        end;
        AppliedAmountLCY := AppliedAmount2;
    end;

    local procedure RoundCurrencyFactor(CurrencyFactor: Decimal) RoundedCurrencyFactor: Decimal
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        with CVLedgerEntryBuffer do begin
            if FindLast then;
            "Entry No." += 1;
            "Original Currency Factor" := CurrencyFactor;
            Insert;
            Find;
            RoundedCurrencyFactor := "Original Currency Factor";
            Delete;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetRemAmount(EntryBuf: Record "CV Ledger Entry Buffer"; ApplnRoundingPrecision: Decimal) RemainingAmount: Decimal
    begin
        if EntryBuf."Amount to Apply" = 0 then
            RemainingAmount := EntryBuf."Remaining Amount"
        else begin
            if Abs(EntryBuf."Remaining Amount") < Abs(EntryBuf."Amount to Apply") then
                RemainingAmount := EntryBuf."Remaining Amount"
            else
                RemainingAmount := EntryBuf."Amount to Apply";

            if (Abs(EntryBuf."Remaining Amount" - EntryBuf."Amount to Apply") < ApplnRoundingPrecision) and
               (ApplnRoundingPrecision <> 0)
            then
                RemainingAmount := RemainingAmount - (EntryBuf."Remaining Amount" - EntryBuf."Amount to Apply");
        end;
    end;

    local procedure InsertRUGLEntry(GenJnlLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; BalAccountNo: Code[20]; IgnoreGLSetup: Boolean; CalcAddCurrResiduals: Boolean; RUCorrection: Boolean): Boolean
    var
        GLEntrySrc: Record "G/L Entry";
        SavedCorrection: Boolean;
    begin
        SavedCorrection := GenJnlLine.Correction;
        if RUCorrection then
            GenJnlLine.Correction := true;
        GLEntrySrc := GLEntry;
        GLEntry."Bal. Account No." := BalAccountNo;
        InsertGLEntry(GenJnlLine, GLEntry, CalcAddCurrResiduals);
        if (BalAccountNo <> '') and (IgnoreGLSetup or GLSetup."Enable Russian Accounting") then begin
            GLEntry := GLEntrySrc;
            GLEntry."Entry No." := NextEntryNo;
            GLEntry."Bal. Account No." := GLEntry."G/L Account No.";
            GLEntry."G/L Account No." := BalAccountNo;
            GLEntry.Amount := -GLEntry.Amount;
            GLEntry."Additional-Currency Amount" := -GLEntry."Additional-Currency Amount";
            GLEntry."VAT Amount" := -GLEntry."VAT Amount";
            InsertGLEntry(GenJnlLine, GLEntry, CalcAddCurrResiduals);
            GenJnlLine.Correction := SavedCorrection;
            exit(true);
        end;
        GenJnlLine.Correction := SavedCorrection;
    end;

    [Scope('OnPrem')]
    procedure SpecialRunWithCheck(var GenJnlLine2: Record "Gen. Journal Line"): Integer
    begin
        ThisIsSpecialRun := true;
        RunWithCheck(GenJnlLine2);
        ThisIsSpecialRun := false;
        exit(GLEntryNo);
    end;

    [Scope('OnPrem')]
    procedure AdjustVATAmount(var VATEntry: Record "VAT Entry"; VATPart: Decimal; var VATBase: Decimal; VATAmount: Decimal; var VATBaseAddCurr: Decimal; VATAmountAddCurr: Decimal; Remaining: Boolean)
    var
        TotalVAT: Decimal;
    begin
        if Remaining then
            TotalVAT := Round((VATEntry."Remaining Unrealized Amount" + VATEntry."Remaining Unrealized Base") * VATPart)
        else
            TotalVAT := Round((VATEntry."Unrealized Amount" + VATEntry."Unrealized Base") * VATPart);
        if TotalVAT <> VATBase + VATAmount then
            VATBase := TotalVAT - VATAmount;

        if Remaining then
            TotalVAT := Round((VATEntry."Add.-Curr. Rem. Unreal. Amount" + VATEntry."Add.-Curr. Rem. Unreal. Base") * VATPart,
                AddCurrency."Amount Rounding Precision")
        else
            TotalVAT := Round((VATEntry."Add.-Currency Unrealized Amt." + VATEntry."Add.-Currency Unrealized Base") * VATPart,
                AddCurrency."Amount Rounding Precision");
        if TotalVAT <> VATAmountAddCurr + VATBaseAddCurr then
            VATBaseAddCurr := TotalVAT - VATAmountAddCurr;
    end;

    [Scope('OnPrem')]
    procedure SummarizeGainLoss(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var CorrDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; Unapply: Boolean)
    var
        Currency: Record Currency;
        DtldCVLedgEntryBuf2: Record "Detailed CV Ledg. Entry Buffer" temporary;
        RealizedForCustEntryNo: Record "Integer" temporary;
        AmountLCY: Decimal;
        EntryNo: Integer;
        CurrencyCode: Code[20];
        CanBeSummarized: Boolean;
        DeleteEntry: Boolean;
        Completed: Boolean;
        DtldCVLedgEntryNo: Integer;
    begin
        GLSetup.Get();
        if not GLSetup."Summarize Gains/Losses" then
            exit;

        CorrDtldCVLedgEntryBuf.DeleteAll();
        DtldCVLedgEntryBuf.Reset();
        DtldCVLedgEntryBuf.SetCurrentKey("CV Ledger Entry No.", "Entry Type");
        DtldCVLedgEntryBuf.SetRange(
          "Entry Type",
          DtldCVLedgEntryBuf."Entry Type"::"Realized Loss",
          DtldCVLedgEntryBuf."Entry Type"::"Realized Gain");
        if DtldCVLedgEntryBuf.FindSet() then
            repeat
                DtldCVLedgEntryBuf2 := DtldCVLedgEntryBuf;
                DtldCVLedgEntryBuf2.Insert();
            until DtldCVLedgEntryBuf.Next() = 0;
        DtldCVLedgEntryBuf2.SetCurrentKey("CV Ledger Entry No.");
        DtldCVLedgEntryBuf.SetFilter(
          "Entry Type", '%1|%2|%3|%4',
          DtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss",
          DtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain",
          DtldCVLedgEntryBuf."Entry Type"::"Realized Loss",
          DtldCVLedgEntryBuf."Entry Type"::"Realized Gain");
        CurrencyCode := '';
        if DtldCVLedgEntryBuf.Find('+') then
            repeat
                if not DtldCVLedgEntryBuf."Prepmt. Diff." then begin
                    if EntryNo <> DtldCVLedgEntryBuf."CV Ledger Entry No." then begin
                        if CurrencyCode <> DtldCVLedgEntryBuf."Currency Code" then begin
                            CurrencyCode := DtldCVLedgEntryBuf."Currency Code";
                            Currency.Get(CurrencyCode);
                            CanBeSummarized :=
                              (Currency."Unrealized Gains Acc." = Currency."Realized Gains Acc.") and
                              (Currency."Unrealized Losses Acc." = Currency."Realized Losses Acc.");
                        end;
                        if CanBeSummarized then begin
                            CorrDtldCVLedgEntryBuf := DtldCVLedgEntryBuf;
                            CorrDtldCVLedgEntryBuf.Insert();
                            if DtldCVLedgEntryBuf."Entry Type" in [DtldCVLedgEntryBuf."Entry Type"::"Realized Loss",
                                                                   DtldCVLedgEntryBuf."Entry Type"::"Realized Gain"]
                            then begin
                                RealizedForCustEntryNo.Number := DtldCVLedgEntryBuf."CV Ledger Entry No.";
                                if RealizedForCustEntryNo.Insert() then;
                            end else begin
                                DtldCVLedgEntryBuf2.SetRange("CV Ledger Entry No.", DtldCVLedgEntryBuf."CV Ledger Entry No.");
                                if not DtldCVLedgEntryBuf2.FindFirst then begin
                                    CorrDtldCVLedgEntryBuf."Entry Type" := CorrDtldCVLedgEntryBuf."Entry Type"::"Realized Gain";
                                    CorrDtldCVLedgEntryBuf.Modify();
                                end;
                            end;
                        end;
                    end;
                end;
            until DtldCVLedgEntryBuf.Next(-1) = 0;

        CorrDtldCVLedgEntryBuf.SetCurrentKey("CV Ledger Entry No.", "Entry Type");
        if CorrDtldCVLedgEntryBuf.FindSet() then begin
            Completed := false;
            AmountLCY := 0;
            EntryNo := CorrDtldCVLedgEntryBuf."CV Ledger Entry No.";
            DtldCVLedgEntryNo := CorrDtldCVLedgEntryBuf."Entry No.";

            DtldCVLedgEntryBuf2.Reset();
            DtldCVLedgEntryBuf2.DeleteAll();
            repeat
                DeleteEntry := false;
                if EntryNo <> CorrDtldCVLedgEntryBuf."CV Ledger Entry No." then begin
                    DtldCVLedgEntryBuf.Get(DtldCVLedgEntryNo);
                    DtldCVLedgEntryBuf2 := DtldCVLedgEntryBuf;
                    DtldCVLedgEntryBuf2."Amount (LCY)" := AmountLCY;
                    DtldCVLedgEntryBuf2.Insert();

                    AmountLCY := 0;
                    EntryNo := CorrDtldCVLedgEntryBuf."CV Ledger Entry No.";
                end;
                AmountLCY := AmountLCY + CorrDtldCVLedgEntryBuf."Amount (LCY)";
                CorrDtldCVLedgEntryBuf."Amount (LCY)" := 0;

                if CorrDtldCVLedgEntryBuf."Entry Type" in
                   [CorrDtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss",
                    CorrDtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain"]
                then
                    DeleteEntry := not RealizedForCustEntryNo.Get(CorrDtldCVLedgEntryBuf."CV Ledger Entry No.");

                if DeleteEntry then
                    CorrDtldCVLedgEntryBuf.Delete
                else
                    CorrDtldCVLedgEntryBuf.Modify();

                DtldCVLedgEntryNo := CorrDtldCVLedgEntryBuf."Entry No.";
                Completed := CorrDtldCVLedgEntryBuf.Next() = 0;
                if Completed then begin
                    DtldCVLedgEntryBuf.Get(DtldCVLedgEntryNo);
                    DtldCVLedgEntryBuf2 := DtldCVLedgEntryBuf;
                    DtldCVLedgEntryBuf2."Amount (LCY)" := AmountLCY;
                    DtldCVLedgEntryBuf2.Insert();
                end;
            until Completed;

            if DtldCVLedgEntryBuf2.FindSet() then
                repeat
                    CorrDtldCVLedgEntryBuf.Get(DtldCVLedgEntryBuf2."Entry No.");
                    CorrDtldCVLedgEntryBuf."Amount (LCY)" := DtldCVLedgEntryBuf2."Amount (LCY)";
                    if not GLSetup."Currency Adjmt with Correction" then
                        if (CorrDtldCVLedgEntryBuf."Amount (LCY)" > 0) xor Unapply then
                            CorrDtldCVLedgEntryBuf."Entry Type" := CorrDtldCVLedgEntryBuf."Entry Type"::"Realized Gain"
                        else
                            CorrDtldCVLedgEntryBuf."Entry Type" := CorrDtldCVLedgEntryBuf."Entry Type"::"Realized Loss";
                    CorrDtldCVLedgEntryBuf.Modify();
                until DtldCVLedgEntryBuf2.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateGainLoss(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var CorrDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
        if CorrDtldCVLedgEntryBuf.Get(DtldCVLedgEntryBuf."Entry No.") then begin
            DtldCVLedgEntryBuf."Entry Type" := CorrDtldCVLedgEntryBuf."Entry Type";
            DtldCVLedgEntryBuf."Amount (LCY)" := CorrDtldCVLedgEntryBuf."Amount (LCY)";
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateCustUnapplyBuffer(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; NextDtldLedgEntryNo: Integer)
    begin
        if DtldCustLedgEntry.FindSet() then
            repeat
                DtldCVLedgEntryBuf.TransferFields(DtldCustLedgEntry);
                DtldCVLedgEntryBuf."Entry No." := NextDtldLedgEntryNo;
                DtldCVLedgEntryBuf."Amount (LCY)" := -DtldCVLedgEntryBuf."Amount (LCY)";
                DtldCVLedgEntryBuf.Insert();
                NextDtldLedgEntryNo := NextDtldLedgEntryNo + 1;
            until DtldCustLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateVendUnapplyBuffer(var DtldCustLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; NextDtldLedgEntryNo: Integer)
    begin
        if DtldCustLedgEntry.FindSet() then
            repeat
                DtldCVLedgEntryBuf.TransferFields(DtldCustLedgEntry);
                DtldCVLedgEntryBuf."Entry No." := NextDtldLedgEntryNo;
                DtldCVLedgEntryBuf."Amount (LCY)" := -DtldCVLedgEntryBuf."Amount (LCY)";
                DtldCVLedgEntryBuf.Insert();
                NextDtldLedgEntryNo := NextDtldLedgEntryNo + 1;
            until DtldCustLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure FindAdjustingVATEntry(var VATEntry: Record "VAT Entry"; CorrDocDate: Date)
    var
        AdjustingVATEntry: Record "VAT Entry";
    begin
        AdjustingVATEntry.SetCurrentKey("Unrealized VAT Entry No.");
        AdjustingVATEntry.SetRange("Unrealized VAT Entry No.", VATEntry."Unrealized VAT Entry No.");
        AdjustingVATEntry.SetRange("Corrected Document Date", CalcDate('<-CM>', CorrDocDate), CalcDate('<CM>', CorrDocDate));
        if AdjustingVATEntry.FindFirst then
            VATEntry."Adjusted VAT Entry No." := AdjustingVATEntry."Entry No.";
    end;

    [Scope('OnPrem')]
    procedure UpdateTaxDiff(GenJnlLine: Record "Gen. Journal Line")
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        with GenJnlLine do
            case "Object Type" of
                "Object Type"::Customer:
                    begin
                        DtldCustLedgEntry.Get("Tax. Diff. Dtld. Entry No.");
                        if DtldCustLedgEntry."Tax Diff. Transaction No." <> 0 then
                            Error(PostedTaxDiffAlreadyExistErr, DtldCustLedgEntry."Tax Diff. Transaction No.");
                        DtldCustLedgEntry."Tax Diff. Transaction No." := NextTransactionNo;
                        DtldCustLedgEntry.Modify();
                    end;
                "Object Type"::Vendor:
                    begin
                        DtldVendLedgEntry.Get("Tax. Diff. Dtld. Entry No.");
                        if DtldVendLedgEntry."Tax Diff. Transaction No." <> 0 then
                            Error(PostedTaxDiffAlreadyExistErr, DtldVendLedgEntry."Tax Diff. Transaction No.");
                        DtldVendLedgEntry."Tax Diff. Transaction No." := NextTransactionNo;
                        DtldVendLedgEntry.Modify();
                    end;
            end;
    end;

    local procedure CalcTaxAccRealizedGainLossAmt(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; GenJnlLine: Record "Gen. Journal Line"; RealizedGainLossAmount: Decimal; AppliedAmount: Decimal; AppliedAmountLCY: Decimal)
    var
        TaxAccRealizedGainLossAmt: Decimal;
    begin
        if GLSetup."Cancel Prepmt. Adjmt. in TA" or (CVLedgEntryBuf."Currency Code" = '') or not CVLedgEntryBuf.Prepayment then
            exit;

        TaxAccRealizedGainLossAmt :=
          Round(AppliedAmountLCY - AppliedAmount / CVLedgEntryBuf."Adjusted Currency Factor");

        TaxAccRealizedGainLossAmt := -TaxAccRealizedGainLossAmt + RealizedGainLossAmount;
        if TaxAccRealizedGainLossAmt = 0 then
            exit;

        DtldCVLedgEntryBuf.InitFromGenJnlLine(GenJnlLine);
        DtldCVLedgEntryBuf.CopyFromCVLedgEntryBuf(CVLedgEntryBuf);
        DtldCVLedgEntryBuf."Prepmt. Diff. in TA" := true;
        if TaxAccRealizedGainLossAmt < 0 then begin
            DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::"Realized Loss";
            DtldCVLedgEntryBuf."Amount (LCY)" := TaxAccRealizedGainLossAmt;
            DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, false);
        end else begin
            DtldCVLedgEntryBuf."Entry Type" := DtldCVLedgEntryBuf."Entry Type"::"Realized Gain";
            DtldCVLedgEntryBuf."Amount (LCY)" := TaxAccRealizedGainLossAmt;
            DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, false);
        end;
    end;

    [Scope('OnPrem')]
    procedure PostPrepmtDiffRealizedVAT(GenJnlLine: Record "Gen. Journal Line"; UnrealizedVATEntry: Record "VAT Entry")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        if VATSettlementMgt.VATIsPostponed(UnrealizedVATEntry, 0, GenJnlLine."Posting Date") then
            exit;

        case GenJnlLine."Source Type" of
            GenJnlLine."Source Type"::Vendor:
                begin
                    VendLedgEntry.Init();
                    VendLedgEntry."Transaction No." := NextTransactionNo;
                    VendLedgEntry."Remaining Amt. (LCY)" := 0;
                    VendLedgEntry."Amount (LCY)" := UnrealizedVATEntry."Unrealized Base" + UnrealizedVATEntry."Unrealized Amount";
                    VendLedgEntry.Open := false;
                    VendUnrealizedVAT(
                      GenJnlLine, VendLedgEntry, GenJnlLine.Amount, UnrealizedVATEntry."Entry No.", 1, GenJnlLine."VAT Transaction No.", 0);
                end;
            GenJnlLine."Source Type"::Customer:
                begin
                    CustLedgEntry.Init();
                    CustLedgEntry."Transaction No." := NextTransactionNo;
                    CustLedgEntry."Remaining Amt. (LCY)" := 0;
                    CustLedgEntry."Amount (LCY)" := UnrealizedVATEntry."Unrealized Base" + UnrealizedVATEntry."Unrealized Amount";
                    CustLedgEntry.Open := false;
                    CustUnrealizedVAT(GenJnlLine, CustLedgEntry, GenJnlLine.Amount, UnrealizedVATEntry."Entry No.", 1, 0);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure TransferCVLedgerEntryBuf(CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
        InitialCVLedgEntryBuf := CVLedgEntryBuf;
    end;

    [Scope('OnPrem')]
    procedure SetCVLedgEntryForVAT(TransactionNo: Integer; CVLedgEntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Reset();
        VATEntry.SetCurrentKey("Transaction No.", "CV Ledg. Entry No.");
        VATEntry.SetRange("Transaction No.", TransactionNo);
        VATEntry.SetRange("CV Ledg. Entry No.", 0);
        VATEntry.ModifyAll("CV Ledg. Entry No.", CVLedgEntryNo);
    end;

    [Scope('OnPrem')]
    procedure IsCheckFinVoided(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"): Boolean
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccLedgEntry2: Record "Bank Account Ledger Entry";
        CheckLedgEntry3: Record "Check Ledger Entry";
        TransactionNo: Integer;
    begin
        DtldCVLedgEntryBuf.Reset();
        DtldCVLedgEntryBuf.SetCurrentKey("CV Ledger Entry No.", "Entry Type");
        DtldCVLedgEntryBuf.SetRange("Entry Type", DtldCVLedgEntryBuf."Entry Type"::Application);
        DtldCVLedgEntryBuf.SetRange(Prepayment, true);
        if DtldCVLedgEntryBuf.FindSet() then
            repeat
                case GenJnlLine."Account Type" of
                    GenJnlLine."Account Type"::Customer:
                        begin
                            CustLedgEntry.Get(DtldCVLedgEntryBuf."CV Ledger Entry No.");
                            TransactionNo := CustLedgEntry."Transaction No.";
                        end;
                    GenJnlLine."Account Type"::Vendor:
                        begin
                            VendLedgEntry.Get(DtldCVLedgEntryBuf."CV Ledger Entry No.");
                            TransactionNo := VendLedgEntry."Transaction No.";
                        end;
                end;
                BankAccLedgEntry2.Reset();
                BankAccLedgEntry2.SetCurrentKey("Transaction No.");
                BankAccLedgEntry2.SetRange("Transaction No.", TransactionNo);
                if BankAccLedgEntry2.FindSet() then
                    repeat
                        CheckLedgEntry3.Reset();
                        CheckLedgEntry3.SetCurrentKey("Bank Account Ledger Entry No.");
                        CheckLedgEntry3.SetRange("Bank Account Ledger Entry No.", BankAccLedgEntry2."Entry No.");
                        CheckLedgEntry3.SetRange("Entry Status", CheckLedgEntry3."Entry Status"::"Financially Voided");
                        if not CheckLedgEntry3.IsEmpty() then
                            exit(true);
                    until BankAccLedgEntry2.Next() = 0;
            until DtldCVLedgEntryBuf.Next() = 0;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    [Scope('OnPrem')]
    procedure IsVATAgentVATPayment(GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        Vend: Record Vendor;
    begin
        if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment) and
           (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor)
        then begin
            Vend.Get(GenJnlLine."Account No.");
            exit(Vend."VAT Agent");
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure UpdateVATAgentVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        VendLedgEntry."Entry No." := NextEntryNo;
        VendLedgEntry."Currency Code" := '';
        VendLedgEntry."Applies-to Doc. Type" := VendLedgEntry."Applies-to Doc. Type"::" ";
        VendLedgEntry."Applies-to Doc. No." := '';
        VendLedgEntry."Applies-to ID" := '';
        VendLedgEntry.Open := true;
        VendLedgEntry."Closed by Entry No." := 0;
        VendLedgEntry."Closed at Date" := 0D;
        VendLedgEntry."Closed by Amount" := 0;
        VendLedgEntry."Closed by Amount (LCY)" := 0;
        VendLedgEntry."Closed by Currency Code" := '';
        VendLedgEntry."Closed by Currency Amount" := 0;
        VendLedgEntry."Adjusted Currency Factor" := 1;
        VendLedgEntry."Original Currency Factor" := 1;
        VendLedgEntry."Amount to Apply" := 0;
        VendLedgEntry."Prepmt. Diff. Appln. Entry No." := 0;
    end;

    local procedure InsertVATAgentVATPmtGLEntry(GenJnlLine: Record "Gen. Journal Line"; PmtAmount: Decimal)
    var
        LCYCurrency: Record Currency;
        FCYCurrency: Record Currency;
        VendAgrmt: Record "Vendor Agreement";
        Vend: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        VATPrepmtPost: Codeunit "VAT Prepayment-Post";
        VATAgentVATPmtAmtFCY: Decimal;
    begin
        VATAgentVATPmtAmount := 0;
        if VATAgentVATPayment then begin
            NextEntryNo := NextEntryNo - 1;
            LCYCurrency.InitRoundingPrecision;
            if GenJnlLine."Currency Code" <> '' then
                FCYCurrency.Get(GenJnlLine."Currency Code")
            else
                FCYCurrency.InitRoundingPrecision;
            if GenJnlLine."Agreement No." <> '' then begin
                VendAgrmt.Get(GenJnlLine."Account No.", GenJnlLine."Agreement No.");
                VATPostingSetup.Get(VendAgrmt."VAT Bus. Posting Group", VendAgrmt."VAT Agent Prod. Posting Group");
            end else begin
                Vend.Get(GenJnlLine."Account No.");
                VATPostingSetup.Get(Vend."VAT Bus. Posting Group", Vend."VAT Agent Prod. Posting Group");
            end;
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
            GenJnlLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
            GenJnlLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
            GenJnlLine."Currency Code" := '';
            VATAgentVATPmtAmount :=
              Round(
                PmtAmount * VATPostingSetup."VAT %" / 100,
                LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection);
            GenJnlLine."Amount (LCY)" := PmtAmount + VATAgentVATPmtAmount;
            GenJnlLine."VAT Base Amount (LCY)" := GenJnlLine."Amount (LCY)";

            VATAgentVATPmtAmtFCY :=
              Round(
                GenJnlLine.Amount * VATPostingSetup."VAT %" / 100,
                FCYCurrency."Amount Rounding Precision", FCYCurrency.VATRoundingDirection);
            GenJnlLine.Amount := GenJnlLine.Amount + VATAgentVATPmtAmtFCY;
            GenJnlLine."VAT Base Amount" := GenJnlLine.Amount;
            VATPrepmtPost.InsertVATAgentPurchInvoice(GenJnlLine, VATAgentVATPmtAmount, VATAgentVATPmtAmtFCY);

            InitVAT(GenJnlLine, GLEntry, VATPostingSetup);
            PostVAT(GenJnlLine, GLEntry, VATPostingSetup);
        end;
    end;

    [Scope('OnPrem')]
    procedure InitVATAgentDtldVendLedgEntry(GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        DtldVendLedgEntryNo: Integer;
    begin
        DtldVendLedgEntry.Reset();
        if DtldVendLedgEntry.FindLast then
            DtldVendLedgEntryNo := DtldVendLedgEntry."Entry No." + 1
        else
            DtldVendLedgEntryNo := 1;

        DtldVendLedgEntry.Init();
        DtldVendLedgEntry."Entry No." := DtldVendLedgEntryNo;
        DtldVendLedgEntry."Vendor Ledger Entry No." := VendLedgEntry."Entry No.";
        DtldVendLedgEntry."Entry Type" := DtldVendLedgEntry."Entry Type"::"Initial Entry";
        DtldVendLedgEntry."Posting Date" := VendLedgEntry."Posting Date";
        DtldVendLedgEntry."Document Type" := VendLedgEntry."Document Type";
        DtldVendLedgEntry."Document No." := VendLedgEntry."Document No.";
        DtldVendLedgEntry.Amount := VATAgentVATPmtAmount;
        DtldVendLedgEntry."Amount (LCY)" := VATAgentVATPmtAmount;
        DtldVendLedgEntry."Vendor No." := VendLedgEntry."Vendor No.";
        DtldVendLedgEntry."Currency Code" := VendLedgEntry."Currency Code";
        DtldVendLedgEntry."User ID" := VendLedgEntry."User ID";
        DtldVendLedgEntry."Initial Entry Due Date" := VendLedgEntry."Due Date";
        DtldVendLedgEntry."Initial Entry Posting Date" := VendLedgEntry."Posting Date";
        DtldVendLedgEntry."Initial Entry Global Dim. 1" := VendLedgEntry."Global Dimension 1 Code";
        DtldVendLedgEntry."Initial Entry Global Dim. 2" := VendLedgEntry."Global Dimension 2 Code";
        DtldVendLedgEntry."Initial Document Type" := VendLedgEntry."Document Type";
        DtldVendLedgEntry."Initial Entry Positive" := VATAgentVATPmtAmount > 0;
        DtldVendLedgEntry."Agreement No." := VendLedgEntry."Agreement No.";
        DtldVendLedgEntry."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        DtldVendLedgEntry."Reason Code" := GenJnlLine."Reason Code";
        DtldVendLedgEntry."Source Code" := GenJnlLine."Source Code";
        DtldVendLedgEntry."Transaction No." := VendLedgEntry."Transaction No.";
        DtldVendLedgEntry."Vendor Posting Group" := GenJnlLine."Posting Group";
    end;

    [Scope('OnPrem')]
    procedure PostVATAllocDepreciation(GenJnlLine: Record "Gen. Journal Line"; VATAllocLine: Record "VAT Allocation Line"; DeprAmount: Decimal; DeprBookCode: Code[10])
    var
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        FAPostingGr: Record "FA Posting Group";
        GLEntry: Record "G/L Entry";
        GLAcc: Record "G/L Account";
    begin
        FA.Get(VATAllocLine."FA No.");
        FADeprBook.Get(FA."No.", DeprBookCode);
        FAPostingGr.Get(FADeprBook."FA Posting Group");
        FAPostingGr.TestField("Accum. Depreciation Account");
        FAPostingGr.TestField("Depreciation Expense Acc.");

        InitGLEntry(GenJnlLine, GLEntry,
          FAPostingGr."Accum. Depreciation Account", DeprAmount, 0, false, true);
        GLAcc.Get(GLEntry."G/L Account No.");
        GLEntry.Description :=
          CopyStr(GenJnlLine.Description + ' ' + GLAcc.Name, 1, MaxStrLen(GLEntry.Description));
        GLEntry."Bal. Account Type" := GLEntry."Bal. Account Type"::"G/L Account";
        GLEntry."Bal. Account No." := FAPostingGr."Depreciation Expense Acc.";
        GLEntry."Source Type" := GLEntry."Source Type"::"Fixed Asset";
        GLEntry."Source No." := FA."No.";
        InsertGLEntry(GenJnlLine, GLEntry, true);

        InitGLEntry(GenJnlLine, GLEntry,
          FAPostingGr."Depreciation Expense Acc.", -DeprAmount, 0, false, true);
        GLAcc.Get(GLEntry."G/L Account No.");
        GLEntry.Description :=
          CopyStr(GenJnlLine.Description + ' ' + GLAcc.Name, 1, MaxStrLen(GLEntry.Description));
        GLEntry."Bal. Account Type" := GLEntry."Bal. Account Type"::"G/L Account";
        GLEntry."Bal. Account No." := FAPostingGr."Accum. Depreciation Account";
        GLEntry."Source Type" := GLEntry."Source Type"::"Fixed Asset";
        GLEntry."Source No." := FA."No.";
        InsertGLEntry(GenJnlLine, GLEntry, true);
    end;

    local procedure CheckVendPrepmtApplPostingDate(GenJnlLine: Record "Gen. Journal Line"; NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; OldVendLedgEntry: Record "Vendor Ledger Entry")
    begin
        if GenJnlLine."Prepayment Status" <> GenJnlLine."Prepayment Status"::" " then
            exit;

        with OldVendLedgEntry do
            if NewCVLedgEntryBuf.Prepayment xor Prepayment then
                if NewCVLedgEntryBuf.Prepayment then
                    CheckVendApplDates(NewCVLedgEntryBuf."Posting Date", "Posting Date", NewCVLedgEntryBuf."Entry No.")
                else
                    CheckVendApplDates("Posting Date", NewCVLedgEntryBuf."Posting Date", "Entry No.");
    end;

    local procedure CheckCustPrepmtApplPostingDate(GenJnlLine: Record "Gen. Journal Line"; NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; OldCustLedgEntry: Record "Cust. Ledger Entry")
    begin
        if GenJnlLine."Prepayment Status" <> GenJnlLine."Prepayment Status"::" " then
            exit;

        with OldCustLedgEntry do
            if NewCVLedgEntryBuf.Prepayment xor Prepayment then
                if NewCVLedgEntryBuf.Prepayment then
                    CheckCustApplDates(NewCVLedgEntryBuf."Posting Date", "Posting Date", NewCVLedgEntryBuf."Entry No.")
                else
                    CheckCustApplDates("Posting Date", NewCVLedgEntryBuf."Posting Date", "Entry No.");
    end;

    local procedure CheckVendApplDates(PrepaymentPostingDate: Date; InitialEntryPostingDate: Date; EntryNo: Integer)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        with VendLedgEntry do
            if PrepaymentPostingDate > InitialEntryPostingDate then
                Error(MustNotBeAfterErr,
                  InitialEntryPostingDate, TableCaption, EntryNo);
    end;

    local procedure CheckCustApplDates(PrepaymentPostingDate: Date; InitialEntryPostingDate: Date; EntryNo: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        with CustLedgEntry do
            if PrepaymentPostingDate > InitialEntryPostingDate then
                Error(MustNotBeAfterErr,
                  InitialEntryPostingDate, TableCaption, EntryNo);
    end;

    local procedure GetGenPostingTypeFromAccType(AccountType: Enum "Gen. Journal Account Type"): Enum "General Posting Type"
    var
        GenJnlLine: Record "Gen. Journal Line";
        DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
    begin
        case AccountType of
            GenJnlLine."Account Type"::Vendor:
                exit(DtldCVLedgEntryBuf."Gen. Posting Type"::Purchase);
            GenJnlLine."Account Type"::Customer:
                exit(DtldCVLedgEntryBuf."Gen. Posting Type"::Sale);
        end;
    end;

    local procedure GetVATAmountsToRealize(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    var
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        RealizedVATEntry: Record "VAT Entry";
    begin
        TempDtldCVLedgEntryBuf.Copy(DtldCVLedgEntryBuf);
        with VATEntryToRealize do begin
            Base := 0;
            Amount := 0;
            "Additional-Currency Base" := 0;
            "Additional-Currency Amount" := 0;
        end;
        with TempDtldCVLedgEntryBuf do begin
            SetRange("CV Ledger Entry No.");
            SetRange(Prepayment, false);
            if FindSet() then
                repeat
                    RealizedVATEntry.SetRange("CV Ledg. Entry No.", "CV Ledger Entry No.");
                    if RealizedVATEntry.FindSet() then
                        repeat
                            VATEntryToRealize.Base += RealizedVATEntry.Base;
                            VATEntryToRealize.Amount += RealizedVATEntry.Amount;
                            VATEntryToRealize."Additional-Currency Base" += RealizedVATEntry."Additional-Currency Base";
                            VATEntryToRealize."Additional-Currency Amount" += RealizedVATEntry."Additional-Currency Amount";
                        until RealizedVATEntry.Next() = 0;
                until TempDtldCVLedgEntryBuf.Next() = 0;
        end;
    end;

    local procedure IsPrepayment(DocumentType: Enum "Gen. Journal Document Type"; Prepayment: Boolean): Boolean
    begin
        exit(
          (DocumentType in [DocumentType::Payment, DocumentType::Refund]) and
          Prepayment and GLSetup."Enable Russian Accounting");
    end;

    local procedure CheckLedgerEntryIsNeeded(BankAcc: Record "Bank Account"; GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        with GenJnlLine do
            exit((((Amount <= 0) or (BankAcc."Account Type" = BankAcc."Account Type"::"Cash Account")) and
              ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") and "Check Printed") or
              ((Amount < 0) and ("Bank Payment Type" = "Bank Payment Type"::"Manual Check")) or
              ((Amount > 0) and (BankAcc."Account Type" = BankAcc."Account Type"::"Cash Account") and
              ("Bank Payment Type" = "Bank Payment Type"::"Manual Check")))
    end;

    local procedure PostDeferral(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        GLEntry: Record "G/L Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        DeferralUtilities: Codeunit "Deferral Utilities";
        PerPostDate: Date;
        PeriodicCount: Integer;
        AmtToDefer: Decimal;
        AmtToDeferACY: Decimal;
        EmptyDeferralLine: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDeferral(GenJournalLine, AccountNo, IsHandled);
        if IsHandled then
            exit;

        with GenJournalLine do begin
            if "Source Type" in ["Source Type"::Vendor, "Source Type"::Customer] then
                // Purchasing and Sales, respectively
                // We can create these types directly from the GL window, need to make sure we don't already have a deferral schedule
                // created for this GL Trx before handing it off to sales/purchasing subsystem
                if "Source Code" <> GLSourceCode then begin
                    PostDeferralPostBuffer(GenJournalLine);
                    exit;
                end;

            if DeferralHeader.Get(DeferralDocType::"G/L", "Journal Template Name", "Journal Batch Name", 0, '', "Line No.") then begin
                EmptyDeferralLine := false;
                // Get the range of detail records for this schedule
                DeferralUtilities.FilterDeferralLines(
                  DeferralLine, DeferralDocType::"G/L".AsInteger(), "Journal Template Name", "Journal Batch Name", 0, '', "Line No.");
                if DeferralLine.FindSet() then
                    repeat
                        if DeferralLine.Amount = 0.0 then
                            EmptyDeferralLine := true;
                    until (DeferralLine.Next() = 0) or EmptyDeferralLine;
                if EmptyDeferralLine then
                    Error(ZeroDeferralAmtErr, "Line No.", "Deferral Code");
                DeferralHeader."Amount to Defer (LCY)" :=
                  Round(CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                      DeferralHeader."Amount to Defer", "Currency Factor"));
                DeferralHeader.Modify();
            end;

            DeferralUtilities.RoundDeferralAmount(
              DeferralHeader,
              "Currency Code", "Currency Factor", "Posting Date", AmtToDefer, AmtToDeferACY);

            DeferralTemplate.Get("Deferral Code");
            DeferralTemplate.TestField("Deferral Account");
            DeferralTemplate.TestField("Deferral %");

            // Get the Deferral Header table so we know the amount to defer...
            // Assume straight GL posting
            if DeferralHeader.Get(DeferralDocType::"G/L", "Journal Template Name", "Journal Batch Name", 0, '', "Line No.") then
                // Get the range of detail records for this schedule
                DeferralUtilities.FilterDeferralLines(
                  DeferralLine, DeferralDocType::"G/L".AsInteger(), "Journal Template Name", "Journal Batch Name", 0, '', "Line No.")
            else
                Error(NoDeferralScheduleErr, "Line No.", "Deferral Code");

            InitGLEntry(
              GenJournalLine, GLEntry, AccountNo,
              -DeferralHeader."Amount to Defer (LCY)", -DeferralHeader."Amount to Defer", true, true);
            GLEntry.Description := SetDeferralDescription(GenJournalLine, DeferralLine);
            OnPostDeferralOnBeforeInsertGLEntryForGLAccount(GenJournalLine, DeferralLine, GLEntry);
            InsertGLEntry(GenJournalLine, GLEntry, true);

            InitGLEntry(
              GenJournalLine, GLEntry, DeferralTemplate."Deferral Account",
              DeferralHeader."Amount to Defer (LCY)", DeferralHeader."Amount to Defer", true, true);
            GLEntry.Description := SetDeferralDescription(GenJournalLine, DeferralLine);
            OnPostDeferralOnBeforeInsertGLEntryForDeferralAccount(GenJournalLine, DeferralLine, GLEntry);
            InsertGLEntry(GenJournalLine, GLEntry, true);

            // Here we want to get the Deferral Details table range and loop through them...
            if DeferralLine.FindSet() then begin
                PeriodicCount := 1;
                repeat
                    PerPostDate := DeferralLine."Posting Date";
                    CheckDeferralPostingDate(PerPostDate);

                    InitGLEntry(
                      GenJournalLine, GLEntry, AccountNo,
                      DeferralLine."Amount (LCY)", DeferralLine.Amount, true, true);
                    GLEntry."Posting Date" := PerPostDate;
                    GLEntry.Description := DeferralLine.Description;
                    OnPostDeferralOnBeforeInsertGLEntryDeferralLineForGLAccount(GenJournalLine, DeferralLine, GLEntry);
                    InsertGLEntry(GenJournalLine, GLEntry, true);

                    InitGLEntry(
                      GenJournalLine, GLEntry, DeferralTemplate."Deferral Account",
                      -DeferralLine."Amount (LCY)", -DeferralLine.Amount, true, true);
                    GLEntry."Posting Date" := PerPostDate;
                    GLEntry.Description := DeferralLine.Description;
                    OnPostDeferralOnBeforeInsertGLEntryDeferralLineForDeferralAccount(GenJournalLine, DeferralLine, GLEntry);
                    InsertGLEntry(GenJournalLine, GLEntry, true);
                    PeriodicCount := PeriodicCount + 1;
                until DeferralLine.Next() = 0;
            end else
                Error(NoDeferralScheduleErr, "Line No.", "Deferral Code");
        end;

        OnAfterPostDeferral(GenJournalLine, TempGLEntryBuf, AccountNo);
    end;

    local procedure CheckDeferralPostingDate(PostingDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDeferralPostDate(PostingDate, IsHandled);
        if IsHandled then
            exit;

    if GenJnlCheckLine.DateNotAllowed(PostingDate) then
        Error(InvalidPostingDateErr, PostingDate);

    end;

    local procedure PostDeferralPostBuffer(GenJournalLine: Record "Gen. Journal Line")
    var
        DeferralPostBuffer: Record "Deferral Posting Buffer";
        GLEntry: Record "G/L Entry";
        PostDate: Date;
    begin
        OnBeforePostDeferralPostBuffer(GenJournalLine);
        with GenJournalLine do begin
            if "Source Type" = "Source Type"::Customer then
                DeferralDocType := DeferralDocType::Sales
            else
                DeferralDocType := DeferralDocType::Purchase;

            DeferralPostBuffer.SetRange("Deferral Doc. Type", DeferralDocType);
            DeferralPostBuffer.SetRange("Document No.", "Document No.");
            DeferralPostBuffer.SetRange("Deferral Line No.", "Deferral Line No.");
            OnPostDeferralPostBufferOnAfterSetFilters(DeferralPostBuffer, GenJournalLine);

            if DeferralPostBuffer.FindSet() then begin
                repeat
                    PostDate := DeferralPostBuffer."Posting Date";
                    if GenJnlCheckLine.DateNotAllowed(PostDate) then
                        Error(InvalidPostingDateErr, PostDate);

                    // When no sales/purch amount is entered, the offset was already posted
                    if (DeferralPostBuffer."Sales/Purch Amount" <> 0) or (DeferralPostBuffer."Sales/Purch Amount (LCY)" <> 0) then begin
                        InitGLEntry(GenJournalLine, GLEntry, DeferralPostBuffer."G/L Account",
                          DeferralPostBuffer."Sales/Purch Amount (LCY)",
                          DeferralPostBuffer."Sales/Purch Amount",
                          true, true);
                        GLEntry."Posting Date" := PostDate;
                        GLEntry.Description := DeferralPostBuffer.Description;
                        GLEntry.CopyFromDeferralPostBuffer(DeferralPostBuffer);
                        OnPostDeferralPostBufferOnBeforeInsertGLEntryForGLAccount(GenJournalLine, DeferralPostBuffer, GLEntry);
                        InsertGLEntry(GenJournalLine, GLEntry, true);
                    end;

                    if DeferralPostBuffer.Amount <> 0 then begin
                        InitGLEntry(GenJournalLine, GLEntry,
                          DeferralPostBuffer."Deferral Account",
                          -DeferralPostBuffer."Amount (LCY)",
                          -DeferralPostBuffer.Amount,
                          true, true);
                        GLEntry."Posting Date" := PostDate;
                        GLEntry.Description := DeferralPostBuffer.Description;
                        OnPostDeferralPostBufferOnBeforeInsertGLEntryForDeferralAccount(GenJournalLine, DeferralPostBuffer, GLEntry);
                        InsertGLEntry(GenJournalLine, GLEntry, true);
                    end;
                until DeferralPostBuffer.Next() = 0;
                DeferralPostBuffer.DeleteAll();
            end;
        end;

        OnAfterPostDeferralPostBuffer(GenJournalLine);
    end;

    procedure RemoveDeferralSchedule(GenJournalLine: Record "Gen. Journal Line")
    var
        DeferralUtilities: Codeunit "Deferral Utilities";
    begin
        // Removing deferral schedule after all deferrals for this line have been posted successfully
        with GenJournalLine do
            DeferralUtilities.DeferralCodeOnDelete(
              "Deferral Document Type"::"G/L".AsInteger(),
              "Journal Template Name", "Journal Batch Name", 0, '', "Line No.");
    end;

    local procedure GetGLSourceCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        GLSourceCode := SourceCodeSetup."General Journal";
    end;

    local procedure DeferralPosting(DeferralCode: Code[10]; SourceCode: Code[10]; AccountNo: Code[20]; var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeferralPosting(DeferralCode, SourceCode, AccountNo, GenJournalLine, Balancing, IsHandled);
        if IsHandled then
            exit;

        if DeferralCode <> '' then
            // Sales and purchasing could have negative amounts, so check for them first...
            if (SourceCode <> GLSourceCode) and
             (GenJournalLine."Account Type" in [GenJournalLine."Account Type"::Customer, GenJournalLine."Account Type"::Vendor])
          then
                PostDeferralPostBuffer(GenJournalLine)
            else
                // Pure GL trx, only post deferrals if it is not a balancing entry
                if not Balancing then
                    PostDeferral(GenJournalLine, AccountNo);
    end;

    local procedure SetDeferralDescription(GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"): Text[100]
    var
        DeferralDescription: Text[100];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDeferralDescription(GenJournalLine, DeferralLine, DeferralDescription, IsHandled);
        if IsHandled then
            exit(DeferralDescription);

        exit(GenJournalLine.Description);
    end;

    local procedure GetPostingAccountNo(VATPostingSetup: Record "VAT Posting Setup"; VATEntry: Record "VAT Entry"; UnrealizedVAT: Boolean): Code[20]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Sales Tax" then begin
            VATEntry.TestField("Tax Jurisdiction Code");
            TaxJurisdiction.Get(VATEntry."Tax Jurisdiction Code");
            case VATEntry.Type of
                VATEntry.Type::Sale:
                    exit(TaxJurisdiction.GetSalesAccount(UnrealizedVAT));
                VATEntry.Type::Purchase:
                    begin
                        if VATEntry."Use Tax" then
                            exit(TaxJurisdiction.GetRevChargeAccount(UnrealizedVAT));
                        exit(TaxJurisdiction.GetPurchAccount(UnrealizedVAT));
                    end;
            end;
        end;

        case VATEntry.Type of
            VATEntry.Type::Sale:
                exit(VATPostingSetup.GetSalesAccount(UnrealizedVAT));
            VATEntry.Type::Purchase:
                exit(VATPostingSetup.GetPurchAccount(UnrealizedVAT));
        end;
    end;

    local procedure IsDebitAmount(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; Unapply: Boolean): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmountCondition: Boolean;
        EntryAmount: Decimal;
    begin
        with DtldCVLedgEntryBuf do begin
            VATAmountCondition :=
              "Entry Type" in ["Entry Type"::"Payment Discount (VAT Excl.)", "Entry Type"::"Payment Tolerance (VAT Excl.)",
                               "Entry Type"::"Payment Discount Tolerance (VAT Excl.)"];
            if VATAmountCondition then begin
                VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                VATAmountCondition := VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Full VAT";
            end;
            if VATAmountCondition then
                EntryAmount := "VAT Amount (LCY)"
            else
                EntryAmount := "Amount (LCY)";
            if Unapply then
                exit(EntryAmount > 0);
            exit(EntryAmount <= 0);
        end;
    end;

    local procedure GetVendorPostingGroup(GenJournalLine: Record "Gen. Journal Line"; var VendorPostingGroup: Record "Vendor Posting Group")
    begin
        VendorPostingGroup.Get(GenJournalLine."Posting Group");
        OnAfterGetVendorPostingGroup(GenJournalLine, VendorPostingGroup);
    end;

    local procedure GetCustomerReceivablesAccount(GenJournalLine: Record "Gen. Journal Line"; CustomerPostingGroup: Record "Customer Posting Group") ReceivablesAccount: Code[20]
    begin
        ReceivablesAccount := CustomerPostingGroup.GetReceivablesAccount();
        OnAfterGetCustomerReceivablesAccount(GenJournalLine, CustomerPostingGroup, ReceivablesAccount);
    end;

    local procedure GetVendorPayablesAccount(GenJournalLine: Record "Gen. Journal Line"; VendorPostingGroup: Record "Vendor Posting Group") PayablesAccount: Code[20]
    begin
        PayablesAccount := VendorPostingGroup.GetPayablesAccount();
        OnAfterGetVendorPayablesAccount(GenJournalLine, VendorPostingGroup, PayablesAccount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunWithCheck(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalLine2: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunWithoutCheck(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalLine2: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCode(var GenJnlLine: Record "Gen. Journal Line"; CheckLine: Boolean; var IsPosted: Boolean; var GLReg: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccDimError(var GenJournalLine: Record "Gen. Journal Line"; GLAccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccDirectPosting(var GenJournalLine: Record "Gen. Journal Line"; GLAcc: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDeferralPostDate(PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchExtDocNo(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartPosting(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartOrContinuePosting(var GenJnlLine: Record "Gen. Journal Line"; LastDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder; LastDocNo: Code[20]; LastDate: Date; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContinuePosting(var GenJournalLine: Record "Gen. Journal Line"; var GLRegister: Record "G/L Register"; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustUnrealizedVAT(var GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; SettledAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostGLAcc(GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var GLEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVAT(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean; var AddCurrGLEntryVATAmt: Decimal; var NextConnectionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPmtDiscountVATByUnapply(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVend(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindAmtForAppln(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var OldAppliedAmount: Decimal; var Handled: Boolean; var ApplnRoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendUnrealizedVAT(var GenJnlLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; SettledAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCustLedgEntryInsert(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldLedgEntryInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATOnAfterCalcVATDifferenceLCY(GenJournalLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; var VATDifferenceLCY: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterVendLedgEntryInsert(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var DtldLedgEntryInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindAmtForAppln(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var OldAppliedAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobLineSign(var GenJnlLine: Record "Gen. Journal Line"; var IsJobLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGLEntry(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; AddCurrAmount: Decimal; UseAddCurrAmount: Boolean; var CurrencyFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGLRegister(var GLRegister: Record "G/L Register"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitBankAccLedgEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCheckLedgEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; Offset: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDtldVendLedgEntry(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; Offset: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDtldCustLedgEntryUnapply(var CustomerPostingGroup: Record "Customer Posting Group"; var OldDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertGlobalGLEntry(var GLEntry: Record "G/L Entry"; var TempGLEntryBuf: Record "G/L Entry"; var NextEntryNo: Integer; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertGLEntry(GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; TempGLEntryBuf: Record "G/L Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitVAT(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var VATPostingSetup: Record "VAT Posting Setup"; var AddCurrGLEntryVATAmt: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertVAT(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var UnrealizedVAT: Boolean; var AddCurrencyCode: Code[10]; var VATPostingSetup: Record "VAT Posting Setup"; var GLEntryAmount: Decimal; var GLEntryVATAmount: Decimal; var GLEntryBaseAmount: Decimal; var SrcCurrCode: Code[10]; var SrcCurrGLEntryAmt: Decimal; var SrcCurrGLEntryVATAmt: Decimal; var SrcCurrGLEntryBaseAmt: Decimal; AddCurrGLEntryVATAmt: Decimal; var NextConnectionNo: Integer; var NextVATEntryNo: Integer; var NextTransactionNo: Integer; TempGLEntryBufEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertVATEntry(GenJnlLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; GLEntryNo: Integer; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterIsNotPayment(DocumentType: Enum "Gen. Journal Document Type"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostBankAcc(var GenJnlLine: Record "Gen. Journal Line"; Balancing: Boolean; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterRunWithCheck(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterRunWithoutCheck(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostPmtDiscountVATByUnapply(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOldCustLedgEntryModify(var CustLedgEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeApplyCustLedgEntry(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; Cust: Record Customer; var IsAmountToApplyCheckHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOldVendLedgEntryModify(var VendLedgEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeApplyVendLedgEntry(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; Vend: Record Vendor; var IsAmountToApplyCheckHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustLedgEntryInsert(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendLedgEntryInsert(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldCustLedgEntryUnapply(var NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; OldDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldVendLedgEntry(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldVendLedgEntryUnapply(var NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; OldDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGLEntryBuffer(var TempGLEntryBuf: Record "G/L Entry" temporary; var GenJournalLine: Record "Gen. Journal Line"; var BalanceCheckAmount: Decimal; var BalanceCheckAmount2: Decimal; var BalanceCheckAddCurrAmount: Decimal; var BalanceCheckAddCurrAmount2: Decimal; var NextEntryNo: Integer; var TotalAmount: Decimal; var TotalAddCurrAmount: Decimal; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGlobalGLEntry(var GlobalGLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempVATEntry(var TempVATEntry: Record "VAT Entry" temporary; GenJournalLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; VATAmount: Decimal; VATBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitAmounts(var GenJnlLine: Record "Gen. Journal Line"; var Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitBankAccLedgEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitCheckEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var GLAccNo: Code[20]; SystemCreatedEntry: Boolean; Amount: Decimal; AmountAddCurr: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitVAT(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean; var LCYCurrency: Record Currency; var AddCurrencyCode: Code[10]; var AddCurrGLEntryVATAmt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGLEntryFromVATEntry(var GLEntry: Record "G/L Entry"; VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertVAT(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var UnrealizedVAT: Boolean; var AddCurrencyCode: Code[10]; var VATPostingSetup: Record "VAT Posting Setup"; var GLEntryAmount: Decimal; var GLEntryVATAmount: Decimal; var GLEntryBaseAmount: Decimal; var SrcCurrCode: Code[10]; var SrcCurrGLEntryAmt: Decimal; var SrcCurrGLEntryVATAmt: Decimal; var SrcCurrGLEntryBaseAmt: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertVATForGLEntry(var GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; GLEntryVATAmount: Decimal; SrcCurrGLEntryVATAmt: Decimal; UnrealizedVAT: Boolean; var IsHandled: Boolean; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertVATEntry(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPostUnrealVATEntry(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line"; var VATEntry2: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFinishPosting(var GenJournalLine: Record "Gen. Journal Line"; var TempGLEntryBuf: Record "G/L Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinishPosting(var GlobalGLEntry: Record "G/L Entry"; var GLRegister: Record "G/L Register"; var IsTransactionConsistent: Boolean; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGLFinishPosting(GLEntry: Record "G/L Entry"; var GenJnlLine: Record "Gen. Journal Line"; IsTransactionConsistent: Boolean; FirstTransactionNo: Integer; var GLRegister: Record "G/L Register"; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextTransactionNoNeeded(GenJnlLine: Record "Gen. Journal Line"; LastDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder; LastDocNo: Code[20]; LastDate: Date; CurrentBalance: Decimal; CurrentBalanceACY: Decimal; var NewTransaction: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostGLAcc(var GenJnlLine: Record "Gen. Journal Line"; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer; Balancing: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscOnAfterAssignPmtDisc(var PmtDisc: Decimal; var PmtDiscLCY: Decimal; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscOnAfterCalcPmtDisc(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var PmtDisc: Decimal; var PmtDiscLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtToleranceOnAfterAssignPmtDisc(var PmtTol: Decimal; var PmtTolLCY: Decimal; var PmtTolAmtToBeApplied: Decimal; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NextTransactionNo: Integer; var FirstNewVATEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscIfAdjVATCopyFields(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostDeferral(var GenJournalLine: Record "Gen. Journal Line"; var TempGLEntryBuf: Record "G/L Entry" temporary; AccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostDeferralPostBuffer(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostDeferral(var GenJournalLine: Record "Gen. Journal Line"; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostDeferralPostBuffer(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJob(var GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; var IsJobLine: Boolean)
    begin
    end;

#if not CLEAN19
    [Obsolete('Replaced by event OnBeforeCreateGLEntriesForTotalAmountsV19().', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmounts(var InvoicePostBuffer: Record "Invoice Post. Buffer"; GenJournalLine: Record "Gen. Journal Line"; var GLAccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmountsV19(var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; GenJournalLine: Record "Gen. Journal Line"; var GLAccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostDtldCVLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; Unapply: Boolean; AccNo: Code[20]; AdjAmount: array[4] of Decimal; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostDtldVendVATAdjustment(GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostDtldCVLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var AccNo: Code[20]; var Unapply: Boolean; var AdjAmount: array[4] of Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostDtldCVLedgEntryCreateGLEntryPmtDiscTol(var GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var Unapply: Boolean; var AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostCust(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostVend(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostVAT(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; VATPostingSetup: Record "VAT Posting Setup"; TaxDetail: Record "Tax Detail"; var NextConnectionNo: Integer; var AddCurrGLEntryVATAmt: Decimal; AddCurrencyCode: Code[10]; UseCurrFactorOnly: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAmtLCYAdjustment(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAplication(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var OldAppliedAmount: Decimal; var PrevNewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var PrevOldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var AllApplied: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPmtTolerance(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var PmtTolAmtToBeApplied: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPmtDisc(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var PmtTolAmtToBeApplied: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPmtDiscTolerance(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNextOldCustLedgEntryToApply(var GenJournalLine: Record "Gen. Journal Line"; var TempOldCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var Completed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNextOldVendLedgEntryToApply(var GenJournalLine: Record "Gen. Journal Line"; var TempOldVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var Completed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCurrencyExchRate(var GenJournalLine: Record "Gen. Journal Line"; var AddCurrencyCode: Code[10]; var UseCurrFactorOnly: Boolean; var CurrencyDate: Date; var CurrencyFactor: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDtldCustLedgEntryAccNo(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var CustomerPostingGroup: Record "Customer Posting Group"; OriginalTransactionNo: Integer; Unapply: Boolean; var VATEntry: Record "VAT Entry"; var AccountNo: code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDtldVendLedgEntryAccNo(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var VendorPostingGroup: Record "Vendor Posting Group"; OriginalTransactionNo: Integer; Unapply: Boolean; var VATEntry: Record "VAT Entry"; var AccountNo: code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcMinimalPossibleLiability(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var MinimalPossibleLiability: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPaymentExceedsLiability(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var MinimalPossibleLiability: Decimal; var PaymentExceedsLiability: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPmtDiscVATAmounts(var VATEntry: Record "VAT Entry"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcToleratedPaymentExceedsLiability(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var MinimalPossibleLiability: Decimal; var ToleratedPaymentExceedsLiability: Boolean; var PmtTolAmtToBeApplied: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPmtDiscount(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var PmtTolAmtToBeApplied: Decimal; var PmtDisc: Decimal; var PmtDiscLCY: Decimal; var PmtDiscAddCurr: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPmtDiscPossible(GenJnlLine: Record "Gen. Journal Line"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPmtDiscTolerance(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var PmtDiscTol: Decimal; var PmtDiscTolLCY: Decimal; var PmtDiscTolAddCurr: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPmtDiscToleranceProc(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var PmtDiscTol: Decimal; var PmtDiscTolLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPmtTolerance(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var PmtTol: Decimal; var PmtTolLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOldDtldCVLedgEntryBuf(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var PrevNewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var PrevOldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNewDtldCVLedgEntryBuf(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var PrevNewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var PrevOldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSettingIsTransactionConsistent(GenJournalLine: Record "Gen. Journal Line"; var IsTransactionConsistent: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCurrencyApplnRounding(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf3: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCurrencyRealizedGainLoss(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var GenJnlLine: Record "Gen. Journal Line"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCurrencyUnrealizedGainLoss(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var GenJnlLine: Record "Gen. Journal Line"; var AppliedAmount: Decimal; var RemainingAmountBeforeAppln: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPmtDiscPossible(var GenJnlLine: Record "Gen. Journal Line"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var IsHandled: Boolean; RoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustPostApplyCustLedgEntry(var GenJnlLinePostApply: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendPostApplyVendLedgEntry(var GenJnlLinePostApply: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostApply(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostApply(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateGLReg(IsTransactionConsistent: Boolean; var IsGLRegInserted: Boolean; var GLReg: Record "G/L Register"; var IsHandled: Boolean; var GenJnlLine: Record "Gen. Journal Line"; GlobalGLEntry: Record "G/L Entry")
    begin
    end;

#if not CLEAN19
    [Obsolete('Replaced by event OnBeforeUpdateTotalAmountsV19().', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTotalAmounts(var TempInvPostBuf: Record "Invoice Post. Buffer" temporary; var DimSetID: Integer; var AmountToCollect: Decimal; var AmountACYToCollect: Decimal; var IsHandled: Boolean; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTotalAmountsV19(var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; var DimSetID: Integer; var AmountToCollect: Decimal; var AmountACYToCollect: Decimal; var IsHandled: Boolean; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertPmtDiscVATForGLEntry(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GenJournalLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLEntryGainLossInsertGLEntry(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

#if not CLEAN19
    [Obsolete('Replaced by event OnBeforeCreateGLEntriesForTotalAmountsUnapplyV19().', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmountsUnapply(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var CustomerPostingGroup: Record "Customer Posting Group"; GenJournalLine: Record "Gen. Journal Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmountsUnapplyV19(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var CustomerPostingGroup: Record "Customer Posting Group"; GenJournalLine: Record "Gen. Journal Line"; var TempIDimPostingBuffer: Record "Dimension Posting Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN19
    [Obsolete('Replaced by event OnBeforeCreateGLEntriesForTotalAmountsUnapplyVendorV19().', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmountsUnapplyVendor(DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var VendorPostingGroup: Record "Vendor Posting Group"; GenJournalLine: Record "Gen. Journal Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmountsUnapplyVendorV19(DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var VendorPostingGroup: Record "Vendor Posting Group"; GenJournalLine: Record "Gen. Journal Line"; var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGLEntryVAT(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGLEntryVAT(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGLEntryVATCopy(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGLEntryVATCopy(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUnrealVATEntry(GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUnapply(GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry";
        VATEntryType: Enum "General Posting Type"; BilltoPaytoNo: Code[20];
                          TransactionNo: Integer;
                          UnapplyVATEntries: Boolean;
        var TempVATEntry: Record "VAT Entry" temporary; var IsHandled: Boolean; var NextVATEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUnrealVATEntry(GenJnlLine: Record "Gen. Journal Line"; var VATEntry2: Record "VAT Entry"; VATAmount: Decimal; VATBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleAddCurrResidualGLEntry(GenJournalLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCurrencyRealizedGainLoss(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; AppliedAmount: Decimal; AppliedAmountLCY: Decimal; var RealizedGainLossLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateCalculateTax(var GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateInitSalesTaxLines(var GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; SalesTaxBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateReverseCalculateTax(var GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATEntryTaxDetails(var VATEntry: Record "VAT Entry"; TaxDetail: Record "Tax Detail")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnAfterRecalculateAmounts(var TempOldCustLedgerEntry: Record "Cust. Ledger Entry" temporary; OldCustLedgerEntry: Record "Cust. Ledger Entry"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnAfterCalcShouldUpdateCalcInterestFromOldBuf(var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; Cust: Record Customer; var ShouldUpdateCalcInterest: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnAfterCalcShouldUpdateCalcInterestFromNewBuf(var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; Cust: Record Customer; var ShouldUpdateCalcInterest: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnBeforePrepareTempCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgerEntryOnBeforeSetCompleted(var GenJournalLine: Record "Gen. Journal Line"; var OldCustLedgEntry: Record "Cust. Ledger Entry"; var NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryOnAfterRecalculateAmounts(var TempOldVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; OldVendorLedgerEntry: Record "Vendor Ledger Entry"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryOnBeforeTempOldVendLedgEntryDelete(var GenJournalLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; AppliedAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryOnBeforeOldVendLedgEntryModify(GenJnlLine: Record "Gen. Journal Line"; var OldVendLedgEntry: Record "Vendor Ledger Entry"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

#if not CLEAN19
    [Obsolete('Replaced by event OnBeforeCreateGLEntryForTotalAmountsForDimPostBuf().', '19.0')]
    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateGLEntryForTotalAmountsForInvPostBuf(var GenJnlLine: Record "Gen. Journal Line"; InvPostBuf: Record "Invoice Post. Buffer"; var GLAccNo: Code[20])
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateGLEntryForTotalAmountsForDimPostBuf(var GenJnlLine: Record "Gen. Journal Line"; TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; var GLAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustLedgEntryModify(var CustLedgerEntry: Record "Cust. Ledger Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendLedgEntryModify(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareTempCustledgEntry(var GenJnlLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareTempVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDeferralDescription(GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; var DeferralDescription: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSummarizeVATFromInitGLEntryVAT(var GLEntry: Record "G/L Entry"; Amount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscIfAdjVATOnBeforeVATEntryFind(var GenJnlLine: Record "Gen. Journal Line"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var VATEntry: Record "VAT Entry"; var PmtDiscLCY2: Decimal; var PmtDiscAddCurr2: Decimal; var PmtDiscFactorLCY: Decimal; var PmtDiscFactorAddCurr: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscAdjVATAmountsOnBeforeProcessVATEntry(var GenJnlLine: Record "Gen. Journal Line"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcPmtDiscIfAdjVATOnBeforeInsertSummarizedVATAfterLoop(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcPmtDiscIfAdjVATOnBeforeInsertSummarizedVATAdjForPaymentDiscount(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcPmtDiscIfAdjVATOnBeforeInsertPmtDiscVATForGLEntry(var VATEntry: Record "VAT Entry"; VATEntry2: Record "VAT Entry"; DtldCVLedgEntryBuf2: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

#if not CLEAN19
    [Obsolete('Replaced by. OnCreateGLEntriesForTotalAmountsUnapplyOnBeforeCreateGLEntryV19().', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCreateGLEntriesForTotalAmountsUnapplyOnBeforeCreateGLEntry(var GenJnlLine: Record "Gen. Journal Line"; var TempInvPostBuf: Record "Invoice Post. Buffer" temporary; var GLAccNo: Code[20]);
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCreateGLEntriesForTotalAmountsUnapplyOnBeforeCreateGLEntryV19(var GenJnlLine: Record "Gen. Journal Line"; var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; var GLAccNo: Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateGLEntryForTotalAmountsOnBeforeInsertGLEntry(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnAfterRunExhangeAccGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnBeforeFinishPosting(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnContinuePostingOnBeforeCalculateCurrentBalance(var GenJournalLine: Record "Gen. Journal Line"; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnBeforeCheckPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnBeforeFinishPosting(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnBeforePostDtldCustLedgEntries(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFinishPostingOnBeforeResetFirstEntryNo(var GLEntry: Record "G/L Entry"; NextEntryNo: Integer; FirstEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleAddCurrResidualGLEntryOnBeforeInsertGLEntry(GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var TempGLEntryBuf: Record "G/L Entry"; NextEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleDtldAdjustmentOnBeforeInitGLEntry(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; TotalAmountLCY: Decimal; TotalAmountAddCurr: Decimal; GLAccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitVATOnBeforeVATPostingSetupCheck(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitVATOnBeforeTestFullVATAccount(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertGLEntryOnBeforeCheckAmountRounding(var GLEntry: Record "G/L Entry"; var IsHandled: Boolean; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertGLEntryOnBeforeAssignTempGLEntryBuf(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPmtDiscVATForGLEntryOnAfterCopyFromGenJnlLine(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempVATEntryOnBeforeInsert(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATEntriesFromTempOnBeforeVATEntryInsert(var VATEntry: Record "VAT Entry"; TempVATEntry: Record "VAT Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATOnAfterAssignVATEntryFields(GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; CurrExchRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATOnBeforeCreateGLEntryForReverseChargeVATToPurchAcc(var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVAT: Boolean; VATAmount: Decimal; VATAmountAddCurr: Decimal; UseAmountAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATOnBeforeCreateGLEntryForReverseChargeVATToRevChargeAcc(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVAT: Boolean; var VATAmount: Decimal; var VATAmountAddCurr: Decimal; UseAmountAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATOnBeforeVATForGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var GLEntryVATAmountNotEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostApplyOnAfterRecalculateAmounts(var OldCVLedgerEntryBuffer2: Record "CV Ledger Entry Buffer"; OldCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostBankAccOnAfterBankAccLedgEntryInsert(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBankAccOnBeforeBankAccLedgEntryInsert(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account"; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBankAccOnAfterCheckLedgEntryInsert(var CheckLedgerEntry: Record "Check Ledger Entry"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBankAccOnBeforeCheckLedgEntryInsert(var CheckLedgerEntry: Record "Check Ledger Entry"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBankAccOnBeforeInitBankAccLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; CurrencyFactor: Decimal; var NextEntryNo: Integer; var NextTransactionNo: Integer; var BankAccPostingGr: Record "Bank Account Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCustOnAfterCopyCVLedgEntryBuf(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostCustOnAfterInitCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; Cust: Record Customer; CustPostingGr: Record "Customer Posting Group")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostCustOnBeforeInitCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var CustPostingGr: Record "Customer Posting Group")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostCustOnAfterTempDtldCVLedgEntryBufCopyFromGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostCustOnBeforeTempDtldCVLedgEntryBufCopyFromGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; var Cust: Record Customer; GLReg: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVendOnAfterCopyCVLedgEntryBuf(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostVendOnBeforeInitVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var VendPostingGr: Record "Vendor Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVendAfterTempDtldCVLedgEntryBufInit(var GenJnlLine: Record "Gen. Journal Line"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldCVLedgEntryOnBeforeCreateGLEntryGainLoss(var GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var Unapply: Boolean; var AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldCVLedgEntryOnAfterCreateGLEntryPmtDiscTol(DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; TempGLEntryBuf: Record "G/L Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldCVLedgEntryOnAfterCreateGLEntryPmtDiscTolVATExcl(DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; TempGLEntryBuf: Record "G/L Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldCustLedgEntriesOnAfterCreateGLEntriesForTotalAmounts(var TempGLEntryBuf: Record "G/L Entry" temporary; var GlobalGLEntry: Record "G/L Entry"; NextTransactionNo: Integer)
    begin
    end;

#if not CLEAN19
    [IntegrationEvent(true, false)]
    [Obsolete('Replaced by event OnPostDtldCustLedgEntriesOnBeforeCreateGLEntriesForTotalAmountsV19().', '19.0')]
    local procedure OnPostDtldCustLedgEntriesOnBeforeCreateGLEntriesForTotalAmounts(var CustPostingGr: Record "Customer Posting Group"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var TempInvPostBuf: Record "Invoice Post. Buffer" temporary; AdjAmount: array[4] of Decimal; SaveEntryNo: Integer; GLAccNo: Code[20]; LedgerEntryInserted: Boolean; AddCurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldCustLedgEntriesOnBeforeCreateGLEntriesForTotalAmountsV19(var CustPostingGr: Record "Customer Posting Group"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; AdjAmount: array[4] of Decimal; SaveEntryNo: Integer; GLAccNo: Code[20]; LedgerEntryInserted: Boolean; AddCurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldVendLedgEntriesOnAfterCreateGLEntriesForTotalAmounts(var TempGLEntryBuf: Record "G/L Entry" temporary; var GlobalGLEntry: Record "G/L Entry"; NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldVendLedgEntriesOnBeforeCreateGLEntriesForTotalAmounts(var VendPostingGr: Record "Vendor Posting Group"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldVendVATAdjustmentOnAfterFindVATEntry(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostGLAccOnBeforeInsertGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var IsHandled: Boolean; Balancing: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetOnAfterSaveGenJnlLineValues(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostFixedAssetOnBeforeInsertGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var IsHandled: Boolean; var TempFAGLPostBuf: Record "FA G/L Posting Buffer" temporary; GLEntry2: Record "G/L Entry"; NextEntyNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetOnBeforePostVAT(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetOnBeforeInitGLEntryFromTempFAGLPostBuf(var GenJournalLine: Record "Gen. Journal Line"; var TempFAGLPostBuf: Record "FA G/L Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralOnBeforeInsertGLEntryForGLAccount(GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralOnBeforeInsertGLEntryForDeferralAccount(GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralOnBeforeInsertGLEntryDeferralLineForGLAccount(GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralOnBeforeInsertGLEntryDeferralLineForDeferralAccount(GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralPostBufferOnBeforeInsertGLEntryForGLAccount(GenJournalLine: Record "Gen. Journal Line"; DeferralPostingBuffer: Record "Deferral Posting Buffer"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralPostBufferOnBeforeInsertGLEntryForDeferralAccount(GenJournalLine: Record "Gen. Journal Line"; DeferralPostingBuffer: Record "Deferral Posting Buffer"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralPostBufferOnAfterSetFilters(var DeferralPostBuffer: Record "Deferral Posting Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnapplyOnAfterVATEntrySetFilters(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnapplyOnBeforeUnapplyVATEntry(var VATEntry: Record "VAT Entry"; var UnapplyVATEntry: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostUnapplyOnBeforeVATEntryInsert(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line"; OrigVATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempCustLedgEntryOnAfterSetFilters(var OldCustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempCustLedgEntryOnBeforeExit(var GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var TempOldCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempCustLedgEntryOnBeforeTestPositive(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempCustLedgEntryOnBeforeTempOldCustLedgEntryInsert(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempVendLedgEntryOnAfterSetFilters(var OldVendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempVendLedgEntryOnAfterSetFiltersBlankAppliesToDocNo(var OldVendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempVendLedgEntryOnBeforeExit(var GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var TempOldVendLedgEntry: Record "Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempVendLedgEntryOnBeforeTempOldVendLedgEntryInsert(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnAfterCreateGLEntriesForTotalAmounts(var GenJournalLine: Record "Gen. Journal Line"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GLReg: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnAfterDtldCustLedgEntrySetFilters(var DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnBeforeCheckPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnBeforePostUnapply(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnBeforeUpdateCustLedgEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var DetailedCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnAfterCreateGLEntriesForTotalAmounts(var GenJournalLine: Record "Gen. Journal Line"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; GLReg: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnAfterFilterSourceEntries(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnBeforeCheckPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnBeforePostUnapply(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnBeforeUpdateVendLedgEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DetailedCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustUnrealizedVATOnAfterVATPartCalculation(GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; PaidAmount: Decimal; TotalUnrealVATAmountFirst: Decimal; TotalUnrealVATAmountLast: Decimal; SettledAmount: Decimal; VATEntry2: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustUnrealizedVATOnAfterCalcPaidAmount(GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry2: Record "Cust. Ledger Entry"; SettledAmount: Decimal; var PaidAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustUnrealizedVATOnBeforeInitGLEntryVAT(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var VATAmount: Decimal; var VATBase: Decimal; var VATAmountAddCurr: Decimal; var VATBaseAddCurr: Decimal; var IsHandled: Boolean; var SalesVATUnrealAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustUnrealizedVATOnAfterSetSalesVATAccounts(var VATEntry: Record "VAT Entry"; var VATPostingSetup: Record "VAT Posting Setup"; var SalesVATAccount: Code[20]; var SalesVATUnrealAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendPostApplyVendLedgEntryOnBeforeCheckPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendPostApplyVendLedgEntryOnBeforeFinishPosting(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendPostApplyVendLedgEntryOnBeforePostDtldVendLedgEntries(var VendorLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendUnrealizedVATOnAfterVATPartCalculation(GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; PaidAmount: Decimal; TotalUnrealVATAmountFirst: Decimal; TotalUnrealVATAmountLast: Decimal; SettledAmount: Decimal; VATEntry2: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendUnrealizedVATOnBeforeInitGLEntryVAT(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var VATAmount: Decimal; var VATBase: Decimal; var VATAmountAddCurr: Decimal; var VATBaseAddCurr: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; ToRecordID: RecordID)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitLastDocDate(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCustLedgEntry(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var TempGLEntryBuf: Record "G/L Entry" temporary; var GlobalGLEntry: Record "G/L Entry"; NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVendLedgEntry(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var TempGLEntryBuf: Record "G/L Entry" temporary; var GlobalGLEntry: Record "G/L Entry"; NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnBeforeTempOldCustLedgEntryDelete(var TempOldCustLedgEntry: Record "Cust. Ledger Entry" temporary; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var Cust: Record Customer; NextEntryNo: Integer; GLReg: Record "G/L Register"; AppliedAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUnrealVATByUnapply(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; VATEntry: Record "VAT Entry"; NewVATEntry: Record "VAT Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUnrealVATByUnapply(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; VATEntry: Record "VAT Entry"; NewVATEntry: Record "VAT Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscPossibleOnBeforeOriginalPmtDiscPossible(GenJnlLine: Record "Gen. Journal Line"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; AmountRoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempCustLedgEntryOnAfterSetFiltersByAppliesToId(var OldCustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldVendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustomerReceivablesAccount(GenJournalLine: Record "Gen. Journal Line"; CustomerPostingGroup: Record "Customer Posting Group"; var ReceivablesAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVendorPostingGroup(GenJournalLine: Record "Gen. Journal Line"; var VendorPostingGroup: Record "Vendor Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVendorPayablesAccount(GenJournalLine: Record "Gen. Journal Line"; VendorPostingGroup: Record "Vendor Posting Group"; var PayablesAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVendUnrealizedVATAccounts(VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; var PurchVATAccount: Code[20]; var PurchVATUnrealAccount: Code[20]; var PurchReverseAccount: Code[20]; var PurchReverseUnrealAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnapplyOnAfterVATEntryInsert(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line"; OrigVATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCalcInterestOnAfterCustLedgEntrySetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendUnrealizedVATOnAfterCalcTotalUnrealVATAmount(var VATEntry2: Record "VAT Entry"; var TotalUnrealVATAmountFirst: Decimal; var TotalUnrealVATAmountLast: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnVendUnrealizedVATOnBeforePostUnrealVATEntry(var GenJnlLine: Record "Gen. Journal Line"; var VATEntry2: Record "VAT Entry"; var VATAmount: Decimal; var VATBase: Decimal; var VATAmountAddCurr: Decimal; var VATBaseAddCurr: Decimal; var GLEntryNo: Integer; VATPart: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostUnrealVATByUnapplyOnBeforeVATEntryModify(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; VATEntry: Record "VAT Entry"; NewVATEntry: Record "VAT Entry"; var VATEntry2: Record "VAT Entry"; var GLEntryNoFromVAT: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPmtTolerancePossible(GenJnlLine: Record "Gen. Journal Line"; PmtDiscountDate: Date; var PmtDiscToleranceDate: Date; var MaxPaymentTolerance: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeferralPosting(DeferralCode: Code[10]; SourceCode: Code[10]; AccountNo: Code[20]; var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesExtDocNo(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchExtDocNoProcedure(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostICPartner(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterStartPosting(GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCustOnAfterAssignCurrencyFactors(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVendOnAfterAssignCurrencyFactors(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInitAmountsOnAddCurrencyPostingNone(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVendOnAfterInitVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertSummarizedVATOnAfterInsertGLEntry(var GenJnlLine: Record "Gen. Journal Line"; var TempGLEntryVAT: Record "G/L Entry" temporary; NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostBankAccOnBeforeCreateGLEntryBalAcc(var GenJnlLine: Record "Gen. Journal Line"; BankAccPostingGr: Record "Bank Account Posting Group"; BankAccount: Record "Bank Account"; NextEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetOnAfterSetGenJnlLineShortcutDimCodes(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostICPartnerOnBeforeCreateGLEntryBalAcc(var GenJnlLine: Record "Gen. Journal Line"; NextEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGlEntry(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateGLEntry(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcApplication(var GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCustPostApplyCustLedgEntryOnAfterApplyCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustPostApplyCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var GLReg: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDtldCustLedgEntryNoOffset(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldCustLedgEntriesOnBeforeUpdateTotalAmounts(var GenJnlLine: Record "Gen. Journal Line"; DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldCustLedgEntriesOnBeforePostDtldCustLedgEntry(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; AddCurrencyCode: Code[10]; var GenJnlLine: Record "Gen. Journal Line"; CustPostingGr: Record "Customer Posting Group"; AdjAmount: array[4] of Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnVendPostApplyVendLedgEntryOnAfterApplyVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVendPostApplyVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; GLReg: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldVendLedgEntriesOnBeforeUpdateTotalAmounts(var GenJnlLine: Record "Gen. Journal Line"; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldVendLedgEntriesOnBeforePostDtldVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group"; AdjAmount: array[4] of Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnUnapplyCustLedgEntryOnBeforeSecondLook(var DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; NextDtldLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnAfterFillDtldCVLedgEntryBuf(var GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnUnapplyCustLedgEntryOnBeforeUpdateTotalAmounts(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDtldVendLedgEntryNoOffset(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnBeforeSecondLook(var DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry"; NextDtldLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnAfterFillDtldCVLedgEntryBuf(var GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnBeforeUpdateTotalAmounts(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessTempVATEntryCustOnAfterProcessTempVATEntry(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var TempVATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGLCalcAddCurrencyPostingNone(var GenJnlLine: Record "Gen. Journal Line"; Amount: Decimal; AddCurrency: Record Currency; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCurrencyExchRateOnAfterSetNewCurrencyDate(var GenJnlLine: Record "Gen. Journal Line"; var NewCurrencyDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCurrencyExchRate(var GenJnlLine: Record "Gen. Journal Line"; NewCurrencyDate: Date; CurrencyDate: Date; UseCurrFactorOnly: Boolean; var CurrencyFactor: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldAdjustmentOnBeforeCreateGLEntryBalAcc(var GenJnlLine: Record "Gen. Journal Line"; GLAcc: Code[20]; AdjAmount: array[4] of Decimal; ArrayIndex: Integer; var IsHandled: Boolean; NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitVATOnVATCalculationTypeNormal(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostVendOnBeforePostDtldVendLedgEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnContinuePostingOnIncreaseNextTransactionNo(var GenJnlLine: Record "Gen. Journal Line"; var NextTransactionNo: Integer; var IsHandled: Boolean)
    begin
    end;
}
