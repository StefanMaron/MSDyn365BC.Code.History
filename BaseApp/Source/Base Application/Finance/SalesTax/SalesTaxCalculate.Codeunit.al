namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 398 "Sales Tax Calculate"
{
    Permissions = TableData "Sales Header" = rim,
                  TableData "Sales Line" = rim,
                  TableData "Purchase Header" = rim,
                  TableData "Purchase Line" = rim,
                  TableData "Service Header" = rim,
                  TableData "Service Line" = rim;

    trigger OnRun()
    begin
    end;

    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TempTaxDetail: Record "Tax Detail" temporary;
        TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary;
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        TempSalesHeader: Record "Sales Header" temporary;
        PurchHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        TaxAmountDifference: Record "Sales Tax Amount Difference";
        TempTaxAmountDifference: Record "Sales Tax Amount Difference" temporary;
        TempTaxDetailMaximums: Record "Tax Detail" temporary;
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
        MaxAmountPerQty: Decimal;
        TaxCountry: Option US,CA;
        IsTotalTaxAmountRoundingSpecified: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 in %2 %3 must be filled in with unique values when %4 is %5.';
        Text001: Label 'The sales tax amount for the %1 %2 and the %3 %4 is incorrect. ';
#pragma warning restore AA0470
        Text003: Label 'Lines is not initialized';
#pragma warning disable AA0470
        Text004: Label 'The calculated sales tax amount is %5, but was supposed to be %6.';
        Text1020000: Label 'Tax country/region %1 is being used.  You must use %2.';
        Text1020001: Label 'Note to Programmers: The function "CopyTaxDifferences" must not be called unless the function "EndSalesTaxCalculation", or the function "PutSalesTaxAmountLineTable", is called first.';
        Text1020003: Label 'Invalid function call. Function reserved for external tax engines only.';
#pragma warning restore AA0470
#pragma warning restore AA0074

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
        OldTransactionID := SalesHeader."STE Transaction ID";
        SalesHeader."STE Transaction ID" := CallExternalTaxEngineForDoc(DATABASE::"Sales Header", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        STETransactionIDChanged := (SalesHeader."STE Transaction ID" <> OldTransactionID);
        if STETransactionIDChanged and UpdateRecIfChanged then
            SalesHeader.Modify();
    end;

    procedure CallExternalTaxEngineForPurch(var PurchHeader: Record "Purchase Header"; UpdateRecIfChanged: Boolean) STETransactionIDChanged: Boolean
    var
        OldTransactionID: Text[20];
    begin
        OldTransactionID := PurchHeader."STE Transaction ID";
        PurchHeader."STE Transaction ID" := CallExternalTaxEngineForDoc(DATABASE::"Purchase Header", PurchHeader."Document Type".AsInteger(), PurchHeader."No.");
        STETransactionIDChanged := (PurchHeader."STE Transaction ID" <> OldTransactionID);
        if STETransactionIDChanged and UpdateRecIfChanged then
            PurchHeader.Modify();
    end;

    procedure CallExternalTaxEngineForServ(var ServiceHeader: Record "Service Header"; UpdateRecIfChanged: Boolean) STETransactionIDChanged: Boolean
    var
        OldTransactionID: Text[20];
    begin
        OldTransactionID := ServiceHeader."STE Transaction ID";
        ServiceHeader."STE Transaction ID" := CallExternalTaxEngineForDoc(DATABASE::"Service Header", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.");
        STETransactionIDChanged := (ServiceHeader."STE Transaction ID" <> OldTransactionID);
        if STETransactionIDChanged and UpdateRecIfChanged then
            ServiceHeader.Modify();
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
        IsHandled: Boolean;
    begin
        TaxAmount := 0;
        IsHandled := false;
        OnBeforeCalculateTaxProcedure(TaxAreaCode, TaxGroupCode, TaxLiable, Date, Amount, Quantity, ExchangeRate, TaxAmount, IsHandled);
        if IsHandled then
            exit;

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
                if TaxDetail.FindLast() and not TaxDetail."Expense/Capitalize" then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    if TaxDetail."Calculate Tax on Tax" then
                        TaxBaseAmount := Amount + TaxAmount
                    else
                        TaxBaseAmount := Amount;
                    // This code uses a temporary table to keep track of Maximums.
                    // This temporary table should be cleared before the first call
                    // to this routine.  All subsequent calls will use the values in
                    // that get put into this temporary table.
                    TempTaxDetailMaximums := TaxDetail;
                    if not TempTaxDetailMaximums.Find() then
                        TempTaxDetailMaximums.Insert();
                    MaxAmountPerQty := TempTaxDetailMaximums."Maximum Amount/Qty.";
                    if (Abs(TaxBaseAmount) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then begin
                        TaxAmount := TaxAmount + TaxBaseAmount * TaxDetail."Tax Below Maximum" / 100;
                        TempTaxDetailMaximums."Maximum Amount/Qty." := TempTaxDetailMaximums."Maximum Amount/Qty." - TaxBaseAmount;
                        TempTaxDetailMaximums.Modify();
                    end else begin
                        MaxAmount := TaxBaseAmount / Abs(TaxBaseAmount) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + ((MaxAmount * TaxDetail."Tax Below Maximum") +
                                       ((TaxBaseAmount - MaxAmount) * TaxDetail."Tax Above Maximum")) / 100;
                        TempTaxDetailMaximums."Maximum Amount/Qty." := 0;
                        TempTaxDetailMaximums.Modify();
                    end;
                end;
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast() and not TaxDetail."Expense/Capitalize" then begin
                    TempTaxDetailMaximums := TaxDetail;
                    if not TempTaxDetailMaximums.Find() then
                        TempTaxDetailMaximums.Insert();
                    MaxAmountPerQty := TempTaxDetailMaximums."Maximum Amount/Qty.";

                    if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then begin
                        TaxAmount := TaxAmount + Quantity * TaxDetail."Tax Below Maximum";
                        TempTaxDetailMaximums."Maximum Amount/Qty." := TempTaxDetailMaximums."Maximum Amount/Qty." - Quantity;
                        TempTaxDetailMaximums.Modify();
                    end else begin
                        MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + (MaxAmount * TaxDetail."Tax Below Maximum") +
                          ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                        TempTaxDetailMaximums."Maximum Amount/Qty." := 0;
                        TempTaxDetailMaximums.Modify();
                    end;
                end;
            until TaxAreaLine.Next(-1) = 0;
        end;
        TaxAmount := TaxAmount * ExchangeFactor;

        if TaxOnTaxCalculated and CalculationOrderViolation then
            Error(
              Text000,
              TaxAreaLine.FieldCaption("Calculation Order"), TaxArea.TableCaption(), TaxAreaLine."Tax Area",
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
                if TaxDetail.FindLast() then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    InclinationLess := TaxDetail."Tax Below Maximum" / 100;
                    InclinationHigher := TaxDetail."Tax Above Maximum" / 100;

                    if TaxDetail."Maximum Amount/Qty." = 0 then
                        for i := 1 to Steps do
                            if TaxDetail."Calculate Tax on Tax" then begin
                                Inclination[i] := Inclination[i] + (1 + Inclination[i]) * InclinationLess;
                                Constant[i] := (1 + InclinationLess) * Constant[i];
                            end else
                                Inclination[i] := Inclination[i] + InclinationLess
                    else begin
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
                                    if TaxDetail."Calculate Tax on Tax" then begin
                                        Inclination[i] := Inclination[i] + (1 + Inclination[i]) * InclinationLess;
                                        Constant[i] := (1 + InclinationLess) * Constant[i];
                                    end else
                                        Inclination[i] := Inclination[i] + InclinationLess;
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
                if TaxDetail.FindLast() then begin
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
              TaxAreaLine.FieldCaption("Calculation Order"), TaxArea.TableCaption(), TaxAreaLine."Tax Area",
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
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitSalesTaxLines(TaxAreaCode, TaxGroupCode, TaxLiable, Amount, Quantity, Date, DesiredTaxAmount, TempTaxDetail, IsHandled, Initialised, FirstLine, TotalForAllocation);
        if IsHandled then
            exit;

        TaxAmount := 0;

        Initialised := true;
        FirstLine := true;
        TempTaxDetail.DeleteAll();

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
                if TaxDetail.FindLast() and
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

                        TempTaxDetailMaximums := TaxDetail;
                        if not TempTaxDetailMaximums.Find() then
                            TempTaxDetailMaximums.Insert();
                        MaxAmountPerQty := TempTaxDetailMaximums."Maximum Amount/Qty.";

                        if (Abs(TaxBaseAmount) <= TaxDetail."Maximum Amount/Qty.") or
                           (TaxDetail."Maximum Amount/Qty." = 0)
                        then begin
                            AddedTaxAmount := TaxBaseAmount * TaxDetail."Tax Below Maximum" / 100;
                            TempTaxDetailMaximums."Maximum Amount/Qty." := TempTaxDetailMaximums."Maximum Amount/Qty." - Quantity;
                            TempTaxDetailMaximums.Modify();
                        end else begin
                            MaxAmount := TaxBaseAmount / Abs(TaxBaseAmount) * TaxDetail."Maximum Amount/Qty.";
                            AddedTaxAmount :=
                              ((MaxAmount * TaxDetail."Tax Below Maximum") +
                               ((TaxBaseAmount - MaxAmount) * TaxDetail."Tax Above Maximum")) / 100;
                            TempTaxDetailMaximums."Maximum Amount/Qty." := 0;
                            TempTaxDetailMaximums.Modify();
                        end;
                    end else
                        AddedTaxAmount := 0;
                    TaxAmount := TaxAmount + AddedTaxAmount;
                    TempTaxDetail := TaxDetail;
                    TempTaxDetail."Tax Below Maximum" := AddedTaxAmount;
                    TempTaxDetail."Tax Above Maximum" := TaxBaseAmount;
                    TempTaxDetail.Insert();
                    RemainingTaxDetails := RemainingTaxDetails + 1;
                end;
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast() and
                   ((TaxDetail."Tax Below Maximum" <> 0) or (TaxDetail."Tax Above Maximum" <> 0)) and
                   not TaxDetail."Expense/Capitalize"
                then begin
                    if TaxLiable then begin
                        TempTaxDetailMaximums := TaxDetail;
                        if not TempTaxDetailMaximums.Find() then
                            TempTaxDetailMaximums.Insert();
                        if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                           (TaxDetail."Maximum Amount/Qty." = 0)
                        then begin
                            AddedTaxAmount := Quantity * TaxDetail."Tax Below Maximum";
                            TempTaxDetailMaximums."Maximum Amount/Qty." := TempTaxDetailMaximums."Maximum Amount/Qty." - Quantity;
                            TempTaxDetailMaximums.Modify();
                        end else begin
                            MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                            AddedTaxAmount :=
                              (MaxAmount * TaxDetail."Tax Below Maximum") +
                              ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                            TempTaxDetailMaximums."Maximum Amount/Qty." := 0;
                            TempTaxDetailMaximums.Modify();
                        end;
                    end else
                        AddedTaxAmount := 0;
                    TaxAmount := TaxAmount + AddedTaxAmount;
                    TempTaxDetail := TaxDetail;
                    TempTaxDetail."Tax Below Maximum" := AddedTaxAmount;
                    TempTaxDetail."Tax Above Maximum" := TaxBaseAmount;
                    TempTaxDetail.Insert();
                    RemainingTaxDetails := RemainingTaxDetails + 1;
                end;
            until TaxAreaLine.Next(-1) = 0;
        end;

        TaxAmount := Round(TaxAmount);

        if (TaxAmount <> DesiredTaxAmount) and (Abs(TaxAmount - DesiredTaxAmount) <= 0.01) then
            if TempTaxDetail.FindSet(true) then begin
                TempTaxDetail."Tax Below Maximum" :=
                  TempTaxDetail."Tax Below Maximum" - TaxAmount + DesiredTaxAmount;
                TempTaxDetail.Modify();
                TaxAmount := DesiredTaxAmount;
            end;

        if TaxOnTaxCalculated and CalculationOrderViolation then
            Error(
              Text000,
              TaxAreaLine.FieldCaption("Calculation Order"), TaxArea.TableCaption(), TaxAreaLine."Tax Area",
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

    procedure HasExciseTax(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Quantity: Decimal; Date: Date): Boolean
    begin
        if (TaxAreaCode = '') or (TaxGroupCode = '') or not TaxLiable then
            exit(false);

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        if TaxAreaLine.Find('+') then
            repeat
                SetTaxDetailFilter(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, Date);
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast() and
                   ((TaxDetail."Tax Below Maximum" <> 0) or (TaxDetail."Tax Above Maximum" <> 0)) and
                   not TaxDetail."Expense/Capitalize"
                then
                    if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then
                        exit(true);
            until TaxAreaLine.Next(-1) = 0;

        exit(false);
    end;

    procedure GetSalesTaxLine(var TaxDetail2: Record "Tax Detail"; var ReturnTaxAmount: Decimal; var ReturnTaxBaseAmount: Decimal): Boolean
    var
        TaxAmount: Decimal;
    begin
        ReturnTaxAmount := 0;

        if not Initialised then
            Error(Text003);

        if FirstLine then begin
            if not TempTaxDetail.Find('-') then begin
                Initialised := false;
                exit(false);
            end;
            TotalTaxAmountRounding := 0;
            FirstLine := false;
        end else
            if TempTaxDetail.Next() = 0 then begin
                Initialised := false;
                exit(false);
            end;

        ReturnTaxBaseAmount := Round(TempTaxDetail."Tax Above Maximum");

        TaxAmount := TempTaxDetail."Tax Below Maximum";
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
        if TempTaxDetail."Tax Below Maximum" = 0 then
            ReturnTaxAmount := 0;

        TaxDetail2 := TempTaxDetail;

        exit(true);
    end;

    procedure ClearMaximums()
    begin
        TempTaxDetailMaximums.DeleteAll();
    end;

    procedure StartSalesTaxCalculation()
    begin
        OnBeforeStartSalestaxCalculation();

        TempSalesTaxAmountLine.Reset();
        TempSalesTaxAmountLine.DeleteAll();
        TempTaxAmountDifference.Reset();
        TempTaxAmountDifference.DeleteAll();
        ClearAll();
    end;

    internal procedure SetTmpSalesHeader(SalesHeader: Record "Sales Header")
    begin
        TempSalesHeader.DeleteAll();
        TempSalesHeader.Copy(SalesHeader);
        TempSalesHeader.Insert();
    end;

    procedure AddSalesLine(SalesLine: Record "Sales Line")
    var
        TaxDetail: Record "Tax Detail";
        SalesTaxAmountLineCalc: Codeunit "Sales Tax Amount Line Calc";
        TotalPositive: Boolean;
        SalesLinePositive: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddSalesLine(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if not SalesHeaderRead then begin
            if TempSalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
                SalesHeader := TempSalesHeader
            else
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
                Enum::"Sales Tax Document Area"::Sales, SalesLine."Document Type".AsInteger(), SalesLine."Document No.");
            SalesHeader.CalcFields(Amount);
        end;
        if not GetSalesTaxCountry(SalesLine."Tax Area Code") then
            exit;

        SalesLine.TestField("Tax Group Code");
        TempSalesTaxAmountLine.Reset();
        case TaxCountry of
            TaxCountry::US:
                // Area Code
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", SalesLine."Tax Area Code");
                    TempSalesTaxAmountLine."Tax Area Code for Key" := SalesLine."Tax Area Code";
                end;
            TaxCountry::CA:
                // Jurisdictions
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", '');
                    TempSalesTaxAmountLine."Tax Area Code for Key" := '';
                end;
        end;
        TempSalesTaxAmountLine.SetRange("Tax Group Code", SalesLine."Tax Group Code");
        OnAddSalesLineOnAfterTempSalesTaxAmountLineSetFilters(TempSalesTaxAmountLine);

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", SalesLine."Tax Area Code");

        TotalPositive := SalesHeader.Amount > 0;
        SalesLinePositive := SalesLine."Line Amount" > 0;
        TaxDetail.SetRange("Tax Group Code", SalesLine."Tax Group Code");
        TaxDetail.SetFilter("Effective Date", '<=%1', SalesHeader."Posting Date");

        if TaxAreaLine.FindSet() then
            repeat
                TempSalesTaxAmountLine.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";

                TempSalesTaxAmountLine.SetRange(Positive, SalesLinePositive);
                TempSalesTaxAmountLine.Positive := SalesLinePositive;
                TaxDetail.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                if (TotalPositive <> SalesLinePositive) and (SalesHeader.Amount <> 0) then
                    if TaxDetail.FindLast() then
                        if TaxDetail."Maximum Amount/Qty." <> 0 then begin
                            TempSalesTaxAmountLine.SetRange(Positive, TotalPositive);
                            TempSalesTaxAmountLine.Positive := TotalPositive;
                        end;

                OnAddSalesLineOnAfterSetSalesTaxAmountLineFilter(TempSalesTaxAmountLine, SalesLine, TaxAreaLine);
                if not TempSalesTaxAmountLine.FindFirst() then begin
                    TempSalesTaxAmountLine.Init();
                    TempSalesTaxAmountLine."Tax Group Code" := SalesLine."Tax Group Code";
                    TempSalesTaxAmountLine."Tax Area Code" := SalesLine."Tax Area Code";
                    TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                    if TaxCountry = TaxCountry::US then begin
                        TempSalesTaxAmountLine."Round Tax" := TaxArea."Round Tax";
                        TaxJurisdiction.Get(TempSalesTaxAmountLine."Tax Jurisdiction Code");
                        TempSalesTaxAmountLine."Is Report-to Jurisdiction" := (TempSalesTaxAmountLine."Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                    end;
                    SalesTaxAmountLineCalc.SetTaxBaseAmount(
                        TempSalesTaxAmountLine, SalesLine."Line Amount" - SalesLine."Inv. Discount Amount", ExchangeFactor, false);
                    TempSalesTaxAmountLine."Line Amount" := SalesLine."Line Amount" / ExchangeFactor;
                    TempSalesTaxAmountLine."Tax Liable" := SalesLine."Tax Liable";
                    TempSalesTaxAmountLine.Quantity := SalesLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := SalesLine."Inv. Discount Amount";
                    TempSalesTaxAmountLine."Calculation Order" := TaxAreaLine."Calculation Order";
                    OnAddSalesLineOnBeforeTempSalesTaxAmountLineInsert(TempSalesTaxAmountLine, SalesLine);
                    TempSalesTaxAmountLine.Insert();
                end else begin
                    TempSalesTaxAmountLine."Line Amount" := TempSalesTaxAmountLine."Line Amount" + (SalesLine."Line Amount" / ExchangeFactor);
                    TempSalesTaxAmountLine."Tax Liable" := SalesLine."Tax Liable";
                    SalesTaxAmountLineCalc.SetTaxBaseAmount(
                        TempSalesTaxAmountLine, SalesLine."Line Amount" - SalesLine."Inv. Discount Amount", ExchangeFactor, true);
                    TempSalesTaxAmountLine."Tax Amount" := 0;
                    TempSalesTaxAmountLine.Quantity := TempSalesTaxAmountLine.Quantity + SalesLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := TempSalesTaxAmountLine."Invoice Discount Amount" + SalesLine."Inv. Discount Amount";
                    OnAddSalesLineOnBeforeModifySalesTaxAmountLine(TempSalesTaxAmountLine, SalesLine);
                    TempSalesTaxAmountLine.Modify();
                end;
            until TaxAreaLine.Next() = 0;

        OnAfterAddSalesLine(TempSalesTaxAmountLine, SalesLine, SalesHeader, ExchangeFactor);
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
        if SalesInvoiceLine.FindSet() then
            repeat
                SalesTaxAmountLineCalc.InitFromSalesInvLine(SalesInvoiceLine);
                SalesTaxAmountLineCalc.CalcSalesOrServLineSalesTaxAmountLine(
                  TempSalesTaxAmountLine, TaxAreaLine, TaxCountry, TaxArea, TaxJurisdiction, ExchangeFactor);
            until SalesInvoiceLine.Next() = 0;

        CopyTaxDifferencesToTemp(
            Enum::"Sales Tax Document Area"::"Posted Sale", TaxAmountDifference."Document Type"::Invoice, SalesInvoiceHeader."No.");
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
        if SalesCrMemoLine.FindSet() then
            repeat
                SalesTaxAmountLineCalc.InitFromSalesCrMemoLine(SalesCrMemoLine);
                SalesTaxAmountLineCalc.CalcSalesOrServLineSalesTaxAmountLine(
                  TempSalesTaxAmountLine, TaxAreaLine, TaxCountry, TaxArea, TaxJurisdiction, ExchangeFactor);
            until SalesCrMemoLine.Next() = 0;

        CopyTaxDifferencesToTemp(
            Enum::"Sales Tax Document Area"::"Posted Sale", TaxAmountDifference."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");
    end;

    procedure AddPurchLine(PurchLine: Record "Purchase Line")
    var
        TaxDetail: Record "Tax Detail";
        SalesTaxAmountLineCalc: Codeunit "Sales Tax Amount Line Calc";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddPurchLine(PurchLine, IsHandled);
        if IsHandled then
            exit;

        if not PurchHeaderRead then begin
            PurchLine.GetPurchHeader();
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
                Enum::"Sales Tax Document Area"::Purchase, PurchLine."Document Type".AsInteger(), PurchLine."Document No.");
        end;
        if not GetSalesTaxCountry(PurchLine."Tax Area Code") then
            exit;

        PurchLine.TestField("Tax Group Code");

        TempSalesTaxAmountLine.Reset();
        case TaxCountry of
            TaxCountry::US:
                // Area Code
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", PurchLine."Tax Area Code");
                    TempSalesTaxAmountLine."Tax Area Code for Key" := PurchLine."Tax Area Code";
                end;
            TaxCountry::CA:
                // Jurisdictions
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", '');
                    TempSalesTaxAmountLine."Tax Area Code for Key" := '';
                end;
        end;
        TempSalesTaxAmountLine.SetRange("Tax Group Code", PurchLine."Tax Group Code");
        TempSalesTaxAmountLine.SetRange("Use Tax", PurchLine."Use Tax");
        OnAddPurchLineOnAfterTempSalesTaxAmountLineSetFilters(TempSalesTaxAmountLine);

        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", PurchLine."Tax Area Code");
        if TaxAreaLine.FindSet() then
            repeat
                TempSalesTaxAmountLine.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                if not TempSalesTaxAmountLine.FindFirst() then begin
                    TempSalesTaxAmountLine.Init();
                    TempSalesTaxAmountLine."Tax Group Code" := PurchLine."Tax Group Code";
                    TempSalesTaxAmountLine."Tax Area Code" := PurchLine."Tax Area Code";
                    TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                    if TaxCountry = TaxCountry::US then begin
                        TempSalesTaxAmountLine."Round Tax" := TaxArea."Round Tax";
                        TaxJurisdiction.Get(TempSalesTaxAmountLine."Tax Jurisdiction Code");
                        TempSalesTaxAmountLine."Is Report-to Jurisdiction" := (TempSalesTaxAmountLine."Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                    end;
                    SalesTaxAmountLineCalc.SetTaxBaseAmount(
                        TempSalesTaxAmountLine, PurchLine."Line Amount" - PurchLine."Inv. Discount Amount", ExchangeFactor, false);
                    TempSalesTaxAmountLine."Line Amount" := PurchLine."Line Amount" / ExchangeFactor;
                    TempSalesTaxAmountLine."Tax Liable" := PurchLine."Tax Liable";
                    TempSalesTaxAmountLine."Use Tax" := PurchLine."Use Tax";
                    SetTaxDetailFilter(TaxDetail, TempSalesTaxAmountLine."Tax Jurisdiction Code", TempSalesTaxAmountLine."Tax Group Code", PurchHeader."Posting Date");
                    if TempSalesTaxAmountLine."Use Tax" then
                        TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                          TaxDetail."Tax Type"::"Use Tax Only")
                    else
                        TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                          TaxDetail."Tax Type"::"Sales Tax Only");

                    if TaxDetail.FindLast() then
                        TempSalesTaxAmountLine."Expense/Capitalize" := TaxDetail."Expense/Capitalize";

                    TempSalesTaxAmountLine."Calculation Order" := TaxAreaLine."Calculation Order";
                    TempSalesTaxAmountLine.Quantity := PurchLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := PurchLine."Inv. Discount Amount";
                    TempSalesTaxAmountLine.Insert();
                end else begin
                    TempSalesTaxAmountLine."Line Amount" := TempSalesTaxAmountLine."Line Amount" + (PurchLine."Line Amount" / ExchangeFactor);
                    TempSalesTaxAmountLine."Tax Liable" := PurchLine."Tax Liable";
                    SalesTaxAmountLineCalc.SetTaxBaseAmount(
                        TempSalesTaxAmountLine, PurchLine."Line Amount" - PurchLine."Inv. Discount Amount", ExchangeFactor, true);
                    TempSalesTaxAmountLine."Tax Amount" := 0;
                    TempSalesTaxAmountLine.Quantity := TempSalesTaxAmountLine.Quantity + PurchLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := TempSalesTaxAmountLine."Invoice Discount Amount" + PurchLine."Inv. Discount Amount";
                    TempSalesTaxAmountLine.Modify();
                end;
            until TaxAreaLine.Next() = 0;

        OnAfterAddPurchLine(TempSalesTaxAmountLine, PurchLine, PurchHeader, ExchangeFactor);
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
        if PurchInvLine.FindSet() then
            repeat
                SalesTaxAmountLineCalc.InitFromPurchInvLine(PurchInvLine);
                SalesTaxAmountLineCalc.CalcPurchLineSalesTaxAmountLine(
                  TempSalesTaxAmountLine, TaxAreaLine, TaxCountry, TaxArea, TaxJurisdiction, ExchangeFactor, TaxDetail, PurchInvHeader."Posting Date");
                OnAddPurchInvoiceLinesOnAfterCalcPurchLineSalesTaxAmountLine(TempSalesTaxAmountLine, PurchInvLine, PurchInvHeader, ExchangeFactor);
            until PurchInvLine.Next() = 0;

        CopyTaxDifferencesToTemp(
            Enum::"Sales Tax Document Area"::"Posted Purchase", TaxAmountDifference."Document Type"::Invoice, PurchInvHeader."No.");
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
        if PurchCrMemoLine.FindSet() then
            repeat
                SalesTaxAmountLineCalc.InitFromPurchCrMemoLine(PurchCrMemoLine);
                SalesTaxAmountLineCalc.CalcPurchLineSalesTaxAmountLine(
                  TempSalesTaxAmountLine, TaxAreaLine, TaxCountry, TaxArea, TaxJurisdiction, ExchangeFactor, TaxDetail, PurchCrMemoHeader."Posting Date");
            until PurchCrMemoLine.Next() = 0;

        CopyTaxDifferencesToTemp(
            Enum::"Sales Tax Document Area"::"Posted Purchase", TaxAmountDifference."Document Type"::"Credit Memo", PurchCrMemoHeader."No.");
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
                Enum::"Sales Tax Document Area"::Service, ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.");
        end;
        if not GetSalesTaxCountry(ServiceLine."Tax Area Code") then
            exit;

        ServiceLine.TestField("Tax Group Code");

        TempSalesTaxAmountLine.Reset();
        case TaxCountry of
            TaxCountry::US:
                // Area Code
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", ServiceLine."Tax Area Code");
                    TempSalesTaxAmountLine."Tax Area Code for Key" := ServiceLine."Tax Area Code";
                end;
            TaxCountry::CA:
                // Jurisdictions
                begin
                    TempSalesTaxAmountLine.SetRange("Tax Area Code for Key", '');
                    TempSalesTaxAmountLine."Tax Area Code for Key" := '';
                end;
        end;
        TempSalesTaxAmountLine.SetRange("Tax Group Code", ServiceLine."Tax Group Code");
        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.SetRange("Tax Area", ServiceLine."Tax Area Code");
        if TaxAreaLine.FindSet() then
            repeat
                TempSalesTaxAmountLine.SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                if not TempSalesTaxAmountLine.FindFirst() then begin
                    TempSalesTaxAmountLine.Init();
                    TempSalesTaxAmountLine."Tax Group Code" := ServiceLine."Tax Group Code";
                    TempSalesTaxAmountLine."Tax Area Code" := ServiceLine."Tax Area Code";
                    TempSalesTaxAmountLine."Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                    if TaxCountry = TaxCountry::US then begin
                        TempSalesTaxAmountLine."Round Tax" := TaxArea."Round Tax";
                        TaxJurisdiction.Get(TempSalesTaxAmountLine."Tax Jurisdiction Code");
                        TempSalesTaxAmountLine."Is Report-to Jurisdiction" := (TempSalesTaxAmountLine."Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                    end;
                    SalesTaxAmountLineCalc.SetTaxBaseAmount(
                        TempSalesTaxAmountLine, ServiceLine."Line Amount" - ServiceLine."Inv. Discount Amount", ExchangeFactor, false);
                    TempSalesTaxAmountLine."Line Amount" := ServiceLine."Line Amount" / ExchangeFactor;
                    TempSalesTaxAmountLine."Tax Liable" := ServiceLine."Tax Liable";
                    TempSalesTaxAmountLine.Quantity := ServiceLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := ServiceLine."Inv. Discount Amount";
                    TempSalesTaxAmountLine."Calculation Order" := TaxAreaLine."Calculation Order";
                    TempSalesTaxAmountLine.Insert();
                end else begin
                    TempSalesTaxAmountLine."Line Amount" := TempSalesTaxAmountLine."Line Amount" + (ServiceLine."Line Amount" / ExchangeFactor);
                    TempSalesTaxAmountLine."Tax Liable" := ServiceLine."Tax Liable";
                    SalesTaxAmountLineCalc.SetTaxBaseAmount(
                        TempSalesTaxAmountLine, ServiceLine."Line Amount" - ServiceLine."Inv. Discount Amount", ExchangeFactor, true);
                    TempSalesTaxAmountLine."Tax Amount" := 0;
                    TempSalesTaxAmountLine.Quantity := TempSalesTaxAmountLine.Quantity + ServiceLine."Quantity (Base)";
                    TempSalesTaxAmountLine."Invoice Discount Amount" := TempSalesTaxAmountLine."Invoice Discount Amount" + ServiceLine."Inv. Discount Amount";
                    TempSalesTaxAmountLine.Modify();
                end;
            until TaxAreaLine.Next() = 0;
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
        if ServInvLine.FindSet() then
            repeat
                SalesTaxAmountLineCalc.InitFromServInvLine(ServInvLine);
                SalesTaxAmountLineCalc.CalcSalesOrServLineSalesTaxAmountLine(
                  TempSalesTaxAmountLine, TaxAreaLine, TaxCountry, TaxArea, TaxJurisdiction, ExchangeFactor);
            until ServInvLine.Next() = 0;

        CopyTaxDifferencesToTemp(
          Enum::"Sales Tax Document Area"::"Posted Service",
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
        if ServCrMemoLine.FindSet() then
            repeat
                SalesTaxAmountLineCalc.InitFromServCrMemoLine(ServCrMemoLine);
                SalesTaxAmountLineCalc.CalcSalesOrServLineSalesTaxAmountLine(
                  TempSalesTaxAmountLine, TaxAreaLine, TaxCountry, TaxArea, TaxJurisdiction, ExchangeFactor);
            until ServCrMemoLine.Next() = 0;

        CopyTaxDifferencesToTemp(
          Enum::"Sales Tax Document Area"::"Posted Service",
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
        LastPositive: Boolean;
        RoundTax: Option "To Nearest",Up,Down;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        case true of
            SalesHeaderRead:
                OnBeforeEndSalesTaxCalculationSales(SalesHeader, TempSalesTaxAmountLine, IsHandled);
            PurchHeaderRead:
                OnBeforeEndSalesTaxCalculationPurchase(PurchHeader, TempSalesTaxAmountLine, IsHandled);
            ServHeaderRead:
                OnBeforeEndSalesTaxCalculationService(ServiceHeader, TempSalesTaxAmountLine, IsHandled);
        end;
        if IsHandled then
            exit;

        TempSalesTaxAmountLine.Reset();
        TempSalesTaxAmountLine.SetRange("Tax Type", TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax");
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                SetTaxDetailFilter(TaxDetail, TempSalesTaxAmountLine."Tax Jurisdiction Code", TempSalesTaxAmountLine."Tax Group Code", Date);
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
                if TempSalesTaxAmountLine."Use Tax" then
                    TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                      TaxDetail."Tax Type"::"Use Tax Only")
                else
                    TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                      TaxDetail."Tax Type"::"Sales Tax Only");
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast() then begin
                    TempSalesTaxAmountLine."Tax Type" := TempSalesTaxAmountLine."Tax Type"::"Excise Tax";
                    TempSalesTaxAmountLine.Insert();
                    TempSalesTaxAmountLine."Tax Type" := TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax";
                end;
            until TempSalesTaxAmountLine.Next() = 0;
        TempSalesTaxAmountLine.Reset();
        if TempSalesTaxAmountLine.FindSet(true) then
            repeat
                TempTaxAmountDifference.Reset();
                TempTaxAmountDifference.SetRange("Tax Area Code", TempSalesTaxAmountLine."Tax Area Code for Key");
                TempTaxAmountDifference.SetRange("Tax Jurisdiction Code", TempSalesTaxAmountLine."Tax Jurisdiction Code");
                TempTaxAmountDifference.SetRange("Tax Group Code", TempSalesTaxAmountLine."Tax Group Code");
                TempTaxAmountDifference.SetRange("Expense/Capitalize", TempSalesTaxAmountLine."Expense/Capitalize");
                TempTaxAmountDifference.SetRange("Tax Type", TempSalesTaxAmountLine."Tax Type");
                TempTaxAmountDifference.SetRange("Use Tax", TempSalesTaxAmountLine."Use Tax");
                TempTaxAmountDifference.SetRange(Positive, TempSalesTaxAmountLine.Positive);
                if TempTaxAmountDifference.FindFirst() then begin
                    TempSalesTaxAmountLine."Tax Difference" := TempTaxAmountDifference."Tax Difference";
                    OnEndSalesTaxCalculationOnBeforeTempSalesTaxLineModify(TempSalesTaxAmountLine);
                    TempSalesTaxAmountLine.Modify();
                end;
            until TempSalesTaxAmountLine.Next() = 0;
        TempSalesTaxAmountLine.Reset();
        TempSalesTaxAmountLine.SetCurrentKey("Tax Area Code for Key", "Tax Group Code", "Tax Type", "Calculation Order");
        if TempSalesTaxAmountLine.FindLast() then begin
            LastTaxAreaCode := TempSalesTaxAmountLine."Tax Area Code for Key";
            LastCalculationOrder := -9999;
            LastTaxType := TempSalesTaxAmountLine."Tax Type";
            LastTaxGroupCode := TempSalesTaxAmountLine."Tax Group Code";
            RoundTax := TempSalesTaxAmountLine."Round Tax";
            repeat
                if (LastTaxAreaCode <> TempSalesTaxAmountLine."Tax Area Code for Key") or
                   (LastTaxGroupCode <> TempSalesTaxAmountLine."Tax Group Code")
                then begin
                    HandleRoundTaxUpOrDown(SalesTaxAmountLine2, RoundTax, TotalTaxAmount, LastTaxAreaCode, LastTaxGroupCode);
                    LastTaxAreaCode := TempSalesTaxAmountLine."Tax Area Code for Key";
                    LastTaxType := TempSalesTaxAmountLine."Tax Type";
                    LastTaxGroupCode := TempSalesTaxAmountLine."Tax Group Code";
                    TaxOnTaxCalculated := false;
                    LastCalculationOrder := -9999;
                    CalculationOrderViolation := false;
                    TotalTaxAmount := 0;
                    RoundTax := TempSalesTaxAmountLine."Round Tax";
                end;
                if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then
                    TaxBaseAmt := TempSalesTaxAmountLine."Tax Base Amount"
                else
                    TaxBaseAmt := TempSalesTaxAmountLine.Quantity;
                if (LastCalculationOrder = TempSalesTaxAmountLine."Calculation Order") and (LastPositive = TempSalesTaxAmountLine.Positive) then
                    CalculationOrderViolation := true;
                LastCalculationOrder := TempSalesTaxAmountLine."Calculation Order";
                LastPositive := TempSalesTaxAmountLine.Positive;

                SetTaxDetailFilter(TaxDetail, TempSalesTaxAmountLine."Tax Jurisdiction Code", TempSalesTaxAmountLine."Tax Group Code", Date);
                TaxDetail.SetRange("Tax Type", TempSalesTaxAmountLine."Tax Type");
                if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then
                    if TempSalesTaxAmountLine."Use Tax" then
                        TaxDetail.SetFilter("Tax Type", '%1|%2', TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax",
                          TempSalesTaxAmountLine."Tax Type"::"Use Tax Only")
                    else
                        TaxDetail.SetFilter("Tax Type", '%1|%2', TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax",
                          TempSalesTaxAmountLine."Tax Type"::"Sales Tax Only");
                if TaxDetail.FindLast() then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    if TaxDetail."Calculate Tax on Tax" and (TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax") then
                        TaxBaseAmt := TempSalesTaxAmountLine."Tax Base Amount" + TotalTaxAmount;
                    if TempSalesTaxAmountLine."Tax Liable" then begin
                        if (Abs(TaxBaseAmt) <= TaxDetail."Maximum Amount/Qty.") or
                           (TaxDetail."Maximum Amount/Qty." = 0)
                        then begin
                            if TempSalesTaxAmountLine."Tax Base Amount FCY" <> TempSalesTaxAmountLine."Tax Base Amount" then begin
                                AddedTaxAmount := Round((TempSalesTaxAmountLine."Tax Base Amount FCY" * TaxDetail."Tax Below Maximum") / 100, Currency."Amount Rounding Precision");
                                AddedTaxAmount := 100 * AddedTaxAmount / ExchangeFactor;
                            end else
                                AddedTaxAmount := TaxBaseAmt * TaxDetail."Tax Below Maximum"
                        end
                        else begin
                            if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then
                                MaxAmount := TaxBaseAmt / Abs(TempSalesTaxAmountLine."Tax Base Amount") * TaxDetail."Maximum Amount/Qty."
                            else
                                MaxAmount := TempSalesTaxAmountLine.Quantity / Abs(TempSalesTaxAmountLine.Quantity) * TaxDetail."Maximum Amount/Qty.";
                            AddedTaxAmount :=
                              (MaxAmount * TaxDetail."Tax Below Maximum") +
                              ((TaxBaseAmt - MaxAmount) * TaxDetail."Tax Above Maximum");
                            OnEndSalesTaxCalculationOnAfterCalculateMaxAmount(TempSalesTaxAmountLine, TaxDetail, MaxAmount, AddedTaxAmount, TaxBaseAmt);
                        end;
                        if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then
                            AddedTaxAmount := AddedTaxAmount / 100.0;
                    end else
                        AddedTaxAmount := 0;
                    TempSalesTaxAmountLine."Tax Amount" := TempSalesTaxAmountLine."Tax Amount" + AddedTaxAmount;
                    TotalTaxAmount := TotalTaxAmount + AddedTaxAmount;
                end;
                ApplyTaxDifference(TempSalesTaxAmountLine, TotalTaxAmount);
                TempSalesTaxAmountLine."Amount Including Tax" := TempSalesTaxAmountLine."Tax Amount" + TempSalesTaxAmountLine."Tax Base Amount";
                if TaxOnTaxCalculated and CalculationOrderViolation then
                    Error(
                      Text000,
                      TempSalesTaxAmountLine.FieldCaption("Calculation Order"), TaxArea.TableCaption(), TempSalesTaxAmountLine."Tax Area Code",
                      TaxDetail.FieldCaption("Calculate Tax on Tax"), CalculationOrderViolation);
                OnEndSalesTaxCalculationOnBeforeSalesTaxAmountLine2Copy(TempSalesTaxAmountLine, TaxBaseAmt, AddedTaxAmount, TotalTaxAmount);
                SalesTaxAmountLine2.Copy(TempSalesTaxAmountLine);
                if (TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Excise Tax") and not TaxDetail."Calculate Tax on Tax" then
                    SalesTaxAmountLine2."Tax %" := 0
                else
                    if TempSalesTaxAmountLine."Tax Base Amount" <> 0 then
                        SalesTaxAmountLine2."Tax %" := 100 * (TempSalesTaxAmountLine."Amount Including Tax" - TempSalesTaxAmountLine."Tax Base Amount") / TempSalesTaxAmountLine."Tax Base Amount"
                    else
                        if (TempSalesTaxAmountLine."Tax %" = 0) and TempSalesTaxAmountLine."Tax Liable" then
                            SalesTaxAmountLine2."Tax %" := TaxDetail."Tax Below Maximum"
                        else
                            SalesTaxAmountLine2."Tax %" := TempSalesTaxAmountLine."Tax %";
                OnEndSalesTaxCalculationOnBeforeSalesTaxAmountLine2Insert(SalesTaxAmountLine2, TempSalesTaxAmountLine);
                SalesTaxAmountLine2.Insert();
            until TempSalesTaxAmountLine.Next(-1) = 0;
            HandleRoundTaxUpOrDown(SalesTaxAmountLine2, RoundTax, TotalTaxAmount, LastTaxAreaCode, LastTaxGroupCode);
        end;
        TempSalesTaxAmountLine.DeleteAll();
        SalesTaxAmountLine2.Reset();
        if SalesTaxAmountLine2.FindSet() then
            repeat
                TempSalesTaxAmountLine.Copy(SalesTaxAmountLine2);
                TempSalesTaxAmountLine.Insert();
            until SalesTaxAmountLine2.Next() = 0;

        OnAfterEndSalesTaxCalulation(TempSalesTaxAmountLine, SalesHeaderRead, PurchHeaderRead, ServHeaderRead, Date);
    end;

    local procedure ApplyTaxDifference(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line"; var TotalTaxAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyTaxDifference(TempSalesTaxAmountLine, IsHandled);
        if IsHandled then
            exit;

        TempSalesTaxAmountLine."Tax Amount" := TempSalesTaxAmountLine."Tax Amount" + TempSalesTaxAmountLine."Tax Difference";
        TotalTaxAmount := TotalTaxAmount + TempSalesTaxAmountLine."Tax Difference";
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
                  SummarizedSalesTaxAmtLine, DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", IsHandled);
            PurchHeaderRead:
                OnBeforeGetSummarizedSalesTaxTable(
                  SummarizedSalesTaxAmtLine, DATABASE::"Purchase Line", PurchHeader."Document Type".AsInteger(), PurchHeader."No.", IsHandled);
            ServHeaderRead:
                OnBeforeGetSummarizedSalesTaxTable(
                  SummarizedSalesTaxAmtLine, DATABASE::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", IsHandled);
        end;
        if IsHandled then
            exit;

        IsHandled := false;
        OnBeforeGetPostedSummarizedSalesTaxTable(SummarizedSalesTaxAmtLine, TempTaxAmountDifference, IsHandled);
        if IsHandled then
            exit;

        Clear(TaxJurisdiction);
        TempSalesTaxAmountLine.Reset();

        SummarizedSalesTaxAmtLine.DeleteAll();
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                Clear(SummarizedSalesTaxAmtLine);
                case TaxCountry of
                    TaxCountry::US:
                        begin
                            SummarizedSalesTaxAmtLine."Tax Area Code for Key" := TempSalesTaxAmountLine."Tax Area Code for Key";
                            if TaxArea.Code <> SummarizedSalesTaxAmtLine."Tax Area Code for Key" then
                                TaxArea.Get(SummarizedSalesTaxAmtLine."Tax Area Code for Key");
                            SummarizedSalesTaxAmtLine."Print Description" := TaxArea.Description;
                        end;
                    TaxCountry::CA:
                        begin
                            SummarizedSalesTaxAmtLine."Tax Jurisdiction Code" := TempSalesTaxAmountLine."Tax Jurisdiction Code";
                            if TaxJurisdiction.Code <> SummarizedSalesTaxAmtLine."Tax Jurisdiction Code" then
                                TaxJurisdiction.Get(SummarizedSalesTaxAmtLine."Tax Jurisdiction Code");
                            SummarizedSalesTaxAmtLine."Print Order" := TaxJurisdiction."Print Order";
                            SummarizedSalesTaxAmtLine."Print Description" := TaxJurisdiction."Print Description";
                            if StrPos(SummarizedSalesTaxAmtLine."Print Description", '%1') <> 0 then
                                SummarizedSalesTaxAmtLine."Tax %" := TempSalesTaxAmountLine."Tax %";
                        end;
                end;
                if not SummarizedSalesTaxAmtLine.Find('=') then
                    SummarizedSalesTaxAmtLine.Insert();
                if (TempSalesTaxAmountLine."Tax Difference" <> 0) or
                   (TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Excise Tax")
                then
                    SummarizedSalesTaxAmtLine."Tax Amount" += TempSalesTaxAmountLine."Tax Amount"
                else
                    SummarizedSalesTaxAmtLine."Tax Amount" += TempSalesTaxAmountLine."Tax Base Amount FCY" * TempSalesTaxAmountLine."Tax %" / 100;
                SummarizedSalesTaxAmtLine.Modify();
            until TempSalesTaxAmountLine.Next() = 0;

        SummarizedSalesTaxAmtLine.SetRange("Tax Amount", 0);
        SummarizedSalesTaxAmtLine.DeleteAll();
        SummarizedSalesTaxAmtLine.SetRange("Tax Amount");

        if SummarizedSalesTaxAmtLine.FindSet() then
            repeat
                if (SummarizedSalesTaxAmtLine."Tax Jurisdiction Code" <> PrevTaxJurisdictionCode) and RoundByJurisdiction then begin
                    PrevTaxJurisdictionCode := SummarizedSalesTaxAmtLine."Tax Jurisdiction Code";
                    RemTaxAmt := 0;
                end;
                if TaxCountry = TaxCountry::CA then
                    SummarizedSalesTaxAmtLine."Tax Amount" := Round(SummarizedSalesTaxAmtLine."Tax Amount", Currency."Amount Rounding Precision")
                else begin
                    SummarizedSalesTaxAmtLine."Tax Amount" += RemTaxAmt;
                    RemTaxAmt := SummarizedSalesTaxAmtLine."Tax Amount" - Round(SummarizedSalesTaxAmtLine."Tax Amount", Currency."Amount Rounding Precision");
                    SummarizedSalesTaxAmtLine."Tax Amount" -= RemTaxAmt;
                end;
                SummarizedSalesTaxAmtLine.Modify();
            until SummarizedSalesTaxAmtLine.Next() = 0;

        SummarizedSalesTaxAmtLine.SetRange("Tax Amount", 0);
        SummarizedSalesTaxAmtLine.DeleteAll();
        SummarizedSalesTaxAmtLine.SetRange("Tax Amount");
    end;

    procedure GetSalesTaxAmountLineTable(var TempSalesTaxAmountLine2: Record "Sales Tax Amount Line" temporary)
    begin
        TempSalesTaxAmountLine.Reset();
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                TempSalesTaxAmountLine2.Copy(TempSalesTaxAmountLine);
                TempSalesTaxAmountLine2.Insert();
            until TempSalesTaxAmountLine.Next() = 0;

        OnAfterGetSalesTaxAmountLineTable(TempSalesTaxAmountLine2);
    end;

    procedure PutSalesTaxAmountLineTable(var SalesTaxLine2: Record "Sales Tax Amount Line" temporary; ProductArea: Integer; DocumentType: Integer; DocumentNo: Code[20])
    begin
        TempSalesTaxAmountLine.Reset();
        TempSalesTaxAmountLine.DeleteAll();
        if SalesTaxLine2.FindSet() then
            repeat
                TempSalesTaxAmountLine.Copy(SalesTaxLine2);
                TempSalesTaxAmountLine.Insert();
            until SalesTaxLine2.Next() = 0;

        CreateSingleTaxDifference(
            Enum::"Sales Tax Document Area".FromInteger(ProductArea), DocumentType, DocumentNo);
    end;

    procedure DistTaxOverSalesLines(var SalesLine: Record "Sales Line")
    var
        TempSalesTaxLine2: Record "Sales Tax Amount Line" temporary;
        SalesLine2: Record "Sales Line" temporary;
        TaxAmount: Decimal;
        Amount: Decimal;
        ReturnTaxAmount: Decimal;
        IsHandled: Boolean;
        SkipCheckTaxAmtLinePos: Boolean;
    begin
        IsHandled := false;
        OnBeforeDistTaxOverSalesLines(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if not IsTotalTaxAmountRoundingSpecified then
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

        TempSalesTaxAmountLine.Reset();
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                SkipCheckTaxAmtLinePos := false;
                SetTaxDetailFilter(TaxDetail, TempSalesTaxAmountLine."Tax Jurisdiction Code", TempSalesTaxAmountLine."Tax Group Code", SalesHeader."Posting Date");
                TaxDetail.SetRange("Tax Type", TempSalesTaxAmountLine."Tax Type");
                if TaxDetail.FindLast() then
                    if TaxDetail."Maximum Amount/Qty." <> 0 then
                        SkipCheckTaxAmtLinePos := true;

                if (TempSalesTaxAmountLine."Tax Jurisdiction Code" <> TempSalesTaxLine2."Tax Jurisdiction Code") and RoundByJurisdiction then begin
                    TempSalesTaxLine2."Tax Jurisdiction Code" := TempSalesTaxAmountLine."Tax Jurisdiction Code";
                    TotalTaxAmountRounding := 0;
                end;
                if TaxCountry = TaxCountry::US then
                    SalesLine.SetRange("Tax Area Code", TempSalesTaxAmountLine."Tax Area Code");
                SalesLine.SetRange("Tax Group Code", TempSalesTaxAmountLine."Tax Group Code");
                SalesLine.SetCurrentKey(Amount);
                OnDistTaxOverSalesLinesOnAfterSetSalesLineFilters(SalesLine, TempSalesTaxAmountLine);
                SalesLine.FindSet(true);
                repeat
                    if ((TaxCountry = TaxCountry::US) or
                        ((TaxCountry = TaxCountry::CA) and TaxAreaLine.Get(SalesLine."Tax Area Code", TempSalesTaxAmountLine."Tax Jurisdiction Code"))) and
                       (CheckTaxAmtLinePos(SalesLine."Line Amount" - SalesLine."Inv. Discount Amount",
                          TempSalesTaxAmountLine.Positive) or SkipCheckTaxAmtLinePos)
                    then begin
                        if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then begin
                            Amount := (SalesLine."Line Amount" - SalesLine."Inv. Discount Amount");
                            OnDistTaxOverSalesLinesOnTempSalesTaxLineLoopOnAfterSetTempSalesTaxLineAmount(TempSalesTaxAmountLine, SalesLine, SalesHeader, Amount);
                            if TempSalesTaxAmountLine."Tax Difference" <> 0 then
                                TaxAmount := Amount * TempSalesTaxAmountLine."Tax Amount" / TempSalesTaxAmountLine."Tax Base Amount"
                            else
                                TaxAmount := Amount * TempSalesTaxAmountLine."Tax %" / 100;
                        end else
                            if (SalesLine."Quantity (Base)" = 0) or (TempSalesTaxAmountLine.Quantity = 0) then
                                TaxAmount := 0
                            else
                                TaxAmount := TempSalesTaxAmountLine."Tax Amount" * ExchangeFactor * SalesLine."Quantity (Base)" / TempSalesTaxAmountLine.Quantity;
                        if TaxAmount = 0 then
                            ReturnTaxAmount := 0
                        else begin
                            ReturnTaxAmount := Round(TaxAmount + TotalTaxAmountRounding, Currency."Amount Rounding Precision");
                            TotalTaxAmountRounding := TaxAmount + TotalTaxAmountRounding - ReturnTaxAmount;
                        end;
                        SalesLine.Amount :=
                          SalesLine."Line Amount" - SalesLine."Inv. Discount Amount";
                        SalesLine."VAT Base Amount" := SalesLine.Amount;
                        OnDistTaxOverSalesLinesOnTempSalesTaxLineLoopOnAfterSetSalesLineVATBaseAmount(SalesLine, SalesHeader);
                        if SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then begin
                            SalesLine2."Amount Including VAT" := SalesLine2."Amount Including VAT" + ReturnTaxAmount;
                            SalesLine2.Modify();
                        end else begin
                            SalesLine2.Copy(SalesLine);
                            SalesLine2."Amount Including VAT" := SalesLine.Amount + ReturnTaxAmount;
                            SalesLine2.Insert();
                        end;
                        if SalesLine."Tax Liable" then
                            SalesLine."Amount Including VAT" := SalesLine2."Amount Including VAT"
                        else
                            SalesLine."Amount Including VAT" := SalesLine.Amount;
                        if SalesLine.Amount <> 0 then
                            SalesLine."VAT %" += TempSalesTaxAmountLine."Tax %"
                        else
                            SalesLine."VAT %" := 0;
                        SalesLine.Modify();
                    end;
                until SalesLine.Next() = 0;
            until TempSalesTaxAmountLine.Next() = 0;
        SalesLine.SetRange("Tax Area Code");
        SalesLine.SetRange("Tax Group Code");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        OnDistTaxOverSalesLinesOnBeforeFindSalesLineAmounts(SalesLine, TempSalesTaxAmountLine);
        if SalesLine.FindSet(true) then
            repeat
                SalesLine."Amount Including VAT" := Round(SalesLine."Amount Including VAT", Currency."Amount Rounding Precision");
                SalesLine.Amount :=
                  Round(SalesLine."Line Amount" - SalesLine."Inv. Discount Amount", Currency."Amount Rounding Precision");
                SalesLine."VAT Base Amount" := SalesLine.Amount;
                OnDistTaxOverSalesLinesOnSalesLineLoopOnAfterSetSalesLineVATBaseAmount(SalesLine, SalesHeader);
                if SalesLine.Quantity = 0 then
                    SalesLine.Validate("Outstanding Amount", SalesLine."Amount Including VAT")
                else
                    SalesLine.Validate(
                      "Outstanding Amount",
                      Round(
                        SalesLine."Amount Including VAT" * SalesLine."Outstanding Quantity" / SalesLine.Quantity,
                        Currency."Amount Rounding Precision"));
                if ((SalesLine."Tax Area Code" = '') and (TempSalesTaxAmountLine."Tax Area Code" <> '')) or (SalesLine."Tax Group Code" = '') then
                    SalesLine."Amount Including VAT" := SalesLine.Amount;
                SalesLine.Modify();
            until SalesLine.Next() = 0;
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
        PurchLine.SetPurchHeader(PurchHeader);

        TempSalesTaxAmountLine.Reset();
        // LOCKING
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                if (TempSalesTaxAmountLine."Tax Jurisdiction Code" <> TempSalesTaxLine2."Tax Jurisdiction Code") and RoundByJurisdiction then begin
                    TempSalesTaxLine2."Tax Jurisdiction Code" := TempSalesTaxAmountLine."Tax Jurisdiction Code";
                    TotalTaxAmountRounding := 0;
                    ExpenseTaxAmountRounding := 0;
                end;
                if TaxCountry = TaxCountry::US then
                    PurchLine.SetRange("Tax Area Code", TempSalesTaxAmountLine."Tax Area Code");
                PurchLine.SetRange("Tax Group Code", TempSalesTaxAmountLine."Tax Group Code");
                PurchLine.SetRange("Use Tax", TempSalesTaxAmountLine."Use Tax");
                PurchLine.SetCurrentKey(Amount);
                OnDistTaxOverPurchLinesOnBeforeFindPurchLineSetTempSalesTaxLineAmount(PurchLine, TempSalesTaxAmountLine);
                PurchLine.FindSet(true);
                repeat
                    if (TaxCountry = TaxCountry::US) or
                       ((TaxCountry = TaxCountry::CA) and TaxAreaLine.Get(PurchLine."Tax Area Code", TempSalesTaxAmountLine."Tax Jurisdiction Code"))
                    then begin
                        if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then begin
                            Amount := (PurchLine."Line Amount" - PurchLine."Inv. Discount Amount");
                            OnDistTaxOverPurchLinesOnTempSalesTaxLineLoopOnAfterSetTempSalesTaxLineAmount(TempSalesTaxAmountLine, PurchLine, PurchHeader, Amount);
                            if TempSalesTaxAmountLine."Tax Difference" <> 0 then
                                TaxAmount := Amount * TempSalesTaxAmountLine."Tax Amount" / TempSalesTaxAmountLine."Tax Base Amount"
                            else
                                TaxAmount := Amount * TempSalesTaxAmountLine."Tax %" / 100;
                        end else
                            if (PurchLine."Quantity (Base)" = 0) or (TempSalesTaxAmountLine.Quantity = 0) then
                                TaxAmount := 0
                            else
                                TaxAmount := TempSalesTaxAmountLine."Tax Amount" * ExchangeFactor * PurchLine."Quantity (Base)" / TempSalesTaxAmountLine.Quantity;
                        if (PurchLine."Use Tax" or TempSalesTaxAmountLine."Expense/Capitalize") and (TaxAmount <> 0) then begin
                            ExpenseTaxAmountRounding := ExpenseTaxAmountRounding + TaxAmount;
                            if PurchLine3.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then begin
                                PurchLine3."Tax To Be Expensed" :=
                                  Round(
                                    PurchLine3."Tax To Be Expensed" + ExpenseTaxAmountRounding,
                                    Currency."Amount Rounding Precision");
                                PurchLine3.Modify();
                            end else begin
                                PurchLine3.Copy(PurchLine);
                                PurchLine3."Tax To Be Expensed" :=
                                   Round(
                                    ExpenseTaxAmountRounding,
                                    Currency."Amount Rounding Precision");
                                PurchLine3.Insert();
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
                                PurchLine3.Insert();
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
                        OnDistTaxOverPurchLinesOnTempSalesTaxLineLoopOnAfterSetPurchLineVATBaseAmount(PurchLine, PurchHeader);
                        if PurchLine2.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then begin
                            PurchLine2."Amount Including VAT" := PurchLine2."Amount Including VAT" + ReturnTaxAmount;
                            PurchLine2.Modify();
                        end else begin
                            PurchLine2.Copy(PurchLine);
                            PurchLine2."Amount Including VAT" := PurchLine.Amount + ReturnTaxAmount;
                            PurchLine2.Insert();
                        end;
                        if PurchLine."Tax Liable" then
                            PurchLine."Amount Including VAT" := PurchLine2."Amount Including VAT"
                        else
                            PurchLine."Amount Including VAT" := PurchLine.Amount;
                        UpdatePurchaseLineVatPct(PurchLine);
                        PurchLine.Modify();
                    end;
                until PurchLine.Next() = 0;
            until TempSalesTaxAmountLine.Next() = 0;
        PurchLine.SetRange("Tax Area Code");
        PurchLine.SetRange("Tax Group Code");
        PurchLine.SetRange("Use Tax");
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        OnDistTaxOverPurchLinesOnBeforeFindPurchLineAmounts(PurchLine, TempSalesTaxAmountLine);
        if PurchLine.FindSet(true) then
            repeat
                PurchLine."Amount Including VAT" := Round(PurchLine."Amount Including VAT", Currency."Amount Rounding Precision");
                PurchLine.Amount :=
                  Round(PurchLine."Line Amount" - PurchLine."Inv. Discount Amount", Currency."Amount Rounding Precision");
                PurchLine."VAT Base Amount" := PurchLine.Amount;
                OnDistTaxOverPurchLinesOnPurchLineLoopOnAfterSetPurchLineVATBaseAmount(PurchLine, PurchHeader);
                if PurchLine.Quantity = 0 then
                    PurchLine.Validate("Outstanding Amount", PurchLine."Amount Including VAT")
                else
                    PurchLine.Validate(
                      "Outstanding Amount",
                      Round(
                        PurchLine."Amount Including VAT" * PurchLine."Outstanding Quantity" / PurchLine.Quantity,
                        Currency."Amount Rounding Precision"));
                if ((PurchLine."Tax Area Code" = '') and (TempSalesTaxAmountLine."Tax Area Code" <> '')) or (PurchLine."Tax Group Code" = '') then
                    PurchLine."Amount Including VAT" := PurchLine.Amount;
                if PurchLine.Amount <> 0 then
                    PurchLine.Modify();
            until PurchLine.Next() = 0;
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

        TempSalesTaxAmountLine.Reset();
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                if (TempSalesTaxAmountLine."Tax Jurisdiction Code" <> TempSalesTaxLine2."Tax Jurisdiction Code") and RoundByJurisdiction then begin
                    TempSalesTaxLine2."Tax Jurisdiction Code" := TempSalesTaxAmountLine."Tax Jurisdiction Code";
                    TotalTaxAmountRounding := 0;
                end;
                if TaxCountry = TaxCountry::US then
                    ServLine.SetRange("Tax Area Code", TempSalesTaxAmountLine."Tax Area Code");
                ServLine.SetRange("Tax Group Code", TempSalesTaxAmountLine."Tax Group Code");
                ServLine.SetCurrentKey(Amount);
                ServLine.FindSet(true);
                repeat
                    if (TaxCountry = TaxCountry::US) or
                       ((TaxCountry = TaxCountry::CA) and TaxAreaLine.Get(ServLine."Tax Area Code", TempSalesTaxAmountLine."Tax Jurisdiction Code"))
                    then begin
                        if TempSalesTaxAmountLine."Tax Type" = TempSalesTaxAmountLine."Tax Type"::"Sales and Use Tax" then begin
                            Amount := (ServLine."Line Amount" - ServLine."Inv. Discount Amount");
                            TaxAmount := Amount * TempSalesTaxAmountLine."Tax %" / 100;
                        end else
                            if (ServLine."Quantity (Base)" = 0) or (TempSalesTaxAmountLine.Quantity = 0) then
                                TaxAmount := 0
                            else
                                TaxAmount := TempSalesTaxAmountLine."Tax Amount" * ExchangeFactor * ServLine."Quantity (Base)" / TempSalesTaxAmountLine.Quantity;
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
                            ServLine2.Modify();
                        end else begin
                            ServLine2.Copy(ServLine);
                            ServLine2."Amount Including VAT" := ServLine.Amount + ReturnTaxAmount;
                            ServLine2.Insert();
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
                        ServLine.Modify();
                    end;
                until ServLine.Next() = 0;
            until TempSalesTaxAmountLine.Next() = 0;
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
                ServLine.Modify();
            until ServLine.Next() = 0;
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
            Currency.InitRoundingPrecision()
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
        TempPurchHeader.DeleteAll();

        CreateSingleTaxDifference(
            Enum::"Sales tax Document Area"::Purchase, PurchHeader."Document Type".AsInteger(), PurchHeader."No.");
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
        TempSalesHeader.DeleteAll();

        CreateSingleTaxDifference(
            Enum::"Sales Tax Document Area"::Sales, SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
    end;

    local procedure CopyTaxDifferencesToTemp(ProductArea: Enum "Sales Tax Document Area"; DocumentType: Integer; DocumentNo: Code[20])
    begin
        TaxAmountDifference.Reset();
        TaxAmountDifference.SetRange("Document Product Area", ProductArea);
        TaxAmountDifference.SetRange("Document Type", DocumentType);
        TaxAmountDifference.SetRange("Document No.", DocumentNo);
        if TaxAmountDifference.FindSet() then
            repeat
                TempTaxAmountDifference := TaxAmountDifference;
                TempTaxAmountDifference.Insert();
            until TaxAmountDifference.Next() = 0
        else
            CreateSingleTaxDifference(ProductArea, DocumentType, DocumentNo);
    end;

    local procedure CreateSingleTaxDifference(ProductArea: Enum "Sales Tax Document Area"; DocumentType: Integer; DocumentNo: Code[20])
    begin
        TempTaxAmountDifference.Reset();
        TempTaxAmountDifference.DeleteAll();
        TempTaxAmountDifference.Init();
        TempTaxAmountDifference."Document Product Area" := ProductArea;
        TempTaxAmountDifference."Document Type" := DocumentType;
        TempTaxAmountDifference."Document No." := DocumentNo;
        TempTaxAmountDifference.Insert();
    end;

    procedure SaveTaxDifferences()
    begin
        TempTaxAmountDifference.Reset();
        if not TempTaxAmountDifference.FindFirst() then
            Error(Text1020001);

        TaxAmountDifference.Reset();
        TaxAmountDifference.SetRange("Document Product Area", TempTaxAmountDifference."Document Product Area");
        TaxAmountDifference.SetRange("Document Type", TempTaxAmountDifference."Document Type");
        TaxAmountDifference.SetRange("Document No.", TempTaxAmountDifference."Document No.");
        TaxAmountDifference.DeleteAll();

        TempSalesTaxAmountLine.Reset();
        TempSalesTaxAmountLine.SetFilter("Tax Difference", '<>0');
        if TempSalesTaxAmountLine.FindSet() then
            repeat
                TaxAmountDifference."Document Product Area" := TempTaxAmountDifference."Document Product Area";
                TaxAmountDifference."Document Type" := TempTaxAmountDifference."Document Type";
                TaxAmountDifference."Document No." := TempTaxAmountDifference."Document No.";
                TaxAmountDifference."Tax Area Code" := TempSalesTaxAmountLine."Tax Area Code for Key";
                TaxAmountDifference."Tax Jurisdiction Code" := TempSalesTaxAmountLine."Tax Jurisdiction Code";
                if TempSalesTaxAmountLine.Positive then
                    TaxAmountDifference."Tax %" := TempSalesTaxAmountLine."Tax %"
                else
                    TaxAmountDifference."Tax %" := -TempSalesTaxAmountLine."Tax %";
                TaxAmountDifference."Tax Group Code" := TempSalesTaxAmountLine."Tax Group Code";
                TaxAmountDifference."Expense/Capitalize" := TempSalesTaxAmountLine."Expense/Capitalize";
                TaxAmountDifference."Tax Type" := TempSalesTaxAmountLine."Tax Type";
                TaxAmountDifference."Use Tax" := TempSalesTaxAmountLine."Use Tax";
                TaxAmountDifference."Tax Difference" := TempSalesTaxAmountLine."Tax Difference";
                TaxAmountDifference.Positive := TempSalesTaxAmountLine.Positive;
                TaxAmountDifference.Insert();
            until TempSalesTaxAmountLine.Next() = 0;
    end;

    procedure SetPurchHeader(NewPurchHeader: Record "Purchase Header")
    begin
        PurchHeader := NewPurchHeader;

        SetUpCurrency(PurchHeader."Currency Code");
        if PurchHeader."Currency Code" <> '' then
            PurchHeader.TestField("Currency Factor");
        if PurchHeader."Currency Factor" = 0 then
            ExchangeFactor := 1
        else
            ExchangeFactor := PurchHeader."Currency Factor";
        CopyTaxDifferencesToTemp(
            Enum::"Sales Tax Document Area"::Purchase, PurchHeader."Document Type".AsInteger(), PurchHeader."No.");

        PurchHeaderRead := true;
    end;

    procedure CalculateExpenseTax(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Date: Date; Amount: Decimal; Quantity: Decimal; ExchangeRate: Decimal) TaxAmount: Decimal
    var
        MaxAmount: Decimal;
        TaxBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateExpenseTax(
            TaxAreaCode, TaxGroupCode, TaxLiable, Date, Amount, Quantity, ExchangeRate, TaxAmount,
            TempTaxDetailMaximums, TaxDetail, TaxAreaLine, IsHandled);
        if IsHandled then
            exit;

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
                if TaxDetail.FindLast() and TaxDetail."Expense/Capitalize" then begin
                    TaxOnTaxCalculated := TaxOnTaxCalculated or TaxDetail."Calculate Tax on Tax";
                    if TaxDetail."Calculate Tax on Tax" then
                        TaxBaseAmount := Amount + TaxAmount
                    else
                        TaxBaseAmount := Amount;
                    TempTaxDetailMaximums := TaxDetail;
                    if not TempTaxDetailMaximums.Find() then
                        TempTaxDetailMaximums.Insert();
                    MaxAmountPerQty := TempTaxDetailMaximums."Maximum Amount/Qty.";
                    if (Abs(TaxBaseAmount) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then begin
                        TaxAmount := TaxAmount + TaxBaseAmount * TaxDetail."Tax Below Maximum" / 100;
                        TempTaxDetailMaximums."Maximum Amount/Qty." := TempTaxDetailMaximums."Maximum Amount/Qty." - TaxBaseAmount;
                        TempTaxDetailMaximums.Modify();
                    end else begin
                        MaxAmount := TaxBaseAmount / Abs(TaxBaseAmount) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + ((MaxAmount * TaxDetail."Tax Below Maximum") +
                                       ((TaxBaseAmount - MaxAmount) * TaxDetail."Tax Above Maximum")) / 100;
                        TempTaxDetailMaximums."Maximum Amount/Qty." := 0;
                        TempTaxDetailMaximums.Modify();
                    end;
                end;
                TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Excise Tax");
                if TaxDetail.FindLast() and TaxDetail."Expense/Capitalize" then begin
                    TempTaxDetailMaximums := TaxDetail;
                    if not TempTaxDetailMaximums.Find() then
                        TempTaxDetailMaximums.Insert();
                    MaxAmountPerQty := TempTaxDetailMaximums."Maximum Amount/Qty.";

                    if (Abs(Quantity) <= TaxDetail."Maximum Amount/Qty.") or
                       (TaxDetail."Maximum Amount/Qty." = 0)
                    then begin
                        TaxAmount := TaxAmount + Quantity * TaxDetail."Tax Below Maximum";
                        TempTaxDetailMaximums."Maximum Amount/Qty." := TempTaxDetailMaximums."Maximum Amount/Qty." - Quantity;
                        TempTaxDetailMaximums.Modify();
                    end else begin
                        MaxAmount := Quantity / Abs(Quantity) * TaxDetail."Maximum Amount/Qty.";
                        TaxAmount :=
                          TaxAmount + (MaxAmount * TaxDetail."Tax Below Maximum") +
                          ((Quantity - MaxAmount) * TaxDetail."Tax Above Maximum");
                        TempTaxDetailMaximums."Maximum Amount/Qty." := 0;
                        TempTaxDetailMaximums.Modify();
                    end;
                end;
            until TaxAreaLine.Next(-1) = 0;
        end;

        TaxAmount := TaxAmount * ExchangeFactor;

        if TaxOnTaxCalculated and CalculationOrderViolation then
            Error(
              Text000,
              TaxAreaLine.FieldCaption("Calculation Order"), TaxArea.TableCaption(), TaxAreaLine."Tax Area",
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
        SalesTaxAmountLine.Reset();
        SalesTaxAmountLine.SetRange("Tax Area Code for Key", TaxAreaCode);
        SalesTaxAmountLine.SetRange("Tax Group Code", TaxGroupCode);
        SalesTaxAmountLine.SetRange("Is Report-to Jurisdiction", true);
        if SalesTaxAmountLine.FindFirst() then begin
            SalesTaxAmountLine.Delete();
            SalesTaxAmountLine."Tax Amount" := SalesTaxAmountLine."Tax Amount" + RoundingError;
            SalesTaxAmountLine."Amount Including Tax" := SalesTaxAmountLine."Tax Amount" + SalesTaxAmountLine."Tax Base Amount";
            if SalesTaxAmountLine."Tax Type" = SalesTaxAmountLine."Tax Type"::"Excise Tax" then
                SalesTaxAmountLine."Tax %" := 0
            else
                if SalesTaxAmountLine."Tax Base Amount" <> 0 then
                    SalesTaxAmountLine."Tax %" := 100 * (SalesTaxAmountLine."Amount Including Tax" - SalesTaxAmountLine."Tax Base Amount") / SalesTaxAmountLine."Tax Base Amount";
            SalesTaxAmountLine.Insert();
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
        if TaxCountry = TaxCountry::US then
            PurchaseLine.SetRange("Tax Area Code", TaxAreaCode);
        if PurchaseLine.FindSet(true) then
            repeat
                TempSalesTaxAmountLine.SetRange("Tax Area Code", TaxAreaCode);
                TempSalesTaxAmountLine.SetRange("Tax Group Code", PurchaseLine."Tax Group Code");
                TempSalesTaxAmountLine.SetRange("Use Tax", PurchaseLine."Use Tax");
                if TempSalesTaxAmountLine.IsEmpty() then begin
                    PurchaseLine.Amount := PurchaseLine."Line Amount" - PurchaseLine."Inv. Discount Amount";
                    PurchaseLine."Amount Including VAT" := PurchaseLine.Amount;
                    PurchaseLine."VAT Base Amount" := PurchaseLine.Amount;
                    PurchaseLine."VAT %" := 0;
                    PurchaseLine."Tax To Be Expensed" := 0;
                    PurchaseLine.Modify();
                end;
            until PurchaseLine.Next() = 0;
    end;

    local procedure ResetTaxAmountsInSalesLines(var SalesLine: Record "Sales Line"; TaxAreaCode: Code[20])
    begin
        if TaxCountry = TaxCountry::US then
            SalesLine.SetRange("Tax Area Code", TaxAreaCode);
        if SalesLine.FindSet(true) then
            repeat
                TempSalesTaxAmountLine.SetRange("Tax Area Code", TaxAreaCode);
                TempSalesTaxAmountLine.SetRange("Tax Group Code", SalesLine."Tax Group Code");
                if TempSalesTaxAmountLine.IsEmpty() then begin
                    SalesLine.Amount := SalesLine."Line Amount" - SalesLine."Inv. Discount Amount";
                    SalesLine."Amount Including VAT" := SalesLine.Amount;
                    SalesLine."VAT Base Amount" := SalesLine.Amount;
                    SalesLine."VAT %" := 0;
                    SalesLine.Modify();
                end;
            until SalesLine.Next() = 0;
    end;

    internal procedure SetTotalTaxAmountRounding(NewTotalTaxAmountRounding: Decimal)
    begin
        TotalTaxAmountRounding := NewTotalTaxAmountRounding;
        IsTotalTaxAmountRoundingSpecified := true;
    end;

    internal procedure GetTotalTaxAmountRounding(): Decimal
    begin
        exit(TotalTaxAmountRounding);
    end;

    local procedure SetTaxDetailFilter(var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; Date: Date)
    begin
        TaxDetail.Reset();
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdictionCode);
        if TaxGroupCode = '' then
            TaxDetail.SetFilter("Tax Group Code", '%1', TaxGroupCode)
        else
            TaxDetail.SetFilter("Tax Group Code", '%1|%2', '', TaxGroupCode);
        if Date = 0D then
            TaxDetail.SetFilter("Effective Date", '<=%1', WorkDate())
        else
            TaxDetail.SetFilter("Effective Date", '<=%1', Date);
    end;

    local procedure UpdatePurchaseLineVatPct(var PurchLine: Record "Purchase Line")
    begin
        if PurchLine.Amount <> 0 then
            PurchLine."VAT %" := Round(100 * (PurchLine."Amount Including VAT" - PurchLine.Amount) / PurchLine.Amount, 0.00001)
        else
            PurchLine."VAT %" := 0;

        OnAfterUpdatePurchaseLineVatPct(PurchLine, PurchHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddSalesLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddPurchLine(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTaxProcedure(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Date: Date; Amount: Decimal; Quantity: Decimal; ExchangeRate: Decimal; var TaxAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSalesTaxLines(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; TaxLiable: Boolean; Amount: Decimal; Quantity: Decimal; Date: Date; DesiredTaxAmount: Decimal; var TMPTaxDetail: Record "Tax Detail"; var IsHandled: Boolean; var Initialised: Boolean; var FirstLine: Boolean; var TotalForAllocation: Decimal)
    begin
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyTaxDifference(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchaseLineVatPct(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverPurchLinesOnPurchLineLoopOnAfterSetPurchLineVATBaseAmount(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverPurchLinesOnTempSalesTaxLineLoopOnAfterSetPurchLineVATBaseAmount(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverPurchLinesOnTempSalesTaxLineLoopOnAfterSetTempSalesTaxLineAmount(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; var Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddPurchInvoiceLinesOnAfterCalcPurchLineSalesTaxAmountLine(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; PurchInvLine: Record "Purch. Inv. Line"; PurchInvHeader: Record "Purch. Inv. Header"; ExchangeFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSalesLine(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ExchangeFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverSalesLinesOnSalesLineLoopOnAfterSetSalesLineVATBaseAmount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverSalesLinesOnTempSalesTaxLineLoopOnAfterSetSalesLineVATBaseAmount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverSalesLinesOnTempSalesTaxLineLoopOnAfterSetTempSalesTaxLineAmount(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverPurchLinesOnBeforeFindPurchLineSetTempSalesTaxLineAmount(var PurchLine: Record "Purchase Line"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverPurchLinesOnBeforeFindPurchLineAmounts(var PurchLine: Record "Purchase Line"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverSalesLinesOnBeforeFindSalesLineAmounts(var SalesLine: Record "Sales Line"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEndSalesTaxCalculationOnBeforeSalesTaxAmountLine2Insert(var SalesTaxAmountLine2: Record "Sales Tax Amount Line" temporary; var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEndSalesTaxCalculationOnBeforeTempSalesTaxLineModify(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEndSalesTaxCalculationOnAfterCalculateMaxAmount(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; TaxDetail: Record "Tax Detail"; var MaxAmount: Decimal; var AddedTaxAmount: Decimal; TaxBaseAmt: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddPurchLine(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; ExchangeFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartSalestaxCalculation()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSalesLineOnAfterTempSalesTaxAmountLineSetFilters(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddPurchLineOnAfterTempSalesTaxAmountLineSetFilters(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesTaxAmountLineTable(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateExpenseTax(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean; Date: Date; Amount: Decimal; Quantity: Decimal; ExchangeRate: Decimal; var TaxAmount: Decimal; var TempTaxDetailMaximums: Record "Tax Detail" temporary; var TaxDetail: Record "Tax Detail"; var TaxAreaLine: Record "Tax Area Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSalesLineOnBeforeTempSalesTaxAmountLineInsert(var TempSalesTaxLine: Record "Sales Tax Amount Line" temporary; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEndSalesTaxCalulation(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; SalesHeaderRead: Boolean; PurchHeaderRead: Boolean; ServHeaderRead: Boolean; ProcessDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSalesLineOnAfterSetSalesTaxAmountLineFilter(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; SalesLine: Record "Sales Line"; TaxAreaLine: Record "Tax Area Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSalesLineOnBeforeModifySalesTaxAmountLine(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; SalesLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEndSalesTaxCalculationOnBeforeSalesTaxAmountLine2Copy(var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; var TaxBaseAmt: Decimal; var AddedTaxAmount: Decimal; var TotalTaxAmount: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDistTaxOverSalesLinesOnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary);
    begin
    end;
}

