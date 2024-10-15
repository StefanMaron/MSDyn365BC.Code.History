table 31066 "VIES Declaration Header"
{
    Caption = 'VIES Declaration Header';
    DataCaptionFields = "No.";
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '20.0';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            NotBlank = true;
        }
        field(3; "Trade Type"; Option)
        {
            Caption = 'Trade Type';
            InitValue = Sales;
            OptionCaption = 'Purchases,Sales,Both';
            OptionMembers = Purchases,Sales,Both;
        }
        field(4; "Period No."; Integer)
        {
            Caption = 'Period No.';
        }
        field(5; Year; Integer)
        {
            Caption = 'Year';
            MaxValue = 9999;
            MinValue = 2000;
        }
        field(6; "Start Date"; Date)
        {
            Caption = 'Start Date';
            Editable = false;
        }
        field(7; "End Date"; Date)
        {
            Caption = 'End Date';
            Editable = false;
        }
        field(8; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(9; "Name 2"; Text[50])
        {
            Caption = 'Name 2';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(10; "Country/Region Name"; Text[50])
        {
            Caption = 'Country/Region Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(11; County; Text[30])
        {
            Caption = 'County';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(12; "Municipality No."; Text[30])
        {
            Caption = 'Municipality No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(13; Street; Text[50])
        {
            Caption = 'Street';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(14; "House No."; Text[30])
        {
            Caption = 'House No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(15; "Apartment No."; Text[30])
        {
            Caption = 'Apartment No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(16; City; Text[30])
        {
            Caption = 'City';
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(17; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(18; "Tax Office Number"; Code[20])
        {
            Caption = 'Tax Office Number';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(19; "Declaration Period"; Option)
        {
            Caption = 'Declaration Period';
            OptionCaption = 'Quarter,Month';
            OptionMembers = Quarter,Month;
            InitValue = Month;
        }
        field(20; "Declaration Type"; Option)
        {
            Caption = 'Declaration Type';
            OptionCaption = 'Normal,Corrective,Corrective-Supplementary';
            OptionMembers = Normal,Corrective,"Corrective-Supplementary";
        }
        field(21; "Corrected Declaration No."; Code[20])
        {
            Caption = 'Corrected Declaration No.';
        }
        field(24; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(25; "Number of Pages"; Integer)
        {
            CalcFormula = Max("VIES Declaration Line"."Report Page Number" WHERE("VIES Declaration No." = FIELD("No.")));
            Caption = 'Number of Pages';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Number of Lines"; Integer)
        {
            CalcFormula = Count("VIES Declaration Line" WHERE("VIES Declaration No." = FIELD("No.")));
            Caption = 'Number of Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; "Sign-off Place"; Text[30])
        {
            Caption = 'Sign-off Place';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(28; "Sign-off Date"; Date)
        {
            Caption = 'Sign-off Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(29; "EU Goods/Services"; Option)
        {
            Caption = 'EU Goods/Services';
            OptionCaption = 'Both,Goods,Services';
            OptionMembers = Both,Goods,Services;
        }
        field(30; "Purchase Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum("VIES Declaration Line"."Amount (LCY)" WHERE("VIES Declaration No." = FIELD("No."),
                                                                            "Trade Type" = CONST(Purchase)));
            Caption = 'Purchase Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Sales Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum("VIES Declaration Line"."Amount (LCY)" WHERE("VIES Declaration No." = FIELD("No."),
                                                                            "Trade Type" = CONST(Sale)));
            Caption = 'Sales Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum("VIES Declaration Line"."Amount (LCY)" WHERE("VIES Declaration No." = FIELD("No.")));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Number of Supplies"; Decimal)
        {
            CalcFormula = Sum("VIES Declaration Line"."Number of Supplies" WHERE("VIES Declaration No." = FIELD("No.")));
            Caption = 'Number of Supplies';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(51; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(70; "Authorized Employee No."; Code[20])
        {
            Caption = 'Authorized Employee No.';
        }
        field(71; "Filled by Employee No."; Code[20])
        {
            Caption = 'Filled by Employee No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(80; "Perform. Country/Region Code"; Code[10])
        {
            Caption = 'Perform. Country/Region Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of VAT Registration in Other Countries has been removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11700; "Natural Person First Name"; Text[30])
        {
            Caption = 'Natural Person First Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(11701; "Natural Person Surname"; Text[30])
        {
            Caption = 'Natural Person Surname';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(11702; "Natural Person Title"; Text[30])
        {
            Caption = 'Natural Person Title';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(11703; "Taxpayer Type"; Option)
        {
            Caption = 'Taxpayer Type';
            OptionCaption = 'Corporation,Individual';
            OptionMembers = Corporation,Individual;
        }
        field(11705; "Natural Employee No."; Code[20])
        {
            Caption = 'Natural Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(11734; "Company Trade Name Appendix"; Text[11])
        {
            Caption = 'Company Trade Name Appendix';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(31060; "Tax Office Region Number"; Code[20])
        {
            Caption = 'Tax Office Region Number';
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
        fieldgroup(DropDown; "EU Goods/Services", "Period No.", Year)
        {
        }
    }

}
