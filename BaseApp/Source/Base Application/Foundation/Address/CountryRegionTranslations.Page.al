namespace Microsoft.Foundation.Address;

page 80 "Country/Region Translations"
{
    Caption = 'Country/Region Translations';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Country/Region Translation";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Language Code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the translation of the name.';
                }
            }
        }
    }
}