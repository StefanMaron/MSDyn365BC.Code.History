codeunit 7205 "CDS Int. Table. Subscriber"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        UserCDSSetupTxt: Label 'Dataverse User Setup';
        CannotResolveUserFromConnectionSetupErr: Label 'The integration user that is specified in the Dataverse connection setup does not exist.';
        RecordMustBeCoupledErr: Label '%1 %2 must be coupled to a Dataverse row.', Comment = '%1 = table caption, %2 = primary key value';
        RecordMustBeCoupledExtErr: Label '%1 %2 must be coupled to a %3 row.', Comment = '%1 = BC table caption, %2 = primary key value, %3 - Dataverse table caption';
        RecordNotFoundErr: Label 'Cannot find %1 in table %2.', Comment = '%1 = The lookup value when searching for the source record, %2 = Source table caption';
        ContactMustBeRelatedToCustomerOrVendorErr: Label 'The contact %1 must have a contact company that has a business relation to a customer or vendor.', Comment = '%1 = Contact No.';
        NewCodePatternTxt: Label 'SP NO. %1', Locked = true;
        SalespersonPurchaserCodeFilterLbl: Label 'SP NO. 0*', Locked = true;
        CouplingsNeedToBeResetErr: Label 'Dataverse integration is enabled. The existing couplings must be reset so that other companies can access records that are coupled to the company being deleted.';
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        UpdateContactParentCompanyTxt: Label 'Updating contact parent company.', Locked = true;
        UpdateContactParentCompanyFailedTxt: Label 'Updating contact parent company failed. Parent Customer ID: %1', Locked = true, Comment = '%1 - parent customer id';
        UpdateContactParentCompanySuccessfulTxt: Label 'Contact parent company has successfully been updated.', Locked = true;
        UpdateContactParentCompanyAlreadySetTxt: Label 'Contact parent company has already been set correctly.', Locked = true;
        DataverseAuthUpgradeEnabledSecretNameLbl: Label 'dataverseauthupgenabled', Locked = true;
        DataverseAuthUpgradeJobQueueCategoryLbl: Label 'CDSAUTHUPG', Locked = true;
        SuccessfullyScheduledDataverseAuthupgradeTxt: Label 'Successfully scheduled Dataverse authentication type upgrade.', Locked = true;
        DataverseAuthupgradeJQEDescriptionTxt: Label 'Upgrading authentication type for connecting to Dataverse.', Comment = 'Dataverse is a name of a Microsoft service and must not be translated.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnInitCDSConnection', '', true, true)]
    local procedure HandleOnInitCDSConnection(var ConnectionName: Text; var handled: Boolean)
    begin
        if handled then
            exit;

        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if not CDSIntegrationImpl.RegisterConnection() then
            exit;

        if CDSIntegrationImpl.ActivateConnection() then begin
            handled := true;
            ConnectionName := CDSIntegrationImpl.GetConnectionDefaultName();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnCloseCDSConnection', '', true, true)]
    local procedure HandleOnCloseCDSConnection(ConnectionName: Text; var handled: Boolean)
    begin
        if handled then
            exit;

        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if CDSIntegrationImpl.UnregisterConnection(ConnectionName) then
            handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnTestCDSConnection', '', true, true)]
    local procedure HandleOnTestCDSConnection(var handled: Boolean)
    begin
        if handled then
            exit;

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
        if handled then
            exit;

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
        if handled then
            exit;

        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        CDSConnectionSetup.Get();
        CDSServerAddress := CDSConnectionSetup."Server Address";
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterInsertRecord', '', false, false)]
    local procedure HandleOnAfterInsertRecord(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'CRM Account-Customer',
            'CRM Account-Vendor':
                begin
                    SetCompanyIdOnCRMAccount(SourceRecordRef);
                    UpdateChildContactsParentCompany(SourceRecordRef);
                end;
            'CRM Contact-Contact':
                begin
                    FixPrimaryContactNo(SourceRecordRef, DestinationRecordRef);
                    SetCompanyIdOnCRMContact(SourceRecordRef);
                end;
            'Contact-CRM Contact':
                FixPrimaryContactIdInCDS(SourceRecordRef, DestinationRecordRef);
            'CRM Systemuser-Salesperson/Purchaser':
                AddCoupledUserToDefaultOwningTeam(SourceRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Salesperson/Purchaser", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteCouplingOnAfterDeleteSalesperson(var Rec: Record "Salesperson/Purchaser"; RunTrigger: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if Rec.IsTemporary() then
            exit;

        CRMIntegrationRecord.SetCurrentKey("Integration ID");
        CRMIntegrationRecord.SetRange("Integration ID", Rec.SystemId);
        if CRMIntegrationRecord.FindFirst() then
            CRMIntegrationRecord.Delete();
    end;

    [TryFunction]
    local procedure AddCoupledUserToDefaultOwningTeam(SourceRecordRef: RecordRef)
    var
        CRMSystemuser: Record "CRM Systemuser";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CrmHelper: DotNet CrmHelper;
        AdminUser: Text;
        AdminPassword: Text;
        AccessToken: Text;
        AdminADDomain: Text;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if not CDSConnectionSetup.Get() then
            exit;
        if CDSConnectionSetup."Authentication Type" <> CDSConnectionSetup."Authentication Type"::Office365 then
            exit;

        SourceRecordRef.SetTable(CRMSystemuser);
        if CRMSystemuser.IsEmpty() then
            exit;

        if CDSIntegrationImpl.SignInCDSAdminUser(CDSConnectionSetup, CrmHelper, AdminUser, AdminPassword, AccessToken, AdminADDomain, true) then
            if AccessToken <> '' then
                CDSIntegrationImpl.AddUsersToDefaultOwningTeam(CDSConnectionSetup, CrmHelper, CRMSystemuser);
    end;

    local procedure SetCompanyIdOnCRMContact(var SourceRecordRef: RecordRef)
    var
        CRMContact: Record "CRM Contact";
        RecRef: RecordRef;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        // if the CDS entity already has a correct company id, do nothing
        if CDSIntegrationImpl.CheckCompanyIdNoTelemetry(SourceRecordRef) then
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
        CRMContact.Find();
        SourceRecordRef.GetTable(CRMContact);
    end;

    local procedure SetCompanyIdOnCRMAccount(var SourceRecordRef: RecordRef)
    var
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        // if the CDS entity already has a correct company id, do nothing
        if CDSIntegrationImpl.CheckCompanyIdNoTelemetry(SourceRecordRef) then
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
        CRMAccount.Find();
        SourceRecordRef.GetTable(CRMAccount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Record Synch.", 'OnTransferFieldData', '', false, false)]
    local procedure OnTransferFieldData(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant; var IsValueFound: Boolean; var NeedsConversion: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSConnectionSetup: Record "CDS Connection Setup";
        DestinationRecRef: RecordRef;
        OriginalDestinationFieldValue: Variant;
        IsClearValueOnFailedSync: Boolean;
        OptionValue: Integer;
        EmptyGuid: Guid;
        TableValue: Text;
        SourceValue: Text;
        CoupledSalespersonPurchaserCode: Code[20];
    begin
        if IsValueFound then
            exit;

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

        if SourceFieldRef.Name() = 'OwnerId' then begin
            CDSConnectionSetup.Get();
            case CDSConnectionSetup."Ownership Model" of
                CDSConnectionSetup."Ownership Model"::Team:
                    begin
                        // in case of field mapping to OwnerId, if ownership model is Team, we don't change the value of Salesperson code
                        NewValue := DestinationFieldRef.Value();
                        IsValueFound := true;
                        NeedsConversion := false;
                        exit;
                    end;
                CDSConnectionSetup."Ownership Model"::Person:
                    begin
                        // in case of field mapping to OwnerId, if ownership model is Person, we should find the SalesPerson/Purchaser mapped to the user
                        CoupledSalespersonPurchaserCode := GetCoupledSalespersonPurchaserCode(SourceFieldRef.Record());
                        if CoupledSalespersonPurchaserCode <> '' then
                            NewValue := CoupledSalespersonPurchaserCode
                        else
                            NewValue := DestinationFieldRef.Value();
                        IsValueFound := true;
                        NeedsConversion := false;
                        exit;
                    end;
            end;
        end;

        OriginalDestinationFieldValue := DestinationFieldRef.Value();
        if DestinationFieldRef.Name() = 'Primary Contact No.' then begin
            SourceValue := Format(SourceFieldRef.Value());
            if (SourceValue = '') or (SourceValue = Format(EmptyGuid)) then begin
                // in case of bringing in a blank value for a field that is marked as "Clear Value on Failed Sync", keep the Destination value
                NewValue := OriginalDestinationFieldValue;
                IsValueFound := true;
                NeedsConversion := false;
                exit;
            end;
        end;

        if CRMSynchHelper.ConvertTableToOption(SourceFieldRef, DestinationFieldRef, OptionValue) then begin
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
                    if IsValueFound then begin
                        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::ToIntegrationTable then
                            IsClearValueOnFailedSync := CRMSynchHelper.IsClearValueOnFailedSync(SourceFieldRef, DestinationFieldRef)
                        else
                            if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then
                                IsClearValueOnFailedSync := CRMSynchHelper.IsClearValueOnFailedSync(DestinationFieldRef, SourceFieldRef);

                        if IsClearValueOnFailedSync then begin
                            DestinationRecRef := DestinationFieldRef.Record();
                            DestinationFieldRef.SetRange(OriginalDestinationFieldValue);
                            if DestinationRecRef.IsEmpty() then
                                NewValue := OriginalDestinationFieldValue;
                        end;
                    end;
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
            'Currency-CRM Transactioncurrency':
                SetDefaultSymbolOnCRMTransactioncurrencyIfEmpty(DestinationRecordRef);
        end;

        if DestinationRecordRef.Number() = DATABASE::"Salesperson/Purchaser" then
            UpdateSalesPersOnBeforeInsertRecord(DestinationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeModifyRecord', '', false, false)]
    local procedure HandleOnBeforeModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
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
                SetCompanyId(DestinationRecordRef);
            'Currency-CRM Transactioncurrency':
                SetDefaultSymbolOnCRMTransactioncurrencyIfEmpty(DestinationRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterModifyRecord', '', false, false)]
    local procedure HandleOnAfterModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if DestinationRecordRef.Number() = Database::Vendor then
            CRMSynchHelper.UpdateContactOnModifyVendor(DestinationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Int. Option Synch. Invoke", 'OnAfterModifyOption', '', false, false)]
    local procedure HandleOnAfterModifyOption(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        RecRef: RecordRef;
        OptionLabel: Text;
        DocumentType: Option "Order","Quote","Invoice";
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then begin
            RecRef := SourceRecordRef;
            if CRMOptionMapping.IsCRMRecordRefMapped(SourceRecordRef, CRMOptionMapping) then
                OptionLabel := CRMOptionMapping.GetRecordRefOptionValue(SourceRecordRef);
        end else begin
            RecRef := DestinationRecordRef;
            CRMOptionMapping.SetRange("Record ID", SourceRecordRef.RecordId);
            if CRMOptionMapping.FindFirst() then
                OptionLabel := CRMOptionMapping.GetRecordRefOptionValue(DestinationRecordRef);
        end;

        if OptionLabel <> '' then begin
            UpdateOrInsertDocumentOptionSet(CRMOptionMapping, RecRef, DocumentType::Order, OptionLabel);
            UpdateOrInsertDocumentOptionSet(CRMOptionMapping, RecRef, DocumentType::Quote, OptionLabel);
            UpdateOrInsertDocumentOptionSet(CRMOptionMapping, RecRef, DocumentType::Invoice, OptionLabel);
        end;
    end;

    local procedure UpdateOrInsertDocumentOptionSet(CRMOptionMapping: Record "CRM Option Mapping"; RecRef: RecordRef; DocumentType: Option "Order","Quote","Invoice"; OptionLabel: Text);
    var
        EntityName: Text;
        FieldName: Text;
        OptionSetMetadataDictionary: Dictionary of [Integer, Text];
    begin
        CRMOptionMapping.GetDocumentMetadataInfo(RecRef, DocumentType, EntityName, FieldName);
        if (EntityName <> '') and (FieldName <> '') then begin
            OptionSetMetadataDictionary := CDSIntegrationMgt.GetOptionSetMetadata(EntityName, FieldName);
            if not OptionSetMetadataDictionary.ContainsKey(CRMOptionMapping."Option Value") then
                CDSIntegrationMgt.InsertOptionSetMetadataWithOptionValue(EntityName, FieldName, OptionLabel, CRMOptionMapping."Option Value")
            else
                CDSIntegrationMgt.UpdateOptionSetMetadata(EntityName, FieldName, CRMOptionMapping."Option Value", OptionLabel);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Int. Option Synch. Invoke", 'OnAfterInsertOption', '', false, false)]
    local procedure HandleOnAfterInsertOption(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        RecRef: RecordRef;
        OptionLabel: Text;
        DocumentType: Option "Order","Quote","Invoice";
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then begin
            RecRef := SourceRecordRef;
            if CRMOptionMapping.IsCRMRecordRefMapped(SourceRecordRef, CRMOptionMapping) then
                OptionLabel := CRMOptionMapping.GetRecordRefOptionValue(SourceRecordRef);
        end else begin
            RecRef := DestinationRecordRef;
            CRMOptionMapping.SetRange("Record ID", SourceRecordRef.RecordId);
            if CRMOptionMapping.FindFirst() then
                OptionLabel := CRMOptionMapping.GetRecordRefOptionValue(DestinationRecordRef);
        end;

        if OptionLabel <> '' then begin
            UpdateOrInsertDocumentOptionSet(CRMOptionMapping, RecRef, DocumentType::Order, OptionLabel);
            UpdateOrInsertDocumentOptionSet(CRMOptionMapping, RecRef, DocumentType::Quote, OptionLabel);
            UpdateOrInsertDocumentOptionSet(CRMOptionMapping, RecRef, DocumentType::Invoice, OptionLabel);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Integration Mgt.", 'OnHasCompanyIdField', '', false, false)]
    local procedure HandleOnHasCompanyIdField(TableId: Integer; var HasField: Boolean)
    begin
        case TableId of
            Database::"CRM Account",
            Database::"CRM Contact",
            Database::"CRM Invoice",
            Database::"CRM Quote",
            Database::"CRM Salesorder",
            Database::"CRM Opportunity",
            Database::"CRM Product",
            Database::"CRM Productpricelevel":
                HasField := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Int. Rec. Uncouple Invoke", 'OnBeforeUncoupleRecord', '', false, false)]
    local procedure HandleOnBeforeUncoupleRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    var
        HasField: Boolean;
    begin
        CDSIntegrationMgt.OnHasCompanyIdField(IntegrationRecordRef.Number(), HasField);
        if not HasField then
            exit;

        if IntegrationRecordRef.IsEmpty() then
            exit;

        CDSIntegrationMgt.ResetCompanyId(IntegrationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Int. Rec. Uncouple Invoke", 'OnAfterUncoupleRecord', '', false, false)]
    local procedure HandleOnAfterUncoupleRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    begin
        RemoveChildCouplings(LocalRecordRef, IntegrationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Table Synch.", 'OnAfterInitSynchJob', '', true, true)]
    local procedure ScheduleAuthUpgradeOnAfterInitSynchJob(ConnectionType: TableConnectionType; IntegrationTableID: Integer)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        JobQueueEntry: Record "Job Queue Entry";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        EnvironmentInformation: Codeunit "Environment Information";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        AzureKeyVault: Codeunit "Azure Key Vault";
        DataverseAuthUpgradeEnabledTxt: Text;
    begin
        if ConnectionType <> TableConnectionType::CRM then
            exit;

        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        if not CRMConnectionSetup.WritePermission() then
            exit;

        if not CDSConnectionSetup.WritePermission() then
            exit;

        if CDSConnectionSetup.Get() then
            if CDSConnectionSetup."Is Enabled" then
                if CDSConnectionSetup."Connection String".IndexOf('{CERTIFICATE}') > 0 then
                    exit;

        if CRMConnectionSetup.IsEnabled() then
            if CRMConnectionSetup.GetConnectionString().IndexOf('{CERTIFICATE}') > 0 then
                exit;

        if not CRMIntegrationManagement.UserCanRescheduleJob() then
            exit;

        // this will enable us to roll this out region per region and it will always exit for Embed ISV clusters
        if not AzureKeyVault.GetAzureKeyVaultSecret(DataverseAuthUpgradeEnabledSecretNameLbl, DataverseAuthUpgradeEnabledTxt) then
            exit;
        if Lowercase(DataverseAuthUpgradeEnabledTxt) <> 'yes' then
            exit;

        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDataverseAuthenticationUpgradeTag()) then
            exit;

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"CDS Setup Certificate Auth");
        if not JobQueueEntry.FindFirst() then
            JobQueueEntry.Init();
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime() + 10000;
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"CDS Setup Certificate Auth";
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Rerun Delay (sec.)" := 120;
        JobQueueEntry."Run in User Session" := false;
        JobQueueEntry."Job Queue Category Code" := CopyStr(DataverseAuthUpgradeJobQueueCategoryLbl, 1, MaxStrLen(JobQueueEntry."Job Queue Category Code"));
        JobQueueEntry.Description := DataverseAuthupgradeJQEDescriptionTxt;
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
        Session.LogMessage('0000GJ7', SuccessfullyScheduledDataverseAuthupgradeTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDataverseAuthenticationUpgradeTag());
    end;

    local procedure RemoveChildCouplings(var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ChildContactList: List of [Guid];
    begin
        if GetCoupledChildContacts(LocalRecordRef, IntegrationRecordRef, ChildContactList) then
            CRMIntegrationManagement.RemoveCoupling(Database::Contact, ChildContactList, false);
    end;

    local procedure GetCoupledChildContacts(var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef; var ChildContactList: List of [Guid]): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMID: Guid;
    begin
        if IntegrationRecordRef.Number() <> Database::"CRM Account" then
            exit(false);

        IntegrationRecordRef.SetTable(CRMAccount);
        if IsNullGuid(CRMAccount.AccountId) then
            exit(false);

        case LocalRecordRef.Number() of
            Database::Customer:
                begin
                    LocalRecordRef.SetTable(Customer);
                    if IsNullGuid(Customer.SystemId) then
                        exit(false);
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                    ContBusRel.SetRange("No.", Customer."No.");
                end;
            Database::Vendor:
                begin
                    LocalRecordRef.SetTable(Vendor);
                    if IsNullGuid(Vendor.SystemId) then
                        exit(false);
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
                    ContBusRel.SetRange("No.", Vendor."No.");
                end;
            else
                exit(false);
        end;

        // Get the Company Contact for this Customer or Vendor
        ContBusRel.SetCurrentKey("Link to Table", "No.");
        if ContBusRel.FindFirst() then begin
            // Get all Person Contacts under it
            Contact.SetCurrentKey("Company Name", "Company No.", Type, Name);
            Contact.SetRange("Company No.", ContBusRel."Contact No.");
            Contact.SetRange(Type, Contact.Type::Person);
            if Contact.FindSet() then
                // Collect coupled CRM Contacts under the CRM Account the Customer or Vendor is coupled to
                repeat
                    if CRMIntegrationRecord.FindIDFromRecordID(Contact.RecordId(), CRMID) then begin
                        CRMContact.Get(CRMID);
                        if CRMContact.ParentCustomerId = CRMAccount.AccountId then
                            ChildContactList.Add(Contact.SystemId);
                    end;
                until Contact.Next() = 0;
        end;
        exit(ChildContactList.Count > 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnIsCDSIntegrationEnabled', '', false, false)]
    local procedure HandleOnIsCDSIntegrationEnabled(var isEnabled: Boolean)
    begin
        if isEnabled then
            exit;

        if CDSIntegrationMgt.IsIntegrationEnabled() then
            isEnabled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetCDSBaseCurrencyId', '', false, false)]
    local procedure HandleOnGetCDSBaseCurrencyId(var BaseCurrencyId: Guid; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if handled then
            exit;

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
        if handled then
            exit;

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
        if handled then
            exit;

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
        if handled then
            exit;

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
        if handled then
            exit;

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
        if Enabled then
            exit;

        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        Enabled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Copy Company", 'OnAfterCreatedNewCompanyByCopyCompany', '', false, false)]
    local procedure HandleOnAfterCreatedNewCompanyByCopyCompany(NewCompanyName: Text[30])
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSIntegrationRecord: Record "CRM Integration Record";
        CDSIntegrationSyncJob: Record "Integration Synch. Job";
        CDSIntegrationsSyncJobErrors: Record "Integration Synch. Job Errors";
    begin
        CDSConnectionSetup.ChangeCompany(NewCompanyName);
        CDSConnectionSetup.DeleteAll();
        CRMConnectionSetup.ChangeCompany(NewCompanyName);
        CRMConnectionSetup.DeleteAll();
        CDSIntegrationRecord.ChangeCompany(NewCompanyName);
        CDSIntegrationRecord.DeleteAll();
        CDSIntegrationSyncJob.ChangeCompany(NewCompanyName);
        CDSIntegrationSyncJob.DeleteAll();
        CDSIntegrationsSyncJobErrors.ChangeCompany(NewCompanyName);
        CDSIntegrationsSyncJobErrors.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure DeleteCouplingOnBeforeDeleteCompany(var Rec: Record Company; RunTrigger: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
        TenantLicenseState: Codeunit "Tenant License State";
        EnumTenantLicenseState: Enum "Tenant License State";
    begin
        if Rec.IsTemporary() then
            exit;

        if CDSConnectionSetup.ChangeCompany(Rec.Name) then
            if CDSConnectionSetup.Get() then
                if CDSConnectionSetup."Is Enabled" then
                    if CRMIntegrationRecord.ChangeCompany(Rec.Name) then
                        if not CRMIntegrationRecord.IsEmpty() then begin
                            if not GuiAllowed() then
                                if TenantLicenseState.GetLicenseState() in [
                                    EnumTenantLicenseState::Suspended,
                                    EnumTenantLicenseState::Deleted,
                                    EnumTenantLicenseState::LockedOut]
                                then
                                    exit;
                            Error(CouplingsNeedToBeResetErr);
                        end;
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

        if CRMSynchHelper.IsContactBusinessRelationOptional() then
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
        AccountId: Guid;
        Silent: Boolean;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        Silent := CRMSynchHelper.IsContactBusinessRelationOptional();
        if FindParentCRMAccountForContact(SourceRecordRef, Silent, AccountId) then begin
            // Transfer the parent company id to the ParentCustomerId
            ParentCustomerIdFieldRef := DestinationRecordRef.Field(CRMContact.FieldNo(ParentCustomerId));
            ParentCustomerIdFieldRef.Value := AccountId;
        end;
    end;

    local procedure FindParentCRMAccountForContact(SourceRecordRef: RecordRef; Silent: Boolean; var AccountId: Guid): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
        Customer: Record Customer;
        Vendor: Record Vendor;
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if CRMSynchHelper.FindContactRelatedCustomer(SourceRecordRef, ContactBusinessRelation) then begin
            if Customer.Get(ContactBusinessRelation."No.") then begin
                CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId(), AccountId);
                exit(true);
            end;
            if not Silent then
                Error(RecordNotFoundErr, Customer.TableCaption(), ContactBusinessRelation."No.");
            exit(false);
        end;

        if CRMSynchHelper.FindContactRelatedVendor(SourceRecordRef, ContactBusinessRelation) then begin
            if Vendor.Get(ContactBusinessRelation."No.") then begin
                CRMIntegrationRecord.FindIDFromRecordID(Vendor.RecordId(), AccountId);
                exit(true);
            end;
            if not Silent then
                Error(RecordNotFoundErr, Vendor.TableCaption(), ContactBusinessRelation."No.");
            exit(false);
        end;

        if not Silent then
            Error(ContactMustBeRelatedToCustomerOrVendorErr, SourceRecordRef.Field(Contact.FieldNo("No.")).Value());
        exit(false);
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
            if Customer."Primary Contact No." = '' then
                if IntegrationTableMapping.FindMapping(Database::Customer, Database::"CRM Account") then
                    if IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable] then begin
                        RecRef.GetTable(Customer);
                        RecordModifiedAfterLastSync := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, RecRef);
                        Customer."Primary Contact No." := Contact."No.";
                        if Contact.Type = Contact.Type::Person then
                            Customer.Contact := Contact.Name;
                        Customer.Modify();
                        if not RecordModifiedAfterLastSync then begin
                            CRMIntegrationRecord.SetRange("Integration ID", Customer.SystemId);
                            if CRMIntegrationRecord.FindFirst() then begin
                                CRMIntegrationRecord."Last Synch. Modified On" := Customer.SystemModifiedAt;
                                CRMIntegrationRecord.Modify();
                            end;
                        end;
                        exit(true);
                    end;

        if FindVendorByAccountId(CRMContact.ParentCustomerId, Vendor) then
            if Vendor."Primary Contact No." = '' then
                if IntegrationTableMapping.FindMapping(Database::Vendor, Database::"CRM Account") then
                    if IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable] then begin
                        RecRef.GetTable(Vendor);
                        RecordModifiedAfterLastSync := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, RecRef);
                        Vendor."Primary Contact No." := Contact."No.";
                        if Contact.Type = Contact.Type::Person then
                            Vendor.Contact := Contact.Name;
                        Vendor.Modify();
                        if not RecordModifiedAfterLastSync then begin
                            CRMIntegrationRecord.SetRange("Integration ID", Vendor.SystemId);
                            if CRMIntegrationRecord.FindFirst() then begin
                                CRMIntegrationRecord."Last Synch. Modified On" := Vendor.SystemModifiedAt;
                                CRMIntegrationRecord.Modify();
                            end;
                        end;
                        exit(true);
                    end;

        exit(false);
    end;

    local procedure UpdateChildContactsParentCompany(CRMAccountRecordRef: RecordRef)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        Contact: Record Contact;
        ContactRecordRef: RecordRef;
        CRMContactRecordRef: RecordRef;
        CompanyId: Guid;
    begin
        CRMAccountRecordRef.SetTable(CRMAccount);
        case CRMAccount.CustomerTypeCode of
            CRMAccount.CustomerTypeCode::Customer:
                if not IntegrationTableMapping.FindMapping(Database::Customer, Database::"CRM Account") then
                    exit;
            CRMAccount.CustomerTypeCode::Vendor:
                if not IntegrationTableMapping.FindMapping(Database::Vendor, Database::"CRM Account") then
                    exit;
            else
                exit;
        end;

        if not (IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable]) then
            exit;

        Contact.SetRange("Company No.", '');
        if Contact.IsEmpty() then
            exit; // all contacts have parent company set

        if not CDSIntegrationImpl.TryGetCompanyId(CompanyId) then
            exit;

        // find and process already synced child contacts
        CRMContact.SetRange(ParentCustomerIdType, CRMContact.ParentCustomerIdType::account);
        CRMContact.SetRange(ParentCustomerId, CRMAccount.AccountId);
        CRMContact.SetRange(CompanyId, CompanyId);
        if CRMContact.FindSet() then
            repeat
                if CRMIntegrationRecord.FindByCRMID(CRMContact.ContactId) then begin
                    CRMContactRecordRef.GetTable(CRMContact);
                    ContactRecordRef.Open(Database::Contact);
                    if ContactRecordRef.GetBySystemId(CRMIntegrationRecord."Integration ID") then begin
                        FixPrimaryContactNo(CRMContactRecordRef, ContactRecordRef);
                        UpdateContactParentCompany(CRMAccount.AccountId, ContactRecordRef);
                    end;
                    ContactRecordRef.Close();
                end;
            until CRMContact.Next() = 0;
    end;

    local procedure UpdateContactParentCompany(AccountId: Guid; var ContactRecordRef: RecordRef)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Contact: Record Contact;
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        RecordModifiedAfterLastSync: Boolean;
        OldCompanyNo: Code[20];
        NewCompanyNo: Code[20];
    begin
        if not IntegrationTableMapping.FindMapping(Database::Contact, Database::"CRM Contact") then
            exit;

        if not (IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable]) then
            exit;

        Session.LogMessage('0000EOB', UpdateContactParentCompanyTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);

        RecordModifiedAfterLastSync := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, ContactRecordRef);
        OldCompanyNo := ContactRecordRef.Field(Contact.FieldNo("Company No.")).Value();

        if not CRMSynchHelper.SetContactParentCompany(AccountId, ContactRecordRef) then begin
            Session.LogMessage('0000EOC', StrSubstNo(UpdateContactParentCompanyFailedTxt, AccountId), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        NewCompanyNo := ContactRecordRef.Field(Contact.FieldNo("Company No.")).Value();
        if NewCompanyNo = OldCompanyNo then begin
            Session.LogMessage('0000EOD', UpdateContactParentCompanyAlreadySetTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        ContactRecordRef.Modify();
        if not RecordModifiedAfterLastSync then begin
            ContactRecordRef.SetTable(Contact);
            CRMIntegrationRecord.SetRange("Integration ID", Contact.SystemId);
            if CRMIntegrationRecord.FindFirst() then begin
                CRMIntegrationRecord."Last Synch. Modified On" := Contact.SystemModifiedAt;
                CRMIntegrationRecord.Modify();
            end;
        end;

        Session.LogMessage('0000EOE', UpdateContactParentCompanySuccessfulTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
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

        case CRMAccount.CustomerTypeCode of
            CRMAccount.CustomerTypeCode::Customer:
                if not IntegrationTableMapping.FindMapping(Database::Customer, Database::"CRM Account") then
                    exit(false);
            CRMAccount.CustomerTypeCode::Vendor:
                if not IntegrationTableMapping.FindMapping(Database::Vendor, Database::"CRM Account") then
                    exit(false);
        end;

        if not (IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::ToIntegrationTable]) then
            exit(false);

        CRMRecordRef.GetTable(CRMAccount);
        CRMAccountModifiedAfterLastSync := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, CRMRecordRef);
        CRMAccount.PrimaryContactId := CRMContact.ContactId;
        CRMAccount.Modify();
        if not CRMAccountModifiedAfterLastSync then begin
            CRMIntegrationRecord.SetRange("CRM ID", CRMAccount.AccountId);
            if CRMIntegrationRecord.FindFirst() then begin
                CRMIntegrationRecord."Last Synch. CRM Modified On" := CRMAccount.ModifiedOn;
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

    local procedure SetDefaultSymbolOnCRMTransactioncurrencyIfEmpty(var DestinationRecordRef: RecordRef)
    var
        TempCRMTransactionCurrency: Record "CRM Transactioncurrency" temporary;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CurrencySymbol: Text[10];
    begin
        if not CRMIntegrationManagement.IsCurrencySymbolMappingEnabled() then
            exit;
        CurrencySymbol := DestinationRecordRef.Field(TempCRMTransactionCurrency.FieldNo(CurrencySymbol)).Value();
        if CurrencySymbol = '' then
            DestinationRecordRef.Field(TempCRMTransactionCurrency.FieldNo(CurrencySymbol)).Value := DestinationRecordRef.Field(TempCRMTransactionCurrency.FieldNo(ISOCurrencyCode)).Value();
    end;

    local procedure UpdateSalesPersOnBeforeInsertRecord(var DestinationRecordRef: RecordRef)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        DestinationFieldRef: FieldRef;
        NewCode: Text;
    begin
        // We need to create a new code for this SP.
        // To do so we just do a SP NO. A
        SalespersonPurchaser.SetFilter(Code, SalespersonPurchaserCodeFilterLbl);
        if SalespersonPurchaser.FindLast() then
            NewCode := IncStr(SalespersonPurchaser.Code)
        else
            NewCode := StrSubstNo(NewCodePatternTxt, '00001');

        DestinationFieldRef := DestinationRecordRef.Field(SalespersonPurchaser.FieldNo(Code));
        DestinationFieldRef.Value := NewCode;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Table Synch.", 'OnAfterInitSynchJob', '', true, true)]
    local procedure LogTelemetryOnAfterInitSynchJob(ConnectionType: TableConnectionType; IntegrationTableID: Integer)
    begin
        if ConnectionType <> TableConnectionType::CRM then
            exit;
        if IntegrationTableID in [
                Database::"CRM Account",
                Database::"CRM Contact",
                Database::"CRM Transactioncurrency",
                Database::"CRM Systemuser"] then begin
            Session.LogMessage('0000FMC', 'Synching a base entity.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;
        if IntegrationTableID > MinCustomTableId() then
            Session.LogMessage('0000FMD', 'Synching a custom entity.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    local procedure MinCustomTableId(): Integer
    begin
        exit(50000);
    end;

    [Scope('OnPrem')]
    procedure SetCompanyId(DestinationRecordRef: RecordRef)
    begin
        if CDSIntegrationImpl.CheckCompanyIdNoTelemetry(DestinationRecordRef) then
            exit;

        CDSIntegrationMgt.SetCompanyId(DestinationRecordRef);
    end;

    [Scope('OnPrem')]
    procedure SetOwnerId(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
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

    local procedure GetCoupledSalespersonPurchaserCode(SourceRecordRef: RecordRef): Code[20]
    var
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        CRMSystemuser: Record "CRM Systemuser";
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
        CDSUserId: Guid;
    begin
        case SourceRecordRef.Number() of
            Database::"CRM Account":
                begin
                    SourceRecordRef.SetTable(CRMAccount);
                    if CRMAccount.OwnerIdType <> CRMAccount.OwnerIdType::systemuser then
                        exit('');
                    CDSUserId := CRMAccount.OwnerId;
                end;
            Database::"CRM Contact":
                begin
                    SourceRecordRef.SetTable(CRMContact);
                    if CRMContact.OwnerIdType <> CRMContact.OwnerIdType::systemuser then
                        exit('');
                    CDSUserId := CRMContact.OwnerId;
                end;
            else
                exit('');
        end;

        if not CRMIntegrationRecord.FindByCRMID(CDSUserId) then
            Error(RecordMustBeCoupledExtErr, CRMSystemuser.TableCaption(), CDSUserId, SalesPersonPurchaser.TableCaption());

        if not SalesPersonPurchaser.GetBySystemId(CRMIntegrationRecord."Integration ID") then
            exit('');

        exit(SalesPersonPurchaser.Code);
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