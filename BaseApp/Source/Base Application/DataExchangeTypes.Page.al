page 1213 "Data Exchange Types"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Data Exchange Types';
    PageType = List;
    SourceTable = "Data Exchange Type";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data exchange type.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data exchange type.';
                }
                field("Data Exch. Def. Code"; "Data Exch. Def. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data exchange definition that the data exchange type uses.';
                }
            }
        }
    }

    actions
    {
    }
}

