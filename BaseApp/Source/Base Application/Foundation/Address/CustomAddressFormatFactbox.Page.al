namespace Microsoft.Foundation.Address;

page 727 "Custom Address Format Factbox"
{
    Caption = 'Custom Address Format';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Custom Address Format";
    SourceTableView = sorting("Country/Region Code", "Line Position");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Line Format"; Rec."Line Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies address fields.';
                }
            }
        }
    }

    actions
    {
    }
}

