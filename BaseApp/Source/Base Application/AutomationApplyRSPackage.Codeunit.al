codeunit 5433 "Automation - Apply RSPackage"
{
    TableNo = "Config. Package";

    trigger OnRun()
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        Validate("Apply Status", "Apply Status"::InProgress);
        Clear("Apply Error");
        Modify(true);

        ConfigPackageTable.SetRange("Package Code", Code);
        ConfigPackageMgt.SetHideDialog(true);
        ConfigPackageMgt.ApplyPackage(Rec, ConfigPackageTable, true);

        // refreshing the record as ApplyPackage updated the Configuration package with the number of records in the package, etc.
        Find();
        Validate("Apply Status", "Apply Status"::Completed);
        Modify(true);
        Commit();
    end;
}

