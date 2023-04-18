codeunit 485 "Change Global Dim Err. Handler"
{
    TableNo = "Change Global Dim. Log Entry";

    trigger OnRun()
    begin
        LockTable();
        if not Get("Table ID") then
            exit;
        Status := Status::Incomplete;
        "Session ID" := -1;
        "Server Instance ID" := -1;
        Modify();
        LogError(Rec);
        SendTraceTagOnError();
    end;

    local procedure LogError(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.Init();
        JobQueueLogEntry."Entry No." := 0;
        JobQueueLogEntry.ID := ChangeGlobalDimLogEntry."Task ID";
        JobQueueLogEntry."Object Type to Run" := JobQueueLogEntry."Object Type to Run"::Codeunit;
        JobQueueLogEntry."Object ID to Run" := CODEUNIT::"Change Global Dimensions";
        JobQueueLogEntry.Description := ChangeGlobalDimLogEntry."Table Name";
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
        JobQueueLogEntry."Error Message" := GetLastErrorText;
        JobQueueLogEntry.SetErrorCallStack(GetLastErrorCallstack);
        JobQueueLogEntry."Start Date/Time" := CurrentDateTime;
        JobQueueLogEntry."End Date/Time" := JobQueueLogEntry."Start Date/Time";
        JobQueueLogEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueLogEntry."User ID"));
#if not CLEAN20
        JobQueueLogEntry."Processed by User ID" := UserId;
#endif
        JobQueueLogEntry.Insert(true);
    end;
}

