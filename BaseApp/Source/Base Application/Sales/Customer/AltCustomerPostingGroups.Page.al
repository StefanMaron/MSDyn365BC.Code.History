namespace Microsoft.Sales.Customer;

page 935 "Alt. Customer Posting Groups"
{
    Caption = 'Alternative Customer Posting Groups';
    DataCaptionFields = "Customer Posting Group";
    PageType = List;
    SourceTable = "Alt. Customer Posting Group";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Alt. Customer Posting Group"; Rec."Alt. Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer group for posting business transactions to general general ledger accounts.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control2; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control3; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}
