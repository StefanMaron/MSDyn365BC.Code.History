#if not CLEAN21
page 2330 "BC O365 Business Info Settings"
{
    Caption = ' ';
    DeleteAllowed = false;
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Company Information";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control11)
            {
                InstructionalText = 'Check your business information and your VAT registration number. This is included in your invoices.';
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of your company.';
                    Visible = false;
                }
                field(Picture; Rec.Picture)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Add your logo';
                    ToolTip = 'Specifies your company''s logo.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.Modify(true);
                    end;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies your company''s address.';
                    Visible = false;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                    Visible = false;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                field(City; Rec.City)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                field(County; Rec.County)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies your company''s county.';
                    Visible = false;

                    trigger OnValidate()
                    var
                        PostCode: Record "Post Code";
                    begin
                        PostCode.UpdateFromCompanyInformation(Rec, false);
                    end;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies your company''s country/region.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        O365CountryRegion: Record "O365 Country/Region";
                    begin
                        if PAGE.RunModal(PAGE::"O365 Country/Region List", O365CountryRegion) <> ACTION::LookupOK then
                            exit;

                        Rec."Country/Region Code" := O365CountryRegion.Code;
                    end;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies your company''s email address.';
                    Visible = false;

                    trigger OnValidate()
                    var
                        MailManagement: Codeunit "Mail Management";
                    begin
                        if Rec."E-Mail" <> '' then
                            MailManagement.CheckValidEmailAddress(Rec."E-Mail");
                    end;
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies your company''s web site.';
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Phone Number';
                    ToolTip = 'Specifies your company''s phone number.';
                    Visible = false;
                }
            }
            field("VAT Registration No."; Rec."VAT Registration No.")
            {
                ApplicationArea = Invoicing, Basic, Suite;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        Initialize();
    end;

    local procedure Initialize()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
#endif
