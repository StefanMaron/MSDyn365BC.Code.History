table 5051 "Contact Alt. Address"
{
    Caption = 'Contact Alt. Address';
    DataCaptionFields = "Contact No.", "Code", "Company Name";
    LookupPageID = "Contact Alt. Address List";

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
        }
        field(4; "Company Name 2"; Text[50])
        {
            Caption = 'Company Name 2';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';

            trigger OnValidate()
            var
                Contact: Text[90];
            begin
                PostCodeCheck.ValidateAddress(
                  CurrFieldNo, DATABASE::"Contact Alt. Address", Rec.GetPosition, 0,
                  "Company Name", "Company Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
            end;
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';

            trigger OnValidate()
            var
                Contact: Text[90];
            begin
                PostCodeCheck.ValidateAddress(
                  CurrFieldNo, DATABASE::"Contact Alt. Address", Rec.GetPosition, 0,
                  "Company Name", "Company Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
            end;
        }
        field(7; City; Text[30])
        {
            Caption = 'City';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                Contact: Text[90];
            begin
                PostCodeCheck.ValidateCity(
                  CurrFieldNo, DATABASE::"Contact Alt. Address", Rec.GetPosition, 0,
                  "Company Name", "Company Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
            end;
        }
        field(8; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                Contact: Text[90];
            begin
                PostCodeCheck.ValidatePostCode(
                  CurrFieldNo, DATABASE::"Contact Alt. Address", Rec.GetPosition, 0,
                  "Company Name", "Company Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
            end;
        }
        field(9; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(12; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(13; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        field(14; "Extension No."; Text[30])
        {
            Caption = 'Extension No.';
        }
        field(15; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(16; Pager; Text[30])
        {
            Caption = 'Pager';
        }
        field(17; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
                SetSearchEmail();
            end;
        }
        field(18; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(19; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(20; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(21; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
        }
        field(22; "Search E-Mail"; Code[80])
        {
            Caption = 'Search Email';
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Search E-Mail")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Contact: Record Contact;
        ContAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
    begin
        Contact.TouchContact("Contact No.");

        ContAltAddrDateRange.SetRange("Contact No.", "Contact No.");
        ContAltAddrDateRange.SetRange("Contact Alt. Address Code", Code);
        ContAltAddrDateRange.DeleteAll();

        PostCodeCheck.DeleteAllAddressID(DATABASE::"Contact Alt. Address", Rec.GetPosition);
    end;

    trigger OnInsert()
    var
        Contact: Record Contact;
    begin
        SetSearchEmail();
        Contact.TouchContact("Contact No.");
    end;

    trigger OnModify()
    var
        Contact: Record Contact;
    begin
        SetSearchEmail();
        "Last Date Modified" := Today;
        Contact.TouchContact("Contact No.");
    end;

    trigger OnRename()
    var
        Contact: Record Contact;
    begin
        if xRec."Contact No." = "Contact No." then
            Contact.TouchContact("Contact No.")
        else begin
            Contact.TouchContact("Contact No.");
            Contact.TouchContact(xRec."Contact No.");
        end;

        PostCodeCheck.MoveAllAddressID(
          DATABASE::"Contact Alt. Address", xRec.GetPosition,
          DATABASE::"Contact Alt. Address", Rec.GetPosition);
    end;

    var
        PostCode: Record "Post Code";
        PostCodeCheck: Codeunit "Post Code Check";

    local procedure SetSearchEmail()
    begin
        if "Search E-Mail" <> "E-Mail".ToUpper() then
            "Search E-Mail" := "E-Mail";
    end;
}

