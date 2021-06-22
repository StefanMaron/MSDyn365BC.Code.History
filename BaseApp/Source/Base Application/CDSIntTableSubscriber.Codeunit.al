codeunit 7205 "CDS Int. Table. Subscriber"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        UserCDSSetupTxt: Label 'Common Data Service User Setup';
        CannotResolveUserFromConnectionSetupErr: Label 'The integration user that is specified in the Common Data Service connection setup does not exist.';
        RecordMustBeCoupledErr: Label '%1 %2 must be coupled to a Common Data Service record.', Comment = '%1 = table caption, %2 = primary key value';
        RecordMustBeCoupledExtErr: Label '%1 %2 must be coupled to a %3 record.', Comment = '%1 = BC table caption, %2 = primary key value, %3 - Common Data Service table caption';
        RecordNotFoundErr: Label 'Cannot find %1 in table %2.', Comment = '%1 = The lookup value when searching for the source record, %2 = Source table caption';
        ContactMustBeRelatedToCustomerOrVendorErr: Label 'The contact %1 must have a contact company that has a business relation to a customer or vendor.', Comment = '%1 = Contact No.';
        NewCodePatternTxt: Label 'SP NO. %1', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnInitCDSConnection', '', true, true)]
    local procedure HandleOnInitCDSConnection(var ConnectionName: Text; var handled: Boolean)
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if not CDSIntegrationImpl.RegisterConnection() then
            exit;

        handled := CDSIntegrationImpl.ActivateConnection();

        if handled then
            ConnectionName := CDSIntegrationImpl.GetConnectionDefaultName();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnCloseCDSConnection', '', true, true)]
    local procedure HandleOnCloseCDSConnection(ConnectionName: Text; var handled: Boolean)
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        handled := CDSIntegrationImpl.UnregisterConnection(ConnectionName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnTestCDSConnection', '', true, true)]
    local procedure HandleOnTestCDSConnection(var handled: Boolean)
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        handled := true;
        CDSIntegrationImpl.TestSystemUsersAvailability();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnGetCDSIntegrationUserId', '', true, true)]
    local procedure HandleOnGetCDSIntegrationUserId(var IntegrationUserId: Guid; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSSystemuser: Record "CRM Systemuser";
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        CDSConnectionSetup.Get();
        FilterCDSSystemUser(CDSSystemuser, CDSConnectionSetup);
        if CDSSystemuser.FindFirst() then
            IntegrationUserId := CDSSystemuser.SystemUserId;

        handled := true;
        if IsNullGuid(IntegrationUserId) then
            ShowError(UserCDSSetupTxt, CannotResolveUserFromConnectionSetupErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnGetCDSServerAddress', '', true, true)]
    local procedure HandleOnGetCDSServerAddress(var CDSServerAddress: Text; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        CDSConnectionSetup.Get();
        CDSServerAddress := CDSConnectionSetup."Server Address";
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterInsertRecord', '', false, false)]
    local procedure HandleOnAfterInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'CRM Account-Customer',
            'CRM Account-Vendor':
                SetCompanyIdOnCRMAccount(SourceRecordRef);
            'CRM Contact-Contact':
                begin
                    FixPrimaryContactNo(SourceRecordRef, DestinationRecordRef);
                    SetCompanyIdOnCRMContact(SourceRecordRef);
                end;
            'Contact-CRM Contact':
                FixPrimaryContactIdInCDS(SourceRecordRef, DestinationRecordRef);
        end;
    end;

    local procedure SetCompanyIdOnCRMContact(var SourceRecordRef: RecordRef)
    var
        CRMContact: Record "CRM Contact";
        RecRef: RecordRef;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;
        SourceRecordRef.SetTable(CRMContact);
        // it is required to calculate these fields, otherwise CDS fails to modify the entity
        if (CRMContact.CreatedByName = '') or (CRMContact.ModifiedByName = '') or (CRMContact.TransactionCurrencyIdName = '') then begin
            CRMContact.SetAutoCalcFields(CreatedByName, ModifiedByName, TransactionCurrencyIdName);
            CRMContact.Find();
        end;
        RecRef.GetTable(CRMContact);
        SetCompanyId(RecRef);
        RecRef.Modify();
    end;

    local procedure SetCompanyIdOnCRMAccount(var SourceRecordRef: RecordRef)
    var
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        SourceRecordRef.SetTable(CRMAccount);
        // it is required to calculate these fields, otherwise CDS fails to modify the entity
        if (CRMAccount.CreatedByName = '') or (CRMAccount.ModifiedByName = '') or (CRMAccount.TransactionCurrencyIdName = '') then begin
            CRMAccount.SetAutoCalcFields(CreatedByName, ModifiedByName, TransactionCurrencyIdName);
            CRMAccount.Find();
        end;
        RecRef.GetTable(CRMAccount);
        SetCompanyId(RecRef);
        RecRef.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Record Synch.", 'OnTransferFieldData', '', false, false)]
    [Scope('OnPrem')]
    procedure OnTransferFieldData(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant; var IsValueFound: Boolean; var NeedsConversion: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSConnectionSetup: Record "CDS Connection Setup";
        OptionValue: Integer;
        EmptyGuid: Guid;
        TableValue: Text;
        SourceValue: Text;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if DestinationFieldRef.Name() = 'OwnerId' then begin
            CDSConnectionSetup.Get();
            case CDSConnectionSetup."Ownership Model" of
                CDSConnectionSetup."Ownership Model"::Team:
                    begin
                        // in case of field mapping to OwnerId, if ownership model is Team, we don't change the value if Salesperson changes
                        NewValue := DestinationFieldRef.Value();
                        IsValueFound := true;
                        NeedsConversion := false;
                        exit;
                    end;
                CDSConnectionSetup."Ownership Model"::Person:
                    begin
                        // in case of field mapping to OwnerId, if ownership model is Person, we should find the user mapped to the Salesperson/Purchaser
                        NewValue := GetCoupledCDSUserId(SourceFieldRef.Record());
                        IsValueFound := true;
                        NeedsConversion := false;
                        exit;
                    end;
            end;
        end;

        if DestinationFieldRef.Name() = 'Primary Contact No.' then begin
            SourceValue := Format(SourceFieldRef.Value());
            if (SourceValue = '') or (SourceValue = Format(EmptyGuid)) then begin
                // in case of bringing in a blank value for a field that is marked as "Clear Value on Failed Sync", keep the Destination value
                NewValue := DestinationFieldRef.Value();
                IsValueFound := true;
                NeedsConversion := false;
                exit;
            end;
        end;

        if CRMSynchHelper.ConvertTableToOption(SourceFieldRef, OptionValue) then begin
            NewValue := OptionValue;
            IsValueFound := true;
            NeedsConversion := true;
        end else
            if CRMSynchHelper.ConvertOptionToTable(SourceFieldRef, DestinationFieldRef, TableValue) then begin
                NewValue := TableValue;
                IsValueFound := true;
                NeedsConversion := false;
            end else
                if CRMSynchHelper.AreFieldsRelatedToMappedTables(SourceFieldRef, DestinationFieldRef, IntegrationTableMapping) then begin
                    IsValueFound := FindNewValueForCoupledRecordPK(IntegrationTableMapping, SourceFieldRef, DestinationFieldRef, NewValue);
                    NeedsConversion := false;
                end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeInsertRecord', '', false, false)]
    local procedure HandleOnBeforeInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        SourceDestCode: Text;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        SourceDestCode := GetSourceDestCode(SourceRecordRef, DestinationRecordRef);

        if SourceDestCode = 'Contact-CRM Contact' then
            UpdateCRMContactParentCustomerId(SourceRecordRef, DestinationRecordRef);

        case SourceDestCode of
            'Customer-CRM Account',
            'Contact-CRM Contact',
            'Vendor-CRM Account':
                begin
                    SetCompanyId(DestinationRecordRef);
                    SetOwnerId(SourceRecordRef, DestinationRecordRef);
                end;
        end;

        if DestinationRecordRef.Number() = DATABASE::"Salesperson/Purchaser" then
            UpdateSalesPersOnBeforeInsertRecord(DestinationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeModifyRecord', '', false, false)]
    local procedure HandleOnBeforeModifyRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Customer-CRM Account',
            'Contact-CRM Contact',
            'Vendor-CRM Account':
                begin
                    SetCompanyId(DestinationRecordRef);
                    SetOwnerId(SourceRecordRef, DestinationRecordRef);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterModifyRecord', '', false, false)]
    local procedure HandleOnAfterModifyRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if DestinationRecordRef.Number() = Database::Vendor then
            CRMSynchHelper.UpdateContactOnModifyVendor(DestinationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnIsCDSIntegrationEnabled', '', false, false)]
    local procedure HandleOnIsCDSIntegrationEnabled(var isEnabled: Boolean)
    var
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        isEnabled := CDSIntegrationMgt.IsIntegrationEnabled();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetCDSBaseCurrencyId', '', false, false)]
    local procedure HandleOnGetCDSBaseCurrencyId(var BaseCurrencyId: Guid; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        BaseCurrencyId := CDSConnectionSetup.BaseCurrencyId;
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetCDSBaseCurrencySymbol', '', false, false)]
    local procedure HandleOnGetCDSBaseCurrencySymbol(var BaseCurrencySymbol: Text[5]; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        BaseCurrencySymbol := CDSConnectionSetup.BaseCurrencySymbol;
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetCDSBaseCurrencyPrecision', '', false, false)]
    local procedure HandleOnGetCDSBaseCurrencyPrecision(var BaseCurrencyPrecision: Integer; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        BaseCurrencyPrecision := CDSConnectionSetup.BaseCurrencyPrecision;
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetCDSCurrencyDecimalPrecision', '', false, false)]
    local procedure HandleOnGetCDSCurrencyDecimalPrecision(var CurrencyDecimalPrecision: Integer; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        CurrencyDecimalPrecision := CDSConnectionSetup.CurrencyDecimalPrecision;
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetCDSOwnershipModel', '', false, false)]
    local procedure HandleOnGetCDSOwnershipModel(var OwnershipModel: Option; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        OwnershipModel := CDSConnectionSetup."Ownership Model";
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetVendorSyncEnabled', '', false, false)]
    local procedure HandleOnGetVendorSyncEnabled(var Enabled: Boolean)
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        Enabled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Copy Company", 'OnAfterCreatedNewCompanyByCopyCompany', '', false, false)]
    local procedure HandleOnAfterCreatedNewCompanyByCopyCompany(NewCompanyName: Text[30])
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CDSConnectionSetup.ChangeCompany(NewCompanyName);
        CDSConnectionSetup.DeleteAll();
        CRMConnectionSetup.ChangeCompany(NewCompanyName);
        CRMConnectionSetup.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnQueryPostFilterIgnoreRecord', '', false, false)]
    procedure OnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
        if IgnoreRecord then
            exit;

        if SourceRecordRef.Number() = Database::Contact then
            HandleContactQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
    end;

    local procedure HandleContactQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if IgnoreRecord then
            exit;

        If not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if CRMSynchHelper.FindContactRelatedCustomer(SourceRecordRef, ContactBusinessRelation) then
            exit;

        if CRMSynchHelper.FindContactRelatedVendor(SourceRecordRef, ContactBusinessRelation) then
            exit;

        IgnoreRecord := true;
    end;

    local procedure UpdateCRMContactParentCustomerId(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMContact: Record "CRM Contact";
        ParentCustomerIdFieldRef: FieldRef;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        // Tranfer the parent company id to the ParentCustomerId
        ParentCustomerIdFieldRef := DestinationRecordRef.Field(CRMContact.FieldNo(ParentCustomerId));
        ParentCustomerIdFieldRef.Value := FindParentCRMAccountForContact(SourceRecordRef);
    end;

    local procedure FindParentCRMAccountForContact(SourceRecordRef: RecordRef): Guid
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
        Customer: Record Customer;
        Vendor: Record Vendor;
        CRMIntegrationRecord: Record "CRM Integration Record";
        AccountId: Guid;
    begin
        if CRMSynchHelper.FindContactRelatedCustomer(SourceRecordRef, ContactBusinessRelation) then begin
            if not Customer.Get(ContactBusinessRelation."No.") then
                Error(RecordNotFoundErr, Customer.TableCaption(), ContactBusinessRelation."No.");
            if CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId(), AccountId) then
                exit(AccountId);
        end;

        if CRMSynchHelper.FindContactRelatedVendor(SourceRecordRef, ContactBusinessRelation) then begin
            if not Vendor.Get(ContactBusinessRelation."No.") then
                Error(RecordNotFoundErr, Vendor.TableCaption(), ContactBusinessRelation."No.");
            if CRMIntegrationRecord.FindIDFromRecordID(Vendor.RecordId(), AccountId) then
                exit(AccountId);
        end;

        Error(ContactMustBeRelatedToCustomerOrVendorErr, SourceRecordRef.Field(Contact.FieldNo("No.")).Value());
    end;

    local procedure FixPrimaryContactNo(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        RecRef: RecordRef;
        RecordModifiedAfterLastSync: Boolean;
    begin
        DestinationRecordRef.SetTable(Contact);
        SourceRecordRef.SetTable(CRMContact);

        if CRMContact.ParentCustomerIdType <> CRMContact.ParentCustomerIdType::account then
            exit(false);

        if IsNullGuid(CRMContact.ParentCustomerId) then
            exit(false);

        if FindCustomerByAccountId(CRMContact.ParentCustomerId, Customer) then
            if Customer."Primary Contact No." = '' then begin
                RecRef.GetTable(Customer);
                IntegrationTableMapping.GET('CUSTOMER');
                RecordModifiedAfterLastSync := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, RecRef);
                Customer."Primary Contact No." := Contact."No.";
                Customer.Modify();
                if not RecordModifiedAfterLastSync then begin
                    CRMIntegrationRecord.SetRange("Integration ID", Customer.SystemId);
                    if CRMIntegrationRecord.FindFirst() then begin
                        CRMIntegrationRecord."Last Synch. Modified On" := CurrentDateTime();
                        CRMIntegrationRecord.Modify();
                    end;
                end;
                exit(true);
            end;

        if FindVendorByAccountId(CRMContact.ParentCustomerId, Vendor) then
            if Vendor."Primary Contact No." = '' then begin
                RecRef.GetTable(Vendor);
                IntegrationTableMapping.GET('VENDOR');
                RecordModifiedAfterLastSync := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, RecRef);
                Vendor."Primary Contact No." := Vendor."No.";
                Vendor.Modify();
                if not RecordModifiedAfterLastSync then begin
                    CRMIntegrationRecord.SetRange("Integration ID", Vendor.SystemId);
                    if CRMIntegrationRecord.FindFirst() then begin
                        CRMIntegrationRecord."Last Synch. Modified On" := CurrentDateTime();
                        CRMIntegrationRecord.Modify();
                    end;
                end;
                exit(true);
            end;

        exit(false);
    end;

    local procedure FindNewValueForCoupledRecordPK(IntegrationTableMapping: Record "Integration Table Mapping"; SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant) IsValueFound: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecID: RecordID;
        CRMID: Guid;
    begin
        if CRMSynchHelper.FindNewValueForSpecialMapping(SourceFieldRef, NewValue) then
            exit(true);
        case IntegrationTableMapping.Direction of
            IntegrationTableMapping.Direction::ToIntegrationTable:
                if Format(SourceFieldRef.Value()) = '' then begin
                    NewValue := CRMID; // Blank GUID
                    IsValueFound := true;
                end else begin
                    if CRMSynchHelper.FindRecordIDByPK(SourceFieldRef.Relation(), SourceFieldRef.Value(), RecID) then
                        if CRMIntegrationRecord.FindIDFromRecordID(RecID, NewValue) then
                            exit(true);
                    if CRMSynchHelper.IsClearValueOnFailedSync(SourceFieldRef, DestinationFieldRef) then begin
                        NewValue := CRMID;
                        exit(true);
                    end;
                    Error(RecordMustBeCoupledErr, SourceFieldRef.Name(), SourceFieldRef.Value());
                end;
            IntegrationTableMapping.Direction::FromIntegrationTable:
                begin
                    CRMID := SourceFieldRef.Value();
                    if IsNullGuid(CRMID) then begin
                        NewValue := '';
                        IsValueFound := true;
                    end else begin
                        if CRMIntegrationRecord.FindRecordIDFromID(CRMID, DestinationFieldRef.Relation(), RecID) then
                            if CRMSynchHelper.FindPKByRecordID(RecID, NewValue) then
                                exit(true);
                        if CRMSynchHelper.IsClearValueOnFailedSync(DestinationFieldRef, SourceFieldRef) then begin
                            NewValue := '';
                            exit(true);
                        end;
                        Error(RecordMustBeCoupledErr, SourceFieldRef.Name(), CRMID);
                    end;
                end;
        end;
    end;

    local procedure FixPrimaryContactIdInCDS(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Boolean
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        CRMRecordRef: RecordRef;
        CRMAccountModifiedAfterLastSync: Boolean;
    begin
        DestinationRecordRef.SetTable(CRMContact);
        SourceRecordRef.SetTable(Contact);

        if CRMContact.ParentCustomerIdType <> CRMContact.ParentCustomerIdType::account then
            exit(false);

        if IsNullGuid(CRMContact.ParentCustomerId) then
            exit(false);

        if not CRMAccount.Get(CRMContact.ParentCustomerId) then
            exit(false);

        if not IsNullGuid(CRMAccount.PrimaryContactId) then
            exit(false);

        CRMRecordRef.GetTable(CRMAccount);
        case CRMAccount.CustomerTypeCode of
            CRMAccount.CustomerTypeCode::Customer:
                IntegrationTableMapping.GET('CUSTOMER');
            CRMAccount.CustomerTypeCode::Vendor:
                IntegrationTableMapping.GET('VENDOR');
        end;
        CRMAccountModifiedAfterLastSync := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, CRMRecordRef);
        CRMAccount.PrimaryContactId := CRMContact.ContactId;
        CRMAccount.Modify();
        if not CRMAccountModifiedAfterLastSync then begin
            CRMIntegrationRecord.SetRange("CRM ID", CRMAccount.AccountId);
            if CRMIntegrationRecord.FindFirst() then begin
                CRMIntegrationRecord."Last Synch. CRM Modified On" := CurrentDateTime();
                CRMIntegrationRecord.Modify();
            end;
        end;
        exit(true);
    end;

    local procedure FindCustomerByAccountId(AccountId: Guid; var Customer: Record Customer): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CustomerRecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(AccountId, DATABASE::Customer, CustomerRecordID) then
            exit(Customer.Get(CustomerRecordID));

        exit(false);
    end;

    local procedure FindVendorByAccountId(AccountId: Guid; var Vendor: Record Vendor): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        VendorRecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(AccountId, DATABASE::Vendor, VendorRecordID) then
            exit(Vendor.Get(VendorRecordID));

        exit(false);
    end;

    local procedure UpdateSalesPersOnBeforeInsertRecord(var DestinationRecordRef: RecordRef)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        DestinationFieldRef: FieldRef;
        NewCodeId: Integer;
    begin
        // We need to create a new code for this SP.
        // To do so we just do a SP A
        NewCodeId := 1;
        while SalespersonPurchaser.Get(StrSubstNo(NewCodePatternTxt, NewCodeId)) do
            NewCodeId := NewCodeId + 1;

        DestinationFieldRef := DestinationRecordRef.Field(SalespersonPurchaser.FieldNo(Code));
        DestinationFieldRef.Value := StrSubstNo(NewCodePatternTxt, NewCodeId);
    end;

    [Scope('OnPrem')]
    procedure SetCompanyId(DestinationRecordRef: RecordRef)
    var
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        CDSIntegrationMgt.SetCompanyId(DestinationRecordRef);
    end;

    [Scope('OnPrem')]
    procedure SetOwnerId(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        UserId: Guid;
    begin
        CDSConnectionSetup.Get();
        case CDSConnectionSetup."Ownership Model" of
            CDSConnectionSetup."Ownership Model"::Team:
                CDSIntegrationMgt.SetOwningTeam(DestinationRecordRef);
            CDSConnectionSetup."Ownership Model"::Person:
                begin
                    UserId := GetCoupledCDSUserId(SourceRecordRef);
                    if not IsNullGuid(UserId) then
                        CDSIntegrationMgt.SetOwningUser(DestinationRecordRef, UserId, true)
                    else
                        CDSIntegrationMgt.SetOwningTeam(DestinationRecordRef);
                end;
        end;
    end;

    local procedure GetCoupledCDSUserId(SourceRecordRef: RecordRef): Guid
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
        SalesPersonPurchaserFieldRef: FieldRef;
        SalesPersonPurchaserCode: Code[20];
        CDSUserId: Guid;
    begin
        case SourceRecordRef.Number() of
            Database::Customer:
                SalesPersonPurchaserFieldRef := SourceRecordRef.Field(Customer.FieldNo(Customer."Salesperson Code"));
            Database::Vendor:
                SalesPersonPurchaserFieldRef := SourceRecordRef.Field(Vendor.FieldNo(Vendor."Purchaser Code"));
            Database::Contact:
                SalesPersonPurchaserFieldRef := SourceRecordRef.Field(Contact.FieldNo(Contact."Salesperson Code"));
            else
                exit(CDSUserId);
        end;

        Evaluate(SalesPersonPurchaserCode, Format(SalesPersonPurchaserFieldRef.Value()));
        if not SalesPersonPurchaser.Get(SalesPersonPurchaserCode) then
            exit(CDSUserId);

        if not CRMIntegrationRecord.FindIDFromRecordID(SalesPersonPurchaser.RecordId(), CDSUserId) then
            Error(
              RecordMustBeCoupledExtErr, SalesPersonPurchaser.TableCaption(), SalesPersonPurchaserFieldRef.Value(),
              IntegrationTableMapping.GetExtendedIntegrationTableCaption());

        exit(CDSUserId);
    end;

    local procedure GetSourceDestCode(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Text
    begin
        if (SourceRecordRef.Number() <> 0) and (DestinationRecordRef.Number() <> 0) then
            exit(StrSubstNo('%1-%2', SourceRecordRef.Name(), DestinationRecordRef.Name()));
        exit('');
    end;

    local procedure ShowError(ActivityDescription: Text[128]; ErrorMessage: Text)
    var
        MyNotifications: Record "My Notifications";
        SystemInitialization: Codeunit "System Initialization";
    begin
        if (not SystemInitialization.IsInProgress()) and (GetExecutionContext() = ExecutionContext::Normal) then
            Error(ErrorMessage);

        MyNotifications.InsertDefault(GetCDSNotificationId(), ActivityDescription, ErrorMessage, true);
    end;

    local procedure GetCDSNotificationId(): Guid
    begin
        exit('877d4577-dafa-4b91-9a03-9f7c6402d883');
    end;

    local procedure FilterCDSSystemUser(var CDSSystemuser: Record "CRM Systemuser"; CDSConnectionSetup: Record "CDS Connection Setup")
    begin
        case CDSConnectionSetup."Authentication Type" of
            CDSConnectionSetup."Authentication Type"::Office365, CDSConnectionSetup."Authentication Type"::OAuth:
                CDSSystemuser.SetRange(InternalEMailAddress, CDSConnectionSetup."User Name");
            CDSConnectionSetup."Authentication Type"::AD, CDSConnectionSetup."Authentication Type"::IFD:
                CDSSystemuser.SetRange(DomainName, CDSConnectionSetup."User Name");
        end;
    end;

}