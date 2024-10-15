page 14953 "KLADR Regions"
{
    Caption = 'Region';
    PageType = List;
    SourceTable = "KLADR Region";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("Address Name"; "Address Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address.';
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

