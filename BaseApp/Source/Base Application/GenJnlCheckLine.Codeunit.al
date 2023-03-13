codeunit 11 "Gen. Jnl.-Check Line"
{
    Permissions = tabledata "General Posting Setup" = rimd,
                  tabledata "Cost Accounting Setup" = R,
                  tabledata "Payment Terms" = R;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        CostAccSetup: Record "Cost Accounting Setup";
        TempErrorMessage: Record "Error Message" temporary;
        DimMgt: Codeunit DimensionManagement;
        CostAccMgt: Codeunit "Cost Account Mgt";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        SkipFiscalYearCheck: Boolean;
        GenJnlTemplateFound: Boolean;
        OverrideDimErr: Boolean;
        LogErrorMode: Boolean;
        IsBatchMode: Boolean;

        Text000: Label 'can only be a closing date for G/L entries';
        Text001: Label 'is not within your range of allowed posting dates';
        Text002: Label '%1 or %2 must be G/L Account or Bank Account.';
        Text003: Label 'must have the same sign as %1';
        Text004: Label 'You must not specify %1 when %2 is %3.';
        Text005: Label '%1 + %2 must be %3.';
        Text006: Label '%1 + %2 must be -%3.';
        Text007: Label 'must be positive';
        Text008: Label 'must be negative';
        Text009: Label 'must have a different sign than %1';
        Text010: Label '%1 %2 and %3 %4 is not allowed.';
        Text011: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5';
        Text012: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
        SpecifyGenPostingTypeErr: Label 'Posting to Account %1 must either be of type Purchase or Sale (see %2), because there are specified values in one of the following fields: %3, %4 , %5, or %6', comment = '%1 an G/L Account number;%2 = Gen. Posting Type; %3 = Gen. Bus. Posting Group; %4 = Gen. Prod. Posting Group; %5 = VAT Bus. Posting Group, %6 = VAT Prod. Posting Group';
        SalesDocAlreadyExistsErr: Label 'Sales %1 %2 already exists.', Comment = '%1 = Document Type; %2 = Document No.';
        PurchDocAlreadyExistsErr: Label 'Purchase %1 %2 already exists.', Comment = '%1 = Document Type; %2 = Document No.';
        EmployeeBalancingDocTypeErr: Label 'must be empty or set to Payment when Balancing Account Type field is set to Employee';
        EmployeeAccountDocTypeErr: Label 'must be empty or set to Payment when Account Type field is set to Employee';

    procedure RunCheck(var GenJnlLine: Record "Gen. Journal Line")
    var
        ICGLAcount: Record "IC G/L Account";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        OnBeforeRunCheck(GenJnlLine);

        if LogErrorMode then begin
            ErrorMessageMgt.Activate(ErrorMessageHandler);
            ErrorMessageMgt.PushContext(ErrorContextElement, GenJnlLine.RecordId, 0, '');
        end;

        GLSetup.Get();
        with GenJnlLine do begin
            if EmptyLine() then
                exit;

            if not GenJnlTemplateFound then begin
                if GenJnlTemplate.Get("Journal Template Name") then;
                GenJnlTemplateFound := true;
            end;

            CheckDates(GenJnlLine);
            ValidateSalesPersonPurchaserCode(GenJnlLine);

            TestDocumentNo(GenJnlLine);

            if ("Account Type" in
                ["Account Type"::Customer,
                 "Account Type"::Vendor,
                 "Account Type"::"Fixed Asset",
                 "Account Type"::"IC Partner"]) and
               ("Bal. Account Type" in
                ["Bal. Account Type"::Customer,
                 "Bal. Account Type"::Vendor,
                 "Bal. Account Type"::"Fixed Asset",
                 "Bal. Account Type"::"IC Partner"])
            then
                Error(
                    ErrorInfo.Create(
                        StrSubstNo(
                        Text002,
                        FieldCaption("Account Type"), FieldCaption("Bal. Account Type")),
                    true,
                    GenJnlLine,
                    GenJnlLine.FieldNo("Account Type")));

            if "Bal. Account No." = '' then
                TestField("Account No.", ErrorInfo.Create());

            CheckZeroAmount(GenJnlLine);

            if ((Amount < 0) xor ("Amount (LCY)" < 0)) and (Amount <> 0) and ("Amount (LCY)" <> 0) then
                FieldError("Amount (LCY)", ErrorInfo.Create(StrSubstNo(Text003, FieldCaption(Amount)), true));

            if ("Account Type" = "Account Type"::"G/L Account") and
               ("Bal. Account Type" = "Bal. Account Type"::"G/L Account")
            then
                CheckAppliesToDocNo(GenJnlLine);

            if ("Recurring Method" in
                ["Recurring Method"::"B  Balance", "Recurring Method"::"RB Reversing Balance"]) and
               ("Currency Code" <> '')
            then
                Error(
                    ErrorInfo.Create(
                        StrSubstNo(
                            Text004,
                            FieldCaption("Currency Code"), FieldCaption("Recurring Method"), "Recurring Method"),
                        true,
                        GenJnlLine,
                        FieldNo("Recurring Method")));

            if "Account No." <> '' then
                CheckAccountNo(GenJnlLine);

            if "Bal. Account No." <> '' then
                CheckBalAccountNo(GenJnlLine);

            if "IC Partner G/L Acc. No." <> '' then
                if ICGLAcount.Get("IC Partner G/L Acc. No.") then
                    ICGLAcount.TestField(Blocked, false, ErrorInfo.Create());

            if (("Account Type" = "Account Type"::"G/L Account") and
                ("Bal. Account Type" = "Bal. Account Type"::"G/L Account")) or
               (("Document Type" <> "Document Type"::Invoice) and
                (not
                 (("Document Type" = "Document Type"::"Credit Memo") and
                  CalcPmtDiscOnCrMemos("Payment Terms Code"))))
            then begin
                TestField("Pmt. Discount Date", 0D, ErrorInfo.Create());
                TestField("Payment Discount %", 0, ErrorInfo.Create());
            end;

            if "Applies-to Doc. No." <> '' then
                TestField("Applies-to ID", '', ErrorInfo.Create());

            if ("Account Type" <> "Account Type"::"Bank Account") and
               ("Bal. Account Type" <> "Bal. Account Type"::"Bank Account")
            then
                TestField("Bank Payment Type", "Bank Payment Type"::" ", ErrorInfo.Create());

            if ("Account Type" = "Account Type"::"Fixed Asset") or
               ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset")
            then
                CODEUNIT.Run(CODEUNIT::"FA Jnl.-Check Line", GenJnlLine);

            if ("Account Type" <> "Account Type"::"Fixed Asset") and
               ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
            then begin
                TestField("Depreciation Book Code", '', ErrorInfo.Create());
                TestField("FA Posting Type", 0, ErrorInfo.Create());
            end;

            if not OverrideDimErr then
                CheckDimensions(GenJnlLine);
        end;

        if CostAccSetup.Get() then
            CostAccMgt.CheckValidCCAndCOInGLEntry(GenJnlLine."Dimension Set ID");

        OnAfterCheckGenJnlLine(GenJnlLine, ErrorMessageMgt);

        if LogErrorMode then
            ErrorMessageMgt.GetErrors(TempErrorMessage);
    end;

    local procedure TestDocumentNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestDocumentNo(GenJournalLine, IsHandled);
        if IsHandled then
            exit;

        GenJournalLine.TestField("Document No.", ErrorInfo.Create());
    end;

    procedure GetErrors(var NewTempErrorMessage: Record "Error Message" temporary)
    begin
        NewTempErrorMessage.Copy(TempErrorMessage, true);
    end;

    local procedure CalcPmtDiscOnCrMemos(PaymentTermsCode: Code[10]): Boolean
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTermsCode <> '' then begin
            PaymentTerms.Get(PaymentTermsCode);
            exit(PaymentTerms."Calc. Pmt. Disc. on Cr. Memos");
        end;
    end;

    procedure DateNotAllowed(PostingDate: Date): Boolean
    var
        SetupRecordID: RecordID;
    begin
        exit(IsDateNotAllowed(PostingDate, SetupRecordID));
    end;

    procedure DeferralPostingDateNotAllowed(PostingDate: Date): Boolean
    var
        SetupRecordID: RecordID;
    begin
        exit(IsDeferralPostingDateNotAllowed(PostingDate, SetupRecordID));
    end;

    procedure DateNotAllowed(PostingDate: Date; TemplateName: Code[20]): Boolean
    var
        SetupRecordID: RecordID;
    begin
        exit(IsDateNotAllowed(PostingDate, SetupRecordID, TemplateName));
    end;

    procedure IsDateNotAllowed(PostingDate: Date; var SetupRecordID: RecordID) DateIsNotAllowed: Boolean
    var
        UserSetupManagement: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsDateNotAllowed(PostingDate, SetupRecordID, GenJnlBatch, DateIsNotAllowed, IsHandled);
        if IsHandled then
            exit;

        DateIsNotAllowed := not UserSetupManagement.IsPostingDateValidWithSetup(PostingDate, SetupRecordID);
        OnAfterDateNoAllowed(PostingDate, DateIsNotAllowed);
        exit(DateIsNotAllowed);
    end;

    procedure IsDeferralPostingDateNotAllowed(PostingDate: Date; var SetupRecordID: RecordID) DateIsNotAllowed: Boolean
    var
        UserSetupManagement: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsDeferralPostingDateNotAllowed(PostingDate, SetupRecordID, GenJnlBatch, DateIsNotAllowed, IsHandled);
        if IsHandled then
            exit;

        DateIsNotAllowed := not UserSetupManagement.IsDeferralPostingDateValidWithSetup(PostingDate, SetupRecordID);
        OnAfterDeferralPostingDateNoAllowed(PostingDate, DateIsNotAllowed);
        exit(DateIsNotAllowed);
    end;

    procedure IsDateNotAllowed(PostingDate: Date; var SetupRecordID: RecordID; TemplateName: Code[20]) DateIsNotAllowed: Boolean
    var
        UserSetupManagement: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsDateNotAllowed(PostingDate, SetupRecordID, GenJnlBatch, DateIsNotAllowed, IsHandled);
        if IsHandled then
            exit;

        DateIsNotAllowed :=
          not UserSetupManagement.IsPostingDateValidWithGenJnlTemplateWithSetup(PostingDate, TemplateName, SetupRecordID);
        OnAfterDateNoAllowed(PostingDate, DateIsNotAllowed);
        exit(DateIsNotAllowed);
    end;

    internal procedure CheckVATDateAllowed(VATDate: Date)
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        if not VATReportingDateMgt.IsValidDate(VATDate) then
            Error('')
    end;

    procedure SetGenJnlBatch(NewGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch := NewGenJnlBatch;
    end;

    procedure SetSkipFiscalYearCheck(NewValue: Boolean)
    begin
        SkipFiscalYearCheck := NewValue;
    end;

    procedure ErrorIfPositiveAmt(GenJnlLine: Record "Gen. Journal Line")
    var
        RaiseError: Boolean;
    begin
        RaiseError := GenJnlLine.Amount > 0;
        OnBeforeErrorIfPositiveAmt(GenJnlLine, RaiseError);
        if RaiseError then
            GenJnlLine.FieldError(Amount, ErrorInfo.Create(Text008, true));
    end;

    procedure ErrorIfNegativeAmt(GenJnlLine: Record "Gen. Journal Line")
    var
        RaiseError: Boolean;
    begin
        RaiseError := GenJnlLine.Amount < 0;
        OnBeforeErrorIfNegativeAmt(GenJnlLine, RaiseError);
        if RaiseError then
            GenJnlLine.FieldError(Amount, ErrorInfo.Create(Text007, true));
    end;

    procedure SetOverDimErr()
    begin
        OverrideDimErr := true;
    end;

    local procedure CheckDates(GenJnlLine: Record "Gen. Journal Line")
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        DateCheckDone: Boolean;
        IsHandled: Boolean;
    begin
        with GenJnlLine do begin
            TestField("Posting Date", ErrorInfo.Create());
            if "Posting Date" <> NormalDate("Posting Date") then begin
                if ("Account Type" <> "Account Type"::"G/L Account") or
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account")
                then
                    FieldError("Posting Date", ErrorInfo.Create(Text000, true));
                if not SkipFiscalYearCheck then begin
                    IsHandled := false;
                    OnBeforeCheckPostingDateInFiscalYear(GenJnlLine, IsHandled);
                    if not IsHandled then
                        AccountingPeriodMgt.CheckPostingDateInFiscalYear("Posting Date");
                end;
            end;

            if GLSetup."Journal Templ. Name Mandatory" then
                TestField("Journal Template Name", ErrorInfo.Create());
            OnBeforeDateNotAllowed(GenJnlLine, DateCheckDone);
            if not DateCheckDone then
                if DateNotAllowed("Posting Date", "Journal Template Name") then
                    FieldError("Posting Date", ErrorInfo.Create(Text001, true));

            if "Document Date" <> 0D then
                if ("Document Date" <> NormalDate("Document Date")) and
                   (("Account Type" <> "Account Type"::"G/L Account") or
                    ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account"))
                then
                    GenJnlLine.FieldError("Document Date", ErrorInfo.Create(Text000, true));
        end;
    end;

    local procedure CheckAccountNo(GenJnlLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        ICPartner: Record "IC Partner";
        CheckDone: Boolean;
    begin
        OnBeforeCheckAccountNo(GenJnlLine, CheckDone);
        if CheckDone then
            exit;

        with GenJnlLine do
            case "Account Type" of
                "Account Type"::"G/L Account":
                    begin
                        if ((("Gen. Bus. Posting Group" <> '') or ("Gen. Prod. Posting Group" <> '') or
                            ("VAT Bus. Posting Group" <> '') or ("VAT Prod. Posting Group" <> '')) and
                            ("Gen. Posting Type" = "Gen. Posting Type"::" "))
                        then
                            Error(
                                ErrorInfo.Create(
                                    StrSubstNo(
                                        SpecifyGenPostingTypeErr, "Account No.", FieldCaption("Gen. Posting Type"),
                                        FieldCaption("Gen. Bus. Posting Group"), FieldCaption("Gen. Prod. Posting Group"),
                                        FieldCaption("VAT Bus. Posting Group"), FieldCaption("VAT Prod. Posting Group")),
                                    true,
                                    GenJnlLine,
                                    GenJnlLine.FieldNo("Gen. Posting Type")));

                        CheckGenProdPostingGroupWhenAdjustForPmtDisc(GenJnlLine);

                        if ("Gen. Posting Type" <> "Gen. Posting Type"::" ") and
                           ("VAT Posting" = "VAT Posting"::"Automatic VAT Entry")
                        then begin
                            if "VAT Amount" + "VAT Base Amount" <> Amount then
                                Error(
                                    ErrorInfo.Create(
                                        StrSubstNo(
                                            Text005, FieldCaption("VAT Amount"), FieldCaption("VAT Base Amount"),
                                            FieldCaption(Amount)),
                                        true,
                                        GenJnlLine,
                                        GenJnlLine.FieldNo("VAT Amount")));
                            if "Currency Code" <> '' then
                                if "VAT Amount (LCY)" + "VAT Base Amount (LCY)" <> "Amount (LCY)" then
                                    Error(
                                        ErrorInfo.Create(
                                            StrSubstNo(
                                                Text005, FieldCaption("VAT Amount (LCY)"),
                                                FieldCaption("VAT Base Amount (LCY)"), FieldCaption("Amount (LCY)")),
                                            true,
                                            GenJnlLine,
                                            GenJnlLine.FieldNo("VAT Amount (LCY)")));
                        end;
                    end;
                "Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee:
                    begin
                        TestField("Gen. Posting Type", 0, ErrorInfo.Create());
                        TestField("Gen. Bus. Posting Group", '', ErrorInfo.Create());
                        TestField("Gen. Prod. Posting Group", '', ErrorInfo.Create());
                        TestField("VAT Bus. Posting Group", '', ErrorInfo.Create());
                        TestField("VAT Prod. Posting Group", '', ErrorInfo.Create());

                        CheckAccountType(GenJnlLine);

                        CheckDocType(GenJnlLine);

                        if not "System-Created Entry" and
                           (((Amount < 0) xor ("Sales/Purch. (LCY)" < 0)) and (Amount <> 0) and ("Sales/Purch. (LCY)" <> 0))
                        then
                            FieldError("Sales/Purch. (LCY)", ErrorInfo.Create(StrSubstNo(Text003, FieldCaption(Amount)), true));
                        CheckJobNoIsEmpty(GenJnlLine);

                        CheckICPartner("Account Type", "Account No.", "Document Type", GenJnlLine);
                    end;
                "Account Type"::"Bank Account":
                    begin
                        TestField("Gen. Posting Type", 0, ErrorInfo.Create());
                        TestField("Gen. Bus. Posting Group", '', ErrorInfo.Create());
                        TestField("Gen. Prod. Posting Group", '', ErrorInfo.Create());
                        TestField("VAT Bus. Posting Group", '', ErrorInfo.Create());
                        TestField("VAT Prod. Posting Group", '', ErrorInfo.Create());
                        CheckJobNoIsEmpty(GenJnlLine);
                        if (Amount < 0) and ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") then
                            TestField("Check Printed", true, ErrorInfo.Create());
                        CheckElectronicPaymentFields(GenJnlLine);
                    end;
                "Account Type"::"IC Partner":
                    begin
                        ICPartner.Get("Account No.");
                        ICPartner.CheckICPartner();
                        if "Journal Template Name" <> '' then begin
                            GenJournalTemplate.Get("Journal Template Name");
                            if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                                FieldError("Account Type", ErrorInfo.Create());
                        end;
                    end;
            end;

        OnAfterCheckAccountNo(GenJnlLine);
    end;

    local procedure CheckBalAccountNo(GenJnlLine: Record "Gen. Journal Line")
    var
        ICPartner: Record "IC Partner";
        CheckDone: Boolean;
    begin
        OnBeforeCheckBalAccountNo(GenJnlLine, CheckDone);
        if CheckDone then
            exit;

        with GenJnlLine do
            case "Bal. Account Type" of
                "Bal. Account Type"::"G/L Account":
                    begin
                        if (("Bal. Gen. Bus. Posting Group" <> '') or ("Bal. Gen. Prod. Posting Group" <> '') or
                            ("Bal. VAT Bus. Posting Group" <> '') or ("Bal. VAT Prod. Posting Group" <> '')) and
                           not ApplicationAreaMgmt.IsSalesTaxEnabled()
                        then
                            TestField("Bal. Gen. Posting Type", ErrorInfo.Create());

                        CheckBalGenProdPostingGroupWhenAdjustForPmtDisc(GenJnlLine);

                        if ("Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" ") and
                           ("VAT Posting" = "VAT Posting"::"Automatic VAT Entry")
                        then begin
                            if "Bal. VAT Amount" + "Bal. VAT Base Amount" <> -Amount then
                                Error(
                                    ErrorInfo.Create(
                                        StrSubstNo(
                                            Text006, FieldCaption("Bal. VAT Amount"), FieldCaption("Bal. VAT Base Amount"),
                                            FieldCaption(Amount)),
                                        true,
                                        GenJnlLine,
                                        FieldNo("Bal. VAT Amount")));
                            if "Currency Code" <> '' then
                                if "Bal. VAT Amount (LCY)" + "Bal. VAT Base Amount (LCY)" <> -"Amount (LCY)" then
                                    Error(
                                        ErrorInfo.Create(
                                            StrSubstNo(
                                                Text006, FieldCaption("Bal. VAT Amount (LCY)"),
                                                FieldCaption("Bal. VAT Base Amount (LCY)"), FieldCaption("Amount (LCY)")),
                                                                true,
                                        GenJnlLine,
                                        FieldNo("Bal. VAT Amount (LCY)")));
                        end;
                    end;
                "Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::Employee:
                    begin
                        TestField("Bal. Gen. Posting Type", 0, ErrorInfo.Create());
                        TestField("Bal. Gen. Bus. Posting Group", '', ErrorInfo.Create());
                        TestField("Bal. Gen. Prod. Posting Group", '', ErrorInfo.Create());
                        TestField("Bal. VAT Bus. Posting Group", '', ErrorInfo.Create());
                        TestField("Bal. VAT Prod. Posting Group", '', ErrorInfo.Create());

                        CheckBalAccountType(GenJnlLine);

                        CheckBalDocType(GenJnlLine);

                        if ((Amount > 0) xor ("Sales/Purch. (LCY)" < 0)) and (Amount <> 0) and ("Sales/Purch. (LCY)" <> 0) then
                            FieldError("Sales/Purch. (LCY)", ErrorInfo.Create(StrSubstNo(Text009, FieldCaption(Amount)), true));
                        CheckJobNoIsEmpty(GenJnlLine);

                        CheckICPartner("Bal. Account Type", "Bal. Account No.", "Document Type", GenJnlLine);
                    end;
                "Bal. Account Type"::"Bank Account":
                    begin
                        TestField("Bal. Gen. Posting Type", 0, ErrorInfo.Create());
                        TestField("Bal. Gen. Bus. Posting Group", '', ErrorInfo.Create());
                        TestField("Bal. Gen. Prod. Posting Group", '', ErrorInfo.Create());
                        TestField("Bal. VAT Bus. Posting Group", '', ErrorInfo.Create());
                        TestField("Bal. VAT Prod. Posting Group", '', ErrorInfo.Create());
                        if (Amount > 0) and ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") then
                            TestField("Check Printed", true, ErrorInfo.Create());
                        CheckElectronicPaymentFields(GenJnlLine);
                    end;
                "Bal. Account Type"::"IC Partner":
                    begin
                        ICPartner.Get("Bal. Account No.");
                        ICPartner.CheckICPartner();
                        if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                            FieldError("Bal. Account Type", ErrorInfo.Create());
                    end;
            end;

        OnAfterCheckBalAccountNo(GenJnlLine);
    end;

    local procedure CheckElectronicPaymentFields(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckElectronicPaymentFields(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        with GenJnlLine do
            if ("Bank Payment Type" = "Bank Payment Type"::"Electronic Payment") or
               ("Bank Payment Type" = "Bank Payment Type"::"Electronic Payment-IAT")
            then begin
                TestField("Exported to Payment File", true, ErrorInfo.Create());
                TestField("Check Transmitted", true, ErrorInfo.Create());
            end;
    end;

    local procedure CheckJobNoIsEmpty(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckJobNoIsEmpty(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.TestField("Job No.", '', ErrorInfo.Create());
    end;

    procedure CheckSalesDocNoIsNotUsed(var GenJournalLine: Record "Gen. Journal Line")
    var
        OldCustLedgEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesDocNoIsNotUsed(GenJournalLine."Document Type".AsInteger(), GenJournalLine."Document No.", IsHandled, GenJournalLine);
        if IsHandled then
            exit;

        OldCustLedgEntry.SetRange("Document No.", GenJournalLine."Document No.");
        OldCustLedgEntry.SetRange("Document Type", GenJournalLine."Document Type");
        if not OldCustLedgEntry.IsEmpty() then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(SalesDocAlreadyExistsErr, GenJournalLine."Document Type", GenJournalLine."Document No."),
                    true,
                    GenJournalLine));
    end;

    procedure CheckPurchDocNoIsNotUsed(var GenJournalLine: Record "Gen. Journal Line")
    var
        OldVendLedgEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchDocNoIsNotUsed(GenJournalLine."Document Type".AsInteger(), GenJournalLine."Document No.", IsHandled, GenJournalLine);
        if IsHandled then
            exit;

        OldVendLedgEntry.SetRange("Document No.", GenJournalLine."Document No.");
        OldVendLedgEntry.SetRange("Document Type", GenJournalLine."Document Type");
        if not OldVendLedgEntry.IsEmpty() then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(PurchDocAlreadyExistsErr, GenJournalLine."Document Type", GenJournalLine."Document No."),
                    true,
                    GenJournalLine));
    end;

    procedure CheckDocType(GenJnlLine: Record "Gen. Journal Line")
    var
        IsPayment: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDocType(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        with GenJnlLine do
            if "Document Type" <> "Document Type"::" " then begin
                if ("Account Type" = "Account Type"::Employee) and not
                   ("Document Type" in ["Document Type"::Payment, "Document Type"::" "])
                then
                    FieldError("Document Type", ErrorInfo.Create(EmployeeAccountDocTypeErr, true));

                IsPayment := "Document Type" in ["Document Type"::Payment, "Document Type"::"Credit Memo"];
                if IsPayment xor (("Account Type" = "Account Type"::Customer) xor IsVendorPaymentToCrMemo(GenJnlLine)) then
                    ErrorIfNegativeAmt(GenJnlLine)
                else
                    ErrorIfPositiveAmt(GenJnlLine);
            end;
    end;

    local procedure CheckBalDocType(GenJnlLine: Record "Gen. Journal Line")
    var
        IsPayment: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBalDocType(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        with GenJnlLine do
            if "Document Type" <> "Document Type"::" " then begin
                if ("Bal. Account Type" = "Bal. Account Type"::Employee) and not
                   ("Document Type" in ["Document Type"::Payment, "Document Type"::" "])
                then
                    FieldError("Document Type", ErrorInfo.Create(EmployeeBalancingDocTypeErr, true));

                IsPayment := "Document Type" in ["Document Type"::Payment, "Document Type"::"Credit Memo"];
                if IsPayment = ("Bal. Account Type" = "Bal. Account Type"::Customer) then
                    ErrorIfNegativeAmt(GenJnlLine)
                else
                    ErrorIfPositiveAmt(GenJnlLine);
            end;
    end;

    local procedure CheckICPartner(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; GenJnlLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ICPartner: Record "IC Partner";
        Employee: Record Employee;
        CheckDone: Boolean;
    begin
        OnBeforeCheckICPartner(AccountType, AccountNo, DocumentType.AsInteger(), CheckDone, GenJnlLine);
        if CheckDone then
            exit;

        case AccountType of
            AccountType::Customer:
                if Customer.Get(AccountNo) then begin
                    Customer.CheckBlockedCustOnJnls(Customer, DocumentType, true);
                    if (Customer."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) and
                       ICPartner.Get(Customer."IC Partner Code")
                    then
                        ICPartner.CheckICPartnerIndirect(Format(AccountType), AccountNo);
                end;
            AccountType::Vendor:
                if Vendor.Get(AccountNo) then begin
                    Vendor.CheckBlockedVendOnJnls(Vendor, DocumentType, true);
                    if (Vendor."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) and
                       ICPartner.Get(Vendor."IC Partner Code")
                    then
                        ICPartner.CheckICPartnerIndirect(Format(AccountType), AccountNo);
                end;
            AccountType::Employee:
                if Employee.Get(AccountNo) then
                    Employee.CheckBlockedEmployeeOnJnls(true)
        end;
    end;

    local procedure CheckDimensions(GenJnlLine: Record "Gen. Journal Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        CheckDone: Boolean;
    begin
        OnBeforeCheckDimensions(GenJnlLine, CheckDone);
        if CheckDone then
            exit;

        with GenJnlLine do begin
            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                ThrowGenJnlLineError(GenJnlLine, Text011, DimMgt.GetDimCombErr());

            TableID[1] := DimMgt.TypeToTableID1("Account Type".AsInteger());
            No[1] := "Account No.";
            TableID[2] := DimMgt.TypeToTableID1("Bal. Account Type".AsInteger());
            No[2] := "Bal. Account No.";
            TableID[3] := DATABASE::Job;
            No[3] := "Job No.";
            TableID[4] := DATABASE::"Salesperson/Purchaser";
            No[4] := "Salespers./Purch. Code";
            TableID[5] := DATABASE::Campaign;
            No[5] := "Campaign No.";

            CheckDone := false;
            OnCheckDimensionsOnAfterAssignDimTableIDs(GenJnlLine, TableID, No, CheckDone);

            if not CheckDone then
                if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                    ThrowGenJnlLineError(GenJnlLine, Text012, DimMgt.GetDimValuePostingErr());
        end;
    end;

    local procedure CheckZeroAmount(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckZeroAmount(GenJnlLine, IsBatchMode, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine.NeedCheckZeroAmount() and not (GenJnlLine.IsRecurring() and IsBatchMode) then
            GenJnlLine.TestField(Amount, ErrorInfo.Create());
    end;

    procedure IsVendorPaymentToCrMemo(GenJournalLine: Record "Gen. Journal Line") Result: Boolean
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsVendorPaymentToCrMemo(GenJournalLine, Result, IsHandled);
        if IsHandled then
            exit;

        with GenJournalLine do begin
            if ("Account Type" = "Account Type"::Vendor) and
               ("Document Type" = "Document Type"::Payment) and
               ("Applies-to Doc. Type" = "Applies-to Doc. Type"::"Credit Memo") and
               ("Applies-to Doc. No." <> '')
            then begin
                GenJournalTemplate.Get("Journal Template Name");
                exit(GenJournalTemplate.Type = GenJournalTemplate.Type::Payments);
            end;
            exit(false);
        end;
    end;

    procedure ThrowGenJnlLineError(GenJournalLine: Record "Gen. Journal Line"; ErrorTemplate: Text; ErrorText: Text)
    begin
        if LogErrorMode then
            exit;

        with GenJournalLine do
            if "Line No." <> 0 then
                Error(
                    ErrorInfo.Create(
                        StrSubstNo(
                            ErrorTemplate,
                            TableCaption, "Journal Template Name", "Journal Batch Name", "Line No.",
                            ErrorText),
                        true,
                        GenJournalLine));

        Error(
            ErrorInfo.Create(ErrorText, true, GenJournalLine));
    end;

    procedure SetBatchMode(NewBatchMode: Boolean)
    begin
        IsBatchMode := NewBatchMode;
    end;

    procedure CheckGenProdPostingGroupWhenAdjustForPmtDisc(GenJnlLine: Record "Gen. Journal Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with GenJnlLine do begin
            if "System-Created Entry" or
               not ("Gen. Posting Type" in ["Gen. Posting Type"::Purchase, "Gen. Posting Type"::Sale]) or
               not ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"])
            then
                exit;

            if VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") and
               VATPostingSetup."Adjust for Payment Discount"
            then
                TestField("Gen. Prod. Posting Group", ErrorInfo.Create());
        end;
    end;

    procedure CheckBalGenProdPostingGroupWhenAdjustForPmtDisc(GenJnlLine: Record "Gen. Journal Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with GenJnlLine do begin
            if "System-Created Entry" or
               not ("Bal. Gen. Posting Type" in ["Bal. Gen. Posting Type"::Purchase, "Bal. Gen. Posting Type"::Sale]) or
               not ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"])
            then
                exit;

            if VATPostingSetup.Get("Bal. VAT Bus. Posting Group", "Bal. VAT Prod. Posting Group") and
               VATPostingSetup."Adjust for Payment Discount"
            then
                TestField("Bal. Gen. Prod. Posting Group", ErrorInfo.Create());
        end;
    end;

    local procedure CheckAccountType(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAccountType(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer) and
            (GenJnlLine."Bal. Gen. Posting Type" = GenJnlLine."Bal. Gen. Posting Type"::Purchase)) or
           ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor) and
            (GenJnlLine."Bal. Gen. Posting Type" = GenJnlLine."Bal. Gen. Posting Type"::Sale))
        then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(
                        Text010,
                        GenJnlLine.FieldCaption("Account Type"), GenJnlLine."Account Type",
                        GenJnlLine.FieldCaption("Bal. Gen. Posting Type"), GenJnlLine."Bal. Gen. Posting Type"),
                    true,
                    GenJnlLine));
    end;

    local procedure CheckBalAccountType(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBalAccountType(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ((GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer) and
            (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Purchase)) or
           ((GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor) and
            (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Sale))
        then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(
                        Text010,
                        GenJnlLine.FieldCaption("Bal. Account Type"), GenJnlLine."Bal. Account Type",
                        GenJnlLine.FieldCaption("Gen. Posting Type"), GenJnlLine."Gen. Posting Type"),
                    true,
                    GenJnlLine));
    end;

#if not CLEAN20
    [Obsolete('Replaced with TestField(..., ErrorInfo.Create())', '20.0')]
    procedure LogTestField(SourceVariant: Variant; FieldNo: Integer)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLogTestField(SourceVariant, FieldNo, IsHandled);
        if IsHandled then
            exit;

        RecRef.GetTable(SourceVariant);
        FldRef := RecRef.Field(FieldNo);
        if LogErrorMode then
            ErrorMessageMgt.LogTestField(SourceVariant, FieldNo)
        else
            FldRef.TestField();
    end;

    [Obsolete('Replaced with TestField(..., ErrorInfo.Create())', '20.0')]
    procedure LogTestField(SourceVariant: Variant; FieldNo: Integer; ExpectedValue: Variant)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLogTestField(SourceVariant, FieldNo, IsHandled);
        if IsHandled then
            exit;

        RecRef.GetTable(SourceVariant);
        FldRef := RecRef.Field(FieldNo);
        if LogErrorMode then
            ErrorMessageMgt.LogTestField(SourceVariant, FieldNo, ExpectedValue)
        else
            FldRef.TestField(ExpectedValue);
    end;

    [Obsolete('Replaced with Error(..., ErrorInfo.Create())', '20.0')]
    procedure LogError(SourceVariant: Variant; ErrorMessage: Text)
    begin
        if LogErrorMode then
            ErrorMessageMgt.LogErrorMessage(0, ErrorMessage, SourceVariant, 0, '')
        else
            Error(ErrorMessage);
    end;

    [Obsolete('Replaced with FieldError(..., ErrorInfo.Create())', '20.0')]
    procedure LogFieldError(SourceVariant: Variant; FieldNo: Integer; ErrorMessage: Text)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(SourceVariant);
        FldRef := RecRef.Field(FieldNo);
        if LogErrorMode then
            ErrorMessageMgt.LogFieldError(SourceVariant, FieldNo, ErrorMessage)
        else
            FldRef.FieldError(ErrorMessage);
    end;
#endif

    procedure SetLogErrorMode(NewLogErrorMode: Boolean)
    begin
        LogErrorMode := NewLogErrorMode;
        if LogErrorMode then
            DimMgt.SetCollectErrorsMode();
    end;

    local procedure CheckAppliesToDocNo(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := true;
        OnBeforeCheckAppliesToDocNo(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.TestField("Applies-to Doc. No.", '', ErrorInfo.Create());
        GenJnlLine.TestField("Applies-to ID", '', ErrorInfo.Create());
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckBalAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var ErrorMessageMgt: Codeunit "Error Message Management")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterDateNoAllowed(PostingDate: Date; var DateIsNotAllowed: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterDeferralPostingDateNoAllowed(PostingDate: Date; var DateIsNotAllowed: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDateNotAllowed(GenJnlLine: Record "Gen. Journal Line"; var DateCheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsDateNotAllowed(PostingDate: Date; SetupRecordID: RecordId; GenJnlBatch: Record "Gen. Journal Batch"; var DateIsNotAllowed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsDeferralPostingDateNotAllowed(PostingDate: Date; SetupRecordID: RecordId; GenJnlBatch: Record "Gen. Journal Batch"; var DateIsNotAllowed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckAccountNo(var GenJnlLine: Record "Gen. Journal Line"; var CheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBalAccountNo(var GenJnlLine: Record "Gen. Journal Line"; var CheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckDimensions(var GenJnlLine: Record "Gen. Journal Line"; var CheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckDocType(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBalDocType(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckICPartner(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Option; var CheckDone: Boolean; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckSalesDocNoIsNotUsed(DocType: Option; DocNo: Code[20]; var IsHandled: Boolean; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckPurchDocNoIsNotUsed(DocType: Option; DocNo: Code[20]; var IsHandled: Boolean; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeErrorIfNegativeAmt(GenJnlLine: Record "Gen. Journal Line"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeErrorIfPositiveAmt(GenJnlLine: Record "Gen. Journal Line"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRunCheck(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckPostingDateInFiscalYear(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckDimensionsOnAfterAssignDimTableIDs(var GenJournalLine: Record "Gen. Journal Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20]; var CheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckAccountType(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBalAccountType(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckAppliesToDocNo(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckJobNoIsEmpty(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckZeroAmount(GenJnlLine: Record "Gen. Journal Line"; IsBatchMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckElectronicPaymentFields(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeIsVendorPaymentToCrMemo(GenJnlLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN20
    [Obsolete('Will be removed due to calling procedure obsoletion', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogTestField(SourceVariant: Variant; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
#endif
}

