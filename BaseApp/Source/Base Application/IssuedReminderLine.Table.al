table 298 "Issued Reminder Line"
{
    Caption = 'Issued Reminder Line';

    fields
    {
        field(1; "Reminder No."; Code[20])
        {
            Caption = 'Reminder No.';
            TableRelation = "Issued Reminder Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            TableRelation = "Issued Reminder Line"."Line No." WHERE("Reminder No." = FIELD("Reminder No."));
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Customer Ledger Entry,Line Fee';
            OptionMembers = " ","G/L Account","Customer Ledger Entry","Line Fee";
        }
        field(5; "Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Entry No.';
            TableRelation = "Cust. Ledger Entry";

            trigger OnLookup()
            begin
                if Type <> Type::"Customer Ledger Entry" then
                    exit;
                IssuedReminderHeader.Get("Reminder No.");
                CustLedgEntry.SetCurrentKey("Customer No.");
                CustLedgEntry.SetRange("Customer No.", IssuedReminderHeader."Customer No.");
                if CustLedgEntry.Get("Entry No.") then;
                PAGE.RunModal(0, CustLedgEntry);
            end;
        }
        field(6; "No. of Reminders"; Integer)
        {
            Caption = 'No. of Reminders';
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(8; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(9; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(10; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnLookup()
            begin
                LookupDocNo;
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Original Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Original Amount';
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Remaining Amount';
        }
        field(15; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(" ")) "Standard Text"
            ELSE
            IF (Type = CONST("G/L Account")) "G/L Account"
            ELSE
            IF (Type = CONST("Line Fee")) "G/L Account";
        }
        field(16; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount';
        }
        field(17; "Interest Rate"; Decimal)
        {
            BlankZero = true;
            Caption = 'Interest Rate';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(19; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
        }
        field(20; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
        }
        field(21; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(22; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(23; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(24; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(25; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'Reminder Line,Not Due,Beginning Text,Ending Text,Rounding,On Hold,Additional Fee,Line Fee';
            OptionMembers = "Reminder Line","Not Due","Beginning Text","Ending Text",Rounding,"On Hold","Additional Fee","Line Fee";
        }
        field(26; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(27; "Applies-To Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-To Document Type';
        }
        field(28; "Applies-To Document No."; Code[20])
        {
            Caption = 'Applies-To Document No.';

            trigger OnLookup()
            begin
                if Type <> Type::"Line Fee" then
                    exit;
                IssuedReminderHeader.Get("Reminder No.");
                CustLedgEntry.SetCurrentKey("Customer No.");
                CustLedgEntry.SetRange("Customer No.", IssuedReminderHeader."Customer No.");
                CustLedgEntry.SetRange("Document Type", "Applies-To Document Type");
                CustLedgEntry.SetRange("Document No.", "Applies-To Document No.");
                if CustLedgEntry.FindLast then;
                PAGE.RunModal(0, CustLedgEntry);
            end;
        }
        field(30; "Detailed Interest Rates Entry"; Boolean)
        {
            Caption = 'Detailed Interest Rates Entry';
        }
        field(50; Canceled; Boolean)
        {
            Caption = 'Canceled';
            DataClassification = SystemMetadata;
        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Reminder No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Reminder No.", Type, "Line Type", "Detailed Interest Rates Entry")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
        key(Key3; "Reminder No.", "Detailed Interest Rates Entry")
        {
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
        key(Key4; "Reminder No.", Type)
        {
            SumIndexFields = "VAT Amount";
        }
    }

    fieldgroups
    {
    }

    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        CustLedgEntry: Record "Cust. Ledger Entry";

    procedure GetCurrencyCodeFromHeader(): Code[10]
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        if "Reminder No." = IssuedReminderHeader."No." then
            exit(IssuedReminderHeader."Currency Code");

        if IssuedReminderHeader.Get("Reminder No.") then
            exit(IssuedReminderHeader."Currency Code");

        exit('');
    end;

    procedure LookupDocNo()
    var
        IsHandled: Boolean;
    begin
        OnBeforeLookupDocNo(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type <> Type::"Customer Ledger Entry" then
            exit;
        IssuedReminderHeader.Get("Reminder No.");
        CustLedgEntry.SetCurrentKey("Customer No.");
        CustLedgEntry.SetRange("Customer No.", IssuedReminderHeader."Customer No.");
        if CustLedgEntry.Get("Entry No.") then;
        PAGE.RunModal(0, CustLedgEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocNo(var IssuedReminderLine: Record "Issued Reminder Line"; var IsHandled: Boolean)
    begin
    end;
}

