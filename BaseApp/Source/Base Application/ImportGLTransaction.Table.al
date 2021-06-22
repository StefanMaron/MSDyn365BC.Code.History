table 1661 "Import G/L Transaction"
{
    Caption = 'Import G/L Transaction';

    fields
    {
        field(1; "App ID"; Guid)
        {
            Caption = 'App ID';
            Editable = false;
        }
        field(2; "External Account"; Code[50])
        {
            Caption = 'External Account';

            trigger OnValidate()
            var
                ImportGLTransaction: Record "Import G/L Transaction";
            begin
                if "External Account" = '' then
                    exit;
                ImportGLTransaction.SetRange("App ID", "App ID");
                ImportGLTransaction.SetRange("External Account", "External Account");
                if ImportGLTransaction.FindFirst then
                    Validate("G/L Account", ImportGLTransaction."G/L Account");
            end;
        }
        field(3; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            TableRelation = "G/L Account" WHERE(Blocked = CONST(false),
                                                 "Direct Posting" = CONST(true),
                                                 "Account Type" = CONST(Posting));
        }
        field(4; "G/L Account Name"; Text[100])
        {
            CalcFormula = Lookup ("G/L Account".Name WHERE("No." = FIELD("G/L Account")));
            Caption = 'G/L Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(10; "Transaction Date"; Date)
        {
            Caption = 'Transaction Date';
        }
        field(12; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "App ID", "Entry No.")
        {
        }
        key(Key2; "App ID", "External Account", "Transaction Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

