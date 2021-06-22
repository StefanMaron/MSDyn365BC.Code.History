page 2123 "O365 Incoming Doc. Att. Pict."
{
    Caption = 'Attachment Picture';
    DataCaptionExpression = Name;
    Editable = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Manage';
    SourceTable = "Incoming Document Attachment";
    SourceTableView = WHERE(Type = CONST(Image));

    layout
    {
        area(content)
        {
            field(AttachmentContent; Content)
            {
                ApplicationArea = Basic, Suite, Invoicing;
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
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Remove attachment';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    if not Confirm(DeleteQst, true) then
                        exit;
                    Delete;
                    CurrPage.Close;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not IncomingDocumentAttachment.Get("Incoming Document Entry No.", "Line No.") then
            IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment.CalcFields(Content);
        SetRecFilter;
    end;

    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        DeleteQst: Label 'Are you sure?';
}

