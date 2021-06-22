page 2322 "BC O365 Inc. Doc. Attch. List"
{
    Caption = 'Incoming Document Files';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    PromotedActionCategories = 'New,Process,Report,Manage';
    SourceTable = "Incoming Document Attachment";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the name of the attached file.';

                    trigger OnDrillDown()
                    begin
                        O365SalesAttachmentMgt.OpenAttachmentPreviewIfSupported(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ToolTip = 'Specifies the type of the attached file.';
                }
                field("File Extension"; "File Extension")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ToolTip = 'Specifies the file type of the attached file.';
                }
                field("Created Date-Time"; "Created Date-Time")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ToolTip = 'Specifies when the incoming document line was created.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(View)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'View File';
                Enabled = "Line No." <> 0;
                Image = Picture;
                Promoted = true;
                PromotedCategory = Category4;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'View the attached file.';

                trigger OnAction()
                begin
                    O365SalesAttachmentMgt.OpenAttachmentPreviewIfSupported(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Delete)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Delete';
                Enabled = "Line No." <> 0;
                Image = Delete;
                Promoted = true;
                PromotedCategory = Category4;
                Scope = Repeater;
                ToolTip = 'Delete the record.';

                trigger OnAction()
                begin
                    Delete;
                    CurrPage.Update;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CameraAvailable := GetCameraAvailable;
        if CameraAvailable then
            CameraProvider := CameraProvider.Create;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        O365SalesAttachmentMgt.AssertIncomingDocumentSizeBelowMax(Rec);
    end;

    var
        O365SalesAttachmentMgt: Codeunit "O365 Sales Attachment Mgt";
        [RunOnClient]
        [WithEvents]
        CameraProvider: DotNet CameraProvider;
        CameraAvailable: Boolean;

    procedure ImportNewFile()
    begin
        if CameraAvailable then
            ImportFromCamera
        else
            O365SalesAttachmentMgt.ImportAttachmentFromFileSystem(Rec);

        O365SalesAttachmentMgt.WarnIfIncomingDocumentSizeAboveMax(Rec);
        O365SalesAttachmentMgt.NotifyIfFileNameIsTruncated(Rec);
    end;

    local procedure ImportFromCamera()
    var
        CameraOptions: DotNet CameraOptions;
    begin
        if not CameraAvailable then
            exit;

        CameraOptions := CameraOptions.CameraOptions;
        CameraOptions.SourceType := 'photolibrary';
        CameraProvider.RequestPictureAsync(CameraOptions);
    end;

    [TryFunction]
    procedure TakeNewPicture()
    var
        CameraOptions: DotNet CameraOptions;
    begin
        if not CameraAvailable then
            exit;
        CameraOptions := CameraOptions.CameraOptions;
        CameraOptions.Quality := 50;
        CameraProvider.RequestPictureAsync(CameraOptions);
    end;

    procedure GetCameraAvailable(): Boolean
    begin
        exit(CameraProvider.IsAvailable);
    end;

    trigger CameraProvider::PictureAvailable(PictureName: Text; PictureFilePath: Text)
    var
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
    begin
        if (PictureName = '') or (PictureFilePath = '') then
            exit;

        ImportAttachmentIncDoc.ProcessAndUploadPicture(PictureFilePath, Rec);
    end;
}

