table 17368 "HR Order Comment Line"
{
    Caption = 'HR Order Comment Line';

    fields
    {
        field(1; "Table Name"; Option)
        {
            Caption = 'Table Name';
            OptionCaption = 'HR Order,P.HR Order,Absence Order,P.Absence Order,Vacation Request,Vacation Schedule,SL Order,P.SL Order,SL Archive,Payroll Document,P.Payroll Document';
            OptionMembers = "HR Order","P.HR Order","Absence Order","P.Absence Order","Vacation Request","Vacation Schedule","SL Order","P.SL Order","SL Archive","Payroll Document","P.Payroll Document";
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
        }
        field(7; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Line No.", "Document Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

