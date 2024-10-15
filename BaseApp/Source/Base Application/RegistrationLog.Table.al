table 11758 "Registration Log"
{
    Caption = 'Registration Log';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '20.0';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
            NotBlank = true;
        }
        field(3; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Customer,Vendor,Contact';
            OptionMembers = Customer,Vendor,Contact;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const(Contact)) Contact;
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Not Verified,Valid,Invalid';
            OptionMembers = "Not Verified",Valid,Invalid;
        }
        field(11; "Verified Name"; Text[150])
        {
            Caption = 'Verified Name';
        }
        field(12; "Verified Address"; Text[150])
        {
            Caption = 'Verified Address';
        }
        field(13; "Verified City"; Text[150])
        {
            Caption = 'Verified City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(14; "Verified Post Code"; Code[20])
        {
            Caption = 'Verified Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(15; "Verified VAT Registration No."; Text[20])
        {
            Caption = 'Verified VAT Registration No.';
        }
        field(20; "Verified Date"; DateTime)
        {
            Caption = 'Verified Date';
        }
        field(25; "Verified Result"; Text[150])
        {
            Caption = 'Verified Result';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
