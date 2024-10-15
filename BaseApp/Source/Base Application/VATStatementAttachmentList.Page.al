page 11773 "VAT Statement Attachment List"
{
    Caption = 'VAT Statement Attachment List';
    DataCaptionFields = "VAT Statement Template Name", "VAT Statement Name";
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "VAT Statement Attachment";

    layout
    {
        area(content)
        {
            repeater(Control1220004)
            {
                ShowCaption = false;
                field("VAT Statement Name"; "VAT Statement Name")
                {
                    ToolTip = 'Specifies the name of VAT statement.';
                    Visible = false;
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of VAT statement attachment.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the VAT statement attachment list.';
                }
                field("File Name"; "File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name and address of the attachment file created for VAT statement.';
                }
            }
        }
    }

    actions
    {
    }
}

