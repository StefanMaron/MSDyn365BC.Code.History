codeunit 132566 "Read Master Data from Cache 2"
{

    trigger OnRun()
    var
        FileName: Text;
    begin
        FileName := IdentifyCacheLocation;
        ReadFileFromCache(TempBlob, FileName);
    end;

    var
        ImportFileQst: Label 'File is not available in the cache. Do you want to import it?';
        SetupTableMissingErr: Label '%1 is missing.', Comment = '%1=TableCaption';
        UploadFileQst: Label 'File is not located on the server. Do you want to upload it?';
        TempBlob: Codeunit "Temp Blob";

    local procedure IdentifyCacheLocation(): Text
    var
        MasterDataSetupSample: Record "Master Data Setup Sample";
    begin
        if not MasterDataSetupSample.Get then
            Error(SetupTableMissingErr, MasterDataSetupSample.TableCaption);

        exit(MasterDataSetupSample.Path + '\' + MasterDataSetupSample.Name);
    end;

    local procedure ReadFileFromCache(var TempBlob2: Codeunit "Temp Blob"; FileName: Text)
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        ReadFileInBase64Encoding: Codeunit "Read File in Base64 Encoding";
        FileNotFoundException: DotNet FileNotFoundException;
        UnauthorizedAccessException: DotNet "System.UnauthorizedAccessException";
    begin
        ReadFileInBase64Encoding.SetFileName(FileName);

        if not ReadFileInBase64Encoding.Run then begin
            DotNetExceptionHandler.Collect;
            ReadFileInBase64Encoding.GetTempBlob(TempBlob2);
            case true of
                DotNetExceptionHandler.TryCastToType(GetDotNetType(FileNotFoundException)):
                    ImportFile(TempBlob2);
                DotNetExceptionHandler.TryCastToType(GetDotNetType(UnauthorizedAccessException)):
                    UploadFileFromClient(TempBlob2, FileName);
                else
                    DotNetExceptionHandler.Rethrow;
            end;
        end else
            ReadFileInBase64Encoding.GetTempBlob(TempBlob2);
    end;

    local procedure ImportFile(var TempBlob2: Codeunit "Temp Blob")
    var
        FileMgt: Codeunit "File Management";
    begin
        if Confirm(ImportFileQst, true) then
            FileMgt.BLOBImport(TempBlob2, '');
    end;

    local procedure UploadFileFromClient(var TempBlob2: Codeunit "Temp Blob"; ClientFileName: Text)
    var
        FileMgt: Codeunit "File Management";
        ServerFileName: Text;
    begin
        if Confirm(UploadFileQst, true) then begin
            ServerFileName := FileMgt.UploadFileSilent(ClientFileName);
            FileMgt.BLOBImportFromServerFile(TempBlob2, ServerFileName);
            // Update the Master Data Setup table to point to the server copy.
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTempBlob(var TempBlob2: Codeunit "Temp Blob")
    begin
        TempBlob2 := TempBlob
    end;
}

