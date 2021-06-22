table 5223 "Detailed Employee Ledger Entry"
{
    Caption = 'Detailed Employee Ledger Entry';
    Permissions = TableData "Detailed Employee Ledger Entry" = m;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Employee Ledger Entry No."; Integer)
        {
            Caption = 'Employee Ledger Entry No.';
            TableRelation = "Employee Ledger Entry";
        }
        field(3; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = ',Initial Entry,Application';
            OptionMembers = ,"Initial Entry",Application;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(8; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(9; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(12; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(13; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(14; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(15; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(16; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
        }
        field(17; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
        }
        field(18; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount (LCY)';
        }
        field(19; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount (LCY)';
        }
        field(21; "Initial Entry Global Dim. 1"; Code[20])
        {
            Caption = 'Initial Entry Global Dim. 1';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(22; "Initial Entry Global Dim. 2"; Code[20])
        {
            Caption = 'Initial Entry Global Dim. 2';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(35; "Initial Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Initial Document Type';
        }
        field(36; "Applied Empl. Ledger Entry No."; Integer)
        {
            Caption = 'Applied Empl. Ledger Entry No.';
        }
        field(37; Unapplied; Boolean)
        {
            Caption = 'Unapplied';
        }
        field(38; "Unapplied by Entry No."; Integer)
        {
            Caption = 'Unapplied by Entry No.';
            TableRelation = "Detailed Vendor Ledg. Entry";
        }
        field(42; "Application No."; Integer)
        {
            Caption = 'Application No.';
            Editable = false;
        }
        field(43; "Ledger Entry Amount"; Boolean)
        {
            Caption = 'Ledger Entry Amount';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Employee Ledger Entry No.", "Posting Date")
        {
        }
        key(Key3; "Transaction No.", "Employee No.", "Entry Type")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        SetLedgerEntryAmount;
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure UpdateDebitCredit(Correction: Boolean)
    begin
        if ((Amount > 0) or ("Amount (LCY)" > 0)) and not Correction or
           ((Amount < 0) or ("Amount (LCY)" < 0)) and Correction
        then begin
            "Debit Amount" := Amount;
            "Credit Amount" := 0;
            "Debit Amount (LCY)" := "Amount (LCY)";
            "Credit Amount (LCY)" := 0;
        end else begin
            "Debit Amount" := 0;
            "Credit Amount" := -Amount;
            "Debit Amount (LCY)" := 0;
            "Credit Amount (LCY)" := -"Amount (LCY)";
        end;
    end;

    procedure SetZeroTransNo(TransactionNo: Integer)
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        ApplicationNo: Integer;
    begin
        DtldEmplLedgEntry.SetCurrentKey("Transaction No.");
        DtldEmplLedgEntry.SetRange("Transaction No.", TransactionNo);
        if DtldEmplLedgEntry.FindSet(true) then begin
            ApplicationNo := DtldEmplLedgEntry."Entry No.";
            repeat
                DtldEmplLedgEntry."Transaction No." := 0;
                DtldEmplLedgEntry."Application No." := ApplicationNo;
                DtldEmplLedgEntry.Modify();
            until DtldEmplLedgEntry.Next = 0;
        end;
    end;

    local procedure SetLedgerEntryAmount()
    begin
        "Ledger Entry Amount" := not ("Entry Type" = "Entry Type"::Application);
    end;
}

