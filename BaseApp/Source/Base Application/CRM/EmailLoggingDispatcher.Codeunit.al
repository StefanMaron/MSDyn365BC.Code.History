#if not CLEAN22
codeunit 5064 "Email Logging Dispatcher"
{
    TableNo = "Job Queue Entry";
    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    trigger OnRun()
    begin
        RunJob(Rec);
    end;

    var
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
        Text001: Label 'Autodiscovery of exchange service failed.';
        Text002: Label 'The %1 folder does not exist. Verify that the path to the folder is correct in the Marketing Setup window.';
        Text003: Label 'The queue or storage folder has not been initialized. Enter the folder path in the Marketing Setup window.';
        Text101: Label 'Validating setup';
        Text102: Label 'Initialization and autodiscovery of Exchange web service is in progress';
        Text103: Label 'Opening queue folder';
        Text104: Label 'Opening storage folder';
        Text105: Label 'Reading email messages';
        Text106: Label 'Checking next email message';
        Text107: Label 'Logging email messages';
        Text108: Label 'Deleting email message from queue';
        ErrorContext: Text;
        Text109: Label 'The interaction template for email messages has not been specified in the Interaction Template Setup window.';
        Text110: Label 'An interaction template for email messages has been specified in the Interaction Template Setup window, but the template does not exist.';
        MessageMovedTxt: Label 'The email message has been moved.', Locked = true;
        MessageCopiedTxt: Label 'The email message has been copied.', Locked = true;
        MessageDeletedTxt: Label 'The email message has been deleted.', Locked = true;
        CannotMoveMessageTxt: Label 'Cannot move the email message.', Locked = true;
        CannotCopyMessageTxt: Label 'Cannot copy the email message.', Locked = true;
        CannotDeleteMessageTxt: Label 'Cannot delete the email message.', Locked = true;
        CannotMoveMessageDetailedTxt: Label 'Cannot move the email message. %1\\%2', Locked = true;
        CannotCopyMessageDetailedTxt: Label 'Cannot copy the email message. %1\\%2', Locked = true;
        CannotDeleteMessageDetailedTxt: Label 'Cannot delete the email message. %1\\%2', Locked = true;
        MessageAlreadyDeletedTxt: Label 'The email message has already been deleted.', Locked = true;
        MessageNotDeletedTxt: Label 'The email message has not been deleted.', Locked = true;
        MessageNotLoggedErr: Label 'The email has not been logged because it could not be moved. %1', Comment = '%1 - exception message';
        CannotDeleteMessageErr: Label 'Cannot delete the email message.';
        EmailLoggingTelemetryCategoryTxt: Label 'AL Email Logging', Locked = true;
        EmailLoggingDispatcherStartedTxt: Label 'Email Logging Dipatcher started.', Locked = true;
        EmailLoggingDispatcherFinishedTxt: Label 'Email Logging Dipatcher finished.', Locked = true;
        SalesPersonEmailTxt: Label 'The email is a salesperson email.', Locked = true;
        NotSalesPersonEmailTxt: Label 'The email is not a salesperson email.', Locked = true;
        ContactEmailTxt: Label 'The email is a contact email.', Locked = true;
        NotContactEmailTxt: Label 'The email is not a contact email.', Locked = true;
        ProcessMessageTxt: Label 'Processsing message.', Locked = true;
        CollectSalespersonRecipientsTxt: Label 'Collecting salesperson recipients.', Locked = true;
        SalespersonRecipientsFoundTxt: Label 'Salesperson recipients are found.', Locked = true;
        SalespersonRecipientsNotFoundTxt: Label 'Salesperson recipients are not found.', Locked = true;
        CollectContactRecipientsTxt: Label 'Collecting contact recipients.', Locked = true;
        ContactRecipientsFoundTxt: Label 'Contact recipients are found.', Locked = true;
        ContactRecipientsNotFoundTxt: Label 'Contact recipients are not found.', Locked = true;
        RunEmailBatchTxt: Label 'Running email batch.', Locked = true;
        ItemLinkedTxt: Label 'Item is linked.', Locked = true;
        ItemNotLinkedTxt: Label 'Item is not linked.', Locked = true;
        MessageForLoggingTxt: Label 'Message is for logging.', Locked = true;
        MessageNotForLoggingTxt: Label 'Message is not for logging.', Locked = true;
        MessageInOutBoundInteractionTxt: Label 'Message is in- or out-bound interaction.', Locked = true;
        MessageNotInOutBoundInteractionTxt: Label 'Message is not in- or out-bound interaction.', Locked = true;
        LogMessageAsInteractionTxt: Label 'Logging message as interaction.', Locked = true;
        InsertInteractionLogEntryTxt: Label 'Insert interaction log entry.', Locked = true;
        ProcessSimilarMessagesTxt: Label 'Process similar messages.', Locked = true;
        ProcessSimilarMessageTxt: Label 'Process similar message.', Locked = true;
        QueueFolderNotFoundTxt: Label 'Queue folder is not found.', Locked = true;
        StorageFolderNotFoundTxt: Label 'Storage folder is not found.', Locked = true;
        EmptyJobQueueEntryIdTxt: Label 'Job queue entry ID is null.', Locked = true;
        ExchangeServiceNotInitializedTxt: Label 'Exchange service is not initialized.', Locked = true;
        EmptyEmailMessageUrlTxt: Label 'Email message URL is empty.', Locked = true;
        NotEmptyEmailMessageUrlTxt: Label 'Email message URL is not empty.', Locked = true;
        AttachmentRecordAlreadyExistsTxt: Label 'Attachment record already exists.', Locked = true;
        AttachmentRecordNotFoundTxt: Label 'Attachment record is not found.', Locked = true;
        EmptyAutodiscoveryEmailTxt: Label 'Autodiscovery email address is empty.', Locked = true;
        NotEmptyAutodiscoveryEmailTxt: Label 'Autodiscovery email address is not empty.', Locked = true;
        InteractionTemplateSetupEmailNotSetTxt: Label 'Field E-mails on Interaction Template Setup is not set.', Locked = true;
        InteractionTemplateSetupNotFoundForEmailTxt: Label 'Interaction Template Setup is not found for email.', Locked = true;
        InteractionTemplateSetupEmailFoundTxt: Label 'Interaction Template Setup is found for email.', Locked = true;
        InteractionTemplateSetupNotConfiguredTxt: Label 'Interaction Template Setup is not configured.', Locked = true;
        NotEmptyRecipientTxt: Label 'Message recipient is not empty.', Locked = true;
        EmptyRecipientTxt: Label 'Message recipient is empty.', Locked = true;
        CopyMessageFromQueueToStorageFolderTxt: Label 'Copy message from queue to storage folder.', Locked = true;
        UpdateMessageTxt: Label 'Update message.', Locked = true;
        PublicFoldersNotInitializedTxt: Label 'Public folders are not initialized.', Locked = true;
        EmailLoggingDisabledTxt: Label 'Email logging is disabled.', Locked = true;
        EmailLoggingDisabledErr: Label 'Email logging is disabled.';
        NoLinkCommentMessageTxt: Label 'There is no link to the email because the email could not be copied.', Comment = 'Max 80 chars';
        NoLinkAttachmentMessageTxt: Label 'There is no link to the email because it could not be copied from the queue to the storage folder.';
        TextFileExtentionTxt: Label 'TXT', Locked = true;

    [NonDebuggable]
    local procedure RunJob(var JobQueueEntry: Record "Job Queue Entry")
    var
        MarketingSetup: Record "Marketing Setup";
        SetupEmailLogging: Codeunit "Setup Email Logging";
        StorageFolder: DotNet IEmailFolder;
        QueueFolder: DotNet IEmailFolder;
        WebCredentials: DotNet WebCredentials;
        OAuthCredentials: DotNet OAuthCredentials;
        Token: Text;
        TenantId: Text;
        Initialized: Boolean;
    begin
        if SetupEmailLogging.IsEmailLoggingUsingGraphApiFeatureEnabled() then
            exit;

        Session.LogMessage('0000BVL', EmailLoggingDispatcherStartedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        if IsNullGuid(JobQueueEntry.ID) then begin
            Session.LogMessage('0000BVM', EmptyJobQueueEntryIdTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit;
        end;

        SetErrorContext(Text101);
        CheckSetup(MarketingSetup);

        SetErrorContext(Text102);

        TenantId := MarketingSetup.GetExchangeTenantId();
        if TenantId <> '' then begin
            SetupEmailLogging.GetClientCredentialsAccessToken(TenantId, Token);
            OAuthCredentials := OAuthCredentials.OAuthCredentials(Token);
            Initialized := ExchangeWebServicesServer.Initialize2010WithUserImpersonation(MarketingSetup."Autodiscovery E-Mail Address",
                MarketingSetup."Exchange Service URL", OAuthCredentials, false);
        end else
            if MarketingSetup."Exchange Account User Name" <> '' then begin
                MarketingSetup.CreateExchangeAccountCredentials(WebCredentials);
                Initialized := ExchangeWebServicesServer.Initialize2010(MarketingSetup."Autodiscovery E-Mail Address",
                    MarketingSetup."Exchange Service URL", WebCredentials, false);
            end;

        if not Initialized then begin
            Session.LogMessage('0000BVP', ExchangeServiceNotInitializedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(Text001);
        end;

        SetErrorContext(Text103);
        if not ExchangeWebServicesServer.GetEmailFolder(MarketingSetup.GetQueueFolderUID(), QueueFolder) then begin
            Session.LogMessage('0000BVQ', QueueFolderNotFoundTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(Text002, MarketingSetup."Queue Folder Path");
        end;

        SetErrorContext(Text104);
        if not ExchangeWebServicesServer.GetEmailFolder(MarketingSetup.GetStorageFolderUID(), StorageFolder) then begin
            Session.LogMessage('0000BVR', StorageFolderNotFoundTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(Text002, MarketingSetup."Storage Folder Path");
        end;

        OnRunJobOnBeforeRunEMailBatch(ErrorContext, ExchangeWebServicesServer, MarketingSetup);
        RunEMailBatch(MarketingSetup."Email Batch Size", QueueFolder, StorageFolder);

        Session.LogMessage('0000BVS', EmailLoggingDispatcherFinishedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
    end;

    [Scope('OnPrem')]
    procedure CheckSetup(var MarketingSetup: Record "Marketing Setup")
    var
        ErrorMsg: Text;
    begin
        if not CheckInteractionTemplateSetup(ErrorMsg) then begin
            Session.LogMessage('0000BVT', InteractionTemplateSetupNotConfiguredTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(ErrorMsg);
        end;

        MarketingSetup.Get();

        if not MarketingSetup."Email Logging Enabled" then begin
            Session.LogMessage('0000CIE', EmailLoggingDisabledTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(EmailLoggingDisabledErr);
        end;

        if not (MarketingSetup."Queue Folder UID".HasValue and MarketingSetup."Storage Folder UID".HasValue) then begin
            Session.LogMessage('0000BVU', PublicFoldersNotInitializedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(Text003);
        end;

        if MarketingSetup."Autodiscovery E-Mail Address" = '' then
            Session.LogMessage('0000BVV', EmptyAutodiscoveryEmailTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
        else
            Session.LogMessage('0000BVW', NotEmptyAutodiscoveryEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        MarketingSetup.TestField("Autodiscovery E-Mail Address");
    end;

    [Scope('OnPrem')]
    procedure RunEMailBatch(BatchSize: Integer; var QueueFolder: DotNet IEmailFolder; var StorageFolder: DotNet IEmailFolder)
    var
        QueueFindResults: DotNet IFindEmailsResults;
        QueueMessage: DotNet IEmailMessage;
        StorageMessage: DotNet IEmailMessage;
        QueueEnumerator: DotNet IEnumerator;
        EmailsLeftInBatch: Integer;
        PageSize: Integer;
        RescanQueueFolder: Boolean;
        EmailMovedToStorage: Boolean;
    begin
        Session.LogMessage('0000BVX', RunEmailBatchTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        EmailsLeftInBatch := BatchSize;
        repeat
            SetErrorContext(Text105);

            PageSize := 50;
            if (BatchSize <> 0) and (EmailsLeftInBatch < PageSize) then
                PageSize := EmailsLeftInBatch;
            // Keep using zero offset, since all processed messages are deleted from the queue folder
            QueueFindResults := QueueFolder.FindEmailMessages(PageSize, 0);
            QueueEnumerator := QueueFindResults.GetEnumerator();
            while QueueEnumerator.MoveNext() do begin
                QueueMessage := QueueEnumerator.Current;
                RescanQueueFolder := ProcessMessage(QueueMessage, QueueFolder, StorageFolder, StorageMessage);
                SetErrorContext(Text108);
                EmailMovedToStorage := false;
                if not IsNull(StorageMessage) then
                    EmailMovedToStorage := QueueMessage.Id = StorageMessage.Id;
                if not EmailMovedToStorage then
                    DeleteMessage(QueueMessage, QueueFolder);
                if RescanQueueFolder then begin
                    QueueFolder.UpdateFolder();
                    QueueFindResults := QueueFolder.FindEmailMessages(PageSize, 0);
                    QueueEnumerator := QueueFindResults.GetEnumerator();
                end;
                RescanQueueFolder := false;
            end;
            EmailsLeftInBatch := EmailsLeftInBatch - PageSize;
            QueueFolder.UpdateFolder();
        until (not QueueFindResults.MoreAvailable) or ((BatchSize <> 0) and (EmailsLeftInBatch <= 0));
    end;

    local procedure DeleteMessage(var QueueMessage: DotNet IEmailMessage; var QueueFolder: DotNet IEmailFolder)
    var
        FoundMessage: DotNet IEmailMessage;
        MessageId: Text;
    begin
        MessageId := QueueMessage.Id();
        if not TryDeleteMessage(QueueMessage) then begin
            Session.LogMessage('0000C40', CannotDeleteMessageTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            QueueFolder.UpdateFolder();
            FoundMessage := QueueFolder.FindEmail(MessageId);
            if not IsNull(FoundMessage) then begin
                Session.LogMessage('0000C41', MessageNotDeletedTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                Error(CannotDeleteMessageErr);
            end;
            Session.LogMessage('0000C42', MessageAlreadyDeletedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        end;
    end;

    [TryFunction]
    local procedure TryDeleteMessage(var QueueMessage: DotNet IEmailMessage)
    begin
        QueueMessage.Delete();
    end;

    procedure GetErrorContext(): Text
    begin
        exit(ErrorContext);
    end;

    procedure SetErrorContext(NewContext: Text)
    begin
        ErrorContext := NewContext;
    end;

    procedure ItemLinkedFromAttachment(MessageId: Text; var Attachment: Record Attachment): Boolean
    begin
        Attachment.SetRange("Email Message Checksum", Attachment.Checksum(MessageId));
        if not Attachment.FindSet() then begin
            Session.LogMessage('0000BVY', ItemNotLinkedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;
        repeat
            if Attachment.GetMessageID() = MessageId then begin
                Session.LogMessage('0000BVZ', ItemLinkedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                exit(true);
            end;
        until (Attachment.Next() = 0);
        Session.LogMessage('0000BW0', ItemNotLinkedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        exit(false);
    end;

    procedure AttachmentRecordAlreadyExists(AttachmentNo: Text; var Attachment: Record Attachment): Boolean
    var
        No: Integer;
    begin
        if Evaluate(No, AttachmentNo) then begin
            if Attachment.Get(No) then begin
                Session.LogMessage('0000BW4', AttachmentRecordAlreadyExistsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                exit(true);
            end;
            Session.LogMessage('0000BW1', AttachmentRecordNotFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;
        Session.LogMessage('0000BW2', AttachmentRecordNotFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        exit(false);
    end;

    local procedure SalespersonRecipients(Message: DotNet IEmailMessage; var SegLine: Record "Segment Line"): Boolean
    var
        RecepientEnumerator: DotNet IEnumerator;
        Recepient: DotNet IEmailAddress;
        RecepientAddress: Text;
    begin
        Session.LogMessage('0000BW3', CollectSalespersonRecipientsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        RecepientEnumerator := Message.Recipients.GetEnumerator();
        while RecepientEnumerator.MoveNext() do begin
            Recepient := RecepientEnumerator.Current;
            RecepientAddress := Recepient.Address;
            if IsSalesperson(RecepientAddress, SegLine."Salesperson Code") then begin
                SegLine.Insert();
                SegLine."Line No." := SegLine."Line No." + 1;
            end;
        end;

        if not SegLine.IsEmpty() then begin
            Session.LogMessage('0000BW5', SalespersonRecipientsFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(true);
        end;

        Session.LogMessage('0000BW6', SalespersonRecipientsNotFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        exit(false);
    end;

    local procedure ContactRecipients(Message: DotNet IEmailMessage; var SegLine: Record "Segment Line"): Boolean
    var
        RecepientEnumerator: DotNet IEnumerator;
        RecepientAddress: DotNet IEmailAddress;
    begin
        Session.LogMessage('0000BW7', CollectContactRecipientsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        RecepientEnumerator := Message.Recipients.GetEnumerator();
        while RecepientEnumerator.MoveNext() do begin
            RecepientAddress := RecepientEnumerator.Current;
            if IsContact(RecepientAddress.Address, SegLine) then begin
                SegLine.Insert();
                SegLine."Line No." := SegLine."Line No." + 1;
            end;
        end;
        if not SegLine.IsEmpty() then begin
            Session.LogMessage('0000BW8', ContactRecipientsFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(true);
        end;

        Session.LogMessage('0000BW9', ContactRecipientsNotFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        exit(false);
    end;

    local procedure IsMessageToLog(QueueMessage: DotNet IEmailMessage; var SegLine: Record "Segment Line"; var Attachment: Record Attachment) Result: Boolean
    var
        Sender: DotNet IEmailAddress;
        QueueMessageIsSensitive: Boolean;
        SenderIsEmpty: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsMessageToLog(SegLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        QueueMessageIsSensitive := QueueMessage.IsSensitive;
        OnIsMessageToLogOnAfterCalcQueueMessageIsSensitive(QueueMessageIsSensitive);
        if QueueMessageIsSensitive then begin
            Session.LogMessage('0000BWA', MessageNotForLoggingTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;

        Sender := QueueMessage.SenderAddress;
        SenderIsEmpty := Sender.IsEmpty() or (QueueMessage.RecipientsCount = 0);
        OnIsMessageToLogOnAfterCalcSenderIsEmpty(SenderIsEmpty);
        if SenderIsEmpty then begin
            Session.LogMessage('0000BWB', MessageNotForLoggingTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;

        if AttachmentRecordAlreadyExists(QueueMessage.NavAttachmentNo, Attachment) then begin
            Session.LogMessage('0000BWC', MessageForLoggingTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(true);
        end;

        if not GetInboundOutboundInteraction(Sender.Address, SegLine, QueueMessage) then begin
            Session.LogMessage('0000BWD', MessageNotForLoggingTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;

        if not SegLine.IsEmpty() then begin
            Session.LogMessage('0000BWE', MessageForLoggingTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(true);
        end;

        Session.LogMessage('0000BWF', MessageNotForLoggingTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure UpdateSegLine(var SegLine: Record "Segment Line"; Emails: Code[10]; Subject: Text; DateSent: DotNet DateTime; DateReceived: DotNet DateTime; AttachmentNo: Integer)
    var
        LineDate: DotNet DateTime;
        DateTimeKind: DotNet DateTimeKind;
        InformationFlow: Integer;
    begin
        Session.LogMessage('0000BWG', UpdateMessageTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        InformationFlow := SegLine."Information Flow";
        SegLine.Validate("Interaction Template Code", Emails);
        SegLine."Information Flow" := InformationFlow;
        SegLine."Correspondence Type" := SegLine."Correspondence Type"::Email;
        SegLine.Description := CopyStr(Subject, 1, MaxStrLen(SegLine.Description));

        if SegLine."Information Flow" = SegLine."Information Flow"::Outbound then begin
            LineDate := DateSent;
            SegLine."Initiated By" := SegLine."Initiated By"::Us;
        end else begin
            LineDate := DateReceived;
            SegLine."Initiated By" := SegLine."Initiated By"::Them;
        end;

        // The date received from Exchange is UTC and to record the UTC date and time
        // using the AL functions requires datetime to be of the local date time kind.
        LineDate := LineDate.DateTime(LineDate.Ticks, DateTimeKind.Local);
        SegLine.Date := DT2Date(LineDate);
        SegLine."Time of Interaction" := DT2Time(LineDate);

        SegLine.Subject := CopyStr(Subject, 1, MaxStrLen(SegLine.Subject));
        SegLine."Attachment No." := AttachmentNo;
        SegLine.Modify();
    end;

    local procedure LogMessageAsInteraction(QueueMessage: DotNet IEmailMessage; StorageFolder: DotNet IEmailFolder; var SegLine: Record "Segment Line"; var Attachment: Record Attachment; var StorageMessage: DotNet IEmailMessage)
    var
        ErrorMessage: Text;
    begin
        if not LogMessageAsInteraction(QueueMessage, StorageFolder, SegLine, Attachment, StorageMessage, ErrorMessage) then
            Error(MessageNotLoggedErr, ErrorMessage);
        Commit();
    end;

    local procedure LogMessageAsInteraction(QueueMessage: DotNet IEmailMessage; StorageFolder: DotNet IEmailFolder; var SegLine: Record "Segment Line"; var Attachment: Record Attachment; var StorageMessage: DotNet IEmailMessage; var ErrorMessage: Text): Boolean
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        EntryNumbers: List of [Integer];
        Subject: Text;
        NextInteractLogEntryNo: Integer;
        EmailMovedToStorage: Boolean;
        EmailMoveError: Text;
    begin
        Session.LogMessage('0000BWH', LogMessageAsInteractionTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        if not SegLine.IsEmpty() then begin
            Session.LogMessage('0000BVN', NotEmptyRecipientTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

            Subject := QueueMessage.Subject;

            Attachment.Reset();
            Attachment.Init();
            Attachment."No." := SequenceNoMgt.GetNextSeqNo(DATABASE::Attachment);
            Attachment.InsertRecord();

            InteractionTemplateSetup.Get();
            SegLine.Reset();
            SegLine.FindSet(true);
            repeat
                UpdateSegLine(
                  SegLine, InteractionTemplateSetup."E-Mails", Subject, QueueMessage.DateTimeSent, QueueMessage.DateTimeReceived,
                  Attachment."No.");
            until SegLine.Next() = 0;

            if SegLine.FindSet() then
                repeat
                    NextInteractLogEntryNo := InsertInteractionLogEntry(SegLine, SequenceNoMgt.GetNextSeqNo(DATABASE::"Interaction Log Entry"));
                    OnLogMessageAsInteractionOnAfterInsertInteractionLogEntry(NextInteractLogEntryNo, Subject);
                    EntryNumbers.Add(NextInteractLogEntryNo);
                until SegLine.Next() = 0;
        end else
            Session.LogMessage('0000BWI', EmptyRecipientTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        if Attachment."No." <> 0 then begin
            Session.LogMessage('0000BWJ', CopyMessageFromQueueToStorageFolderTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

            if TryMoveMessage(QueueMessage, StorageFolder, EmailMovedToStorage) then
                if EmailMovedToStorage then begin
                    Session.LogMessage('0000ETD', MessageMovedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                    StorageMessage := QueueMessage;
                    LinkAttachmentToMessage(Attachment, StorageMessage);
                    exit(true);
                end;
            EmailMoveError := GetLastErrorText();
            Session.LogMessage('0000ETE', CannotMoveMessageTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            if EmailMoveError <> '' then
                Session.LogMessage('0000ETF', StrSubstNo(CannotMoveMessageDetailedTxt, EmailMoveError, GetLastErrorCallStack()), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

            if TryCopyMessage(QueueMessage, StorageFolder, StorageMessage) then begin
                Session.LogMessage('0000ETG', MessageCopiedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                LinkAttachmentToMessage(Attachment, StorageMessage);
                exit(true);
            end;
            Session.LogMessage('0000ETH', CannotCopyMessageTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Session.LogMessage('0000ETI', StrSubstNo(CannotCopyMessageDetailedTxt, GetLastErrorText(), GetLastErrorCallStack()), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

            if TryDeleteMessage(QueueMessage) then begin
                Session.LogMessage('0000ETJ', MessageDeletedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                AddNoLinkContent(Attachment);
                AddNoLinkComment(EntryNumbers);
                exit(true);
            end;
            Session.LogMessage('0000ETK', CannotDeleteMessageTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Session.LogMessage('0000ETL', StrSubstNo(CannotDeleteMessageDetailedTxt, GetLastErrorText(), GetLastErrorCallStack()), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

            ErrorMessage := EmailMoveError;
        end;

        exit(false);
    end;

    local procedure LinkAttachmentToMessage(var Attachment: Record Attachment; var StorageMessage: DotNet IEmailMessage)
    var
        OutStream: OutStream;
        EMailMessageUrl: Text;
    begin
        Attachment.LinkToMessage(StorageMessage.Id, StorageMessage.EntryId, true);
        StorageMessage.NavAttachmentNo := Format(Attachment."No.");
        StorageMessage.Update();
        Attachment."Email Message Url".CreateOutStream(OutStream);
        EMailMessageUrl := StorageMessage.LinkUrl();
        if EMailMessageUrl <> '' then begin
            Session.LogMessage('0000BWK', NotEmptyEmailMessageUrlTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            OutStream.Write(EMailMessageUrl);
        end else
            Session.LogMessage('0000BWL', EmptyEmailMessageUrlTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        Attachment.Modify();
    end;

    local procedure AddNoLinkContent(var Attachment: Record Attachment)
    begin
        Attachment."Storage Type" := Attachment."Storage Type"::Embedded;
        Attachment."Read Only" := true;
        Attachment."File Extension" := TextFileExtentionTxt;
        Attachment.Write(NoLinkAttachmentMessageTxt);
        Attachment.Modify();
    end;

    local procedure AddNoLinkComment(var LogEntryNumbers: List of [Integer])
    var
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        EntryNo: Integer;
        LineNo: Integer;
    begin
        foreach EntryNo in LogEntryNumbers do begin
            InterLogEntryCommentLine.SetRange("Entry No.", EntryNo);
            if InterLogEntryCommentLine.FindLast() then
                LineNo := InterLogEntryCommentLine."Line No." + 10000
            else
                LineNo := 10000;
            InterLogEntryCommentLine.Init();
            InterLogEntryCommentLine."Entry No." := EntryNo;
            InterLogEntryCommentLine."Line No." := LineNo;
            InterLogEntryCommentLine.Date := WorkDate();
            InterLogEntryCommentLine.Comment := CopyStr(NoLinkCommentMessageTxt, 1, MaxStrLen(InterLogEntryCommentLine.Comment));
            InterLogEntryCommentLine.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryMoveMessage(var QueueMessage: DotNet IEmailMessage; var StorageFolder: DotNet IEmailFolder; var Moved: Boolean)
    begin
        Moved := QueueMessage.MoveToFolder(StorageFolder);
    end;

    [TryFunction]
    local procedure TryCopyMessage(var QueueMessage: DotNet IEmailMessage; var StorageFolder: DotNet IEmailFolder; var StorageMessage: DotNet IEmailMessage)
    begin
        StorageMessage := QueueMessage.CopyToFolder(StorageFolder);
    end;

    procedure InsertInteractionLogEntry(SegLine: Record "Segment Line"; EntryNo: Integer): Integer
    var
        InteractLogEntry: Record "Interaction Log Entry";
    begin
        Session.LogMessage('0000BWM', InsertInteractionLogEntryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        InteractLogEntry.Init();
        InteractLogEntry."Entry No." := EntryNo;
        InteractLogEntry."Correspondence Type" := InteractLogEntry."Correspondence Type"::Email;
        InteractLogEntry.CopyFromSegment(SegLine);
        InteractLogEntry."E-Mail Logged" := true;

        InteractLogEntry.InsertRecord();
        EntryNo := InteractLogEntry."Entry No.";

        OnAfterInsertInteractionLogEntry();
        exit(EntryNo);
    end;

    procedure IsSalesperson(Email: Text; var SalespersonCode: Code[20]) Result: Boolean
    var
        Salesperson: Record "Salesperson/Purchaser";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsSalesperson(Email, SalespersonCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Email = '' then begin
            Session.LogMessage('0000BWN', NotSalesPersonEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;

        if StrLen(Email) > MaxStrLen(Salesperson."Search E-Mail") then begin
            Session.LogMessage('0000BWO', NotSalesPersonEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;

        Salesperson.SetCurrentKey("Search E-Mail");
        Salesperson.SetRange("Search E-Mail", Email);
        if Salesperson.FindFirst() then begin
            Session.LogMessage('0000BWP', SalesPersonEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            SalespersonCode := Salesperson.Code;
            exit(true);
        end;

        Session.LogMessage('0000BWQ', NotSalesPersonEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        exit(false);
    end;

    procedure IsContact(EMail: Text; var SegLine: Record "Segment Line") Result: Boolean
    var
        Cont: Record Contact;
        ContAltAddress: Record "Contact Alt. Address";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsContact(EMail, SegLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if EMail = '' then begin
            Session.LogMessage('0000BWR', NotContactEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;

        if StrLen(EMail) > MaxStrLen(Cont."Search E-Mail") then begin
            Session.LogMessage('0000BWS', NotContactEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;

        Cont.SetCurrentKey("Search E-Mail");
        Cont.SetRange("Search E-Mail", EMail);
        if Cont.FindFirst() then begin
            Session.LogMessage('0000BWT', ContactEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            SegLine."Contact No." := Cont."No.";
            SegLine."Contact Company No." := Cont."Company No.";
            SegLine."Contact Alt. Address Code" := '';
            exit(true);
        end;

        if StrLen(EMail) > MaxStrLen(ContAltAddress."Search E-Mail") then begin
            Session.LogMessage('0000BWU', NotContactEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;

        ContAltAddress.SetCurrentKey("Search E-Mail");
        ContAltAddress.SetRange("Search E-Mail", EMail);
        if ContAltAddress.FindFirst() then begin
            Session.LogMessage('0000BWV', ContactEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            SegLine."Contact No." := ContAltAddress."Contact No.";
            Cont.Get(ContAltAddress."Contact No.");
            SegLine."Contact Company No." := Cont."Company No.";
            SegLine."Contact Alt. Address Code" := ContAltAddress.Code;
            exit(true);
        end;

        Session.LogMessage('0000BWW', NotContactEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        exit(false);
    end;

    local procedure ProcessMessage(QueueMessage: DotNet IEmailMessage; QueueFolder: DotNet IEmailFolder; var StorageFolder: DotNet IEmailFolder; var StorageMessage: DotNet IEmailMessage) SimilarEmailsFound: Boolean
    var
        TempSegLine: Record "Segment Line" temporary;
        Attachment: Record Attachment;
    begin
        Session.LogMessage('0000BWX', ProcessMessageTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        TempSegLine.DeleteAll();
        TempSegLine.Init();

        Attachment.Init();
        Attachment.Reset();
        SimilarEmailsFound := false;
        SetErrorContext(Text106);
        if IsMessageToLog(QueueMessage, TempSegLine, Attachment) then begin
            SetErrorContext(Text107);
            LogMessageAsInteraction(QueueMessage, StorageFolder, TempSegLine, Attachment, StorageMessage);
            if not IsNull(StorageMessage) then
                SimilarEmailsFound := ProcessSimilarMessages(StorageMessage, QueueFolder, StorageFolder, QueueMessage.Id);
        end;
    end;

    procedure CheckInteractionTemplateSetup(var ErrorMsg: Text): Boolean
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
        InteractionTemplate: Record "Interaction Template";
    begin
        // Emails cannot be automatically logged unless the field Emails on Interaction Template Setup is set.
        InteractionTemplateSetup.Get();
        if InteractionTemplateSetup."E-Mails" = '' then begin
            Session.LogMessage('0000BWZ', InteractionTemplateSetupEmailNotSetTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            ErrorMsg := Text109;
            exit(false);
        end;

        // Since we have no guarantees that the Interaction Template for Emails exists, we check for it here.
        InteractionTemplate.SetFilter(Code, '=%1', InteractionTemplateSetup."E-Mails");
        if InteractionTemplate.IsEmpty() then begin
            Session.LogMessage('0000BX0', InteractionTemplateSetupNotFoundForEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            ErrorMsg := Text110;
            exit(false);
        end;

        Session.LogMessage('0000BX1', InteractionTemplateSetupEmailFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        exit(true);
    end;

    local procedure ProcessSimilarMessages(var PrimaryStorageMessage: DotNet IEmailMessage; var QueueFolder: DotNet IEmailFolder; var StorageFolder: DotNet IEmailFolder; PrimaryQueueMessageId: Text) FolderUpdateNeeded: Boolean
    var
        TempSegLine: Record "Segment Line" temporary;
        Attachment: Record Attachment;
        FindResults: DotNet IFindEmailsResults;
        Enumerator: DotNet IEnumerator;
        TargetMessage: DotNet IEmailMessage;
        Sender: DotNet IEmailAddress;
        StorageMessage: DotNet IEmailMessage;
        MessageId: Text;
        FolderOffset: Integer;
        EmailLogged: Boolean;
        EmailMovedToStorage: Boolean;
    begin
        Session.LogMessage('0000BX2', ProcessSimilarMessagesTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        QueueFolder.UseSampleEmailAsFilter(PrimaryStorageMessage);
        FolderOffset := 0;
        repeat
            FindResults := QueueFolder.FindEmailMessages(50, FolderOffset);

            Session.LogMessage('0000BX3', ProcessSimilarMessageTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

            if FindResults.TotalCount > 0 then begin
                Enumerator := FindResults.GetEnumerator();
                while Enumerator.MoveNext() do begin
                    TempSegLine.DeleteAll();
                    TempSegLine.Init();
                    TargetMessage := Enumerator.Current;
                    EmailLogged := false;
                    EmailMovedToStorage := false;
                    if TargetMessage.Id <> PrimaryQueueMessageId then begin
                        Sender := TargetMessage.SenderAddress;
                        if (PrimaryStorageMessage.Subject = TargetMessage.Subject) and
                           (PrimaryStorageMessage.Body = TargetMessage.Body)
                        then
                            if ExchangeWebServicesServer.CompareEmailAttachments(PrimaryStorageMessage, TargetMessage) then begin
                                MessageId := PrimaryStorageMessage.Id;
                                if ItemLinkedFromAttachment(MessageId, Attachment) then begin
                                    if not TryDeleteMessage(PrimaryStorageMessage) then;
                                    LogMessageAsInteraction(TargetMessage, StorageFolder, TempSegLine, Attachment, StorageMessage);
                                    if not IsNull(StorageMessage) then begin
                                        PrimaryStorageMessage := StorageMessage;
                                        EmailMovedToStorage := TargetMessage.Id = PrimaryStorageMessage.Id;
                                    end;
                                    if not EmailMovedToStorage then
                                        DeleteMessage(TargetMessage, QueueFolder);
                                    EmailLogged := true;
                                end;
                            end;
                        if not EmailLogged then
                            if AttachmentRecordAlreadyExists(TargetMessage.NavAttachmentNo, Attachment) then begin
                                LogMessageAsInteraction(TargetMessage, StorageFolder, TempSegLine, Attachment, StorageMessage);
                                if not IsNull(StorageMessage) then begin
                                    PrimaryStorageMessage := StorageMessage;
                                    EmailMovedToStorage := TargetMessage.Id = PrimaryStorageMessage.Id;
                                end;
                                if not EmailMovedToStorage then
                                    DeleteMessage(TargetMessage, QueueFolder);
                                EmailLogged := true;
                            end;
                        if EmailLogged then
                            FolderUpdateNeeded := true;
                    end;
                end;
                if FolderUpdateNeeded then
                    FolderOffset := 0
                else
                    FolderOffset := FindResults.NextPageOffset;
            end;
        until not FindResults.MoreAvailable;
    end;

    local procedure GetInboundOutboundInteraction(SenderAddress: Text; var SegLine: Record "Segment Line"; var QueueMessage: DotNet IEmailMessage): Boolean
    begin
        OnBeforeGetInboundOutboundInteraction(SenderAddress, SegLine);
        // Check if in- or out-bound and store sender and recipients in segment line(s)
        if IsSalesperson(SenderAddress, SegLine."Salesperson Code") then begin
            SegLine."Information Flow" := SegLine."Information Flow"::Outbound;
            if not ContactRecipients(QueueMessage, SegLine) then begin
                Session.LogMessage('0000BX4', MessageNotInOutBoundInteractionTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                exit(false);
            end;
        end else
            if IsContact(SenderAddress, SegLine) then begin
                SegLine."Information Flow" := SegLine."Information Flow"::Inbound;
                if not SalespersonRecipients(QueueMessage, SegLine) then begin
                    Session.LogMessage('0000BX5', MessageNotInOutBoundInteractionTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                    exit(false);
                end;
            end else begin
                Session.LogMessage('0000BX6', MessageNotInOutBoundInteractionTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                exit(false);
            end;

        Session.LogMessage('0000BX7', MessageInOutBoundInteractionTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInteractionLogEntry()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsMessageToLog(var SegmentLine: Record "Segment Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsSalesperson(var Email: Text; var SalespersonCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsContact(var Email: Text; var SegLine: Record "Segment Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInboundOutboundInteraction(var SenderAddress: Text; var SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsMessageToLogOnAfterCalcQueueMessageIsSensitive(var QueueMessageIsSensitive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsMessageToLogOnAfterCalcSenderIsEmpty(var SenderIsEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunJobOnBeforeRunEMailBatch(var ErrorContext: Text; var ExchangeWebServicesServer: Codeunit "Exchange Web Services Server"; MarketingSetup: Record "Marketing Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogMessageAsInteractionOnAfterInsertInteractionLogEntry(NextInteractLogEntryNo: Integer; Subject: Text)
    begin
    end;
}
#endif
