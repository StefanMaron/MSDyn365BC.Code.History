table 11704 "Bank Statement Header"
{
    Caption = 'Bank Statement Header';
    DataCaptionFields = "No.", "Bank Account No.", "Bank Account Name";
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    DataClassification = CustomerContent;

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
            TableRelation = "Bank Account";
        }
        field(4; "Bank Account Name"; Text[100])
        {
            CalcFormula = lookup("Bank Account".Name where("No." = field("Bank Account No.")));
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
            CalcFormula = sum("Bank Statement Line".Amount where("Bank Statement No." = field("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Amount (LCY)"; Decimal)
        {
            CalcFormula = sum("Bank Statement Line"."Amount (LCY)" where("Bank Statement No." = field("No.")));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; Debit; Decimal)
        {
            CalcFormula = - sum("Bank Statement Line".Amount where("Bank Statement No." = field("No."),
                                                                   Positive = const(false)));
            Caption = 'Debit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Debit (LCY)"; Decimal)
        {
            CalcFormula = - sum("Bank Statement Line"."Amount (LCY)" where("Bank Statement No." = field("No."),
                                                                           Positive = const(false)));
            Caption = 'Debit (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Credit; Decimal)
        {
            CalcFormula = sum("Bank Statement Line".Amount where("Bank Statement No." = field("No."),
                                                                  Positive = const(true)));
            Caption = 'Credit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Credit (LCY)"; Decimal)
        {
            CalcFormula = sum("Bank Statement Line"."Amount (LCY)" where("Bank Statement No." = field("No."),
                                                                          Positive = const(true)));
            Caption = 'Credit (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "No. of Lines"; Integer)
        {
            CalcFormula = count("Bank Statement Line" where("Bank Statement No." = field("No.")));
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
            ValidateTableRelation = false;
        }
        field(20; "Bank Statement Currency Code"; Code[10])
        {
            Caption = 'Bank Statement Currency Code';
            TableRelation = Currency;
        }
        field(21; "Bank Statement Currency Factor"; Decimal)
        {
            Caption = 'Bank Statement Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
        }
        field(30; "Last Issuing No."; Code[20])
        {
            Caption = 'Last Issuing No.';
            Editable = false;
            TableRelation = "Sales Invoice Header";
        }
        field(35; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(55; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(60; "Check Amount"; Decimal)
        {
            Caption = 'Check Amount';
            Editable = false;
        }
        field(65; "Check Amount (LCY)"; Decimal)
        {
            Caption = 'Check Amount (LCY)';
            Editable = false;
        }
        field(70; "Check Debit"; Decimal)
        {
            Caption = 'Check Debit';
            Editable = false;
        }
        field(75; "Check Debit (LCY)"; Decimal)
        {
            Caption = 'Check Debit (LCY)';
            Editable = false;
        }
        field(80; "Check Credit"; Decimal)
        {
            Caption = 'Check Credit';
            Editable = false;
        }
        field(85; "Check Credit (LCY)"; Decimal)
        {
            Caption = 'Check Credit (LCY)';
            Editable = false;
        }
        field(90; IBAN; Code[50])
        {
            Caption = 'IBAN';
        }
        field(95; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
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
