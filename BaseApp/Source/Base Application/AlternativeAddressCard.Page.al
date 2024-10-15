page 5203 "Alternative Address Card"
{
    Caption = 'Alternative Address Card';
    DataCaptionExpression = Caption;
    DelayedInsert = true;
    PageType = Card;
    SourceTable = "Alternative Address";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the employee''s alternate address.';
                }
                field("Valid from Date"; "Valid from Date")
                {
                }
                field("KLADR Address"; "KLADR Address")
                {
                    ToolTip = 'Specifies if the address is based on the Russian KLADR address database. ';

                    trigger OnValidate()
                    begin
                        UpdateFields;
                    end;
                }
                field("Address Type"; "Address Type")
                {
                    ToolTip = 'Specifies what the address applies to.';
                }
                field("Address Format"; "Address Format")
                {
                    ToolTip = 'Specifies the format of the address that is displayed on external-facing documents. You link an address format to a country/region code so that external-facing documents based on cards or documents with that country/region code use the specified address format. NOTE: If the County field is filled in, then the county will be printed above the country/region unless you select the City/County/Post Code option.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s last name.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("Region Code"; "Region Code")
                {
                }
                field("Region Category"; "Region Category")
                {
                    Editable = "Region CategoryEditable";
                }
                field(Region; Region)
                {

                    trigger OnAssistEdit()
                    begin
                        if "KLADR Address" then begin
                            KLADRMgt.LookupAddress(Rec, 1);
                            if xRec.Region <> Region then begin
                                UpdateValues("KLADR Code");
                            end;
                        end;
                    end;
                }
                field("Area Category"; "Area Category")
                {
                    Editable = "Area CategoryEditable";
                }
                field("Area"; Area)
                {
                    ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';

                    trigger OnAssistEdit()
                    begin
                        if "KLADR Address" then begin
                            KLADRMgt.LookupAddress(Rec, 2);
                            if xRec.Area <> Area then begin
                                UpdateValues("KLADR Code");
                            end;
                        end;
                    end;
                }
                field("City Category"; "City Category")
                {
                    Editable = "City CategoryEditable";
                }
                field(City; City)
                {
                    Lookup = false;
                    ToolTip = 'Specifies the city of the address.';

                    trigger OnAssistEdit()
                    begin
                        if "KLADR Address" then begin
                            KLADRMgt.LookupAddress(Rec, 3);
                            if xRec.City <> City then begin
                                UpdateValues("KLADR Code");
                            end;
                        end;
                    end;
                }
                field("Locality Category"; "Locality Category")
                {
                    Editable = "Locality CategoryEditable";
                }
                field(Locality; Locality)
                {

                    trigger OnAssistEdit()
                    begin
                        if "KLADR Address" then begin
                            KLADRMgt.LookupAddress(Rec, 4);
                            if xRec.Locality <> Locality then begin
                                UpdateValues("KLADR Code");
                            end;
                        end;
                    end;
                }
                field("Street Category"; "Street Category")
                {
                    Editable = "Street CategoryEditable";
                }
                field(Street; Street)
                {

                    trigger OnAssistEdit()
                    begin
                        if "KLADR Address" then begin
                            KLADRMgt.LookupAddress(Rec, 5);
                            if xRec.Street <> Street then
                                UpdateValues("KLADR Code");
                        end;
                    end;
                }
                group(Control5)
                {
                    ShowCaption = false;
                    Visible = IsCountyVisible;
                    field(County; County)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Post CodeEditable";
                    ToolTip = 'Specifies the postal code.';
                }
                field("Post Code Zone"; "Post Code Zone")
                {
                    Visible = "Post Code ZoneVisible";

                    trigger OnAssistEdit()
                    var
                        KLADRAddr: Record "KLADR Address";
                    begin
                        if "KLADR Address" then begin
                            KLADRMgt.LookupAddress(Rec, 6);
                            if xRec.Locality <> Locality then begin
                                UpdateValues("KLADR Code");
                            end;
                        end;
                    end;
                }
                field(House; House)
                {
                }
                field(Building; Building)
                {
                }
                field(Apartment; Apartment)
                {
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate address for the employee.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'KLADR Address';
                    ToolTip = 'Specifies additional address information.';
                }
                field("Tax Inspection Code"; "Tax Inspection Code")
                {
                    Editable = "Tax Inspection CodeEditable";
                }
                field(OKATO; OKATO)
                {
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No.2"; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s telephone number at the alternate address.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s fax number at the alternate address.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the employee''s alternate email address.';
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
                Visible = true;
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
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Human Resource Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Alternative Address"),
                                  "No." = FIELD("Person No."),
                                  "Alternative Address Code" = FIELD(Code);
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
    }

    trigger OnInit()
    begin
        "Tax Inspection CodeEditable" := true;
        "Post CodeEditable" := true;
        "Street CategoryEditable" := true;
        "Locality CategoryEditable" := true;
        "City CategoryEditable" := true;
        "Area CategoryEditable" := true;
        "Region CategoryEditable" := true;
        "Post Code ZoneVisible" := true;
    end;

    trigger OnOpenPage()
    begin
        IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
    end;

    var
        Text000: Label 'untitled';
        Person: Record Person;
        Mail: Codeunit Mail;
        KLADRMgt: Codeunit "KLADR Management";
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;
        MissingPostCode: Boolean;
        [InDataSet]
        "Post Code ZoneVisible": Boolean;
        [InDataSet]
        "Region CategoryEditable": Boolean;
        [InDataSet]
        "Area CategoryEditable": Boolean;
        [InDataSet]
        "City CategoryEditable": Boolean;
        [InDataSet]
        "Locality CategoryEditable": Boolean;
        [InDataSet]
        "Street CategoryEditable": Boolean;
        [InDataSet]
        "Post CodeEditable": Boolean;
        [InDataSet]
        "Tax Inspection CodeEditable": Boolean;

    [Scope('OnPrem')]
    procedure UpdateFields()
    begin
        "Post Code ZoneVisible" := "KLADR Address";
        "Region CategoryEditable" := not "KLADR Address";
        "Area CategoryEditable" := not "KLADR Address";
        "City CategoryEditable" := not "KLADR Address";
        "Locality CategoryEditable" := not "KLADR Address";
        "Street CategoryEditable" := not "KLADR Address";
        "Post CodeEditable" := not "KLADR Address";
        "Tax Inspection CodeEditable" := not "KLADR Address";
    end;

    procedure Caption(): Text
    begin
        if Person.Get("Person No.") then
            exit("Person No." + ' ' + Person.GetFullName + ' ' + Code);

        exit(Text000);
    end;
}

