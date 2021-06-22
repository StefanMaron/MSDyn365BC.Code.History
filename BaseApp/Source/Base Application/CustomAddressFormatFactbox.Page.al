page 727 "Custom Address Format Factbox"
{
    Caption = 'Custom Address Format';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Custom Address Format";
    SourceTableView = SORTING("Country/Region Code", "Line Position");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Line Format"; "Line Format")
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

