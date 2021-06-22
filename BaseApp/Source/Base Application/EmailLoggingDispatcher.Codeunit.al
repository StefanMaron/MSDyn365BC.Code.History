codeunit 5064 "Email Logging Dispatcher"
{
    TableNo = "Job Queue Entry";

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
        CannotDeleteMessageTxt: Label 'Cannot delete the email message.';
        MessageAlreadyDeletedTxt: Label 'The email message has already been deleted.', Locked = true;
        MessageNotDeletedTxt: Label 'The email message has not been deleted.', Locked = true;
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
        SendTraceTag('0000BVL', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, EmailLoggingDispatcherStartedTxt, DataClassification::SystemMetadata);

        if IsNullGuid(JobQueueEntry.ID) then begin
            SendTraceTag('0000BVM', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, EmptyJobQueueEntryIdTxt, DataClassification::SystemMetadata);
            exit;
        end;

        SetErrorContext(Text101);
        CheckSetup(MarketingSetup);

        SetErrorContext(Text102);

        if not IsNullGuid(MarketingSetup."Exchange Tenant Id Key") then begin
            TenantId := MarketingSetup.GetExchangeTenantId();
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
            SendTraceTag('0000BVP', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, ExchangeServiceNotInitializedTxt, DataClassification::SystemMetadata);
            Error(Text001);
        end;

        SetErrorContext(Text103);
        if not ExchangeWebServicesServer.GetEmailFolder(MarketingSetup.GetQueueFolderUID, QueueFolder) then begin
            SendTraceTag('0000BVQ', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, QueueFolderNotFoundTxt, DataClassification::SystemMetadata);
            Error(Text002, MarketingSetup."Queue Folder Path");
        end;

        SetErrorContext(Text104);
        if not ExchangeWebServicesServer.GetEmailFolder(MarketingSetup.GetStorageFolderUID, StorageFolder) then begin
            SendTraceTag('0000BVR', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, StorageFolderNotFoundTxt, DataClassification::SystemMetadata);
            Error(Text002, MarketingSetup."Storage Folder Path");
        end;

        RunEMailBatch(MarketingSetup."Email Batch Size", QueueFolder, StorageFolder);

        SendTraceTag('0000BVS', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, EmailLoggingDispatcherFinishedTxt, DataClassification::SystemMetadata);
    end;

    [Scope('OnPrem')]
    procedure CheckSetup(var MarketingSetup: Record "Marketing Setup")
    var
        ErrorMsg: Text;
    begin
        if not CheckInteractionTemplateSetup(ErrorMsg) then begin
            SendTraceTag('0000BVT', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, InteractionTemplateSetupNotConfiguredTxt, DataClassification::SystemMetadata);
            Error(ErrorMsg);
        end;

        MarketingSetup.Get();

        if not MarketingSetup."Email Logging Enabled" then begin
            SendTraceTag('0000CIE', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, EmailLoggingDisabledTxt, DataClassification::SystemMetadata);
            Error(EmailLoggingDisabledErr);
        end;

        if not (MarketingSetup."Queue Folder UID".HasValue and MarketingSetup."Storage Folder UID".HasValue) then begin
            SendTraceTag('0000BVU', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, PublicFoldersNotInitializedTxt, DataClassification::SystemMetadata);
            Error(Text003);
        end;

        if MarketingSetup."Autodiscovery E-Mail Address" = '' then
            SendTraceTag('0000BVV', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, EmptyAutodiscoveryEmailTxt, DataClassification::SystemMetadata)
        else
            SendTraceTag('0000BVW', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, NotEmptyAutodiscoveryEmailTxt, DataClassification::SystemMetadata);
        MarketingSetup.TestField("Autodiscovery E-Mail Address");
    end;

    [Scope('OnPrem')]
    procedure RunEMailBatch(BatchSize: Integer; var QueueFolder: DotNet IEmailFolder; var StorageFolder: DotNet IEmailFolder)
    var
        QueueFindResults: DotNet IFindEmailsResults;
        QueueMessage: DotNet IEmailMessage;
        QueueEnumerator: DotNet IEnumerator;
        EmailsLeftInBatch: Integer;
        PageSize: Integer;
        RescanQueueFolder: Boolean;
    begin
        SendTraceTag('0000BVX', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, RunEmailBatchTxt, DataClassification::SystemMetadata);

        EmailsLeftInBatch := BatchSize;
        repeat
            SetErrorContext(Text105);

            PageSize := 50;
            if (BatchSize <> 0) and (EmailsLeftInBatch < PageSize) then
                PageSize := EmailsLeftInBatch;
            // Keep using zero offset, since all processed messages are deleted from the queue folder
            QueueFindResults := QueueFolder.FindEmailMessages(PageSize, 0);
            QueueEnumerator := QueueFindResults.GetEnumerator;
            while QueueEnumerator.MoveNext do begin
                QueueMessage := QueueEnumerator.Current;
                RescanQueueFolder := ProcessMessage(QueueMessage, QueueFolder, StorageFolder);
                SetErrorContext(Text108);
                DeleteMessage(QueueMessage, QueueFolder);
                if RescanQueueFolder then begin
                    QueueFolder.UpdateFolder;
                    QueueFindResults := QueueFolder.FindEmailMessages(PageSize, 0);
                    QueueEnumerator := QueueFindResults.GetEnumerator;
                end;
                RescanQueueFolder := false;
            end;
            EmailsLeftInBatch := EmailsLeftInBatch - PageSize;
            QueueFolder.UpdateFolder;
        until (not QueueFindResults.MoreAvailable) or ((BatchSize <> 0) and (EmailsLeftInBatch <= 0));
    end;

    local procedure DeleteMessage(var QueueMessage: DotNet IEmailMessage; var QueueFolder: DotNet IEmailFolder)
    var
        FoundMessage: DotNet IEmailMessage;
        MessageId: Text;
    begin
        MessageId := QueueMessage.Id();
        if not TryDeleteMessage(QueueMessage) then begin
            SendTraceTag('0000C40', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, CannotDeleteMessageTxt, DataClassification::SystemMetadata);
            QueueFolder.UpdateFolder();
            FoundMessage := QueueFolder.FindEmail(MessageId);
            if not IsNull(FoundMessage) then begin
                SendTraceTag('0000C41', EmailLoggingTelemetryCategoryTxt, Verbosity::Error, MessageNotDeletedTxt, DataClassification::SystemMetadata);
                Error(CannotDeleteMessageErr);
            end;
            SendTraceTag('0000C42', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageAlreadyDeletedTxt, DataClassification::SystemMetadata);
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
        if not Attachment.FindSet then begin
            SendTraceTag('0000BVY', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ItemNotLinkedTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        repeat
            if Attachment.GetMessageID = MessageId then begin
                SendTraceTag('0000BVZ', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ItemLinkedTxt, DataClassification::SystemMetadata);
                exit(true);
            end;
        until (Attachment.Next = 0);
        SendTraceTag('0000BW0', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ItemNotLinkedTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    procedure AttachmentRecordAlreadyExists(AttachmentNo: Text; var Attachment: Record Attachment): Boolean
    var
        No: Integer;
    begin
        if Evaluate(No, AttachmentNo) then begin
            if Attachment.Get(No) then begin
                SendTraceTag('0000BW4', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, AttachmentRecordAlreadyExistsTxt, DataClassification::SystemMetadata);
                exit(true);
            end;
            SendTraceTag('0000BW1', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, AttachmentRecordNotFoundTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        SendTraceTag('0000BW2', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, AttachmentRecordNotFoundTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    local procedure SalespersonRecipients(Message: DotNet IEmailMessage; var SegLine: Record "Segment Line"): Boolean
    var
        RecepientEnumerator: DotNet IEnumerator;
        Recepient: DotNet IEmailAddress;
        RecepientAddress: Text;
    begin
        SendTraceTag('0000BW3', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CollectSalespersonRecipientsTxt, DataClassification::SystemMetadata);

        RecepientEnumerator := Message.Recipients.GetEnumerator;
        while RecepientEnumerator.MoveNext do begin
            Recepient := RecepientEnumerator.Current;
            RecepientAddress := Recepient.Address;
            if IsSalesperson(RecepientAddress, SegLine."Salesperson Code") then begin
                SegLine.Insert();
                SegLine."Line No." := SegLine."Line No." + 1;
            end;
        end;

        if not SegLine.IsEmpty then begin
            SendTraceTag('0000BW5', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, SalespersonRecipientsFoundTxt, DataClassification::SystemMetadata);
            exit(true);
        end;

        SendTraceTag('0000BW6', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, SalespersonRecipientsNotFoundTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    local procedure ContactRecipients(Message: DotNet IEmailMessage; var SegLine: Record "Segment Line"): Boolean
    var
        RecepientEnumerator: DotNet IEnumerator;
        RecepientAddress: DotNet IEmailAddress;
    begin
        SendTraceTag('0000BW7', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CollectContactRecipientsTxt, DataClassification::SystemMetadata);

        RecepientEnumerator := Message.Recipients.GetEnumerator;
        while RecepientEnumerator.MoveNext do begin
            RecepientAddress := RecepientEnumerator.Current;
            if IsContact(RecepientAddress.Address, SegLine) then begin
                SegLine.Insert();
                SegLine."Line No." := SegLine."Line No." + 1;
            end;
        end;
        if not SegLine.IsEmpty then begin
            SendTraceTag('0000BW8', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ContactRecipientsFoundTxt, DataClassification::SystemMetadata);
            exit(true);
        end;

        SendTraceTag('0000BW9', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ContactRecipientsNotFoundTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    local procedure IsMessageToLog(QueueMessage: DotNet IEmailMessage; var SegLine: Record "Segment Line"; var Attachment: Record Attachment): Boolean
    var
        Sender: DotNet IEmailAddress;
    begin
        if QueueMessage.IsSensitive then begin
            SendTraceTag('0000BWA', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageNotForLoggingTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        Sender := QueueMessage.SenderAddress;
        if Sender.IsEmpty or (QueueMessage.RecipientsCount = 0) then begin
            SendTraceTag('0000BWB', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageNotForLoggingTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        if AttachmentRecordAlreadyExists(QueueMessage.NavAttachmentNo, Attachment) then begin
            SendTraceTag('0000BWC', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageForLoggingTxt, DataClassification::SystemMetadata);
            exit(true);
        end;

        if not GetInboundOutboundInteraction(Sender.Address, SegLine, QueueMessage) then begin
            SendTraceTag('0000BWD', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageNotForLoggingTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        if not SegLine.IsEmpty then begin
            SendTraceTag('0000BWE', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageForLoggingTxt, DataClassification::SystemMetadata);
            exit(true);
        end;

        SendTraceTag('0000BWF', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageNotForLoggingTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure UpdateSegLine(var SegLine: Record "Segment Line"; Emails: Code[10]; Subject: Text; DateSent: DotNet DateTime; DateReceived: DotNet DateTime; AttachmentNo: Integer)
    var
        LineDate: DotNet DateTime;
        DateTimeKind: DotNet DateTimeKind;
        InformationFlow: Integer;
    begin
        SendTraceTag('0000BWG', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, UpdateMessageTxt, DataClassification::SystemMetadata);

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
        InteractLogEntry: Record "Interaction Log Entry";
        InteractionTemplateSetup: Record "Interaction Template Setup";
        OStream: OutStream;
        Subject: Text;
        EMailMessageUrl: Text;
        AttachmentNo: Integer;
        NextInteractLogEntryNo: Integer;
    begin
        SendTraceTag('0000BWH', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, LogMessageAsInteractionTxt, DataClassification::SystemMetadata);

        if not SegLine.IsEmpty then begin
            SendTraceTag('0000BVN', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, NotEmptyRecipientTxt, DataClassification::SystemMetadata);

            Subject := QueueMessage.Subject;

            Attachment.Reset();
            Attachment.LockTable();
            if Attachment.FindLast then
                AttachmentNo := Attachment."No." + 1
            else
                AttachmentNo := 1;

            Attachment.Init();
            Attachment."No." := AttachmentNo;
            Attachment.Insert();

            InteractionTemplateSetup.Get();
            SegLine.Reset();
            SegLine.FindSet(true);
            repeat
                UpdateSegLine(
                  SegLine, InteractionTemplateSetup."E-Mails", Subject, QueueMessage.DateTimeSent, QueueMessage.DateTimeReceived,
                  Attachment."No.");
            until SegLine.Next = 0;

            InteractLogEntry.LockTable();
            if InteractLogEntry.FindLast then
                NextInteractLogEntryNo := InteractLogEntry."Entry No.";
            if SegLine.FindSet then
                repeat
                    NextInteractLogEntryNo := NextInteractLogEntryNo + 1;
                    InsertInteractionLogEntry(SegLine, NextInteractLogEntryNo);
                until SegLine.Next = 0;
        end else
            SendTraceTag('0000BWI', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, EmptyRecipientTxt, DataClassification::SystemMetadata);

        if Attachment."No." <> 0 then begin
            SendTraceTag('0000BWJ', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CopyMessageFromQueueToStorageFolderTxt, DataClassification::SystemMetadata);
            StorageMessage := QueueMessage.CopyToFolder(StorageFolder);
            Attachment.LinkToMessage(StorageMessage.Id, StorageMessage.EntryId, true);
            StorageMessage.NavAttachmentNo := Format(Attachment."No.");
            StorageMessage.Update;

            Attachment."Email Message Url".CreateOutStream(OStream);
            EMailMessageUrl := StorageMessage.LinkUrl;
            if EMailMessageUrl <> '' then begin
                SendTraceTag('0000BWK', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, NotEmptyEmailMessageUrlTxt, DataClassification::SystemMetadata);
                OStream.Write(EMailMessageUrl);
            end else
                SendTraceTag('0000BWL', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, EmptyEmailMessageUrlTxt, DataClassification::SystemMetadata);
            Attachment.Modify();

            Commit();
        end;
    end;

    procedure InsertInteractionLogEntry(SegLine: Record "Segment Line"; EntryNo: Integer)
    var
        InteractLogEntry: Record "Interaction Log Entry";
    begin
        SendTraceTag('0000BWM', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InsertInteractionLogEntryTxt, DataClassification::SystemMetadata);

        InteractLogEntry.Init();
        InteractLogEntry."Entry No." := EntryNo;
        InteractLogEntry."Correspondence Type" := InteractLogEntry."Correspondence Type"::Email;
        InteractLogEntry.CopyFromSegment(SegLine);
        InteractLogEntry."E-Mail Logged" := true;
        InteractLogEntry.Insert();
        OnAfterInsertInteractionLogEntry;
    end;

    procedure IsSalesperson(Email: Text; var SalespersonCode: Code[20]): Boolean
    var
        Salesperson: Record "Salesperson/Purchaser";
    begin
        if Email = '' then begin
            SendTraceTag('0000BWN', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, NotSalesPersonEmailTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        if StrLen(Email) > MaxStrLen(Salesperson."Search E-Mail") then begin
            SendTraceTag('0000BWO', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, NotSalesPersonEmailTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        Salesperson.SetCurrentKey("Search E-Mail");
        Salesperson.SetRange("Search E-Mail", Email);
        if Salesperson.FindFirst then begin
            SendTraceTag('0000BWP', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, SalesPersonEmailTxt, DataClassification::SystemMetadata);
            SalespersonCode := Salesperson.Code;
            exit(true);
        end;

        SendTraceTag('0000BWQ', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, NotSalesPersonEmailTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    procedure IsContact(EMail: Text; var SegLine: Record "Segment Line"): Boolean
    var
        Cont: Record Contact;
        ContAltAddress: Record "Contact Alt. Address";
    begin
        if EMail = '' then begin
            SendTraceTag('0000BWR', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, NotContactEmailTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        if StrLen(EMail) > MaxStrLen(Cont."Search E-Mail") then begin
            SendTraceTag('0000BWS', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, NotContactEmailTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        Cont.SetCurrentKey("Search E-Mail");
        Cont.SetRange("Search E-Mail", EMail);
        if Cont.FindFirst then begin
            SendTraceTag('0000BWT', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ContactEmailTxt, DataClassification::SystemMetadata);
            SegLine."Contact No." := Cont."No.";
            SegLine."Contact Company No." := Cont."Company No.";
            SegLine."Contact Alt. Address Code" := '';
            exit(true);
        end;

        if StrLen(EMail) > MaxStrLen(ContAltAddress."Search E-Mail") then begin
            SendTraceTag('0000BWU', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, NotContactEmailTxt, DataClassification::SystemMetadata);
            exit(false);
        end;

        ContAltAddress.SetCurrentKey("Search E-Mail");
        ContAltAddress.SetRange("Search E-Mail", EMail);
        if ContAltAddress.FindFirst then begin
            SendTraceTag('0000BWV', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ContactEmailTxt, DataClassification::SystemMetadata);
            SegLine."Contact No." := ContAltAddress."Contact No.";
            Cont.Get(ContAltAddress."Contact No.");
            SegLine."Contact Company No." := Cont."Company No.";
            SegLine."Contact Alt. Address Code" := ContAltAddress.Code;
            exit(true);
        end;

        SendTraceTag('0000BWW', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, NotContactEmailTxt, DataClassification::SystemMetadata);
        exit(false);
    end;

    local procedure ProcessMessage(QueueMessage: DotNet IEmailMessage; QueueFolder: DotNet IEmailFolder; StorageFolder: DotNet IEmailFolder) SimilarEmailsFound: Boolean
    var
        TempSegLine: Record "Segment Line" temporary;
        Attachment: Record Attachment;
        StorageMessage: DotNet IEmailMessage;
    begin
        SendTraceTag('0000BWX', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ProcessMessageTxt, DataClassification::SystemMetadata);

        TempSegLine.DeleteAll();
        TempSegLine.Init();

        Attachment.Init();
        Attachment.Reset();
        SimilarEmailsFound := false;
        SetErrorContext(Text106);
        if IsMessageToLog(QueueMessage, TempSegLine, Attachment) then begin
            SetErrorContext(Text107);
            LogMessageAsInteraction(QueueMessage, StorageFolder, TempSegLine, Attachment, StorageMessage);
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
            SendTraceTag('0000BWZ', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InteractionTemplateSetupEmailNotSetTxt, DataClassification::SystemMetadata);
            ErrorMsg := Text109;
            exit(false);
        end;

        // Since we have no guarantees that the Interaction Template for Emails exists, we check for it here.
        InteractionTemplate.SetFilter(Code, '=%1', InteractionTemplateSetup."E-Mails");
        if not InteractionTemplate.FindFirst then begin
            SendTraceTag('0000BX0', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InteractionTemplateSetupNotFoundForEmailTxt, DataClassification::SystemMetadata);
            ErrorMsg := Text110;
            exit(false);
        end;

        SendTraceTag('0000BX1', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InteractionTemplateSetupEmailFoundTxt, DataClassification::SystemMetadata);
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
        StorageMessage2: DotNet IEmailMessage;
        MessageId: Text;
        FolderOffset: Integer;
        EmailLogged: Boolean;
    begin
        SendTraceTag('0000BX2', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ProcessSimilarMessagesTxt, DataClassification::SystemMetadata);

        QueueFolder.UseSampleEmailAsFilter(PrimaryStorageMessage);
        FolderOffset := 0;
        repeat
            FindResults := QueueFolder.FindEmailMessages(50, FolderOffset);

            SendTraceTag('0000BX3', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ProcessSimilarMessageTxt, DataClassification::SystemMetadata);

            if FindResults.TotalCount > 0 then begin
                Enumerator := FindResults.GetEnumerator;
                while Enumerator.MoveNext do begin
                    TempSegLine.DeleteAll();
                    TempSegLine.Init();
                    TargetMessage := Enumerator.Current;
                    EmailLogged := false;
                    if TargetMessage.Id <> PrimaryQueueMessageId then begin
                        Sender := TargetMessage.SenderAddress;
                        if (PrimaryStorageMessage.Subject = TargetMessage.Subject) and
                           (PrimaryStorageMessage.Body = TargetMessage.Body)
                        then begin
                            if ExchangeWebServicesServer.CompareEmailAttachments(PrimaryStorageMessage, TargetMessage) then begin
                                MessageId := PrimaryStorageMessage.Id;
                                if ItemLinkedFromAttachment(MessageId, Attachment) then begin
                                    PrimaryStorageMessage.Delete();
                                    LogMessageAsInteraction(TargetMessage, StorageFolder, TempSegLine, Attachment, StorageMessage2);
                                    PrimaryStorageMessage := StorageMessage2;
                                    TargetMessage.Delete();
                                    EmailLogged := true;
                                end;
                            end
                        end;
                        if not EmailLogged then
                            if AttachmentRecordAlreadyExists(TargetMessage.NavAttachmentNo, Attachment) then begin
                                LogMessageAsInteraction(TargetMessage, StorageFolder, TempSegLine, Attachment, StorageMessage2);
                                PrimaryStorageMessage := StorageMessage2;
                                TargetMessage.Delete();
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
                SendTraceTag('0000BX4', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageNotInOutBoundInteractionTxt, DataClassification::SystemMetadata);
                exit(false);
            end;
        end else begin
            if IsContact(SenderAddress, SegLine) then begin
                SegLine."Information Flow" := SegLine."Information Flow"::Inbound;
                if not SalespersonRecipients(QueueMessage, SegLine) then begin
                    SendTraceTag('0000BX5', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageNotInOutBoundInteractionTxt, DataClassification::SystemMetadata);
                    exit(false);
                end;
            end else begin
                SendTraceTag('0000BX6', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageNotInOutBoundInteractionTxt, DataClassification::SystemMetadata);
                exit(false);
            end;
        end;

        SendTraceTag('0000BX7', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageInOutBoundInteractionTxt, DataClassification::SystemMetadata);
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInteractionLogEntry()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInboundOutboundInteraction(SenderAddress: Text; var SegmentLine: Record "Segment Line")
    begin
    end;
}

