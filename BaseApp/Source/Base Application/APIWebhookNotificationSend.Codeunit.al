codeunit 6154 "API Webhook Notification Send"
{
    // 1. Aggregates notifications
    // 2. Generates notifications payload per notification URL
    // 3. Sends notifications


    trigger OnRun()
    begin
        if not IsApiSubscriptionEnabled() then begin
            SendTraceTag('000029V', APIWebhookCategoryLbl, VERBOSITY::Normal, DisabledSubscriptionMsg, DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        Initialize();
        DeleteExpiredSubscriptions();
        DeleteObsoleteSubscriptions();
        DeleteInactiveJobs();

        if not GetActiveSubscriptions() then begin
            SendTraceTag('000029W', APIWebhookCategoryLbl, VERBOSITY::Normal, NoActiveSubscriptionsMsg, DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        // Don't roll back the cleanup done
        // and release any potentional locks before starting of processing
        Commit();
        ProcessNotifications();
    end;

    var
        TempAPIWebhookNotificationAggr: Record "API Webhook Notification Aggr" temporary;
        TempAPIWebhookSubscription: Record "API Webhook Subscription" temporary;
        TempSubscriptionIdBySubscriptionNoNameValueBuffer: Record "Name/Value Buffer" temporary;
        TempKeyFieldTypeBySubscriptionIdNameValueBuffer: Record "Name/Value Buffer" temporary;
        TempFirstModifiedDateTimeAPIWebhookNotification: Record "API Webhook Notification" temporary;
        TypeHelper: Codeunit "Type Helper";
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
        ResourceUrlBySubscriptionIdDictionaryWrapper: Codeunit "Dictionary Wrapper";
        NotificationUrlBySubscriptionIdDictionaryWrapper: Codeunit "Dictionary Wrapper";
        SubscriptionsPerNotificationUrlDictionaryWrapper: Codeunit "Dictionary Wrapper";
        ProcessingDateTime: DateTime;
        APIWebhookCategoryLbl: Label 'AL API Webhook', Locked = true;
        ActivityLogContextLbl: Label 'APIWEBHOOK', Locked = true;
        JobQueueCategoryCodeLbl: Label 'APIWEBHOOK', Locked = true;
        ProcessNotificationsMsg: Label 'Process notifications. Processing time: %1.', Locked = true;
        DeleteProcessedNotificationsMsg: Label 'Delete processed notifications. Processing time: %1.', Locked = true;
        SavedFailedNotificationsMsg: Label 'Saved failed notifications. Earliest scheduled time: %1.', Locked = true;
        SaveFailedNotificationMsg: Label 'Save failed notification. Change type: %1. Last modification time: %2. Attempt number: %3.', Locked = true;
        GenerateAggregateNotificationMsg: Label 'Generate aggregate notification. Change type: %1. Last modification time: %2.', Locked = true;
        MergeIntoExistingCollectionAggregateNotificationMsg: Label 'Merge into existing collection aggregate notification. Change type: %1. Last modification time: %2.', Locked = true;
        MergeAllIntoNewCollectionAggregateNotificationMsg: Label 'Merge all notifications into new collection aggregate notification. Last modification time: %1.', Locked = true;
        GenerateSingleAggregateNotificationMsg: Label 'Generate single aggregate notification. Change type: %1. Last modification time: %2.', Locked = true;
        SendNotificationsMsg: Label 'Send notifications. Unique notification URL count: %1.', Locked = true;
        SendNotificationMsg: Label 'Send notification. Notification URL number: %1.', Locked = true;
        AllPayloadsEmptyMsg: Label 'No one notification has been sent. All the payloads are empty.', Locked = true;
        SucceedNotificationMsg: Label 'Notification has been sent successfully. Notification URL number: %1.', Locked = true;
        FailedNotificationRescheduleMsg: Label 'Server was not able to proceess the notification at this point. Notification URL number: %1. Response code %2. Notification is rescheduled.', Locked = true;
        FailedNotificationRejectedMsg: Label 'Server has rejected the notification. Notification URL number: %1. Response code %2.', Locked = true;
        NoPendingNotificationsMsg: Label 'No pending notifications.', Locked = true;
        NoActiveSubscriptionsMsg: Label 'No active subscriptions.', Locked = true;
        DisabledSubscriptionMsg: Label 'API subscription disabled.', Locked = true;
        DeleteObsoleteSubscriptionMsg: Label 'Delete obsolete subscription. Subscription expiration time: %1. Source table: %2.', Locked = true;
        DeleteExpiredSubscriptionMsg: Label 'Delete expired subscription. Subscription expiration time: %1. Source table: %2.', Locked = true;
        DeleteInvalidSubscriptionsMsg: Label 'Delete invalid subscriptions with numbers %1.', Locked = true;
        DeleteInvalidSubscriptionMsg: Label 'Delete invalid subscription with number %1.', Locked = true;
        DeleteSubscriptionWithTooManyFailuresMsg: Label 'Delete subscription with too many failures. Subscription expiration time: %1. Attempt number: %2.', Locked = true;
        DeleteNotificationsForSubscriptionsMsg: Label 'Delete notifications for subscriptions with numbers %1.', Locked = true;
        DeleteNotificationsForSubscriptionMsg: Label 'Delete notifications for subscription with number %1.', Locked = true;
        UnexpectedNotificationChangeTypeMsg: Label 'Unexpected notification change type. Expected change type: %1. Actual change type: %2.', Locked = true;
        ManyNotificationsOfTypeCollectionMsg: Label 'Many notifications of type collection. Expected count: %1. Actual count: %2.', Locked = true;
        FewNotificationsOfTypeCollectionMsg: Label 'Few notifications of type collection. Expected count: %1. Actual count: %2.', Locked = true;
        UpdateNotificationOfTypeCollectionMsg: Label 'Update notification of type collection. First modification time: %1. Last modification time: %2.', Locked = true;
        MergeNotificationsOfTypeUpdatedMsg: Label 'Merge notifications of type updated. Last modification time: %1.', Locked = true;
        MergeNotificationsIntoOneOfTypeCollectionMsg: Label 'Merge %1 notifications into one of type collection. First modification time: %2. Last modification time: %3.', Locked = true;
        EmptyLastModifiedDateTimeMsg: Label 'Empty last modified time. Notification change type: %1. Attempt number: %2.', Locked = true;
        EmptyNotificationUrlErr: Label 'Empty notification URL. Notification URL number: %1.', Locked = true;
        EmptySubscriptionIdErr: Label 'Empty subscription ID. Subscription number %1.', Locked = true;
        EmptyPayloadPerSubscriptionErr: Label 'Empty payload per subscription. Subscription number %1.', Locked = true;
        EmptyPayloadPerNotificationUrlErr: Label 'Empty payload per notification URL. Notification URL number: %1.', Locked = true;
        CannotGetResponseErr: Label 'Cannot get response. Notification URL number: %1.', Locked = true;
        CannotFindCachedAggregateNotificationErr: Label 'Cannot find cached aggregate notification for subscription ID.', Locked = true;
        CannotFindCachedCollectionAggregateNotificationMsg: Label 'Cannot find cached collection aggregate notification for subscription ID.', Locked = true;
        CannotFindCachedSubscriptionIdForSubscriptionNumberErr: Label 'Cannot find cached subscription ID for subscription number %1.', Locked = true;
        CannotFindCachedEntityKeyFieldTypeForSubscriptionIdErr: Label 'Cannot find cached entity key field type for subscription ID.', Locked = true;
        CannotFindCachedFirstModifiedTimeForSubscriptionIdMsg: Label 'Cannot find cached first modified time for subscription ID.', Locked = true;
        CannotFindCachedResourceUrlForSubscriptionIdErr: Label 'Cannot find cached resource URL for subscription ID.', Locked = true;
        CannotFindCachedNotificationUrlForSubscriptionIdErr: Label 'Cannot find cached notification URL for subscription ID.', Locked = true;
        CannotFindCachedSubscriptionNumbersForNotificationUrlNumberErr: Label 'Cannot find cached subscription numbers for notification URL number %1.', Locked = true;
        CannotFindCachedNotificationUrlForNotificationUrlNumberErr: Label 'Cannot find cached notification URL for notification URL number %1.', Locked = true;
        FoundCachedSubscriptionIdForSubscriptionNumberMsg: Label 'Found cached subscription ID for subscription number %1.', Locked = true;
        FoundCachedEntityKeyFieldTypeForSubscriptionIdMsg: Label 'Found cached entity key field type %1 for subscription ID.', Locked = true;
        FoundCachedFirstModifiedTimeForSubscriptionIdMsg: Label 'Found cached first modified time %1 for subscription ID.', Locked = true;
        FoundCachedResourceUrlForSubscriptionIdMsg: Label 'Found cached resource URL for subscription ID.', Locked = true;
        FoundCachedNotificationUrlForSubscriptionIdMsg: Label 'Found cached notification URL for subscription ID.', Locked = true;
        FoundCachedSubscriptionNumbersForNotificationUrlNumberMsg: Label 'Found cached subscription numbers %1 for notification URL number %2.', Locked = true;
        CachedResourceUrlForSubscriptionIdMsg: Label 'Resource URL for subscription ID is cached already. Subscription number: %1. Subscription expiration time: %2.', Locked = true;
        CachedNotificationUrlForSubscriptionIdMsg: Label 'Notification URL for subscription ID is cached already. Subscription number: %1. Subscription expiration time: %2.', Locked = true;
        CachingSubscriptionIdForSubscriptionNumberMsg: Label 'Caching subscription ID for subscription number %1. Subscription expiration time: %2.', Locked = true;
        CachingEntityKeyFieldTypeForSubscriptionIdMsg: Label 'Caching entity key field type for subscription ID. Subscription number: %1. Subscription expiration time: %2.', Locked = true;
        CachingFirstModifiedTimeForSubscriptionIdMsg: Label 'Caching first modified time for subscription ID. Old value: %1. New value: %2.', Locked = true;
        NewFirstModifiedTimeLaterThanCachedMsg: Label 'New first modified time %1 is later than cached time %2.', Locked = true;
        CachingResourceUrlForSubscriptionIdMsg: Label 'Caching resource URL for subscription ID. Subscription number: %1. Subscription expiration time: %2.', Locked = true;
        CachingNotificationUrlForSubscriptionIdMsg: Label 'Caching notification URL for subscription ID. Subscription number: %1. Subscription expiration time: %2.', Locked = true;
        CachingSubscriptionNumbersForNotificationUrlMsg: Label 'Adding subscription with number %1 to the cached list of subscription numbers by notification URL. Subscription expiration time: %2.', Locked = true;
        CollectPayloadPerNotificationUrlMsg: Label 'Collect payload per notification URL. Notification URL number: %1. Subscription numbers: %2.', Locked = true;
        CollectPayloadPerSubscriptionMsg: Label 'Collect payload per subscription. Subscription number: %1.', Locked = true;
        CollectNotificationPayloadMsg: Label 'Collect notification payload. Subscription number: %1. Notification number: %2. Change type: %3. Last modification time: %4.', Locked = true;
        CannotFindSubscriptionErr: Label 'Cannot find subscription. Subscription number: %1.', Locked = true;
        NoNotificationsForSubscriptionMsg: Label 'No notifications for subscription. Subscription number: %1.', Locked = true;
        RescheduleBeforeOrEqualToProcessingMsg: Label 'Reschedule time %1 is before or equal to processing time %2.', Locked = true;
        IncreaseAttemptNumberForSubscriptionsMsg: Label 'Increase attempt number for notifications. Subscription numbers %1. Processing time: %2.', Locked = true;
        IncreaseAttemptNumberForSubscriptionMsg: Label 'Increase attempt number for notifications. Subscription number %1. Processing time: %2.', Locked = true;
        IncreaseAttemptNumberForNotificationMsg: Label 'Increase attempt number for notification. Subscription number: %1. Change type: %2. Last modification time: %3. Attempt number: %4. Scheduled time: %5. Processing time: %6.', Locked = true;
        DoNotIncreaseAttemptNumberForNotificationMsg: Label 'Do not increase attempt number for notification. Subscription number: %1. Change type: %2. Last modification time: %3. Attempt number: %4. Scheduled time: %5. Processing time: %6.', Locked = true;
        SendingNotificationFailedErr: Label 'Sending notification failed for %1. Response code: %2. Error message: %3. Error details: %4.', Locked = true;
        CannotInsertAggregateNotificationErr: Label 'Cannot insert aggregate notification. Notification ID: %1. Change type: %2. Last modification time: %3. Attempt number: %4. Sending scheduled time: %5.', Locked = true;
        SendingJobFailedMsg: Label 'Sending job failed. Earliest start time: %1.', Locked = true;
        FailedJobDetailsMsg: Label 'Sending job failed. %1', Locked = true;
        DeleteInactiveJobMsg: Label 'Delete inactive job. Status: %1. Earliest start time: %2.', Locked = true;
        DeleteReadyButNotScheduledJobMsg: Label 'Delete ready but not scheduled job. Earliest start time: %1.', Locked = true;
        DeleteJobWithWrongParametersMsg: Label 'Delete job with wrong parameters. Category: %1. Recurring: %2. Earliest start time: %3.', Locked = true;
        SubscriptionDetailsTxt: Label 'Subscription ID: %1. Resource URL: %2. Notification URL: %3.', Locked = true;
        FailedNotificationDetailsTxt: Label 'Notification URL: %1. Response code: %2. Error message: %3. Error details: %4.', Locked = true;
        DeleteInvalidSubscriptionTitleTxt: Label 'Delete invalid subscription.', Locked = true;
        DeleteObsoleteSubscriptionTitleTxt: Label 'Delete obsolete subscription.', Locked = true;
        DeleteExpiredSubscriptionTitleTxt: Label 'Delete expired subscription.', Locked = true;
        DeleteSubscriptionWithTooManyFailuresTitleTxt: Label 'Delete subscription with too many failures.', Locked = true;
        IncreaseAttemptNumberTitleTxt: Label 'Increase attempt number.', Locked = true;
        NotificationFailedTitleTxt: Label 'Notification failed.', Locked = true;
        JobFailedTitleTxt: Label 'Job failed.', Locked = true;

    local procedure Initialize()
    begin
        TempAPIWebhookNotificationAggr.Reset();
        TempAPIWebhookNotificationAggr.DeleteAll();
        TempAPIWebhookNotificationAggr.SetCurrentKey("Subscription ID", "Last Modified Date Time", "Change Type");
        TempAPIWebhookNotificationAggr.Ascending(true);

        TempAPIWebhookSubscription.Reset();
        TempAPIWebhookSubscription.DeleteAll();
        TempAPIWebhookSubscription.SetCurrentKey("Subscription Id");
        TempAPIWebhookSubscription.Ascending(true);

        TempSubscriptionIdBySubscriptionNoNameValueBuffer.Reset();
        TempSubscriptionIdBySubscriptionNoNameValueBuffer.DeleteAll();
        TempSubscriptionIdBySubscriptionNoNameValueBuffer.SetCurrentKey(ID);
        TempSubscriptionIdBySubscriptionNoNameValueBuffer.Ascending(true);

        TempKeyFieldTypeBySubscriptionIdNameValueBuffer.Reset();
        TempKeyFieldTypeBySubscriptionIdNameValueBuffer.DeleteAll();
        TempKeyFieldTypeBySubscriptionIdNameValueBuffer.SetCurrentKey(Name);
        TempKeyFieldTypeBySubscriptionIdNameValueBuffer.Ascending(true);

        TempFirstModifiedDateTimeAPIWebhookNotification.Reset();
        TempFirstModifiedDateTimeAPIWebhookNotification.DeleteAll();
        TempFirstModifiedDateTimeAPIWebhookNotification.SetCurrentKey("Subscription ID");
        TempFirstModifiedDateTimeAPIWebhookNotification.Ascending(true);

        ResourceUrlBySubscriptionIdDictionaryWrapper.Clear();
        NotificationUrlBySubscriptionIdDictionaryWrapper.Clear();
        SubscriptionsPerNotificationUrlDictionaryWrapper.Clear();

        ProcessingDateTime := CurrentDateTime();
    end;

    local procedure ProcessNotifications()
    var
        RescheduleDateTime: DateTime;
        AggregateNotificationsExist: Boolean;
    begin
        SendTraceTag('00006ZT', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(ProcessNotificationsMsg, DateTimeToString(ProcessingDateTime)), DATACLASSIFICATION::SystemMetadata);
        OnBeforeProcessNotifications();
        TransferAggregateNotificationsToBuffer();
        AggregateNotificationsExist := GenerateAggregateNotifications();
        if AggregateNotificationsExist then begin
            SendNotifications();
            UpdateTablesFromBuffer(RescheduleDateTime);
            if RescheduleDateTime > ProcessingDateTime then
                APIWebhookNotificationMgt.ScheduleJob(RescheduleDateTime)
            else
                if RescheduleDateTime <> 0DT then
                    SendTraceTag('00006ZU', APIWebhookCategoryLbl, VERBOSITY::Normal,
                      StrSubstNo(RescheduleBeforeOrEqualToProcessingMsg,
                        DateTimeToString(RescheduleDateTime), DateTimeToString(ProcessingDateTime)),
                      DATACLASSIFICATION::SystemMetadata);
        end;
        OnAfterProcessNotifications();
    end;

    local procedure SendNotifications()
    var
        SubscriptionNumbers: Text;
        NotificationUrl: Text;
        PayloadPerNotificationUrl: Text;
        NotificationUrlCount: Integer;
        I: Integer;
        Reschedule: Boolean;
        HasPayload: Boolean;
    begin
        NotificationUrlCount := SubscriptionsPerNotificationUrlDictionaryWrapper.Count();
        SendTraceTag('00006ZV', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(SendNotificationsMsg, NotificationUrlCount),
          DATACLASSIFICATION::SystemMetadata);
        for I := 1 to NotificationUrlCount do
            if GetSubscriptionsPerNotificationUrl(I, NotificationUrl, SubscriptionNumbers) then begin
                PayloadPerNotificationUrl := GetPayloadPerNotificationUrl(I, SubscriptionNumbers);
                if not HasPayload then
                    HasPayload := PayloadPerNotificationUrl <> '';
                if SendNotification(I, NotificationUrl, PayloadPerNotificationUrl, Reschedule) then
                    DeleteNotifications(SubscriptionNumbers)
                else
                    if Reschedule then
                        IncreaseAttemptNumber(SubscriptionNumbers)
                    else begin
                        DeleteNotifications(SubscriptionNumbers);
                        DeleteInvalidSubscriptions(SubscriptionNumbers);
                    end;
            end;
        if not HasPayload then
            SendTraceTag('0000735', APIWebhookCategoryLbl, VERBOSITY::Warning,
              AllPayloadsEmptyMsg, DATACLASSIFICATION::SystemMetadata);
    end;

    local procedure GetPayloadPerNotificationUrl(NotificationUrlNumber: Integer; SubscriptionNumbers: Text): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonArray: DotNet JArray;
        SubscriptionNumber: Text;
        RemainingSubscriptionNumbers: Text;
        SubscriptionId: Text;
        PayloadPerNotificationUrl: Text;
        I: Integer;
        N: Integer;
    begin
        SendTraceTag('00006ZX', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(CollectPayloadPerNotificationUrlMsg, NotificationUrlNumber, SubscriptionNumbers),
          DATACLASSIFICATION::SystemMetadata);

        JSONManagement.InitializeEmptyCollection();
        JSONManagement.GetJsonArray(JsonArray);

        RemainingSubscriptionNumbers := SubscriptionNumbers;
        N := StrLen(RemainingSubscriptionNumbers) div 2;
        for I := 0 to N do
            if StrLen(RemainingSubscriptionNumbers) > 0 then begin
                SubscriptionNumber := GetNextToken(RemainingSubscriptionNumbers, ',');
                SubscriptionId := GetSubscriptionIdBySubscriptionNumber(SubscriptionNumber);
                AddPayloadPerSubscription(JSONManagement, JsonArray, SubscriptionId, SubscriptionNumber);
            end else
                I := N;

        if JsonArray.Count() = 0 then begin
            SendTraceTag('000029X', APIWebhookCategoryLbl, VERBOSITY::Normal,
              StrSubstNo(EmptyPayloadPerNotificationUrlErr, NotificationUrlNumber),
              DATACLASSIFICATION::SystemMetadata);
            exit('')
        end;

        PayloadPerNotificationUrl := JsonArray.ToString();
        FormatPayloadPerNotificationUrl(PayloadPerNotificationUrl);
        exit(PayloadPerNotificationUrl);
    end;

    local procedure AddPayloadPerSubscription(var JSONManagement: Codeunit "JSON Management"; var JsonArray: DotNet JArray; SubscriptionId: Text; SubscriptionNumber: Text)
    var
        JsonObject: DotNet JObject;
        I: Integer;
    begin
        SendTraceTag('00006ZY', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(CollectPayloadPerSubscriptionMsg, SubscriptionNumber), DATACLASSIFICATION::SystemMetadata);

        if SubscriptionId = '' then begin
            SendTraceTag('00006ZZ', APIWebhookCategoryLbl, VERBOSITY::Error,
              StrSubstNo(EmptySubscriptionIdErr, SubscriptionNumber), DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        ClearFiltersFromNotificationsBuffer();
        TempAPIWebhookNotificationAggr.SetRange("Subscription ID", SubscriptionId);
        if not TempAPIWebhookNotificationAggr.Find('-') then begin
            SendTraceTag('0000700', APIWebhookCategoryLbl, VERBOSITY::Normal,
              StrSubstNo(NoNotificationsForSubscriptionMsg, SubscriptionNumber), DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        // We have two rows for a notification of change type Collection. We take the last one.
        if TempAPIWebhookNotificationAggr."Change Type" = TempAPIWebhookNotificationAggr."Change Type"::Collection then
            TempAPIWebhookNotificationAggr.FindLast();

        repeat
            if GetEntityJObject(SubscriptionNumber, TempAPIWebhookNotificationAggr, JsonObject) then begin
                JSONManagement.AddJObjectToJArray(JsonArray, JsonObject);
                I += 1;
                SendTraceTag('00006ZW', APIWebhookCategoryLbl, VERBOSITY::Normal,
                  StrSubstNo(CollectNotificationPayloadMsg, SubscriptionNumber, I, TempAPIWebhookNotificationAggr."Change Type",
                    DateTimeToString(TempAPIWebhookNotificationAggr."Last Modified Date Time")),
                  DATACLASSIFICATION::SystemMetadata);
            end;
        until TempAPIWebhookNotificationAggr.Next() = 0;

        if I > 0 then
            exit;

        SendTraceTag('000029Y', APIWebhookCategoryLbl, VERBOSITY::Error,
          StrSubstNo(EmptyPayloadPerSubscriptionErr, SubscriptionNumber), DATACLASSIFICATION::SystemMetadata);
    end;

    local procedure FormatPayloadPerNotificationUrl(var PayloadPerNotificationUrl: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        JsonArray: DotNet JArray;
    begin
        if PayloadPerNotificationUrl = '' then
            exit;
        JSONManagement.InitializeCollection(PayloadPerNotificationUrl);
        JSONManagement.GetJsonArray(JsonArray);
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.AddJArrayToJObject(JsonObject, 'value', JsonArray);
        PayloadPerNotificationUrl := JsonObject.ToString();
    end;

    local procedure GetPendingNotifications(var APIWebhookNotification: Record "API Webhook Notification"; ProcessingDateTime: DateTime): Boolean
    begin
        APIWebhookNotification.SetCurrentKey("Subscription ID", "Last Modified Date Time", "Change Type");
        APIWebhookNotification.Ascending(true);
        APIWebhookNotification.SetFilter("Last Modified Date Time", '<=%1', ProcessingDateTime);
        exit(APIWebhookNotification.FindSet());
    end;

    local procedure TransferAggregateNotificationsToBuffer()
    var
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
        EmptyGuid: Guid;
    begin
        APIWebhookNotificationAggr.SetFilter(ID, '<>%1', EmptyGuid);
        APIWebhookNotificationAggr.SetFilter("Subscription ID", '<>%1', '');
        if APIWebhookNotificationAggr.FindSet() then
            repeat
                TempAPIWebhookNotificationAggr.TransferFields(APIWebhookNotificationAggr, true);
                if not TempAPIWebhookNotificationAggr.Insert() then begin
                    SendTraceTag('0000736', APIWebhookCategoryLbl, VERBOSITY::Error,
                      StrSubstNo(CannotInsertAggregateNotificationErr,
                        TempAPIWebhookNotificationAggr.ID, TempAPIWebhookNotificationAggr."Change Type",
                        DateTimeToString(TempAPIWebhookNotificationAggr."Last Modified Date Time"),
                        TempAPIWebhookNotificationAggr."Attempt No.",
                        DateTimeToString(TempAPIWebhookNotificationAggr."Sending Scheduled Date Time")),
                      DATACLASSIFICATION::SystemMetadata);
                    exit;
                end;
            until APIWebhookNotificationAggr.Next() = 0;
    end;

    local procedure GenerateAggregateNotifications(): Boolean
    var
        APIWebhookNotification: Record "API Webhook Notification";
        PendingNotificationsExist: Boolean;
        NewNotificationsExist: Boolean;
    begin
        ClearFiltersFromNotificationsBuffer();
        PendingNotificationsExist := TempAPIWebhookNotificationAggr.FindFirst();
        NewNotificationsExist := GetPendingNotifications(APIWebhookNotification, ProcessingDateTime);

        if (not PendingNotificationsExist) and (not NewNotificationsExist) then begin
            SendTraceTag('0000298', APIWebhookCategoryLbl, VERBOSITY::Normal, NoPendingNotificationsMsg, DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;

        if PendingNotificationsExist then
            CollectFirstModifiedTimeForPendingCollectionNotifications;

        if NewNotificationsExist then
            repeat
                GenerateAggregateNotification(APIWebhookNotification);
            until APIWebhookNotification.Next() = 0;

        exit(true);
    end;

    local procedure GenerateAggregateNotification(var APIWebhookNotification: Record "API Webhook Notification")
    var
        TooManyNotifications: Boolean;
    begin
        SendTraceTag('000073O', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(GenerateAggregateNotificationMsg,
            APIWebhookNotification."Change Type", DateTimeToString(APIWebhookNotification."Last Modified Date Time")),
          DATACLASSIFICATION::SystemMetadata);

        ClearFiltersFromNotificationsBuffer();
        TempAPIWebhookNotificationAggr.SetRange("Subscription ID", APIWebhookNotification."Subscription ID");
        if TempAPIWebhookNotificationAggr.FindLast then begin
            if TempAPIWebhookNotificationAggr."Change Type" = TempAPIWebhookNotificationAggr."Change Type"::Collection then begin
                MergeIntoExistingCollectionAggregateNotification(APIWebhookNotification);
                exit;
            end;

            if APIWebhookNotification."Change Type" = APIWebhookNotification."Change Type"::Updated then begin
                if MergeIntoExistingUpdatedAggregateNotification(APIWebhookNotification) then
                    exit;
            end;
        end;

        GenerateSingleAggregateNotification(APIWebhookNotification, TooManyNotifications);

        if TooManyNotifications then
            MergeAllIntoNewCollectionAggregateNotification(APIWebhookNotification);
    end;

    local procedure CollectFirstModifiedTimeForPendingCollectionNotifications()
    var
        PrevSubscriptionId: Text;
    begin
        ClearFiltersFromNotificationsBuffer();
        TempAPIWebhookNotificationAggr.SetRange("Change Type", TempAPIWebhookNotificationAggr."Change Type"::Collection);
        if not TempAPIWebhookNotificationAggr.FindFirst() then
            exit;

        // We have two rows for a notification of change type Collection. We collect the date from the first one.
        repeat
            if TempAPIWebhookNotificationAggr."Subscription ID" <> PrevSubscriptionId then begin
                if TempAPIWebhookNotificationAggr."Subscription ID" <> '' then
                    CollectFirstModifiedTimeBySubscriptionId(
                      TempAPIWebhookNotificationAggr."Subscription ID", TempAPIWebhookNotificationAggr."Last Modified Date Time");
                PrevSubscriptionId := TempAPIWebhookNotificationAggr."Subscription ID";
            end;
        until TempAPIWebhookNotificationAggr.Next() = 0;
    end;

    local procedure MergeIntoExistingCollectionAggregateNotification(var APIWebhookNotification: Record "API Webhook Notification")
    var
        LastAPIWebhookNotification: Record "API Webhook Notification";
        CountPerSubscription: Integer;
        FirstNotificationId: Guid;
        LastNotificationId: Guid;
        FirstModifiedDateTime: DateTime;
        LastModifiedDateTime: DateTime;
    begin
        SendTraceTag('000073P', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(MergeIntoExistingCollectionAggregateNotificationMsg,
            APIWebhookNotification."Change Type", DateTimeToString(APIWebhookNotification."Last Modified Date Time")),
          DATACLASSIFICATION::SystemMetadata);

        ClearFiltersFromNotificationsBuffer();
        TempAPIWebhookNotificationAggr.SetRange("Subscription ID", APIWebhookNotification."Subscription ID");
        if not TempAPIWebhookNotificationAggr.FindLast then begin
            SendTraceTag('000073Q', APIWebhookCategoryLbl, VERBOSITY::Error, CannotFindCachedCollectionAggregateNotificationMsg,
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;
        if TempAPIWebhookNotificationAggr."Change Type" <> TempAPIWebhookNotificationAggr."Change Type"::Collection then begin
            SendTraceTag('000073R', APIWebhookCategoryLbl, VERBOSITY::Error, CannotFindCachedCollectionAggregateNotificationMsg,
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        LastNotificationId := TempAPIWebhookNotificationAggr.ID;
        CountPerSubscription := TempAPIWebhookNotificationAggr.Count();

        GetLastNotification(LastAPIWebhookNotification, APIWebhookNotification."Subscription ID");
        LastModifiedDateTime := LastAPIWebhookNotification."Last Modified Date Time";
        TempAPIWebhookNotificationAggr."Last Modified Date Time" := LastModifiedDateTime;
        TempAPIWebhookNotificationAggr.Modify(true);

        TempAPIWebhookNotificationAggr.FindFirst();
        if TempAPIWebhookNotificationAggr."Change Type" <> TempAPIWebhookNotificationAggr."Change Type"::Collection then begin
            SendTraceTag('000073S', APIWebhookCategoryLbl, VERBOSITY::Warning,
              StrSubstNo(UnexpectedNotificationChangeTypeMsg,
                TempAPIWebhookNotificationAggr."Change Type"::Collection, TempAPIWebhookNotificationAggr."Change Type"),
              DATACLASSIFICATION::SystemMetadata);
            TempAPIWebhookNotificationAggr."Change Type" := TempAPIWebhookNotificationAggr."Change Type"::Collection;
            TempAPIWebhookNotificationAggr.Modify(true);
        end;

        FirstNotificationId := TempAPIWebhookNotificationAggr.ID;
        if TempAPIWebhookNotificationAggr."Last Modified Date Time" <> 0DT then
            if LastAPIWebhookNotification."Change Type" <> LastAPIWebhookNotification."Change Type"::Deleted then
                if not HasNotificationOnDelete(APIWebhookNotification."Subscription ID") then
                    FirstModifiedDateTime := TempAPIWebhookNotificationAggr."Last Modified Date Time";

        if TempAPIWebhookNotificationAggr."Last Modified Date Time" <> FirstModifiedDateTime then begin
            TempAPIWebhookNotificationAggr."Last Modified Date Time" := FirstModifiedDateTime;
            TempAPIWebhookNotificationAggr.Modify(true);
        end;

        // We should have two rows for a notification of change type Collection.
        if CountPerSubscription <> 2 then
            if CountPerSubscription = 1 then begin
                SendTraceTag('000072W', APIWebhookCategoryLbl, VERBOSITY::Warning,
                  StrSubstNo(FewNotificationsOfTypeCollectionMsg, 2, CountPerSubscription), DATACLASSIFICATION::SystemMetadata);
                FirstModifiedDateTime := 0DT;
                TempAPIWebhookNotificationAggr.ID := CreateGuid;
                TempAPIWebhookNotificationAggr."Last Modified Date Time" := FirstModifiedDateTime;
                if not TempAPIWebhookNotificationAggr.Insert() then begin
                    SendTraceTag('0000737', APIWebhookCategoryLbl, VERBOSITY::Error,
                      StrSubstNo(CannotInsertAggregateNotificationErr,
                        TempAPIWebhookNotificationAggr.ID, TempAPIWebhookNotificationAggr."Change Type",
                        DateTimeToString(TempAPIWebhookNotificationAggr."Last Modified Date Time"),
                        TempAPIWebhookNotificationAggr."Attempt No.",
                        DateTimeToString(TempAPIWebhookNotificationAggr."Sending Scheduled Date Time")),
                      DATACLASSIFICATION::SystemMetadata);
                    exit;
                end;
            end else begin
                SendTraceTag('00006P2', APIWebhookCategoryLbl, VERBOSITY::Warning,
                  StrSubstNo(ManyNotificationsOfTypeCollectionMsg, 2, CountPerSubscription), DATACLASSIFICATION::SystemMetadata);
                TempAPIWebhookNotificationAggr.SetFilter(ID, '<>%1&<>%2', FirstNotificationId, LastNotificationId);
                TempAPIWebhookNotificationAggr.DeleteAll();
            end;

        SendTraceTag('0000712', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(UpdateNotificationOfTypeCollectionMsg,
            DateTimeToString(FirstModifiedDateTime), DateTimeToString(LastModifiedDateTime)),
          DATACLASSIFICATION::SystemMetadata);

        CollectFirstModifiedTimeBySubscriptionId(APIWebhookNotification."Subscription ID", FirstModifiedDateTime);
        APIWebhookNotification := LastAPIWebhookNotification;
    end;

    local procedure MergeIntoExistingUpdatedAggregateNotification(var APIWebhookNotification: Record "API Webhook Notification"): Boolean
    begin
        ClearFiltersFromNotificationsBuffer();
        TempAPIWebhookNotificationAggr.SetRange("Subscription ID", APIWebhookNotification."Subscription ID");
        TempAPIWebhookNotificationAggr.SetRange("Entity Key Value", APIWebhookNotification."Entity Key Value");
        if TempAPIWebhookNotificationAggr.FindLast then
            if TempAPIWebhookNotificationAggr."Change Type" = TempAPIWebhookNotificationAggr."Change Type"::Updated then begin
                SendTraceTag('0000713', APIWebhookCategoryLbl, VERBOSITY::Normal,
                  StrSubstNo(MergeNotificationsOfTypeUpdatedMsg, DateTimeToString(APIWebhookNotification."Last Modified Date Time")),
                  DATACLASSIFICATION::SystemMetadata);
                TempAPIWebhookNotificationAggr."Last Modified Date Time" := APIWebhookNotification."Last Modified Date Time";
                TempAPIWebhookNotificationAggr.Modify(true);
                exit(true);
            end;
        exit(false);
    end;

    local procedure GenerateSingleAggregateNotification(var APIWebhookNotification: Record "API Webhook Notification"; var TooManyNotifications: Boolean)
    var
        CountPerSubscription: Integer;
    begin
        ClearFiltersFromNotificationsBuffer();
        TempAPIWebhookNotificationAggr.SetRange("Subscription ID", APIWebhookNotification."Subscription ID");
        CountPerSubscription := TempAPIWebhookNotificationAggr.Count();
        TooManyNotifications := CountPerSubscription > GetMaxNumberOfNotifications - 1;
        if TooManyNotifications then
            exit;

        SendTraceTag('000073T', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(GenerateSingleAggregateNotificationMsg, TempAPIWebhookNotificationAggr."Change Type",
            DateTimeToString(TempAPIWebhookNotificationAggr."Last Modified Date Time")),
          DATACLASSIFICATION::SystemMetadata);

        TempAPIWebhookNotificationAggr.TransferFields(APIWebhookNotification, true);
        if not TempAPIWebhookNotificationAggr.Insert() then begin
            SendTraceTag('0000738', APIWebhookCategoryLbl, VERBOSITY::Error,
              StrSubstNo(CannotInsertAggregateNotificationErr,
                TempAPIWebhookNotificationAggr.ID, TempAPIWebhookNotificationAggr."Change Type",
                DateTimeToString(TempAPIWebhookNotificationAggr."Last Modified Date Time"),
                TempAPIWebhookNotificationAggr."Attempt No.",
                DateTimeToString(TempAPIWebhookNotificationAggr."Sending Scheduled Date Time")),
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;
    end;

    local procedure MergeAllIntoNewCollectionAggregateNotification(var APIWebhookNotification: Record "API Webhook Notification")
    var
        FirstNotificationId: Guid;
        FirstModifiedDateTime: DateTime;
        LastModifiedDateTime: DateTime;
        CountPerSubscription: Integer;
    begin
        SendTraceTag('000073U', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(MergeAllIntoNewCollectionAggregateNotificationMsg,
            DateTimeToString(APIWebhookNotification."Last Modified Date Time")),
          DATACLASSIFICATION::SystemMetadata);
        ClearFiltersFromNotificationsBuffer();
        TempAPIWebhookNotificationAggr.SetRange("Subscription ID", APIWebhookNotification."Subscription ID");
        if not TempAPIWebhookNotificationAggr.FindFirst() then begin
            SendTraceTag('000073V', APIWebhookCategoryLbl, VERBOSITY::Error, CannotFindCachedAggregateNotificationErr,
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;
        CountPerSubscription := TempAPIWebhookNotificationAggr.Count();
        FirstNotificationId := TempAPIWebhookNotificationAggr.ID;
        FirstModifiedDateTime := 0DT;
        if TempAPIWebhookNotificationAggr."Last Modified Date Time" <> 0DT then
            if APIWebhookNotification."Change Type" <> APIWebhookNotification."Change Type"::Deleted then
                if not HasNotificationOnDelete(APIWebhookNotification."Subscription ID") then
                    FirstModifiedDateTime := TempAPIWebhookNotificationAggr."Last Modified Date Time";
        TempAPIWebhookNotificationAggr."Last Modified Date Time" := FirstModifiedDateTime;
        TempAPIWebhookNotificationAggr."Change Type" := TempAPIWebhookNotificationAggr."Change Type"::Collection;
        TempAPIWebhookNotificationAggr.Modify(true);

        LastModifiedDateTime := APIWebhookNotification."Last Modified Date Time";

        SendTraceTag('0000714', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(MergeNotificationsIntoOneOfTypeCollectionMsg, CountPerSubscription,
            DateTimeToString(FirstModifiedDateTime), DateTimeToString(LastModifiedDateTime)),
          DATACLASSIFICATION::SystemMetadata);

        CollectFirstModifiedTimeBySubscriptionId(APIWebhookNotification."Subscription ID", FirstModifiedDateTime);

        ClearFiltersFromNotificationsBuffer();
        TempAPIWebhookNotificationAggr.SetRange("Subscription ID", APIWebhookNotification."Subscription ID");
        TempAPIWebhookNotificationAggr.SetFilter(ID, '<>%1', FirstNotificationId);
        TempAPIWebhookNotificationAggr.DeleteAll();

        TempAPIWebhookNotificationAggr.TransferFields(APIWebhookNotification, true);
        TempAPIWebhookNotificationAggr."Last Modified Date Time" := LastModifiedDateTime;
        TempAPIWebhookNotificationAggr."Change Type" := TempAPIWebhookNotificationAggr."Change Type"::Collection;
        if not TempAPIWebhookNotificationAggr.Insert() then begin
            SendTraceTag('0000739', APIWebhookCategoryLbl, VERBOSITY::Error,
              StrSubstNo(CannotInsertAggregateNotificationErr,
                TempAPIWebhookNotificationAggr.ID, TempAPIWebhookNotificationAggr."Change Type",
                DateTimeToString(TempAPIWebhookNotificationAggr."Last Modified Date Time"),
                TempAPIWebhookNotificationAggr."Attempt No.",
                DateTimeToString(TempAPIWebhookNotificationAggr."Sending Scheduled Date Time")),
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;
    end;

    local procedure GetLastNotification(var APIWebhookNotification: Record "API Webhook Notification"; SubscriptionId: Text[150])
    begin
        APIWebhookNotification.SetRange("Subscription ID", SubscriptionId);
        APIWebhookNotification.SetCurrentKey("Last Modified Date Time", "Change Type");
        APIWebhookNotification.Ascending(true);
        APIWebhookNotification.FindLast();
    end;

    local procedure HasNotificationOnDelete(SubscriptionId: Text[150]): Boolean
    var
        APIWebhookNotification: Record "API Webhook Notification";
    begin
        APIWebhookNotification.SetRange("Subscription ID", SubscriptionId);
        APIWebhookNotification.SetRange("Change Type", APIWebhookNotification."Change Type"::Deleted);
        exit(not APIWebhookNotification.IsEmpty());
    end;

    local procedure CollectValuesInDictionaries(var APIWebhookSubscription: Record "API Webhook Subscription"; SubscriptionNumber: Integer)
    begin
        CollectSubscriptionIdBySubscriptionNumber(APIWebhookSubscription, SubscriptionNumber);
        CollectKeyFieldTypeBySubscriptionId(APIWebhookSubscription, SubscriptionNumber);
        CollectResourceUrlBySubscriptionId(APIWebhookSubscription, SubscriptionNumber);
        CollectNotificationUrlBySubscriptionId(APIWebhookSubscription, SubscriptionNumber);
        CollectSubscriptionsPerNotificationUrl(APIWebhookSubscription, SubscriptionNumber);
    end;

    local procedure CollectSubscriptionIdBySubscriptionNumber(var APIWebhookSubscription: Record "API Webhook Subscription"; SubscriptionNumber: Integer)
    begin
        SendTraceTag('0000701', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(CachingSubscriptionIdForSubscriptionNumberMsg, SubscriptionNumber,
            DateTimeToString(APIWebhookSubscription."Expiration Date Time")),
          DATACLASSIFICATION::SystemMetadata);
        Clear(TempSubscriptionIdBySubscriptionNoNameValueBuffer);
        TempSubscriptionIdBySubscriptionNoNameValueBuffer.ID := SubscriptionNumber;
        TempSubscriptionIdBySubscriptionNoNameValueBuffer.Name := '';
        TempSubscriptionIdBySubscriptionNoNameValueBuffer.Value := APIWebhookSubscription."Subscription Id";
        TempSubscriptionIdBySubscriptionNoNameValueBuffer.Insert()
    end;

    local procedure CollectKeyFieldTypeBySubscriptionId(var APIWebhookSubscription: Record "API Webhook Subscription"; SubscriptionNumber: Integer)
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyFieldType: Text;
    begin
        SendTraceTag('0000702', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(CachingEntityKeyFieldTypeForSubscriptionIdMsg, SubscriptionNumber,
            DateTimeToString(APIWebhookSubscription."Expiration Date Time")),
          DATACLASSIFICATION::SystemMetadata);

        if not APIWebhookNotificationMgt.GetEntity(APIWebhookSubscription, ApiWebhookEntity) then
            exit;

        RecRef.Open(APIWebhookSubscription."Source Table Id", true);
        if not APIWebhookNotificationMgt.TryGetEntityKeyField(ApiWebhookEntity, RecRef, FieldRef) then
            exit;

        KeyFieldType := Format(FieldRef.Type);

        Clear(TempKeyFieldTypeBySubscriptionIdNameValueBuffer);
        TempKeyFieldTypeBySubscriptionIdNameValueBuffer.ID := SubscriptionNumber;
        TempKeyFieldTypeBySubscriptionIdNameValueBuffer.Name := APIWebhookSubscription."Subscription Id";
        TempKeyFieldTypeBySubscriptionIdNameValueBuffer.Value :=
          CopyStr(KeyFieldType, 1, MaxStrLen(TempKeyFieldTypeBySubscriptionIdNameValueBuffer.Value));
        TempKeyFieldTypeBySubscriptionIdNameValueBuffer.Insert()
    end;

    local procedure CollectFirstModifiedTimeBySubscriptionId(SubscriptionId: Text[150]; FirstModifiedDateTime: DateTime)
    var
        OldValue: DateTime;
        NewValue: DateTime;
    begin
        NewValue := FirstModifiedDateTime;
        TempFirstModifiedDateTimeAPIWebhookNotification.SetRange("Subscription ID", SubscriptionId);
        if not TempFirstModifiedDateTimeAPIWebhookNotification.FindFirst() then begin
            SendTraceTag('000072X', APIWebhookCategoryLbl, VERBOSITY::Normal,
              StrSubstNo(CachingFirstModifiedTimeForSubscriptionIdMsg, OldValue, NewValue), DATACLASSIFICATION::SystemMetadata);
            Clear(TempFirstModifiedDateTimeAPIWebhookNotification);
            TempFirstModifiedDateTimeAPIWebhookNotification.ID := CreateGuid;
            TempFirstModifiedDateTimeAPIWebhookNotification."Subscription ID" := SubscriptionId;
            TempFirstModifiedDateTimeAPIWebhookNotification."Last Modified Date Time" := FirstModifiedDateTime;
            TempFirstModifiedDateTimeAPIWebhookNotification.Insert();
            exit;
        end;

        OldValue := TempFirstModifiedDateTimeAPIWebhookNotification."Last Modified Date Time";
        if NewValue < OldValue then begin
            SendTraceTag('000072Y', APIWebhookCategoryLbl, VERBOSITY::Normal,
              StrSubstNo(CachingFirstModifiedTimeForSubscriptionIdMsg, OldValue, NewValue), DATACLASSIFICATION::SystemMetadata);
            TempFirstModifiedDateTimeAPIWebhookNotification."Last Modified Date Time" := NewValue;
            TempFirstModifiedDateTimeAPIWebhookNotification.Modify();
            exit;
        end;

        SendTraceTag('000072Z', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(NewFirstModifiedTimeLaterThanCachedMsg, NewValue, OldValue), DATACLASSIFICATION::SystemMetadata);
    end;

    local procedure CollectResourceUrlBySubscriptionId(var APIWebhookSubscription: Record "API Webhook Subscription"; SubscriptionNumber: Integer)
    var
        ResourceUrl: Text;
    begin
        if ResourceUrlBySubscriptionIdDictionaryWrapper.ContainsKey(APIWebhookSubscription."Subscription Id") then begin
            SendTraceTag('0000703', APIWebhookCategoryLbl, VERBOSITY::Normal,
              StrSubstNo(CachedResourceUrlForSubscriptionIdMsg, SubscriptionNumber,
                DateTimeToString(APIWebhookSubscription."Expiration Date Time")),
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        SendTraceTag('0000704', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(CachingResourceUrlForSubscriptionIdMsg, SubscriptionNumber,
            DateTimeToString(APIWebhookSubscription."Expiration Date Time")),
          DATACLASSIFICATION::SystemMetadata);
        ResourceUrl := GetResourceUrl(APIWebhookSubscription);
        ResourceUrlBySubscriptionIdDictionaryWrapper.Set(APIWebhookSubscription."Subscription Id", ResourceUrl);
    end;

    local procedure CollectNotificationUrlBySubscriptionId(var APIWebhookSubscription: Record "API Webhook Subscription"; SubscriptionNumber: Integer)
    var
        NotificationUrl: Text;
    begin
        if NotificationUrlBySubscriptionIdDictionaryWrapper.ContainsKey(APIWebhookSubscription."Subscription Id") then begin
            SendTraceTag('0000705', APIWebhookCategoryLbl, VERBOSITY::Normal,
              StrSubstNo(CachedNotificationUrlForSubscriptionIdMsg, SubscriptionNumber,
                DateTimeToString(APIWebhookSubscription."Expiration Date Time")),
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        SendTraceTag('0000706', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(CachingNotificationUrlForSubscriptionIdMsg, SubscriptionNumber,
            DateTimeToString(APIWebhookSubscription."Expiration Date Time")),
          DATACLASSIFICATION::SystemMetadata);
        NotificationUrl := GetNotificationUrl(APIWebhookSubscription);
        NotificationUrlBySubscriptionIdDictionaryWrapper.Set(APIWebhookSubscription."Subscription Id", NotificationUrl);
    end;

    local procedure CollectSubscriptionsPerNotificationUrl(var APIWebhookSubscription: Record "API Webhook Subscription"; SubscriptionNumber: Integer)
    var
        CachedValue: Variant;
        NotificationUrl: Text;
        SubscriptionId: Text;
        SubscriptionNumbers: Text;
    begin
        SubscriptionId := APIWebhookSubscription."Subscription Id";

        SendTraceTag('0000707', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(CachingSubscriptionNumbersForNotificationUrlMsg, SubscriptionNumber,
            DateTimeToString(APIWebhookSubscription."Expiration Date Time")),
          DATACLASSIFICATION::SystemMetadata);

        NotificationUrl := GetNotificationUrlBySubscriptionId(SubscriptionId);
        if NotificationUrl = '' then
            exit;

        if SubscriptionsPerNotificationUrlDictionaryWrapper.TryGetValue(NotificationUrl, CachedValue) then begin
            SubscriptionNumbers := CachedValue;
            SubscriptionNumbers := StrSubstNo('%1,%2', SubscriptionNumbers, SubscriptionNumber);
        end else
            SubscriptionNumbers := Format(SubscriptionNumber);
        SubscriptionsPerNotificationUrlDictionaryWrapper.Set(NotificationUrl, SubscriptionNumbers);
    end;

    local procedure DeleteNotifications(SubscriptionNumbers: Text)
    var
        SubscriptionId: Text;
        SubscriptionNumber: Text;
        RemainingSubscriptionNumbers: Text;
        I: Integer;
        N: Integer;
    begin
        SendTraceTag('0000708', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(DeleteNotificationsForSubscriptionsMsg, SubscriptionNumbers), DATACLASSIFICATION::SystemMetadata);
        RemainingSubscriptionNumbers := SubscriptionNumbers;
        N := StrLen(RemainingSubscriptionNumbers) div 2;
        for I := 0 to N do
            if StrLen(RemainingSubscriptionNumbers) > 0 then begin
                SubscriptionNumber := GetNextToken(RemainingSubscriptionNumbers, ',');
                SubscriptionId := GetSubscriptionIdBySubscriptionNumber(SubscriptionNumber);
                SendTraceTag('0000709', APIWebhookCategoryLbl, VERBOSITY::Normal,
                  StrSubstNo(DeleteNotificationsForSubscriptionMsg, SubscriptionNumber), DATACLASSIFICATION::SystemMetadata);
                if SubscriptionId <> '' then begin
                    ClearFiltersFromNotificationsBuffer();
                    TempAPIWebhookNotificationAggr.SetRange("Subscription ID", SubscriptionId);
                    TempAPIWebhookNotificationAggr.DeleteAll();
                end;
            end else
                I := N;
    end;

    local procedure DeleteInvalidSubscriptions(SubscriptionNumbers: Text)
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        SubscriptionId: Text;
        SubscriptionNumber: Text;
        RemainingSubscriptionNumbers: Text;
        I: Integer;
        N: Integer;
    begin
        SendTraceTag('000070A', APIWebhookCategoryLbl, VERBOSITY::Warning,
          StrSubstNo(DeleteInvalidSubscriptionsMsg, SubscriptionNumbers), DATACLASSIFICATION::SystemMetadata);
        RemainingSubscriptionNumbers := SubscriptionNumbers;
        N := StrLen(RemainingSubscriptionNumbers) div 2;
        for I := 0 to N do
            if StrLen(RemainingSubscriptionNumbers) > 0 then begin
                SubscriptionNumber := GetNextToken(RemainingSubscriptionNumbers, ',');
                SubscriptionId := GetSubscriptionIdBySubscriptionNumber(SubscriptionNumber);
                SendTraceTag('00006SJ', APIWebhookCategoryLbl, VERBOSITY::Warning,
                  StrSubstNo(DeleteInvalidSubscriptionMsg, SubscriptionNumber), DATACLASSIFICATION::SystemMetadata);
                if SubscriptionId <> '' then
                    if APIWebhookSubscription.Get(SubscriptionId) then begin
                        LogActivity(false, DeleteInvalidSubscriptionTitleTxt, GetSubscriptionDetails(SubscriptionId));
                        APIWebhookNotificationMgt.DeleteSubscription(APIWebhookSubscription);
                    end;
            end else
                I := 10;
    end;

    local procedure IncreaseAttemptNumber(SubscriptionNumbers: Text)
    var
        SubscriptionId: Text;
        SubscriptionNumber: Text;
        RemainingSubscriptionNumbers: Text;
        I: Integer;
        N: Integer;
    begin
        SendTraceTag('000070B', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(IncreaseAttemptNumberForSubscriptionsMsg, SubscriptionNumbers, DateTimeToString(ProcessingDateTime)),
          DATACLASSIFICATION::SystemMetadata);
        RemainingSubscriptionNumbers := SubscriptionNumbers;
        N := StrLen(RemainingSubscriptionNumbers) div 2;
        for I := 0 to N do
            if StrLen(RemainingSubscriptionNumbers) > 0 then begin
                SubscriptionNumber := GetNextToken(RemainingSubscriptionNumbers, ',');
                SubscriptionId := GetSubscriptionIdBySubscriptionNumber(SubscriptionNumber);
                SendTraceTag('000070C', APIWebhookCategoryLbl, VERBOSITY::Normal,
                  StrSubstNo(IncreaseAttemptNumberForSubscriptionMsg, SubscriptionNumber, DateTimeToString(ProcessingDateTime)),
                  DATACLASSIFICATION::SystemMetadata);
                if SubscriptionId <> '' then begin
                    LogActivity(false, IncreaseAttemptNumberTitleTxt, GetSubscriptionDetails(SubscriptionId));
                    ClearFiltersFromNotificationsBuffer();
                    TempAPIWebhookNotificationAggr.SetRange("Subscription ID", SubscriptionId);
                    if TempAPIWebhookNotificationAggr.Find('-') then
                        repeat
                            if TempAPIWebhookNotificationAggr."Sending Scheduled Date Time" <= ProcessingDateTime then begin
                                TempAPIWebhookNotificationAggr."Attempt No." += 1;
                                TempAPIWebhookNotificationAggr.Modify();
                                SendTraceTag('000070Q', APIWebhookCategoryLbl, VERBOSITY::Normal,
                                  StrSubstNo(IncreaseAttemptNumberForNotificationMsg, SubscriptionNumber, TempAPIWebhookNotificationAggr."Change Type",
                                    DateTimeToString(TempAPIWebhookNotificationAggr."Last Modified Date Time"),
                                    TempAPIWebhookNotificationAggr."Attempt No.",
                                    DateTimeToString(TempAPIWebhookNotificationAggr."Sending Scheduled Date Time"),
                                    DateTimeToString(ProcessingDateTime)),
                                  DATACLASSIFICATION::SystemMetadata);
                            end else
                                SendTraceTag('000075T', APIWebhookCategoryLbl, VERBOSITY::Normal,
                                  StrSubstNo(DoNotIncreaseAttemptNumberForNotificationMsg, SubscriptionNumber,
                                    TempAPIWebhookNotificationAggr."Change Type",
                                    DateTimeToString(TempAPIWebhookNotificationAggr."Last Modified Date Time"),
                                    TempAPIWebhookNotificationAggr."Attempt No.",
                                    DateTimeToString(TempAPIWebhookNotificationAggr."Sending Scheduled Date Time"),
                                    DateTimeToString(ProcessingDateTime)),
                                  DATACLASSIFICATION::SystemMetadata);
                        until TempAPIWebhookNotificationAggr.Next() = 0;
                end;
            end else
                I := N;
    end;

    local procedure UpdateTablesFromBuffer(var EarliestRescheduleDateTime: DateTime)
    begin
        DeleteSubscriptionsWithTooManyFailures();
        DeleteProcessedNotifications();
        SaveFailedAggregateNotifications(EarliestRescheduleDateTime);
    end;

    local procedure DeleteProcessedNotifications()
    var
        APIWebhookNotification: Record "API Webhook Notification";
    begin
        SendTraceTag('000070D', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(DeleteProcessedNotificationsMsg, DateTimeToString(ProcessingDateTime)), DATACLASSIFICATION::SystemMetadata);
        APIWebhookNotification.SetFilter("Last Modified Date Time", '<=%1', ProcessingDateTime);
        if not APIWebhookNotification.IsEmpty() then
            APIWebhookNotification.DeleteAll(true);
    end;

    local procedure SaveFailedAggregateNotifications(var EarliestScheduledDateTime: DateTime)
    var
        APIWebhookNotificationAggr: Record "API Webhook Notification Aggr";
        ScheduledDateTime: DateTime;
    begin
        EarliestScheduledDateTime := 0DT;
        if not APIWebhookNotificationAggr.IsEmpty() then
            APIWebhookNotificationAggr.DeleteAll(true);
        ClearFiltersFromNotificationsBuffer();

        if not TempAPIWebhookNotificationAggr.Find('-') then
            exit;

        repeat
            APIWebhookNotificationAggr.TransferFields(TempAPIWebhookNotificationAggr, true);
            if APIWebhookNotificationAggr."Sending Scheduled Date Time" < ProcessingDateTime then begin
                ScheduledDateTime := ProcessingDateTime + GetDelayTimeForAttempt(TempAPIWebhookNotificationAggr."Attempt No.");
                APIWebhookNotificationAggr."Sending Scheduled Date Time" := ScheduledDateTime;
                if (ScheduledDateTime < EarliestScheduledDateTime) or (EarliestScheduledDateTime = 0DT) then
                    EarliestScheduledDateTime := ScheduledDateTime;
            end;
            SendTraceTag('000070F', APIWebhookCategoryLbl, VERBOSITY::Normal,
              StrSubstNo(SaveFailedNotificationMsg, APIWebhookNotificationAggr."Change Type",
                DateTimeToString(APIWebhookNotificationAggr."Last Modified Date Time"), APIWebhookNotificationAggr."Attempt No."),
              DATACLASSIFICATION::SystemMetadata);
            if not APIWebhookNotificationAggr.Insert(true) then begin
                SendTraceTag('000073A', APIWebhookCategoryLbl, VERBOSITY::Error,
                  StrSubstNo(CannotInsertAggregateNotificationErr,
                    APIWebhookNotificationAggr.ID, APIWebhookNotificationAggr."Change Type",
                    DateTimeToString(APIWebhookNotificationAggr."Last Modified Date Time"),
                    APIWebhookNotificationAggr."Attempt No.",
                    DateTimeToString(APIWebhookNotificationAggr."Sending Scheduled Date Time")),
                  DATACLASSIFICATION::SystemMetadata);
                exit;
            end;
        until TempAPIWebhookNotificationAggr.Next() = 0;

        SendTraceTag('000070E', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(SavedFailedNotificationsMsg, DateTimeToString(EarliestScheduledDateTime)),
          DATACLASSIFICATION::SystemMetadata);
    end;

    local procedure SendNotification(NotificationUrlNumber: Integer; NotificationUrl: Text; NotificationPayload: Text; var Reschedule: Boolean): Boolean
    var
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseBody: Text;
        ErrorMessage: Text;
        ErrorDetails: Text;
        Success: Boolean;
    begin
        if NotificationUrl = '' then begin
            SendTraceTag('000029Z', APIWebhookCategoryLbl, VERBOSITY::Error,
              StrSubstNo(EmptyNotificationUrlErr, NotificationUrlNumber), DATACLASSIFICATION::SystemMetadata);
            exit(true);
        end;

        if NotificationPayload = '' then begin
            SendTraceTag('00002A0', APIWebhookCategoryLbl, VERBOSITY::Normal,
              StrSubstNo(EmptyPayloadPerNotificationUrlErr, NotificationUrlNumber),
              DATACLASSIFICATION::SystemMetadata);
            exit(true);
        end;

        OnBeforeSendNotification(NotificationUrl, NotificationPayload);

        SendTraceTag('000029B', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(SendNotificationMsg, NotificationUrlNumber), DATACLASSIFICATION::SystemMetadata);
        Success := SendRequest(
            NotificationUrlNumber, NotificationUrl, NotificationPayload, ResponseBody, ErrorMessage, ErrorDetails, HttpStatusCode);
        if not Success then
            ErrorMessage += GetLastErrorText + ErrorMessage;

        OnAfterSendNotification(ErrorMessage, ErrorDetails, HttpStatusCode);

        if not Success then begin
            Reschedule := ShouldReschedule(HttpStatusCode);
            SendTraceTag('000076N', APIWebhookCategoryLbl, VERBOSITY::Warning,
              StrSubstNo(SendingNotificationFailedErr, NotificationUrl, HttpStatusCode, ErrorMessage, ErrorDetails),
              DATACLASSIFICATION::CustomerContent);
            LogActivity(true, NotificationFailedTitleTxt,
              StrSubstNo(FailedNotificationDetailsTxt, NotificationUrl, HttpStatusCode, ErrorMessage, ErrorDetails));
            if Reschedule then begin
                SendTraceTag('000029C', APIWebhookCategoryLbl, VERBOSITY::Warning,
                  StrSubstNo(FailedNotificationRescheduleMsg, NotificationUrlNumber, HttpStatusCode),
                  DATACLASSIFICATION::SystemMetadata);
                exit(false);
            end;

            SendTraceTag('000029D', APIWebhookCategoryLbl, VERBOSITY::Warning,
              StrSubstNo(FailedNotificationRejectedMsg, NotificationUrlNumber, HttpStatusCode),
              DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;

        SendTraceTag('000029E', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(SucceedNotificationMsg, NotificationUrlNumber), DATACLASSIFICATION::SystemMetadata);
        exit(true);
    end;

    [TryFunction]
    local procedure SendRequest(NotificationUrlNumber: Integer; NotificationUrl: Text; NotificationPayload: Text; var ResponseBody: Text; var ErrorMessage: Text; var ErrorDetails: Text; var HttpStatusCode: DotNet HttpStatusCode)
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        ResponseHeaders: DotNet NameValueCollection;
    begin
        if NotificationUrl = '' then begin
            SendTraceTag('00002A1', APIWebhookCategoryLbl, VERBOSITY::Warning,
              StrSubstNo(EmptyNotificationUrlErr, NotificationUrlNumber), DATACLASSIFICATION::SystemMetadata);
            Error(StrSubstNo(EmptyNotificationUrlErr, NotificationUrlNumber));
        end;

        if NotificationPayload = '' then begin
            SendTraceTag('00002A2', APIWebhookCategoryLbl, VERBOSITY::Warning,
              StrSubstNo(EmptyPayloadPerNotificationUrlErr, NotificationUrlNumber), DATACLASSIFICATION::SystemMetadata);
            Error(StrSubstNo(EmptyPayloadPerNotificationUrlErr, NotificationUrlNumber));
        end;

        HttpWebRequestMgt.Initialize(NotificationUrl);
        HttpWebRequestMgt.DisableUI;
        HttpWebRequestMgt.SetMethod('POST');
        HttpWebRequestMgt.SetReturnType('application/json');
        HttpWebRequestMgt.SetContentType('application/json');
        HttpWebRequestMgt.SetTimeout(GetSendingNotificationTimeout);
        HttpWebRequestMgt.AddBodyAsText(NotificationPayload);

        if not HttpWebRequestMgt.SendRequestAndReadTextResponse(ResponseBody, ErrorMessage, ErrorDetails, HttpStatusCode, ResponseHeaders) then begin
            if IsNull(HttpStatusCode) then
                SendTraceTag('00002A3', APIWebhookCategoryLbl, VERBOSITY::Warning,
                  StrSubstNo(CannotGetResponseErr, NotificationUrlNumber), DATACLASSIFICATION::SystemMetadata);
            Error(StrSubstNo(CannotGetResponseErr, NotificationUrlNumber));
        end;
    end;

    local procedure ShouldReschedule(var HttpStatusCode: DotNet HttpStatusCode): Boolean
    var
        HttpStatusCodeNumber: Integer;
    begin
        if IsNull(HttpStatusCode) then
            exit(true);

        HttpStatusCodeNumber := HttpStatusCode;

        // 5xx range - Server error
        // 408 - Request Timeout, 429 - Too Many Requests
        if ((HttpStatusCodeNumber >= 500) and (HttpStatusCodeNumber <= 599)) or
           (HttpStatusCodeNumber = 408) or (HttpStatusCodeNumber = 429)
        then
            exit(true);

        exit(false);
    end;

    local procedure GetEntityJObject(SubscriptionNumber: Text; var TempAPIWebhookNotificationAggr: Record "API Webhook Notification Aggr" temporary; var JSONObject: DotNet JObject): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        ResourceUrl: Text;
        LastModifiedDateTime: DateTime;
    begin
        ClearFiltersFromSubscriptionsBuffer();
        TempAPIWebhookSubscription.SetRange("Subscription Id", TempAPIWebhookNotificationAggr."Subscription ID");
        if not TempAPIWebhookSubscription.FindFirst() then begin
            SendTraceTag('000070G', APIWebhookCategoryLbl, VERBOSITY::Error,
              StrSubstNo(CannotFindSubscriptionErr, SubscriptionNumber), DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;

        ResourceUrl := GetEntityUrl(TempAPIWebhookNotificationAggr, TempAPIWebhookSubscription);
        if ResourceUrl = '' then
            exit(false);

        LastModifiedDateTime := TempAPIWebhookNotificationAggr."Last Modified Date Time";
        if LastModifiedDateTime = 0DT then
            if TempAPIWebhookNotificationAggr."Change Type" = TempAPIWebhookNotificationAggr."Change Type"::Collection then
                LastModifiedDateTime := CurrentDateTime()
            else
                SendTraceTag('00006P3', APIWebhookCategoryLbl, VERBOSITY::Warning,
                  StrSubstNo(EmptyLastModifiedDateTimeMsg, TempAPIWebhookNotificationAggr."Change Type",
                    TempAPIWebhookNotificationAggr."Attempt No."),
                  DATACLASSIFICATION::SystemMetadata);

        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JSONObject);
        JSONManagement.AddJPropertyToJObject(JSONObject, 'subscriptionId', TempAPIWebhookSubscription."Subscription Id");
        JSONManagement.AddJPropertyToJObject(JSONObject, 'clientState', TempAPIWebhookSubscription."Client State");
        JSONManagement.AddJPropertyToJObject(JSONObject, 'expirationDateTime', TempAPIWebhookSubscription."Expiration Date Time");
        JSONManagement.AddJPropertyToJObject(JSONObject, 'resource', ResourceUrl);
        JSONManagement.AddJPropertyToJObject(JSONObject, 'changeType', LowerCase(Format(TempAPIWebhookNotificationAggr."Change Type")));
        JSONManagement.AddJPropertyToJObject(JSONObject, 'lastModifiedDateTime', LastModifiedDateTime);
        exit(true);
    end;

    local procedure GetEntityUrl(var TempAPIWebhookNotificationAggr: Record "API Webhook Notification Aggr" temporary; var TempAPIWebhookSubscription: Record "API Webhook Subscription" temporary): Text
    var
        EntityUrl: Text;
    begin
        if TempAPIWebhookNotificationAggr."Change Type" <> TempAPIWebhookNotificationAggr."Change Type"::Collection then
            EntityUrl := GetSingleEntityUrl(TempAPIWebhookNotificationAggr, TempAPIWebhookSubscription)
        else
            EntityUrl := GetEntityCollectionUrl(TempAPIWebhookNotificationAggr, TempAPIWebhookSubscription);
        exit(EntityUrl);
    end;

    local procedure GetSingleEntityUrl(var TempAPIWebhookNotificationAggr: Record "API Webhook Notification Aggr" temporary; var TempAPIWebhookSubscription: Record "API Webhook Subscription" temporary): Text
    var
        ResourceUrl: Text;
        EntityUrl: Text;
        EntityKeyFieldType: Text;
        EntityKeyValue: Text;
    begin
        ResourceUrl := GetResourceUrlBySubscriptionId(TempAPIWebhookSubscription."Subscription Id");
        if ResourceUrl = '' then
            exit('');

        EntityKeyFieldType := GetEntityKeyFieldTypeBySubscriptionId(TempAPIWebhookSubscription."Subscription Id");
        if EntityKeyFieldType = '' then
            exit('');

        EntityKeyValue := GetUriEscapeFieldValue(EntityKeyFieldType, TempAPIWebhookNotificationAggr."Entity Key Value");

        EntityUrl := StrSubstNo('%1(%2)', ResourceUrl, EntityKeyValue);
        exit(EntityUrl);
    end;

    local procedure GetEntityCollectionUrl(var TempAPIWebhookNotificationAggr: Record "API Webhook Notification Aggr" temporary; var TempAPIWebhookSubscription: Record "API Webhook Subscription" temporary): Text
    var
        ResourceUrl: Text;
        EntityUrl: Text;
        FirstModifiedDateTimeUtcString: Text;
        FirstModifiedDateTimeAdjusted: DateTime;
        FirstModifiedDateTime: DateTime;
    begin
        ResourceUrl := GetResourceUrlBySubscriptionId(TempAPIWebhookSubscription."Subscription Id");
        if ResourceUrl = '' then
            exit('');

        FirstModifiedDateTime := GetFirstModifiedTimeBySubscriptionId(TempAPIWebhookNotificationAggr."Subscription ID");
        if FirstModifiedDateTime = 0DT then
            exit(ResourceUrl);

        if not HasLastModifiedDateTimeField(TempAPIWebhookSubscription) then
            exit(ResourceUrl);

        // Subtract 50 milliseconds to be sure we get all the changes since the SQL rounds in the different way than C# / AL.
        FirstModifiedDateTimeAdjusted := FirstModifiedDateTime - 50;
        FirstModifiedDateTimeUtcString := DateTimeToUtcString(FirstModifiedDateTimeAdjusted);
        EntityUrl := ResourceUrl + '?$filter=lastModifiedDateTime%20gt%20' + FirstModifiedDateTimeUtcString;
        exit(EntityUrl);
    end;

    local procedure GetUriEscapeFieldValue(FieldType: Text; FieldValue: Text): Text
    var
        FormattedValue: Text;
    begin
        case FieldType of
            'Code', 'Text':
                if FieldValue <> '' then
                    FormattedValue := AddQuotes(TypeHelper.UriEscapeDataString(FieldValue))
                else
                    FormattedValue := AddQuotes(FieldValue);
            'Option':
                FormattedValue := AddQuotes(TypeHelper.UriEscapeDataString(FieldValue));
            'DateFormula':
                FormattedValue := AddQuotes(FieldValue);
            else
                FormattedValue := FieldValue;
        end;
        exit(FormattedValue);
    end;

    local procedure AddQuotes(InText: Text) OutText: Text
    begin
        OutText := '''' + InText + '''';
    end;

    local procedure GetSubscriptionIdBySubscriptionNumber(SubscriptionNumber: Text): Text
    var
        SubscriptionId: Text;
    begin
        if not TempSubscriptionIdBySubscriptionNoNameValueBuffer.Get(SubscriptionNumber) then begin
            SendTraceTag('00002A4', APIWebhookCategoryLbl, VERBOSITY::Error,
              StrSubstNo(CannotFindCachedSubscriptionIdForSubscriptionNumberErr, SubscriptionNumber),
              DATACLASSIFICATION::SystemMetadata);
            exit('');
        end;

        SubscriptionId := TempSubscriptionIdBySubscriptionNoNameValueBuffer.Value;
        if SubscriptionId = '' then begin
            SendTraceTag('000070R', APIWebhookCategoryLbl, VERBOSITY::Error,
              StrSubstNo(CannotFindCachedSubscriptionIdForSubscriptionNumberErr, SubscriptionNumber),
              DATACLASSIFICATION::SystemMetadata);
            exit('');
        end;

        SendTraceTag('000070S', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(FoundCachedSubscriptionIdForSubscriptionNumberMsg, SubscriptionNumber),
          DATACLASSIFICATION::SystemMetadata);
        exit(SubscriptionId);
    end;

    local procedure GetEntityKeyFieldTypeBySubscriptionId(SubscriptionId: Text): Text
    var
        EntityKeyFieldType: Text;
    begin
        TempKeyFieldTypeBySubscriptionIdNameValueBuffer.SetRange(Name, SubscriptionId);
        if not TempKeyFieldTypeBySubscriptionIdNameValueBuffer.FindFirst() then begin
            SendTraceTag('00002A5', APIWebhookCategoryLbl, VERBOSITY::Error,
              CannotFindCachedEntityKeyFieldTypeForSubscriptionIdErr, DATACLASSIFICATION::SystemMetadata);
            exit('');
        end;

        EntityKeyFieldType := TempKeyFieldTypeBySubscriptionIdNameValueBuffer.Value;
        if EntityKeyFieldType = '' then begin
            SendTraceTag('000070T', APIWebhookCategoryLbl, VERBOSITY::Error,
              CannotFindCachedEntityKeyFieldTypeForSubscriptionIdErr, DATACLASSIFICATION::SystemMetadata);
            exit('');
        end;

        SendTraceTag('000070U', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(FoundCachedEntityKeyFieldTypeForSubscriptionIdMsg, EntityKeyFieldType),
          DATACLASSIFICATION::SystemMetadata);
        exit(EntityKeyFieldType);
    end;

    local procedure GetFirstModifiedTimeBySubscriptionId(SubscriptionId: Text): DateTime
    var
        FirstModifiedDateTime: DateTime;
    begin
        TempFirstModifiedDateTimeAPIWebhookNotification.SetRange("Subscription ID", SubscriptionId);
        if not TempFirstModifiedDateTimeAPIWebhookNotification.FindFirst() then begin
            SendTraceTag('0000730', APIWebhookCategoryLbl, VERBOSITY::Normal,
              CannotFindCachedFirstModifiedTimeForSubscriptionIdMsg, DATACLASSIFICATION::SystemMetadata);
            exit(0DT);
        end;

        FirstModifiedDateTime := TempFirstModifiedDateTimeAPIWebhookNotification."Last Modified Date Time";
        if FirstModifiedDateTime = 0DT then begin
            SendTraceTag('0000731', APIWebhookCategoryLbl, VERBOSITY::Normal,
              CannotFindCachedFirstModifiedTimeForSubscriptionIdMsg, DATACLASSIFICATION::SystemMetadata);
            exit(0DT);
        end;

        SendTraceTag('0000732', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(FoundCachedFirstModifiedTimeForSubscriptionIdMsg, DateTimeToString(FirstModifiedDateTime)),
          DATACLASSIFICATION::SystemMetadata);
        exit(FirstModifiedDateTime);
    end;

    local procedure GetResourceUrlBySubscriptionId(SubscriptionId: Text): Text
    var
        CachedValue: Variant;
        ResourceUrl: Text;
    begin
        if not ResourceUrlBySubscriptionIdDictionaryWrapper.TryGetValue(SubscriptionId, CachedValue) then begin
            SendTraceTag('00002A6', APIWebhookCategoryLbl, VERBOSITY::Error,
              CannotFindCachedResourceUrlForSubscriptionIdErr, DATACLASSIFICATION::SystemMetadata);
            exit('');
        end;

        ResourceUrl := CachedValue;
        if ResourceUrl = '' then begin
            SendTraceTag('000070V', APIWebhookCategoryLbl, VERBOSITY::Error,
              CannotFindCachedResourceUrlForSubscriptionIdErr, DATACLASSIFICATION::SystemMetadata);
            exit('');
        end;

        SendTraceTag('000070W', APIWebhookCategoryLbl, VERBOSITY::Normal,
          FoundCachedResourceUrlForSubscriptionIdMsg, DATACLASSIFICATION::SystemMetadata);
        exit(ResourceUrl);
    end;

    local procedure GetNotificationUrlBySubscriptionId(SubscriptionId: Text): Text
    var
        CachedValue: Variant;
        NotificationUrl: Text;
    begin
        if not NotificationUrlBySubscriptionIdDictionaryWrapper.TryGetValue(SubscriptionId, CachedValue) then begin
            SendTraceTag('00002A7', APIWebhookCategoryLbl, VERBOSITY::Error,
              CannotFindCachedNotificationUrlForSubscriptionIdErr, DATACLASSIFICATION::SystemMetadata);
            exit('');
        end;

        NotificationUrl := CachedValue;
        if NotificationUrl = '' then begin
            SendTraceTag('000070X', APIWebhookCategoryLbl, VERBOSITY::Error,
              CannotFindCachedNotificationUrlForSubscriptionIdErr, DATACLASSIFICATION::SystemMetadata);
            exit('');
        end;

        SendTraceTag('000070Y', APIWebhookCategoryLbl, VERBOSITY::Normal,
          FoundCachedNotificationUrlForSubscriptionIdMsg, DATACLASSIFICATION::SystemMetadata);
        exit(NotificationUrl);
    end;

    local procedure GetSubscriptionsPerNotificationUrl(NotificationUrlNumber: Integer; var NotificationUrl: Text; var SubscriptionNumbers: Text): Boolean
    var
        CachedKey: Variant;
        CachedValue: Variant;
    begin
        if not SubscriptionsPerNotificationUrlDictionaryWrapper.TryGetKeyValue(NotificationUrlNumber - 1, CachedKey, CachedValue) then begin
            SendTraceTag('000070H', APIWebhookCategoryLbl, VERBOSITY::Error,
              StrSubstNo(CannotFindCachedSubscriptionNumbersForNotificationUrlNumberErr, NotificationUrlNumber),
              DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;

        NotificationUrl := CachedKey;
        SubscriptionNumbers := CachedValue;
        if NotificationUrl = '' then begin
            SendTraceTag('000070Z', APIWebhookCategoryLbl, VERBOSITY::Error,
              StrSubstNo(CannotFindCachedSubscriptionNumbersForNotificationUrlNumberErr, NotificationUrlNumber),
              DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;

        if SubscriptionNumbers = '' then begin
            SendTraceTag('0000710', APIWebhookCategoryLbl, VERBOSITY::Error,
              StrSubstNo(CannotFindCachedNotificationUrlForNotificationUrlNumberErr, NotificationUrlNumber),
              DATACLASSIFICATION::SystemMetadata);
            exit(false);
        end;

        SendTraceTag('0000711', APIWebhookCategoryLbl, VERBOSITY::Normal,
          StrSubstNo(FoundCachedSubscriptionNumbersForNotificationUrlNumberMsg, SubscriptionNumbers, NotificationUrlNumber),
          DATACLASSIFICATION::SystemMetadata);
        exit(true);
    end;

    local procedure GetNextToken(var SeparatedValues: Text; Separator: Text): Text
    var
        Token: Text;
        Pos: Integer;
    begin
        Pos := StrPos(SeparatedValues, Separator);
        if Pos > 0 then begin
            Token := CopyStr(SeparatedValues, 1, Pos - 1);
            if Pos < StrLen(SeparatedValues) then
                SeparatedValues := CopyStr(SeparatedValues, Pos + 1)
            else
                SeparatedValues := '';
        end else begin
            Token := SeparatedValues;
            SeparatedValues := '';
        end;
        exit(Token);
    end;

    local procedure GetResourceUrl(var APIWebhookSubscription: Record "API Webhook Subscription"): Text
    var
        InStream: InStream;
        ResourceUrl: Text;
    begin
        APIWebhookSubscription."Resource Url Blob".CreateInStream(InStream);
        InStream.Read(ResourceUrl);
        exit(ResourceUrl);
    end;

    local procedure GetNotificationUrl(var APIWebhookSubscription: Record "API Webhook Subscription"): Text
    var
        InStream: InStream;
        NotificationUrl: Text;
    begin
        APIWebhookSubscription."Notification Url Blob".CreateInStream(InStream);
        InStream.Read(NotificationUrl);
        exit(NotificationUrl);
    end;

    local procedure HasLastModifiedDateTimeField(var APIWebhookSubscription: Record "API Webhook Subscription"): Boolean
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        Result: Boolean;
    begin
        if not APIWebhookNotificationMgt.GetEntity(APIWebhookSubscription, ApiWebhookEntity) then
            exit(false);

        RecordRef.Open(ApiWebhookEntity."Table No.");
        Result := APIWebhookNotificationMgt.FindLastModifiedDateTimeField(RecordRef, FieldRef);

        exit(Result);
    end;

    local procedure GetActiveSubscriptions(): Boolean
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        SubscriptionNumber: Integer;
    begin
        APIWebhookSubscription.SetAutoCalcFields("Notification Url Blob", "Resource Url Blob");
        APIWebhookSubscription.SetFilter("Expiration Date Time", '>=%1', ProcessingDateTime);
        APIWebhookSubscription.SetFilter("Company Name", '%1|%2', CompanyName, '');
        if not APIWebhookSubscription.FindSet() then
            exit(false);

        SubscriptionNumber := 0;
        repeat
            SubscriptionNumber += 1;
            Clear(TempAPIWebhookSubscription);
            TempAPIWebhookSubscription.Init();
            TempAPIWebhookSubscription.TransferFields(APIWebhookSubscription, true);
            Clear(TempAPIWebhookSubscription."Notification Url Blob");
            Clear(TempAPIWebhookSubscription."Resource Url Blob");
            TempAPIWebhookSubscription.Insert();
            CollectValuesInDictionaries(APIWebhookSubscription, SubscriptionNumber);
        until APIWebhookSubscription.Next() = 0;
        exit(true);
    end;

    local procedure DeleteObsoleteSubscriptions()
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
        ApiWebhookEntity: Record "Api Webhook Entity";
    begin
        if not APIWebhookSubscription.FindSet() then
            exit;

        repeat
            if not APIWebhookNotificationMgt.GetEntity(APIWebhookSubscription, ApiWebhookEntity) then begin
                SendTraceTag('0000299', APIWebhookCategoryLbl, VERBOSITY::Normal,
                  StrSubstNo(DeleteObsoleteSubscriptionMsg,
                    DateTimeToString(APIWebhookSubscription."Expiration Date Time"), APIWebhookSubscription."Source Table Id"),
                  DATACLASSIFICATION::SystemMetadata);
                LogActivity(false, DeleteObsoleteSubscriptionTitleTxt, GetSubscriptionDetails(APIWebhookSubscription."Subscription Id"));
                APIWebhookNotificationMgt.DeleteSubscription(APIWebhookSubscription);
            end;
        until APIWebhookSubscription.Next() = 0;
    end;

    local procedure DeleteExpiredSubscriptions()
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
    begin
        APIWebhookSubscription.SetFilter("Expiration Date Time", '<%1', ProcessingDateTime);
        APIWebhookSubscription.SetFilter("Company Name", '%1|%2', CompanyName, '');
        if not APIWebhookSubscription.FindSet() then
            exit;

        repeat
            SendTraceTag('000029A', APIWebhookCategoryLbl, VERBOSITY::Normal,
              StrSubstNo(DeleteExpiredSubscriptionMsg,
                DateTimeToString(APIWebhookSubscription."Expiration Date Time"), APIWebhookSubscription."Source Table Id"),
              DATACLASSIFICATION::SystemMetadata);
            LogActivity(false, DeleteExpiredSubscriptionTitleTxt,
              GetSubscriptionDetails(APIWebhookSubscription."Subscription Id"));
            APIWebhookNotificationMgt.DeleteSubscription(APIWebhookSubscription);
        until APIWebhookSubscription.Next() = 0;
    end;

    local procedure DeleteSubscriptionsWithTooManyFailures()
    var
        APIWebhookSubscription: Record "API Webhook Subscription";
    begin
        ClearFiltersFromNotificationsBuffer();
        TempAPIWebhookNotificationAggr.SetFilter("Attempt No.", '>%1', GetMaxNumberOfAttempts);
        if not TempAPIWebhookNotificationAggr.Find('-') then
            exit;

        repeat
            if APIWebhookSubscription.Get(TempAPIWebhookNotificationAggr."Subscription ID") then begin
                SendTraceTag('00007MN', APIWebhookCategoryLbl, VERBOSITY::Normal,
                  StrSubstNo(DeleteSubscriptionWithTooManyFailuresMsg,
                    DateTimeToString(APIWebhookSubscription."Expiration Date Time"), TempAPIWebhookNotificationAggr."Attempt No."),
                  DATACLASSIFICATION::SystemMetadata);
                LogActivity(false, DeleteSubscriptionWithTooManyFailuresTitleTxt,
                  GetSubscriptionDetails(APIWebhookSubscription."Subscription Id"));
                APIWebhookNotificationMgt.DeleteSubscription(APIWebhookSubscription);
            end;
        until TempAPIWebhookNotificationAggr.Next() = 0;
        TempAPIWebhookNotificationAggr.DeleteAll();
    end;

    local procedure DeleteInactiveJobs()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        OnBeforeDeleteInactiveJobs;
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"API Webhook Notification Send");
        JobQueueEntry.SetFilter(Status, '<>%1&<>%2', JobQueueEntry.Status::"In Process", JobQueueEntry.Status::Ready);
        if JobQueueEntry.FindSet() then
            repeat
                SendTraceTag('000070N', APIWebhookCategoryLbl, VERBOSITY::Normal,
                  StrSubstNo(DeleteInactiveJobMsg, JobQueueEntry.Status, DateTimeToString(JobQueueEntry."Earliest Start Date/Time")),
                  DATACLASSIFICATION::SystemMetadata);
                if JobQueueEntry.Delete(true) then;
            until JobQueueEntry.Next() = 0;

        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Ready);
        if JobQueueEntry.FindSet() then
            repeat
                if (JobQueueEntry."Job Queue Category Code" <> JobQueueCategoryCodeLbl) or JobQueueEntry."Recurring Job" then begin
                    SendTraceTag('000029Q', APIWebhookCategoryLbl, VERBOSITY::Warning,
                      StrSubstNo(DeleteJobWithWrongParametersMsg, JobQueueEntry."Job Queue Category Code",
                        JobQueueEntry."Recurring Job", DateTimeToString(JobQueueEntry."Earliest Start Date/Time")),
                      DATACLASSIFICATION::SystemMetadata);
                    if JobQueueEntry.Delete(true) then;
                end else begin
                    JobQueueEntry.CalcFields(Scheduled);
                    if not JobQueueEntry.Scheduled then begin
                        SendTraceTag('000075S', APIWebhookCategoryLbl, VERBOSITY::Warning,
                          StrSubstNo(DeleteReadyButNotScheduledJobMsg, DateTimeToString(JobQueueEntry."Earliest Start Date/Time")),
                          DATACLASSIFICATION::SystemMetadata);
                        if JobQueueEntry.Delete(true) then;
                    end;
                end;
            until JobQueueEntry.Next() = 0;
    end;

    local procedure ClearFiltersFromNotificationsBuffer()
    begin
        TempAPIWebhookNotificationAggr.SetRange(ID);
        TempAPIWebhookNotificationAggr.SetRange("Subscription ID");
        TempAPIWebhookNotificationAggr.SetRange("Entity Key Value");
        TempAPIWebhookNotificationAggr.SetRange("Attempt No.");
        TempAPIWebhookNotificationAggr.SetRange("Change Type");
    end;

    local procedure ClearFiltersFromSubscriptionsBuffer()
    begin
        TempAPIWebhookSubscription.SetRange("Subscription Id");
    end;

    local procedure IsApiSubscriptionEnabled(): Boolean
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        exit(GraphMgtGeneralTools.IsApiSubscriptionEnabled);
    end;

    local procedure GetMaxNumberOfNotifications(): Integer
    var
        ServerSetting: Codeunit "Server Setting";
        Handled: Boolean;
        MaxNumberOfNotifications: Integer;
    begin
        OnGetMaxNumberOfNotifications(Handled, MaxNumberOfNotifications);
        if Handled then
            exit(MaxNumberOfNotifications);

        MaxNumberOfNotifications := ServerSetting.GetApiSubscriptionMaxNumberOfNotifications;
        exit(MaxNumberOfNotifications);
    end;

    local procedure GetMaxNumberOfAttempts(): Integer
    var
        Handled: Boolean;
        Value: Integer;
    begin
        OnGetMaxNumberOfAttempts(Handled, Value);
        if Handled then
            exit(Value);

        exit(5);
    end;

    local procedure GetSendingNotificationTimeout(): Integer
    var
        ServerSetting: Codeunit "Server Setting";
        Handled: Boolean;
        Timeout: Integer;
    begin
        OnGetSendingNotificationTimeout(Handled, Timeout);
        if Handled then
            exit(Timeout);

        Timeout := ServerSetting.GetApiSubscriptionSendingNotificationTimeout;
        exit(Timeout);
    end;

    local procedure GetDelayTimeForAttempt(AttemptNumber: Integer): Integer
    begin
        case AttemptNumber of
            0, 1, 2:
                exit(60000);
            3:
                exit(600000);
            4:
                exit(6000000);
            else
                exit(60000000);
        end;
    end;

    [EventSubscriber(ObjectType::Table, 472, 'OnBeforeInsertLogEntry', '', false, false)]
    local procedure HandleOnBeforeInsertJobQueueLogEntry(var JobQueueLogEntry: Record "Job Queue Log Entry"; var JobQueueEntry: Record "Job Queue Entry")
    begin
        if JobQueueLogEntry.IsTemporary then
            exit;
        if JobQueueLogEntry.Status <> JobQueueLogEntry.Status::Error then
            exit;
        if JobQueueEntry."Object ID to Run" <> CODEUNIT::"API Webhook Notification Send" then
            exit;
        if JobQueueEntry."Object Type to Run" <> JobQueueEntry."Object Type to Run"::Codeunit then
            exit;

        SendTraceTag('000075U', APIWebhookCategoryLbl, VERBOSITY::Error,
          StrSubstNo(SendingJobFailedMsg, DateTimeToString(JobQueueEntry."Earliest Start Date/Time")),
          DATACLASSIFICATION::SystemMetadata);

        SendTraceTag('000076O', APIWebhookCategoryLbl, VERBOSITY::Error,
          StrSubstNo(FailedJobDetailsMsg, JobQueueLogEntry."Error Message"),
          DATACLASSIFICATION::CustomerContent);

        LogActivity(true, JobFailedTitleTxt, JobQueueLogEntry."Error Message");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessNotifications()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessNotifications()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteInactiveJobs()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendNotification(NotificationUrl: Text; Payload: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendNotification(var ErrorMessage: Text; var ErrorDetails: Text; var HttpStatusCode: DotNet HttpStatusCode)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMaxNumberOfNotifications(var Handled: Boolean; var Value: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMaxNumberOfAttempts(var Handled: Boolean; var Value: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSendingNotificationTimeout(var Handled: Boolean; var Value: Integer)
    begin
    end;

    local procedure DateTimeToString(Value: DateTime): Text
    begin
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2> <Hours24>:<Minutes,2>:<Seconds,2><Second dec.><Comma,.>'));
    end;

    [Scope('OnPrem')]
    procedure DateTimeToUtcString(DateTimeValue: DateTime): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        UtcDateTimeString: Text;
    begin
        // TODO replace getting UTC through JSON with the new function when such function is implemented on the platform side
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'value', DateTimeValue);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'value', UtcDateTimeString);
        exit(UtcDateTimeString);
    end;

    local procedure LogActivity(ActivityFailed: Boolean; ActivityDescription: Text; ActivityMessage: Text)
    var
        DummyAPIWebhookSubscription: Record "API Webhook Subscription";
        ActivityLog: Record "Activity Log";
        ActivityStatus: Option;
    begin
        if ActivityFailed then
            ActivityStatus := ActivityLog.Status::Failed
        else
            ActivityStatus := ActivityLog.Status::Success;
        ActivityLog.LogActivity(DummyAPIWebhookSubscription.RecordId, ActivityStatus, ActivityLogContextLbl,
          ActivityDescription, ActivityMessage);
    end;

    local procedure GetSubscriptionDetails(SubscriptionId: Text): Text
    var
        ResourceUrl: Text;
        NotificationUrl: Text;
    begin
        ResourceUrl := GetResourceUrlBySubscriptionId(SubscriptionId);
        NotificationUrl := GetNotificationUrlBySubscriptionId(SubscriptionId);
        exit(StrSubstNo(SubscriptionDetailsTxt, SubscriptionId, ResourceUrl, NotificationUrl));
    end;
}

