namespace System.IO;

using System.Environment.Configuration;
using System.Threading;
using Microsoft.Utilities;

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

        Rec.SetRecFilter();
        if not CODEUNIT.Run(CODEUNIT::"Import Config. Package Files", Rec) then begin
            AssistedCompanySetupStatus.Get(CompanyName);
            JobQueueEntry.Init();
            JobQueueEntry.ID := AssistedCompanySetupStatus."Task ID";
            JobQueueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
            JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
            JobQueueEntry."Object ID to Run" := CODEUNIT::"Import Config. Package Files";
            JobQueueEntry.Status := JobQueueEntry.Status::Error;
            JobQueueEntry."Error Message" := GetLastErrorText;
            JobQueueEntry.Description := DescriptionTxt;
            JobQueueEntry.InsertLogEntry(JobQueueLogEntry);
            JobQueueEntry.FinalizeLogEntry(JobQueueLogEntry);
            Commit();
            Error(GetLastErrorText);
        end;
    end;

    var
        DescriptionTxt: Label 'Could not complete the company setup.';
}

