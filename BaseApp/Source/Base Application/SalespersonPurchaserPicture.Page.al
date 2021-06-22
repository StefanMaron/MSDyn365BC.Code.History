page 5108 "Salesperson/Purchaser Picture"
{
    Caption = 'Salesperson/Purchaser Picture';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = CardPart;
    SourceTable = "Salesperson/Purchaser";

    layout
    {
        area(content)
        {
            field(Image; Image)
            {
                ApplicationArea = Basic, Suite;
                ShowCaption = false;
                ToolTip = 'Specifies the picture that has been inserted for the salesperson or purchaser.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(TakePicture)
            {
                ApplicationArea = All;
                Caption = 'Take';
                Image = Camera;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Activate the camera on the device.';
                Visible = CameraAvailable;

                trigger OnAction()
                var
                    InStream: InStream;
                begin
                    TestField(Code);
                    TestField(Name);

                    if not CameraAvailable then
                        exit;

                    Camera.SetQuality(100); // 100%
                    Camera.RunModal();
                    if Camera.HasPicture() then begin
                        if Image.HasValue then
                            if not Confirm(OverrideImageQst) then
                                exit;

                        Camera.GetPicture(Instream);

                        Clear(Image);
                        Image.ImportStream(Instream, 'Salesperson Purchaser Picture');
                        if not Modify(true) then
                            Insert(true);
                    end;

                    Clear(Camera);
                end;
            }
            action(ImportPicture)
            {
                ApplicationArea = All;
                Caption = 'Import';
                Image = Import;
                ToolTip = 'Import a picture file.';

                trigger OnAction()
                var
                    FileManagement: Codeunit "File Management";
                    FileName: Text;
                    ClientFileName: Text;
                begin
                    TestField(Code);
                    TestField(Name);

                    if Image.HasValue then
                        if not Confirm(OverrideImageQst) then
                            exit;

                    FileName := FileManagement.UploadFile(SelectPictureTxt, ClientFileName);
                    if FileName = '' then
                        exit;

                    Clear(Image);
                    Image.ImportFile(FileName, ClientFileName);
                    Modify(true);

                    if FileManagement.DeleteServerFile(FileName) then;
                end;
            }
            action(ExportFile)
            {
                ApplicationArea = All;
                Caption = 'Export';
                Enabled = DeleteExportEnabled;
                Image = Export;
                ToolTip = 'Export the picture to a file.';

                trigger OnAction()
                var
                    FileManagement: Codeunit "File Management";
                    ToFile: Text;
                    ExportPath: Text;
                begin
                    TestField(Code);
                    TestField(Name);

                    ToFile := StrSubstNo('%1 %2.jpg', Code, Name);
                    ExportPath := TemporaryPath + Code + Format(Image.MediaId);
                    Image.ExportFile(ExportPath);

                    FileManagement.ExportImage(ExportPath, ToFile);
                end;
            }
            action(DeletePicture)
            {
                ApplicationArea = All;
                Caption = 'Delete';
                Enabled = DeleteExportEnabled;
                Image = Delete;
                ToolTip = 'Delete the record.';

                trigger OnAction()
                begin
                    TestField(Code);

                    if not Confirm(DeleteImageQst) then
                        exit;

                    Clear(Image);
                    Modify(true);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetEditableOnPictureActions;
    end;

    trigger OnOpenPage()
    begin
        CameraAvailable := Camera.IsAvailable();
    end;

    var
        Camera: Page Camera;
        [InDataSet]
        CameraAvailable: Boolean;
        OverrideImageQst: Label 'The existing picture will be replaced. Do you want to continue?';
        DeleteImageQst: Label 'Are you sure you want to delete the picture?';
        SelectPictureTxt: Label 'Select a picture to upload';
        DeleteExportEnabled: Boolean;

    local procedure SetEditableOnPictureActions()
    begin
        DeleteExportEnabled := Image.HasValue;
    end;
}

