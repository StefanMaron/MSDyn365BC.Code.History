codeunit 5064 "Email Logging Dispatcher"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        MarketingSetup: Record "Marketing Setup";
        StorageFolder: DotNet IEmailFolder;
        QueueFolder: DotNet IEmailFolder;
        WebCredentials: DotNet WebCredentials;
    begin
        if IsNullGuid(ID) then
            exit;

        SetErrorContext(Text101);
        CheckSetup(MarketingSetup);

        SetErrorContext(Text102);
        if MarketingSetup."Exchange Account User Name" <> '' then
            MarketingSetup.CreateExchangeAccountCredentials(WebCredentials);

        if not ExchangeWebServicesServer.Initialize2010(MarketingSetup."Autodiscovery E-Mail Address",
             MarketingSetup."Exchange Service URL", WebCredentials, false)
        then
            Error(Text001);

        SetErrorContext(Text103);
        if not ExchangeWebServicesServer.GetEmailFolder(MarketingSetup.GetQueueFolderUID, QueueFolder) then
            Error(Text002, MarketingSetup."Queue Folder Path");

        SetErrorContext(Text104);
        if not ExchangeWebServicesServer.GetEmailFolder(MarketingSetup.GetStorageFolderUID, StorageFolder) then
            Error(Text002, MarketingSetup."Storage Folder Path");

        RunEMailBatch(MarketingSetup."Email Batch Size", QueueFolder, StorageFolder);
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
        NoLinkCommentMessageTxt: Label 'There is no link to the email because the email could not be copied.', Comment = 'Max 80 chars';
        NoLinkAttachmentMessageTxt: Label 'There is no link to the email because it could not be copied from the queue to the storage folder.';
        TextFileExtentionTxt: Label 'TXT', Locked = true;

    [Scope('OnPrem')]
    procedure CheckSetup(var MarketingSetup: Record "Marketing Setup")
    var
        ErrorMsg: Text;
    begin
        if not CheckInteractionTemplateSetup(ErrorMsg) then
            Error(ErrorMsg);

        MarketingSetup.Get;
        if not (MarketingSetup."Queue Folder UID".HasValue and MarketingSetup."Storage Folder UID".HasValue) then
            Error(Text003);

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
                RescanQueueFolder := ProcessMessage(QueueMessage, QueueFolder, StorageFolder, StorageMessage);
                SetErrorContext(Text108);
                EmailMovedToStorage := false;
                if not IsNull(StorageMessage) then
                    EmailMovedToStorage := QueueMessage.Id = StorageMessage.Id;
                if not EmailMovedToStorage then
                    QueueMessage.Delete;
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
        if not Attachment.FindSet then
            exit(false);
        repeat
            if Attachment.GetMessageID = MessageId then
                exit(true);
        until (Attachment.Next = 0);
        exit(false);
    end;

    procedure AttachmentRecordAlreadyExists(AttachmentNo: Text; var Attachment: Record Attachment): Boolean
    var
        No: Integer;
    begin
        if Evaluate(No, AttachmentNo) then
            exit(Attachment.Get(No));
        exit(false);
    end;

    local procedure SalespersonRecipients(Message: DotNet IEmailMessage; var SegLine: Record "Segment Line"): Boolean
    var
        RecepientEnumerator: DotNet IEnumerator;
        Recepient: DotNet IEmailAddress;
        RecepientAddress: Text;
    begin
        RecepientEnumerator := Message.Recipients.GetEnumerator;
        while RecepientEnumerator.MoveNext do begin
            Recepient := RecepientEnumerator.Current;
            RecepientAddress := Recepient.Address;
            if IsSalesperson(RecepientAddress, SegLine."Salesperson Code") then begin
                SegLine.Insert;
                SegLine."Line No." := SegLine."Line No." + 1;
            end;
        end;
        exit(not SegLine.IsEmpty);
    end;

    local procedure ContactRecipients(Message: DotNet IEmailMessage; var SegLine: Record "Segment Line"): Boolean
    var
        RecepientEnumerator: DotNet IEnumerator;
        RecepientAddress: DotNet IEmailAddress;
    begin
        RecepientEnumerator := Message.Recipients.GetEnumerator;
        while RecepientEnumerator.MoveNext do begin
            RecepientAddress := RecepientEnumerator.Current;
            if IsContact(RecepientAddress.Address, SegLine) then begin
                SegLine.Insert;
                SegLine."Line No." := SegLine."Line No." + 1;
            end;
        end;
        exit(not SegLine.IsEmpty);
    end;

    local procedure IsMessageToLog(QueueMessage: DotNet IEmailMessage; var SegLine: Record "Segment Line"; var Attachment: Record Attachment): Boolean
    var
        Sender: DotNet IEmailAddress;
    begin
        if QueueMessage.IsSensitive then
            exit(false);

        Sender := QueueMessage.SenderAddress;
        if Sender.IsEmpty or (QueueMessage.RecipientsCount = 0) then
            exit(false);

        if AttachmentRecordAlreadyExists(QueueMessage.NavAttachmentNo, Attachment) then
            exit(true);

        if not GetInboundOutboundInteraction(Sender.Address, SegLine, QueueMessage) then
            exit(false);

        exit(not SegLine.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure UpdateSegLine(var SegLine: Record "Segment Line"; Emails: Code[10]; Subject: Text; DateSent: DotNet DateTime; DateReceived: DotNet DateTime; AttachmentNo: Integer)
    var
        LineDate: DotNet DateTime;
        DateTimeKind: DotNet DateTimeKind;
        InformationFlow: Integer;
    begin
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
        SegLine.Modify;
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
        InteractLogEntry: Record "Interaction Log Entry";
        InteractionTemplateSetup: Record "Interaction Template Setup";
        EntryNumbers: List of [Integer];
        Subject: Text;
        AttachmentNo: Integer;
        NextInteractLogEntryNo: Integer;
        EmailMovedToStorage: Boolean;
        EmailMoveError: Text;
    begin
        if not SegLine.IsEmpty then begin
            Subject := QueueMessage.Subject;

            Attachment.Reset;
            Attachment.LockTable;
            if Attachment.FindLast then
                AttachmentNo := Attachment."No." + 1
            else
                AttachmentNo := 1;

            Attachment.Init;
            Attachment."No." := AttachmentNo;
            Attachment.Insert;

            InteractionTemplateSetup.Get;
            SegLine.Reset;
            SegLine.FindSet(true);
            repeat
                UpdateSegLine(
                  SegLine, InteractionTemplateSetup."E-Mails", Subject, QueueMessage.DateTimeSent, QueueMessage.DateTimeReceived,
                  Attachment."No.");
            until SegLine.Next = 0;

            InteractLogEntry.LockTable;
            if InteractLogEntry.FindLast then
                NextInteractLogEntryNo := InteractLogEntry."Entry No.";
            if SegLine.FindSet then
                repeat
                    NextInteractLogEntryNo := NextInteractLogEntryNo + 1;
                    InsertInteractionLogEntry(SegLine, NextInteractLogEntryNo);
                    EntryNumbers.Add(NextInteractLogEntryNo);
                until SegLine.Next = 0;
        end;

        if Attachment."No." <> 0 then begin
            if TryMoveMessage(QueueMessage, StorageFolder, EmailMovedToStorage) then
                if EmailMovedToStorage then begin
                    SendTraceTag('0000ETD', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageMovedTxt, DataClassification::SystemMetadata);
                    StorageMessage := QueueMessage;
                    LinkAttachmentToMessage(Attachment, StorageMessage);
                    exit(true);
                end;
            EmailMoveError := GetLastErrorText();
            SendTraceTag('0000ETE', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, CannotMoveMessageTxt, DataClassification::SystemMetadata);
            if EmailMoveError <> '' then
                SendTraceTag('0000ETF', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, StrSubstNo(CannotMoveMessageDetailedTxt, EmailMoveError, GetLastErrorCallStack()), DataClassification::CustomerContent);

            if TryCopyMessage(QueueMessage, StorageFolder, StorageMessage) then begin
                SendTraceTag('0000ETG', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageCopiedTxt, DataClassification::SystemMetadata);
                LinkAttachmentToMessage(Attachment, StorageMessage);
                exit(true);
            end;
            SendTraceTag('0000ETH', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, CannotCopyMessageTxt, DataClassification::SystemMetadata);
            SendTraceTag('0000ETI', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, StrSubstNo(CannotCopyMessageDetailedTxt, GetLastErrorText(), GetLastErrorCallStack()), DataClassification::CustomerContent);

            if TryDeleteMessage(QueueMessage) then begin
                SendTraceTag('0000ETJ', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MessageDeletedTxt, DataClassification::SystemMetadata);
                AddNoLinkContent(Attachment);
                AddNoLinkComment(EntryNumbers);
                exit(true);
            end;
            SendTraceTag('0000ETK', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, CannotDeleteMessageTxt, DataClassification::SystemMetadata);
            SendTraceTag('0000ETL', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, StrSubstNo(CannotDeleteMessageDetailedTxt, GetLastErrorText(), GetLastErrorCallStack()), DataClassification::CustomerContent);

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
        StorageMessage.Update;

        Attachment."Email Message Url".CreateOutStream(OutStream);
        EMailMessageUrl := StorageMessage.LinkUrl;
        if EMailMessageUrl <> '' then
            OutStream.Write(EMailMessageUrl);
        Attachment.Modify;

        Commit;
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

    procedure InsertInteractionLogEntry(SegLine: Record "Segment Line"; EntryNo: Integer)
    var
        InteractLogEntry: Record "Interaction Log Entry";
    begin
        InteractLogEntry.Init;
        InteractLogEntry."Entry No." := EntryNo;
        InteractLogEntry."Correspondence Type" := InteractLogEntry."Correspondence Type"::Email;
        InteractLogEntry.CopyFromSegment(SegLine);
        InteractLogEntry."E-Mail Logged" := true;
        InteractLogEntry.Insert;
        OnAfterInsertInteractionLogEntry;
    end;

    procedure IsSalesperson(Email: Text; var SalespersonCode: Code[20]): Boolean
    var
        Salesperson: Record "Salesperson/Purchaser";
    begin
        if Email = '' then
            exit(false);

        if StrLen(Email) > MaxStrLen(Salesperson."Search E-Mail") then
            exit(false);

        Salesperson.SetCurrentKey("Search E-Mail");
        Salesperson.SetRange("Search E-Mail", Email);
        if Salesperson.FindFirst then begin
            SalespersonCode := Salesperson.Code;
            exit(true);
        end;
        exit(false);
    end;

    procedure IsContact(EMail: Text; var SegLine: Record "Segment Line"): Boolean
    var
        Cont: Record Contact;
        ContAltAddress: Record "Contact Alt. Address";
    begin
        if EMail = '' then
            exit(false);

        if StrLen(EMail) > MaxStrLen(Cont."Search E-Mail") then
            exit(false);

        Cont.SetCurrentKey("Search E-Mail");
        Cont.SetRange("Search E-Mail", EMail);
        if Cont.FindFirst then begin
            SegLine."Contact No." := Cont."No.";
            SegLine."Contact Company No." := Cont."Company No.";
            SegLine."Contact Alt. Address Code" := '';
            exit(true);
        end;

        if StrLen(EMail) > MaxStrLen(ContAltAddress."Search E-Mail") then
            exit(false);

        ContAltAddress.SetCurrentKey("Search E-Mail");
        ContAltAddress.SetRange("Search E-Mail", EMail);
        if ContAltAddress.FindFirst then begin
            SegLine."Contact No." := ContAltAddress."Contact No.";
            Cont.Get(ContAltAddress."Contact No.");
            SegLine."Contact Company No." := Cont."Company No.";
            SegLine."Contact Alt. Address Code" := ContAltAddress.Code;
            exit(true);
        end;

        exit(false);
    end;

    local procedure ProcessMessage(QueueMessage: DotNet IEmailMessage; QueueFolder: DotNet IEmailFolder; var StorageFolder: DotNet IEmailFolder; var StorageMessage: DotNet IEmailMessage) SimilarEmailsFound: Boolean
    var
        TempSegLine: Record "Segment Line" temporary;
        Attachment: Record Attachment;
    begin
        TempSegLine.DeleteAll;
        TempSegLine.Init;

        Attachment.Init;
        Attachment.Reset;
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
        InteractionTemplateSetup.Get;
        if InteractionTemplateSetup."E-Mails" = '' then begin
            ErrorMsg := Text109;
            exit(false);
        end;

        // Since we have no guarantees that the Interaction Template for Emails exists, we check for it here.
        InteractionTemplate.SetFilter(Code, '=%1', InteractionTemplateSetup."E-Mails");
        if not InteractionTemplate.FindFirst then begin
            ErrorMsg := Text110;
            exit(false);
        end;

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
        QueueFolder.UseSampleEmailAsFilter(PrimaryStorageMessage);
        FolderOffset := 0;
        repeat
            FindResults := QueueFolder.FindEmailMessages(50, FolderOffset);
            if FindResults.TotalCount > 0 then begin
                Enumerator := FindResults.GetEnumerator;
                while Enumerator.MoveNext do begin
                    TempSegLine.DeleteAll;
                    TempSegLine.Init;
                    TargetMessage := Enumerator.Current;
                    EmailLogged := false;
                    EmailMovedToStorage := false;
                    if TargetMessage.Id <> PrimaryQueueMessageId then begin
                        Sender := TargetMessage.SenderAddress;
                        if (PrimaryStorageMessage.Subject = TargetMessage.Subject) and
                           (PrimaryStorageMessage.Body = TargetMessage.Body)
                        then begin
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
                            end
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
            if not ContactRecipients(QueueMessage, SegLine) then
                exit(false);
        end else begin
            if IsContact(SenderAddress, SegLine) then begin
                SegLine."Information Flow" := SegLine."Information Flow"::Inbound;
                if not SalespersonRecipients(QueueMessage, SegLine) then
                    exit(false);
            end else
                exit(false);
        end;
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

