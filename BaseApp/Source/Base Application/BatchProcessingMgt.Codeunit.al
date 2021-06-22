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
    begin
        if ProcessingCodeunitID = 0 then
            Error(ProcessingCodeunitNotSetErr);

        OnBeforeBatchProcess(RecRef);

        with RecRef do begin
            if IsEmpty then
                exit;

            FillBatchProcessingMap(RecRef);
            Commit();

            FindSet;

            if GuiAllowed then begin
                Window.Open(PostingTemplateMsg);
                CounterTotal := Count;
            end;

            if ErrorMessageMgt.Activate(ErrorMessageHandler) then
                ErrorMessageMgt.PushContext(ErrorContextElement, Number, 0, StrSubstNo(BatchProcessingTxt, Caption));
            repeat
                if GuiAllowed then begin
                    CounterToPost += 1;
                    Window.Update(1, Round(CounterToPost / CounterTotal * 10000, 1));
                end;

                if CanProcessRecord(RecRef) then
                    if ProcessRecord(RecRef, BatchConfirm) then
                        CounterPosted += 1;
            until Next = 0;

            ResetBatchID;

            IsHandled := false;
            OnBatchProcessOnBeforeShowMessage(CounterPosted, CounterTotal, IsHandled);
            if not IsHandled then
                if GuiAllowed then begin
                    Window.Close;
                    if CounterPosted <> CounterTotal then
                        ErrorMessageHandler.NotifyAboutErrors
                    else
                        Message(BatchCompletedMsg);
                end;
        end;

        OnAfterBatchProcess(RecRef, CounterPosted);
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

    local procedure FillBatchProcessingMap(var RecRef: RecordRef)
    begin
        with RecRef do begin
            FindSet;
            repeat
                DeleteLostParameters(RecordId);
                InsertBatchProcessingSessionMapEntry(RecRef);
            until Next = 0;
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
                if not BatchProcessingParameter.IsEmpty then
                    BatchProcessingParameter.DeleteAll();
            until BatchProcessingSessionMap.Next = 0;
            BatchProcessingSessionMap.DeleteAll();
        end;
    end;

    procedure AddParameter(ParameterId: Integer; Value: Variant)
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
    begin
        InitBatchID;

        BatchProcessingParameter.Init();
        BatchProcessingParameter."Batch ID" := BatchID;
        BatchProcessingParameter."Parameter Id" := ParameterId;
        BatchProcessingParameter."Parameter Value" := Format(Value);
        BatchProcessingParameter.Insert();
    end;

    procedure GetParameterText(RecordID: RecordID; ParameterId: Integer; var ParameterValue: Text[250]): Boolean
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingSessionMap.SetRange("Record ID", RecordID);
        BatchProcessingSessionMap.SetRange("User ID", UserSecurityId);
        BatchProcessingSessionMap.SetRange("Session ID", SessionId);

        if not BatchProcessingSessionMap.FindFirst then
            exit(false);

        if not BatchProcessingParameter.Get(BatchProcessingSessionMap."Batch ID", ParameterId) then
            exit(false);

        ParameterValue := BatchProcessingParameter."Parameter Value";
        exit(true);
    end;

    procedure GetParameterBoolean(RecordID: RecordID; ParameterId: Integer; var ParameterValue: Boolean): Boolean
    var
        Result: Boolean;
        Value: Text[250];
    begin
        if not GetParameterText(RecordID, ParameterId, Value) then
            exit(false);

        if not Evaluate(Result, Value) then
            exit(false);

        ParameterValue := Result;
        exit(true);
    end;

    procedure GetParameterInteger(RecordID: RecordID; ParameterId: Integer; var ParameterValue: Integer): Boolean
    var
        Result: Integer;
        Value: Text[250];
    begin
        if not GetParameterText(RecordID, ParameterId, Value) then
            exit(false);

        if not Evaluate(Result, Value) then
            exit(false);

        ParameterValue := Result;
        exit(true);
    end;

    procedure GetParameterDate(RecordID: RecordID; ParameterId: Integer; var ParameterValue: Date): Boolean
    var
        Result: Date;
        Value: Text[250];
    begin
        if not GetParameterText(RecordID, ParameterId, Value) then
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
    local procedure OnAfterBatchProcess(var RecRef: RecordRef; var CounterPosted: Integer)
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
}

