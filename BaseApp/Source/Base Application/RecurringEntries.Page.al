page 15000302 "Recurring Entries"
{
    Caption = 'Recurring Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Recurring Post";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Blanket Order No."; "Blanket Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the blanket order number associated with the recurring document.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the recurring post.';
                }
                field(Time; Time)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the time of the recurring post.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type associated with the recurring post.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number associated with the recurring document.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user ID associated with the recurring post.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the serial number associated with the recurring document.';
                }
            }
        }
    }

    actions
    {
    }
}

