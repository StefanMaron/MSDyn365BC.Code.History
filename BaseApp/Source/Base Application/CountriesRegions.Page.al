page 10 "Countries/Regions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Countries/Regions';
    PageType = List;
    SourceTable = "Country/Region";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("ISO Code"; "ISO Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a two-letter country code defined in ISO 3166-1.';
                }
                field("ISO Numeric Code"; "ISO Numeric Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a three-digit code number defined in ISO 3166-1.';
                }
                field("Address Format"; "Address Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the address that is displayed on external-facing documents. You link an address format to a country/region code so that external-facing documents based on cards or documents with that country/region code use the specified address format. NOTE: If the County field is filled in, then the county will be printed above the country/region unless you select the City+County+Post Code option.';
                }
                field("Contact Address Format"; "Contact Address Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies where you want the contact name to appear in mailing addresses.';
                }
                field("County Name"; "County Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the county.';
                }
                field("EU Country/Region Code"; "EU Country/Region Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the EU code for the country/region you are doing business with.';
                }
                field("Intrastat Code"; "Intrastat Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies an INTRASTAT code for the country/region you are trading with.';
                }
                field("VAT Scheme"; "VAT Scheme")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the national body that issues the VAT registration number for the country/region in connection with electronic document sending.';
                }
            }
        }
        area(factboxes)
        {
            part(Control8; "Custom Address Format Factbox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Country/Region Code" = FIELD(Code);
                Visible = "Address Format" = "Address Format"::Custom;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Country/Region")
            {
                Caption = '&Country/Region';
                Image = CountryRegion;
                action("VAT Reg. No. Formats")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Reg. No. Formats';
                    Image = NumberSetup;
                    RunObject = Page "VAT Registration No. Formats";
                    RunPageLink = "Country/Region Code" = FIELD(Code);
                    ToolTip = 'Specify that the tax registration number for an account, such as a customer, corresponds to the standard format for tax registration numbers in an account''s country/region.';
                }
                action(CustomAddressFormat)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Custom Address Format';
                    Enabled = "Address Format" = "Address Format"::Custom;
                    Image = Addresses;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Define the scope and order of fields that make up the country/region address.';

                    trigger OnAction()
                    var
                        CustomAddressFormat: Record "Custom Address Format";
                        CustomAddressFormatPage: Page "Custom Address Format";
                    begin
                        if "Address Format" <> "Address Format"::Custom then
                            exit;

                        CustomAddressFormat.FilterGroup(2);
                        CustomAddressFormat.SetRange("Country/Region Code", Code);
                        CustomAddressFormat.FilterGroup(0);

                        Clear(CustomAddressFormatPage);
                        CustomAddressFormatPage.SetTableView(CustomAddressFormat);
                        CustomAddressFormatPage.RunModal;
                    end;
                }
            }
        }
    }
}

