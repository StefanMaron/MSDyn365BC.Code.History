page 27047 "SAT Customs Regimes"
{
    DelayedInsert = true;
    Caption = 'SAT Customs Regimes';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "SAT Customs Regime";
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
                    ToolTip = 'Specifies a code for this entry according to the SAT customs regime definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description for this entry according to the SAT custom regime definition.';
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

