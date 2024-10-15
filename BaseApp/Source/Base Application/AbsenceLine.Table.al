table 17386 "Absence Line"
{
    Caption = 'Absence Line';

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Vacation,Sick Leave,Travel,Other Absence';
            OptionMembers = Vacation,"Sick Leave",Travel,"Other Absence";
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Absence Header"."No." WHERE("Document Type" = FIELD("Document Type"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Time Activity Code"; Code[10])
        {
            Caption = 'Time Activity Code';
            TableRelation = IF ("Document Type" = CONST(Vacation)) "Time Activity" WHERE("Time Activity Type" = CONST(Vacation))
            ELSE
            IF ("Document Type" = CONST("Sick Leave")) "Time Activity" WHERE("Time Activity Type" = CONST("Sick Leave"))
            ELSE
            IF ("Document Type" = CONST(Travel)) "Time Activity" WHERE("Time Activity Type" = CONST(Travel))
            ELSE
            IF ("Document Type" = CONST("Other Absence")) "Time Activity" WHERE("Time Activity Type" = CONST(Other));

            trigger OnValidate()
            begin
                TestStatusOpen;
                GetAbsenceHeader;
                "Employee No." := AbsenceHeader."Employee No.";
                Employee.Get("Employee No.");
                "Person No." := Employee."Person No.";

                if TimeActivity.Get("Time Activity Code") then begin
                    case "Document Type" of
                        "Document Type"::Vacation:
                            begin
                                TimeActivity.TestField("Time Activity Type",
                                  TimeActivity."Time Activity Type"::Vacation);
                                Validate("Vacation Type", TimeActivity."Vacation Type");
                                if "Time Activity Code" <> xRec."Time Activity Code" then
                                    Validate("Vacation Request No.", '');
                            end;
                        "Document Type"::"Sick Leave":
                            begin
                                TimeActivity.TestField("Time Activity Type",
                                  TimeActivity."Time Activity Type"::"Sick Leave");
                                Validate("Sick Leave Type", TimeActivity."Sick Leave Type");
                            end;
                    end;
                    Description := CopyStr(TimeActivity.Description, 1, MaxStrLen(Description));
                    Validate("Element Code", TimeActivity."Element Code");
                end;
            end;
        }
        field(5; Description; Text[50])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(6; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                LocMgt.CheckPeriodDates("Start Date", "End Date");
                AbsenceLine := Rec;
                AbsenceLine.SetRange("Document Type", "Document Type");
                AbsenceLine.SetRange("Document No.", "Document No.");
                if AbsenceLine.Next(-1) <> 0 then
                    if AbsenceLine."End Date" >= "Start Date" then
                        FieldError("Start Date");

                Validate("Employee No.");
            end;
        }
        field(7; "End Date"; Date)
        {
            Caption = 'End Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                LocMgt.CheckPeriodDates("Start Date", "End Date");
                Validate("Employee No.");
            end;
        }
        field(8; "Absence Entry No."; Integer)
        {
            Caption = 'Absence Entry No.';

            trigger OnLookup()
            begin
                EmployeeAbsenceEntry.Reset();
                EmployeeAbsenceEntry.SetCurrentKey("Employee No.");
                EmployeeAbsenceEntry.SetRange("Employee No.", "Employee No.");
                EmployeeAbsenceEntry.SetRange("Time Activity Code", "Time Activity Code");
                EmployeeAbsenceEntry.SetRange("Entry Type", EmployeeAbsenceEntry."Entry Type"::Accrual);
                if PAGE.RunModal(0, EmployeeAbsenceEntry) = ACTION::LookupOK then
                    Validate("Absence Entry No.", EmployeeAbsenceEntry."Entry No.");
            end;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(9; "Vacation Request No."; Code[20])
        {
            Caption = 'Vacation Request No.';
            TableRelation = "Vacation Request" WHERE("Employee No." = FIELD("Employee No."),
                                                      "Time Activity Code" = FIELD("Time Activity Code"));

            trigger OnValidate()
            begin
                TestStatusOpen;
                TestField("Document Type", "Document Type"::Vacation);
                if "Vacation Request No." <> '' then begin
                    VacationRequest.Get("Vacation Request No.");
                    VacationRequest.TestField(Status, VacationRequest.Status::Approved);
                    "Start Date" := VacationRequest."Start Date";
                    Validate("End Date", VacationRequest."End Date");
                    Description := VacationRequest.Description;
                end else begin
                    "Start Date" := 0D;
                    "End Date" := 0D;
                    "Calendar Days" := 0;
                end;
            end;
        }
        field(10; "Calendar Days"; Decimal)
        {
            Caption = 'Calendar Days';
            MinValue = 1;

            trigger OnValidate()
            begin
                TestStatusOpen;
                if "Calendar Days" > 0 then
                    "End Date" := CalcDate(StrSubstNo('<%1D>', "Calendar Days" - 1), "Start Date")
                else
                    "End Date" := "Start Date";
                Validate("Employee No.");
            end;
        }
        field(11; "Working Days"; Decimal)
        {
            Caption = 'Working Days';
            Editable = false;
        }
        field(13; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            Editable = false;
            TableRelation = Employee;

            trigger OnValidate()
            begin
                if "Start Date" <> 0D then begin
                    Employee.Get("Employee No.");
                    Terminated := Employee.IsTerminated("Start Date");
                    if not Terminated then begin
                        if "Document Type" = "Document Type"::"Sick Leave" then begin
                            SickLeaveSetup.GetPaymentPercent(Rec);
                            if ("Sick Leave Type" in
                                ["Sick Leave Type"::"Family Member Care",
                                 "Sick Leave Type"::"Post Vaccination",
                                 "Sick Leave Type"::Quarantine]) and
                               ("Relative Person No." <> '')
                            then begin
                                TestField("Treatment Type");
                                SickLeaveSetup.GetCarePaymentPercent(Rec);
                            end;
                        end;

                        CalcDays;

                        if "End Date" <> 0D then begin
                            AECalcMgt.FillAbsenceLineAEDates(Rec);
                            if "Document Type" = "Document Type"::"Sick Leave" then begin
                                SickLeaveSetup.GetEmployerPaymentDay(Rec);
                                SickLeaveSetup.GetFSIPaymentDays(Rec);
                            end;
                        end;
                    end else
                        if ("Document Type" = "Document Type"::"Sick Leave") and ("End Date" <> 0D) then begin
                            // TEST "Sick Leave Type"
                            SickLeaveSetup.GetPaymentPercent(Rec);
                            AECalcMgt.FillAbsenceLineAEDates(Rec);
                            "Calendar Days" :=
                              CalendarMgt.GetPeriodInfo(
                                Employee."Calendar Code", "Start Date", "End Date", 1);
                            SickLeaveSetup.GetEmployerPaymentDay(Rec);
                            SickLeaveSetup.GetFSIPaymentDays(Rec);
                        end;
                end;
            end;
        }
        field(14; "Special Payment Days"; Decimal)
        {
            Caption = 'Special Payment Days';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(15; "Special Payment Percent"; Decimal)
        {
            Caption = 'Special Payment Percent';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(16; "Days Paid by Employer"; Decimal)
        {
            Caption = 'Days Paid by Employer';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(17; "Days Not Paid"; Decimal)
        {
            Caption = 'Days Not Paid';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(18; "Payment Days"; Decimal)
        {
            Caption = 'Payment Days';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(19; "Payment Percent"; Decimal)
        {
            Caption = 'Payment Percent';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(20; "Vacation Type"; Option)
        {
            Caption = 'Vacation Type';
            Editable = false;
            OptionCaption = ' ,Regular,Additional,Education,Childcare,Other';
            OptionMembers = " ",Regular,Additional,Education,Childcare,Other;
        }
        field(21; "Sick Leave Type"; Option)
        {
            Caption = 'Sick Leave Type';
            Editable = false;
            OptionCaption = ' ,Common Disease,Common Injury,Professional Disease,Work Injury,Family Member Care,Post Vaccination,Quarantine,Sanatory Cure,Pregnancy Leave,Child Care 1.5 years,Child Care 3 years';
            OptionMembers = " ","Common Disease","Common Injury","Professional Disease","Work Injury","Family Member Care","Post Vaccination",Quarantine,"Sanatory Cure","Pregnancy Leave","Child Care 1.5 years","Child Care 3 years";

            trigger OnValidate()
            begin
                Validate("Employee No.");
            end;
        }
        field(22; "Change Reason"; Text[50])
        {
            Caption = 'Change Reason';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(23; "Treatment Type"; Option)
        {
            Caption = 'Treatment Type';
            OptionCaption = ' ,Out-Patient,In-Patient';
            OptionMembers = " ","Out-Patient","In-Patient";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(24; "AE Period From"; Code[10])
        {
            Caption = 'AE Period From';
            TableRelation = "Payroll Period";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(25; "AE Period To"; Code[10])
        {
            Caption = 'AE Period To';
            TableRelation = "Payroll Period";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(27; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            TableRelation = Person;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(28; "Relative Person No."; Code[20])
        {
            Caption = 'Relative Person No.';
            TableRelation = Person;

            trigger OnLookup()
            begin
                TestField("Document Type", "Document Type"::"Sick Leave");
                if not ("Sick Leave Type" in
                        ["Sick Leave Type"::"Family Member Care",
                         "Sick Leave Type"::"Child Care 1.5 years",
                         "Sick Leave Type"::"Child Care 3 years",
                         "Sick Leave Type"::"Post Vaccination",
                         "Sick Leave Type"::Quarantine])
                then
                    Error(Text002,
                      FieldCaption("Relative Person No."),
                      FieldCaption("Sick Leave Type"),
                      "Sick Leave Type");

                EmployeeRelative.Reset();
                EmployeeRelative.SetRange("Person No.", "Person No.");
                if PAGE.RunModal(0, EmployeeRelative) = ACTION::LookupOK then begin
                    EmployeeRelative.TestField("Relative Person No.");
                    Validate("Relative Person No.", EmployeeRelative."Relative Person No.");
                end;
            end;

            trigger OnValidate()
            begin
                if "Relative Person No." <> '' then begin
                    TestField("Document Type", "Document Type"::"Sick Leave");
                    if not ("Sick Leave Type" in
                            ["Sick Leave Type"::"Family Member Care",
                             "Sick Leave Type"::"Child Care 1.5 years",
                             "Sick Leave Type"::"Child Care 3 years",
                             "Sick Leave Type"::"Post Vaccination",
                             "Sick Leave Type"::Quarantine])
                    then
                        Error(Text002,
                          FieldCaption("Relative Person No."),
                          FieldCaption("Sick Leave Type"),
                          "Sick Leave Type");
                end;

                if ("Document Type" = "Document Type"::"Sick Leave") and ("Start Date" <> 0D) then begin
                    SickLeaveSetup.GetPaymentPercent(Rec);
                    if ("Sick Leave Type" in
                        ["Sick Leave Type"::"Family Member Care",
                         "Sick Leave Type"::"Post Vaccination",
                         "Sick Leave Type"::Quarantine]) and
                       ("Relative Person No." <> '')
                    then begin
                        TestField("Treatment Type");
                        SickLeaveSetup.GetCarePaymentPercent(Rec);
                    end;
                end;
            end;
        }
        field(29; "Child Grant Type"; Option)
        {
            Caption = 'Child Grant Type';
            OptionCaption = '0,1,2,3,4,5';
            OptionMembers = "0","1","2","3","4","5";
        }
        field(30; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(31; "Previous Document No."; Code[20])
        {
            Caption = 'Previous Document No.';
            TableRelation = "Posted Absence Header"."No." WHERE("Document Type" = FIELD("Document Type"),
                                                                 "Employee No." = FIELD("Employee No."));

            trigger OnValidate()
            begin
                Validate("Employee No.");
            end;
        }
        field(32; Terminated; Boolean)
        {
            Caption = 'Terminated';
            Editable = false;
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "Calendar Days", "Working Days";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestStatusOpen;
    end;

    trigger OnInsert()
    begin
        TestStatusOpen;
    end;

    var
        TimeActivity: Record "Time Activity";
        AbsenceHeader: Record "Absence Header";
        AbsenceLine: Record "Absence Line";
        Employee: Record Employee;
        EmployeeRelative: Record "Employee Relative";
        SickLeaveSetup: Record "Sick Leave Setup";
        EmployeeJobEntry: Record "Employee Job Entry";
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
        VacationRequest: Record "Vacation Request";
        LocMgt: Codeunit "Localisation Management";
        CalendarMgt: Codeunit "Payroll Calendar Management";
        AECalcMgt: Codeunit "AE Calc Management";
        Text002: Label 'You cannot enter %1 if %2 is %3.';
        Text003: Label 'Employee %1 is not employed as of date %2.';
        DimMgt: Codeunit DimensionManagement;

    [Scope('OnPrem')]
    procedure CalcDays()
    var
        CalDays: Decimal;
        Holidays: Decimal;
    begin
        if ("Start Date" <> 0D) and ("End Date" <> 0D) then begin
            if not Employee.GetJobEntry("Employee No.", "Start Date", EmployeeJobEntry) then
                Error(Text003, "Employee No.", "Start Date");

            CalDays :=
              CalendarMgt.GetPeriodInfo(
                EmployeeJobEntry."Calendar Code", "Start Date", "End Date", 1);
            Holidays :=
              CalendarMgt.GetPeriodInfo(
                GetOfficialCalendarCode, "Start Date", "End Date", 4);
            "Working Days" :=
              CalendarMgt.GetPeriodInfo(
                EmployeeJobEntry."Calendar Code", "Start Date", "End Date", 2);

            case "Document Type" of
                "Document Type"::Vacation:
                    begin
                        "Calendar Days" := CalDays - Holidays;

                        TimeActivity.Get("Time Activity Code");
                        if TimeActivity."Paid Activity" then begin
                            "Payment Days" := "Calendar Days";
                            "Payment Percent" := 100;
                            "Days Paid by Employer" := "Calendar Days";
                        end;
                    end;
                "Document Type"::"Sick Leave":
                    "Calendar Days" := CalDays;
                else begin
                        "Calendar Days" := CalDays;
                        TimeActivity.Get("Time Activity Code");
                        if TimeActivity."Paid Activity" then begin
                            TestField("Working Days");
                            "Payment Days" := "Working Days";
                            "Payment Percent" := 100;
                            "Days Paid by Employer" := "Working Days";
                        end;
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateDim(Type1: Integer; No1: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        GetAbsenceHeader;
        "Dimension Set ID" :=
          DimMgt.GetDefaultDimID(
            TableID, No, SourceCodeSetup.Sales,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code",
            AbsenceHeader."Dimension Set ID", DATABASE::Employee);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure ShowComments()
    var
        HROrderCommentLine: Record "HR Order Comment Line";
        HROrderCommentLines: Page "HR Order Comment Lines";
    begin
        HROrderCommentLine.SetRange("Table Name", HROrderCommentLine."Table Name"::"Absence Order");
        HROrderCommentLine.SetRange("No.", "Document No.");
        HROrderCommentLine.SetRange("Line No.", "Line No.");
        HROrderCommentLines.SetTableView(HROrderCommentLine);
        HROrderCommentLines.RunModal;
    end;

    [Scope('OnPrem')]
    procedure FindPreviousAbsenceHeader(var PostedAbsenceLine: Record "Posted Absence Line") Exist: Boolean
    begin
        Exist := FindFirstAbsenceHeader(PostedAbsenceLine, "Previous Document No.");
    end;

    local procedure FindFirstAbsenceHeader(var PostedAbsenceLine: Record "Posted Absence Line"; PrevDocNo: Code[20]): Boolean
    begin
        PostedAbsenceLine.Reset();
        PostedAbsenceLine.SetRange("Document Type", "Document Type");
        PostedAbsenceLine.SetRange("Document No.", PrevDocNo);
        if PostedAbsenceLine.FindFirst then
            if PostedAbsenceLine."Previous Document No." = '' then
                exit(true)
            else
                exit(FindFirstAbsenceHeader(PostedAbsenceLine, PostedAbsenceLine."Previous Document No."))
        else
            exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetPaymentDaysPerYear() Days: Decimal
    var
        PostedAbsenceLine: Record "Posted Absence Line";
    begin
        PostedAbsenceLine.Reset();
        PostedAbsenceLine.SetRange("Document Type", "Document Type");
        PostedAbsenceLine.SetRange("Sick Leave Type", "Sick Leave Type");
        PostedAbsenceLine.SetRange("Start Date", CalcDate('<-CY>', "Start Date"), CalcDate('<CY>', "Start Date"));
        PostedAbsenceLine.SetRange("Relative Person No.", "Relative Person No.");
        if PostedAbsenceLine.Find('-') then
            repeat
                Days := Days + PostedAbsenceLine."Payment Days" + PostedAbsenceLine."Special Payment Days";
            until PostedAbsenceLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetAbsenceHeader()
    begin
        TestField("Document No.");
        if ("Document Type" <> AbsenceHeader."Document Type") or ("Document No." <> AbsenceHeader."No.") then
            AbsenceHeader.Get("Document Type", "Document No.");
    end;

    local procedure TestStatusOpen()
    begin
        GetAbsenceHeader;
        AbsenceHeader.TestField(Status, AbsenceHeader.Status::Open);
    end;

    local procedure GetOfficialCalendarCode(): Code[10]
    var
        HRSetup: Record "Human Resources Setup";
    begin
        HRSetup.Get();
        HRSetup.TestField("Official Calendar Code");
        exit(HRSetup."Official Calendar Code");
    end;
}

