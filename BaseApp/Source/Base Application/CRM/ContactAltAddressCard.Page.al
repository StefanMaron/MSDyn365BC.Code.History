page 5056 "Contact Alt. Address Card"
{
    Caption = 'Contact Alt. Address Card';
    DataCaptionExpression = Caption();
    PageType = Card;
    SourceTable = "Contact Alt. Address";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                group(Control1040008)
                {
                    ShowCaption = false;
                    Visible = IsAddressLookupTextEnabled;
                    field(LookupAddress; LookupAddressLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            ShowPostcodeLookup(true);
                        end;
                    }
                }
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the alternate address.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company for the alternate address.';
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s address. This address will appear on all sales documents for the customer.';

                    trigger OnValidate()
                    var
                        PostcodeBusinessLogic: Codeunit "Postcode Business Logic";
                    begin
                        PostcodeBusinessLogic.ShowDiscoverabilityNotificationIfNeccessary();
                    end;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the contact''s alternative address.';
                }
                field(County; County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county for the contact''s alternative address.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the postal code.';

                    trigger OnValidate()
                    var
                        PostcodeBusinessLogic: Codeunit "Postcode Business Logic";
                    begin
                        PostcodeBusinessLogic.ShowDiscoverabilityNotificationIfNeccessary();
                        ShowPostcodeLookup(false);
                    end;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code for the contact''s alternate address. To see the country/region codes in the Country/Region table, click the field.';

                    trigger OnValidate()
                    begin
                        HandleAddressLookupVisibility();
                    end;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number for the alternate address.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No.2"; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number for the alternate address.';
                }
                field("Mobile Phone No."; Rec."Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the mobile phone number for the alternate address.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the fax number for the alternate address.';
                }
                field("Telex No."; Rec."Telex No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telex number for the alternate address.';
                }
                field(Pager; Pager)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the pager number for the contact at the alternate address.';
                }
                field("Telex Answer Back"; Rec."Telex Answer Back")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telex answer back number for the alternate address.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the e-mail address for the contact at the alternate address.';
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact''s web site.';
                }
            }
        }
        area(factboxes)
        {
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
            group("&Alt. Contact Address")
            {
                Caption = '&Alt. Contact Address';
                action("Date Ranges")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Ranges';
                    Image = DateRange;
                    RunObject = Page "Alt. Addr. Date Ranges";
                    RunPageLink = "Contact No." = FIELD("Contact No."),
                                  "Contact Alt. Address Code" = FIELD(Code);
                    ToolTip = 'Specify date ranges that apply to the contact''s alternate address.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        HandleAddressLookupVisibility();
    end;

    var
        Text000: Label 'untitled';
        IsAddressLookupTextEnabled: Boolean;
        LookupAddressLbl: Label 'Lookup address from postcode';

    procedure Caption(): Text
    var
        Cont: Record Contact;
    begin
        if Cont.Get("Contact No.") then
            exit("Contact No." + ' ' + Cont.Name + ' ' + Code + ' ' + "Company Name");

        exit(Text000);
    end;

    local procedure ShowPostcodeLookup(ShowInputFields: Boolean)
    var
        TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary;
        TempAutocompleteAddress: Record "Autocomplete Address" temporary;
        PostcodeBusinessLogic: Codeunit "Postcode Business Logic";
    begin
        if not PostcodeBusinessLogic.SupportedCountryOrRegionCode("Country/Region Code") then
            exit;

        if not PostcodeBusinessLogic.IsConfigured() or (("Post Code" = '') and not ShowInputFields) then
            exit;

        TempEnteredAutocompleteAddress.Address := Address;
        TempEnteredAutocompleteAddress.Postcode := "Post Code";

        if not PostcodeBusinessLogic.ShowLookupWindow(TempEnteredAutocompleteAddress, ShowInputFields, TempAutocompleteAddress) then
            exit;

        CopyAutocompleteFields(TempAutocompleteAddress);
        HandleAddressLookupVisibility();
    end;

    local procedure CopyAutocompleteFields(var TempAutocompleteAddress: Record "Autocomplete Address" temporary)
    begin
        Address := TempAutocompleteAddress.Address;
        "Address 2" := TempAutocompleteAddress."Address 2";
        "Post Code" := TempAutocompleteAddress.Postcode;
        City := TempAutocompleteAddress.City;
        County := TempAutocompleteAddress.County;
        "Country/Region Code" := TempAutocompleteAddress."Country / Region";
    end;

    local procedure HandleAddressLookupVisibility()
    var
        PostcodeBusinessLogic: Codeunit "Postcode Business Logic";
    begin
        if not CurrPage.Editable or not PostcodeBusinessLogic.IsConfigured() then
            IsAddressLookupTextEnabled := false
        else
            IsAddressLookupTextEnabled := PostcodeBusinessLogic.SupportedCountryOrRegionCode("Country/Region Code");
    end;
}

