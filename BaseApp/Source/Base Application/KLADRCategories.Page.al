page 14952 "KLADR Categories"
{
    Caption = 'KLADR Categories';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "KLADR Category";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field(Level; Level)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(Placement; Placement)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Place Dot"; "Place Dot")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

