table 11740 "Cash Desk User"
{
    Caption = 'Cash Desk User';
    LookupPageID = "Cash Desk Users";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Cash Desk No."; Code[20])
        {
            Caption = 'Cash Desk No.';
            NotBlank = true;
            TableRelation = "Bank Account" WHERE("Account Type" = CONST("Cash Desk"));
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
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
            ObsoleteTag = '18.0';
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

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    procedure GetUserName(UserName: Code[50]): Text[80]
    var
        User: Record User;
    begin
        User.SetCurrentKey("User Name");
        User.SetRange("User Name", UserName);
        if User.FindFirst then
            exit(User."Full Name");
    end;
}

