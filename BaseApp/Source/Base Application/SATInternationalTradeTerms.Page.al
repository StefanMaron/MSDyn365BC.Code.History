page 27045 "SAT International Trade Terms"
{
    PageType = List;
    SourceTable = "SAT International Trade Term";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for this entry according to the SAT internatoinal trade terms definition.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the SAT internatoinal trade terms definition.';
                }
            }
        }
    }

    actions
    {
    }
}

