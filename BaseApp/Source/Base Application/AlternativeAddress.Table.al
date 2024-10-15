table 5201 "Alternative Address"
{
    Caption = 'Alternative Address';
    DataCaptionFields = "Employee No.", Name, "Code";
    DrillDownPageID = "Alternative Address List";
    LookupPageID = "Alternative Address List";

    fields
    {
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            NotBlank = true;
            TableRelation = Employee;

            trigger OnValidate()
            begin
                Employee.Get("Employee No.");
                Name := Employee."Last Name";
            end;
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
            var
                Contact: Text[90];
            begin
                PostCodeCheck.ValidateAddress(
                  CurrFieldNo, DATABASE::"Alternative Address", Rec.GetPosition, 0,
                  Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
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
                  CurrFieldNo, DATABASE::"Alternative Address", Rec.GetPosition, 0,
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
            var
                Contact: Text[90];
            begin
                PostCodeCheck.ValidateCity(
                  CurrFieldNo, DATABASE::"Alternative Address", Rec.GetPosition, 0,
                  Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
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
                  CurrFieldNo, DATABASE::"Alternative Address", Rec.GetPosition, 0,
                  Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
            end;
        }
        field(9; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(10; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
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
        field(13; Comment; Boolean)
        {
            CalcFormula = Exist ("Human Resource Comment Line" WHERE("Table Name" = CONST("Alternative Address"),
                                                                     "No." = FIELD("Employee No."),
                                                                     "Alternative Address Code" = FIELD(Code)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
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
        key(Key1; "Employee No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PostCodeCheck.DeleteAllAddressID(DATABASE::"Alternative Address", Rec.GetPosition);
    end;

    trigger OnRename()
    begin
        PostCodeCheck.MoveAllAddressID(
          DATABASE::"Alternative Address", xRec.GetPosition,
          DATABASE::"Alternative Address", Rec.GetPosition);
    end;

    var
        PostCode: Record "Post Code";
        Employee: Record Employee;
        PostCodeCheck: Codeunit "Post Code Check";
}

