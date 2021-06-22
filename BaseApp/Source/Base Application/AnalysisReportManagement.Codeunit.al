codeunit 7110 "Analysis Report Management"
{
    TableNo = "Analysis Line";

    trigger OnRun()
    begin
        SetFilter("Row Ref. No.", TryExpression);
    end;

    var
        Text001: Label 'DEFAULT';
        Text002: Label 'Default Lines';
        Text003: Label 'Default Columns';
        OriginalAnalysisLineFilters: Record "Analysis Line";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisFieldValue: Record "Analysis Field Value" temporary;
        GLSetup: Record "General Ledger Setup";
        InventorySetup: Record "Inventory Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        StartDate: Date;
        EndDate: Date;
        FiscalStartDate: Date;
        DivisionError: Boolean;
        PeriodError: Boolean;
        FormulaError: Boolean;
        CyclicError: Boolean;
        CallLevel: Integer;
        OldAnalysisLineFilters: Text;
        OldAnalysisColumnFilters: Text;
        OldAnalysisLineTemplate: Code[10];
        Text005Tok: Label 'M', Comment = 'Month';
        Text006Tok: Label 'Q', Comment = 'Quarter';
        Text007Tok: Label 'Y', Comment = 'Year';
        Text021: Label 'Conversion of dimension totaling filter %1 results in a filter that becomes too long.';
        Text022: Label 'You must specify an %1 on %2 %3 %4 that includes the %5 dimension.';
        Text023: Label 'Column formula: %1';
        Text024: Label 'Row formula: %1';
        SalesSetupRead: Boolean;
        InventorySetupRead: Boolean;
        TryExpression: Text[250];
        ColumnFormulaMsg: Label 'Column formula: %1. \Error: %2.', Comment = '%1 - text of Column formula; %2 - text of Error';
        ShowError: Option "None","Division by Zero","Period Error","Invalid Formula","Cyclic Formula",All;
        SeparatorTok: Label ';', Locked = true;

    procedure LookupReportName(CurrentAnalysisArea: Option Sales,Purchase,Inventory; var CurrentReportName: Code[10]): Boolean
    var
        AnalysisReportName: Record "Analysis Report Name";
    begin
        AnalysisReportName."Analysis Area" := CurrentAnalysisArea;
        AnalysisReportName.Name := CurrentReportName;
        AnalysisReportName.FilterGroup := 2;
        AnalysisReportName.SetRange("Analysis Area", CurrentAnalysisArea);
        AnalysisReportName.FilterGroup := 0;
        if PAGE.RunModal(0, AnalysisReportName) = ACTION::LookupOK then begin
            CurrentReportName := AnalysisReportName.Name;
            exit(true);
        end;
    end;

    procedure CheckReportName(CurrentReportName: Code[10]; var AnalysisLine: Record "Analysis Line")
    var
        AnalysisReportName: Record "Analysis Report Name";
    begin
        if CurrentReportName <> '' then
            AnalysisReportName.Get(AnalysisLine.GetRangeMax("Analysis Area"), CurrentReportName);
    end;

    procedure OpenAnalysisLines(var CurrentLineTemplate: Code[10]; var AnalysisLine: Record "Analysis Line")
    begin
        CheckAnalysisLineTemplName(AnalysisLine.GetRangeMax("Analysis Area"), CurrentLineTemplate);
        AnalysisLine.FilterGroup := 2;
        AnalysisLine.SetRange("Analysis Line Template Name", CurrentLineTemplate);
        AnalysisLine.FilterGroup := 0;
    end;

    local procedure CheckAnalysisLineTemplName(CurrentAnalysisArea: Option Sale,Purchase,Inventory; var CurrentAnalysisLineTempl: Code[10])
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        if not AnalysisLineTemplate.Get(CurrentAnalysisArea, CurrentAnalysisLineTempl) then begin
            AnalysisLineTemplate.SetRange("Analysis Area", CurrentAnalysisArea);
            if not AnalysisLineTemplate.FindFirst then begin
                AnalysisLineTemplate.Init();
                AnalysisLineTemplate."Analysis Area" := CurrentAnalysisArea;
                AnalysisLineTemplate.Name := Text001;
                AnalysisLineTemplate.Description := Text002;
                AnalysisLineTemplate.Insert(true);
                Commit();
            end;
            CurrentAnalysisLineTempl := AnalysisLineTemplate.Name;
        end;
    end;

    procedure CheckAnalysisLineTemplName(CurrentAnalysisLineTempl: Code[10]; var AnalysisLine: Record "Analysis Line")
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        AnalysisLineTemplate.Get(AnalysisLine.GetRangeMax("Analysis Area"), CurrentAnalysisLineTempl);
    end;

    procedure SetAnalysisLineTemplName(CurrentAnalysisLineTempl: Code[10]; var AnalysisLine: Record "Analysis Line")
    begin
        AnalysisLine.FilterGroup := 2;
        AnalysisLine.SetRange("Analysis Area", AnalysisLine.GetRangeMax("Analysis Area"));
        AnalysisLine.SetRange("Analysis Line Template Name", CurrentAnalysisLineTempl);
        AnalysisLine.FilterGroup := 0;
        if AnalysisLine.Find('-') then;
    end;

    procedure LookupAnalysisLineTemplName(var CurrentAnalysisLineTempl: Code[10]; var AnalysisLine: Record "Analysis Line"): Boolean
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        Commit();
        AnalysisLineTemplate."Analysis Area" := AnalysisLine.GetRangeMax("Analysis Area");
        AnalysisLineTemplate.Name := AnalysisLine.GetRangeMax("Analysis Line Template Name");
        AnalysisLineTemplate.FilterGroup := 2;
        AnalysisLineTemplate.SetRange("Analysis Area", AnalysisLine.GetRangeMax("Analysis Area"));
        AnalysisLineTemplate.FilterGroup := 0;
        if PAGE.RunModal(0, AnalysisLineTemplate) = ACTION::LookupOK then begin
            CheckAnalysisLineTemplName(AnalysisLineTemplate.Name, AnalysisLine);
            CurrentAnalysisLineTempl := AnalysisLineTemplate.Name;
            SetAnalysisLineTemplName(CurrentAnalysisLineTempl, AnalysisLine);
            exit(true);
        end;
        OpenAnalysisLines(CurrentAnalysisLineTempl, AnalysisLine);
    end;

    procedure OpenAnalysisLinesForm(var AnalysisLine2: Record "Analysis Line"; CurrentAnalysisLineTempl: Code[10])
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisLines: Page "Inventory Analysis Lines";
        AnalysisLinesForSale: Page "Sales Analysis Lines";
        AnalysisLinesForPurchase: Page "Purchase Analysis Lines";
    begin
        Commit();
        AnalysisLine.Copy(AnalysisLine2);
        case AnalysisLine.GetRangeMax("Analysis Area") of
            AnalysisLine."Analysis Area"::Sales:
                begin
                    AnalysisLinesForSale.SetCurrentAnalysisLineTempl(CurrentAnalysisLineTempl);
                    AnalysisLinesForSale.SetTableView(AnalysisLine);
                    AnalysisLinesForSale.RunModal;
                end;
            AnalysisLine."Analysis Area"::Purchase:
                begin
                    AnalysisLinesForPurchase.SetCurrentAnalysisLineTempl(CurrentAnalysisLineTempl);
                    AnalysisLinesForPurchase.SetTableView(AnalysisLine);
                    AnalysisLinesForPurchase.RunModal;
                end;
            else
                AnalysisLines.SetCurrentAnalysisLineTempl(CurrentAnalysisLineTempl);
                AnalysisLines.SetTableView(AnalysisLine);
                AnalysisLines.RunModal;
        end;
    end;

    procedure OpenAnalysisColumnsForm(var AnalysisLine: Record "Analysis Line"; CurrentColumnTempl: Code[10])
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisColumns: Page "Analysis Columns";
    begin
        Commit();
        AnalysisColumn.FilterGroup := 2;
        AnalysisColumn.SetRange(
          "Analysis Area", AnalysisLine.GetRangeMax("Analysis Area"));
        AnalysisColumn.FilterGroup := 0;
        AnalysisColumns.SetTableView(AnalysisColumn);
        AnalysisColumns.SetCurrentColumnName(CurrentColumnTempl);
        AnalysisColumns.RunModal;
    end;

    procedure OpenColumns(var CurrentColumnTempl: Code[10]; var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column")
    begin
        CheckColumnTemplate(AnalysisLine.GetRangeMax("Analysis Area"), CurrentColumnTempl);
        AnalysisColumn.FilterGroup := 2;
        AnalysisColumn.SetRange("Analysis Area", AnalysisLine.GetRangeMax("Analysis Area"));
        AnalysisColumn.SetRange("Analysis Column Template", CurrentColumnTempl);
        AnalysisColumn.FilterGroup := 0;
    end;

    procedure OpenColumns(var CurrentColumnTempl: Code[10]; var AnalysisColumn: Record "Analysis Column")
    begin
        CheckColumnTemplate(AnalysisColumn.GetRangeMax("Analysis Area"), CurrentColumnTempl);
        AnalysisColumn.FilterGroup := 2;
        AnalysisColumn.SetRange("Analysis Column Template", CurrentColumnTempl);
        AnalysisColumn.FilterGroup := 0;
    end;

    local procedure CheckColumnTemplate(CurrentAnalysisArea: Option Sale,Purchase,Inventory; var CurrentColumnName: Code[10])
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        if not AnalysisColumnTemplate.Get(CurrentAnalysisArea, CurrentColumnName) then begin
            AnalysisColumnTemplate.SetRange("Analysis Area", CurrentAnalysisArea);
            if not AnalysisColumnTemplate.FindFirst then begin
                AnalysisColumnTemplate.Init();
                AnalysisColumnTemplate."Analysis Area" := CurrentAnalysisArea;
                AnalysisColumnTemplate.Name := Text001;
                AnalysisColumnTemplate.Description := Text003;
                AnalysisColumnTemplate.Insert(true);
                Commit();
            end;
            CurrentColumnName := AnalysisColumnTemplate.Name;
        end;
    end;

    procedure GetColumnTemplate(CurrentAnalysisArea: Option Sale,Purchase,Inventory; CurrentColumnTemplate: Code[10])
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        AnalysisColumnTemplate.Get(CurrentAnalysisArea, CurrentColumnTemplate);
    end;

    procedure SetColumnName(CurrentAnalysisArea: Option Sale,Purchase,Inventory; CurrentColumnName: Code[10]; var AnalysisColumn: Record "Analysis Column")
    begin
        AnalysisColumn.FilterGroup := 2;
        AnalysisColumn.SetRange("Analysis Area", CurrentAnalysisArea);
        AnalysisColumn.SetRange("Analysis Column Template", CurrentColumnName);
        AnalysisColumn.FilterGroup := 0;
        if AnalysisColumn.Find('-') then;
    end;

    procedure CopyColumnsToTemp(var AnalysisLine: Record "Analysis Line"; ColumnName: Code[10]; var TempAnalysisColumn: Record "Analysis Column")
    var
        AnalysisColumn: Record "Analysis Column";
    begin
        TempAnalysisColumn.Reset();
        TempAnalysisColumn.DeleteAll();
        AnalysisColumn.SetRange(
          "Analysis Area", AnalysisLine.GetRangeMax("Analysis Area"));
        AnalysisColumn.SetRange("Analysis Column Template", ColumnName);
        if AnalysisColumn.FindSet then begin
            repeat
                TempAnalysisColumn := AnalysisColumn;
                TempAnalysisColumn.Insert();
            until AnalysisColumn.Next = 0;
            TempAnalysisColumn.FindFirst;
        end;
    end;

    procedure LookupColumnName(CurrentAnalysisArea: Option; var CurrentColumnName: Code[10]): Boolean
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        AnalysisColumnTemplate.FilterGroup := 2;
        AnalysisColumnTemplate.SetRange("Analysis Area", CurrentAnalysisArea);
        AnalysisColumnTemplate.FilterGroup := 0;
        AnalysisColumnTemplate."Analysis Area" := CurrentAnalysisArea;
        AnalysisColumnTemplate.Name := CurrentColumnName;
        if PAGE.RunModal(0, AnalysisColumnTemplate) = ACTION::LookupOK then begin
            CurrentColumnName := AnalysisColumnTemplate.Name;
            exit(true);
        end;
    end;

    procedure SetSourceType(var AnalysisLine: Record "Analysis Line"; CurrentSourceTypeFilter: Option " ",Customer,Vendor,Item)
    begin
        if CurrentSourceTypeFilter = CurrentSourceTypeFilter::" " then
            exit;

        AnalysisLine.SetRange("Source Type Filter", CurrentSourceTypeFilter);
    end;

    procedure SetSourceNo(var AnalysisLine: Record "Analysis Line"; CurrentSourceTypeNoFilter: Text)
    begin
        AnalysisLine.SetFilter("Source No. Filter", CurrentSourceTypeNoFilter);
    end;

    procedure LookupSourceNo(var AnalysisLine: Record "Analysis Line"; CurrentSourceTypeFilter: Option " ",Customer,Vendor,Item; var CurrentSourceTypeNoFilter: Text)
    var
        CustList: Page "Customer List";
        VendList: Page "Vendor List";
        ItemList: Page "Item List";
    begin
        case CurrentSourceTypeFilter of
            CurrentSourceTypeFilter::" ":
                exit;
            CurrentSourceTypeFilter::Customer:
                begin
                    CustList.LookupMode := true;
                    if CustList.RunModal = ACTION::LookupOK then
                        CurrentSourceTypeNoFilter := CustList.GetSelectionFilter;
                end;
            CurrentSourceTypeFilter::Vendor:
                begin
                    VendList.LookupMode := true;
                    if VendList.RunModal = ACTION::LookupOK then
                        CurrentSourceTypeNoFilter := VendList.GetSelectionFilter;
                end;
            CurrentSourceTypeFilter::Item:
                begin
                    ItemList.LookupMode := true;
                    if ItemList.RunModal = ACTION::LookupOK then
                        CurrentSourceTypeNoFilter := ItemList.GetSelectionFilter;
                end;
        end;
        SetSourceNo(AnalysisLine, CurrentSourceTypeNoFilter);
    end;

    local procedure AccPeriodStartEnd(Formula: Code[20]; Date: Date; var StartDate: Date; var EndDate: Date)
    var
        AnalysisColumn: Record "Analysis Column";
        Steps: Integer;
        Type: Option " ",Period,"Fiscal Year","Fiscal Halfyear","Fiscal Quarter";
        RangeFromType: Option Int,CP,LP;
        RangeToType: Option Int,CP,LP;
        RangeFromInt: Integer;
        RangeToInt: Integer;
    begin
        if Formula = '' then
            exit;

        AnalysisColumn.ParsePeriodFormula(
          Formula, Steps, Type, RangeFromType, RangeToType, RangeFromInt, RangeToInt);

        AccountingPeriodMgt.AccPeriodStartEnd(
          Date, StartDate, EndDate, PeriodError, Steps, Type, RangeFromType, RangeToType, RangeFromInt, RangeToInt);
    end;

    procedure CalcCell(var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; DrillDown: Boolean): Decimal
    var
        ErrorText: Text;
        Result: Decimal;
    begin
        if DrillDown and
           ((AnalysisColumn."Column Type" = AnalysisColumn."Column Type"::Formula) or
            (AnalysisLine.Type = AnalysisLine.Type::Formula))
        then begin
            if AnalysisColumn."Column Type" = AnalysisColumn."Column Type"::Formula then begin
                ErrorText := CalcFieldError(AnalysisLine."Line No.", AnalysisColumn."Line No.");
                if ErrorText = '' then
                    Message(Text023, AnalysisColumn.Formula)
                else
                    Message(ColumnFormulaMsg, AnalysisColumn.Formula, ErrorText);
            end else
                Message(Text024, AnalysisLine.Range);
            exit(0);
        end;

        OriginalAnalysisLineFilters.CopyFilters(AnalysisLine);

        StartDate := AnalysisLine.GetRangeMin("Date Filter");
        if EndDate <> AnalysisLine.GetRangeMax("Date Filter") then begin
            EndDate := AnalysisLine.GetRangeMax("Date Filter");
            FiscalStartDate := AccountingPeriodMgt.FindFiscalYear(EndDate);
        end;
        DivisionError := false;
        PeriodError := false;
        FormulaError := false;
        CyclicError := false;
        CallLevel := 0;

        if (OldAnalysisLineFilters <> AnalysisLine.GetFilters) or
           (OldAnalysisColumnFilters <> AnalysisColumn.GetFilters) or
           (OldAnalysisLineTemplate <> AnalysisLine."Analysis Line Template Name") or
           (OldAnalysisLineTemplate <> AnalysisColumn."Analysis Column Template")
        then begin
            AnalysisFieldValue.Reset();
            AnalysisFieldValue.DeleteAll();
            OldAnalysisLineFilters := AnalysisLine.GetFilters;
            OldAnalysisColumnFilters := AnalysisColumn.GetFilters;
            OldAnalysisLineTemplate := AnalysisLine."Analysis Line Template Name";
            OldAnalysisLineTemplate := AnalysisColumn."Analysis Column Template";
        end;

        Result := CalcCellValue(AnalysisLine, AnalysisColumn, DrillDown);
        with AnalysisColumn do begin
            case Show of
                Show::"When Positive":
                    if Result < 0 then
                        Result := 0;
                Show::"When Negative":
                    if Result > 0 then
                        Result := 0;
            end;
            if "Show Opposite Sign" then
                Result := -Result;
        end;
        if AnalysisLine."Show Opposite Sign" then
            Result := -Result;
        exit(Result);
    end;

    local procedure CalcCellValue(AnalysisLine: Record "Analysis Line"; AnalysisColumn: Record "Analysis Column"; DrillDown: Boolean): Decimal
    var
        ItemStatisticsBuf: Record "Item Statistics Buffer";
        Result: Decimal;
    begin
        Result := 0;
        if AnalysisLine.Range <> '' then begin
            case true of
                AnalysisFieldValue.Get(AnalysisLine."Line No.", AnalysisColumn."Line No.") and not DrillDown:
                    begin
                        Result := AnalysisFieldValue.Value;
                        DivisionError := DivisionError or AnalysisFieldValue."Has Error";
                        PeriodError := PeriodError or AnalysisFieldValue."Period Error";
                        FormulaError := FormulaError or AnalysisFieldValue."Formula Error";
                        CyclicError := CyclicError or AnalysisFieldValue."Cyclic Error";
                        exit(Result);
                    end;
                AnalysisColumn."Column Type" = AnalysisColumn."Column Type"::Formula:
                    Result :=
                      EvaluateExpression(
                        false, AnalysisColumn.Formula, AnalysisLine, AnalysisColumn);
                AnalysisLine.Type = AnalysisLine.Type::Formula:
                    Result :=
                      EvaluateExpression(
                        true, AnalysisLine.Range, AnalysisLine, AnalysisColumn);
                (StartDate = 0D) or (EndDate in [0D, DMY2Date(31, 12, 9999)]):
                    begin
                        Result := 0;
                        PeriodError := true;
                    end;
                else
                    if (AnalysisLineTemplate."Analysis Area" <> AnalysisLine."Analysis Area") or
                       (AnalysisLineTemplate.Name <> AnalysisLine."Analysis Line Template Name")
                    then
                        AnalysisLineTemplate.Get(AnalysisLine."Analysis Area", AnalysisLine."Analysis Line Template Name");
                    AnalysisLine.CopyFilters(OriginalAnalysisLineFilters);
                    SetItemRowFilters(ItemStatisticsBuf, AnalysisLine);
                    SetItemColumnFilters(ItemStatisticsBuf, AnalysisColumn);

                    Result := Result + CalcItemStatistics(ItemStatisticsBuf, AnalysisLine, AnalysisColumn, DrillDown);
            end;

            if not DrillDown then begin
                AnalysisFieldValue."Row Ref. No." := AnalysisLine."Line No.";
                AnalysisFieldValue."Column No." := AnalysisColumn."Line No.";
                AnalysisFieldValue.Value := Result;
                AnalysisFieldValue."Has Error" := DivisionError;
                AnalysisFieldValue."Period Error" := PeriodError;
                AnalysisFieldValue."Formula Error" := FormulaError;
                AnalysisFieldValue."Cyclic Error" := CyclicError;
                if AnalysisFieldValue.Insert() then;
            end;
        end;
        exit(Result);
    end;

    local procedure CalcItemStatistics(var ItemStatisticsBuf: Record "Item Statistics Buffer"; var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; DrillDown: Boolean): Decimal
    var
        ColValue: Decimal;
    begin
        ColValue := 0;

        if (AnalysisLineTemplate."Analysis Area" <> AnalysisLine."Analysis Area") or
           (AnalysisLineTemplate.Name <> AnalysisLine."Analysis Line Template Name")
        then
            AnalysisLineTemplate.Get(AnalysisLine."Analysis Area", AnalysisLine."Analysis Line Template Name");

        if AnalysisColumn."Column Type" <> AnalysisColumn."Column Type"::Formula then begin
            with ItemStatisticsBuf do begin
                if AnalysisLine.GetFilter("Source No. Filter") <> '' then
                    case FilterToValue(AnalysisLine) of
                        AnalysisLine."Source Type Filter"::Customer:
                            begin
                                SetRange("Source Type Filter", "Source Type Filter"::Customer);
                                SetFilter("Source No. Filter", GetSourceNoFilter(ItemStatisticsBuf, AnalysisLine));
                            end;
                        AnalysisLine."Source Type Filter"::Vendor:
                            begin
                                SetRange("Source Type Filter", "Source Type Filter"::Vendor);
                                SetFilter("Source No. Filter", GetSourceNoFilter(ItemStatisticsBuf, AnalysisLine));
                            end;
                        AnalysisLine."Source Type Filter"::Item:
                            SetFilter("Item Filter", GetSourceNoFilter(ItemStatisticsBuf, AnalysisLine));
                    end;
                if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                    if GetFilter("Global Dimension 1 Filter") = '' then
                        AnalysisLine.CopyFilter("Dimension 1 Filter", "Global Dimension 1 Filter");
                    if GetFilter("Global Dimension 2 Filter") = '' then
                        AnalysisLine.CopyFilter("Dimension 2 Filter", "Global Dimension 2 Filter");
                    FilterGroup := 2;
                    SetFilter("Global Dimension 1 Filter", GetDimTotalingFilter(1, AnalysisLine."Dimension 1 Totaling"));
                    SetFilter("Global Dimension 2 Filter", GetDimTotalingFilter(2, AnalysisLine."Dimension 2 Totaling"));
                    FilterGroup := 0;
                end else begin
                    SetFilter("Analysis View Filter", AnalysisLineTemplate."Item Analysis View Code");
                    if GetFilter("Dimension 1 Filter") = '' then
                        AnalysisLine.CopyFilter("Dimension 1 Filter", "Dimension 1 Filter");
                    if GetFilter("Dimension 2 Filter") = '' then
                        AnalysisLine.CopyFilter("Dimension 2 Filter", "Dimension 2 Filter");
                    if GetFilter("Dimension 3 Filter") = '' then
                        AnalysisLine.CopyFilter("Dimension 3 Filter", "Dimension 3 Filter");
                    FilterGroup := 2;
                    SetFilter("Dimension 1 Filter", GetDimTotalingFilter(1, AnalysisLine."Dimension 1 Totaling"));
                    SetFilter("Dimension 2 Filter", GetDimTotalingFilter(2, AnalysisLine."Dimension 2 Totaling"));
                    SetFilter("Dimension 3 Filter", GetDimTotalingFilter(3, AnalysisLine."Dimension 3 Totaling"));
                    FilterGroup := 0;
                end;
                AnalysisLine.CopyFilter("Location Filter", "Location Filter");
            end;

            case AnalysisColumn."Ledger Entry Type" of
                AnalysisColumn."Ledger Entry Type"::"Item Entries":
                    if DrillDown then
                        case AnalysisColumn."Value Type" of
                            AnalysisColumn."Value Type"::Quantity:
                                DrillDownQuantity(ItemStatisticsBuf, AnalysisColumn.Invoiced);
                            AnalysisColumn."Value Type"::"Sales Amount":
                                DrillDownSalesAmount(ItemStatisticsBuf, AnalysisColumn.Invoiced);
                            AnalysisColumn."Value Type"::"Cost Amount":
                                DrillDownCostAmount(ItemStatisticsBuf, AnalysisColumn.Invoiced);
                            AnalysisColumn."Value Type"::"Non-Invntble Amount":
                                DrillDownCostAmountNonInvnt(ItemStatisticsBuf, AnalysisColumn.Invoiced);
                            AnalysisColumn."Value Type"::"Unit Price":
                                DrillDownUnitPrice(ItemStatisticsBuf);
                            AnalysisColumn."Value Type"::"Standard Cost":
                                DrillDownStdCost(ItemStatisticsBuf);
                            AnalysisColumn."Value Type"::"Indirect Cost":
                                DrillDownIndirectCost(ItemStatisticsBuf);
                            AnalysisColumn."Value Type"::"Unit Cost":
                                DrillDownUnitCost(ItemStatisticsBuf);
                        end
                    else
                        case AnalysisColumn."Value Type" of
                            AnalysisColumn."Value Type"::Quantity:
                                ColValue := CalcQuantity(ItemStatisticsBuf, AnalysisColumn.Invoiced);
                            AnalysisColumn."Value Type"::"Sales Amount":
                                ColValue := CalcSalesAmount(ItemStatisticsBuf, AnalysisColumn.Invoiced);
                            AnalysisColumn."Value Type"::"Cost Amount":
                                ColValue := CalcCostAmount(ItemStatisticsBuf, AnalysisColumn.Invoiced);
                            AnalysisColumn."Value Type"::"Non-Invntble Amount":
                                ColValue := CalcCostAmountNonInvnt(ItemStatisticsBuf, AnalysisColumn.Invoiced);
                            AnalysisColumn."Value Type"::"Unit Price":
                                ColValue := CalcUnitPrice(ItemStatisticsBuf);
                            AnalysisColumn."Value Type"::"Standard Cost":
                                ColValue := CalcStdCost(ItemStatisticsBuf);
                            AnalysisColumn."Value Type"::"Indirect Cost":
                                ColValue := CalcIndirectCost(ItemStatisticsBuf);
                            AnalysisColumn."Value Type"::"Unit Cost":
                                ColValue := CalcUnitCost(ItemStatisticsBuf);
                        end;
                AnalysisColumn."Ledger Entry Type"::"Item Budget Entries":
                    if DrillDown then
                        case AnalysisColumn."Value Type" of
                            AnalysisColumn."Value Type"::Quantity:
                                DrillDownBudgetQuantity(ItemStatisticsBuf);
                            AnalysisColumn."Value Type"::"Sales Amount":
                                DrillDownBudgetSalesAmount(ItemStatisticsBuf);
                            AnalysisColumn."Value Type"::"Cost Amount":
                                DrillDownBudgetCostAmount(ItemStatisticsBuf);
                        end
                    else
                        case AnalysisColumn."Value Type" of
                            AnalysisColumn."Value Type"::Quantity:
                                ColValue := CalcBudgetQuantity(ItemStatisticsBuf);
                            AnalysisColumn."Value Type"::"Sales Amount":
                                ColValue := CalcBudgetSalesAmount(ItemStatisticsBuf);
                            AnalysisColumn."Value Type"::"Cost Amount":
                                ColValue := CalcBudgetCostAmount(ItemStatisticsBuf);
                        end;
            end;
        end;

        OnAfterCalcItemStatistics(ItemStatisticsBuf, AnalysisLine, AnalysisColumn, DrillDown, ColValue);
        exit(ColValue);
    end;

    procedure SetItemRowFilters(var ItemStatisticsBuf: Record "Item Statistics Buffer"; var AnalysisLine: Record "Analysis Line")
    begin
        with AnalysisLine do begin
            case "Analysis Area" of
                "Analysis Area"::Sales:
                    ItemStatisticsBuf.SetRange("Analysis Area Filter", "Analysis Area"::Sales);
                "Analysis Area"::Purchase:
                    ItemStatisticsBuf.SetRange("Analysis Area Filter", "Analysis Area"::Purchase);
                "Analysis Area"::Inventory:
                    ItemStatisticsBuf.SetRange("Analysis Area Filter", "Analysis Area"::Inventory);
            end;
            ItemStatisticsBuf.SetFilter("Budget Filter", GetFilter("Item Budget Filter"));
            case Type of
                Type::Item:
                    ItemStatisticsBuf.SetFilter("Item Filter", Range);
                Type::Customer:
                    begin
                        ItemStatisticsBuf.SetRange("Source Type Filter", ItemStatisticsBuf."Source Type Filter"::Customer);
                        ItemStatisticsBuf.SetFilter("Source No. Filter", Range);
                    end;
                Type::Vendor:
                    begin
                        ItemStatisticsBuf.SetRange("Source Type Filter", ItemStatisticsBuf."Source Type Filter"::Vendor);
                        ItemStatisticsBuf.SetFilter("Source No. Filter", Range);
                    end;
                Type::"Sales/Purchase person":
                    begin
                        GetSalesSetup;
                        SetGroupDimFilter(ItemStatisticsBuf, SalesSetup."Salesperson Dimension Code", Range);
                    end;
                Type::"Customer Group":
                    begin
                        GetSalesSetup;
                        SetGroupDimFilter(ItemStatisticsBuf, SalesSetup."Customer Group Dimension Code", Range);
                    end;
                Type::"Item Group":
                    begin
                        GetInventorySetup;
                        SetGroupDimFilter(ItemStatisticsBuf, InventorySetup."Item Group Dimension Code", Range);
                    end;
            end;
        end;
    end;

    procedure SetItemColumnFilters(var ItemStatisticsBuf: Record "Item Statistics Buffer"; var AnalysisColumn: Record "Analysis Column")
    var
        FromDate: Date;
        ToDate: Date;
        FiscalStartDate2: Date;
    begin
        with AnalysisColumn do begin
            ItemStatisticsBuf.SetFilter("Entry Type Filter", "Value Entry Type Filter");
            ItemStatisticsBuf.SetFilter("Item Ledger Entry Type Filter", "Item Ledger Entry Type Filter");

            if (Format("Comparison Date Formula") <> '0') and (Format("Comparison Date Formula") <> '') then begin
                FromDate := CalcDate("Comparison Date Formula", StartDate);
                if (EndDate = CalcDate('<CM>', EndDate)) and
                   ((StrPos(Format("Comparison Date Formula"), Text005Tok) > 0) or
                    (StrPos(Format("Comparison Date Formula"), Text006Tok) > 0) or
                    (StrPos(Format("Comparison Date Formula"), Text007Tok) > 0))
                then
                    ToDate := CalcDate('<CM>', CalcDate("Comparison Date Formula", EndDate))
                else
                    ToDate := CalcDate("Comparison Date Formula", EndDate);
                FiscalStartDate2 := AccountingPeriodMgt.FindFiscalYear(ToDate);
            end else
                if "Comparison Period Formula" <> '' then begin
                    AccPeriodStartEnd("Comparison Period Formula", StartDate, FromDate, ToDate);
                    FiscalStartDate2 := AccountingPeriodMgt.FindFiscalYear(ToDate);
                end else begin
                    FromDate := StartDate;
                    ToDate := EndDate;
                    FiscalStartDate2 := FiscalStartDate;
                end;
            case "Column Type" of
                "Column Type"::"Net Change":
                    ItemStatisticsBuf.SetRange("Date Filter", FromDate, ToDate);
                "Column Type"::"Balance at Date":
                    ItemStatisticsBuf.SetRange("Date Filter", 0D, ToDate);
                "Column Type"::"Beginning Balance":
                    ItemStatisticsBuf.SetRange(
                      "Date Filter", 0D, CalcDate('<-1D>', FromDate));
                "Column Type"::"Year to Date":
                    ItemStatisticsBuf.SetRange(
                      "Date Filter", FiscalStartDate2, ToDate);
                "Column Type"::"Rest of Fiscal Year":
                    ItemStatisticsBuf.SetRange(
                      "Date Filter",
                      CalcDate('<+1D>', ToDate),
                      AccountingPeriodMgt.FindEndOfFiscalYear(FiscalStartDate2));
                "Column Type"::"Entire Fiscal Year":
                    ItemStatisticsBuf.SetRange(
                      "Date Filter",
                      FiscalStartDate2,
                      AccountingPeriodMgt.FindEndOfFiscalYear(FiscalStartDate2));
            end;
        end;
    end;

    local procedure EvaluateExpression(IsAnalysisLineExpression: Boolean; Expression: Text[250]; AnalysisLine: Record "Analysis Line"; AnalysisColumn: Record "Analysis Column"): Decimal
    var
        Result: Decimal;
        Parentheses: Integer;
        Operator: Char;
        LeftOperand: Text[250];
        RightOperand: Text[250];
        LeftResult: Decimal;
        RightResult: Decimal;
        i: Integer;
        IsExpression: Boolean;
        IsFilter: Boolean;
        Operators: Text[8];
        OperatorNo: Integer;
        AnalysisLineID: Integer;
    begin
        Result := 0;

        CallLevel := CallLevel + 1;
        if CallLevel > 25 then begin
            CyclicError := true;
            exit;
        end;

        Expression := DelChr(Expression, '<>', ' ');
        if StrLen(Expression) > 0 then begin
            Parentheses := 0;
            IsExpression := false;
            Operators := '+-*/^';
            OperatorNo := 1;
            repeat
                i := StrLen(Expression);
                repeat
                    if Expression[i] = '(' then
                        Parentheses := Parentheses + 1
                    else
                        if Expression[i] = ')' then
                            Parentheses := Parentheses - 1;
                    if (Parentheses = 0) and (Expression[i] = Operators[OperatorNo]) then
                        IsExpression := true
                    else
                        i := i - 1;
                until IsExpression or (i <= 0);
                if not IsExpression then
                    OperatorNo := OperatorNo + 1;
            until (OperatorNo > StrLen(Operators)) or IsExpression;
            if IsExpression then begin
                if i > 1 then
                    LeftOperand := CopyStr(Expression, 1, i - 1)
                else
                    LeftOperand := '';
                if i < StrLen(Expression) then
                    RightOperand := CopyStr(Expression, i + 1)
                else
                    RightOperand := '';
                Operator := Expression[i];
                LeftResult :=
                  EvaluateExpression(
                    IsAnalysisLineExpression, LeftOperand, AnalysisLine, AnalysisColumn);
                RightResult :=
                  EvaluateExpression(
                    IsAnalysisLineExpression, RightOperand, AnalysisLine, AnalysisColumn);
                case Operator of
                    '^':
                        Result := Power(LeftResult, RightResult);
                    '*':
                        Result := LeftResult * RightResult;
                    '/':
                        if RightResult = 0 then begin
                            Result := 0;
                            DivisionError := true;
                        end else
                            Result := LeftResult / RightResult;
                    '+':
                        Result := LeftResult + RightResult;
                    '-':
                        Result := LeftResult - RightResult;
                end;
            end else
                if (Expression[1] = '(') and (Expression[StrLen(Expression)] = ')') then
                    Result :=
                      EvaluateExpression(
                        IsAnalysisLineExpression, CopyStr(Expression, 2, StrLen(Expression) - 2),
                        AnalysisLine, AnalysisColumn)
                else begin
                    IsFilter :=
                      (StrPos(Expression, '..') +
                       StrPos(Expression, '|') +
                       StrPos(Expression, '<') +
                       StrPos(Expression, '>') +
                       StrPos(Expression, '&') +
                       StrPos(Expression, '=') > 0);
                    if (StrLen(Expression) > 10) and (not IsFilter) then
                        Evaluate(Result, Expression)
                    else
                        if IsAnalysisLineExpression then begin
                            AnalysisLine.SetRange("Analysis Area", AnalysisLine."Analysis Area");
                            AnalysisLine.SetRange("Analysis Line Template Name", AnalysisLine."Analysis Line Template Name");
                            if not IsValidAnalysisExpression(AnalysisLine, Expression) then
                                FormulaError := true
                            else
                                AnalysisLine.SetFilter("Row Ref. No.", Expression);
                            AnalysisLineID := AnalysisLine."Line No.";
                            if not FormulaError then begin
                                if AnalysisLine.Find('-') then
                                    repeat
                                        if AnalysisLine."Line No." <> AnalysisLineID then
                                            Result := Result + CalcCellValue(AnalysisLine, AnalysisColumn, false);
                                    until AnalysisLine.Next = 0
                                else
                                    if IsFilter or (not Evaluate(Result, Expression)) then
                                        FormulaError := true;
                            end;
                        end else begin
                            AnalysisColumn.SetRange("Analysis Area", AnalysisColumn."Analysis Area");
                            AnalysisColumn.SetRange("Analysis Column Template", AnalysisColumn."Analysis Column Template");
                            if not IsValidAnalysisExpression(AnalysisLine, Expression) then
                                FormulaError := true
                            else
                                AnalysisColumn.SetFilter("Column No.", Expression);
                            AnalysisLineID := AnalysisColumn."Line No.";
                            if not FormulaError then begin
                                if AnalysisColumn.Find('-') then
                                    repeat
                                        if AnalysisColumn."Line No." <> AnalysisLineID then
                                            Result := Result + CalcCellValue(AnalysisLine, AnalysisColumn, false);
                                    until AnalysisColumn.Next = 0
                                else
                                    if IsFilter or (not Evaluate(Result, Expression)) then
                                        FormulaError := true;
                            end;
                        end;
                end;
        end;
        CallLevel := CallLevel - 1;
        exit(Result);
    end;

    procedure GetDivisionError(): Boolean
    begin
        exit(DivisionError);
    end;

    procedure GetPeriodError(): Boolean
    begin
        exit(PeriodError);
    end;

    procedure GetFormulaError(): Boolean
    begin
        exit(FormulaError);
    end;

    procedure GetCyclicError(): Boolean
    begin
        exit(CyclicError);
    end;

    procedure SetAnalysisLineTemplate(var NewAnalysisLineTemplate: Record "Analysis Line Template")
    begin
        AnalysisLineTemplate := NewAnalysisLineTemplate;
    end;

    local procedure GetDimTotalingFilter(DimNo: Integer; DimTotaling: Text[80]): Text[1024]
    var
        DimTotaling2: Text[80];
        DimTotalPart: Text[80];
        ResultFilter: Text[1024];
        ResultFilter2: Text[1024];
        i: Integer;
    begin
        if DimTotaling = '' then
            exit(DimTotaling);
        DimTotaling2 := DimTotaling;
        repeat
            i := StrPos(DimTotaling2, '|');
            if i > 0 then begin
                DimTotalPart := CopyStr(DimTotaling2, 1, i - 1);
                if i < StrLen(DimTotaling2) then
                    DimTotaling2 := CopyStr(DimTotaling2, i + 1)
                else
                    DimTotaling2 := '';
            end else
                DimTotalPart := DimTotaling2;
            ResultFilter2 := ConvDimTotalingFilter(DimNo, DimTotalPart);
            if ResultFilter2 <> '' then
                if StrLen(ResultFilter) + StrLen(ResultFilter2) + 1 > MaxStrLen(ResultFilter) then
                    Error(Text021, DimTotaling)
                else begin
                    if ResultFilter <> '' then
                        ResultFilter := ResultFilter + '|';
                    ResultFilter := ResultFilter + ResultFilter2;
                end;
        until i <= 0;
        exit(ResultFilter);
    end;

    local procedure ConvDimTotalingFilter(DimNo: Integer; DimTotaling: Text[80]): Text[1024]
    var
        DimVal: Record "Dimension Value";
        ItemAnalysisView: Record "Item Analysis View";
        DimCode: Code[20];
        ResultFilter: Text[1024];
        DimValTotaling: Boolean;
    begin
        if DimTotaling = '' then
            exit(DimTotaling);

        if AnalysisLineTemplate."Item Analysis View Code" <> '' then
            ItemAnalysisView.Get(AnalysisLineTemplate."Analysis Area", AnalysisLineTemplate."Item Analysis View Code")
        else begin
            GLSetup.Get();
            ItemAnalysisView.Init();
            ItemAnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
            ItemAnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
        end;

        case DimNo of
            1:
                DimCode := ItemAnalysisView."Dimension 1 Code";
            2:
                DimCode := ItemAnalysisView."Dimension 2 Code";
            3:
                DimCode := ItemAnalysisView."Dimension 3 Code";
        end;
        if DimCode = '' then
            exit(DimTotaling);

        DimVal.SetRange("Dimension Code", DimCode);
        DimVal.SetFilter(Code, DimTotaling);
        if DimVal.Find('-') then
            repeat
                DimValTotaling :=
                  DimVal."Dimension Value Type" in
                  [DimVal."Dimension Value Type"::Total, DimVal."Dimension Value Type"::"End-Total"];
                if DimValTotaling and (DimVal.Totaling <> '') then begin
                    if StrLen(ResultFilter) + StrLen(DimVal.Totaling) + 1 > MaxStrLen(ResultFilter) then
                        Error(Text021, DimTotaling);
                    if ResultFilter <> '' then
                        ResultFilter := ResultFilter + '|';
                    ResultFilter := ResultFilter + DimVal.Totaling;
                end;
            until (DimVal.Next = 0) or not DimValTotaling;

        if DimValTotaling then
            exit(ResultFilter);

        exit(DimTotaling);
    end;

    local procedure CalcSalesAmount(var ItemStatisticsBuf: Record "Item Statistics Buffer"; Invoiced: Boolean): Decimal
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                if Invoiced then begin
                    CalcFields("Sales Amount (Actual)");
                    exit("Sales Amount (Actual)");
                end;
                CalcFields("Sales Amount (Expected)");
                exit("Sales Amount (Expected)");
            end;
            if Invoiced then begin
                CalcFields("Analysis - Sales Amt. (Actual)");
                exit("Analysis - Sales Amt. (Actual)");
            end;
            CalcFields("Analysis - Sales Amt. (Exp)");
            exit("Analysis - Sales Amt. (Exp)");
        end;
    end;

    local procedure CalcCostAmount(var ItemStatisticsBuf: Record "Item Statistics Buffer"; Invoiced: Boolean): Decimal
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                if Invoiced then begin
                    CalcFields("Cost Amount (Actual)");
                    exit("Cost Amount (Actual)");
                end;
                CalcFields("Cost Amount (Expected)");
                exit("Cost Amount (Expected)");
            end;
            if Invoiced then begin
                CalcFields("Analysis - Cost Amt. (Actual)");
                exit("Analysis - Cost Amt. (Actual)");
            end;
            CalcFields("Analysis - Cost Amt. (Exp)");
            exit("Analysis - Cost Amt. (Exp)");
        end;
    end;

    local procedure CalcCostAmountNonInvnt(var ItemStatisticsBuf: Record "Item Statistics Buffer"; Invoiced: Boolean): Decimal
    begin
        with ItemStatisticsBuf do begin
            SetRange("Item Ledger Entry Type Filter");
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                if Invoiced then begin
                    CalcFields("Cost Amount (Non-Invtbl.)");
                    exit("Cost Amount (Non-Invtbl.)");
                end;
                exit(0);
            end;
            if Invoiced then begin
                CalcFields("Analysis CostAmt.(Non-Invtbl.)");
                exit("Analysis CostAmt.(Non-Invtbl.)");
            end;
        end;
    end;

    local procedure CalcQuantity(var ItemStatisticsBuf: Record "Item Statistics Buffer"; Invoiced: Boolean): Decimal
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                SetRange("Entry Type Filter");
                if Invoiced then begin
                    CalcFields("Invoiced Quantity");
                    exit("Invoiced Quantity");
                end;
                CalcFields(Quantity);
                exit(Quantity);
            end;
            SetRange("Entry Type Filter");
            if Invoiced then begin
                CalcFields("Analysis - Invoiced Quantity");
                exit("Analysis - Invoiced Quantity");
            end;
            CalcFields("Analysis - Quantity");
            exit("Analysis - Quantity");
        end;
    end;

    local procedure CalcUnitPrice(var ItemStatisticsBuf: Record "Item Statistics Buffer"): Decimal
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculation: interface "Price Calculation";
        PriceType: Enum "Price Type";
    begin
        if Item.Get(CopyStr(ItemStatisticsBuf.GetFilter("Item Filter"), 1, MaxStrLen(Item."No."))) then begin
            SalesLine.Type := SalesLine.Type::Item;
            SalesLine."No." := Item."No.";
            SalesLine."Posting Date" := ItemStatisticsBuf.GetRangeMin("Date Filter");
            SalesLinePrice.SetLine(PriceType::Sale, SalesLine);
            PriceCalculationMgt.GetHandler(SalesLinePrice, PriceCalculation);
            PriceCalculation.FindPrice(TempPriceListLine, false);
            exit(TempPriceListLine."Unit Price");
        end
    end;

    local procedure CalcStdCost(var ItemStatisticsBuf: Record "Item Statistics Buffer"): Decimal
    var
        Item: Record Item;
    begin
        with Item do
            if Get(CopyStr(ItemStatisticsBuf.GetFilter("Item Filter"), 1, MaxStrLen("No."))) then
                exit("Standard Cost");
    end;

    local procedure CalcIndirectCost(var ItemStatisticsBuf: Record "Item Statistics Buffer"): Decimal
    var
        Item: Record Item;
    begin
        with Item do
            if Get(CopyStr(ItemStatisticsBuf.GetFilter("Item Filter"), 1, MaxStrLen("No."))) then
                exit("Indirect Cost %");
    end;

    local procedure CalcUnitCost(var ItemStatisticsBuf: Record "Item Statistics Buffer"): Decimal
    var
        Item: Record Item;
    begin
        with Item do
            if Get(CopyStr(ItemStatisticsBuf.GetFilter("Item Filter"), 1, MaxStrLen("No."))) then
                exit("Unit Cost");
    end;

    local procedure CalcBudgetSalesAmount(var ItemStatisticsBuf: Record "Item Statistics Buffer"): Decimal
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter")
            else
                SetRange("Item Ledger Entry Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                CalcFields("Budgeted Sales Amount");
                exit("Budgeted Sales Amount");
            end;
            CalcFields("Analysis - Budgeted Sales Amt.");
            exit("Analysis - Budgeted Sales Amt.");
        end;
    end;

    local procedure CalcBudgetCostAmount(var ItemStatisticsBuf: Record "Item Statistics Buffer"): Decimal
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                CalcFields("Budgeted Cost Amount");
                exit("Budgeted Cost Amount");
            end;
            CalcFields("Analysis - Budgeted Cost Amt.");
            exit("Analysis - Budgeted Cost Amt.");
        end;
    end;

    local procedure CalcBudgetQuantity(var ItemStatisticsBuf: Record "Item Statistics Buffer"): Decimal
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                CalcFields("Budgeted Quantity");
                exit("Budgeted Quantity");
            end;
            CalcFields("Analysis - Budgeted Quantity");
            exit("Analysis - Budgeted Quantity");
        end;
    end;

    local procedure DrillDownSalesAmount(var ItemStatisticsBuf: Record "Item Statistics Buffer"; Invoiced: Boolean)
    var
        ValueEntry: Record "Value Entry";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                FilterValueEntry(ItemStatisticsBuf, ValueEntry);
                if Invoiced then
                    PAGE.Run(0, ValueEntry, ValueEntry."Sales Amount (Actual)")
                else
                    PAGE.Run(0, ValueEntry, ValueEntry."Sales Amount (Expected)");
            end else begin
                FilterItemAnalyViewEntry(ItemStatisticsBuf, ItemAnalysisViewEntry);
                if Invoiced then
                    PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry."Sales Amount (Actual)")
                else
                    PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry."Sales Amount (Expected)");
            end;
        end;
    end;

    local procedure DrillDownCostAmount(var ItemStatisticsBuf: Record "Item Statistics Buffer"; Invoiced: Boolean)
    var
        ValueEntry: Record "Value Entry";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                FilterValueEntry(ItemStatisticsBuf, ValueEntry);
                if Invoiced then
                    PAGE.Run(0, ValueEntry, ValueEntry."Cost Amount (Actual)")
                else
                    PAGE.Run(0, ValueEntry, ValueEntry."Cost Amount (Expected)");
            end else begin
                FilterItemAnalyViewEntry(ItemStatisticsBuf, ItemAnalysisViewEntry);
                if Invoiced then
                    PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry."Cost Amount (Actual)")
                else
                    PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry."Cost Amount (Expected)");
            end;
        end;
    end;

    local procedure DrillDownCostAmountNonInvnt(var ItemStatisticsBuf: Record "Item Statistics Buffer"; Invoiced: Boolean)
    var
        ValueEntry: Record "Value Entry";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                FilterValueEntry(ItemStatisticsBuf, ValueEntry);
                if Invoiced then
                    PAGE.Run(0, ValueEntry, ValueEntry."Cost Amount (Non-Invtbl.)");
            end else begin
                FilterItemAnalyViewEntry(ItemStatisticsBuf, ItemAnalysisViewEntry);
                if Invoiced then
                    PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry."Cost Amount (Non-Invtbl.)")
            end;
        end;
    end;

    local procedure DrillDownQuantity(var ItemStatisticsBuf: Record "Item Statistics Buffer"; Invoiced: Boolean)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            SetRange("Entry Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                if Invoiced then begin
                    FilterValueEntry(ItemStatisticsBuf, ValueEntry);
                    PAGE.Run(0, ValueEntry, ValueEntry."Invoiced Quantity");
                end else begin
                    FilterItemLedgEntry(ItemStatisticsBuf, ItemLedgEntry);
                    PAGE.Run(0, ItemLedgEntry, ItemLedgEntry.Quantity);
                end;
            end else begin
                FilterItemAnalyViewEntry(ItemStatisticsBuf, ItemAnalysisViewEntry);
                if Invoiced then
                    PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry."Invoiced Quantity")
                else
                    PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry.Quantity);
            end;
        end;
    end;

    local procedure DrillDownUnitPrice(var ItemStatisticsBuf: Record "Item Statistics Buffer")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TempPriceListLine: Record "Price List Line" temporary;
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceCalculation: Interface "Price Calculation";
        PriceType: Enum "Price Type";
    begin
        if Item.Get(CopyStr(ItemStatisticsBuf.GetFilter("Item Filter"), 1, MaxStrLen(Item."No."))) then begin
            SalesLine.Type := SalesLine.Type::Item;
            SalesLine."No." := Item."No.";
            SalesLine."Posting Date" := ItemStatisticsBuf.GetRangeMin("Date Filter");
            SalesLinePrice.SetLine(PriceType::Sale, SalesLine);
            PriceCalculationMgt.GetHandler(SalesLinePrice, PriceCalculation);
            if PriceCalculation.FindPrice(TempPriceListLine, false) then
                PriceCalculation.ShowPrices(TempPriceListLine)
            else begin
                ItemStatisticsBuf.CopyFilter("Item Filter", Item."No.");
                PAGE.RunModal(PAGE::"Item Card", Item, Item."Unit Price");
            end;
        end;
    end;

    local procedure DrillDownStdCost(var ItemStatisticsBuf: Record "Item Statistics Buffer")
    var
        Item: Record Item;
    begin
        with Item do begin
            ItemStatisticsBuf.CopyFilter("Item Filter", "No.");
            PAGE.RunModal(PAGE::"Item Card", Item, "Standard Cost");
        end;
    end;

    local procedure DrillDownIndirectCost(var ItemStatisticsBuf: Record "Item Statistics Buffer")
    var
        Item: Record Item;
    begin
        with Item do begin
            ItemStatisticsBuf.CopyFilter("Item Filter", "No.");
            PAGE.RunModal(PAGE::"Item Card", Item, "Indirect Cost %");
        end;
    end;

    local procedure DrillDownUnitCost(var ItemStatisticsBuf: Record "Item Statistics Buffer")
    var
        Item: Record Item;
    begin
        with Item do begin
            ItemStatisticsBuf.CopyFilter("Item Filter", "No.");
            PAGE.RunModal(PAGE::"Item Card", Item, "Unit Cost");
        end;
    end;

    local procedure DrillDownBudgetSalesAmount(var ItemStatisticsBuf: Record "Item Statistics Buffer")
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                FilterItemBudgetEntry(ItemStatisticsBuf, ItemBudgetEntry);
                PAGE.Run(0, ItemBudgetEntry, ItemBudgetEntry."Sales Amount");
            end else begin
                FilterItemAnalyViewBudgEntry(ItemStatisticsBuf, ItemAnalysisViewBudgEntry);
                PAGE.Run(0, ItemAnalysisViewBudgEntry, ItemAnalysisViewBudgEntry."Sales Amount");
            end;
        end;
    end;

    local procedure DrillDownBudgetCostAmount(var ItemStatisticsBuf: Record "Item Statistics Buffer")
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                FilterItemBudgetEntry(ItemStatisticsBuf, ItemBudgetEntry);
                PAGE.Run(0, ItemBudgetEntry, ItemBudgetEntry."Cost Amount");
            end else begin
                FilterItemAnalyViewBudgEntry(ItemStatisticsBuf, ItemAnalysisViewBudgEntry);
                PAGE.Run(0, ItemAnalysisViewBudgEntry, ItemAnalysisViewBudgEntry."Cost Amount");
            end;
        end;
    end;

    local procedure DrillDownBudgetQuantity(var ItemStatisticsBuf: Record "Item Statistics Buffer")
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Source No. Filter") = '' then
                SetRange("Source Type Filter");

            if AnalysisLineTemplate."Item Analysis View Code" = '' then begin
                FilterItemBudgetEntry(ItemStatisticsBuf, ItemBudgetEntry);
                PAGE.Run(0, ItemBudgetEntry, ItemBudgetEntry.Quantity);
            end else begin
                FilterItemAnalyViewBudgEntry(ItemStatisticsBuf, ItemAnalysisViewBudgEntry);
                PAGE.Run(0, ItemAnalysisViewBudgEntry, ItemAnalysisViewBudgEntry.Quantity);
            end;
        end;
    end;

    local procedure FilterValueEntry(var ItemStatisticsBuf: Record "Item Statistics Buffer"; var ValueEntry: Record "Value Entry")
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Item Filter") <> '' then
                CopyFilter("Item Filter", ValueEntry."Item No.");

            if GetFilter("Date Filter") <> '' then
                CopyFilter("Date Filter", ValueEntry."Posting Date");

            if GetFilter("Entry Type Filter") <> '' then
                CopyFilter("Entry Type Filter", ValueEntry."Entry Type");

            if GetFilter("Item Ledger Entry Type Filter") <> '' then
                CopyFilter("Item Ledger Entry Type Filter", ValueEntry."Item Ledger Entry Type");

            if GetFilter("Location Filter") <> '' then
                CopyFilter("Location Filter", ValueEntry."Location Code");

            if GetFilter("Global Dimension 1 Filter") <> '' then
                CopyFilter("Global Dimension 1 Filter", ValueEntry."Global Dimension 1 Code");

            if GetFilter("Global Dimension 2 Filter") <> '' then
                CopyFilter("Global Dimension 2 Filter", ValueEntry."Global Dimension 2 Code");

            if GetFilter("Source Type Filter") <> '' then
                CopyFilter("Source Type Filter", ValueEntry."Source Type");

            FilterGroup := 2;
            ValueEntry.FilterGroup := 2;
            if GetFilter("Global Dimension 1 Filter") <> '' then
                CopyFilter("Global Dimension 1 Filter", ValueEntry."Global Dimension 1 Code");
            if GetFilter("Global Dimension 2 Filter") <> '' then
                CopyFilter("Global Dimension 2 Filter", ValueEntry."Global Dimension 2 Code");
            FilterGroup := 0;
            ValueEntry.FilterGroup := 0;

            if GetFilter("Source No. Filter") <> '' then begin
                ValueEntry.SetCurrentKey("Source Type", "Source No.");
                CopyFilter("Source No. Filter", ValueEntry."Source No.");
            end else
                ValueEntry.SetCurrentKey("Item No.", "Posting Date");
        end;
    end;

    local procedure FilterItemLedgEntry(var ItemStatisticsBuf: Record "Item Statistics Buffer"; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        with ItemStatisticsBuf do begin
            if GetFilter("Item Filter") <> '' then
                CopyFilter("Item Filter", ItemLedgEntry."Item No.");

            if GetFilter("Date Filter") <> '' then
                CopyFilter("Date Filter", ItemLedgEntry."Posting Date");

            if GetFilter("Item Ledger Entry Type Filter") <> '' then
                CopyFilter("Item Ledger Entry Type Filter", ItemLedgEntry."Entry Type");

            if GetFilter("Location Filter") <> '' then
                CopyFilter("Location Filter", ItemLedgEntry."Location Code");

            if GetFilter("Global Dimension 1 Filter") <> '' then
                CopyFilter("Global Dimension 1 Filter", ItemLedgEntry."Global Dimension 1 Code");

            if GetFilter("Global Dimension 2 Filter") <> '' then
                CopyFilter("Global Dimension 2 Filter", ItemLedgEntry."Global Dimension 2 Code");

            if GetFilter("Source Type Filter") <> '' then
                CopyFilter("Source Type Filter", ItemLedgEntry."Source Type");

            FilterGroup := 2;
            ItemLedgEntry.FilterGroup := 2;
            if GetFilter("Global Dimension 1 Filter") <> '' then
                CopyFilter("Global Dimension 1 Filter", ItemLedgEntry."Global Dimension 1 Code");
            if GetFilter("Global Dimension 2 Filter") <> '' then
                CopyFilter("Global Dimension 2 Filter", ItemLedgEntry."Global Dimension 2 Code");
            FilterGroup := 0;
            ItemLedgEntry.FilterGroup := 0;

            if GetFilter("Source No. Filter") <> '' then begin
                ItemLedgEntry.SetCurrentKey("Source Type", "Source No.");
                CopyFilter("Source No. Filter", ItemLedgEntry."Source No.");
            end else
                ItemLedgEntry.SetCurrentKey("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
        end;
    end;

    local procedure FilterItemBudgetEntry(var ItemStatisticsBuf: Record "Item Statistics Buffer"; var ItemBudgetEntry: Record "Item Budget Entry")
    begin
        with ItemStatisticsBuf do begin
            CopyFilter("Analysis Area Filter", ItemBudgetEntry."Analysis Area");
            CopyFilter("Budget Filter", ItemBudgetEntry."Budget Name");

            if GetFilter("Item Filter") <> '' then
                CopyFilter("Item Filter", ItemBudgetEntry."Item No.");

            if GetFilter("Date Filter") <> '' then
                CopyFilter("Date Filter", ItemBudgetEntry.Date);

            if GetFilter("Global Dimension 1 Filter") <> '' then
                CopyFilter("Global Dimension 1 Filter", ItemBudgetEntry."Global Dimension 1 Code");

            if GetFilter("Global Dimension 2 Filter") <> '' then
                CopyFilter("Global Dimension 2 Filter", ItemBudgetEntry."Global Dimension 2 Code");

            if GetFilter("Source Type Filter") <> '' then
                CopyFilter("Source Type Filter", ItemBudgetEntry."Source Type");

            FilterGroup := 2;
            ItemBudgetEntry.FilterGroup := 2;
            if GetFilter("Global Dimension 1 Filter") <> '' then
                CopyFilter("Global Dimension 1 Filter", ItemBudgetEntry."Global Dimension 1 Code");
            if GetFilter("Global Dimension 2 Filter") <> '' then
                CopyFilter("Global Dimension 2 Filter", ItemBudgetEntry."Global Dimension 2 Code");
            FilterGroup := 0;
            ItemBudgetEntry.FilterGroup := 0;

            if GetFilter("Source No. Filter") <> '' then begin
                ItemBudgetEntry.SetCurrentKey("Analysis Area", "Budget Name", "Source Type", "Source No.");
                CopyFilter("Source No. Filter", ItemBudgetEntry."Source No.");
            end else
                ItemBudgetEntry.SetCurrentKey("Analysis Area", "Budget Name", "Item No.");
        end;
    end;

    local procedure FilterItemAnalyViewEntry(var ItemStatisticsBuf: Record "Item Statistics Buffer"; var ItemAnalysisViewEntry: Record "Item Analysis View Entry")
    begin
        with ItemStatisticsBuf do begin
            CopyFilter("Analysis Area Filter", ItemAnalysisViewEntry."Analysis Area");
            CopyFilter("Analysis View Filter", ItemAnalysisViewEntry."Analysis View Code");

            if GetFilter("Item Filter") <> '' then
                CopyFilter("Item Filter", ItemAnalysisViewEntry."Item No.");

            if GetFilter("Date Filter") <> '' then
                CopyFilter("Date Filter", ItemAnalysisViewEntry."Posting Date");

            if GetFilter("Entry Type Filter") <> '' then
                CopyFilter("Entry Type Filter", ItemAnalysisViewEntry."Entry Type");

            if GetFilter("Item Ledger Entry Type Filter") <> '' then
                CopyFilter("Item Ledger Entry Type Filter", ItemAnalysisViewEntry."Item Ledger Entry Type");

            if GetFilter("Location Filter") <> '' then
                CopyFilter("Location Filter", ItemAnalysisViewEntry."Location Code");

            if GetFilter("Dimension 1 Filter") <> '' then
                CopyFilter("Dimension 1 Filter", ItemAnalysisViewEntry."Dimension 1 Value Code");

            if GetFilter("Dimension 2 Filter") <> '' then
                CopyFilter("Dimension 2 Filter", ItemAnalysisViewEntry."Dimension 2 Value Code");

            if GetFilter("Dimension 3 Filter") <> '' then
                CopyFilter("Dimension 3 Filter", ItemAnalysisViewEntry."Dimension 3 Value Code");

            if GetFilter("Source Type Filter") <> '' then
                CopyFilter("Source Type Filter", ItemAnalysisViewEntry."Source Type");

            if GetFilter("Source No. Filter") <> '' then
                CopyFilter("Source No. Filter", ItemAnalysisViewEntry."Source No.");

            FilterGroup := 2;
            ItemAnalysisViewEntry.FilterGroup := 2;
            if GetFilter("Dimension 1 Filter") <> '' then
                CopyFilter("Dimension 1 Filter", ItemAnalysisViewEntry."Dimension 1 Value Code");
            if GetFilter("Dimension 2 Filter") <> '' then
                CopyFilter("Dimension 2 Filter", ItemAnalysisViewEntry."Dimension 2 Value Code");
            if GetFilter("Dimension 3 Filter") <> '' then
                CopyFilter("Dimension 3 Filter", ItemAnalysisViewEntry."Dimension 3 Value Code");
            FilterGroup := 0;
            ItemAnalysisViewEntry.FilterGroup := 0;
        end;
    end;

    local procedure FilterItemAnalyViewBudgEntry(var ItemStatisticsBuf: Record "Item Statistics Buffer"; var ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry")
    begin
        with ItemStatisticsBuf do begin
            CopyFilter("Analysis Area Filter", ItemAnalysisViewBudgEntry."Analysis Area");
            CopyFilter("Analysis View Filter", ItemAnalysisViewBudgEntry."Analysis View Code");
            CopyFilter("Budget Filter", ItemAnalysisViewBudgEntry."Budget Name");

            if GetFilter("Item Filter") <> '' then
                CopyFilter("Item Filter", ItemAnalysisViewBudgEntry."Item No.");

            if GetFilter("Date Filter") <> '' then
                CopyFilter("Date Filter", ItemAnalysisViewBudgEntry."Posting Date");

            if GetFilter("Dimension 1 Filter") <> '' then
                CopyFilter("Dimension 1 Filter", ItemAnalysisViewBudgEntry."Dimension 1 Value Code");

            if GetFilter("Dimension 2 Filter") <> '' then
                CopyFilter("Dimension 2 Filter", ItemAnalysisViewBudgEntry."Dimension 2 Value Code");

            if GetFilter("Dimension 3 Filter") <> '' then
                CopyFilter("Dimension 3 Filter", ItemAnalysisViewBudgEntry."Dimension 3 Value Code");

            if GetFilter("Source Type Filter") <> '' then
                CopyFilter("Source Type Filter", ItemAnalysisViewBudgEntry."Source Type");

            if GetFilter("Source No. Filter") <> '' then
                CopyFilter("Source No. Filter", ItemAnalysisViewBudgEntry."Source No.");

            FilterGroup := 2;
            ItemAnalysisViewBudgEntry.FilterGroup := 2;
            if GetFilter("Dimension 1 Filter") <> '' then
                CopyFilter("Dimension 1 Filter", ItemAnalysisViewBudgEntry."Dimension 1 Value Code");
            if GetFilter("Dimension 2 Filter") <> '' then
                CopyFilter("Dimension 2 Filter", ItemAnalysisViewBudgEntry."Dimension 2 Value Code");
            if GetFilter("Dimension 3 Filter") <> '' then
                CopyFilter("Dimension 3 Filter", ItemAnalysisViewBudgEntry."Dimension 3 Value Code");
            FilterGroup := 0;
            ItemAnalysisViewBudgEntry.FilterGroup := 0;
        end;
    end;

    local procedure SetGroupDimFilter(var ItemStatisticsBuf: Record "Item Statistics Buffer"; GroupDimCode: Code[20]; DimValueFilter: Text[250])
    var
        ItemAnalysisView: Record "Item Analysis View";
    begin
        if AnalysisLineTemplate."Item Analysis View Code" <> '' then begin
            ItemAnalysisView.Get(AnalysisLineTemplate."Analysis Area", AnalysisLineTemplate."Item Analysis View Code");
            case GroupDimCode of
                '':
                    exit;
                ItemAnalysisView."Dimension 1 Code":
                    ItemStatisticsBuf.SetFilter("Dimension 1 Filter", DimValueFilter);
                ItemAnalysisView."Dimension 2 Code":
                    ItemStatisticsBuf.SetFilter("Dimension 2 Filter", DimValueFilter);
                ItemAnalysisView."Dimension 3 Code":
                    ItemStatisticsBuf.SetFilter("Dimension 3 Filter", DimValueFilter);
                else
                    Error(Text022,
                      AnalysisLineTemplate.FieldCaption("Item Analysis View Code"),
                      AnalysisLineTemplate.TableCaption,
                      AnalysisLineTemplate."Analysis Area",
                      AnalysisLineTemplate.Name,
                      GroupDimCode);
            end;
        end else begin
            GLSetup.Get();
            case GroupDimCode of
                '':
                    exit;
                GLSetup."Global Dimension 1 Code":
                    ItemStatisticsBuf.SetFilter("Global Dimension 1 Filter", DimValueFilter);
                GLSetup."Global Dimension 2 Code":
                    ItemStatisticsBuf.SetFilter("Global Dimension 2 Filter", DimValueFilter);
                else
                    Error(Text022,
                      AnalysisLineTemplate.FieldCaption("Item Analysis View Code"),
                      AnalysisLineTemplate.TableCaption,
                      AnalysisLineTemplate."Analysis Area",
                      AnalysisLineTemplate.Name,
                      GroupDimCode);
            end;
        end;
    end;

    local procedure FilterToValue(var AnalysisLine: Record "Analysis Line"): Integer
    var
        AnalysisLine2: Record "Analysis Line";
    begin
        with AnalysisLine2 do
            for "Source Type Filter" := "Source Type Filter"::" " to "Source Type Filter"::Item do
                if AnalysisLine.GetFilter("Source Type Filter") = Format("Source Type Filter") then
                    exit("Source Type Filter");
    end;

    local procedure GetSalesSetup()
    begin
        if SalesSetupRead then
            exit;
        SalesSetup.Get();
        SalesSetupRead := true;
    end;

    local procedure GetInventorySetup()
    begin
        if InventorySetupRead then
            exit;
        InventorySetup.Get();
        InventorySetupRead := true;
    end;

    procedure SetExpression(Expression: Text[250])
    begin
        TryExpression := Expression;
    end;

    local procedure IsValidAnalysisExpression(var AnalysisLine: Record "Analysis Line"; Expression: Text[250]): Boolean
    var
        AnalysisReportMgt: Codeunit "Analysis Report Management";
    begin
        AnalysisReportMgt.SetExpression(Expression);
        if AnalysisReportMgt.Run(AnalysisLine) then
            exit(true);
        exit(false);
    end;

    procedure ValidateFilter(var "Filter": Text; RecNo: Integer; FieldNumber: Integer; ConvertToNumbers: Boolean)
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisType: Record "Analysis Type";
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
    begin
        case RecNo of
            DATABASE::"Analysis Column":
                case FieldNumber of
                    AnalysisColumn.FieldNo("Item Ledger Entry Type Filter"):
                        begin
                            ItemStatisticsBuffer.SetFilter("Item Ledger Entry Type Filter", Filter);
                            Filter := ItemStatisticsBuffer.GetFilter("Item Ledger Entry Type Filter");
                        end;
                    AnalysisColumn.FieldNo("Value Entry Type Filter"):
                        begin
                            ItemStatisticsBuffer.SetFilter("Entry Type Filter", Filter);
                            Filter := ItemStatisticsBuffer.GetFilter("Entry Type Filter");
                        end;
                end;
            DATABASE::"Analysis Type":
                case FieldNumber of
                    AnalysisType.FieldNo("Item Ledger Entry Type Filter"):
                        begin
                            ItemStatisticsBuffer.SetFilter("Item Ledger Entry Type Filter", Filter);
                            Filter := ItemStatisticsBuffer.GetFilter("Item Ledger Entry Type Filter");
                        end;
                    AnalysisType.FieldNo("Value Entry Type Filter"):
                        begin
                            ItemStatisticsBuffer.SetFilter("Entry Type Filter", Filter);
                            Filter := ItemStatisticsBuffer.GetFilter("Entry Type Filter");
                        end;
                end;
        end;

        if ConvertToNumbers then
            ConvertOptionNameToNo(Filter, RecNo, FieldNumber);
    end;

    local procedure ConvertOptionNameToNo(var "Filter": Text; RecNo: Integer; FieldNumber: Integer)
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisType: Record "Analysis Type";
        DummyItemStatisticsBuffer: Record "Item Statistics Buffer";
        VarInteger: Integer;
        OptionNo: Integer;
        OptionName: Text[30];
    begin
        while true do begin
            case RecNo of
                DATABASE::"Analysis Column":
                    case FieldNumber of
                        AnalysisColumn.FieldNo("Item Ledger Entry Type Filter"):
                            begin
                                DummyItemStatisticsBuffer."Item Ledger Entry Type Filter" := OptionNo;
                                OptionName := Format(DummyItemStatisticsBuffer."Item Ledger Entry Type Filter");
                            end;
                        AnalysisColumn.FieldNo("Value Entry Type Filter"):
                            begin
                                DummyItemStatisticsBuffer."Entry Type Filter" := OptionNo;
                                OptionName := Format(DummyItemStatisticsBuffer."Entry Type Filter");
                            end;
                    end;
                DATABASE::"Analysis Type":
                    case FieldNumber of
                        AnalysisType.FieldNo("Item Ledger Entry Type Filter"):
                            begin
                                DummyItemStatisticsBuffer."Item Ledger Entry Type Filter" := OptionNo;
                                OptionName := Format(DummyItemStatisticsBuffer."Item Ledger Entry Type Filter");
                            end;
                        AnalysisType.FieldNo("Value Entry Type Filter"):
                            begin
                                DummyItemStatisticsBuffer."Entry Type Filter" := OptionNo;
                                OptionName := Format(DummyItemStatisticsBuffer."Entry Type Filter");
                            end;
                    end;
            end;

            if Evaluate(VarInteger, OptionName) then
                if VarInteger = OptionNo then
                    exit;

            FindAndReplace(Filter, OptionName, Format(OptionNo));
            OptionNo += 1;
        end;
    end;

    local procedure FindAndReplace(var "Filter": Text; FindWhat: Text[30]; ReplaceWith: Text[30])
    var
        Position: Integer;
    begin
        while true do begin
            Position := StrPos(Filter, FindWhat);
            if Position = 0 then
                exit;
            Filter := InsStr(DelStr(Filter, Position, StrLen(FindWhat)), ReplaceWith, Position);
        end;
    end;

    local procedure GetSourceNoFilter(var ItemStatisticsBuf: Record "Item Statistics Buffer"; var AnalysisLine: Record "Analysis Line"): Text
    begin
        case FilterToValue(AnalysisLine) of
            AnalysisLine."Source Type Filter"::Item:
                exit(DelChr(StrSubstNo('%1&%2',
                      ItemStatisticsBuf.GetFilter("Item Filter"), AnalysisLine.GetFilter("Source No. Filter")), '<>', '&'));
            else
                exit(DelChr(StrSubstNo('%1&%2',
                      ItemStatisticsBuf.GetFilter("Source No. Filter"), AnalysisLine.GetFilter("Source No. Filter")), '<>', '&'));
        end;
    end;

    local procedure CalcFieldError(RowNo: Integer; ColumnNo: Integer) ErrorText: Text
    var
        AllErrorType: Boolean;
    begin
        AnalysisFieldValue.SetRange("Row Ref. No.", RowNo);
        AnalysisFieldValue.SetRange("Column No.", ColumnNo);
        if AnalysisFieldValue.FindFirst then begin
            AllErrorType :=
              AnalysisFieldValue."Has Error" and
              AnalysisFieldValue."Period Error" and
              AnalysisFieldValue."Formula Error" and
              AnalysisFieldValue."Cyclic Error";
            if AllErrorType then
                exit(Format(ShowError::All));
            if AnalysisFieldValue."Has Error" then
                ErrorText := Format(ShowError::"Division by Zero") + SeparatorTok;
            if AnalysisFieldValue."Period Error" then
                ErrorText := Format(ShowError::"Period Error") + SeparatorTok;
            if AnalysisFieldValue."Formula Error" then
                ErrorText := Format(ShowError::"Invalid Formula") + SeparatorTok;
            if AnalysisFieldValue."Cyclic Error" then
                ErrorText := Format(ShowError::"Cyclic Formula") + SeparatorTok;
            ErrorText := DelChr(ErrorText, '>', SeparatorTok);
        end;

        AnalysisFieldValue.SetRange("Row Ref. No.");
        AnalysisFieldValue.SetRange("Column No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcItemStatistics(var ItemStatisticsBuf: Record "Item Statistics Buffer"; var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; DrillDown: Boolean; var ColValue: Decimal);
    begin
    end;
}

