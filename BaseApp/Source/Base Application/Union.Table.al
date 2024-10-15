table 5209 Union
{
    Caption = 'Union';
    DrillDownPageID = Unions;
    LookupPageID = Unions;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; Address; Text[100])
        {
            Caption = 'Address';

            trigger OnValidate()
            var
                Contact: Text[90];
            begin
                PostCodeCheck.ValidateAddress(
                  CurrFieldNo, DATABASE::Union, Rec.GetPosition, 0,
                  Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
            end;
        }
        field(4; "Post Code"; Code[20])
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
                  CurrFieldNo, DATABASE::Union, Rec.GetPosition, 0,
                  Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
            end;
        }
        field(5; City; Text[30])
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
                  CurrFieldNo, DATABASE::Union, Rec.GetPosition, 0,
                  Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
            end;
        }
        field(6; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(7; "No. of Members Employed"; Integer)
        {
            CalcFormula = Count (Employee WHERE(Status = FILTER(<> Terminated),
                                                "Union Code" = FIELD(Code)));
            Caption = 'No. of Members Employed';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(9; "Address 2"; Text[50])
        {
            Caption = 'Address 2';

            trigger OnValidate()
            var
                Contact: Text[90];
            begin
                PostCodeCheck.ValidateAddress(
                  CurrFieldNo, DATABASE::Union, Rec.GetPosition, 0,
                  Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
            end;
        }
        field(10; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(11; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(12; "E-Mail"; Text[80])
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
        field(13; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(14; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PostCodeCheck.DeleteAllAddressID(DATABASE::Union, Rec.GetPosition);
    end;

    trigger OnRename()
    begin
        PostCodeCheck.MoveAllAddressID(
          DATABASE::Union, xRec.GetPosition, DATABASE::Union, Rec.GetPosition);
    end;

    var
        PostCode: Record "Post Code";
        PostCodeCheck: Codeunit "Post Code Check";
}

