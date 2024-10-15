table 11705 "Bank Statement Line"
{
    Caption = 'Bank Statement Line';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '22.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Statement No."; Code[20])
        {
            Caption = 'Bank Statement No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Customer,Vendor,Bank Account';
            OptionMembers = " ",Customer,Vendor,"Bank Account";

            trigger OnValidate()
            begin
                if Type <> xRec.Type then
                    Validate("No.", '');
            end;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Customer)) Customer."No."
            else
            if (Type = const(Vendor)) Vendor."No."
            else
            if (Type = const("Bank Account")) "Bank Account"."No.";

            trigger OnValidate()
            var
                BankAcc: Record "Bank Account";
                Cust: Record Customer;
                Vend: Record Vendor;
            begin
                if "No." <> xRec."No." then
                    Validate("Cust./Vendor Bank Account Code", '');
                case Type of
                    Type::"Bank Account":
                        begin
                            if not BankAcc.Get("No.") then
                                BankAcc.Init();
                            "Account No." := BankAcc."Bank Account No.";
                            Name := BankAcc.Name;
                        end;
                    Type::Customer:
                        begin
                            if not Cust.Get("No.") then
                                Cust.Init();
                            Name := Cust.Name;
                        end;
                    Type::Vendor:
                        begin
                            if not Vend.Get("No.") then
                                Vend.Init();
                            Name := Vend.Name;
                        end;
                end;
            end;
        }
        field(5; "Cust./Vendor Bank Account Code"; Code[20])
        {
            Caption = 'Cust./Vendor Bank Account Code';
            TableRelation = if (Type = const(Customer)) "Customer Bank Account".Code WHERE("Customer No." = field("No."))
            else
            if (Type = const(Vendor)) "Vendor Bank Account".Code WHERE("Vendor No." = field("No."));

            trigger OnValidate()
            var
                VendBankAcc: Record "Vendor Bank Account";
                CustBankAcc: Record "Customer Bank Account";
            begin
                if "Cust./Vendor Bank Account Code" <> xRec."Cust./Vendor Bank Account Code" then
                    case Type of
                        Type::Vendor:
                            begin
                                if not VendBankAcc.Get("No.", "Cust./Vendor Bank Account Code") then
                                    VendBankAcc.Init();
                                "Account No." := VendBankAcc."Bank Account No.";
                            end;
                        Type::Customer:
                            begin
                                if not CustBankAcc.Get("No.", "Cust./Vendor Bank Account Code") then
                                    CustBankAcc.Init();
                                "Account No." := CustBankAcc."Bank Account No.";
                            end
                        else
                            if "Cust./Vendor Bank Account Code" <> '' then
                                FieldError(Type);
                    end;
            end;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Account No."; Text[30])
        {
            Caption = 'Account No.';
        }
        field(8; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
            Numeric = true;
        }
        field(9; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
            CharAllowed = '09';
            Numeric = true;
        }
        field(10; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
            CharAllowed = '09';
            Numeric = true;
        }
        field(11; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(12; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(17; Positive; Boolean)
        {
            Caption = 'Positive';
            Editable = false;
        }
        field(18; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
        }
        field(20; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(25; "Bank Statement Currency Code"; Code[10])
        {
            Caption = 'Bank Statement Currency Code';
            TableRelation = Currency;
        }
        field(26; "Amount (Bank Stat. Currency)"; Decimal)
        {
            AutoFormatExpression = "Bank Statement Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount (Bank Stat. Currency)';
        }
        field(27; "Bank Statement Currency Factor"; Decimal)
        {
            Caption = 'Bank Statement Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
        }
        field(40; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        field(45; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
        }
        field(70; Name; Text[100])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; "Bank Statement No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Statement No.", Positive)
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }
}