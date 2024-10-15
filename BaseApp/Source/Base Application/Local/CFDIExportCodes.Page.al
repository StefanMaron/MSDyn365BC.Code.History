page 27004 "CFDI Export Codes"
{
    Caption = 'CFDI Export Codes';
    PageType = List;
    SourceTable = "CFDI Export Code";
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
                    ToolTip = 'Specifies a code for this entry according to the CFDI export definition.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the CFDI export definition.';
                }
                field("Foreign Trade"; "Foreign Trade")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the entry indicates foreing trade according to the SAT export definition.';
                }
            }
        }
    }

    actions
    {
    }
}

