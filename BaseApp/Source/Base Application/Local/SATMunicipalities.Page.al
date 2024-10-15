page 27027 "SAT Municipalities"
{
    DelayedInsert = true;
    Caption = 'SAT Municipalities';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "SAT Municipality";
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
                    ToolTip = 'Specifies a code for this entry according to the SAT municipality definition.';
                }
                field(State; Rec.State)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the state code according to SAT.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description for this entry according to the SAT municipality definition.';
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

