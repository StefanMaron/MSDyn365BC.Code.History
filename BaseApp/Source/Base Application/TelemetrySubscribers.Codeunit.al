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
        JobQueueEntryFinishedTxt: Label 'JobID = %1, ObjectType = %2, ObjectID = %3, Status = Finished, Result = %4', Locked = true;
        JobQueueEntryEnqueuedTxt: Label 'JobID = %1, ObjectType = %2, ObjectID = %3, Recurring = %4, Status = %5', Locked = true;
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
        PurchaseDocumentInformationLbl: Label 'Purchase document information', Locked = true;
        SalesDocumentInformationLbl: Label 'Sales document information', Locked = true;
        SalesInvoiceInformationLbl: Label 'Sales invoice information', Locked = true;
        EmailCategoryLbl: Label 'Email', Locked = true;
        UserPlansTelemetryLbl: Label 'User with %1 plans opened the %2 page.', Comment = '%1 - User plans; %2 - page name', Locked = true;

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

        Session.LogMessage('00001O5', StrSubstNo(ProfileChangedTelemetryMsg, PrevAllProfile."Profile ID", CurrentAllProfile."Profile ID"), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', ProfileChangedTelemetryCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Page, 2340, 'OnAfterNoSeriesModified', '', true, true)]
    local procedure LogNoSeriesModifiedInvoicing()
    begin
        if not IsSaaS then
            exit;

        Session.LogMessage('00001PI', NoSeriesEditedTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', NoSeriesCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Table, 9802, 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetLinkAdded(var Rec: Record "Permission Set Link"; RunTrigger: Boolean)
    var
        PermissionSetLink: Record "Permission Set Link";
    begin
        if not IsSaaS then
            exit;

        Session.LogMessage('0000250', StrSubstNo(PermissionSetLinkAddedTelemetryTxt, Rec."Permission Set ID", Rec."Linked Permission Set ID", PermissionSetLink.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PermissionSetCategoryTxt);
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
        Session.LogMessage('0000251', StrSubstNo(PermissionSetAddedTelemetryTxt, Rec."Role ID", TenantPermissionSet.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PermissionSetCategoryTxt);
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

        Session.LogMessage('0000252', StrSubstNo(PermissionSetAssignedToUserTelemetryTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PermissionSetCategoryTxt);
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

        Session.LogMessage('0000253', StrSubstNo(PermissionSetAssignedToUserGroupTelemetryTxt, Rec."Role ID", Rec."User Group Code"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PermissionSetCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, 453, 'OnAfterEnqueueJobQueueEntry', '', false, false)]
    local procedure SendTraceOnAfterEnqueueJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
        if not IsSaaS() then
            exit;

        Session.LogMessage('0000AIX', StrSubstNo(JobQueueEntryEnqueuedTxt, JobQueueEntry.ID, JobQueueEntry."Object Type to Run", JobQueueEntry."Object ID to Run", JobQueueEntry."Recurring Job", JobQueueEntry.Status), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', JobQueueEntriesCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, 448, 'OnBeforeExecuteJob', '', false, false)]
    local procedure SendTraceOnJobQueueEntryStarted(var JobQueueEntry: Record "Job Queue Entry")
    begin
        if not IsSaaS then
            exit;

        Session.LogMessage('000082B', StrSubstNo(JobQueueEntryStartedTxt, JobQueueEntry.ID, JobQueueEntry."Object Type to Run", JobQueueEntry."Object ID to Run"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', JobQueueEntriesCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, 448, 'OnAfterExecuteJob', '', false, false)]
    local procedure SendTraceOnJobQueueEntryFinished(var JobQueueEntry: Record "Job Queue Entry"; WasSuccess: Boolean)
    var
        Language: Codeunit Language;
        TranslationHelper: Codeunit "Translation Helper";
        Result: Text[10];
    begin
        if not IsSaaS then
            exit;

        if WasSuccess then
            Result := 'Success'
        else
            Result := 'Fail';

        TranslationHelper.SetGlobalLanguageById(Language.GetDefaultApplicationLanguageId());

        Session.LogMessage('000082C', StrSubstNo(JobQueueEntryFinishedTxt, JobQueueEntry.ID, JobQueueEntry."Object Type to Run",
            JobQueueEntry."Object ID to Run", Result), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', JobQueueEntriesCategoryTxt);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Codeunit, 5815, 'OnAfterCode', '', false, false)]
    local procedure SendTraceUndoSalesShipmentNoOfLines(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
        if not IsSaaS then
            exit;

        SalesShipmentLine.SetRange(Correction, true);
        Session.LogMessage('000085N', StrSubstNo(UndoSalesShipmentNoOfLinesTxt, SalesShipmentLine.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', UndoSalesShipmentCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Page, 9852, 'OnEffectivePermissionsPopulated', '', true, true)]
    local procedure EffectivePermissionsFetchedInPage(CurrUserId: Guid; CurrCompanyName: Text[30]; CurrObjectType: Integer; CurrObjectId: Integer)
    begin
        if not IsSaaS then
            exit;

        Session.LogMessage('000027E', StrSubstNo(EffectivePermsCalculatedTxt, CurrCompanyName, CurrObjectType, CurrObjectId), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PermissionSetCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, 9852, 'OnTenantPermissionModified', '', true, true)]
    local procedure EffectivePermissionsChangeInPage(PermissionSetId: Code[20])
    begin
        if not IsSaaS then
            exit;

        Session.LogMessage('000027G', StrSubstNo(TenantPermissionsChangedFromEffectivePermissionsPageTxt, PermissionSetId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PermissionSetCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, 91, 'OnAfterConfirmPost', '', true, true)]
    local procedure LogNumberOfPurchaseLines(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        DocumentType: Integer;
        Attributes: Dictionary of [Text, Text];
    begin
        DocumentType := PurchaseHeader."Document Type".AsInteger();

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");

        Attributes.Add('Document Type', Format(DocumentType));
        Attributes.Add('Number of lines', Format(PurchaseLine.Count()));
        Session.LogMessage('0000CST', PurchaseDocumentInformationLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Attributes);
    end;

    [EventSubscriber(ObjectType::Codeunit, 81, 'OnAfterConfirmPost', '', true, true)]
    local procedure LogNumberOfSalesLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        DocumentType: Integer;
        Attributes: Dictionary of [Text, Text];
    begin
        DocumentType := SalesHeader."Document Type".AsInteger();

        SalesLine.SetRange("Document No.", SalesHeader."No.");

        Session.LogMessage('000085U', StrSubstNo(NumberOfDocumentLinesMsg, Format(DocumentType), SalesLine.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RecordCountCategoryTxt);

        Attributes.Add('Document Type', Format(DocumentType));
        Attributes.Add('Number of lines', Format(SalesLine.Count()));
        Session.LogMessage('0000CSU', SalesDocumentInformationLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Attributes);
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
        Attributes: Dictionary of [Text, Text];
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");

        Session.LogMessage('000085V', StrSubstNo(NumberOfDocumentLinesMsg, 'Sales Invoice - export', SalesInvoiceLine.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RecordCountCategoryTxt);

        Attributes.Add('Number of lines', Format(SalesInvoiceLine.Count()));
        Session.LogMessage('0000CZ0', SalesInvoiceInformationLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Attributes);
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
        Session.LogMessage('000089V', StrSubstNo(UserSettingUpEmailLoggingTxt, SetupEmailLogging.Caption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
    end;

    [EventSubscriber(ObjectType::Page, 1811, 'OnAfterAssistedSetupEmailLoggingCompleted', '', false, false)]
    local procedure LogTelemetryOnAfterAssistedSetupEmailLoggingCompleted()
    var
        SetupEmailLogging: Page "Setup Email Logging";
    begin
        Session.LogMessage('000089W', StrSubstNo(UserCompletedSettingUpEmailLoggingTxt, SetupEmailLogging.Caption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
    end;

    [EventSubscriber(ObjectType::Page, 5094, 'OnAfterMarketingSetupEmailLoggingUsed', '', false, false)]
    local procedure LogTelemetryOnAfterMarketingSetupEmailLoggingUsed()
    var
        MarketingSetup: Page "Marketing Setup";
    begin
        Session.LogMessage('000089X', StrSubstNo(UserSettingUpEmailLoggingTxt, MarketingSetup.Caption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
    end;

    [EventSubscriber(ObjectType::Page, 5094, 'OnAfterMarketingSetupEmailLoggingCompleted', '', false, false)]
    local procedure LogTelemetryOnAfterMarketingSetupEmailLoggingCompleted()
    var
        MarketingSetup: Page "Marketing Setup";
    begin
        Session.LogMessage('000089Y', StrSubstNo(UserCompletedSettingUpEmailLoggingTxt, MarketingSetup.Caption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
    end;

    [EventSubscriber(ObjectType::Codeunit, 5064, 'OnAfterInsertInteractionLogEntry', '', false, false)]
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

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Process Bank Acc. Rec Lines", 'OnAfterImportBankStatement', '', true, true)]
    local procedure LogTelemetryOnBankAccRecOnAfterImportBankStatement(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; DataExch: Record "Data Exch.")
    begin
        Session.LogMessage('0000AHY', StrSubstNo(BankAccountRecImportedBankStatementLinesCountMsg, DataExch.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Match Bank Rec. Lines", 'OnAfterMatchBankRecLinesMatchSingle', '', true, true)]
    local procedure LogTelemetryOnAfterMatchBankRecLinesMatchSingle(CountMatchCandidates: Integer; TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer")
    begin
        Session.LogMessage('0000AHZ', StrSubstNo(BankAccountRecAutoMatchMsg, CountMatchCandidates, TempBankStatementMatchingBuffer.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);
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

    [EventSubscriber(ObjectType::Page, Page::"Sent Emails", 'OnOpenPageEvent', '', false, false)]
    local procedure LogUserPlansOnOpenSentEmails()
    begin
        Session.LogMessage('0000CTU', StrSubstNo(UserPlansTelemetryLbl, GetUserPlans(), 'Sent Emails'), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Email Outbox", 'OnOpenPageEvent', '', false, false)]
    local procedure LogUserPlansOnOpenEmailOutbox()
    begin
        Session.LogMessage('0000CTT', StrSubstNo(UserPlansTelemetryLbl, GetUserPlans(), 'Email Oubox'), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Email Account Wizard", 'OnOpenPageEvent', '', false, false)]
    local procedure LogUserPlansOnOpenEmailAccountWizard()
    begin
        Session.LogMessage('0000CTJ', StrSubstNo(UserPlansTelemetryLbl, GetUserPlans(), 'Email Account Wizard'), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);
    end;

    local procedure GetUserPlans(): Text
    var
        AzureADPlan: Codeunit "Azure AD Plan";
        UserPlans: List of [Text];
        UserPlan: Text;
        ConcatenatedUserPlans: Text;
        Delimiter: Text;
    begin
        AzureADPlan.GetPlanNames(UserSecurityId(), UserPlans);

        ConcatenatedUserPlans := '';
        Delimiter := ' | ';
        foreach UserPlan in UserPlans do
            ConcatenatedUserPlans += UserPlan + Delimiter;

        ConcatenatedUserPlans := '[' + ConcatenatedUserPlans.TrimEnd(Delimiter) + ']';
        exit(ConcatenatedUserPlans);
    end;
}

