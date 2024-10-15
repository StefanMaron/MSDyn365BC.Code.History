page 27024 "SAT Hazardous Materials"
{
    DelayedInsert = true;
    Caption = 'SAT Hazardous Materials';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "SAT Hazardous Material";
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
                    ToolTip = 'Specifies a code for this entry according to the SAT hazardous definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description for this entry according to the SAT hazardous definition.';
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

