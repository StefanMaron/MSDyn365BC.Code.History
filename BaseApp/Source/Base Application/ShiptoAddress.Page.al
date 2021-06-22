page 300 "Ship-to Address"
{
    Caption = 'Ship-to Address';
    DataCaptionExpression = Caption;
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
                    field("Code"; Code)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies a ship-to address code.';
                    }
                    field(Name; Name)
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
                        ToolTip = 'Specifies the ship-to address.';
                    }
                    field("Address 2"; "Address 2")
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
                    field("Post Code"; "Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Country/Region Code"; "Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the country/region of the address.';

                        trigger OnValidate()
                        begin
                            IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
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
                            DisplayMap;
                        end;
                    }
                }
                field("Phone No."; "Phone No.")
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
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the recipient''s fax number.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    Importance = Additional;
                    ToolTip = 'Specifies the recipient''s email address.';
                }
                field("Home Page"; "Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the recipient''s web site.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code to be used for the recipient.';
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a code for the shipment method to be used for the recipient.';
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                }
                field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                }
                field("Service Zone Code"; "Service Zone Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the service zone in which the ship-to address is located.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies when the ship-to address was last modified.';
                }
                field("Customer No."; "Customer No.")
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
    end;

    trigger OnAfterGetRecord()
    begin
        IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(GetFilterCustNo) then
            exit;

        OnBeforeOnNewRecord(Customer);

        Validate(Name, Customer.Name);
        Validate(Address, Customer.Address);
        Validate("Address 2", Customer."Address 2");
        "Country/Region Code" := Customer."Country/Region Code";
        City := Customer.City;
        County := Customer.County;
        "Post Code" := Customer."Post Code";
        Validate(Contact, Customer.Contact);

        OnAfterOnNewRecord(Customer);
    end;

    trigger OnOpenPage()
    begin
        IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
    end;

    var
        ShowMapLbl: Label 'Show on Map';
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnNewRecord(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnNewRecord(var Customer: Record Customer)
    begin
    end;
}

