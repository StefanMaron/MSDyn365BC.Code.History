codeunit 29 "Error Message Handler"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        Active: Boolean;
        NotificationMsg: Label 'An error or warning occured during operation %1.', Comment = '%1 - decription of operation';
        DetailsMsg: Label 'Details';

    procedure AppendTo(var TempErrorMessageBuf: Record "Error Message" temporary): Boolean
    var
        NextID: Integer;
    begin
        with TempErrorMessage do begin
            SetRange(Context, false);
            if IsEmpty then
                exit(false);

            LogLastError;

            NextID := 0;
            TempErrorMessageBuf.Reset();
            if TempErrorMessageBuf.FindLast then
                NextID := TempErrorMessageBuf.ID;
            SetRange(Context, false);
            FindSet;
            repeat
                NextID += 1;
                TempErrorMessageBuf := TempErrorMessage;
                TempErrorMessageBuf.ID := NextID;
                TempErrorMessageBuf.Insert();
            until Next = 0;
            exit(true);
        end;
    end;

    procedure Activate(var ErrorMessageHandler: Codeunit "Error Message Handler"): Boolean
    begin
        Active := BindSubscription(ErrorMessageHandler);
        exit(Active);
    end;

    local procedure GetLink("Code": Code[30]): Text[250]
    var
        NamedForwardLink: Record "Named Forward Link";
    begin
        if NamedForwardLink.Get(Code) then
            exit(NamedForwardLink.Link);
    end;

    procedure ShowErrors(): Boolean
    begin
        if Active then begin
            RegisterErrorMessages;
            exit(TempErrorMessage.ShowErrors);
        end;
    end;

    procedure NotifyAboutErrors()
    begin
        if Active then
            ShowNotification(RegisterErrorMessages);
    end;

    local procedure ShowNotification(RegisterID: Guid)
    var
        ContextErrorMessage: Record "Error Message";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Notification: Notification;
    begin
        TempErrorMessage.GetContext(ContextErrorMessage);
        NotificationLifecycleMgt.RecallNotificationsForRecord(ContextErrorMessage."Context Record ID", false);
        Notification.Message(StrSubstNo(NotificationMsg, ContextErrorMessage."Additional Information"));
        Notification.SetData('RegisterID', RegisterID);
        Notification.AddAction(DetailsMsg, CODEUNIT::"Error Message Management", 'ShowErrors');
        NotificationLifecycleMgt.SendNotification(Notification, ContextErrorMessage."Context Record ID");
    end;

    [Scope('OnPrem')]
    procedure RegisterErrorMessages() RegisterID: Guid
    var
        ContextErrorMessage: Record "Error Message";
        ErrorMessage: Record "Error Message";
        ErrorMessageRegister: Record "Error Message Register";
    begin
        TempErrorMessage.LogLastError;

        TempErrorMessage.SetRange(Context, false);
        if not TempErrorMessage.FindSet then
            exit;

        TempErrorMessage.GetContext(ContextErrorMessage);
        RegisterID := ErrorMessageRegister.New(ContextErrorMessage."Additional Information");
        repeat
            ErrorMessage := TempErrorMessage;
            ErrorMessage."Register ID" := RegisterID;
            ErrorMessage.ID := 0; // autoincrement
            ErrorMessage.Insert();
        until TempErrorMessage.Next = 0;
    end;

    procedure WriteMessagesToFile(FileName: Text; ThrowLastError: Boolean) FileCreated: Boolean;
    var
        ContextErrorMessage: Record "Error Message";
        ErrorCallStack: Text;
        ErrorText: Text;
    begin
        if ThrowLastError then begin
            ErrorCallStack := GetLastErrorCallStack();
            ErrorText := GetLastErrorText();
        end;
        TempErrorMessage.LogLastError;

        TempErrorMessage.SetRange(Context, false);
        if TempErrorMessage.FindSet then
            WriteMessagesToFile(TempErrorMessage, FileName, ErrorCallStack);
        IF ThrowLastError then
            Error('%1 %2', ErrorText, ErrorCallStack);
    end;

    local procedure WriteMessagesToFile(var ErrorMessage: Record "Error Message"; FileName: Text; ErrorCallStack: Text) FileCreated: Boolean;
    var
        LogFile: File;
        OutStr: OutStream;
        CRLF: Text[2];
    begin
        with ErrorMessage do begin
            FileCreated := LogFile.Create(FileName);
            if FileCreated then begin
                CRLF[1] := 13;
                CRLF[2] := 10;
                LogFile.CreateOutStream(OutStr);
                repeat
                    OutStr.WriteText("Additional Information" + ' : ' + Description + CRLF);
                until Next = 0;
                if ErrorCallStack <> '' then
                    OutStr.WriteText(ErrorCallStack);
                LogFile.Close();
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 28, 'OnGetFirstContextID', '', false, false)]
    local procedure OnGetFirstContextIDHandler(ContextRecordID: RecordID; var ContextID: Integer)
    begin
        if Active then begin
            ContextID := 0;
            TempErrorMessage.Reset();
            TempErrorMessage.SetCurrentKey(Context);
            TempErrorMessage.SetRange(Context, true);
            TempErrorMessage.SetRange("Context Record ID", ContextRecordID);
            if TempErrorMessage.FindFirst then
                ContextID := TempErrorMessage.ID
            else begin
                TempErrorMessage.Reset();
                if TempErrorMessage.FindLast then
                    ContextID := TempErrorMessage.ID;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 28, 'OnGetErrors', '', false, false)]
    local procedure OnGetErrorsHandler(var TempErrorMessageResult: Record "Error Message" temporary)
    begin
        if Active then begin
            TempErrorMessage.CopyFilters(TempErrorMessageResult);
            if TempErrorMessage.FindSet then
                repeat
                    TempErrorMessageResult := TempErrorMessage;
                    TempErrorMessageResult.Insert();
                until TempErrorMessage.Next = 0;
            TempErrorMessage.Reset();
        end
    end;

    [Scope('OnPrem')]
    procedure HasErrors(): Boolean
    begin
        exit(TempErrorMessage.HasErrors(false));
    end;

    [EventSubscriber(ObjectType::Codeunit, 28, 'OnGetLastErrorID', '', false, false)]
    local procedure OnGetLastErrorID(var ID: Integer; var ErrorMessage: Text[250])
    begin
        if Active then begin
            ID := TempErrorMessage.GetLastID;
            ErrorMessage := TempErrorMessage.Description;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 28, 'OnLogError', '', false, false)]
    local procedure OnLogErrorHandler(MessageType: Option; ContextFieldNo: Integer; ErrorMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30]; var IsLogged: Boolean)
    begin
        if Active then begin
            TempErrorMessage."Message Type" := MessageType;
            IsLogged :=
              TempErrorMessage.LogContextFieldError(
                ContextFieldNo, ErrorMessage, SourceVariant, SourceFieldNo, GetLink(HelpArticleCode)) <> 0
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 28, 'OnLogSimpleError', '', false, false)]
    local procedure OnLogSimpleErrorHandler(ErrorMessage: Text; var IsLogged: Boolean)
    begin
        if Active then
            IsLogged := TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, ErrorMessage) <> 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, 28, 'OnFindActiveSubscriber', '', false, false)]
    local procedure OnFindActiveSubscriberHandler(var IsFound: Boolean)
    begin
        if not IsFound then
            IsFound := Active;
    end;

    [EventSubscriber(ObjectType::Codeunit, 28, 'OnPushContext', '', false, false)]
    local procedure OnPushContextHandler()
    begin
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Information, '');
        TempErrorMessage.Context := true;
        TempErrorMessage.Modify();
    end;
}

