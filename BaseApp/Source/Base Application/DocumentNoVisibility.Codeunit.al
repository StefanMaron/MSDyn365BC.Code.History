codeunit 1400 DocumentNoVisibility
{

    trigger OnRun()
    begin
    end;

    procedure SalesDocumentNoIsVisible(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo; DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        SalesNoSeriesSetup: Page "Sales No. Series Setup";
        DocNoSeries: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeSalesDocumentNoIsVisible(DocType, DocNo, IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if DocNo <> '' then
            exit(false);

        DocNoSeries := DetermineSalesSeriesNo(DocType);

        if not NoSeries.Get(DocNoSeries) then begin
            SalesNoSeriesSetup.SetFieldsVisibility(DocType);
            SalesNoSeriesSetup.RunModal;
            DocNoSeries := DetermineSalesSeriesNo(DocType);
        end;

        exit(ForceShowNoSeriesForDocNo(DocNoSeries));
    end;

    procedure PurchaseDocumentNoIsVisible(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        PurchaseNoSeriesSetup: Page "Purchase No. Series Setup";
        DocNoSeries: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforePurchaseDocumentNoIsVisible(DocType, DocNo, IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if DocNo <> '' then
            exit(false);

        DocNoSeries := DeterminePurchaseSeriesNo(DocType);

        if not NoSeries.Get(DocNoSeries) then begin
            PurchaseNoSeriesSetup.SetFieldsVisibility(DocType);
            PurchaseNoSeriesSetup.RunModal;
            DocNoSeries := DeterminePurchaseSeriesNo(DocType);
        end;

        exit(ForceShowNoSeriesForDocNo(DocNoSeries));
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

        NoSeriesCode := DetermineTransferOrderSeriesNo;
        exit(ForceShowNoSeriesForDocNo(NoSeriesCode));
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

        NoSeriesCode := DetermineCustomerSeriesNo;
        exit(ForceShowNoSeriesForDocNo(NoSeriesCode));
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

        NoSeriesCode := DetermineVendorSeriesNo;
        exit(ForceShowNoSeriesForDocNo(NoSeriesCode));
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

        NoSeriesCode := DetermineItemSeriesNo;
        exit(ForceShowNoSeriesForDocNo(NoSeriesCode));
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

        NoSeriesCode := DetermineFixedAssetSeriesNo;
        exit(ForceShowNoSeriesForDocNo(NoSeriesCode));
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

        NoSeriesCode := DetermineEmployeeSeriesNo;
        exit(ForceShowNoSeriesForDocNo(NoSeriesCode));
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

        NoSeriesCode := DetermineBankAccountSeriesNo;
        exit(ForceShowNoSeriesForDocNo(NoSeriesCode));
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

        NoSeriesCode := DetermineResourceSeriesNo;
        exit(ForceShowNoSeriesForDocNo(NoSeriesCode));
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

        NoSeriesCode := DetermineJobSeriesNo;
        exit(ForceShowNoSeriesForDocNo(NoSeriesCode));
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

        NoSeriesCode := DetermineContactSeriesNo;
        exit(ForceShowNoSeriesForDocNo(NoSeriesCode));
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
        if not NoSeriesRelationship.IsEmpty then
            exit(true);

        if NoSeries."Manual Nos." or (NoSeries."Default Nos." = false) then
            exit(true);

        exit(NoSeriesMgt.DoGetNextNo(NoSeriesCode, SeriesDate, false, true) = '');
    end;

    procedure CheckNumberSeries(RecVariant: Variant; NoSeriesCode: Code[20]; FieldNo: Integer)
    var
        NoSeries: Record "No. Series";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        NewNo: Code[20];
    begin
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
}

