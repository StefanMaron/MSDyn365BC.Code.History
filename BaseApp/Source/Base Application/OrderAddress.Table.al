table 224 "Order Address"
{
    Caption = 'Order Address';
    DataCaptionFields = "Vendor No.", Name, "Code";
    LookupPageID = "Order Address List";

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';

            trigger OnValidate()
            begin
                PostCodeCheck.ValidateAddress(
                  CurrFieldNo, DATABASE::"Order Address", Rec.GetPosition, 0,
                  Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
            end;
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';

            trigger OnValidate()
            begin
                PostCodeCheck.ValidateAddress(
                  CurrFieldNo, DATABASE::"Order Address", Rec.GetPosition, 0,
                  Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
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
            begin
                PostCodeCheck.ValidateCity(
                  CurrFieldNo, DATABASE::"Order Address", Rec.GetPosition, 0,
                  Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
            end;
        }
        field(8; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(10; "Telex No."; Text[30])
        {
            Caption = 'Telex No.';
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(54; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(85; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(91; "Post Code"; Code[20])
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
            begin
                PostCodeCheck.ValidatePostCode(
                  CurrFieldNo, DATABASE::"Order Address", Rec.GetPosition, 0,
                  Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
            end;
        }
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(103; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PostCodeCheck.DeleteAllAddressID(DATABASE::"Order Address", Rec.GetPosition);
    end;

    trigger OnInsert()
    begin
        Vend.Get("Vendor No.");
        Name := Vend.Name;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        "Last Date Modified" := Today;
        PostCodeCheck.MoveAllAddressID(
          DATABASE::"Order Address", xRec.GetPosition, DATABASE::"Order Address", Rec.GetPosition);
    end;

    var
        Text000: Label 'untitled';
        Vend: Record Vendor;
        PostCode: Record "Post Code";
        Text001: Label 'Before you can use Online Map, you must fill in the Online Map Setup window.\See Setting Up Online Map in Help.';
        PostCodeCheck: Codeunit "Post Code Check";

    procedure Caption(): Text
    begin
        if "Vendor No." = '' then
            exit(Text000);
        Vend.Get("Vendor No.");
        exit(StrSubstNo('%1 %2 %3 %4', Vend."No.", Vend.Name, Code, Name));
    end;

    procedure DisplayMap()
    var
        OnlineMapSetup: Record "Online Map Setup";
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapSetup.SetRange(Enabled, true);
        if OnlineMapSetup.FindFirst then
            OnlineMapManagement.MakeSelection(DATABASE::"Order Address", GetPosition)
        else
            Message(Text001);
    end;
}

