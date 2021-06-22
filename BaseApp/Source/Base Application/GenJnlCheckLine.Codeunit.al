codeunit 11 "Gen. Jnl.-Check Line"
{
    Permissions = TableData "General Posting Setup" = rimd;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
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
        GLSetup: Record "General Ledger Setup";
        GenJnlTemplate: Record "Gen. Journal Template";
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
        SalesDocAlreadyExistsErr: Label 'Sales %1 %2 already exists.', Comment = '%1 = Document Type; %2 = Document No.';
        PurchDocAlreadyExistsErr: Label 'Purchase %1 %2 already exists.', Comment = '%1 = Document Type; %2 = Document No.';
        IsBatchMode: Boolean;
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
            if EmptyLine then
                exit;

            if not GenJnlTemplateFound then begin
                if GenJnlTemplate.Get("Journal Template Name") then;
                GenJnlTemplateFound := true;
            end;

            CheckDates(GenJnlLine);
            ValidateSalesPersonPurchaserCode(GenJnlLine);

            LogTestField(GenJnlLine, FieldNo("Document No."));

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
                LogError(
                    GenJnlLine,
                    StrSubstNo(
                        Text002,
                        FieldCaption("Account Type"), FieldCaption("Bal. Account Type")));

            if "Bal. Account No." = '' then
                LogTestField(GenJnlLine, FieldNo("Account No."));

            CheckZeroAmount(GenJnlLine);

            if ((Amount < 0) xor ("Amount (LCY)" < 0)) and (Amount <> 0) and ("Amount (LCY)" <> 0) then
                LogFieldError(GenJnlLine, FieldNo("Amount (LCY)"), StrSubstNo(Text003, FieldCaption(Amount)));

            if ("Account Type" = "Account Type"::"G/L Account") and
               ("Bal. Account Type" = "Bal. Account Type"::"G/L Account")
            then
                CheckAppliesToDocNo(GenJnlLine);

            if ("Recurring Method" in
                ["Recurring Method"::"B  Balance", "Recurring Method"::"RB Reversing Balance"]) and
               ("Currency Code" <> '')
            then
                LogError(
                    GenJnlLine,
                    StrSubstNo(
                        Text004,
                        FieldCaption("Currency Code"), FieldCaption("Recurring Method"), "Recurring Method"));

            if "Account No." <> '' then
                CheckAccountNo(GenJnlLine);

            if "Bal. Account No." <> '' then
                CheckBalAccountNo(GenJnlLine);

            if "IC Partner G/L Acc. No." <> '' then
                if ICGLAcount.Get("IC Partner G/L Acc. No.") then
                    ICGLAcount.TestField(Blocked, false);

            if (("Account Type" = "Account Type"::"G/L Account") and
                ("Bal. Account Type" = "Bal. Account Type"::"G/L Account")) or
               (("Document Type" <> "Document Type"::Invoice) and
                (not
                 (("Document Type" = "Document Type"::"Credit Memo") and
                  CalcPmtDiscOnCrMemos("Payment Terms Code"))))
            then begin
                LogTestField(GenJnlLine, FieldNo("Pmt. Discount Date"), 0D);
                LogTestField(GenJnlLine, FieldNo("Payment Discount %"), 0);
            end;

            if (("Account Type" = "Account Type"::"G/L Account") and
                ("Bal. Account Type" = "Bal. Account Type"::"G/L Account")) or
               ("Applies-to Doc. No." <> '')
            then
                LogTestField(GenJnlLine, FieldNo("Applies-to ID"), '');

            if ("Account Type" <> "Account Type"::"Bank Account") and
               ("Bal. Account Type" <> "Bal. Account Type"::"Bank Account")
            then
                LogTestField(GenJnlLine, FieldNo("Bank Payment Type"), "Bank Payment Type"::" ");

            if ("Account Type" = "Account Type"::"Fixed Asset") or
               ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset")
            then
                CODEUNIT.Run(CODEUNIT::"FA Jnl.-Check Line", GenJnlLine);

            if ("Account Type" <> "Account Type"::"Fixed Asset") and
               ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
            then begin
                LogTestField(GenJnlLine, FieldNo("Depreciation Book Code"), '');
                LogTestField(GenJnlLine, FieldNo("FA Posting Type"), 0);
            end;

            if not OverrideDimErr then
                CheckDimensions(GenJnlLine);
        end;

        if CostAccSetup.Get then
            CostAccMgt.CheckValidCCAndCOInGLEntry(GenJnlLine."Dimension Set ID");

        OnAfterCheckGenJnlLine(GenJnlLine);

        if LogErrorMode then
            ErrorMessageMgt.GetErrors(TempErrorMessage);
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

    procedure IsDateNotAllowed(PostingDate: Date; var SetupRecordID: RecordID) DateIsNotAllowed: Boolean
    var
        UserSetupManagement: Codeunit "User Setup Management";
    begin
        DateIsNotAllowed := not UserSetupManagement.IsPostingDateValidWithSetup(PostingDate, SetupRecordID);
        OnAfterDateNoAllowed(PostingDate, DateIsNotAllowed);
        exit(DateIsNotAllowed);
    end;

    procedure SetSkipFiscalYearCheck(NewValue: Boolean)
    begin
        SkipFiscalYearCheck := NewValue;
    end;

    local procedure ErrorIfPositiveAmt(GenJnlLine: Record "Gen. Journal Line")
    var
        RaiseError: Boolean;
    begin
        RaiseError := GenJnlLine.Amount > 0;
        OnBeforeErrorIfPositiveAmt(GenJnlLine, RaiseError);
        if RaiseError then
            LogFieldError(GenJnlLine, GenJnlLine.FieldNo(Amount), Text008);
    end;

    local procedure ErrorIfNegativeAmt(GenJnlLine: Record "Gen. Journal Line")
    var
        RaiseError: Boolean;
    begin
        RaiseError := GenJnlLine.Amount < 0;
        OnBeforeErrorIfNegativeAmt(GenJnlLine, RaiseError);
        if RaiseError then
            LogFieldError(GenJnlLine, GenJnlLine.FieldNo(Amount), Text007);
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
            LogTestField(GenJnlLine, FieldNo("Posting Date"));
            if "Posting Date" <> NormalDate("Posting Date") then begin
                if ("Account Type" <> "Account Type"::"G/L Account") or
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account")
                then
                    LogFieldError(GenJnlLine, GenJnlLine.FieldNo("Posting Date"), Text000);
                if not SkipFiscalYearCheck then begin
                    IsHandled := false;
                    OnBeforeCheckPostingDateInFiscalYear(GenJnlLine, IsHandled);
                    if not IsHandled then
                        AccountingPeriodMgt.CheckPostingDateInFiscalYear("Posting Date");
                end;
            end;

            OnBeforeDateNotAllowed(GenJnlLine, DateCheckDone);
            if not DateCheckDone then
                if DateNotAllowed("Posting Date") then
                    LogFieldError(GenJnlLine, GenJnlLine.FieldNo("Posting Date"), Text001);

            if "Document Date" <> 0D then
                if ("Document Date" <> NormalDate("Document Date")) and
                   (("Account Type" <> "Account Type"::"G/L Account") or
                    ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account"))
                then
                    LogFieldError(GenJnlLine, GenJnlLine.FieldNo("Document Date"), Text000);
        end;
    end;

    local procedure CheckAccountNo(GenJnlLine: Record "Gen. Journal Line")
    var
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
                            LogError(
                                GenJnlLine,
                                StrSubstNo(
                                    SpecifyGenPostingTypeErr, "Account No.", FieldCaption("Gen. Posting Type"),
                                    FieldCaption("Gen. Bus. Posting Group"), FieldCaption("Gen. Prod. Posting Group"),
                                    FieldCaption("VAT Bus. Posting Group"), FieldCaption("VAT Prod. Posting Group")));

                        CheckGenProdPostingGroupWhenAdjustForPmtDisc(GenJnlLine);

                        if ("Gen. Posting Type" <> "Gen. Posting Type"::" ") and
                           ("VAT Posting" = "VAT Posting"::"Automatic VAT Entry")
                        then begin
                            if "VAT Amount" + "VAT Base Amount" <> Amount then
                                LogError(
                                    GenJnlLine,
                                    StrSubstNo(
                                        Text005, FieldCaption("VAT Amount"), FieldCaption("VAT Base Amount"),
                                        FieldCaption(Amount)));
                            if "Currency Code" <> '' then
                                if "VAT Amount (LCY)" + "VAT Base Amount (LCY)" <> "Amount (LCY)" then
                                    LogError(
                                        GenJnlLine,
                                        StrSubstNo(
                                            Text005, FieldCaption("VAT Amount (LCY)"),
                                            FieldCaption("VAT Base Amount (LCY)"), FieldCaption("Amount (LCY)")));
                        end;
                    end;
                "Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee:
                    begin
                        LogTestField(GenJnlLine, FieldNo("Gen. Posting Type"), 0);
                        LogTestField(GenJnlLine, FieldNo("Gen. Bus. Posting Group"), '');
                        LogTestField(GenJnlLine, FieldNo("Gen. Prod. Posting Group"), '');
                        LogTestField(GenJnlLine, FieldNo("VAT Bus. Posting Group"), '');
                        LogTestField(GenJnlLine, FieldNo("VAT Prod. Posting Group"), '');

                        CheckAccountType(GenJnlLine);

                        CheckDocType(GenJnlLine);

                        if not "System-Created Entry" and
                           (((Amount < 0) xor ("Sales/Purch. (LCY)" < 0)) and (Amount <> 0) and ("Sales/Purch. (LCY)" <> 0))
                        then
                            LogFieldError(GenJnlLine, GenJnlLine.FieldNo("Sales/Purch. (LCY)"), StrSubstNo(Text003, FieldCaption(Amount)));
                        CheckJobNoIsEmpty(GenJnlLine);

                        CheckICPartner("Account Type", "Account No.", "Document Type");
                    end;
                "Account Type"::"Bank Account":
                    begin
                        LogTestField(GenJnlLine, FieldNo("Gen. Posting Type"), 0);
                        LogTestField(GenJnlLine, FieldNo("Gen. Bus. Posting Group"), '');
                        LogTestField(GenJnlLine, FieldNo("Gen. Prod. Posting Group"), '');
                        LogTestField(GenJnlLine, FieldNo("VAT Bus. Posting Group"), '');
                        LogTestField(GenJnlLine, FieldNo("VAT Prod. Posting Group"), '');
                        CheckJobNoIsEmpty(GenJnlLine);
                        if (Amount < 0) and ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") then
                            LogTestField(GenJnlLine, FieldNo("Check Printed"), true);
                        CheckElectronicPaymentFields(GenJnlLine);
                    end;
                "Account Type"::"IC Partner":
                    begin
                        ICPartner.Get("Account No.");
                        ICPartner.CheckICPartner;
                        if "Journal Template Name" <> '' then
                            if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                                LogFieldError(GenJnlLine, GenJnlLine.FieldNo("Account Type"), '');
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
                           not ApplicationAreaMgmt.IsSalesTaxEnabled
                        then
                            LogTestField(GenJnlLine, FieldNo("Bal. Gen. Posting Type"));

                        CheckBalGenProdPostingGroupWhenAdjustForPmtDisc(GenJnlLine);

                        if ("Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" ") and
                           ("VAT Posting" = "VAT Posting"::"Automatic VAT Entry")
                        then begin
                            if "Bal. VAT Amount" + "Bal. VAT Base Amount" <> -Amount then
                                LogError(
                                    GenJnlLine,
                                    StrSubstNo(
                                        Text006, FieldCaption("Bal. VAT Amount"), FieldCaption("Bal. VAT Base Amount"),
                                        FieldCaption(Amount)));
                            if "Currency Code" <> '' then
                                if "Bal. VAT Amount (LCY)" + "Bal. VAT Base Amount (LCY)" <> -"Amount (LCY)" then
                                    LogError(
                                        GenJnlLine,
                                        StrSubstNo(
                                            Text006, FieldCaption("Bal. VAT Amount (LCY)"),
                                            FieldCaption("Bal. VAT Base Amount (LCY)"), FieldCaption("Amount (LCY)")));
                        end;
                    end;
                "Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::Employee:
                    begin
                        LogTestField(GenJnlLine, FieldNo("Bal. Gen. Posting Type"), 0);
                        LogTestField(GenJnlLine, FieldNo("Bal. Gen. Bus. Posting Group"), '');
                        LogTestField(GenJnlLine, FieldNo("Bal. Gen. Prod. Posting Group"), '');
                        LogTestField(GenJnlLine, FieldNo("Bal. VAT Bus. Posting Group"), '');
                        LogTestField(GenJnlLine, FieldNo("Bal. VAT Prod. Posting Group"), '');

                        CheckBalAccountType(GenJnlLine);

                        CheckBalDocType(GenJnlLine);

                        if ((Amount > 0) xor ("Sales/Purch. (LCY)" < 0)) and (Amount <> 0) and ("Sales/Purch. (LCY)" <> 0) then
                            LogFieldError(GenJnlLine, GenJnlLine.FieldNo("Sales/Purch. (LCY)"), StrSubstNo(Text009, FieldCaption(Amount)));
                        CheckJobNoIsEmpty(GenJnlLine);

                        CheckICPartner("Bal. Account Type", "Bal. Account No.", "Document Type");
                    end;
                "Bal. Account Type"::"Bank Account":
                    begin
                        LogTestField(GenJnlLine, FieldNo("Bal. Gen. Posting Type"), 0);
                        LogTestField(GenJnlLine, FieldNo("Bal. Gen. Bus. Posting Group"), '');
                        LogTestField(GenJnlLine, FieldNo("Bal. Gen. Prod. Posting Group"), '');
                        LogTestField(GenJnlLine, FieldNo("Bal. VAT Bus. Posting Group"), '');
                        LogTestField(GenJnlLine, FieldNo("Bal. VAT Prod. Posting Group"), '');
                        if (Amount > 0) and ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") then
                            LogTestField(GenJnlLine, FieldNo("Check Printed"), true);
                        CheckElectronicPaymentFields(GenJnlLine);
                    end;
                "Bal. Account Type"::"IC Partner":
                    begin
                        ICPartner.Get("Bal. Account No.");
                        ICPartner.CheckICPartner;
                        if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                            LogFieldError(GenJnlLine, GenJnlLine.FieldNo("Bal. Account Type"), '');
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
                LogTestField(GenJnlLine, FieldNo("Exported to Payment File"), true);
                LogTestField(GenJnlLine, FieldNo("Check Transmitted"), true);
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

        LogTestField(GenJnlLine, GenJnlLine.FieldNo("Job No."), '');
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
        if not OldCustLedgEntry.IsEmpty then
            LogError(GenJournalLine, StrSubstNo(SalesDocAlreadyExistsErr, GenJournalLine."Document Type", GenJournalLine."Document No."));
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
        if not OldVendLedgEntry.IsEmpty then
            LogError(GenJournalLine, StrSubstNo(PurchDocAlreadyExistsErr, GenJournalLine."Document Type", GenJournalLine."Document No."));
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
                    LogFieldError(GenJnlLine, GenJnlLine.FieldNo("Document Type"), EmployeeAccountDocTypeErr);

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
                    LogFieldError(GenJnlLine, GenJnlLine.FieldNo("Document Type"), EmployeeBalancingDocTypeErr);

                IsPayment := "Document Type" in ["Document Type"::Payment, "Document Type"::"Credit Memo"];
                if IsPayment = ("Bal. Account Type" = "Bal. Account Type"::Customer) then
                    ErrorIfNegativeAmt(GenJnlLine)
                else
                    ErrorIfPositiveAmt(GenJnlLine);
            end;
    end;

    local procedure CheckICPartner(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ICPartner: Record "IC Partner";
        Employee: Record Employee;
        CheckDone: Boolean;
    begin
        OnBeforeCheckICPartner(AccountType, AccountNo, DocumentType.AsInteger(), CheckDone);
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
                ThrowGenJnlLineError(GenJnlLine, Text011, DimMgt.GetDimCombErr);

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

            OnCheckDimensionsOnAfterAssignDimTableIDs(GenJnlLine, TableID, No);

            if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                ThrowGenJnlLineError(GenJnlLine, Text012, DimMgt.GetDimValuePostingErr);
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

        if GenJnlLine.NeedCheckZeroAmount and not (GenJnlLine.IsRecurring and IsBatchMode) then
            LogTestField(GenJnlLine, GenJnlLine.FieldNo(Amount));
    end;

    local procedure IsVendorPaymentToCrMemo(GenJournalLine: Record "Gen. Journal Line") Result: Boolean
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

    local procedure ThrowGenJnlLineError(GenJournalLine: Record "Gen. Journal Line"; ErrorTemplate: Text; ErrorText: Text)
    begin
        if LogErrorMode then
            exit;

        with GenJournalLine do
            if "Line No." <> 0 then
                LogError(
                    GenJournalLine,
                    StrSubstNo(
                        ErrorTemplate,
                        TableCaption, "Journal Template Name", "Journal Batch Name", "Line No.",
                        ErrorText));
        LogError(GenJournalLine, ErrorText);
    end;

    procedure SetBatchMode(NewBatchMode: Boolean)
    begin
        IsBatchMode := NewBatchMode;
    end;

    local procedure CheckGenProdPostingGroupWhenAdjustForPmtDisc(GenJnlLine: Record "Gen. Journal Line")
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
                LogTestField(GenJnlLine, FieldNo("Gen. Prod. Posting Group"));
        end;
    end;

    local procedure CheckBalGenProdPostingGroupWhenAdjustForPmtDisc(GenJnlLine: Record "Gen. Journal Line")
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
                LogTestField(GenJnlLine, FieldNo("Bal. Gen. Prod. Posting Group"));
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
            LogError(
                GenJnlLine,
                StrSubstNo(
                    Text010,
                    GenJnlLine.FieldCaption("Account Type"), GenJnlLine."Account Type",
                    GenJnlLine.FieldCaption("Bal. Gen. Posting Type"), GenJnlLine."Bal. Gen. Posting Type"));
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
            LogError(
                GenJnlLine,
                StrSubstNo(
                    Text010,
                    GenJnlLine.FieldCaption("Bal. Account Type"), GenJnlLine."Bal. Account Type",
                    GenJnlLine.FieldCaption("Gen. Posting Type"), GenJnlLine."Gen. Posting Type"));
    end;

    local procedure LogTestField(SourceVariant: Variant; FieldNo: Integer)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(SourceVariant);
        FldRef := RecRef.Field(FieldNo);
        if LogErrorMode then
            ErrorMessageMgt.LogTestField(SourceVariant, FieldNo)
        else
            FldRef.TestField();
    end;

    local procedure LogTestField(SourceVariant: Variant; FieldNo: Integer; ExpectedValue: Variant)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(SourceVariant);
        FldRef := RecRef.Field(FieldNo);
        if LogErrorMode then
            ErrorMessageMgt.LogTestField(SourceVariant, FieldNo, ExpectedValue)
        else
            FldRef.TestField(ExpectedValue);
    end;

    local procedure LogError(SourceVariant: Variant; ErrorMessage: Text)
    begin
        if LogErrorMode then
            ErrorMessageMgt.LogErrorMessage(0, ErrorMessage, SourceVariant, 0, '')
        else
            Error(ErrorMessage);
    end;

    local procedure LogFieldError(SourceVariant: Variant; FieldNo: Integer; ErrorMessage: Text)
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

        LogTestField(GenJnlLine, GenJnlLine.FieldNo("Applies-to Doc. No."), '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBalAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDateNoAllowed(PostingDate: Date; var DateIsNotAllowed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDateNotAllowed(GenJnlLine: Record "Gen. Journal Line"; var DateCheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAccountNo(var GenJnlLine: Record "Gen. Journal Line"; var CheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBalAccountNo(var GenJnlLine: Record "Gen. Journal Line"; var CheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimensions(var GenJnlLine: Record "Gen. Journal Line"; var CheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocType(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBalDocType(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICPartner(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Option; var CheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesDocNoIsNotUsed(DocType: Option; DocNo: Code[20]; var IsHandled: Boolean; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchDocNoIsNotUsed(DocType: Option; DocNo: Code[20]; var IsHandled: Boolean; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorIfNegativeAmt(GenJnlLine: Record "Gen. Journal Line"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorIfPositiveAmt(GenJnlLine: Record "Gen. Journal Line"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCheck(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDateInFiscalYear(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDimensionsOnAfterAssignDimTableIDs(var GenJournalLine: Record "Gen. Journal Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAccountType(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBalAccountType(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAppliesToDocNo(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJobNoIsEmpty(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckZeroAmount(GenJnlLine: Record "Gen. Journal Line"; IsBatchMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckElectronicPaymentFields(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsVendorPaymentToCrMemo(GenJnlLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

