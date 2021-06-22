codeunit 5465 "Graph Mgt - General Tools"
{
    Permissions = TableData "Sales Invoice Header" = rimd,
                  TableData "Sales Cr.Memo Header" = rimd,
                  TableData "Purch. Inv. Header" = rimd;

    trigger OnRun()
    begin
        ApiSetup;
    end;

    var
        CannotChangeIDErr: Label 'Value of Id is immutable.', Locked = true;
        CannotChangeLastDateTimeModifiedErr: Label 'Value of LastDateTimeModified is immutable.', Locked = true;
        MissingFieldValueErr: Label '%1 must be specified.', Locked = true;
        AggregateErrorTxt: Label 'AL APIAggregate', Locked = true;
        AggregateIsMissingMainRecordTxt: Label 'Aggregate does not have main record.', Locked = true;

    [Scope('OnPrem')]
    procedure GetMandatoryStringPropertyFromJObject(var JsonObject: DotNet JObject; PropertyName: Text; var PropertyValue: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        Found: Boolean;
    begin
        Found := JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, PropertyName, PropertyValue);
        if not Found then
            Error(MissingFieldValueErr, PropertyName);
    end;

    procedure UpdateIntegrationRecords(var SourceRecordRef: RecordRef; FieldNumber: Integer; OnlyRecordsWithoutID: Boolean)
    var
        IntegrationRecord: Record "Integration Record";
        UpdatedIntegrationRecord: Record "Integration Record";
        IntegrationManagement: Codeunit "Integration Management";
        FilterFieldRef: FieldRef;
        IDFieldRef: FieldRef;
        NullGuid: Guid;
    begin
        if OnlyRecordsWithoutID then begin
            FilterFieldRef := SourceRecordRef.Field(FieldNumber);
            FilterFieldRef.SetRange(NullGuid);
        end;

        if SourceRecordRef.FindSet then
            repeat
                IDFieldRef := SourceRecordRef.Field(FieldNumber);
                if not IntegrationRecord.Get(IDFieldRef.Value) then begin
                    IntegrationManagement.InsertUpdateIntegrationRecord(SourceRecordRef, CurrentDateTime);
                    if IsNullGuid(Format(IDFieldRef.Value)) then begin
                        UpdatedIntegrationRecord.SetRange("Record ID", SourceRecordRef.RecordId);
                        UpdatedIntegrationRecord.FindFirst;
                        IDFieldRef.Value := IntegrationManagement.GetIdWithoutBrackets(UpdatedIntegrationRecord."Integration ID");
                    end;

                    SourceRecordRef.Modify(false);
                end;
            until SourceRecordRef.Next = 0;
    end;

    procedure HandleUpdateReferencedIdFieldOnItem(var RecRef: RecordRef; NewId: Guid; var Handled: Boolean; DatabaseNumber: Integer; RecordFieldNumber: Integer)
    var
        IdFieldRef: FieldRef;
    begin
        if Handled then
            exit;

        if RecRef.Number <> DatabaseNumber then
            exit;

        IdFieldRef := RecRef.Field(RecordFieldNumber);
        IdFieldRef.Value(NewId);

        Handled := true;
    end;

    [Scope('OnPrem')]
    procedure InsertOrUpdateODataType(NewKey: Code[50]; NewDescription: Text[250]; OdmDefinition: Text)
    var
        ODataEdmType: Record "OData Edm Type";
        ODataOutStream: OutStream;
        RecordExist: Boolean;
    begin
        if not ODataEdmType.WritePermission then
            exit;

        RecordExist := ODataEdmType.Get(NewKey);

        if not RecordExist then begin
            Clear(ODataEdmType);
            ODataEdmType.Key := NewKey;
        end;

        ODataEdmType.Validate(Description, NewDescription);
        ODataEdmType."Edm Xml".CreateOutStream(ODataOutStream, TEXTENCODING::UTF8);
        ODataOutStream.WriteText(OdmDefinition);

        if RecordExist then
            ODataEdmType.Modify(true)
        else
            ODataEdmType.Insert(true);
    end;

    [Scope('Cloud')]
    procedure ProcessNewRecordFromAPI(var InsertedRecordRef: RecordRef; var TempFieldSet: Record "Field"; ModifiedDateTime: DateTime)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        IntegrationManagement: Codeunit "Integration Management";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        UpdatedRecRef: RecordRef;
    begin
        if not ConfigTmplSelectionRules.FindTemplateBasedOnRecordFields(InsertedRecordRef, ConfigTemplateHeader) then
            exit;

        if ConfigTemplateManagement.ApplyTemplate(InsertedRecordRef, TempFieldSet, UpdatedRecRef, ConfigTemplateHeader) then
            InsertedRecordRef := UpdatedRecRef.Duplicate;

        IntegrationManagement.InsertUpdateIntegrationRecord(InsertedRecordRef, ModifiedDateTime);
    end;

    procedure ErrorIdImmutable()
    begin
        Error(CannotChangeIDErr);
    end;

    procedure ErrorLastDateTimeModifiedImmutable()
    begin
        Error(CannotChangeLastDateTimeModifiedErr);
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure ApiSetup()
    begin
    end;

    procedure IsApiEnabled(): Boolean
    var
        ServerSetting: Codeunit "Server Setting";
        Handled: Boolean;
        IsAPIEnabled: Boolean;
    begin
        OnGetIsAPIEnabled(Handled, IsAPIEnabled);
        if Handled then
            exit(IsAPIEnabled);

        exit(ServerSetting.GetApiServicesEnabled);
    end;

    procedure IsApiSubscriptionEnabled(): Boolean
    var
        ServerSetting: Codeunit "Server Setting";
        Handled: Boolean;
        APISubscriptionsEnabled: Boolean;
    begin
        if not IsApiEnabled then
            exit(false);

        OnGetAPISubscriptionsEnabled(Handled, APISubscriptionsEnabled);
        if Handled then
            exit(APISubscriptionsEnabled);

        exit(ServerSetting.GetApiSubscriptionsEnabled);
    end;

    procedure APISetupIfEnabled()
    begin
        if IsApiEnabled then
            ApiSetup;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5150, 'OnGetIntegrationActivated', '', false, false)]
    local procedure OnGetIntegrationActivated(var IsSyncEnabled: Boolean)
    var
        ApiWebService: Record "Api Web Service";
        ODataEdmType: Record "OData Edm Type";
        ForceIsApiEnabledVerification: Boolean;
    begin
        OnForceIsApiEnabledVerification(ForceIsApiEnabledVerification);

        if not ForceIsApiEnabledVerification and IsSyncEnabled then
            exit;

        if ForceIsApiEnabledVerification then
            if not IsApiEnabled then
                exit;

        if not ApiWebService.ReadPermission then
            exit;

        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Page);
        ApiWebService.SetRange(Published, true);
        if ApiWebService.IsEmpty then
            exit;
        if not ODataEdmType.ReadPermission then
            exit;

        IsSyncEnabled := not ODataEdmType.IsEmpty;
    end;

    procedure TranslateNAVCurrencyCodeToCurrencyCode(var CachedLCYCurrencyCode: Code[10]; CurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        if CachedLCYCurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            CachedLCYCurrencyCode := GeneralLedgerSetup."LCY Code";
        end;

        exit(CachedLCYCurrencyCode);
    end;

    procedure TranslateCurrencyCodeToNAVCurrencyCode(var CachedLCYCurrencyCode: Code[10]; CurrentCurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrentCurrencyCode = '' then
            exit('');

        // Update LCY cache
        if CachedLCYCurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            CachedLCYCurrencyCode := GeneralLedgerSetup."LCY Code";
        end;

        if CachedLCYCurrencyCode = CurrentCurrencyCode then
            exit('');

        exit(CurrentCurrencyCode);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2, 'OnCompanyInitialize', '', true, true)]
    local procedure InitDemoCompanyApisForSaaS()
    var
        CompanyInformation: Record "Company Information";
        APIEntitiesSetup: Record "API Entities Setup";
        EnvironmentInfo: Codeunit "Environment Information";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if not EnvironmentInfo.IsSaaS then
            exit;

        if not CompanyInformation.Get then
            exit;

        if not CompanyInformation."Demo Company" then
            exit;

        APIEntitiesSetup.SafeGet;

        if APIEntitiesSetup."Demo Company API Initialized" then
            exit;

        GraphMgtGeneralTools.ApiSetup;

        APIEntitiesSetup.SafeGet;
        APIEntitiesSetup.Validate("Demo Company API Initialized", true);
        APIEntitiesSetup.Modify(true);
    end;

    procedure TransferRelatedRecordIntegrationIDs(var OriginalRecordRef: RecordRef; var UpdatedRecordRef: RecordRef; var TempRelatedRecodIdsField: Record "Field")
    var
        OriginalFieldRef: FieldRef;
        UpdatedFieldRef: FieldRef;
    begin
        // We cannot use GETTABLE to set values back e.g. RecRef.GETTABLE(Customer) since it will interupt Insert/Modify transaction.
        // The Insert and Modify triggers will not run. We can assign the fields via FieldRef.
        if not TempRelatedRecodIdsField.FindFirst then
            exit;

        repeat
            OriginalFieldRef := OriginalRecordRef.Field(TempRelatedRecodIdsField."No.");
            UpdatedFieldRef := UpdatedRecordRef.Field(TempRelatedRecodIdsField."No.");
            OriginalFieldRef.Value := UpdatedFieldRef.Value;
        until TempRelatedRecodIdsField.Next = 0;
    end;

    procedure CleanAggregateWithoutParent(MainRecordVariant: Variant)
    var
        MainRecordRef: RecordRef;
    begin
        MainRecordRef.GetTable(MainRecordVariant);
        MainRecordRef.Delete();
        SendTraceTag(
          '00001QW', AggregateErrorTxt, VERBOSITY::Error, AggregateIsMissingMainRecordTxt, DATACLASSIFICATION::SystemMetadata);
    end;

    procedure StripBrackets(StringWithBrackets: Text): Text
    begin
        if StrPos(StringWithBrackets, '{') = 1 then
            exit(CopyStr(Format(StringWithBrackets), 2, 36));
        exit(StringWithBrackets);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetIsAPIEnabled(var Handled: Boolean; var IsAPIEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAPISubscriptionsEnabled(var Handled: Boolean; var APISubscriptionsEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForceIsApiEnabledVerification(var ForceIsApiEnabledVerification: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, 8618, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteConfigTemplates(var Rec: Record "Config. Template Header"; RunTrigger: Boolean)
    var
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
    begin
        if RunTrigger then begin
            ConfigTmplSelectionRules.SetRange("Template Code", Rec.Code);
            ConfigTmplSelectionRules.DeleteAll();
        end;
    end;
}

