table 31067 "VIES Declaration Line"
{
    Caption = 'VIES Declaration Line';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '20.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VIES Declaration No."; Code[20])
        {
            Caption = 'VIES Declaration No.';
        }
        field(2; "Trade Type"; Option)
        {
            Caption = 'Trade Type';
            OptionCaption = 'Purchase,Sale, ';
            OptionMembers = Purchase,Sale," ";
            InitValue = " ";
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(7; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'New,Cancellation,Correction';
            OptionMembers = New,Cancellation,Correction;
        }
        field(8; "Related Line No."; Integer)
        {
            Caption = 'Related Line No.';
        }
        field(9; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(12; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            DecimalPlaces = 0 : 0;
        }
        field(13; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
        }
        field(14; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
        }
        field(15; "EU 3-Party Intermediate Role"; Boolean)
        {
            Caption = 'EU 3-Party Intermediate Role';
        }
        field(17; "Number of Supplies"; Decimal)
        {
            BlankNumbers = DontBlank;
            Caption = 'Number of Supplies';
            DecimalPlaces = 0 : 0;
        }
        field(20; "Corrected Reg. No."; Boolean)
        {
            Caption = 'Corrected Reg. No.';
            Editable = false;
        }
        field(21; "Corrected Amount"; Boolean)
        {
            Caption = 'Corrected Amount';
            Editable = false;
        }
        field(25; "Trade Role Type"; Option)
        {
            Caption = 'Trade Role Type';
            OptionCaption = 'Direct Trade,Intermediate Trade,Property Movement, ';
            OptionMembers = "Direct Trade","Intermediate Trade","Property Movement"," ";
            InitValue = " ";
        }
        field(29; "System-Created"; Boolean)
        {
            Caption = 'System-Created';
            Editable = false;
        }
        field(30; "Report Page Number"; Integer)
        {
            Caption = 'Report Page Number';
        }
        field(31; "Report Line Number"; Integer)
        {
            Caption = 'Report Line Number';
        }
        field(35; "Record Code"; Option)
        {
            Caption = 'Record Code';
            OptionCaption = ' ,1,2,3';
            OptionMembers = " ","1","2","3";

            trigger OnValidate()
            begin
                if "Record Code" = xRec."Record Code" then
                    exit;

                TestField("Trade Type", "Trade Type"::" ");
                TestField("Trade Role Type", "Trade Role Type"::" ");
                TestField("Number of Supplies", 0);
                TestField("Amount (LCY)", 0);
                "VAT Reg. No. of Original Cust." := '';
            end;
        }
        field(36; "VAT Reg. No. of Original Cust."; Text[20])
        {
            Caption = 'VAT Reg. No. of Original Cust.';

            trigger OnValidate()
            begin
                TestField("Record Code", "Record Code"::"3");
            end;
        }
    }

    keys
    {
        key(Key1; "VIES Declaration No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "Amount (LCY)", "Number of Supplies";
        }
        key(Key2; "Trade Type", "Country/Region Code", "VAT Registration No.", "Trade Role Type", "EU Service")
        {
            SumIndexFields = "Amount (LCY)";
        }
        key(Key3; "VAT Registration No.")
        {
            SumIndexFields = "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

}
