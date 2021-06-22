page 2330 "BC O365 Business Info Settings"
{
    Caption = ' ';
    DeleteAllowed = false;
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Company Information";

    layout
    {
        area(content)
        {
            group(Control11)
            {
                InstructionalText = 'Check your business information and your VAT registration number. This is included in your invoices.';
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of your company.';
                    Visible = false;
                }
                field(Picture; Picture)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Add your logo';
                    ToolTip = 'Specifies your company''s logo.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Modify(true);
                    end;
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies your company''s address.';
                    Visible = false;
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies additional address information.';
                    Visible = false;
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Lookup = false;
                    ToolTip = 'Specifies your company''s postal code.';
                    Visible = false;

                    trigger OnValidate()
                    var
                        PostCode: Record "Post Code";
                    begin
                        PostCode.UpdateFromCompanyInformation(Rec, true);
                    end;
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Lookup = false;
                    ToolTip = 'Specifies your company''s city.';
                    Visible = false;

                    trigger OnValidate()
                    var
                        PostCode: Record "Post Code";
                    begin
                        PostCode.UpdateFromCompanyInformation(Rec, false);
                    end;
                }
                field(County; County)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies your company''s county.';
                    Visible = false;

                    trigger OnValidate()
                    var
                        PostCode: Record "Post Code";
                    begin
                        PostCode.UpdateFromCompanyInformation(Rec, false);
                    end;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies your company''s country/region.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        O365CountryRegion: Record "O365 Country/Region";
                    begin
                        if PAGE.RunModal(PAGE::"O365 Country/Region List", O365CountryRegion) <> ACTION::LookupOK then
                            exit;

                        "Country/Region Code" := O365CountryRegion.Code;
                    end;
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies your company''s email address.';
                    Visible = false;

                    trigger OnValidate()
                    var
                        MailManagement: Codeunit "Mail Management";
                    begin
                        if "E-Mail" <> '' then
                            MailManagement.CheckValidEmailAddress("E-Mail");
                    end;
                }
                field("Home Page"; "Home Page")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies your company''s web site.';
                    Visible = false;
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Phone Number';
                    ToolTip = 'Specifies your company''s phone number.';
                    Visible = false;
                }
            }
            field("VAT Registration No."; "VAT Registration No.")
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        Initialize;
    end;

    local procedure Initialize()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

