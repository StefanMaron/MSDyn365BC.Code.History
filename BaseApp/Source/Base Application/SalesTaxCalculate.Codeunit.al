codeunit 398 "Sales Tax Calculate"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label '%1 in %2 %3 must be filled in with unique values when %4 is %5.';
        Text001: Label 'The sales tax amount for the %1 %2 and the %3 %4 is incorrect. ';
        Text003: Label 'Lines is not initialized';
        Text004: Label 'The calculated sales tax amount is %5, but was supposed to be %6.';
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TMPTaxDetail: Record "Tax Detail" temporary;
        TempSalesTaxLine: Record "Sales Tax Amount Line" temporary;
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        TaxAmountDifference: Record "Sales Tax Amount Difference";
        TempTaxAmountDifference: Record "Sales Tax Amount Difference" temporary;
        ExchangeFactor: Decimal;
        TotalTaxAmountRounding: Decimal;
        TotalForAllocation: Decimal;
        RemainingTaxDetails: Integer;
        LastCalculationOrder: Integer;
        Initialised: Boolean;
        FirstLine: Boolean;
        TaxOnTaxCalculated: Boolean;
        CalculationOrderViolation: Boolean;
        SalesHeaderRead: Boolean;
        PurchHeaderRead: Boolean;
        ServHeaderRead: Boolean;
        TaxAreaRead: Boolean;
        RoundByJurisdiction: Boolean;
        TaxDetailMaximumsTemp: Record "Tax Detail" temporary;
        MaxAmountPerQty: Decimal;
        TaxCountry: Option US,CA;
        ServiceHeader: Record "Service Header";
        Text1020000: Label 'Tax country/region %1 is being used.  You must use %2.';
        Text1020001: Label 'Note to Programmers: The function "CopyTaxDifferences" must not be called unless the function "EndSalesTaxCalculation", or the function "PutSalesTaxAmountLineTable", is called first.';
        Text1020003: Label 'Invalid function call. Function reserved for external tax engines only.';
        TempPrepaidSalesLine: Record "Sales Line" temporary;
        PrepmtPosting: Boolean;

    procedure CallExternalTaxEngineForDoc(DocTable: Integer; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]) STETransactionID: Text[20]
    begin
        Error(Text1020003);
    end;

    procedure CallExternalTaxEngineForJnl(var GenJnlLine: Record "Gen. Journal Line"; CalculationType: Option Normal,Reverse,Expense): Decimal
    begin
        Error(Text1020003);
    end;

    procedure CallExternalTaxEngineForSales(var SalesHeader: Record "Sales Header"; UpdateRecIfChanged: Boolean) STETransactionIDChanged: Boolean
    var
        OldTransactionID: Text[20];
    begin
        with SalesHeader do begin
            OldTransactionID := "STE Transaction ID";
            "STE Transaction ID" := CallExternalTaxEngineForDoc(DATABASE::"Sales Header", "Document Type", "No.");
            STETransactionIDChanged := ("STE Transaction ID" <> OldTransactionID);
            if STETransactionIDChanged and UpdateRecIfChanged then
                Modify;
        end;
    end;

    procedure CallExternalTaxEngineForPurch(var PurchHeader: Record "Purchase Header"; UpdateRecIfChanged: Boolean) STETransactionIDChanged: Boolean
    var
        OldTransactionID: Text[20];
    begin
        with PurchHeader do begin
            OldTransactionID := "STE Transaction ID";
            "STE Transaction ID" := CallExternalTaxEngineForDoc(DATABASE::"Purchase Header", "Document Type", "No.");
            STETransactionIDChanged := ("STE Transaction ID" <> OldTransactionID);
            if STETransactionIDChanged and UpdateRecIfChanged then
                Modify;
        end;
    end;

    procedure CallExternalTaxEngineForServ(var ServiceHeader: Record "Service Header"; UpdateRecIfChanged: Boolean) STETransactionIDChanged: Boolean
    var
        OldTransactionID: Text[20];
    begin
        with ServiceHeader do begin
            OldTransactionID := "STE Transaction ID";
            "STE Transaction ID" := CallExternalTaxEngineForDoc(DATABASE::"Service Header", "Document Type", "No.");
            STETransactionIDChanged := ("STE Transaction ID" <> OldTransactionID);
            if STETransactionIDChanged and UpdateRecIfChanged then
                Modify;
        end;
    end;

    procedure FinalizeExternalTaxCalcForDoc(DocTable: Integer; DocNo: Code[20])
    begin
        Error(Text1020003);
    end;

    procedure FinalizeExternalTaxCalcForJnl(var GLEntry: Record "G/L Entry")
    begin
        Error(Text1020003);
    end;

    procedure CalculateTax(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Date: Date; Amount: Decimal; Quantity: Decimal; ExchangeRate: Decimal) TaxAmount: Decimal
    var
        MaxAmount: Decimal;
        TaxBaseAmount: Decimal;
    begin
        TaxAmount := 0;

        if not TaxLiable or (TaxAreaCode = '') or (TaxGroupCode = '') or
           ((Amount = 0) and (Quantity = 0))
        then
            exit;

        if ExchangeRate = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := ExchangeRate;

        Amount := Amount / ExchangeFactor;

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        if TaxAreaLine.Find('+') then begin
            LastCalculationOrder := TaxAreaLine."Calculation Order" + 1;
            TaxOnTaxCalculated := false;
            CalculationOrderViolation := false;
            repeat
                if TaxAreaLine."Calculation Order" >= LastCalculationOrder then
                    CalculationOrderViolation := true
                else
                    LastCalculationOrder := TaxAreaLine."Calculation Order";
                SetTaxDetailFilter(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, Date);
                TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                  TaxDetail."Tax Type"::"Sales Tax Only");
                if TaxDetail.FindLast and not TaxDetail."Expense/Capitalize" then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    if TaxDetail."Calculate Tax on Tax" then
                        TaxBaseAmount := Amount + TaxAmount
                    else
                        TaxBaseAmount := Amount;
                    // This code uses a temporary table to keep track of Maximums.
                    // This temporary table should be cleared before the first call
                    // to this routine.  All subsequent calls will use the values in
                    // that get put into this temporary table.
                    TaxDetailMaximumsTemp := TaxDetail;
                    if not TaxDetailMaximumsTemp.Find then
                        TaxDetailMaximumsTemp.Insert;
                    MaxAmountPerQty := TaxDetailMaximumsTemp."Maximum Amount/Qty.";
                    if (Abs(TaxBaseAmount) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then begin
                        TaxAmount := TaxAmount + TaxBaseAmount * TaxDetail."Tax Below Maximum" / 100;
                        TaxDetailMaximumsTemp."Maximum Amount/Qty." := TaxDetailMaximumsTemp."Maximum Amount/Qty." - TaxBaseAmount;
                        TaxDetailMaximumsTemp.Modify;
                    end else begin
                        MaxAmount := TaxBaseAmount / Abs(TaxBaseAmount) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + ((MaxAmount * TaxDetail."Tax Below Maximum") +
                                       ((TaxBaseAmount - MaxAmount) * TaxDetail."Tax Above Maximum")) / 100;
                        TaxDetailMaximumsTemp."Maximum Amount/Qty." := 0;
                        TaxDetailMaximumsTemp.Modify;
                    end;
                end;
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast and not TaxDetail."Expense/Capitalize" then begin
                    TaxDetailMaximumsTemp := TaxDetail;
                    if not TaxDetailMaximumsTemp.Find then
                        TaxDetailMaximumsTemp.Insert;
                    MaxAmountPerQty := TaxDetailMaximumsTemp."Maximum Amount/Qty.";

                    if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then begin
                        TaxAmount := TaxAmount + Quantity * TaxDetail."Tax Below Maximum";
                        TaxDetailMaximumsTemp."Maximum Amount/Qty." := TaxDetailMaximumsTemp."Maximum Amount/Qty." - Quantity;
                        TaxDetailMaximumsTemp.Modify;
                    end else begin
                        MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + (MaxAmount * TaxDetail."Tax Below Maximum") +
                          ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                        TaxDetailMaximumsTemp."Maximum Amount/Qty." := 0;
                        TaxDetailMaximumsTemp.Modify;
                    end;
                end;
            until TaxAreaLine.Next(-1) = 0;
        end;
        TaxAmount := TaxAmount * ExchangeFactor;

        if TaxOnTaxCalculated and CalculationOrderViolation then
            Error(
              Text000,
              TaxAreaLine.FieldCaption("Calculation Order"), TaxArea.TableCaption, TaxAreaLine."Tax Area",
              TaxDetail.FieldCaption("Calculate Tax on Tax"), CalculationOrderViolation);
    end;

    procedure ReverseCalculateTax(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Date: Date; TotalAmount: Decimal; Quantity: Decimal; ExchangeRate: Decimal) Amount: Decimal
    var
        Inclination: array[10] of Decimal;
        Constant: array[10] of Decimal;
        MaxRangeAmount: array[10] of Decimal;
        MaxTaxAmount: Decimal;
        i: Integer;
        j: Integer;
        Steps: Integer;
        InclinationLess: Decimal;
        InclinationHigher: Decimal;
        ConstantHigher: Decimal;
        SplitAmount: Decimal;
        MaxAmount: Decimal;
        Inserted: Boolean;
        Found: Boolean;
    begin
        Amount := TotalAmount;

        if not TaxLiable or (TaxAreaCode = '') or (TaxGroupCode = '') or
           ((Amount = 0) and (Quantity = 0))
        then
            exit;

        if ExchangeRate = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := ExchangeRate;

        TotalAmount := TotalAmount / ExchangeFactor;

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        Steps := 1;
        Clear(Inclination);
        Clear(Constant);
        Clear(MaxRangeAmount);
        if TaxAreaLine.Find('+') then begin
            LastCalculationOrder := TaxAreaLine."Calculation Order" + 1;
            TaxOnTaxCalculated := false;
            CalculationOrderViolation := false;
            repeat
                if TaxAreaLine."Calculation Order" >= LastCalculationOrder then
                    CalculationOrderViolation := true
                else
                    LastCalculationOrder := TaxAreaLine."Calculation Order";
                SetTaxDetailFilter(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, Date);
                TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                  TaxDetail."Tax Type"::"Sales Tax Only");
                if TaxDetail.FindLast then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    InclinationLess := TaxDetail."Tax Below Maximum" / 100;
                    InclinationHigher := TaxDetail."Tax Above Maximum" / 100;

                    if TaxDetail."Maximum Amount/Qty." = 0 then begin
                        for i := 1 to Steps do
                            if TaxDetail."Calculate Tax on Tax" then begin
                                Inclination[i] := Inclination[i] + (1 + Inclination[i]) * InclinationLess;
                                Constant[i] := (1 + InclinationLess) * Constant[i];
                            end else
                                Inclination[i] := Inclination[i] + InclinationLess;
                    end else begin
                        if TaxDetail."Calculate Tax on Tax" then begin
                            ConstantHigher :=
                              (TaxDetail."Tax Below Maximum" - TaxDetail."Tax Above Maximum") / 100 *
                              TaxDetail."Maximum Amount/Qty.";
                            i := 1;
                            Found := false;
                            while i < Steps do begin
                                MaxTaxAmount := (1 + Inclination[i]) * MaxRangeAmount[i] + Constant[i];
                                if Abs(TaxDetail."Maximum Amount/Qty.") < MaxTaxAmount then begin
                                    SplitAmount :=
                                      (Abs(TaxDetail."Maximum Amount/Qty.") / TaxDetail."Maximum Amount/Qty.") *
                                      ((Abs(TaxDetail."Maximum Amount/Qty.") - Constant[i]) / (1 + Inclination[i]));
                                    i := Steps;
                                    Found := true;
                                end;
                                i := i + 1;
                            end;
                            if not Found then
                                SplitAmount :=
                                  (Abs(TaxDetail."Maximum Amount/Qty.") / TaxDetail."Maximum Amount/Qty.") *
                                  (Abs(TaxDetail."Maximum Amount/Qty.") - Constant[Steps]) / (1 + Inclination[Steps]);
                        end else begin
                            ConstantHigher :=
                              (TaxDetail."Tax Below Maximum" - TaxDetail."Tax Above Maximum") / 100 *
                              TaxDetail."Maximum Amount/Qty.";
                            SplitAmount := TaxDetail."Maximum Amount/Qty.";
                        end;
                        i := 1;
                        Inserted := false;
                        while i <= Steps do begin
                            case true of
                                (MaxRangeAmount[i] < SplitAmount) and (MaxRangeAmount[i] > 0):
                                    begin
                                        if TaxDetail."Calculate Tax on Tax" then begin
                                            Inclination[i] := Inclination[i] + (1 + Inclination[i]) * InclinationLess;
                                            Constant[i] := (1 + InclinationLess) * Constant[i];
                                        end else
                                            Inclination[i] := Inclination[i] + InclinationLess;
                                    end;
                                MaxRangeAmount[i] = SplitAmount:
                                    begin
                                        if TaxDetail."Calculate Tax on Tax" then begin
                                            Inclination[i] := Inclination[i] + (1 + Inclination[i]) * InclinationLess;
                                            Constant[i] := (1 + InclinationLess) * Constant[i];
                                        end else
                                            Inclination[i] := Inclination[i] + InclinationLess;
                                        Inserted := true;
                                    end;
                                (MaxRangeAmount[i] > SplitAmount) or (MaxRangeAmount[i] = 0):
                                    if Inserted then begin
                                        if TaxDetail."Calculate Tax on Tax" then begin
                                            Inclination[i] := Inclination[i] + (1 + Inclination[i]) * InclinationHigher;
                                            Constant[i] := (1 + InclinationHigher) * Constant[i];
                                        end else
                                            Inclination[i] := Inclination[i] + InclinationHigher;
                                        Constant[i] := Constant[i] + ConstantHigher;
                                    end else begin
                                        Steps := Steps + 1;
                                        for j := Steps downto i + 1 do begin
                                            Inclination[j] := Inclination[j - 1];
                                            Constant[j] := Constant[j - 1];
                                            MaxRangeAmount[j] := MaxRangeAmount[j - 1];
                                        end;
                                        if TaxDetail."Calculate Tax on Tax" then begin
                                            Inclination[i] := Inclination[i] + (1 + Inclination[i]) * InclinationLess;
                                            Constant[i] := (1 + InclinationLess) * Constant[i];
                                        end else
                                            Inclination[i] := Inclination[i] + InclinationLess;
                                        MaxRangeAmount[i] := SplitAmount;
                                        Inserted := true;
                                    end;
                            end;
                            i := i + 1;
                        end;
                    end;
                end;
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast then begin
                    if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then
                        ConstantHigher := Quantity * TaxDetail."Tax Below Maximum"
                    else begin
                        MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                        ConstantHigher :=
                          (MaxAmount * TaxDetail."Tax Below Maximum") +
                          ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                    end;
                    ConstantHigher := Abs(ConstantHigher);

                    for i := 1 to Steps do
                        Constant[i] := Constant[i] + ConstantHigher;
                end;
            until TaxAreaLine.Next(-1) = 0;
        end;

        if TaxOnTaxCalculated and CalculationOrderViolation then
            Error(
              Text000,
              TaxAreaLine.FieldCaption("Calculation Order"), TaxArea.TableCaption, TaxAreaLine."Tax Area",
              TaxDetail.FieldCaption("Calculate Tax on Tax"), CalculationOrderViolation);

        i := 1;
        Found := false;
        while i < Steps do begin
            MaxTaxAmount := (1 + Inclination[i]) * MaxRangeAmount[i] + Constant[i];
            if Abs(TotalAmount) < MaxTaxAmount then begin
                if TotalAmount = 0 then
                    Amount := 0
                else
                    Amount :=
                      (Abs(TotalAmount) / TotalAmount) *
                      ((Abs(TotalAmount) - Constant[i]) / (1 + Inclination[i]));
                i := Steps;
                Found := true;
            end;
            i := i + 1;
        end;

        if not Found then
            if TotalAmount = 0 then
                Amount := 0
            else
                Amount :=
                  (Abs(TotalAmount) / TotalAmount) *
                  (Abs(TotalAmount) - Constant[Steps]) / (1 + Inclination[Steps]);

        Amount := Amount * ExchangeFactor;
    end;

    procedure InitSalesTaxLines(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Amount: Decimal; Quantity: Decimal; Date: Date; DesiredTaxAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        MaxAmount: Decimal;
        TaxAmount: Decimal;
        AddedTaxAmount: Decimal;
        TaxBaseAmount: Decimal;
    begin
        TaxAmount := 0;

        Initialised := true;
        FirstLine := true;
        TMPTaxDetail.DeleteAll;

        RemainingTaxDetails := 0;

        if (TaxAreaCode = '') or (TaxGroupCode = '') then
            exit;

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        if TaxAreaLine.Find('+') then begin
            LastCalculationOrder := TaxAreaLine."Calculation Order" + 1;
            TaxOnTaxCalculated := false;
            CalculationOrderViolation := false;
            repeat
                if TaxAreaLine."Calculation Order" >= LastCalculationOrder then
                    CalculationOrderViolation := true
                else
                    LastCalculationOrder := TaxAreaLine."Calculation Order";
                SetTaxDetailFilter(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, Date);
                TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                  TaxDetail."Tax Type"::"Sales Tax Only");
                if TaxDetail.FindLast and
                   ((TaxDetail."Tax Below Maximum" <> 0) or (TaxDetail."Tax Above Maximum" <> 0)) and
                   not TaxDetail."Expense/Capitalize"
                then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    if TaxDetail."Calculate Tax on Tax" then
                        TaxBaseAmount := Amount + TaxAmount
                    else
                        TaxBaseAmount := Amount;
                    if TaxLiable then begin
                        // This code uses a temporary table to keep track of Maximums.
                        // This temporary table should be cleared before the first call
                        // to this routine.  All subsequent calls will use the values in
                        // that get put into this temporary table.

                        TaxDetailMaximumsTemp := TaxDetail;
                        if not TaxDetailMaximumsTemp.Find then
                            TaxDetailMaximumsTemp.Insert;
                        MaxAmountPerQty := TaxDetailMaximumsTemp."Maximum Amount/Qty.";

                        if (Abs(TaxBaseAmount) <= TaxDetail."Maximum Amount/Qty.") or
                           (TaxDetail."Maximum Amount/Qty." = 0)
                        then begin
                            AddedTaxAmount := TaxBaseAmount * TaxDetail."Tax Below Maximum" / 100;
                            TaxDetailMaximumsTemp."Maximum Amount/Qty." := TaxDetailMaximumsTemp."Maximum Amount/Qty." - Quantity;
                            TaxDetailMaximumsTemp.Modify;
                        end else begin
                            MaxAmount := TaxBaseAmount / Abs(TaxBaseAmount) * TaxDetail."Maximum Amount/Qty.";
                            AddedTaxAmount :=
                              ((MaxAmount * TaxDetail."Tax Below Maximum") +
                               ((TaxBaseAmount - MaxAmount) * TaxDetail."Tax Above Maximum")) / 100;
                            TaxDetailMaximumsTemp."Maximum Amount/Qty." := 0;
                            TaxDetailMaximumsTemp.Modify;
                        end;
                    end else
                        AddedTaxAmount := 0;
                    TaxAmount := TaxAmount + AddedTaxAmount;
                    TMPTaxDetail := TaxDetail;
                    TMPTaxDetail."Tax Below Maximum" := AddedTaxAmount;
                    TMPTaxDetail."Tax Above Maximum" := TaxBaseAmount;
                    TMPTaxDetail.Insert;
                    RemainingTaxDetails := RemainingTaxDetails + 1;
                end;
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast and
                   ((TaxDetail."Tax Below Maximum" <> 0) or (TaxDetail."Tax Above Maximum" <> 0)) and
                   not TaxDetail."Expense/Capitalize"
                then begin
                    if TaxLiable then begin
                        TaxDetailMaximumsTemp := TaxDetail;
                        if not TaxDetailMaximumsTemp.Find then
                            TaxDetailMaximumsTemp.Insert;
                        if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                           (TaxDetail."Maximum Amount/Qty." = 0)
                        then begin
                            AddedTaxAmount := Quantity * TaxDetail."Tax Below Maximum";
                            TaxDetailMaximumsTemp."Maximum Amount/Qty." := TaxDetailMaximumsTemp."Maximum Amount/Qty." - Quantity;
                            TaxDetailMaximumsTemp.Modify;
                        end else begin
                            MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                            AddedTaxAmount :=
                              (MaxAmount * TaxDetail."Tax Below Maximum") +
                              ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                            TaxDetailMaximumsTemp."Maximum Amount/Qty." := 0;
                            TaxDetailMaximumsTemp.Modify;
                        end;
                    end else
                        AddedTaxAmount := 0;
                    TaxAmount := TaxAmount + AddedTaxAmount;
                    TMPTaxDetail := TaxDetail;
                    TMPTaxDetail."Tax Below Maximum" := AddedTaxAmount;
                    TMPTaxDetail."Tax Above Maximum" := TaxBaseAmount;
                    TMPTaxDetail.Insert;
                    RemainingTaxDetails := RemainingTaxDetails + 1;
                end;
            until TaxAreaLine.Next(-1) = 0;
        end;

        TaxAmount := Round(TaxAmount);

        if (TaxAmount <> DesiredTaxAmount) and (Abs(TaxAmount - DesiredTaxAmount) <= 0.01) then
            if TMPTaxDetail.FindSet(true) then begin
                TMPTaxDetail."Tax Below Maximum" :=
                  TMPTaxDetail."Tax Below Maximum" - TaxAmount + DesiredTaxAmount;
                TMPTaxDetail.Modify;
                TaxAmount := DesiredTaxAmount;
            end;

        if TaxOnTaxCalculated and CalculationOrderViolation then
            Error(
              Text000,
              TaxAreaLine.FieldCaption("Calculation Order"), TaxArea.TableCaption, TaxAreaLine."Tax Area",
              TaxDetail.FieldCaption("Calculate Tax on Tax"), CalculationOrderViolation);

        if TaxAmount <> DesiredTaxAmount then
            Error(
              Text001 +
              Text004,
              TaxAreaCode, GenJnlLine.FieldCaption("Tax Area Code"),
              TaxGroupCode, GenJnlLine.FieldCaption("Tax Group Code"),
              TaxAmount, DesiredTaxAmount);

        TotalForAllocation := DesiredTaxAmount;
    end;

    procedure GetSalesTaxLine(var TaxDetail2: Record "Tax Detail"; var ReturnTaxAmount: Decimal; var ReturnTaxBaseAmount: Decimal): Boolean
    var
        TaxAmount: Decimal;
    begin
        ReturnTaxAmount := 0;

        if not Initialised then
            Error(Text003);

        if FirstLine then begin
            if not TMPTaxDetail.FindSet then begin
                Initialised := false;
                exit(false);
            end;
            TotalTaxAmountRounding := 0;
            FirstLine := false;
        end else
            if TMPTaxDetail.Next = 0 then begin
                Initialised := false;
                exit(false);
            end;

        ReturnTaxBaseAmount := Round(TMPTaxDetail."Tax Above Maximum");

        TaxAmount := TMPTaxDetail."Tax Below Maximum";
        if TaxAmount <> 0 then begin
            ReturnTaxAmount := Round(TaxAmount + TotalTaxAmountRounding);
            TotalTaxAmountRounding := TaxAmount + TotalTaxAmountRounding - ReturnTaxAmount;
        end;

        if RemainingTaxDetails = 0 then
            TaxAmount := TotalForAllocation
        else
            if Abs(TaxAmount) > Abs(TotalForAllocation) then
                TaxAmount := TotalForAllocation;

        TotalForAllocation := TotalForAllocation - TaxAmount;
        if TMPTaxDetail."Tax Below Maximum" = 0 then
            ReturnTaxAmount := 0;

        TaxDetail2 := TMPTaxDetail;

        exit(true);
    end;

    procedure ClearMaximums()
    begin
        TaxDetailMaximumsTemp.DeleteAll;
    end;

    procedure StartSalesTaxCalculation()
    begin
        TempSalesTaxLine.Reset;
        TempSalesTaxLine.DeleteAll;
        TempTaxAmountDifference.Reset;
        TempTaxAmountDifference.DeleteAll;
        ClearAll;
    end;

    procedure AddSalesLine(SalesLine: Record "Sales Line")
    var
        SalesTaxAmountLineCalc: Codeunit "Sales Tax Amount Line Calc";
    begin
        if not SalesHeaderRead then begin
            TempPrepaidSalesLine.DeleteAll;
            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
            SalesHeaderRead := true;
            SalesHeader.TestField("Prices Including VAT", false);
            if not GetSalesTaxCountry(SalesHeader."Tax Area Code") then
                exit;
            SetUpCurrency(SalesHeader."Currency Code");
            if SalesHeader."Currency Code" <> '' then
                SalesHeader.TestField("Currency Factor");
            if SalesHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := SalesHeader."Currency Factor";
            CopyTaxDifferencesToTemp(
              TaxAmountDifference."Document Product Area"::Sales,
              SalesLine."Document Type",
              SalesLine."Document No.");
        end;
        if not GetSalesTaxCountry(SalesLine."Tax Area Code") then
            exit;

        SalesLine.TestField("Tax Group Code");
        if IsFinalPrepaidSalesLine(SalesLine) then begin
            TempPrepaidSalesLine := SalesLine;
            TempPrepaidSalesLine.Insert;
        end;

        with TempSalesTaxLine do begin
            Reset;
            case TaxCountry of
                TaxCountry::US:  // Area Code
                    begin
                        SetRange("Tax Area Code for Key", SalesLine."Tax Area Code");
                        "Tax Area Code for Key" := SalesLine."Tax Area Code";
                    end;
                TaxCountry::CA:  // Jurisdictions
                    begin
                        SetRange("Tax Area Code for Key", '');
                        "Tax Area Code for Key" := '';
                    end;
            end;
            SetRange("Tax Group Code", SalesLine."Tax Group Code");
            TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
            TaxAreaLine.SetRange("Tax Area", SalesLine."Tax Area Code");
            if TaxAreaLine.FindSet then
                repeat
                    SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                    SetRange(Positive, SalesLine."Line Amount" - SalesLine."Inv. Discount Amount" > 0);

                    "Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                    if not FindFirst then begin
                        Init;
                        "Tax Group Code" := SalesLine."Tax Group Code";
                        "Tax Area Code" := SalesLine."Tax Area Code";
                        "Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                        if TaxCountry = TaxCountry::US then begin
                            "Round Tax" := TaxArea."Round Tax";
                            TaxJurisdiction.Get("Tax Jurisdiction Code");
                            "Is Report-to Jurisdiction" := ("Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                        end;
                        SalesTaxAmountLineCalc.SetTaxBaseAmount(
                          TempSalesTaxLine, SalesLine."Line Amount" - SalesLine."Inv. Discount Amount", ExchangeFactor, false);
                        "Line Amount" := SalesLine."Line Amount" / ExchangeFactor;
                        "Tax Liable" := SalesLine."Tax Liable";
                        Quantity := SalesLine."Quantity (Base)";
                        "Invoice Discount Amount" := SalesLine."Inv. Discount Amount";
                        "Calculation Order" := TaxAreaLine."Calculation Order";

                        Positive := SalesLine."Line Amount" - SalesLine."Inv. Discount Amount" > 0;

                        Insert;
                    end else begin
                        "Line Amount" := "Line Amount" + (SalesLine."Line Amount" / ExchangeFactor);
                        if SalesLine."Tax Liable" then
                            "Tax Liable" := SalesLine."Tax Liable";
                        SalesTaxAmountLineCalc.SetTaxBaseAmount(
                          TempSalesTaxLine, SalesLine."Line Amount" - SalesLine."Inv. Discount Amount", ExchangeFactor, true);
                        "Tax Amount" := 0;
                        Quantity := Quantity + SalesLine."Quantity (Base)";
                        "Invoice Discount Amount" := "Invoice Discount Amount" + SalesLine."Inv. Discount Amount";
                        Modify;
                    end;
                until TaxAreaLine.Next = 0;
        end;
    end;

    procedure AddSalesInvoiceLines(DocNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesTaxAmountLineCalc: Codeunit "Sales Tax Amount Line Calc";
    begin
        SalesInvoiceHeader.Get(DocNo);
        SalesInvoiceHeader.TestField("Prices Including VAT", false);
        if not GetSalesTaxCountry(SalesInvoiceHeader."Tax Area Code") then
            exit;
        SetUpCurrency(SalesInvoiceHeader."Currency Code");
        if SalesInvoiceHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := SalesInvoiceHeader."Currency Factor";

        SalesInvoiceLine.SetRange("Document No.", DocNo);
        SalesInvoiceLine.SetFilter("Tax Group Code", '<>%1', '');
        if SalesInvoiceLine.FindSet then
            repeat
                SalesTaxAmountLineCalc.InitFromSalesInvLine(SalesInvoiceLine);
                SalesTaxAmountLineCalc.CalcSalesOrServLineSalesTaxAmountLine(
                  TempSalesTaxLine, TaxAreaLine, TaxCountry, TaxArea, TaxJurisdiction, ExchangeFactor);
            until SalesInvoiceLine.Next = 0;

        CopyTaxDifferencesToTemp(
          TaxAmountDifference."Document Product Area"::"Posted Sale",
          TaxAmountDifference."Document Type"::Invoice,
          SalesInvoiceHeader."No.");
    end;

    procedure AddSalesCrMemoLines(DocNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesTaxAmountLineCalc: Codeunit "Sales Tax Amount Line Calc";
    begin
        SalesCrMemoHeader.Get(DocNo);
        SalesCrMemoHeader.TestField("Prices Including VAT", false);
        if not GetSalesTaxCountry(SalesCrMemoHeader."Tax Area Code") then
            exit;
        SetUpCurrency(SalesCrMemoHeader."Currency Code");
        if SalesCrMemoHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := SalesCrMemoHeader."Currency Factor";

        SalesCrMemoLine.SetRange("Document No.", DocNo);
        SalesCrMemoLine.SetFilter("Tax Group Code", '<>%1', '');
        if SalesCrMemoLine.FindSet then
            repeat
                SalesTaxAmountLineCalc.InitFromSalesCrMemoLine(SalesCrMemoLine);
                SalesTaxAmountLineCalc.CalcSalesOrServLineSalesTaxAmountLine(
                  TempSalesTaxLine, TaxAreaLine, TaxCountry, TaxArea, TaxJurisdiction, ExchangeFactor);
            until SalesCrMemoLine.Next = 0;

        CopyTaxDifferencesToTemp(
          TaxAmountDifference."Document Product Area"::"Posted Sale",
          TaxAmountDifference."Document Type"::"Credit Memo",
          SalesCrMemoHeader."No.");
    end;

    procedure AddPurchLine(PurchLine: Record "Purchase Line")
    var
        TaxDetail: Record "Tax Detail";
        SalesTaxAmountLineCalc: Codeunit "Sales Tax Amount Line Calc";
    begin
        if not PurchHeaderRead then begin
            PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
            PurchHeaderRead := true;
            PurchHeader.TestField("Prices Including VAT", false);
            if not GetSalesTaxCountry(PurchHeader."Tax Area Code") then
                exit;
            SetUpCurrency(PurchHeader."Currency Code");
            if PurchHeader."Currency Code" <> '' then
                PurchHeader.TestField("Currency Factor");
            if PurchHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := PurchHeader."Currency Factor";
            CopyTaxDifferencesToTemp(
              TaxAmountDifference."Document Product Area"::Purchase,
              PurchLine."Document Type",
              PurchLine."Document No.");
        end;
        if not GetSalesTaxCountry(PurchLine."Tax Area Code") then
            exit;

        PurchLine.TestField("Tax Group Code");

        with TempSalesTaxLine do begin
            Reset;
            case TaxCountry of
                TaxCountry::US:  // Area Code
                    begin
                        SetRange("Tax Area Code for Key", PurchLine."Tax Area Code");
                        "Tax Area Code for Key" := PurchLine."Tax Area Code";
                    end;
                TaxCountry::CA:  // Jurisdictions
                    begin
                        SetRange("Tax Area Code for Key", '');
                        "Tax Area Code for Key" := '';
                    end;
            end;
            SetRange("Tax Group Code", PurchLine."Tax Group Code");
            SetRange("Use Tax", PurchLine."Use Tax");
            TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
            TaxAreaLine.SetRange("Tax Area", PurchLine."Tax Area Code");
            if TaxAreaLine.FindSet then
                repeat
                    SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                    "Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                    if not FindFirst then begin
                        Init;
                        "Tax Group Code" := PurchLine."Tax Group Code";
                        "Tax Area Code" := PurchLine."Tax Area Code";
                        "Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                        if TaxCountry = TaxCountry::US then begin
                            "Round Tax" := TaxArea."Round Tax";
                            TaxJurisdiction.Get("Tax Jurisdiction Code");
                            "Is Report-to Jurisdiction" := ("Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                        end;
                        SalesTaxAmountLineCalc.SetTaxBaseAmount(
                          TempSalesTaxLine, PurchLine."Line Amount" - PurchLine."Inv. Discount Amount", ExchangeFactor, false);
                        "Line Amount" := PurchLine."Line Amount" / ExchangeFactor;
                        "Tax Liable" := PurchLine."Tax Liable";
                        "Use Tax" := PurchLine."Use Tax";
                        SetTaxDetailFilter(TaxDetail, "Tax Jurisdiction Code", "Tax Group Code", PurchHeader."Posting Date");
                        if "Use Tax" then
                            TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                              TaxDetail."Tax Type"::"Use Tax Only")
                        else
                            TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                              TaxDetail."Tax Type"::"Sales Tax Only");

                        if TaxDetail.FindLast then
                            "Expense/Capitalize" := TaxDetail."Expense/Capitalize";

                        "Calculation Order" := TaxAreaLine."Calculation Order";
                        Quantity := PurchLine."Quantity (Base)";
                        "Invoice Discount Amount" := PurchLine."Inv. Discount Amount";
                        Insert;
                    end else begin
                        "Line Amount" := "Line Amount" + (PurchLine."Line Amount" / ExchangeFactor);
                        if PurchLine."Tax Liable" then
                            "Tax Liable" := PurchLine."Tax Liable";
                        SalesTaxAmountLineCalc.SetTaxBaseAmount(
                          TempSalesTaxLine, PurchLine."Line Amount" - PurchLine."Inv. Discount Amount", ExchangeFactor, true);
                        "Tax Amount" := 0;
                        Quantity := Quantity + PurchLine."Quantity (Base)";
                        "Invoice Discount Amount" := "Invoice Discount Amount" + PurchLine."Inv. Discount Amount";
                        Modify;
                    end;
                until TaxAreaLine.Next = 0;
        end;
    end;

    procedure AddPurchInvoiceLines(DocNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        SalesTaxAmountLineCalc: Codeunit "Sales Tax Amount Line Calc";
    begin
        PurchInvHeader.Get(DocNo);
        PurchInvHeader.TestField("Prices Including VAT", false);
        if not GetSalesTaxCountry(PurchInvHeader."Tax Area Code") then
            exit;
        SetUpCurrency(PurchInvHeader."Currency Code");
        if PurchInvHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := PurchInvHeader."Currency Factor";

        PurchInvLine.SetRange("Document No.", DocNo);
        PurchInvLine.SetFilter("Tax Group Code", '<>%1', '');
        if PurchInvLine.FindSet then
            repeat
                SalesTaxAmountLineCalc.InitFromPurchInvLine(PurchInvLine);
                SalesTaxAmountLineCalc.CalcPurchLineSalesTaxAmountLine(
                  TempSalesTaxLine, TaxAreaLine, TaxCountry, TaxArea, TaxJurisdiction, ExchangeFactor, TaxDetail, PurchInvHeader."Posting Date");
            until PurchInvLine.Next = 0;

        CopyTaxDifferencesToTemp(
          TaxAmountDifference."Document Product Area"::"Posted Purchase",
          TaxAmountDifference."Document Type"::Invoice,
          PurchInvHeader."No.");
    end;

    procedure AddPurchCrMemoLines(DocNo: Code[20])
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        SalesTaxAmountLineCalc: Codeunit "Sales Tax Amount Line Calc";
    begin
        PurchCrMemoHeader.Get(DocNo);
        PurchCrMemoHeader.TestField("Prices Including VAT", false);
        if not GetSalesTaxCountry(PurchCrMemoHeader."Tax Area Code") then
            exit;
        SetUpCurrency(PurchCrMemoHeader."Currency Code");
        if PurchCrMemoHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := PurchCrMemoHeader."Currency Factor";

        PurchCrMemoLine.SetRange("Document No.", DocNo);
        PurchCrMemoLine.SetFilter("Tax Group Code", '<>%1', '');
        if PurchCrMemoLine.FindSet then
            repeat
                SalesTaxAmountLineCalc.InitFromPurchCrMemoLine(PurchCrMemoLine);
                SalesTaxAmountLineCalc.CalcPurchLineSalesTaxAmountLine(
                  TempSalesTaxLine, TaxAreaLine, TaxCountry, TaxArea, TaxJurisdiction, ExchangeFactor, TaxDetail, PurchCrMemoHeader."Posting Date");
            until PurchCrMemoLine.Next = 0;

        CopyTaxDifferencesToTemp(
          TaxAmountDifference."Document Product Area"::"Posted Purchase",
          TaxAmountDifference."Document Type"::"Credit Memo",
          PurchCrMemoHeader."No.");
    end;

    procedure AddServiceLine(ServiceLine: Record "Service Line")
    var
        SalesTaxAmountLineCalc: Codeunit "Sales Tax Amount Line Calc";
    begin
        if not ServHeaderRead then begin
            ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
            ServHeaderRead := true;
            ServiceHeader.TestField("Prices Including VAT", false);
            if not GetSalesTaxCountry(ServiceHeader."Tax Area Code") then
                exit;
            SetUpCurrency(ServiceHeader."Currency Code");
            if ServiceHeader."Currency Code" <> '' then
                ServiceHeader.TestField("Currency Factor");
            if ServiceHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := ServiceHeader."Currency Factor";
            CopyTaxDifferencesToTemp(
              TaxAmountDifference."Document Product Area"::Service,
              ServiceLine."Document Type",
              ServiceLine."Document No.");
        end;
        if not GetSalesTaxCountry(ServiceLine."Tax Area Code") then
            exit;

        ServiceLine.TestField("Tax Group Code");

        with TempSalesTaxLine do begin
            Reset;
            case TaxCountry of
                TaxCountry::US:  // Area Code
                    begin
                        SetRange("Tax Area Code for Key", ServiceLine."Tax Area Code");
                        "Tax Area Code for Key" := ServiceLine."Tax Area Code";
                    end;
                TaxCountry::CA:  // Jurisdictions
                    begin
                        SetRange("Tax Area Code for Key", '');
                        "Tax Area Code for Key" := '';
                    end;
            end;
            SetRange("Tax Group Code", ServiceLine."Tax Group Code");
            TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
            TaxAreaLine.SetRange("Tax Area", ServiceLine."Tax Area Code");
            if TaxAreaLine.FindSet then
                repeat
                    SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                    "Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                    if not FindFirst then begin
                        Init;
                        "Tax Group Code" := ServiceLine."Tax Group Code";
                        "Tax Area Code" := ServiceLine."Tax Area Code";
                        "Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                        if TaxCountry = TaxCountry::US then begin
                            "Round Tax" := TaxArea."Round Tax";
                            TaxJurisdiction.Get("Tax Jurisdiction Code");
                            "Is Report-to Jurisdiction" := ("Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                        end;
                        SalesTaxAmountLineCalc.SetTaxBaseAmount(
                          TempSalesTaxLine, ServiceLine."Line Amount" - ServiceLine."Inv. Discount Amount", ExchangeFactor, false);
                        "Line Amount" := ServiceLine."Line Amount" / ExchangeFactor;
                        "Tax Liable" := ServiceLine."Tax Liable";
                        Quantity := ServiceLine."Quantity (Base)";
                        "Invoice Discount Amount" := ServiceLine."Inv. Discount Amount";
                        "Calculation Order" := TaxAreaLine."Calculation Order";
                        Insert;
                    end else begin
                        "Line Amount" := "Line Amount" + (ServiceLine."Line Amount" / ExchangeFactor);
                        if ServiceLine."Tax Liable" then
                            "Tax Liable" := ServiceLine."Tax Liable";
                        SalesTaxAmountLineCalc.SetTaxBaseAmount(
                          TempSalesTaxLine, ServiceLine."Line Amount" - ServiceLine."Inv. Discount Amount", ExchangeFactor, true);
                        "Tax Amount" := 0;
                        Quantity := Quantity + ServiceLine."Quantity (Base)";
                        "Invoice Discount Amount" := "Invoice Discount Amount" + ServiceLine."Inv. Discount Amount";
                        Modify;
                    end;
                until TaxAreaLine.Next = 0;
        end;
    end;

    procedure AddServInvoiceLines(DocNo: Code[20])
    var
        ServInvHeader: Record "Service Invoice Header";
        ServInvLine: Record "Service Invoice Line";
        SalesTaxAmountLineCalc: Codeunit "Sales Tax Amount Line Calc";
    begin
        ServInvHeader.Get(DocNo);
        ServInvHeader.TestField("Prices Including VAT", false);
        if not GetSalesTaxCountry(ServInvHeader."Tax Area Code") then
            exit;
        SetUpCurrency(ServInvHeader."Currency Code");
        if ServInvHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := ServInvHeader."Currency Factor";

        ServInvLine.SetRange("Document No.", DocNo);
        ServInvLine.SetFilter("Tax Group Code", '<>%1', '');
        if ServInvLine.FindSet then
            repeat
                SalesTaxAmountLineCalc.InitFromServInvLine(ServInvLine);
                SalesTaxAmountLineCalc.CalcSalesOrServLineSalesTaxAmountLine(
                  TempSalesTaxLine, TaxAreaLine, TaxCountry, TaxArea, TaxJurisdiction, ExchangeFactor);
            until ServInvLine.Next = 0;

        CopyTaxDifferencesToTemp(
          TaxAmountDifference."Document Product Area"::"Posted Service",
          TaxAmountDifference."Document Type"::Invoice,
          ServInvHeader."No.");
    end;

    procedure AddServCrMemoLines(DocNo: Code[20])
    var
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        ServCrMemoLine: Record "Service Cr.Memo Line";
        SalesTaxAmountLineCalc: Codeunit "Sales Tax Amount Line Calc";
    begin
        ServCrMemoHeader.Get(DocNo);
        ServCrMemoHeader.TestField("Prices Including VAT", false);
        if not GetSalesTaxCountry(ServCrMemoHeader."Tax Area Code") then
            exit;
        SetUpCurrency(ServCrMemoHeader."Currency Code");
        if ServCrMemoHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := ServCrMemoHeader."Currency Factor";

        ServCrMemoLine.SetRange("Document No.", DocNo);
        ServCrMemoLine.SetFilter("Tax Group Code", '<>%1', '');
        if ServCrMemoLine.FindSet then
            repeat
                SalesTaxAmountLineCalc.InitFromServCrMemoLine(ServCrMemoLine);
                SalesTaxAmountLineCalc.CalcSalesOrServLineSalesTaxAmountLine(
                  TempSalesTaxLine, TaxAreaLine, TaxCountry, TaxArea, TaxJurisdiction, ExchangeFactor);
            until ServCrMemoLine.Next = 0;

        CopyTaxDifferencesToTemp(
          TaxAmountDifference."Document Product Area"::"Posted Service",
          TaxAmountDifference."Document Type"::"Credit Memo",
          ServCrMemoHeader."No.");
    end;

    procedure EndSalesTaxCalculation(Date: Date)
    var
        SalesTaxAmountLine2: Record "Sales Tax Amount Line" temporary;
        TaxDetail: Record "Tax Detail";
        AddedTaxAmount: Decimal;
        TotalTaxAmount: Decimal;
        MaxAmount: Decimal;
        TaxBaseAmt: Decimal;
        LastTaxAreaCode: Code[20];
        LastTaxType: Integer;
        LastTaxGroupCode: Code[20];
        RoundTax: Option "To Nearest",Up,Down;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        case true of
            SalesHeaderRead:
                OnBeforeEndSalesTaxCalculationSales(SalesHeader, TempSalesTaxLine, IsHandled);
            PurchHeaderRead:
                OnBeforeEndSalesTaxCalculationPurchase(PurchHeader, TempSalesTaxLine, IsHandled);
            ServHeaderRead:
                OnBeforeEndSalesTaxCalculationService(ServiceHeader, TempSalesTaxLine, IsHandled);
        end;
        if IsHandled then
            exit;

        with TempSalesTaxLine do begin
            Reset;
            SetRange("Tax Type", "Tax Type"::"Sales and Use Tax");
            if FindSet then
                repeat
                    SetTaxDetailFilter(TaxDetail, "Tax Jurisdiction Code", "Tax Group Code", Date);
                    TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
                    if "Use Tax" then
                        TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                          TaxDetail."Tax Type"::"Use Tax Only")
                    else
                        TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                          TaxDetail."Tax Type"::"Sales Tax Only");
                    if not TaxDetail.FindLast then
                        Delete;
                    TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                    if TaxDetail.FindLast then begin
                        "Tax Type" := "Tax Type"::"Excise Tax";
                        Insert;
                        "Tax Type" := "Tax Type"::"Sales and Use Tax";
                    end;
                until Next = 0;
            Reset;
            if FindSet(true) then
                repeat
                    TempTaxAmountDifference.Reset;
                    TempTaxAmountDifference.SetRange("Tax Area Code", "Tax Area Code for Key");
                    TempTaxAmountDifference.SetRange("Tax Jurisdiction Code", "Tax Jurisdiction Code");
                    TempTaxAmountDifference.SetRange("Tax Group Code", "Tax Group Code");
                    TempTaxAmountDifference.SetRange("Expense/Capitalize", "Expense/Capitalize");
                    TempTaxAmountDifference.SetRange("Tax Type", "Tax Type");
                    TempTaxAmountDifference.SetRange("Use Tax", "Use Tax");
                    if TempTaxAmountDifference.FindFirst then begin
                        "Tax Difference" := TempTaxAmountDifference."Tax Difference";
                        Modify;
                    end;
                until Next = 0;
            Reset;
            SetCurrentKey("Tax Area Code for Key", "Tax Group Code", "Tax Type", "Calculation Order");
            if FindLast then begin
                LastTaxAreaCode := "Tax Area Code for Key";
                LastCalculationOrder := -9999;
                LastTaxType := "Tax Type";
                LastTaxGroupCode := "Tax Group Code";
                RoundTax := "Round Tax";
                repeat
                    if (LastTaxAreaCode <> "Tax Area Code for Key") or
                       (LastTaxGroupCode <> "Tax Group Code")
                    then begin
                        HandleRoundTaxUpOrDown(SalesTaxAmountLine2, RoundTax, TotalTaxAmount, LastTaxAreaCode, LastTaxGroupCode);
                        LastTaxAreaCode := "Tax Area Code for Key";
                        LastTaxType := "Tax Type";
                        LastTaxGroupCode := "Tax Group Code";
                        TaxOnTaxCalculated := false;
                        LastCalculationOrder := -9999;
                        CalculationOrderViolation := false;
                        TotalTaxAmount := 0;
                        RoundTax := "Round Tax";
                    end;
                    if "Tax Type" = "Tax Type"::"Sales and Use Tax" then
                        TaxBaseAmt := "Tax Base Amount"
                    else
                        TaxBaseAmt := Quantity;
                    if LastCalculationOrder = "Calculation Order" then
                        CalculationOrderViolation := true;
                    LastCalculationOrder := "Calculation Order";

                    SetTaxDetailFilter(TaxDetail, "Tax Jurisdiction Code", "Tax Group Code", Date);
                    TaxDetail.SetRange("Tax Type", "Tax Type");
                    if "Tax Type" = "Tax Type"::"Sales and Use Tax" then
                        if "Use Tax" then
                            TaxDetail.SetFilter("Tax Type", '%1|%2', "Tax Type"::"Sales and Use Tax",
                              "Tax Type"::"Use Tax Only")
                        else
                            TaxDetail.SetFilter("Tax Type", '%1|%2', "Tax Type"::"Sales and Use Tax",
                              "Tax Type"::"Sales Tax Only");
                    if TaxDetail.FindLast then begin
                        TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                        if TaxDetail."Calculate Tax on Tax" and ("Tax Type" = "Tax Type"::"Sales and Use Tax") then
                            TaxBaseAmt := "Tax Base Amount" + TotalTaxAmount;
                        if "Tax Liable" then begin
                            if (Abs(TaxBaseAmt) <= TaxDetail."Maximum Amount/Qty.") or
                               (TaxDetail."Maximum Amount/Qty." = 0)
                            then
                                AddedTaxAmount := TaxBaseAmt * TaxDetail."Tax Below Maximum"
                            else begin
                                if "Tax Type" = "Tax Type"::"Sales and Use Tax" then
                                    MaxAmount := TaxBaseAmt / Abs("Tax Base Amount") * TaxDetail."Maximum Amount/Qty."
                                else
                                    MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                                AddedTaxAmount :=
                                  (MaxAmount * TaxDetail."Tax Below Maximum") +
                                  ((TaxBaseAmt - MaxAmount) * TaxDetail."Tax Above Maximum");
                            end;
                            if "Tax Type" = "Tax Type"::"Sales and Use Tax" then
                                AddedTaxAmount := AddedTaxAmount / 100.0;
                        end else
                            AddedTaxAmount := 0;
                        "Tax Amount" := "Tax Amount" + AddedTaxAmount;
                        TotalTaxAmount := TotalTaxAmount + AddedTaxAmount;
                    end;
                    "Tax Amount" := "Tax Amount" + "Tax Difference";
                    TotalTaxAmount := TotalTaxAmount + "Tax Difference";
                    "Amount Including Tax" := "Tax Amount" + "Tax Base Amount";
                    if TaxOnTaxCalculated and CalculationOrderViolation then
                        Error(
                          Text000,
                          FieldCaption("Calculation Order"), TaxArea.TableCaption, "Tax Area Code",
                          TaxDetail.FieldCaption("Calculate Tax on Tax"), CalculationOrderViolation);
                    SalesTaxAmountLine2.Copy(TempSalesTaxLine);
                    if "Tax Type" = "Tax Type"::"Excise Tax" then
                        SalesTaxAmountLine2."Tax %" := 0
                    else
                        if "Tax Base Amount" <> 0 then
                            SalesTaxAmountLine2."Tax %" := 100 * ("Amount Including Tax" - "Tax Base Amount") / "Tax Base Amount"
                        else
                            if "Tax %" = 0 then
                                SalesTaxAmountLine2."Tax %" := TaxDetail."Tax Below Maximum"
                            else
                                SalesTaxAmountLine2."Tax %" := "Tax %";
                    SalesTaxAmountLine2.Insert;
                until Next(-1) = 0;
                UpdateSalesTaxForPrepmt(SalesTaxAmountLine2, TotalTaxAmount, RoundTax);
                HandleRoundTaxUpOrDown(SalesTaxAmountLine2, RoundTax, TotalTaxAmount, LastTaxAreaCode, LastTaxGroupCode);
            end;
            DeleteAll;
            SalesTaxAmountLine2.Reset;
            if SalesTaxAmountLine2.FindSet then
                repeat
                    Copy(SalesTaxAmountLine2);
                    Insert;
                until SalesTaxAmountLine2.Next = 0;
        end;
    end;

    procedure GetSummarizedSalesTaxTable(var SummarizedSalesTaxAmtLine: Record "Sales Tax Amount Line")
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        RemTaxAmt: Decimal;
        PrevTaxJurisdictionCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        case true of
            SalesHeaderRead:
                OnBeforeGetSummarizedSalesTaxTable(
                  SummarizedSalesTaxAmtLine, DATABASE::"Sales Line", SalesHeader."Document Type", SalesHeader."No.", IsHandled);
            PurchHeaderRead:
                OnBeforeGetSummarizedSalesTaxTable(
                  SummarizedSalesTaxAmtLine, DATABASE::"Purchase Line", PurchHeader."Document Type", PurchHeader."No.", IsHandled);
            ServHeaderRead:
                OnBeforeGetSummarizedSalesTaxTable(
                  SummarizedSalesTaxAmtLine, DATABASE::"Service Line", ServiceHeader."Document Type", ServiceHeader."No.", IsHandled);
        end;
        if IsHandled then
            exit;

        IsHandled := false;
        OnBeforeGetPostedSummarizedSalesTaxTable(SummarizedSalesTaxAmtLine, TempTaxAmountDifference, IsHandled);
        if IsHandled then
            exit;

        Clear(TaxJurisdiction);
        TempSalesTaxLine.Reset;

        with SummarizedSalesTaxAmtLine do begin
            DeleteAll;
            if TempSalesTaxLine.FindSet then
                repeat
                    Clear(SummarizedSalesTaxAmtLine);
                    case TaxCountry of
                        TaxCountry::US:
                            begin
                                "Tax Area Code for Key" := TempSalesTaxLine."Tax Area Code for Key";
                                if TaxArea.Code <> "Tax Area Code for Key" then
                                    TaxArea.Get("Tax Area Code for Key");
                                "Print Description" := TaxArea.Description;
                            end;
                        TaxCountry::CA:
                            begin
                                "Tax Jurisdiction Code" := TempSalesTaxLine."Tax Jurisdiction Code";
                                if TaxJurisdiction.Code <> "Tax Jurisdiction Code" then
                                    TaxJurisdiction.Get("Tax Jurisdiction Code");
                                "Print Order" := TaxJurisdiction."Print Order";
                                "Print Description" := TaxJurisdiction."Print Description";
                                if StrPos("Print Description", '%1') <> 0 then
                                    "Tax %" := TempSalesTaxLine."Tax %";
                            end;
                    end;
                    if not Find('=') then
                        Insert;
                    if (TempSalesTaxLine."Tax Difference" <> 0) or
                       (TempSalesTaxLine."Tax Type" = TempSalesTaxLine."Tax Type"::"Excise Tax")
                    then
                        "Tax Amount" += TempSalesTaxLine."Tax Amount"
                    else
                        "Tax Amount" += TempSalesTaxLine."Tax Base Amount FCY" * TempSalesTaxLine."Tax %" / 100;
                    Modify;
                until TempSalesTaxLine.Next = 0;

            SetRange("Tax Amount", 0);
            DeleteAll;
            SetRange("Tax Amount");

            if FindSet then
                repeat
                    if ("Tax Jurisdiction Code" <> PrevTaxJurisdictionCode) and RoundByJurisdiction then begin
                        PrevTaxJurisdictionCode := "Tax Jurisdiction Code";
                        RemTaxAmt := 0;
                    end;
                    if TaxCountry = TaxCountry::CA then
                        "Tax Amount" := Round("Tax Amount", Currency."Amount Rounding Precision")
                    else begin
                        "Tax Amount" += RemTaxAmt;
                        RemTaxAmt := "Tax Amount" - Round("Tax Amount", Currency."Amount Rounding Precision");
                        "Tax Amount" -= RemTaxAmt;
                    end;
                    Modify;
                until Next = 0;

            SetRange("Tax Amount", 0);
            DeleteAll;
            SetRange("Tax Amount");
        end;
    end;

    procedure GetSalesTaxAmountLineTable(var SalesTaxLine2: Record "Sales Tax Amount Line" temporary)
    begin
        TempSalesTaxLine.Reset;
        if TempSalesTaxLine.FindSet then
            repeat
                SalesTaxLine2.Copy(TempSalesTaxLine);
                SalesTaxLine2.Insert;
            until TempSalesTaxLine.Next = 0;
    end;

    procedure PutSalesTaxAmountLineTable(var SalesTaxLine2: Record "Sales Tax Amount Line" temporary; ProductArea: Integer; DocumentType: Integer; DocumentNo: Code[20])
    begin
        TempSalesTaxLine.Reset;
        TempSalesTaxLine.DeleteAll;
        if SalesTaxLine2.FindSet then
            repeat
                TempSalesTaxLine.Copy(SalesTaxLine2);
                TempSalesTaxLine.Insert;
            until SalesTaxLine2.Next = 0;

        CreateSingleTaxDifference(ProductArea, DocumentType, DocumentNo);
    end;

    procedure DistTaxOverSalesLines(var SalesLine: Record "Sales Line")
    var
        TempSalesTaxLine2: Record "Sales Tax Amount Line" temporary;
        SalesLine2: Record "Sales Line" temporary;
        TaxAmount: Decimal;
        Amount: Decimal;
        ReturnTaxAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDistTaxOverSalesLines(SalesLine, IsHandled);
        if IsHandled then
            exit;

        TotalTaxAmountRounding := 0;
        if not SalesHeaderRead then begin
            if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
                exit;
            SalesHeaderRead := true;
            SetUpCurrency(SalesHeader."Currency Code");
            if SalesHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := SalesHeader."Currency Factor";
            if not GetSalesTaxCountry(SalesHeader."Tax Area Code") then
                exit;
        end;
        SalesLine.ModifyAll("VAT %", 0);

        ResetTaxAmountsInSalesLines(SalesLine, SalesHeader."Tax Area Code");

        with TempSalesTaxLine do begin
            Reset;
            if FindSet then
                repeat
                    if ("Tax Jurisdiction Code" <> TempSalesTaxLine2."Tax Jurisdiction Code") and RoundByJurisdiction then begin
                        TempSalesTaxLine2."Tax Jurisdiction Code" := "Tax Jurisdiction Code";
                        TotalTaxAmountRounding := 0;
                    end;
                    if TaxCountry = TaxCountry::US then
                        SalesLine.SetRange("Tax Area Code", "Tax Area Code");
                    SalesLine.SetRange("Tax Group Code", "Tax Group Code");
                    SalesLine.SetCurrentKey(Amount);
                    SalesLine.FindSet(true);
                    repeat
                        if ((TaxCountry = TaxCountry::US) or
                            ((TaxCountry = TaxCountry::CA) and TaxAreaLine.Get(SalesLine."Tax Area Code", "Tax Jurisdiction Code"))) and
                           CheckTaxAmtLinePos(SalesLine."Line Amount" - SalesLine."Inv. Discount Amount",
                             Positive)
                        then begin
                            if "Tax Type" = "Tax Type"::"Sales and Use Tax" then begin
                                Amount := (SalesLine."Line Amount" - SalesLine."Inv. Discount Amount");
                                if "Tax Difference" <> 0 then
                                    TaxAmount := Amount * "Tax Amount" / "Tax Base Amount"
                                else
                                    TaxAmount := Amount * "Tax %" / 100;
                            end else begin
                                if (SalesLine."Quantity (Base)" = 0) or (Quantity = 0) then
                                    TaxAmount := 0
                                else
                                    TaxAmount := "Tax Amount" * ExchangeFactor * SalesLine."Quantity (Base)" / Quantity;
                            end;
                            if TaxAmount = 0 then
                                ReturnTaxAmount := 0
                            else begin
                                ReturnTaxAmount := Round(TaxAmount + TotalTaxAmountRounding, Currency."Amount Rounding Precision");
                                TotalTaxAmountRounding := TaxAmount + TotalTaxAmountRounding - ReturnTaxAmount;
                            end;
                            SalesLine.Amount :=
                              SalesLine."Line Amount" - SalesLine."Inv. Discount Amount";
                            SalesLine."VAT Base Amount" := SalesLine.Amount;
                            if SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then begin
                                if not IsFinalPrepaidSalesLine(SalesLine) then
                                    SalesLine2."Amount Including VAT" := SalesLine2."Amount Including VAT" + ReturnTaxAmount;
                                SalesLine2.Modify;
                            end else begin
                                SalesLine2.Copy(SalesLine);
                                if IsFinalPrepaidSalesLine(SalesLine) then
                                    SalesLine2."Amount Including VAT" := SalesLine2."Amount Including VAT" - SalesLine.GetPrepaidSalesAmountInclVAT
                                else
                                    SalesLine2."Amount Including VAT" := SalesLine.Amount + ReturnTaxAmount;
                                SalesLine2.Insert;
                            end;
                            if SalesLine."Tax Liable" then
                                SalesLine."Amount Including VAT" := SalesLine2."Amount Including VAT"
                            else
                                SalesLine."Amount Including VAT" := SalesLine.Amount;
                            if SalesLine.Amount <> 0 then
                                SalesLine."VAT %" += "Tax %"
                            else
                                SalesLine."VAT %" := 0;
                            SalesLine.Modify;
                        end;
                    until SalesLine.Next = 0;
                until Next = 0;
            SalesLine.SetRange("Tax Area Code");
            SalesLine.SetRange("Tax Group Code");
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            if SalesLine.FindSet(true) then
                repeat
                    SalesLine."Amount Including VAT" := Round(SalesLine."Amount Including VAT", Currency."Amount Rounding Precision");
                    SalesLine.Amount :=
                      Round(SalesLine."Line Amount" - SalesLine."Inv. Discount Amount", Currency."Amount Rounding Precision");
                    SalesLine."VAT Base Amount" := SalesLine.Amount;
                    if SalesLine.Quantity = 0 then
                        SalesLine.Validate("Outstanding Amount", SalesLine."Amount Including VAT")
                    else
                        SalesLine.Validate(
                          "Outstanding Amount",
                          Round(
                            SalesLine."Amount Including VAT" * SalesLine."Outstanding Quantity" / SalesLine.Quantity,
                            Currency."Amount Rounding Precision"));
                    if ((SalesLine."Tax Area Code" = '') and ("Tax Area Code" <> '')) or (SalesLine."Tax Group Code" = '') then
                        SalesLine."Amount Including VAT" := SalesLine.Amount;
                    SalesLine.Modify;
                until SalesLine.Next = 0;
        end;
    end;

    procedure DistTaxOverPurchLines(var PurchLine: Record "Purchase Line")
    var
        TempSalesTaxLine2: Record "Sales Tax Amount Line" temporary;
        PurchLine2: Record "Purchase Line" temporary;
        PurchLine3: Record "Purchase Line" temporary;
        TaxAmount: Decimal;
        ReturnTaxAmount: Decimal;
        Amount: Decimal;
        ExpenseTaxAmountRounding: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDistTaxOverPurchLines(PurchLine, IsHandled);
        if IsHandled then
            exit;

        TotalTaxAmountRounding := 0;
        ExpenseTaxAmountRounding := 0;
        if not PurchHeaderRead then begin
            if not PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.") then
                exit;
            PurchHeaderRead := true;
            SetUpCurrency(PurchHeader."Currency Code");
            if PurchHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := PurchHeader."Currency Factor";
            if not GetSalesTaxCountry(PurchHeader."Tax Area Code") then
                exit;
        end;

        ResetTaxAmountsInPurchLines(PurchLine, PurchHeader."Tax Area Code");

        with TempSalesTaxLine do begin
            Reset;
            // LOCKING
            if FindSet then
                repeat
                    if ("Tax Jurisdiction Code" <> TempSalesTaxLine2."Tax Jurisdiction Code") and RoundByJurisdiction then begin
                        TempSalesTaxLine2."Tax Jurisdiction Code" := "Tax Jurisdiction Code";
                        TotalTaxAmountRounding := 0;
                        ExpenseTaxAmountRounding := 0;
                    end;
                    if TaxCountry = TaxCountry::US then
                        PurchLine.SetRange("Tax Area Code", "Tax Area Code");
                    PurchLine.SetRange("Tax Group Code", "Tax Group Code");
                    PurchLine.SetRange("Use Tax", "Use Tax");
                    PurchLine.SetCurrentKey(Amount);
                    PurchLine.FindSet(true);
                    repeat
                        if (TaxCountry = TaxCountry::US) or
                           ((TaxCountry = TaxCountry::CA) and TaxAreaLine.Get(PurchLine."Tax Area Code", "Tax Jurisdiction Code"))
                        then begin
                            if "Tax Type" = "Tax Type"::"Sales and Use Tax" then begin
                                Amount := (PurchLine."Line Amount" - PurchLine."Inv. Discount Amount");
                                if "Tax Difference" <> 0 then
                                    TaxAmount := Amount * "Tax Amount" / "Tax Base Amount"
                                else
                                    TaxAmount := Amount * "Tax %" / 100;
                            end else begin
                                if (PurchLine."Quantity (Base)" = 0) or (Quantity = 0) then
                                    TaxAmount := 0
                                else
                                    TaxAmount := "Tax Amount" * ExchangeFactor * PurchLine."Quantity (Base)" / Quantity;
                            end;
                            if (PurchLine."Use Tax" or "Expense/Capitalize") and (TaxAmount <> 0) then begin
                                ExpenseTaxAmountRounding := ExpenseTaxAmountRounding + TaxAmount;
                                if PurchLine3.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then begin
                                    PurchLine3."Tax To Be Expensed" :=
                                      Round(
                                        PurchLine3."Tax To Be Expensed" + ExpenseTaxAmountRounding,
                                        Currency."Amount Rounding Precision");
                                    PurchLine3.Modify;
                                end else begin
                                    PurchLine3.Copy(PurchLine);
                                    PurchLine3."Tax To Be Expensed" :=
                                      Round(
                                        ExpenseTaxAmountRounding,
                                        Currency."Amount Rounding Precision");
                                    PurchLine3.Insert;
                                end;
                                PurchLine."Tax To Be Expensed" := PurchLine3."Tax To Be Expensed";
                                ExpenseTaxAmountRounding :=
                                  ExpenseTaxAmountRounding -
                                  Round(
                                    ExpenseTaxAmountRounding,
                                    Currency."Amount Rounding Precision");
                            end else begin
                                if not PurchLine3.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then begin
                                    PurchLine3.Copy(PurchLine);
                                    PurchLine3."Tax To Be Expensed" := 0;
                                    PurchLine3.Insert;
                                end;
                                PurchLine."Tax To Be Expensed" := PurchLine3."Tax To Be Expensed";
                            end;
                            if PurchLine."Use Tax" then
                                TaxAmount := 0;
                            if TaxAmount = 0 then
                                ReturnTaxAmount := 0
                            else begin
                                ReturnTaxAmount := Round(TaxAmount + TotalTaxAmountRounding, Currency."Amount Rounding Precision");
                                TotalTaxAmountRounding := TaxAmount + TotalTaxAmountRounding - ReturnTaxAmount;
                            end;
                            PurchLine.Amount := PurchLine."Line Amount" - PurchLine."Inv. Discount Amount";
                            PurchLine."VAT Base Amount" := PurchLine.Amount;
                            if PurchLine2.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then begin
                                PurchLine2."Amount Including VAT" := PurchLine2."Amount Including VAT" + ReturnTaxAmount;
                                PurchLine2.Modify;
                            end else begin
                                PurchLine2.Copy(PurchLine);
                                PurchLine2."Amount Including VAT" := PurchLine.Amount + ReturnTaxAmount;
                                PurchLine2.Insert;
                            end;
                            if PurchLine."Tax Liable" then
                                PurchLine."Amount Including VAT" := PurchLine2."Amount Including VAT"
                            else
                                PurchLine."Amount Including VAT" := PurchLine.Amount;
                            if PurchLine.Amount <> 0 then
                                PurchLine."VAT %" :=
                                  Round(100 * (PurchLine."Amount Including VAT" - PurchLine.Amount) / PurchLine.Amount, 0.00001)
                            else
                                PurchLine."VAT %" := 0;
                            PurchLine.Modify;
                        end;
                    until PurchLine.Next = 0;
                until Next = 0;
            PurchLine.SetRange("Tax Area Code");
            PurchLine.SetRange("Tax Group Code");
            PurchLine.SetRange("Use Tax");
            PurchLine.SetRange("Document Type", PurchHeader."Document Type");
            PurchLine.SetRange("Document No.", PurchHeader."No.");
            if PurchLine.FindSet(true) then
                repeat
                    PurchLine."Amount Including VAT" := Round(PurchLine."Amount Including VAT", Currency."Amount Rounding Precision");
                    PurchLine.Amount :=
                      Round(PurchLine."Line Amount" - PurchLine."Inv. Discount Amount", Currency."Amount Rounding Precision");
                    PurchLine."VAT Base Amount" := PurchLine.Amount;
                    if PurchLine.Quantity = 0 then
                        PurchLine.Validate("Outstanding Amount", PurchLine."Amount Including VAT")
                    else
                        PurchLine.Validate(
                          "Outstanding Amount",
                          Round(
                            PurchLine."Amount Including VAT" * PurchLine."Outstanding Quantity" / PurchLine.Quantity,
                            Currency."Amount Rounding Precision"));
                    if ((PurchLine."Tax Area Code" = '') and ("Tax Area Code" <> '')) or (PurchLine."Tax Group Code" = '') then
                        PurchLine."Amount Including VAT" := PurchLine.Amount;
                    if PurchLine.Amount <> 0 then
                        PurchLine.Modify;
                until PurchLine.Next = 0;
        end;
    end;

    procedure DistTaxOverServLines(var ServLine: Record "Service Line")
    var
        TempSalesTaxLine2: Record "Sales Tax Amount Line" temporary;
        ServLine2: Record "Service Line" temporary;
        TaxAmount: Decimal;
        Amount: Decimal;
        ReturnTaxAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDistTaxOverServLines(ServLine, IsHandled);
        if IsHandled then
            exit;

        TotalTaxAmountRounding := 0;
        if not ServHeaderRead then begin
            if not ServiceHeader.Get(ServLine."Document Type", ServLine."Document No.") then
                exit;
            ServHeaderRead := true;
            SetUpCurrency(ServiceHeader."Currency Code");
            if ServiceHeader."Currency Factor" = 0 then
                ExchangeFactor := 1
            else
                ExchangeFactor := ServiceHeader."Currency Factor";
            if not GetSalesTaxCountry(ServiceHeader."Tax Area Code") then
                exit;
        end;

        with TempSalesTaxLine do begin
            Reset;
            if FindSet then
                repeat
                    if ("Tax Jurisdiction Code" <> TempSalesTaxLine2."Tax Jurisdiction Code") and RoundByJurisdiction then begin
                        TempSalesTaxLine2."Tax Jurisdiction Code" := "Tax Jurisdiction Code";
                        TotalTaxAmountRounding := 0;
                    end;
                    if TaxCountry = TaxCountry::US then
                        ServLine.SetRange("Tax Area Code", "Tax Area Code");
                    ServLine.SetRange("Tax Group Code", "Tax Group Code");
                    ServLine.SetCurrentKey(Amount);
                    ServLine.FindSet(true);
                    repeat
                        if (TaxCountry = TaxCountry::US) or
                           ((TaxCountry = TaxCountry::CA) and TaxAreaLine.Get(ServLine."Tax Area Code", "Tax Jurisdiction Code"))
                        then begin
                            if "Tax Type" = "Tax Type"::"Sales and Use Tax" then begin
                                Amount := (ServLine."Line Amount" - ServLine."Inv. Discount Amount");
                                TaxAmount := Amount * "Tax %" / 100;
                            end else begin
                                if (ServLine."Quantity (Base)" = 0) or (Quantity = 0) then
                                    TaxAmount := 0
                                else
                                    TaxAmount := "Tax Amount" * ExchangeFactor * ServLine."Quantity (Base)" / Quantity;
                            end;
                            if TaxAmount = 0 then
                                ReturnTaxAmount := 0
                            else begin
                                ReturnTaxAmount := Round(TaxAmount + TotalTaxAmountRounding, Currency."Amount Rounding Precision");
                                TotalTaxAmountRounding := TaxAmount + TotalTaxAmountRounding - ReturnTaxAmount;
                            end;
                            ServLine.Amount :=
                              ServLine."Line Amount" - ServLine."Inv. Discount Amount";
                            ServLine."VAT Base Amount" := ServLine.Amount;
                            if ServLine2.Get(ServLine."Document Type", ServLine."Document No.", ServLine."Line No.") then begin
                                ServLine2."Amount Including VAT" := ServLine2."Amount Including VAT" + ReturnTaxAmount;
                                ServLine2.Modify;
                            end else begin
                                ServLine2.Copy(ServLine);
                                ServLine2."Amount Including VAT" := ServLine.Amount + ReturnTaxAmount;
                                ServLine2.Insert;
                            end;
                            if ServLine."Tax Liable" then
                                ServLine."Amount Including VAT" := ServLine2."Amount Including VAT"
                            else
                                ServLine."Amount Including VAT" := ServLine.Amount;
                            if ServLine.Amount <> 0 then
                                ServLine."VAT %" :=
                                  Round(100 * (ServLine."Amount Including VAT" - ServLine.Amount) / ServLine.Amount, 0.00001)
                            else
                                ServLine."VAT %" := 0;
                            ServLine.Modify;
                        end;
                    until ServLine.Next = 0;
                until Next = 0;
            ServLine.SetRange("Tax Area Code");
            ServLine.SetRange("Tax Group Code");
            ServLine.SetRange("Document Type", ServiceHeader."Document Type");
            ServLine.SetRange("Document No.", ServiceHeader."No.");
            if ServLine.FindSet(true) then
                repeat
                    ServLine."Amount Including VAT" := Round(ServLine."Amount Including VAT", Currency."Amount Rounding Precision");
                    ServLine.Amount :=
                      Round(ServLine."Line Amount" - ServLine."Inv. Discount Amount", Currency."Amount Rounding Precision");
                    ServLine."VAT Base Amount" := ServLine.Amount;
                    ServLine.Modify;
                until ServLine.Next = 0;
        end;
    end;

    procedure GetSalesTaxCountry(TaxAreaCode: Code[20]): Boolean
    begin
        if TaxAreaCode = '' then
            exit(false);
        if TaxAreaRead then begin
            if TaxAreaCode = TaxArea.Code then
                exit(true);
            if TaxArea.Get(TaxAreaCode) then
                if TaxCountry <> TaxArea."Country/Region" then  // make sure countries match
                    Error(Text1020000, TaxArea."Country/Region", TaxCountry)
                else
                    exit(true);
        end else
            if TaxArea.Get(TaxAreaCode) then begin
                TaxAreaRead := true;
                TaxCountry := TaxArea."Country/Region";
                RoundByJurisdiction := TaxArea."Country/Region" = TaxArea."Country/Region"::CA;
                exit(true);
            end;

        exit(false);
    end;

    local procedure SetUpCurrency(CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure ReadTempPurchHeader(TempPurchHeader: Record "Purchase Header" temporary)
    begin
        PurchHeader.Copy(TempPurchHeader);
        if PurchHeader."Tax Area Code" = '' then
            exit;
        PurchHeaderRead := true;
        SetUpCurrency(TempPurchHeader."Currency Code");
        if TempPurchHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := PurchHeader."Currency Factor";
        TempPurchHeader.DeleteAll;

        CreateSingleTaxDifference(
          TaxAmountDifference."Document Product Area"::Purchase,
          PurchHeader."Document Type",
          PurchHeader."No.");
    end;

    procedure ReadTempSalesHeader(TempSalesHeader: Record "Sales Header" temporary)
    begin
        SalesHeader.Copy(TempSalesHeader);
        if SalesHeader."Tax Area Code" = '' then
            exit;
        SalesHeaderRead := true;
        SetUpCurrency(TempSalesHeader."Currency Code");
        if TempSalesHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := TempSalesHeader."Currency Factor";
        TempSalesHeader.DeleteAll;

        CreateSingleTaxDifference(
          TaxAmountDifference."Document Product Area"::Sales,
          SalesHeader."Document Type",
          SalesHeader."No.");
    end;

    local procedure CopyTaxDifferencesToTemp(ProductArea: Integer; DocumentType: Integer; DocumentNo: Code[20])
    begin
        TaxAmountDifference.Reset;
        TaxAmountDifference.SetRange("Document Product Area", ProductArea);
        TaxAmountDifference.SetRange("Document Type", DocumentType);
        TaxAmountDifference.SetRange("Document No.", DocumentNo);
        if TaxAmountDifference.FindSet then
            repeat
                TempTaxAmountDifference := TaxAmountDifference;
                TempTaxAmountDifference.Insert;
            until TaxAmountDifference.Next = 0
        else
            CreateSingleTaxDifference(ProductArea, DocumentType, DocumentNo);
    end;

    local procedure CreateSingleTaxDifference(ProductArea: Integer; DocumentType: Integer; DocumentNo: Code[20])
    begin
        TempTaxAmountDifference.Reset;
        TempTaxAmountDifference.DeleteAll;
        TempTaxAmountDifference.Init;
        TempTaxAmountDifference."Document Product Area" := ProductArea;
        TempTaxAmountDifference."Document Type" := DocumentType;
        TempTaxAmountDifference."Document No." := DocumentNo;
        TempTaxAmountDifference.Insert;
    end;

    procedure SaveTaxDifferences()
    begin
        TempTaxAmountDifference.Reset;
        if not TempTaxAmountDifference.FindFirst then
            Error(Text1020001);

        TaxAmountDifference.Reset;
        TaxAmountDifference.SetRange("Document Product Area", TempTaxAmountDifference."Document Product Area");
        TaxAmountDifference.SetRange("Document Type", TempTaxAmountDifference."Document Type");
        TaxAmountDifference.SetRange("Document No.", TempTaxAmountDifference."Document No.");
        TaxAmountDifference.DeleteAll;

        TempSalesTaxLine.Reset;
        TempSalesTaxLine.SetFilter("Tax Difference", '<>0');
        if TempSalesTaxLine.FindSet then
            repeat
                TaxAmountDifference."Document Product Area" := TempTaxAmountDifference."Document Product Area";
                TaxAmountDifference."Document Type" := TempTaxAmountDifference."Document Type";
                TaxAmountDifference."Document No." := TempTaxAmountDifference."Document No.";
                TaxAmountDifference."Tax Area Code" := TempSalesTaxLine."Tax Area Code for Key";
                TaxAmountDifference."Tax Jurisdiction Code" := TempSalesTaxLine."Tax Jurisdiction Code";
                TaxAmountDifference."Tax %" := TempSalesTaxLine."Tax %";
                TaxAmountDifference."Tax Group Code" := TempSalesTaxLine."Tax Group Code";
                TaxAmountDifference."Expense/Capitalize" := TempSalesTaxLine."Expense/Capitalize";
                TaxAmountDifference."Tax Type" := TempSalesTaxLine."Tax Type";
                TaxAmountDifference."Use Tax" := TempSalesTaxLine."Use Tax";
                TaxAmountDifference."Tax Difference" := TempSalesTaxLine."Tax Difference";
                TaxAmountDifference.Insert;
            until TempSalesTaxLine.Next = 0;
    end;

    procedure CalculateExpenseTax(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Date: Date; Amount: Decimal; Quantity: Decimal; ExchangeRate: Decimal) TaxAmount: Decimal
    var
        MaxAmount: Decimal;
        TaxBaseAmount: Decimal;
    begin
        TaxAmount := 0;

        if not TaxLiable or (TaxAreaCode = '') or (TaxGroupCode = '') or
           ((Amount = 0) and (Quantity = 0))
        then
            exit;

        if ExchangeRate = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := ExchangeRate;

        Amount := Amount / ExchangeFactor;

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        if TaxAreaLine.Find('+') then begin
            LastCalculationOrder := TaxAreaLine."Calculation Order" + 1;
            TaxOnTaxCalculated := false;
            CalculationOrderViolation := false;
            repeat
                if TaxAreaLine."Calculation Order" >= LastCalculationOrder then
                    CalculationOrderViolation := true
                else
                    LastCalculationOrder := TaxAreaLine."Calculation Order";
                SetTaxDetailFilter(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, Date);
                TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax", TaxDetail."Tax Type"::"Sales Tax Only");
                if TaxDetail.FindLast and TaxDetail."Expense/Capitalize" then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    if TaxDetail."Calculate Tax on Tax" then
                        TaxBaseAmount := Amount + TaxAmount
                    else
                        TaxBaseAmount := Amount;
                    TaxDetailMaximumsTemp := TaxDetail;
                    if not TaxDetailMaximumsTemp.Find then
                        TaxDetailMaximumsTemp.Insert;
                    MaxAmountPerQty := TaxDetailMaximumsTemp."Maximum Amount/Qty.";
                    if (Abs(TaxBaseAmount) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then begin
                        TaxAmount := TaxAmount + TaxBaseAmount * TaxDetail."Tax Below Maximum" / 100;
                        TaxDetailMaximumsTemp."Maximum Amount/Qty." := TaxDetailMaximumsTemp."Maximum Amount/Qty." - TaxBaseAmount;
                        TaxDetailMaximumsTemp.Modify;
                    end else begin
                        MaxAmount := TaxBaseAmount / Abs(TaxBaseAmount) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + ((MaxAmount * TaxDetail."Tax Below Maximum") +
                                       ((TaxBaseAmount - MaxAmount) * TaxDetail."Tax Above Maximum")) / 100;
                        TaxDetailMaximumsTemp."Maximum Amount/Qty." := 0;
                        TaxDetailMaximumsTemp.Modify;
                    end;
                end;
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast and TaxDetail."Expense/Capitalize" then begin
                    TaxDetailMaximumsTemp := TaxDetail;
                    if not TaxDetailMaximumsTemp.Find then
                        TaxDetailMaximumsTemp.Insert;
                    MaxAmountPerQty := TaxDetailMaximumsTemp."Maximum Amount/Qty.";

                    if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then begin
                        TaxAmount := TaxAmount + Quantity * TaxDetail."Tax Below Maximum";
                        TaxDetailMaximumsTemp."Maximum Amount/Qty." := TaxDetailMaximumsTemp."Maximum Amount/Qty." - Quantity;
                        TaxDetailMaximumsTemp.Modify;
                    end else begin
                        MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + (MaxAmount * TaxDetail."Tax Below Maximum") +
                          ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                        TaxDetailMaximumsTemp."Maximum Amount/Qty." := 0;
                        TaxDetailMaximumsTemp.Modify;
                    end;
                end;
            until TaxAreaLine.Next(-1) = 0;
        end;

        TaxAmount := TaxAmount * ExchangeFactor;

        if TaxOnTaxCalculated and CalculationOrderViolation then
            Error(
              Text000,
              TaxAreaLine.FieldCaption("Calculation Order"), TaxArea.TableCaption, TaxAreaLine."Tax Area",
              TaxDetail.FieldCaption("Calculate Tax on Tax"), CalculationOrderViolation);
    end;

    procedure HandleRoundTaxUpOrDown(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; RoundTax: Option "To Nearest",Up,Down; TotalTaxAmount: Decimal; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        RoundedAmount: Decimal;
        RoundingError: Decimal;
    begin
        if (RoundTax = RoundTax::"To Nearest") or (TotalTaxAmount = 0) then
            exit;
        case RoundTax of
            RoundTax::Up:
                RoundedAmount := Round(TotalTaxAmount, 0.01, '>');
            RoundTax::Down:
                RoundedAmount := Round(TotalTaxAmount, 0.01, '<');
        end;
        RoundingError := RoundedAmount - TotalTaxAmount;
        with SalesTaxAmountLine do begin
            Reset;
            SetRange("Tax Area Code for Key", TaxAreaCode);
            SetRange("Tax Group Code", TaxGroupCode);
            SetRange("Is Report-to Jurisdiction", true);
            if FindFirst then begin
                Delete;
                "Tax Amount" := "Tax Amount" + RoundingError;
                "Amount Including Tax" := "Tax Amount" + "Tax Base Amount";
                if "Tax Type" = "Tax Type"::"Excise Tax" then
                    "Tax %" := 0
                else
                    if "Tax Base Amount" <> 0 then
                        "Tax %" := 100 * ("Amount Including Tax" - "Tax Base Amount") / "Tax Base Amount";
                Insert;
            end;
        end;
    end;

    local procedure CheckTaxAmtLinePos(SalesLineAmt: Decimal; TaxAmtLinePos: Boolean): Boolean
    begin
        exit(
          ((SalesLineAmt > 0) and TaxAmtLinePos) or
          ((SalesLineAmt <= 0) and not TaxAmtLinePos)
          );
    end;

    local procedure ResetTaxAmountsInPurchLines(var PurchaseLine: Record "Purchase Line"; TaxAreaCode: Code[20])
    begin
        with PurchaseLine do begin
            if TaxCountry = TaxCountry::US then
                SetRange("Tax Area Code", TaxAreaCode);
            if FindSet(true) then
                repeat
                    TempSalesTaxLine.SetRange("Tax Area Code", TaxAreaCode);
                    TempSalesTaxLine.SetRange("Tax Group Code", "Tax Group Code");
                    TempSalesTaxLine.SetRange("Use Tax", "Use Tax");
                    if TempSalesTaxLine.IsEmpty then begin
                        Amount := "Line Amount" - "Inv. Discount Amount";
                        "Amount Including VAT" := Amount;
                        "VAT Base Amount" := Amount;
                        "VAT %" := 0;
                        "Tax To Be Expensed" := 0;
                        Modify;
                    end;
                until Next = 0;
        end;
    end;

    local procedure ResetTaxAmountsInSalesLines(var SalesLine: Record "Sales Line"; TaxAreaCode: Code[20])
    begin
        with SalesLine do begin
            if TaxCountry = TaxCountry::US then
                SetRange("Tax Area Code", TaxAreaCode);
            if FindSet(true) then
                repeat
                    TempSalesTaxLine.SetRange("Tax Area Code", TaxAreaCode);
                    TempSalesTaxLine.SetRange("Tax Group Code", "Tax Group Code");
                    if TempSalesTaxLine.IsEmpty then begin
                        Amount := "Line Amount" - "Inv. Discount Amount";
                        "Amount Including VAT" := Amount;
                        "VAT Base Amount" := Amount;
                        "VAT %" := 0;
                        Modify;
                    end;
                until Next = 0;
        end;
    end;

    local procedure IsFinalPrepaidSalesLine(SalesLine: Record "Sales Line"): Boolean
    var
        SalesHeader: Record "Sales Header";
        CheckSalesLine: Record "Sales Line";
    begin
        if not PrepmtPosting then
            exit(false);

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        if not CheckSalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then
            exit(false);

        if CheckSalesLine."Prepayment %" = 0 then
            exit;

        if not SalesHeader."Prepmt. Include Tax" then
            if CheckSalesLine."Prepmt. Amt. Inv." = 0 then
                exit(false);

        exit(CheckSalesLine.IsFinalInvoice);
    end;

    local procedure UpdateSalesTaxForPrepmt(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var TotalTaxAmount: Decimal; RoundTax: Option "To Nearest",Up,Down)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CheckTotalTaxAmount: Decimal;
        TaxRoundingDiff: Decimal;
    begin
        if TotalTaxAmount = 0 then
            exit;

        case RoundTax of
            RoundTax::"To Nearest":
                CheckTotalTaxAmount := Round(TotalTaxAmount);
            RoundTax::Up:
                CheckTotalTaxAmount := Round(TotalTaxAmount, 0.01, '>');
            RoundTax::Down:
                CheckTotalTaxAmount := Round(TotalTaxAmount, 0.01, '<');
        end;

        if not TempPrepaidSalesLine.IsEmpty then begin
            TempPrepaidSalesLine.CalcSums("Amount Including VAT");
            TaxRoundingDiff :=
              TempPrepaidSalesLine."Amount Including VAT" - TempPrepaidSalesLine.GetPrepaidSalesAmountInclVAT -
              (SalesTaxAmountLine."Tax Base Amount" + CheckTotalTaxAmount);
            GeneralLedgerSetup.Get;
            if Abs(TaxRoundingDiff) <= GeneralLedgerSetup."Amount Rounding Precision" then begin
                TotalTaxAmount := TotalTaxAmount + TaxRoundingDiff;
                SalesTaxAmountLine."Tax Amount" += TaxRoundingDiff;
                SalesTaxAmountLine."Amount Including Tax" += TaxRoundingDiff;
                SalesTaxAmountLine.Modify;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetPrepmtPosting(NewPrepmtPosting: Boolean)
    begin
        PrepmtPosting := NewPrepmtPosting;
    end;

    local procedure SetTaxDetailFilter(var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; Date: Date)
    begin
        TaxDetail.Reset;
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdictionCode);
        if TaxGroupCode = '' then
            TaxDetail.SetFilter("Tax Group Code", '%1', TaxGroupCode)
        else
            TaxDetail.SetFilter("Tax Group Code", '%1|%2', '', TaxGroupCode);
        if Date = 0D then
            TaxDetail.SetFilter("Effective Date", '<=%1', WorkDate)
        else
            TaxDetail.SetFilter("Effective Date", '<=%1', Date);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDistTaxOverPurchLines(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDistTaxOverSalesLines(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDistTaxOverServLines(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEndSalesTaxCalculationSales(SalesHeader: Record "Sales Header"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEndSalesTaxCalculationPurchase(PurchaseHeader: Record "Purchase Header"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEndSalesTaxCalculationService(ServiceHeader: Record "Service Header"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSummarizedSalesTaxTable(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostedSummarizedSalesTaxTable(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var TempSalesTaxAmountDifference: Record "Sales Tax Amount Difference" temporary; var IsHandled: Boolean)
    begin
    end;
}

