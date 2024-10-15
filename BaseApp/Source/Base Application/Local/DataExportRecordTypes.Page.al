page 11014 "Data Export Record Types"
{
    Caption = 'Data Export Record Types';
    PageType = List;
    SourceTable = "Data Export Record Type";

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code for a data export record type.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a short description for a data export record type.';
                }
            }
        }
    }

    actions
    {
    }
}

