codeunit 4008 "Hybrid BC Management"
{
    Permissions = tabledata "Intelligent Cloud Table Status" = rimd;

    var
        SqlCompatibilityErr: Label 'SQL database must be at compatibility level 130 or higher.';
        DatabaseTooLargeErr: Label 'The maximum replicated data size of 150 GB has been exceeded.';
        TableNotExistsErr: Label 'The table does not exist in the local instance.';
        SchemaMismatchErr: Label 'The local table schema differs from the Business Central cloud table.';
        FailurePreparingDataErr: Label 'Failed to prepare data for the table. Inner error: %1';
        FailureCopyingTableErr: Label 'Failed to copy the table. Inner error: %1';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Message Management", 'OnResolveMessageCode', '', false, false)]
    local procedure GetBCMessageOnResolveMessageCode(MessageCode: Code[10]; InnerMessage: Text; var Message: Text)
    var
        ErrorCodePosition: Integer;
    begin
        if Message <> '' then
            exit;

        if MessageCode = '' then begin
            ErrorCodePosition := StrPos(InnerMessage, 'SqlErrorNumber=');
            if ErrorCodePosition > 0 then
                MessageCode := CopyStr(InnerMessage, ErrorCodePosition + 15, 5);
        end;

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
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        IntelligentCloudTableStatus: Record "Intelligent Cloud Table Status";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        HybridBCWizard: Codeunit "Hybrid BC Wizard";
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        ErrorMessage: Text;
    begin
        if not HybridCloudManagement.CanHandleNotification(SubscriptionId, HybridBCWizard.ProductId()) then
            exit;

        HybridReplicationSummary.Get(RunId);

        IntelligentCloudTableStatus.SetFilter("Run ID", RunId);
        if IntelligentCloudTableStatus.FindSet() then
            repeat
                HybridReplicationDetail.Init();
                HybridReplicationDetail."Run ID" := RunId;
                HybridReplicationDetail."Start Time" := HybridReplicationSummary."Start Time";
                HybridReplicationDetail."End Time" := HybridReplicationSummary."End Time";

                HybridReplicationDetail."Table Name" := IntelligentCloudTableStatus."Table Name";
                HybridReplicationDetail."Company Name" := IntelligentCloudTableStatus."Company Name";
                HybridReplicationDetail.Status := HybridReplicationDetail.Status::Successful;

                if (IntelligentCloudTableStatus."Error Message" <> '') or
                    (IntelligentCloudTableStatus."Error Code" <> '') then begin
                    ErrorMessage := HybridMessageManagement.ResolveMessageCode(CopyStr(IntelligentCloudTableStatus."Error Code", 1, 10), IntelligentCloudTableStatus."Error Message");
                    HybridMessageManagement.SetHybridReplicationDetailStatus(IntelligentCloudTableStatus."Error Code", HybridReplicationDetail);
                    HybridReplicationDetail.SetErrors(ErrorMessage);
                end;

                HybridReplicationDetail.Insert();
            until IntelligentCloudTableStatus.Next() = 0;
        IntelligentCloudTableStatus.DeleteAll();
    end;
}