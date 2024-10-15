table 11758 "Registration Log"
{
    Caption = 'Registration Log';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

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
            TableRelation = IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Account Type" = CONST(Contact)) Contact;
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
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
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(14; "Verified Post Code"; Code[20])
        {
            Caption = 'Verified Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
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

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure InitRegLog(var RegistrationLog: Record "Registration Log"; AcountType: Option; AccountNo: Code[20]; RegNo: Text[20])
    begin
        RegistrationLog.Init();
        RegistrationLog."Account Type" := AcountType;
        RegistrationLog."Account No." := AccountNo;
        RegistrationLog."Registration No." := RegNo;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure UpdateCard()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        RegistrationLogMgt: Codeunit "Registration Log Mgt.";
        RecordRef: RecordRef;
    begin
        TestField(Status, Status::Valid);

        case "Account Type" of
            "Account Type"::Customer:
                begin
                    Customer.Get("Account No.");
                    RegistrationLogMgt.RunARESUpdate(RecordRef, Customer, Rec);
                end;
            "Account Type"::Vendor:
                begin
                    Vendor.Get("Account No.");
                    RegistrationLogMgt.RunARESUpdate(RecordRef, Vendor, Rec);
                end;
            "Account Type"::Contact:
                begin
                    Contact.Get("Account No.");
                    RegistrationLogMgt.RunARESUpdate(RecordRef, Contact, Rec);
                end;
        end;

        RecordRef.Modify(true);
    end;
}

