page 27013 "SAT Item Subform"
{
    Caption = 'SAT Item Subform';
    PageType = ListPart;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved item.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the involved item.';
                }
                field("SAT Item Classification"; "SAT Item Classification")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SAT classification of the involved item.';
                }
            }
        }
    }

    actions
    {
    }
}

