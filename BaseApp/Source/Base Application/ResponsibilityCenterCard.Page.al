page 5714 "Responsibility Center Card"
{
    Caption = 'Responsibility Center Card';
    PageType = Card;
    SourceTable = "Responsibility Center";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the responsibility center code.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name.';
                }
                field(Address; Address)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the address associated with the responsibility center.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies additional address information.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; City)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the city where the responsibility center is located.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name of the person you regularly contact. ';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location of the responsibility center.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the responsibility center''s phone number.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Location;
                    Importance = Additional;
                    ToolTip = 'Specifies the fax number of the responsibility center.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Location;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the responsibility center.';
                }
                field("Home Page"; "Home Page")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the responsibility center''s web site.';
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                ObsoleteTag = '18.0';
                Visible = false;

                field("Bank Account Code"; "Bank Account Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the bank account code of the company.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Bank Name"; "Bank Name")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name of the bank.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Bank Branch No."; "Bank Branch No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of the bank branch.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Transit No."; "Transit No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the international bank identifier code (SWIFT) of the bank where you have the account.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
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
            group("&Resp. Ctr.")
            {
                Caption = '&Resp. Ctr.';
                Image = Dimensions;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(5714),
                                  "No." = FIELD(Code);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
            }
        }
    }
}

