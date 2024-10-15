#if not CLEAN19
codeunit 1400 DocumentNoVisibility
{
    SingleInstance = true;

    var
        IsCustNoInitialized: Boolean;
        IsVendNoInitialized: Boolean;
        IsEmployeeNoInitialized: Boolean;
        IsItemNoInitialized: Boolean;
        IsBankNoInitialized: Boolean;
        IsFANoInitialized: Boolean;
        IsResNoInitialized: Boolean;
        IsJobNoInitialized: Boolean;
        IsTransferOrdNoInitialized: Boolean;
        IsContactNoInitialized: Boolean;
        CustNoVisible: Boolean;
        VendNoVisible: Boolean;
        EmployeeNoVisible: Boolean;
        ItemNoVisible: Boolean;
        BankNoVisible: Boolean;
        FANoVisible: Boolean;
        ResNoVisible: Boolean;
        JobNoVisible: Boolean;
        TransferOrdNoVisible: Boolean;
        ContactNoVisible: Boolean;
        SalesDocsNoVisible: Dictionary of [Integer, Boolean];
        PurchaseDocsNoVisible: Dictionary of [Integer, Boolean];

    procedure ClearState()
    begin
        IsCustNoInitialized := false;
        IsVendNoInitialized := false;
        IsEmployeeNoInitialized := false;
        IsItemNoInitialized := false;
        IsBankNoInitialized := false;
        IsFANoInitialized := false;
        IsResNoInitialized := false;
        IsJobNoInitialized := false;
        IsTransferOrdNoInitialized := false;
        IsContactNoInitialized := false;
        CustNoVisible := false;
        VendNoVisible := false;
        EmployeeNoVisible := false;
        ItemNoVisible := false;
        BankNoVisible := false;
        FANoVisible := false;
        ResNoVisible := false;
        JobNoVisible := false;
        TransferOrdNoVisible := false;
        ContactNoVisible := false;

        Clear(SalesDocsNoVisible);
        Clear(PurchaseDocsNoVisible);
    end;

    procedure SalesDocumentNoIsVisible(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo; DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        SalesNoSeriesSetup: Page "Sales No. Series Setup";
        DocNoSeries: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeSalesDocumentNoIsVisible(DocType, DocNo, IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if DocNo <> '' then
            exit(false);

        if SalesDocsNoVisible.ContainsKey(DocType) then
            exit(SalesDocsNoVisible.Get(DocType));

        DocNoSeries := DetermineSalesSeriesNo(DocType);
        if not NoSeries.Get(DocNoSeries) then begin
            SalesNoSeriesSetup.SetFieldsVisibility(DocType);
            SalesNoSeriesSetup.RunModal;
            DocNoSeries := DetermineSalesSeriesNo(DocType);
        end;
        Result := ForceShowNoSeriesForDocNo(DocNoSeries);
        SalesDocsNoVisible.Add(DocType, Result);
        exit(Result);
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    procedure PurchaseDocumentNoIsVisible(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order","Advance Letter"; DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        PurchaseNoSeriesSetup: Page "Purchase No. Series Setup";
        DocNoSeries: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforePurchaseDocumentNoIsVisible(DocType, DocNo, IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if DocNo <> '' then
            exit(false);

        if PurchaseDocsNoVisible.ContainsKey(DocType) then
            exit(PurchaseDocsNoVisible.Get(DocType));

        DocNoSeries := DeterminePurchaseSeriesNo(DocType);
        if not NoSeries.Get(DocNoSeries) then begin
            PurchaseNoSeriesSetup.SetFieldsVisibility(DocType);
            PurchaseNoSeriesSetup.RunModal;
            DocNoSeries := DeterminePurchaseSeriesNo(DocType);
        end;
        Result := ForceShowNoSeriesForDocNo(DocNoSeries);
        PurchaseDocsNoVisible.Add(DocType, Result);
        exit(Result);
    end;

    procedure TransferOrderNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeTransferOrderNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsTransferOrdNoInitialized then
            exit(TransferOrdNoVisible);
        IsTransferOrdNoInitialized := true;

        NoSeriesCode := DetermineTransferOrderSeriesNo;
        TransferOrdNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(TransferOrdNoVisible);
    end;

    procedure CustomerNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeCustomerNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsCustNoInitialized then
            exit(CustNoVisible);
        IsCustNoInitialized := true;

        NoSeriesCode := DetermineCustomerSeriesNo;
        CustNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(CustNoVisible);
    end;

    procedure VendorNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeVendorNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsVendNoInitialized then
            exit(VendNoVisible);
        IsVendNoInitialized := true;

        NoSeriesCode := DetermineVendorSeriesNo;
        VendNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(VendNoVisible);
    end;

    procedure ItemNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeItemNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsItemNoInitialized then
            exit(ItemNoVisible);
        IsItemNoInitialized := true;

        NoSeriesCode := DetermineItemSeriesNo;
        ItemNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(ItemNoVisible);
    end;

    procedure FixedAssetNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeFixedAssetNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsFANoInitialized then
            exit(FANoVisible);
        IsFANoInitialized := true;

        NoSeriesCode := DetermineFixedAssetSeriesNo;
        FANoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(FANoVisible);
    end;

    procedure EmployeeNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeEmployeeNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsEmployeeNoInitialized then
            exit(EmployeeNoVisible);
        IsEmployeeNoInitialized := true;

        NoSeriesCode := DetermineEmployeeSeriesNo;
        EmployeeNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(EmployeeNoVisible);
    end;

    procedure BankAccountNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeBankAccountNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsBankNoInitialized then
            exit(BankNoVisible);
        IsBankNoInitialized := true;

        NoSeriesCode := DetermineBankAccountSeriesNo;
        BankNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(BankNoVisible);
    end;

    procedure ResourceNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeResourceNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsResNoInitialized then
            exit(ResNoVisible);
        IsResNoInitialized := true;

        NoSeriesCode := DetermineResourceSeriesNo;
        ResNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(ResNoVisible);
    end;

    procedure JobNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeJobNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsJobNoInitialized then
            exit(JobNoVisible);
        IsJobNoInitialized := true;

        NoSeriesCode := DetermineJobSeriesNo;
        JobNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(JobNoVisible);
    end;

    procedure ContactNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeContactNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsContactNoInitialized then
            exit(ContactNoVisible);
        IsContactNoInitialized := true;

        NoSeriesCode := DetermineContactSeriesNo;
        ContactNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(ContactNoVisible);
    end;

    procedure CustomerNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineCustomerSeriesNo) then
            exit(NoSeries."Default Nos.");

        exit(false);
    end;

    procedure VendorNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineVendorSeriesNo) then
            exit(NoSeries."Default Nos.");

        exit(false);
    end;

    procedure ItemNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineItemSeriesNo) then
            exit(NoSeries."Default Nos.");
    end;

    procedure TransferOrderNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineTransferOrderSeriesNo) then
            exit(NoSeries."Default Nos.");
    end;

    procedure FixedAssetNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineFixedAssetSeriesNo) then
            exit(NoSeries."Default Nos.");
    end;

    procedure EmployeeNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineEmployeeSeriesNo) then
            exit(NoSeries."Default Nos.");
    end;

    local procedure DetermineSalesSeriesNo(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo): Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
    begin
        SalesReceivablesSetup.Get();
        SalesHeader.SetRange("Document Type", DocType);
        case DocType of
            DocType::Quote:
                begin
                    CheckNumberSeries(SalesHeader, SalesReceivablesSetup."Quote Nos.", SalesHeader.FieldNo("No."));
                    exit(SalesReceivablesSetup."Quote Nos.");
                end;
            DocType::Order:
                begin
                    CheckNumberSeries(SalesHeader, SalesReceivablesSetup."Order Nos.", SalesHeader.FieldNo("No."));
                    exit(SalesReceivablesSetup."Order Nos.");
                end;
            DocType::Invoice:
                begin
                    CheckNumberSeries(SalesHeader, SalesReceivablesSetup."Invoice Nos.", SalesHeader.FieldNo("No."));
                    exit(SalesReceivablesSetup."Invoice Nos.");
                end;
            DocType::"Credit Memo":
                begin
                    CheckNumberSeries(SalesHeader, SalesReceivablesSetup."Credit Memo Nos.", SalesHeader.FieldNo("No."));
                    exit(SalesReceivablesSetup."Credit Memo Nos.");
                end;
            DocType::"Blanket Order":
                begin
                    CheckNumberSeries(SalesHeader, SalesReceivablesSetup."Blanket Order Nos.", SalesHeader.FieldNo("No."));
                    exit(SalesReceivablesSetup."Blanket Order Nos.");
                end;
            DocType::"Return Order":
                begin
                    CheckNumberSeries(SalesHeader, SalesReceivablesSetup."Return Order Nos.", SalesHeader.FieldNo("No."));
                    exit(SalesReceivablesSetup."Return Order Nos.");
                end;
            DocType::Reminder:
                begin
                    CheckNumberSeries(SalesHeader, SalesReceivablesSetup."Reminder Nos.", SalesHeader.FieldNo("No."));
                    exit(SalesReceivablesSetup."Reminder Nos.");
                end;
            DocType::FinChMemo:
                begin
                    CheckNumberSeries(SalesHeader, SalesReceivablesSetup."Fin. Chrg. Memo Nos.", SalesHeader.FieldNo("No."));
                    exit(SalesReceivablesSetup."Fin. Chrg. Memo Nos.");
                end;
        end;
    end;

    local procedure DeterminePurchaseSeriesNo(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"): Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchasesPayablesSetup.Get();
        PurchaseHeader.SetRange("Document Type", DocType);
        case DocType of
            DocType::Quote:
                begin
                    CheckNumberSeries(PurchaseHeader, PurchasesPayablesSetup."Quote Nos.", PurchaseHeader.FieldNo("No."));
                    exit(PurchasesPayablesSetup."Quote Nos.");
                end;
            DocType::Order:
                begin
                    CheckNumberSeries(PurchaseHeader, PurchasesPayablesSetup."Order Nos.", PurchaseHeader.FieldNo("No."));
                    exit(PurchasesPayablesSetup."Order Nos.");
                end;
            DocType::Invoice:
                begin
                    CheckNumberSeries(PurchaseHeader, PurchasesPayablesSetup."Invoice Nos.", PurchaseHeader.FieldNo("No."));
                    exit(PurchasesPayablesSetup."Invoice Nos.");
                end;
            DocType::"Credit Memo":
                begin
                    CheckNumberSeries(PurchaseHeader, PurchasesPayablesSetup."Credit Memo Nos.", PurchaseHeader.FieldNo("No."));
                    exit(PurchasesPayablesSetup."Credit Memo Nos.");
                end;
            DocType::"Blanket Order":
                begin
                    CheckNumberSeries(PurchaseHeader, PurchasesPayablesSetup."Blanket Order Nos.", PurchaseHeader.FieldNo("No."));
                    exit(PurchasesPayablesSetup."Blanket Order Nos.");
                end;
            DocType::"Return Order":
                begin
                    CheckNumberSeries(PurchaseHeader, PurchasesPayablesSetup."Return Order Nos.", PurchaseHeader.FieldNo("No."));
                    exit(PurchasesPayablesSetup."Return Order Nos.");
                end;
        end;
    end;

    local procedure DetermineTransferOrderSeriesNo(): Code[20]
    var
        InventorySetup: Record "Inventory Setup";
        TransferHeader: Record "Transfer Header";
    begin
        InventorySetup.Get();
        CheckNumberSeries(TransferHeader, InventorySetup."Transfer Order Nos.", TransferHeader.FieldNo("No."));
        exit(InventorySetup."Transfer Order Nos.");
    end;

    local procedure DetermineCustomerSeriesNo(): Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
    begin
        SalesReceivablesSetup.Get();
        CheckNumberSeries(Customer, SalesReceivablesSetup."Customer Nos.", Customer.FieldNo("No."));
        exit(SalesReceivablesSetup."Customer Nos.");
    end;

    local procedure DetermineVendorSeriesNo(): Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Vendor: Record Vendor;
    begin
        PurchasesPayablesSetup.Get();
        CheckNumberSeries(Vendor, PurchasesPayablesSetup."Vendor Nos.", Vendor.FieldNo("No."));
        exit(PurchasesPayablesSetup."Vendor Nos.");
    end;

    local procedure DetermineItemSeriesNo(): Code[20]
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
    begin
        InventorySetup.Get();
        CheckNumberSeries(Item, InventorySetup."Item Nos.", Item.FieldNo("No."));
        exit(InventorySetup."Item Nos.");
    end;

    local procedure DetermineFixedAssetSeriesNo(): Code[20]
    var
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        FASetup.Get();
        CheckNumberSeries(FixedAsset, FASetup."Fixed Asset Nos.", FixedAsset.FieldNo("No."));
        exit(FASetup."Fixed Asset Nos.");
    end;

    local procedure DetermineEmployeeSeriesNo(): Code[20]
    var
        HumanResourcesSetup: Record "Human Resources Setup";
        Employee: Record Employee;
    begin
        HumanResourcesSetup.Get();
        CheckNumberSeries(Employee, HumanResourcesSetup."Employee Nos.", Employee.FieldNo("No."));
        exit(HumanResourcesSetup."Employee Nos.");
    end;

    local procedure DetermineBankAccountSeriesNo(): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        BankAccount: Record "Bank Account";
    begin
        GeneralLedgerSetup.Get();
        CheckNumberSeries(BankAccount, GeneralLedgerSetup."Bank Account Nos.", BankAccount.FieldNo("No."));
        exit(GeneralLedgerSetup."Bank Account Nos.");
    end;

    local procedure DetermineResourceSeriesNo(): Code[20]
    var
        ResourcesSetup: Record "Resources Setup";
        Resource: Record Resource;
    begin
        ResourcesSetup.Get();
        CheckNumberSeries(Resource, ResourcesSetup."Resource Nos.", Resource.FieldNo("No."));
        exit(ResourcesSetup."Resource Nos.");
    end;

    local procedure DetermineJobSeriesNo(): Code[20]
    var
        JobsSetup: Record "Jobs Setup";
        Job: Record Job;
    begin
        JobsSetup.Get();
        CheckNumberSeries(Job, JobsSetup."Job Nos.", Job.FieldNo("No."));
        exit(JobsSetup."Job Nos.");
    end;

    local procedure DetermineContactSeriesNo(): Code[20]
    var
        MarketingSetup: Record "Marketing Setup";
        Contact: Record Contact;
    begin
        MarketingSetup.Get();
        CheckNumberSeries(Contact, MarketingSetup."Contact Nos.", Contact.FieldNo("No."));
        exit(MarketingSetup."Contact Nos.");
    end;

    procedure ForceShowNoSeriesForDocNo(NoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        NoSeriesRelationship: Record "No. Series Relationship";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        SeriesDate: Date;
    begin
        if not NoSeries.Get(NoSeriesCode) then
            exit(true);

        SeriesDate := WorkDate;
        NoSeriesRelationship.SetRange(Code, NoSeriesCode);
        if not NoSeriesRelationship.IsEmpty() then
            exit(true);

        if NoSeries."Manual Nos." or (NoSeries."Default Nos." = false) then
            exit(true);

        exit(NoSeriesMgt.DoGetNextNo(NoSeriesCode, SeriesDate, false, true) = '');
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SalesAdvanceLetterNoIsVisible(TemplateCode: Code[10]; DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        SalesNoSeriesSetup: Page "Sales No. Series Setup";
        SalesAdvNoSeriesSetup: Page "Sales Adv. No. Series Setup";
        DocNoSeries: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo,"Advance Letter";
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        // NAVCZ
        IsHandled := false;
        IsVisible := false;
        OnBeforeSalesAdvanceLetterNoIsVisible(TemplateCode, DocNo, IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if DocNo <> '' then
            exit(false);

        DocNoSeries := DetermineSalesAdvanceSeriesNo(TemplateCode);

        if not NoSeries.Get(DocNoSeries) then begin
            if TemplateCode <> '' then begin
                SalesAdvNoSeriesSetup.SetTemplateCode(TemplateCode);
                SalesAdvNoSeriesSetup.RunModal;
            end else begin
                SalesNoSeriesSetup.SetFieldsVisibility(DocType::"Advance Letter");
                SalesNoSeriesSetup.RunModal;
            end;

            DocNoSeries := DetermineSalesAdvanceSeriesNo(TemplateCode);
        end;

        exit(ForceShowNoSeriesForDocNo(DocNoSeries));
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure PurchaseAdvanceLetterNoIsVisible(TemplateCode: Code[10]; DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        PurchaseNoSeriesSetup: Page "Purchase No. Series Setup";
        PurchaseAdvNoSeriesSetup: Page "Purchase Adv. No. Series Setup";
        DocNoSeries: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order","Advance Letter";
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        // NAVCZ
        IsHandled := false;
        IsVisible := false;
        OnBeforePurchaseAdvanceLetterNoIsVisible(TemplateCode, DocNo, IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if DocNo <> '' then
            exit(false);

        DocNoSeries := DeterminePurchaseAdvanceSeriesNo(TemplateCode);

        if not NoSeries.Get(DocNoSeries) then begin
            if TemplateCode <> '' then begin
                PurchaseAdvNoSeriesSetup.SetTemplateCode(TemplateCode);
                PurchaseAdvNoSeriesSetup.RunModal;
            end else begin
                PurchaseNoSeriesSetup.SetFieldsVisibility(DocType::"Advance Letter");
                PurchaseNoSeriesSetup.RunModal;
            end;

            DocNoSeries := DeterminePurchaseAdvanceSeriesNo(TemplateCode);
        end;

        exit(ForceShowNoSeriesForDocNo(DocNoSeries));
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    local procedure DetermineSalesAdvanceSeriesNo(TemplateCode: Code[10]): Code[20]
    var
        SalesAdvPaymentTemplate: Record "Sales Adv. Payment Template";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        NoSeriesCode: Code[20];
    begin
        // NAVCZ
        if TemplateCode <> '' then begin
            SalesAdvPaymentTemplate.Get(TemplateCode);
            NoSeriesCode := SalesAdvPaymentTemplate."Advance Letter Nos.";
        end else begin
            SalesReceivablesSetup.Get();
            NoSeriesCode := SalesReceivablesSetup."Advance Letter Nos.";
        end;

        CheckNumberSeries(SalesAdvanceLetterHeader, NoSeriesCode, SalesAdvanceLetterHeader.FieldNo("No."));
        exit(NoSeriesCode);
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    local procedure DeterminePurchaseAdvanceSeriesNo(TemplateCode: Code[10]): Code[20]
    var
        PurchaseAdvPaymentTemplate: Record "Purchase Adv. Payment Template";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        NoSeriesCode: Code[20];
    begin
        // NAVCZ
        if TemplateCode <> '' then begin
            PurchaseAdvPaymentTemplate.Get(TemplateCode);
            NoSeriesCode := PurchaseAdvPaymentTemplate."Advance Letter Nos.";
        end else begin
            PurchasesPayablesSetup.Get();
            NoSeriesCode := PurchasesPayablesSetup."Advance Letter Nos.";
        end;

        CheckNumberSeries(PurchAdvanceLetterHeader, NoSeriesCode, PurchAdvanceLetterHeader.FieldNo("No."));
        exit(NoSeriesCode);
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure BankDocumentNoIsVisible(BankAccNo: Code[20]; DocType: Option "Bank Statement","Payment Order"; DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        BankNoSeriesSetup: Page "Bank No. Series Setup";
        DocNoSeries: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        // NAVCZ
        IsHandled := false;
        IsVisible := false;
        OnBeforeBankDocumentNoIsVisible(BankAccNo, DocType, DocNo, IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if DocNo <> '' then
            exit(false);

        if BankAccNo = '' then
            exit(true);

        DocNoSeries := DetermineBankSeriesNo(BankAccNo, DocType);

        if not NoSeries.Get(DocNoSeries) then begin
            BankNoSeriesSetup.SetFieldsVisibility(DocType);
            BankNoSeriesSetup.SetBankAccountNo(BankAccNo);
            BankNoSeriesSetup.RunModal;
            DocNoSeries := DetermineBankSeriesNo(BankAccNo, DocType);
        end;

        exit(ForceShowNoSeriesForDocNo(DocNoSeries));
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    local procedure DetermineBankSeriesNo(BankAccNo: Code[20]; DocType: Option "Bank Statement","Payment Order"): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankStatementHeader: Record "Bank Statement Header";
        PaymentOrderHeader: Record "Payment Order Header";
    begin
        // NAVCZ
        BankAccount.Get(BankAccNo);
        case DocType of
            DocType::"Bank Statement":
                begin
                    CheckNumberSeries(BankStatementHeader, BankAccount."Bank Statement Nos.", BankStatementHeader.FieldNo("No."));
                    exit(BankAccount."Bank Statement Nos.");
                end;
            DocType::"Payment Order":
                begin
                    CheckNumberSeries(PaymentOrderHeader, BankAccount."Payment Order Nos.", PaymentOrderHeader.FieldNo("No."));
                    exit(BankAccount."Payment Order Nos.");
                end;
        end;
    end;

#if not CLEAN18
    [Scope('OnPrem')]
    [Obsolete('Moved to Compensation Localization Pack for Czech.', '18.0')]
    procedure CreditCardNoIsVisible(DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        DocNoSeries: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        // NAVCZ
        IsHandled := false;
        IsVisible := false;
        OnBeforeCreditCardNoIsVisible(DocNo, IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if DocNo <> '' then
            exit(false);

        DocNoSeries := DetermineCreditSeriesNo;

        if not NoSeries.Get(DocNoSeries) then begin
            PAGE.RunModal(PAGE::"Credits No. Series Setup");
            DocNoSeries := DetermineCreditSeriesNo;
        end;

        exit(ForceShowNoSeriesForDocNo(DocNoSeries));
    end;

    local procedure DetermineCreditSeriesNo(): Code[20]
    var
        CreditsSetup: Record "Credits Setup";
        CreditHeader: Record "Credit Header";
    begin
        // NAVCZ
        CreditsSetup.Get();
        CheckNumberSeries(CreditHeader, CreditsSetup."Credit Nos.", CreditHeader.FieldNo("No."));
        exit(CreditsSetup."Credit Nos.");
    end;

#endif
#if not CLEAN17
    [Obsolete('Moved to Core Localization Pack for Czech.', '17.0')]
    [Scope('OnPrem')]
    procedure StatReportingDocumentNoIsVisible(DocType: Option "VIES Declaration","Reverse Charge","VAT Control Report"; DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        StatRepNoSeriesSetup: Page "Stat. Rep. No. Series Setup";
        DocNoSeries: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        // NAVCZ
        IsHandled := false;
        IsVisible := false;
        OnBeforeStatReportingDocumentNoIsVisible(DocType, DocNo, IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if DocNo <> '' then
            exit(false);

        DocNoSeries := DetermineStatReportingSeriesNo(DocType);

        if not NoSeries.Get(DocNoSeries) then begin
            StatRepNoSeriesSetup.SetFieldsVisibility(DocType);
            StatRepNoSeriesSetup.RunModal;
            DocNoSeries := DetermineStatReportingSeriesNo(DocType);
        end;

        exit(ForceShowNoSeriesForDocNo(DocNoSeries));
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.0')]
    local procedure DetermineStatReportingSeriesNo(DocType: Option "VIES Declaration","Reverse Charge","VAT Control Report"): Code[20]
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        VIESDeclarationHeader: Record "VIES Declaration Header";
        VATControlReportHeader: Record "VAT Control Report Header";
    begin
        // NAVCZ
        StatReportingSetup.Get();
        case DocType of
            DocType::"VIES Declaration":
                begin
                    CheckNumberSeries(VIESDeclarationHeader, StatReportingSetup."VIES Declaration Nos.", VIESDeclarationHeader.FieldNo("No."));
                    exit(StatReportingSetup."VIES Declaration Nos.");
                end;
            DocType::"VAT Control Report":
                begin
                    CheckNumberSeries(VATControlReportHeader, StatReportingSetup."VAT Control Report Nos.", VATControlReportHeader.FieldNo("No."));
                    exit(StatReportingSetup."VAT Control Report Nos.");
                end;
        end;
    end;

#endif
    procedure CheckNumberSeries(RecVariant: Variant; NoSeriesCode: Code[20]; FieldNo: Integer)
    var
        NoSeries: Record "No. Series";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        NewNo: Code[20];
    begin
        OnBeforeCheckNumberSeries(RecVariant, NoSeriesCode, FieldNo, NoSeries);
        if RecVariant.IsRecord and (NoSeriesCode <> '') and NoSeries.Get(NoSeriesCode) then begin
            NewNo := NoSeriesMgt.DoGetNextNo(NoSeriesCode, 0D, false, true);
            RecRef.GetTable(RecVariant);
            FieldRef := RecRef.Field(FieldNo);
            FieldRef.SetRange(NewNo);
            if RecRef.FindFirst then begin
                NoSeriesMgt.SaveNoSeries;
                CheckNumberSeries(RecRef, NoSeriesCode, FieldNo);
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNumberSeries(var RecVariant: Variant; var NoSeriesCode: Code[20]; FieldNo: Integer; var NoSeries: Record "No. Series")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesDocumentNoIsVisible(DocType: Option; DocNo: Code[20]; var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseDocumentNoIsVisible(DocType: Option; DocNo: Code[20]; var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferOrderNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustomerNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendorNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFixedAssetNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmployeeNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBankAccountNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResourceNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesAdvanceLetterNoIsVisible(TemplateCode: Code[10]; DocNo: code[20]; var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseAdvanceLetterNoIsVisible(TemplateCode: Code[10]; DocNo: code[20]; var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeBankDocumentNoIsVisible(BankAccNo: Code[20]; DocType: Option; DocNo: Code[20]; var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;
#if not CLEAN18

    [Obsolete('Moved to Compensation Localization Pack for Czech.', '18.2')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreditCardNoIsVisible(DocNo: Code[20]; var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.2')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeStatReportingDocumentNoIsVisible(DocType: Option; DocNo: Code[20]; var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif
}

#endif