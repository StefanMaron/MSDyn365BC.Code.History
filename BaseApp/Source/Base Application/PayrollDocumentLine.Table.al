table 17415 "Payroll Document Line"
{
    Caption = 'Payroll Document Line';
    Permissions = TableData "Payroll Period AE" = rimd;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Payroll Document";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(8; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(9; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(11; "Calc Group"; Code[10])
        {
            Caption = 'Calc Group';
            TableRelation = "Payroll Calc Group";
        }
        field(13; Amount; Decimal)
        {
            Caption = 'Amount';
            DecimalPlaces = 2 : 2;
            Editable = false;

            trigger OnValidate()
            begin
                CheckDocStatus;
            end;
        }
        field(14; "Payroll Amount"; Decimal)
        {
            Caption = 'Payroll Amount';
            DecimalPlaces = 2 : 2;

            trigger OnValidate()
            begin
                CheckDocStatus;
                if (CurrFieldNo = FieldNo("Payroll Amount")) and ("Payroll Amount" <> xRec."Payroll Amount") then
                    ConfirmChangeAmount;
            end;
        }
        field(15; "Taxable Amount"; Decimal)
        {
            Caption = 'Taxable Amount';
            DecimalPlaces = 2 : 2;

            trigger OnValidate()
            begin
                CheckDocStatus;
                if (CurrFieldNo = FieldNo("Taxable Amount")) and ("Taxable Amount" <> xRec."Taxable Amount") then
                    ConfirmChangeAmount;
            end;
        }
        field(17; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(23; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                CheckDocStatus;
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                CheckDocStatus;
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(26; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Vacation,Sick Leave,Travel,Other Absence';
            OptionMembers = " ",Vacation,"Sick Leave",Travel,"Other Absence";
        }
        field(27; "HR Order No."; Code[20])
        {
            Caption = 'HR Order No.';
        }
        field(28; "HR Order Date"; Date)
        {
            Caption = 'HR Order Date';
        }
        field(30; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";

            trigger OnValidate()
            begin
                CheckDocStatus;
                GetDocumentHeader;
                PayrollDoc.TestField("Employee No.");
                "Employee No." := PayrollDoc."Employee No.";
                "Period Code" := PayrollDoc."Period Code";

                if "Element Code" = '' then begin
                    Calculate := false;
                    exit;
                end;

                PayrollElement.Get("Element Code");
                "Depends on Salary Element" := PayrollElement."Depends on Salary Element";
                Calculate := PayrollElement.Calculate;

                AvailabilityIndex := false;

                PayrollCalcGroupLine.Reset();
                PayrollCalcGroupLine.SetRange("Payroll Calc Group", Employee."Payroll Calc Group");
                if PayrollCalcGroupLine.FindSet then
                    repeat
                        PayrollCalcTypeLine.Reset();
                        PayrollCalcTypeLine.SetRange("Calc Type Code", PayrollCalcGroupLine."Payroll Calc Type");
                        PayrollCalcTypeLine.SetRange("Element Code", "Element Code");
                        if PayrollCalcTypeLine.FindFirst then
                            AvailabilityIndex := true;
                    until PayrollCalcGroupLine.Next = 0;

                CreateDim(DATABASE::"Payroll Element", "Element Code");

                if not AvailabilityIndex then
                    Message(Text005);

                CalculatePayroll.CopyElementToPayrollDocLine(PayrollElement, Rec);
                if PayrollCalcTypeLine."Payroll Posting Group" <> '' then
                    "Posting Group" := PayrollCalcTypeLine."Payroll Posting Group";

                if "Posting Group" = '' then
                    if PayrollElement."Posting Type" = PayrollElement."Posting Type"::Charge then
                        if Employee."Posting Group" <> '' then
                            "Posting Group" := Employee."Posting Group";

                if PayrollElement.Description = '' then
                    Description := CopyStr(
                        Employee."Last Name" + ' ' + Employee."First Name" + ' ' + Employee."Middle Name", 1, MaxStrLen(Description));

                if "Element Type" = "Element Type"::"Netto Salary" then
                    "Posting Group" := Employee."Posting Group";
            end;
        }
        field(31; Calculate; Boolean)
        {
            Caption = 'Calculate';
            Editable = false;
        }
        field(32; "Element Type"; Option)
        {
            Caption = 'Element Type';
            Editable = false;
            OptionCaption = 'Wage,Bonus,Income Tax,Netto Salary,Tax Deduction,Deduction,Other,Funds,Reporting';
            OptionMembers = Wage,Bonus,"Income Tax","Netto Salary","Tax Deduction",Deduction,Other,Funds,Reporting;
        }
        field(33; "Posting Type"; Option)
        {
            Caption = 'Posting Type';
            Editable = false;
            OptionCaption = 'Not Post,Charge,Liability,Liability Charge,Information Only';
            OptionMembers = "Not Post",Charge,Liability,"Liability Charge","Information Only";
        }
        field(34; "Element Group"; Code[20])
        {
            Caption = 'Element Group';
            Editable = false;
            TableRelation = "Payroll Element Group";
        }
        field(35; "Print in Pay-Sheet"; Option)
        {
            Caption = 'Print in Pay-Sheet';
            OptionCaption = 'Not Print,Current Value,From Starting Year,Balance,Current+From Starting Year,Current+Balance';
            OptionMembers = "Not Print","Current Value","From Starting Year",Balance,"Current+From Starting Year","Current+Balance";
        }
        field(36; "Salary Indexation"; Boolean)
        {
            Caption = 'Salary Indexation';
        }
        field(37; "Depends on Salary Element"; Code[20])
        {
            Caption = 'Depends on Salary Element';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Wage));
        }
        field(38; "Payment Source"; Option)
        {
            Caption = 'Payment Source';
            OptionCaption = 'Employeer,FSI';
            OptionMembers = Employeer,FSI;
        }
        field(52; "Time Activity Code"; Code[10])
        {
            Caption = 'Time Activity Code';
            TableRelation = "Time Activity";
        }
        field(55; "Employee Ledger Entry No."; Integer)
        {
            Caption = 'Employee Ledger Entry No.';
            TableRelation = "Employee Ledger Entry";
        }
        field(61; "Bonus Type"; Option)
        {
            Caption = 'Bonus Type';
            OptionCaption = ' ,Monthly,Quarterly,Semi-Annual,Annual';
            OptionMembers = " ",Monthly,Quarterly,"Semi-Annual",Annual;
        }
        field(100; "Pay-Sheet Print"; Boolean)
        {
            Caption = 'Pay-Sheet Print';
            Editable = true;
        }
        field(102; Print; Integer)
        {
            Caption = 'Print';
            Editable = false;
        }
        field(103; "Original Amount"; Decimal)
        {
            Caption = 'Original Amount';
            DecimalPlaces = 2 : 2;
            Editable = false;
        }
        field(104; "Corr. Amount"; Decimal)
        {
            Caption = 'Corr. Amount';
            DecimalPlaces = 2 : 2;
            Description = 'DEL';
            Editable = false;
        }
        field(108; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            TableRelation = "Payroll Calendar";

            trigger OnValidate()
            begin
                CheckDocStatus;
            end;
        }
        field(109; "Corr. Amount 2"; Decimal)
        {
            Caption = 'Corr. Amount 2';
            DecimalPlaces = 2 : 2;
            Description = 'DEL';
        }
        field(110; "Directory Code"; Code[10])
        {
            Caption = 'Directory Code';
            TableRelation = IF ("Element Type" = FILTER(Wage | Bonus | Other)) "Payroll Directory".Code WHERE(Type = CONST(Income))
            ELSE
            IF ("Element Type" = FILTER("Tax Deduction")) "Payroll Directory".Code WHERE(Type = CONST("Tax Deduction"))
            ELSE
            IF ("Element Type" = CONST(Funds)) "Payroll Directory".Code WHERE(Type = CONST(Tax));
        }
        field(111; "Calc Type Code"; Code[20])
        {
            Caption = 'Calc Type Code';
            Editable = false;
            TableRelation = "Payroll Calc Type";
        }
        field(112; Priority; Integer)
        {
            Caption = 'Priority';
        }
        field(113; "FSI Base"; Boolean)
        {
            Caption = 'FSI Base';
        }
        field(115; "Federal FMI Base"; Boolean)
        {
            Caption = 'Federal FMI Base';
        }
        field(116; "Territorial FMI Base"; Boolean)
        {
            Caption = 'Territorial FMI Base';
        }
        field(117; "Pension Fund Base"; Boolean)
        {
            Caption = 'Pension Fund Base';
        }
        field(118; "Income Tax Base"; Boolean)
        {
            Caption = 'Income Tax Base';
        }
        field(119; "FSI Injury Base"; Boolean)
        {
            Caption = 'FSI Injury Base';
        }
        field(122; "AE Period From"; Code[10])
        {
            Caption = 'AE Period From';
            Editable = false;
            TableRelation = "Payroll Period";
        }
        field(123; "AE Period To"; Code[10])
        {
            Caption = 'AE Period To';
            Editable = false;
            TableRelation = "Payroll Period";
        }
        field(124; "Print Priority"; Integer)
        {
            Caption = 'Print Priority';
        }
        field(129; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            TableRelation = "Organizational Unit";
        }
        field(130; "Employee Posting Group"; Code[20])
        {
            Caption = 'Employee Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(132; "Pay Type"; Option)
        {
            Caption = 'Pay Type';
            OptionCaption = ' ,Salary Schedule,Social,Other Income';
            OptionMembers = " ","Salary Schedule",Social,"Other Income";
        }
        field(136; "Employee Account No."; Code[20])
        {
            Caption = 'Employee Account No.';
        }
        field(141; "Wage Period From"; Code[10])
        {
            Caption = 'Wage Period From';
            TableRelation = "Payroll Period";
        }
        field(142; "Wage Period To"; Code[10])
        {
            Caption = 'Wage Period To';
            TableRelation = "Payroll Period";
        }
        field(148; "Amount (ACY)"; Decimal)
        {
            Caption = 'Amount (ACY)';
        }
        field(150; "Action Starting Date"; Date)
        {
            Caption = 'Action Starting Date';
        }
        field(151; "Action Ending Date"; Date)
        {
            Caption = 'Action Ending Date';
        }
        field(201; "Source Pay"; Option)
        {
            Caption = 'Source Pay';
            OptionCaption = ' ,Cost,Profit,FSI,FOSI';
            OptionMembers = " ",Cost,Profit,FSI,FOSI;
        }
        field(220; "AE Total Earnings"; Decimal)
        {
            CalcFormula = Sum ("Payroll Document Line AE"."Amount for AE" WHERE("Document No." = FIELD("Document No."),
                                                                                "Document Line No." = FIELD("Line No.")));
            Caption = 'AE Total Earnings';
            Editable = false;
            FieldClass = FlowField;
        }
        field(221; "AE Daily Earnings"; Decimal)
        {
            Caption = 'AE Daily Earnings';
            Editable = false;
        }
        field(222; "AE Hourly Earnings"; Decimal)
        {
            Caption = 'AE Hourly Earnings';
        }
        field(223; "AE Total Days"; Decimal)
        {
            CalcFormula = Sum ("Payroll Period AE"."Average Days" WHERE("Document No." = FIELD("Document No."),
                                                                        "Line No." = FIELD("Line No.")));
            Caption = 'AE Total Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(224; "AE Total FSI Earnings"; Decimal)
        {
            CalcFormula = Sum ("Payroll Document Line AE"."Amount for FSI" WHERE("Document No." = FIELD("Document No."),
                                                                                 "Document Line No." = FIELD("Line No.")));
            Caption = 'AE Total FSI Earnings';
            Editable = false;
            FieldClass = FlowField;
        }
        field(225; "AE Total Earnings Indexed"; Decimal)
        {
            CalcFormula = Sum ("Payroll Document Line AE"."Indexed Amount for AE" WHERE("Document No." = FIELD("Document No."),
                                                                                        "Document Line No." = FIELD("Line No.")));
            Caption = 'AE Total Earnings Indexed';
            Editable = false;
            FieldClass = FlowField;
        }
        field(234; "Payment Percent"; Decimal)
        {
            Caption = 'Payment Percent';
        }
        field(240; "Code OKATO"; Code[11])
        {
            Caption = 'Code OKATO';
        }
        field(241; "Code KPP"; Code[10])
        {
            Caption = 'Code KPP';
        }
        field(244; "Vacation Posting Group"; Code[20])
        {
            Caption = 'Vacation Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(250; "Planned Days"; Decimal)
        {
            Caption = 'Planned Days';
        }
        field(251; "Planned Hours"; Decimal)
        {
            Caption = 'Planned Hours';
        }
        field(252; "Actual Days"; Decimal)
        {
            Caption = 'Actual Days';
        }
        field(253; "Actual Hours"; Decimal)
        {
            Caption = 'Actual Hours';
        }
        field(256; "Payment Days"; Decimal)
        {
            Caption = 'Payment Days';
        }
        field(257; "Payment Hours"; Decimal)
        {
            Caption = 'Payment Hours';
        }
        field(258; "Days Not Paid"; Decimal)
        {
            Caption = 'Days Not Paid';
        }
        field(259; "Excluded Days"; Decimal)
        {
            Caption = 'Excluded Days';
            Editable = false;
        }
        field(260; "Days To Exclude"; Decimal)
        {
            Caption = 'Days To Exclude';
            Editable = false;
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
        field(17400; "Payroll Ledger Entry No."; Integer)
        {
            Caption = 'Payroll Ledger Entry No.';
            TableRelation = "Payroll Ledger Entry";
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount, "Payroll Amount";
        }
        key(Key2; "Element Type", "Employee No.", "Period Code", "Posting Type")
        {
            SumIndexFields = Amount, "Payroll Amount";
        }
        key(Key3; "Element Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PayrollDocLineAE.Reset();
        PayrollDocLineAE.SetRange("Document No.", "Document No.");
        PayrollDocLineAE.SetRange("Document Line No.", "Line No.");
        PayrollDocLineAE.DeleteAll();

        PayrollPeriodAE.Reset();
        PayrollPeriodAE.SetRange("Document No.", "Document No.");
        PayrollPeriodAE.SetRange("Line No.", "Line No.");
        PayrollPeriodAE.DeleteAll();

        PayrollDocLineCalc.Reset();
        PayrollDocLineCalc.SetRange("Document No.", "Document No.");
        PayrollDocLineCalc.SetRange("Document Line No.", "Line No.");
        PayrollDocLineCalc.DeleteAll();

        PayrollDocLineVar.Reset();
        PayrollDocLineVar.SetRange("Document No.", "Document No.");
        PayrollDocLineVar.SetRange("Document Line No.", "Line No.");
        PayrollDocLineVar.DeleteAll();

        PayrollDocLineExpr.Reset();
        PayrollDocLineExpr.SetRange("Document No.", "Document No.");
        PayrollDocLineExpr.SetRange("Document Line No.", "Line No.");
        PayrollDocLineExpr.DeleteAll();
    end;

    var
        Text005: Label 'Incorrect element!';
        Text008: Label 'Do you really want to change this calculated value?';
        Employee: Record Employee;
        PayrollElement: Record "Payroll Element";
        PayrollCalcTypeLine: Record "Payroll Calc Type Line";
        PayrollCalcGroupLine: Record "Payroll Calc Group Line";
        PayrollDoc: Record "Payroll Document";
        PayrollPeriodAE: Record "Payroll Period AE";
        PayrollDocLineAE: Record "Payroll Document Line AE";
        PayrollDocLineCalc: Record "Payroll Document Line Calc.";
        PayrollDocLineExpr: Record "Payroll Document Line Expr.";
        PayrollDocLineVar: Record "Payroll Document Line Var.";
        CalculatePayroll: Report "Suggest Payroll Documents";
        DimMgt: Codeunit DimensionManagement;
        AvailabilityIndex: Boolean;

    [Scope('OnPrem')]
    procedure GetDocumentHeader()
    begin
        if "Document No." <> PayrollDoc."No." then
            PayrollDoc.Get("Document No.");
    end;

    local procedure ConfirmChangeAmount()
    begin
        if Calculate then begin
            if Confirm(Text008) then
                Calculate := false
            else
                Error('');
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
        GetDocumentHeader;
        "Dimension Set ID" :=
          DimMgt.GetDefaultDimID(
            TableID, No, SourceCodeSetup."Payroll Calculation",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code",
            PayrollDoc."Dimension Set ID", DATABASE::Employee);
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
        HROrderCommentLine.SetRange("Table Name", HROrderCommentLine."Table Name"::"Payroll Document");
        HROrderCommentLine.SetRange("No.", "Document No.");
        HROrderCommentLine.SetRange("Line No.", "Line No.");
        HROrderCommentLines.SetTableView(HROrderCommentLine);
        HROrderCommentLines.RunModal;
    end;

    [Scope('OnPrem')]
    procedure ShowCalculation()
    var
        PayrollDocLineCalc: Record "Payroll Document Line Calc.";
        PayrollDocCalcLines: Page "Payroll Document Calc. Lines";
    begin
        TestField("Document No.");
        TestField("Line No.");
        PayrollDocLineCalc.SetRange("Document No.", "Document No.");
        PayrollDocLineCalc.SetRange("Document Line No.", "Line No.");
        PayrollDocCalcLines.SetTableView(PayrollDocLineCalc);
        PayrollDocCalcLines.RunModal;
    end;

    [Scope('OnPrem')]
    procedure ShowAEEntries()
    var
        PayrollDocLine: Record "Payroll Document Line";
        PayrollDocLineAEForm: Page "Payroll Document Line AE";
    begin
        TestField("Document No.");
        TestField("Line No.");
        PayrollDocLine.SetRange("Document No.", "Document No.");
        PayrollDocLine.SetRange("Line No.", "Line No.");
        PayrollDocLineAEForm.SetTableView(PayrollDocLine);
        PayrollDocLineAEForm.RunModal;
    end;

    [Scope('OnPrem')]
    procedure ShowAEPeriods()
    var
        PayrollPeriodAE: Record "Payroll Period AE";
        PayrollPeriodAEForm: Page "Payroll Doc. Line AE Periods";
    begin
        TestField("Document No.");
        TestField("Line No.");
        PayrollPeriodAE.SetRange("Document No.", "Document No.");
        PayrollPeriodAE.SetRange("Line No.", "Line No.");
        PayrollPeriodAEForm.SetDocLine(Rec);
        PayrollPeriodAEForm.SetTableView(PayrollPeriodAE);
        PayrollPeriodAEForm.RunModal;
    end;

    [Scope('OnPrem')]
    procedure CheckDocStatus()
    begin
        GetDocumentHeader;
        PayrollDoc.TestField(Status, PayrollDoc.Status::Open);
    end;
}

