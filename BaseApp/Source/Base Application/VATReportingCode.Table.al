table 344 "VAT Reporting Code"
{
    Caption = 'VAT Reporting Code';
    LookupPageID = "VAT Reporting Codes";

    fields
    {
        field(1; Code; Code[20])
        {
        }
        field(2; Description; Text[250])
        {
        }
        field(10600; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;
        }
        field(10601; "Test Gen. Posting Type"; Option)
        {
            Caption = 'Test Gen. Posting Type';
            OptionCaption = ' ,Mandatory,Same';
            OptionMembers = " ",Mandatory,Same;
        }
        field(10610; "Trade Settlement 2017 Box No."; Option)
        {
            OptionCaption = ' ,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19';
            OptionMembers = " ","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19";
        }
        field(10611; "Reverse Charge Report Box No."; Option)
        {
            OptionCaption = ' ,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19';
            OptionMembers = " ","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19";
        }
        field(10620; "VAT Specification Code"; Code[50])
        {
            TableRelation = "VAT Specification".Code;
        }
        field(10621; "VAT Note Code"; Code[50])
        {
            TableRelation = "VAT Note".Code;
        }
        field(10622; "SAF-T VAT Code"; Code[20])
        {
            Caption = 'SAF-T Code';
            TableRelation = "VAT Reporting Code".Code;
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description)
        {
        }
    }
}
