codeunit 1509 "Notification Entry Dispatcher"
{
    Permissions = TableData "User Setup" = r,
                  TableData "Notification Entry" = rimd,
                  TableData "Sent Notification Entry" = rimd,
                  TableData "Email Item" = rimd;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        if "Parameter String" = '' then
            DispatchInstantNotifications()
        else
            DispatchNotificationTypeForUser("Parameter String");
    end;

    var
        NotificationManagement: Codeunit "Notification Management";
        NotificationMailSubjectTxt: Label 'Notification overview';
        NoEmailAccountsErr: Label 'Cannot send the email. No email accounts have been added.';
        HtmlBodyFilePath: Text;

    local procedure DispatchInstantNotifications()
    var
        UserSetup: Record "User Setup";
        TempNotificationEntryFromTo: Record "Notification Entry" temporary;
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        UserIdWithError: Code[50];
    begin
        GetTempNotificationEntryFromTo(TempNotificationEntryFromTo);
        TempNotificationEntryFromTo.Reset();

        if TempNotificationEntryFromTo.FindSet() then begin
            ErrorMessageMgt.Activate(ErrorMessageHandler);
            ErrorMessageMgt.PushContext(ErrorContextElement, TempNotificationEntryFromTo, 0, '');
            repeat
                if not UserSetup.Get(TempNotificationEntryFromTo."Recipient User ID") then
                    UserIdWithError := TempNotificationEntryFromTo."Recipient User ID"
                else
                    if ScheduledInstantly(UserSetup."User ID", TempNotificationEntryFromTo.Type) then
                        DispatchForNotificationType(TempNotificationEntryFromTo.Type, UserSetup, TempNotificationEntryFromTo."Sender User ID")
            until TempNotificationEntryFromTo.Next() = 0;
            Commit();
            ErrorMessageMgt.Finish(ErrorMessageHandler);
        end;

        if UserIdWithError <> '' then
            UserSetup.Get(UserIdWithError);
    end;

    local procedure DispatchNotificationTypeForUser(Parameter: Text)
    var
        UserSetup: Record "User Setup";
        NotificationEntry: Record "Notification Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDispatchNotificationTypeForUser(Parameter, IsHandled);
        if IsHandled then
            exit;

        NotificationEntry.SetView(Parameter);
        UserSetup.Get(NotificationEntry.GetRangeMax("Recipient User ID"));
        DispatchForNotificationType(NotificationEntry.GetRangeMax(Type), UserSetup, CopyStr(UserId(), 1, 50));
    end;

    local procedure DispatchForNotificationType(NotificationType: Enum "Notification Entry Type"; UserSetup: Record "User Setup"; SenderUserID: Code[50])
    var
        NotificationEntry: Record "Notification Entry";
        NotificationSetup: Record "Notification Setup";
    begin
        NotificationEntry.SetRange("Recipient User ID", UserSetup."User ID");
        NotificationEntry.SetRange(Type, NotificationType);
        if SenderUserID <> '' then
            NotificationEntry.SetRange("Sender User ID", SenderUserID);

        DeleteOutdatedApprovalNotificationEntires(NotificationEntry);

        if not NotificationEntry.FindFirst() then
            exit;

        FilterToActiveNotificationEntries(NotificationEntry);

        NotificationSetup.GetNotificationTypeSetupForUser(NotificationType, NotificationEntry."Recipient User ID");

        CreateAndDispatch(NotificationSetup, NotificationEntry, UserSetup);

        OnAfterDispatchForNotificationType(NotificationSetup, NotificationEntry);
    end;

    local procedure CreateAndDispatch(NotificationSetup: Record "Notification Setup"; var NotificationEntry: Record "Notification Entry"; UserSetup: Record "User Setup")
    begin
        OnBeforeCreateAndDispatch(NotificationSetup, NotificationEntry);
        case NotificationSetup."Notification Method" of
            NotificationSetup."Notification Method"::Email:
                CreateMailAndDispatch(NotificationEntry, UserSetup."E-Mail");
            NotificationSetup."Notification Method"::Note:
                CreateNoteAndDispatch(NotificationEntry);
        end;
    end;

    local procedure ScheduledInstantly(RecipientUserID: Code[50]; NotificationType: Enum "Notification Entry Type"): Boolean
    var
        NotificationSchedule: Record "Notification Schedule";
    begin
        if not NotificationSchedule.Get(RecipientUserID, NotificationType) then
            exit(true); // No rules are set up, send immediately

        exit(NotificationSchedule.Recurrence = NotificationSchedule.Recurrence::Instantly);
    end;

    local procedure CreateMailAndDispatch(var NotificationEntry: Record "Notification Entry"; Email: Text)
    var
        NotificationSetup: Record "Notification Setup";
        MailManagement: Codeunit "Mail Management";
        DocumentMailing: Codeunit "Document-Mailing";
        ErrorMessageMgt: Codeunit "Error Message Management";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        SourceReference: RecordRef;
        DocumentRecRef: RecordRef;
        BodyText: Text;
        MailSubject: Text;
        ErrorText: Text;
        IsEmailedSuccessfully: Boolean;
        IsHandled: Boolean;
        AttachmentStream: InStream;
        SourceTables, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
    begin
        if not GetHTMLBodyText(NotificationEntry, BodyText) then
            exit;

        MailSubject := NotificationMailSubjectTxt;
        IsHandled := false;
        OnBeforeCreateMailAndDispatch(NotificationEntry, MailSubject, Email, IsHandled);
        if IsHandled then
            exit;

        TempBlob.CreateInStream(AttachmentStream);

        if NotificationEntry.FindSet() then
            repeat
                // Add "Primary Source" Related Record (Notification Entry)
                SourceReference.GetTable(NotificationEntry);
                SourceReference.GetBySystemId(NotificationEntry.SystemId);
                SourceTables.Add(SourceReference.Number());
                SourceIDs.Add(SourceReference.Field(SourceReference.SystemIdNo()).Value());
                SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

                // Add "Related Entity" Related Record (Document)
                GetTargetRecRef(NotificationEntry, DocumentRecRef);
                SourceTables.Add(DocumentRecRef.Number());
                SourceIDs.Add(DocumentRecRef.Field(DocumentRecRef.SystemIdNo()).Value());
                SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());
            until NotificationEntry.Next() = 0;

        IsEmailedSuccessfully := DocumentMailing.EmailFile(
         AttachmentStream, '', HtmlBodyFilePath, MailSubject, Email, true, Enum::"Email Scenario"::"Notification", SourceTables, SourceIDs, SourceRelationTypes);
        FileManagement.DeleteServerFile(HtmlBodyFilePath);
        if IsEmailedSuccessfully then
            NotificationManagement.MoveNotificationEntryToSentNotificationEntries(
              NotificationEntry, BodyText, true, NotificationSetup."Notification Method"::Email.AsInteger())
        else begin
            ErrorText := GetLastErrorText();
            if ErrorText = '' then
                if not MailManagement.IsEnabled() then
                    ErrorText := NoEmailAccountsErr;

            NotificationEntry."Error Message" := ErrorText;
            NotificationEntry.Modify(true);
            ErrorMessageMgt.LogError(NotificationEntry, ErrorText, '');
        end;

        OnAfterCreateMailAndDispatch(NotificationEntry, Email, IsEmailedSuccessfully);
    end;

    local procedure CreateNoteAndDispatch(var NotificationEntry: Record "Notification Entry")
    var
        NotificationSetup: Record "Notification Setup";
        BodyText: Text;
    begin
        repeat
            if AddNote(NotificationEntry, BodyText) then
                NotificationManagement.MoveNotificationEntryToSentNotificationEntries(
                  NotificationEntry, BodyText, false, NotificationSetup."Notification Method"::Note.AsInteger());
        until NotificationEntry.Next() = 0;
    end;

    local procedure AddNote(var NotificationEntry: Record "Notification Entry"; var Body: Text): Boolean
    var
        RecordLink: Record "Record Link";
        PageManagement: Codeunit "Page Management";
        RecordLinkManagement: Codeunit "Record Link Management";
        ErrorMessageMgt: Codeunit "Error Message Management";
        RecRefLink: RecordRef;
        Link: Text;
    begin
        with RecordLink do begin
            Init();
            "Link ID" := 0;
            GetTargetRecRef(NotificationEntry, RecRefLink);
            if not RecRefLink.HasFilter then
                RecRefLink.SetRecFilter();
            "Record ID" := RecRefLink.RecordId;
            Link := GetUrl(DefaultClientType, CompanyName, OBJECTTYPE::Page, PageManagement.GetPageID(RecRefLink), RecRefLink, true);
            OnAddNoteOnAfterGetUrl(Link, NotificationEntry, RecRefLink);
            URL1 := CopyStr(Link, 1, MaxStrLen(URL1));
            Description := CopyStr(Format(NotificationEntry."Triggered By Record"), 1, 250);
            Type := Type::Note;
            CreateNoteBody(NotificationEntry, Body);
            RecordLinkManagement.WriteNote(RecordLink, Body);
            Created := CurrentDateTime;
            "User ID" := NotificationEntry."Created By";
            Company := CompanyName;
            Notify := true;
            "To User ID" := NotificationEntry."Recipient User ID";
            if not Insert(true) then begin
                ErrorMessageMgt.LogError(NotificationEntry, GetLastErrorText(), '');
                exit(false);
            end;
            exit(true);
        end;

        exit(false);
    end;

    local procedure FilterToActiveNotificationEntries(var NotificationEntry: Record "Notification Entry")
    begin
        repeat
            NotificationEntry.Mark(true);
        until NotificationEntry.Next() = 0;
        NotificationEntry.MarkedOnly(true);
        NotificationEntry.FindSet();
    end;

    local procedure ConvertHtmlFileToText(HtmlBodyFilePath: Text; var BodyText: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        BlobInStream: InStream;
    begin
        FileManagement.BLOBImportFromServerFile(TempBlob, HtmlBodyFilePath);
        TempBlob.CreateInStream(BlobInStream);
        BlobInStream.ReadText(BodyText);
    end;

    local procedure CreateNoteBody(var NotificationEntry: Record "Notification Entry"; var Body: Text)
    var
        RecRef: RecordRef;
        DocumentType: Text;
        DocumentNo: Text;
        DocumentName: Text;
        ActionText: Text;
    begin
        GetTargetRecRef(NotificationEntry, RecRef);
        NotificationManagement.GetDocumentTypeAndNumber(RecRef, DocumentType, DocumentNo);
        DocumentName := DocumentType + ' ' + DocumentNo;
        ActionText := NotificationManagement.GetActionTextFor(NotificationEntry);
        OnCreateNoteBodyOnAfterGetActionTextFor(NotificationEntry, ActionText);
        Body := DocumentName + ' ' + ActionText;
    end;

    [Scope('OnPrem')]
    procedure GetHTMLBodyText(var NotificationEntry: Record "Notification Entry"; var BodyTextOut: Text) Result: Boolean
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        FileManagement: Codeunit "File Management";
        ErrorMessageMgt: Codeunit "Error Message Management";
        IsHandled: Boolean;
        TempLayoutCode: Code[20];
    begin
        IsHandled := false;
        OnBeforeGetHTMLBodyText(NotificationEntry, BodyTextOut, Result, IsHandled);
        if IsHandled then
            exit(Result);

        HtmlBodyFilePath := FileManagement.ServerTempFileName('html');
        TempLayoutCode := '';
        OnGetHTMLBodyTextOnAfterSetTempLayoutCode(NotificationEntry, BodyTextOut, TempLayoutCode);
        ReportLayoutSelection.SetTempLayoutSelected(TempLayoutCode);
        if not REPORT.SaveAsHtml(REPORT::"Notification Email", HtmlBodyFilePath, NotificationEntry) then begin
            NotificationEntry."Error Message" := GetLastErrorText;
            NotificationEntry.Modify(true);
            ErrorMessageMgt.LogError(NotificationEntry, GetLastErrorText(), '');
            ClearLastError();
            exit(false);
        end;

        ConvertHtmlFileToText(HtmlBodyFilePath, BodyTextOut);
        exit(true);
    end;

    procedure GetTargetRecRef(var NotificationEntry: Record "Notification Entry"; var TargetRecRefOut: RecordRef)
    var
        ApprovalEntry: Record "Approval Entry";
        OverdueApprovalEntry: Record "Overdue Approval Entry";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTargetRecRef(NotificationEntry, TargetRecRefOut, IsHandled);
        if IsHandled then
            exit;

        DataTypeManagement.GetRecordRef(NotificationEntry."Triggered By Record", RecRef);

        case NotificationEntry.Type of
            NotificationEntry.Type::"New Record":
                TargetRecRefOut := RecRef;
            NotificationEntry.Type::Approval:
                begin
                    RecRef.SetTable(ApprovalEntry);
                    TargetRecRefOut.Get(ApprovalEntry."Record ID to Approve");
                end;
            NotificationEntry.Type::Overdue:
                begin
                    RecRef.SetTable(OverdueApprovalEntry);
                    TargetRecRefOut.Get(OverdueApprovalEntry."Record ID to Approve");
                end;
        end;
    end;

    local procedure DeleteOutdatedApprovalNotificationEntires(var NotificationEntry: Record "Notification Entry")
    begin
        if NotificationEntry.FindFirst() then
            repeat
                if ApprovalNotificationEntryIsOutdated(NotificationEntry) then
                    NotificationEntry.Delete();
            until NotificationEntry.Next() = 0;
    end;

    local procedure ApprovalNotificationEntryIsOutdated(var NotificationEntry: Record "Notification Entry"): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
        OverdueApprovalEntry: Record "Overdue Approval Entry";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        IsOutdated, IsHandled : Boolean;
    begin
        IsOutdated := false;
        IsHandled := false;
        OnBeforeApprovalNotificationEntryIsOutdated(NotificationEntry, IsOutdated, IsHandled);
        if IsHandled then
            exit(IsOutdated);

        if not DataTypeManagement.GetRecordRef(NotificationEntry."Triggered By Record", RecRef) then
            exit(true); // if no approval entry in RecRef, mark entry as outdated

        case NotificationEntry.Type of
            NotificationEntry.Type::Approval:
                begin
                    RecRef.SetTable(ApprovalEntry);
                    if not RecRef.Get(ApprovalEntry."Record ID to Approve") then
                        exit(true);
                end;
            NotificationEntry.Type::Overdue:
                begin
                    RecRef.SetTable(OverdueApprovalEntry);
                    if not RecRef.Get(OverdueApprovalEntry."Record ID to Approve") then
                        exit(true);
                end;
        end;
    end;

    local procedure GetTempNotificationEntryFromTo(var TempNotificationEntryFromTo: Record "Notification Entry" temporary)
    var
        NotificationEntry: Record "Notification Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTempNotificationEntryFromTo(NotificationEntry, TempNotificationEntryFromTo, IsHandled);
        if IsHandled then
            exit;

        NotificationEntry.SetRange("Sender User ID", UserId());
        if NotificationEntry.FindSet() then
            repeat
                TempNotificationEntryFromTo.SetRange("Sender User ID", NotificationEntry."Sender User ID");
                TempNotificationEntryFromTo.SetRange("Recipient User ID", NotificationEntry."Recipient User ID");
                if TempNotificationEntryFromTo.IsEmpty() then begin
                    TempNotificationEntryFromTo := NotificationEntry;
                    TempNotificationEntryFromTo.Insert();
                end;
            until NotificationEntry.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateMailAndDispatch(var NotificationEntry: Record "Notification Entry"; Email: Text; IsEmailedSuccessfully: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDispatchForNotificationType(NotificationSetup: Record "Notification Setup"; var NotificationEntry: Record "Notification Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNoteOnAfterGetUrl(var Link: Text; NotificationEntry: Record "Notification Entry"; RecRefLink: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateMailAndDispatch(var NotificationEntry: Record "Notification Entry"; var MailSubject: Text; var Email: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAndDispatch(NotificationSetup: Record "Notification Setup"; var NotificationEntry: Record "Notification Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTargetRecRef(var NotificationEntry: Record "Notification Entry"; var TargetRecRefOut: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetHTMLBodyText(var NotificationEntry: Record "Notification Entry"; var BodyTextOut: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNoteBodyOnAfterGetActionTextFor(var NotificationEntry: Record "Notification Entry"; var ActionText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDispatchNotificationTypeForUser(Parameter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTempNotificationEntryFromTo(var NotificationEntry: Record "Notification Entry"; var TempNotificationEntryFromTo: Record "Notification Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetHTMLBodyTextOnAfterSetTempLayoutCode(var NotificationEntry: Record "Notification Entry"; var BodyTextOut: Text; var TempLayoutCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApprovalNotificationEntryIsOutdated(var NotificationEntry: Record "Notification Entry"; var IsOutdated: Boolean; var IsHandled: Boolean)
    begin
    end;
}

