page 300 "Ship-to Address"
{
    Caption = 'Ship-to Address';
    DataCaptionExpression = Rec.Caption();
    PageType = Card;
    SourceTable = "Ship-to Address";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                group(Control3)
                {
                    ShowCaption = false;
                    group(Control1040006)
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
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies a ship-to address code.';
                    }
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the name associated with the ship-to address.';
                    }
                    field(GLN; GLN)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the recipient''s GLN code.';
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
                        ToolTip = 'Specifies the city the items are being shipped to.';
                    }
                    group(Control13)
                    {
                        ShowCaption = false;
                        Visible = IsCountyVisible;
                        field(County; County)
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the state, province, or county as a part of the address.';
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the customer''s country/region code. To see the country/region codes in the Country/Region table, click the field.';

                        trigger OnValidate()
                        begin
                            IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
                            HandleAddressLookupVisibility();
                        end;
                    }
                    field(ShowMap; ShowMapLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = TRUE;
                        ToolTip = 'Specifies the customer''s address on your preferred map website.';

                        trigger OnDrillDown()
                        begin
                            CurrPage.Update(true);
                            DisplayMap();
                        end;
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the recipient''s telephone number.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you contact about orders shipped to this address.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the recipient''s fax number.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    Importance = Additional;
                    ToolTip = 'Specifies the recipient''s email address.';
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the recipient''s web site.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code to be used for the recipient.';
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a code for the shipment method to be used for the recipient.';
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                }
                field("Service Zone Code"; Rec."Service Zone Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the service zone in which the ship-to address is located.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies when the ship-to address was last modified.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer number.';
                    Visible = false;
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
            group("&Address")
            {
                Caption = '&Address';
                Image = Addresses;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
        HandleAddressLookupVisibility();
    end;

    trigger OnAfterGetRecord()
    begin
        IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        if not Customer.Get(GetFilterCustNo()) then
            exit;

        IsHandled := false;
        OnBeforeOnNewRecord(Customer, IsHandled, Rec);
        if IsHandled then
            exit;

        Validate(Name, Customer.Name);
        Validate(Address, Customer.Address);
        Validate("Address 2", Customer."Address 2");
        "Country/Region Code" := Customer."Country/Region Code";
        City := Customer.City;
        County := Customer.County;
        "Post Code" := Customer."Post Code";
        Validate(Contact, Customer.Contact);

        OnAfterOnNewRecord(Customer, Rec);
    end;

    trigger OnOpenPage()
    begin
        IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
    end;

    var
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;
        IsAddressLookupTextEnabled: Boolean;
        LookupAddressLbl: Label 'Lookup address from postcode';

        ShowMapLbl: Label 'Show on Map';

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

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnNewRecord(var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnNewRecord(var Customer: Record Customer; var IsHandled: Boolean; var ShipToAddress: Record "Ship-to Address")
    begin
    end;
}

