codeunit 5461 "Graph Int. - Contact"
{

    trigger OnRun()
    begin
    end;

    var
        BusinessTypeMissingErr: Label 'BusinessType is not present on Graph Contact.', Locked = true;
        BusinessTypeUnknownValueErr: Label 'BusinessType has an invalid value: %1.', Locked = true;
        BusinessCategoryMissingErr: Label 'The Graph Contact must have 1 or more business category fields.', Locked = true;
        BusinessCategoryWrongValueErr: Label 'The business category has an invalid value: %1.\%2.', Locked = true;
        NoBusinessCategoryErr: Label 'At least one business category must be set to True.', Locked = true;
        CannotGetGraphXrmIdErr: Label 'Cannot find the graph XrmId for graph record id %1.', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnAfterTransferRecordFields', '', false, false)]
    local procedure OnAfterTransferRecordFields(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var AdditionalFieldsWereModified: Boolean)
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Contact-Graph Contact':
                begin
                    DestinationRecordRef.SetTable(GraphContact);
                    SourceRecordRef.SetTable(Contact);
                    SetContactFieldsOnGraph(Contact, GraphContact);
                    SetIntegrationIdFieldOnGraph(Contact, GraphContact);
                    AdditionalFieldsWereModified := true;
                    DestinationRecordRef.GetTable(GraphContact);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnBeforeInsertRecord', '', false, false)]
    local procedure OnBeforeInsertRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        ContactType: Option;
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Graph Contact-Contact':
                begin
                    DestinationRecordRef.SetTable(Contact);
                    SourceRecordRef.SetTable(GraphContact);
                    VerifyGraphContactRequiredData(GraphContact);
                    ContactType := Contact.Type;
                    GraphCollectionMgtContact.GetBusinessType(GraphContact.GetBusinessTypeString, ContactType);
                    Contact.Type := ContactType;
                    SetGraphFieldsOnContact(GraphContact, Contact);
                    DestinationRecordRef.GetTable(Contact);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnAfterInsertRecord', '', false, false)]
    local procedure OnAfterInsertRecord(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        ModifySourceRecord: Boolean;
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Graph Contact-Contact':
                begin
                    DestinationRecordRef.SetTable(Contact);
                    SourceRecordRef.SetTable(GraphContact);
                    SetContactBusinessRelations(GraphContact, Contact);
                    CheckAndFixDisplayName(GraphContact, Contact, ModifySourceRecord);
                    ModifySourceGraphContact(GraphContact, ModifySourceRecord);
                    DestinationRecordRef.GetTable(Contact);
                    SourceRecordRef.GetTable(GraphContact);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnBeforeModifyRecord', '', false, false)]
    local procedure OnBeforeModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        GraphContact: Record "Graph Contact";
        Contact: Record Contact;
        ModifySource: Boolean;
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Graph Contact-Contact':
                begin
                    DestinationRecordRef.SetTable(Contact);
                    SourceRecordRef.SetTable(GraphContact);
                    VerifyGraphContactRequiredData(GraphContact);
                    SetGraphFieldsOnContact(GraphContact, Contact);
                    SetContactBusinessRelations(GraphContact, Contact);
                    DestinationRecordRef.GetTable(Contact);
                end;
            'Contact-Graph Contact':
                begin
                    DestinationRecordRef.SetTable(GraphContact);
                    SourceRecordRef.SetTable(Contact);
                    CheckAndFixContactBusinessRelations(GraphContact, Contact, ModifySource);
                    if ModifySource then
                        DestinationRecordRef.GetTable(GraphContact);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnAfterModifyRecord', '', false, false)]
    local procedure OnAfterModifyRecord(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        GraphContact: Record "Graph Contact";
        Contact: Record Contact;
        ModifySourceRecord: Boolean;
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Graph Contact-Contact':
                begin
                    DestinationRecordRef.SetTable(Contact);
                    SourceRecordRef.SetTable(GraphContact);
                    SetContactBusinessRelations(GraphContact, Contact);
                    CheckAndFixContactBusinessRelations(GraphContact, Contact, ModifySourceRecord);
                    CheckAndFixDisplayName(GraphContact, Contact, ModifySourceRecord);
                    ModifySourceGraphContact(GraphContact, ModifySourceRecord);
                    SourceRecordRef.GetTable(GraphContact);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5347, 'OnBeforeDeleteRecord', '', false, false)]
    local procedure OnBeforeDeleteRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var DestinationRecordRef: RecordRef)
    var
        Contact: Record Contact;
    begin
        case GetDestCode(DestinationRecordRef) of
            'Contact':
                begin
                    DestinationRecordRef.SetTable(Contact);
                    BlockCustVendBank(Contact);
                end;
        end;
    end;

    procedure FindOrCreateCustomerFromGraphContactSafe(GraphContactId: Text[250]; var Customer: Record Customer; var Contact: Record Contact): Boolean
    var
        MarketingSetup: Record "Marketing Setup";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        if not FindContactFromGraphId(GraphContactId, Contact) then begin
            GraphSyncRunner.SyncFromGraphSynchronously(
              CODEUNIT::"Graph Subscription Management", GraphSyncRunner.GetDefaultSyncSynchronouslyTimeoutInSeconds);
            if not FindContactFromGraphId(GraphContactId, Contact) then
                exit(false);
        end;

        if FindCustomerFromContact(Customer, Contact) then
            exit(true);

        // Promote contact to customer
        if not MarketingSetup.Get then
            exit(false);

        if MarketingSetup."Bus. Rel. Code for Customers" = '' then
            exit(false);

        Contact.SetHideValidationDialog(true);
        Contact.CreateCustomer(MarketingSetup.GetCustomerTemplate(Contact.Type));

        // This line triggers sync back to graph via Background session
        // We need to update IsCustomer flag back to Graph
        // FindCustomerFromGraphContact function is used in the web services
        // We must be able to revert changes back, thus background session is needed (there are several COMMITs)
        Contact.Modify(true);

        exit(FindCustomerFromContact(Customer, Contact));
    end;

    procedure FindContactFromGraphId(GraphContactId: Text[250]; var Contact: Record Contact): Boolean
    var
        DummyGraphIntegrationRecord: Record "Graph Integration Record";
        SearchGraphIntegrationRecord: Record "Graph Integration Record";
        ContactRecordID: RecordID;
        ContactXrmId: Guid;
    begin
        if GraphContactId = '' then
            exit(false);

        if Evaluate(ContactXrmId, GraphContactId) then begin
            SearchGraphIntegrationRecord.SetRange(XRMId, ContactXrmId);
            if not SearchGraphIntegrationRecord.FindFirst then
                exit(false);

            GraphContactId := SearchGraphIntegrationRecord."Graph ID";
        end;

        if not DummyGraphIntegrationRecord.FindRecordIDFromID(GraphContactId, DATABASE::Contact, ContactRecordID) then
            exit(false);

        exit(Contact.Get(ContactRecordID));
    end;

    procedure FindCustomerFromContact(var Customer: Record Customer; var Contact: Record Contact): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // Check primary contact first
        Customer.SetRange("Primary Contact No.", Contact."No.");
        if Customer.FindFirst then
            exit(true);

        Customer.SetRange("Primary Contact No.");
        ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");

        if not ContactBusinessRelation.FindFirst then
            exit(false);

        exit(Customer.Get(ContactBusinessRelation."No."));
    end;

    procedure FindGraphContactIdFromCustomer(var GraphContactId: Text[250]; var Customer: Record Customer; var Contact: Record Contact): Boolean
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
        ContactNo: Code[20];
    begin
        // Use primary contact if specified
        if Customer."Primary Contact No." <> '' then
            ContactNo := Customer."Primary Contact No."
        else begin
            ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
            ContactBusinessRelation.SetRange("No.", Customer."No.");
            if MarketingSetup.Get then
                ContactBusinessRelation.SetRange("Business Relation Code", MarketingSetup."Bus. Rel. Code for Customers");

            if not ContactBusinessRelation.FindFirst then
                exit(false);

            ContactNo := ContactBusinessRelation."Contact No.";
        end;

        if not Contact.Get(ContactNo) then
            exit(false);

        exit(GraphIntegrationRecord.FindIDFromRecordID(Contact.RecordId, GraphContactId));
    end;

    procedure FindGraphContactIdFromCustomerNo(var GraphContactID: Text[250]; CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
        DummyContact: Record Contact;
    begin
        if not Customer.Get(CustomerNo) then
            exit;

        exit(FindGraphContactIdFromCustomer(GraphContactID, Customer, DummyContact));
    end;

    procedure FindGraphContactIdFromVendor(var GraphContactId: Text[250]; var Vendor: Record Vendor; var Contact: Record Contact): Boolean
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
        ContactNo: Code[20];
    begin
        // Use primary contact if specified
        if Vendor."Primary Contact No." <> '' then
            ContactNo := Vendor."Primary Contact No."
        else begin
            ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
            ContactBusinessRelation.SetRange("No.", Vendor."No.");
            if MarketingSetup.Get then
                ContactBusinessRelation.SetRange("Business Relation Code", MarketingSetup."Bus. Rel. Code for Vendors");

            if not ContactBusinessRelation.FindFirst then
                exit(false);

            ContactNo := ContactBusinessRelation."Contact No.";
        end;

        if not Contact.Get(ContactNo) then
            exit(false);

        exit(GraphIntegrationRecord.FindIDFromRecordID(Contact.RecordId, GraphContactId));
    end;

    local procedure GetSourceDestCode(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Text
    begin
        if (SourceRecordRef.Number <> 0) and (DestinationRecordRef.Number <> 0) then
            exit(StrSubstNo('%1-%2', SourceRecordRef.Name, DestinationRecordRef.Name));
        exit('');
    end;

    local procedure GetDestCode(DestinationRecordRef: RecordRef): Text
    begin
        if DestinationRecordRef.Number <> 0 then
            exit(StrSubstNo('%1', DestinationRecordRef.Name));
        exit('');
    end;

    local procedure SetContactFieldsOnGraph(Contact: Record Contact; var GraphContact: Record "Graph Contact")
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        EmailAddressesString: Text;
        BusinessTypeString: Text;
        IsNavCreatedString: Text;
        IsLead: Boolean;
        IsPartner: Boolean;
        IsContact: Boolean;
    begin
        // Avoid syncing contacts without a name to Graph, which may be created because of creating a Customer without a name.
        Contact.TestField(Name);

        if Contact.Type = Contact.Type::Company then
            GraphContact.DisplayName := Contact."Company Name"
        else
            if (Contact."First Name" in ['', ' ']) and (Contact."Middle Name" = '') and (Contact.Surname = '') then
                GraphContact.DisplayName := Contact.Name;

        // E-MailAddresses:
        EmailAddressesString := GraphContact.GetEmailAddressesString;
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 0, Contact."E-Mail");
        EmailAddressesString := GraphCollectionMgtContact.UpdateEmailAddress(EmailAddressesString, 1, Contact."E-Mail 2");
        GraphContact.SetEmailAddressesString(EmailAddressesString);

        // Extensions
        BusinessTypeString := GraphCollectionMgtContact.AddBusinessType(Contact.Type);
        GraphContact.SetBusinessTypeString(BusinessTypeString);

        // If the property exists OR IsCustomer = TRUE then set the property, else leave empty.
        UpdateBusinessCategoriesFromNAV(Contact, GraphContact);

        if GraphContact.Id = '' then begin // new graph contact
            IsNavCreatedString := GraphCollectionMgtContact.AddIsNavCreated(true);
            GraphContact.SetIsNavCreatedString(IsNavCreatedString);
        end;

        IsLead := GraphCollectionMgtContact.GetIsLead(GraphContact.GetIsLeadString);
        IsPartner := GraphCollectionMgtContact.GetIsPartner(GraphContact.GetIsPartnerString);
        IsContact := GraphCollectionMgtContact.GetIsContact(GraphContact.GetIsContactString);

        // at least 1 must be true. If none are true, set IsContact = TRUE
        if not (CheckIsBank(Contact) or CheckIsCustomer(Contact) or CheckIsVendor(Contact) or IsLead or IsPartner or IsContact) then
            GraphContact.SetIsContactString(GraphCollectionMgtContact.AddIsContact(true));

        // Comments
        GraphContact.SetPersonalNotesString(GraphCollectionMgtContact.GetContactComments(Contact));
    end;

    local procedure SetGraphFieldsOnContact(GraphContact: Record "Graph Contact"; var Contact: Record Contact)
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        DummyName: Text;
    begin
        if Contact.Type = Contact.Type::Company then begin
            if (GraphContact.DisplayName = '') and (GraphContact.CompanyName <> '') then
                Contact.Validate(Name, CopyStr(GraphContact.CompanyName, 1, MaxStrLen(Contact.Name)))
            else
                Contact.Validate(Name, CopyStr(GraphContact.DisplayName, 1, MaxStrLen(Contact.Name)));
        end else
            Contact.Validate("First Name");

        // E-MailAddresses:
        GraphCollectionMgtContact.InitializeCollection(GraphContact.GetEmailAddressesString);
        GraphCollectionMgtContact.GetEmailAddress(0, DummyName, Contact."E-Mail");
        GraphCollectionMgtContact.GetEmailAddress(1, DummyName, Contact."E-Mail 2");

        // Comments
        GraphCollectionMgtContact.SetContactComments(Contact, GraphContact.GetPersonalNotesString);
    end;

    local procedure SetContactBusinessRelations(GraphContact: Record "Graph Contact"; var Contact: Record Contact)
    var
        MarketingSetup: Record "Marketing Setup";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        if MarketingSetup.Get then begin
            // IsCustomer
            Contact.SetHideValidationDialog(true);
            if MarketingSetup."Bus. Rel. Code for Customers" <> '' then
                if GraphCollectionMgtContact.GetIsCustomer(GraphContact.GetIsCustomerString) and
                   not CheckIsCustomer(Contact)
                then
                    Contact.CreateCustomer(MarketingSetup.GetCustomerTemplate(Contact.Type));

            if Contact.Type = Contact.Type::Company then begin
                // IsVendor
                if MarketingSetup."Bus. Rel. Code for Vendors" <> '' then
                    if GraphCollectionMgtContact.GetIsVendor(GraphContact.GetIsVendorString) and
                       not CheckIsVendor(Contact)
                    then
                        Contact.CreateVendor;

                // IsBank
                if MarketingSetup."Bus. Rel. Code for Bank Accs." <> '' then
                    if GraphCollectionMgtContact.GetIsBank(GraphContact.GetIsBankString) and
                       not CheckIsBank(Contact)
                    then
                        Contact.CreateBankAccount;
            end;
        end;
    end;

    local procedure UpdateBusinessCategoriesFromNAV(var Contact: Record Contact; var GraphContact: Record "Graph Contact") Modified: Boolean
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IsBankString: Text;
        IsCustomerString: Text;
        IsVendorString: Text;
        GraphIsBank: Boolean;
        GraphIsCustomer: Boolean;
        GraphIsVendor: Boolean;
        NavIsBank: Boolean;
        NavIsCustomer: Boolean;
        NavIsVendor: Boolean;
    begin
        // Checks for inconsistencies in the business category fields and updates the graph contact accordingly

        GraphIsBank := GraphCollectionMgtContact.GetIsBank(GraphContact.GetIsBankString);
        GraphIsCustomer := GraphCollectionMgtContact.GetIsCustomer(GraphContact.GetIsCustomerString);
        GraphIsVendor := GraphCollectionMgtContact.GetIsVendor(GraphContact.GetIsVendorString);

        NavIsBank := CheckIsBank(Contact);
        NavIsCustomer := CheckIsCustomer(Contact);
        NavIsVendor := CheckIsVendor(Contact);

        if GraphIsBank <> NavIsBank then begin
            IsBankString := GraphCollectionMgtContact.AddIsBank(NavIsBank);
            GraphContact.SetIsBankString(IsBankString);
            Modified := true;
        end;

        if GraphIsCustomer <> NavIsCustomer then begin
            IsCustomerString := GraphCollectionMgtContact.AddIsCustomer(NavIsCustomer);
            GraphContact.SetIsCustomerString(IsCustomerString);
            Modified := true;
        end;

        if GraphIsVendor <> NavIsVendor then begin
            IsVendorString := GraphCollectionMgtContact.AddIsVendor(NavIsVendor);
            GraphContact.SetIsVendorString(IsVendorString);
            Modified := true;
        end;
    end;

    local procedure CheckIsCustomer(Contact: Record Contact): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        exit(not ContactBusinessRelation.IsEmpty);
    end;

    local procedure CheckIsVendor(Contact: Record Contact): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        exit(not ContactBusinessRelation.IsEmpty);
    end;

    local procedure CheckIsBank(Contact: Record Contact): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::"Bank Account");
        exit(not ContactBusinessRelation.IsEmpty);
    end;

    local procedure CheckAndFixContactBusinessRelations(var GraphContact: Record "Graph Contact"; Contact: Record Contact; var ModifySourceRecord: Boolean)
    begin
        ModifySourceRecord := UpdateBusinessCategoriesFromNAV(Contact, GraphContact) or ModifySourceRecord;
    end;

    local procedure CheckAndFixDisplayName(var GraphContact: Record "Graph Contact"; var Contact: Record Contact; var ModifySourceRecord: Boolean)
    begin
        if (GraphContact.DisplayName = '') and (Contact.Name <> '') then begin
            GraphContact.DisplayName := Contact.Name;
            ModifySourceRecord := true;
        end;
    end;

    local procedure ModifySourceGraphContact(var GraphContact: Record "Graph Contact"; ModifySourceRecord: Boolean)
    begin
        if ModifySourceRecord then
            GraphContact.Modify(true);
    end;

    local procedure VerifyGraphContactRequiredData(GraphContact: Record "Graph Contact")
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        Value: Text;
        BusinessTypeString: Text;
        IsCustomerString: Text;
        IsVendorString: Text;
        IsBankString: Text;
        IsContactString: Text;
        IsLeadString: Text;
        IsPartnerString: Text;
        HasBusinessCategory: Boolean;
    begin
        BusinessTypeString := GraphContact.GetBusinessTypeString;

        // GraphContact MUST contain BusinessType
        if not GraphCollectionMgtContact.HasBusinessType(BusinessTypeString) then
            Error(BusinessTypeMissingErr);

        // BusinessType MUST contain a valid value
        if not GraphCollectionMgtContact.TryGetBusinessTypeValue(BusinessTypeString, Value) then
            Error(BusinessTypeUnknownValueErr, Value);

        IsCustomerString := GraphContact.GetIsCustomerString;
        IsVendorString := GraphContact.GetIsVendorString;
        IsBankString := GraphContact.GetIsBankString;
        IsContactString := GraphContact.GetIsContactString;
        IsLeadString := GraphContact.GetIsLeadString;
        IsPartnerString := GraphContact.GetIsPartnerString;

        // At least one of the Business Category fields must be present
        if not (GraphCollectionMgtContact.HasIsCustomer(IsCustomerString) or
                GraphCollectionMgtContact.HasIsVendor(IsVendorString) or
                GraphCollectionMgtContact.HasIsBank(IsBankString) or
                GraphCollectionMgtContact.HasIsContact(IsContactString) or
                GraphCollectionMgtContact.HasIsLead(IsLeadString) or
                GraphCollectionMgtContact.HasIsPartner(IsPartnerString))
        then
            Error(BusinessCategoryMissingErr);

        // Business Category fields MUST contain a valid value
        // At least 1 Business Category must be set to TRUE
        if GraphCollectionMgtContact.HasIsCustomer(IsCustomerString) then begin
            if not GraphCollectionMgtContact.TryGetIsCustomerValue(IsCustomerString, Value) then
                Error(BusinessCategoryWrongValueErr, GetLastErrorText, IsCustomerString);
            if GraphCollectionMgtContact.GetIsCustomer(IsCustomerString) then
                HasBusinessCategory := true;
        end;

        if GraphCollectionMgtContact.HasIsVendor(IsVendorString) then begin
            if not GraphCollectionMgtContact.TryGetIsVendorValue(IsVendorString, Value) then
                Error(BusinessCategoryWrongValueErr, GetLastErrorText, IsVendorString);
            if GraphCollectionMgtContact.GetIsVendor(IsVendorString) then
                HasBusinessCategory := true;
        end;

        if GraphCollectionMgtContact.HasIsBank(IsBankString) then begin
            if not GraphCollectionMgtContact.TryGetIsBankValue(IsBankString, Value) then
                Error(BusinessCategoryWrongValueErr, GetLastErrorText, IsBankString);
            if GraphCollectionMgtContact.GetIsBank(IsBankString) then
                HasBusinessCategory := true;
        end;

        if GraphCollectionMgtContact.HasIsContact(IsContactString) then begin
            if not GraphCollectionMgtContact.TryGetIsContactValue(IsContactString, Value) then
                Error(BusinessCategoryWrongValueErr, GetLastErrorText, IsContactString);
            if GraphCollectionMgtContact.GetIsContact(IsContactString) then
                HasBusinessCategory := true;
        end;

        if GraphCollectionMgtContact.HasIsLead(IsLeadString) then begin
            if not GraphCollectionMgtContact.TryGetIsLeadValue(IsLeadString, Value) then
                Error(BusinessCategoryWrongValueErr, GetLastErrorText, IsLeadString);
            if GraphCollectionMgtContact.GetIsLead(IsLeadString) then
                HasBusinessCategory := true;
        end;

        if GraphCollectionMgtContact.HasIsPartner(IsPartnerString) then begin
            if not GraphCollectionMgtContact.TryGetIsPartnerValue(IsPartnerString, Value) then
                Error(BusinessCategoryWrongValueErr, GetLastErrorText, IsPartnerString);
            if GraphCollectionMgtContact.GetIsPartner(IsPartnerString) then
                HasBusinessCategory := true;
        end;

        if not HasBusinessCategory then
            Error(NoBusinessCategoryErr);
    end;

    local procedure BlockCustVendBank(DeletedContact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
    begin
        ContactBusinessRelation.SetRange("Contact No.", DeletedContact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        if ContactBusinessRelation.FindFirst then
            if Customer.Get(ContactBusinessRelation."No.") then
                DeleteOrBlockCustomer(Customer);

        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        if ContactBusinessRelation.FindFirst then
            if Vendor.Get(ContactBusinessRelation."No.") then begin
                Vendor.Blocked := Vendor.Blocked::All;
                Vendor.Modify();
            end;

        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::"Bank Account");
        if ContactBusinessRelation.FindFirst then
            if BankAccount.Get(ContactBusinessRelation."No.") then begin
                BankAccount.Blocked := true;
                BankAccount.Modify();
            end;

        ContactBusinessRelation.Reset();
        ContactBusinessRelation.SetRange("Contact No.", DeletedContact."No.");
        ContactBusinessRelation.DeleteAll();
    end;

    local procedure SetIntegrationIdFieldOnGraph(var Contact: Record Contact; var GraphContact: Record "Graph Contact")
    var
        IntegrationRecord: Record "Integration Record";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        IntegrationIdString: Text;
    begin
        if not IntegrationRecord.FindByRecordId(Contact.RecordId) then
            exit;

        IntegrationIdString := GraphCollectionMgtContact.AddNavIntegrationId(IntegrationRecord."Integration ID");
        GraphContact.SetNavIntegrationIdString(IntegrationIdString);
    end;

    [Scope('OnPrem')]
    procedure SetXRMId(var GraphIntegrationRecord: Record "Graph Integration Record")
    var
        GraphContact: Record "Graph Contact";
        XrmID: Guid;
    begin
        if not (GraphIntegrationRecord."Table ID" = DATABASE::Contact) then
            exit;

        if not GraphContact.Get(GraphIntegrationRecord."Graph ID") then
            exit;

        if GraphContact.GetXrmId(XrmID) then
            GraphIntegrationRecord.XRMId := XrmID;
    end;

    [Scope('OnPrem')]
    procedure UpdateBlankXrmIds()
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphContact: Record "Graph Contact";
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        BlankGuid: Guid;
        XrmId: Guid;
        InboundConnectionName: Text;
    begin
        if not GraphSyncRunner.IsGraphSyncEnabled then
            exit;

        GraphIntegrationRecord.SetRange(XRMId, BlankGuid);
        GraphIntegrationRecord.SetRange("Table ID", DATABASE::Contact);
        if not GraphIntegrationRecord.FindSet(true, false) then
            exit;

        InboundConnectionName := GraphConnectionSetup.GetInboundConnectionName(DATABASE::Contact);

        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundConnectionName) then
            RegisterTableConnection(
              TABLECONNECTIONTYPE::MicrosoftGraph, InboundConnectionName,
              GraphConnectionSetup.GetInboundConnectionString(DATABASE::Contact));

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundConnectionName, true);

        repeat
            if GetGraphContact(GraphContact, GraphIntegrationRecord) then begin
                if not GraphContact.GetXrmId(XrmId) then
                    Error(CannotGetGraphXrmIdErr, GraphIntegrationRecord."Graph ID");
                GraphIntegrationRecord.XRMId := XrmId;
                GraphIntegrationRecord.Modify();
            end;
        until GraphIntegrationRecord.Next = 0;
    end;

    [TryFunction]
    local procedure GetGraphContact(var GraphContact: Record "Graph Contact"; GraphIntegrationRecord: Record "Graph Integration Record")
    begin
        GraphContact.Get(GraphIntegrationRecord."Graph ID");
    end;

    local procedure DeleteOrBlockCustomer(var Customer: Record Customer)
    begin
        // If there are any open or posted documents for the customer, then the customer is marked as blocked
        if Customer.HasAnyOpenOrPostedDocuments then begin
            Customer.Validate(Blocked, Customer.Blocked::All);
            Customer.Modify(true);
            // If there are no documents, then the customer is deleted
        end else
            Customer.Delete(true);
    end;
}

