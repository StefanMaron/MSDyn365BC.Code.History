page 27008 "CFDI Subjects to Tax"
{
    Caption = 'CFDI Subject to Tax';
    PageType = List;
    SourceTable = "CFDI Subject to Tax";
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
                    ToolTip = 'Specifies a code for this entry according to the CFDI subject to tax definition.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the CFDI subject to tax definition.';
                }
            }
        }
    }

    actions
    {
    }
}

