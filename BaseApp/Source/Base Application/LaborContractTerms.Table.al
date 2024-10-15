table 17362 "Labor Contract Terms"
{
    Caption = 'Labor Contract Terms';

    fields
    {
        field(1; "Labor Contract No."; Code[20])
        {
            Caption = 'Labor Contract No.';
            TableRelation = "Labor Contract";
        }
        field(2; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";

            trigger OnValidate()
            begin
                CheckLaborContractStatus;
                PayrollElement.Get("Element Code");
                Description := CopyStr(PayrollElement.Description, 1, MaxStrLen(Description));
                "Posting Group" := PayrollElement."Payroll Posting Group";
                "Salary Indexation" := PayrollElement."Use Indexation";

                TimeActivity.SetRange("Element Code", "Element Code");
                if TimeActivity.FindFirst then
                    "Time Activity Code" := TimeActivity.Code;
            end;
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                CheckLaborContractStatus;
            end;
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                CheckLaborContractStatus;
            end;
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                CheckLaborContractStatus;
            end;
        }
        field(6; Amount; Decimal)
        {
            Caption = 'Amount';

            trigger OnValidate()
            begin
                CheckLaborContractStatus;
            end;
        }
        field(7; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = "Payroll Posting Group";

            trigger OnValidate()
            begin
                CheckLaborContractStatus;
            end;
        }
        field(8; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                CheckLaborContractStatus;
            end;
        }
        field(9; Percent; Decimal)
        {
            Caption = 'Percent';

            trigger OnValidate()
            begin
                CheckLaborContractStatus;
                if Percent <> 0 then begin
                    LaborContractLine.Reset();
                    LaborContractLine.SetRange("Contract No.", "Labor Contract No.");
                    LaborContractLine.SetRange("Operation Type", "Operation Type");
                    LaborContractLine.SetRange("Supplement No.", "Supplement No.");
                    LaborContractLine.FindFirst;

                    Position.Get(LaborContractLine."Position No.");
                    Position.TestField("Base Salary Element Code");
                    Position.TestField("Base Salary Amount");
                    Amount := Position."Base Salary" * Percent / 100;
                end;
            end;
        }
        field(10; "Time Activity Code"; Code[10])
        {
            Caption = 'Time Activity Code';
            TableRelation = "Time Activity" WHERE("Time Activity Type" = CONST(Vacation),
                                                   "Use Accruals" = FILTER(<> false));

            trigger OnValidate()
            begin
                CheckLaborContractStatus;
                if TimeActivity.Get("Time Activity Code") then
                    if "Element Code" = '' then
                        "Element Code" := TimeActivity."Element Code";
            end;
        }
        field(11; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'Payroll Element,Vacation Accrual';
            OptionMembers = "Payroll Element","Vacation Accrual";

            trigger OnValidate()
            begin
                CheckLaborContractStatus;
            end;
        }
        field(12; "Supplement No."; Code[10])
        {
            Caption = 'Supplement No.';
        }
        field(13; "Operation Type"; Option)
        {
            Caption = 'Operation Type';
            OptionCaption = 'Hire,Transfer,Combination,Dismissal';
            OptionMembers = Hire,Transfer,Combination,Dismissal;
        }
        field(14; Quantity; Decimal)
        {
            Caption = 'Quantity';

            trigger OnValidate()
            begin
                CheckLaborContractStatus;
            end;
        }
        field(15; "Salary Indexation"; Boolean)
        {
            Caption = 'Salary Indexation';
        }
        field(16; "Depends on Salary Element"; Code[20])
        {
            Caption = 'Depends on Salary Element';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Wage));
        }
    }

    keys
    {
        key(Key1; "Labor Contract No.", "Operation Type", "Supplement No.", "Line Type", "Element Code")
        {
            Clustered = true;
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckLaborContractStatus;
    end;

    trigger OnInsert()
    begin
        CheckLaborContractStatus;
    end;

    var
        PayrollElement: Record "Payroll Element";
        TimeActivity: Record "Time Activity";
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
        Position: Record Position;

    [Scope('OnPrem')]
    procedure CheckLaborContractStatus()
    var
        LaborContractLine: Record "Labor Contract Line";
    begin
        LaborContract.Get("Labor Contract No.");
        if LaborContract.Status = LaborContract.Status::Closed then
            LaborContract.FieldError(Status);

        if LaborContractLine.Get("Labor Contract No.", "Operation Type", "Supplement No.") then
            if LaborContractLine.Status = LaborContractLine.Status::Approved then
                if LaborContractLine."Operation Type" <> LaborContractLine."Operation Type"::Combination then
                    LaborContractLine.FieldError(Status);
    end;

    [Scope('OnPrem')]
    procedure CalcVacationCompensation()
    var
        VacationCalculation: Codeunit "Vacation Days Calculation";
    begin
        TestField("Operation Type", "Operation Type"::Dismissal);

        LaborContract.Get("Labor Contract No.");
        Quantity :=
          VacationCalculation.CalculateAllUnusedVacationDays(
            LaborContract."Employee No.", LaborContract."Ending Date");
        Modify;
    end;
}

