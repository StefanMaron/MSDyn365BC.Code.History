codeunit 9 "Acc. Sched. KPI Dimensions"
{
    TableNo = "Acc. Schedule Line";

    trigger OnRun()
    begin
    end;

    var
        IllegalValErr: Label 'You have entered an illegal value or a nonexistent row number.';
        GeneralErr: Label '%1\\ %2 %3 %4.', Locked = true;
        ErrorOccurredErr: Label 'The error occurred when the program tried to calculate:\';
        AccSchedLineErr: Label 'Acc. Sched. Line: Row No. = %1, Line No. = %2, Totaling = %3\', Comment = '%1 = Row No., %2= Line No., %3 = Totaling';
        ColumnErr: Label 'Acc. Sched. Column: Column No. = %1, Line No. = %2, Formula  = %3', Comment = '%1 = Column No., %2= Line No., %3 = Formula';
        CircularRefErr: Label 'Because of circular references, the program cannot calculate a formula.';
        AccSchedName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        TempAccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer" temporary;
        AccSchedManagement: Codeunit AccSchedManagement;
        StartDate: Date;
        EndDate: Date;
        CallLevel: Integer;
        CallingAccSchedLineID: Integer;
        CallingColumnLayoutID: Integer;

    procedure GetCellDataWithDimensions(var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var TempAccSchedKPIBuffer2: Record "Acc. Sched. KPI Buffer" temporary)
    var
        LastDataLineNo: Integer;
    begin
        with TempAccSchedKPIBuffer do begin
            Init;
            TransferFields(TempAccSchedKPIBuffer2, false);
            if not Insert() then
                Modify;
        end;

        TempAccSchedKPIBuffer2.Reset();
        if TempAccSchedKPIBuffer2.FindLast then;
        LastDataLineNo := TempAccSchedKPIBuffer2."No.";

        AccScheduleLine.CopyFilters(AccSchedLine);
        StartDate := AccScheduleLine.GetRangeMin("Date Filter");
        if EndDate <> AccScheduleLine.GetRangeMax("Date Filter") then
            EndDate := AccScheduleLine.GetRangeMax("Date Filter");

        CallLevel := 0;
        CallingAccSchedLineID := AccSchedLine."Line No.";
        CallingColumnLayoutID := ColumnLayout."Line No.";

        ColumnLayout.FindSet;
        repeat
            AddCellValueDimensions(AccSchedLine, ColumnLayout, TempAccSchedKPIBuffer2);
        until ColumnLayout.Next = 0;

        with TempAccSchedKPIBuffer2 do begin
            Reset;
            if FindLast then;
            if "No." = LastDataLineNo then begin
                Init;
                "No." += 1;
                Date := TempAccSchedKPIBuffer.Date;
                "Closed Period" := TempAccSchedKPIBuffer."Closed Period";
                "Account Schedule Name" := TempAccSchedKPIBuffer."Account Schedule Name";
                "KPI Code" := TempAccSchedKPIBuffer."KPI Code";
                "KPI Name" := TempAccSchedKPIBuffer."KPI Name";
                Insert;
            end;
        end;
    end;

    local procedure AddCellValueDimensions(AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer")
    var
        GLAcc: Record "G/L Account";
        CostType: Record "Cost Type";
        CFAccount: Record "Cash Flow Account";
        IsExpression: Boolean;
    begin
        if AccSchedLine.Totaling = '' then
            exit;

        if AccSchedName.Name <> AccSchedLine."Schedule Name" then
            AccSchedName.Get(AccSchedLine."Schedule Name");

        IsExpression :=
          AccSchedLine."Totaling Type" in
          [AccSchedLine."Totaling Type"::Formula, AccSchedLine."Totaling Type"::"Set Base For Percent"];

        if IsExpression then
            EvalExprWithDimensions(AccSchedLine.Totaling, AccSchedLine, ColumnLayout, AccSchedKPIBuffer)
        else begin
            if (StartDate = 0D) or (EndDate = 0D) or (EndDate = DMY2Date(31, 12, 9999)) then // Period Error
                exit;

            AccSchedManagement.SetStartDateEndDate(StartDate, EndDate);

            if AccSchedLine."Totaling Type" in
               [AccSchedLine."Totaling Type"::"Posting Accounts",
                AccSchedLine."Totaling Type"::"Total Accounts"]
            then begin
                AccSchedLine.CopyFilters(AccScheduleLine);
                AccSchedManagement.SetGLAccRowFilters(GLAcc, AccSchedLine);
                AccSchedManagement.SetGLAccColumnFilters(GLAcc, AccSchedLine, ColumnLayout);

                if (AccSchedLine."Totaling Type" = AccSchedLine."Totaling Type"::"Posting Accounts") and
                   (StrLen(AccSchedLine.Totaling) <= MaxStrLen(GLAcc.Totaling)) and (StrPos(AccSchedLine.Totaling, '*') = 0)
                then begin
                    GLAcc."Account Type" := GLAcc."Account Type"::Total;
                    GLAcc.Totaling := AccSchedLine.Totaling;
                    AddGLAccDimensions(GLAcc, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                end else
                    if GLAcc.Find('-') then
                        repeat
                            AddGLAccDimensions(GLAcc, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                        until GLAcc.Next = 0;
            end;

            if AccSchedLine."Totaling Type" in
               [AccSchedLine."Totaling Type"::"Cost Type",
                AccSchedLine."Totaling Type"::"Cost Type Total"]
            then begin
                AccSchedLine.CopyFilters(AccScheduleLine);
                AccSchedManagement.SetCostTypeRowFilters(CostType, AccSchedLine, ColumnLayout);
                AccSchedManagement.SetCostTypeColumnFilters(CostType, AccSchedLine, ColumnLayout);

                if (AccSchedLine."Totaling Type" = AccSchedLine."Totaling Type"::"Cost Type") and
                   (StrLen(AccSchedLine.Totaling) <= MaxStrLen(GLAcc.Totaling)) and (StrPos(AccSchedLine.Totaling, '*') = 0)
                then begin
                    CostType.Type := CostType.Type::Total;
                    CostType.Totaling := AccSchedLine.Totaling;
                    AddCostTypeDimensions(CostType, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                end else begin
                    if CostType.Find('-') then
                        repeat
                            AddCostTypeDimensions(CostType, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                        until CostType.Next = 0;
                end;
            end;

            if AccSchedLine."Totaling Type" in
               [AccSchedLine."Totaling Type"::"Cash Flow Entry Accounts",
                AccSchedLine."Totaling Type"::"Cash Flow Total Accounts"]
            then begin
                AccSchedLine.CopyFilters(AccScheduleLine);
                AccSchedManagement.SetCFAccRowFilter(CFAccount, AccSchedLine);
                AccSchedManagement.SetCFAccColumnFilter(CFAccount, AccSchedLine, ColumnLayout);
                if (AccSchedLine."Totaling Type" = AccSchedLine."Totaling Type"::"Cash Flow Entry Accounts") and
                   (StrLen(AccSchedLine.Totaling) <= 30)
                then begin
                    CFAccount."Account Type" := CFAccount."Account Type"::Total;
                    CFAccount.Totaling := AccSchedLine.Totaling;
                    AddCFAccountDimensions(CFAccount, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                end else
                    if CFAccount.Find('-') then
                        repeat
                            AddCFAccountDimensions(CFAccount, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                        until CFAccount.Next = 0;
            end;
        end;
    end;

    local procedure AddGLAccDimensions(var GLAcc: Record "G/L Account"; var AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer")
    var
        AnalysisViewEntry: Record "Analysis View Entry";
        GLEntryDimensions: Query "G/L Entry Dimensions";
        GLBudgetEntryDimensions: Query "G/L Budget Entry Dimensions";
        AnalysisViewEntryDimensions: Query "Analysis View Entry Dimensions";
        AnalysisViewBudgEntryDims: Query "Analysis View Budg. Entry Dims";
        "Filter": Text;
        AmountType: Option "Net Amount","Debit Amount","Credit Amount";
        AmountToAdd: Decimal;
    begin
        if ConflictAmountType(AccSchedLine, ColumnLayout."Amount Type", AmountType) then
            exit;

        case ColumnLayout."Ledger Entry Type" of
            ColumnLayout."Ledger Entry Type"::Entries:
                if AccSchedName."Analysis View Name" = '' then begin
                    GLEntryDimensions.SetFilter(Posting_Date, GLAcc.GetFilter("Date Filter"));
                    if GLAcc.Totaling = '' then
                        GLEntryDimensions.SetRange(G_L_Account_No, GLAcc."No.")
                    else
                        GLEntryDimensions.SetFilter(G_L_Account_No, GLAcc.Totaling);
                    GLEntryDimensions.SetFilter(
                      Business_Unit_Code, AccSchedLine.GetFilter("Business Unit Filter"));

                    Filter := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 1 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"), '&');
                    GLEntryDimensions.SetFilter(Global_Dimension_1_Code, Filter);

                    Filter := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 2 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"), '&');
                    GLEntryDimensions.SetFilter(Global_Dimension_2_Code, Filter);

                    GLEntryDimensions.Open;
                    while GLEntryDimensions.Read do begin
                        case AmountType of
                            AmountType::"Net Amount":
                                AmountToAdd := GLEntryDimensions.Sum_Amount;
                            AmountType::"Debit Amount":
                                AmountToAdd := GLEntryDimensions.Sum_Debit_Amount;
                            AmountType::"Credit Amount":
                                AmountToAdd := GLEntryDimensions.Sum_Credit_Amount;
                        end;
                        if PassToResult(AccSchedLine.Show, GLEntryDimensions.Sum_Amount) then
                            CheckAddDimsToResult(
                              AccSchedKPIBuffer, ColumnLayout, GLEntryDimensions.Dimension_Set_ID, AmountToAdd);
                    end;
                    GLEntryDimensions.Close;
                end else begin
                    if GLAcc.Totaling = '' then
                        Filter := GLAcc."No."
                    else
                        Filter := GLAcc.Totaling;

                    FilterAnalysisViewEntriesDim(
                      AnalysisViewEntryDimensions, AccSchedName."Analysis View Name",
                      AnalysisViewEntry."Account Source"::"G/L Account", Filter,
                      GLAcc.GetFilter("Date Filter"), AccSchedLine);

                    AnalysisViewEntryDimensions.Open;
                    while AnalysisViewEntryDimensions.Read do begin
                        case AmountType of
                            AmountType::"Net Amount":
                                AmountToAdd := AnalysisViewEntryDimensions.Sum_Amount;
                            AmountType::"Debit Amount":
                                AmountToAdd := AnalysisViewEntryDimensions.Sum_Debit_Amount;
                            AmountType::"Credit Amount":
                                AmountToAdd := AnalysisViewEntryDimensions.Sum_Credit_Amount;
                        end;
                        if PassToResult(AccSchedLine.Show, AnalysisViewEntryDimensions.Sum_Amount) then
                            CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd);
                    end;
                    AnalysisViewEntryDimensions.Close;
                end;
            ColumnLayout."Ledger Entry Type"::"Budget Entries":
                if AccSchedName."Analysis View Name" = '' then begin
                    GLBudgetEntryDimensions.SetFilter(Budget_Name, AccSchedLine.GetFilter("G/L Budget Filter"));
                    GLBudgetEntryDimensions.SetFilter(Date, GLAcc.GetFilter("Date Filter"));

                    if GLAcc.Totaling = '' then
                        GLBudgetEntryDimensions.SetRange(G_L_Account_No, GLAcc."No.")
                    else
                        GLBudgetEntryDimensions.SetFilter(G_L_Account_No, GLAcc.Totaling);
                    GLBudgetEntryDimensions.SetFilter(
                      Business_Unit_Code, AccSchedLine.GetFilter("Business Unit Filter"));

                    Filter := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 1 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"), '&');
                    GLBudgetEntryDimensions.SetFilter(Global_Dimension_1_Code, Filter);

                    Filter := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 2 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"), '&');
                    GLBudgetEntryDimensions.SetFilter(Global_Dimension_2_Code, Filter);

                    GLBudgetEntryDimensions.Open;
                    while GLBudgetEntryDimensions.Read do begin
                        case AmountType of
                            AmountType::"Net Amount":
                                AmountToAdd := GLBudgetEntryDimensions.Sum_Amount;
                            AmountType::"Debit Amount":
                                begin
                                    AmountToAdd := GLBudgetEntryDimensions.Sum_Amount;
                                    if AmountToAdd < 0 then
                                        AmountToAdd := 0;
                                end;
                            AmountType::"Credit Amount":
                                begin
                                    AmountToAdd := -GLBudgetEntryDimensions.Sum_Amount;
                                    if AmountToAdd < 0 then
                                        AmountToAdd := 0;
                                end;
                        end;
                        if PassToResult(AccSchedLine.Show, GLBudgetEntryDimensions.Sum_Amount) then
                            CheckAddDimsToResult(
                              AccSchedKPIBuffer, ColumnLayout, GLBudgetEntryDimensions.Dimension_Set_ID, AmountToAdd);
                    end;
                    GLBudgetEntryDimensions.Close;
                end else begin
                    if GLAcc.Totaling = '' then
                        AnalysisViewBudgEntryDims.SetRange(G_L_Account_No, GLAcc."No.")
                    else
                        AnalysisViewBudgEntryDims.SetFilter(G_L_Account_No, GLAcc.Totaling);
                    AnalysisViewBudgEntryDims.SetRange(Analysis_View_Code, AccSchedName."Analysis View Name");
                    AnalysisViewBudgEntryDims.SetFilter(Budget_Name, AccSchedLine.GetFilter("G/L Budget Filter"));
                    AnalysisViewBudgEntryDims.SetFilter(Posting_Date, GLAcc.GetFilter("Date Filter"));
                    AnalysisViewBudgEntryDims.SetFilter(
                      Business_Unit_Code, AccSchedLine.GetFilter("Business Unit Filter"));

                    Filter := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 1 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"), '&');
                    AnalysisViewBudgEntryDims.SetFilter(Dimension_1_Value_Code, Filter);

                    Filter := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 2 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"), '&');
                    AnalysisViewBudgEntryDims.SetFilter(Dimension_2_Value_Code, Filter);

                    Filter := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 3 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(3, AccSchedLine."Dimension 3 Totaling"), '&');
                    AnalysisViewBudgEntryDims.SetFilter(Dimension_3_Value_Code, Filter);

                    Filter := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 4 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(4, AccSchedLine."Dimension 4 Totaling"), '&');
                    AnalysisViewBudgEntryDims.SetFilter(Dimension_4_Value_Code, Filter);

                    AnalysisViewBudgEntryDims.Open;
                    while AnalysisViewBudgEntryDims.Read do begin
                        case AmountType of
                            AmountType::"Net Amount":
                                AmountToAdd := AnalysisViewBudgEntryDims.Sum_Amount;
                            AmountType::"Debit Amount":
                                begin
                                    AmountToAdd := AnalysisViewBudgEntryDims.Sum_Amount;
                                    if AmountToAdd < 0 then
                                        AmountToAdd := 0;
                                end;
                            AmountType::"Credit Amount":
                                begin
                                    AmountToAdd := -AnalysisViewBudgEntryDims.Sum_Amount;
                                    if AmountToAdd < 0 then
                                        AmountToAdd := 0;
                                end;
                        end;
                        if PassToResult(AccSchedLine.Show, AnalysisViewBudgEntryDims.Sum_Amount) then
                            CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd);
                    end;
                    AnalysisViewBudgEntryDims.Close;
                end;
        end;
    end;

    local procedure AddCostTypeDimensions(var CostType: Record "Cost Type"; var AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer")
    var
        CostEntry: Record "Cost Entry";
        CostBudgetEntry: Record "Cost Budget Entry";
        AmountType: Option "Net Amount","Debit Amount","Credit Amount";
        TestBalance: Boolean;
        Balance: Decimal;
        AmountToAdd: Decimal;
    begin
        if ConflictAmountType(AccSchedLine, ColumnLayout."Amount Type", AmountType) then
            exit;

        TestBalance := AccSchedLine.Show in
          [AccSchedLine.Show::"When Negative Balance", AccSchedLine.Show::"When Positive Balance"];
        if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::Entries then begin
            with CostEntry do begin
                if CostType.Totaling = '' then
                    SetRange("Cost Type No.", CostType."No.")
                else
                    SetFilter("Cost Type No.", CostType.Totaling);
                CostType.CopyFilter("Date Filter", "Posting Date");
                AccSchedLine.CopyFilter("Cost Center Filter", "Cost Center Code");
                AccSchedLine.CopyFilter("Cost Object Filter", "Cost Object Code");
                FilterGroup(2);
                SetFilter(
                  "Cost Center Code",
                  AccSchedManagement.GetDimTotalingFilter(5, AccSchedLine."Cost Center Totaling"));
                SetFilter(
                  "Cost Object Code",
                  AccSchedManagement.GetDimTotalingFilter(6, AccSchedLine."Cost Object Totaling"));
                FilterGroup(0);
            end;

            case AmountType of
                AmountType::"Net Amount":
                    begin
                        CostEntry.CalcSums(Amount);
                        AmountToAdd := CostEntry.Amount;
                        Balance := AmountToAdd;
                    end;
                AmountType::"Debit Amount":
                    begin
                        if TestBalance then begin
                            CostEntry.CalcSums("Debit Amount", Amount);
                            Balance := CostEntry.Amount;
                        end else
                            CostEntry.CalcSums("Debit Amount");
                        AmountToAdd := CostEntry."Debit Amount";
                    end;
                AmountType::"Credit Amount":
                    begin
                        if TestBalance then begin
                            CostEntry.CalcSums("Credit Amount", Amount);
                            Balance := CostEntry.Amount;
                        end else
                            CostEntry.CalcSums("Credit Amount");
                        AmountToAdd := CostEntry."Credit Amount";
                    end;
            end;
            if not TestBalance then
                CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd)
            else
                if PassToResult(AccSchedLine.Show, Balance) then
                    CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd);
        end;

        if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::"Budget Entries" then begin
            with CostBudgetEntry do begin
                SetCurrentKey("Budget Name", "Cost Type No.", "Cost Center Code", "Cost Object Code", Date);
                if CostType.Totaling = '' then
                    SetRange("Cost Type No.", CostType."No.")
                else
                    SetFilter("Cost Type No.", CostType.Totaling);
                CostType.CopyFilter("Date Filter", Date);
                AccSchedLine.CopyFilter("Cost Budget Filter", "Budget Name");
                AccSchedLine.CopyFilter("Cost Center Filter", "Cost Center Code");
                AccSchedLine.CopyFilter("Cost Object Filter", "Cost Object Code");
                FilterGroup(2);
                SetFilter(
                  "Cost Center Code",
                  AccSchedManagement.GetDimTotalingFilter(5, AccSchedLine."Cost Center Totaling"));
                SetFilter(
                  "Cost Object Code",
                  AccSchedManagement.GetDimTotalingFilter(6, AccSchedLine."Cost Object Totaling"));
                FilterGroup(0);
            end;

            CostBudgetEntry.CalcSums(Amount);
            case AmountType of
                AmountType::"Net Amount":
                    AmountToAdd := CostBudgetEntry.Amount;
                AmountType::"Debit Amount":
                    if CostBudgetEntry.Amount > 0 then
                        AmountToAdd := CostBudgetEntry.Amount;
                AmountType::"Credit Amount":
                    if CostBudgetEntry.Amount < 0 then
                        AmountToAdd := CostBudgetEntry.Amount;
            end;
            if not TestBalance then
                CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd)
            else
                if PassToResult(AccSchedLine.Show, CostBudgetEntry.Amount) then
                    CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd);
        end;
    end;

    local procedure AddCFAccountDimensions(var CFAccount: Record "Cash Flow Account"; var AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer")
    var
        AnalysisViewEntry: Record "Analysis View Entry";
        CFForecastEntryDimensions: Query "CF Forecast Entry Dimensions";
        AnalysisViewEntryDimensions: Query "Analysis View Entry Dimensions";
        "Filter": Text;
        AmountType: Option "Net Amount","Debit Amount","Credit Amount";
        AmountToAdd: Decimal;
    begin
        if ConflictAmountType(AccSchedLine, ColumnLayout."Amount Type", AmountType) then
            exit;

        if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::Entries then
            if AccSchedName."Analysis View Name" = '' then begin
                if CFAccount.Totaling = '' then
                    CFForecastEntryDimensions.SetRange(Cash_Flow_Account_No, CFAccount."No.")
                else
                    CFForecastEntryDimensions.SetFilter(Cash_Flow_Account_No, CFAccount.Totaling);

                CFForecastEntryDimensions.SetFilter(Cash_Flow_Date, CFAccount.GetFilter("Date Filter"));
                CFForecastEntryDimensions.SetFilter(
                  Cash_Flow_Forecast_No, AccSchedLine.GetFilter("Cash Flow Forecast Filter"));

                Filter := CombineFilters(
                    AccSchedLine.GetFilter("Dimension 1 Filter"), AccSchedLine."Dimension 1 Totaling", '&');
                CFForecastEntryDimensions.SetFilter(Global_Dimension_1_Code, Filter);

                Filter := CombineFilters(
                    AccSchedLine.GetFilter("Dimension 2 Filter"), AccSchedLine."Dimension 2 Totaling", '&');
                CFForecastEntryDimensions.SetFilter(Global_Dimension_2_Code, Filter);

                CFForecastEntryDimensions.Open;
                while CFForecastEntryDimensions.Read do begin
                    if AmountType = AmountType::"Net Amount" then
                        AmountToAdd := CFForecastEntryDimensions.Sum_Amount_LCY
                    else
                        AmountToAdd := 0;
                    CheckAddDimsToResult(
                      AccSchedKPIBuffer, ColumnLayout, CFForecastEntryDimensions.Dimension_Set_ID,
                      AmountToAdd);
                end;
                CFForecastEntryDimensions.Close;
            end else begin
                if CFAccount.Totaling = '' then
                    Filter := CFAccount."No."
                else
                    Filter := CFAccount.Totaling;

                FilterAnalysisViewEntriesDim(
                  AnalysisViewEntryDimensions, AccSchedName."Analysis View Name",
                  AnalysisViewEntry."Account Source"::"Cash Flow Account", Filter,
                  CFAccount.GetFilter("Date Filter"), AccSchedLine);
                AnalysisViewEntryDimensions.SetFilter(
                  Cash_Flow_Forecast_No, AccSchedLine.GetFilter("Cash Flow Forecast Filter"));

                AnalysisViewEntryDimensions.Open;
                while AnalysisViewEntryDimensions.Read do begin
                    if AmountType = AmountType::"Net Amount" then
                        AmountToAdd := AnalysisViewEntryDimensions.Sum_Amount
                    else
                        AmountToAdd := 0;
                    CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd);
                end;
                AnalysisViewEntryDimensions.Close;
            end;
    end;

    local procedure EvalExprWithDimensions(Expression: Text[250]; AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer")
    var
        TempAccSchedKPIBufferDim: Record "Acc. Sched. KPI Buffer" temporary;
        SrcAccSchedLineFilter: Text;
        Value: Decimal;
    begin
        SrcAccSchedLineFilter := GetAccSchedLineFormulaFilter(Expression, AccSchedLine);
        GetExpressionDimensions(AccSchedKPIBuffer, TempAccSchedKPIBufferDim, SrcAccSchedLineFilter);
        with TempAccSchedKPIBufferDim do
            if FindSet then
                repeat
                    Value :=
                      EvalExprWithDimFilter("Dimension Set ID", Expression, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                    CheckAddDimsToResult(
                      AccSchedKPIBuffer, ColumnLayout, "Dimension Set ID", Value);
                until Next = 0;
    end;

    local procedure GetExpressionDimensions(var TempAccSchedKPIBufferExisting: Record "Acc. Sched. KPI Buffer" temporary; var TempAccSchedKPIBufferResulting: Record "Acc. Sched. KPI Buffer" temporary; LineFilter: Text)
    begin
        with TempAccSchedKPIBufferExisting do begin
            SetFilter("KPI Code", LineFilter);
            if FindSet then
                repeat
                    if ("Net Change Actual" <> 0) or ("Balance at Date Actual" <> 0) or
                       ("Net Change Budget" <> 0) or ("Balance at Date Budget" <> 0) or
                       ("Net Change Actual Last Year" <> 0) or ("Balance at Date Act. Last Year" <> 0) or
                       ("Net Change Budget Last Year" <> 0) or ("Balance at Date Bud. Last Year" <> 0)
                    then
                        AddDimsToBuffer(TempAccSchedKPIBufferResulting, "Dimension Set ID")
                until Next = 0;
            SetRange("KPI Code");
        end;
    end;

    local procedure GetCellValueWithDimFilter(var TempAccSchedKPIBufferExisting: Record "Acc. Sched. KPI Buffer" temporary; AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; DimSetID: Integer) Result: Decimal
    begin
        with TempAccSchedKPIBufferExisting do begin
            SetRange("Account Schedule Name", AccSchedLine."Schedule Name");
            SetRange("KPI Code", AccSchedLine."Row No.");
            SetRange("Dimension Set ID", DimSetID);
            if FindFirst then
                Result := GetColumnValue(ColumnLayout);

            SetRange("Account Schedule Name");
            SetRange("KPI Code");
            SetRange("Dimension Set ID");
        end;
    end;

    local procedure GetAccSchedLineFormulaFilter(Expression: Text; AccSchedLine: Record "Acc. Schedule Line") ResultingFilter: Text
    var
        FilterPart: Text;
        i: Integer;
        j: Integer;
        IsFilter: Boolean;
        FoundFilterPart: Boolean;
    begin
        Expression := DelChr(Expression, '<>', ' ');
        if StrLen(Expression) > 0 then begin
            Expression := ConvertStr(Expression, '+-*/^%()', ';;;;;;;;');
            i := StrLen(Expression);
            while i > 0 do begin
                if Expression[i] <> ';' then begin
                    FoundFilterPart := false;
                    j := i - 1;
                    repeat
                        if j = 0 then
                            FoundFilterPart := true;
                        if not FoundFilterPart then
                            FoundFilterPart := Expression[j] = ';';

                        if FoundFilterPart then begin
                            FilterPart := CopyStr(Expression, j + 1, i - j);
                            AccSchedLine.SetRange("Schedule Name", AccSchedLine."Schedule Name");
                            AccSchedLine.SetFilter("Row No.", FilterPart);
                            IsFilter :=
                              (StrPos(FilterPart, '..') +
                               StrPos(FilterPart, '|') +
                               StrPos(FilterPart, '<') +
                               StrPos(FilterPart, '>') +
                               StrPos(FilterPart, '&') +
                               StrPos(FilterPart, '=') > 0);
                            if (StrLen(FilterPart) <= 10) or IsFilter then
                                if AccSchedLine.FindFirst then
                                    ResultingFilter := CombineFilters(ResultingFilter, FilterPart, '|');
                            i := j;
                        end else
                            j -= 1;
                    until FoundFilterPart;
                end;
                i -= 1;
            end;
        end;
    end;

    local procedure EvalExprWithDimFilter(DimSetID: Integer; Expression: Text[250]; AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var ExistingAccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer"): Decimal
    var
        Result: Decimal;
        Parantheses: Integer;
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
        AccSchedLineID: Integer;
    begin
        Result := 0;

        CallLevel := CallLevel + 1;
        if CallLevel > 25 then
            ShowError(CircularRefErr, AccSchedLine, ColumnLayout);

        Expression := DelChr(Expression, '<>', ' ');
        if StrLen(Expression) > 0 then begin
            Parantheses := 0;
            IsExpression := false;
            Operators := '+-*/^%';
            OperatorNo := 1;
            repeat
                i := StrLen(Expression);
                repeat
                    if Expression[i] = '(' then
                        Parantheses := Parantheses + 1
                    else
                        if Expression[i] = ')' then
                            Parantheses := Parantheses - 1;
                    if (Parantheses = 0) and (Expression[i] = Operators[OperatorNo]) then
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
                  EvalExprWithDimFilter(
                    DimSetID, LeftOperand, AccSchedLine, ColumnLayout, ExistingAccSchedKPIBuffer);
                RightResult :=
                  EvalExprWithDimFilter(
                    DimSetID, RightOperand, AccSchedLine, ColumnLayout, ExistingAccSchedKPIBuffer);
                case Operator of
                    '^':
                        Result := Power(LeftResult, RightResult);
                    '%':
                        if RightResult = 0 then // Division Error
                            Result := 0
                        else
                            Result := 100 * LeftResult / RightResult;
                    '*':
                        Result := LeftResult * RightResult;
                    '/':
                        if RightResult = 0 then // Division Error
                            Result := 0
                        else
                            Result := LeftResult / RightResult;
                    '+':
                        Result := LeftResult + RightResult;
                    '-':
                        Result := LeftResult - RightResult;
                end;
            end else
                if (Expression[1] = '(') and (Expression[StrLen(Expression)] = ')') then
                    Result :=
                      EvalExprWithDimFilter(
                        DimSetID, CopyStr(Expression, 2, StrLen(Expression) - 2),
                        AccSchedLine, ColumnLayout, ExistingAccSchedKPIBuffer)
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
                    else begin
                        AccSchedLine.SetRange("Schedule Name", AccSchedLine."Schedule Name");
                        AccSchedLine.SetFilter("Row No.", Expression);
                        AccSchedLineID := AccSchedLine."Line No.";
                        if AccSchedLine.Find('-') then
                            repeat
                                if AccSchedLine."Line No." <> AccSchedLineID then
                                    Result +=
                                      GetCellValueWithDimFilter(ExistingAccSchedKPIBuffer, AccSchedLine, ColumnLayout, DimSetID);
                            until AccSchedLine.Next = 0
                        else
                            if IsFilter or (not Evaluate(Result, Expression)) then
                                ShowError(IllegalValErr, AccSchedLine, ColumnLayout);
                    end;
                end;
        end;
        CallLevel := CallLevel - 1;
        exit(Result);
    end;

    local procedure ShowError(MessageLine: Text[100]; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
        AccSchedLine.SetRange("Schedule Name", AccSchedLine."Schedule Name");
        AccSchedLine.SetRange("Line No.", CallingAccSchedLineID);
        if AccSchedLine.FindFirst then;
        ColumnLayout.SetRange("Column Layout Name", ColumnLayout."Column Layout Name");
        ColumnLayout.SetRange("Line No.", CallingColumnLayoutID);
        if ColumnLayout.FindFirst then;
        Error(GeneralErr,
          MessageLine,
          ErrorOccurredErr,
          StrSubstNo(AccSchedLineErr, AccSchedLine."Row No.", AccSchedLine."Line No.", AccSchedLine.Totaling),
          StrSubstNo(ColumnErr, ColumnLayout."Column No.", ColumnLayout."Line No.", ColumnLayout.Formula));
    end;

    local procedure ConflictAmountType(AccSchedLine: Record "Acc. Schedule Line"; ColumnLayoutAmtType: Option "Net Amount","Debit Amount","Credit Amount"; var AmountType: Option): Boolean
    begin
        if (ColumnLayoutAmtType = AccSchedLine."Amount Type") or
           (AccSchedLine."Amount Type" = AccSchedLine."Amount Type"::"Net Amount")
        then
            AmountType := ColumnLayoutAmtType
        else
            if ColumnLayoutAmtType = ColumnLayoutAmtType::"Net Amount" then
                AmountType := AccSchedLine."Amount Type"
            else
                exit(true);
        exit(false);
    end;

    local procedure CombineFilters(FilterPart1: Text; FilterPart2: Text; CombineSymbol: Text[1]): Text
    begin
        PrepareFilterPart(FilterPart1);
        PrepareFilterPart(FilterPart2);

        if (FilterPart1 <> '') and (FilterPart2 <> '') then
            exit(StrSubstNo('%1%2%3', FilterPart1, CombineSymbol, FilterPart2));

        if FilterPart1 <> '' then
            exit(FilterPart1);

        if FilterPart2 <> '' then
            exit(FilterPart2);

        exit('');
    end;

    local procedure PrepareFilterPart(var FilterText: Text)
    begin
        FilterText := DelChr(FilterText, '<>', ' ');
        if FilterText <> '' then
            if (FilterText[1] <> '(') and (FilterText[StrLen(FilterText)] <> ')') then
                FilterText := StrSubstNo('(%1)', FilterText);
    end;

    local procedure CheckAddDimsToResult(var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer"; ColumnLayout: Record "Column Layout"; DimensionSetID: Integer; Amount: Decimal)
    begin
        if Amount = 0 then
            exit;

        with AccSchedKPIBuffer do begin
            SetRange("Account Schedule Name", TempAccSchedKPIBuffer."Account Schedule Name");
            SetRange("KPI Code", TempAccSchedKPIBuffer."KPI Code");
            SetRange("Dimension Set ID", DimensionSetID);
            if not FindFirst then begin
                Reset;
                if FindLast then;
                Init;
                "No." += 1;
                Date := TempAccSchedKPIBuffer.Date;
                "Closed Period" := TempAccSchedKPIBuffer."Closed Period";
                "Account Schedule Name" := TempAccSchedKPIBuffer."Account Schedule Name";
                "KPI Code" := TempAccSchedKPIBuffer."KPI Code";
                "KPI Name" := TempAccSchedKPIBuffer."KPI Name";
                "Dimension Set ID" := DimensionSetID;
                AddColumnValue(ColumnLayout, Amount);
                Insert;
            end else begin
                AddColumnValue(ColumnLayout, Amount);
                Modify;
            end;
        end;
    end;

    local procedure AddDimsToBuffer(var TempAccSchedKPIBufferResulting: Record "Acc. Sched. KPI Buffer" temporary; DimensionSetID: Integer)
    begin
        with TempAccSchedKPIBufferResulting do begin
            SetRange("Dimension Set ID", DimensionSetID);
            if not FindFirst then begin
                Reset;
                if FindLast then;
                "No." += 1;
                "Dimension Set ID" := DimensionSetID;
                Insert;
            end;
            SetRange("Dimension Set ID");
        end;
    end;

    procedure PostProcessAmount(AccSchedLine: Record "Acc. Schedule Line"; Amount: Decimal): Decimal
    begin
        if AccSchedLine."Show Opposite Sign" then
            exit(-Amount);
        exit(Amount);
    end;

    local procedure PassToResult(AccSchedLineShow: Option; Balance: Decimal) BalanceIsOK: Boolean
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        case AccSchedLineShow of
            AccScheduleLine.Show::"When Positive Balance":
                if Balance > 0 then
                    BalanceIsOK := true
                else
                    BalanceIsOK := false;
            AccScheduleLine.Show::"When Negative Balance":
                if Balance < 0 then
                    BalanceIsOK := true
                else
                    BalanceIsOK := false;
            else
                BalanceIsOK := true;
        end;
        exit(BalanceIsOK);
    end;

    local procedure FilterAnalysisViewEntriesDim(var AnalysisViewEntryDimensions: Query "Analysis View Entry Dimensions"; AnalysisViewName: Code[10]; AccountSource: Option; AccountFilter: Text; DateFilter: Text; AccScheduleLine2: Record "Acc. Schedule Line")
    begin
        with AnalysisViewEntryDimensions do begin
            SetRange(Analysis_View_Code, AnalysisViewName);
            SetRange(Account_Source, AccountSource);
            SetFilter(Account_No, AccountFilter);
            SetFilter(Business_Unit_Code, AccScheduleLine2.GetFilter("Business Unit Filter"));
            SetFilter(Posting_Date, DateFilter);

            SetFilter(Dimension_1_Value_Code,
              CombineFilters(
                AccScheduleLine2.GetFilter("Dimension 1 Filter"),
                AccSchedManagement.GetDimTotalingFilter(1, AccScheduleLine2."Dimension 1 Totaling"), '&'));
            SetFilter(Dimension_2_Value_Code,
              CombineFilters(
                AccScheduleLine2.GetFilter("Dimension 2 Filter"),
                AccSchedManagement.GetDimTotalingFilter(2, AccScheduleLine2."Dimension 2 Totaling"), '&'));
            SetFilter(Dimension_3_Value_Code,
              CombineFilters(
                AccScheduleLine2.GetFilter("Dimension 3 Filter"),
                AccSchedManagement.GetDimTotalingFilter(3, AccScheduleLine2."Dimension 3 Totaling"), '&'));
            SetFilter(Dimension_4_Value_Code,
              CombineFilters(
                AccScheduleLine2.GetFilter("Dimension 4 Filter"),
                AccSchedManagement.GetDimTotalingFilter(4, AccScheduleLine2."Dimension 4 Totaling"), '&'));
        end;
    end;
}

