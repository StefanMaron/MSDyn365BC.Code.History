table 31122 "EET Cash Register"
{
    Caption = 'EET Cash Register';
    LookupPageID = "EET Cash Registers";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Business Premises Code"; Code[10])
        {
            Caption = 'Business Premises Code';
            NotBlank = true;
            TableRelation = "EET Business Premises";
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(10; "Register Type"; Option)
        {
            Caption = 'Register Type';
            OptionCaption = ' ,Cash Desk';
            OptionMembers = " ","Cash Desk";

            trigger OnValidate()
            begin
                Validate("Register No.", '');
            end;
        }
        field(12; "Register No."; Code[20])
        {
            Caption = 'Register No.';
            TableRelation = IF ("Register Type" = CONST("Cash Desk")) "Bank Account" WHERE("Account Type" = CONST("Cash Desk"));

            trigger OnValidate()
            begin
                if "Register No." = '' then
                    "Register Name" := '';

                if ("Register No." <> xRec."Register No.") and ("Register No." <> '') then begin
                    CheckDuplicateRegister;
                    "Register Name" := GetRegisterName;
                end;
            end;
        }
        field(15; "Register Name"; Text[50])
        {
            Caption = 'Register Name';
        }
        field(17; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
            TableRelation = "Certificate CZ Code";
        }
        field(20; "Receipt Serial Nos."; Code[20])
        {
            Caption = 'Receipt Serial Nos.';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Business Premises Code", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Register Type", "Register No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        EETEntry: Record "EET Entry";
    begin
        EETEntry.SetCurrentKey("Business Premises Code", "Cash Register Code");
        EETEntry.SetRange("Business Premises Code", "Business Premises Code");
        EETEntry.SetRange("Cash Register Code", Code);
        if not EETEntry.IsEmpty then
            Error(EntryExistsErr, TableCaption, Code);
    end;

    var
        EntryExistsErr: Label 'You cannot delete %1 %2 because there is at least one EET entry.', Comment = '%1 = Table Caption;%2 = Primary Key';
        RegisterDuplicatedErr: Label 'Register No. %1 is already defined for EET Cash Register: %2 %3.', Comment = '%1=Register Number, %2=Business Premises Code, %3=Cach Register Code';

    local procedure GetRegisterName(): Text[50]
    var
        BankAccount: Record "Bank Account";
    begin
        case "Register Type" of
            "Register Type"::"Cash Desk":
                begin
                    BankAccount.Get("Register No.");
                    exit(BankAccount.Name);
                end;
        end;
    end;

    [TryFunction]
    local procedure CheckDuplicateRegister()
    var
        EETCashRegister: Record "EET Cash Register";
    begin
        EETCashRegister.SetCurrentKey("Register Type", "Register No.");
        EETCashRegister.SetRange("Register Type", "Register Type");
        EETCashRegister.SetRange("Register No.", "Register No.");
        if EETCashRegister.FindFirst then
            Error(RegisterDuplicatedErr, "Register No.", EETCashRegister."Business Premises Code", EETCashRegister.Code);
    end;
}

