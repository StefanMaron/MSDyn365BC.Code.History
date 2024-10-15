codeunit 17404 "Payroll Document - Calculate"
{
    TableNo = "Payroll Document Line";

    trigger OnRun()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Calculated: Boolean;
        Execute: Boolean;
        ConditionIsTrue: Option " ","FALSE","TRUE";
        BlockType: Option " ","THEN","ELSE";
        GotoFlag: Boolean;
        IFQty: Integer;
        ENDIFQty: Integer;
    begin
        TestField("Element Code");
        TestField("Period Code");

        HumanResourcesSetup.Get;

        // initialize journal line amount
        "Payroll Amount" := 0;
        "Taxable Amount" := 0;
        "Corr. Amount" := 0;
        "Corr. Amount 2" := 0;
        "Planned Days" := 0;
        "Planned Hours" := 0;
        "Actual Days" := 0;
        "Actual Hours" := 0;
        "AE Daily Earnings" := 0;

        CurrCode := '';
        PositCode := '';
        DepartCode := '';
        SavedValue := 0;
        HaveEmplLedgEntry := false;
        StopCalc := false;
        Exception := false;

        Clear(StartDate);
        Clear(EndDate);

        if not Calculate then   // NOTE:  this should never happen, but...
            exit;

        PayrollElement.Get("Element Code");
        if "Employee Ledger Entry No." <> 0 then begin
            EmplLedgEntry.Get("Employee Ledger Entry No.");
            HaveEmplLedgEntry := true;
        end;

        InitPayrollPeriod("Period Code", "Wage Period From");

        PayrollCalculation.Reset;
        PayrollCalculation.SetRange("Element Code", "Element Code");
        PayrollCalculation.SetRange("Period Code", FirstPayrollPeriod.Code, "Period Code");
        if PayrollCalculation.FindLast then begin
            RemoveCalculations(Rec);
            PrepareCalculations(Rec, PayrollCalculation);

            // calculation start
            PayrollDocLineCalc.Reset;
            PayrollDocLineCalc.SetRange("Document No.", "Document No.");
            PayrollDocLineCalc.SetRange("Document Line No.", "Line No.");

            // check qty of IF and ENDIF
            PayrollDocLineCalc.SetRange(
              "Statement 1", PayrollDocLineCalc."Statement 1"::"IF");
            IFQty := PayrollDocLineCalc.Count;
            PayrollDocLineCalc.SetRange(
              "Statement 1", PayrollDocLineCalc."Statement 1"::ENDIF);
            ENDIFQty := PayrollDocLineCalc.Count;
            if IFQty <> ENDIFQty then
                Error(Text063);

            PayrollDocLineCalc.SetRange("Statement 1");
            PayrollDocLineCalc.Find('-');

            // Find statement type
            Calculated := false;
            while not Calculated do
                // Calculate step first
                if PayrollCalcFunction.Get(PayrollDocLineCalc."Function Code") then begin
                    CalculateFunction(Rec, PayrollCalcFunction."Function No.",
                      PayrollDocLineCalc."Result Value", PayrollDocLineCalc."Result Flag");

                    if PayrollDocLineCalc.Variable <> '' then begin
                        if PayrollDocLineVar.Get(
                             "Document No.", "Line No.", PayrollDocLineCalc.Variable)
                        then begin
                            PayrollDocLineVar.Value := PayrollDocLineCalc.Rounding(PayrollDocLineCalc."Result Value");
                            PayrollDocLineVar.Calculated := true;
                            PayrollDocLineVar.Error := false;
                            PayrollDocLineVar.Modify;
                        end else begin
                            PayrollDocLineVar.Init;
                            PayrollDocLineVar."Document No." := "Document No.";
                            PayrollDocLineVar."Document Line No." := "Line No.";
                            PayrollDocLineVar."Line No." := PayrollDocLineCalc."Line No.";
                            PayrollDocLineVar.Variable := PayrollDocLineCalc.Variable;
                            PayrollDocLineVar.Value := PayrollDocLineCalc.Rounding(PayrollDocLineCalc."Result Value");
                            PayrollDocLineVar.Calculated := true;
                            PayrollDocLineVar.Error := false;
                            PayrollDocLineVar.Insert;
                        end;
                        ExprMgt.CheckStops(PayrollDocLineVar);
                    end;

                    if PayrollDocLineCalc."Result Field No." <> 0 then begin
                        RecRef.Open(DATABASE::"Payroll Document Line");
                        RecRef.GetTable(Rec);
                        FldRef := RecRef.Field(PayrollDocLineCalc."Result Field No.");
                        FldRef.Value(
                          PayrollDocLineCalc.Rounding(
                            PayrollDocLineCalc."Result Value"));
                        RecRef.SetTable(Rec);
                        RecRef.Modify;
                        RecRef.Close;
                        Find;
                    end;

                    PayrollDocLineCalc."No. of Runs" += 1;
                    PayrollDocLineCalc.Modify;
                    if PayrollDocLineCalc.Next = 0 then
                        Calculated := true;
                end else begin
                    // Execute statement if
                    // 1. No block
                    // 2. If Block = THEN and Cond = TRUE
                    // 3. If Block = ELSE and Cond = FALSE

                    // Set Block
                    case PayrollDocLineCalc."Statement 1" of
                        PayrollDocLineCalc."Statement 1"::"IF":
                            BlockType := BlockType::" ";
                        PayrollDocLineCalc."Statement 1"::"THEN":
                            BlockType := BlockType::"THEN";
                        PayrollDocLineCalc."Statement 1"::"ELSE":
                            BlockType := BlockType::"ELSE";
                        PayrollDocLineCalc."Statement 1"::ENDIF:
                            BlockType := BlockType::" ";
                    end;
                    PayrollDocLineCalc."Logical Result" := 0;
                    PayrollDocLineCalc."Result Value" := 0;

                    Execute := false;
                    if (BlockType = BlockType::" ") or
                       ((BlockType = BlockType::"THEN") and
                        (ConditionIsTrue = ConditionIsTrue::"TRUE")) or
                       ((BlockType = BlockType::"ELSE") and
                        (ConditionIsTrue = ConditionIsTrue::"FALSE"))
                    then
                        Execute := true;
                    if Execute then begin
                        // parse Statement 1
                        case PayrollDocLineCalc."Statement 1" of
                            PayrollDocLineCalc."Statement 1"::" ":
                                begin
                                    case PayrollDocLineCalc."Statement 2" of
                                        PayrollDocLineCalc."Statement 2"::" ":
                                            ExprMgt.EvaluateExpr(
                                              Rec, PayrollDocLineCalc, PayrollDocLineVar,
                                              PayrollDocLineCalc.Expression, 0, 0,
                                              PayrollDocLineCalc."Result Value",
                                              PayrollDocLineCalc."Logical Result");
                                        PayrollDocLineCalc."Statement 2"::MIN,
                                      PayrollDocLineCalc."Statement 2"::MAX,
                                      PayrollDocLineCalc."Statement 2"::ABS,
                                      PayrollDocLineCalc."Statement 2"::ROUND:
                                            ExprMgt.EvaluateExpr(
                                              Rec, PayrollDocLineCalc, PayrollDocLineVar,
                                              PayrollDocLineCalc.Expression, 0, 0,
                                              PayrollDocLineCalc."Result Value",
                                              PayrollDocLineCalc."Logical Result");
                                        PayrollDocLineCalc."Statement 2"::GOTO:
                                            begin
                                                GotoLabel(PayrollDocLineCalc);
                                                GotoFlag := true;
                                            end;
                                        PayrollDocLineCalc."Statement 2"::STOP:
                                            Calculated := true;
                                    end;
                                    PayrollDocLineCalc."No. of Runs" += 1;
                                end;
                            PayrollDocLineCalc."Statement 1"::"IF": // IF
                                begin
                                    PayrollDocLineCalc.TestField("Statement 2", 0);
                                    ExprMgt.EvaluateExpr(
                                      Rec, PayrollDocLineCalc, PayrollDocLineVar,
                                      PayrollDocLineCalc.Expression, 0, 0,
                                      PayrollDocLineCalc."Result Value",
                                      PayrollDocLineCalc."Logical Result");
                                    ConditionIsTrue := PayrollDocLineCalc."Logical Result";
                                    PayrollDocLineCalc."No. of Runs" += 1;
                                end;
                            PayrollDocLineCalc."Statement 1"::"THEN": // THEN
                                if ConditionIsTrue = ConditionIsTrue::"TRUE" then begin
                                    BlockType := BlockType::"THEN";
                                    case PayrollDocLineCalc."Statement 2" of
                                        PayrollDocLineCalc."Statement 2"::" ":
                                            if PayrollDocLineCalc.Expression <> '' then begin
                                                ExprMgt.EvaluateExpr(
                                                  Rec, PayrollDocLineCalc, PayrollDocLineVar,
                                                  PayrollDocLineCalc.Expression, 0, 0,
                                                  PayrollDocLineCalc."Result Value",
                                                  PayrollDocLineCalc."Logical Result");
                                                PayrollDocLineCalc."No. of Runs" += 1;
                                            end;
                                        PayrollDocLineCalc."Statement 2"::MIN,
                                        PayrollDocLineCalc."Statement 2"::MAX,
                                        PayrollDocLineCalc."Statement 2"::ABS,
                                        PayrollDocLineCalc."Statement 2"::ROUND:
                                            begin
                                                ExprMgt.EvaluateExpr(
                                                  Rec, PayrollDocLineCalc, PayrollDocLineVar,
                                                  PayrollDocLineCalc.Expression, 0, 0,
                                                  PayrollDocLineCalc."Result Value",
                                                  PayrollDocLineCalc."Logical Result");
                                                PayrollDocLineCalc."No. of Runs" += 1;
                                            end;
                                        PayrollDocLineCalc."Statement 2"::GOTO:
                                            begin
                                                GotoLabel(PayrollDocLineCalc);
                                                GotoFlag := true;
                                            end;
                                        PayrollDocLineCalc."Statement 2"::STOP:
                                            Calculated := true;
                                    end;
                                end;
                            PayrollDocLineCalc."Statement 1"::"ELSE": // ELSE
                                if ConditionIsTrue = ConditionIsTrue::"FALSE" then begin
                                    BlockType := BlockType::"ELSE";
                                    case PayrollDocLineCalc."Statement 2" of
                                        PayrollDocLineCalc."Statement 2"::" ":
                                            if PayrollDocLineCalc.Expression <> '' then begin
                                                ExprMgt.EvaluateExpr(
                                                  Rec, PayrollDocLineCalc, PayrollDocLineVar,
                                                  PayrollDocLineCalc.Expression, 0, 0,
                                                  PayrollDocLineCalc."Result Value",
                                                  PayrollDocLineCalc."Logical Result");
                                                PayrollDocLineCalc."No. of Runs" += 1;
                                            end;
                                        PayrollDocLineCalc."Statement 2"::MIN,
                                        PayrollDocLineCalc."Statement 2"::MAX,
                                        PayrollDocLineCalc."Statement 2"::ABS,
                                        PayrollDocLineCalc."Statement 2"::ROUND:
                                            begin
                                                ExprMgt.EvaluateExpr(
                                                  Rec, PayrollDocLineCalc, PayrollDocLineVar,
                                                  PayrollDocLineCalc.Expression, 0, 0,
                                                  PayrollDocLineCalc."Result Value",
                                                  PayrollDocLineCalc."Logical Result");
                                                PayrollDocLineCalc."No. of Runs" += 1;
                                            end;
                                        PayrollDocLineCalc."Statement 2"::GOTO:
                                            begin
                                                GotoLabel(PayrollDocLineCalc);
                                                GotoFlag := true;
                                            end;
                                        PayrollDocLineCalc."Statement 2"::STOP:
                                            Calculated := true;
                                    end;
                                end;
                            PayrollDocLineCalc."Statement 1"::ENDIF: // ENDIF
                                begin
                                    ConditionIsTrue := 0;
                                    BlockType := 0;
                                    PayrollDocLineCalc."No. of Runs" += 1;
                                end;
                        end;
                        PayrollDocLineCalc.Modify;

                        // Save result of expression calculation
                        if PayrollDocLineCalc.Variable <> '' then begin
                            if PayrollDocLineVar.Get(
                                 "Document No.", "Line No.", PayrollDocLineCalc.Variable)
                            then begin
                                PayrollDocLineVar.Value := PayrollDocLineCalc.Rounding(PayrollDocLineCalc."Result Value");
                                PayrollDocLineVar.Calculated := true;
                                PayrollDocLineVar.Error := false;
                                PayrollDocLineVar.Modify;
                            end else begin
                                PayrollDocLineVar.Init;
                                PayrollDocLineVar."Document No." := "Document No.";
                                PayrollDocLineVar."Document Line No." := "Line No.";
                                PayrollDocLineVar."Element Code" := "Element Code";
                                PayrollDocLineVar."Line No." := "Line No.";
                                PayrollDocLineVar.Variable := PayrollDocLineCalc.Variable;
                                PayrollDocLineVar.Value := PayrollDocLineCalc.Rounding(PayrollDocLineCalc."Result Value");
                                PayrollDocLineVar.Calculated := true;
                                PayrollDocLineVar.Error := false;
                                PayrollDocLineVar.Insert;
                            end;
                            ExprMgt.CheckStops(PayrollDocLineVar);
                        end;

                        if PayrollDocLineCalc."Result Field No." <> 0 then begin
                            RecRef.Open(DATABASE::"Payroll Document Line");
                            RecRef.GetTable(Rec);
                            FldRef := RecRef.Field(PayrollDocLineCalc."Result Field No.");
                            FldRef.Value(
                              PayrollDocLineCalc.Rounding(
                                PayrollDocLineCalc."Result Value"));
                            RecRef.SetTable(Rec);
                            RecRef.Modify;
                            RecRef.Close;
                            Find;
                        end;
                    end;

                    if GotoFlag then
                        GotoFlag := false
                    else
                        if PayrollDocLineCalc.Next = 0 then
                            Calculated := true;
                end;

            if not Calculated then begin // If no method, the default is just set to Employee Ledger Entry
                PayrollDocLineCalc."Result Value" :=
                  PayrollDocLineCalc.Rounding(GetEmplLedgEntryAmt(Rec, 0));
                "Payroll Amount" := PayrollDocLineCalc."Result Value";
                PayrollDocLineCalc.Modify;
            end;
        end;
    end;

    var
        HumanResourcesSetup: Record "Human Resources Setup";
        PayrollCalcFunction: Record "Payroll Calculation Function";
        PayrollElement: Record "Payroll Element";
        PayrollElement2: Record "Payroll Element";
        PayrollCalculation: Record "Payroll Calculation";
        PayrollCalcLine: Record "Payroll Calculation Line";
        PayrollDocLineCalc: Record "Payroll Document Line Calc.";
        PayrollPeriod: Record "Payroll Period";
        PrevPayrollPeriod: Record "Payroll Period";
        WagePayrollPeriod: Record "Payroll Period";
        FirstPayrollPeriod: Record "Payroll Period";
        FirstYearPayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        Employee2: Record Employee;
        EmplLedgEntry: Record "Employee Ledger Entry";
        RangeHeader: Record "Payroll Range Header";
        PayrollElementVar: Record "Payroll Element Variable";
        PayrollDocLineVar: Record "Payroll Document Line Var.";
        PayrollElementExpr: Record "Payroll Element Expression";
        PayrollDocLineExpr: Record "Payroll Document Line Expr.";
        SickLeaveSetup: Record "Sick Leave Setup";
        CalendarMgt: Codeunit "Payroll Calendar Management";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        ExprMgt: Codeunit "Payroll Expression Management";
        AEMgt: Codeunit "AE Calc Management";
        HaveEmplLedgEntry: Boolean;
        StopCalc: Boolean;
        Exception: Boolean;
        SavedValue: Decimal;
        CurrCode: Code[10];
        PositCode: Text[30];
        DepartCode: Text[30];
        StartDate: array[5] of Date;
        EndDate: array[5] of Date;
        Text001: Label 'Call for function %1 in method %2 does not exist.';
        Text002: Label 'You cannot use both "%1" and "%2" in the same %6 range. See Amounts in Range named %3 in %4 %5.';
        ShouldNotBeErr: Label 'Element Code %1: field %2 should not be %3.';
        Bracket: Option Limit,MaxWithholding,Percent,Quantity,TaxPercent,MinAmount,MaxAmount;
        UOM: Option Day,Hour,CalDay;
        Text060: Label 'Label %1 not found.';
        Text063: Label 'Quantity of IF and ENDIF statements does not match.';

    [Scope('OnPrem')]
    procedure CalculateFunction(var PayrollDocLine: Record "Payroll Document Line"; FunctionNo: Integer; var ResultValue: Decimal; var ResultFlag: Option)
    var
        StartDate: Date;
        EndDate: Date;
    begin
        with PayrollDocLine do
            case FunctionNo of
                23:   // GET LEDGER ENTRY AMOUNT - NOT USED
                    ResultValue := GetEmplLedgEntryAmt(PayrollDocLine, 0);
                24:   // GET LEDGER ENTRY QTY  - NOT USED
                    ResultValue := GetEmplLedgEntryAmt(PayrollDocLine, 1);
                220:       // ADD BASE AMOUNT
                    ResultValue := BaseAmount(PayrollDocLine, PayrollDocLineCalc."Base Amount Code");
                247:       // ADD BASE BALANCE
                    ResultValue := BaseBalance(PayrollDocLine, PayrollDocLineCalc."Base Amount Code");
                249:       // AMOUNT IS DEDUCTION
                    if GetRangeHeader(PayrollDocLine) then
                        ResultValue := Deduction(PayrollDocLine, 0);
                252:       // GET RANGE MIN AMOUNT
                    if GetRangeHeader(PayrollDocLine) then
                        ResultValue := Brackets("Employee No.", Bracket::MinAmount);
                253:       // GET RANGE MAX AMOUNT
                    if GetRangeHeader(PayrollDocLine) then
                        ResultValue := Brackets("Employee No.", Bracket::MaxAmount);
                255:       // GET RANGE COEFFICIENT
                    if GetRangeHeader(PayrollDocLine) then
                        ResultValue := Brackets("Employee No.", Bracket::Quantity);
                261:       // BALANCE TO DATE
                    ResultValue := BalanceToDate(PayrollDocLine);
                262,
              2013:       // EARNINGS YTD
                    ResultValue := YTDEarnings(PayrollDocLine);
                263:       // INCOME TAX AMOUNT YTD
                    ResultValue := YTDTaxableIncomeTax(PayrollDocLine);
                270:       // GET MROT
                    ResultValue := GetFSILimit("Period Code", 0);
                271:       // GET FSI MAX SALARY
                    ResultValue := GetFSILimit("Period Code", 1);
                    // Russian specific
                2002:    // ÅÉêîàì. æÆÇéÄè ìÇïÄâÇ
                    if GetRangeHeader(PayrollDocLine) then
                        ResultValue := -Withholding(PayrollDocLine, "Corr. Amount");
                2003: // TAXABLE AMOUNT YTD
                    ResultValue := YTDTaxableAmount(PayrollDocLine);
                2005:    // PAYROLL AMOUNT YTD
                    ResultValue := YTDPayrollAmount(PayrollDocLine);
                2024:   // æôîîÇ æèêäèê äïƒ äÄòÄäÇ
                    if GetRangeHeader(PayrollDocLine) then
                        ResultValue := -EarningsCredit(PayrollDocLine, "Corr. Amount", -YTDPayrollAmount(PayrollDocLine));
                2025: // éøùàÆø ìÇ åêï£à
                    if GetRangeHeader(PayrollDocLine) then
                        ResultValue := PropertyDeduction(PayrollDocLine, "Corr. Amount");
                2030:   // éøùàÆ ï£âÄÆÇ æôîîÇ æ ìÇùÇïÇ âÄäÇ ÅÄ ÆàèôÖêë îàæƒû
                    if GetRangeHeader(PayrollDocLine) then
                        ResultValue := DeductionAmount(PayrollDocLine, "Corr. Amount");
                2035:    // æôîîÇ ÄüïÇâ. ìÇïÄâÄî æ ìÇùÇïÇ âÄäÇ (Ô«½ý¬« ñ½´ ìäöï)
                    ResultValue := YTDTypeTaxable(PayrollDocLine);
                2036:    // ÆàèôÖÇƒ æôîîÇ ìÇïÄâÇ  (Ô«½ý¬« ñ½´ ìäöï)
                    ResultValue := YTDTypeAmount(PayrollDocLine);
                2040:   // ìÇïÄâÄÄüïÇâÇàîøë äÄòÄä ÅÄ æÅÉÇéèà 2-ìäöï
                    ResultValue := GetIncomeTaxAmounts(PayrollDocLine, 0);
                2041:   // æôîîÇ ìÇùêæïàììÄâÄ ìÇïÄâÇ ÅÄ æÅÉÇéèà 2-ìäöï
                    ResultValue := GetIncomeTaxAmounts(PayrollDocLine, 1);
                2042:   // æôîîÇ ôÅïÇùàììÄâÄ ìÇïÄâÇ ÅÄ æÅÉÇéèà 2-ìäöï
                    ResultValue := GetIncomeTaxAmounts(PayrollDocLine, 2);
                2043:   // æôîîÇ ÅÄïôùàììÄâÄ éøùàÆÇ ÅÄ æÅÉÇéèà 2-ìäöï
                    ResultValue := GetIncomeTaxAmounts(PayrollDocLine, 3);
                2070:    // ìÇùÇï£ìÄâÄ æÇï£äÄ = èÄìàùìÄâÄ æÇï£äÄ ÅÉÄÿïÄâÄ îàæƒûÇ
                    ResultValue := GetStartingBalance(PayrollDocLine);
                2100: // èÄïêùàæÆéÄ ùÇæÄé ÅÄ ÆÇüàï× äïƒ öêï£ÆÉÇ éÉàîàììøò ÇèÆêéìÄæÆàë
                    ResultValue :=
                      TimesheetMgt.GetTimeSheetData(PayrollDocLine, 1, PayrollDocLineCalc."Time Activity Group");
                2101: // èÄïêùàæÆéÄ äìàë ÅÄ ÆÇüàï× äïƒ öêï£ÆÉÇ éÉàîàììøò ÇèÆêéìÄæÆàë
                    ResultValue :=
                      TimesheetMgt.GetTimeSheetData(PayrollDocLine, 0, PayrollDocLineCalc."Time Activity Group");
                2102: // èÄïêùàæÆéÄ èÇïàìäÇÉìøò äìàë ÅÄ èÇïàìäÇÉ× é ÅàÉêÄäà
                    ResultValue :=
                      CalendarMgt.GetPeriodInfo(
                        "Calendar Code", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 1);
                2103: // èÄïêùàæÆéÄ ÉÇüÄùêò äìàë ÅÄ èÇïàìäÇÉ× é âÄäô
                    ResultValue :=
                      CalendarMgt.GetPeriodInfo(
                        "Calendar Code", FirstYearPayrollPeriod."Starting Date",
                        CalcDate('<CY>', FirstYearPayrollPeriod."Starting Date"), 2);
                2104: // èÄïêùàæÆéÄ ÉÇüÄùêò äìàë ÅÄ èÇïàìäÇÉ× é ÅàÉêÄäà
                    ResultValue :=
                      CalendarMgt.GetPeriodInfo(
                        "Calendar Code", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 2);
                2105: // èÄïêùàæÆéÄ ÉÇüÄùêò ùÇæÄé ÅÄ èÇïàìäÇÉ× é ÅàÉêÄäà
                    ResultValue :=
                      CalendarMgt.GetPeriodInfo(
                        "Calendar Code", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 3);
                2106: // èÄïêùàæÆéÄ ÉÇüÄùêò ùÇæÄé ÅÄ èÇïàìäÇÉ× é âÄäô
                    ResultValue :=
                      CalendarMgt.GetPeriodInfo(
                        "Calendar Code", FirstYearPayrollPeriod."Starting Date",
                        CalcDate('<CY>', FirstYearPayrollPeriod."Starting Date"), 3);
                2107: // èÄïêùàæÆéÄ èÇïàìäÇÉìøò äìàë ÅÄ èÇïàìäÇÉ× é ÅàÉêÄäà ê äàëæÆéêê
                    begin
                        if "Action Starting Date" <= PayrollPeriod."Starting Date" then
                            StartDate := PayrollPeriod."Starting Date"
                        else
                            StartDate := "Action Starting Date";
                        if "Action Ending Date" >= PayrollPeriod."Ending Date" then
                            EndDate := PayrollPeriod."Ending Date"
                        else
                            EndDate := "Action Ending Date";
                        ResultValue :=
                          CalendarMgt.GetPeriodInfo(
                            "Calendar Code", StartDate, EndDate, 1);
                    end;
                2108: // èÄïêùàæÆéÄ ÉÇüÄùêò äìàë ÅÄ èÇïàìäÇÉ× é ÅàÉêÄäà ê äàëæÆéêê
                    begin
                        if "Action Starting Date" <= PayrollPeriod."Starting Date" then
                            StartDate := PayrollPeriod."Starting Date"
                        else
                            StartDate := "Action Starting Date";
                        if "Action Ending Date" >= PayrollPeriod."Ending Date" then
                            EndDate := PayrollPeriod."Ending Date"
                        else
                            EndDate := "Action Ending Date";
                        ResultValue :=
                          CalendarMgt.GetPeriodInfo(
                            "Calendar Code", StartDate, EndDate, 3);
                    end;
                2110: // çÇÅÄïìàìêà ÆÇüïêûø æÉàäìàâÄ çÇÉÇüÄÆèÇ
                    ResultValue := AEMgt.FillDocLineAEData(PayrollDocLine, PayrollDocLineCalc."AE Setup Code");
                2111: // ÅÄïôùêÆ£ ïêîêÆ äìàéìÄâÄ æç
                    ResultValue := SickLeaveSetup.GetMaxDailyPayment(PayrollDocLine);
                2112: // ÅÄïôùêÆ£ îÇèæ. ÉÇçîàÉ ÄÅïÇÆø ÅÄ æç
                    ResultValue := SickLeaveSetup.GetMinWageAmount(PayrollDocLine);
                2113: // æôî=ÄèïÇä ÅÉàä.îàæƒûÇ
                    ResultValue := GetSalaryPrevPeriod(PayrollDocLine);
                2114: // èÄïêùàæÆéÄ èÇïàìäÇÉìøò äìàë ÅÄ èÇïàìäÇÉ× é ÅàÉêÄäà ìÇùêæïàìêƒ
                    ResultValue :=
                      CalendarMgt.GetPeriodInfo(
                        "Calendar Code", WagePayrollPeriod."Starting Date", WagePayrollPeriod."Ending Date", 1);
                2220:    // æôîîÇ = æôîîà üÇçÄéÄâÄ ÄèïÇäÇ æÄÆÉôäìêèÇ çÇ ÅàÉêÄä
                    ResultValue := GetBaseSalary("Employee No.", PayrollPeriod);
                2221:    // æôîîÇ = æôîîà ìÇäüÇéÄè çÇéêæƒÖêò Ä üÇçÄéÄâÄ ÄèïÇäÇ
                    ResultValue := GetExtraSalary("Employee No.", PayrollPeriod);
                2230:  // îàæƒùìøë ÄèïÇä ÅÉÄÅÄÉû. ÄÆÉÇüÄÆÇììøî ùÇæÇî
                    ResultValue := GetSalaryPay(PayrollDocLine, UOM::Hour, PayrollDocLineCalc."Time Activity Group");
                2232:  // ÇéÇìæ ìÇ äÇÆô ÅÉÄÅÄÉû. ÄÆÉÇüÄÆÇììøî ùÇæÇî
                    ResultValue := GetAdvancePay(PayrollDocLine, UOM::Hour, PayrollDocLineCalc."Time Activity Group");
                2239: // æÆÇéèÇ ÅÉÄÅÄÉû. èÇïàìäÇÉ×
                    ResultValue := SalaryProRataCalendar(PayrollDocLine);
                2240:  // îàæƒùìøë ÄèïÇä ÅÉÄÅÄÉû. ÄÆÉÇüÄÆÇììøî äìƒî
                    ResultValue := GetSalaryPay(PayrollDocLine, UOM::Day, PayrollDocLineCalc."Time Activity Group");
                2241:  // îàæƒùìøë äÄÅïÇÆÇ ÅÄ ÄèïÇäô ê ùÇæÇî ÅÄ éÉàîàììÄë âÉôÅÅà
                    ResultValue := GetExtraPay(PayrollDocLine, PayrollDocLineCalc."Time Activity Group");
                2242:  // ÇéÇìæ ìÇ äÇÆô ÅÉÄÅÄÉû. ÄÆÉÇüÄÆÇììøî äìƒî
                    ResultValue := GetAdvancePay(PayrollDocLine, UOM::Day, PayrollDocLineCalc."Time Activity Group");
                2300: // ÉÇæùàÆ æÆÇåÇ
                    ResultValue := ServiceYears(PayrollDocLine);
                2301: // ÅÉÄéàÉèÇ ÆêÅÇ ÆÉôäÄéÄâÄ äÄâÄéÄÉÇ: âÅò = 1
                    ResultValue := LaborContractType(PayrollDocLine);
                else
                    if PayrollCalcFunction."Function No." <> 0 then
                        Error(Text001, PayrollCalcFunction."Function No.", PayrollCalcFunction.Code);
            end;
    end;

    local procedure Annualize(Amount: Decimal): Decimal
    begin
        exit(Amount * 12);
    end;

    local procedure BalanceToDate(var PayrollDocLine: Record "Payroll Document Line"): Decimal
    begin
        with Employee2 do begin
            Reset;
            SetRange("Employee No. Filter", PayrollDocLine."Employee No.");
            SetRange("Element Type Filter", PayrollDocLine."Element Type");
            SetRange("Element Code Filter", PayrollDocLine."Element Code");
            SetRange("Payroll Period Filter", FirstYearPayrollPeriod.Code, PayrollDocLine."Period Code");
            CalcFields("Payroll Amount");
            exit("Payroll Amount");
        end;
    end;

    local procedure BaseAmount(var PayrollDocLine: Record "Payroll Document Line"; BaseAmountCode: Code[10]): Decimal
    var
        PayrollDocLine3: Record "Payroll Document Line";
        PayrollBaseAmount: Record "Payroll Base Amount";
        Base: Decimal;
    begin
        Base := 0;

        with PayrollDocLine3 do begin
            Reset;
            SetRange("Document No.", PayrollDocLine."Document No.");

            PayrollBaseAmount.Reset;
            PayrollBaseAmount.SetRange("Element Code", PayrollDocLine."Element Code");
            if PayrollBaseAmount.FindSet then
                repeat
                    // Skip blank entries and entries we don't care about
                    if ((PayrollBaseAmount."Element Code Filter" <> '') or
                        (PayrollBaseAmount."Element Type Filter" <> '') or
                        (PayrollBaseAmount."Element Group Filter" <> '') or
                        (PayrollBaseAmount."Posting Type Filter" <> '')) and
                       ((BaseAmountCode = '') or
                        (BaseAmountCode = PayrollBaseAmount.Code))
                    then begin
                        // Set up the filters according to what is in the BaseAmount record
                        if PayrollBaseAmount."Element Code Filter" = '' then
                            SetRange("Element Code")
                        else
                            SetFilter("Element Code", PayrollBaseAmount."Element Code Filter");
                        if PayrollBaseAmount."Element Type Filter" = '' then
                            SetRange("Element Type")
                        else
                            SetFilter("Element Type", PayrollBaseAmount."Element Type Filter");
                        if PayrollBaseAmount."Element Group Filter" = '' then
                            SetRange("Element Group")
                        else
                            SetFilter("Element Group", PayrollBaseAmount."Element Group Filter");
                        if PayrollBaseAmount."Posting Type Filter" = '' then
                            SetRange("Posting Type")
                        else
                            SetFilter("Posting Type", PayrollBaseAmount."Posting Type Filter");
                        case PayrollBaseAmount."Income Tax Base Filter" of
                            0:
                                SetRange("Income Tax Base");
                            1:
                                SetRange("Income Tax Base", true);
                            2:
                                SetRange("Income Tax Base", false);
                        end;
                        case PayrollBaseAmount."PF Base Filter" of
                            0:
                                SetRange("Pension Fund Base");
                            1:
                                SetRange("Pension Fund Base", true);
                            2:
                                SetRange("Pension Fund Base", false);
                        end;
                        case PayrollBaseAmount."FSI Base Filter" of
                            0:
                                SetRange("FSI Base");
                            1:
                                SetRange("FSI Base", true);
                            2:
                                SetRange("FSI Base", false);
                        end;
                        case PayrollBaseAmount."Federal FMI Base Filter" of
                            0:
                                SetRange("Federal FMI Base");
                            1:
                                SetRange("Federal FMI Base", true);
                            2:
                                SetRange("Federal FMI Base", false);
                        end;
                        case PayrollBaseAmount."Territorial FMI Base Filter" of
                            0:
                                SetRange("Territorial FMI Base");
                            1:
                                SetRange("Territorial FMI Base", true);
                            2:
                                SetRange("Territorial FMI Base", false);
                        end;
                        case PayrollBaseAmount."FSI Injury Base Filter" of
                            0:
                                SetRange("FSI Injury Base");
                            1:
                                SetRange("FSI Injury Base", true);
                            2:
                                SetRange("FSI Injury Base", false);
                        end;
                        // Run through the Payroll Journal
                        if FindSet then
                            repeat
                                Base := Base + "Payroll Amount";
                            until Next = 0;
                    end;
                until PayrollBaseAmount.Next = 0;
        end;

        exit(Base);
    end;

    local procedure BaseBalance(var PayrollDocLine: Record "Payroll Document Line"; BaseAmountCode: Code[10]): Decimal
    var
        PayrollLedgEntry: Record "Payroll Ledger Entry";
        PayrollBaseAmount: Record "Payroll Base Amount";
        Base: Decimal;
    begin
        Base := 0;

        with PayrollLedgEntry do begin
            Reset;
            SetCurrentKey("Employee No.");
            SetRange("Employee No.", PayrollDocLine."Employee No.");

            PayrollBaseAmount.Reset;
            PayrollBaseAmount.SetRange("Element Code", PayrollDocLine."Element Code");
            if PayrollBaseAmount.FindSet then
                repeat
                    // Skip blank entries and entries we don't care about
                    if ((PayrollBaseAmount."Element Code Filter" <> '') or
                        (PayrollBaseAmount."Element Type Filter" <> '') or
                        (PayrollBaseAmount."Element Group Filter" <> '') or
                        (PayrollBaseAmount."Posting Type Filter" <> '')) and
                       ((BaseAmountCode = '') or
                        (BaseAmountCode = PayrollBaseAmount.Code))
                    then begin
                        // Set up the filters according to what is in the BaseAmount record
                        if PayrollBaseAmount."Element Code Filter" = '' then
                            SetRange("Element Code")
                        else
                            SetFilter("Element Code", PayrollBaseAmount."Element Code Filter");
                        if PayrollBaseAmount."Element Type Filter" = '' then
                            SetRange("Element Type")
                        else
                            SetFilter("Element Type", PayrollBaseAmount."Element Type Filter");
                        if PayrollBaseAmount."Element Group Filter" = '' then
                            SetRange("Element Group")
                        else
                            SetFilter("Element Group", PayrollBaseAmount."Element Group Filter");
                        if PayrollBaseAmount."Posting Type Filter" = '' then
                            SetRange("Posting Type")
                        else
                            SetFilter("Posting Type", PayrollBaseAmount."Posting Type Filter");
                        case PayrollBaseAmount."Income Tax Base Filter" of
                            0:
                                SetRange("Income Tax Base");
                            1:
                                SetRange("Income Tax Base", true);
                            2:
                                SetRange("Income Tax Base", false);
                        end;
                        case PayrollBaseAmount."PF Base Filter" of
                            0:
                                SetRange("Pension Fund Base");
                            1:
                                SetRange("Pension Fund Base", true);
                            2:
                                SetRange("Pension Fund Base", false);
                        end;
                        case PayrollBaseAmount."FSI Base Filter" of
                            0:
                                SetRange("FSI Base");
                            1:
                                SetRange("FSI Base", true);
                            2:
                                SetRange("FSI Base", false);
                        end;
                        case PayrollBaseAmount."Federal FMI Base Filter" of
                            0:
                                SetRange("Federal FMI Base");
                            1:
                                SetRange("Federal FMI Base", true);
                            2:
                                SetRange("Federal FMI Base", false);
                        end;
                        case PayrollBaseAmount."Territorial FMI Base Filter" of
                            0:
                                SetRange("Territorial FMI Base");
                            1:
                                SetRange("Territorial FMI Base", true);
                            2:
                                SetRange("Territorial FMI Base", false);
                        end;
                        case PayrollBaseAmount."FSI Injury Base Filter" of
                            0:
                                SetRange("FSI Injury Base");
                            1:
                                SetRange("FSI Injury Base", true);
                            2:
                                SetRange("FSI Injury Base", false);
                        end;
                        // Run through the Payroll Journal
                        if FindSet then
                            repeat
                                Base := Base + "Payroll Amount";
                            until Next = 0;
                    end;
                until PayrollBaseAmount.Next = 0;
        end;

        exit(Base);
    end;

    local procedure Brackets(EmployeeNo: Code[20]; Bracket: Option Limit,MaxWithholding,Percent,Quantity,TaxPercent,MinAmount,MaxAmount): Decimal
    var
        RangeLine: Record "Payroll Range Line";
    begin
        with RangeLine do begin
            SetRange("Range Code", RangeHeader.Code);
            SetRange("Element Code", RangeHeader."Element Code");
            SetRange("Period Code", RangeHeader."Period Code");

            if Employee.Get(EmployeeNo) then begin
                Employee.TestField(Gender);
                Employee.TestField("Birth Date");
                if RangeHeader."Allow Employee Gender" then
                    SetRange("Employee Gender", Employee.Gender);
                if RangeHeader."Allow Employee Age" then
                    SetRange("From Birthday and Younger", 0D, Employee."Birth Date");
            end;

            if FindFirst then
                case Bracket of
                    Bracket::Limit:
                        begin
                            TestField(Limit);
                            exit(Limit);
                        end;
                    Bracket::MaxWithholding:
                        exit("Max Deduction");
                    Bracket::Percent:
                        begin
                            TestField(Percent);
                            exit(Percent);
                        end;
                    Bracket::Quantity:
                        exit(Quantity);
                    Bracket::TaxPercent:
                        begin
                            TestField("Tax %");
                            exit("Tax %");
                        end;
                    Bracket::MinAmount:
                        exit("Min Amount");
                    Bracket::MaxAmount:
                        exit("Max Amount");
                end;

            exit(0);
        end;
    end;

    local procedure Deduction(var PayrollDocLine: Record "Payroll Document Line"; PreDeductionAmount: Decimal): Decimal
    var
        RangeLine: Record "Payroll Range Line";
        RemainingAllowances: Integer;
        ReturnValue: Decimal;
        LineDeductionAmount: Decimal;
        UsesAmountOver: Boolean;
        AmountOverLineFound: Boolean;
    begin
        GetEmplLedgEntryAmt(PayrollDocLine, 0);
        with RangeLine do begin
            SetCurrentKey("Element Code", "Range Code", "Period Code", "Over Amount");
            SetRange("Element Code", RangeHeader."Element Code");
            SetRange("Range Code", RangeHeader.Code);
            SetRange("Period Code", RangeHeader."Period Code");

            Employee.Reset;
            if Employee.Get(PayrollDocLine."Employee No.") then begin
                Employee.TestField(Gender);
                Employee.TestField("Birth Date");
            end;

            if RangeHeader."Allow Employee Gender" = true then
                SetRange("Employee Gender", Employee.Gender);

            if RangeHeader."Allow Employee Age" = true then
                SetRange("From Birthday and Younger", 0D, Employee."Birth Date");

            if Find('+') then begin
                RemainingAllowances := EmplLedgEntry.Quantity;
                ReturnValue := 0;
                UsesAmountOver := ("Over Amount" <> 0);
                AmountOverLineFound := false;
                repeat
                    if UsesAmountOver then
                        AmountOverLineFound := (Annualize(PreDeductionAmount) > "Over Amount");
                    if not UsesAmountOver or AmountOverLineFound then begin
                        LineDeductionAmount := Amount;
                        if Percent <> 0 then begin
                            LineDeductionAmount := LineDeductionAmount +
                              (Annualize(PreDeductionAmount) * Percent / 100.0);
                            if "From Allowance" <> 0 then
                                Error(Text002, FieldName(Percent), FieldName("From Allowance"),
                                  "Range Code", PayrollElement.TableName, "Element Code",
                                  Format(RangeHeader."Range Type"));
                        end;

                        if "On Allowance" then
                            if "From Allowance" = 0 then
                                LineDeductionAmount := LineDeductionAmount * EmplLedgEntry.Quantity
                            else
                                if RemainingAllowances >= "From Allowance" then begin
                                    LineDeductionAmount := LineDeductionAmount * (RemainingAllowances - ("From Allowance" - 1));
                                    RemainingAllowances := "From Allowance" - 1;
                                end;

                        if LineDeductionAmount < "Min Amount" then
                            LineDeductionAmount := "Min Amount";

                        if ("Max Amount" <> 0) and (LineDeductionAmount > "Max Amount") then
                            LineDeductionAmount := "Max Amount";

                        ReturnValue := ReturnValue + ProrateAnnually(PayrollDocLine, LineDeductionAmount);
                    end;
                until AmountOverLineFound or (Next(-1) = 0);
                exit(ReturnValue);
            end;
            exit(0);
        end;
    end;

    local procedure GetEmplLedgEntryAmt(var PayrollDocLine: Record "Payroll Document Line"; AmountType: Option Amount,Quantity): Decimal
    begin
        with EmplLedgEntry do begin
            if PayrollDocLine."Employee Ledger Entry No." <> 0 then
                Get(PayrollDocLine."Employee Ledger Entry No.")
            else begin
                Reset;
                SetRange("Employee No.", PayrollDocLine."Employee No.");
                SetRange("Element Code", PayrollDocLine."Element Code");
                if PayrollElement."Include into Calculation by" =
                   PayrollElement."Include into Calculation by"::"Action Period"
                then
                    SetRange("Action Starting Date", 0D, PayrollPeriod."Ending Date");
                if not FindLast then
                    exit(0);
            end;

            case PayrollElement."Include into Calculation by" of
                PayrollElement."Include into Calculation by"::"Action Period":
                    if (("Action Ending Date" = 0D) or
                        ("Action Ending Date" > PayrollPeriod."Starting Date"))
                    then
                        case AmountType of
                            AmountType::Amount:
                                exit(Amount);
                            AmountType::Quantity:
                                exit(Quantity);
                        end;
                PayrollElement."Include into Calculation by"::"Period Code":
                    case AmountType of
                        AmountType::Amount:
                            exit(Amount);
                        AmountType::Quantity:
                            exit(Quantity);
                    end;
            end;
            exit(0);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetBaseSalary(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"): Decimal
    var
        PeriodWorkDays: Decimal;
        PeriodSalary: Decimal;
        WorkDays: Decimal;
        StartDate: Date;
        EndDate: Date;
        ElementFilter: Text[1024];
    begin
        // Base salary for period
        HumanResourcesSetup.Get;
        HumanResourcesSetup.TestField("Element Code Salary Days");
        ElementFilter := HumanResourcesSetup."Element Code Salary Days";
        if HumanResourcesSetup."Element Code Salary Hours" <> '' then
            ElementFilter += '|' + HumanResourcesSetup."Element Code Salary Hours";
        if HumanResourcesSetup."Element Code Salary Amount" <> '' then
            ElementFilter += '|' + HumanResourcesSetup."Element Code Salary Amount";

        PeriodWorkDays := 0;
        PeriodSalary := 0;

        EmplLedgEntry.Reset;
        EmplLedgEntry.SetRange("Employee No.", EmployeeNo);
        EmplLedgEntry.SetFilter("Element Code", ElementFilter);
        EmplLedgEntry.SetRange("Action Starting Date", 0D, PayrollPeriod."Ending Date");
        EmplLedgEntry.SetFilter("Action Ending Date", '%1|%2..', 0D, PayrollPeriod."Starting Date");
        if EmplLedgEntry.FindSet then begin
            repeat
                if EmplLedgEntry."Action Starting Date" >= PayrollPeriod."Starting Date" then
                    StartDate := EmplLedgEntry."Action Starting Date"
                else
                    StartDate := PayrollPeriod."Starting Date";
                if (EmplLedgEntry."Action Ending Date" = 0D) or
                   (EmplLedgEntry."Action Ending Date" >= PayrollPeriod."Ending Date")
                then
                    EndDate := PayrollPeriod."Ending Date"
                else
                    EndDate := EmplLedgEntry."Action Ending Date";
                WorkDays :=
                  CalendarMgt.GetPeriodInfo(EmplLedgEntry."Calendar Code", StartDate, EndDate, 2);
                PeriodWorkDays := PeriodWorkDays + WorkDays;
            until EmplLedgEntry.Next = 0;
            if PeriodWorkDays = 0 then
                exit(0);

            if EmplLedgEntry.FindSet then
                repeat
                    if EmplLedgEntry."Action Starting Date" >= PayrollPeriod."Starting Date" then
                        StartDate := EmplLedgEntry."Action Starting Date"
                    else
                        StartDate := PayrollPeriod."Starting Date";
                    if (EmplLedgEntry."Action Ending Date" = 0D) or
                       (EmplLedgEntry."Action Ending Date" >= PayrollPeriod."Ending Date")
                    then
                        EndDate := PayrollPeriod."Ending Date"
                    else
                        EndDate := EmplLedgEntry."Action Ending Date";
                    WorkDays :=
                      CalendarMgt.GetPeriodInfo(EmplLedgEntry."Calendar Code", StartDate, EndDate, 2);
                    PeriodSalary := PeriodSalary + EmplLedgEntry.Amount * WorkDays / PeriodWorkDays;
                until EmplLedgEntry.Next = 0;

            exit(PeriodSalary);
        end;
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure GetExtraSalary(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"): Decimal
    var
        PeriodWorkDays: Decimal;
        PeriodSalary: Decimal;
        WorkDays: Decimal;
        StartDate: Date;
        EndDate: Date;
        ElementFilter: Text[1024];
        ElementFilter2: Text[1024];
        FirstElement: Boolean;
    begin
        // Base salary for period
        HumanResourcesSetup.Get;
        HumanResourcesSetup.TestField("Element Code Salary Days");
        ElementFilter := HumanResourcesSetup."Element Code Salary Days";
        if HumanResourcesSetup."Element Code Salary Hours" <> '' then
            ElementFilter += '|' + HumanResourcesSetup."Element Code Salary Hours";
        if HumanResourcesSetup."Element Code Salary Amount" <> '' then
            ElementFilter += '|' + HumanResourcesSetup."Element Code Salary Amount";

        ElementFilter2 := '';
        FirstElement := true;
        PayrollElement2.Reset;
        PayrollElement2.SetFilter("Depends on Salary Element", ElementFilter);
        if PayrollElement2.FindSet then
            repeat
                if FirstElement then begin
                    ElementFilter2 := PayrollElement2.Code;
                    FirstElement := false;
                end else
                    ElementFilter2 += '|' + PayrollElement2.Code;
            until PayrollElement2.Next = 0;

        PeriodWorkDays := 0;
        PeriodSalary := 0;

        EmplLedgEntry.Reset;
        EmplLedgEntry.SetRange("Employee No.", EmployeeNo);
        EmplLedgEntry.SetFilter("Element Code", ElementFilter2);
        EmplLedgEntry.SetRange("Action Starting Date", 0D, PayrollPeriod."Ending Date");
        EmplLedgEntry.SetFilter("Action Ending Date", '%1|%2..', 0D, PayrollPeriod."Starting Date");
        if EmplLedgEntry.FindSet then begin
            repeat
                if EmplLedgEntry."Action Starting Date" >= PayrollPeriod."Starting Date" then
                    StartDate := EmplLedgEntry."Action Starting Date"
                else
                    StartDate := PayrollPeriod."Starting Date";
                if (EmplLedgEntry."Action Ending Date" = 0D) or
                   (EmplLedgEntry."Action Ending Date" >= PayrollPeriod."Ending Date")
                then
                    EndDate := PayrollPeriod."Ending Date"
                else
                    EndDate := EmplLedgEntry."Action Ending Date";
                WorkDays :=
                  CalendarMgt.GetPeriodInfo(EmplLedgEntry."Calendar Code", StartDate, EndDate, 2);
                PeriodWorkDays := PeriodWorkDays + WorkDays;
            until EmplLedgEntry.Next = 0;
            if PeriodWorkDays = 0 then
                exit(0);

            EmplLedgEntry.FindFirst;
            repeat
                if EmplLedgEntry."Action Starting Date" >= PayrollPeriod."Starting Date" then
                    StartDate := EmplLedgEntry."Action Starting Date"
                else
                    StartDate := PayrollPeriod."Starting Date";
                if (EmplLedgEntry."Action Ending Date" = 0D) or
                   (EmplLedgEntry."Action Ending Date" >= PayrollPeriod."Ending Date")
                then
                    EndDate := PayrollPeriod."Ending Date"
                else
                    EndDate := EmplLedgEntry."Action Ending Date";
                WorkDays :=
                  CalendarMgt.GetPeriodInfo(EmplLedgEntry."Calendar Code", StartDate, EndDate, 2);
                PeriodWorkDays := PeriodWorkDays + WorkDays;
                PeriodSalary := PeriodSalary + EmplLedgEntry.Amount * WorkDays / PeriodWorkDays;
            until EmplLedgEntry.Next = 0;

            exit(PeriodSalary);
        end;
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure GetAdvancePay(var PayrollDocLine: Record "Payroll Document Line"; TimeType: Option Day,Hour; TimeActivityGroup: Code[20]): Decimal
    var
        PeriodWorkTime: Decimal;
        PeriodSalary: Decimal;
        WorkTime: Decimal;
        StartDate: Date;
        EndDate: Date;
        ElementFilter: Text[1024];
    begin
        // Base salary for period
        HumanResourcesSetup.Get;
        case TimeType of
            TimeType::Day:
                begin
                    HumanResourcesSetup.TestField("Element Code Salary Days");
                    ElementFilter := HumanResourcesSetup."Element Code Salary Days";
                end;
            TimeType::Hour:
                begin
                    HumanResourcesSetup.TestField("Element Code Salary Hours");
                    ElementFilter := HumanResourcesSetup."Element Code Salary Hours";
                end;
        end;
        if HumanResourcesSetup."Element Code Salary Amount" <> '' then
            ElementFilter += '|' + HumanResourcesSetup."Element Code Salary Amount";

        PeriodWorkTime := 0;
        PeriodSalary := 0;
        EmplLedgEntry.Reset;
        EmplLedgEntry.SetRange("Employee No.", PayrollDocLine."Employee No.");
        EmplLedgEntry.SetFilter("Element Code", ElementFilter);
        EmplLedgEntry.SetRange("Action Starting Date", 0D, PayrollPeriod."Ending Date");
        EmplLedgEntry.SetFilter("Action Ending Date", '%1|%2..', 0D, PayrollPeriod."Starting Date");
        if EmplLedgEntry.FindSet then begin
            repeat
                if EmplLedgEntry."Action Starting Date" >= PayrollPeriod."Starting Date" then
                    StartDate := EmplLedgEntry."Action Starting Date"
                else
                    StartDate := PayrollPeriod."Starting Date";
                if (EmplLedgEntry."Action Ending Date" = 0D) or
                   (EmplLedgEntry."Action Ending Date" >= PayrollPeriod."Ending Date")
                then
                    EndDate := PayrollPeriod."Ending Date"
                else
                    EndDate := EmplLedgEntry."Action Ending Date";
                case TimeType of
                    TimeType::Day:
                        WorkTime :=
                          CalendarMgt.GetPeriodInfo(EmplLedgEntry."Calendar Code", StartDate, EndDate, 2);
                    TimeType::Hour:
                        WorkTime :=
                          CalendarMgt.GetPeriodInfo(EmplLedgEntry."Calendar Code", StartDate, EndDate, 3);
                end;
                PeriodWorkTime := PeriodWorkTime + WorkTime;
            until EmplLedgEntry.Next = 0;
            if PeriodWorkTime = 0 then
                exit(0);
            PayrollPeriod.TestField("Advance Date");
            if EmplLedgEntry.FindSet then
                repeat
                    if EmplLedgEntry."Action Starting Date" >= PayrollPeriod."Starting Date" then
                        StartDate := EmplLedgEntry."Action Starting Date"
                    else
                        StartDate := PayrollPeriod."Starting Date";
                    if (EmplLedgEntry."Action Ending Date" = 0D) or
                       (EmplLedgEntry."Action Ending Date" >= PayrollPeriod."Advance Date")
                    then
                        EndDate := PayrollPeriod."Advance Date"
                    else
                        EndDate := EmplLedgEntry."Action Ending Date";
                    case TimeType of
                        TimeType::Day:
                            WorkTime :=
                              TimesheetMgt.GetTimesheetInfo(
                                PayrollDocLine."Employee No.", HumanResourcesSetup."Work Time Group Code", StartDate, EndDate, 4);
                        TimeType::Hour:
                            WorkTime :=
                              TimesheetMgt.GetTimesheetInfo(
                                PayrollDocLine."Employee No.", HumanResourcesSetup."Work Time Group Code", StartDate, EndDate, 3);
                    end;
                    PeriodSalary := PeriodSalary + EmplLedgEntry.Amount * WorkTime / PeriodWorkTime;
                until EmplLedgEntry.Next = 0;
            exit(PeriodSalary);
        end;
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure GetSalaryPay(var PayrollDocLine: Record "Payroll Document Line"; TimeType: Option; TimeActivityGroup: Code[20]): Decimal
    var
        PlannedTime: Decimal;
        ActualTime: Decimal;
    begin
        // Calculate salary for single Employee Ledger Entry
        PlannedTime := 0;
        ActualTime := 0;

        PayrollElement.Get(PayrollDocLine."Element Code");
        PayrollDocLine.TestField("Action Starting Date");
        PayrollDocLine.TestField("Action Ending Date");
        PayrollDocLine.TestField("Employee Ledger Entry No.");
        EmplLedgEntry.Get(PayrollDocLine."Employee Ledger Entry No.");
        EmplLedgEntry.TestField(Amount);

        PlannedTime :=
          TimesheetMgt.GetTimesheetInfo(
            PayrollDocLine."Employee No.", TimeActivityGroup,
            PayrollPeriod."Starting Date", PayrollPeriod."Ending Date",
            TimeType);

        if PlannedTime = 0 then
            Error(ShouldNotBeErr,
              PayrollDocLine."Element Code", PayrollDocLine.FieldCaption("Planned Hours"), PlannedTime);

        ActualTime :=
          TimesheetMgt.GetTimesheetInfo(
            PayrollDocLine."Employee No.", TimeActivityGroup,
            PayrollDocLine."Action Starting Date", PayrollDocLine."Action Ending Date",
            TimeType + 2);

        case TimeType of
            0:
                begin
                    PayrollDocLine."Planned Days" := PlannedTime;
                    PayrollDocLine."Actual Days" := ActualTime;
                end;
            1:
                begin
                    PayrollDocLine."Planned Hours" := PlannedTime;
                    PayrollDocLine."Actual Hours" := ActualTime;
                end;
        end;

        exit(EmplLedgEntry.Amount * ActualTime / PlannedTime);
    end;

    [Scope('OnPrem')]
    procedure GetExtraPay(var PayrollDocLine: Record "Payroll Document Line"; TimeActivityGroup: Code[20]): Decimal
    var
        Salary: Decimal;
        ActualHours: Decimal;
        StartDate: Date;
        EndDate: Date;
    begin
        // Calculate extrapay by hours depending on salary
        Salary := 0;

        HumanResourcesSetup.Get;
        HumanResourcesSetup.TestField("Element Code Salary Days");

        PayrollElement.Get(PayrollDocLine."Element Code");
        // PayrollElement.TESTFIELD("Depends on Salary");

        PayrollDocLine."Actual Hours" := 0;
        PayrollDocLine."Planned Hours" :=
          TimesheetMgt.GetTimesheetInfo(
            PayrollDocLine."Employee No.", HumanResourcesSetup."Work Time Group Code",
            PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 1);

        EmplLedgEntry.Reset;
        EmplLedgEntry.SetRange("Employee No.", PayrollDocLine."Employee No.");
        EmplLedgEntry.SetRange("Element Code", HumanResourcesSetup."Element Code Salary Days");
        EmplLedgEntry.SetRange("Action Starting Date", 0D, PayrollPeriod."Ending Date");
        EmplLedgEntry.SetFilter("Action Ending Date", '%1|%2..', 0D, PayrollPeriod."Starting Date");
        if EmplLedgEntry.FindSet then
            repeat
                if EmplLedgEntry."Action Starting Date" >= PayrollPeriod."Starting Date" then
                    StartDate := EmplLedgEntry."Action Starting Date"
                else
                    StartDate := PayrollPeriod."Starting Date";
                if (EmplLedgEntry."Action Ending Date" > PayrollPeriod."Ending Date") or
                   (EmplLedgEntry."Action Ending Date" = 0D)
                then
                    EndDate := PayrollPeriod."Ending Date"
                else
                    EndDate := EmplLedgEntry."Action Ending Date";

                ActualHours :=
                  TimesheetMgt.GetTimesheetInfo(
                    PayrollDocLine."Employee No.", TimeActivityGroup,
                    StartDate, EndDate, 3);

                Salary += EmplLedgEntry.Amount * ActualHours / PayrollDocLine."Planned Hours";
                PayrollDocLine."Actual Hours" += ActualHours;
            until EmplLedgEntry.Next = 0;

        exit(Salary);
    end;

    [Scope('OnPrem')]
    procedure GetRangeHeader(var PayrollDocLine: Record "Payroll Document Line"): Boolean
    var
        EmployeeLedgEntry: Record "Employee Ledger Entry";
    begin
        with RangeHeader do begin
            Reset;
            SetCurrentKey("Element Code", "Range Type", "Period Code");
            SetRange("Element Code", PayrollDocLine."Element Code");
            SetRange("Range Type", PayrollDocLineCalc."Range Type");
            case PayrollElement."Include into Calculation by" of
                PayrollElement."Include into Calculation by"::"Action Period":
                    begin
                        if EmployeeLedgEntry.Get(PayrollDocLine."Employee Ledger Entry No.") then begin
                            EmployeeLedgEntry.TestField("Action Starting Date");
                            SetRange("Period Code", FirstPayrollPeriod.Code, EmployeeLedgEntry."Period Code");
                        end else
                            SetRange("Period Code", FirstPayrollPeriod.Code, PayrollDocLine."Period Code");
                    end;
                PayrollElement."Include into Calculation by"::"Period Code":
                    SetRange("Period Code", FirstPayrollPeriod.Code, PayrollDocLine."Period Code");
            end;
            if not FindLast then begin
                Clear(RangeHeader);
                exit(false);
            end;
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetFSILimit(PeriodCode: Code[10]; LimitType: Option MROT,FSI): Decimal
    var
        PayrollLimit: Record "Payroll Limit";
    begin
        PayrollLimit.Reset;
        PayrollLimit.SetRange(Type, LimitType);
        PayrollLimit.SetFilter("Payroll Period", '..%1', PeriodCode);
        if PayrollLimit.FindLast then
            exit(PayrollLimit.Amount);

        exit(0);
    end;

    local procedure ProrateAnnually(var PayrollDocLine: Record "Payroll Document Line"; Amount: Decimal): Decimal
    begin
        exit(Amount / 12);
    end;

    [Scope('OnPrem')]
    procedure Withholding(var PayrollDocLine: Record "Payroll Document Line"; TaxableGross: Decimal): Decimal
    var
        RangeLine: Record "Payroll Range Line";
        ReturnValue: Decimal;
        HumanSetup: Record "Human Resources Setup";
        FundTax: Boolean;
        Sign: Integer;
    begin
        HumanSetup.Get;
        RangeHeader.Reset;
        RangeHeader.SetRange("Element Code", PayrollDocLine."Element Code");
        RangeHeader.SetRange("Period Code", FirstPayrollPeriod.Code, PayrollDocLine."Period Code");
        if RangeHeader.FindLast then;

        if TaxableGross >= 0 then
            Sign := 1
        else
            Sign := -1;

        FundTax := (PayrollDocLine."Element Type" = PayrollDocLine."Element Type"::Funds);
        with RangeLine do begin
            Reset;
            if not FundTax then
                SetCurrentKey("Element Code", "Range Code", "Period Code", "Over Amount");
            SetRange("Element Code", RangeHeader."Element Code");
            SetRange("Range Code", RangeHeader.Code);
            SetRange("Period Code", RangeHeader."Period Code");

            if Employee.Get(PayrollDocLine."Employee No.") then begin
                Employee.TestField(Gender);
                Employee.TestField("Birth Date");
                if RangeHeader."Allow Employee Gender" then
                    SetRange("Employee Gender", Employee.Gender);
                if RangeHeader."Allow Employee Age" then
                    SetRange("From Birthday and Younger", 0D, Employee."Birth Date");
            end;

            SetFilter("Over Amount", '<%1', Abs(TaxableGross));

            if not FindLast then begin
                SetRange("Over Amount");
                if not FindFirst then
                    exit(0);
            end;

            ReturnValue := "Tax Amount" +
              ((TaxableGross - Sign * "Over Amount") * "Tax %" / 100.0);

            if (ReturnValue < 0) and not IsCorrDocument(PayrollDocLine."Document No.") then
                ReturnValue := 0
            else
                if ("Max Deduction" > 0) and (Abs(ReturnValue) > "Max Deduction") then
                    ReturnValue := Sign * "Max Deduction";
        end;

        if RangeLine."Directory Code" <> '' then
            PayrollDocLine."Directory Code" := RangeLine."Directory Code";

        exit(ReturnValue);
    end;

    [Scope('OnPrem')]
    procedure EarningsCredit(var PayrollDocLine: Record "Payroll Document Line"; YTDTaxableAmount: Decimal; AmountYTD: Decimal): Decimal
    var
        RangeLine: Record "Payroll Range Line";
        ReturnValue: Decimal;
        CompAmount: Decimal;
    begin
        RangeHeader.SetRange("Element Code", PayrollDocLine."Element Code");
        RangeHeader.SetRange("Period Code", FirstPayrollPeriod.Code, PayrollDocLine."Period Code");
        if RangeHeader.FindLast then;

        with RangeLine do begin
            SetCurrentKey(
              "Element Code", "Range Code", "Period Code", "Over Amount");
            SetRange("Element Code", RangeHeader."Element Code");
            SetRange("Range Code", RangeHeader.Code);
            SetRange("Period Code", RangeHeader."Period Code");
            FindFirst;
            TestField(Amount);
            ReturnValue := 0;
            CompAmount := YTDTaxableAmount + AmountYTD;
            if CompAmount < Amount - AmountYTD then
                ReturnValue := CompAmount
            else
                ReturnValue := Amount - AmountYTD;
            exit(ReturnValue);
        end;
    end;

    [Scope('OnPrem')]
    procedure PropertyDeduction(var PayrollDocLine: Record "Payroll Document Line"; AmountMaxBenefitMonth: Decimal): Decimal
    var
        EmployeeLedgerEntry2: Record "Employee Ledger Entry";
        ReturnValue: Decimal;
        AmountBenefitBuild: Decimal;
    begin
        ReturnValue := 0;
        AmountBenefitBuild := 0;

        // ÄÅÉàäàïàìêà üøïÇ ïê ï£âÄÆÇ ìÇ åêï£à çÇ 3 âÄäÇ äÄ ÉÇæùàÆÇ
        with EmployeeLedgerEntry2 do begin
            Reset;
            SetCurrentKey("Employee No.");
            SetRange("Employee No.", PayrollDocLine."Employee No.");
            SetRange("Element Code", PayrollDocLine."Element Code");
            // ßÑ®þáß »« ºá¬«¡«ñáÔÑ½ýßÔóÒ, ½ýú«Ôá ñáÑÔß´ ¡á ú«ñ, »«Ô«¼ ¼«ªÑÔ íÙÔý »Ó«ñ½Ñ¡á («ÔñÑ½ý¡Ù¼ ñ«¬Ò¼Ñ¡Ô«¼)
            SetRange("Action Starting Date", FirstYearPayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
            SetFilter(Amount, '>%1', 0);
            if not FindLast then
                exit(0);
        end;

        // ÄÅÉàäàïàìêà äÄìÇïÄâÄéøò éøùàÆÄé æ îÄîàìÆÇ ï£âÄÆø äÄ ÉÇæùàÆÇ çÇÉÅïÇÆø
        with Employee2 do begin
            Reset;
            SetRange("Employee No. Filter", PayrollDocLine."Employee No.");
            SetRange("Directory Code Filter", PayrollDocLine."Directory Code");
            SetRange("Payroll Period Filter", FirstYearPayrollPeriod.Code, PayrollPeriod.Code);
            CalcFields("Payroll Amount");
            AmountBenefitBuild := -"Payroll Amount";
        end;

        // àæïê ï£âÄÆÇ êçÉÇæòÄäÄéÇìÇ, ÆÄ éøòÄä = 0
        if AmountBenefitBuild < EmplLedgEntry.Amount then begin
            if (EmplLedgEntry.Amount - AmountBenefitBuild) < AmountMaxBenefitMonth then
                ReturnValue := EmplLedgEntry.Amount - AmountBenefitBuild
            else
                ReturnValue := AmountMaxBenefitMonth;
            ReturnValue := -ReturnValue;
            exit(ReturnValue);
        end;
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure YTDEarnings(var PayrollDocLine: Record "Payroll Document Line"): Decimal
    begin
        // Find Year-To-Date Gross Earnings
        HumanResourcesSetup.Get;
        with Employee2 do begin
            Reset;
            SetRange("Employee No. Filter", PayrollDocLine."Employee No.");
            SetRange("Payroll Period Filter", FirstYearPayrollPeriod.Code, PayrollDocLine."Period Code");
            SetFilter("Element Code Filter", '%1|%2', HumanResourcesSetup."Income Tax 13%", HumanResourcesSetup."Income Tax 30%");
            CalcFields("Taxable Amount");
            exit("Taxable Amount");
        end;
    end;

    [Scope('OnPrem')]
    procedure YTDTaxableAmount(var PayrollDocLine: Record "Payroll Document Line"): Decimal
    begin
        with Employee2 do begin
            Reset;
            SetRange("Employee No. Filter", PayrollDocLine."Employee No.");
            SetRange("Element Type Filter", PayrollDocLine."Element Type");
            SetRange("Posting Type Filter", PayrollDocLine."Posting Type");
            SetRange("Element Code Filter", PayrollDocLine."Element Code");
            SetRange("Payroll Period Filter", FirstYearPayrollPeriod.Code, PrevPayrollPeriod.Code);
            CalcFields("Taxable Amount");
            exit("Taxable Amount");
        end;
    end;

    [Scope('OnPrem')]
    procedure YTDPayrollAmount(var PayrollDocLine: Record "Payroll Document Line"): Decimal
    begin
        with Employee2 do begin
            Reset;
            SetRange("Employee No. Filter", PayrollDocLine."Employee No.");
            SetRange("Element Type Filter", PayrollDocLine."Element Type");
            SetRange("Posting Type Filter", PayrollDocLine."Posting Type");
            SetRange("Element Code Filter", PayrollDocLine."Element Code");
            SetRange("Payroll Period Filter", FirstYearPayrollPeriod.Code, PrevPayrollPeriod.Code);
            CalcFields("Payroll Amount");
            exit("Payroll Amount");
        end;
    end;

    [Scope('OnPrem')]
    procedure YTDTypeAmount(var PayrollDocLine: Record "Payroll Document Line"): Decimal
    begin
        HumanResourcesSetup.Get;
        with Employee2 do begin
            Reset;
            SetRange("Employee No. Filter", PayrollDocLine."Employee No.");
            SetRange("Element Type Filter", PayrollDocLine."Element Type");
            SetRange("Posting Type Filter", PayrollDocLine."Posting Type");
            SetFilter("Element Code Filter", '<>%1&<>%2', HumanResourcesSetup."Income Tax 35%", HumanResourcesSetup."Income Tax 9%");
            SetRange("Payroll Period Filter", FirstYearPayrollPeriod.Code, PayrollDocLine."Period Code");
            CalcFields("Payroll Amount");
            exit("Payroll Amount");
        end;
    end;

    [Scope('OnPrem')]
    procedure YTDTaxableIncomeTax(var PayrollDocLine: Record "Payroll Document Line"): Decimal
    begin
        with Employee2 do begin
            Reset;
            SetRange("Employee No. Filter", PayrollDocLine."Employee No.");
            SetRange("Element Type Filter", PayrollDocLine."Element Type");
            SetRange("Posting Type Filter", PayrollDocLine."Posting Type");
            SetRange("Element Code Filter", PayrollDocLine."Element Code");
            SetRange("Payroll Period Filter", FirstYearPayrollPeriod.Code, PayrollDocLine."Period Code");
            CalcFields("Taxable Amount");
            exit("Taxable Amount");
        end;
    end;

    [Scope('OnPrem')]
    procedure YTDTypeTaxable(var PayrollDocLine: Record "Payroll Document Line"): Decimal
    begin
        HumanResourcesSetup.Get;
        with Employee2 do begin
            Reset;
            SetRange("Employee No. Filter", PayrollDocLine."Employee No.");
            SetRange("Element Type Filter", PayrollDocLine."Element Type");
            SetRange("Posting Type Filter", PayrollDocLine."Posting Type");
            SetFilter("Element Code Filter", '<>%1&<>%2', HumanResourcesSetup."Income Tax 35%", HumanResourcesSetup."Income Tax 9%");
            SetRange("Payroll Period Filter", FirstYearPayrollPeriod.Code, PayrollDocLine."Period Code");
            CalcFields("Taxable Amount");
            exit("Taxable Amount");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetIncomeTaxAmounts(var PayrollDocLine: Record "Payroll Document Line"; AmountType: Option "Taxable Amount","Income Tax Accrued","Income Tax Paid","Tax Deduction"): Decimal
    var
        PersonIncomeHeader: Record "Person Income Header";
        PersonIncomeEntry: Record "Person Income Entry";
        Year: Integer;
        AmtToReturn: Decimal;
    begin
        Employee2.Get(PayrollDocLine."Employee No.");
        Year := Date2DMY(PayrollPeriod."Ending Date", 3);
        AmtToReturn := 0;
        PersonIncomeHeader.Reset;
        PersonIncomeHeader.SetCurrentKey("Person No.");
        PersonIncomeHeader.SetRange("Person No.", Employee2."Person No.");
        PersonIncomeHeader.SetRange(Year, Year);
        PersonIncomeHeader.SetRange(Calculation, false);
        if PersonIncomeHeader.FindSet then
            repeat
                case AmountType of
                    AmountType::"Taxable Amount":
                        begin
                            PersonIncomeHeader.CalcFields("Total Taxable Income");
                            AmtToReturn += PersonIncomeHeader."Total Taxable Income";
                        end;
                    AmountType::"Income Tax Accrued":
                        begin
                            PersonIncomeHeader.CalcFields("Total Accrued Tax");
                            AmtToReturn += PersonIncomeHeader."Total Accrued Tax";
                        end;
                    AmountType::"Income Tax Paid":
                        begin
                            PersonIncomeHeader.CalcFields("Total Paid to Person");
                            AmtToReturn += PersonIncomeHeader."Total Paid to Person";
                        end;
                    AmountType::"Tax Deduction":
                        begin
                            PersonIncomeEntry.Reset;
                            PersonIncomeEntry.SetRange("Person Income No.", PersonIncomeHeader."No.");
                            PersonIncomeEntry.SetRange("Person No.", PersonIncomeHeader."Person No.");
                            PersonIncomeEntry.SetRange("Period Code", FirstPayrollPeriod.Code, PayrollDocLine."Period Code");
                            PersonIncomeEntry.SetRange("Entry Type", PersonIncomeEntry."Entry Type"::"Tax Deduction");
                            PersonIncomeEntry.SetRange("Tax Deduction Code", PayrollDocLine."Directory Code");
                            if PersonIncomeEntry.FindSet then
                                repeat
                                    AmtToReturn += PersonIncomeEntry."Tax Deduction Amount";
                                until PersonIncomeEntry.Next = 0;
                        end;
                end;
            until PersonIncomeHeader.Next = 0;
        exit(AmtToReturn);
    end;

    [Scope('OnPrem')]
    procedure GetStartingBalance(var PayrollDocLine: Record "Payroll Document Line"): Decimal
    var
        Vendor: Record Vendor;
        Person: Record Person;
    begin
        Employee2.Get(PayrollDocLine."Employee No.");
        Employee2.TestField("Person No.");
        Person.Get(Employee2."Person No.");
        Person.TestField("Vendor No.");
        Vendor.Get(Person."Vendor No.");
        PayrollPeriod.Get(PayrollDocLine."Period Code");
        Vendor.SetFilter("Date Filter", '..%1', PayrollPeriod."Starting Date" - 1);
        Vendor.CalcFields("Balance (LCY)");
        exit(Vendor."Balance (LCY)");
    end;

    [Scope('OnPrem')]
    procedure GetSalaryPrevPeriod(var PayrollDocLine: Record "Payroll Document Line"): Decimal
    var
        PrevPayrollPeriod: Record "Payroll Period";
    begin
        PrevPayrollPeriod.Get(PayrollPeriod.Code);
        if PrevPayrollPeriod.Next(-1) <> 0 then begin
            Employee2.Reset;
            Employee2.SetRange("Employee No. Filter", PayrollDocLine."Employee No.");
            Employee2.SetRange("Payroll Period Filter", PrevPayrollPeriod.Code);
            Employee2.SetFilter("Element Code Filter", '%1|%2|%3',
              HumanResourcesSetup."Element Code Salary Days",
              HumanResourcesSetup."Element Code Salary Hours",
              HumanResourcesSetup."Element Code Salary Amount");
            Employee2.CalcFields("Payroll Amount");
            exit(Employee2."Payroll Amount");
        end;
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure ServiceYears(var PayrollDocLine: Record "Payroll Document Line"): Decimal
    var
        ReturnValue: Decimal;
        QuantityYears: Integer;
        QuantityMonths: Integer;
        QuantityDays: Integer;
    begin
        ReturnValue := 0;

        QuantityYears := 0;
        QuantityMonths := 0;
        QuantityDays := 0;

        if Employee.Get(PayrollDocLine."Employee No.") then
            if Employee."Employment Date" <> 0D then begin
                QuantityYears := Date2DMY(WorkDate, 3) - Date2DMY(Employee."Employment Date", 3);
                QuantityMonths := Date2DMY(WorkDate, 2) - Date2DMY(Employee."Employment Date", 2);
                if QuantityMonths < 0 then begin
                    QuantityMonths := QuantityMonths + 12;
                    QuantityYears := QuantityYears - 1;
                end;
                QuantityDays := Date2DMY(WorkDate, 1) - Date2DMY(Employee."Employment Date", 1);
                if QuantityDays < 0 then begin
                    QuantityDays := QuantityDays + 30;
                    QuantityMonths := QuantityMonths - 1;
                    if QuantityMonths < 0 then begin
                        QuantityMonths := QuantityMonths + 12;
                        QuantityYears := QuantityYears - 1;
                    end;
                end;

                if QuantityYears < 5 then
                    ReturnValue := 0
                else
                    ReturnValue := QuantityYears;
            end;

        exit(ReturnValue);
    end;

    [Scope('OnPrem')]
    procedure LaborContractType(PayrollDocLine: Record "Payroll Document Line"): Decimal
    var
        LaborContract: Record "Labor Contract";
    begin
        Employee2.Get(PayrollDocLine."Employee No.");
        LaborContract.Get(Employee2."Contract No.");
        if LaborContract."Contract Type" = LaborContract."Contract Type"::"Civil Contract" then
            exit(1);

        exit(0);
    end;

    [Scope('OnPrem')]
    procedure SalaryProRataCalendar(var PayrollDocLine: Record "Payroll Document Line"): Decimal
    var
        ReturnValue: Decimal;
        TempEmplLedgEntry: Record "Employee Ledger Entry" temporary;
        HoursWork: Decimal;
        CalendarCode: Code[10];
        CalendarHours: Decimal;
    begin
        ReturnValue := 0;
        HoursWork := 0;
        CalendarCode := '';
        TempEmplLedgEntry.Reset;
        TempEmplLedgEntry.DeleteAll;

        if PayrollElement.Get(PayrollDocLine."Element Code") then begin
            EmplLedgEntry.Reset;
            EmplLedgEntry.SetRange("Employee No.", PayrollDocLine."Employee No.");
            EmplLedgEntry.SetRange("Element Code", PayrollElement.Code);
            EmplLedgEntry.SetRange("Action Starting Date", 0D, PayrollPeriod."Ending Date");
            if not EmplLedgEntry.Find('+') then
                exit(0);
            EmplLedgEntry.Find('-');
            repeat
                if (EmplLedgEntry."Action Ending Date" < EmplLedgEntry."Action Starting Date") and
                   (EmplLedgEntry."Action Ending Date" <> 0D)
                then
                    EmplLedgEntry.TestField("Action Ending Date", EmplLedgEntry."Action Ending Date");
                TempEmplLedgEntry := EmplLedgEntry;
                TempEmplLedgEntry.Insert;
                if TempEmplLedgEntry.Next(-1) <> 0 then begin
                    if (TempEmplLedgEntry."Action Ending Date" >= EmplLedgEntry."Action Starting Date") or
                       (TempEmplLedgEntry."Action Ending Date" = 0D)
                    then begin
                        TempEmplLedgEntry."Action Ending Date" := CalcDate('<-1D>', EmplLedgEntry."Action Starting Date");
                        TempEmplLedgEntry.Modify;
                    end;
                    TempEmplLedgEntry.Next(+1);
                end;
            until EmplLedgEntry.Next = 0;

            HoursWork :=
              CalendarMgt.GetPeriodInfo(
                PayrollDocLine."Calendar Code", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 3);
            if HoursWork = 0 then
                Error(ShouldNotBeErr,
                  PayrollDocLine."Element Code", PayrollDocLine.FieldCaption("Actual Hours"), HoursWork);

            TempEmplLedgEntry.Find('-');
            repeat
                if (TempEmplLedgEntry."Action Starting Date" >= PayrollPeriod."Starting Date") and
                   (TempEmplLedgEntry."Action Ending Date" >= PayrollPeriod."Starting Date") and
                   (TempEmplLedgEntry."Action Ending Date" <= PayrollPeriod."Ending Date")
                then begin
                    CalendarHours :=
                      CalendarMgt.GetPeriodInfo(
                        PayrollDocLine."Calendar Code", TempEmplLedgEntry."Action Starting Date", TempEmplLedgEntry."Action Ending Date", 3);
                    ReturnValue := ReturnValue + (TempEmplLedgEntry.Amount / HoursWork) * CalendarHours;
                end else
                    if (TempEmplLedgEntry."Action Starting Date" < PayrollPeriod."Starting Date") and
                       (TempEmplLedgEntry."Action Ending Date" >= PayrollPeriod."Starting Date") and
                       (TempEmplLedgEntry."Action Ending Date" <= PayrollPeriod."Ending Date")
                    then begin
                        CalendarHours :=
                          CalendarMgt.GetPeriodInfo(
                            PayrollDocLine."Calendar Code", PayrollPeriod."Starting Date", TempEmplLedgEntry."Action Ending Date", 3);
                        ReturnValue := ReturnValue + (TempEmplLedgEntry.Amount / HoursWork) * CalendarHours;
                    end else
                        if (TempEmplLedgEntry."Action Starting Date" >= PayrollPeriod."Starting Date") and
                           ((TempEmplLedgEntry."Action Ending Date" = 0D) or
                            (TempEmplLedgEntry."Action Ending Date" > PayrollPeriod."Ending Date"))
                        then begin
                            CalendarHours :=
                              CalendarMgt.GetPeriodInfo(
                                PayrollDocLine."Calendar Code", TempEmplLedgEntry."Action Starting Date", PayrollPeriod."Ending Date", 3);
                            ReturnValue := ReturnValue + (TempEmplLedgEntry.Amount / HoursWork) * CalendarHours;
                        end else
                            if (TempEmplLedgEntry."Action Starting Date" < PayrollPeriod."Starting Date") and
                               ((TempEmplLedgEntry."Action Ending Date" = 0D) or
                                (TempEmplLedgEntry."Action Ending Date" > PayrollPeriod."Ending Date"))
                            then begin
                                CalendarHours :=
                                  CalendarMgt.GetPeriodInfo(
                                    PayrollDocLine."Calendar Code",
                                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 3);
                                ReturnValue := ReturnValue + (TempEmplLedgEntry.Amount / HoursWork) * CalendarHours;
                            end;
            until TempEmplLedgEntry.Next = 0;
            exit(ReturnValue);
        end;
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure DeductionAmount(var PayrollDocLine: Record "Payroll Document Line"; TaxableIncome: Decimal): Decimal
    var
        RangeLine: Record "Payroll Range Line";
        Employee: Record Employee;
        DeductionAmount: Decimal;
    begin
        GetRangeHeader(PayrollDocLine);
        with RangeLine do begin
            Reset;
            SetCurrentKey("Element Code", "Range Code", "Period Code", "Over Amount");
            SetRange("Element Code", PayrollDocLine."Element Code");
            SetRange("Range Code", RangeHeader.Code);
            SetRange("Period Code", RangeHeader."Period Code");
            SetFilter("Over Amount", '<%1', TaxableIncome);
            if not FindLast then begin
                SetRange("Over Amount");
                FindFirst;
            end;

            DeductionAmount := Amount * PayrollDocLine.Quantity;

            Employee.Get(PayrollDocLine."Employee No.");
            if (Employee."Termination Date" <> 0D) and
               (Employee."Termination Date" < PayrollPeriod."Ending Date")
            then
                DeductionAmount := 0;

            if "On Allowance" then
                // Deductions due YTD
                DeductionAmount := DeductionAmount + DeductionQuantityYTD(PayrollDocLine);

            if DeductionAmount < "Min Amount" then
                DeductionAmount := "Min Amount";

            if ("Max Amount" <> 0) and (DeductionAmount > "Max Amount") then
                DeductionAmount := "Max Amount";

            PayrollDocLine."Directory Code" := "Directory Code";
        end;
        exit(DeductionAmount);
    end;

    [Scope('OnPrem')]
    procedure DeductionQuantityYTD(var PayrollDocLine: Record "Payroll Document Line"): Decimal
    var
        TmpPayrollDocLine: Record "Payroll Document Line" temporary;
        StartDate: Date;
        EndDate: Date;
        CurrDate: Date;
        DeductionEndDate: Date;
        DeductionAmount: Decimal;
        IncomeTaxBase: Decimal;
    begin
        // Deductions due YTD
        if PayrollDocLine."Directory Code" = '' then
            exit(0);

        with EmplLedgEntry do begin
            DeductionEndDate := CalcDate('<-1D>', PayrollPeriod."Starting Date");
            Employee.Get(PayrollDocLine."Employee No.");
            if (Employee."Termination Date" <> 0D) and
               (Employee."Termination Date" < PayrollPeriod."Starting Date")
            then
                DeductionEndDate := CalcDate('<CM>', Employee."Termination Date");

            Reset;
            SetRange("Employee No.", PayrollDocLine."Employee No.");
            SetRange("Element Code", PayrollDocLine."Element Code");
            SetRange("Action Starting Date", 0D, DeductionEndDate);
            if FindSet then
                repeat
                    if ("Action Ending Date" = 0D) or ("Action Ending Date" >= DeductionEndDate) then begin
                        StartDate := CalcDate('<-CY>', PayrollPeriod."Starting Date");
                        if StartDate < "Action Starting Date" then
                            StartDate := CalcDate('<-CM>', "Action Starting Date");
                        EndDate := DeductionEndDate;
                        if StartDate > EndDate then
                            exit(0);
                        Employee2.Reset;
                        Employee2.SetRange("Employee No. Filter", PayrollDocLine."Employee No.");
                        Employee2.SetFilter("Element Type Filter", '%1|%2',
                          Employee2."Element Type Filter"::Wage,
                          Employee2."Element Type Filter"::Bonus);
                        Employee2.SetRange("Base Type Filter", Employee2."Base Type Filter"::"Income Tax");
                        CurrDate := CalcDate('<1M-1D>', StartDate);
                        repeat
                            Employee2.SetRange("Date Filter", StartDate, CurrDate);
                            Employee2.CalcFields("Payroll Amount");
                            IncomeTaxBase := Employee2."Payroll Amount";
                            TmpPayrollDocLine.Copy(PayrollDocLine);
                            if IncomeTaxBase <> 0 then
                                DeductionAmount := DeductionAmount + GetDeductionQty(TmpPayrollDocLine, IncomeTaxBase);
                            CurrDate := CalcDate('<1D+1M-1D>', CurrDate);
                        until CurrDate > DeductionEndDate;
                    end;
                until Next = 0;
        end;
        exit(DeductionAmount);
    end;

    [Scope('OnPrem')]
    procedure GetDeductionQty(var PayrollDocLine: Record "Payroll Document Line"; BaseAmount: Decimal): Decimal
    var
        RangeLine: Record "Payroll Range Line";
        DeductionAmount: Decimal;
    begin
        // Current deduction due - 11.05.10
        with RangeLine do begin
            SetCurrentKey("Element Code", "Range Code", "Period Code", "Over Amount");
            SetRange("Element Code", PayrollDocLine."Element Code");
            SetRange("Range Code", RangeHeader.Code);
            SetRange("Period Code", RangeHeader."Period Code");
            SetFilter("Over Amount", '<%1', BaseAmount);
            if not FindLast then begin
                SetRange("Over Amount");
                FindFirst;
            end;

            DeductionAmount := Amount * PayrollDocLine.Quantity;

            if "On Allowance" then
                if DeductionAmount < "Min Amount" then
                    DeductionAmount := "Min Amount";

            if ("Max Amount" <> 0) and (DeductionAmount > "Max Amount") then
                DeductionAmount := "Max Amount";

            PayrollDocLine."Directory Code" := "Directory Code";
        end;
        exit(DeductionAmount);
    end;

    [Scope('OnPrem')]
    procedure GotoLabel(var PayrollDocLineCalc: Record "Payroll Document Line Calc.")
    var
        PayrollDocLineCalc2: Record "Payroll Document Line Calc.";
    begin
        PayrollDocLineCalc2.Reset;
        PayrollDocLineCalc2.SetRange("Element Code", PayrollDocLineCalc."Element Code");
        PayrollDocLineCalc2.SetRange("Period Code", PayrollDocLineCalc."Period Code");
        PayrollDocLineCalc2.SetRange(Label, PayrollDocLineCalc.Expression);
        if PayrollDocLineCalc2.FindFirst then
            PayrollDocLineCalc.Get(
              PayrollDocLineCalc2."Document No.", PayrollDocLineCalc2."Document Line No.",
              PayrollDocLineCalc2."Line No.")
        else
            Error(Text060, PayrollDocLineCalc.Expression);
    end;

    [Scope('OnPrem')]
    procedure CalcElementByPostedEntries(ElementCode: Code[20]; EmployeeNo: Code[20]; StartDate: Date; EndDate: Date; BaseAmountCode: Code[10]): Decimal
    var
        PayrollLedgEntry: Record "Payroll Ledger Entry";
        PayrollBaseAmount: Record "Payroll Base Amount";
        StartPeriod: Record "Payroll Period";
        EndPeriod: Record "Payroll Period";
        Base: Decimal;
    begin
        Base := 0;

        StartPeriod.Reset;
        StartPeriod.SetRange("Starting Date", 0D, StartDate);
        StartPeriod.FindLast;

        EndPeriod.Reset;
        EndPeriod.SetFilter("Ending Date", '%1..', EndDate);
        EndPeriod.FindFirst;

        with PayrollLedgEntry do begin
            Reset;
            SetCurrentKey("Employee No.");
            SetRange("Employee No.", EmployeeNo);
            SetRange("Period Code", StartPeriod.Code, EndPeriod.Code);

            PayrollBaseAmount.Reset;
            PayrollBaseAmount.SetRange("Element Code", ElementCode);
            if PayrollBaseAmount.FindSet then
                repeat
                    // Skip blank entries and entries we don't care about
                    if ((PayrollBaseAmount."Element Code Filter" <> '') or
                        (PayrollBaseAmount."Element Type Filter" <> '') or
                        (PayrollBaseAmount."Element Group Filter" <> '') or
                        (PayrollBaseAmount."Posting Type Filter" <> '')) and
                       ((BaseAmountCode = '') or
                        (BaseAmountCode = PayrollBaseAmount.Code))
                    then begin
                        // Set up the filters according to what is in the BaseAmount record
                        if PayrollBaseAmount."Element Code Filter" = '' then
                            SetRange("Element Code")
                        else
                            SetFilter("Element Code", PayrollBaseAmount."Element Code Filter");

                        if PayrollBaseAmount."Element Type Filter" = '' then
                            SetRange("Element Type")
                        else
                            SetFilter("Element Type", PayrollBaseAmount."Element Type Filter");

                        if PayrollBaseAmount."Element Group Filter" = '' then
                            SetRange("Element Group")
                        else
                            SetFilter("Element Group", PayrollBaseAmount."Element Group Filter");

                        if PayrollBaseAmount."Posting Type Filter" = '' then
                            SetRange("Posting Type")
                        else
                            SetFilter("Posting Type", PayrollBaseAmount."Posting Type Filter");

                        case PayrollBaseAmount."Income Tax Base Filter" of
                            0:
                                SetRange("Income Tax Base");
                            1:
                                SetRange("Income Tax Base", true);
                            2:
                                SetRange("Income Tax Base", false);
                        end;
                        case PayrollBaseAmount."PF Base Filter" of
                            0:
                                SetRange("Pension Fund Base");
                            1:
                                SetRange("Pension Fund Base", true);
                            2:
                                SetRange("Pension Fund Base", false);
                        end;
                        case PayrollBaseAmount."FSI Base Filter" of
                            0:
                                SetRange("FSI Base");
                            1:
                                SetRange("FSI Base", true);
                            2:
                                SetRange("FSI Base", false);
                        end;
                        case PayrollBaseAmount."Federal FMI Base Filter" of
                            0:
                                SetRange("Federal FMI Base");
                            1:
                                SetRange("Federal FMI Base", true);
                            2:
                                SetRange("Federal FMI Base", false);
                        end;
                        case PayrollBaseAmount."Territorial FMI Base Filter" of
                            0:
                                SetRange("Territorial FMI Base");
                            1:
                                SetRange("Territorial FMI Base", true);
                            2:
                                SetRange("Territorial FMI Base", false);
                        end;
                        case PayrollBaseAmount."FSI Injury Base Filter" of
                            0:
                                SetRange("FSI Injury Base");
                            1:
                                SetRange("FSI Injury Base", true);
                            2:
                                SetRange("FSI Injury Base", false);
                        end;
                        // Run through the entries
                        if FindSet then
                            repeat
                                Base := Base + "Payroll Amount";
                            until Next = 0;
                    end;
                until PayrollBaseAmount.Next = 0;
        end;

        exit(Base);
    end;

    [Scope('OnPrem')]
    procedure CalcElementByPayrollDocs(ElementCode: Code[20]; EmployeeNo: Code[20]; StartDate: Date; EndDate: Date; BaseAmountCode: Code[10]): Decimal
    var
        PayrollDocLine3: Record "Payroll Document Line";
        PayrollBaseAmount: Record "Payroll Base Amount";
        StartPeriod: Record "Payroll Period";
        EndPeriod: Record "Payroll Period";
        Base: Decimal;
    begin
        Base := 0;

        StartPeriod.Reset;
        StartPeriod.SetRange("Starting Date", 0D, StartDate);
        StartPeriod.FindLast;

        EndPeriod.Reset;
        EndPeriod.SetFilter("Ending Date", '%1..', EndDate);
        EndPeriod.FindFirst;

        with PayrollDocLine3 do begin
            Reset;
            SetRange("Employee No.", EmployeeNo);
            SetRange("Period Code", StartPeriod.Code, EndPeriod.Code);

            PayrollBaseAmount.Reset;
            PayrollBaseAmount.SetRange("Element Code", ElementCode);
            if PayrollBaseAmount.FindSet then
                repeat
                    // Skip blank entries and entries we don't care about
                    if ((PayrollBaseAmount."Element Code Filter" <> '') or
                        (PayrollBaseAmount."Element Type Filter" <> '') or
                        (PayrollBaseAmount."Element Group Filter" <> '') or
                        (PayrollBaseAmount."Posting Type Filter" <> '')) and
                       ((BaseAmountCode = '') or
                        (BaseAmountCode = PayrollBaseAmount.Code))
                    then begin
                        // Set up the filters according to what is in the BaseAmount record
                        if PayrollBaseAmount."Element Code Filter" = '' then
                            SetRange("Element Code")
                        else
                            SetFilter("Element Code", PayrollBaseAmount."Element Code Filter");
                        if PayrollBaseAmount."Element Type Filter" = '' then
                            SetRange("Element Type")
                        else
                            SetFilter("Element Type", PayrollBaseAmount."Element Type Filter");
                        if PayrollBaseAmount."Element Group Filter" = '' then
                            SetRange("Element Group")
                        else
                            SetFilter("Element Group", PayrollBaseAmount."Element Group Filter");
                        if PayrollBaseAmount."Posting Type Filter" = '' then
                            SetRange("Posting Type")
                        else
                            SetFilter("Posting Type", PayrollBaseAmount."Posting Type Filter");
                        case PayrollBaseAmount."Income Tax Base Filter" of
                            0:
                                SetRange("Income Tax Base");
                            1:
                                SetRange("Income Tax Base", true);
                            2:
                                SetRange("Income Tax Base", false);
                        end;
                        case PayrollBaseAmount."PF Base Filter" of
                            0:
                                SetRange("Pension Fund Base");
                            1:
                                SetRange("Pension Fund Base", true);
                            2:
                                SetRange("Pension Fund Base", false);
                        end;
                        case PayrollBaseAmount."FSI Base Filter" of
                            0:
                                SetRange("FSI Base");
                            1:
                                SetRange("FSI Base", true);
                            2:
                                SetRange("FSI Base", false);
                        end;
                        case PayrollBaseAmount."Federal FMI Base Filter" of
                            0:
                                SetRange("Federal FMI Base");
                            1:
                                SetRange("Federal FMI Base", true);
                            2:
                                SetRange("Federal FMI Base", false);
                        end;
                        case PayrollBaseAmount."Territorial FMI Base Filter" of
                            0:
                                SetRange("Territorial FMI Base");
                            1:
                                SetRange("Territorial FMI Base", true);
                            2:
                                SetRange("Territorial FMI Base", false);
                        end;
                        case PayrollBaseAmount."FSI Injury Base Filter" of
                            0:
                                SetRange("FSI Injury Base");
                            1:
                                SetRange("FSI Injury Base", true);
                            2:
                                SetRange("FSI Injury Base", false);
                        end;
                        // Run through the Payroll Journal
                        if FindSet then
                            repeat
                                Base := Base + "Payroll Amount";
                            until Next = 0;
                    end;
                until PayrollBaseAmount.Next = 0;
        end;

        exit(Base);
    end;

    [Scope('OnPrem')]
    procedure InitPayrollPeriod(PeriodCode: Code[10]; WagePeriodCode: Code[10])
    begin
        FirstPayrollPeriod.Reset;
        FirstPayrollPeriod.FindFirst;

        PayrollPeriod.Get(PeriodCode);
        PayrollPeriod.TestField("Starting Date");
        PayrollPeriod.TestField("Ending Date");

        PrevPayrollPeriod.Get(PeriodCode);
        PrevPayrollPeriod.Next(-1);

        FirstYearPayrollPeriod.Reset;
        FirstYearPayrollPeriod.SetFilter("Starting Date", '%1..',
          CalcDate('<-CY>', PayrollPeriod."Starting Date"));
        FirstYearPayrollPeriod.FindFirst;

        WagePayrollPeriod.Get(WagePeriodCode);
        WagePayrollPeriod.TestField("Starting Date");
        WagePayrollPeriod.TestField("Ending Date");
    end;

    local procedure IsCorrDocument(DocumentNo: Code[20]): Boolean
    var
        PayrollDocument: Record "Payroll Document";
    begin
        if PayrollDocument.Get(DocumentNo) then
            exit(PayrollDocument.Correction);
    end;

    [Scope('OnPrem')]
    procedure RoundAmountToPay(AmountToPay: Decimal): Decimal
    begin
        HumanResourcesSetup.Get;
        if HumanResourcesSetup."Amt. to Pay Rounding Precision" <> 0 then
            AmountToPay :=
              Round(
                AmountToPay,
                HumanResourcesSetup."Amt. to Pay Rounding Precision",
                HumanResourcesSetup.AmtToPayRoundingDirection);

        exit(AmountToPay);
    end;

    local procedure RemoveCalculations(PayrollDocumentLine: Record "Payroll Document Line")
    begin
        with PayrollDocumentLine do begin
            PayrollDocLineCalc.Reset;
            PayrollDocLineCalc.SetRange("Document No.", "Document No.");
            PayrollDocLineCalc.SetRange("Document Line No.", "Line No.");
            if not PayrollDocLineCalc.IsEmpty then
                PayrollDocLineCalc.DeleteAll;

            PayrollDocLineExpr.Reset;
            PayrollDocLineExpr.SetRange("Document No.", "Document No.");
            PayrollDocLineExpr.SetRange("Document Line No.", "Line No.");
            if not PayrollDocLineExpr.IsEmpty then
                PayrollDocLineExpr.DeleteAll;

            PayrollDocLineVar.Reset;
            PayrollDocLineVar.SetRange("Document No.", "Document No.");
            PayrollDocLineVar.SetRange("Document Line No.", "Line No.");
            if not PayrollDocLineVar.IsEmpty then
                PayrollDocLineVar.DeleteAll;
        end;
    end;

    local procedure PrepareCalculations(PayrollDocLine: Record "Payroll Document Line"; PayrollCalculation: Record "Payroll Calculation")
    begin
        PayrollCalcLine.Reset;
        PayrollCalcLine.SetRange("Element Code", PayrollCalculation."Element Code");
        PayrollCalcLine.SetRange("Period Code", PayrollCalculation."Period Code");
        if PayrollCalcLine.FindSet then
            repeat
                PayrollDocLineCalc.Init;
                PayrollDocLineCalc.TransferFields(PayrollCalcLine);
                PayrollDocLineCalc."Document No." := PayrollDocLine."Document No.";
                PayrollDocLineCalc."Document Line No." := PayrollDocLine."Line No.";
                PayrollDocLineCalc."Period Code" := PayrollDocLine."Period Code";
                PayrollDocLineCalc.Insert;
            until PayrollCalcLine.Next = 0;

        PayrollElementVar.Reset;
        PayrollElementVar.SetRange("Element Code", PayrollCalculation."Element Code");
        PayrollElementVar.SetRange("Period Code", PayrollCalculation."Period Code");
        if PayrollElementVar.FindSet then
            repeat
                PayrollDocLineVar.Init;
                PayrollDocLineVar."Element Code" := PayrollElementVar."Element Code";
                PayrollDocLineVar.Variable := PayrollElementVar.Variable;
                PayrollDocLineVar."Document No." := PayrollDocLine."Document No.";
                PayrollDocLineVar."Document Line No." := PayrollDocLine."Line No.";
                PayrollDocLineVar.Insert;
            until PayrollElementVar.Next = 0;

        PayrollElementExpr.Reset;
        PayrollElementExpr.SetRange("Element Code", PayrollCalculation."Element Code");
        PayrollElementExpr.SetRange("Period Code", PayrollCalculation."Period Code");
        if PayrollElementExpr.FindSet then
            repeat
                PayrollDocLineExpr.Init;
                PayrollDocLineExpr.TransferFields(PayrollElementExpr);
                PayrollDocLineExpr."Document No." := PayrollDocLine."Document No.";
                PayrollDocLineExpr."Document Line No." := PayrollDocLine."Line No.";
                PayrollDocLineExpr.Insert;
            until PayrollElementExpr.Next = 0;
    end;
}

