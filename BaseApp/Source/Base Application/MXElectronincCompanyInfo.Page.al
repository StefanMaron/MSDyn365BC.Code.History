page 10458 "MX Electroninc - CompanyInfo"
{
    Caption = 'Company Information';
    PageType = CardPart;
    SourceTable = "Company Information";

    layout
    {
        area(content)
        {
            group(Control1310004)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the company''s name and corporate form. For example, Inc. or Ltd.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the postal code.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the company''s email address.';
                }
                field("RFC Number"; Rec."RFC Number")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the federal registration number for taxpayers.';
                }
#if not CLEAN22
                field("RFC No."; "RFC No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the federal registration number for taxpayers.';
                    ObsoleteReason = 'Replaced with RFC Number';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';
                    Visible = false;
                }
#endif

                field("CURP No."; "CURP No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the unique fiscal card identification number. The CURP number must contain 18 digits.';
                }
                field("State Inscription"; "State Inscription")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the tax ID number that is assigned by state tax authorities to every person or corporation.';
                }
                field("Tax Scheme"; "Tax Scheme")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the tax scheme that the company complies with.';
                }
            }
        }
    }

    actions
    {
    }
}

