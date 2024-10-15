page 12202 "VAT Transaction Nature"
{
    Caption = 'VAT Transaction Nature';
    PageType = List;
    SourceTable = "VAT Transaction Nature";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code that identifies the type.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description.';
                }
            }
        }
    }

    actions
    {
    }
}

