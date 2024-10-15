table 17417 "Posted Payroll Document Line"
{
    Caption = 'Posted Payroll Document Line';

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Posted Payroll Document";
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
        }
        field(14; "Payroll Amount"; Decimal)
        {
            Caption = 'Payroll Amount';
            DecimalPlaces = 2 : 2;
        }
        field(15; "Taxable Amount"; Decimal)
        {
            Caption = 'Taxable Amount';
            DecimalPlaces = 2 : 2;
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
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
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
            Editable = false;
        }
        field(108; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            TableRelation = "Payroll Calendar";
        }
        field(109; "Corr. Amount 2"; Decimal)
        {
            Caption = 'Corr. Amount 2';
            DecimalPlaces = 2 : 2;
        }
        field(110; "Directory Code"; Code[10])
        {
            Caption = 'Directory Code';
        }
        field(111; "Calc Type Code"; Code[20])
        {
            Caption = 'Calc Type Code';
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
        }
        field(123; "AE Period To"; Code[10])
        {
            Caption = 'AE Period To';
            Editable = false;
        }
        field(124; "Print Priority"; Integer)
        {
            Caption = 'Print Priority';
        }
        field(125; Reason; Text[30])
        {
            Caption = 'Reason';
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
            CalcFormula = Sum ("Posted Payroll Doc. Line AE"."Amount for AE" WHERE("Document No." = FIELD("Document No."),
                                                                                   "Document Line No." = FIELD("Line No.")));
            Caption = 'AE Total Earnings';
            Editable = false;
            FieldClass = FlowField;
        }
        field(221; "AE Daily Earnings"; Decimal)
        {
            Caption = 'AE Daily Earnings';
        }
        field(222; "AE Hourly Earnings"; Decimal)
        {
            Caption = 'AE Hourly Earnings';
        }
        field(223; "AE Total Days"; Decimal)
        {
            CalcFormula = Sum ("Posted Payroll Period AE"."Average Days" WHERE("Document No." = FIELD("Document No."),
                                                                               "Line No." = FIELD("Line No.")));
            Caption = 'AE Total Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(224; "AE Total FSI Earnings"; Decimal)
        {
            CalcFormula = Sum ("Posted Payroll Doc. Line AE"."Amount for FSI" WHERE("Document No." = FIELD("Document No."),
                                                                                    "Document Line No." = FIELD("Line No.")));
            Caption = 'AE Total FSI Earnings';
            Editable = false;
            FieldClass = FlowField;
        }
        field(225; "AE Total Earnings Indexed"; Decimal)
        {
            CalcFormula = Sum ("Posted Payroll Doc. Line AE"."Indexed Amount for AE" WHERE("Document No." = FIELD("Document No."),
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
        key(Key2; "Document No.", "Element Type", "Posting Type")
        {
            SumIndexFields = Amount, "Payroll Amount";
        }
        key(Key3; "Document Type", "HR Order No.")
        {
        }
        key(Key4; "Employee No.", "Period Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption, "Document No.", "Line No."));
    end;

    [Scope('OnPrem')]
    procedure ShowComments()
    var
        HROrderCommentLine: Record "HR Order Comment Line";
        HROrderCommentLines: Page "HR Order Comment Lines";
    begin
        HROrderCommentLine.SetRange("Table Name", HROrderCommentLine."Table Name"::"P.Payroll Document");
        HROrderCommentLine.SetRange("No.", "Document No.");
        HROrderCommentLine.SetRange("Line No.", "Line No.");
        HROrderCommentLines.SetTableView(HROrderCommentLine);
        HROrderCommentLines.RunModal;
    end;

    [Scope('OnPrem')]
    procedure ShowCalculation()
    var
        PostedPayrollDocLineCalc: Record "Posted Payroll Doc. Line Calc.";
        PostedPayrDocCalcLines: Page "Posted Payr. Doc. Calc. Lines";
    begin
        TestField("Document No.");
        TestField("Line No.");
        PostedPayrollDocLineCalc.SetRange("Document No.", "Document No.");
        PostedPayrollDocLineCalc.SetRange("Document Line No.", "Line No.");
        PostedPayrDocCalcLines.SetTableView(PostedPayrollDocLineCalc);
        PostedPayrDocCalcLines.RunModal;
    end;

    [Scope('OnPrem')]
    procedure ShowAEEntries()
    var
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
        PostedPayrollDocLineAEForm: Page "Posted Payroll Doc. Line AE";
    begin
        TestField("Document No.");
        TestField("Line No.");
        PostedPayrollDocLine.SetRange("Document No.", "Document No.");
        PostedPayrollDocLine.SetRange("Line No.", "Line No.");
        PostedPayrollDocLineAEForm.SetTableView(PostedPayrollDocLine);
        PostedPayrollDocLineAEForm.RunModal;
    end;

    [Scope('OnPrem')]
    procedure ShowAEPeriods()
    var
        PostedPayrollPeriodAE: Record "Posted Payroll Period AE";
        PostedPayrDocLineAEPer: Page "Posted Payr. Doc. Line AE Per.";
    begin
        TestField("Document No.");
        TestField("Line No.");
        PostedPayrollPeriodAE.SetRange("Document No.", "Document No.");
        PostedPayrollPeriodAE.SetRange("Line No.", "Line No.");
        PostedPayrDocLineAEPer.SetDocLine(Rec);
        PostedPayrDocLineAEPer.SetTableView(PostedPayrollPeriodAE);
        PostedPayrDocLineAEPer.RunModal;
    end;
}

