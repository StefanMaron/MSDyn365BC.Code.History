#if not CLEAN19
codeunit 9888 "SmartList Mgmt"
{
    Access = Internal;
    ObsoleteState = Pending;
    ObsoleteReason = 'The SmartList Designer is not supported in Business Central.';
    ObsoleteTag = '19.0';

    procedure DoesUserHaveManagementAccess(UserSID: Guid): Boolean
    var
        result: Boolean;
    begin
        // Id of the 'SmartList Management' system object
        if TryDoesUserHaveSystemObjectAccess(UserSID, 9610, result) then
            exit(result);

        exit(false);
    end;

    procedure DoesUserHaveImportExportAccess(UserSID: Guid): Boolean
    var
        result: Boolean;
    begin
        // Id of the 'SmartList Import/Export' system object
        if TryDoesUserHaveSystemObjectAccess(UserSID, 9615, result) then
            exit(result);

        exit(false);
    end;

    [TryFunction]
    local procedure TryDoesUserHaveSystemObjectAccess(UserSID: Guid; ObjectId: Integer; var hasAccess: Boolean)
    var
        TempPermission: Record "Permission" temporary;
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        TempCompanyName: Text[50];
    begin
        TempCompanyName := CopyStr(CompanyName(), 1, MaxStrLen(TempCompanyName)); // Necessary to avoid AA0139 - Possible overflow
        EffectivePermissionsMgt.PopulateEffectivePermissionsBuffer(
            TempPermission,
            UserSID,
            TempCompanyName,
            TempPermission."Object Type"::System,
            ObjectId,
            false);

        hasAccess := TempPermission."Execute Permission" = TempPermission."Execute Permission"::Yes;
    end;

    procedure BulkAddQueryPermissions(var QueryManagement: Record "Designed Query Management"; var PermissionSet: Record "Permission Set Buffer")
    var
        Permission: Record "Designed Query Permission";
    begin
        Permission.Init();
        if (QueryManagement.FindSet()) then
            repeat
                if (PermissionSet.FindSet()) then
                    repeat
                        if (not Permission.Get('00000000-0000-0000-0000-000000000000', PermissionSet."Role ID", QueryManagement."Object ID")) then begin
                            Permission."App ID" := '00000000-0000-0000-0000-000000000000';
                            Permission."Role ID" := PermissionSet."Role ID";
                            Permission."Object ID" := QueryManagement."Object ID";
                            Permission."Read Permission" := Permission."Read Permission"::Yes;
                            Permission."Insert Permission" := Permission."Insert Permission"::" ";
                            Permission."Modify Permission" := Permission."Modify Permission"::" ";
                            Permission."Delete Permission" := Permission."Delete Permission"::" ";
                            Permission."Execute Permission" := Permission."Execute Permission"::Yes;
                            Permission.Insert();
                        end;
                    until PermissionSet.Next() = 0;
            until QueryManagement.Next() = 0;
    end;

    procedure BulkAssignGroup(var QueryManagement: Record "Designed Query Management"; Group: Text[100])
    begin
        if (QueryManagement.FindSet()) then
            repeat
                QueryManagement.Group := Group;
                QueryManagement.Modify();
            until QueryManagement.Next() = 0;
    end;

    procedure ExportQueries(var QueryManagement: Record "Designed Query Management"; Filename: Text)
    var
        ResultsRec: Record "SmartList Export Results";
        ArchiveBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        Args: DotNet DqExportArgs;
        Exporter: DotNet DqExporter;
        ExportResult: DotNet DqImportExportResult;
        ExportResults: DotNet DqImportExportResults;
        ArchiveStream: OutStream;
        I: Integer;
    begin
        ArchiveBlob.CreateOutStream(ArchiveStream);
        Args := Args.DqExportArgs(ArchiveStream);
        Exporter := Exporter.DqExporter();

        // Record should be set up with the proper filters so our enumeration gives us all N
        // selected records from the page.
        if (QueryManagement.FindSet()) then
            repeat
                Args.AddObjectId(QueryManagement."Object ID");
            until QueryManagement.Next() = 0;

        // Perform the export and then hand the archive file off to the browser for download.
        ExportResults := Exporter.ExportArchive(Args);
        if ExportResults.Count() > 0 then
            FileMgt.BLOBExport(ArchiveBlob, Filename, true);

        // Clear previous run's results and hydrate the results table with data from this operation.
        ResultsRec.Init();
        ResultsRec.DeleteAll();
        for I := 0 to ExportResults.Count() - 1 do begin
            ExportResult := ExportResults.Get(I);
            ResultsRec.Name := ExportResult.Name();
            ResultsRec.Success := ExportResult.Success();
            ResultsRec.Errors := ExportResult.Errors();
            ResultsRec.Insert();
        end;
    end;

    procedure ImportQueries(ArchiveStream: InStream)
    var
        ResultsRec: Record "SmartList Import Results";
        Importer: DotNet DqImporter;
        ImportResult: DotNet DqImportExportResult;
        ImportResults: DotNet DqImportExportResults;
        I: Integer;
    begin
        // Perform the import
        Importer := Importer.DqImporter();
        ImportResults := Importer.ImportArchive(ArchiveStream);

        // Clear previous run's results and hydrate the results table with data from this operation.
        ResultsRec.Init();
        ResultsRec.DeleteAll();
        for I := 0 to ImportResults.Count() - 1 do begin
            ImportResult := ImportResults.Get(I);
            ResultsRec.Name := ImportResult.Name();
            ResultsRec.Success := ImportResult.Success();
            ResultsRec.Errors := ImportResult.Errors();
            ResultsRec.Insert();
        end;
    end;
}
#endif