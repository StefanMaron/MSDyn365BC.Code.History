codeunit 7153 "Item Analysis Management"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Period';
        Text001: Label '<Sign><Integer Thousand><Decimals,2>, Locked = true';
        Text003: Label '%1 is not a valid line definition.';
        Text004: Label '%1 is not a valid column definition.';
        Text005: Label '1,6,,Dimension 1 Filter';
        Text006: Label '1,6,,Dimension 2 Filter';
        Text007: Label '1,6,,Dimension 3 Filter';
        Text008: Label 'DEFAULT';
        Text009: Label 'Default analysis view';
        PrevItemAnalysisView: Record "Item Analysis View";
        MatrixMgt: Codeunit "Matrix Management";

    local procedure DimCodeNotAllowed(DimCode: Text[30]; ItemAnalysisView: Record "Item Analysis View"): Boolean
    var
        Item: Record Item;
        Location: Record Location;
    begin
        exit(
          not (UpperCase(DimCode) in
               [UpperCase(Item.TableCaption),
                UpperCase(Location.TableCaption),
                UpperCase(Text000),
                ItemAnalysisView."Dimension 1 Code",
                ItemAnalysisView."Dimension 2 Code",
                ItemAnalysisView."Dimension 3 Code",
                '']));
    end;

    local procedure DimCodeToOption(DimCode: Text[30]; ItemAnalysisView: Record "Item Analysis View"): Integer
    var
        Location: Record Location;
        Item: Record Item;
    begin
        case DimCode of
            Item.TableCaption:
                exit(0);
            Text000:
                exit(1);
            Location.TableCaption:
                exit(2);
            ItemAnalysisView."Dimension 1 Code":
                exit(3);
            ItemAnalysisView."Dimension 2 Code":
                exit(4);
            ItemAnalysisView."Dimension 3 Code":
                exit(5);
            else
                exit(-1);
        end;
    end;

    local procedure CopyItemToBuf(var Item: Record Item; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        with DimCodeBuf do begin
            Init;
            Code := Item."No.";
            Name := Item.Description;
        end;
    end;

    local procedure CopyPeriodToBuf(var Period: Record Date; var DimCodeBuf: Record "Dimension Code Buffer"; DateFilter: Text[30])
    var
        Period2: Record Date;
    begin
        with DimCodeBuf do begin
            Init;
            Code := Format(Period."Period Start");
            "Period Start" := Period."Period Start";
            "Period End" := Period."Period End";
            if DateFilter <> '' then begin
                Period2.SetFilter("Period End", DateFilter);
                if Period2.GetRangeMax("Period End") < "Period End" then
                    "Period End" := Period2.GetRangeMax("Period End");
            end;
            Name := Period."Period Name";
        end;
    end;

    local procedure CopyLocationToBuf(var Location: Record Location; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        with DimCodeBuf do begin
            Init;
            Code := Location.Code;
            Name := Location.Name;
        end;
    end;

    local procedure CopyDimValueToBuf(var DimVal: Record "Dimension Value"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        with DimCodeBuf do begin
            Init;
            Code := DimVal.Code;
            Name := DimVal.Name;
            Totaling := DimVal.Totaling;
            Indentation := DimVal.Indentation;
            "Show in Bold" :=
              DimVal."Dimension Value Type" <> DimVal."Dimension Value Type"::Standard;
        end;
    end;

    local procedure FilterItemAnalyViewEntry(var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var ItemAnalysisViewEntry: Record "Item Analysis View Entry")
    begin
        with ItemStatisticsBuffer do begin
            CopyFilter("Analysis Area Filter", ItemAnalysisViewEntry."Analysis Area");
            CopyFilter("Analysis View Filter", ItemAnalysisViewEntry."Analysis View Code");

            if GetFilter("Item Filter") <> '' then
                CopyFilter("Item Filter", ItemAnalysisViewEntry."Item No.");

            if GetFilter("Date Filter") <> '' then
                CopyFilter("Date Filter", ItemAnalysisViewEntry."Posting Date");

            if GetFilter("Location Filter") <> '' then
                CopyFilter("Location Filter", ItemAnalysisViewEntry."Location Code");

            if GetFilter("Dimension 1 Filter") <> '' then
                CopyFilter("Dimension 1 Filter", ItemAnalysisViewEntry."Dimension 1 Value Code");

            if GetFilter("Dimension 2 Filter") <> '' then
                CopyFilter("Dimension 2 Filter", ItemAnalysisViewEntry."Dimension 2 Value Code");

            if GetFilter("Dimension 3 Filter") <> '' then
                CopyFilter("Dimension 3 Filter", ItemAnalysisViewEntry."Dimension 3 Value Code");
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

            if GetFilter("Location Filter") <> '' then
                CopyFilter("Location Filter", ItemAnalysisViewBudgEntry."Location Code");

            if GetFilter("Date Filter") <> '' then
                CopyFilter("Date Filter", ItemAnalysisViewBudgEntry."Posting Date");

            if GetFilter("Dimension 1 Filter") <> '' then
                CopyFilter("Dimension 1 Filter", ItemAnalysisViewBudgEntry."Dimension 1 Value Code");

            if GetFilter("Dimension 2 Filter") <> '' then
                CopyFilter("Dimension 2 Filter", ItemAnalysisViewBudgEntry."Dimension 2 Value Code");

            if GetFilter("Dimension 3 Filter") <> '' then
                CopyFilter("Dimension 3 Filter", ItemAnalysisViewBudgEntry."Dimension 3 Value Code");
        end;
    end;

    local procedure SetDimFilters(var ItemStatisticsBuffer: Record "Item Statistics Buffer"; DimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; DimCodeBuf: Record "Dimension Code Buffer")
    begin
        with ItemStatisticsBuffer do
            case DimOption of
                DimOption::Item:
                    SetRange("Item Filter", DimCodeBuf.Code);
                DimOption::Period:
                    SetRange("Date Filter", DimCodeBuf."Period Start", DimCodeBuf."Period End");
                DimOption::Location:
                    SetRange("Location Filter", DimCodeBuf.Code);
                DimOption::"Dimension 1":
                    if DimCodeBuf.Totaling <> '' then
                        SetFilter("Dimension 1 Filter", DimCodeBuf.Totaling)
                    else
                        SetRange("Dimension 1 Filter", DimCodeBuf.Code);
                DimOption::"Dimension 2":
                    if DimCodeBuf.Totaling <> '' then
                        SetFilter("Dimension 2 Filter", DimCodeBuf.Totaling)
                    else
                        SetRange("Dimension 2 Filter", DimCodeBuf.Code);
                DimOption::"Dimension 3":
                    if DimCodeBuf.Totaling <> '' then
                        SetFilter("Dimension 3 Filter", DimCodeBuf.Totaling)
                    else
                        SetRange("Dimension 3 Filter", DimCodeBuf.Code);
            end;
    end;

    procedure SetCommonFilters(CurrentAnalysisArea: Option; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentAnalysisViewCode: Code[10]; ItemFilter: Text; LocationFilter: Text; DateFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; BudgetFilter: Text)
    begin
        with ItemStatisticsBuffer do begin
            Reset;
            SetRange("Analysis Area Filter", CurrentAnalysisArea);
            SetRange("Analysis View Filter", CurrentAnalysisViewCode);

            if ItemFilter <> '' then
                SetFilter("Item Filter", ItemFilter);
            if LocationFilter <> '' then
                SetFilter("Location Filter", LocationFilter);
            if DateFilter <> '' then
                SetFilter("Date Filter", DateFilter);
            if Dim1Filter <> '' then
                SetFilter("Dimension 1 Filter", Dim1Filter);
            if Dim2Filter <> '' then
                SetFilter("Dimension 2 Filter", Dim2Filter);
            if Dim3Filter <> '' then
                SetFilter("Dimension 3 Filter", Dim3Filter);
            if BudgetFilter <> '' then
                SetFilter("Budget Filter", BudgetFilter);
        end;
    end;

    procedure AnalysisViewSelection(CurrentAnalysisArea: Option; var CurrentItemAnalysisViewCode: Code[10]; var ItemAnalysisView: Record "Item Analysis View"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var Dim1Filter: Code[250]; var Dim2Filter: Code[250]; var Dim3Filter: Code[250])
    begin
        if not ItemAnalysisView.Get(CurrentAnalysisArea, CurrentItemAnalysisViewCode) then begin
            ItemAnalysisView.FilterGroup := 2;
            ItemAnalysisView.SetRange("Analysis Area", CurrentAnalysisArea);
            ItemAnalysisView.FilterGroup := 0;
            if not ItemAnalysisView.Find('-') then begin
                ItemAnalysisView.Init();
                ItemAnalysisView."Analysis Area" := CurrentAnalysisArea;
                ItemAnalysisView.Code := Text008;
                ItemAnalysisView.Name := Text009;
                ItemAnalysisView.Insert(true);
            end;
            CurrentItemAnalysisViewCode := ItemAnalysisView.Code;
        end;

        SetItemAnalysisView(
          CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
          Dim1Filter, Dim2Filter, Dim3Filter);
    end;

    procedure CheckAnalysisView(CurrentAnalysisArea: Option; CurrentItemAnalysisViewCode: Code[10]; var ItemAnalysisView: Record "Item Analysis View")
    begin
        ItemAnalysisView.Get(CurrentAnalysisArea, CurrentItemAnalysisViewCode);
    end;

    procedure SetItemAnalysisView(CurrentAnalysisArea: Option; CurrentItemAnalysisViewCode: Code[10]; var ItemAnalysisView: Record "Item Analysis View"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var Dim1Filter: Code[250]; var Dim2Filter: Code[250]; var Dim3Filter: Code[250])
    begin
        ItemStatisticsBuffer.SetRange("Analysis Area Filter", CurrentAnalysisArea);
        ItemStatisticsBuffer.SetRange("Analysis View Filter", CurrentItemAnalysisViewCode);

        if PrevItemAnalysisView.Code <> '' then begin
            if ItemAnalysisView."Dimension 1 Code" <> PrevItemAnalysisView."Dimension 1 Code" then
                Dim1Filter := '';
            if ItemAnalysisView."Dimension 2 Code" <> PrevItemAnalysisView."Dimension 2 Code" then
                Dim2Filter := '';
            if ItemAnalysisView."Dimension 3 Code" <> PrevItemAnalysisView."Dimension 3 Code" then
                Dim3Filter := '';
        end;
        ItemStatisticsBuffer.SetFilter("Dimension 1 Filter", Dim1Filter);
        ItemStatisticsBuffer.SetFilter("Dimension 2 Filter", Dim2Filter);
        ItemStatisticsBuffer.SetFilter("Dimension 3 Filter", Dim3Filter);

        PrevItemAnalysisView := ItemAnalysisView;
    end;

    procedure LookupItemAnalysisView(CurrentAnalysisArea: Option; var CurrentItemAnalysisViewCode: Code[10]; var ItemAnalysisView: Record "Item Analysis View"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var Dim1Filter: Code[250]; var Dim2Filter: Code[250]; var Dim3Filter: Code[250])
    var
        ItemAnalysisView2: Record "Item Analysis View";
    begin
        ItemAnalysisView2.Copy(ItemAnalysisView);
        ItemAnalysisView2.FilterGroup := 2;
        ItemAnalysisView2.SetRange("Analysis Area", CurrentAnalysisArea);
        ItemAnalysisView2.FilterGroup := 0;
        if PAGE.RunModal(0, ItemAnalysisView2) = ACTION::LookupOK then begin
            ItemAnalysisView := ItemAnalysisView2;
            CurrentItemAnalysisViewCode := ItemAnalysisView.Code;
            SetItemAnalysisView(
              CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
              Dim1Filter, Dim2Filter, Dim3Filter);
        end else
            AnalysisViewSelection(
              CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
              Dim1Filter, Dim2Filter, Dim3Filter);
    end;

    procedure LookUpCode(DimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; DimCode: Text[30]; "Code": Text[30])
    var
        Item: Record Item;
        Location: Record Location;
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        case DimOption of
            DimOption::Item:
                begin
                    Item.Get(Code);
                    PAGE.RunModal(0, Item);
                end;
            DimOption::Period:
                ;
            DimOption::Location:
                begin
                    Location.Get(Code);
                    PAGE.RunModal(0, Location);
                end;
            DimOption::"Dimension 1",
            DimOption::"Dimension 2",
            DimOption::"Dimension 3":
                begin
                    DimVal.SetRange("Dimension Code", DimCode);
                    DimVal.Get(DimCode, Code);
                    Clear(DimValList);
                    DimValList.SetTableView(DimVal);
                    DimValList.SetRecord(DimVal);
                    DimValList.RunModal;
                end;
        end;
    end;

    procedure LookUpDimFilter(Dim: Code[20]; var Text: Text): Boolean
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        if Dim = '' then
            exit(false);
        DimValList.LookupMode(true);
        DimVal.SetRange("Dimension Code", Dim);
        DimValList.SetTableView(DimVal);
        if DimValList.RunModal = ACTION::LookupOK then begin
            DimValList.GetRecord(DimVal);
            Text := DimValList.GetSelectionFilter;
            exit(true);
        end;
    end;

    procedure DrillDown(CurrentAnalysisArea: Option; ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentItemAnalysisViewCode: Code[10]; ItemFilter: Text; LocationFilter: Text; DateFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; BudgetFilter: Text; LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; LineDimCodeBuf: Record "Dimension Code Buffer"; ColDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; ColDimCodeBuf: Record "Dimension Code Buffer"; SetColumnFilter: Boolean; ValueType: Option "Sales Amount","Cost Amount","Sales Quantity"; ShowActualBudget: Option "Actual Amounts","Budgeted Amounts",Variance,"Variance%","Index%")
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        ItemAnalysisViewBudgetEntry: Record "Item Analysis View Budg. Entry";
    begin
        SetCommonFilters(
          CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
          ItemFilter, LocationFilter, DateFilter, Dim1Filter, Dim2Filter, Dim3Filter, BudgetFilter);
        SetDimFilters(ItemStatisticsBuffer, LineDimOption, LineDimCodeBuf);
        if SetColumnFilter then
            SetDimFilters(ItemStatisticsBuffer, ColDimOption, ColDimCodeBuf);

        case ShowActualBudget of
            ShowActualBudget::"Actual Amounts",
            ShowActualBudget::Variance,
            ShowActualBudget::"Variance%",
            ShowActualBudget::"Index%":
                begin
                    FilterItemAnalyViewEntry(ItemStatisticsBuffer, ItemAnalysisViewEntry);
                    case ValueType of
                        ValueType::"Sales Amount":
                            PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry."Sales Amount (Actual)");
                        ValueType::"Cost Amount":
                            PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry."Cost Amount (Actual)");
                        ValueType::"Sales Quantity":
                            PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry.Quantity);
                    end;
                end;
            ShowActualBudget::"Budgeted Amounts":
                begin
                    FilterItemAnalyViewBudgEntry(ItemStatisticsBuffer, ItemAnalysisViewBudgetEntry);
                    case ValueType of
                        ValueType::"Sales Amount":
                            PAGE.Run(0, ItemAnalysisViewBudgetEntry, ItemAnalysisViewBudgetEntry."Sales Amount");
                        ValueType::"Cost Amount":
                            PAGE.Run(0, ItemAnalysisViewBudgetEntry, ItemAnalysisViewBudgetEntry."Cost Amount");
                        ValueType::"Sales Quantity":
                            PAGE.Run(0, ItemAnalysisViewBudgetEntry, ItemAnalysisViewBudgetEntry.Quantity);
                    end;
                end;
        end;
    end;

    procedure SetLineAndColDim(ItemAnalysisView: Record "Item Analysis View"; var LineDimCode: Text[30]; var LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; var ColumnDimCode: Text[30]; var ColumnDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3")
    var
        Item: Record Item;
    begin
        if (LineDimCode = '') and (ColumnDimCode = '') then begin
            LineDimCode := Item.TableCaption;
            ColumnDimCode := Text000;
        end;
        LineDimOption := DimCodeToOption(LineDimCode, ItemAnalysisView);
        ColumnDimOption := DimCodeToOption(ColumnDimCode, ItemAnalysisView);
    end;

    procedure GetDimSelection(OldDimSelCode: Text[30]; var ItemAnalysisView: Record "Item Analysis View"): Text[30]
    var
        Item: Record Item;
        Location: Record Location;
        DimSelection: Page "Dimension Selection";
    begin
        DimSelection.InsertDimSelBuf(false, Item.TableCaption, Item.TableCaption);
        DimSelection.InsertDimSelBuf(false, Location.TableCaption, Location.TableCaption);
        DimSelection.InsertDimSelBuf(false, Text000, Text000);
        if ItemAnalysisView."Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, ItemAnalysisView."Dimension 1 Code", '');
        if ItemAnalysisView."Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, ItemAnalysisView."Dimension 2 Code", '');
        if ItemAnalysisView."Dimension 3 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, ItemAnalysisView."Dimension 3 Code", '');

        DimSelection.LookupMode := true;
        if DimSelection.RunModal = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode);
        exit(OldDimSelCode);
    end;

    procedure ValidateLineDimCode(ItemAnalysisView: Record "Item Analysis View"; var LineDimCode: Text[30]; var LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; ColumnDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; var InternalDateFilter: Text; var DateFilter: Text; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var PeriodInitialized: Boolean)
    begin
        if DimCodeNotAllowed(LineDimCode, ItemAnalysisView) then begin
            Message(Text003, LineDimCode);
            LineDimCode := '';
        end;
        LineDimOption := DimCodeToOption(LineDimCode, ItemAnalysisView);
        InternalDateFilter := ItemStatisticsBuffer.GetFilter("Date Filter");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    procedure ValidateColumnDimCode(ItemAnalysisView: Record "Item Analysis View"; var ColumnDimCode: Text[30]; var ColumnDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; var InternalDateFilter: Text; var DateFilter: Text; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var PeriodInitialized: Boolean)
    begin
        if DimCodeNotAllowed(ColumnDimCode, ItemAnalysisView) then begin
            Message(Text004, ColumnDimCode);
            ColumnDimCode := '';
        end;
        ColumnDimOption := DimCodeToOption(ColumnDimCode, ItemAnalysisView);
        InternalDateFilter := ItemStatisticsBuffer.GetFilter("Date Filter");
        if (ColumnDimOption <> ColumnDimOption::Period) and (LineDimOption <> LineDimOption::Period) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    procedure FormatAmount(var Text: Text[250]; RoundingFactor: Option "None","1","1000","1000000")
    var
        Amount: Decimal;
    begin
        if (Text = '') or (RoundingFactor = RoundingFactor::None) then
            exit;
        Evaluate(Amount, Text);
        Amount := MatrixMgt.RoundValue(Amount, RoundingFactor);
        if Amount = 0 then
            Text := ''
        else
            case RoundingFactor of
                RoundingFactor::"1":
                    Text := Format(Amount);
                RoundingFactor::"1000", RoundingFactor::"1000000":
                    Text := Format(Amount, 0, Text001);
            end;
    end;

    procedure FindRec(ItemAnalysisView: Record "Item Analysis View"; DimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]; ItemFilter: Code[250]; LocationFilter: Code[250]; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; var DateFilter: Text[30]; var PeriodInitialized: Boolean; InternalDateFilter: Text[30]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]): Boolean
    var
        Item: Record Item;
        Location: Record Location;
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        Found: Boolean;
    begin
        case DimOption of
            DimOption::Item:
                begin
                    Item."No." := DimCodeBuf.Code;
                    if ItemFilter <> '' then
                        Item.SetFilter("No.", ItemFilter);
                    Found := Item.Find(Which);
                    if Found then
                        CopyItemToBuf(Item, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if not PeriodInitialized then
                        DateFilter := '';
                    PeriodInitialized := true;
                    Period."Period Start" := DimCodeBuf."Period Start";
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter)
                    else
                        if InternalDateFilter <> '' then
                            Period.SetFilter("Period Start", InternalDateFilter);
                    Found := PeriodFormMgt.FindDate(Which, Period, PeriodType);
                    if Found then
                        CopyPeriodToBuf(Period, DimCodeBuf, DateFilter);
                end;
            DimOption::Location:
                begin
                    Location.Code := CopyStr(DimCodeBuf.Code, 1, MaxStrLen(Location.Code));
                    if LocationFilter <> '' then
                        Location.SetFilter(Code, LocationFilter);
                    Found := Location.Find(Which);
                    if Found then
                        CopyLocationToBuf(Location, DimCodeBuf);
                end;
            DimOption::"Dimension 1":
                begin
                    if Dim1Filter <> '' then
                        DimVal.SetFilter(Code, Dim1Filter);
                    DimVal."Dimension Code" := ItemAnalysisView."Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 2":
                begin
                    if Dim2Filter <> '' then
                        DimVal.SetFilter(Code, Dim2Filter);
                    DimVal."Dimension Code" := ItemAnalysisView."Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 3":
                begin
                    if Dim3Filter <> '' then
                        DimVal.SetFilter(Code, Dim3Filter);
                    DimVal."Dimension Code" := ItemAnalysisView."Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;
        exit(Found);
    end;

    procedure NextRec(ItemAnalysisView: Record "Item Analysis View"; DimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; ItemFilter: Code[250]; LocationFilter: Code[250]; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; DateFilter: Text[30]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]): Integer
    var
        Item: Record Item;
        Location: Record Location;
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        ResultSteps: Integer;
    begin
        case DimOption of
            DimOption::Item:
                begin
                    Item."No." := DimCodeBuf.Code;
                    if ItemFilter <> '' then
                        Item.SetFilter("No.", ItemFilter);
                    ResultSteps := Item.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyItemToBuf(Item, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter);
                    Period."Period Start" := DimCodeBuf."Period Start";
                    ResultSteps := PeriodFormMgt.NextDate(Steps, Period, PeriodType);
                    if ResultSteps <> 0 then
                        CopyPeriodToBuf(Period, DimCodeBuf, DateFilter);
                end;
            DimOption::Location:
                begin
                    Location.Code := CopyStr(DimCodeBuf.Code, 1, MaxStrLen(Location.Code));
                    if LocationFilter <> '' then
                        Location.SetFilter(Code, LocationFilter);
                    ResultSteps := Location.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyLocationToBuf(Location, DimCodeBuf);
                end;
            DimOption::"Dimension 1":
                begin
                    if Dim1Filter <> '' then
                        DimVal.SetFilter(Code, Dim1Filter);
                    DimVal."Dimension Code" := ItemAnalysisView."Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 2":
                begin
                    if Dim2Filter <> '' then
                        DimVal.SetFilter(Code, Dim2Filter);
                    DimVal."Dimension Code" := ItemAnalysisView."Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 3":
                begin
                    if Dim3Filter <> '' then
                        DimVal.SetFilter(Code, Dim3Filter);
                    DimVal."Dimension Code" := ItemAnalysisView."Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;
        exit(ResultSteps);
    end;

    procedure GetCaptionClass(AnalysisViewDimType: Integer; ItemAnalysisView: Record "Item Analysis View"): Text[250]
    begin
        case AnalysisViewDimType of
            1:
                begin
                    if ItemAnalysisView."Dimension 1 Code" <> '' then
                        exit('1,6,' + ItemAnalysisView."Dimension 1 Code");
                    exit(Text005);
                end;
            2:
                begin
                    if ItemAnalysisView."Dimension 2 Code" <> '' then
                        exit('1,6,' + ItemAnalysisView."Dimension 2 Code");
                    exit(Text006);
                end;
            3:
                begin
                    if ItemAnalysisView."Dimension 3 Code" <> '' then
                        exit('1,6,' + ItemAnalysisView."Dimension 3 Code");
                    exit(Text007);
                end;
        end;
    end;

    procedure CalcAmount(ValueType: Option "Sales Amount","Cost Amount",Quantity; SetColumnFilter: Boolean; CurrentAnalysisArea: Option; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentItemAnalysisViewCode: Code[10]; ItemFilter: Code[250]; LocationFilter: Code[250]; DateFilter: Text[30]; BudgetFilter: Code[250]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]; LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; LineDimCodeBuf: Record "Dimension Code Buffer"; ColDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; ColDimCodeBuf: Record "Dimension Code Buffer"; ShowActualBudget: Option "Actual Amounts","Budgeted Amounts",Variance,"Variance%","Index%"): Decimal
    var
        Amount: Decimal;
        ActualAmt: Decimal;
        BudgetAmt: Decimal;
    begin
        case ShowActualBudget of
            ShowActualBudget::"Actual Amounts":
                Amount :=
                  CalcActualAmount(
                    ValueType, SetColumnFilter,
                    CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                    ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                    Dim1Filter, Dim2Filter, Dim3Filter,
                    LineDimOption, LineDimCodeBuf,
                    ColDimOption, ColDimCodeBuf);
            ShowActualBudget::"Budgeted Amounts":
                Amount :=
                  CalcBudgetAmount(
                    ValueType, SetColumnFilter,
                    CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                    ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                    Dim1Filter, Dim2Filter, Dim3Filter,
                    LineDimOption, LineDimCodeBuf,
                    ColDimOption, ColDimCodeBuf);
            ShowActualBudget::Variance:
                begin
                    ActualAmt :=
                      CalcActualAmount(
                        ValueType, SetColumnFilter,
                        CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                        ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                        Dim1Filter, Dim2Filter, Dim3Filter,
                        LineDimOption, LineDimCodeBuf,
                        ColDimOption, ColDimCodeBuf);
                    BudgetAmt :=
                      CalcBudgetAmount(
                        ValueType, SetColumnFilter,
                        CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                        ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                        Dim1Filter, Dim2Filter, Dim3Filter,
                        LineDimOption, LineDimCodeBuf,
                        ColDimOption, ColDimCodeBuf);
                    Amount := ActualAmt - BudgetAmt;
                end;
            ShowActualBudget::"Variance%":
                begin
                    Amount :=
                      CalcBudgetAmount(
                        ValueType, SetColumnFilter,
                        CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                        ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                        Dim1Filter, Dim2Filter, Dim3Filter,
                        LineDimOption, LineDimCodeBuf,
                        ColDimOption, ColDimCodeBuf);
                    if Amount <> 0 then begin
                        ActualAmt :=
                          CalcActualAmount(
                            ValueType, SetColumnFilter,
                            CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                            ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                            Dim1Filter, Dim2Filter, Dim3Filter,
                            LineDimOption, LineDimCodeBuf,
                            ColDimOption, ColDimCodeBuf);
                        Amount := Round(100 * (ActualAmt - Amount) / Amount);
                    end;
                end;
            ShowActualBudget::"Index%":
                begin
                    Amount :=
                      CalcBudgetAmount(
                        ValueType, SetColumnFilter,
                        CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                        ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                        Dim1Filter, Dim2Filter, Dim3Filter,
                        LineDimOption, LineDimCodeBuf,
                        ColDimOption, ColDimCodeBuf);
                    ActualAmt :=
                      CalcActualAmount(
                        ValueType, SetColumnFilter,
                        CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                        ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                        Dim1Filter, Dim2Filter, Dim3Filter,
                        LineDimOption, LineDimCodeBuf,
                        ColDimOption, ColDimCodeBuf);
                    if Amount <> 0 then
                        Amount := Round(100 * ActualAmt / Amount);
                end;
        end;

        exit(Amount);
    end;

    local procedure CalcActualAmount(ValueType: Option "Sales Amount","Cost Amount",Quantity; SetColumnFilter: Boolean; CurrentAnalysisArea: Option; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentItemAnalysisViewCode: Code[10]; ItemFilter: Code[250]; LocationFilter: Code[250]; DateFilter: Text[30]; BudgetFilter: Code[250]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]; LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; LineDimCodeBuf: Record "Dimension Code Buffer"; ColDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; ColDimCodeBuf: Record "Dimension Code Buffer"): Decimal
    var
        Amount: Decimal;
    begin
        SetCommonFilters(
          CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
          ItemFilter, LocationFilter, DateFilter, Dim1Filter, Dim2Filter, Dim3Filter, BudgetFilter);

        SetDimFilters(ItemStatisticsBuffer, LineDimOption, LineDimCodeBuf);
        if SetColumnFilter then
            SetDimFilters(ItemStatisticsBuffer, ColDimOption, ColDimCodeBuf)
        else
            case ColDimOption of
                ColDimOption::"Dimension 1":
                    ItemStatisticsBuffer.SetRange("Dimension 1 Filter");
                ColDimOption::"Dimension 2":
                    ItemStatisticsBuffer.SetRange("Dimension 2 Filter");
                ColDimOption::"Dimension 3":
                    ItemStatisticsBuffer.SetRange("Dimension 3 Filter");
            end;

        case ValueType of
            ValueType::"Sales Amount":
                begin
                    ItemStatisticsBuffer.CalcFields("Analysis - Sales Amt. (Actual)", "Analysis - Sales Amt. (Exp)");
                    Amount :=
                      ItemStatisticsBuffer."Analysis - Sales Amt. (Actual)" +
                      ItemStatisticsBuffer."Analysis - Sales Amt. (Exp)";
                end;
            ValueType::"Cost Amount":
                begin
                    ItemStatisticsBuffer.CalcFields(
                      "Analysis - Cost Amt. (Actual)",
                      "Analysis - Cost Amt. (Exp)",
                      "Analysis CostAmt.(Non-Invtbl.)");
                    Amount :=
                      ItemStatisticsBuffer."Analysis - Cost Amt. (Actual)" +
                      ItemStatisticsBuffer."Analysis - Cost Amt. (Exp)" +
                      ItemStatisticsBuffer."Analysis CostAmt.(Non-Invtbl.)";
                end;
            ValueType::Quantity:
                begin
                    ItemStatisticsBuffer.CalcFields("Analysis - Quantity");
                    Amount := ItemStatisticsBuffer."Analysis - Quantity";
                end;
        end;

        exit(Amount);
    end;

    local procedure CalcBudgetAmount(ValueType: Option "Sales Amount","Cost Amount",Quantity; SetColumnFilter: Boolean; CurrentAnalysisArea: Option; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentItemAnalysisViewCode: Code[10]; ItemFilter: Code[250]; LocationFilter: Code[250]; DateFilter: Text[30]; BudgetFilter: Code[250]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]; LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; LineDimCodeBuf: Record "Dimension Code Buffer"; ColDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3"; ColDimCodeBuf: Record "Dimension Code Buffer"): Decimal
    var
        Amount: Decimal;
    begin
        SetCommonFilters(
          CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
          ItemFilter, LocationFilter, DateFilter, Dim1Filter, Dim2Filter, Dim3Filter, BudgetFilter);

        SetDimFilters(ItemStatisticsBuffer, LineDimOption, LineDimCodeBuf);
        if SetColumnFilter then
            SetDimFilters(ItemStatisticsBuffer, ColDimOption, ColDimCodeBuf);

        case ValueType of
            ValueType::"Sales Amount":
                begin
                    ItemStatisticsBuffer.CalcFields("Analysis - Budgeted Sales Amt.");
                    Amount := ItemStatisticsBuffer."Analysis - Budgeted Sales Amt.";
                end;
            ValueType::"Cost Amount":
                begin
                    ItemStatisticsBuffer.CalcFields("Analysis - Budgeted Cost Amt.");
                    Amount := ItemStatisticsBuffer."Analysis - Budgeted Cost Amt.";
                end;
            ValueType::Quantity:
                begin
                    ItemStatisticsBuffer.CalcFields("Analysis - Budgeted Quantity");
                    Amount := ItemStatisticsBuffer."Analysis - Budgeted Quantity";
                end;
        end;

        exit(Amount);
    end;
}

