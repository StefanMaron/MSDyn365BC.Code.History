page 27017 "SAT Payment Terms"
{
    Caption = 'SAT Payment Terms';
    PageType = List;
    SourceTable = "SAT Payment Term";
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
                    ToolTip = 'Specifies a code for this entry according to the SAT payment term definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the SAT payment term definition.';
                }
            }
        }
    }

    actions
    {
    }
}

