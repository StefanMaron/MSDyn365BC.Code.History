codeunit 28 "Error Message Management"
{

    trigger OnRun()
    begin
    end;

    var
        JoinedErr: Label '%1 %2.', Locked = true;
        JobQueueErrMsgProcessingTxt: Label 'Job Queue Error Message Processing.', Locked = true;
        MessageType: Option Error,Warning,Information;

    procedure Activate(var ErrorMessageHandler: Codeunit "Error Message Handler"): Boolean
    begin
        if not IsActive then begin
            ClearLastError;
            exit(ErrorMessageHandler.Activate(ErrorMessageHandler));
        end;
        exit(false);
    end;

    procedure IsActive() IsFound: Boolean
    begin
        OnFindActiveSubscriber(IsFound);
    end;

    procedure Finish(ContextVariant: Variant)
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        if GetErrorsInContext(ContextVariant, TempErrorMessage) then begin
            if not GuiAllowed then
                SendTraceTag('000097V', JobQueueErrMsgProcessingTxt, Verbosity::Normal, TempErrorMessage.Description, DataClassification::CustomerContent);
            StopTransaction;
        end;
    end;

    local procedure StopTransaction()
    begin
        Error('')
    end;

    procedure IsTransactionStopped(): Boolean
    begin
        exit(StrPos(GetCallStackTop, '(CodeUnit 28).StopTransaction') > 0);
    end;

    local procedure GetCallStackTop(): Text[250]
    var
        CallStack: Text[250];
        DividerPos: Integer;
    begin
        CallStack := CopyStr(GetLastErrorCallstack, 1, 250);
        if CallStack = '' then
            exit('');
        DividerPos := StrPos(CallStack, '\');
        if DividerPos > 0 then
            exit(CopyStr(CallStack, 1, DividerPos - 1));
        exit(CallStack);
    end;

    local procedure GetContextRecID(ContextVariant: Variant; var ContextRecID: RecordID)
    var
        RecRef: RecordRef;
        TableNo: Integer;
    begin
        Clear(ContextRecID);
        case true of
            ContextVariant.IsRecord:
                begin
                    RecRef.GetTable(ContextVariant);
                    ContextRecID := RecRef.RecordId;
                end;
            ContextVariant.IsRecordId:
                ContextRecID := ContextVariant;
            ContextVariant.IsInteger:
                begin
                    TableNo := ContextVariant;
                    if TableNo > 0 then
                        if GetBlankRecID(ContextVariant, ContextRecID) then;
                end;
        end;
    end;

    [TryFunction]
    local procedure GetBlankRecID(TableNo: Integer; var RecID: RecordID)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        RecID := RecRef.RecordId;
        RecRef.Close;
    end;

    [Scope('OnPrem')]
    procedure ShowErrors(Notification: Notification)
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
        RegisterID: Guid;
    begin
        if not Evaluate(RegisterID, Notification.GetData('RegisterID')) then
            Clear(RegisterID);
        ErrorMessage.FilterGroup(2);
        ErrorMessage.SetRange("Register ID", RegisterID);
        ErrorMessage.FilterGroup(0);
        if ErrorMessage.FindSet then begin
            repeat
                TempErrorMessage := ErrorMessage;
                TempErrorMessage.Insert();
            until ErrorMessage.Next = 0;
            TempErrorMessage.ShowErrors;
        end;
    end;

    procedure ThrowError(ContextErrorMessage: Text; DetailedErrorMessage: Text)
    begin
        if not IsActive then
            Error(JoinedErr, ContextErrorMessage, DetailedErrorMessage);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindActiveSubscriber(var IsFound: Boolean)
    begin
    end;

    procedure GetFieldNo(TableNo: Integer; FieldName: Text): Integer
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, TableNo);
        Field.SetRange(FieldName, FieldName);
        if Field.FindFirst then
            exit(Field."No.");
    end;

    procedure FindFirstErrorMessage(var ErrorMessage: Text[250]): Boolean
    begin
        exit(GetLastError(ErrorMessage) > 0);
    end;

    local procedure GetFirstContextID(ContextRecordID: RecordID) ContextID: Integer
    begin
        if ContextRecordID.TableNo = 0 then
            exit(0);
        OnGetFirstContextID(ContextRecordID, ContextID);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFirstContextID(ContextRecordID: RecordID; var ContextID: Integer)
    begin
    end;

    procedure GetErrors(var TempErrorMessage: Record "Error Message" temporary): Boolean
    begin
        TempErrorMessage.SetRange(Context, false);
        OnGetErrors(TempErrorMessage);
        exit(TempErrorMessage.FindFirst);
    end;

    procedure GetErrorsInContext(ContextVariant: Variant; var TempErrorMessage: Record "Error Message" temporary): Boolean
    var
        ContextRecID: RecordID;
    begin
        GetContextRecID(ContextVariant, ContextRecID);
        TempErrorMessage.SetFilter(ID, '>%1', GetFirstContextID(ContextRecID));
        TempErrorMessage.SetRange("Message Type", TempErrorMessage."Message Type"::Error);
        exit(GetErrors(TempErrorMessage));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetErrors(var TempErrorMessageResult: Record "Error Message" temporary)
    begin
    end;

    procedure GetLastError(var ErrorMessage: Text[250]) ID: Integer
    begin
        OnGetLastErrorID(ID, ErrorMessage);
    end;

    procedure GetLastErrorID() ID: Integer
    var
        ErrorMessage: Text[250];
    begin
        OnGetLastErrorID(ID, ErrorMessage);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetLastErrorID(var ID: Integer; var ErrorMessage: Text[250])
    begin
    end;

    procedure LogError(SourceVariant: Variant; ErrorMessage: Text; HelpArticleCode: Code[30])
    var
        ContextErrorMessage: Record "Error Message";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        if not GetTopContext(ContextErrorMessage) then
            PushContext(ErrorContextElement, 0, 0, GetCallStackTop);
        LogErrorMessage(ContextErrorMessage."Context Field Number", ErrorMessage, SourceVariant, 0, HelpArticleCode);
    end;

    procedure LogContextFieldError(ContextFieldNo: Integer; ErrorMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30])
    begin
        LogErrorMessage(ContextFieldNo, ErrorMessage, SourceVariant, SourceFieldNo, HelpArticleCode);
    end;

    procedure LogMessage(NewMessageType: Option; ContextFieldNo: Integer; InformationMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30]): Boolean
    begin
        case NewMessageType of
            MessageType::Error:
                exit(LogErrorMessage(ContextFieldNo, InformationMessage, SourceVariant, SourceFieldNo, HelpArticleCode));
            MessageType::Warning:
                exit(LogWarning(ContextFieldNo, InformationMessage, SourceVariant, SourceFieldNo, HelpArticleCode));
            MessageType::Information:
                exit(LogInformation(ContextFieldNo, InformationMessage, SourceVariant, SourceFieldNo, HelpArticleCode));
        end;
    end;

    procedure LogErrorMessage(ContextFieldNo: Integer; ErrorMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30]) IsLogged: Boolean
    begin
        OnLogError(MessageType::Error, ContextFieldNo, ErrorMessage, SourceVariant, SourceFieldNo, HelpArticleCode, IsLogged);
        if not IsLogged then
            Error(ErrorMessage);
    end;

    procedure LogSimpleErrorMessage(ErrorMessage: Text) IsLogged: Boolean
    begin
        OnLogSimpleError(ErrorMessage, IsLogged);
        if not IsLogged then
            Error(ErrorMessage);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogSimpleError(ErrorMessage: Text; var IsLogged: Boolean)
    begin
    end;

    procedure LogWarning(ContextFieldNo: Integer; WarningMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30]) IsLogged: Boolean
    begin
        OnLogError(MessageType::Warning, ContextFieldNo, WarningMessage, SourceVariant, SourceFieldNo, HelpArticleCode, IsLogged);
    end;

    procedure LogWarning(WarningMessage: Text) IsLogged: Boolean
    begin
        OnLogError(MessageType::Warning, 0, WarningMessage, 0, 0, '', IsLogged);
    end;

    procedure LogInformation(ContextFieldNo: Integer; InformationMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30]) IsLogged: Boolean
    begin
        OnLogError(MessageType::Information, ContextFieldNo, InformationMessage, SourceVariant, SourceFieldNo, HelpArticleCode, IsLogged);
    end;

    procedure LogInformation(InformationMessage: Text) IsLogged: Boolean
    begin
        OnLogError(MessageType::Information, 0, InformationMessage, 0, 0, '', IsLogged);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogError(MessageType: Option; ContextFieldNo: Integer; ErrorMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30]; var IsLogged: Boolean)
    begin
    end;

    procedure PushContext(var ErrorContextElement: Codeunit "Error Context Element"; ContextVariant: Variant; ContextFieldNo: Integer; AdditionalInfo: Text[250]) ID: Integer
    var
        RecID: RecordID;
    begin
        if IsActive then begin
            ID := ErrorContextElement.GetID;
            if ID = 0 then begin
                OnGetTopElement(ID);
                ID += 1;
                BindSubscription(ErrorContextElement);
            end;
            GetContextRecID(ContextVariant, RecID);
            ErrorContextElement.Set(ID, RecID, ContextFieldNo, AdditionalInfo);
            OnPushContext;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPushContext()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTopElement(var TopElementID: Integer)
    begin
    end;

    procedure GetTopContext(var ErrorMessage: Record "Error Message"): Boolean
    begin
        OnGetTopContext(ErrorMessage);
        exit(ErrorMessage.ID > 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTopContext(var ErrorMessage: Record "Error Message")
    begin
    end;
}

