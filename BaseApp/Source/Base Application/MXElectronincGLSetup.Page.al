page 10459 "MX Electroninc - GLSetup"
{
    Caption = 'General Ledger Setup';
    PageType = CardPart;
    SourceTable = "General Ledger Setup";

    layout
    {
        area(content)
        {
            group(Control1310001)
            {
                ShowCaption = false;
                field("PAC Code"; "PAC Code")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the authorized service provider, PAC, that will certify your identity by applying digital stamps to your electronic invoices.';
                }
                field("PAC Environment"; "PAC Environment")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies whether your company issues electronic invoices in Mexico, and whether you use the web services of your authorized service provider, PAC, in a test or production environment.';
                }
                field("SAT Certificate"; "SAT Certificate")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the certificate from the tax authorities that you want to use for issuing electronic invoices.';
                }
            }
        }
    }

    actions
    {
    }
}

