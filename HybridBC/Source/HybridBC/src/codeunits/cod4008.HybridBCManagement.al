codeunit 4008 "Hybrid BC Management"
{
    var
        SqlCompatibilityErr: Label 'SQL database must be at comptibility level 130 or higher.';
        DatabaseTooLargeErr: Label 'The maximum replicated data size of 150 GB has been exceeded.';
        TableNotExistsErr: Label 'The table does not exist in the local instance.';
        SchemaMismatchErr: Label 'The local table schema differs from the Business Central cloud table.';
        FailurePreparingDataErr: Label 'Failed to prepare data for the table. Inner error: %1';
        FailureCopyingTableErr: Label 'Failed to copy the table. Inner error: %1';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Message Management", 'OnResolveMessageCode', '', false, false)]
    local procedure GetBCMessageOnResolveMessageCode(MessageCode: Code[10]; InnerMessage: Text; var Message: Text)
    begin
        if Message <> '' then
            exit;

        case MessageCode of
            '50001':
                Message := SqlCompatibilityErr;
            '50002':
                Message := DatabaseTooLargeErr;
            '50004':
                Message := TableNotExistsErr;
            '50005':
                Message := SchemaMismatchErr;
            '50006':
                Message := StrSubstNo(FailurePreparingDataErr, InnerMessage);
            '50007':
                Message := StrSubstNo(FailureCopyingTableErr, InnerMessage);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnReplicationRunCompleted', '', false, false)]
    local procedure UpdateStatusOnHybridReplicationCompleted(RunId: Text[50]; SubscriptionId: Text; NotificationText: Text)
    var
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        HybridBCWizard: Codeunit "Hybrid BC Wizard";
        JsonManagement: Codeunit "JSON Management";
        Value: Text;
    begin
        if not HybridCloudManagement.CanHandleNotification(SubscriptionId, HybridBCWizard.ProductId()) then
            exit;

        // Get table information, iterate through and create detail records for each
        JsonManagement.InitializeObject(NotificationText);

        if JsonManagement.GetArrayPropertyValueAsStringByName('IncrementalTables', Value) then
            ParseTableDetails(RunId, Value);

        if JsonManagement.GetArrayPropertyValueAsStringByName('FullTables', Value) then
            ParseTableDetails(RunId, Value);
    end;

    local procedure ParseTableDetails(RunId: Text[50]; ResultCollection: Text)
    var
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        JsonManagement: Codeunit "JSON Management";
        ErrorMessage: Text;
        Errors: Text;
        ErrorCode: Text;
        Result: Text;
        ResultCount: Integer;
        Value: Text;
        i: Integer;
    begin
        HybridReplicationSummary.Get(RunId);
        JsonManagement.InitializeCollection(ResultCollection);
        ResultCount := JsonManagement.GetCollectionCount();

        for i := 0 TO ResultCount - 1 do begin
            JsonManagement.GetObjectFromCollectionByIndex(Result, i);
            JsonManagement.InitializeObject(Result);

            HybridReplicationDetail.Init();
            HybridReplicationDetail."Run ID" := RunId;
            HybridReplicationDetail."Start Time" := HybridReplicationSummary."Start Time";
            HybridReplicationDetail."End Time" := HybridReplicationSummary."End Time";

            JsonManagement.GetStringPropertyValueByName('TableName', Value);
            HybridReplicationDetail."Table Name" := CopyStr(Value, 1, 250);

            JsonManagement.GetStringPropertyValueByName('CompanyName', Value);
            HybridReplicationDetail."Company Name" := CopyStr(Value, 1, 250);

            HybridReplicationDetail.Status := HybridReplicationDetail.Status::Successful;

            if JsonManagement.GetStringPropertyValueByName('ErrorCode', ErrorCode) or
               JsonManagement.GetStringPropertyValueByName('ErrorMessage', ErrorMessage) or
               JsonManagement.GetStringPropertyValueByName('Errors', Errors) then begin
                if ErrorMessage = '' then
                    ErrorMessage := Errors;

                if not (ErrorMessage in ['', '[]']) or (ErrorCode <> '') then begin
                    ErrorMessage := HybridMessageManagement.ResolveMessageCode(CopyStr(ErrorCode, 1, 10), ErrorMessage);
                    HybridMessageManagement.SetHybridReplicationDetailStatus(ErrorCode, HybridReplicationDetail);
                    HybridReplicationDetail.SetErrors(ErrorMessage);
                end;
            end;

            HybridReplicationDetail.Insert();
        end;
    end;
}