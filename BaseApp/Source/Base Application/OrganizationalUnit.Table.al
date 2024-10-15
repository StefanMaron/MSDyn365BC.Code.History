table 12422 "Organizational Unit"
{
    Caption = 'Organizational Unit';
    DrillDownPageID = "Organizational Units";
    LookupPageID = "Organizational Units";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(3; "Full Name"; Text[250])
        {
            Caption = 'Full Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(5; Totalling; Text[250])
        {
            Caption = 'Totalling';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(6; Level; Integer)
        {
            Caption = 'Level';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(7; "Parent Code"; Code[10])
        {
            Caption = 'Parent Code';
            TableRelation = "Organizational Unit";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                Indent;
            end;
        }
        field(8; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Unit,Heading';
            OptionMembers = Unit,Heading;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                Indent;
            end;
        }
        field(9; Purpose; Option)
        {
            Caption = 'Purpose';
            OptionCaption = ' ,Primary,Supplementary';
            OptionMembers = " ",Primary,Supplementary;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(10; "Manager No."; Code[20])
        {
            Caption = 'Manager No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(12; "Payment Type"; Option)
        {
            Caption = 'Payment Type';
            OptionCaption = 'Time Work,Piece Rate';
            OptionMembers = "Time Work","Piece Rate";
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(14; "Alternative Name"; Text[50])
        {
            Caption = 'Alternative Name';
        }
        field(15; "Address Code"; Code[10])
        {
            Caption = 'Address Code';
            TableRelation = "Company Address";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(16; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Approved,Closed';
            OptionMembers = Open,Approved,Closed;
        }
        field(17; "Isolated Org. Unit"; Boolean)
        {
            Caption = 'Isolated Org. Unit';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(18; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(19; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(21; "Element Type Filter"; Option)
        {
            Caption = 'Element Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Wage,Bonus,Income Tax,Netto Salary,Tax Deduction,Deduction,Other,Funds,Reporting';
            OptionMembers = Wage,Bonus,"Income Tax","Netto Salary","Tax Deduction",Deduction,Other,Funds,Reporting;
        }
        field(22; "Element Code Filter"; Code[20])
        {
            Caption = 'Element Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Payroll Element";
        }
        field(23; "Job Title Code Filter"; Code[10])
        {
            Caption = 'Job Title Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Job Title";
        }
        field(24; "Position Status Filter"; Option)
        {
            Caption = 'Position Status Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Planned,Approved,Closed';
            OptionMembers = Planned,Approved,Closed;
        }
        field(30; "Payroll Amount"; Decimal)
        {
            CalcFormula = Sum ("Payroll Ledger Entry"."Payroll Amount" WHERE("Org. Unit Code" = FIELD(Code),
                                                                             "Org. Unit Code" = FIELD(FILTER(Totalling)),
                                                                             "Element Type" = FIELD("Element Type Filter"),
                                                                             "Element Code" = FIELD("Element Code Filter"),
                                                                             "Posting Date" = FIELD("Date Filter")));
            Caption = 'Payroll Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Taxable Amount"; Decimal)
        {
            CalcFormula = Sum ("Payroll Ledger Entry"."Taxable Amount" WHERE("Org. Unit Code" = FIELD(Code),
                                                                             "Org. Unit Code" = FIELD(FILTER(Totalling)),
                                                                             "Element Type" = FIELD("Element Type Filter"),
                                                                             "Element Code" = FIELD("Element Code Filter"),
                                                                             "Posting Date" = FIELD("Date Filter")));
            Caption = 'Taxable Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(35; Timesheet; Boolean)
        {
            Caption = 'Timesheet';
        }
        field(36; "Timesheet Owner"; Code[20])
        {
            Caption = 'Timesheet Owner';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(40; "Total Position Rate"; Decimal)
        {
            CalcFormula = Sum (Position.Rate WHERE("Org. Unit Code" = FIELD(Code),
                                                   "Org. Unit Code" = FIELD(FILTER(Totalling)),
                                                   "Job Title Code" = FIELD("Job Title Code Filter"),
                                                   Status = FIELD("Position Status Filter"),
                                                   "Starting Date" = FIELD(UPPERLIMIT("Date Filter"))));
            Caption = 'Total Position Rate';
            Editable = false;
            FieldClass = FlowField;
        }
        field(42; "Filled Position Rate"; Decimal)
        {
            CalcFormula = Sum ("Employee Job Entry"."Position Rate" WHERE("Org. Unit Code" = FIELD(Code),
                                                                          "Org. Unit Code" = FIELD(FILTER(Totalling)),
                                                                          "Job Title Code" = FIELD("Job Title Code Filter"),
                                                                          "Starting Date" = FIELD(UPPERLIMIT("Date Filter"))));
            Caption = 'Filled Position Rate';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Approved by User"; Code[50])
        {
            Caption = 'Approved by User';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(51; "Approval Date"; Date)
        {
            Caption = 'Approval Date';
            Editable = false;
        }
        field(52; "Created by User"; Code[50])
        {
            Caption = 'Created by User';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(53; "Created Date"; Date)
        {
            Caption = 'Created Date';
            Editable = false;
        }
        field(54; "Closed by User"; Code[50])
        {
            Caption = 'Closed by User';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(55; "Closed Date"; Date)
        {
            Caption = 'Closed Date';
            Editable = false;
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
        fieldgroup(DropDown; "Code", Name)
        {
        }
    }

    trigger OnDelete()
    begin
        TestField(Status, Status::Open);

        case Type of
            Type::Heading:
                begin
                    OrganizationalUnit.SetRange("Parent Code", Code);
                    if not OrganizationalUnit.IsEmpty then
                        Error('');
                end;
            Type::Unit:
                begin
                    CalcFields("Total Position Rate");
                    TestField("Total Position Rate", 0);
                end;
        end;
    end;

    trigger OnInsert()
    begin
        "Created by User" := UserId;
        "Created Date" := Today;
    end;

    var
        HumanResSetup: Record "Human Resources Setup";
        OrganizationalUnit: Record "Organizational Unit";
        Position: Record Position;
        Text14700: Label 'Organizational Unit %1 cannot be reopened because it already used in positions.';
        Text14701: Label 'Organizational Unit %1 cannot be closed because there are approved positions with this code.';

    [Scope('OnPrem')]
    procedure Indent()
    begin
        Level := 0;
        if "Parent Code" <> '' then begin
            OrganizationalUnit.Reset;
            OrganizationalUnit.SetRange(Code, "Parent Code");
            if OrganizationalUnit.FindFirst then
                Level := OrganizationalUnit.Level + 1
            else
                if Type > 0 then
                    Level := Type - 1
        end;
    end;

    [Scope('OnPrem')]
    procedure Approve(IsChangeOrder: Boolean)
    begin
        if not IsChangeOrder then begin
            HumanResSetup.Get;
            HumanResSetup.TestField("Use Staff List Change Orders", false);
        end;

        TestField(Code);
        TestField(Name);
        TestField("Starting Date");
        TestField(Status, Status::Open);
        TestField(Blocked, false);

        "Approved by User" := UserId;
        "Approval Date" := Today;
        Status := Status::Approved;
        Modify;
    end;

    [Scope('OnPrem')]
    procedure Reopen(IsChangeOrder: Boolean)
    begin
        TestField(Status, Status::Approved);

        if not IsChangeOrder then begin
            HumanResSetup.Get;
            HumanResSetup.TestField("Use Staff List Change Orders", false);

            Position.Reset;
            Position.SetRange("Org. Unit Code", Code);
            if not Position.IsEmpty then
                Error(Text14700, Code);
        end;

        Status := Status::Open;
        Modify;
    end;

    [Scope('OnPrem')]
    procedure Close(IsChangeOrder: Boolean)
    begin
        TestField(Status, Status::Approved);

        if not IsChangeOrder then begin
            HumanResSetup.Get;
            HumanResSetup.TestField("Use Staff List Change Orders", false);

            Position.Reset;
            Position.SetRange("Org. Unit Code", Code);
            Position.SetFilter(Status, '<>%1', Position.Status::Closed);
            if not Position.IsEmpty then
                Error(Text14701, Code);
        end;

        Status := Status::Closed;
        "Closed by User" := UserId;
        "Closed Date" := Today;
        Modify;
    end;
}

