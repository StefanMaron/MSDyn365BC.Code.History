table 31093 "Reverse Charge Header"
{
    Caption = 'Reverse Charge Header';
    DataCaptionFields = "No.";
    ObsoleteState = Removed;
    ObsoleteReason = 'The functionality of Reverse Charge Statement will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(5; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            NotBlank = true;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(10; "Period No."; Integer)
        {
            Caption = 'Period No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(11; Year; Integer)
        {
            Caption = 'Year';
            MaxValue = 9999;
            MinValue = 2000;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(15; "Start Date"; Date)
        {
            Caption = 'Start Date';
            Editable = false;
        }
        field(16; "End Date"; Date)
        {
            Caption = 'End Date';
            Editable = false;
        }
        field(20; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(21; "Country/Region Name"; Text[50])
        {
            Caption = 'Country/Region Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(22; County; Text[30])
        {
            Caption = 'County';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(23; Street; Text[50])
        {
            Caption = 'Street';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(24; "House No."; Text[30])
        {
            Caption = 'House No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(25; "Municipality No."; Text[30])
        {
            Caption = 'Municipality No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(26; City; Text[30])
        {
            Caption = 'City';
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
#if not CLEAN18

            trigger OnValidate()
            var
                CountryCode: Code[10];
            begin
                TestField(Status, Status::Open);
                PostCode.ValidateCity(City, "Post Code", County, CountryCode, (CurrFieldNo <> 0) and GuiAllowed);
            end;
#endif
        }
        field(27; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
#if not CLEAN18

            trigger OnValidate()
            var
                CountryCode: Code[10];
            begin
                TestField(Status, Status::Open);
                PostCode.ValidatePostCode(City, "Post Code", County, CountryCode, (CurrFieldNo <> 0) and GuiAllowed);
            end;
#endif
        }
        field(30; "Tax Office No."; Code[20])
        {
            Caption = 'Tax Office No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(31; "Tax Office Region No."; Code[20])
        {
            Caption = 'Tax Office Region No.';
        }
        field(35; "Declaration Period"; Option)
        {
            Caption = 'Declaration Period';
            OptionCaption = 'Month,Quarter';
            OptionMembers = Month,Quarter;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(36; "Declaration Type"; Option)
        {
            Caption = 'Declaration Type';
            OptionCaption = 'Normal,Corrective';
            OptionMembers = Normal,Corrective;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(40; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(50; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(55; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(60; "Natural Employee No."; Code[20])
        {
            Caption = 'Natural Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(61; "Authorized Employee No."; Code[20])
        {
            Caption = 'Authorized Employee No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(65; "Filled by Employee No."; Code[20])
        {
            Caption = 'Filled by Employee No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(80; "Statement Type"; Option)
        {
            Caption = 'Statement Type';
            OptionCaption = 'Vendor,Customer';
            OptionMembers = Vendor,Customer;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(85; "Part Period From"; Date)
        {
            Caption = 'Part Period From';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Start Date");
                TestField("End Date");
                if "Part Period From" <> 0D then
                    if ("Part Period From" < "Start Date") or ("Part Period From" > "End Date") or
                       (("Part Period To" <> 0D) and ("Part Period To" < "Part Period From"))
                    then
                        FieldError("Part Period From");
            end;
        }
        field(86; "Part Period To"; Date)
        {
            Caption = 'Part Period To';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Start Date");
                TestField("End Date");
                if "Part Period To" <> 0D then
                    if ("Part Period To" < "Start Date") or ("Part Period To" > "End Date") or
                       (("Part Period From" <> 0D) and ("Part Period To" < "Part Period From"))
                    then
                        FieldError("Part Period To");
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Start Date", "End Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "VAT Registration No.")
        {
        }
    }
#if not CLEAN18

    trigger OnRename()
    begin
        Error(RenameErr, TableCaption);
    end;

    var
        PostCode: Record "Post Code";
        CompanyInfo: Record "Company Information";
        RenameErr: Label 'You cannot rename a %1.', Comment = '%1=TABLECAPTION';

    [Scope('OnPrem')]
    [Obsolete('The functionality of Reverse Charge Statement will be removed and this function should not be used.', '18.0')]
    procedure InitRecord()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        Country: Record "Country/Region";
    begin
        CompanyInfo.Get();
        StatReportingSetup.Get();

        "Document Date" := WorkDate;

        Country.Get(CompanyInfo."Country/Region Code");
        "Country/Region Name" := Country.Name;
        "VAT Registration No." := CompanyInfo."VAT Registration No.";
        County := CompanyInfo.County;
        City := CompanyInfo.City;
        "Post Code" := CompanyInfo."Post Code";

    end;

#endif
}