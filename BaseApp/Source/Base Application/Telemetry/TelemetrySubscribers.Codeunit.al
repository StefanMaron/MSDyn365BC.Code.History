codeunit 1351 "Telemetry Subscribers"
{
    Permissions = TableData "Permission Set Link" = r;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        Telemetry: Codeunit Telemetry;
        ProfileChangedTelemetryMsg: Label 'Profile changed from %1 to %2.', Comment = '%1=Previous profile id, %2=New profile id';
        ProfileChangedTelemetryCategoryTxt: Label 'AL User Profile';
        PermissionSetCategoryTxt: Label 'AL PermissionSet', Locked = true;
        PermissionSetLinkAddedTelemetryTxt: Label 'A Permission Set Link was added between Source Permission Set %1 and Permission Set %2. Total count of Permission Set Links are %3.', Locked = true;
        PermissionSetAssignedToUserGroupTelemetryTxt: Label 'Permission Set %1 was added to a user group %2.', Locked = true;
        PermissionSetLinkAddedTelemetryScopeAllTxt: Label 'Permission set link added: %1 -> %2', Locked = true;
        PermissionSetLinkRemovedTelemetryScopeAllTxt: Label 'Permission set link removed: %1 -> %2', Locked = true;
        PermissionSetAddedTelemetryScopeAllTxt: Label 'User-defined permission set added: %1', Locked = true;
        PermissionSetRemovedTelemetryScopeAllTxt: Label 'User-defined permission set removed: %1', Locked = true;
        PermissionSetSystemAddedTelemetryScopeAllTxt: Label 'Permission set added: %1', Locked = true;
        PermissionSetSystemRemovedTelemetryScopeAllTxt: Label 'Permission set removed: %1', Locked = true;
        PermissionSetAssignedToUserTelemetryScopeAllTxt: Label 'Permission set assigned to user: %1', Locked = true;
        PermissionSetRemovedFromUserTelemetryScopeAllTxt: Label 'Permission set removed from user: %1', Locked = true;
        PermissionSetAssignedToUserGroupTelemetryScopeAllTxt: Label 'Permission set assigned to user group: %1', Locked = true;
        PermissionSetRemovedFromUserGroupTelemetryScopeAllTxt: Label 'Permission set removed from user group: %1', Locked = true;
        EffectivePermsCalculatedTxt: Label 'Effective permissions were calculated for company %1, object type %2, object ID %3.', Locked = true, Comment = '%1 = company name, %2 = object type, %3 = object Id';
        TenantPermissionsChangedFromEffectivePermissionsPageTxt: Label 'Tenant permission set %1 was changed.', Locked = true, Comment = '%1 = permission set id';
        NumberOfDocumentLinesMsg: Label 'Type of Document: %1, Number of Document Lines: %2', Locked = true;
        RecordCountCategoryTxt: Label 'AL Record Count', Locked = true;
        JobQueueEntriesCategoryTxt: Label 'AL JobQueueEntries', Locked = true;
        ReusingExistingJobFromIdTxt: Label 'Reusing Job Queue', Locked = true;
        JobQueueEntryFinishedTxt: Label 'JobID = %1, ObjectType = %2, ObjectID = %3, Status = Finished, Result = %4, Company = %5, Scheduled Task Id = %6', Locked = true;
        JobQueueEntryStartedAllTxt: Label 'Job queue entry started: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryFinishedAllTxt: Label 'Job queue entry finished: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryErrorAllTxt: Label 'Job queue entry errored: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryEnqueuedAllTxt: Label 'Job queue entry enqueued: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryNotEnqueuedTxt: Label 'Job queue entry not enqueued: %1', Comment = '%1 = Job queue id', Locked = true;
        UndoSalesShipmentCategoryTxt: Label 'AL UndoSalesShipmentNoOfLines', Locked = true;
        UndoSalesShipmentNoOfLinesTxt: Label 'UndoNoOfLines = %1', Locked = true;
        EmailLoggingTelemetryCategoryTxt: Label 'AL Email Logging', Locked = true;
        UserSettingUpEmailLoggingTxt: Label 'User is attempting to set up email logging via %1 page.', Locked = true;
        UserCompletedSettingUpEmailLoggingTxt: Label 'User completed the setting up of email logging via %1 page.', Locked = true;
        UserCreatingInteractionLogEntryBasedOnEmailTxt: Label 'User created an interaction log entry from an email message.', Locked = true;
        BankAccountRecCategoryLbl: Label 'AL Bank Account Rec', Locked = true;
        BankAccountRecPostedWithBankAccCurrencyCodeMsg: Label 'Bank Account Reconciliation posted with CurrencyCode set to: %1', Locked = true;
#if not CLEAN21
        BankAccountRecAutoMatchMsg: Label 'Total number of lines in the bank statement: %1; Total number of automatches: %2', Locked = true;
#endif
        BankAccountRecTextToAccountCountLbl: Label 'Number of lines where Text-To-Applied was used: %1', Locked = true;
        BankAccountRecTransferToGJMsg: Label 'Lines of Bank Statement to transfer to GJ: %1', Locked = true;
        PurchaseDocumentInformationLbl: Label 'Purchase document posted: %1', Locked = true;
        SalesDocumentInformationLbl: Label 'Sales document posted: %1 ', Locked = true;
        SalesInvoiceInformationLbl: Label 'Sales invoice posted: %1', Locked = true;
        LogNonInventoryUsageLbl: Label 'Non-inventory usage logging', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Conf./Personalization Mgt.", 'OnProfileChanged', '', true, true)]
    local procedure SendTraceOnProfileChanged(PrevAllProfile: Record "All Profile"; CurrentAllProfile: Record "All Profile")
    begin
        if not IsSaaS() then
            exit;

        Session.LogMessage('00001O5', StrSubstNo(ProfileChangedTelemetryMsg, PrevAllProfile."Profile ID", CurrentAllProfile."Profile ID"), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', ProfileChangedTelemetryCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Permission Set Link", 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetLinkAdded(var Rec: Record "Permission Set Link"; RunTrigger: Boolean)
    var
        PermissionSetLink: Record "Permission Set Link";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Session.LogMessage('0000250', StrSubstNo(PermissionSetLinkAddedTelemetryTxt, Rec."Permission Set ID", Rec."Linked Permission Set ID", PermissionSetLink.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', PermissionSetCategoryTxt);

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('SourcePermissionSetId', Rec."Permission Set ID");
        Dimensions.Add('LinkedPermissionSetId', Rec."Linked Permission Set ID");
        Dimensions.Add('NumberOfUserDefinedPermissionSetLinks', Format(PermissionSetLink.Count));
        Session.LogMessage('0000E28', StrSubstNo(PermissionSetLinkAddedTelemetryScopeAllTxt, Rec."Permission Set ID", Rec."Linked Permission Set ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Permission Set Link", 'OnBeforeDeleteEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetLinkRemoved(var Rec: Record "Permission Set Link"; RunTrigger: Boolean)
    var
        PermissionSetLink: Record "Permission Set Link";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('SourcePermissionSetId', Rec."Permission Set ID");
        Dimensions.Add('LinkedPermissionSetId', Rec."Linked Permission Set ID");
        Dimensions.Add('NumberOfUserDefinedPermissionSetLinks', Format(PermissionSetLink.Count - 1));
        Session.LogMessage('0000E29', StrSubstNo(PermissionSetLinkRemovedTelemetryScopeAllTxt, Rec."Permission Set ID", Rec."Linked Permission Set ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Permission Set", 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetIsAdded(var Rec: Record "Permission Set"; RunTrigger: Boolean)
    var
        PermissionSetRec: Record "Permission Set";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('NumberOfSystemPermissionSets', Format(PermissionSetRec.Count));
        Session.LogMessage('0000GMG', StrSubstNo(PermissionSetSystemAddedTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Permission Set", 'OnBeforeDeleteEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetIsRemoved(var Rec: Record "Permission Set"; RunTrigger: Boolean)
    var
        PermissionSetRec: Record "Permission Set";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('NumberOfSystemPermissionSets', Format(PermissionSetRec.Count - 1));
        Session.LogMessage('0000GMH', StrSubstNo(PermissionSetSystemRemovedTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tenant Permission Set", 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnUserDefinedPermissionSetIsAdded(var Rec: Record "Tenant Permission Set"; RunTrigger: Boolean)
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        if not IsNullGuid(Rec."App ID") then
            exit;

        TenantPermissionSet.SetRange("App ID", Rec."App ID");

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('NumberOfUserDefinedPermissionSets', Format(TenantPermissionSet.Count));
        Session.LogMessage('0000E2A', StrSubstNo(PermissionSetAddedTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tenant Permission Set", 'OnBeforeDeleteEvent', '', true, true)]
    local procedure SendTraceOnUserDefinedPermissionSetIsRemoved(var Rec: Record "Tenant Permission Set"; RunTrigger: Boolean)
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        if not IsNullGuid(Rec."App ID") then
            exit;

        TenantPermissionSet.SetRange("App ID", Rec."App ID");

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('NumberOfUserDefinedPermissionSets', Format(TenantPermissionSet.Count - 1));
        Session.LogMessage('0000E2B', StrSubstNo(PermissionSetRemovedTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Access Control", 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetIsAssignedToAUser(var Rec: Record "Access Control"; RunTrigger: Boolean)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('PermissionSetAppId', Rec."App ID");
        Dimensions.Add('PermissionSetScope', Format(Rec.Scope));
        Session.LogMessage('0000E2C', StrSubstNo(PermissionSetAssignedToUserTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Access Control", 'OnBeforeDeleteEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetIsRemovedFromAUser(var Rec: Record "Access Control"; RunTrigger: Boolean)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('PermissionSetAppId', Rec."App ID");
        Dimensions.Add('PermissionSetScope', Format(Rec.Scope));
        Session.LogMessage('0000E2D', StrSubstNo(PermissionSetRemovedFromUserTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Group Permission Set", 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetIsAssignedToAUserGroup(var Rec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Session.LogMessage('0000253', StrSubstNo(PermissionSetAssignedToUserGroupTelemetryTxt, Rec."Role ID", Rec."User Group Code"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PermissionSetCategoryTxt);

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('PermissionSetAppId', Rec."App ID");
        Dimensions.Add('PermissionSetScope', Format(Rec.Scope));
        Dimensions.Add('UserGroupId', Rec."User Group Code");
        Session.LogMessage('0000E2E', StrSubstNo(PermissionSetAssignedToUserGroupTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Group Permission Set", 'OnBeforeDeleteEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetIsRemovedFromAUserGroup(var Rec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('PermissionSetAppId', Rec."App ID");
        Dimensions.Add('PermissionSetScope', Format(Rec.Scope));
        Dimensions.Add('UserGroupId', Rec."User Group Code");
        Session.LogMessage('0000E2F', StrSubstNo(PermissionSetRemovedFromUserGroupTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnReuseExisingJobFromId', '', false, false)]
    local procedure EmitTelemetryOnReuseExisingJobFromId(JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Telemetry.LogMessage('0000F6B',
                                ReusingExistingJobFromIdTxt,
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::ExtensionPublisher,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnAfterEnqueueJobQueueEntry', '', false, false)]
    local procedure SendTraceOnAfterEnqueueJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);

        if IsNullGuid(JobQueueEntry."System Task ID") then
            Telemetry.LogMessage('0000FNY',
                                    StrSubstNo(JobQueueEntryNotEnqueuedTxt, Format(JobQueueEntry.ID, 0, 4)),
                                    Verbosity::Warning,
                                    DataClassification::OrganizationIdentifiableInformation,
                                    TelemetryScope::All,
                                    Dimensions)
        else
            Telemetry.LogMessage('0000E24',
                                    StrSubstNo(JobQueueEntryEnqueuedAllTxt, Format(JobQueueEntry.ID, 0, 4)),
                                    Verbosity::Normal,
                                    DataClassification::OrganizationIdentifiableInformation,
                                    TelemetryScope::All,
                                    Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Dispatcher", 'OnBeforeExecuteJob', '', false, false)]
    local procedure SendTraceOnJobQueueEntryStarted(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Telemetry.LogMessage('0000E25',
                                StrSubstNo(JobQueueEntryStartedAllTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Dispatcher", 'OnAfterSuccessExecuteJob', '', false, false)]
    local procedure SendTraceOnJobQueueEntryFinishedSuccessfully(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        // Job has finished but JQE does not update to finished status when it does (By design)
        Dimensions.Set('JobQueueStatus', Format(JobQueueEntry.Status::Finished));
        Telemetry.LogMessage('000082C',
                                StrSubstNo(JobQueueEntryFinishedTxt, JobQueueEntry.ID, JobQueueEntry."Object Type to Run", JobQueueEntry."Object ID to Run", 'Success', JobQueueEntry.CurrentCompany(), JobQueueEntry."System Task ID"),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::ExtensionPublisher,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Error Handler", 'OnBeforeLogError', '', false, false)]
    local procedure SendTraceOnJobQueueEntryErrored(var JobQueueLogEntry: Record "Job Queue Log Entry"; var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Dimensions.Add('JobQueueStacktrace', JobQueueLogEntry.GetErrorCallStack());
        Telemetry.LogMessage('0000HE7',
                                StrSubstNo(JobQueueEntryErrorAllTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Warning,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Dispatcher", 'OnAfterSuccessHandleRequest', '', false, false)]
    local procedure SendTraceOnJobQueueEntryRequestFinishedSuccessfully(var JobQueueEntry: Record "Job Queue Entry"; JobQueueExecutionTime: Integer)
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Dimensions.Add('JobQueueExecutionTimeInMs', Format(JobQueueExecutionTime));
        Telemetry.LogMessage('0000E26',
                                StrSubstNo(JobQueueEntryFinishedAllTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    internal procedure SetJobQueueTelemetryDimensions(var JobQueueEntry: Record "Job Queue Entry"; var Dimensions: Dictionary of [Text, Text])
    begin
        Dimensions.Add('Category', JobQueueEntriesCategoryTxt);
        Dimensions.Add('JobQueueId', Format(JobQueueEntry.ID, 0, 4));
        Dimensions.Add('JobQueueObjectType', Format(JobQueueEntry."Object Type to Run"));
        Dimensions.Add('JobQueueObjectId', Format(JobQueueEntry."Object ID to Run"));
        Dimensions.Add('JobQueueStatus', Format(JobQueueEntry.Status));
        Dimensions.Add('JobQueueIsRecurring', Format(JobQueueEntry."Recurring Job"));
        Dimensions.Add('JobQueueEarliestStartDateTime', Format(JobQueueEntry."Earliest Start Date/Time", 0, 9)); // UTC time
        Dimensions.Add('JobQueueCompanyName', JobQueueEntry.CurrentCompany());
        Dimensions.Add('JobQueueScheduledTaskId', Format(JobQueueEntry."System Task ID", 0, 4));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Sales Shipment Line", 'OnAfterCode', '', false, false)]
    local procedure SendTraceUndoSalesShipmentNoOfLines(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
        if not IsSaaS() then
            exit;

        SalesShipmentLine.SetRange(Correction, true);
        Session.LogMessage('000085N', StrSubstNo(UndoSalesShipmentNoOfLinesTxt, SalesShipmentLine.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', UndoSalesShipmentCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Effective Permissions", 'OnEffectivePermissionsPopulated', '', true, true)]
    local procedure EffectivePermissionsFetchedInPage(CurrUserId: Guid; CurrCompanyName: Text[30]; CurrObjectType: Integer; CurrObjectId: Integer)
    begin
        if not IsSaaS() then
            exit;

        Session.LogMessage('000027E', StrSubstNo(EffectivePermsCalculatedTxt, CurrCompanyName, CurrObjectType, CurrObjectId), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PermissionSetCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Effective Permissions Mgt.", 'OnTenantPermissionModified', '', true, true)]
    local procedure EffectivePermissionsChangeInPage(PermissionSetId: Code[20])
    begin
        if not IsSaaS() then
            exit;

        Session.LogMessage('000027G', StrSubstNo(TenantPermissionsChangedFromEffectivePermissionsPageTxt, PermissionSetId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PermissionSetCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post (Yes/No)", 'OnAfterPost', '', true, true)]
    local procedure LogNumberOfPurchaseLines(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        DocumentType: Integer;
        DocumentNumber: Code[20];
        Attributes: Dictionary of [Text, Text];
    begin
        DocumentType := PurchaseHeader."Document Type".AsInteger();
        DocumentNumber := PurchaseHeader."No.";
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");

        Attributes.Add('DocumentType', Format(DocumentType));
        Attributes.Add('DocumentNumber', Format(DocumentNumber));
        Attributes.Add('NumberOfLines', Format(PurchaseLine.Count()));
        Session.LogMessage('0000CST', StrSubstNo(PurchaseDocumentInformationLbl, DocumentNumber), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Attributes);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post (Yes/No)", 'OnAfterPost', '', true, true)]
    local procedure LogNumberOfSalesLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        DocumentType: Integer;
        DocumentNumber: Code[20];
        Attributes: Dictionary of [Text, Text];
    begin
        DocumentType := SalesHeader."Document Type".AsInteger();
        DocumentNumber := SalesHeader."No.";
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");

        Session.LogMessage('000085U', StrSubstNo(NumberOfDocumentLinesMsg, Format(DocumentType), SalesLine.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RecordCountCategoryTxt);

        Attributes.Add('DocumentType', Format(DocumentType));
        Attributes.Add('DocumentNumber', Format(DocumentnUmber));
        Attributes.Add('NumberOfLines', Format(SalesLine.Count()));
        Session.LogMessage('0000CSU', StrSubstNo(SalesDocumentInformationLbl, DocumentNumber), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Attributes);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Invoice", 'OnAfterGetSalesHeader', '', true, true)]
    local procedure LogNumberOfSalesInvoiceLinesForReport1306(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        LogNumberOfSalesInvoiceLines(SalesInvoiceHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Management", 'OnSendDailyTelemetry', '', true, true)]
    local procedure LogNonInventoryUsage()
    var
        TelemetryQuery: Query "Non-Inventory Telemetry";
        Attributes: Dictionary of [Text, Text];
    begin
        TelemetryQuery.SetRange(Location_Code, '');
        TelemetryQuery.Open();
        if TelemetryQuery.Read() then
            Attributes.Add('NoOfNonInventoryItemLedgerEntriesWithoutLocation', Format(TelemetryQuery.NoOfNonInventory))
        else
            Attributes.Add('NoOfNonInventoryItemLedgerEntriesWithoutLocation', '0');
        TelemetryQuery.Close();

        TelemetryQuery.SetFilter(Location_Code, '<> ''''');
        TelemetryQuery.Open();
        if TelemetryQuery.Read() then
            Attributes.Add('NoOfNonInventoryItemLedgerEntriesWithLocation', Format(TelemetryQuery.NoOfNonInventory))
        else
            Attributes.Add('NoOfNonInventoryItemLedgerEntriesWithLocation', '0');
        TelemetryQuery.Close();

        Session.LogMessage(
            '0000FD5',
            LogNonInventoryUsageLbl,
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::All,
            Attributes
        );
    end;

    local procedure LogNumberOfSalesInvoiceLines(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNumber: Code[20];
        Attributes: Dictionary of [Text, Text];
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        DocumentNumber := SalesInvoiceHeader."No.";
        Session.LogMessage('000085V', StrSubstNo(NumberOfDocumentLinesMsg, 'Sales Invoice - export', SalesInvoiceLine.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RecordCountCategoryTxt);
        Attributes.Add('DocumentNumber', Format(DocumentnUmber));
        Attributes.Add('NumberOfLines', Format(SalesInvoiceLine.Count()));

        Session.LogMessage('0000CZ0', StrSubstNo(SalesInvoiceInformationLbl, DocumentNumber), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Attributes);
    end;

    local procedure IsSaaS(): Boolean
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        exit(EnvironmentInfo.IsSaaS());
    end;

    [EventSubscriber(ObjectType::Page, Page::"Setup Email Logging", 'OnOpenPageEvent', '', false, false)]
    local procedure LogTelemetryOnOpenSetupEmailLoggingPage()
    var
        SetupEmailLogging: Page "Setup Email Logging";
    begin
        Session.LogMessage('000089V', StrSubstNo(UserSettingUpEmailLoggingTxt, SetupEmailLogging.Caption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
    end;

    [EventSubscriber(ObjectType::Page, Page::"Setup Email Logging", 'OnAfterAssistedSetupEmailLoggingCompleted', '', false, false)]
    local procedure LogTelemetryOnAfterAssistedSetupEmailLoggingCompleted()
    var
        SetupEmailLogging: Page "Setup Email Logging";
    begin
        Session.LogMessage('000089W', StrSubstNo(UserCompletedSettingUpEmailLoggingTxt, SetupEmailLogging.Caption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
    end;

    [EventSubscriber(ObjectType::Page, Page::"Marketing Setup", 'OnAfterMarketingSetupEmailLoggingUsed', '', false, false)]
    local procedure LogTelemetryOnAfterMarketingSetupEmailLoggingUsed()
    var
        MarketingSetup: Page "Marketing Setup";
    begin
        Session.LogMessage('000089X', StrSubstNo(UserSettingUpEmailLoggingTxt, MarketingSetup.Caption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
    end;

    [EventSubscriber(ObjectType::Page, Page::"Marketing Setup", 'OnAfterMarketingSetupEmailLoggingCompleted', '', false, false)]
    local procedure LogTelemetryOnAfterMarketingSetupEmailLoggingCompleted()
    var
        MarketingSetup: Page "Marketing Setup";
    begin
        Session.LogMessage('000089Y', StrSubstNo(UserCompletedSettingUpEmailLoggingTxt, MarketingSetup.Caption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Email Logging Dispatcher", 'OnAfterInsertInteractionLogEntry', '', false, false)]
    local procedure LogTelemetryOnAfterInsertInteractionLogEntry()
    begin
        Session.LogMessage('000089Z', UserCreatingInteractionLogEntryBasedOnEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Bank Acc. Reconciliation Post", 'OnAfterFinalizePost', '', true, true)]
    local procedure LogTelemetryOnBankAccRecPostOnAfterFinalizePost(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccount: Record "Bank Account";
    begin
        with BankAccount do begin
            Get(BankAccReconciliation."Bank Account No.");
            Session.LogMessage('0000AHX', StrSubstNo(BankAccountRecPostedWithBankAccCurrencyCodeMsg, BankAccount."Currency Code"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);
        end;
    end;

#if not CLEAN21
    [EventSubscriber(ObjectType::Codeunit, codeunit::"Match Bank Rec. Lines", 'OnAfterMatchBankRecLinesMatchSingle', '', true, true)]
    local procedure LogTelemetryOnAfterMatchBankRecLinesMatchSingle(CountMatchCandidates: Integer; TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer")
    begin
        Session.LogMessage('0000AHZ', StrSubstNo(BankAccountRecAutoMatchMsg, CountMatchCandidates, TempBankStatementMatchingBuffer.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);
    end;
#endif

    [EventSubscriber(ObjectType::Page, Page::"Payment Reconciliation Journal", 'OnBeforeInvokePost', '', true, true)]
    local procedure LogTelemetryOnPaymentRecJournalOnBeforeInvokePost(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Match Confidence", BankAccReconciliationLine."Match Confidence"::"High - Text-to-Account Mapping");

        Session.LogMessage('0000AI8', StrSubstNo(BankAccountRecTextToAccountCountLbl, BankAccReconciliationLine.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Bank Acc. Reconciliation", 'OnAfterActionEvent', 'Transfer to General Journal', true, true)]
    local procedure LogTelemetryOnBankAccReconciliationAfterTransfToGJ(var Rec: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", Rec."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", Rec."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", Rec."Statement No.");
        BankAccReconciliationLine.SetFilter(Difference, '<>%1', 0);
        Session.LogMessage('0000AHW', StrSubstNo(BankAccountRecTransferToGJMsg, BankAccReconciliationLine.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Management", 'OnSendDailyTelemetry', '', true, true)]
    local procedure LogDatabaseWaitStatistics()
    begin
        Codeunit.Run(Codeunit::"Emit Database Wait Statistics");
        #if not CLEAN21
        Codeunit.Run(Codeunit::"Emit Enabled Features Signal");
        #endif
    end;
}

