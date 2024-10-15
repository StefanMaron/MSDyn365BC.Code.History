table 17365 "Labor Contract Terms Setup"
{
    Caption = 'Labor Contract Terms Setup';

    fields
    {
        field(1; "Table Type"; Option)
        {
            Caption = 'Table Type';
            OptionCaption = 'Position,Person';
            OptionMembers = Position,Person;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF ("Table Type" = CONST(Position)) Position
            ELSE
            IF ("Table Type" = CONST(Person)) Person;
        }
        field(6; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";

            trigger OnValidate()
            begin
                if "Table Type" = "Table Type"::Position then
                    if Position.Get("No.") then begin
                        Position.TestField("Base Salary Element Code");
                        if "Element Code" = Position."Base Salary Element Code" then
                            Error(Text14700, "Element Code", TableCaption);
                    end;
            end;
        }
        field(7; "Operation Type"; Option)
        {
            Caption = 'Operation Type';
            OptionCaption = 'All,Hire,Transfer,Combination,Dismissal';
            OptionMembers = All,Hire,Transfer,Combination,Dismissal;
        }
        field(8; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Payroll Element,Vacation Accrual';
            OptionMembers = "Payroll Element","Vacation Accrual";
        }
        field(9; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(12; "Additional Salary"; Boolean)
        {
            Caption = 'Additional Salary';
        }
        field(15; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(16; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(17; Percent; Decimal)
        {
            Caption = 'Percent';

            trigger OnValidate()
            begin
                if ("Table Type" = "Table Type"::Position) and (Percent <> 0) then begin
                    Position.Get("No.");
                    Position.TestField("Base Salary Element Code");
                    Position.TestField("Base Salary Amount");
                    Amount := Position."Base Salary" * Percent / 100;
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Table Type", "No.", "Element Code", "Operation Type", "Start Date", "End Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckPositionStatus;
    end;

    trigger OnInsert()
    begin
        CheckPositionStatus;
    end;

    trigger OnModify()
    begin
        CheckPositionStatus;
    end;

    var
        Position: Record Position;
        Text14700: Label 'You should not enter %1 in %2.';

    [Scope('OnPrem')]
    procedure CheckPositionStatus()
    var
        Position: Record Position;
    begin
        if "Table Type" = "Table Type"::Position then
            if Position.Get("No.") then
                if (Position.Status = Position.Status::Closed) or (Position.Status = Position.Status::Approved) then
                    Position.FieldError(Status);
    end;
}

