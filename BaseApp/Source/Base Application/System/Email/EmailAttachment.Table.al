namespace System.Email;

table 9501 "Email Attachment"
{
    Caption = 'Email Attachment';
    ObsoleteReason = 'We are reverting the fix that was using this table as it was not possible to solve the problem this way.';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Email Item ID"; Guid)
        {
            Caption = 'Email Item ID';
            TableRelation = "Email Item".ID;
        }
        field(2; Number; Integer)
        {
            Caption = 'Number';
        }
        field(10; "File Path"; Text[250])
        {
            Caption = 'File Path';
        }
        field(11; Name; Text[50])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; "Email Item ID", Number)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

