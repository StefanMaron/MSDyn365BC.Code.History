page 27046 "SAT Custom Units"
{
    PageType = List;
    SourceTable = "SAT Customs Unit";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for this entry according to the SAT custom units definition.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the SAT custom units definition.';
                }
            }
        }
    }

    actions
    {
    }
}

