table 12178 "Issued Customer Bill Line"
{
    Caption = 'Issued Customer Bill Line';

    fields
    {
        field(1; "Customer Bill No."; Code[20])
        {
            Caption = 'Customer Bill No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(11; "Customer Name"; Text[100])
        {
            CalcFormula = Lookup (Customer.Name WHERE("No." = FIELD("Customer No.")));
            Caption = 'Customer Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Customer Bank Acc. No."; Code[20])
        {
            Caption = 'Customer Bank Acc. No.';
            TableRelation = "Customer Bank Account".Code WHERE("Customer No." = FIELD("Customer No."));
        }
        field(15; "Temporary Cust. Bill No."; Code[20])
        {
            Caption = 'Temporary Cust. Bill No.';
        }
        field(16; "Final Cust. Bill No."; Code[20])
        {
            Caption = 'Final Cust. Bill No.';
        }
        field(20; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(21; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = IF ("Document Type" = CONST(Invoice)) "Sales Invoice Header"
            ELSE
            IF ("Document Type" = CONST("Credit Memo")) "Sales Cr.Memo Header"
            ELSE
            IF ("Document Type" = CONST("Finance Charge Memo")) "Finance Charge Memo Header"
            ELSE
            IF ("Document Type" = CONST(Reminder)) "Reminder Header";
        }
        field(22; "Document Occurrence"; Integer)
        {
            Caption = 'Document Occurrence';
        }
        field(23; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(28; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(30; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(35; "Cumulative Bank Receipts"; Boolean)
        {
            Caption = 'Cumulative Bank Receipts';
        }
        field(40; "Recalled by"; Code[50])
        {
            Caption = 'Recalled by';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(41; "Recall Date"; Date)
        {
            Caption = 'Recall Date';
        }
        field(45; "Customer Entry No."; Integer)
        {
            Caption = 'Customer Entry No.';
            TableRelation = "Cust. Ledger Entry";
        }
        field(12000; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" WHERE("Customer No." = FIELD("Customer No."));
        }
    }

    keys
    {
        key(Key1; "Customer Bill No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount;
        }
        key(Key2; "Customer Entry No.")
        {
        }
        key(Key3; "Customer No.", "Due Date", "Customer Bank Acc. No.", "Cumulative Bank Receipts")
        {
        }
        key(Key4; "Customer Bill No.", "Final Cust. Bill No.")
        {
        }
    }

    fieldgroups
    {
    }
}

