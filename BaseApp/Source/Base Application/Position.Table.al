table 17370 Position
{
    Caption = 'Position';
    DrillDownPageID = "Position List";
    LookupPageID = "Position List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    HumanResSetup.Get();
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                end;
            end;
        }
        field(2; "Job Title Code"; Code[10])
        {
            Caption = 'Job Title Code';
            TableRelation = "Job Title";

            trigger OnValidate()
            begin
                CheckModify;
                if JobTitle.Get("Job Title Code") then begin
                    JobTitle.TestField(Type, JobTitle.Type::"Job Title");
                    JobTitle.TestField(Blocked, false);
                    "Job Title Name" := JobTitle.Name;
                    if "Budgeted Position No." <> '' then begin
                        Position2.Get("Budgeted Position No.");
                        TestField("Job Title Code", Position2."Job Title Code");
                    end;
                    "Base Salary Element Code" := JobTitle."Base Salary Element Code";
                    Validate("Base Salary", JobTitle."Base Salary Amount");
                    Validate("Category Code", JobTitle."Category Code");
                    Validate("Calendar Code", JobTitle."Calendar Code");
                    Validate("Worktime Norm", JobTitle."Worktime Norm");
                    Validate("Kind of Work", JobTitle."Kind of Work");
                    Validate("Conditions of Work", JobTitle."Conditions of Work");
                    Validate("Calc Group Code", JobTitle."Calc Group Code");
                    Validate("Posting Group", JobTitle."Posting Group");
                    Validate("Statistical Group Code", JobTitle."Statistics Group Code");
                    CopyContractTerms;
                    Calculate;
                end;
            end;
        }
        field(3; "Job Title Name"; Text[50])
        {
            Caption = 'Job Title Name';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(4; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            TableRelation = "Organizational Unit";

            trigger OnValidate()
            begin
                CheckModify;
                HumanResSetup.Get();
                if "Org. Unit Code" = '' then
                    "Org. Unit Name" := ''
                else begin
                    OrganizationalUnit.Get("Org. Unit Code");
                    OrganizationalUnit.TestField(Type, OrganizationalUnit.Type::Unit);
                    if not HumanResSetup."Use Staff List Change Orders" then
                        OrganizationalUnit.TestField(Status, OrganizationalUnit.Status::Approved);
                    OrganizationalUnit.TestField(Blocked, false);
                    "Org. Unit Name" := OrganizationalUnit.Name;
                    if ("Starting Date" <> 0D) and (OrganizationalUnit."Starting Date" > "Starting Date") then
                        Error(Text002,
                          OrganizationalUnit.TableCaption, OrganizationalUnit.FieldCaption("Starting Date"),
                          TableCaption, FieldCaption("Starting Date"));
                    if ("Ending Date" <> 0D) and (OrganizationalUnit."Ending Date" <> 0D) and
                       (OrganizationalUnit."Ending Date" < "Ending Date")
                    then
                        Error(Text002,
                          TableCaption, FieldCaption("Starting Date"),
                          OrganizationalUnit.TableCaption, OrganizationalUnit.FieldCaption("Starting Date"));
                    if "Budgeted Position No." <> '' then begin
                        Position2.Get("Budgeted Position No.");
                        TestField("Job Title Code", Position2."Job Title Code");
                    end;
                    CopyContractTerms;
                end;
            end;
        }
        field(5; "Org. Unit Name"; Text[50])
        {
            Caption = 'Org. Unit Name';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(7; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Planned,Approved,Closed';
            OptionMembers = Planned,Approved,Closed;
        }
        field(8; "Parent Position No."; Code[20])
        {
            Caption = 'Parent Position No.';
            TableRelation = Position;

            trigger OnValidate()
            begin

                if "Parent Position No." <> '' then begin
                    if "No." = "Parent Position No." then
                        FieldError("Parent Position No.");
                    Position.Get("Parent Position No.");
                    Level := Position.Level + 1;
                    if "Org. Unit Code" = '' then
                        Validate("Org. Unit Code", Position."Org. Unit Code");
                end else
                    Level := 0;
            end;
        }
        field(9; "Filled Rate"; Decimal)
        {
            CalcFormula = Sum ("Employee Job Entry"."Position Rate" WHERE("Position No." = FIELD("No."),
                                                                          "Starting Date" = FIELD("Date Filter")));
            Caption = 'Filled Rate';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; Rate; Decimal)
        {
            Caption = 'Rate';
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckModify;
                if not "Budgeted Position" then
                    if Rate > 1 then
                        Error(Text003, FieldCaption(Rate), 1);

                Calculate;
            end;
        }
        field(11; "Base Salary"; Decimal)
        {
            Caption = 'Base Salary';

            trigger OnValidate()
            begin
                CheckModify;
                Calculate;
            end;
        }
        field(12; "Additional Salary"; Decimal)
        {
            Caption = 'Additional Salary';

            trigger OnValidate()
            begin
                CheckModify;
                Calculate;
            end;
        }
        field(13; "Budgeted Salary"; Decimal)
        {
            Caption = 'Budgeted Salary';

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(14; "Monthly Salary"; Decimal)
        {
            Caption = 'Monthly Salary';
            Editable = false;
        }
        field(15; Note; Text[250])
        {
            Caption = 'Note';
        }
        field(16; "Approval Date"; Date)
        {
            Caption = 'Approval Date';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(17; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                CheckModify;
                if OrganizationalUnit.Get("Org. Unit Code") then
                    if ("Starting Date" <> 0D) and (OrganizationalUnit."Starting Date" > "Starting Date") then
                        Error(Text002,
                          OrganizationalUnit.TableCaption, OrganizationalUnit.FieldCaption("Starting Date"),
                          TableCaption, FieldCaption("Starting Date"));
            end;
        }
        field(18; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                CheckModify;
                if OrganizationalUnit.Get("Org. Unit Code") then
                    if ("Ending Date" <> 0D) and (OrganizationalUnit."Ending Date" <> 0D) and
                       (OrganizationalUnit."Ending Date" < "Ending Date")
                    then
                        Error(Text002,
                          TableCaption, FieldCaption("Ending Date"),
                          OrganizationalUnit.TableCaption, OrganizationalUnit.FieldCaption("Ending Date"));
            end;
        }
        field(19; "Base Salary Element Code"; Code[20])
        {
            Caption = 'Base Salary Element Code';
            TableRelation = "Payroll Element";

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(20; "Category Code"; Code[10])
        {
            Caption = 'Category Code';
            TableRelation = "Employee Category";

            trigger OnValidate()
            begin
                CheckModify;
                CopyContractTerms;
                Calculate;
            end;
        }
        field(21; "Opening Reason"; Text[250])
        {
            Caption = 'Opening Reason';

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(22; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            TableRelation = "Payroll Calendar";

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(23; "Statistical Group Code"; Code[10])
        {
            Caption = 'Statistical Group Code';
            TableRelation = "Employee Statistics Group";

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(24; "Worktime Norm"; Code[10])
        {
            Caption = 'Worktime Norm';
            TableRelation = "Worktime Norm";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(25; "Use Trial Period"; Boolean)
        {
            Caption = 'Use Trial Period';

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(26; "Trial Period Description"; Text[50])
        {
            Caption = 'Trial Period Description';

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(27; "Liability for Breakage"; Option)
        {
            Caption = 'Liability for Breakage';
            OptionCaption = 'None,Team,Personal';
            OptionMembers = "None",Team,Personal;

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(28; "Hire Conditions"; Code[20])
        {
            Caption = 'Hire Conditions';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Hire Condition"));

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(29; Level; Integer)
        {
            Caption = 'Level';

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(30; "Kind of Work"; Option)
        {
            Caption = 'Kind of Work';
            OptionCaption = ' ,Permanent,Temporary,Seasonal';
            OptionMembers = " ",Permanent,"Temporary",Seasonal;

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(31; "Out-of-Staff"; Boolean)
        {
            Caption = 'Out-of-Staff';

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(32; "Conditions of Work"; Option)
        {
            Caption = 'Conditions of Work';
            OptionCaption = ' ,Regular,Heavy,Unhealthy,Very Heavy,Other';
            OptionMembers = " ",Regular,Heavy,Unhealthy,"Very Heavy",Other;

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(33; "Calc Group Code"; Code[10])
        {
            Caption = 'Calc Group Code';
            TableRelation = "Payroll Calc Group";

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(34; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = "Payroll Posting Group";

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(35; "Created By User"; Code[50])
        {
            Caption = 'Created By User';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(36; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(37; "Approved By User"; Code[50])
        {
            Caption = 'Approved By User';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(38; "Closed By User"; Code[50])
        {
            Caption = 'Closed By User';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(39; "Closing Date"; Date)
        {
            Caption = 'Closing Date';
            Editable = false;
        }
        field(40; "Organization Size"; Integer)
        {
            CalcFormula = Count (Position WHERE("Parent Position No." = FIELD("No.")));
            Caption = 'Organization Size';
            Editable = false;
            FieldClass = FlowField;
        }
        field(41; "Trial Period Formula"; DateFormula)
        {
            Caption = 'Trial Period Formula';

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(42; "Reopened Date"; Date)
        {
            Caption = 'Reopened Date';
        }
        field(43; "Reopened by User"; Code[50])
        {
            Caption = 'Reopened by User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(45; "Allow Overdraft"; Boolean)
        {
            Caption = 'Allow Overdraft';
        }
        field(50; "Budgeted Position"; Boolean)
        {
            Caption = 'Budgeted Position';

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(51; "Budgeted Position No."; Code[20])
        {
            Caption = 'Budgeted Position No.';
            TableRelation = Position WHERE("Budgeted Position" = CONST(true));

            trigger OnValidate()
            begin
                CheckModify;
            end;
        }
        field(52; "Used Rate"; Decimal)
        {
            CalcFormula = Sum (Position.Rate WHERE("Budgeted Position No." = FIELD("No.")));
            Caption = 'Used Rate';
            Editable = false;
            FieldClass = FlowField;
        }
        field(53; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(54; "Base Salary Amount"; Decimal)
        {
            Caption = 'Base Salary Amount';
            Editable = false;
        }
        field(55; "Monthly Salary Amount"; Decimal)
        {
            Caption = 'Monthly Salary Amount';
            Editable = false;
        }
        field(56; "Additional Salary Amount"; Decimal)
        {
            Caption = 'Additional Salary Amount';
            Editable = false;
        }
        field(57; "Budgeted Salary Amount"; Decimal)
        {
            Caption = 'Budgeted Salary Amount';
            Editable = false;
        }
        field(60; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(70; "Future Period Vacat. Post. Gr."; Code[20])
        {
            Caption = 'Future Period Vacat. Post. Gr.';
            TableRelation = "Payroll Posting Group";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Org. Unit Code", "Job Title Code", Status, "Budgeted Position", "Out-of-Staff", "Starting Date")
        {
            SumIndexFields = "Monthly Salary Amount", "Base Salary Amount", "Additional Salary Amount", "Budgeted Salary Amount", Rate;
        }
        key(Key3; "Org. Unit Code", "Job Title Code", "No.")
        {
        }
        key(Key4; "Parent Position No.", "No.")
        {
        }
        key(Key5; "Budgeted Position", "Budgeted Position No.")
        {
            SumIndexFields = "Budgeted Salary", Rate;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Job Title Code", "Job Title Name", "Org. Unit Code", "Org. Unit Name")
        {
        }
    }

    trigger OnDelete()
    begin
        TestField(Status, Position.Status::Planned);
        if not Confirm(Text000, true, "No.") then
            Error('');

        LaborContractTermsSetup.Reset();
        LaborContractTermsSetup.SetRange("Table Type", LaborContractTermsSetup."Table Type"::Position);
        LaborContractTermsSetup.SetRange("No.", "No.");
        LaborContractTermsSetup.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            HumanResSetup.Get();
            TestNoSeries;
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", 0D, "No.", "No. Series");
        end;

        "Created By User" := UserId;
        "Creation Date" := Today;
    end;

    var
        HumanResSetup: Record "Human Resources Setup";
        Position: Record Position;
        Position2: Record Position;
        OrganizationalUnit: Record "Organizational Unit";
        JobTitle: Record "Job Title";
        DefaultLaborContractTerms: Record "Default Labor Contract Terms";
        LaborContractTermsSetup: Record "Labor Contract Terms Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text000: Label 'Do you want really to delete position %1?';
        Text001: Label 'Do you want to approve %1?';
        Text002: Label '%1 %2 should be earlier than %3 %4.', Comment = '%1 = Org. Unit, %2 = Date, %3 = Position, %4 = Date';
        Text003: Label '%1 can exceed %2 for budget positions only.';

    [Scope('OnPrem')]
    procedure AssistEdit(OldPosition: Record Position): Boolean
    begin
        with Position do begin
            Position := Rec;
            HumanResSetup.Get();
            HumanResSetup.TestField("Position Nos.");
            if NoSeriesMgt.SelectSeries(HumanResSetup."Position Nos.", OldPosition."No. Series", "No. Series") then begin
                HumanResSetup.Get();
                HumanResSetup.TestField("Position Nos.");
                NoSeriesMgt.SetSeries("No.");
                Rec := Position;
                exit(true);
            end;
        end;
    end;

    local procedure TestNoSeries()
    begin
        if "Budgeted Position" then
            HumanResSetup.TestField("Budgeted Position Nos.")
        else
            HumanResSetup.TestField("Position Nos.");
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        if "Budgeted Position" then
            exit(HumanResSetup."Budgeted Position Nos.");

        exit(HumanResSetup."Position Nos.");
    end;

    [Scope('OnPrem')]
    procedure CheckModify()
    begin
        if Status > Status::Planned then
            FieldError(Status);
    end;

    [Scope('OnPrem')]
    procedure Calculate()
    begin
        "Monthly Salary" := "Base Salary" + "Additional Salary";

        "Base Salary Amount" := "Base Salary" * Rate;
        "Additional Salary Amount" := "Additional Salary" * Rate;
        "Monthly Salary Amount" := "Monthly Salary" * Rate;
        "Budgeted Salary Amount" := "Budgeted Salary" * Rate;
    end;

    [Scope('OnPrem')]
    procedure Approve(IsChangeOrder: Boolean)
    var
        Confirmed: Boolean;
    begin
        if not IsChangeOrder then begin
            HumanResSetup.Get();
            HumanResSetup.TestField("Use Staff List Change Orders", false);
        end;

        TestField(Status, Status::Planned);

        TestField("Job Title Code");
        TestField("Org. Unit Code");
        TestField(Rate);
        TestField("Base Salary");
        TestField("Monthly Salary");
        TestField("Category Code");
        TestField("Calendar Code");
        TestField("Calc Group Code");
        TestField("Posting Group");
        TestField("Kind of Work");
        TestField("Conditions of Work");
        TestField(Rate);
        TestField("Starting Date");
        if "Kind of Work" in ["Kind of Work"::"Temporary", "Kind of Work"::Seasonal] then
            TestField("Ending Date");

        if "Org. Unit Code" <> '' then begin
            OrganizationalUnit.Get("Org. Unit Code");
            OrganizationalUnit.TestField(Type, OrganizationalUnit.Type::Unit);
            if not HumanResSetup."Use Staff List Change Orders" then
                OrganizationalUnit.TestField(Status, OrganizationalUnit.Status::Approved);
            OrganizationalUnit.TestField(Blocked, false);
        end;

        Confirmed := true;
        if not IsChangeOrder then
            if not Confirm(Text001, true, "No.") then
                Confirmed := false;

        if Confirmed then begin
            Status := Status::Approved;
            "Approved By User" := UserId;
            "Approval Date" := Today;
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure Reopen(IsChangeOrder: Boolean)
    begin
        if not IsChangeOrder then begin
            HumanResSetup.Get();
            HumanResSetup.TestField("Use Staff List Change Orders", false);
        end;

        TestField(Status, Status::Approved);
        if "Budgeted Position" then begin
            CalcFields("Used Rate");
            TestField("Used Rate", 0);
        end else begin
            CalcFields("Filled Rate");
            TestField("Filled Rate", 0);
        end;
        Status := Status::Planned;
        "Reopened by User" := UserId;
        "Reopened Date" := Today;
        Modify;
    end;

    [Scope('OnPrem')]
    procedure Close(IsChangeOrder: Boolean)
    begin
        if not IsChangeOrder then begin
            HumanResSetup.Get();
            HumanResSetup.TestField("Use Staff List Change Orders", false);
        end;

        TestField(Status, Status::Approved);
        if "Budgeted Position" then begin
            CalcFields("Used Rate");
            if "Used Rate" > 0 then begin
                Position2.Reset();
                Position2.SetCurrentKey("Budgeted Position", "Budgeted Position No.");
                Position2.SetRange("Budgeted Position", false);
                Position2.SetRange("Budgeted Position No.", "No.");
                if Position2.FindSet then
                    repeat
                        Position2.TestField(Status, Position2.Status::Closed);
                    until Position2.Next() = 0;
            end;
        end else begin
            CalcFields("Filled Rate");
            TestField("Filled Rate", 0);
        end;

        Status := Status::Closed;
        "Closed By User" := UserId;
        "Closing Date" := Today;
        Modify;
    end;

    [Scope('OnPrem')]
    procedure CopyContractTerms()
    begin
        if ("Job Title Code" <> '') and ("Org. Unit Code" <> '') and ("Category Code" <> '') then begin
            DefaultLaborContractTerms.Reset();
            DefaultLaborContractTerms.SetFilter("Category Code", '%1|%2', "Category Code", '');
            DefaultLaborContractTerms.SetFilter("Org. Unit Code", '%1|%2', "Org. Unit Code", '');
            DefaultLaborContractTerms.SetFilter("Job Title Code", '%1|%2', "Job Title Code", '');
            DefaultLaborContractTerms.SetRange("Start Date", 0D, "Starting Date");
            DefaultLaborContractTerms.SetFilter("End Date", '%1|%2..', 0D, "Ending Date");
            if DefaultLaborContractTerms.FindSet then
                repeat
                    LaborContractTermsSetup.SetRange("Table Type", LaborContractTermsSetup."Table Type"::Position);
                    LaborContractTermsSetup.SetRange("No.", "No.");
                    LaborContractTermsSetup.SetRange("Element Code", DefaultLaborContractTerms."Element Code");
                    LaborContractTermsSetup.SetRange("Operation Type", DefaultLaborContractTerms."Operation Type");
                    LaborContractTermsSetup.SetRange("Start Date", DefaultLaborContractTerms."Start Date");
                    if LaborContractTermsSetup.FindFirst then begin
                        if LaborContractTermsSetup.Amount < DefaultLaborContractTerms.Amount then begin
                            LaborContractTermsSetup.Amount := DefaultLaborContractTerms.Amount;
                            LaborContractTermsSetup.Modify();
                        end;
                        if LaborContractTermsSetup.Quantity < DefaultLaborContractTerms.Quantity then begin
                            LaborContractTermsSetup.Quantity := DefaultLaborContractTerms.Quantity;
                            LaborContractTermsSetup.Modify();
                        end;
                    end else begin
                        LaborContractTermsSetup.Init();
                        LaborContractTermsSetup."Table Type" := LaborContractTermsSetup."Table Type"::Position;
                        LaborContractTermsSetup."No." := "No.";
                        LaborContractTermsSetup."Element Code" := DefaultLaborContractTerms."Element Code";
                        LaborContractTermsSetup."Operation Type" := DefaultLaborContractTerms."Operation Type";
                        LaborContractTermsSetup."Start Date" := DefaultLaborContractTerms."Start Date";
                        LaborContractTermsSetup."End Date" := DefaultLaborContractTerms."End Date";
                        LaborContractTermsSetup.Type := DefaultLaborContractTerms.Type;
                        LaborContractTermsSetup.Amount := DefaultLaborContractTerms.Amount;
                        LaborContractTermsSetup.Percent := DefaultLaborContractTerms.Percent;
                        LaborContractTermsSetup.Quantity := DefaultLaborContractTerms.Quantity;
                        LaborContractTermsSetup."Additional Salary" := DefaultLaborContractTerms."Additional Salary";
                        LaborContractTermsSetup.Insert();
                    end;
                until DefaultLaborContractTerms.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowContractTerms()
    var
        LaborContractTermsSetup: Record "Labor Contract Terms Setup";
        PayrollElement: Record "Payroll Element";
        LaborContractTermsSetupPage: Page "Labor Contract Terms Setup";
    begin
        LaborContractTermsSetup.SetRange("Table Type", LaborContractTermsSetup."Table Type"::Position);
        LaborContractTermsSetup.SetRange("No.", "No.");
        LaborContractTermsSetupPage.SetTableView(LaborContractTermsSetup);
        LaborContractTermsSetupPage.RunModal;

        if Status = Status::Planned then begin
            "Additional Salary" := 0;
            LaborContractTermsSetup.SetRange(Type, LaborContractTermsSetup.Type::"Payroll Element");
            if LaborContractTermsSetup.Find('-') then
                repeat
                    PayrollElement.Get(LaborContractTermsSetup."Element Code");
                    if PayrollElement.Type = PayrollElement.Type::Wage then
                        "Additional Salary" := "Additional Salary" + LaborContractTermsSetup.Amount;
                until LaborContractTermsSetup.Next() = 0;

            if "Additional Salary" <> xRec."Additional Salary" then begin
                Validate("Additional Salary");
                Modify;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CopyPosition(CreationDate: Date): Code[20]
    var
        NewPosition: Record Position;
        NewLaborContractTermsSetup: Record "Labor Contract Terms Setup";
    begin
        NewPosition.Init();
        NewPosition.TransferFields(Rec, false);
        NewPosition.Status := NewPosition.Status::Planned;
        NewPosition."Created By User" := UserId;
        NewPosition."Creation Date" := CreationDate;
        NewPosition."Approved By User" := '';
        NewPosition."Approval Date" := 0D;
        NewPosition."Closed By User" := '';
        NewPosition."Closing Date" := 0D;
        NewPosition."No." := '';
        NewPosition.Insert(true);

        LaborContractTermsSetup.Reset();
        LaborContractTermsSetup.SetRange("Table Type", LaborContractTermsSetup."Table Type"::Position);
        LaborContractTermsSetup.SetRange("No.", "No.");
        if LaborContractTermsSetup.FindSet then
            repeat
                NewLaborContractTermsSetup := LaborContractTermsSetup;
                NewLaborContractTermsSetup."No." := NewPosition."No.";
                NewLaborContractTermsSetup.Insert();
            until LaborContractTermsSetup.Next() = 0;

        exit(NewPosition."No.");
    end;
}

