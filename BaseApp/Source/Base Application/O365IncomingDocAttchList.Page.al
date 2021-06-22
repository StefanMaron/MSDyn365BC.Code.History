page 2122 "O365 Incoming Doc. Attch. List"
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
            action(DrillDown)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'View File';
                Gesture = LeftSwipe;
                Image = Picture;
                Promoted = true;
                PromotedCategory = Category4;
                Scope = Repeater;
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
                Gesture = RightSwipe;
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
            action(Open)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Open';
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
                Visible = false;

                trigger OnAction()
                begin
                    O365SalesAttachmentMgt.OpenAttachmentPreviewIfSupported(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        O365SalesAttachmentMgt: Codeunit "O365 Sales Attachment Mgt";
        MediaUpload: Page "Media Upload";
        Camera: Page Camera;

    procedure ImportNewFile()
    begin
        if MediaUpload.IsAvailable() then
            ImportFromDevice()
        else
            O365SalesAttachmentMgt.ImportAttachmentFromFileSystem(Rec);
    end;

    local procedure ImportFromDevice()
    var
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        PictureInStream: InStream;
    begin
        if not MediaUpload.IsAvailable() then
            exit;

        MediaUpload.SetMediaType(Enum::"Media Type"::Picture);
        MediaUpload.RunModal();
        if MediaUpload.HasMedia() then begin
            MediaUpload.GetMedia(PictureInStream);
            ImportAttachmentIncDoc.ProcessAndUploadPicture(PictureInStream, Rec);
        end;
        Clear(MediaUpload);
    end;

    [TryFunction]
    procedure TakeNewPicture()
    var
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        PictureInStream: InStream;
    begin
        if not Camera.IsAvailable() then
            exit;
        Camera.RunModal();
        if Camera.HasPicture() then begin
            Camera.GetPicture(PictureInStream);
            ImportAttachmentIncDoc.ProcessAndUploadPicture(PictureInStream, Rec);
        end;
        Clear(Camera);
    end;

    procedure GetCameraAvailable(): Boolean
    begin
        exit(Camera.IsAvailable());
    end;
}

