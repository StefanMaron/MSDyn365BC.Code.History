table 5201 "Alternative Address"
{
    Caption = 'Alternative Address';
    DataCaptionFields = "Person No.", Name, "Code";
    DrillDownPageID = "Alternative Address List";
    LookupPageID = "Alternative Address List";

    fields
    {
        field(1; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            NotBlank = true;
            TableRelation = Person;
            //This property is currently not supported
            //TestTableRelation = false;

            trigger OnValidate()
            begin
                Person.Get("Person No.");
                Name := Person.GetFullName;
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
            begin
                TestField("KLADR Address", false);
            end;
        }
        field(6; "Address 2"; Text[100])
        {
            Caption = 'Address 2';

            trigger OnValidate()
            begin
                TestField("KLADR Address", false);
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
                if "KLADR Address" then begin
                    if Street = '' then
                        "KLADR Code" := KLADRAddr.GetParentCode("KLADR Code", 3);
                    UpdateValues("KLADR Code");
                    ValidateKLADRAddress;
                end else
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
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
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; County; Text[50])
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
                                                                     "No." = FIELD("Person No."),
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
            var
                CountryRegion: Record "Country/Region";
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
                if CountryRegion.Get("Country/Region Code") then
                    if CountryRegion."Local Country/Region Code" = '' then begin
                        CountryRegion."Local Country/Region Code" := "Country/Region Code";
                        CountryRegion.Modify();
                    end;
            end;
        }
        field(17400; "City Category"; Text[10])
        {
            Caption = 'City Category';
            TableRelation = "KLADR Category".Code WHERE(Level = CONST(3));
        }
        field(17401; Locality; Text[50])
        {
            Caption = 'Locality';

            trigger OnValidate()
            begin
                if "KLADR Address" then begin
                    if Street = '' then
                        "KLADR Code" := KLADRAddr.GetParentCode("KLADR Code", 4);
                    UpdateValues("KLADR Code");
                end;

                if "KLADR Address" then
                    ValidateKLADRAddress;
            end;
        }
        field(17402; "Locality Category"; Text[10])
        {
            Caption = 'Locality Category';
            TableRelation = "KLADR Category".Code WHERE(Level = CONST(4));
        }
        field(17403; "Region Code"; Code[2])
        {
            Caption = 'Region Code';
            CharAllowed = '09';
            TableRelation = "KLADR Region";
        }
        field(17404; "Region Category"; Text[10])
        {
            Caption = 'Region Category';
            TableRelation = "KLADR Category".Code WHERE(Level = CONST(1));
        }
        field(17405; Street; Text[50])
        {
            Caption = 'Street';

            trigger OnValidate()
            begin
                if "KLADR Address" then begin
                    if Street = '' then
                        "KLADR Code" := KLADRAddr.GetParentCode("KLADR Code", 5);
                    UpdateValues("KLADR Code");
                end;

                Address := GetStreetAddress;
                if "KLADR Address" then
                    ValidateKLADRAddress;
            end;
        }
        field(17406; "Street Category"; Text[10])
        {
            Caption = 'Street Category';
            TableRelation = "KLADR Category".Code WHERE(Level = CONST(5));
        }
        field(17407; House; Text[10])
        {
            Caption = 'House';

            trigger OnValidate()
            begin
                Address := GetStreetAddress;
                if "KLADR Address" then
                    ValidateKLADRAddress;
            end;
        }
        field(17408; Building; Text[10])
        {
            Caption = 'Building';

            trigger OnValidate()
            begin
                Address := GetStreetAddress;
                if "KLADR Address" then
                    ValidateKLADRAddress;
            end;
        }
        field(17409; Apartment; Text[10])
        {
            Caption = 'Apartment';

            trigger OnValidate()
            begin
                Address := GetStreetAddress;
                if "KLADR Address" then
                    ValidateKLADRAddress;
            end;
        }
        field(17410; "Address Format"; Option)
        {
            Caption = 'Address Format';
            OptionCaption = 'Post Code+City,,,,Post Code+Region+Area+City+Settlement,Post Code+Region+City,Post Code+Region';
            OptionMembers = "Post Code+City",,,,"Post Code+Region+Area+City+Settlement","Post Code+Region+City","Post Code+Region";
        }
        field(17411; "KLADR Code"; Code[19])
        {
            Caption = 'KLADR Code';
        }
        field(17412; "Address Type"; Option)
        {
            Caption = 'Address Type';
            OptionCaption = 'Permanent,Registration,Birthplace,Other';
            OptionMembers = Permanent,Registration,Birthplace,Other;

            trigger OnValidate()
            begin
                if "Address Type" = "Address Type"::Birthplace then begin
                    AltAddr.SetRange("Person No.", "Person No.");
                    AltAddr.SetRange("Address Type", AltAddr."Address Type"::Birthplace);
                    if AltAddr.FindFirst then
                        Error(Text14700);
                end;
            end;
        }
        field(17413; "Tax Inspection Code"; Code[4])
        {
            Caption = 'Tax Inspection Code';
        }
        field(17415; "Area"; Text[50])
        {
            Caption = 'Area';

            trigger OnValidate()
            begin
                if "KLADR Address" then begin
                    if Street = '' then
                        "KLADR Code" := KLADRAddr.GetParentCode("KLADR Code", 2);
                    UpdateValues("KLADR Code");
                end;

                if "KLADR Address" then
                    ValidateKLADRAddress;
            end;
        }
        field(17416; "Area Category"; Text[10])
        {
            Caption = 'Area Category';
            TableRelation = "KLADR Category".Code WHERE(Level = CONST(2));
        }
        field(17417; "Post Code Zone"; Text[50])
        {
            Caption = 'Post Code Zone';

            trigger OnValidate()
            begin
                if "KLADR Address" then begin
                    if Street = '' then
                        "KLADR Code" := KLADRAddr.GetParentCode("KLADR Code", 6);
                    UpdateValues("KLADR Code");
                end;

                if "KLADR Address" then
                    ValidateKLADRAddress;
            end;
        }
        field(17418; Region; Text[50])
        {
            Caption = 'Region';

            trigger OnValidate()
            begin
                if "KLADR Address" then begin
                    if Street = '' then
                        "KLADR Code" := KLADRAddr.GetParentCode("KLADR Code", 1);
                    UpdateValues("KLADR Code");
                end;

                if "KLADR Address" then
                    ValidateKLADRAddress;
            end;
        }
        field(17419; "KLADR Address"; Boolean)
        {
            Caption = 'KLADR Address';
        }
        field(17422; OKATO; Code[20])
        {
            Caption = 'OKATO';
        }
        field(17423; "Valid from Date"; Date)
        {
            Caption = 'Valid from Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                AltAddr.Reset();
                AltAddr.SetCurrentKey("Person No.", "Address Type", "Valid from Date");
                AltAddr.SetRange("Person No.", "Person No.");
                AltAddr.SetRange("Address Type", "Address Type");
                AltAddr.SetRange("Valid from Date", "Valid from Date");
                if AltAddr.FindFirst then
                    Error(Text14701, AltAddr."Address Type", AltAddr."Valid from Date");
            end;
        }
    }

    keys
    {
        key(Key1; "Person No.", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Person No.", "Address Type", "Valid from Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if "Address Type" <> "Address Type"::Birthplace then
            TestField("Valid from Date");

        UpdateEmployesAddressFields("Person No.");
    end;

    trigger OnModify()
    begin
        if "Address Type" <> "Address Type"::Birthplace then
            TestField("Valid from Date");

        UpdateEmployesAddressFields("Person No.");
    end;

    var
        PostCode: Record "Post Code";
        Person: Record Person;
        Text_House: Label 'h. ';
        Text_Appt: Label 'fl.';
        Text_Building: Label 'build. ';
        Text_Comma: Label ', ';
        Category: Record "KLADR Category";
        AltAddr: Record "Alternative Address";
        KLADRAddr: Record "KLADR Address";
        Text14700: Label 'Birth place address already exists.';
        Text14701: Label 'Address with type %1 valid from %2 already exists.';

    [Scope('OnPrem')]
    procedure GetAddress() Result: Text[1024]
    var
        i: Integer;
    begin
        Result := '';
        for i := 1 to 5 do
            AddLevel(Result, GetName(i), GetCategory(i), i, true);
        if (House <> '') and (Building <> '') then
            AddStr(Result, StrSubstNo('%1%2%3%4%5', Text_House, House, Text_Comma, Text_Building, Building), true)
        else
            if (House <> '') and (Building = '') then
                AddStr(Result, StrSubstNo('%1%2', Text_House, House), false)
            else
                if (House = '') and (Building <> '') then
                    AddStr(Result, StrSubstNo('%1%2', Text_Building, Building), false);
        if Apartment <> '' then
            AddStr(Result, StrSubstNo('%1 %2', Text_Appt, Apartment), false);
    end;

    [Scope('OnPrem')]
    procedure GetStreetAddress() Result: Text[1024]
    begin
        Result := '';
        AddLevel(Result, GetName(5), GetCategory(5), 5, true);
        if (House <> '') and (Building <> '') then
            AddStr(Result, StrSubstNo('%1%2%3%4%5', Text_House, House, Text_Comma, Text_Building, Building), true)
        else
            if (House <> '') and (Building = '') then
                AddStr(Result, StrSubstNo('%1%2', Text_House, House), false)
            else
                if (House = '') and (Building <> '') then
                    AddStr(Result, StrSubstNo('%1%2', Text_Building, Building), false);
        if Apartment <> '' then
            AddStr(Result, StrSubstNo('%1 %2', Text_Appt, Apartment), false);
    end;

    local procedure AddStr(var Str: Text[1024]; Str1: Text[1024]; ForTax: Boolean)
    begin
        if ForTax then
            Str := Str + ',' + Str1
        else
            if Str1 <> '' then
                if Str <> '' then
                    Str := Str + ', ' + Str1
                else
                    Str := Str1;
    end;

    local procedure AddLevel(var Str: Text[1024]; Name: Text[40]; CategoryCode: Text[10]; Level: Integer; UseCatSetting: Boolean)
    begin
        if Name = '' then
            exit;

        AddStr(Str, Category.GetTextWithCategory(CategoryCode, Level, Name, false, UseCatSetting), false);
    end;

    [Scope('OnPrem')]
    procedure GetAddressPart(AddressType: Option; EmployeeNo: Code[20]; ShowCategory: Boolean; FromLevel: Integer; Full: Boolean): Text[250]
    begin
        AltAddr.Reset();
        AltAddr.SetCurrentKey("Person No.", "Address Type");
        AltAddr.SetRange("Person No.", EmployeeNo);
        AltAddr.SetRange("Address Type", AddressType);
        if AltAddr.FindFirst then begin
            if ShowCategory then
                exit(
                  Category.GetTextWithCategory(
                    AltAddr.GetCategory(FromLevel), FromLevel, AltAddr.GetName(FromLevel), Full, false));

            exit(AltAddr.GetName(FromLevel));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetName(FromLevel: Integer): Text[40]
    begin
        case FromLevel of
            1:
                exit(Region);
            2:
                exit(Area);
            3:
                exit(City);
            4:
                exit(Locality);
            5:
                exit(Street);
            6:
                exit("Post Code Zone");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCategory(FromLevel: Integer): Text[10]
    begin
        case FromLevel of
            1:
                exit("Region Category");
            2:
                exit("Area Category");
            3:
                exit("City Category");
            4:
                exit("Locality Category");
            5:
                exit("Street Category");
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateKLADRAddress()
    var
        AddressTax: Text[250];
    begin
        AddStr(AddressTax, "Post Code", true);
        AddStr(AddressTax, Region, true);
        AddStr(AddressTax, Area, true);
        AddStr(AddressTax, City, true);
        AddStr(AddressTax, Locality, true);
        AddStr(AddressTax, Street, true);
        AddStr(AddressTax, House, true);
        AddStr(AddressTax, Building, true);
        AddStr(AddressTax, Apartment, true);
        "Address 2" := UpperCase(AddressTax);
    end;

    [Scope('OnPrem')]
    procedure SetValues(ToLevel: Integer; Name: Text[50]; CategoryCode: Text[10])
    begin
        case ToLevel of
            1:
                begin
                    Region := Name;
                    "Region Category" := CategoryCode;
                end;
            2:
                begin
                    Area := Name;
                    "Area Category" := CategoryCode;
                end;
            3:
                begin
                    City := Name;
                    "City Category" := CategoryCode;
                end;
            4:
                begin
                    Locality := Name;
                    "Locality Category" := CategoryCode;
                end;
            5:
                begin
                    Street := Name;
                    "Street Category" := CategoryCode;
                end;
            6:
                "Post Code Zone" := Name;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateValues(AddrCode: Code[19])
    var
        KLADRAddr: Record "KLADR Address";
        CurrCode: Code[19];
        CurrLevel: Integer;
        i: Integer;
    begin
        CurrCode := AddrCode;
        for i := 1 to 6 do
            SetValues(i, '', '');

        "Post Code" := '';
        "Tax Inspection Code" := '';
        while KLADRAddr.Get(CurrCode) do begin
            if "Post Code" = '' then
                "Post Code" := KLADRAddr.Index;
            if "Tax Inspection Code" = '' then
                "Tax Inspection Code" := KLADRAddr.GNINMB;
            CurrLevel := KLADRAddr.GetLevel(KLADRAddr.Code);
            SetValues(CurrLevel, KLADRAddr.Name, KLADRAddr."Category Code");
            CurrCode := KLADRAddr.Parent;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateEmployesAddressFields(PersonNo: Code[20])
    var
        Employee: Record Employee;
        AltAddr: Record "Alternative Address";
        RegistrationAddressExists: Boolean;
    begin
        RegistrationAddressExists := GetLastRegistrationAddr(AltAddr, PersonNo);
        if "Address Type" = "Address Type"::Registration then begin
            if RegistrationAddressExists and (AltAddr."Valid from Date" > "Valid from Date") then
                exit;
        end else
            if RegistrationAddressExists or ("Address Type" <> "Address Type"::Permanent) then
                exit;

        Employee.SetRange("Person No.", PersonNo);
        if Employee.FindSet then
            repeat
                Employee.Address := CopyStr(Address, 1, 50);
                Employee.City := City;
                Employee."Post Code" := "Post Code";
                Employee."Country/Region Code" := "Country/Region Code";

                Employee.Modify();
            until Employee.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetLastRegistrationAddr(var AltAddr: Record "Alternative Address"; PersonNo: Code[20]): Boolean
    begin
        AltAddr.SetCurrentKey("Person No.", "Address Type", "Valid from Date");
        AltAddr.SetRange("Person No.", PersonNo);
        AltAddr.SetRange("Address Type", "Address Type"::Registration);

        if AltAddr.FindLast then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetFullAddress(IncludePostCode: Boolean) FullAddress: Text[1024]
    begin
        if "Person No." = '' then
            exit('');

        if IncludePostCode then
            FullAddress := "Post Code" + ', ';

        case "Address Format" of
            "Address Format"::"Post Code+City":
                FullAddress :=
                  FullAddress +
                  "City Category" + '. ' + City + ', ';

            "Address Format"::"Post Code+Region+Area+City+Settlement":
                FullAddress :=
                  FullAddress +
                  "Region Category" + '. ' + Region + ', ' +
                  "Area Category" + '. ' + Area + ', ' +
                  "City Category" + '. ' + City + ', ' +
                  "Locality Category" + '. ' + Locality + ', ';

            "Address Format"::"Post Code+Region+City":
                FullAddress :=
                  FullAddress +
                  "Region Category" + '. ' + Region + ', ' +
                  "City Category" + '. ' + City + ', ';

            "Address Format"::"Post Code+Region":
                FullAddress :=
                  FullAddress +
                  "Region Category" + '. ' + Region + ', ';
        end;

        FullAddress := FullAddress + Address;
    end;
}

