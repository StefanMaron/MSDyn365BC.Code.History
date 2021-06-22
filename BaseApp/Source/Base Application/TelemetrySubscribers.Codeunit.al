codeunit 1351 "Telemetry Subscribers"
{
    Permissions = TableData "Permission Set Link" = r;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        ProfileChangedTelemetryMsg: Label 'Profile changed from %1 to %2.', Comment = '%1=Previous profile id, %2=New profile id';
        ProfileChangedTelemetryCategoryTxt: Label 'AL User Profile';
        NoSeriesCategoryTxt: Label 'AL NoSeries', Locked = true;
        NoSeriesEditedTelemetryTxt: Label 'The number series was changed by the user.', Locked = true;
        PermissionSetCategoryTxt: Label 'AL PermissionSet', Locked = true;
        PermissionSetLinkAddedTelemetryTxt: Label 'A Permission Set Link was added between Source Permission Set %1 and Permission Set %2. Total count of Permission Set Links are %3.', Locked = true;
        PermissionSetAddedTelemetryTxt: Label 'Permission Set %1 was added. Total count of user defined Permission Sets is %2.', Locked = true;
        PermissionSetAssignedToUserTelemetryTxt: Label 'Permission Set %1 was added to a user.', Locked = true;
        PermissionSetAssignedToUserGroupTelemetryTxt: Label 'Permission Set %1 was added to a user group %2.', Locked = true;
        EffectivePermsCalculatedTxt: Label 'Effective permissions were calculated for company %1, object type %2, object ID %3.', Locked = true, Comment = '%1 = company name, %2 = object type, %3 = object Id';
        TenantPermissionsChangedFromEffectivePermissionsPageTxt: Label 'Tenant permission set %1 was changed.', Locked = true, Comment = '%1 = permission set id';
        NumberOfDocumentLinesMsg: Label 'Type of Document: %1, Number of Document Lines: %2', Locked = true;
        RecordCountCategoryTxt: Label 'AL Record Count', Locked = true;
        JobQueueEntriesCategoryTxt: Label 'AL JobQueueEntries', Locked = true;
        JobQueueEntryStartedTxt: Label 'JobID = %1, ObjectType = %2, ObjectID = %3, Status = Started', Locked = true;
        JobQueueEntryStartedTransientTxt: Label 'JobID = %1, ObjectType = %2, ObjectID = %3, ParameterString = %4, Status = Started', Locked = true;
        JobQueueEntryFinishedTxt: Label 'JobID = %1, ObjectType = %2, ObjectID = %3, Status = Finished, Result = %4', Locked = true;
        JobQueueEntryFinishedTransientTxt: Label 'JobID = %1, ObjectType = %2, ObjectID = %3, ParameterString = %4, Status = Finished, Result = %5', Locked = true;
        JobQueueEntryEnqueuedTxt: Label 'JobID = %1, ObjectType = %2, ObjectID = %3, Recurring = %4, Status = %5', Locked = true;
        JobQueueEntryInsertedTxt: Label 'JobID = %1, ObjectType = %2, ObjectID = %3, Recurring = %4', Locked = true;
        UndoSalesShipmentCategoryTxt: Label 'AL UndoSalesShipmentNoOfLines', Locked = true;
        UndoSalesShipmentNoOfLinesTxt: Label 'UndoNoOfLines = %1', Locked = true;
        EmailLoggingTelemetryCategoryTxt: Label 'AL Email Logging', Locked = true;
        UserSettingUpEmailLoggingTxt: Label 'User is attempting to set up email logging via %1 page.', Locked = true;
        UserCompletedSettingUpEmailLoggingTxt: Label 'User completed the setting up of email logging via %1 page.', Locked = true;
        UserCreatingInteractionLogEntryBasedOnEmailTxt: Label 'User created an interaction log entry from an email message.', Locked = true;
        BankAccountRecCategoryLbl: Label 'AL Bank Account Rec', Locked = true;
        BankAccountRecPostedWithBankAccCurrencyCodeMsg: Label 'Bank Account Reconciliation posted with CurrencyCode set to: %1', Locked = true;
        BankAccountRecImportedBankStatementLinesCountMsg: Label 'Number of imported lines in bank statement: %1', Locked = true;
        BankAccountRecAutoMatchMsg: Label 'Total number of lines in the bank statement: %1; Total number of automatches: %2', Locked = true;
        BankAccountRecTextToAccountCountLbl: Label 'Number of lines where Text-To-Applied was used: %1', Locked = true;
        BankAccountRecTransferToGJMsg: Label 'Lines of Bank Statement to transfer to GJ: %1', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, 40, 'OnAfterCompanyOpen', '', true, true)]
    local procedure ScheduleMasterdataTelemetryAfterCompanyOpen()
    var
        CodeUnitMetadata: Record "CodeUnit Metadata";
        TelemetryManagement: Codeunit "Telemetry Management";
    begin
        if not IsSaaS then
            exit;

        CodeUnitMetadata.ID := CODEUNIT::"Generate Master Data Telemetry";
        TelemetryManagement.ScheduleCalEventsForTelemetryAsync(CodeUnitMetadata.RecordId, CODEUNIT::"Create Telemetry Cal. Events", 20);
    end;

    [EventSubscriber(ObjectType::Codeunit, 40, 'OnAfterCompanyOpen', '', true, true)]
    local procedure ScheduleActivityTelemetryAfterCompanyOpen()
    var
        CodeUnitMetadata: Record "CodeUnit Metadata";
        TelemetryManagement: Codeunit "Telemetry Management";
    begin
        if not IsSaaS then
            exit;

        CodeUnitMetadata.ID := CODEUNIT::"Generate Activity Telemetry";
        TelemetryManagement.ScheduleCalEventsForTelemetryAsync(CodeUnitMetadata.RecordId, CODEUNIT::"Create Telemetry Cal. Events", 21);
    end;

    [EventSubscriber(ObjectType::Codeunit, 9170, 'OnProfileChanged', '', true, true)]
    local procedure SendTraceOnProfileChanged(PrevAllProfile: Record "All Profile"; CurrentAllProfile: Record "All Profile")
    begin
        if not IsSaaS then
            exit;

        SendTraceTag(
          '00001O5', ProfileChangedTelemetryCategoryTxt, VERBOSITY::Normal, StrSubstNo(ProfileChangedTelemetryMsg, PrevAllProfile."Profile ID", CurrentAllProfile."Profile ID"),
          DATACLASSIFICATION::CustomerContent);
    end;

    [EventSubscriber(ObjectType::Page, 2340, 'OnAfterNoSeriesModified', '', true, true)]
    local procedure LogNoSeriesModifiedInvoicing()
    begin
        if not IsSaaS then
            exit;

        SendTraceTag('00001PI', NoSeriesCategoryTxt, VERBOSITY::Normal, NoSeriesEditedTelemetryTxt, DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Table, 9802, 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetLinkAdded(var Rec: Record "Permission Set Link"; RunTrigger: Boolean)
    var
        PermissionSetLink: Record "Permission Set Link";
    begin
        if not IsSaaS then
            exit;

        SendTraceTag(
          '0000250', PermissionSetCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(PermissionSetLinkAddedTelemetryTxt, Rec."Permission Set ID", Rec."Linked Permission Set ID", PermissionSetLink.Count),
          DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Table, 2000000165, 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnUserDefinedPermissionSetIsAdded(var Rec: Record "Tenant Permission Set"; RunTrigger: Boolean)
    var
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        if not IsSaaS then
            exit;

        if not IsNullGuid(Rec."App ID") then
            exit;

        TenantPermissionSet.SetRange("App ID", Rec."App ID");
        SendTraceTag(
          '0000251', PermissionSetCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(PermissionSetAddedTelemetryTxt, Rec."Role ID", TenantPermissionSet.Count), DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Table, 2000000053, 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnUserDefinedPermissionSetIsAssignedToAUser(var Rec: Record "Access Control"; RunTrigger: Boolean)
    var
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        if not IsSaaS then
            exit;

        if not IsNullGuid(Rec."App ID") then
            exit;

        if not TenantPermissionSet.Get(Rec."App ID", Rec."Role ID") then
            exit;

        SendTraceTag(
          '0000252', PermissionSetCategoryTxt, VERBOSITY::Normal, StrSubstNo(PermissionSetAssignedToUserTelemetryTxt, Rec."Role ID"),
          DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Table, 9003, 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnUserDefinedPermissionSetIsAssignedToAUserGroup(var Rec: Record "User Group Permission Set"; RunTrigger: Boolean)
    var
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        if not IsSaaS then
            exit;

        if not IsNullGuid(Rec."App ID") then
            exit;

        if not TenantPermissionSet.Get(Rec."App ID", Rec."Role ID") then
            exit;

        SendTraceTag(
          '0000253', PermissionSetCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(PermissionSetAssignedToUserGroupTelemetryTxt, Rec."Role ID", Rec."User Group Code"),
          DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Table, 472, 'OnAfterInsertEvent', '', false, false)]
    local procedure SendTraceOnAfterInsertJobQueueEntry(var Rec: Record "Job Queue Entry")
    begin
        if not IsSaaS() then
            exit;

        SendTraceTag('0000AIW', JobQueueEntriesCategoryTxt, Verbosity::Normal,
            StrSubstNo(JobQueueEntryInsertedTxt, Rec.ID, Rec."Object Type to Run", Rec."Object ID to Run", Rec."Recurring Job"),
            DataClassification::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Codeunit, 453, 'OnAfterEnqueueJobQueueEntry', '', false, false)]
    local procedure SendTraceOnAfterEnqueueJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
        if not IsSaaS() then
            exit;

        SendTraceTag('0000AIX', JobQueueEntriesCategoryTxt, Verbosity::Normal,
            StrSubstNo(JobQueueEntryEnqueuedTxt, JobQueueEntry.ID, JobQueueEntry."Object Type to Run", JobQueueEntry."Object ID to Run", JobQueueEntry."Recurring Job", JobQueueEntry.Status),
            DataClassification::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Codeunit, 448, 'OnBeforeExecuteJob', '', false, false)]
    local procedure SendTraceOnJobQueueEntryStarted(var JobQueueEntry: Record "Job Queue Entry")
    begin
        if not IsSaaS then
            exit;

        SendTraceTag(
          '000082B', JobQueueEntriesCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(JobQueueEntryStartedTxt, JobQueueEntry.ID, JobQueueEntry."Object Type to Run", JobQueueEntry."Object ID to Run"),
          DATACLASSIFICATION::SystemMetadata);
        SendTraceTag(
          '0000AEE', JobQueueEntriesCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(JobQueueEntryStartedTransientTxt, JobQueueEntry.ID, JobQueueEntry."Object Type to Run", JobQueueEntry."Object ID to Run", JobQueueEntry."Parameter String"),
          DATACLASSIFICATION::CustomerContent);
    end;

    [EventSubscriber(ObjectType::Codeunit, 448, 'OnAfterExecuteJob', '', false, false)]
    local procedure SendTraceOnJobQueueEntryFinished(var JobQueueEntry: Record "Job Queue Entry"; WasSuccess: Boolean)
    var
        Result: Text[10];
    begin
        if not IsSaaS then
            exit;

        if WasSuccess then
            Result := 'Success'
        else
            Result := 'Fail';

        SendTraceTag(
          '000082C', JobQueueEntriesCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(JobQueueEntryFinishedTxt, JobQueueEntry.ID, JobQueueEntry."Object Type to Run",
            JobQueueEntry."Object ID to Run", Result),
          DATACLASSIFICATION::SystemMetadata);
        SendTraceTag(
          '0000AEF', JobQueueEntriesCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(JobQueueEntryFinishedTransientTxt, JobQueueEntry.ID, JobQueueEntry."Object Type to Run",
            JobQueueEntry."Object ID to Run", JobQueueEntry."Parameter String", Result),
          DATACLASSIFICATION::CustomerContent);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5815, 'OnAfterCode', '', false, false)]
    local procedure SendTraceUndoSalesShipmentNoOfLines(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
        if not IsSaaS then
            exit;

        SalesShipmentLine.SetRange(Correction, true);
        SendTraceTag('000085N', UndoSalesShipmentCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(UndoSalesShipmentNoOfLinesTxt, SalesShipmentLine.Count),
          DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Page, 9852, 'OnEffectivePermissionsPopulated', '', true, true)]
    local procedure EffectivePermissionsFetchedInPage(CurrUserId: Guid; CurrCompanyName: Text[30]; CurrObjectType: Integer; CurrObjectId: Integer)
    begin
        if not IsSaaS then
            exit;

        SendTraceTag(
          '000027E', PermissionSetCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(EffectivePermsCalculatedTxt, CurrCompanyName, CurrObjectType, CurrObjectId),
          DATACLASSIFICATION::OrganizationIdentifiableInformation);
    end;

    [EventSubscriber(ObjectType::Codeunit, 9852, 'OnTenantPermissionModified', '', true, true)]
    local procedure EffectivePermissionsChangeInPage(PermissionSetId: Code[20])
    begin
        if not IsSaaS then
            exit;

        SendTraceTag(
          '000027G', PermissionSetCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(TenantPermissionsChangedFromEffectivePermissionsPageTxt, PermissionSetId),
          DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Codeunit, 91, 'OnAfterConfirmPost', '', true, true)]
    local procedure LogNumberOfPurchaseLines(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        DocumentType: Integer;
    begin
        DocumentType := PurchaseHeader."Document Type";

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");

        SendTraceTag('000085T', RecordCountCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(NumberOfDocumentLinesMsg, Format(DocumentType), PurchaseLine.Count), DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Codeunit, 81, 'OnAfterConfirmPost', '', true, true)]
    local procedure LogNumberOfSalesLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        DocumentType: Integer;
    begin
        DocumentType := SalesHeader."Document Type";

        SalesLine.SetRange("Document No.", SalesHeader."No.");

        SendTraceTag('000085U', RecordCountCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(NumberOfDocumentLinesMsg, Format(DocumentType), SalesLine.Count), DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Report, 1306, 'OnAfterGetSalesHeader', '', true, true)]
    local procedure LogNumberOfSalesInvoiceLinesForReport1306(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        LogNumberOfSalesInvoiceLines(SalesInvoiceHeader);
    end;

    [EventSubscriber(ObjectType::Report, 206, 'OnAfterGetRecordSalesInvoiceHeader', '', true, true)]
    local procedure LogNumberOfSalesInvoiceLinesForReport206(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        LogNumberOfSalesInvoiceLines(SalesInvoiceHeader);
    end;

    local procedure LogNumberOfSalesInvoiceLines(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SendTraceTag('000085V', RecordCountCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(NumberOfDocumentLinesMsg, 'Sales Invoice - export', SalesInvoiceLine.Count), DATACLASSIFICATION::SystemMetadata);
    end;

    local procedure IsSaaS(): Boolean
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        exit(EnvironmentInfo.IsSaaS);
    end;

    [EventSubscriber(ObjectType::Page, 1811, 'OnOpenPageEvent', '', false, false)]
    local procedure LogTelemetryOnOpenSetupEmailLoggingPage()
    var
        SetupEmailLogging: Page "Setup Email Logging";
    begin
        SendTraceTag(
          '000089V', EmailLoggingTelemetryCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(UserSettingUpEmailLoggingTxt, SetupEmailLogging.Caption), DATACLASSIFICATION::SystemMetadata)
    end;

    [EventSubscriber(ObjectType::Page, 1811, 'OnAfterAssistedSetupEmailLoggingCompleted', '', false, false)]
    local procedure LogTelemetryOnAfterAssistedSetupEmailLoggingCompleted()
    var
        SetupEmailLogging: Page "Setup Email Logging";
    begin
        SendTraceTag(
          '000089W', EmailLoggingTelemetryCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(UserCompletedSettingUpEmailLoggingTxt, SetupEmailLogging.Caption), DATACLASSIFICATION::SystemMetadata)
    end;

    [EventSubscriber(ObjectType::Page, 5094, 'OnAfterMarketingSetupEmailLoggingUsed', '', false, false)]
    local procedure LogTelemetryOnAfterMarketingSetupEmailLoggingUsed()
    var
        MarketingSetup: Page "Marketing Setup";
    begin
        SendTraceTag(
          '000089X', EmailLoggingTelemetryCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(UserSettingUpEmailLoggingTxt, MarketingSetup.Caption), DATACLASSIFICATION::SystemMetadata)
    end;

    [EventSubscriber(ObjectType::Page, 5094, 'OnAfterMarketingSetupEmailLoggingCompleted', '', false, false)]
    local procedure LogTelemetryOnAfterMarketingSetupEmailLoggingCompleted()
    var
        MarketingSetup: Page "Marketing Setup";
    begin
        SendTraceTag(
          '000089Y', EmailLoggingTelemetryCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(UserCompletedSettingUpEmailLoggingTxt, MarketingSetup.Caption), DATACLASSIFICATION::SystemMetadata)
    end;

    [EventSubscriber(ObjectType::Codeunit, 5064, 'OnAfterInsertInteractionLogEntry', '', false, false)]
    local procedure LogTelemetryOnAfterInsertInteractionLogEntry()
    begin
        SendTraceTag(
          '000089Z', EmailLoggingTelemetryCategoryTxt, VERBOSITY::Normal,
          UserCreatingInteractionLogEntryBasedOnEmailTxt, DATACLASSIFICATION::SystemMetadata)
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Bank Acc. Reconciliation Post", 'OnAfterFinalizePost', '', true, true)]
    local procedure LogTelemetryOnBankAccRecPostOnAfterFinalizePost(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccount: Record "Bank Account";
    begin
        with BankAccount do begin
            Get(BankAccReconciliation."Bank Account No.");
            SendTraceTag('0000AHX', BankAccountRecCategoryLbl, VERBOSITY::Normal, StrSubstNo(BankAccountRecPostedWithBankAccCurrencyCodeMsg, BankAccount."Currency Code"), DATACLASSIFICATION::SystemMetadata);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Process Bank Acc. Rec Lines", 'OnAfterImportBankStatement', '', true, true)]
    local procedure LogTelemetryOnBankAccRecOnAfterImportBankStatement(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; DataExch: Record "Data Exch.")
    begin
        SendTraceTag('0000AHY', BankAccountRecCategoryLbl, VERBOSITY::Normal, StrSubstNo(BankAccountRecImportedBankStatementLinesCountMsg, DataExch.Count), DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Match Bank Rec. Lines", 'OnAfterMatchBankRecLinesMatchSingle', '', true, true)]
    local procedure LogTelemetryOnAfterMatchBankRecLinesMatchSingle(CountMatchCandidates: Integer; TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer")
    begin
        SendTraceTag('0000AHZ', BankAccountRecCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(BankAccountRecAutoMatchMsg, CountMatchCandidates, TempBankStatementMatchingBuffer.Count),
          DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Payment Reconciliation Journal", 'OnBeforeInvokePost', '', true, true)]
    local procedure LogTelemetryOnPaymentRecJournalOnBeforeInvokePost(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Match Confidence", BankAccReconciliationLine."Match Confidence"::"High - Text-to-Account Mapping");

        SendTraceTag('0000AI8', BankAccountRecCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(BankAccountRecTextToAccountCountLbl, BankAccReconciliationLine.Count), DATACLASSIFICATION::SystemMetadata);
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
        SendTraceTag('0000AHW', BankAccountRecCategoryLbl, VERBOSITY::Normal,
            StrSubstNo(BankAccountRecTransferToGJMsg, BankAccReconciliationLine.Count), DATACLASSIFICATION::SystemMetadata);
    end;
}

