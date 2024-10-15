codeunit 11602 "Import Subsidiary"
{

    trigger OnRun()
    begin
        BASMngmt.ImportSubsidiaries();
        Clear(BASMngmt);
    end;

    var
        BASMngmt: Codeunit "BAS Management";
}

