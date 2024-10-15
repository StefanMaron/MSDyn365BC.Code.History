table 10602 "VAT Code"
{
    Caption = 'VAT Code';
    LookupPageID = "VAT Codes";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;
        }
        field(3; "Test Gen. Posting Type"; Option)
        {
            Caption = 'Test Gen. Posting Type';
            OptionCaption = ' ,Mandatory,Same';
            OptionMembers = " ",Mandatory,Same;
        }
        field(4; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(5; "Trade Settlement 2017 Box No."; Option)
        {
            Caption = 'Trade Settlement 2017 Box No.';
            OptionCaption = ' ,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19';
            OptionMembers = " ","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19";
        }
        field(6; "Reverse Charge Report Box No."; Option)
        {
            Caption = 'Reverse Charge Report Box No.';
            OptionCaption = ' ,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19';
            OptionMembers = " ","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19";
        }
        field(7; "VAT % For Reporting"; Decimal)
        {
            Caption = 'VAT Rate For Reporting';
#if not CLEAN18
            ObsoleteState = Pending;
            ObsoleteTag = '20.0';
            ObsoleteReason = 'Moved to extension';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
            ObsoleteReason = 'Moved to extension';
#endif
        }
        field(8; "Report VAT %"; Boolean)
        {
            Caption = 'Report VAT Rate';
#if not CLEAN18
            ObsoleteState = Pending;
            ObsoleteTag = '20.0';
            ObsoleteReason = 'Moved to extension';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
            ObsoleteReason = 'Moved to extension';
#endif
        }
        field(10620; "SAFT Compensation"; Boolean)
        {
            Caption = 'Compensation';
            ObsoleteReason = 'Moved to extension';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
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
        fieldgroup(DropDown; "Code", Description, "Gen. Posting Type")
        {
        }
    }
}

