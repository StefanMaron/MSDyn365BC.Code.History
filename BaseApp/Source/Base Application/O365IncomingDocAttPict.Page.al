page 2123 "O365 Incoming Doc. Att. Pict."
{
    Caption = 'Attachment Picture';
    DataCaptionExpression = Name;
    Editable = false;
    PageType = Card;
    SourceTable = "Incoming Document Attachment";
    SourceTableView = WHERE(Type = CONST(Image));

    layout
    {
        area(content)
        {
            field(AttachmentContent; Content)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                ShowCaption = false;
                ToolTip = 'Specifies the content of the attachment. ';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(DeleteLine)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Remove attachment';
                Image = Delete;

                trigger OnAction()
                begin
                    if not Confirm(DeleteQst, true) then
                        exit;
                    Delete();
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(DeleteLine_Promoted; DeleteLine)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not IncomingDocumentAttachment.Get("Incoming Document Entry No.", "Line No.") then
            IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment.CalcFields(Content);
        SetRecFilter();
    end;

    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        DeleteQst: Label 'Are you sure?';
}
