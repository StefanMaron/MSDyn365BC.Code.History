codeunit 19 "Gen. Jnl.-Post Preview"
{

    trigger OnRun()
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        HideDialogs := TRUE;
        CLEAR(PostingPreviewEventHandler);
        Preview(PreviewSubscriber, PreviewRecord);
        HideDialogs := false;
        LastErrorText := GetLastErrorText;
        if not IsSuccess then
            ErrorMessageMgt.LogError(PreviewRecord, LastErrorText, '');
        Error('');
    end;

    var
        NothingToPostMsg: Label 'There is nothing to post.';
        PreviewModeErr: Label 'Preview mode.';
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
        SubscriberTypeErr: Label 'Invalid Subscriber type. The type must be CODEUNIT.';
        RecVarTypeErr: Label 'Invalid RecVar type. The type must be RECORD.';
        PreviewExitStateErr: Label 'The posting preview has stopped because of a state that is not valid.';
        PreviewSubscriber: Variant;
        PreviewRecord: Variant;
        LastErrorText: Text;
        HideDialogs: Boolean;

    procedure Preview(Subscriber: Variant; RecVar: Variant)
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        RunResult: Boolean;
    begin
        if not Subscriber.IsCodeunit then
            Error(SubscriberTypeErr);
        if not RecVar.IsRecord then
            Error(RecVarTypeErr);

        BindSubscription(PostingPreviewEventHandler);
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, RecVar, 0, PreviewModeErr);
        OnAfterBindSubscription(PostingPreviewEventHandler);

        RunResult := RunPreview(Subscriber, RecVar);

        UnbindSubscription(PostingPreviewEventHandler);
        OnAfterUnbindSubscription;

        // The OnRunPreview event expects subscriber following template: Result := <Codeunit>.RUN
        // So we assume RunPreview returns FALSE with the error.
        // To prevent return FALSE without thrown error we check error call stack.
        if RunResult or (GetLastErrorCallstack = '') then
            Error(PreviewExitStateErr);

        if NOT HideDialogs then begin
            if GetLastErrorText <> PreviewModeErr then
                if ErrorMessageHandler.ShowErrors then
                    Error('');
            ShowAllEntries;
            Error('');
        end;
    end;

    procedure GetPreviewHandler(var ResultPostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
        ResultPostingPreviewEventHandler := PostingPreviewEventHandler;
    end;

    procedure IsActive(): Boolean
    var
        Result: Boolean;
    begin
        // The lookup to event subscription system virtual table is the performance killer.
        // We call subscriber CU 20 to get active state of posting preview context.
        OnSystemSetPostingPreviewActive(Result);

        OnAfterIsActive(Result);
        exit(Result);
    end;

    procedure IsSuccess(): Boolean;
    begin
        exit(LastErrorText = PreviewModeErr);
    end;

    local procedure RunPreview(Subscriber: Variant; RecVar: Variant): Boolean
    var
        Result: Boolean;
    begin
        OnRunPreview(Result, Subscriber, RecVar);
        exit(Result);
    end;

    procedure SetContext(Subscriber: Variant; RecVar: Variant)
    begin
        PreviewSubscriber := Subscriber;
        PreviewRecord := RecVar;
    end;

    local procedure ShowAllEntries()
    var
        TempDocumentEntry: Record "Document Entry" temporary;
        GLPostingPreview: Page "G/L Posting Preview";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowAllEntries(TempDocumentEntry, IsHandled);
        if IsHandled then
            exit;

        PostingPreviewEventHandler.FillDocumentEntry(TempDocumentEntry);
        if not TempDocumentEntry.IsEmpty then begin
            GLPostingPreview.Set(TempDocumentEntry, PostingPreviewEventHandler);
            GLPostingPreview.Run
        end else
            Message(NothingToPostMsg);
    end;

    procedure ShowDimensions(TableID: Integer; EntryNo: Integer; DimensionSetID: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        DimMgt.ShowDimensionSet(DimensionSetID, StrSubstNo('%1 %2', RecRef.Caption, EntryNo));
    end;

    procedure ThrowError()
    begin
        OnBeforeThrowError;
        Error(PreviewModeErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBindSubscription(var PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUnbindSubscription()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSystemSetPostingPreviewActive(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsActive(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAllEntries(var TempDocumentEntry: Record "Document Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeThrowError()
    begin
    end;
}

