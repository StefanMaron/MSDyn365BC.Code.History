table 11741 "Cash Desk Event"
{
    Caption = 'Cash Desk Event';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '20.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Cash Desk No."; Code[20])
        {
            Caption = 'Cash Desk No.';
        }
        field(5; "Cash Document Type"; Option)
        {
            Caption = 'Cash Document Type';
            OptionCaption = ' ,Receipt,Withdrawal';
            OptionMembers = " ",Receipt,Withdrawal;

            trigger OnValidate()
            begin
                "Document Type" := "Document Type"::" ";

                if (("Account Type" = "Account Type"::Vendor) and ("Cash Document Type" = "Cash Document Type"::Withdrawal)) or
                   (("Account Type" = "Account Type"::Customer) and ("Cash Document Type" = "Cash Document Type"::Receipt))
                then
                    "Document Type" := "Document Type"::Payment;
                if (("Account Type" = "Account Type"::Customer) and ("Cash Document Type" = "Cash Document Type"::Withdrawal)) or
                   (("Account Type" = "Account Type"::Vendor) and ("Cash Document Type" = "Cash Document Type"::Receipt))
                then
                    "Document Type" := "Document Type"::Refund;
            end;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = ' ,G/L Account,Customer,Vendor,Bank Account,Fixed Asset,Employee';
            OptionMembers = " ","G/L Account",Customer,Vendor,"Bank Account","Fixed Asset",Employee;

            trigger OnValidate()
            begin
                if "Account Type" <> xRec."Account Type" then begin
                    Validate("Cash Document Type");
                    Validate("Account No.", '');
                    Validate("Gen. Posting Type", "Gen. Posting Type"::" ");
                    Validate("VAT Bus. Posting Group", '');
                    Validate("VAT Prod. Posting Group", '');
                end;
            end;
        }
        field(12; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const(" ")) "Standard Text"
            else
            if ("Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const(Employee)) Employee
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            var
                StdTxt: Record "Standard Text";
                GLAcc: Record "G/L Account";
                Employee: Record Employee;
            begin
                if ("Account No." <> xRec."Account No.") and ("Account No." <> '') then
                    case "Account Type" of
                        "Account Type"::" ":
                            begin
                                StdTxt.Get("Account No.");
                                Description := StdTxt.Description;
                            end;
                        "Account Type"::"G/L Account":
                            begin
                                GLAcc.Get("Account No.");
                                Description := GLAcc.Name;
                                "Gen. Posting Type" := GLAcc."Gen. Posting Type";
                                "VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
                                "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
                            end;
                        "Account Type"::Customer:
                            begin
                                Customer.Get("Account No.");
                                Description := Customer.Name;
                                "Gen. Posting Type" := "Gen. Posting Type"::" ";
                                "VAT Bus. Posting Group" := '';
                                "VAT Prod. Posting Group" := '';
                            end;
                        "Account Type"::Vendor:
                            begin
                                Vendor.Get("Account No.");
                                Vendor.CheckBlockedVendOnJnls(Vendor, "Document Type", false);
                                Description := Vendor.Name;
                                "Gen. Posting Type" := "Gen. Posting Type"::" ";
                                "VAT Bus. Posting Group" := '';
                                "VAT Prod. Posting Group" := '';
                            end;
                        "Account Type"::"Fixed Asset":
                            begin
                                FA.Get("Account No.");
                                Description := FA.Description;
                                "Gen. Posting Type" := "Gen. Posting Type"::" ";
                                "VAT Bus. Posting Group" := '';
                                "VAT Prod. Posting Group" := '';
                            end;
                        "Account Type"::"Bank Account":
                            begin
                                BankAccount.Get("Account No.");
                                Description := BankAccount.Name;
                                "Gen. Posting Type" := "Gen. Posting Type"::" ";
                                "VAT Bus. Posting Group" := '';
                                "VAT Prod. Posting Group" := '';
                            end;
                        "Account Type"::Employee:
                            begin
                                Employee.Get("Account No.");
                                Description := CopyStr(Employee.FullName(), 1, MaxStrLen(Description));
                                "Gen. Posting Type" := "Gen. Posting Type"::" ";
                                "VAT Bus. Posting Group" := '';
                                "VAT Prod. Posting Group" := '';
                            end;
                    end;
            end;
        }
        field(14; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(29; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(30; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(72; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(117; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(31125; "EET Transaction"; Boolean)
        {
            Caption = 'EET Transaction';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
            ObsoleteTag = '21.0';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        FA: Record "Fixed Asset";
        BankAccount: Record "Bank Account";

}