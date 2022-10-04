codeunit 5432 "Automation - Import RSPackage"
{
    TableNo = "Config. Package";

    trigger OnRun()
    var
        TenantConfigPackageFile: Record "Tenant Config. Package File";
        TempBlobDecompressed: Codeunit "Temp Blob";
        TempBlob: Codeunit "Temp Blob";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        InStream: InStream;
    begin
        Validate("Import Status", "Import Status"::InProgress);
        Clear("Import Error");
        Modify(true);

        TenantConfigPackageFile.Get(Code);
        TempBlob.FromRecord(TenantConfigPackageFile, TenantConfigPackageFile.FieldNo(Content));

        ConfigXMLExchange.SetHideDialog(true);
        ConfigXMLExchange.DecompressPackageToBlob(TempBlob, TempBlobDecompressed);
        TempBlobDecompressed.CreateInStream(InStream);
        ConfigXMLExchange.ImportPackageXMLWithCodeFromStream(InStream, Code);

        // refreshing the record as ImportPackageXMLWithCodeFromStream updated the Configuration package with the number of records in the package, etc.
        Find();
        Validate("Import Status", "Import Status"::Completed);
        Modify(true);
        Commit();
    end;
}

