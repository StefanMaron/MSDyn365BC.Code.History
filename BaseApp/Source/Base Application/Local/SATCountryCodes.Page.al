page 27044 "SAT Country Codes"
{
    Caption = 'SAT Country Codes';
    PageType = List;
    SourceTable = "SAT Country Code";
    ApplicationArea = BasicMX;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("SAT Country Code"; Rec."SAT Country Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for this entry according to the SAT country code definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the SAT country code definition.';
                }
            }
        }
    }

    actions
    {
    }
}

