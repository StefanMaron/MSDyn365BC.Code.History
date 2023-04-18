#if not CLEAN21
page 2122 "O365 Incoming Doc. Attch. List"
{
    Caption = 'Incoming Document Files';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    PromotedActionCategories = 'New,Process,Report,Manage';
    SourceTable = "Incoming Document Attachment";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the name of the attached file.';

                    trigger OnDrillDown()
                    begin
                        O365SalesAttachmentMgt.OpenAttachmentPreviewIfSupported(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the attached file.';
                }
                field("File Extension"; Rec."File Extension")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the file type of the attached file.';
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Delete';
                Gesture = RightSwipe;
                Image = Delete;
                Promoted = true;
                PromotedCategory = Category4;
                Scope = Repeater;
                ToolTip = 'Delete the record.';

                trigger OnAction()
                begin
                    Delete();
                    CurrPage.Update();
                end;
            }
            action(Open)
            {
                ApplicationArea = Invoicing, Basic, Suite;
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
        Camera: Codeunit Camera;
        MediaUpload: Page "Media Upload";

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
        PictureName: Text;
    begin
        if Camera.GetPicture(PictureInStream, PictureName) then
            ImportAttachmentIncDoc.ProcessAndUploadPicture(PictureInStream, Rec);
    end;

    procedure GetCameraAvailable(): Boolean
    begin
        exit(Camera.IsAvailable());
    end;
}
#endif
