page 12430 "OKATO Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'OKATO Codes';
    PageType = List;
    SourceTable = OKATO;
    UsageCategory = Lists;

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
                    ToolTip = 'Specifies the standard OKATO classification code.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the OKATO classification code.';
                }
                field("Region Code"; "Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the region where the district is located.';
                }
                field("Tax Authority No."; "Tax Authority No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the tax authority associated with the district.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable(not CurrPage.LookupMode);
    end;
}

