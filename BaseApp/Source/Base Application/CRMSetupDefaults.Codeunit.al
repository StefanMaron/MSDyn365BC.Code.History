codeunit 5334 "CRM Setup Defaults"
{

    trigger OnRun()
    begin
    end;

    var
        JobQueueEntryNameTok: Label ' %1 - %2 synchronization job.', Comment = '%1 = The Integration Table Name to synchronized (ex. CUSTOMER), %2 = CRM product name';
        IntegrationTablePrefixTok: Label 'Dynamics CRM', Comment = 'Product name', Locked = true;
        CustomStatisticsSynchJobDescTxt: Label 'Customer Statistics - %1 synchronization job', Comment = '%1 = CRM product name';
        CustomSalesOrderSynchJobDescTxt: Label 'Sales Order Status - %1 synchronization job', Comment = '%1 = CRM product name';
        CustomSalesOrderNotesSynchJobDescTxt: Label 'Sales Order Notes - %1 synchronization job', Comment = '%1 = CRM product name';
        CRMAccountConfigTemplateCodeTok: Label 'CRMACCOUNT', Comment = 'Config. Template code for CRM Accounts created from Customers. Max length 10.';
        CRMAccountConfigTemplateDescTxt: Label 'New CRM Account records created during synch.', Comment = 'Max. length 50.';
        CustomerConfigTemplateCodeTok: Label 'CRMCUST', Comment = 'Customer template code for new customers created from CRM data. Max length 10.';
        CustomerConfigTemplateDescTxt: Label 'New Customer records created during synch.', Comment = 'Max. length 50.';
        CRMProductName: Codeunit "CRM Product Name";
        AutoCreateSalesOrdersTxt: Label 'Automatically create sales orders from sales orders that are submitted in %1.', Comment = '%1 = CRM product name';
        AutoProcessQuotesTxt: Label 'Automatically process sales quotes from sales quotes that are activated in %1.', Comment = '%1 = CRM product name';

    procedure ResetConfiguration(CRMConnectionSetup: Record "CRM Connection Setup")
    var
        TempCRMConnectionSetup: Record "CRM Connection Setup" temporary;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ConnectionName: Text;
        EnqueueJobQueEntries: Boolean;
    begin
        EnqueueJobQueEntries := CRMConnectionSetup.DoReadCRMData;
        ConnectionName := RegisterTempConnectionIfNeeded(CRMConnectionSetup, TempCRMConnectionSetup);
        if ConnectionName <> '' then
            SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName, true);

        ResetSalesPeopleSystemUserMapping('SALESPEOPLE', EnqueueJobQueEntries);
        ResetCustomerAccountMapping('CUSTOMER', EnqueueJobQueEntries);
        ResetContactContactMapping('CONTACT', EnqueueJobQueEntries);
        ResetCurrencyTransactionCurrencyMapping('CURRENCY', EnqueueJobQueEntries);
        ResetUnitOfMeasureUoMScheduleMapping('UNIT OF MEASURE', EnqueueJobQueEntries);
        ResetItemProductMapping('ITEM-PRODUCT', EnqueueJobQueEntries);
        ResetResourceProductMapping('RESOURCE-PRODUCT', EnqueueJobQueEntries);
        ResetCustomerPriceGroupPricelevelMapping('CUSTPRCGRP-PRICE', EnqueueJobQueEntries);
        ResetSalesPriceProductPricelevelMapping('SALESPRC-PRODPRICE', EnqueueJobQueEntries);
        ResetSalesInvoiceHeaderInvoiceMapping('POSTEDSALESINV-INV', EnqueueJobQueEntries);
        ResetSalesInvoiceLineInvoiceMapping('POSTEDSALESLINE-INV');
        ResetShippingAgentMapping('SHIPPING AGENT');
        ResetShipmentMethodMapping('SHIPMENT METHOD');
        ResetPaymentTermsMapping('PAYMENT TERMS');
        ResetOpportunityMapping('OPPORTUNITY');
        if CRMConnectionSetup."Is S.Order Integration Enabled" then begin
            ResetSalesOrderMapping('SALESORDER-ORDER', EnqueueJobQueEntries);
            RecreateSalesOrderStatusJobQueueEntry(EnqueueJobQueEntries);
            RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueEntries);
            CODEUNIT.Run(CODEUNIT::"CRM Enable Posts");
        end;

        RecreateStatisticsJobQueueEntry(EnqueueJobQueEntries);
        if CRMConnectionSetup."Auto Create Sales Orders" then
            RecreateAutoCreateSalesOrdersJobQueueEntry(EnqueueJobQueEntries);
        if CRMConnectionSetup."Auto Process Sales Quotes" then
            RecreateAutoProcessSalesQuotesJobQueueEntry(EnqueueJobQueEntries);

        if CRMIntegrationManagement.IsCRMSolutionInstalled then
            ResetCRMNAVConnectionData;

        ResetDefaultCRMPricelevel(CRMConnectionSetup);
        OnAfterResetConfiguration(CRMConnectionSetup);

        if ConnectionName <> '' then
            TempCRMConnectionSetup.UnregisterConnectionWithName(ConnectionName);
    end;

    local procedure ResetSalesPeopleSystemUserMapping(IntegrationTableMappingName: Code[20]; ShouldRecreateJobQueueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser",
          CRMSystemuser.FieldNo(SystemUserId), CRMSystemuser.FieldNo(ModifiedOn),
          '', '', true);

        CRMSystemuser.Reset;
        CRMSystemuser.SetRange(IsDisabled, false);
        CRMSystemuser.SetRange(IsLicensed, true);
        CRMSystemuser.SetRange(IsIntegrationUser, false);
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Systemuser", CRMSystemuser.TableCaption, CRMSystemuser.GetView));
        IntegrationTableMapping.Modify;

        // Email > InternalEMailAddress
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalespersonPurchaser.FieldNo("E-Mail"),
          CRMSystemuser.FieldNo(InternalEMailAddress),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        // Name > FullName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalespersonPurchaser.FieldNo(Name),
          CRMSystemuser.FieldNo(FullName),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        // Phone No. > MobilePhone
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalespersonPurchaser.FieldNo("Phone No."),
          CRMSystemuser.FieldNo(MobilePhone),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, ShouldRecreateJobQueueEntry, 1440);
    end;

    local procedure ResetCustomerAccountMapping(IntegrationTableMappingName: Code[20]; ShouldRecreateJobQueueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Customer, DATABASE::"CRM Account",
          CRMAccount.FieldNo(AccountId), CRMAccount.FieldNo(ModifiedOn),
          ResetCustomerConfigTemplate, ResetAccountConfigTemplate, true);

        Customer.SetRange(Blocked, Customer.Blocked::" ");
        IntegrationTableMapping.SetTableFilter(GetTableFilterFromView(DATABASE::Customer, Customer.TableCaption, Customer.GetView));

        CRMAccount.SetRange(StateCode, CRMAccount.StateCode::Active);
        CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Customer);
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Account", CRMAccount.TableCaption, CRMAccount.GetView));
        IntegrationTableMapping."Dependency Filter" := 'SALESPEOPLE|CURRENCY';
        IntegrationTableMapping.Modify;

        // OwnerIdType::systemuser
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMAccount.FieldNo(OwnerIdType),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMAccount.OwnerIdType::systemuser), false, false);

        // Salesperson Code > OwnerId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Salesperson Code"),
          CRMAccount.FieldNo(OwnerId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);
        SetIntegrationFieldMappingNotNull;

        // Name > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo(Name),
          CRMAccount.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Contact > Address1_PrimaryContactName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo(Contact),
          CRMAccount.FieldNo(Address1_PrimaryContactName),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', false, false); // We do not validate contact name.

        // Address > Address1_Line1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo(Address),
          CRMAccount.FieldNo(Address1_Line1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Address 2 > Address1_Line2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Address 2"),
          CRMAccount.FieldNo(Address1_Line2),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Post Code > Address1_PostalCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Post Code"),
          CRMAccount.FieldNo(Address1_PostalCode),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // City > Address1_City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo(City),
          CRMAccount.FieldNo(Address1_City),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Country > Address1_Country
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Country/Region Code"),
          CRMAccount.FieldNo(Address1_Country),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // County > Address1_StateOrProvince
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo(County),
          CRMAccount.FieldNo(Address1_StateOrProvince),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Email > EmailAddress1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("E-Mail"),
          CRMAccount.FieldNo(EMailAddress1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Fax No > Fax
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Fax No."),
          CRMAccount.FieldNo(Fax),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Home Page > WebSiteUrl
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Home Page"),
          CRMAccount.FieldNo(WebSiteURL),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Phone No. > Telephone1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Phone No."),
          CRMAccount.FieldNo(Telephone1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Shipment Method Code > address1_freighttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Shipment Method Code"),
          CRMAccount.FieldNo(Address1_FreightTermsCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Shipping Agent Code > address1_shippingmethodcode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Shipping Agent Code"),
          CRMAccount.FieldNo(Address1_ShippingMethodCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Payment Terms Code > paymenttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Payment Terms Code"),
          CRMAccount.FieldNo(PaymentTermsCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Credit Limit (LCY) > creditlimit
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Credit Limit (LCY)"),
          CRMAccount.FieldNo(CreditLimit),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Primary Contact No." > PrimaryContactId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Primary Contact No."),
          CRMAccount.FieldNo(PrimaryContactId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);
        SetIntegrationFieldMappingClearValueOnFailedSync;

        OnAfterResetCustomerAccountMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, ShouldRecreateJobQueueEntry, 720);
    end;

    local procedure ResetContactContactMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMContact: Record "CRM Contact";
        Contact: Record Contact;
        EmptyGuid: Guid;
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Contact, DATABASE::"CRM Contact",
          CRMContact.FieldNo(ContactId), CRMContact.FieldNo(ModifiedOn),
          '', '', true);

        Contact.Reset;
        Contact.SetRange(Type, Contact.Type::Person);
        Contact.SetFilter("Company No.", '<>''''');
        IntegrationTableMapping.SetTableFilter(GetTableFilterFromView(DATABASE::Contact, Contact.TableCaption, Contact.GetView));

        CRMContact.Reset;
        CRMContact.SetFilter(ParentCustomerId, '<>''%1''', EmptyGuid);
        CRMContact.SetRange(ParentCustomerIdType, CRMContact.ParentCustomerIdType::account);
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Contact", CRMContact.TableCaption, CRMContact.GetView));
        IntegrationTableMapping."Dependency Filter" := 'CUSTOMER';
        IntegrationTableMapping.Modify;

        // OwnerIdType::systemuser
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMContact.FieldNo(OwnerIdType),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMContact.OwnerIdType::systemuser), false, false);

        // Salesperson Code > OwnerId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Salesperson Code"),
          CRMContact.FieldNo(OwnerId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);
        SetIntegrationFieldMappingNotNull;

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Currency Code"),
          CRMContact.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Address > Address1_Line1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo(Address),
          CRMContact.FieldNo(Address1_Line1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Address 2 > Address1_Line2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Address 2"),
          CRMContact.FieldNo(Address1_Line2),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Post Code > Address1_PostalCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Post Code"),
          CRMContact.FieldNo(Address1_PostalCode),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // City > Address1_City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo(City),
          CRMContact.FieldNo(Address1_City),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Country/Region Code > Address1_Country
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Country/Region Code"),
          CRMContact.FieldNo(Address1_Country),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // County > Address1_StateOrProvince
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo(County),
          CRMContact.FieldNo(Address1_StateOrProvince),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Email > EmailAddress1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("E-Mail"),
          CRMContact.FieldNo(EMailAddress1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Fax No. > Fax
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Fax No."),
          CRMContact.FieldNo(Fax),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // First Name > FirstName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("First Name"),
          CRMContact.FieldNo(FirstName),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Middle Name > MiddleName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Middle Name"),
          CRMContact.FieldNo(MiddleName),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Surname > LastName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo(Surname),
          CRMContact.FieldNo(LastName),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Home Page > WebSiteUrl
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Home Page"),
          CRMContact.FieldNo(WebSiteUrl),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Mobile Phone No. > MobilePhone
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Mobile Phone No."),
          CRMContact.FieldNo(MobilePhone),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Pager > Pager
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo(Pager),
          CRMContact.FieldNo(Pager),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Phone No. > Telephone1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo("Phone No."),
          CRMContact.FieldNo(Telephone1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Type
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Contact.FieldNo(Type), 0,
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          Format(Contact.Type::Person), true, false);

        // CRMContact.ParentCustomerIdType::account
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMContact.FieldNo(ParentCustomerIdType),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMContact.ParentCustomerIdType::account), false, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    local procedure ResetCurrencyTransactionCurrencyMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Currency, DATABASE::"CRM Transactioncurrency",
          CRMTransactioncurrency.FieldNo(TransactionCurrencyId),
          CRMTransactioncurrency.FieldNo(ModifiedOn),
          '',
          '',
          true);

        // Code > ISOCurrencyCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Currency.FieldNo(Code),
          CRMTransactioncurrency.FieldNo(ISOCurrencyCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Code > CurrencySymbol
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Currency.FieldNo(Code),
          CRMTransactioncurrency.FieldNo(CurrencySymbol),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Description > CurrencyName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Currency.FieldNo(Description),
          CRMTransactioncurrency.FieldNo(CurrencyName),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    local procedure ResetItemProductMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Item, DATABASE::"CRM Product",
          CRMProduct.FieldNo(ProductId), CRMProduct.FieldNo(ModifiedOn),
          '', '', true);

        IntegrationTableMapping."Dependency Filter" := 'UNIT OF MEASURE';
        SetIntegrationTableFilterForCRMProduct(IntegrationTableMapping, CRMProduct, CRMProduct.ProductTypeCode::SalesInventory);

        // "No." > ProductNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("No."),
          CRMProduct.FieldNo(ProductNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Description > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo(Description),
          CRMProduct.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Unit Price > Price
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Unit Price"),
          CRMProduct.FieldNo(Price),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Cost > Standard Cost
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Unit Cost"),
          CRMProduct.FieldNo(StandardCost),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Cost > Current Cost
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Unit Cost"),
          CRMProduct.FieldNo(CurrentCost),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Volume > Stock Volume
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Unit Volume"),
          CRMProduct.FieldNo(StockVolume),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Gross Weight > Stock Weight
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Gross Weight"),
          CRMProduct.FieldNo(StockWeight),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Vendor No. > Vendor ID
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Vendor No."),
          CRMProduct.FieldNo(VendorID),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Vendor Item No. > Vendor part number
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Vendor Item No."),
          CRMProduct.FieldNo(VendorPartNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Inventory > Quantity on Hand. If less then zero, it will later be set to zero
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo(Inventory),
          CRMProduct.FieldNo(QuantityOnHand),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Base Unit of Measure > DefaultUoMScheduleId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Base Unit of Measure"),
          CRMProduct.FieldNo(DefaultUoMScheduleId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    local procedure ResetResourceProductMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Resource, DATABASE::"CRM Product",
          CRMProduct.FieldNo(ProductId), CRMProduct.FieldNo(ModifiedOn),
          '', '', true);

        IntegrationTableMapping."Dependency Filter" := 'UNIT OF MEASURE';
        SetIntegrationTableFilterForCRMProduct(IntegrationTableMapping, CRMProduct, CRMProduct.ProductTypeCode::Services);

        // "No." > ProductNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("No."),
          CRMProduct.FieldNo(ProductNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Name > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo(Name),
          CRMProduct.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Unit Price > Price
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("Unit Price"),
          CRMProduct.FieldNo(Price),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Cost > Standard Cost
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("Unit Cost"),
          CRMProduct.FieldNo(StandardCost),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Cost > Current Cost
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("Unit Cost"),
          CRMProduct.FieldNo(CurrentCost),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Vendor No. > Vendor ID
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("Vendor No."),
          CRMProduct.FieldNo(VendorID),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Capacity > Quantity on Hand. If less then zero, it will later be set to zero
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo(Capacity),
          CRMProduct.FieldNo(QuantityOnHand),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    local procedure ResetSalesInvoiceHeaderInvoiceMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CRMInvoice: Record "CRM Invoice";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Sales Invoice Header", DATABASE::"CRM Invoice",
          CRMInvoice.FieldNo(InvoiceId), CRMInvoice.FieldNo(ModifiedOn),
          '', '', true);
        IntegrationTableMapping."Dependency Filter" := 'OPPORTUNITY';
        IntegrationTableMapping.Modify;

        // "No." > InvoiceNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("No."),
          CRMInvoice.FieldNo(InvoiceNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // OwnerId = systemuser
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMInvoice.FieldNo(OwnerIdType),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMInvoice.OwnerIdType::systemuser), false, false);

        // Salesperson Code > OwnerId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Salesperson Code"),
          CRMInvoice.FieldNo(OwnerId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);
        SetIntegrationFieldMappingNotNull;

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Currency Code"),
          CRMInvoice.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Due Date" > DueDate
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Due Date"),
          CRMInvoice.FieldNo(DueDate),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Name"),
          CRMInvoice.FieldNo(ShipTo_Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Address"),
          CRMInvoice.FieldNo(ShipTo_Line1),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Address 2"),
          CRMInvoice.FieldNo(ShipTo_Line2),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to City"),
          CRMInvoice.FieldNo(ShipTo_City),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to Country/Region Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Country/Region Code"),
          CRMInvoice.FieldNo(ShipTo_Country),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Post Code"),
          CRMInvoice.FieldNo(ShipTo_PostalCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to County"),
          CRMInvoice.FieldNo(ShipTo_StateOrProvince),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Shipment Date"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Shipment Date"),
          CRMInvoice.FieldNo(DateDelivered),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Name"),
          CRMInvoice.FieldNo(BillTo_Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Address"),
          CRMInvoice.FieldNo(BillTo_Line1),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Address 2"),
          CRMInvoice.FieldNo(BillTo_Line2),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to City"),
          CRMInvoice.FieldNo(BillTo_City),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Country/Region Code
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Country/Region Code"),
          CRMInvoice.FieldNo(BillTo_Country),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Bill-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Post Code"),
          CRMInvoice.FieldNo(BillTo_PostalCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Bill-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to County"),
          CRMInvoice.FieldNo(BillTo_StateOrProvince),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Amount > TotalAmountLessFreight
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo(Amount),
          CRMInvoice.FieldNo(TotalAmountLessFreight),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Amount Including VAT" > TotalAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Amount Including VAT"),
          CRMInvoice.FieldNo(TotalAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Invoice Discount Amount" > DiscountAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Invoice Discount Amount"),
          CRMInvoice.FieldNo(DiscountAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Shipping Agent Code > address1_shippingmethodcode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Shipping Agent Code"),
          CRMInvoice.FieldNo(ShippingMethodCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Payment Terms Code > paymenttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Payment Terms Code"),
          CRMInvoice.FieldNo(PaymentTermsCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    local procedure ResetSalesInvoiceLineInvoiceMapping(IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CRMInvoicedetail: Record "CRM Invoicedetail";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Sales Invoice Line", DATABASE::"CRM Invoicedetail",
          CRMInvoicedetail.FieldNo(InvoiceDetailId), CRMInvoicedetail.FieldNo(ModifiedOn),
          '', '', false);
        IntegrationTableMapping."Dependency Filter" := 'POSTEDSALESINV-INV';
        IntegrationTableMapping.Modify;

        // Quantity -> Quantity
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo(Quantity),
          CRMInvoicedetail.FieldNo(Quantity),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Line Discount Amount" -> "Manual Discount Amount"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo("Line Discount Amount"),
          CRMInvoicedetail.FieldNo(ManualDiscountAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Unit Price" > PricePerUnit
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo("Unit Price"),
          CRMInvoicedetail.FieldNo(PricePerUnit),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // TRUE > IsPriceOverridden
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0,
          CRMInvoicedetail.FieldNo(IsPriceOverridden),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '1', true, false);

        // Amount -> BaseAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo(Amount),
          CRMInvoicedetail.FieldNo(BaseAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Amount Including VAT" -> ExtendedAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo("Amount Including VAT"),
          CRMInvoicedetail.FieldNo(ExtendedAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);
    end;

    local procedure ResetSalesOrderMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Sales Header", DATABASE::"CRM Salesorder",
          CRMSalesorder.FieldNo(SalesOrderId), CRMSalesorder.FieldNo(ModifiedOn),
          '', '', true);
        SalesHeader.Reset;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        IntegrationTableMapping.SetTableFilter(
          GetTableFilterFromView(DATABASE::"Sales Header", SalesHeader.TableCaption, SalesHeader.GetView));
        IntegrationTableMapping."Dependency Filter" := 'OPPORTUNITY';
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableMapping.Modify;

        // "No." > OrderNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("No."),
          CRMSalesorder.FieldNo(OrderNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // OwnerId = systemuser
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMSalesorder.FieldNo(OwnerIdType),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMSalesorder.OwnerIdType::systemuser), false, false);

        // Salesperson Code > OwnerId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Salesperson Code"),
          CRMSalesorder.FieldNo(OwnerId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);
        SetIntegrationFieldMappingNotNull;

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Currency Code"),
          CRMSalesorder.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Name"),
          CRMSalesorder.FieldNo(ShipTo_Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Address"),
          CRMSalesorder.FieldNo(ShipTo_Line1),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Address 2"),
          CRMSalesorder.FieldNo(ShipTo_Line2),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to City"),
          CRMSalesorder.FieldNo(ShipTo_City),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to Country/Region Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Country/Region Code"),
          CRMSalesorder.FieldNo(ShipTo_Country),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Post Code"),
          CRMSalesorder.FieldNo(ShipTo_PostalCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to County"),
          CRMSalesorder.FieldNo(ShipTo_StateOrProvince),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Shipment Date"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Last Shipment Date"),
          CRMSalesorder.FieldNo(DateFulfilled),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Name"),
          CRMSalesorder.FieldNo(BillTo_Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Address"),
          CRMSalesorder.FieldNo(BillTo_Line1),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Address 2"),
          CRMSalesorder.FieldNo(BillTo_Line2),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to City"),
          CRMSalesorder.FieldNo(BillTo_City),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Country/Region Code
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Country/Region Code"),
          CRMSalesorder.FieldNo(BillTo_Country),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Bill-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Post Code"),
          CRMSalesorder.FieldNo(BillTo_PostalCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Bill-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to County"),
          CRMSalesorder.FieldNo(BillTo_StateOrProvince),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Amount > TotalAmountLessFreight
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo(Amount),
          CRMSalesorder.FieldNo(TotalAmountLessFreight),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Amount Including VAT" > TotalAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Amount Including VAT"),
          CRMSalesorder.FieldNo(TotalAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Invoice Discount Amount" > DiscountAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Invoice Discount Amount"),
          CRMSalesorder.FieldNo(DiscountAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Shipping Agent Code > address1_shippingmethodcode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Shipping Agent Code"),
          CRMSalesorder.FieldNo(ShippingMethodCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Payment Terms Code > paymenttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Payment Terms Code"),
          CRMSalesorder.FieldNo(PaymentTermsCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Requested Delivery Date" -> RequestDeliveryBy
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Requested Delivery Date"),
          CRMSalesorder.FieldNo(RequestDeliveryBy),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    [Scope('OnPrem')]
    procedure ResetSalesOrderMappingConfiguration(CRMConnectionSetup: Record "CRM Connection Setup")
    var
        EnqueueJobQueueEntries: Boolean;
    begin
        EnqueueJobQueueEntries := CRMConnectionSetup.DoReadCRMData;
        if CRMConnectionSetup."Is S.Order Integration Enabled" then begin
            ResetSalesOrderMapping('SALESORDER-ORDER', EnqueueJobQueueEntries);
            RecreateSalesOrderStatusJobQueueEntry(EnqueueJobQueueEntries);
            RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueueEntries);
            CODEUNIT.Run(CODEUNIT::"CRM Enable Posts")
        end else
            DeleteSalesOrderSyncMappingAndJobQueueEntries('SALESORDER-ORDER');
    end;

    local procedure ResetCustomerPriceGroupPricelevelMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CustomerPriceGroup: Record "Customer Price Group";
        CRMPricelevel: Record "CRM Pricelevel";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Customer Price Group", DATABASE::"CRM Pricelevel",
          CRMPricelevel.FieldNo(PriceLevelId), CRMPricelevel.FieldNo(ModifiedOn),
          '', '', true);
        IntegrationTableMapping."Dependency Filter" := 'CURRENCY';
        IntegrationTableMapping.Modify;

        // Code > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          CustomerPriceGroup.FieldNo(Code),
          CRMPricelevel.FieldNo(Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    local procedure ResetSalesPriceProductPricelevelMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesPrice: Record "Sales Price";
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Sales Price", DATABASE::"CRM Productpricelevel",
          CRMProductpricelevel.FieldNo(ProductPriceLevelId), CRMProductpricelevel.FieldNo(ModifiedOn),
          '', '', false);

        SalesPrice.Reset;
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetFilter("Sales Code", '<>''''');
        IntegrationTableMapping.SetTableFilter(
          GetTableFilterFromView(DATABASE::"Sales Price", SalesPrice.TableCaption, SalesPrice.GetView));

        IntegrationTableMapping."Dependency Filter" := 'CUSTPRCGRP-PRICE|ITEM-PRODUCT';
        IntegrationTableMapping.Modify;

        // "Sales Code" > PriceLevelId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Sales Code"),
          CRMProductpricelevel.FieldNo(PriceLevelId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Item No." > ProductId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Item No."),
          CRMProductpricelevel.FieldNo(ProductId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Item No." > ProductNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Item No."),
          CRMProductpricelevel.FieldNo(ProductNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Currency Code"),
          CRMProductpricelevel.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // >> PricingMethodCode = CurrencyAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMProductpricelevel.FieldNo(PricingMethodCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMProductpricelevel.PricingMethodCode::CurrencyAmount), false, false);

        // "Unit Price" > Amount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Unit Price"),
          CRMProductpricelevel.FieldNo(Amount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    local procedure ResetUnitOfMeasureUoMScheduleMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        UnitOfMeasure: Record "Unit of Measure";
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Unit of Measure", DATABASE::"CRM Uomschedule",
          CRMUomschedule.FieldNo(UoMScheduleId), CRMUomschedule.FieldNo(ModifiedOn),
          '', '', true);

        // Code > BaseUoM Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          UnitOfMeasure.FieldNo(Code),
          CRMUomschedule.FieldNo(BaseUoMName),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    local procedure ResetShippingAgentMapping(IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        ShippingAgent: Record "Shipping Agent";
        CRMAccount: Record "CRM Account";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Shipping Agent", DATABASE::"CRM Account",
          CRMAccount.FieldNo(Address1_ShippingMethodCode), 0,
          '', '', false);

        // Code > "CRM Account".Address1_ShippingMethodCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          ShippingAgent.FieldNo(Code),
          CRMAccount.FieldNo(Address1_ShippingMethodCode),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        CRMIntegrationTableSynch.SynchOption(IntegrationTableMapping);
    end;

    local procedure ResetShipmentMethodMapping(IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        ShipmentMethod: Record "Shipment Method";
        CRMAccount: Record "CRM Account";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Shipment Method", DATABASE::"CRM Account",
          CRMAccount.FieldNo(Address1_FreightTermsCode), 0,
          '', '', false);

        // Code > "CRM Account".Address1_FreightTermsCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          ShipmentMethod.FieldNo(Code),
          CRMAccount.FieldNo(Address1_FreightTermsCode),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        CRMIntegrationTableSynch.SynchOption(IntegrationTableMapping);
    end;

    local procedure ResetPaymentTermsMapping(IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        PaymentTerms: Record "Payment Terms";
        CRMAccount: Record "CRM Account";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Payment Terms", DATABASE::"CRM Account",
          CRMAccount.FieldNo(PaymentTermsCode), 0,
          '', '', false);

        // Code > "CRM Account".PaymentTermsCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PaymentTerms.FieldNo(Code),
          CRMAccount.FieldNo(PaymentTermsCode),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        CRMIntegrationTableSynch.SynchOption(IntegrationTableMapping);
    end;

    local procedure ResetOpportunityMapping(IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Opportunity: Record Opportunity;
        CRMOpportunity: Record "CRM Opportunity";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Opportunity, DATABASE::"CRM Opportunity",
          CRMOpportunity.FieldNo(OpportunityId), CRMOpportunity.FieldNo(ModifiedOn),
          '', '', false);
        IntegrationTableMapping."Dependency Filter" := 'CONTACT';
        IntegrationTableMapping.Modify;

        // Description > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo(Description),
          CRMOpportunity.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Contact No." > ParentContactId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo("Contact No."),
          CRMOpportunity.FieldNo(ParentContactId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // OwnerId = systemuser
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMOpportunity.FieldNo(OwnerIdType),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMOpportunity.OwnerIdType::systemuser), false, false);

        // Salesperson Code > OwnerId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo("Salesperson Code"),
          CRMOpportunity.FieldNo(OwnerId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);
        SetIntegrationFieldMappingNotNull;

        // "Estimated Value (LCY)" > EstimatedValue
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo("Estimated Value (LCY)"),
          CRMOpportunity.FieldNo(EstimatedValue),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Estimated Closing Date" > EstimatedCloseDate
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo("Estimated Closing Date"),
          CRMOpportunity.FieldNo(EstimatedCloseDate),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        CRMIntegrationTableSynch.SynchOption(IntegrationTableMapping);
    end;

    local procedure InsertIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean)
    begin
        IntegrationTableMapping.CreateRecord(MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo,
          IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode,
          SynchOnlyCoupledRecords, GetDefaultDirection(TableNo), IntegrationTablePrefixTok);
    end;

    local procedure InsertIntegrationFieldMapping(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.CreateRecord(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection,
          ConstValue, ValidateField, ValidateIntegrationTableField);
    end;

    local procedure SetIntegrationFieldMappingClearValueOnFailedSync()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.FindLast;
        IntegrationFieldMapping."Clear Value on Failed Sync" := true;
        IntegrationFieldMapping.Modify;
    end;

    local procedure SetIntegrationFieldMappingNotNull()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.FindLast;
        IntegrationFieldMapping."Not Null" := true;
        IntegrationFieldMapping.Modify;
    end;

    procedure CreateJobQueueEntry(IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            Init;
            Clear(ID); // "Job Queue - Enqueue" is to define new ID
            "Earliest Start Date/Time" := CurrentDateTime + 1000;
            "Object Type to Run" := "Object Type to Run"::Codeunit;
            "Object ID to Run" := CODEUNIT::"Integration Synch. Job Runner";
            "Record ID to Process" := IntegrationTableMapping.RecordId;
            "Run in User Session" := false;
            "Notify On Success" := false;
            "Maximum No. of Attempts to Run" := 2;
            Status := Status::Ready;
            "Rerun Delay (sec.)" := 30;
            Description :=
              CopyStr(
                StrSubstNo(
                  JobQueueEntryNameTok, IntegrationTableMapping.GetTempDescription, CRMProductName.SHORT), 1, MaxStrLen(Description));
            exit(CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry))
        end;
    end;

    local procedure RecreateStatisticsJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"CRM Statistics Job",
          30,
          StrSubstNo(CustomStatisticsSynchJobDescTxt, CRMProductName.SHORT),
          false);
    end;

    local procedure RecreateSalesOrderStatusJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"CRM Order Status Update Job",
          7,
          StrSubstNo(CustomSalesOrderSynchJobDescTxt, CRMProductName.SHORT),
          false);
    end;

    local procedure RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueEntry: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"CRM Notes Synch Job",
          5,
          StrSubstNo(CustomSalesOrderNotesSynchJobDescTxt, CRMProductName.SHORT),
          false);
    end;

    local procedure RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping: Record "Integration Table Mapping"; IntervalInMinutes: Integer; ShouldRecreateJobQueueEntry: Boolean; InactivityTimeoutPeriod: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", "Object Type to Run"::Codeunit);
            SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
            SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
            DeleteTasks;

            InitRecurringJob(IntervalInMinutes);
            "Object Type to Run" := "Object Type to Run"::Codeunit;
            "Object ID to Run" := CODEUNIT::"Integration Synch. Job Runner";
            "Record ID to Process" := IntegrationTableMapping.RecordId;
            "Run in User Session" := false;
            Description :=
              CopyStr(StrSubstNo(JobQueueEntryNameTok, IntegrationTableMapping.Name, CRMProductName.SHORT), 1, MaxStrLen(Description));
            "Maximum No. of Attempts to Run" := 10;
            Status := Status::Ready;
            "Rerun Delay (sec.)" := 30;
            "Inactivity Timeout Period" := InactivityTimeoutPeriod;
            if ShouldRecreateJobQueueEntry then
                CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry)
            else
                Insert(true);
        end;
    end;

    procedure ResetCRMNAVConnectionData()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationManagement.SetCRMNAVConnectionUrl(GetUrl(CLIENTTYPE::Web));
        CRMIntegrationManagement.SetCRMNAVODataUrlCredentials(
          CRMIntegrationManagement.GetItemAvailabilityWebServiceURL, '', '');
    end;

    procedure RecreateAutoCreateSalesOrdersJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"Auto Create Sales Orders",
          30,
          StrSubstNo(AutoCreateSalesOrdersTxt, CRMProductName.SHORT),
          false);
    end;

    procedure RecreateAutoProcessSalesQuotesJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"Auto Process Sales Quotes",
          30,
          StrSubstNo(AutoProcessQuotesTxt, CRMProductName.SHORT),
          false);
    end;

    local procedure RecreateJobQueueEntry(EnqueueJobQueEntry: Boolean; CodeunitId: Integer; MinutesBetweenRun: Integer; EntryDescription: Text; StatusReady: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", "Object Type to Run"::Codeunit);
            SetRange("Object ID to Run", CodeunitId);
            DeleteTasks;

            InitRecurringJob(MinutesBetweenRun);
            "Object Type to Run" := "Object Type to Run"::Codeunit;
            "Object ID to Run" := CodeunitId;
            Description := CopyStr(EntryDescription, 1, MaxStrLen(Description));
            "Maximum No. of Attempts to Run" := 2;
            if StatusReady then
                Status := Status::Ready
            else begin
                Status := Status::"On Hold with Inactivity Timeout";
                "Inactivity Timeout Period" := MinutesBetweenRun;
            end;
            "Rerun Delay (sec.)" := 30;
            if EnqueueJobQueEntry then
                CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry)
            else
                Insert(true);
        end;
    end;

    procedure DeleteAutoCreateSalesOrdersJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", "Object Type to Run"::Codeunit);
            SetRange("Object ID to Run", CODEUNIT::"Auto Create Sales Orders");
            DeleteTasks;
        end;
    end;

    local procedure DeleteSalesOrderSyncMappingAndJobQueueEntries(IntegrationTableMappingName: Code[20])
    var
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Order Status Update Job");
        JobQueueEntry.DeleteTasks;
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Notes Synch Job");
        JobQueueEntry.DeleteTasks;

        if IntegrationTableMapping.Get(IntegrationTableMappingName) then begin
            JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
            JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
            JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
            JobQueueEntry.DeleteTasks;
            IntegrationTableMapping.Delete;
        end;
    end;

    procedure DeleteAutoProcessSalesQuotesJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", "Object Type to Run"::Codeunit);
            SetRange("Object ID to Run", CODEUNIT::"Auto Process Sales Quotes");
            DeleteTasks;
        end;
    end;

    procedure GetAddPostedSalesDocumentToCRMAccountWallConfig(): Boolean
    begin
        exit(true);
    end;

    procedure GetAllowNonSecureConnections(): Boolean
    begin
        // Most OnPrem solutions uses http if running in a private domain. CRM Server only demands https if the system has been
        // configured with internet connectivity, which is not the default. NAV Should not contrain the connection to CRM if the system
        // admin has configured the CRM service to be on a private domain only.
        exit(true);
    end;

    procedure GetCRMTableNo(NAVTableID: Integer): Integer
    begin
        case NAVTableID of
            DATABASE::Contact:
                exit(DATABASE::"CRM Contact");
            DATABASE::Currency:
                exit(DATABASE::"CRM Transactioncurrency");
            DATABASE::Customer:
                exit(DATABASE::"CRM Account");
            DATABASE::"Customer Price Group":
                exit(DATABASE::"CRM Pricelevel");
            DATABASE::Item,
          DATABASE::Resource:
                exit(DATABASE::"CRM Product");
            DATABASE::"Sales Invoice Header":
                exit(DATABASE::"CRM Invoice");
            DATABASE::"Sales Invoice Line":
                exit(DATABASE::"CRM Invoicedetail");
            DATABASE::"Sales Price":
                exit(DATABASE::"CRM Productpricelevel");
            DATABASE::"Salesperson/Purchaser":
                exit(DATABASE::"CRM Systemuser");
            DATABASE::"Unit of Measure":
                exit(DATABASE::"CRM Uomschedule");
            DATABASE::Opportunity:
                exit(DATABASE::"CRM Opportunity");
            DATABASE::"Sales Header":
                exit(DATABASE::"CRM Salesorder");
            DATABASE::"Record Link":
                exit(DATABASE::"CRM Annotation");
        end;
    end;

    procedure GetDefaultDirection(NAVTableID: Integer): Integer
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        case NAVTableID of
            DATABASE::Contact,
          DATABASE::Customer,
          DATABASE::Item,
          DATABASE::Resource,
          DATABASE::Opportunity:
                exit(IntegrationTableMapping.Direction::Bidirectional);
            DATABASE::Currency,
          DATABASE::"Customer Price Group",
          DATABASE::"Sales Invoice Header",
          DATABASE::"Sales Invoice Line",
          DATABASE::"Sales Price",
          DATABASE::"Unit of Measure":
                exit(IntegrationTableMapping.Direction::ToIntegrationTable);
            DATABASE::"Payment Terms",
          DATABASE::"Shipment Method",
          DATABASE::"Shipping Agent",
          DATABASE::"Salesperson/Purchaser":
                exit(IntegrationTableMapping.Direction::FromIntegrationTable);
        end;
    end;

    procedure GetProductQuantityPrecision(): Integer
    begin
        exit(2);
    end;

    procedure GetNameFieldNo(TableID: Integer): Integer
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CustomerPriceGroup: Record "Customer Price Group";
        CRMPricelevel: Record "CRM Pricelevel";
        Item: Record Item;
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        UnitOfMeasure: Record "Unit of Measure";
        CRMUomschedule: Record "CRM Uomschedule";
        Opportunity: Record Opportunity;
        CRMOpportunity: Record "CRM Opportunity";
    begin
        case TableID of
            DATABASE::Contact:
                exit(Contact.FieldNo(Name));
            DATABASE::"CRM Contact":
                exit(CRMContact.FieldNo(FullName));
            DATABASE::Currency:
                exit(Currency.FieldNo(Code));
            DATABASE::"CRM Transactioncurrency":
                exit(CRMTransactioncurrency.FieldNo(ISOCurrencyCode));
            DATABASE::Customer:
                exit(Customer.FieldNo(Name));
            DATABASE::"CRM Account":
                exit(CRMAccount.FieldNo(Name));
            DATABASE::"Customer Price Group":
                exit(CustomerPriceGroup.FieldNo(Code));
            DATABASE::"CRM Pricelevel":
                exit(CRMPricelevel.FieldNo(Name));
            DATABASE::Item:
                exit(Item.FieldNo("No."));
            DATABASE::Resource:
                exit(Resource.FieldNo("No."));
            DATABASE::"CRM Product":
                exit(CRMProduct.FieldNo(ProductNumber));
            DATABASE::"Salesperson/Purchaser":
                exit(SalespersonPurchaser.FieldNo(Name));
            DATABASE::"CRM Systemuser":
                exit(CRMSystemuser.FieldNo(FullName));
            DATABASE::"Unit of Measure":
                exit(UnitOfMeasure.FieldNo(Code));
            DATABASE::"CRM Uomschedule":
                exit(CRMUomschedule.FieldNo(Name));
            DATABASE::Opportunity:
                exit(Opportunity.FieldNo(Description));
            DATABASE::"CRM Opportunity":
                exit(CRMOpportunity.FieldNo(Name));
        end;
    end;

    local procedure GetTableFilterFromView(TableID: Integer; Caption: Text; View: Text): Text
    var
        FilterBuilder: FilterPageBuilder;
    begin
        FilterBuilder.AddTable(Caption, TableID);
        FilterBuilder.SetView(Caption, View);
        exit(FilterBuilder.GetView(Caption, true));
    end;

    procedure GetPrioritizedMappingList(var NameValueBuffer: Record "Name/Value Buffer")
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
        NextPriority: Integer;
    begin
        NextPriority := 1;

        // 1) From CRM Systemusers
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, 0, DATABASE::"CRM Systemuser");
        // 2) From Currency
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Currency, 0);
        // 3) From Unit of measure
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::"Unit of Measure", 0);
        // 4) To/From Customers/CRM Accounts
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Customer, DATABASE::"CRM Account");
        // 5) To/From Contacts/CRM Contacts
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Contact, DATABASE::"CRM Contact");
        // 6) From Items to CRM Products
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Item, DATABASE::"CRM Product");
        // 7) From Resources to CRM Products
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Resource, DATABASE::"CRM Product");

        IntegrationTableMapping.Reset;
        IntegrationTableMapping.SetFilter("Parent Name", '=''''');
        IntegrationTableMapping.SetRange("Int. Table UID Field Type", Field.Type::GUID);
        if IntegrationTableMapping.FindSet then
            repeat
                AddPrioritizedMappingToList(NameValueBuffer, NextPriority, IntegrationTableMapping.Name);
            until IntegrationTableMapping.Next = 0;
    end;

    local procedure AddPrioritizedMappingsToList(var NameValueBuffer: Record "Name/Value Buffer"; var Priority: Integer; TableID: Integer; IntegrationTableID: Integer)
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        with IntegrationTableMapping do begin
            Reset;
            SetRange("Delete After Synchronization", false);
            if TableID > 0 then
                SetRange("Table ID", TableID);
            if IntegrationTableID > 0 then
                SetRange("Integration Table ID", IntegrationTableID);
            SetRange("Int. Table UID Field Type", Field.Type::GUID);
            if FindSet then
                repeat
                    AddPrioritizedMappingToList(NameValueBuffer, Priority, Name);
                until Next = 0;
        end;
    end;

    local procedure AddPrioritizedMappingToList(var NameValueBuffer: Record "Name/Value Buffer"; var Priority: Integer; MappingName: Code[20])
    begin
        with NameValueBuffer do begin
            SetRange(Value, MappingName);

            if not FindFirst then begin
                Init;
                ID := Priority;
                Name := Format(Priority);
                Value := MappingName;
                Insert;
                Priority := Priority + 1;
            end;

            Reset;
        end;
    end;

    procedure GetTableIDCRMEntityNameMapping(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        TempNameValueBuffer.Reset;
        TempNameValueBuffer.DeleteAll;

        AddEntityTableMapping('systemuser', DATABASE::"Salesperson/Purchaser", TempNameValueBuffer);
        AddEntityTableMapping('systemuser', DATABASE::"CRM Systemuser", TempNameValueBuffer);

        AddEntityTableMapping('account', DATABASE::Customer, TempNameValueBuffer);
        AddEntityTableMapping('account', DATABASE::"CRM Account", TempNameValueBuffer);

        AddEntityTableMapping('contact', DATABASE::Contact, TempNameValueBuffer);
        AddEntityTableMapping('contact', DATABASE::"CRM Contact", TempNameValueBuffer);

        AddEntityTableMapping('product', DATABASE::Item, TempNameValueBuffer);
        AddEntityTableMapping('product', DATABASE::Resource, TempNameValueBuffer);
        AddEntityTableMapping('product', DATABASE::"CRM Product", TempNameValueBuffer);

        AddEntityTableMapping('salesorder', DATABASE::"Sales Header", TempNameValueBuffer);
        AddEntityTableMapping('salesorder', DATABASE::"CRM Salesorder", TempNameValueBuffer);

        AddEntityTableMapping('invoice', DATABASE::"Sales Invoice Header", TempNameValueBuffer);
        AddEntityTableMapping('invoice', DATABASE::"CRM Invoice", TempNameValueBuffer);

        AddEntityTableMapping('opportunity', DATABASE::Opportunity, TempNameValueBuffer);
        AddEntityTableMapping('opportunity', DATABASE::"CRM Opportunity", TempNameValueBuffer);

        // Only NAV
        AddEntityTableMapping('pricelevel', DATABASE::"Customer Price Group", TempNameValueBuffer);
        AddEntityTableMapping('transactioncurrency', DATABASE::Currency, TempNameValueBuffer);
        AddEntityTableMapping('uomschedule', DATABASE::"Unit of Measure", TempNameValueBuffer);

        // Only CRM
        AddEntityTableMapping('incident', DATABASE::"CRM Incident", TempNameValueBuffer);
        AddEntityTableMapping('quote', DATABASE::"CRM Quote", TempNameValueBuffer);
    end;

    local procedure AddEntityTableMapping(CRMEntityTypeName: Text; TableID: Integer; var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        with TempNameValueBuffer do begin
            Init;
            ID := Count + 1;
            Name := CopyStr(CRMEntityTypeName, 1, MaxStrLen(Name));
            Value := Format(TableID);
            Insert;
        end;
    end;

    local procedure ResetAccountConfigTemplate(): Code[10]
    var
        AccountConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        CRMAccount: Record "CRM Account";
    begin
        ConfigTemplateLine.SetRange(
          "Data Template Code", CopyStr(CRMAccountConfigTemplateCodeTok, 1, MaxStrLen(AccountConfigTemplateHeader.Code)));
        ConfigTemplateLine.DeleteAll;
        AccountConfigTemplateHeader.SetRange(
          Code, CopyStr(CRMAccountConfigTemplateCodeTok, 1, MaxStrLen(AccountConfigTemplateHeader.Code)));
        AccountConfigTemplateHeader.DeleteAll;

        AccountConfigTemplateHeader.Init;
        AccountConfigTemplateHeader.Code := CopyStr(CRMAccountConfigTemplateCodeTok, 1, MaxStrLen(AccountConfigTemplateHeader.Code));
        AccountConfigTemplateHeader.Description :=
          CopyStr(CRMAccountConfigTemplateDescTxt, 1, MaxStrLen(AccountConfigTemplateHeader.Description));
        AccountConfigTemplateHeader."Table ID" := DATABASE::"CRM Account";
        AccountConfigTemplateHeader.Insert;
        ConfigTemplateLine.Init;
        ConfigTemplateLine."Data Template Code" := AccountConfigTemplateHeader.Code;
        ConfigTemplateLine."Line No." := 1;
        ConfigTemplateLine.Type := ConfigTemplateLine.Type::Field;
        ConfigTemplateLine."Table ID" := DATABASE::"CRM Account";
        ConfigTemplateLine."Field ID" := CRMAccount.FieldNo(CustomerTypeCode);
        ConfigTemplateLine."Field Name" := CRMAccount.FieldName(CustomerTypeCode);
        ConfigTemplateLine."Default Value" := Format(CRMAccount.CustomerTypeCode::Customer);
        ConfigTemplateLine."Language ID" := GlobalLanguage();
        ConfigTemplateLine.Insert;

        exit(CRMAccountConfigTemplateCodeTok);
    end;

    local procedure ResetCustomerConfigTemplate(): Code[10]
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        CustomerConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        CustomerConfigTemplateLine: Record "Config. Template Line";
        Customer: Record Customer;
        FoundTemplateCode: Code[10];
    begin
        CustomerConfigTemplateLine.SetRange(
          "Data Template Code", CopyStr(CustomerConfigTemplateCodeTok, 1, MaxStrLen(CustomerConfigTemplateLine."Data Template Code")));
        CustomerConfigTemplateLine.DeleteAll;
        CustomerConfigTemplateHeader.SetRange(
          Code, CopyStr(CustomerConfigTemplateCodeTok, 1, MaxStrLen(CustomerConfigTemplateHeader.Code)));
        CustomerConfigTemplateHeader.DeleteAll;

        // Base the customer config template off the first customer template with currency code '' (LCY);
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        if ConfigTemplateHeader.FindSet then
            repeat
                ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
                ConfigTemplateLine.SetRange("Field ID", Customer.FieldNo("Currency Code"));
                ConfigTemplateLine.SetFilter("Default Value", '');
                if ConfigTemplateLine.FindFirst then begin
                    FoundTemplateCode := ConfigTemplateHeader.Code;
                    break;
                end;
            until ConfigTemplateHeader.Next = 0;

        if FoundTemplateCode = '' then
            exit('');

        CustomerConfigTemplateHeader.Init;
        CustomerConfigTemplateHeader.TransferFields(ConfigTemplateHeader, false);
        CustomerConfigTemplateHeader.Code := CopyStr(CustomerConfigTemplateCodeTok, 1, MaxStrLen(CustomerConfigTemplateHeader.Code));
        CustomerConfigTemplateHeader.Description :=
          CopyStr(CustomerConfigTemplateDescTxt, 1, MaxStrLen(CustomerConfigTemplateHeader.Description));
        CustomerConfigTemplateHeader.Insert;

        ConfigTemplateLine.Reset;
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.FindSet;
        repeat
            CustomerConfigTemplateLine.Init;
            CustomerConfigTemplateLine.TransferFields(ConfigTemplateLine, true);
            CustomerConfigTemplateLine."Data Template Code" := CustomerConfigTemplateHeader.Code;
            CustomerConfigTemplateLine.Insert;
        until ConfigTemplateLine.Next = 0;

        exit(CustomerConfigTemplateCodeTok);
    end;

    local procedure RegisterTempConnectionIfNeeded(CRMConnectionSetup: Record "CRM Connection Setup"; var TempCRMConnectionSetup: Record "CRM Connection Setup" temporary) ConnectionName: Text
    begin
        if CRMConnectionSetup."Is User Mapping Required" then begin
            ConnectionName := Format(CreateGuid);
            TempCRMConnectionSetup.TransferFields(CRMConnectionSetup);
            TempCRMConnectionSetup."Is User Mapping Required" := false;
            TempCRMConnectionSetup.RegisterConnectionWithName(ConnectionName);
        end;
    end;

    local procedure ResetDefaultCRMPricelevel(CRMConnectionSetup: Record "CRM Connection Setup")
    begin
        CRMConnectionSetup.Find;
        Clear(CRMConnectionSetup."Default CRM Price List ID");
        CRMConnectionSetup.Modify;
    end;

    local procedure SetIntegrationTableFilterForCRMProduct(var IntegrationTableMapping: Record "Integration Table Mapping"; CRMProduct: Record "CRM Product"; ProductTypeCode: Option)
    begin
        CRMProduct.SetRange(ProductTypeCode, ProductTypeCode);
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Product", CRMProduct.TableCaption, CRMProduct.GetView));
        IntegrationTableMapping.Modify;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetConfiguration(CRMConnectionSetup: Record "CRM Connection Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetCustomerAccountMapping(IntegrationTableMappingName: Code[20])
    begin
    end;
}

