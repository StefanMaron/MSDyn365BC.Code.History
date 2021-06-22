codeunit 7204 "CDS Setup Defaults"
{

    trigger OnRun()
    begin
    end;

    var
        JobQueueEntryNameTok: Label ' %1 - %2 synchronization job.', Comment = '%1 = The Integration Table Name to synchronized (ex. CUSTOMER), %2 = CRM product name';
        IntegrationTablePrefixTok: Label 'Dynamics CRM', Comment = 'Product name', Locked = true;
        CDSCustomerConfigTemplateCodeTok: Label 'CDSCUSTOME', Comment = 'Config. Template code for Common Data Service Accounts created from Customers. Max length 10.', Locked = true;
        CDSVendorConfigTemplateCodeTok: Label 'CDSVENDOR', Comment = 'Config. Template code for Common Data Service Accounts created from Vendors. Max length 10.', Locked = true;
        CRMAccountConfigTemplateDescTxt: Label 'New CRM Account records created during synch.', Comment = 'Max. length 50.';
        CustomerConfigTemplateCodeTok: Label 'CDSCUST', Comment = 'Customer template code for new customers created from Common Data Service data. Max length 10.', Locked = true;
        VendorConfigTemplateCodeTok: Label 'CDSVEND', Comment = 'Vendor template code for new vendors created from Common Data Service data. Max length 10.', Locked = true;
        CustomerConfigTemplateDescTxt: Label 'New Customer records created during synch.', Comment = 'Max. length 50.';
        VendorConfigTemplateDescTxt: Label 'New Vendor records created during synch.', Comment = 'Max. length 50.';
        CDSTxt: Label 'Common Data Service', Locked = true;

    procedure ResetConfiguration(var CDSConnectionSetup: Record "CDS Connection Setup")
    var
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        CDSIntegrationMgt.RegisterConnection();
        CDSIntegrationMgt.ActivateConnection();

        ResetSalesPeopleSystemUserMapping('SALESPEOPLE', true);
        ResetCustomerAccountMapping('CUSTOMER', true);
        ResetVendorAccountMapping('VENDOR', true);
        ResetContactContactMapping('CONTACT', true);
        ResetCurrencyTransactionCurrencyMapping('CURRENCY', true);
        ResetPaymentTermsMapping('PAYMENT TERMS');
        ResetShipmentMethodMapping('SHIPMENT METHOD');
        ResetShippingAgentMapping('SHIPPING AGENT');
        CDSConnectionSetup.SetBaseCurrencyData();
        RemoveCustomerContactLinkJobQueueEntries();

        OnAfterResetConfiguration(CDSConnectionSetup);
    end;

    local procedure ResetSalesPeopleSystemUserMapping(IntegrationTableMappingName: Code[20]; ShouldRecreateJobQueueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CDSSystemuser: Record "CRM Systemuser";
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser",
          CDSSystemuser.FieldNo(SystemUserId), CDSSystemuser.FieldNo(ModifiedOn),
          '', '', true);

        CDSSystemuser.Reset();
        CDSSystemuser.SetRange(IsDisabled, false);
        CDSSystemuser.SetRange(IsLicensed, true);
        CDSSystemuser.SetRange(IsIntegrationUser, false);
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Systemuser", CDSSystemuser.TableCaption(), CDSSystemuser.GetView()));
        IntegrationTableMapping.Modify();

        // Email > InternalEMailAddress
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalespersonPurchaser.FieldNo("E-Mail"),
          CDSSystemuser.FieldNo(InternalEMailAddress),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        // Name > FullName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalespersonPurchaser.FieldNo(Name),
          CDSSystemuser.FieldNo(FullName),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        // Phone No. > MobilePhone
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalespersonPurchaser.FieldNo("Phone No."),
          CDSSystemuser.FieldNo(MobilePhone),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        if CDSConnectionSetup.Get() then
            if CDSConnectionSetup."Ownership Model" = CDSConnectionSetup."Ownership Model"::Person then
                RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, ShouldRecreateJobQueueEntry, 1440);
    end;

    local procedure ResetCustomerAccountMapping(IntegrationTableMappingName: Code[20]; ShouldRecreateJobQueueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSCompany: Record "CDS Company";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EmptyGuid: Guid;
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Customer, DATABASE::"CRM Account",
          CRMAccount.FieldNo(AccountId), CRMAccount.FieldNo(ModifiedOn),
          ResetBCAccountConfigTemplate(Database::Customer), ResetCDSAccountConfigTemplate(Database::Customer), true);

        Customer.SetRange(Blocked, Customer.Blocked::" ");
        IntegrationTableMapping.SetTableFilter(GetTableFilterFromView(DATABASE::Customer, Customer.TableCaption(), Customer.GetView()));

        CRMAccount.SetRange(StateCode, CRMAccount.StateCode::Active);
        CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Customer);
        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            CRMAccount.SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Account", CRMAccount.TableCaption(), CRMAccount.GetView()));
        if CDSConnectionSetup.Get() then
            if CDSConnectionSetup."Ownership Model" = CDSConnectionSetup."Ownership Model"::Person then
                IntegrationTableMapping."Dependency Filter" := 'SALESPEOPLE|CURRENCY'
            else
                IntegrationTableMapping."Dependency Filter" := 'CURRENCY';
        IntegrationTableMapping.Modify();

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
        SetIntegrationFieldMappingNotNull();

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
          IntegrationFieldMapping.Direction::Bidirectional,
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

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Currency Code"),
          CRMAccount.FieldNo(TransactionCurrencyId),
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
          CRMAccount.FieldNo(Address1_FreightTermsCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Shipping Agent Code > address1_shippingmethodcode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Shipping Agent Code"),
          CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Payment Terms Code > paymenttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Customer.FieldNo("Payment Terms Code"),
          CRMAccount.FieldNo(PaymentTermsCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
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
        SetIntegrationFieldMappingClearValueOnFailedSync();

        OnAfterResetCustomerAccountMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, ShouldRecreateJobQueueEntry, 720);
    end;

    local procedure ResetVendorAccountMapping(IntegrationTableMappingName: Code[20]; ShouldRecreateJobQueueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMAccount: Record "CRM Account";
        Vendor: Record Vendor;
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSCompany: Record "CDS Company";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EmptyGuid: Guid;
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Vendor, DATABASE::"CRM Account",
          CRMAccount.FieldNo(AccountId), CRMAccount.FieldNo(ModifiedOn),
          ResetBCAccountConfigTemplate(Database::Vendor), ResetCDSAccountConfigTemplate(Database::Vendor), true);

        Vendor.SetRange(Blocked, Vendor.Blocked::" ");
        IntegrationTableMapping.SetTableFilter(GetTableFilterFromView(DATABASE::Vendor, Vendor.TableCaption(), Vendor.GetView()));

        CRMAccount.SetRange(StateCode, CRMAccount.StateCode::Active);
        CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Vendor);
        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            CRMAccount.SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Account", CRMAccount.TableCaption(), CRMAccount.GetView()));
        if CDSConnectionSetup.Get() then
            if CDSConnectionSetup."Ownership Model" = CDSConnectionSetup."Ownership Model"::Person then
                IntegrationTableMapping."Dependency Filter" := 'SALESPEOPLE|CURRENCY'
            else
                IntegrationTableMapping."Dependency Filter" := 'CURRENCY';
        IntegrationTableMapping.Modify();

        // OwnerIdType::systemuser
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMAccount.FieldNo(OwnerIdType),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMAccount.OwnerIdType::systemuser), false, false);

        // Purchaser Code > OwnerId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Purchaser Code"),
          CRMAccount.FieldNo(OwnerId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);
        SetIntegrationFieldMappingNotNull();

        // Name > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo(Name),
          CRMAccount.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Contact > Address1_PrimaryContactName
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo(Contact),
          CRMAccount.FieldNo(Address1_PrimaryContactName),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', false, false); // We do not validate contact name.

        // Address > Address1_Line1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo(Address),
          CRMAccount.FieldNo(Address1_Line1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Address 2 > Address1_Line2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Address 2"),
          CRMAccount.FieldNo(Address1_Line2),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Post Code > Address1_PostalCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Post Code"),
          CRMAccount.FieldNo(Address1_PostalCode),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // City > Address1_City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo(City),
          CRMAccount.FieldNo(Address1_City),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Country > Address1_Country
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Country/Region Code"),
          CRMAccount.FieldNo(Address1_Country),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // County > Address1_StateOrProvince
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo(County),
          CRMAccount.FieldNo(Address1_StateOrProvince),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Currency Code"),
          CRMAccount.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Email > EmailAddress1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("E-Mail"),
          CRMAccount.FieldNo(EMailAddress1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Fax No > Fax
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Fax No."),
          CRMAccount.FieldNo(Fax),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Home Page > WebSiteUrl
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Home Page"),
          CRMAccount.FieldNo(WebSiteURL),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Phone No. > Telephone1
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Phone No."),
          CRMAccount.FieldNo(Telephone1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Shipment Method Code > address1_freighttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Shipment Method Code"),
          CRMAccount.FieldNo(Address1_FreightTermsCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Shipping Agent Code > address1_shippingmethodcode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Shipping Agent Code"),
          CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Payment Terms Code > paymenttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Payment Terms Code"),
          CRMAccount.FieldNo(PaymentTermsCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Primary Contact No." > PrimaryContactId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Vendor.FieldNo("Primary Contact No."),
          CRMAccount.FieldNo(PrimaryContactId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);
        SetIntegrationFieldMappingClearValueOnFailedSync();

        OnAfterResetVendorAccountMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, ShouldRecreateJobQueueEntry, 720);
    end;

    local procedure ResetContactContactMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMContact: Record "CRM Contact";
        Contact: Record Contact;
        CDSCompany: Record "CDS Company";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EmptyGuid: Guid;
    begin
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Contact, DATABASE::"CRM Contact",
          CRMContact.FieldNo(ContactId), CRMContact.FieldNo(ModifiedOn),
          '', '', true);

        Contact.Reset();
        Contact.SetRange(Type, Contact.Type::Person);
        Contact.SetFilter("Company No.", '<>''''');
        IntegrationTableMapping.SetTableFilter(GetTableFilterFromView(DATABASE::Contact, Contact.TableCaption(), Contact.GetView()));

        CRMContact.Reset();
        CRMContact.SetFilter(ParentCustomerId, '<>''%1''', EmptyGuid);
        CRMContact.SetRange(ParentCustomerIdType, CRMContact.ParentCustomerIdType::account);
        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            CRMContact.SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Contact", CRMContact.TableCaption(), CRMContact.GetView()));
        IntegrationTableMapping."Dependency Filter" := 'CUSTOMER|VENDOR';
        IntegrationTableMapping.Modify();

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
        SetIntegrationFieldMappingNotNull();

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

        OnAfterResetContactContactMapping(IntegrationTableMappingName);

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
          CRMAccount.FieldNo(PaymentTermsCodeEnum), 0,
          '', '', false);

        // Code > "CRM Account".PaymentTermsCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PaymentTerms.FieldNo(Code),
          CRMAccount.FieldNo(PaymentTermsCodeEnum),
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
          CRMAccount.FieldNo(Address1_FreightTermsCodeEnum), 0,
          '', '', false);

        // Code > "CRM Account".Address1_FreightTermsCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          ShipmentMethod.FieldNo(Code),
          CRMAccount.FieldNo(Address1_FreightTermsCodeEnum),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        CRMIntegrationTableSynch.SynchOption(IntegrationTableMapping);
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
          CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum), 0,
          '', '', false);

        // Code > "CRM Account".Address1_ShippingMethodCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          ShippingAgent.FieldNo(Code),
          CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
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
        IntegrationFieldMapping.FindLast();
        IntegrationFieldMapping."Clear Value on Failed Sync" := true;
        IntegrationFieldMapping.Modify();
    end;

    local procedure SetIntegrationFieldMappingNotNull()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.FindLast();
        IntegrationFieldMapping."Not Null" := true;
        IntegrationFieldMapping.Modify();
    end;

    procedure CreateJobQueueEntry(IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    // TO DO: This is needed for "Run Full Synch"
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            Init();
            Clear(ID); // "Job Queue - Enqueue" is to define new ID
            "Earliest Start Date/Time" := CurrentDateTime() + 1000;
            "Object Type to Run" := "Object Type to Run"::Codeunit;
            "Object ID to Run" := CODEUNIT::"Integration Synch. Job Runner";
            "Record ID to Process" := IntegrationTableMapping.RecordId();
            "Run in User Session" := false;
            "Notify On Success" := false;
            "Maximum No. of Attempts to Run" := 2;
            Status := Status::Ready;
            "Rerun Delay (sec.)" := 30;
            Description :=
              CopyStr(
                StrSubstNo(
                  JobQueueEntryNameTok, IntegrationTableMapping.GetTempDescription(), CDSTxt), 1, MaxStrLen(Description));
            exit(CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry))
        end;
    end;

    local procedure RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping: Record "Integration Table Mapping"; IntervalInMinutes: Integer; ShouldRecreateJobQueueEntry: Boolean; InactivityTimeoutPeriod: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", "Object Type to Run"::Codeunit);
            SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
            SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
            DeleteTasks();

            InitRecurringJob(IntervalInMinutes);
            "Object Type to Run" := "Object Type to Run"::Codeunit;
            "Object ID to Run" := CODEUNIT::"Integration Synch. Job Runner";
            "Record ID to Process" := IntegrationTableMapping.RecordId();
            "Run in User Session" := false;
            Description :=
              CopyStr(StrSubstNo(JobQueueEntryNameTok, IntegrationTableMapping.Name, CDSTxt), 1, MaxStrLen(Description));
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

    [Scope('OnPrem')]
    procedure RemoveCustomerContactLinkJobQueueEntries();
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Customer-Contact Link");
        JobQueueEntry.DeleteTasks();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Setup Defaults", 'OnGetCDSTableNo', '', false, false)]
    local procedure ReturnProxyTableNoOnGetCDSTableNo(BCTableNo: Integer; var CDSTableNo: Integer; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if handled then
            exit;

        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        case BCTableNo of
            DATABASE::Contact:
                CDSTableNo := DATABASE::"CRM Contact";
            DATABASE::Currency:
                CDSTableNo := DATABASE::"CRM Transactioncurrency";
            DATABASE::Customer,
            DATABASE::Vendor:
                CDSTableNo := DATABASE::"CRM Account";
            DATABASE::"Salesperson/Purchaser":
                CDSTableNo := DATABASE::"CRM Systemuser";
        end;

        if CDSTableNo <> 0 then
            handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Setup Defaults", 'OnAddEntityTableMapping', '', false, false)]
    local procedure AddProxyTablesOnAddEntityTableMapping(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        TempNameValueBuffer.ID := TempNameValueBuffer.Count() + 1;
        TempNameValueBuffer.Name := 'account';
        TempNameValueBuffer.Value := Format(Database::Vendor);
        TempNameValueBuffer.Insert();
    end;

    procedure GetDefaultDirection(NAVTableID: Integer): Integer
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        case NAVTableID of
            DATABASE::Contact,
          DATABASE::Customer:
                exit(IntegrationTableMapping.Direction::Bidirectional);
            DATABASE::Currency:
                exit(IntegrationTableMapping.Direction::ToIntegrationTable);
            DATABASE::"Payment Terms",
          DATABASE::"Shipment Method",
          DATABASE::"Shipping Agent",
          DATABASE::"Salesperson/Purchaser":
                exit(IntegrationTableMapping.Direction::FromIntegrationTable);
        end;
    end;

    local procedure GetTableFilterFromView(TableID: Integer; Caption: Text; View: Text): Text
    var
        FilterBuilder: FilterPageBuilder;
    begin
        FilterBuilder.AddTable(Caption, TableID);
        FilterBuilder.SetView(Caption, View);
        exit(FilterBuilder.GetView(Caption, false));
    end;

    procedure GetPrioritizedMappingList(var NameValueBuffer: Record "Name/Value Buffer")
    // TO DO: This is needed for "Synchronize Modified Records" that we should add
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
        // 3) To/From Customers/CRM Accounts
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Customer, DATABASE::"CRM Account");
        // 4)  Vendor
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Vendor, DATABASE::"CRM Account");
        // 5) To/From Contacts/CRM Contacts
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Contact, DATABASE::"CRM Contact");

        IntegrationTableMapping.Reset();
        IntegrationTableMapping.SetFilter("Parent Name", '=''''');
        IntegrationTableMapping.SetRange("Int. Table UID Field Type", Field.Type::GUID);
        if IntegrationTableMapping.FindSet() then
            repeat
                AddPrioritizedMappingToList(NameValueBuffer, NextPriority, IntegrationTableMapping.Name);
            until IntegrationTableMapping.Next() = 0;
    end;

    local procedure AddPrioritizedMappingsToList(var NameValueBuffer: Record "Name/Value Buffer"; var Priority: Integer; TableID: Integer; IntegrationTableID: Integer)
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        with IntegrationTableMapping do begin
            Reset();
            SetRange("Delete After Synchronization", false);
            if TableID > 0 then
                SetRange("Table ID", TableID);
            if IntegrationTableID > 0 then
                SetRange("Integration Table ID", IntegrationTableID);
            SetRange("Int. Table UID Field Type", Field.Type::GUID);
            if FindSet() then
                repeat
                    AddPrioritizedMappingToList(NameValueBuffer, Priority, Name);
                until Next() = 0;
        end;
    end;

    local procedure AddPrioritizedMappingToList(var NameValueBuffer: Record "Name/Value Buffer"; var Priority: Integer; MappingName: Code[20])
    begin
        with NameValueBuffer do begin
            SetRange(Value, MappingName);

            if not FindFirst() then begin
                Init();
                ID := Priority;
                Name := Format(Priority);
                Value := MappingName;
                Insert();
                Priority := Priority + 1;
            end;

            Reset();
        end;
    end;

    local procedure ResetCDSAccountConfigTemplate(TableNo: Integer): Code[10]
    var
        AccountConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        CRMAccount: Record "CRM Account";
        TemplateCode: Code[10];
        CustomerTypeCode: Option;
    begin
        case TableNo of
            Database::Customer:
                begin
                    TemplateCode := CDSCustomerConfigTemplateCodeTok;
                    CustomerTypeCode := CRMAccount.CustomerTypeCode::Customer;
                end;
            Database::Vendor:
                begin
                    TemplateCode := CDSVendorConfigTemplateCodeTok;
                    CustomerTypeCode := CRMAccount.CustomerTypeCode::Vendor;
                end;
            else
                exit('');
        end;

        ConfigTemplateLine.SetRange(
          "Data Template Code", CopyStr(TemplateCode, 1, MaxStrLen(AccountConfigTemplateHeader.Code)));
        ConfigTemplateLine.DeleteAll();
        AccountConfigTemplateHeader.SetRange(
          Code, CopyStr(TemplateCode, 1, MaxStrLen(AccountConfigTemplateHeader.Code)));
        AccountConfigTemplateHeader.DeleteAll();

        AccountConfigTemplateHeader.Init();
        AccountConfigTemplateHeader.Code := CopyStr(TemplateCode, 1, MaxStrLen(AccountConfigTemplateHeader.Code));
        AccountConfigTemplateHeader.Description :=
          CopyStr(CRMAccountConfigTemplateDescTxt, 1, MaxStrLen(AccountConfigTemplateHeader.Description));
        AccountConfigTemplateHeader."Table ID" := DATABASE::"CRM Account";
        AccountConfigTemplateHeader.Insert();
        ConfigTemplateLine.Init();
        ConfigTemplateLine."Data Template Code" := AccountConfigTemplateHeader.Code;
        ConfigTemplateLine."Line No." := 1;
        ConfigTemplateLine.Type := ConfigTemplateLine.Type::Field;
        ConfigTemplateLine."Table ID" := DATABASE::"CRM Account";
        ConfigTemplateLine."Field ID" := CRMAccount.FieldNo(CustomerTypeCode);
        ConfigTemplateLine."Field Name" := CRMAccount.FieldName(CustomerTypeCode);
        ConfigTemplateLine."Default Value" := Format(CustomerTypeCode);
        ConfigTemplateLine."Language ID" := GlobalLanguage();
        ConfigTemplateLine.Insert();

        exit(TemplateCode);
    end;

    local procedure ResetBCAccountConfigTemplate(TableNo: Integer): Code[10]
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        BCAccountConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        BCAccountConfigTemplateLine: Record "Config. Template Line";
        Customer: Record Customer;
        Vendor: Record Vendor;
        FoundTemplateCode: Code[10];
        ConfigTemplateCode: Code[10];
        ConfigTemplateDesc: Text;
        CurrencyFieldNo: Integer;
    begin
        case TableNo of
            Database::Customer:
                begin
                    ConfigTemplateCode := CustomerConfigTemplateCodeTok;
                    ConfigTemplateDesc := CustomerConfigTemplateDescTxt;
                    CurrencyFieldNo := Customer.FieldNo("Currency Code");
                end;
            Database::Vendor:
                begin
                    ConfigTemplateCode := VendorConfigTemplateCodeTok;
                    ConfigTemplateDesc := VendorConfigTemplateDescTxt;
                    CurrencyFieldNo := Vendor.FieldNo("Currency Code");
                end;
            else
                exit('');
        end;

        BCAccountConfigTemplateLine.SetRange(
          "Data Template Code", CopyStr(ConfigTemplateCode, 1, MaxStrLen(BCAccountConfigTemplateLine."Data Template Code")));
        BCAccountConfigTemplateLine.DeleteAll();
        BCAccountConfigTemplateHeader.SetRange(
          Code, CopyStr(ConfigTemplateCode, 1, MaxStrLen(BCAccountConfigTemplateHeader.Code)));
        BCAccountConfigTemplateHeader.DeleteAll();

        // Base the customer config template off the first customer template with currency code '' (LCY);
        ConfigTemplateHeader.SetRange("Table ID", TableNo);
        if ConfigTemplateHeader.FindSet() then
            repeat
                ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
                ConfigTemplateLine.SetRange("Field ID", CurrencyFieldNo);
                ConfigTemplateLine.SetFilter("Default Value", '');
                if ConfigTemplateLine.FindFirst() then begin
                    FoundTemplateCode := ConfigTemplateHeader.Code;
                    break;
                end;
            until ConfigTemplateHeader.Next() = 0;

        if FoundTemplateCode = '' then
            exit('');

        BCAccountConfigTemplateHeader.Init();
        BCAccountConfigTemplateHeader.TransferFields(ConfigTemplateHeader, false);
        BCAccountConfigTemplateHeader.Code := CopyStr(ConfigTemplateCode, 1, MaxStrLen(BCAccountConfigTemplateHeader.Code));
        BCAccountConfigTemplateHeader.Description :=
          CopyStr(ConfigTemplateDesc, 1, MaxStrLen(BCAccountConfigTemplateHeader.Description));
        BCAccountConfigTemplateHeader.Insert();

        ConfigTemplateLine.Reset();
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.FindSet();
        repeat
            if not (ConfigTemplateLine."Field ID" = CurrencyFieldNo) then begin
                BCAccountConfigTemplateLine.Init();
                BCAccountConfigTemplateLine.TransferFields(ConfigTemplateLine, true);
                BCAccountConfigTemplateLine."Data Template Code" := BCAccountConfigTemplateHeader.Code;
                BCAccountConfigTemplateLine.Insert();
            end;
        until ConfigTemplateLine.Next() = 0;

        exit(ConfigTemplateCode);
    end;

    [Scope('OnPrem')]
    procedure RunCoupleSalespeoplePage()
    var
        CRMSystemuser: Record "CRM Systemuser";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
        CRMSystemuserList: Page "CRM Systemuser List";
        IntTableFilter: Text;
    begin
        IntTableFilter :=
          LookupCRMTables.GetIntegrationTableFilter(DATABASE::"CRM Systemuser", DATABASE::"Salesperson/Purchaser");
        CRMSystemuser.SetView(IntTableFilter);
        CRMSystemuserList.SetTableView(CRMSystemuser);
        CRMSystemuserList.Initialize(true);
        CRMSystemuserList.Run();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Integration Mgt.", 'OnEnableIntegration', '', false, false)]
    local procedure HandleOnEnableIntegration()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CDSConnectionSetup.Get();
        case CDSConnectionSetup."Ownership Model" of
            CDSConnectionSetup."Ownership Model"::Person:
                if IntegrationTableMapping.Get('SALESPEOPLE') then begin
                    RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, true, 1440);
                    if IntegrationTableMapping.Get('VENDOR') then begin
                        IntegrationTableMapping."Dependency Filter" := 'SALESPEOPLE|CURRENCY';
                        IntegrationTableMapping.Modify();
                    end;
                    if IntegrationTableMapping.Get('CUSTOMER') then begin
                        IntegrationTableMapping."Dependency Filter" := 'SALESPEOPLE|CURRENCY';
                        IntegrationTableMapping.Modify();
                    end;
                end;
            CDSConnectionSetup."Ownership Model"::Team:
                if IntegrationTableMapping.Get('SALESPEOPLE') then begin
                    JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                    JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
                    JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
                    JobQueueEntry.DeleteTasks();
                    IntegrationTableMapping.Delete(true);
                    if IntegrationTableMapping.Get('VENDOR') then begin
                        IntegrationTableMapping."Dependency Filter" := 'CURRENCY';
                        IntegrationTableMapping.Modify();
                    end;
                    if IntegrationTableMapping.Get('CUSTOMER') then begin
                        IntegrationTableMapping."Dependency Filter" := 'CURRENCY';
                        IntegrationTableMapping.Modify();
                    end;
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetConfiguration(CDSConnectionSetup: Record "CDS Connection Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetCustomerAccountMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetVendorAccountMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetContactContactMapping(IntegrationTableMappingName: Code[20])
    begin
    end;
}

