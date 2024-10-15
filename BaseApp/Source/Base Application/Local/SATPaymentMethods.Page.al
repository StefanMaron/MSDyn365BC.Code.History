page 27018 "SAT Payment Methods"
{
    Caption = 'SAT Payment Methods';
    PageType = List;
    SourceTable = "SAT Payment Method";
    ApplicationArea = BasicMX;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for this entry according to the SAT payment method definition.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the SAT payment method definition.';
                }
            }
        }
    }

    actions
    {
    }
}

