page 27028 "SAT Localities"
{
    DelayedInsert = true;
    Caption = 'SAT Localities';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "SAT Locality";
    ApplicationArea = BasicMX;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a code for this entry according to the SAT locality definition.';
                }
                field(State; Rec.State)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the state code for this entry according to SAT.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description for this entry according to the SAT locality definition.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }
}

