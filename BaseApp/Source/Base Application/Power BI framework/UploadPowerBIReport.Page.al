page 6320 "Upload Power BI Report"
{
    // // Test page for manually importing PBIX blobs into database.
    // // TODO: Remove before check-in.

    Caption = 'Upload Power BI Report';
    PageType = NavigatePage;
    SourceTable = "Power BI Customer Reports";

    layout
    {
        area(content)
        {
            field(FileName; FileName)
            {
                ApplicationArea = All;
                AssistEdit = true;
                Caption = 'File';
                Editable = false;
                ShowMandatory = true;
                ToolTip = 'Specifies File Name';

                trigger OnAssistEdit()
                var
                    TempFileName: Text;
                begin
                    // Event handler for the ellipsis button that opens the file selection dialog.
                    TempFileName := FileManagement.BLOBImportWithFilter(TempBlob, FileDialogTxt, '', FileFilterTxt, ExtFilterTxt);

                    if TempFileName = '' then
                        // User clicked Cancel in the file selection dialog.
                        exit;

                    FileName := TempFileName;

                    if ReportName = '' then begin
                        ReportName := CopyStr(FileManagement.GetFileNameWithoutExtension(FileName), 1, 200);
                        IsFileLoaded := true;
                    end;
                end;

                trigger OnValidate()
                begin
                    if not FileManagement.ClientFileExists(FileName) then
                        Error(FileExistErr, FileName);
                end;
            }
            field(ReportName; ReportName)
            {
                ApplicationArea = All;
                Caption = 'Report Name';
                Editable = IsFileLoaded;
                ShowMandatory = true;
                ToolTip = 'Specifies Report Name';
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("Upload Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Upload Report';
                InFooterBar = true;
                Visible = true;

                trigger OnAction()
                var
                    RecordRef: RecordRef;
                begin
                    UploadedReportCount := Count;

                    if FileName = '' then
                        Error(FileNameErr);

                    if ReportName = '' then
                        Error(ReportNameErr);

                    Reset;
                    SetFilter(Id, ReportID);
                    if not IsEmpty then
                        Error(BlobIdErr);

                    Reset;
                    SetFilter(Name, ReportName);
                    if not IsEmpty then
                        Error(BlobNameErr);

                    Reset;

                    if UploadedReportCount < MaxReportLimit then begin
                        Init;
                        Id := ReportID;
                        Name := ReportName;
                        RecordRef.GetTable(Rec);
                        TempBlob.ToRecordRef(RecordRef, FieldNo("Blob File"));
                        RecordRef.SetTable(Rec);
                        Version := 1;
                        Insert
                    end else
                        Message(TableLimitMsg);
                    Commit();

                    FileName := '';
                    ReportName := '';

                    ReportID := CreateGuid;
                    IsFileLoaded := false;
                    CurrPage.Update(false);
                    Message(UploadMsg);
                end;
            }
        }
    }

    trigger OnInit()
    begin
        MaxReportLimit := 20;
    end;

    trigger OnOpenPage()
    begin
        if not UserPermissions.IsSuper(UserSecurityId) then
            Error(PermissionErr);

        if not PowerBIServiceMgt.IsUserReadyForPowerBI then
            Error(NotReadyErr);

        ReportID := CreateGuid;
    end;

    var
        ReportNameErr: Label 'You must enter a report name.';
        FileNameErr: Label 'You must enter a file name.';
        NotReadyErr: Label 'The Power BI Service is currently unavailable.';
        FileExistErr: Label 'The file %1 does not exist.', Comment = 'asdf';
        BlobIdErr: Label 'A blob with this ID already exists.';
        TempBlob: Codeunit "Temp Blob";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        UserPermissions: Codeunit "User Permissions";
        FileManagement: Codeunit "File Management";
        FileDialogTxt: Label 'Select a PBIX report file.';
        FileFilterTxt: Label 'Power BI Files(*.pbix)|*.pbix';
        ExtFilterTxt: Label 'pbix';
        ReportID: Guid;
        FileName: Text;
        ReportName: Text[200];
        PermissionErr: Label 'User does not have permissions to operate this page.';
        IsFileLoaded: Boolean;
        MaxReportLimit: Integer;
        UploadedReportCount: Integer;
        TableLimitMsg: Label 'The Customer Report table is full. Remove a report and try again.';
        BlobNameErr: Label 'A blob with this name already exists.';
        UploadMsg: Label 'The report has been added for deployment. Once deployed, it will appear in the select reports list.';
}

