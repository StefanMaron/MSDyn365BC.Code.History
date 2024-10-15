table 17424 "Payroll Register"
{
    Caption = 'Payroll Register';
    LookupPageID = "Payroll Registers";

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            TableRelation = "Employee Ledger Entry";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            TableRelation = "Employee Ledger Entry";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Item Journal Batch";
            //This property is currently not supported
            //TestTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Creation Date")
        {
        }
        key(Key3; "Source Code", "Creation Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'Do you want to cancel %1?';
        Text002: Label '%1 canceled successfully.';
        Text003: Label 'You can only cancel entries that were posted from a journal.';
        Text004: Label 'You cannot cancel %1 because the register has already been canceled.';

    [Scope('OnPrem')]
    procedure CancelRegister(PayrollRegNo: Integer)
    var
        PayrollRegister: Record "Payroll Register";
        EmplJnlPostLine: Codeunit "Employee Journal - Post Line";
    begin
        PayrollRegister.Get(PayrollRegNo);

        if (PayrollRegister."From Entry No." = 0) and (PayrollRegister."To Entry No." = 0) then
            Error(Text004, PayrollRegister.TableCaption);

        if PayrollRegister."Journal Batch Name" = '' then
            Error(Text003);

        if not Confirm(Text001, false, PayrollRegister.TableCaption) then
            exit;

        Clear(EmplJnlPostLine);
        EmplJnlPostLine.CancelRegister(PayrollRegister."No.");

        Message(Text002, PayrollRegister.TableCaption);
    end;
}

