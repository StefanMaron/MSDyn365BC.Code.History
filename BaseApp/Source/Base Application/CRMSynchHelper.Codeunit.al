codeunit 5342 "CRM Synch. Helper"
{
    Permissions = TableData "Sales Invoice Header" = m;

    trigger OnRun()
    begin
    end;

    var
        TempCRMPricelevel: Record "CRM Pricelevel" temporary;
        TempCRMTransactioncurrency: Record "CRM Transactioncurrency" temporary;
        TempCRMUom: Record "CRM Uom" temporary;
        TempCRMUomschedule: Record "CRM Uomschedule" temporary;
        CRMProductName: Codeunit "CRM Product Name";
        CRMBaseCurrencyNotFoundInNAVErr: Label 'The currency with the ISO code ''%1'' cannot be found. Therefore, the exchange rate between ''%2'' and ''%3'' cannot be calculated.', Comment = '%1,%2,%3=the ISO code of a currency (example: DKK);';
        DynamicsCRMTransactionCurrencyRecordNotFoundErr: Label 'Cannot find the currency with the value ''%1'' in Common Data Service.', Comment = '%1=the currency code';
        DynamicsCRMUoMNotFoundInGroupErr: Label 'Cannot find any unit of measure inside the unit group ''%1'' in %2.', Comment = '%1=Unit Group Name, %2 = CRM product name';
        DynamicsCRMUoMFoundMultipleInGroupErr: Label 'Multiple units of measure were found in the unit group ''%1'' in %2.', Comment = '%1=Unit Group Name, %2 = CRM product name';
        IncorrectCRMUoMNameErr: Label 'The unit of measure in the unit group ''%1'' has an incorrect name: expected name ''%2'', found name ''%3''.', Comment = '%1=Unit Group name (ex: NAV PIECE), %2=Expected name (ex: PIECE), %3=Actual name (ex: BOX)';
        IncorrectCRMUoMQuantityErr: Label 'The quantity on the unit of measure ''%1'' should be 1.', Comment = '%1=unit of measure name (ex: PIECE).';
        DynamicsCRMUomscheduleNotFoundErr: Label 'Cannot find the unit group ''%1'' in %2.', Comment = '%1 = unit group name, %2 = CRM product name';
        IncorrectCRMUoMStatusErr: Label 'The unit of measure ''%1'' is not the base unit of measure of the unit group ''%2''.', Comment = '%1=value of the unit of measure, %2=value of the unit group';
        InvalidDestinationRecordNoErr: Label 'Invalid destination record number.';
        NavTxt: Label 'NAV', Locked = true;
        RecordMustBeCoupledErr: Label '%1 %2 must be coupled to a %3 record.', Comment = '%1 = table caption, %2 = primary key value, %3 = CRM Table caption';
        RecordNotFoundErr: Label '%1 could not be found in %2.', Comment = '%1=value;%2=table name in which the value was searched';
        CanOnlyUseSystemUserOwnerTypeErr: Label 'Only %1 Owner of Type SystemUser can be mapped to Salespeople.', Comment = 'Dynamics CRM entity owner property can be of type team or systemuser. Only the type systemuser is supported. %1 = CRM product name';
        DefaultNAVPriceListNameTxt: Label '%1 Default Price List', Comment = '%1 - product name';
        BaseCurrencyIsNullErr: Label 'The base currency is not defined. Disable and enable CRM connection to initialize setup properly.';
        CurrencyPriceListNameTxt: Label 'Price List in %1', Comment = '%1 - currency code';
        UnableToFindPageForRecordErr: Label 'Unable to find a page for record %1.', Comment = '%1 ID of the record';
        MappingMustBeSetForGUIDFieldErr: Label 'Table %1 must be mapped to table %2 to transfer value between fields %3  and %4.', Comment = '%1 and %2 are table IDs, %3 and %4 are field captions.';

    procedure ClearCache()
    begin
        TempCRMPricelevel.Reset();
        TempCRMPricelevel.DeleteAll();
        Clear(TempCRMPricelevel);

        TempCRMTransactioncurrency.Reset();
        TempCRMTransactioncurrency.DeleteAll();
        Clear(TempCRMTransactioncurrency);

        TempCRMUom.Reset();
        TempCRMUom.DeleteAll();
        Clear(TempCRMUom);

        TempCRMUomschedule.Reset();
        TempCRMUomschedule.DeleteAll();
        Clear(TempCRMUomschedule);
    end;

    [Obsolete('Use GetDefaultPriceListName instead', '15.2')]
    procedure GetDefaultNAVPriceListName(): Text[50]
    begin
        exit(StrSubstNo(DefaultNAVPriceListNameTxt, PRODUCTNAME.Short()));
    end;

    procedure GetDefaultPriceListName(): Text[100]
    begin
        exit(StrSubstNo(DefaultNAVPriceListNameTxt, PRODUCTNAME.Short()));
    end;

    local procedure CreateCRMDefaultPriceList(var CRMPricelevel: Record "CRM Pricelevel")
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        with CRMPricelevel do begin
            Reset();
            SetRange(Name, GetDefaultPriceListName());
            if not FindFirst() then begin
                Init();
                Name := GetDefaultPriceListName();
                FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);
                TransactionCurrencyId := CRMTransactioncurrency.TransactionCurrencyId;
                TransactionCurrencyIdName := CRMTransactioncurrency.CurrencyName;
                Insert();

                AddToCacheCRMPriceLevel(CRMPricelevel);
            end;
        end;
    end;

    procedure CreateCRMPricelevelInCurrency(var CRMPricelevel: Record "CRM Pricelevel"; CurrencyCode: Code[10]; NewExchangeRate: Decimal)
    var
        CRMOrganization: Record "CRM Organization";
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMOrganization.FindFirst();
        FindCurrencyCRMIntegrationRecord(CRMIntegrationRecord, CurrencyCode);

        with CRMPricelevel do begin
            Init();
            PriceLevelId := Format(CreateGuid());
            OrganizationId := CRMOrganization.OrganizationId;
            Name :=
              CopyStr(StrSubstNo(CurrencyPriceListNameTxt, CurrencyCode), 1, MaxStrLen(Name));
            TransactionCurrencyId := CRMIntegrationRecord."CRM ID";
            ExchangeRate := NewExchangeRate;
            Insert();
        end;
    end;

    local procedure CreateCRMProductpricelevelForProduct(CRMProduct: Record "CRM Product"; NewPriceLevelId: Guid)
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        with CRMProductpricelevel do begin
            Init();
            PriceLevelId := NewPriceLevelId;
            UoMId := CRMProduct.DefaultUoMId;
            UoMScheduleId := CRMProduct.DefaultUoMScheduleId;
            ProductId := CRMProduct.ProductId;
            Amount := CRMProduct.Price;
            TransactionCurrencyId := CRMProduct.TransactionCurrencyId;
            ProductNumber := CRMProduct.ProductNumber;
            Insert();
        end;
    end;

    procedure CreateCRMProductpriceIfAbsent(CRMInvoicedetail: Record "CRM Invoicedetail")
    begin
        if not IsNullGuid(CRMInvoicedetail.ProductId) then
            if not FindCRMProductPriceFromCRMInvoicedetail(CRMInvoicedetail) then
                CreateCRMProductpriceFromCRMInvoiceDetail(CRMInvoicedetail);
    end;

    local procedure CreateCRMProductpriceFromCRMInvoiceDetail(CRMInvoicedetail: Record "CRM Invoicedetail")
    var
        CRMInvoice: Record "CRM Invoice";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMUom: Record "CRM Uom";
    begin
        CRMInvoice.Get(CRMInvoicedetail.InvoiceId);
        CRMUom.Get(CRMInvoicedetail.UoMId);
        with CRMProductpricelevel do begin
            Init();
            PriceLevelId := CRMInvoice.PriceLevelId;
            ProductId := CRMInvoicedetail.ProductId;
            UoMId := CRMInvoicedetail.UoMId;
            UoMScheduleId := CRMUom.UoMScheduleId;
            Amount := CRMInvoicedetail.PricePerUnit;
            Insert();
        end;
    end;

    local procedure CreateCRMTransactioncurrency(var CRMTransactioncurrency: Record "CRM Transactioncurrency"; CurrencyCode: Code[10])
    begin
        with CRMTransactioncurrency do begin
            Init();
            ISOCurrencyCode := CopyStr(CurrencyCode, 1, MaxStrLen(ISOCurrencyCode));
            CurrencyName := ISOCurrencyCode;
            CurrencySymbol := ISOCurrencyCode;
            CurrencyPrecision := GetCRMCurrencyDefaultPrecision();
            ExchangeRate := GetCRMLCYToFCYExchangeRate(ISOCurrencyCode);
            Insert();
        end;
    end;

    procedure FindCRMDefaultPriceList(var CRMPricelevel: Record "CRM Pricelevel")
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        with CRMConnectionSetup do begin
            Get();
            if not FindCRMPriceList(CRMPricelevel, "Default CRM Price List ID") then begin
                CreateCRMDefaultPriceList(CRMPricelevel);
                Validate("Default CRM Price List ID", CRMPricelevel.PriceLevelId);
                Modify();
            end;
        end;
    end;

    local procedure FindCRMPriceList(var CRMPricelevel: Record "CRM Pricelevel"; PriceListId: Guid): Boolean
    begin
        if not IsNullGuid(PriceListId) then begin
            CRMPricelevel.Reset();
            CRMPricelevel.SetRange(PriceLevelId, PriceListId);
            exit(FindCachedCRMPriceLevel(CRMPricelevel));
        end;
    end;

    procedure FindCRMPriceListByCurrencyCode(var CRMPricelevel: Record "CRM Pricelevel"; CurrencyCode: Code[10]): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if CurrencyCode = '' then begin
            FindCRMDefaultPriceList(CRMPricelevel);
            exit(true);
        end;

        FindCurrencyCRMIntegrationRecord(CRMIntegrationRecord, CurrencyCode);
        CRMPricelevel.Reset();
        CRMPricelevel.SetRange(TransactionCurrencyId, CRMIntegrationRecord."CRM ID");
        exit(FindCachedCRMPriceLevel(CRMPricelevel));
    end;

    procedure FindCRMProductPriceFromCRMInvoicedetail(CRMInvoicedetail: Record "CRM Invoicedetail"): Boolean
    var
        CRMInvoice: Record "CRM Invoice";
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        CRMInvoice.Get(CRMInvoicedetail.InvoiceId);
        CRMProductpricelevel.SetRange(PriceLevelId, CRMInvoice.PriceLevelId);
        CRMProductpricelevel.SetRange(ProductId, CRMInvoicedetail.ProductId);
        CRMProductpricelevel.SetRange(UoMId, CRMInvoicedetail.UoMId);
        exit(not CRMProductpricelevel.IsEmpty());
    end;

    local procedure FindCurrencyCRMIntegrationRecord(var CRMIntegrationRecord: Record "CRM Integration Record"; CurrencyCode: Code[10])
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        Currency.Get(CurrencyCode);
        if not CRMIntegrationRecord.FindByRecordID(Currency.RecordId()) then
            Error(RecordMustBeCoupledErr, Currency.TableCaption(), CurrencyCode, CRMTransactioncurrency.TableCaption());
    end;

    local procedure FindContactByAccountId(var Contact: Record Contact; AccountId: Guid): Boolean
    var
        IsVendorsSyncEnabled: Boolean;
    begin
        if FindCustomersContactByAccountId(Contact, AccountId) then
            exit(true);

        OnGetVendorSyncEnabled(IsVendorsSyncEnabled);
        if IsVendorsSyncEnabled then
            if FindVendorsContactByAccountId(Contact, AccountId) then
                exit(true);

        exit(false);
    end;

    local procedure FindCustomersContactByAccountId(var Contact: Record Contact; AccountId: Guid): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        CustomerRecordID: RecordID;
        OutOfMapFilter: Boolean;
    begin
        if IsNullGuid(AccountId) then
            exit(false);

        if not CRMIntegrationRecord.FindRecordIDFromID(AccountId, DATABASE::Customer, CustomerRecordID) then
            if SynchRecordIfMappingExists(DATABASE::"CRM Account", AccountId, OutOfMapFilter) then begin
                if not CRMIntegrationRecord.FindRecordIDFromID(AccountId, DATABASE::Customer, CustomerRecordID) then
                    exit(false);
            end else
                if OutOfMapFilter then
                    exit(true);

        if Customer.Get(CustomerRecordID) then begin
            ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
            ContactBusinessRelation.SetRange("No.", Customer."No.");
            if ContactBusinessRelation.FindFirst() then
                exit(Contact.Get(ContactBusinessRelation."Contact No."));
        end;
    end;

    local procedure FindVendorsContactByAccountId(var Contact: Record Contact; AccountId: Guid): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Vendor: Record Vendor;
        VendorRecordID: RecordID;
        OutOfMapFilter: Boolean;
    begin
        if IsNullGuid(AccountId) then
            exit(false);

        if not CRMIntegrationRecord.FindRecordIDFromID(AccountId, DATABASE::Vendor, VendorRecordID) then
            if SynchRecordIfMappingExists(DATABASE::"CRM Account", AccountId, OutOfMapFilter) then begin
                if not CRMIntegrationRecord.FindRecordIDFromID(AccountId, DATABASE::Vendor, VendorRecordID) then
                    exit(false);
            end else
                if OutOfMapFilter then
                    exit(true);

        if Vendor.Get(VendorRecordID) then begin
            ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
            ContactBusinessRelation.SetRange("No.", Vendor."No.");
            if ContactBusinessRelation.FindFirst() then
                exit(Contact.Get(ContactBusinessRelation."Contact No."));
        end;
    end;

    procedure FindNAVLocalCurrencyInCRM(var CRMTransactioncurrency: Record "CRM Transactioncurrency"): Guid
    var
        NAVLCYCode: Code[10];
    begin
        NAVLCYCode := GetNavLCYCode();
        CRMTransactioncurrency.SetRange(ISOCurrencyCode, NAVLCYCode);
        if not FindCachedCRMTransactionCurrency(CRMTransactioncurrency) then begin
            CreateCRMTransactioncurrency(CRMTransactioncurrency, NAVLCYCode);
            AddToCacheCRMTransactionCurrency(CRMTransactioncurrency);
        end;
        exit(CRMTransactioncurrency.TransactionCurrencyId);
    end;

    procedure GetBaseCurrencyPrecision() DecimalPrecision: Decimal
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        BaseCurrencyPrecision: integer;
        handled: Boolean;
    begin
        DecimalPrecision := 1;
        OnGetCDSBaseCurrencyPrecision(BaseCurrencyPrecision, handled);

        if not handled then begin
            CRMConnectionSetup.Get();
            BaseCurrencyPrecision := CRMConnectionSetup.BaseCurrencyPrecision;
        end;

        if BaseCurrencyPrecision > 0 then
            DecimalPrecision := Power(10, -BaseCurrencyPrecision);
    end;

    procedure GetCRMCurrencyDefaultPrecision(): Integer
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CurrencyDecimalPrecision: Integer;
        handled: Boolean;
    begin
        OnGetCDSCurrencyDecimalPrecision(CurrencyDecimalPrecision, handled);

        if handled then
            exit(CurrencyDecimalPrecision);

        CRMConnectionSetup.Get();
        exit(CRMConnectionSetup.CurrencyDecimalPrecision);
    end;

    local procedure GetCRMBaseCurrencyId(): Guid
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        BaseCurrencyId: Guid;
        handled: Boolean;
    begin
        OnGetCDSBaseCurrencyId(BaseCurrencyId, handled);

        if handled then
            exit(BaseCurrencyId);

        CRMConnectionSetup.Get();
        exit(CRMConnectionSetup.BaseCurrencyId);
    end;

    local procedure GetCRMBaseCurrencySymbol(): Text[5]
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        BaseCurrencySymbol: Text[5];
        handled: Boolean;
    begin
        OnGetCDSBaseCurrencySymbol(BaseCurrencySymbol, handled);

        if handled then
            exit(BaseCurrencySymbol);

        CRMConnectionSetup.Get();
        exit(CRMConnectionSetup.BaseCurrencySymbol);
    end;

    local procedure GetCRMExchangeRateRoundingPrecision(): Decimal
    begin
        exit(0.0000000001);
    end;

    procedure GetCRMLCYToFCYExchangeRate(ToCurrencyISOCode: Text[10]): Decimal
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        BaseCurrencyId: Guid;
        BaseCurrencySymbol: Text[5];
    begin
        BaseCurrencyId := GetCRMBaseCurrencyId();
        BaseCurrencySymbol := GetCRMBaseCurrencySymbol();
        if IsNullGuid(BaseCurrencyId) then
            Error(BaseCurrencyIsNullErr);
        if ToCurrencyISOCode = DelChr(BaseCurrencySymbol) then
            exit(1.0);

        CRMTransactioncurrency.SetRange(TransactionCurrencyId, BaseCurrencyId);
        if not FindCachedCRMTransactionCurrency(CRMTransactioncurrency) then
            Error(DynamicsCRMTransactionCurrencyRecordNotFoundErr, BaseCurrencySymbol);
        exit(GetFCYtoFCYExchangeRate(CRMTransactioncurrency.ISOCurrencyCode, ToCurrencyISOCode));
    end;

    procedure GetFCYtoFCYExchangeRate(FromFCY: Code[10]; ToFCY: Code[10]): Decimal
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CalculatedExchangeRate: Decimal;
        NavLCYCode: Code[10];
    begin
        FromFCY := DelChr(FromFCY);
        ToFCY := DelChr(ToFCY);
        if (FromFCY = '') or (ToFCY = '') then
            Error(CRMBaseCurrencyNotFoundInNAVErr, '', ToFCY, FromFCY);

        if ToFCY = FromFCY then
            exit(1.0);

        NavLCYCode := GetNavLCYCode();
        if ToFCY = NavLCYCode then
            ToFCY := '';

        if FromFCY = NavLCYCode then
            exit(CurrencyExchangeRate.GetCurrentCurrencyFactor(ToFCY));

        if not Currency.Get(FromFCY) then
            Error(CRMBaseCurrencyNotFoundInNAVErr, FromFCY, ToFCY, FromFCY);

        // In CRM exchange rate is inverted, so ExchangeAmtFCYToFCY takes (ToFCY,FromFCY) instead of (FromFCY,ToFCY)
        CalculatedExchangeRate := CurrencyExchangeRate.ExchangeAmtFCYToFCY(WorkDate(), ToFCY, FromFCY, 1);
        CalculatedExchangeRate := Round(CalculatedExchangeRate, GetCRMExchangeRateRoundingPrecision(), '=');
        exit(CalculatedExchangeRate);
    end;

    local procedure GetNavLCYCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("LCY Code");
        exit(GeneralLedgerSetup."LCY Code");
    end;

    procedure GetUnitGroupName(UnitOfMeasureCode: Text): Text[200]
    begin
        exit(CopyStr(StrSubstNo('%1 %2', NavTxt, UnitOfMeasureCode), 1, 200));
    end;

    procedure GetUnitOfMeasureName(UnitOfMeasureRecordRef: RecordRef): Text[100]
    var
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasureCodeFieldRef: FieldRef;
    begin
        UnitOfMeasureCodeFieldRef := UnitOfMeasureRecordRef.Field(UnitOfMeasure.FieldNo(Code));
        exit(CopyStr(Format(UnitOfMeasureCodeFieldRef.Value()), 1, 100));
    end;

    procedure SetCRMDecimalsSupportedValue(var CRMProduct: Record "CRM Product")
    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        CRMProduct.QuantityDecimal := CRMSetupDefaults.GetProductQuantityPrecision();
    end;

    procedure SetCRMDefaultPriceListOnProduct(var CRMProduct: Record "CRM Product") AdditionalFieldsWereModified: Boolean
    var
        CRMPricelevel: Record "CRM Pricelevel";
    begin
        FindCRMDefaultPriceList(CRMPricelevel);

        if CRMProduct.PriceLevelId <> CRMPricelevel.PriceLevelId then begin
            CRMProduct.PriceLevelId := CRMPricelevel.PriceLevelId;
            AdditionalFieldsWereModified := true;
        end;
    end;

    procedure SetCRMProductStateToActive(var CRMProduct: Record "CRM Product")
    begin
        CRMProduct.StateCode := CRMProduct.StateCode::Active;
        CRMProduct.StatusCode := CRMProduct.StatusCode::Active;
    end;

    procedure SetCRMProductStateToRetired(var CRMProduct: Record "CRM Product")
    begin
        CRMProduct.StateCode := CRMProduct.StateCode::Retired;
        CRMProduct.StatusCode := CRMProduct.StatusCode::Retired;
    end;

    procedure SetContactParentCompany(AccountID: Guid; DestinationContactRecordRef: RecordRef): Boolean
    var
        CompanyContact: Record Contact;
        DestinationFieldRef: FieldRef;
        Result: Boolean;
    begin
        if DestinationContactRecordRef.Number() <> DATABASE::Contact then
            Error(InvalidDestinationRecordNoErr);

        Result := FindContactByAccountId(CompanyContact, AccountID);
        DestinationFieldRef := DestinationContactRecordRef.Field(CompanyContact.FieldNo("Company No."));
        DestinationFieldRef.Value := CompanyContact."No.";
        DestinationFieldRef := DestinationContactRecordRef.Field(CompanyContact.FieldNo("Company Name"));
        DestinationFieldRef.Value := CompanyContact.Name;
        exit(Result);
    end;

    procedure SynchRecordIfMappingExists(TableNo: Integer; PrimaryKey: Variant; var OutOfMapFilter: Boolean): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        NewJobEntryId: Guid;
    begin
        if IntegrationTableMapping.FindMapping(TableNo, PrimaryKey) then begin
            NewJobEntryId := CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, PrimaryKey, true, false);
            OutOfMapFilter := CRMIntegrationTableSynch.GetOutOfMapFilter();
        end;

        if IsNullGuid(NewJobEntryId) then
            exit(false);
        if IntegrationSynchJob.Get(NewJobEntryId) then
            exit(
              (IntegrationSynchJob.Inserted > 0) or
              (IntegrationSynchJob.Modified > 0) or
              (IntegrationSynchJob.Unchanged > 0));
    end;

    procedure UpdateCRMCurrencyIdIfChanged(CurrencyCode: Text; var DestinationCurrencyIDFieldRef: FieldRef): Boolean
    begin
        // Given a source NAV currency code, find a currency with the same ISO code in CRM and update the target CRM currency value if needed
        exit(UpdateFieldRefValueIfChanged(DestinationCurrencyIDFieldRef, GetCRMTransactioncurrency(CurrencyCode)));
    end;

    procedure UpdateCRMInvoiceStatus(var CRMInvoice: Record "CRM Invoice"; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        if CustLedgerEntry.FindFirst() then
            UpdateCRMInvoiceStatusFromEntry(CRMInvoice, CustLedgerEntry);
    end;

    procedure UpdateCRMInvoiceStatusFromEntry(var CRMInvoice: Record "CRM Invoice"; CustLedgerEntry: Record "Cust. Ledger Entry"): Integer
    var
        NewCRMInvoice: Record "CRM Invoice";
    begin
        with CRMInvoice do begin
            CalculateActualStatusCode(CustLedgerEntry, NewCRMInvoice);
            if (NewCRMInvoice.StateCode <> StateCode) or (NewCRMInvoice.StatusCode <> StatusCode) then begin
                ActivateInvoiceForFurtherUpdate(CRMInvoice);
                StateCode := NewCRMInvoice.StateCode;
                StatusCode := NewCRMInvoice.StatusCode;
                Modify();
                exit(1);
            end;
        end;
    end;

    local procedure CalculateActualStatusCode(CustLedgerEntry: Record "Cust. Ledger Entry"; var CRMInvoice: Record "CRM Invoice")
    begin
        with CRMInvoice do begin
            CustLedgerEntry.CalcFields("Remaining Amount", Amount);
            if CustLedgerEntry."Remaining Amount" = 0 then begin
                StateCode := StateCode::Paid;
                StatusCode := StatusCode::Complete;
            end else
                if CustLedgerEntry."Remaining Amount" <> CustLedgerEntry.Amount then begin
                    StateCode := StateCode::Paid;
                    StatusCode := StatusCode::Partial;
                end else begin
                    StateCode := StateCode::Active;
                    StatusCode := StatusCode::Billed;
                end;
        end;
    end;

    local procedure ActivateInvoiceForFurtherUpdate(var CRMInvoice: Record "CRM Invoice")
    begin
        with CRMInvoice do
            if StateCode <> StateCode::Active then begin
                StateCode := StateCode::Active;
                StatusCode := StatusCode::Billed;
                Modify();
            end;
    end;

    procedure UpdateCRMPriceListItem(var CRMProduct: Record "CRM Product") AdditionalFieldsWereModified: Boolean
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        if IsNullGuid(CRMProduct.ProductId) then
            exit(false);

        AdditionalFieldsWereModified := SetCRMDefaultPriceListOnProduct(CRMProduct);
        CRMProductpricelevel.SetRange(ProductId, CRMProduct.ProductId);
        CRMProductpricelevel.SetRange(PriceLevelId, CRMProduct.PriceLevelId);
        if CRMProductpricelevel.FindFirst() then
            exit(UpdateCRMProductpricelevel(CRMProductpricelevel, CRMProduct) or AdditionalFieldsWereModified);

        CreateCRMProductpricelevelForProduct(CRMProduct, CRMProduct.PriceLevelId);
        exit(true);
    end;

    procedure UpdateCRMProductPriceIfNegative(var CRMProduct: Record "CRM Product"): Boolean
    begin
        // CRM doesn't allow negative prices. Update the price to zero, if negative (this preserves the behavior of the old CRM Connector)
        if CRMProduct.Price < 0 then begin
            CRMProduct.Price := 0;
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateCRMProductQuantityOnHandIfNegative(var CRMProduct: Record "CRM Product"): Boolean
    begin
        // Update to zero, if negative (this preserves the behavior of the old CRM Connector)
        if CRMProduct.QuantityOnHand < 0 then begin
            CRMProduct.QuantityOnHand := 0;
            exit(true);
        end;

        exit(false);
    end;

    local procedure UpdateCRMProductpricelevel(var CRMProductpricelevel: Record "CRM Productpricelevel"; CRMProduct: Record "CRM Product") AdditionalFieldsWereModified: Boolean
    begin
        with CRMProductpricelevel do begin
            if PriceLevelId <> CRMProduct.PriceLevelId then begin
                PriceLevelId := CRMProduct.PriceLevelId;
                AdditionalFieldsWereModified := true;
            end;

            if UoMId <> CRMProduct.DefaultUoMId then begin
                UoMId := CRMProduct.DefaultUoMId;
                AdditionalFieldsWereModified := true;
            end;

            if UoMScheduleId <> CRMProduct.DefaultUoMScheduleId then begin
                UoMScheduleId := CRMProduct.DefaultUoMScheduleId;
                AdditionalFieldsWereModified := true;
            end;

            if Amount <> CRMProduct.Price then begin
                Amount := CRMProduct.Price;
                AdditionalFieldsWereModified := true;
            end;

            if TransactionCurrencyId <> CRMProduct.TransactionCurrencyId then begin
                TransactionCurrencyId := CRMProduct.TransactionCurrencyId;
                AdditionalFieldsWereModified := true;
            end;

            if ProductNumber <> CRMProduct.ProductNumber then begin
                ProductNumber := CRMProduct.ProductNumber;
                AdditionalFieldsWereModified := true;
            end;

            if AdditionalFieldsWereModified then
                Modify();
        end;
    end;

    procedure UpdateCRMProductTypeCodeIfChanged(var CRMProduct: Record "CRM Product"; NewProductTypeCode: Integer): Boolean
    begin
        // We use ProductTypeCode::SalesInventory and ProductTypeCode::Services to trace back later,
        // where this CRM product originated from: a NAV Item, or a NAV Resource
        if CRMProduct.ProductTypeCode <> NewProductTypeCode then begin
            CRMProduct.ProductTypeCode := NewProductTypeCode;
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateCRMProductStateCodeIfChanged(var CRMProduct: Record "CRM Product"; NewBlocked: Boolean): Boolean
    var
        NewStateCode: Option;
    begin
        if NewBlocked then
            NewStateCode := CRMProduct.StateCode::Retired
        else
            NewStateCode := CRMProduct.StateCode::Active;

        if NewStateCode <> CRMProduct.StateCode then begin
            if NewBlocked then
                SetCRMProductStateToRetired(CRMProduct)
            else
                SetCRMProductStateToActive(CRMProduct);
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateItemBlockedIfChanged(var Item: Record Item; NewBlocked: Boolean): Boolean
    begin
        if Item.Blocked <> NewBlocked then begin
            Item.Blocked := NewBlocked;
            exit(true);
        end;
    end;

    procedure UpdateResourceBlockedIfChanged(var Resource: Record Resource; NewBlocked: Boolean): Boolean
    begin
        if Resource.Blocked <> NewBlocked then begin
            Resource.Blocked := NewBlocked;
            exit(true);
        end;
    end;

    procedure UpdateCRMProductUoMFieldsIfChanged(var CRMProduct: Record "CRM Product"; UnitOfMeasureCode: Code[10]): Boolean
    var
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        AdditionalFieldsWereModified: Boolean;
    begin
        // Get the unit of measure ID used in this product
        // On that unit of measure ID, get the UoMName, UomscheduleID, UomscheduleName and update them in the product if needed

        GetValidCRMUnitOfMeasureRecords(CRMUom, CRMUomschedule, UnitOfMeasureCode);

        // Update UoM ID if changed
        if CRMProduct.DefaultUoMId <> CRMUom.UoMId then begin
            CRMProduct.DefaultUoMId := CRMUom.UoMId;
            AdditionalFieldsWereModified := true;
        end;

        // Update the Uomschedule ID if changed
        if CRMProduct.DefaultUoMScheduleId <> CRMUomschedule.UoMScheduleId then begin
            CRMProduct.DefaultUoMScheduleId := CRMUomschedule.UoMScheduleId;
            AdditionalFieldsWereModified := true;
        end;

        exit(AdditionalFieldsWereModified);
    end;

    procedure UpdateCRMProductVendorNameIfChanged(var CRMProduct: Record "CRM Product"): Boolean
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(CRMProduct.VendorPartNumber) then
            exit(false);

        if CRMProduct.VendorName <> Vendor.Name then begin
            CRMProduct.VendorName := Vendor.Name;
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateOwnerIfChanged(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; SourceSalespersonCodeFieldNo: Integer; DestinationOwnerFieldNo: Integer; DestinationOwnerTypeFieldNo: Integer; DestinationOwnerTypeValue: Option): Boolean
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonCodeFieldRef: FieldRef;
        OwnerFieldRef: FieldRef;
        OwnerTypeFieldRef: FieldRef;
        OwnerGuid: Guid;
        CurrentOwnerGuid: Guid;
    begin
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
        IntegrationTableMapping.SetRange("Integration Table ID", DATABASE::"CRM Systemuser");
        if not IntegrationTableMapping.FindFirst() then
            exit(false); // There are no mapping for salepeople to SystemUsers

        SalespersonCodeFieldRef := SourceRecordRef.Field(SourceSalespersonCodeFieldNo);

        // Ignore empty salesperson code.
        if Format(SalespersonCodeFieldRef.Value()) = '' then
            exit(false);

        SalespersonPurchaser.SetFilter(Code, Format(SalespersonCodeFieldRef.Value()));
        if not SalespersonPurchaser.FindFirst() then
            Error(RecordNotFoundErr, SalespersonCodeFieldRef.Value(), SalespersonPurchaser.TableCaption());

        if not CRMIntegrationRecord.FindIDFromRecordID(SalespersonPurchaser.RecordId(), OwnerGuid) then
            Error(
              RecordMustBeCoupledErr, SalespersonPurchaser.TableCaption(), SalespersonCodeFieldRef.Value(),
              IntegrationTableMapping.GetExtendedIntegrationTableCaption());

        OwnerFieldRef := DestinationRecordRef.Field(DestinationOwnerFieldNo);
        CurrentOwnerGuid := OwnerFieldRef.Value();
        if CurrentOwnerGuid <> OwnerGuid then begin
            OwnerFieldRef.Value := OwnerGuid;
            OwnerTypeFieldRef := DestinationRecordRef.Field(DestinationOwnerTypeFieldNo);
            OwnerTypeFieldRef.Value := DestinationOwnerTypeValue;
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateContactOnModifyCustomer(RecRef: RecordRef)
    var
        Customer: Record Customer;
        CustContUpdate: Codeunit "CustCont-Update";
    begin
        if RecRef.Number() = DATABASE::Customer then begin
            RecRef.SetTable(Customer);
            CustContUpdate.OnModify(Customer);
        end;
    end;

    procedure UpdateContactOnModifyVendor(RecRef: RecordRef)
    var
        Vendor: Record Vendor;
        VendContUpdate: Codeunit "VendCont-Update";
    begin
        if RecRef.Number() = DATABASE::Vendor then begin
            RecRef.SetTable(Vendor);
            VendContUpdate.OnModify(Vendor);
        end;
    end;

    procedure FindContactRelatedCustomer(SourceRecordRef: RecordRef; var ContactBusinessRelation: Record "Contact Business Relation"): Boolean
    var
        Contact: Record Contact;
        MarketingSetup: Record "Marketing Setup";
        CompanyNoFieldRef: FieldRef;
    begin
        // Tranfer the parent company id to the ParentCustomerId
        CompanyNoFieldRef := SourceRecordRef.Field(Contact.FieldNo("Company No."));
        if not Contact.Get(CompanyNoFieldRef.Value()) then
            exit(false);

        //Contact.Type::Person
        MarketingSetup.Get();
        ContactBusinessRelation.SetFilter("Business Relation Code", MarketingSetup."Bus. Rel. Code for Customers");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetFilter("Contact No.", Contact."No.");
        exit(ContactBusinessRelation.FindFirst());
    end;

    procedure FindContactRelatedVendor(SourceRecordRef: RecordRef; var ContactBusinessRelation: Record "Contact Business Relation"): Boolean
    var
        Vendor: Record Contact;
        MarketingSetup: Record "Marketing Setup";
        CompanyNoFieldRef: FieldRef;
    begin
        // Tranfer the parent company id to the ParentCustomerId
        CompanyNoFieldRef := SourceRecordRef.Field(Vendor.FieldNo("Company No."));
        if not Vendor.Get(CompanyNoFieldRef.Value()) then
            exit(false);

        MarketingSetup.Get();
        ContactBusinessRelation.SetFilter("Business Relation Code", MarketingSetup."Bus. Rel. Code for Vendors");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetFilter("Contact No.", Vendor."No.");
        exit(ContactBusinessRelation.FindFirst());
    end;

    procedure UpdateSalesPersonCodeIfChanged(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; SourceOwnerIDFieldNo: Integer; SourceOwnerTypeFieldNo: Integer; AllowedOwnerTypeValue: Option; DestinationSalesPersonCodeFieldNo: Integer): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        IntegrationTableMapping: Record "Integration Table Mapping";
        OutlookSynchTypeConv: Codeunit "Outlook Synch. Type Conv";
        SalesPersonRecordID: RecordID;
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
        CRMSystemUserID: Guid;
        CurrentOptionValue: Integer;
        OutOfMapFilter: Boolean;
    begin
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
        IntegrationTableMapping.SetRange("Integration Table ID", DATABASE::"CRM Systemuser");
        if IntegrationTableMapping.IsEmpty() then
            exit(false); // There are no mapping for salepeople to SystemUsers

        SourceFieldRef := SourceRecordRef.Field(SourceOwnerTypeFieldNo);
        CurrentOptionValue := OutlookSynchTypeConv.TextToOptionValue(Format(SourceFieldRef.Value()), SourceFieldRef.OptionMembers());
        // Allow 0 as it is the default value for CRM options.
        if (CurrentOptionValue <> 0) and (CurrentOptionValue <> AllowedOwnerTypeValue) then
            Error(CanOnlyUseSystemUserOwnerTypeErr, CRMProductName.SHORT());

        SourceFieldRef := SourceRecordRef.Field(SourceOwnerIDFieldNo);
        CRMSystemUserID := SourceFieldRef.Value();

        if IsNullGuid(CRMSystemUserID) then
            exit(false);

        DestinationFieldRef := DestinationRecordRef.Field(DestinationSalesPersonCodeFieldNo);

        if not CRMIntegrationRecord.FindRecordIDFromID(CRMSystemUserID, DATABASE::"Salesperson/Purchaser", SalesPersonRecordID) then begin
            if not SynchRecordIfMappingExists(DATABASE::"CRM Systemuser", CRMSystemUserID, OutOfMapFilter) then
                exit(false);
            if not CRMIntegrationRecord.FindRecordIDFromID(CRMSystemUserID, DATABASE::"Salesperson/Purchaser", SalesPersonRecordID) then
                exit(false);
        end;

        if not SalespersonPurchaser.Get(SalesPersonRecordID) then
            exit(false);

        exit(UpdateFieldRefValueIfChanged(DestinationFieldRef, SalespersonPurchaser.Code));
    end;

    procedure UpdateFieldRefValueIfChanged(var DestinationFieldRef: FieldRef; NewFieldValue: Text): Boolean
    begin
        // Compare and updates the fieldref value, if different
        if Format(DestinationFieldRef.Value()) = NewFieldValue then
            exit(false);

        // Return TRUE if the value was changed
        DestinationFieldRef.Value := NewFieldValue;
        exit(true);
    end;

    procedure GetValidCRMUnitOfMeasureRecords(var CRMUom: Record "CRM Uom"; var CRMUomschedule: Record "CRM Uomschedule"; UnitOfMeasureCode: Code[10])
    var
        CRMUnitGroupName: Text;
    begin
        // This function checks that the CRM Unit of Measure and its parent group exist in CRM, and that the user didn't change their properties from
        // the expected ones

        // Attempt to get the Uomschedule with the expected name = 'NAV ' + UnitOfMeasureCode
        CRMUnitGroupName := GetUnitGroupName(UnitOfMeasureCode);
        CRMUomschedule.SetRange(Name, CRMUnitGroupName);

        // CRM Unit Group - Not found
        if not FindCachedCRMUomschedule(CRMUomschedule) then
            Error(DynamicsCRMUomscheduleNotFoundErr, CRMUnitGroupName, CRMProductName.SHORT());

        // CRM Unit Group  - Multiple found
        if CountCRMUomschedule(CRMUomschedule) > 1 then
            Error(DynamicsCRMUoMFoundMultipleInGroupErr, CRMUnitGroupName, CRMProductName.SHORT());

        // CRM Unit Group - One found - check its child unit of measure, should be just one
        CRMUom.SetRange(UoMScheduleId, CRMUomschedule.UoMScheduleId);

        // CRM Unit of Measure - not found
        if not FindCachedCRMUom(CRMUom) then
            Error(DynamicsCRMUoMNotFoundInGroupErr, CRMUomschedule.Name, CRMProductName.SHORT());

        // CRM Unit of Measure - multiple found
        if CountCRMUom(CRMUom) > 1 then
            Error(DynamicsCRMUoMFoundMultipleInGroupErr, CRMUomschedule.Name, CRMProductName.SHORT());

        // CRM Unit of Measure - one found, does it have the correct name?
        if CRMUom.Name <> UnitOfMeasureCode then
            Error(IncorrectCRMUoMNameErr, CRMUomschedule.Name, UnitOfMeasureCode, CRMUom.Name);

        // CRM Unit of Measure should be the base
        if not CRMUom.IsScheduleBaseUoM then
            Error(IncorrectCRMUoMStatusErr, CRMUom.Name, CRMUomschedule.Name);

        // CRM Unit of Measure should have the conversion rate of 1
        if CRMUom.Quantity <> 1 then
            Error(IncorrectCRMUoMQuantityErr, CRMUom.Name);

        // All checks passed. We're good to go
    end;

    procedure GetNavCurrencyCode(TransactionCurrencyId: Guid): Code[10]
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        NAVLCYCode: Code[10];
        CRMCurrencyCode: Code[10];
    begin
        if IsNullGuid(TransactionCurrencyId) then
            exit('');
        NAVLCYCode := GetNavLCYCode();
        CRMTransactioncurrency.SetRange(TransactionCurrencyId, TransactionCurrencyId);
        if not FindCachedCRMTransactionCurrency(CRMTransactioncurrency) then
            Error(DynamicsCRMTransactionCurrencyRecordNotFoundErr, TransactionCurrencyId);
        CRMCurrencyCode := DelChr(CRMTransactioncurrency.ISOCurrencyCode);
        if CRMCurrencyCode = NAVLCYCode then
            exit('');

        Currency.Get(CRMCurrencyCode);
        exit(Currency.Code);
    end;

    procedure GetCRMTransactioncurrency(CurrencyCode: Text): Guid
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        NAVLCYCode: Code[10];
    begin
        // In NAV, an empty currency means local currency (LCY)
        NAVLCYCode := GetNavLCYCode();
        if DelChr(CurrencyCode) = '' then
            CurrencyCode := NAVLCYCode;

        if CurrencyCode = NAVLCYCode then
            FindNAVLocalCurrencyInCRM(CRMTransactioncurrency)
        else begin
            CRMTransactioncurrency.SetRange(ISOCurrencyCode, CurrencyCode);
            if not FindCachedCRMTransactionCurrency(CRMTransactioncurrency) then
                Error(DynamicsCRMTransactionCurrencyRecordNotFoundErr, CurrencyCode);
        end;
        exit(CRMTransactioncurrency.TransactionCurrencyId)
    end;

    local procedure AddToCacheCRMPriceLevel(CRMPricelevel: Record "CRM Pricelevel")
    begin
        TempCRMPricelevel := CRMPricelevel;
        TempCRMPricelevel.Insert();
    end;

    local procedure CacheCRMPriceLevel(): Boolean
    var
        CRMPricelevel: Record "CRM Pricelevel";
    begin
        TempCRMPricelevel.Reset();
        if TempCRMPricelevel.IsEmpty() then
            if CRMPricelevel.FindSet() then
                repeat
                    AddToCacheCRMPriceLevel(CRMPricelevel)
                until CRMPricelevel.Next() = 0;
        exit(not TempCRMPricelevel.IsEmpty());
    end;

    local procedure FindCachedCRMPriceLevel(var CRMPricelevel: Record "CRM Pricelevel"): Boolean
    begin
        if not CacheCRMPriceLevel() then
            exit(false);
        TempCRMPricelevel.Copy(CRMPricelevel);
        if TempCRMPricelevel.FindFirst() then begin
            CRMPricelevel.Copy(TempCRMPricelevel);
            exit(true);
        end;
    end;

    local procedure AddToCacheCRMTransactionCurrency(CRMTransactioncurrency: Record "CRM Transactioncurrency")
    begin
        TempCRMTransactioncurrency := CRMTransactioncurrency;
        TempCRMTransactioncurrency.Insert();
    end;

    local procedure CacheCRMTransactionCurrency(): Boolean
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        TempCRMTransactioncurrency.Reset();
        if TempCRMTransactioncurrency.IsEmpty() then
            if CRMTransactioncurrency.FindSet() then
                repeat
                    AddToCacheCRMTransactionCurrency(CRMTransactioncurrency)
                until CRMTransactioncurrency.Next() = 0;
        exit(not TempCRMTransactioncurrency.IsEmpty());
    end;

    local procedure FindCachedCRMTransactionCurrency(var CRMTransactioncurrency: Record "CRM Transactioncurrency"): Boolean
    begin
        if not CacheCRMTransactionCurrency() then
            exit(false);
        TempCRMTransactioncurrency.Copy(CRMTransactioncurrency);
        if TempCRMTransactioncurrency.FindFirst() then begin
            CRMTransactioncurrency.Copy(TempCRMTransactioncurrency);
            exit(true);
        end;
    end;

    local procedure AddToCacheCRMUom(CRMUom: Record "CRM Uom")
    begin
        TempCRMUom := CRMUom;
        TempCRMUom.Insert();
    end;

    local procedure CacheCRMUom(): Boolean
    var
        CRMUom: Record "CRM Uom";
    begin
        TempCRMUom.Reset();
        if TempCRMUom.IsEmpty() then
            if CRMUom.FindSet() then
                repeat
                    AddToCacheCRMUom(CRMUom)
                until CRMUom.Next() = 0;
        exit(not TempCRMUom.IsEmpty());
    end;

    local procedure CountCRMUom(var CRMUom: Record "CRM Uom"): Integer
    begin
        TempCRMUom.Copy(CRMUom);
        exit(TempCRMUom.Count());
    end;

    local procedure FindCachedCRMUom(var CRMUom: Record "CRM Uom"): Boolean
    begin
        if not CacheCRMUom() then
            exit(false);
        TempCRMUom.Copy(CRMUom);
        if TempCRMUom.FindFirst() then begin
            CRMUom.Copy(TempCRMUom);
            exit(true);
        end;
    end;

    local procedure AddToCacheCRMUomschedule(CRMUomschedule: Record "CRM Uomschedule")
    begin
        TempCRMUomschedule := CRMUomschedule;
        TempCRMUomschedule.Insert();
    end;

    local procedure CacheCRMUomschedule(): Boolean
    var
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        TempCRMUomschedule.Reset();
        if TempCRMUomschedule.IsEmpty() then
            if CRMUomschedule.FindSet() then
                repeat
                    AddToCacheCRMUomschedule(CRMUomschedule)
                until CRMUomschedule.Next() = 0;
        exit(not TempCRMUomschedule.IsEmpty());
    end;

    local procedure CountCRMUomschedule(var CRMUomschedule: Record "CRM Uomschedule"): Integer
    begin
        TempCRMUomschedule.Copy(CRMUomschedule);
        exit(TempCRMUomschedule.Count());
    end;

    local procedure FindCachedCRMUomschedule(var CRMUomschedule: Record "CRM Uomschedule"): Boolean
    begin
        if not CacheCRMUomschedule() then
            exit(false);
        TempCRMUomschedule.Copy(CRMUomschedule);
        if TempCRMUomschedule.FindFirst() then begin
            CRMUomschedule.Copy(TempCRMUomschedule);
            exit(true);
        end;
    end;

    procedure SetSalesInvoiceHeaderCoupledToCRM(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader."Coupled to CRM" := true;
        SalesInvoiceHeader.Modify();
    end;

    procedure ShowPage(RecordID: RecordID)
    var
        TableMetadata: Record "Table Metadata";
        PageManagement: Codeunit "Page Management";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CrmId: Guid;
        CrmIdText: Text;
    begin
        if RecordID.TableNo() = 0 then
            exit;
        if not TableMetadata.Get(RecordID.TableNo()) then
            exit;

        if not TableMetadata.DataIsExternal then begin
            PageManagement.PageRun(RecordID);
            exit;
        end;

        if TableMetadata.TableType = TableMetadata.TableType::CRM then begin
            CrmIdText := Format(RecordID);
            CrmIdText := CopyStr(CrmIdText, StrPos(CrmIdText, ':') + 1);
            Evaluate(CrmId, CrmIdText);
            HyperLink(CRMIntegrationManagement.GetCRMEntityUrlFromCRMID(RecordID.TableNo(), CrmId));
            exit;
        end;

        Error(UnableToFindPageForRecordErr, Format(RecordID, 0, 1));
    end;

    procedure FindNewValueForSpecialMapping(SourceFieldRef: FieldRef; var NewValue: Variant) IsValueFound: Boolean
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMID: Guid;
    begin
        case SourceFieldRef.Relation() of
            DATABASE::Currency: // special handling of Local currency
                if Format(SourceFieldRef.Value()) = '' then begin
                    FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);
                    NewValue := CRMTransactioncurrency.TransactionCurrencyId;
                    IsValueFound := true;
                end;
            DATABASE::"CRM Transactioncurrency": // special handling of Local currency
                begin
                    CRMID := SourceFieldRef.Value();
                    if GetNavCurrencyCode(CRMID) = '' then begin
                        NewValue := '';
                        IsValueFound := true;
                    end;
                end;
        end;
    end;

    procedure FindPKByRecordID(RecID: RecordID; var PrimaryKey: Variant) Found: Boolean
    var
        RecordRef: RecordRef;
        KeyRef: KeyRef;
        FieldRef: FieldRef;
    begin
        Found := RecordRef.Get(RecID);
        KeyRef := RecordRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        PrimaryKey := FieldRef.Value();
    end;

    procedure FindRecordIDByPK(TableID: Integer; PrimaryKey: Variant; var RecID: RecordID) Found: Boolean
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableID);
        KeyRef := RecordRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        FieldRef.SetRange(PrimaryKey);
        Found := RecordRef.FindFirst();
        RecID := RecordRef.RecordId();
        RecordRef.Close();
    end;

    procedure FindSourceIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef): Boolean
    var
        SourceRecRef: RecordRef;
        DestinationRecRef: RecordRef;
    begin
        SourceRecRef := SourceFieldRef.Record();
        DestinationRecRef := DestinationFieldRef.Record();
        IntegrationTableMapping.SetRange("Table ID", SourceRecRef.Number());
        IntegrationTableMapping.SetRange("Integration Table ID", DestinationRecRef.Number());
        exit(IntegrationTableMapping.FindFirst());
    end;

    procedure IsClearValueOnFailedSync(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        if FindSourceIntegrationTableMapping(IntegrationTableMapping, SourceFieldRef, DestinationFieldRef) then
            with IntegrationFieldMapping do begin
                SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
                SetRange("Field No.", SourceFieldRef.Number());
                SetRange("Integration Table Field No.", DestinationFieldRef.Number());
                FindFirst();
                exit("Clear Value on Failed Sync");
            end;
        exit(false);
    end;

    procedure AreFieldsRelatedToMappedTables(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        SourceTableID: Integer;
        DestinationTableID: Integer;
        Direction: Integer;
    begin
        if (SourceFieldRef.Relation() <> 0) and (DestinationFieldRef.Relation() <> 0) then begin
            SourceTableID := SourceFieldRef.Relation();
            DestinationTableID := DestinationFieldRef.Relation();
            if DestinationFieldRef.Type() = FieldType::GUID then begin
                IntegrationTableMapping.SetRange("Table ID", SourceTableID);
                IntegrationTableMapping.SetRange("Integration Table ID", DestinationTableID);
                Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
            end else begin
                IntegrationTableMapping.SetRange("Table ID", DestinationTableID);
                IntegrationTableMapping.SetRange("Integration Table ID", SourceTableID);
                Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
            end;
            IntegrationTableMapping.SetRange("Delete After Synchronization", false);
            if IntegrationTableMapping.FindFirst() then begin
                IntegrationTableMapping.Direction := Direction;
                exit(true);
            end;
            Error(
              MappingMustBeSetForGUIDFieldErr,
              SourceFieldRef.Relation(), DestinationFieldRef.Relation(), SourceFieldRef.Name(), DestinationFieldRef.Name());
        end;
    end;

    procedure ConvertTableToOption(SourceFieldRef: FieldRef; var OptionValue: Integer) TableIsMapped: Boolean
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        RecordRef: RecordRef;
        RecID: RecordID;
    begin
        TableIsMapped := false;
        OptionValue := 0;
        if IsTableMappedToCRMOption(SourceFieldRef.Relation()) then begin
            TableIsMapped := true;
            if FindRecordIDByPK(SourceFieldRef.Relation(), SourceFieldRef.Value(), RecID) then begin
                CRMOptionMapping.SetRange("Record ID", RecID);
                if CRMOptionMapping.FindFirst() then
                    OptionValue := CRMOptionMapping."Option Value";
            end;
            RecordRef.Close();
        end;
        exit(TableIsMapped);
    end;

    procedure ConvertOptionToTable(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var TableValue: Text) TableIsMapped: Boolean
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        RecordRef: RecordRef;
        RecID: RecordID;
        PrimaryKey: Variant;
    begin
        TableIsMapped := false;
        if IsTableMappedToCRMOption(DestinationFieldRef.Relation()) then begin
            TableIsMapped := true;
            CRMOptionMapping.SetRange("Option Value Caption", SourceFieldRef.Value());
            CRMOptionMapping.SetRange("Table ID", DestinationFieldRef.Relation());
            CRMOptionMapping.SetRange("Integration Field ID", SourceFieldRef.Number());
            if CRMOptionMapping.FindFirst() then begin
                FindPKByRecordID(CRMOptionMapping."Record ID", PrimaryKey);
                Evaluate(TableValue, PrimaryKey);
            end else
                TableValue := DestinationFieldRef.Value();
        end;
        exit(TableIsMapped);
    end;

    procedure UpdateCDSOptionMapping(OldRecId: RecordId; NewRecId: RecordId)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        CRMOptionMapping.SetRange("Record ID", OldRecId);
        if CRMOptionMapping.FindFirst() then
            CRMOptionMapping.Rename(NewRecId);
    end;

    local procedure IsTableMappedToCRMOption(TableID: Integer): Boolean
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        CRMOptionMapping.SetRange("Table ID", TableID);
        exit(not CRMOptionMapping.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCDSBaseCurrencyId(var BaseCurrencyId: Guid; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnGetCDSOwnershipModel(var OwnershipModel: Option; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCDSBaseCurrencySymbol(var BaseCurrencySymbol: Text[5]; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCDSBaseCurrencyPrecision(var BaseCurrencyPrecision: Integer; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCDSCurrencyDecimalPrecision(var CurrencyDecimalPrecision: Integer; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendorSyncEnabled(var Enabled: Boolean)
    begin
    end;
}
