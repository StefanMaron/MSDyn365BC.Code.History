codeunit 1380 "Batch Processing Mgt."
{
    Permissions = TableData "Batch Processing Parameter" = rimd,
                  TableData "Batch Processing Session Map" = rimd;

    trigger OnRun()
    begin
        RunCustomProcessing;
    end;

    var
        PostingTemplateMsg: Label 'Processing: @1@@@@@@@', Comment = '1 - overall progress';
        RecRefCustomerProcessing: RecordRef;
        ProcessingCodeunitID: Integer;
        BatchID: Guid;
        ProcessingCodeunitNotSetErr: Label 'A processing codeunit has not been selected.';
        BatchCompletedMsg: Label 'All the documents were processed.';
        IsCustomProcessingHandled: Boolean;
        IsHandled: Boolean;
        KeepParameters: Boolean;
        BatchProcessingTxt: Label 'Batch processing of %1 records.', Comment = '%1 - a table caption';
        ProcessingMsg: Label 'Executing codeunit %1 on record %2.', Comment = '%1 - codeunit id,%2 - record id';

    procedure BatchProcess(var RecRef: RecordRef)
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        Window: Dialog;
        CounterTotal: Integer;
        CounterToPost: Integer;
        CounterPosted: Integer;
        BatchConfirm: Option " ",Skip,Update;
        FullBatchProcessed: Boolean;
    begin
        if ProcessingCodeunitID = 0 then
            Error(ProcessingCodeunitNotSetErr);

        OnBeforeBatchProcess(RecRef);

        with RecRef do begin
            if IsEmpty() then
                exit;

            FillBatchProcessingMap(RecRef);
            Commit();

            FindSet();

            if GuiAllowed then begin
                Window.Open(PostingTemplateMsg);
                CounterTotal := Count;
            end;

            if ErrorMessageMgt.Activate(ErrorMessageHandler) then
                ErrorMessageMgt.PushContext(ErrorContextElement, Number, 0, StrSubstNo(BatchProcessingTxt, Caption));
            if not BatchShouldBeProcessedInBackground(RecRef, FullBatchProcessed) then
                repeat
                    if GuiAllowed then begin
                        CounterToPost += 1;
                        Window.Update(1, Round(CounterToPost / CounterTotal * 10000, 1));
                    end;

                    if CanProcessRecord(RecRef) then
                        if ProcessRecord(RecRef, BatchConfirm) then
                            CounterPosted += 1;
                until Next() = 0;

            OnBatchProcessOnBeforeResetBatchID(RecRef, ProcessingCodeunitID);
            ResetBatchID;

            IsHandled := false;
            OnBatchProcessOnBeforeShowMessage(CounterPosted, CounterTotal, IsHandled);

            if GuiAllowed then begin
                Window.Close;
                if not IsHandled then
                    if (CounterPosted <> CounterTotal) and not FullBatchProcessed then begin
                        ErrorMessageHandler.NotifyAboutErrors();
                        ErrorMessageMgt.PopContext(ErrorContextElement);
                    end else
                        Message(BatchCompletedMsg);
            end;
        end;

        OnAfterBatchProcess(RecRef, CounterPosted, ProcessingCodeunitID);
    end;

    local procedure CanProcessRecord(var RecRef: RecordRef): Boolean
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        Result: Boolean;
    begin
        Result := true;
        OnVerifyRecord(RecRef, Result);

        if not Result then
            if GetLastErrorText <> '' then begin
                ErrorMessageMgt.LogError(RecRef.RecordId, GetLastErrorText, '');
                ClearLastError;
            end;
        exit(Result);
    end;

    procedure FillBatchProcessingMap(var RecRef: RecordRef)
    begin
        with RecRef do begin
            FindSet();
            repeat
                DeleteLostParameters(RecordId);
                InsertBatchProcessingSessionMapEntry(RecRef);
            until Next() = 0;
        end;
    end;

    procedure GetErrorMessages(var TempErrorMessageResult: Record "Error Message" temporary)
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        ErrorMessageMgt.GetErrors(TempErrorMessageResult);
    end;

    local procedure InsertBatchProcessingSessionMapEntry(RecRef: RecordRef)
    var
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        if IsNullGuid(BatchID) then
            exit;

        BatchProcessingSessionMap.Init();
        BatchProcessingSessionMap."Record ID" := RecRef.RecordId;
        BatchProcessingSessionMap."Batch ID" := BatchID;
        BatchProcessingSessionMap."User ID" := UserSecurityId;
        BatchProcessingSessionMap."Session ID" := SessionId;
        BatchProcessingSessionMap.Insert();
    end;

    local procedure InvokeProcessing(var RecRef: RecordRef): Boolean
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        RecVar: Variant;
        Result: Boolean;
    begin
        ClearLastError;

        BatchProcessingMgt.SetRecRefForCustomProcessing(RecRef);
        Result := BatchProcessingMgt.Run;
        BatchProcessingMgt.GetRecRefForCustomProcessing(RecRef);

        RecVar := RecRef;

        if (GetLastErrorCallstack = '') and Result and not BatchProcessingMgt.GetIsCustomProcessingHandled then begin
            ErrorMessageMgt.PushContext(
              ErrorContextElement, RecRef.RecordId, 0, StrSubstNo(ProcessingMsg, ProcessingCodeunitID, RecRef.RecordId));
            Result := CODEUNIT.Run(ProcessingCodeunitID, RecVar);
        end;
        if BatchProcessingMgt.GetIsCustomProcessingHandled then
            KeepParameters := BatchProcessingMgt.GetKeepParameters;
        if not Result then
            if GetLastErrorText <> '' then begin
                ErrorMessageMgt.LogError(RecVar, GetLastErrorText, '');
                ErrorMessageMgt.PopContext(ErrorContextElement);
                ClearLastError;
            end;

        RecRef.GetTable(RecVar);

        exit(Result);
    end;

    local procedure RunCustomProcessing()
    var
        Handled: Boolean;
        KeepParametersLocal: Boolean;
    begin
        OnCustomProcessing(RecRefCustomerProcessing, Handled, KeepParametersLocal);
        IsCustomProcessingHandled := Handled;
        KeepParameters := KeepParametersLocal;
    end;

    local procedure InitBatchID()
    begin
        if IsNullGuid(BatchID) then
            BatchID := CreateGuid;
    end;

    local procedure ProcessRecord(var RecRef: RecordRef; var BatchConfirm: Option): Boolean
    var
        ProcessingResult: Boolean;
    begin
        OnBeforeBatchProcessing(RecRef, BatchConfirm);

        ProcessingResult := InvokeProcessing(RecRef);

        OnAfterBatchProcessing(RecRef, ProcessingResult);

        exit(ProcessingResult);
    end;

    procedure ResetBatchID()
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        if not KeepParameters then begin
            BatchProcessingParameter.SetRange("Batch ID", BatchID);
            BatchProcessingParameter.DeleteAll();

            BatchProcessingSessionMap.SetRange("Batch ID", BatchID);
            BatchProcessingSessionMap.DeleteAll();
        end;

        Clear(BatchID);

        Commit();
    end;

    procedure DeleteBatchProcessingSessionMapForRecordId(RecordIdToClean: RecordId)
    var
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingSessionMap.SetRange("Batch ID", BatchID);
        BatchProcessingSessionMap.SetRange("Record ID", RecordIdToClean);
        BatchProcessingSessionMap.DeleteAll();
    end;

    local procedure DeleteLostParameters(RecordID: RecordID)
    var
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
        BatchProcessingParameter: Record "Batch Processing Parameter";
    begin
        BatchProcessingSessionMap.SetRange("Record ID", RecordID);
        BatchProcessingSessionMap.SetRange("User ID", UserSecurityId);
        BatchProcessingSessionMap.SetRange("Session ID", SessionId);
        BatchProcessingSessionMap.SetFilter("Batch ID", '<>%1', BatchID);
        if BatchProcessingSessionMap.FindSet then begin
            repeat
                BatchProcessingParameter.SetRange("Batch ID", BatchProcessingSessionMap."Batch ID");
                if not BatchProcessingParameter.IsEmpty() then
                    BatchProcessingParameter.DeleteAll();
            until BatchProcessingSessionMap.Next() = 0;
            BatchProcessingSessionMap.DeleteAll();
        end;
    end;


    [Obsolete('Replaced by SetParameter().', '17.0')]
    procedure AddParameter(ParameterId: Integer; Value: Variant)
    begin
        SetParameter("Batch Posting Parameter Type".FromInteger(ParameterId), Value);
    end;

    procedure SetParameter(ParameterId: Enum "Batch Posting Parameter Type"; Value: Variant)
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        IsProcessed: Boolean;
    begin
        InitBatchID;

        BatchProcessingParameter.Init();
        BatchProcessingParameter."Batch ID" := BatchID;
        BatchProcessingParameter."Parameter Id" := ParameterId.AsInteger();
        BatchProcessingParameter."Parameter Value" := Format(Value);

        IsProcessed := false;
        OnSetParameterOnBeforeParameterInsert(BatchProcessingParameter, IsProcessed);
        if not IsProcessed then
            BatchProcessingParameter.Insert();
    end;

    [Obsolete('Replaced by GetTextParameter().', '17.0')]
    procedure GetParameterText(RecordID: RecordID; ParameterId: Integer; var ParameterValue: Text[250]): Boolean
    begin
        exit(GetTextParameter(RecordID, "Batch Posting Parameter Type".FromInteger(ParameterId), ParameterValue))
    end;

    procedure GetTextParameter(RecordID: RecordID; ParameterId: Enum "Batch Posting Parameter Type"; var ParameterValue: Text[250]): Boolean
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingSessionMap.SetRange("Record ID", RecordID);
        BatchProcessingSessionMap.SetRange("User ID", UserSecurityId);
        BatchProcessingSessionMap.SetRange("Session ID", SessionId);

        if not BatchProcessingSessionMap.FindFirst() then
            exit(false);

        if not BatchProcessingParameter.Get(BatchProcessingSessionMap."Batch ID", ParameterId) then
            exit(false);

        ParameterValue := BatchProcessingParameter."Parameter Value";
        exit(true);
    end;

    [Obsolete('Replaced by GetBooleanParameter().', '17.0')]
    procedure GetParameterBoolean(RecordID: RecordID; ParameterId: Integer; var ParameterValue: Boolean): Boolean
    begin
        exit(GetBooleanParameter(RecordID, "Batch Posting Parameter Type".FromInteger(ParameterId), ParameterValue));
    end;

    procedure GetBooleanParameter(RecordID: RecordID; ParameterId: Enum "Batch Posting Parameter Type"; var ParameterValue: Boolean): Boolean
    var
        Result: Boolean;
        Value: Text[250];
    begin
        if not GetTextParameter(RecordID, ParameterId, Value) then
            exit(false);

        if not Evaluate(Result, Value) then
            exit(false);

        ParameterValue := Result;
        exit(true);
    end;

    [Obsolete('Replaced by GetIntegerParameter().', '17.0')]
    procedure GetParameterInteger(RecordID: RecordID; ParameterId: Integer; var ParameterValue: Integer): Boolean
    begin
        exit(GetIntegerParameter(RecordID, "Batch Posting Parameter Type".FromInteger(ParameterId), ParameterValue));
    end;

    procedure GetIntegerParameter(RecordID: RecordID; ParameterId: Enum "Batch Posting Parameter Type"; var ParameterValue: Integer): Boolean
    var
        Result: Integer;
        Value: Text[250];
    begin
        if not GetTextParameter(RecordID, ParameterId, Value) then
            exit(false);

        if not Evaluate(Result, Value) then
            exit(false);

        ParameterValue := Result;
        exit(true);
    end;

    [Obsolete('Replaced by GetDateParameter().', '17.0')]
    procedure GetParameterDate(RecordID: RecordID; ParameterId: Integer; var ParameterValue: Date): Boolean
    begin
        exit(GetDateParameter(RecordID, "Batch Posting Parameter Type".FromInteger(ParameterId), ParameterValue));
    end;

    procedure GetDateParameter(RecordID: RecordID; ParameterId: Enum "Batch Posting Parameter Type"; var ParameterValue: Date): Boolean
    var
        Result: Date;
        Value: Text[250];
    begin
        if not GetTextParameter(RecordID, ParameterId, Value) then
            exit(false);

        if not Evaluate(Result, Value) then
            exit(false);

        ParameterValue := Result;
        exit(true);
    end;

    procedure GetIsCustomProcessingHandled(): Boolean
    begin
        exit(IsCustomProcessingHandled);
    end;

    procedure GetKeepParameters(): Boolean
    begin
        exit(KeepParameters);
    end;

    procedure GetRecRefForCustomProcessing(var RecRef: RecordRef)
    begin
        RecRef := RecRefCustomerProcessing;
    end;

    [Scope('OnPrem')]
    procedure GetBatchFromSession(SourceRecordID: RecordID; SourceSessionID: Integer)
    var
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingSessionMap.SetRange("Record ID", SourceRecordID);
        BatchProcessingSessionMap.SetRange("Session ID", SourceSessionID);
        BatchProcessingSessionMap.SetRange("User ID", UserSecurityId);
        if BatchProcessingSessionMap.FindFirst then begin
            BatchProcessingSessionMap."Session ID" := SessionId;
            BatchProcessingSessionMap.Modify();
        end;
        BatchID := BatchProcessingSessionMap."Batch ID";
    end;

    procedure SetRecRefForCustomProcessing(RecRef: RecordRef)
    begin
        RecRefCustomerProcessing := RecRef;
    end;

    procedure SetProcessingCodeunit(NewProcessingCodeunitID: Integer)
    begin
        ProcessingCodeunitID := NewProcessingCodeunitID;
    end;

    local procedure BatchShouldBeProcessedInBackground(var RecRef: RecordRef; var FullBatchProcessed: Boolean): Boolean
    var
        IsProcessed: Boolean;
        SkippedRecordExists: Boolean;
    begin
        IsProcessed := false;
        OnBeforeBatchShouldBeProcessedInBackground(RecRef, IsProcessed);
        if IsProcessed then
            exit(false);

        if not IsPostWithJobQueueEnabled() then
            exit(false);

        ProcessBatchInBackground(RecRef, SkippedRecordExists);
        FullBatchProcessed := not SkippedRecordExists;

        exit(true);
    end;

    local procedure IsPostWithJobQueueEnabled() Result: Boolean
    begin
        OnIsPostWithJobQueueEnabled(Result);
    end;

    local procedure ProcessBatchInBackground(var RecRef: RecordRef; var SkippedRecordExists: Boolean)
    begin
        OnProcessBatchInBackground(RecRef, SkippedRecordExists);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnVerifyRecord(var RecRef: RecordRef; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeBatchProcess(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeBatchProcessing(var RecRef: RecordRef; var BatchConfirm: Option)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterBatchProcess(var RecRef: RecordRef; var CounterPosted: Integer; ProcessingCodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterBatchProcessing(var RecRef: RecordRef; PostingResult: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnCustomProcessing(var RecRef: RecordRef; var Handled: Boolean; var KeepParameters: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBatchProcessOnBeforeShowMessage(CounterPosted: Integer; CounterTotal: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBatchProcessOnBeforeResetBatchID(var RecRef: RecordRef; ProcessingCodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBatchShouldBeProcessedInBackground(var RecRef: RecordRef; var IsProcessed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsPostWithJobQueueEnabled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetParameterOnBeforeParameterInsert(BatchProcessingParameter: Record "Batch Processing Parameter"; var IsProcessed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessBatchInBackground(var RecRef: RecordRef; var SkippedRecordExists: Boolean)
    begin
    end;
}

