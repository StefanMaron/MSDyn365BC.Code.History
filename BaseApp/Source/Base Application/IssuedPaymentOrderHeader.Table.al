table 11710 "Issued Payment Order Header"
{
    Caption = 'Issued Payment Order Header';
    DataCaptionFields = "No.", "Bank Account No.", "Bank Account Name";
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(3; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            Editable = true;
            NotBlank = true;
            TableRelation = "Bank Account";
        }
        field(4; "Bank Account Name"; Text[100])
        {
            CalcFormula = Lookup("Bank Account".Name WHERE("No." = FIELD("Bank Account No.")));
            Caption = 'Bank Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Account No."; Text[30])
        {
            Caption = 'Account No.';
        }
        field(6; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(8; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
        }
        field(9; Amount; Decimal)
        {
            CalcFormula = Sum("Issued Payment Order Line".Amount WHERE("Payment Order No." = FIELD("No."),
                                                                        Status = CONST(" ")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum("Issued Payment Order Line"."Amount (LCY)" WHERE("Payment Order No." = FIELD("No."),
                                                                                Status = CONST(" ")));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; Debit; Decimal)
        {
            CalcFormula = Sum("Issued Payment Order Line".Amount WHERE("Payment Order No." = FIELD("No."),
                                                                        Positive = CONST(true),
                                                                        Status = CONST(" ")));
            Caption = 'Debit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Debit (LCY)"; Decimal)
        {
            CalcFormula = Sum("Issued Payment Order Line"."Amount (LCY)" WHERE("Payment Order No." = FIELD("No."),
                                                                                Positive = CONST(true),
                                                                                Status = CONST(" ")));
            Caption = 'Debit (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Credit; Decimal)
        {
            CalcFormula = - Sum("Issued Payment Order Line".Amount WHERE("Payment Order No." = FIELD("No."),
                                                                         Positive = CONST(false),
                                                                         Status = CONST(" ")));
            Caption = 'Credit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Credit (LCY)"; Decimal)
        {
            CalcFormula = - Sum("Issued Payment Order Line"."Amount (LCY)" WHERE("Payment Order No." = FIELD("No."),
                                                                                 Positive = CONST(false),
                                                                                 Status = CONST(" ")));
            Caption = 'Credit (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "No. of Lines"; Integer)
        {
            CalcFormula = Count("Issued Payment Order Line" WHERE("Payment Order No." = FIELD("No.")));
            Caption = 'No. of Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(17; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(20; "Payment Order Currency Code"; Code[10])
        {
            Caption = 'Payment Order Currency Code';
            TableRelation = Currency;
        }
        field(21; "Payment Order Currency Factor"; Decimal)
        {
            Caption = 'Payment Order Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
        }
        field(25; "Pre-Assigned No. Series"; Code[20])
        {
            Caption = 'Pre-Assigned No. Series';
            TableRelation = "No. Series";
        }
        field(26; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
        }
        field(30; "Pre-Assigned User ID"; Code[50])
        {
            Caption = 'Pre-Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(35; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(50; "No. exported"; Integer)
        {
            Caption = 'No. exported';
            Editable = false;
        }
        field(55; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(60; "Foreign Payment Order"; Boolean)
        {
            Caption = 'Foreign Payment Order';
        }
        field(90; IBAN; Code[50])
        {
            Caption = 'IBAN';
        }
        field(95; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
        }
        field(100; "Uncertainty Pay.Check DateTime"; DateTime)
        {
            Caption = 'Uncertainty Pay.Check DateTime';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}