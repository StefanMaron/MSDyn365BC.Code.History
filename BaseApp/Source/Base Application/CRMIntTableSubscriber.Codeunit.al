codeunit 5341 "CRM Int. Table. Subscriber"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        CRMProductName: Codeunit "CRM Product Name";
        CannotFindSyncedProductErr: Label 'Cannot find a synchronized product for %1.', Comment = '%1=product identifier';
        CannotSynchOnlyLinesErr: Label 'Cannot synchronize invoice lines separately.';
        CannotSynchProductErr: Label 'Cannot synchronize the product %1.', Comment = '%1=product identification';
        RecordNotFoundErr: Label 'Cannot find %1 in table %2.', Comment = '%1 = The lookup value when searching for the source record, %2 = Source table caption';
        ContactsMustBeRelatedToCompanyErr: Label 'The contact %1 must have a contact company that has a business relation to a customer.', Comment = '%1 = Contact No.';
        ContactMissingCompanyErr: Label 'The contact cannot be synchronized because the company does not exist.';
        CRMUnitGroupExistsAndIsInactiveErr: Label 'The %1 %2 already exists in %3, but it cannot be synchronized, because it is inactive.', Comment = '%1=table caption: Unit Group,%2=The name of the indicated Unit Group;%3=product name';
        CRMUnitGroupContainsMoreThanOneUoMErr: Label 'The %4 %1 %2 contains more than one %3. This setup cannot be used for synchronization.', Comment = '%1=table caption: Unit Group,%2=The name of the indicated Unit Group,%3=table caption: Unit., %4 = Dataverse service name';
        CustomerHasChangedErr: Label 'Cannot create the invoice in %2. The customer from the original %2 sales order %1 was changed or is no longer coupled.', Comment = '%1=CRM sales order number, %2 = Dataverse service name';
        NoCoupledSalesInvoiceHeaderErr: Label 'Cannot find the coupled %1 invoice header.', Comment = '%1 = Dataverse service name';
        RecordMustBeCoupledErr: Label '%1 %2 must be coupled to a record in %3.', Comment = '%1 =field caption, %2 = field value, %3 - product name ';
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CurrencyExchangeRateMissingErr: Label 'Cannot create or update the currency %1 in %2, because there is no exchange rate defined for it.', Comment = '%1 - currency code, %2 - Dataverse service name';
        NewCodePatternTxt: Label 'SP NO. %1', Locked = true;
        SourceDestCodePatternTxt: Label '%1-%2', Locked = true;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        UpdateContactParentCompanyTxt: Label 'Updating contact parent company.', Locked = true;
        UpdateContactParentCompanyFailedTxt: Label 'Updating contact parent company failed. Parent Customer ID: %1', Locked = true, Comment = '%1 - parent customer id';
        UpdateContactParentCompanySuccessfulTxt: Label 'Updated contact parent company successfully.', Locked = true;

    procedure ClearCache()
    begin
        CRMSynchHelper.ClearCache();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Start Codeunit", 'OnAfterRun', '', false, false)]
    local procedure OnAfterJobQueueEntryRun(var JobQueueEntry: Record "Job Queue Entry")
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if IsJobQueueEntryCRMIntegrationJob(JobQueueEntry, IntegrationTableMapping) then
            if IntegrationSynchJob.HaveJobsBeenIdle(JobQueueEntry.GetLastLogEntryNo()) then begin
                if JobQueueEntry."Recurring Job" then
                    JobQueueEntry.Status := JobQueueEntry.Status::"On Hold with Inactivity Timeout"
            end else
                JobQueueEntry.Status := JobQueueEntry.Status::Ready;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Management", 'OnDeleteIntegrationRecord', '', false, false)]
    local procedure OnDeleteIntegrationRecord(var RecRef: RecordRef)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if CRMIntegrationRecord.FindByRecordID(RecRef.RecordId()) then
            if RecRef.Number() = DATABASE::"Sales Header" then
                CRMIntegrationRecord.Delete()
            else begin
                CRMIntegrationRecord.Skipped := true;
                CRMIntegrationRecord.Modify();
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnFindingIfJobNeedsToBeRun', '', false, false)]
    local procedure OnFindingIfJobNeedsToBeRun(var Sender: Record "Job Queue Entry"; var Result: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecRef: RecordRef;
        ConnectionID: Guid;
    begin
        if Result then
            exit;

        if IsJobQueueEntryCRMIntegrationJob(Sender, IntegrationTableMapping) and
           CRMIntegrationManagement.IsCRMTable(IntegrationTableMapping."Integration Table ID")
        then begin
            CRMConnectionSetup.Get();
            if CRMConnectionSetup."Is Enabled" or CDSIntegrationImpl.IsIntegrationEnabled() then begin
                ConnectionID := Format(CreateGuid());
                if CDSIntegrationImpl.IsIntegrationEnabled() then begin
                    CDSIntegrationImpl.RegisterConnection(ConnectionID);
                    SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionID, false)
                end else
                    CRMConnectionSetup.RegisterConnectionWithName(ConnectionID);
                RecRef.Open(IntegrationTableMapping."Integration Table ID");
                IntegrationTableMapping.SetIntRecordRefFilter(RecRef);
                if not RecRef.IsEmpty() then
                    Result := true;
                RecRef.Close();
                if CDSIntegrationImpl.IsIntegrationEnabled() then
                    CDSIntegrationImpl.UnregisterConnection(ConnectionID)
                else
                    CRMConnectionSetup.UnregisterConnectionWithName(ConnectionID);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job Queue Log Entries", 'OnShowDetails', '', false, false)]
    local procedure OnShowDetailedLog(JobQueueLogEntry: Record "Job Queue Log Entry")
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        if (JobQueueLogEntry."Object Type to Run" = JobQueueLogEntry."Object Type to Run"::Codeunit) and
           (JobQueueLogEntry."Object ID to Run" in [CODEUNIT::"Integration Synch. Job Runner", CODEUNIT::"CRM Statistics Job", CODEUNIT::"Int. Uncouple Job Runner"])
        then begin
            IntegrationSynchJob.SetRange("Job Queue Log Entry No.", JobQueueLogEntry."Entry No.");
            PAGE.RunModal(PAGE::"Integration Synch. Job List", IntegrationSynchJob);
        end;
    end;

    local procedure IsJobQueueEntryCRMIntegrationJob(JobQueueEntry: Record "Job Queue Entry"; var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        RecRef: RecordRef;
    begin
        Clear(IntegrationTableMapping);
        if JobQueueEntry."Object Type to Run" <> JobQueueEntry."Object Type to Run"::Codeunit then
            exit(false);
        case JobQueueEntry."Object ID to Run" of
            CODEUNIT::"CRM Statistics Job":
                exit(true);
            CODEUNIT::"Integration Synch. Job Runner":
                begin
                    if not RecRef.Get(JobQueueEntry."Record ID to Process") then
                        exit(false);
                    if RecRef.Number() = DATABASE::"Integration Table Mapping" then begin
                        RecRef.SetTable(IntegrationTableMapping);
                        exit(IntegrationTableMapping."Synch. Codeunit ID" = CODEUNIT::"CRM Integration Table Synch.");
                    end;
                end;
            CODEUNIT::"Int. Uncouple Job Runner":
                begin
                    if not RecRef.Get(JobQueueEntry."Record ID to Process") then
                        exit(false);
                    if RecRef.Number() = DATABASE::"Integration Table Mapping" then begin
                        RecRef.SetTable(IntegrationTableMapping);
                        exit(IntegrationTableMapping."Uncouple Codeunit ID" = Codeunit::"CDS Int. Table Uncouple");
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnCleanupAfterJobExecution(var Rec: Record "Job Queue Entry"; RunTrigger: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecordID: RecordID;
        RecRef: RecordRef;
    begin
        if Rec.IsTemporary() then
            exit;

        RecordID := Rec."Record ID to Process";
        if RecordID.TableNo() = DATABASE::"Integration Table Mapping" then begin
            RecRef := RecordID.GetRecord();
            RecRef.SetTable(IntegrationTableMapping);
            if IntegrationTableMapping.Get(IntegrationTableMapping.Name) then
                if IntegrationTableMapping."Delete After Synchronization" then
                    IntegrationTableMapping.Delete(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeTransferRecordFields', '', false, false)]
    procedure OnBeforeTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Sales Invoice Header-CRM Invoice':
                CheckItemOrResourceIsNotBlocked(SourceRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Record Synch.", 'OnTransferFieldData', '', false, false)]
    procedure OnTransferFieldData(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant; var IsValueFound: Boolean; var NeedsConversion: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSConnectionSetup: Record "CDS Connection Setup";
        OptionValue: Integer;
        TableValue: Text;
    begin
        if IsValueFound then
            exit;

        if CRMIntegrationManagement.IsCDSIntegrationEnabled() then
            if (SourceFieldRef.Record().Number() in [Database::Customer, Database::Vendor, Database::Currency, Database::Contact, Database::"Salesperson/Purchaser"]) or
                (DestinationFieldRef.Record().Number() in [Database::Customer, Database::Vendor, Database::Currency, Database::Contact, Database::"Salesperson/Purchaser"]) then
                exit;

        if CRMSynchHelper.ConvertTableToOption(SourceFieldRef, OptionValue) then begin
            NewValue := OptionValue;
            IsValueFound := true;
            NeedsConversion := true;
            exit;
        end;

        if CRMSynchHelper.ConvertOptionToTable(SourceFieldRef, DestinationFieldRef, TableValue) then begin
            NewValue := TableValue;
            IsValueFound := true;
            NeedsConversion := false;
            exit;
        end;

        if DestinationFieldRef.Name() = 'OwnerId' then
            if CRMIntegrationManagement.IsCDSIntegrationEnabled() then begin
                CDSConnectionSetup.Get();
                if CDSConnectionSetup."Ownership Model" = CDSConnectionSetup."Ownership Model"::Team then begin
                    // in case of field mapping to OwnerId, if ownership model is Team, we don't change the value if Salesperson changes
                    NewValue := DestinationFieldRef.Value();
                    IsValueFound := true;
                    NeedsConversion := false;
                    exit;
                end;
            end;

        if CRMSynchHelper.AreFieldsRelatedToMappedTables(SourceFieldRef, DestinationFieldRef, IntegrationTableMapping) then
            if FindNewValueForCoupledRecordPK(IntegrationTableMapping, SourceFieldRef, DestinationFieldRef, NewValue) then begin
                IsValueFound := true;
                NeedsConversion := false;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterTransferRecordFields', '', false, false)]
    procedure OnAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var AdditionalFieldsWereModified: Boolean; DestinationIsInserted: Boolean)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'CRM Account-Customer':
                if UpdateCustomerBlocked(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Sales Price-CRM Productpricelevel':
                if UpdateCRMProductPricelevelAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Price List Line-CRM Productpricelevel':
                if UpdateCRMProductPricelevelAfterTransferRecordFieldsPriceListLine(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Currency-CRM Transactioncurrency':
                if UpdateCRMTransactionCurrencyAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Item-CRM Product',
            'Resource-CRM Product':
                if UpdateCRMProductAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef, DestinationIsInserted) then
                    AdditionalFieldsWereModified := true;
            'CRM Product-Item':
                if UpdateItemAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'CRM Product-Resource':
                if UpdateResourceAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Unit of Measure-CRM Uomschedule':
                if UpdateCRMUoMScheduleAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeInsertRecord', '', false, false)]
    procedure OnBeforeInsertRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'CRM Contact-Contact':
                UpdateContactParentCompany(SourceRecordRef, DestinationRecordRef);
            'Contact-CRM Contact':
                UpdateCRMContactParentCustomerId(SourceRecordRef, DestinationRecordRef);
            'Currency-CRM Transactioncurrency':
                UpdateCRMTransactionCurrencyBeforeInsertRecord(DestinationRecordRef);
            'Customer Price Group-CRM Pricelevel':
                UpdateCRMPricelevelBeforeInsertRecord(SourceRecordRef, DestinationRecordRef);
            'Price List Header-CRM Pricelevel':
                UpdateCRMPricelevelBeforeInsertPriceListHeader(SourceRecordRef, DestinationRecordRef);
            'Item-CRM Product',
            'Resource-CRM Product':
                UpdateCRMProductBeforeInsertRecord(DestinationRecordRef);
            'Sales Invoice Header-CRM Invoice':
                begin
                    CheckSalesInvoiceLineItemsAreCoupled(SourceRecordRef);
                    UpdateCRMInvoiceBeforeInsertRecord(SourceRecordRef, DestinationRecordRef);
                end;
            'Opportunity-CRM Opportunity':
                UpdateCRMOpportunityBeforeInsertRecord(DestinationRecordRef);
            'Sales Invoice Line-CRM Invoicedetail':
                UpdateCRMInvoiceDetailsBeforeInsertRecord(SourceRecordRef, DestinationRecordRef);
        end;

        case DestinationRecordRef.Number() of
            Database::"Salesperson/Purchaser":
                UpdateSalesPersOnBeforeInsertRecord(DestinationRecordRef);
            Database::"CRM Account":
                UpdateAccountEnumsFromOptions(DestinationRecordRef);
            Database::"CRM Invoice":
                UpdateInvoiceEnumsFromOptions(DestinationRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterInsertRecord', '', false, false)]
    procedure OnAfterInsertRecord(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        SourceDestCode: Text;
    begin
        SourceDestCode := GetSourceDestCode(SourceRecordRef, DestinationRecordRef);
        case SourceDestCode of
            'Customer Price Group-CRM Pricelevel':
                ResetCRMProductpricelevelFromCustomerPriceGroup(SourceRecordRef);
            'Price List Header-CRM Pricelevel':
                ResetCRMProductpricelevelFromPriceListHeader(SourceRecordRef);
            'Item-CRM Product',
            'Resource-CRM Product':
                UpdateCRMProductAfterInsertRecord(DestinationRecordRef);
            'Sales Invoice Header-CRM Invoice':
                UpdateCRMInvoiceAfterInsertRecord(SourceRecordRef, DestinationRecordRef);
            'Sales Invoice Line-CRM Invoicedetail':
                UpdateCRMInvoiceDetailsAfterInsertRecord(SourceRecordRef, DestinationRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeModifyRecord', '', false, false)]
    procedure OnBeforeModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'CRM Contact-Contact':
                UpdateContactParentCompany(SourceRecordRef, DestinationRecordRef);
            'Contact-CRM Contact':
                UpdateCRMContactParentCustomerId(SourceRecordRef, DestinationRecordRef);
            'Customer Price Group-CRM Pricelevel':
                UpdateCRMPricelevelBeforeModifyRecord(SourceRecordRef, DestinationRecordRef);
            'Price List Header-CRM Pricelevel':
                UpdateCRMPricelevelBeforeModifyPriceListHeader(SourceRecordRef, DestinationRecordRef);
            'Item-CRM Product',
            'Resource-CRM Product',
            'Opportunity-CRM Opportunity',
            'Sales Header-CRM Salesorder',
            'Sales Invoice Header-CRM Invoice':
                SetCompanyId(DestinationRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterModifyRecord', '', false, false)]
    procedure OnAfterModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Customer Price Group-CRM Pricelevel':
                ResetCRMProductpricelevelFromCustomerPriceGroup(SourceRecordRef);
            'Price List Header-CRM Pricelevel':
                ResetCRMProductpricelevelFromPriceListHeader(SourceRecordRef);
        end;

        if DestinationRecordRef.Number() = DATABASE::Customer then
            CRMSynchHelper.UpdateContactOnModifyCustomer(DestinationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterUnchangedRecordHandled', '', false, false)]
    procedure OnAfterUnchangedRecordHandled(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Customer Price Group-CRM Pricelevel':
                ResetCRMProductpricelevelFromCustomerPriceGroup(SourceRecordRef);
            'Price List Header-CRM Pricelevel':
                ResetCRMProductpricelevelFromPriceListHeader(SourceRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnQueryPostFilterIgnoreRecord', '', false, false)]
    procedure OnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
        if IgnoreRecord then
            exit;

        case SourceRecordRef.Number() of
            DATABASE::Contact:
                HandleContactQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
            DATABASE::Opportunity:
                HandleOpportunityQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
            DATABASE::"Sales Invoice Line":
                Error(CannotSynchOnlyLinesErr);
            DATABASE::Item:
                HandleItemQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
            DATABASE::Resource:
                HandleResourceQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnFindUncoupledDestinationRecord', '', false, false)]
    procedure OnFindUncoupledDestinationRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var DestinationIsDeleted: Boolean; var DestinationFound: Boolean)
    begin
        if DestinationFound then
            exit;

        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Unit of Measure-CRM Uomschedule':
                if CRMUoMScheduleFindUncoupledDestinationRecord(SourceRecordRef, DestinationRecordRef) then
                    DestinationFound := true;
            'Currency-CRM Transactioncurrency':
                if CRMTransactionCurrencyFindUncoupledDestinationRecord(SourceRecordRef, DestinationRecordRef) then
                    DestinationFound := true;
        end;

        case SourceRecordRef.Number() of
            DATABASE::"Sales Price":
                if CRMPriceListLineFindUncoupledDestinationRecord(SourceRecordRef, DestinationRecordRef) then
                    DestinationFound := true;
            DATABASE::"Price List Line":
                if CRMExtPriceListLineFindUncoupledDestinationRecord(SourceRecordRef, DestinationRecordRef) then
                    DestinationFound := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Integration Table Mapping", 'OnAfterDeleteEvent', '', false, false)]
    procedure OnAfterDeleteIntegrationTableMapping(var Rec: Record "Integration Table Mapping"; RunTrigger: Boolean)
    var
        JobQueueEntry: record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetFilter("Object ID to Run", '%1|%2', Codeunit::"Integration Synch. Job Runner", Codeunit::"Int. Uncouple Job Runner");
        JobQueueEntry.SetRange("Record ID to Process", Rec.RecordId());
        JobQueueEntry.DeleteTasks();
    end;

    local procedure UpdateOwnerIdAndCompanyId(var DestinationRecordRef: RecordRef)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if CDSIntegrationImpl.IsIntegrationEnabled() then begin
            if not CDSIntegrationImpl.CheckCompanyIdNoTelemetry(DestinationRecordRef) then
                CDSIntegrationImpl.SetCompanyId(DestinationRecordRef);
            CDSConnectionSetup.Get();
            if CDSConnectionSetup."Ownership Model" = CDSConnectionSetup."Ownership Model"::Team then
                CDSIntegrationImpl.SetOwningTeam(DestinationRecordRef);
        end;
    end;

    local procedure SetCompanyId(var DestinationRecordRef: RecordRef)
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if CDSIntegrationImpl.CheckCompanyIdNoTelemetry(DestinationRecordRef) then
            exit;

        CDSIntegrationImpl.SetCompanyId(DestinationRecordRef);
    end;

    local procedure GetSourceDestCode(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Text
    begin
        if (SourceRecordRef.Number() <> 0) and (DestinationRecordRef.Number() <> 0) then
            exit(StrSubstNo(SourceDestCodePatternTxt, SourceRecordRef.Name(), DestinationRecordRef.Name()));
        exit('');
    end;

    local procedure UpdateCustomerBlocked(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef): Boolean
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        DestinationFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
        OptionValue: Integer;
    begin
        // Blocked - we're only handling from Active > Inactive meaning Blocked::"" > Blocked::"All"
        SourceFieldRef := SourceRecordRef.Field(CRMAccount.FieldNo(StatusCode));
        OptionValue := SourceFieldRef.Value();
        if OptionValue = CRMAccount.StatusCode::Inactive then begin
            DestinationFieldRef := DestinationRecordRef.Field(Customer.FieldNo(Blocked));
            OptionValue := DestinationFieldRef.Value();
            if OptionValue = Customer.Blocked::" ".AsInteger() then begin
                DestinationFieldRef.Value := Customer.Blocked::All;
                exit(true);
            end;
        end;
    end;

    local procedure UpdateContactParentCompany(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMContact: Record "CRM Contact";
        SourceFieldRef: FieldRef;
        ParentCustomerId: Guid;
    begin
        Session.LogMessage('0000ECA', UpdateContactParentCompanyTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        // When updating we also want to set the company contact id
        // We only allow updating contacts if the company has already been created
        SourceFieldRef := SourceRecordRef.Field(CRMContact.FieldNo(ParentCustomerId));
        ParentCustomerId := SourceFieldRef.Value();
        if not CRMSynchHelper.SetContactParentCompany(ParentCustomerId, DestinationRecordRef) then begin
            Session.LogMessage('0000ECB', StrSubstNo(UpdateContactParentCompanyFailedTxt, ParentCustomerId), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            Error(ContactMissingCompanyErr);
        end;
        Session.LogMessage('0000ECH', UpdateContactParentCompanySuccessfulTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    local procedure HandleContactQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if IgnoreRecord then
            exit;

        if CRMSynchHelper.FindContactRelatedCustomer(SourceRecordRef, ContactBusinessRelation) then
            exit;

        if CRMIntegrationManagement.IsCDSIntegrationEnabled() then
            if CRMSynchHelper.FindContactRelatedVendor(SourceRecordRef, ContactBusinessRelation) then
                exit;

        IgnoreRecord := true;
    end;

    local procedure HandleItemQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
    begin
        if IgnoreRecord then
            exit;

        if not SalesReceivablesSetup.Get() then
            exit;

        SourceRecordRef.SetTable(Item);
        if SalesReceivablesSetup."Write-in Product No." <> Item."No." then
            exit;

        IgnoreRecord := true;
    end;

    local procedure HandleResourceQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Resource: Record Resource;
    begin
        if IgnoreRecord then
            exit;

        if not SalesReceivablesSetup.Get() then
            exit;

        SourceRecordRef.SetTable(Resource);
        if SalesReceivablesSetup."Write-in Product No." <> Resource."No." then
            exit;

        IgnoreRecord := true;
    end;

    local procedure HandleOpportunityQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        Opportunity: Record Opportunity;
        Contact: Record Contact;
        CDSConnectionSetup: Record "CDS Connection Setup";
        ContactRecordRef: RecordRef;
    begin
        if IgnoreRecord then
            exit;

        if not CRMIntegrationManagement.IsCDSIntegrationEnabled() then
            exit;

        CDSConnectionSetup.Get();
        if CDSConnectionSetup."Ownership Model" = CDSConnectionSetup."Ownership Model"::Person then
            exit;

        SourceRecordRef.SetTable(Opportunity);
        if not Contact.Get(Opportunity."Contact No.") then
            exit;

        ContactRecordRef.GetTable(Contact);
        if (Contact.Type <> Contact.Type::Person) or (Contact."Company No." = '') then
            IgnoreRecord := true;

        HandleContactQueryPostFilterIgnoreRecord(ContactRecordRef, IgnoreRecord);
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

    local procedure UpdateCRMContactParentCustomerId(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMContact: Record "CRM Contact";
        ParentCustomerIdFieldRef: FieldRef;
    begin
        if CRMIntegrationManagement.IsCDSIntegrationEnabled() then
            exit;

        // Tranfer the parent company id to the ParentCustomerId
        ParentCustomerIdFieldRef := DestinationRecordRef.Field(CRMContact.FieldNo(ParentCustomerId));
        ParentCustomerIdFieldRef.Value := FindParentCRMAccountForContact(SourceRecordRef);
    end;

    local procedure CheckSalesInvoiceLineItemsAreCoupled(SourceRecordRef: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SourceRecordRef.SetTable(SalesInvoiceHeader);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                // this call will throw an error if the Sales Invoice Line has an uncoupled product, thus rolling back the creation of the Dynamics 365 Sales invoice
                if SalesInvoiceLine."No." <> '' then
                    FindCRMProductId(SalesInvoiceLine);
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure UpdateCRMInvoiceAfterInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMInvoice: Record "CRM Invoice";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        DocumentTotals: Codeunit "Document Totals";
        SourceLinesRecordRef: RecordRef;
        TaxAmount: Decimal;
    begin
        SourceRecordRef.SetTable(SalesInvoiceHeader);
        DestinationRecordRef.SetTable(CRMInvoice);

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if not SalesInvoiceLine.IsEmpty() then begin
            SourceLinesRecordRef.GetTable(SalesInvoiceLine);
            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(SourceLinesRecordRef, false, false);

            SalesInvoiceLine.CalcSums("Line Discount Amount");
            CRMInvoice.TotalLineItemDiscountAmount := SalesInvoiceLine."Line Discount Amount";
        end;

        CRMConnectionSetup.Get();

        if CRMConnectionSetup."Is S.Order Integration Enabled" then begin
            DocumentTotals.CalculatePostedSalesInvoiceTotals(SalesInvoiceHeader, TaxAmount, SalesInvoiceLine);
            CRMInvoice.TotalAmount := SalesInvoiceHeader."Amount Including VAT";
            CRMInvoice.TotalTax := TaxAmount;
            CRMInvoice.TotalDiscountAmount := SalesInvoiceHeader."Invoice Discount Amount";
        end else begin
            CRMInvoice.FreightAmount := 0;
            CRMInvoice.DiscountPercentage := 0;
            CRMInvoice.TotalTax := CRMInvoice.TotalAmount - CRMInvoice.TotalAmountLessFreight;
            CRMInvoice.TotalDiscountAmount := CRMInvoice.DiscountAmount + CRMInvoice.TotalLineItemDiscountAmount;
        end;
        CRMInvoice.Modify();
        CRMSynchHelper.UpdateCRMInvoiceStatus(CRMInvoice, SalesInvoiceHeader);

        CRMSynchHelper.SetSalesInvoiceHeaderCoupledToCRM(SalesInvoiceHeader);
    end;

    local procedure UpdateCRMInvoiceBeforeInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMInvoice: Record "CRM Invoice";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMSalesorder: Record "CRM Salesorder";
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ShipmentMethod: Record "Shipment Method";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
        OutStream: OutStream;
        AccountId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCRMInvoiceBeforeInsertRecord(SourceRecordRef, DestinationRecordRef, IsHandled);
        if IsHandled then
            exit;

        SourceRecordRef.SetTable(SalesInvoiceHeader);
        DestinationRecordRef.SetTable(CRMInvoice);

        // Shipment Method Code -> go to table Shipment Method, and from there extract the description and add it to
        if ShipmentMethod.Get(SalesInvoiceHeader."Shipment Method Code") then begin
            Clear(CRMInvoice.Description);
            CRMInvoice.Description.CreateOutStream(OutStream, TEXTENCODING::UTF16);
            OutStream.WriteText(ShipmentMethod.Description);
        end;

        if CRMSalesOrderToSalesOrder.GetCRMSalesOrder(CRMSalesorder, SalesInvoiceHeader."Your Reference") then begin
            CRMInvoice.OpportunityId := CRMSalesorder.OpportunityId;
            CRMInvoice.SalesOrderId := CRMSalesorder.SalesOrderId;
            CRMInvoice.PriceLevelId := CRMSalesorder.PriceLevelId;
            CRMInvoice.Name := CRMSalesorder.Name;

            if not CRMSalesOrderToSalesOrder.GetCoupledCustomer(CRMSalesorder, Customer) then begin
                if not CRMSalesOrderToSalesOrder.GetCRMAccountOfCRMSalesOrder(CRMSalesorder, CRMAccount) then
                    Error(CustomerHasChangedErr, CRMSalesorder.OrderNumber, CRMProductName.CDSServiceName());
                if not CRMSynchHelper.SynchRecordIfMappingExists(Database::Customer, Database::"CRM Account", CRMAccount.AccountId) then
                    Error(CustomerHasChangedErr, CRMSalesorder.OrderNumber, CRMProductName.CDSServiceName());
            end;
            if Customer."No." <> SalesInvoiceHeader."Sell-to Customer No." then
                Error(CustomerHasChangedErr, CRMSalesorder.OrderNumber, CRMProductName.CDSServiceName());
            CRMInvoice.CustomerId := CRMSalesorder.CustomerId;
            CRMInvoice.CustomerIdType := CRMSalesorder.CustomerIdType;
        end else begin
            CRMInvoice.Name := SalesInvoiceHeader."No.";
            Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

            if not CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId(), AccountId) then
                if not CRMSynchHelper.SynchRecordIfMappingExists(Database::Customer, Database::"CRM Account", Customer.RecordId()) then
                    Error(CustomerHasChangedErr, CRMSalesorder.OrderNumber, CRMProductName.CDSServiceName());
            CRMInvoice.CustomerId := AccountId;
            CRMInvoice.CustomerIdType := CRMInvoice.CustomerIdType::account;
            if not CRMSynchHelper.FindCRMPriceListByCurrencyCode(CRMPricelevel, SalesInvoiceHeader."Currency Code") then
                CRMSynchHelper.CreateCRMPricelevelInCurrency(
                  CRMPricelevel, SalesInvoiceHeader."Currency Code", SalesInvoiceHeader."Currency Factor");
            CRMInvoice.PriceLevelId := CRMPricelevel.PriceLevelId;
        end;
        DestinationRecordRef.GetTable(CRMInvoice);
        UpdateOwnerIdAndCompanyId(DestinationRecordRef);
    end;

    local procedure UpdateCRMInvoiceDetailsAfterInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMInvoicedetail: Record "CRM Invoicedetail";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SourceRecordRef.SetTable(SalesInvoiceLine);
        DestinationRecordRef.SetTable(CRMInvoicedetail);

        CRMInvoicedetail.VolumeDiscountAmount := 0;
        CRMInvoicedetail.ManualDiscountAmount := SalesInvoiceLine."Line Discount Amount";
        CRMInvoicedetail.Tax := SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;
        CRMInvoicedetail.BaseAmount :=
          SalesInvoiceLine.Amount + SalesInvoiceLine."Inv. Discount Amount" + SalesInvoiceLine."Line Discount Amount";
        CRMInvoicedetail.ExtendedAmount :=
          SalesInvoiceLine."Amount Including VAT" + SalesInvoiceLine."Inv. Discount Amount";
        CRMInvoicedetail.Modify();

        DestinationRecordRef.GetTable(CRMInvoicedetail);
    end;

    local procedure UpdateCRMInvoiceDetailsBeforeInsertRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMInvoicedetail: Record "CRM Invoicedetail";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSalesInvoiceHeaderId: Guid;
    begin
        SourceRecordRef.SetTable(SalesInvoiceLine);
        DestinationRecordRef.SetTable(CRMInvoicedetail);

        // Get the NAV and CRM invoice headers
        SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.");
        if not CRMIntegrationRecord.FindIDFromRecordID(SalesInvoiceHeader.RecordId(), CRMSalesInvoiceHeaderId) then
            Error(NoCoupledSalesInvoiceHeaderErr, CRMProductName.CDSServiceName());

        // Initialize the CRM invoice lines
        InitializeCRMInvoiceLineFromCRMHeader(CRMInvoicedetail, CRMSalesInvoiceHeaderId);
        InitializeCRMInvoiceLineFromSalesInvoiceHeader(CRMInvoicedetail, SalesInvoiceHeader);
        InitializeCRMInvoiceLineFromSalesInvoiceLine(CRMInvoicedetail, SalesInvoiceLine);
        InitializeCRMInvoiceLineWithProductDetails(CRMInvoicedetail, SalesInvoiceLine);

        CRMSynchHelper.CreateCRMProductpriceIfAbsent(CRMInvoicedetail);

        DestinationRecordRef.GetTable(CRMInvoicedetail);
    end;

    local procedure UpdateCRMPricelevelBeforeInsertRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CustomerPriceGroup: Record "Customer Price Group";
        DestinationFieldRef: FieldRef;
        OutStream: OutStream;
    begin
        SourceRecordRef.SetTable(CustomerPriceGroup);
        CheckCustPriceGroupForSync(CRMTransactioncurrency, CustomerPriceGroup);

        DestinationFieldRef := DestinationRecordRef.Field(CRMPricelevel.FieldNo(TransactionCurrencyId));
        CRMSynchHelper.UpdateCRMCurrencyIdIfChanged(CRMTransactioncurrency.ISOCurrencyCode, DestinationFieldRef);

        DestinationRecordRef.SetTable(CRMPricelevel);
        CRMPricelevel.Description.CreateOutStream(OutStream, TEXTENCODING::UTF16);
        OutStream.WriteText(CustomerPriceGroup.Description);
        DestinationRecordRef.GetTable(CRMPricelevel);

        SetCompanyId(DestinationRecordRef);
    end;

    local procedure UpdateCRMPricelevelBeforeInsertPriceListHeader(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        PriceListHeader: Record "Price List Header";
        DestinationFieldRef: FieldRef;
        OutStream: OutStream;
    begin
        SourceRecordRef.SetTable(PriceListHeader);
        CheckPriceListHeaderForSync(CRMTransactioncurrency, PriceListHeader);

        DestinationFieldRef := DestinationRecordRef.Field(CRMPricelevel.FieldNo(TransactionCurrencyId));
        CRMSynchHelper.UpdateCRMCurrencyIdIfChanged(CRMTransactioncurrency.ISOCurrencyCode, DestinationFieldRef);

        DestinationRecordRef.SetTable(CRMPricelevel);
        CRMPricelevel.Description.CreateOutStream(OutStream, TEXTENCODING::UTF16);
        OutStream.WriteText(PriceListHeader.Description);

        if PriceListHeader.Status = PriceListHeader.Status::Active then
            CRMPricelevel.StateCode := CRMPricelevel.StateCode::Active
        else
            CRMPricelevel.StateCode := CRMPricelevel.StateCode::Inactive;
        DestinationRecordRef.GetTable(CRMPricelevel);

        SetCompanyId(DestinationRecordRef);
    end;

    local procedure UpdateCRMOpportunityBeforeInsertRecord(var DestinationRecordRef: RecordRef)
    begin
        UpdateOwnerIdAndCompanyId(DestinationRecordRef);
    end;

    local procedure UpdateCRMPricelevelBeforeModifyRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        SourceRecordRef.SetTable(CustomerPriceGroup);
        CheckCustPriceGroupForSync(CRMTransactioncurrency, CustomerPriceGroup);

        DestinationRecordRef.SetTable(CRMPricelevel);
        CRMPricelevel.TestField(TransactionCurrencyId, CRMTransactioncurrency.TransactionCurrencyId);

        SetCompanyId(DestinationRecordRef);
    end;

    local procedure UpdateCRMPricelevelBeforeModifyPriceListHeader(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        PriceListHeader: Record "Price List Header";
    begin
        SourceRecordRef.SetTable(PriceListHeader);
        CheckPriceListHeaderForSync(CRMTransactioncurrency, PriceListHeader);

        DestinationRecordRef.SetTable(CRMPricelevel);
        CRMPricelevel.TestField(TransactionCurrencyId, CRMTransactioncurrency.TransactionCurrencyId);

        SetCompanyId(DestinationRecordRef);
    end;

    local procedure ResetCRMProductpricelevelFromCustomerPriceGroup(SourceRecordRef: RecordRef)
    var
        CustomerPriceGroup: Record "Customer Price Group";
        SalesPrice: Record "Sales Price";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        SalesPriceRecordRef: RecordRef;
    begin
        SourceRecordRef.SetTable(CustomerPriceGroup);

        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", CustomerPriceGroup.Code);
        if not SalesPrice.IsEmpty() then begin
            SalesPriceRecordRef.GetTable(SalesPrice);
            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(SalesPriceRecordRef, false, false);
        end;
    end;

    local procedure ResetCRMProductpricelevelFromPriceListHeader(SourceRecordRef: RecordRef)
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        SalesPriceRecordRef: RecordRef;
    begin
        SourceRecordRef.SetTable(PriceListHeader);

        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        if not PriceListLine.IsEmpty() then begin
            SalesPriceRecordRef.GetTable(PriceListLine);
            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(SalesPriceRecordRef, false, false);
        end;
    end;

    local procedure UpdateCRMProductPricelevelAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) UoMHasBeenChanged: Boolean
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
        SalesPrice: Record "Sales Price";
        CRMUom: Record "CRM Uom";
    begin
        DestinationRecordRef.SetTable(CRMProductpricelevel);
        SourceRecordRef.SetTable(SalesPrice);
        FindCRMUoMIdForSalesPrice("Price Asset Type"::Item, SalesPrice."Item No.", SalesPrice."Unit of Measure Code", CRMUom);
        if CRMProductpricelevel.UoMId <> CRMUom.UoMId then begin
            CRMProductpricelevel.UoMId := CRMUom.UoMId;
            CRMProductpricelevel.UoMScheduleId := CRMUom.UoMScheduleId;
            UoMHasBeenChanged := true;
        end;
        DestinationRecordRef.GetTable(CRMProductpricelevel);
    end;

    local procedure UpdateCRMProductPricelevelAfterTransferRecordFieldsPriceListLine(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) UoMHasBeenChanged: Boolean
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
        PriceListLine: Record "Price List Line";
        CRMUom: Record "CRM Uom";
    begin
        DestinationRecordRef.SetTable(CRMProductpricelevel);
        SourceRecordRef.SetTable(PriceListLine);
        FindCRMUoMIdForSalesPrice(PriceListLine."Asset Type", PriceListLine."Asset No.", PriceListLine."Unit of Measure Code", CRMUom);
        if CRMProductpricelevel.UoMId <> CRMUom.UoMId then begin
            CRMProductpricelevel.UoMId := CRMUom.UoMId;
            CRMProductpricelevel.UoMScheduleId := CRMUom.UoMScheduleId;
            UoMHasBeenChanged := true;
        end;
        DestinationRecordRef.GetTable(CRMProductpricelevel);
    end;

    local procedure UpdateCRMProductAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; DestinationIsInserted: Boolean) AdditionalFieldsWereModified: Boolean
    var
        Item: Record Item;
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DestinationFieldRef: FieldRef;
        UnitOfMeasureCodeFieldRef: FieldRef;
        UnitOfMeasureCode: Code[10];
        ProductTypeCode: Option;
        Blocked: Boolean;
    begin
        // Update CRM UoM ID, UoMSchedule Id. The CRM UoM Name and UoMScheduleName will be cascade-updated from their IDs by CRM
        if SourceRecordRef.Number() = DATABASE::Item then begin
            Blocked := SourceRecordRef.Field(Item.FieldNo(Blocked)).Value();
            UnitOfMeasureCodeFieldRef := SourceRecordRef.Field(Item.FieldNo("Base Unit of Measure"));
            ProductTypeCode := CRMProduct.ProductTypeCode::SalesInventory;
        end;

        if SourceRecordRef.Number() = DATABASE::Resource then begin
            Blocked := SourceRecordRef.Field(Resource.FieldNo(Blocked)).Value();
            UnitOfMeasureCodeFieldRef := SourceRecordRef.Field(Resource.FieldNo("Base Unit of Measure"));
            ProductTypeCode := CRMProduct.ProductTypeCode::Services;
        end;

        UnitOfMeasureCodeFieldRef.TestField();
        UnitOfMeasureCode := Format(UnitOfMeasureCodeFieldRef.Value());

        // Update CRM Currency Id (if changed)
        GeneralLedgerSetup.Get();
        DestinationFieldRef := DestinationRecordRef.Field(CRMProduct.FieldNo(TransactionCurrencyId));
        if CRMSynchHelper.UpdateCRMCurrencyIdIfChanged(Format(GeneralLedgerSetup."LCY Code"), DestinationFieldRef) then
            AdditionalFieldsWereModified := true;

        DestinationRecordRef.SetTable(CRMProduct);
        if CRMSynchHelper.UpdateCRMProductUoMFieldsIfChanged(CRMProduct, UnitOfMeasureCode) then
            AdditionalFieldsWereModified := true;

        // If the CRMProduct price is negative, update it to zero (CRM doesn't allow negative prices)
        if CRMSynchHelper.UpdateCRMProductPriceIfNegative(CRMProduct) then
            AdditionalFieldsWereModified := true;

        // If the CRM Quantity On Hand is negative, update it to zero
        if CRMSynchHelper.UpdateCRMProductQuantityOnHandIfNegative(CRMProduct) then
            AdditionalFieldsWereModified := true;

        // Create or update the default price list
        if CRMSynchHelper.UpdateCRMPriceListItem(CRMProduct) then
            AdditionalFieldsWereModified := true;

        // Update the Vendor Name
        if CRMSynchHelper.UpdateCRMProductVendorNameIfChanged(CRMProduct) then
            AdditionalFieldsWereModified := true;

        // Set the ProductTypeCode, to later know if this product came from an item or from a resource
        if CRMSynchHelper.UpdateCRMProductTypeCodeIfChanged(CRMProduct, ProductTypeCode) then
            AdditionalFieldsWereModified := true;

        if DestinationIsInserted then
            if CRMSynchHelper.UpdateCRMProductStateCodeIfChanged(CRMProduct, Blocked) then
                AdditionalFieldsWereModified := true;

        if AdditionalFieldsWereModified then
            DestinationRecordRef.GetTable(CRMProduct);
    end;

    local procedure UpdateCRMProductAfterInsertRecord(var DestinationRecordRef: RecordRef)
    var
        CRMProduct: Record "CRM Product";
    begin
        DestinationRecordRef.SetTable(CRMProduct);
        CRMSynchHelper.UpdateCRMPriceListItem(CRMProduct);
        CRMSynchHelper.SetCRMProductStateToActive(CRMProduct);
        CRMProduct.Modify();
        DestinationRecordRef.GetTable(CRMProduct);
    end;

    local procedure UpdateCRMProductBeforeInsertRecord(var DestinationRecordRef: RecordRef)
    var
        CRMProduct: Record "CRM Product";
    begin
        DestinationRecordRef.SetTable(CRMProduct);
        CRMSynchHelper.SetCRMDecimalsSupportedValue(CRMProduct);
        DestinationRecordRef.GetTable(CRMProduct);
        SetCompanyId(DestinationRecordRef);
    end;

    local procedure UpdateItemAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) AdditionalFieldsWereModified: Boolean
    var
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        Blocked: Boolean;
    begin
        SourceRecordRef.SetTable(CRMProduct);
        DestinationRecordRef.SetTable(Item);

        Blocked := CRMProduct.StateCode <> CRMProduct.StateCode::Active;
        if CRMSynchHelper.UpdateItemBlockedIfChanged(Item, Blocked) then begin
            DestinationRecordRef.GetTable(Item);
            AdditionalFieldsWereModified := true;
        end;
    end;

    local procedure UpdateResourceAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) AdditionalFieldsWereModified: Boolean
    var
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        Blocked: Boolean;
    begin
        SourceRecordRef.SetTable(CRMProduct);
        DestinationRecordRef.SetTable(Resource);

        Blocked := CRMProduct.StateCode <> CRMProduct.StateCode::Active;
        if CRMSynchHelper.UpdateResourceBlockedIfChanged(Resource, Blocked) then begin
            DestinationRecordRef.GetTable(Resource);
            AdditionalFieldsWereModified := true;
        end;
    end;

    local procedure UpdateCRMTransactionCurrencyBeforeInsertRecord(var DestinationRecordRef: RecordRef)
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        DestinationCurrencyPrecisionFieldRef: FieldRef;
    begin
        // Fill in the target currency precision, taken from CRM precision defaults
        DestinationCurrencyPrecisionFieldRef := DestinationRecordRef.Field(CRMTransactioncurrency.FieldNo(CurrencyPrecision));
        DestinationCurrencyPrecisionFieldRef.Value := CRMSynchHelper.GetCRMCurrencyDefaultPrecision();
    end;

    local procedure UpdateCRMTransactionCurrencyAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) AdditionalFieldsWereModified: Boolean
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        CurrencyCodeFieldRef: FieldRef;
        DestinationExchangeRateFieldRef: FieldRef;
        LatestExchangeRate: Decimal;
    begin
        // Fill-in the target currency Exchange Rate
        CurrencyCodeFieldRef := SourceRecordRef.Field(Currency.FieldNo(Code));
        DestinationExchangeRateFieldRef := DestinationRecordRef.Field(CRMTransactioncurrency.FieldNo(ExchangeRate));
        LatestExchangeRate := CRMSynchHelper.GetCRMLCYToFCYExchangeRate(Format(CurrencyCodeFieldRef.Value()));
        if LatestExchangeRate = 0 then
            Error(CurrencyExchangeRateMissingErr, Format(CurrencyCodeFieldRef.Value()), CRMProductName.CDSServiceName());
        if CRMSynchHelper.UpdateFieldRefValueIfChanged(
             DestinationExchangeRateFieldRef,
             Format(LatestExchangeRate))
        then
            AdditionalFieldsWereModified := true;
    end;

    local procedure CRMTransactionCurrencyFindUncoupledDestinationRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) DestinationFound: Boolean
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CurrencyCodeFieldRef: FieldRef;
    begin
        // Attempt to match currencies between NAV and CRM, on NAVCurrency.Code = CRMCurrency.ISOCode
        CurrencyCodeFieldRef := SourceRecordRef.Field(Currency.FieldNo(Code));

        // Find destination record
        CRMTransactioncurrency.SetRange(ISOCurrencyCode, Format(CurrencyCodeFieldRef.Value()));
        // A match between the selected NAV currency and a CRM currency was found
        if CRMTransactioncurrency.FindFirst() then
            DestinationFound := DestinationRecordRef.Get(CRMTransactioncurrency.RecordId());
    end;

    local procedure CRMPriceListLineFindUncoupledDestinationRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) DestinationFound: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMUom: Record "CRM Uom";
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        SalesPrice: Record "Sales Price";
    begin
        // Look for a line with the same combination of ProductId,UoMId
        SourceRecordRef.SetTable(SalesPrice);
        CustomerPriceGroup.Get(SalesPrice."Sales Code");
        if CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup.RecordId()) then begin
            CRMProductpricelevel.SetRange(PriceLevelId, CRMIntegrationRecord."CRM ID");
            FindCRMUoMIdForSalesPrice("Price Asset Type"::Item, SalesPrice."Item No.", SalesPrice."Unit of Measure Code", CRMUom);
            CRMProductpricelevel.SetRange(UoMId, CRMUom.UoMId);
            Item.Get(SalesPrice."Item No.");
            CRMIntegrationRecord.FindByRecordID(Item.RecordId());
            CRMProductpricelevel.SetRange(ProductId, CRMIntegrationRecord."CRM ID");
            DestinationFound := CRMProductpricelevel.FindFirst();
            DestinationRecordRef.GetTable(CRMProductpricelevel);
        end;
    end;

    local procedure CRMExtPriceListLineFindUncoupledDestinationRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) DestinationFound: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMUom: Record "CRM Uom";
        Item: Record Item;
        Resource: Record Resource;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // Look for a line with the same combination of ProductId,UoMId
        SourceRecordRef.SetTable(PriceListLine);
        PriceListHeader.Get(PriceListLine."Price List Code");
        if CRMIntegrationRecord.FindByRecordID(PriceListHeader.RecordId()) then begin
            CRMProductpricelevel.SetRange(PriceLevelId, CRMIntegrationRecord."CRM ID");
            FindCRMUoMIdForSalesPrice(PriceListLine."Asset Type", PriceListLine."Asset No.", PriceListLine."Unit of Measure Code", CRMUom);
            CRMProductpricelevel.SetRange(UoMId, CRMUom.UoMId);
            case PriceListLine."Asset Type" of
                "Price Asset Type"::Item:
                    begin
                        Item.Get(PriceListLine."Asset No.");
                        CRMIntegrationRecord.FindByRecordID(Item.RecordId());
                    end;
                "Price Asset Type"::Resource:
                    begin
                        Resource.Get(PriceListLine."Asset No.");
                        CRMIntegrationRecord.FindByRecordID(Resource.RecordId());
                    end;
            end;
            CRMProductpricelevel.SetRange(ProductId, CRMIntegrationRecord."CRM ID");
            DestinationFound := CRMProductpricelevel.FindFirst();
            DestinationRecordRef.GetTable(CRMProductpricelevel);
        end;
    end;

    local procedure UpdateCRMUoMScheduleAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) AdditionalFieldsWereModified: Boolean
    var
        CRMUomschedule: Record "CRM Uomschedule";
        DestinationFieldRef: FieldRef;
        UnitNameWasUpdated: Boolean;
        CRMUomScheduleName: Text[200];
        CRMUomScheduleStateCode: Option;
        UnitGroupName: Text[200];
        UnitOfMeasureName: Text[100];
        CRMID: Guid;
    begin
        // Prefix with NAV
        UnitOfMeasureName := CRMSynchHelper.GetUnitOfMeasureName(SourceRecordRef);
        UnitGroupName := CRMSynchHelper.GetUnitGroupName(UnitOfMeasureName); // prefix with "NAV "
        DestinationFieldRef := DestinationRecordRef.Field(CRMUomschedule.FieldNo(Name));
        CRMUomScheduleName := Format(DestinationFieldRef.Value());
        if CRMUomScheduleName <> UnitGroupName then begin
            DestinationFieldRef.Value := UnitGroupName;
            AdditionalFieldsWereModified := true;
        end;

        // Get the State Code
        DestinationFieldRef := DestinationRecordRef.Field(CRMUomschedule.FieldNo(StateCode));
        CRMUomScheduleStateCode := DestinationFieldRef.Value();

        DestinationFieldRef := DestinationRecordRef.Field(CRMUomschedule.FieldNo(UoMScheduleId));
        CRMID := DestinationFieldRef.Value();
        if not ValidateCRMUoMSchedule(CRMUomScheduleName, CRMUomScheduleStateCode, CRMID, UnitOfMeasureName, UnitNameWasUpdated) then
            exit;

        if UnitNameWasUpdated then
            AdditionalFieldsWereModified := true;
    end;

    local procedure CRMUoMScheduleFindUncoupledDestinationRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) DestinationFound: Boolean
    var
        CRMUomschedule: Record "CRM Uomschedule";
        UnitFieldWasUpdated: Boolean;
    begin
        // A match between the selected NAV Unit of Measure and a CRM <Unit Group, Unit> tuple was found
        if FindValidCRMUoMSchedule(CRMUomschedule, SourceRecordRef, UnitFieldWasUpdated) then
            DestinationFound := DestinationRecordRef.Get(CRMUomschedule.RecordId());
    end;

    local procedure FindValidCRMUoMSchedule(var CRMUomschedule: Record "CRM Uomschedule"; SourceRecordRef: RecordRef; var UnitNameWasUpdated: Boolean): Boolean
    var
        UnitGroupName: Text[200];
        UnitOfMeasureName: Text[100];
    begin
        UnitOfMeasureName := CRMSynchHelper.GetUnitOfMeasureName(SourceRecordRef);
        UnitGroupName := CRMSynchHelper.GetUnitGroupName(UnitOfMeasureName); // prefix with "NAV "

        // If the CRM Unit Group does not exist, exit
        CRMUomschedule.SetRange(Name, UnitGroupName);
        if not CRMUomschedule.FindFirst() then
            exit(false);

        ValidateCRMUoMSchedule(
          CRMUomschedule.Name, CRMUomschedule.StateCode, CRMUomschedule.UoMScheduleId, UnitOfMeasureName, UnitNameWasUpdated);

        exit(true);
    end;

    local procedure ValidateCRMUoMSchedule(CRMUomScheduleName: Text[200]; CRMUomScheduleStateCode: Option; CRMUomScheduleId: Guid; UnitOfMeasureName: Text[100]; var UnitNameWasUpdated: Boolean): Boolean
    var
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        // If the CRM Unit Group is not active throw and error
        if CRMUomScheduleStateCode = CRMUomschedule.StateCode::Inactive then
            Error(CRMUnitGroupExistsAndIsInactiveErr, CRMUomschedule.TableCaption(), CRMUomScheduleName, CRMProductName.CDSServiceName());

        // If the CRM Unit Group contains > 1 Units, fail
        CRMUom.SetRange(UoMScheduleId, CRMUomScheduleId);
        if CRMUom.Count() > 1 then
            Error(
              CRMUnitGroupContainsMoreThanOneUoMErr, CRMUomschedule.TableCaption(), CRMUomScheduleName, CRMUom.TableCaption(),
              CRMProductName.CDSServiceName());

        // If the CRM Unit Group contains zero Units, then exit (no match found)
        if not CRMUom.FindFirst() then
            exit(false);

        // Verify the CRM Unit name is correct, else update it
        if CRMUom.Name <> UnitOfMeasureName then begin
            CRMUom.Name := UnitOfMeasureName;
            CRMUom.Modify();
            UnitNameWasUpdated := true;
        end;

        exit(true);
    end;

    local procedure FindParentCRMAccountForContact(SourceRecordRef: RecordRef) AccountId: Guid
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
        Customer: Record Customer;
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if not CRMSynchHelper.FindContactRelatedCustomer(SourceRecordRef, ContactBusinessRelation) then
            Error(ContactsMustBeRelatedToCompanyErr, SourceRecordRef.Field(Contact.FieldNo("No.")).Value());

        if not Customer.Get(ContactBusinessRelation."No.") then
            Error(RecordNotFoundErr, Customer.TableCaption(), ContactBusinessRelation."No.");

        CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId(), AccountId);
    end;

    local procedure InitializeCRMInvoiceLineFromCRMHeader(var CRMInvoicedetail: Record "CRM Invoicedetail"; CRMInvoiceId: Guid)
    var
        CRMInvoice: Record "CRM Invoice";
    begin
        CRMInvoice.Get(CRMInvoiceId);
        CRMInvoicedetail.ActualDeliveryOn := CRMInvoice.DateDelivered;
        CRMInvoicedetail.TransactionCurrencyId := CRMInvoice.TransactionCurrencyId;
        CRMInvoicedetail.ExchangeRate := CRMInvoice.ExchangeRate;
        CRMInvoicedetail.InvoiceId := CRMInvoice.InvoiceId;
        CRMInvoicedetail.ShipTo_City := CRMInvoice.ShipTo_City;
        CRMInvoicedetail.ShipTo_Country := CRMInvoice.ShipTo_Country;
        CRMInvoicedetail.ShipTo_Line1 := CRMInvoice.ShipTo_Line1;
        CRMInvoicedetail.ShipTo_Line2 := CRMInvoice.ShipTo_Line2;
        CRMInvoicedetail.ShipTo_Line3 := CRMInvoice.ShipTo_Line3;
        CRMInvoicedetail.ShipTo_Name := CRMInvoice.ShipTo_Name;
        CRMInvoicedetail.ShipTo_PostalCode := CRMInvoice.ShipTo_PostalCode;
        CRMInvoicedetail.ShipTo_StateOrProvince := CRMInvoice.ShipTo_StateOrProvince;
        CRMInvoicedetail.ShipTo_Fax := CRMInvoice.ShipTo_Fax;
        CRMInvoicedetail.ShipTo_Telephone := CRMInvoice.ShipTo_Telephone;
    end;

    local procedure InitializeCRMInvoiceLineFromSalesInvoiceHeader(var CRMInvoicedetail: Record "CRM Invoicedetail"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CRMInvoicedetail.TransactionCurrencyId := CRMSynchHelper.GetCRMTransactioncurrency(SalesInvoiceHeader."Currency Code");
        if SalesInvoiceHeader."Currency Factor" = 0 then
            CRMInvoicedetail.ExchangeRate := 1
        else
            CRMInvoicedetail.ExchangeRate := Round(1 / SalesInvoiceHeader."Currency Factor");
    end;

    local procedure InitializeCRMInvoiceLineFromSalesInvoiceLine(var CRMInvoicedetail: Record "CRM Invoicedetail"; SalesInvoiceLine: Record "Sales Invoice Line")
    begin
        CRMInvoicedetail.LineItemNumber := SalesInvoiceLine."Line No.";
        CRMInvoicedetail.Tax := SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;
    end;

    local procedure InitializeCRMInvoiceLineWithProductDetails(var CRMInvoicedetail: Record "CRM Invoicedetail"; SalesInvoiceLine: Record "Sales Invoice Line")
    var
        CRMProduct: Record "CRM Product";
        CRMProductId: Guid;
    begin
        CRMProductId := FindCRMProductId(SalesInvoiceLine);
        if IsNullGuid(CRMProductId) then begin
            // This will be created as a CRM write-in product
            CRMInvoicedetail.IsProductOverridden := true;
            CRMInvoicedetail.ProductDescription :=
              StrSubstNo('%1 %2.', Format(SalesInvoiceLine."No."), Format(SalesInvoiceLine.Description));
        end else begin
            // There is a coupled product or resource in CRM, transfer data from there
            CRMProduct.Get(CRMProductId);
            CRMInvoicedetail.ProductId := CRMProduct.ProductId;
            CRMInvoicedetail.UoMId := CRMProduct.DefaultUoMId;
        end;
    end;

    local procedure FindCRMProductId(SalesInvoiceLine: Record "Sales Invoice Line") CRMID: Guid
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Resource: Record Resource;
    begin
        Clear(CRMID);
        SalesReceivablesSetup.Get();
        // if this is the item that represents the Write-In product from CDS, there is no CRMID
        if SalesReceivablesSetup."Write-in Product No." = SalesInvoiceLine."No." then
            exit;
        case SalesInvoiceLine.Type of
            SalesInvoiceLine.Type::Item:
                CRMID := FindCRMProductIdForItem(SalesInvoiceLine."No.");
            SalesInvoiceLine.Type::Resource:
                begin
                    Resource.Get(SalesInvoiceLine."No.");
                    if not CRMIntegrationRecord.FindIDFromRecordID(Resource.RecordId(), CRMID) then begin
                        if not CRMSynchHelper.SynchRecordIfMappingExists(Database::Resource, Database::"CRM Product", Resource.RecordId()) then
                            Error(CannotSynchProductErr, Resource."No.");
                        if not CRMIntegrationRecord.FindIDFromRecordID(Resource.RecordId(), CRMID) then
                            Error(CannotFindSyncedProductErr);
                    end;
                end;
        end;
    end;

    local procedure FindCRMProductIdForItem(ItemNo: Code[20]) CRMID: Guid
    var
        Item: Record Item;
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        Item.Get(ItemNo);
        if not CRMIntegrationRecord.FindIDFromRecordID(Item.RecordId(), CRMID) then begin
            if not CRMSynchHelper.SynchRecordIfMappingExists(Database::Item, Database::"CRM Product", Item.RecordId()) then
                Error(CannotSynchProductErr, Item."No.");
            if not CRMIntegrationRecord.FindIDFromRecordID(Item.RecordId(), CRMID) then
                Error(CannotFindSyncedProductErr);
        end;
    end;

    local procedure FindCRMProductIdForResource(ResourceNo: Code[20]) CRMID: Guid
    var
        Resource: Record Resource;
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        Resource.Get(ResourceNo);
        if not CRMIntegrationRecord.FindIDFromRecordID(Resource.RecordId(), CRMID) then begin
            if not CRMSynchHelper.SynchRecordIfMappingExists(Database::Resource, Database::"CRM Product", Resource.RecordId()) then
                Error(CannotSynchProductErr, Resource."No.");
            if not CRMIntegrationRecord.FindIDFromRecordID(Resource.RecordId(), CRMID) then
                Error(CannotFindSyncedProductErr);
        end;
    end;

    local procedure FindCRMUoMIdForSalesPrice(AssetType: Enum "Price Asset Type"; AssetNo: Code[20]; UoMCode: Code[10]; var CRMUom: Record "CRM Uom")
    var
        Item: Record Item;
        Resource: Record Resource;
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        if UoMCode = '' then
            case AssetType of
                AssetType::Item:
                    begin
                        Item.Get(AssetNo);
                        UoMCode := Item."Base Unit of Measure";
                    end;
                AssetType::Resource:
                    begin
                        Resource.Get(AssetNo);
                        UoMCode := Resource."Base Unit of Measure";
                    end;
                else
                    exit;
            end;
        CRMSynchHelper.GetValidCRMUnitOfMeasureRecords(CRMUom, CRMUomschedule, UoMCode);
    end;

    local procedure CheckSalesPricesForSync(CustomerPriceGroupCode: Code[10]; ExpectedCurrencyCode: Code[10])
    var
        SalesPrice: Record "Sales Price";
        CRMUom: Record "CRM Uom";
    begin
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", CustomerPriceGroupCode);
        if SalesPrice.FindSet() then
            repeat
                SalesPrice.TestField("Currency Code", ExpectedCurrencyCode);
                FindCRMProductIdForItem(SalesPrice."Item No.");
                FindCRMUoMIdForSalesPrice("Price Asset Type"::Item, SalesPrice."Item No.", SalesPrice."Unit of Measure Code", CRMUom);
            until SalesPrice.Next() = 0;
    end;

    local procedure CheckPriceListLinesForSync(PriceListCode: Code[20]; ExpectedCurrencyCode: Code[10])
    var
        PriceListLine: Record "Price List Line";
        CRMUom: Record "CRM Uom";
    begin
        PriceListLine.SetRange("Price List Code", PriceListCode);
        if PriceListLine.FindSet() then
            repeat
                PriceListLine.TestField("Currency Code", ExpectedCurrencyCode);
                case PriceListLine."Asset Type" of
                    "Price Asset Type"::Item:
                        FindCRMProductIdForItem(PriceListLine."Asset No.");
                    "Price Asset Type"::Resource:
                        FindCRMProductIdForResource(PriceListLine."Asset No.");
                end;
                FindCRMUoMIdForSalesPrice(PriceListLine."Asset Type", PriceListLine."Asset No.", PriceListLine."Unit of Measure Code", CRMUom);
            until PriceListLine.Next() = 0;
    end;

    local procedure CheckCustPriceGroupForSync(var CRMTransactioncurrency: Record "CRM Transactioncurrency"; CustomerPriceGroup: Record "Customer Price Group")
    var
        SalesPrice: Record "Sales Price";
    begin
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", CustomerPriceGroup.Code);
        if SalesPrice.FindFirst() then begin
            CRMTransactioncurrency.Get(CRMSynchHelper.GetCRMTransactioncurrency(SalesPrice."Currency Code"));
            CheckSalesPricesForSync(CustomerPriceGroup.Code, SalesPrice."Currency Code");
        end else
            CRMSynchHelper.FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);
    end;

    local procedure CheckPriceListHeaderForSync(var CRMTransactioncurrency: Record "CRM Transactioncurrency"; PriceListHeader: Record "Price List Header")
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        if PriceListLine.FindFirst() then begin
            CRMTransactioncurrency.Get(CRMSynchHelper.GetCRMTransactioncurrency(PriceListLine."Currency Code"));
            CheckPriceListLinesForSync(PriceListHeader.Code, PriceListLine."Currency Code");
        end else
            CRMSynchHelper.FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);
    end;

    local procedure CheckItemOrResourceIsNotBlocked(SourceRecordRef: RecordRef)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        Item: Record Item;
        Resource: Record Resource;
    begin
        SourceRecordRef.SetTable(SalesInvHeader);
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.SetFilter(Type, '%1|%2', SalesInvLine.Type::Item, SalesInvLine.Type::Resource);
        if SalesInvLine.FindSet() then
            repeat
                if SalesInvLine.Type = SalesInvLine.Type::Item then begin
                    Item.Get(SalesInvLine."No.");
                    Item.TestField(Blocked, false);
                end else begin
                    Resource.Get(SalesInvLine."No.");
                    Resource.TestField(Blocked, false);
                end;
            until SalesInvLine.Next() = 0;
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
                    if CRMSynchHelper.FindRecordIDByPK(IntegrationTableMapping."Table ID", SourceFieldRef.Value(), RecID) then
                        if CRMIntegrationRecord.FindIDFromRecordID(RecID, NewValue) then
                            exit(true);
                    if CRMSynchHelper.IsClearValueOnFailedSync(SourceFieldRef, DestinationFieldRef) then begin
                        NewValue := CRMID;
                        exit(true);
                    end;
                    Error(RecordMustBeCoupledErr, SourceFieldRef.Caption(), SourceFieldRef.Value(), CRMProductName.CDSServiceName());
                end;
            IntegrationTableMapping.Direction::FromIntegrationTable:
                begin
                    CRMID := SourceFieldRef.Value();
                    if IsNullGuid(CRMID) then begin
                        NewValue := '';
                        IsValueFound := true;
                    end else begin
                        if CRMIntegrationRecord.FindRecordIDFromID(CRMID, IntegrationTableMapping."Table ID", RecID) then
                            if CRMSynchHelper.FindPKByRecordID(RecID, NewValue) then
                                exit(true);
                        if CRMSynchHelper.IsClearValueOnFailedSync(DestinationFieldRef, SourceFieldRef) then begin
                            NewValue := '';
                            exit(true);
                        end;
                        Error(RecordMustBeCoupledErr, SourceFieldRef.Caption(), CRMID, PRODUCTNAME.Short());
                    end;
                end;
        end;
    end;

    local procedure UpdateAccountEnumsFromOptions(var DestinationRecordRef: RecordRef)
    var
        CRMAccount: Record "CRM Account";
        PaymentTermsEnumValue: Enum "CDS Payment Terms Code";
        ShipmentMethodEnumValue: Enum "CDS Shipment Method Code";
        ShippingAgentEnumValue: Enum "CDS Shipping Agent Code";
    begin
        PaymentTermsEnumValue := DestinationRecordRef.Field(CRMAccount.FieldNo(PaymentTermsCodeEnum)).Value();
        UpdateEnumFromOption(DestinationRecordRef, CRMAccount.FieldNo(PaymentTermsCode), CRMAccount.FieldNo(PaymentTermsCodeEnum), PaymentTermsEnumValue.AsInteger());

        ShipmentMethodEnumValue := DestinationRecordRef.Field(CRMAccount.FieldNo(Address1_FreightTermsCodeEnum)).Value();
        UpdateEnumFromOption(DestinationRecordRef, CRMAccount.FieldNo(Address1_FreightTermsCode), CRMAccount.FieldNo(Address1_FreightTermsCodeEnum), ShipmentMethodEnumValue.AsInteger());

        ShippingAgentEnumValue := DestinationRecordRef.Field(CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum)).Value();
        UpdateEnumFromOption(DestinationRecordRef, CRMAccount.FieldNo(Address1_ShippingMethodCode), CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum), ShippingAgentEnumValue.AsInteger());
    end;

    local procedure UpdateInvoiceEnumsFromOptions(var DestinationRecordRef: RecordRef)
    var
        CRMInvoice: Record "CRM Invoice";
        PaymentTermsEnumValue: Enum "CDS Payment Terms Code";
        ShippingAgentEnumValue: Enum "CDS Shipping Agent Code";
    begin
        PaymentTermsEnumValue := DestinationRecordRef.Field(CRMInvoice.FieldNo(PaymentTermsCodeEnum)).Value();
        UpdateEnumFromOption(DestinationRecordRef, CRMInvoice.FieldNo(PaymentTermsCode), CRMInvoice.FieldNo(PaymentTermsCodeEnum), PaymentTermsEnumValue.AsInteger());

        ShippingAgentEnumValue := DestinationRecordRef.Field(CRMInvoice.FieldNo(ShippingMethodCodeEnum)).Value();
        UpdateEnumFromOption(DestinationRecordRef, CRMInvoice.FieldNo(ShippingMethodCode), CRMInvoice.FieldNo(ShippingMethodCodeEnum), ShippingAgentEnumValue.AsInteger());
    end;

    local procedure UpdateEnumFromOption(var DestinationRecordRef: RecordRef; OptionFieldNo: Integer; EnumFieldNo: Integer; EnumValue: Integer)
    var
        OptionDestinationFielRef: FieldRef;
        EnumDestinationFielRef: FieldRef;
        OptionValue: Integer;
    begin
        OptionDestinationFielRef := DestinationRecordRef.Field(OptionFieldNo);
        EnumDestinationFielRef := DestinationRecordRef.Field(EnumFieldNo);
        OptionValue := OptionDestinationFielRef.Value();
        if (OptionValue <> 0) and (OptionValue <> EnumValue) then
            EnumDestinationFielRef.Value := OptionValue;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCRMInvoiceBeforeInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; var IsHandled: Boolean)
    begin
    end;
}

