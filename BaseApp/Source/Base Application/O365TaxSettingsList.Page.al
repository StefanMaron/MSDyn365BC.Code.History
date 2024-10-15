page 10151 "O365 Tax Settings List"
{
    Caption = 'Tax Rates';
    CardPageID = "O365 Tax Settings Card";
    DeleteAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Tax Area";

    layout
    {
        area(content)
        {
            repeater(Control1020001)
            {
                ShowCaption = false;
                field(GetDescriptionInCurrentLanguage; GetDescriptionInCurrentLanguageFullLength())
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    StyleExpr = StyleExpr;
                    ToolTip = 'Specifies the tax rate used to calculate tax on what you buy or sell.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Open';
                Image = ViewDetails;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"O365 Tax Settings Card", Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DefaultCode := O365TaxSettingsManagement.GetDefaultTaxArea;
        if Code = DefaultCode then
            StyleExpr := 'Strong'
        else
            StyleExpr := 'Standard';
    end;

    var
        O365TaxSettingsManagement: Codeunit "O365 Tax Settings Management";
        DefaultCode: Code[20];
        StyleExpr: Text;
}
