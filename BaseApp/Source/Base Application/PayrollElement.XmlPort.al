xmlport 17400 "Payroll Element"
{
    Caption = 'Payroll Element';

    schema
    {
        textelement(PayrollElements)
        {
            tableelement("payroll element"; "Payroll Element")
            {
                XmlName = 'PayrollElement';
                UseTemporary = true;
                fieldelement(Code; "Payroll Element".Code)
                {
                }
                fieldelement(Type; "Payroll Element".Type)
                {
                }
                fieldelement(ElementGroup; "Payroll Element"."Element Group")
                {
                }
                fieldelement(Description; "Payroll Element".Description)
                {
                }
                fieldelement(GenPostType; "Payroll Element"."Posting Type")
                {
                }
                fieldelement(PayrollPostingGroup; "Payroll Element"."Payroll Posting Group")
                {
                }
                fieldelement(DirectoryCode; "Payroll Element"."Directory Code")
                {
                }
                fieldelement(Calculate; "Payroll Element".Calculate)
                {
                }
                fieldelement(NormalSign; "Payroll Element"."Normal Sign")
                {
                }
                fieldelement(FSIBase; "Payroll Element"."FSI Base")
                {
                }
                fieldelement(FedFMIBase; "Payroll Element"."Federal FMI Base")
                {
                }
                fieldelement(TerFMIBase; "Payroll Element"."Territorial FMI Base")
                {
                }
                fieldelement(PensionFundBase; "Payroll Element"."PF Base")
                {
                }
                fieldelement(IncomeTaxBase; "Payroll Element"."Income Tax Base")
                {
                }
                fieldelement(FSIInjuryBase; "Payroll Element"."FSI Injury Base")
                {
                }
                fieldelement(PayType; "Payroll Element"."Pay Type")
                {
                }
                fieldelement(SourcePay; "Payroll Element"."Source Pay")
                {
                }
                fieldelement(BonusType; "Payroll Element"."Bonus Type")
                {
                }
                fieldelement(SalaryIndexation; "Payroll Element"."Use Indexation")
                {
                }
                fieldelement(DependsOnSalary; "Payroll Element"."Depends on Salary Element")
                {
                }
                fieldelement(DistributeByPeriods; "Payroll Element"."Distribute by Periods")
                {
                }
                fieldelement(IncludeCalculationBy; "Payroll Element"."Include into Calculation by")
                {
                }
                fieldelement(GlobalDimension1Code; "Payroll Element"."Global Dimension 1 Code")
                {
                }
                fieldelement(GlobalDimension2Code; "Payroll Element"."Global Dimension 2 Code")
                {
                }
                tableelement("element dimension"; "Default Dimension")
                {
                    LinkFields = "No." = FIELD(Code);
                    LinkTable = "Payroll Element";
                    MinOccurs = Zero;
                    XmlName = 'Dimensions';
                    SourceTableView = WHERE("Table ID" = CONST(17400));
                    UseTemporary = true;
                    fieldelement(ElementCode; "Element Dimension"."No.")
                    {
                    }
                    fieldelement(Code; "Element Dimension"."Dimension Code")
                    {
                    }
                    fieldelement(ValueCode; "Element Dimension"."Dimension Value Code")
                    {
                    }
                    fieldelement(ValuePosting; "Element Dimension"."Value Posting")
                    {
                    }
                }
                tableelement("payroll range header"; "Payroll Range Header")
                {
                    LinkFields = "Element Code" = FIELD(Code);
                    LinkTable = "Payroll Element";
                    MinOccurs = Zero;
                    XmlName = 'RangeHeader';
                    UseTemporary = true;
                    fieldelement(Code; "Payroll Range Header".Code)
                    {
                    }
                    fieldelement(Description; "Payroll Range Header".Description)
                    {
                    }
                    fieldelement(ElementCode; "Payroll Range Header"."Element Code")
                    {
                    }
                    fieldelement(RangeType; "Payroll Range Header"."Range Type")
                    {
                    }
                    fieldelement(PeriodCode; "Payroll Range Header"."Period Code")
                    {
                    }
                    fieldelement(AllowEmployeeGender; "Payroll Range Header"."Allow Employee Gender")
                    {
                    }
                    fieldelement(AllowEmployeeAge; "Payroll Range Header"."Allow Employee Age")
                    {
                    }
                    fieldelement(ConsiderRelative; "Payroll Range Header"."Consider Relative")
                    {
                    }
                    tableelement("payroll range line"; "Payroll Range Line")
                    {
                        LinkFields = "Element Code" = FIELD("Element Code"), "Range Code" = FIELD(Code), "Period Code" = FIELD("Period Code");
                        LinkTable = "Payroll Range Header";
                        MinOccurs = Zero;
                        XmlName = 'RangeLine';
                        UseTemporary = true;
                        fieldelement(LineNo; "Payroll Range Line"."Line No.")
                        {
                        }
                        fieldelement(RangeCode; "Payroll Range Line"."Range Code")
                        {
                        }
                        fieldelement(ElementCode; "Payroll Range Line"."Element Code")
                        {
                        }
                        fieldelement(PeriodCode; "Payroll Range Line"."Period Code")
                        {
                        }
                        fieldelement(RangeType; "Payroll Range Line"."Range Type")
                        {
                        }
                        textelement(OverAmount)
                        {
                        }
                        textelement(Limit)
                        {
                        }
                        textelement(TaxProc)
                        {
                        }
                        textelement(Percent)
                        {
                        }
                        textelement(Quantity)
                        {
                        }
                        textelement(TaxAmount)
                        {
                        }
                        textelement(Amount)
                        {
                        }
                        textelement(IncreaseWage)
                        {
                        }
                        textelement(MaxDeduction)
                        {
                        }
                        textelement(MinAmount)
                        {
                        }
                        textelement(MaxAmount)
                        {
                        }
                        fieldelement(OnAllowance; "Payroll Range Line"."On Allowance")
                        {
                        }
                        fieldelement(FromAllowance; "Payroll Range Line"."From Allowance")
                        {
                        }
                        textelement(CoordinationProc)
                        {
                        }
                        textelement(MaxProc)
                        {
                        }
                        fieldelement(DirectoryCode; "Payroll Range Line"."Directory Code")
                        {
                        }
                        fieldelement(EmployeeGender; "Payroll Range Line"."Employee Gender")
                        {
                        }
                        fieldelement(FromBirthdayandYounger; "Payroll Range Line"."From Birthday and Younger")
                        {
                        }
                        textelement(Age)
                        {
                        }
                        fieldelement(DisabledPerson; "Payroll Range Line"."Disabled Person")
                        {
                        }
                        fieldelement(Student; "Payroll Range Line".Student)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            OverAmount := Format("Payroll Range Line"."Over Amount", 0, 1);
                            Limit := Format("Payroll Range Line".Limit, 0, 1);
                            TaxProc := Format("Payroll Range Line"."Tax %", 0, 1);
                            Percent := Format("Payroll Range Line".Percent, 0, 1);
                            Quantity := Format("Payroll Range Line".Quantity, 0, 1);
                            TaxAmount := Format("Payroll Range Line"."Tax Amount", 0, 1);
                            Amount := Format("Payroll Range Line".Amount, 0, 1);
                            IncreaseWage := Format("Payroll Range Line"."Increase Wage", 0, 1);
                            MaxDeduction := Format("Payroll Range Line"."Max Deduction", 0, 1);
                            MinAmount := Format("Payroll Range Line"."Min Amount", 0, 1);
                            MaxAmount := Format("Payroll Range Line"."Max Amount", 0, 1);
                            CoordinationProc := Format("Payroll Range Line"."Coordination %", 0, 1);
                            MaxProc := Format("Payroll Range Line"."Max %", 0, 1);
                            Age := Format("Payroll Range Line".Age, 0, 1);
                        end;

                        trigger OnBeforeInsertRecord()
                        begin
                            Evaluate("Payroll Range Line"."Over Amount", OverAmount);
                            Evaluate("Payroll Range Line".Limit, Limit);
                            Evaluate("Payroll Range Line"."Tax %", TaxProc);
                            Evaluate("Payroll Range Line".Percent, Percent);
                            Evaluate("Payroll Range Line".Quantity, Quantity);
                            Evaluate("Payroll Range Line"."Tax Amount", TaxAmount);
                            Evaluate("Payroll Range Line".Amount, Amount);
                            Evaluate("Payroll Range Line"."Increase Wage", IncreaseWage);
                            Evaluate("Payroll Range Line"."Max Deduction", MaxDeduction);
                            Evaluate("Payroll Range Line"."Min Amount", MinAmount);
                            Evaluate("Payroll Range Line"."Max Amount", MaxAmount);
                            Evaluate("Payroll Range Line"."Coordination %", CoordinationProc);
                            Evaluate("Payroll Range Line"."Max %", MaxProc);
                            Evaluate("Payroll Range Line".Age, Age);
                        end;
                    }
                }
                tableelement("payroll base amount"; "Payroll Base Amount")
                {
                    LinkFields = "Element Code" = FIELD(Code);
                    LinkTable = "Payroll Element";
                    MinOccurs = Zero;
                    XmlName = 'BaseAmounts';
                    UseTemporary = true;
                    fieldelement(ElementCode; "Payroll Base Amount"."Element Code")
                    {
                    }
                    fieldelement(Code; "Payroll Base Amount".Code)
                    {
                    }
                    fieldelement(Description; "Payroll Base Amount".Description)
                    {
                    }
                    fieldelement(ElementCodeFilter; "Payroll Base Amount"."Element Code Filter")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ElementTypeFilter; "Payroll Base Amount"."Element Type Filter")
                    {
                    }
                    fieldelement(ElementGroupFilter; "Payroll Base Amount"."Element Group Filter")
                    {
                    }
                    fieldelement(GenPostTypeFilter; "Payroll Base Amount"."Posting Type Filter")
                    {
                    }
                    fieldelement(IncomeTaxBaseFilter; "Payroll Base Amount"."Income Tax Base Filter")
                    {
                    }
                    fieldelement(PFBaseFilter; "Payroll Base Amount"."PF Base Filter")
                    {
                    }
                    fieldelement(FSIBaseFilter; "Payroll Base Amount"."FSI Base Filter")
                    {
                    }
                    fieldelement(FederalFMIBaseFilter; "Payroll Base Amount"."Federal FMI Base Filter")
                    {
                    }
                    fieldelement(TerritorialFMIBaseFilter; "Payroll Base Amount"."Territorial FMI Base Filter")
                    {
                    }
                    fieldelement(FSIInjuryBaseFilter; "Payroll Base Amount"."FSI Injury Base Filter")
                    {
                    }
                }
                tableelement("payroll calculation"; "Payroll Calculation")
                {
                    LinkFields = "Element Code" = FIELD(Code);
                    LinkTable = "Payroll Element";
                    MinOccurs = Zero;
                    XmlName = 'Calculation';
                    UseTemporary = true;
                    fieldelement(ElementCode; "Payroll Calculation"."Element Code")
                    {
                    }
                    fieldelement(Description; "Payroll Calculation".Description)
                    {
                    }
                    fieldelement(PeriodCode; "Payroll Calculation"."Period Code")
                    {

                        trigger OnAfterAssignField()
                        begin
                            PayrollCalculation := "Payroll Calculation";
                        end;
                    }
                    tableelement("payroll calculation line"; "Payroll Calculation Line")
                    {
                        LinkFields = "Element Code" = FIELD("Element Code"), "Period Code" = FIELD("Period Code");
                        LinkTable = "Payroll Calculation";
                        XmlName = 'CalculationLine';
                        UseTemporary = true;
                        fieldelement(ElementCode; "Payroll Calculation Line"."Element Code")
                        {
                        }
                        fieldelement(PeriodCode; "Payroll Calculation Line"."Period Code")
                        {
                        }
                        fieldelement(LineNo; "Payroll Calculation Line"."Line No.")
                        {
                        }
                        fieldelement(FunctionCode; "Payroll Calculation Line"."Function Code")
                        {
                        }
                        fieldelement(RangeType; "Payroll Calculation Line"."Range Type")
                        {
                        }
                        fieldelement(RangeCode; "Payroll Calculation Line"."Range Code")
                        {
                        }
                        fieldelement(BaseAmountCode; "Payroll Calculation Line"."Base Amount Code")
                        {
                        }
                        fieldelement(TimeActivityGroup; "Payroll Calculation Line"."Time Activity Group")
                        {
                        }
                        fieldelement(Variable; "Payroll Calculation Line".Variable)
                        {
                        }
                        fieldelement(Expression; "Payroll Calculation Line".Expression)
                        {
                        }
                        fieldelement(ResultFieldNo; "Payroll Calculation Line"."Result Field No.")
                        {
                        }
                        fieldelement(Statement1; "Payroll Calculation Line"."Statement 1")
                        {
                        }
                        fieldelement(Statement2; "Payroll Calculation Line"."Statement 2")
                        {
                        }
                        fieldelement(Label; "Payroll Calculation Line".Label)
                        {
                        }
                        fieldelement(Description; "Payroll Calculation Line".Description)
                        {
                        }
                        fieldelement(RoundingPrecision; "Payroll Calculation Line"."Rounding Precision")
                        {
                        }
                        fieldelement(RoundingType; "Payroll Calculation Line"."Rounding Type")
                        {
                        }
                        tableelement("payroll element expression"; "Payroll Element Expression")
                        {
                            LinkFields = "Element Code" = FIELD("Element Code"), "Period Code" = FIELD("Period Code"), "Calculation Line No." = FIELD("Line No.");
                            LinkTable = "Payroll Calculation Line";
                            MinOccurs = Zero;
                            XmlName = 'ExpressionLine';
                            UseTemporary = true;
                            fieldelement(ElementCode; "Payroll Element Expression"."Element Code")
                            {
                            }
                            fieldelement(PeriodCode; "Payroll Element Expression"."Period Code")
                            {
                            }
                            fieldelement(CalcLineNo; "Payroll Element Expression"."Calculation Line No.")
                            {
                            }
                            fieldelement(Level; "Payroll Element Expression".Level)
                            {
                            }
                            fieldelement(ParentLineNo; "Payroll Element Expression"."Parent Line No.")
                            {
                            }
                            fieldelement(LineNo; "Payroll Element Expression"."Line No.")
                            {
                            }
                            fieldelement(Comparison; "Payroll Element Expression".Comparison)
                            {
                            }
                            fieldelement(Type; "Payroll Element Expression".Type)
                            {
                            }
                            fieldelement(TableNo; "Payroll Element Expression"."Table No.")
                            {
                            }
                            fieldelement(FieldNo; "Payroll Element Expression"."Field No.")
                            {
                            }
                            fieldelement(Expression; "Payroll Element Expression".Expression)
                            {
                            }
                            fieldelement(Operator; "Payroll Element Expression".Operator)
                            {
                            }
                            fieldelement(LeftBracket; "Payroll Element Expression"."Left Bracket")
                            {
                            }
                            fieldelement(RightBracket; "Payroll Element Expression"."Right Bracket")
                            {
                            }
                            fieldelement(SourceTable; "Payroll Element Expression"."Source Table")
                            {
                            }
                            fieldelement(Variable; "Payroll Element Expression"."Assign to Variable")
                            {
                            }
                            fieldelement(RoundingPrecision; "Payroll Element Expression"."Rounding Precision")
                            {
                            }
                            fieldelement(RoundingType; "Payroll Element Expression"."Rounding Type")
                            {
                            }
                            fieldelement(AssigntoFieldNo; "Payroll Element Expression"."Assign to Field No.")
                            {
                            }
                            fieldelement(Description; "Payroll Element Expression".Description)
                            {
                            }
                            fieldelement(LogicalSuffix; "Payroll Element Expression"."Logical Suffix")
                            {
                            }
                            fieldelement(LogicalPrefix; "Payroll Element Expression"."Logical Prefix")
                            {
                            }
                        }
                    }
                }
                tableelement("payroll element variable"; "Payroll Element Variable")
                {
                    LinkFields = "Element Code" = FIELD(Code);
                    LinkTable = "Payroll Element";
                    MinOccurs = Zero;
                    XmlName = 'Variables';
                    UseTemporary = true;
                    fieldelement(Variable; "Payroll Element Variable".Variable)
                    {
                    }

                    trigger OnBeforeInsertRecord()
                    begin
                        "Payroll Element Variable"."Element Code" := PayrollCalculation."Element Code";
                        "Payroll Element Variable"."Period Code" := PayrollCalculation."Period Code";
                    end;
                }
            }
            tableelement("payroll element group"; "Payroll Element Group")
            {
                MinOccurs = Zero;
                XmlName = 'PayrollElementGroup';
                UseTemporary = true;
                fieldelement(Code; "Payroll Element Group".Code)
                {
                }
                fieldelement(Name; "Payroll Element Group".Name)
                {
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    var
        PayrollElementGroup: Record "Payroll Element Group";
        PayrollElement: Record "Payroll Element";
        PayrollBaseAmount: Record "Payroll Base Amount";
        PayrollCalculation: Record "Payroll Calculation";
        PayrollCalculationLine: Record "Payroll Calculation Line";
        PayrollElementExpression: Record "Payroll Element Expression";
        PayrollElementVariable: Record "Payroll Element Variable";
        PayrollRangeHeader: Record "Payroll Range Header";
        PayrollRangeLine: Record "Payroll Range Line";
        DefaultDimension: Record "Default Dimension";

    [Scope('OnPrem')]
    procedure SetData(var SourcePayrollElement: Record "Payroll Element")
    begin
        if SourcePayrollElement.FindSet then
            repeat
                "Payroll Element" := SourcePayrollElement;
                "Payroll Element".Insert();

                DefaultDimension.SetRange("Table ID", DATABASE::"Payroll Element");
                DefaultDimension.SetRange("No.", SourcePayrollElement.Code);
                if DefaultDimension.FindSet then
                    repeat
                        "Element Dimension" := DefaultDimension;
                        "Element Dimension".Insert();
                    until DefaultDimension.Next() = 0;

                PayrollBaseAmount.SetRange("Element Code", SourcePayrollElement.Code);
                if PayrollBaseAmount.FindSet then
                    repeat
                        "Payroll Base Amount" := PayrollBaseAmount;
                        "Payroll Base Amount".Insert();
                    until PayrollBaseAmount.Next() = 0;

                PayrollRangeHeader.SetRange("Element Code", SourcePayrollElement.Code);
                if PayrollRangeHeader.FindSet then
                    repeat
                        "Payroll Range Header" := PayrollRangeHeader;
                        "Payroll Range Header".Insert();

                        PayrollRangeLine.SetRange("Element Code", PayrollRangeHeader."Element Code");
                        PayrollRangeLine.SetRange("Range Code", PayrollRangeHeader.Code);
                        PayrollRangeLine.SetRange("Period Code", PayrollRangeHeader."Period Code");
                        if PayrollRangeLine.FindSet then
                            repeat
                                "Payroll Range Line" := PayrollRangeLine;
                                "Payroll Range Line".Insert();
                            until PayrollRangeLine.Next() = 0;
                    until PayrollRangeHeader.Next() = 0;

                PayrollCalculation.SetRange("Element Code", SourcePayrollElement.Code);
                if PayrollCalculation.FindSet then
                    repeat
                        "Payroll Calculation" := PayrollCalculation;
                        "Payroll Calculation".Insert();

                        PayrollCalculationLine.SetRange("Element Code", PayrollCalculation."Element Code");
                        PayrollCalculationLine.SetRange("Period Code", PayrollCalculation."Period Code");
                        if PayrollCalculationLine.FindSet then
                            repeat
                                "Payroll Calculation Line" := PayrollCalculationLine;
                                "Payroll Calculation Line".Insert();

                                PayrollElementExpression.SetRange("Element Code", PayrollCalculationLine."Element Code");
                                PayrollElementExpression.SetRange("Period Code", PayrollCalculationLine."Period Code");
                                PayrollElementExpression.SetRange("Calculation Line No.", PayrollCalculationLine."Line No.");
                                if PayrollElementExpression.FindSet then
                                    repeat
                                        "Payroll Element Expression" := PayrollElementExpression;
                                        "Payroll Element Expression".Insert();
                                    until PayrollElementExpression.Next() = 0;
                            until PayrollCalculationLine.Next() = 0;
                    until PayrollCalculation.Next() = 0;

                PayrollElementVariable.SetRange("Element Code", SourcePayrollElement.Code);
                if PayrollElementVariable.FindSet then
                    repeat
                        "Payroll Element Variable" := PayrollElementVariable;
                        "Payroll Element Variable".Insert();
                    until PayrollElementVariable.Next() = 0;

                if SourcePayrollElement."Element Group" <> '' then
                    if not "Payroll Element Group".Get(SourcePayrollElement."Element Group") then begin
                        PayrollElementGroup.Get(SourcePayrollElement."Element Group");
                        "Payroll Element Group" := PayrollElementGroup;
                        "Payroll Element Group".Insert();
                    end;
            until SourcePayrollElement.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportData()
    begin
        "Payroll Element".Reset();
        if "Payroll Element".FindSet then
            repeat
                if PayrollElement.Get("Payroll Element".Code) then
                    PayrollElement.Delete(true);
                PayrollElement := "Payroll Element";
                PayrollElement.Insert();
            until "Payroll Element".Next() = 0;

        "Element Dimension".Reset();
        if "Element Dimension".FindSet then
            repeat
                if DefaultDimension.Get(
                     DATABASE::"Payroll Element",
                     "Element Dimension"."No.",
                     "Element Dimension"."Dimension Code")
                then
                    DefaultDimension.Delete(true);
                DefaultDimension := "Element Dimension";
                DefaultDimension.Insert();
            until "Element Dimension".Next() = 0;

        "Payroll Base Amount".Reset();
        if "Payroll Base Amount".FindSet then
            repeat
                if PayrollBaseAmount.Get("Payroll Base Amount"."Element Code", "Payroll Base Amount".Code) then
                    PayrollBaseAmount.Delete(true);
                PayrollBaseAmount := "Payroll Base Amount";
                PayrollBaseAmount.Insert();
            until "Payroll Base Amount".Next() = 0;

        "Payroll Range Header".Reset();
        if "Payroll Range Header".FindSet then
            repeat
                if PayrollRangeHeader.Get(
                     "Payroll Range Header"."Element Code",
                     "Payroll Range Header".Code,
                     "Payroll Range Header"."Period Code")
                then
                    PayrollRangeHeader.Delete(true);
                PayrollRangeHeader := "Payroll Range Header";
                PayrollRangeHeader.Insert();
            until "Payroll Range Header".Next() = 0;

        "Payroll Range Line".Reset();
        if "Payroll Range Line".FindSet then
            repeat
                if PayrollRangeLine.Get(
                     "Payroll Range Line"."Element Code", "Payroll Range Line"."Range Code",
                     "Payroll Range Line"."Period Code", "Payroll Range Line"."Line No.")
                then
                    PayrollRangeLine.Delete(true);
                PayrollRangeLine := "Payroll Range Line";
                PayrollRangeLine.Insert();
            until "Payroll Range Line".Next() = 0;

        "Payroll Calculation".Reset();
        if "Payroll Calculation".FindSet then
            repeat
                if PayrollCalculation.Get("Payroll Calculation"."Element Code", "Payroll Calculation"."Period Code") then
                    "Payroll Calculation".Delete(true);
                PayrollCalculation := "Payroll Calculation";
                PayrollCalculation.Insert();
            until "Payroll Calculation".Next() = 0;

        "Payroll Calculation Line".Reset();
        if "Payroll Calculation Line".FindSet then
            repeat
                if PayrollCalculationLine.Get(
                     "Payroll Calculation Line"."Element Code",
                     "Payroll Calculation Line"."Period Code",
                     "Payroll Calculation Line"."Line No.")
                then
                    PayrollCalculationLine.Delete(true);
                PayrollCalculationLine := "Payroll Calculation Line";
                PayrollCalculationLine.Insert();
            until "Payroll Calculation Line".Next() = 0;

        "Payroll Element Expression".Reset();
        if "Payroll Element Expression".FindSet then
            repeat
                if PayrollElementExpression.Get(
                     "Payroll Element Expression"."Element Code",
                     "Payroll Element Expression"."Period Code",
                     "Payroll Element Expression"."Calculation Line No.",
                     "Payroll Element Expression"."Line No.")
                then
                    PayrollElementExpression.Delete(true);
                PayrollElementExpression := "Payroll Element Expression";
                PayrollElementExpression.Insert();
            until "Payroll Element Expression".Next() = 0;

        "Payroll Element Variable".Reset();
        if "Payroll Element Variable".FindSet then
            repeat
                if PayrollElementVariable.Get(
                     "Payroll Element Variable"."Element Code",
                     "Payroll Element Variable"."Period Code",
                     "Payroll Element Variable".Variable)
                then
                    PayrollElementVariable.Delete(true);
                PayrollElementVariable := "Payroll Element Variable";
                PayrollElementVariable.Insert();
            until "Payroll Element Variable".Next() = 0;

        "Payroll Element Group".Reset();
        if "Payroll Element Group".FindSet then
            repeat
                if PayrollElementGroup.Get("Payroll Element Group".Code) then
                    PayrollElementGroup.Delete(true);
                PayrollElementGroup := "Payroll Element Group";
                PayrollElementGroup.Insert();
            until "Payroll Element Group".Next() = 0;
    end;
}

