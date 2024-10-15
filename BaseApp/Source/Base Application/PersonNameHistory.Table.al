table 17351 "Person Name History"
{
    Caption = 'Person Name History';

    fields
    {
        field(1; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            NotBlank = true;
            TableRelation = Person;
        }
        field(2; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(3; "First Name"; Text[30])
        {
            Caption = 'First Name';
        }
        field(4; "Middle Name"; Text[30])
        {
            Caption = 'Middle Name';
        }
        field(5; "Last Name"; Text[30])
        {
            Caption = 'Last Name';
        }
        field(10; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(11; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(12; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(20; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(21; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
    }

    keys
    {
        key(Key1; "Person No.", "Start Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure GetFullName(): Text[100]
    begin
        exit("Last Name" + ' ' + "First Name" + ' ' + "Middle Name");
    end;

    [Scope('OnPrem')]
    procedure GetNameInitials() NameInitials: Text[100]
    begin
        NameInitials := "Last Name";

        if "First Name" <> '' then
            NameInitials := NameInitials + ' ' + CopyStr("First Name", 1, 1) + '.';

        if "Middle Name" <> '' then
            NameInitials := NameInitials + CopyStr("Middle Name", 1, 1) + '.';
    end;
}

