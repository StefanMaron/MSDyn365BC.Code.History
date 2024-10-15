page 27026 "SAT States"
{
    DelayedInsert = true;
    Caption = 'SAT States';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "SAT State";
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
                    ToolTip = 'Specifies the state code according to SAT.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the name of the state according to SAT.';
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

