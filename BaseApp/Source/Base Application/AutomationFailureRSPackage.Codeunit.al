codeunit 5434 "Automation - Failure RSPackage"
{
    TableNo = "Config. Package";

    trigger OnRun()
    begin
        if "Import Status" in ["Import Status"::InProgress, "Import Status"::Scheduled] then begin
            "Import Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen("Import Error"));
            Validate("Import Status", "Import Status"::Error);
        end else
            if "Apply Status" in ["Apply Status"::InProgress, "Apply Status"::Scheduled] then begin
                "Apply Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen("Apply Error"));
                if "Apply Error" = '' then
                    "Apply Error" := ApplyErrorLbl;
                Validate("Apply Status", "Apply Status"::Error);
            end;
        Modify(true);
        Commit();
    end;

    var
        ApplyErrorLbl: Label 'Applying configuration package failed.';
}

