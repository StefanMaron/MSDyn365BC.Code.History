table 11740 "Cash Desk User"
{
    Caption = 'Cash Desk User';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '20.0';

    fields
    {
        field(1; "Cash Desk No."; Code[20])
        {
            Caption = 'Cash Desk No.';
            NotBlank = true;
        }
        field(2; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(10; Create; Boolean)
        {
            Caption = 'Create';
        }
        field(11; Issue; Boolean)
        {
            Caption = 'Issue';
        }
        field(12; Post; Boolean)
        {
            Caption = 'Post';
        }
        field(22; "User Name"; Text[80])
        {
            Caption = 'User Name';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(31120; "Post EET Only"; Boolean)
        {
            Caption = 'Post EET Only';
        }
    }

    keys
    {
        key(Key1; "Cash Desk No.", "User ID")
        {
            Clustered = true;
        }
        key(Key2; "User ID", "Cash Desk No.")
        {
        }
    }

    fieldgroups
    {
    }
}
