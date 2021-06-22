codeunit 6153 "API Webhook Notification Mgt."
{
    // Registers notifications in table API Webhook Notification on entity insert, modify, rename and delete

    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        IntegrationManagement: Codeunit "Integration Management";
        APIWebhookCategoryLbl: Label 'AL API Webhook', Locked = true;
        JobQueueCategoryCodeLbl: Label 'APIWEBHOOK', Locked = true;
        JobQueueCategoryDescLbl: Label 'Send API Webhook Notifications';
        CreateNotificationMsg: Label 'Create new notification. Subscription expiration time: %1. Source table: %2. Last modified time: %3. Change type: %4. Notification ID: %5.', Locked = true;
        CannotCreateNotificationErr: Label 'Cannot create new notification. Subscription expiration time: %1. Source table: %2. Last modified time: %3. Change type: %4.', Locked = true;
        FilterMatchingMsg: Label 'The record in table %1 is matching the filter in %2 %3.', Locked = true;
        FilterMismatchingMsg: Label 'The record in table %1 is mismatching the filter in %2 %3.', Locked = true;
        DeleteSubscriptionMsg: Label 'Delete subscription. Subscription expiration time: %1. Source table: %2.', Locked = true;
        DeleteObsoleteOrUnsupportedSubscriptionMsg: Label 'Delete subscription for an obsolete or unsupported entity.', Locked = true;
        UnsupportedFieldTypeErr: Label 'The %1 field in the %2 table is of an unsupported type.', Locked = true;
        ChangeTypeOption: Option Created,Updated,Deleted,Collection;
        CachedApiSubscriptionEnabled: Boolean;
        FindingEntityMsg: Label 'Finding entity for subscription. Subscription expiration time: %1. Source table: %2.', Locked = true;
        CannotFindEntityErr: Label 'Cannot find entity. Table: %1.', Locked = true;
        TemporarySourceTableErr: Label 'No support for entities with a temporary source table. Table: %1.', Locked = true;
        CompositeEntityKeyErr: Label 'No support for entities with a composite key. Fields: %1. Table: %2.', Locked = true;
        IncorrectEntityKeyErr: Label 'Incorrect entity key. Fields: %1. Table: %2.', Locked = true;
        ScheduleJobMsg: Label 'Schedule job. Processing time: %1. Earliest start time: %2. Latest start time: %3.', Locked = true;
        ReadyJobExistsMsg: Label 'Ready job exists. Earliest start time: %1.', Locked = true;
        CreateJobCategoryMsg: Label 'Create new job category.', Locked = true;
        CreateJobMsg: Label 'Create new job. Earliest start time: %1.', Locked = true;
        UseCachedApiSubscriptionEnabled: Boolean;
        TooManyJobsMsg: Label 'New job is not created. Count of jobs cannot exceed %1.', Locked = true;
        FieldTok: Label 'Field', Locked = true;
        EqConstTok: Label '=CONST(', Locked = true;
        EqFilterTok: Label '=FILTER(', Locked = true;

    [Scope('OnPrem')]
    procedure OnDatabaseInsert(var RecRef: RecordRef)
    begin
        ProcessSubscriptions(RecRef, ChangeTypeOption::Created);
    end;

    [Scope('OnPrem')]
    procedure OnDatabaseModify(var RecRef: RecordRef)
    begin
        ProcessSubscriptions(RecRef, ChangeTypeOption::Updated);
    end;

    [Scope('OnPrem')]
    procedure OnDatabaseDelete(var RecRef: RecordRef)
    begin
        ProcessSubscriptions(RecRef, ChangeTypeOption::Deleted);
    end;

    [Scope('OnPrem')]
    procedure OnDatabaseRename(var RecRef: RecordRef; var xRecRef: RecordRef)
    begin
        ProcessSubscriptionsOnRename(RecRef, xRecRef);
    end;

    local procedure ProcessSubscriptions(var RecRef: RecordRef; ChangeType: Option)
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        ScheduleJobQueue: Boolean;
        EarliestStartDateTime: DateTime;
    begin
        if RecRef.IsTemporary then
            exit;

        if not GetSubscriptions(APIWebhookSubscription, RecRef.Number) then
            exit;

        repeat
            if ProcessSubscription(RecRef, APIWebhookSubscription, ChangeType) then
                ScheduleJobQueue := true;
        until APIWebhookSubscription.Next() = 0;

        if ScheduleJobQueue then begin
            EarliestStartDateTime := CurrentDateTime();
            ScheduleJob(EarliestStartDateTime);
        end;
    end;

    local procedure ProcessSubscription(var RecRef: RecordRef; var APIWebhookSubscription: Record "API Webhook Subscription"; ChangeType: Option): Boolean
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
    begin
        if not GetEntity(APIWebhookSubscription, ApiWebhookEntity) then begin
            SendTraceTag('000024M', APIWebhookCategoryLbl, VERBOSITY::Warning, DeleteObsoleteOrUnsupportedSubscriptionMsg,
              DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;

        if CheckTableFilters(ApiWebhookEntity, RecRef) then
            exit(RegisterNotification(ApiWebhookEntity, APIWebhookSubscription, RecRef, ChangeType));

        exit(false);
    end;

    local procedure ProcessSubscriptionsOnRename(var RecRef: RecordRef; var xRecRef: RecordRef)
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        ScheduleJobQueue: Boolean;
        EarliestStartDateTime: DateTime;
    begin
        if RecRef.IsTemporary then
            exit;

        if not GetSubscriptions(APIWebhookSubscription, RecRef.Number) then
            exit;

        repeat
            if ProcessSubscriptionOnRename(RecRef, xRecRef, APIWebhookSubscription) then
                ScheduleJobQueue := true;
        until APIWebhookSubscription.Next() = 0;

        if ScheduleJobQueue then begin
            EarliestStartDateTime := CurrentDateTime();
            ScheduleJob(EarliestStartDateTime);
        end;
    end;

    local procedure ProcessSubscriptionOnRename(var RecRef: RecordRef; var xRecRef: RecordRef; var APIWebhookSubscription: Record "API Webhook Subscription"): Boolean
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        RegisteredNotificationDeleted: Boolean;
        RegisteredNotificationCreated: Boolean;
    begin
        if not GetEntity(APIWebhookSubscription, ApiWebhookEntity) then begin
            SendTraceTag('000024N', APIWebhookCategoryLbl, VERBOSITY::Warning, DeleteObsoleteOrUnsupportedSubscriptionMsg,
              DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;

        if ApiWebhookEntity."OData Key Specified" then begin
            if not CheckTableFilters(ApiWebhookEntity, RecRef) then
                exit(false);
            exit(RegisterNotification(ApiWebhookEntity, APIWebhookSubscription, RecRef, ChangeTypeOption::Updated));
        end;

        if CheckTableFilters(ApiWebhookEntity, xRecRef) then
            RegisteredNotificationDeleted :=
              RegisterNotification(ApiWebhookEntity, APIWebhookSubscription, xRecRef, ChangeTypeOption::Deleted);
        if CheckTableFilters(ApiWebhookEntity, RecRef) then
            RegisteredNotificationCreated :=
              RegisterNotification(ApiWebhookEntity, APIWebhookSubscription, RecRef, ChangeTypeOption::Created);
        exit(RegisteredNotificationDeleted or RegisteredNotificationCreated);
    end;

    local procedure GetSubscriptions(var APIWebhookSubscription: Record "API Webhook Subscription"; TableId: Integer): Boolean
    begin
        if not IsApiSubscriptionEnabled() then
            exit(false);

        if APIWebhookSubscription.IsEmpty() then
            exit(false);

        APIWebhookSubscription.SetFilter("Expiration Date Time", '>%1', CurrentDateTime());
        APIWebhookSubscription.SetFilter("Company Name", '%1|%2', CompanyName(), '');
        APIWebhookSubscription.SetRange("Source Table Id", TableId);
        exit(APIWebhookSubscription.FindSet());
    end;

    [EventSubscriber(ObjectType::Codeunit, 5150, 'OnEnabledDatabaseTriggersSetup', '', false, false)]
    local procedure EnabledDatabaseTriggersSetup(TableID: Integer; var Enabled: Boolean)
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if not GraphMgtGeneralTools.IsApiSubscriptionEnabled() then begin
            Enabled := false;
            exit;
        end;

        APIWebhookSubscription.SetFilter("Expiration Date Time", '>%1', CurrentDateTime());
        APIWebhookSubscription.SetFilter("Company Name", '%1|%2', CompanyName, '');
        APIWebhookSubscription.SetRange("Source Table Id", TableID);
        Enabled := not APIWebhookSubscription.IsEmpty();
    end;

    [Scope('OnPrem')]
    procedure GetEntity(var APIWebhookSubscription: Record "API Webhook Subscription"; var ApiWebhookEntity: Record "Api Webhook Entity"): Boolean
    begin
        SendTraceTag('00006ZN', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(FindingEntityMsg, DateTimeToString(APIWebhookSubscription."Expiration Date Time"),
            APIWebhookSubscription."Source Table Id"),
          DATACLASSIFICATION::SystemMetadata);
        ApiWebhookEntity.SetRange(Publisher, APIWebhookSubscription."Entity Publisher");
        ApiWebhookEntity.SetRange(Group, APIWebhookSubscription."Entity Group");
        ApiWebhookEntity.SetRange(Version, APIWebhookSubscription."Entity Version");
        ApiWebhookEntity.SetRange(Name, APIWebhookSubscription."Entity Set Name");
        ApiWebhookEntity.SetRange("Table No.", APIWebhookSubscription."Source Table Id");
        if not ApiWebhookEntity.FindFirst() then begin
            SendTraceTag('000029S', APIWebhookCategoryLbl, VERBOSITY::Warning,
              StrSubstNo(CannotFindEntityErr, APIWebhookSubscription."Source Table Id"), DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;
        if ApiWebhookEntity."Table Temporary" then begin
            SendTraceTag('000029T', APIWebhookCategoryLbl, VERBOSITY::Warning,
              StrSubstNo(TemporarySourceTableErr, ApiWebhookEntity."Table No."),
              DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;
        if StrPos(ApiWebhookEntity."Key Fields", ',') > 0 then begin
            SendTraceTag('000029U', APIWebhookCategoryLbl, VERBOSITY::Warning,
              StrSubstNo(CompositeEntityKeyErr, ApiWebhookEntity."Key Fields", ApiWebhookEntity."Table No."),
              DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;
        exit(true);
    end;

    local procedure CheckTableFilters(var ApiWebhookEntity: Record "Api Webhook Entity"; var RecRef: RecordRef): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        TempRecRef: RecordRef;
        FiltersInStream: InStream;
        TableFilters: Text;
    begin
        TempBlob.FromRecord(ApiWebhookEntity, ApiWebhookEntity.FieldNo("Table Filters"));
        TempBlob.CreateInStream(FiltersInStream, TEXTENCODING::UTF8);
        FiltersInStream.Read(TableFilters);

        if TableFilters <> '' then begin
            TempRecRef.Open(RecRef.Number, true);
            TempRecRef.Init();
            CopyPrimaryKeyFields(RecRef, TempRecRef);
            CopyFilterFields(RecRef, TempRecRef, TableFilters);
            TempRecRef.Insert();
            TempRecRef.SetView(TableFilters);
            if TempRecRef.IsEmpty() then begin
                SendTraceTag('00006ZO', APIWebhookCategoryLbl, VERBOSITY::Normal,
                  StrSubstNo(FilterMismatchingMsg, RecRef.Number, ApiWebhookEntity."Object Type", ApiWebhookEntity."Object ID"),
                  DATACLASSIFICATION::SystemMetadata);
                exit(false);
            end;
        end;
        SendTraceTag('00006ZP', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(FilterMatchingMsg, RecRef.Number, ApiWebhookEntity."Object Type", ApiWebhookEntity."Object ID"),
          DATACLASSIFICATION::SystemMetadata);
        exit(true);
    end;

    local procedure CopyPrimaryKeyFields(var FromRecRef: RecordRef; var ToRecRef: RecordRef)
    var
        KeyRef: KeyRef;
        FromFieldRef: FieldRef;
        I: Integer;
    begin
        KeyRef := FromRecRef.KeyIndex(1);
        for I := 1 to KeyRef.FieldCount() do begin
            FromFieldRef := KeyRef.FieldIndex(I);
            CopyFieldValue(FromFieldRef, ToRecRef);
        end;
    end;

    local procedure CopyFilterFields(var FromRecRef: RecordRef; var ToRecRef: RecordRef; TableFilters: Text)
    var
        FromFieldRef: FieldRef;
        RemainingTableFilters: Text;
        FieldNoTxt: Text;
        FieldNo: Integer;
        FieldTokLen: Integer;
        Pos: Integer;
        EqPos: Integer;
        I: Integer;
        N: Integer;
    begin
        FieldTokLen := StrLen(FieldTok);
        N := StrLen(TableFilters);
        RemainingTableFilters := TableFilters;
        for I := 0 to N do
            if StrLen(RemainingTableFilters) > 0 then begin
                Pos := StrPos(RemainingTableFilters, FieldTok);
                if Pos > 0 then begin
                    RemainingTableFilters := CopyStr(RemainingTableFilters, Pos + FieldTokLen);
                    EqPos := StrPos(RemainingTableFilters, EqConstTok);
                    // At least one digit must be before "=" sign
                    if EqPos < 2 then
                        EqPos := StrPos(RemainingTableFilters, EqFilterTok);
                    // Integer max value is 2,147,483,647 so no more then Text[10]
                    if (EqPos > 1) and (EqPos < 12) then begin
                        FieldNoTxt := CopyStr(RemainingTableFilters, 1, EqPos - 1);
                        if Evaluate(FieldNo, FieldNoTxt) then
                            if FieldNo <= ToRecRef.FieldCount() then begin
                                FromFieldRef := FromRecRef.Field(FieldNo);
                                CopyFieldValue(FromFieldRef, ToRecRef);
                            end;
                    end;
                end;
            end else
                I := N;
    end;

    local procedure CopyFieldValue(var FromFieldRef: FieldRef; var ToRecordRef: RecordRef)
    var
        ToFieldRef: FieldRef;
    begin
        if FromFieldRef.Class = FieldClass::Normal then begin
            ToFieldRef := ToRecordRef.Field(FromFieldRef.Number);
            ToFieldRef.Value := FromFieldRef.Value;
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteSubscription(var APIWebhookSubscription: Record "API Webhook Subscription")
    var
        APIWebhookNotification: Record "API Webhook Notification";
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
    begin
        SendTraceTag('00006ZQ', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(DeleteSubscriptionMsg,
            DateTimeToString(APIWebhookSubscription."Expiration Date Time"), APIWebhookSubscription."Source Table Id"),
          DATACLASSIFICATION::SystemMetadata);
        APIWebhookNotification.SetRange("Subscription ID", APIWebhookSubscription."Subscription Id");
        if not APIWebhookNotification.IsEmpty() then
            APIWebhookNotification.DeleteAll(true);

        APIWebhookNotificationAggr.SetRange("Subscription ID", APIWebhookSubscription."Subscription Id");
        if not APIWebhookNotificationAggr.IsEmpty() then
            APIWebhookNotificationAggr.DeleteAll(true);

        if not APIWebhookSubscription.Delete() then;
    end;

    local procedure RegisterNotification(var ApiWebhookEntity: Record "Api Webhook Entity"; var APIWebhookSubscription: Record "API Webhook Subscription"; var RecRef: RecordRef; ChangeType: Option): Boolean
    var
        APIWebhookNotification: Record "API Webhook Notification";
        FieldRef: FieldRef;
        FieldValue: Text;
    begin
        if TryGetEntityKeyValue(ApiWebhookEntity, RecRef, FieldValue) then begin
            APIWebhookNotification.ID := CreateGuid();
            APIWebhookNotification."Subscription ID" := APIWebhookSubscription."Subscription Id";
            APIWebhookNotification."Created By User SID" := UserSecurityId();
            APIWebhookNotification."Change Type" := ChangeType;
            if APIWebhookNotification."Change Type" = APIWebhookNotification."Change Type"::Deleted then
                APIWebhookNotification."Last Modified Date Time" := CurrentDateTime()
            else
                APIWebhookNotification."Last Modified Date Time" := GetLastModifiedDateTime(RecRef, FieldRef);
            APIWebhookNotification."Entity Key Value" := CopyStr(FieldValue, 1, MaxStrLen(APIWebhookNotification."Entity Key Value"));
            if APIWebhookNotification.Insert(true) then begin
                SendTraceTag('000024P', APIWebhookCategoryLbl, VERBOSITY::Normal,
                  StrSubstNo(CreateNotificationMsg,
                    DateTimeToString(APIWebhookSubscription."Expiration Date Time"), APIWebhookSubscription."Source Table Id",
                    DateTimeToString(APIWebhookNotification."Last Modified Date Time"),
                    APIWebhookNotification."Change Type", APIWebhookNotification.ID),
                  DATACLASSIFICATION::SystemMetadata);
                exit(true);
            end;
        end;

        SendTraceTag('000029L', APIWebhookCategoryLbl, VERBOSITY::Error,
          StrSubstNo(CannotCreateNotificationErr,
            DateTimeToString(APIWebhookSubscription."Expiration Date Time"), APIWebhookSubscription."Source Table Id",
            DateTimeToString(APIWebhookNotification."Last Modified Date Time"), APIWebhookNotification."Change Type"),
          DATACLASSIFICATION::SystemMetadata);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure TryGetEntityKeyField(var ApiWebhookEntity: Record "Api Webhook Entity"; var RecRef: RecordRef; var FieldRef: FieldRef): Boolean
    var
        ErrorMessage: Text;
        FieldNo: Integer;
    begin
        if StrPos(ApiWebhookEntity."Key Fields", ',') > 0 then begin
            ErrorMessage := StrSubstNo(CompositeEntityKeyErr, ApiWebhookEntity."Key Fields", RecRef.Number);
            SendTraceTag('000029M', APIWebhookCategoryLbl, VERBOSITY::Warning, ErrorMessage, DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;

        if not Evaluate(FieldNo, ApiWebhookEntity."Key Fields") then begin
            ErrorMessage := StrSubstNo(IncorrectEntityKeyErr, ApiWebhookEntity."Key Fields", RecRef.Number);
            SendTraceTag('000029N', APIWebhookCategoryLbl, VERBOSITY::Error, ErrorMessage, DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;

        FieldRef := RecRef.Field(FieldNo);
        exit(true);
    end;

    local procedure TryGetEntityKeyValue(var ApiWebhookEntity: Record "Api Webhook Entity"; var RecRef: RecordRef; var FieldValue: Text): Boolean
    var
        FieldRef: FieldRef;
    begin
        if not TryGetEntityKeyField(ApiWebhookEntity, RecRef, FieldRef) then
            exit(false);

        if not GetRawFieldValue(FieldRef, FieldValue) then
            exit(false);

        exit(true);
    end;

    local procedure GetRawFieldValue(var FieldRef: FieldRef; var Value: Text): Boolean
    var
        Date: Date;
        Time: Time;
        DateTime: DateTime;
        BigInt: BigInteger;
        Decimal: Decimal;
        Bool: Boolean;
        Guid: Guid;
        ErrorMessage: Text;
    begin
        case FieldRef.Type of
            FieldType::GUID:
                begin
                    Guid := FieldRef.Value;
                    Value := LowerCase(IntegrationManagement.GetIdWithoutBrackets(Guid));
                end;
            FieldType::Code, FieldType::Text:
                begin
                    Value := FieldRef.Value;
                    if Value <> '' then
                        Value := Format(FieldRef.Value);
                end;
            FieldType::Option:
                Value := Format(FieldRef);
            FieldType::Integer, FieldType::BigInteger:
                Value := Format(FieldRef.Value);
            FieldType::Boolean:
                begin
                    Bool := FieldRef.Value;
                    Value := SetBoolFormat(Bool);
                end;
            FieldType::Date:
                begin
                    Date := FieldRef.Value;
                    Value := SetDateFormat(Date);
                end;
            FieldType::Time:
                begin
                    Time := FieldRef.Value;
                    Value := SetTimeFormat(Time);
                end;
            FieldType::DateTime:
                begin
                    DateTime := FieldRef.Value;
                    Value := SetDateTimeFormat(DateTime);
                end;
            FieldType::Duration:
                begin
                    BigInt := FieldRef.Value;
                    // Use round to avoid conversion errors due to the conversion from decimal to long.
                    BigInt := Round(BigInt / 60000, 1);
                    Value := Format(BigInt);
                end;
            FieldType::DateFormula:
                Value := Format(FieldRef.Value);
            FieldType::Decimal:
                begin
                    Decimal := FieldRef.Value;
                    Value := SetDecimalFormat(Decimal);
                end;
            else begin
                    ErrorMessage := StrSubstNo(UnsupportedFieldTypeErr, FieldRef.Caption, FieldRef.Record.Caption);
                    SendTraceTag('000029O', APIWebhookCategoryLbl, VERBOSITY::Error, ErrorMessage, DATACLASSIFICATION::SystemMetadata);
                    exit(false);
                end;
        end;
        exit(true);
    end;

    local procedure SetDateFormat(InDate: Date) OutDate: Text
    begin
        OutDate := Format(InDate, 0, '<Year4>-<Month,2>-<Day,2>');
    end;

    local procedure SetTimeFormat(InTime: Time) OutTime: Text
    begin
        OutTime := ConvertStr(Format(InTime, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'), ' ', '0');
    end;

    local procedure SetDateTimeFormat(InDateTime: DateTime) OutDateTime: Text
    begin
        if InDateTime = 0DT then
            OutDateTime := SetDateFormat(0D) + 'T' + SetTimeFormat(0T) + 'Z'
        else
            OutDateTime := SetDateFormat(DT2Date(InDateTime)) + 'T' + SetTimeFormat(DT2Time(InDateTime)) + 'Z';
    end;

    local procedure SetDecimalFormat(InDecimal: Decimal) OutDecimal: Text
    begin
        OutDecimal := Format(InDecimal, 0, '<Sign>') + Format(InDecimal, 0, '<Integer>');

        if CopyStr(Format(InDecimal, 0, '<Decimals>'), 2) <> '' then
            OutDecimal := OutDecimal + '.' + CopyStr(Format(InDecimal, 0, '<Decimals>'), 2)
        else
            OutDecimal := OutDecimal + '.0';
    end;

    local procedure SetBoolFormat(InBoolean: Boolean) OutBoolean: Text
    begin
        if InBoolean then
            OutBoolean := 'true'
        else
            OutBoolean := 'false';
    end;

    local procedure GetLastModifiedDateTime(var RecRef: RecordRef; var FieldRef: FieldRef): DateTime
    var
        LastModifiedDateTime: DateTime;
    begin
        if FindLastModifiedDateTimeField(RecRef, FieldRef) then
            LastModifiedDateTime := FieldRef.Value
        else
            LastModifiedDateTime := CurrentDateTime();
        exit(LastModifiedDateTime);
    end;

    [Scope('OnPrem')]
    procedure FindLastModifiedDateTimeField(var RecRef: RecordRef; var FieldRef: FieldRef): Boolean
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, RecRef.Number);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetRange(Type, Field.Type::DateTime);
        Field.SetFilter(FieldName, '%1|%2|%3|%4',
          'Last Modified Date Time', 'Last Modified DateTime', 'Last DateTime Modified', 'Last Date Time Modified');

        if not Field.FindFirst() then
            exit(false);

        FieldRef := RecRef.Field(Field."No.");
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ScheduleJob(EarliestStartDateTime: DateTime)
    var
        JobQueueEntry: Record "Job Queue Entry";
        ProcessingDateTime: DateTime;
        LatestStartDateTime: DateTime;
    begin
        ProcessingDateTime := CurrentDateTime();
        LatestStartDateTime := EarliestStartDateTime + GetDelayTime();

        SendTraceTag('000070M', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(ScheduleJobMsg, DateTimeToString(ProcessingDateTime), DateTimeToString(EarliestStartDateTime), DateTimeToString(LatestStartDateTime)),
          DATACLASSIFICATION::SystemMetadata);

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"API Webhook Notification Send");
        JobQueueEntry.SetRange("Job Queue Category Code", JobQueueCategoryCodeLbl);
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Ready);
        JobQueueEntry.SetRange("Earliest Start Date/Time", EarliestStartDateTime, LatestStartDateTime);
        if JobQueueEntry.FindFirst() then begin
            JobQueueEntry.CalcFields(Scheduled);
            if JobQueueEntry.Scheduled then begin
                SendTraceTag('000070O', APIWebhookCategoryLbl, VERBOSITY::Normal,
                  StrSubstNo(ReadyJobExistsMsg, DateTimeToString(JobQueueEntry."Earliest Start Date/Time")),
                  DATACLASSIFICATION::SystemMetadata);
                exit;
            end;
        end;

        JobQueueEntry.SetRange(Status);
        JobQueueEntry.SetRange("Earliest Start Date/Time");
        if JobQueueEntry.Count() >= GetMaxNumberOfJobs then begin
            SendTraceTag('000070P', APIWebhookCategoryLbl, VERBOSITY::Normal, StrSubstNo(TooManyJobsMsg, GetMaxNumberOfJobs),
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        CreateJob(LatestStartDateTime);
    end;

    local procedure CreateJob(EarliestStartDateTime: DateTime)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if EarliestStartDateTime = 0DT then
            EarliestStartDateTime := CurrentDateTime() + GetDelayTime();

        SendTraceTag('00006ZR', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(CreateJobMsg, DateTimeToString(EarliestStartDateTime)), DATACLASSIFICATION::SystemMetadata);

        SetJobParameters(JobQueueEntry, EarliestStartDateTime);
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;

    local procedure SetJobParameters(var JobQueueEntry: Record "Job Queue Entry"; EarliestStartDateTime: DateTime)
    begin
        CreateApiWebhookJobCategoryIfMissing;

        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"API Webhook Notification Send";
        JobQueueEntry."Job Queue Category Code" :=
          CopyStr(JobQueueCategoryCodeLbl, 1, MaxStrLen(JobQueueEntry."Job Queue Category Code"));
        JobQueueEntry."Earliest Start Date/Time" := EarliestStartDateTime;
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry."Maximum No. of Attempts to Run" := 2;
        JobQueueEntry."Rerun Delay (sec.)" := GetDelayTime div 1000;
    end;

    local procedure CreateApiWebhookJobCategoryIfMissing()
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        if not JobQueueCategory.Get(JobQueueCategoryCodeLbl) then begin
            SendTraceTag('00006ZS', APIWebhookCategoryLbl, VERBOSITY::Normal, CreateJobCategoryMsg, DATACLASSIFICATION::SystemMetadata);
            JobQueueCategory.Validate(Code, CopyStr(JobQueueCategoryCodeLbl, 1, MaxStrLen(JobQueueCategory.Code)));
            JobQueueCategory.Validate(Description, CopyStr(JobQueueCategoryDescLbl, 1, MaxStrLen(JobQueueCategory.Description)));
            JobQueueCategory.Insert(true);
        end;
    end;

    local procedure GetDelayTime(): Integer
    var
        ServerSetting: Codeunit "Server Setting";
        Handled: Boolean;
        DelayTime: Integer;
    begin
        OnGetDelayTime(Handled, DelayTime);
        if Handled then
            exit(DelayTime);

        DelayTime := ServerSetting.GetApiSubscriptionDelayTime();
        exit(DelayTime);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDelayTime(var Handled: Boolean; var Value: Integer)
    begin
    end;

    local procedure IsApiSubscriptionEnabled(): Boolean
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if UseCachedApiSubscriptionEnabled then
            exit(CachedApiSubscriptionEnabled);

        CachedApiSubscriptionEnabled := GraphMgtGeneralTools.IsApiSubscriptionEnabled;
        UseCachedApiSubscriptionEnabled := true;

        exit(CachedApiSubscriptionEnabled);
    end;

    [Scope('OnPrem')]
    procedure Reset()
    begin
        UseCachedApiSubscriptionEnabled := false;
        Clear(CachedApiSubscriptionEnabled);
    end;

    local procedure GetMaxNumberOfJobs(): Integer
    begin
        exit(20);
    end;

    local procedure DateTimeToString(Value: DateTime): Text
    begin
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2> <Hours24>:<Minutes,2>:<Seconds,2><Second dec.><Comma,.>'));
    end;
}

