table 17372 "Staff List"
{
    Caption = 'Staff List';

    fields
    {
        field(1; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            NotBlank = true;
            TableRelation = "Organizational Unit";

            trigger OnValidate()
            begin
                if OrganizationalUnit.Get("Org. Unit Code") then
                    "Org. Unit Name" := OrganizationalUnit.Name;
            end;
        }
        field(2; "Job Title Code"; Code[10])
        {
            Caption = 'Job Title Code';
            NotBlank = true;
            TableRelation = "Job Title";

            trigger OnValidate()
            begin
                if JobTitle.Get("Job Title Code") then
                    "Job Title Name" := JobTitle.Name;
            end;
        }
        field(4; "Org. Unit Name"; Text[50])
        {
            Caption = 'Org. Unit Name';
            Editable = false;
        }
        field(5; "Job Title Name"; Text[50])
        {
            Caption = 'Job Title Name';
            Editable = false;
        }
        field(6; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        field(7; "Parent Code"; Code[10])
        {
            Caption = 'Parent Code';
            TableRelation = "Organizational Unit";
        }
        field(8; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Unit,Heading,Total';
            OptionMembers = Unit,Heading,Total;
        }
        field(10; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(11; "Budgeted Filter"; Boolean)
        {
            Caption = 'Budgeted Filter';
            FieldClass = FlowFilter;
        }
        field(12; "Out-of-Staff Filter"; Boolean)
        {
            Caption = 'Out-of-Staff Filter';
            FieldClass = FlowFilter;
        }
        field(20; "Planned Positions"; Decimal)
        {
            CalcFormula = Sum (Position.Rate WHERE(Status = CONST(Planned),
                                                   "Org. Unit Code" = FIELD("Org. Unit Code"),
                                                   "Job Title Code" = FIELD("Job Title Code"),
                                                   "Budgeted Position" = FIELD("Budgeted Filter"),
                                                   "Out-of-Staff" = FIELD("Out-of-Staff Filter"),
                                                   "Starting Date" = FIELD("Date Filter")));
            Caption = 'Planned Positions';
            FieldClass = FlowField;
        }
        field(21; "Approved Positions"; Decimal)
        {
            CalcFormula = Sum (Position.Rate WHERE(Status = CONST(Approved),
                                                   "Org. Unit Code" = FIELD("Org. Unit Code"),
                                                   "Job Title Code" = FIELD("Job Title Code"),
                                                   "Budgeted Position" = FIELD("Budgeted Filter"),
                                                   "Out-of-Staff" = FIELD("Out-of-Staff Filter"),
                                                   "Starting Date" = FIELD("Date Filter")));
            Caption = 'Approved Positions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; "Closed Positions"; Decimal)
        {
            CalcFormula = Sum (Position.Rate WHERE(Status = CONST(Closed),
                                                   "Org. Unit Code" = FIELD("Org. Unit Code"),
                                                   "Job Title Code" = FIELD("Job Title Code"),
                                                   "Budgeted Position" = FIELD("Budgeted Filter"),
                                                   "Out-of-Staff" = FIELD("Out-of-Staff Filter"),
                                                   "Starting Date" = FIELD("Date Filter")));
            Caption = 'Closed Positions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Approved Base Salary"; Decimal)
        {
            CalcFormula = Sum (Position."Base Salary Amount" WHERE(Status = CONST(Approved),
                                                                   "Org. Unit Code" = FIELD("Org. Unit Code"),
                                                                   "Job Title Code" = FIELD("Job Title Code"),
                                                                   "Budgeted Position" = FIELD("Budgeted Filter"),
                                                                   "Out-of-Staff" = FIELD("Out-of-Staff Filter"),
                                                                   "Starting Date" = FIELD("Date Filter")));
            Caption = 'Approved Base Salary';
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; "Approved Monthly Salary"; Decimal)
        {
            CalcFormula = Sum (Position."Monthly Salary Amount" WHERE(Status = CONST(Approved),
                                                                      "Org. Unit Code" = FIELD("Org. Unit Code"),
                                                                      "Job Title Code" = FIELD("Job Title Code"),
                                                                      "Budgeted Position" = FIELD("Budgeted Filter"),
                                                                      "Out-of-Staff" = FIELD("Out-of-Staff Filter"),
                                                                      "Starting Date" = FIELD("Date Filter")));
            Caption = 'Approved Monthly Salary';
            Editable = false;
            FieldClass = FlowField;
        }
        field(25; "Approved Additional Salary"; Decimal)
        {
            CalcFormula = Sum (Position."Additional Salary Amount" WHERE(Status = CONST(Approved),
                                                                         "Org. Unit Code" = FIELD("Org. Unit Code"),
                                                                         "Job Title Code" = FIELD("Job Title Code"),
                                                                         "Budgeted Position" = FIELD("Budgeted Filter"),
                                                                         "Out-of-Staff" = FIELD("Out-of-Staff Filter"),
                                                                         "Starting Date" = FIELD("Date Filter")));
            Caption = 'Approved Additional Salary';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Approved Budgeted Salary"; Decimal)
        {
            CalcFormula = Sum (Position."Budgeted Salary Amount" WHERE(Status = CONST(Approved),
                                                                       "Org. Unit Code" = FIELD("Org. Unit Code"),
                                                                       "Job Title Code" = FIELD("Job Title Code"),
                                                                       "Budgeted Position" = FIELD("Budgeted Filter"),
                                                                       "Out-of-Staff" = FIELD("Out-of-Staff Filter"),
                                                                       "Starting Date" = FIELD("Date Filter")));
            Caption = 'Approved Budgeted Salary';
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; "Planned Base Salary"; Decimal)
        {
            CalcFormula = Sum (Position."Base Salary Amount" WHERE(Status = CONST(Planned),
                                                                   "Org. Unit Code" = FIELD("Org. Unit Code"),
                                                                   "Job Title Code" = FIELD("Job Title Code"),
                                                                   "Budgeted Position" = FIELD("Budgeted Filter"),
                                                                   "Out-of-Staff" = FIELD("Out-of-Staff Filter"),
                                                                   "Starting Date" = FIELD("Date Filter")));
            Caption = 'Planned Base Salary';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Planned Monthly Salary"; Decimal)
        {
            CalcFormula = Sum (Position."Monthly Salary Amount" WHERE(Status = CONST(Planned),
                                                                      "Org. Unit Code" = FIELD("Org. Unit Code"),
                                                                      "Job Title Code" = FIELD("Job Title Code"),
                                                                      "Budgeted Position" = FIELD("Budgeted Filter"),
                                                                      "Out-of-Staff" = FIELD("Out-of-Staff Filter"),
                                                                      "Starting Date" = FIELD("Date Filter")));
            Caption = 'Planned Monthly Salary';
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Planned Additional Salary"; Decimal)
        {
            CalcFormula = Sum (Position."Additional Salary Amount" WHERE(Status = CONST(Planned),
                                                                         "Org. Unit Code" = FIELD("Org. Unit Code"),
                                                                         "Job Title Code" = FIELD("Job Title Code"),
                                                                         "Budgeted Position" = FIELD("Budgeted Filter"),
                                                                         "Out-of-Staff" = FIELD("Out-of-Staff Filter"),
                                                                         "Starting Date" = FIELD("Date Filter")));
            Caption = 'Planned Additional Salary';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Planned Budgeted Salary"; Decimal)
        {
            CalcFormula = Sum (Position."Budgeted Salary Amount" WHERE(Status = CONST(Planned),
                                                                       "Org. Unit Code" = FIELD("Org. Unit Code"),
                                                                       "Job Title Code" = FIELD("Job Title Code"),
                                                                       "Budgeted Position" = FIELD("Budgeted Filter"),
                                                                       "Out-of-Staff" = FIELD("Out-of-Staff Filter"),
                                                                       "Starting Date" = FIELD("Date Filter")));
            Caption = 'Planned Budgeted Salary';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Org. Unit Code", "Job Title Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        JobTitle: Record "Job Title";
        OrganizationalUnit: Record "Organizational Unit";
        Position: Record Position;
        Text14703: Label 'This function will create Staff List archive as of date %1. Continue?';

    [Scope('OnPrem')]
    procedure Create(var TempStaffList: Record "Staff List" temporary; StartDate: Date; EndDate: Date)
    begin
        TempStaffList.DeleteAll;

        OrganizationalUnit.Reset;
        OrganizationalUnit.SetFilter(Status, '<>%1', OrganizationalUnit.Status::Open);
        OrganizationalUnit.SetRange("Starting Date", 0D, EndDate);
        OrganizationalUnit.SetFilter("Ending Date", '%1|%2..', 0D, StartDate);
        if OrganizationalUnit.FindSet then
            repeat
                Position.Reset;
                Position.SetCurrentKey("Org. Unit Code");
                Position.SetRange("Org. Unit Code", OrganizationalUnit.Code);
                Position.SetRange("Starting Date", StartDate, EndDate);
                if Position.FindSet then
                    repeat
                        InitRecord(
                          TempStaffList, OrganizationalUnit.Code, Position."Job Title Code", OrganizationalUnit.Level,
                          OrganizationalUnit."Parent Code", OrganizationalUnit.Type);
                        if TempStaffList.Insert then;
                    until Position.Next = 0
                else begin
                    InitRecord(
                      TempStaffList, OrganizationalUnit.Code, '', OrganizationalUnit.Level, OrganizationalUnit."Parent Code",
                      OrganizationalUnit.Type);
                    TempStaffList.Insert;
                end;
            until OrganizationalUnit.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure InitRecord(var TempStaffList: Record "Staff List" temporary; OrgUnitCode: Code[10]; JobTitleCode: Code[10]; Level: Integer; ParentCode: Code[10]; Type: Integer)
    begin
        TempStaffList.Init;
        TempStaffList.Validate("Org. Unit Code", OrgUnitCode);
        TempStaffList.Validate("Job Title Code", JobTitleCode);
        TempStaffList.Indentation := Level;
        TempStaffList."Parent Code" := ParentCode;
        TempStaffList.Type := Type;
    end;

    [Scope('OnPrem')]
    procedure CreateArchive(var TempStaffListBuffer: Record "Staff List" temporary)
    var
        StaffListArchive: Record "Staff List Archive";
        StaffListLineArchive: Record "Staff List Line Archive";
        CompanyInfo: Record "Company Information";
        HumanResSetup: Record "Human Resources Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if not
           Confirm(
             StrSubstNo(Text14703, TempStaffListBuffer.GetRangeMax("Date Filter")), true)
        then
            exit;

        CompanyInfo.Get;
        CompanyInfo.TestField("HR Manager No.");
        CompanyInfo.TestField("Accountant No.");

        HumanResSetup.Get;
        HumanResSetup.TestField("HR Order Nos.");

        StaffListArchive.Init;
        StaffListArchive."Document No." :=
          NoSeriesMgt.GetNextNo(HumanResSetup."HR Order Nos.", Today, true);
        StaffListArchive."Document Date" := Today;
        StaffListArchive."Order No." := StaffListArchive."Document No.";
        StaffListArchive."Order Date" := StaffListArchive."Document Date";
        StaffListArchive."HR Manager No." := CompanyInfo."HR Manager No.";
        StaffListArchive."Chief Accountant No." := CompanyInfo."Accountant No.";
        StaffListArchive."Staff List Date" := GetRangeMax("Date Filter");
        StaffListArchive.Insert;

        TempStaffListBuffer.CopyFilter("Date Filter", "Date Filter");
        if TempStaffListBuffer.FindSet then
            repeat
                StaffListLineArchive.Init;
                StaffListLineArchive."Org. Unit Code" := TempStaffListBuffer."Org. Unit Code";
                StaffListLineArchive."Org. Unit Name" := TempStaffListBuffer."Org. Unit Name";
                StaffListLineArchive."Job Title Code" := TempStaffListBuffer."Job Title Code";
                StaffListLineArchive."Job Title Name" := TempStaffListBuffer."Job Title Name";
                StaffListLineArchive."Parent Code" := TempStaffListBuffer."Parent Code";
                StaffListLineArchive.Indentation := TempStaffListBuffer.Indentation;
                StaffListLineArchive.Type := TempStaffListBuffer.Type;
                StaffListLineArchive."Document No." := StaffListArchive."Document No.";
                // Staff positions
                TempStaffListBuffer.SetRange("Out-of-Staff Filter", false);
                TempStaffListBuffer.CalcFields(
                  "Approved Positions", "Approved Base Salary",
                  "Approved Monthly Salary", "Approved Additional Salary", "Approved Budgeted Salary");
                StaffListLineArchive."Staff Positions" := TempStaffListBuffer."Approved Positions";
                StaffListLineArchive."Staff Base Salary" := TempStaffListBuffer."Approved Base Salary";
                StaffListLineArchive."Staff Monthly Salary" := TempStaffListBuffer."Approved Monthly Salary";
                StaffListLineArchive."Staff Additional Salary" := TempStaffListBuffer."Approved Additional Salary";
                StaffListLineArchive."Staff Budgeted Salary" := TempStaffListBuffer."Approved Budgeted Salary";
                StaffListLineArchive."Occupied Staff Positions" := 0;
                Position.SetRange("Org. Unit Code", TempStaffListBuffer."Org. Unit Code");
                Position.SetRange("Job Title Code", TempStaffListBuffer."Job Title Code");
                Position.SetRange(Status, Position.Status::Approved);
                Position.SetRange("Out-of-Staff", false);
                Position.SetRange("Starting Date", 0D, GetRangeMax("Date Filter"));
                if Position.FindSet then
                    repeat
                        Position.CalcFields("Filled Rate");
                        StaffListLineArchive."Occupied Staff Positions" :=
                          StaffListLineArchive."Occupied Staff Positions" + Position."Filled Rate";
                    until Position.Next = 0;
                StaffListLineArchive."Vacant Staff Positions" :=
                  StaffListLineArchive."Staff Positions" - StaffListLineArchive."Occupied Staff Positions";
                // Out-of-Staff positions
                TempStaffListBuffer.SetRange("Out-of-Staff Filter", true);
                TempStaffListBuffer.CalcFields(
                  "Approved Positions", "Approved Base Salary",
                  "Approved Monthly Salary", "Approved Additional Salary", "Approved Budgeted Salary");
                StaffListLineArchive."Out-of-Staff Positions" := TempStaffListBuffer."Approved Positions";
                StaffListLineArchive."Out-of-Staff Base Salary" := TempStaffListBuffer."Approved Base Salary";
                StaffListLineArchive."Out-of-Staff Monthly Salary" := TempStaffListBuffer."Approved Monthly Salary";
                StaffListLineArchive."Out-of-Staff Additional Salary" := TempStaffListBuffer."Approved Additional Salary";
                StaffListLineArchive."Out-of-Staff Budgeted Salary" := TempStaffListBuffer."Approved Budgeted Salary";
                StaffListLineArchive."Occup. Out-of-Staff Positions" := 0;
                Position.SetRange("Org. Unit Code", TempStaffListBuffer."Org. Unit Code");
                Position.SetRange("Job Title Code", TempStaffListBuffer."Job Title Code");
                Position.SetRange(Status, Position.Status::Approved);
                Position.SetRange("Out-of-Staff", true);
                Position.SetRange("Starting Date", 0D, GetRangeMax("Date Filter"));
                if Position.FindSet then
                    repeat
                        Position.CalcFields("Filled Rate");
                        StaffListLineArchive."Occup. Out-of-Staff Positions" :=
                          StaffListLineArchive."Occup. Out-of-Staff Positions" + Position."Filled Rate";
                    until Position.Next = 0;
                StaffListLineArchive."Vacant Out-of-Staff Positions" :=
                  StaffListLineArchive."Out-of-Staff Positions" - StaffListLineArchive."Occup. Out-of-Staff Positions";
                TempStaffListBuffer.SetRange("Out-of-Staff Filter");
                StaffListLineArchive.Insert;
            until TempStaffListBuffer.Next = 0;
    end;
}

