table 10524 "GovTalk Message Parts"
{
    Caption = 'GovTalk Message Parts';

    fields
    {
        field(1; "Part Id"; Guid)
        {
            Caption = 'Part Id';
        }
        field(2; "Report No."; Code[20])
        {
            Caption = 'Report No.';
            TableRelation = "VAT Report Header"."No.";
        }
        field(3; "VAT Report Config. Code"; Option)
        {
            Caption = 'VAT Report Config. Code';
            Editable = true;
            OptionCaption = 'EC Sales List,VAT Report';
            OptionMembers = "EC Sales List","VAT Report";
            TableRelation = "VAT Reports Configuration"."VAT Report Type";
        }
        field(4; "Correlation Id"; Text[250])
        {
            Caption = 'Correlation Id';
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = ' ,Released,Submitted,Accepted,Rejected';
            OptionMembers = " ",Released,Submitted,Accepted,Rejected;
        }
    }

    keys
    {
        key(Key1; "Part Id")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

