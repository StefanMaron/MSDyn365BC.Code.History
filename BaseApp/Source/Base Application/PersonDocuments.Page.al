page 17353 "Person Documents"
{
    Caption = 'Person Documents';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Person Document";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Valid from Date"; "Valid from Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Valid to Date"; "Valid to Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Series"; "Document Series")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Issue Authority"; "Issue Authority")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Issue Date"; "Issue Date")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

