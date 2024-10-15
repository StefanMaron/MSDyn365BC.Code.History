table 17388 "Posted Absence Line"
{
    Caption = 'Posted Absence Line';

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
            TableRelation = "Posted Absence Header"."No." WHERE("Document Type" = FIELD("Document Type"));
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
        }
        field(5; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(6; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(7; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(8; "Absence Entry No."; Integer)
        {
            Caption = 'Absence Entry No.';
        }
        field(9; "Vacation Request No."; Code[20])
        {
            Caption = 'Vacation Request No.';
            TableRelation = "Vacation Request" WHERE("Employee No." = FIELD("Employee No."));
        }
        field(10; "Calendar Days"; Decimal)
        {
            Caption = 'Calendar Days';
        }
        field(11; "Working Days"; Decimal)
        {
            Caption = 'Working Days';
        }
        field(13; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(14; "Special Payment Days"; Decimal)
        {
            Caption = 'Special Payment Days';
        }
        field(15; "Special Payment Percent"; Decimal)
        {
            Caption = 'Special Payment Percent';
        }
        field(16; "Days Paid by Employer"; Decimal)
        {
            Caption = 'Days Paid by Employer';
        }
        field(17; "Days Not Paid"; Decimal)
        {
            Caption = 'Days Not Paid';
        }
        field(18; "Payment Days"; Decimal)
        {
            Caption = 'Payment Days';
        }
        field(19; "Payment Percent"; Decimal)
        {
            Caption = 'Payment Percent';
        }
        field(20; "Vacation Type"; Option)
        {
            Caption = 'Vacation Type';
            OptionCaption = ' ,Regular,Additional,Education,Childcare,Other';
            OptionMembers = " ",Regular,Additional,Education,Childcare,Other;
        }
        field(21; "Sick Leave Type"; Option)
        {
            Caption = 'Sick Leave Type';
            OptionCaption = ' ,Common Disease,Common Injury,Professional Disease,Work Injury,Family Member Care,Post Vaccination,Quarantine,Sanatory Cure,Pregnancy Leave,Child Care 1.5 years,Child Care 3 years';
            OptionMembers = " ","Common Disease","Common Injury","Professional Disease","Work Injury","Family Member Care","Post Vaccination",Quarantine,"Sanatory Cure","Pregnancy Leave","Child Care 1.5 years","Child Care 3 years";
        }
        field(22; "Change Reason"; Text[50])
        {
            Caption = 'Change Reason';
        }
        field(23; "Treatment Type"; Option)
        {
            Caption = 'Treatment Type';
            OptionCaption = ' ,Out-Patient,In-Patient';
            OptionMembers = " ","Out-Patient","In-Patient";
        }
        field(24; "AE Period From"; Code[10])
        {
            Caption = 'AE Period From';
            TableRelation = "Payroll Period";
        }
        field(25; "AE Period To"; Code[10])
        {
            Caption = 'AE Period To';
            TableRelation = "Payroll Period";
        }
        field(27; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            TableRelation = Person;
        }
        field(28; "Relative Person No."; Code[20])
        {
            Caption = 'Relative Person No.';
            TableRelation = Person;

            trigger OnLookup()
            begin
                EmployeeRelative.Reset();
                EmployeeRelative.SetRange("Person No.", "Person No.");
                PAGE.Run(0, EmployeeRelative);
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
        }
        field(31; "Previous Document No."; Code[20])
        {
            Caption = 'Previous Document No.';
            TableRelation = "Posted Absence Header"."No." WHERE("Document Type" = FIELD("Document Type"),
                                                                 "Employee No." = FIELD("Employee No."));
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            TableRelation = "Dimension Set Entry";
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

    var
        EmployeeRelative: Record "Employee Relative";
        DimMgt: Codeunit DimensionManagement;

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
        HROrderCommentLine.SetRange("Table Name", HROrderCommentLine."Table Name"::"P.Absence Order");
        HROrderCommentLine.SetRange("No.", "Document No.");
        HROrderCommentLine.SetRange("Line No.", "Line No.");
        HROrderCommentLines.SetTableView(HROrderCommentLine);
        HROrderCommentLines.RunModal;
    end;

    [Scope('OnPrem')]
    procedure ShowAEEntries()
    var
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
        PostedPayrollDocLine2: Record "Posted Payroll Document Line";
        PostedPayrollDocLineAEForm: Page "Posted Payroll Doc. Line AE";
    begin
        TestField("Document No.");
        TestField("Line No.");

        PostedPayrollDocLine2.Reset();
        PostedPayrollDocLine2.SetCurrentKey("Document Type", "HR Order No.");
        PostedPayrollDocLine2.SetRange("Document Type", "Document Type" + 1);
        PostedPayrollDocLine2.SetRange("HR Order No.", "Document No.");
        PostedPayrollDocLine2.SetRange("Employee No.", "Employee No.");
        PostedPayrollDocLine2.SetRange("Element Code", "Element Code");
        if PostedPayrollDocLine2.FindFirst then begin
            PostedPayrollDocLine.SetRange("Document No.", PostedPayrollDocLine2."Document No.");
            PostedPayrollDocLine.SetRange("Line No.", PostedPayrollDocLine2."Line No.");
            PostedPayrollDocLineAEForm.SetTableView(PostedPayrollDocLine);
            PostedPayrollDocLineAEForm.RunModal;
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowAEPeriods()
    var
        PostedPayrollPeriodAE: Record "Posted Payroll Period AE";
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
        PayrollPeriodAEForm: Page "Posted Payr. Doc. Line AE Per.";
    begin
        TestField("Document No.");
        TestField("Line No.");

        PostedPayrollDocLine.Reset();
        PostedPayrollDocLine.SetCurrentKey("Document Type", "HR Order No.");
        PostedPayrollDocLine.SetRange("Document Type", "Document Type" + 1);
        PostedPayrollDocLine.SetRange("HR Order No.", "Document No.");
        PostedPayrollDocLine.SetRange("Employee No.", "Employee No.");
        PostedPayrollDocLine.SetRange("Element Code", "Element Code");
        if PostedPayrollDocLine.FindFirst then begin
            PostedPayrollPeriodAE.SetRange("Document No.", PostedPayrollDocLine."Document No.");
            PostedPayrollPeriodAE.SetRange("Line No.", PostedPayrollDocLine."Line No.");
            PayrollPeriodAEForm.SetDocLine(PostedPayrollDocLine);
            PayrollPeriodAEForm.SetTableView(PostedPayrollPeriodAE);
            PayrollPeriodAEForm.RunModal;
        end;
    end;
}

