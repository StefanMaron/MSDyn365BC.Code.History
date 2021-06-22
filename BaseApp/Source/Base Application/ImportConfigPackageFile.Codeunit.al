codeunit 1799 "Import Config. Package File"
{
    TableNo = "Configuration Package File";

    trigger OnRun()
    var
        JobQueueEntry: Record "Job Queue Entry";
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        // give time to update AssistedCompanySetupStatus with "Session ID" and "Task ID"
        Sleep(500);

        SetRecFilter;
        if not CODEUNIT.Run(CODEUNIT::"Import Config. Package Files", Rec) then begin
            AssistedCompanySetupStatus.Get(CompanyName);
            with JobQueueEntry do begin
                Init;
                ID := AssistedCompanySetupStatus."Task ID";
                "User ID" := UserId;
                "Object Type to Run" := "Object Type to Run"::Codeunit;
                "Object ID to Run" := CODEUNIT::"Import Config. Package Files";
                Status := Status::Error;
                "Error Message" := GetLastErrorText;
                Description := DescriptionTxt;
                InsertLogEntry(JobQueueLogEntry);
                FinalizeLogEntry(JobQueueLogEntry);
            end;
            Commit();
            Error(GetLastErrorText);
        end;
    end;

    var
        DescriptionTxt: Label 'Could not complete the company setup.';
}

