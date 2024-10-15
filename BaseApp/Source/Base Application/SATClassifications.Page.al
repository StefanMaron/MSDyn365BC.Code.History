page 27040 "SAT Classifications"
{
    Caption = 'SAT Item Classification';
    PageType = List;
    SourceTable = "SAT Classification";
    ApplicationArea = BasicMX;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("SAT Classification"; "SAT Classification")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for this entry according to the SAT item classification definition.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the SAT item classification definition.';
                }
            }
        }
    }

    actions
    {
    }
}

