table 17382 "Employee Journal Line"
{
    Caption = 'Employee Journal Line';

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Employee Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Employee Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            NotBlank = true;
            TableRelation = Employee;

            trigger OnValidate()
            begin
                Employee.Get("Employee No.");
                "Posting Group" := Employee."Posting Group";
                "Payroll Calc Group" := Employee."Payroll Calc Group";
                "Contract No." := Employee."Contract No.";
                "Person No." := Employee."Person No.";
                if "Starting Date" = 0D then begin
                    "Calendar Code" := Employee."Calendar Code";
                    "Position No." := Employee."Position No.";
                end else
                    if Employee.GetJobEntry("Employee No.", "Starting Date", EmployeeJobEntry) then begin
                        "Calendar Code" := EmployeeJobEntry."Calendar Code";
                        "Position No." := EmployeeJobEntry."Position No.";
                    end else
                        FieldError("Starting Date");

                "Relative Person No." := '';
                "Applies-to Entry" := 0;

                CreateDim(
                  DATABASE::Employee, "Employee No.",
                  DATABASE::"Payroll Element", "Element Code");
            end;
        }
        field(5; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";

            trigger OnValidate()
            begin
                PayrollElement.Get("Element Code");
                Description := PayrollElement.Description;
                if PayrollElement."Payroll Posting Group" <> '' then
                    Validate("Posting Group", PayrollElement."Payroll Posting Group");

                CreateDim(
                  DATABASE::"Payroll Element", "Element Code",
                  DATABASE::Employee, "Employee No.")
            end;
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                if "Posting Date" <> 0D then
                    "Period Code" :=
                      PayrollPeriod.PeriodByDate("Posting Date");
            end;
        }
        field(7; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                TestField("Employee No.");
                if "Starting Date" <> 0D then begin
                    if Employee.GetJobEntry("Employee No.", "Starting Date", EmployeeJobEntry) then begin
                        "Calendar Code" := EmployeeJobEntry."Calendar Code";
                        "Position No." := EmployeeJobEntry."Position No.";
                    end;
                    PayrollElement.Get("Element Code");
                    if PayrollElement."Bonus Type" <> 0 then
                        "Wage Period From" := PayrollPeriod.PeriodByDate("Starting Date");
                end;
            end;
        }
        field(8; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                PayrollElement.Get("Element Code");
                if PayrollElement."Bonus Type" <> 0 then
                    "Wage Period To" := PayrollPeriod.PeriodByDate("Ending Date");
            end;
        }
        field(9; Amount; Decimal)
        {
            Caption = 'Amount';
            DecimalPlaces = 0 : 5;
        }
        field(10; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(12; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            Editable = false;
            TableRelation = "Payroll Calendar";
        }
        field(13; "Payroll Calc Group"; Code[10])
        {
            Caption = 'Payroll Calc Group';
            Editable = false;
            TableRelation = "Payroll Calc Group";
        }
        field(14; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            Editable = false;
        }
        field(15; "HR Order No."; Code[20])
        {
            Caption = 'HR Order No.';
        }
        field(16; "HR Order Date"; Date)
        {
            Caption = 'HR Order Date';
        }
        field(17; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(19; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(20; "Position No."; Code[20])
        {
            Caption = 'Position No.';
            Editable = false;
            TableRelation = Position;
        }
        field(21; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            Editable = false;
            TableRelation = Person;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(25; "Time Activity Code"; Code[10])
        {
            Caption = 'Time Activity Code';
            TableRelation = "Time Activity";

            trigger OnValidate()
            begin
                if TimeActivity.Get("Time Activity Code") then
                    if ("Element Code" = '') and (TimeActivity."Element Code" <> '') then
                        Validate("Element Code", TimeActivity."Element Code");
            end;
        }
        field(26; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(28; "Post Action"; Option)
        {
            Caption = 'Post Action';
            OptionCaption = 'Add,Update,Close';
            OptionMembers = Add,Update,Close;
        }
        field(29; "Applies-to Entry"; Integer)
        {
            Caption = 'Applies-to Entry';

            trigger OnLookup()
            var
                EmployeeLedgEntry: Record "Employee Ledger Entry";
                EmployeeLedgEntries: Page "Employee Ledger Entries";
            begin
                if "Post Action" <> "Post Action"::Add then begin
                    EmployeeLedgEntry.Reset;
                    EmployeeLedgEntry.SetCurrentKey("Employee No.", "Element Code");
                    EmployeeLedgEntry.SetRange("Employee No.", "Employee No.");
                    EmployeeLedgEntry.SetRange("Element Code", "Element Code");
                    EmployeeLedgEntries.SetTableView(EmployeeLedgEntry);
                    EmployeeLedgEntries.LookupMode(true);
                    if EmployeeLedgEntries.RunModal = ACTION::LookupOK then begin
                        EmployeeLedgEntries.GetRecord(EmployeeLedgEntry);
                        Validate("Applies-to Entry", EmployeeLedgEntry."Entry No.");
                    end;
                end else
                    TestField("Post Action", "Post Action"::Add);
            end;

            trigger OnValidate()
            var
                EmployeeLedgEntry: Record "Employee Ledger Entry";
            begin
                if "Applies-to Entry" <> 0 then
                    EmployeeLedgEntry.Get("Applies-to Entry");
            end;
        }
        field(30; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Vacation,Sick Leave,Travel,Other Absence';
            OptionMembers = " ",Vacation,"Sick Leave",Travel,"Other Absence";
        }
        field(31; "Vacation Type"; Option)
        {
            Caption = 'Vacation Type';
            OptionCaption = ' ,Regular,Additional,Education,Childcare,Other';
            OptionMembers = " ",Regular,Additional,Education,Childcare,Other;
        }
        field(32; "Payment Days"; Decimal)
        {
            Caption = 'Payment Days';
        }
        field(33; "Payment Percent"; Decimal)
        {
            Caption = 'Payment Percent';
        }
        field(34; "Sick Leave Type"; Option)
        {
            Caption = 'Sick Leave Type';
            OptionCaption = ' ,Common Disease,Common Injury,Professional Disease,Work Injury,Family Member Care,Post Vaccination,Quarantine,Sanatory Cure,Pregnancy Leave,Child Care 1.5 years,Child Care 3 years';
            OptionMembers = " ","Common Disease","Common Injury","Professional Disease","Work Injury","Family Member Care","Post Vaccination",Quarantine,"Sanatory Cure","Pregnancy Leave","Child Care 1.5 years","Child Care 3 years";
        }
        field(35; "Child Grant Type"; Option)
        {
            Caption = 'Child Grant Type';
            OptionCaption = '0,1,2,3,4,5';
            OptionMembers = "0","1","2","3","4","5";
        }
        field(36; "AE Period From"; Code[10])
        {
            Caption = 'AE Period From';
            TableRelation = "Payroll Period";

            trigger OnValidate()
            begin
                if ("AE Period From" <> '') and ("AE Period To" <> '') then
                    if "AE Period From" > "AE Period To" then
                        Error(Text001, FieldCaption("AE Period To"), FieldCaption("AE Period From"));

                if ("Period Code" <> '') and ("AE Period From" <> '') then
                    if "AE Period From" > "Period Code" then
                        Error(Text001, FieldCaption("Period Code"), FieldCaption("AE Period From"));
            end;
        }
        field(37; "AE Period To"; Code[10])
        {
            Caption = 'AE Period To';
            TableRelation = "Payroll Period";

            trigger OnValidate()
            begin
                if ("AE Period From" <> '') and ("AE Period To" <> '') then
                    if "AE Period From" > "AE Period To" then
                        Error(Text001, FieldCaption("AE Period To"), FieldCaption("AE Period From"));

                if ("Period Code" <> '') and ("AE Period To" <> '') then
                    if "AE Period To" > "Period Code" then
                        Error(Text001, FieldCaption("Period Code"), FieldCaption("AE Period To"));
            end;
        }
        field(38; "Wage Period To"; Code[10])
        {
            Caption = 'Wage Period To';
            TableRelation = "Payroll Period";
        }
        field(39; "Wage Period From"; Code[10])
        {
            Caption = 'Wage Period From';
            TableRelation = "Payroll Period";
        }
        field(43; "Days Not Paid"; Decimal)
        {
            Caption = 'Days Not Paid';
        }
        field(45; "Relative Person No."; Code[20])
        {
            Caption = 'Relative Person No.';
            TableRelation = Person;

            trigger OnLookup()
            var
                EmployeeRelative: Record "Employee Relative";
            begin
                EmployeeRelative.Reset;
                EmployeeRelative.SetRange("Person No.", "Person No.");
                if PAGE.RunModal(0, EmployeeRelative) = ACTION::LookupOK then begin
                    EmployeeRelative.TestField("Relative Person No.");
                    Validate("Relative Person No.", EmployeeRelative."Relative Person No.");
                end;
            end;
        }
        field(46; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnValidate()
            begin
                if "HR Order No." = '' then
                    "HR Order No." := "Document No.";
            end;
        }
        field(47; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                if "HR Order Date" = 0D then
                    "HR Order Date" := "Document Date";
            end;
        }
        field(48; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(49; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(50; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(51; "Salary Indexation"; Boolean)
        {
            Caption = 'Salary Indexation';
        }
        field(52; "Depends on Salary Element"; Code[20])
        {
            Caption = 'Depends on Salary Element';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Wage));
        }
        field(53; "Payment Source"; Option)
        {
            Caption = 'Payment Source';
            OptionCaption = 'Employeer,FSI';
            OptionMembers = Employeer,FSI;
        }
        field(54; Terminated; Boolean)
        {
            Caption = 'Terminated';
            Editable = false;
        }
        field(55; "External Document No."; Text[30])
        {
            Caption = 'External Document No.';
        }
        field(56; "External Document Date"; Date)
        {
            Caption = 'External Document Date';
        }
        field(57; "External Document Issued By"; Text[50])
        {
            Caption = 'External Document Issued By';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        Employee: Record Employee;
        PayrollElement: Record "Payroll Element";
        TimeActivity: Record "Time Activity";
        EmployeeJnlTemplate: Record "Employee Journal Template";
        EmployeeJnlBatch: Record "Employee Journal Batch";
        EmployeeJnlLine: Record "Employee Journal Line";
        PayrollPeriod: Record "Payroll Period";
        EmployeeJobEntry: Record "Employee Job Entry";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        Text001: Label '%1 should be greater than %2.';

    [Scope('OnPrem')]
    procedure EmptyLine(): Boolean
    begin
        exit(("Employee No." = '') and ("Element Code" = ''));
    end;

    [Scope('OnPrem')]
    procedure SetUpNewLine(LastEmployeeJnlLine: Record "Employee Journal Line")
    begin
        EmployeeJnlTemplate.Get("Journal Template Name");
        EmployeeJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        EmployeeJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        EmployeeJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if EmployeeJnlLine.FindFirst then begin
            "Posting Date" := LastEmployeeJnlLine."Posting Date";
            "HR Order Date" := LastEmployeeJnlLine."Posting Date";
            "HR Order No." := LastEmployeeJnlLine."HR Order No.";
        end else begin
            "Posting Date" := WorkDate;
            "HR Order Date" := WorkDate;
            if EmployeeJnlBatch."No. Series" <> '' then begin
                Clear(NoSeriesMgt);
                "HR Order No." := NoSeriesMgt.TryGetNextNo(EmployeeJnlBatch."No. Series", "Posting Date");
            end;
        end;
        "Source Code" := EmployeeJnlTemplate."Source Code";
        "Reason Code" := EmployeeJnlBatch."Reason Code";
        "Posting No. Series" := EmployeeJnlBatch."Posting No. Series";
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
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetDefaultDimID(
            TableID, No, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;
}

