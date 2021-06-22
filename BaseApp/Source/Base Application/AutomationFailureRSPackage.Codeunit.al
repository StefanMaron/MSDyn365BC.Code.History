codeunit 5434 "Automation - Failure RSPackage"
{
    TableNo = "Config. Package";

    trigger OnRun()
    begin
        if "Import Status" in ["Import Status"::InProgress, "Import Status"::Scheduled] then
            Validate("Import Status", "Import Status"::Error)
        else
            if "Apply Status" in ["Apply Status"::InProgress, "Apply Status"::Scheduled] then
                Validate("Apply Status", "Apply Status"::Error);
        Modify(true);
        Commit();
    end;
}

