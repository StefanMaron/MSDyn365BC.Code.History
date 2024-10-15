page 7158 "Sales Analysis by Dimensions"
{
    Caption = 'Sales Analysis by Dimensions';
    DataCaptionExpression = CurrentItemAnalysisViewCode;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Dimension Code Buffer";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrentItemAnalysisViewCode; CurrentItemAnalysisViewCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Analysis View Code';
                    ToolTip = 'Specifies the code for the analysis view that the filter belongs to.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ItemAnalysisMgt.LookupItemAnalysisView(
                          CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
                          Dim1Filter, Dim2Filter, Dim3Filter);
                        ItemAnalysisMgt.SetLineAndColDim(
                          ItemAnalysisView, LineDimCode, LineDimOption, ColumnDimCode, ColumnDimOption);
                        UpdateFilterFields;
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        ItemAnalysisMgt.CheckAnalysisView(CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView);
                        CurrentItemAnalysisViewCodeOnA;
                    end;
                }
                field(LineDimCode; LineDimCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show as Lines';
                    ToolTip = 'Specifies which values you want to show as lines in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := ItemAnalysisMgt.GetDimSelection(LineDimCode, ItemAnalysisView);
                        if NewCode <> LineDimCode then begin
                            Text := NewCode;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            ColumnDimCode := '';
                            ItemAnalysisMgt.ValidateColumnDimCode(
                              ItemAnalysisView, ColumnDimCode, ColumnDimOption, LineDimOption,
                              InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        end;
                        ItemAnalysisMgt.ValidateLineDimCode(
                          ItemAnalysisView, LineDimCode, LineDimOption, ColumnDimOption,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        if LineDimOption = LineDimOption::Period then
                            SetCurrentKey("Period Start")
                        else
                            SetCurrentKey(Code);
                        LineDimCodeOnAfterValidate;
                    end;
                }
                field(ColumnDimCode; ColumnDimCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show as Columns';
                    ToolTip = 'Specifies which values you want to show as columns in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := ItemAnalysisMgt.GetDimSelection(ColumnDimCode, ItemAnalysisView);
                        if NewCode <> ColumnDimCode then begin
                            Text := NewCode;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            LineDimCode := '';
                            ItemAnalysisMgt.ValidateLineDimCode(
                              ItemAnalysisView, LineDimCode, LineDimOption, ColumnDimOption,
                              InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        end;
                        ItemAnalysisMgt.ValidateColumnDimCode(
                          ItemAnalysisView, ColumnDimCode, ColumnDimOption, LineDimOption,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        ColumnDimCodeOnAfterValidate;
                    end;
                }
                field(ValueType; ValueType)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Value As';
                    OptionCaption = 'Sales Amount,COGS Amount,Quantity';
                    ToolTip = 'Specifies how data is shown in the analysis view.';
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        ItemStatisticsBuffer.SetFilter("Date Filter", DateFilter);
                        DateFilter := ItemStatisticsBuffer.GetFilter("Date Filter");
                        InternalDateFilter := DateFilter;
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        DateFilterOnAfterValidate;
                    end;
                }
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies a filter to specify the items for which values will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemList: Page "Item List";
                    begin
                        ItemList.LookupMode(true);
                        if ItemList.RunModal = ACTION::LookupOK then begin
                            Text := ItemList.GetSelectionFilter;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        ItemFilterOnAfterValidate;
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies the filter through which you want to analyze sales entries.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LocationList: Page "Location List";
                    begin
                        LocationList.LookupMode(true);
                        if LocationList.RunModal = ACTION::LookupOK then begin
                            Text := LocationList.GetSelectionFilter;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        LocationFilterOnAfterValidate;
                    end;
                }
                field(BudgetFilter; BudgetFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Budget Filter';
                    ToolTip = 'Specifies the budget that information in the matrix is shown for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemBudgetName: Record "Item Budget Name";
                    begin
                        ItemBudgetName.FilterGroup := 2;
                        ItemBudgetName.SetRange("Analysis Area", CurrentAnalysisArea);
                        ItemBudgetName.FilterGroup := 0;
                        if PAGE.RunModal(0, ItemBudgetName) = ACTION::LookupOK then begin
                            Text := ItemBudgetName.Name;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        BudgetFilterOnAfterValidate;
                    end;
                }
                field(Dim1FilterControl; Dim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = ItemAnalysisMgt.GetCaptionClass(1, ItemAnalysisView);
                    Caption = 'Dimension 1 Filter';
                    Enabled = Dim1FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 1 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(ItemAnalysisMgt.LookUpDimFilter(ItemAnalysisView."Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        ItemStatisticsBuffer.SetFilter("Dimension 1 Filter", Dim1Filter);
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        Dim1FilterOnAfterValidate;
                    end;
                }
                field(Dim2FilterControl; Dim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = ItemAnalysisMgt.GetCaptionClass(2, ItemAnalysisView);
                    Caption = 'Dimension 2 Filter';
                    Enabled = Dim2FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 2 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(ItemAnalysisMgt.LookUpDimFilter(ItemAnalysisView."Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        ItemStatisticsBuffer.SetFilter("Dimension 2 Filter", Dim2Filter);
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        Dim2FilterOnAfterValidate;
                    end;
                }
                field(Dim3FilterControl; Dim3Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = ItemAnalysisMgt.GetCaptionClass(3, ItemAnalysisView);
                    Caption = 'Dimension 3 Filter';
                    Enabled = Dim3FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 3 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(ItemAnalysisMgt.LookUpDimFilter(ItemAnalysisView."Dimension 3 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        ItemStatisticsBuffer.SetFilter("Dimension 3 Filter", Dim3Filter);
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        Dim3FilterOnAfterValidate;
                    end;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field(ShowActualBudget; ShowActualBudget)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show';
                    OptionCaption = 'Actual Amounts,Budgeted Amounts,Variance,Variance%,Index%';
                    ToolTip = 'Specifies if the selected value is shown in the window.';
                }
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Rounding Factor';
                    OptionCaption = 'None,1,1000,1000000';
                    ToolTip = 'Specifies the factor that is used to round the amounts.';
                }
                field(ShowColumnName; ShowColumnName)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Column Name';
                    ToolTip = 'Specifies that the names of columns are shown in the matrix window.';

                    trigger OnValidate()
                    begin
                        ShowColumnNameOnAfterValidate;
                    end;
                }
                field(ShowOppositeSign; ShowOppositeSign)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Opposite Sign';
                    MultiLine = true;
                    ToolTip = 'Specifies whether to show debits as negative amounts (with minus signs) and credits as positive amounts in the matrix window.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'View by';
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                    end;
                }
                field(ColumnSet; MATRIX_CaptionRange)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Column Set';
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Actions")
            {
                Caption = '&Actions';
                Image = "Action";
                action("Reverse Lines and Columns")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Reverse Lines and Columns';
                    Image = Undo;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Change the display of the matrix by inverting the values in the Show as Lines and Show as Columns fields.';

                    trigger OnAction()
                    var
                        TempDimCode: Text[30];
                    begin
                        TempDimCode := ColumnDimCode;
                        ColumnDimCode := LineDimCode;
                        LineDimCode := TempDimCode;
                        ItemAnalysisMgt.ValidateLineDimCode(
                          ItemAnalysisView, LineDimCode, LineDimOption, ColumnDimOption,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        ItemAnalysisMgt.ValidateColumnDimCode(
                          ItemAnalysisView, ColumnDimCode, ColumnDimOption, LineDimOption,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                    end;
                }
            }
        }
        area(processing)
        {
            action(ShowMatrix_Process)
            {
                ApplicationArea = Dimensions;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'View the actual analysis report according to the selected filters and options.';

                trigger OnAction()
                begin
                    Clear(SalesAnalysisByDimMatrix);
                    ShowMatrix;
                end;
            }
            action(PreviousSet)
            {
                ApplicationArea = Dimensions;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Previous);
                end;
            }
            action(NextSet)
            {
                ApplicationArea = Dimensions;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Next);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(
          ItemAnalysisMgt.FindRec(
            ItemAnalysisView, LineDimOption, Rec, Which,
            ItemFilter, LocationFilter, PeriodType, DateFilter, PeriodInitialized, InternalDateFilter,
            Dim1Filter, Dim2Filter, Dim3Filter));
    end;

    trigger OnInit()
    begin
        Dim3FilterEnable := true;
        Dim2FilterEnable := true;
        Dim1FilterEnable := true;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(
          ItemAnalysisMgt.NextRec(
            ItemAnalysisView, LineDimOption, Rec, Steps,
            ItemFilter, LocationFilter, PeriodType, DateFilter,
            Dim1Filter, Dim2Filter, Dim3Filter));
    end;

    trigger OnOpenPage()
    begin
        CurrentAnalysisArea := CurrentAnalysisArea::Sales;

        GLSetup.Get;

        ItemAnalysisMgt.AnalysisViewSelection(
          CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
          Dim1Filter, Dim2Filter, Dim3Filter);

        if (NewItemAnalysisCode <> '') and (NewItemAnalysisCode <> CurrentItemAnalysisViewCode) then begin
            CurrentItemAnalysisViewCode := NewItemAnalysisCode;
            ItemAnalysisMgt.CheckAnalysisView(CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView);
            ItemAnalysisMgt.SetItemAnalysisView(
              CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
              Dim1Filter, Dim2Filter, Dim3Filter);
        end;

        ItemAnalysisMgt.SetLineAndColDim(
          ItemAnalysisView, LineDimCode, LineDimOption, ColumnDimCode, ColumnDimOption);
        UpdateFilterFields;

        FindPeriod('');

        NoOfColumns := SalesAnalysisByDimMatrix.GetMatrixDimension;
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ItemAnalysisView: Record "Item Analysis View";
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        MATRIX_PeriodRecords: array[32] of Record Date;
        ItemAnalysisMgt: Codeunit "Item Analysis Management";
        MatrixMgt: Codeunit "Matrix Management";
        SalesAnalysisByDimMatrix: Page "Sales Analysis by Dim Matrix";
        CurrentItemAnalysisViewCode: Code[10];
        CurrentAnalysisArea: Option Sales,Purchase,Inventory;
        ValueType: Option "Sales Amount","COGS Amount","Sales Quantity";
        ShowActualBudget: Option "Actual Amounts","Budgeted Amounts",Variance,"Variance%","Index%";
        RoundingFactor: Option "None","1","1000","1000000";
        LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
        ColumnDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        BudgetFilter: Code[250];
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        InternalDateFilter: Text[30];
        MatrixColumnCaptions: array[32] of Text[80];
        PeriodInitialized: Boolean;
        ShowColumnName: Boolean;
        ShowOppositeSign: Boolean;
        DateFilter: Text[30];
        Dim1Filter: Code[250];
        Dim2Filter: Code[250];
        Dim3Filter: Code[250];
        ItemFilter: Code[250];
        LocationFilter: Code[250];
        FirstColumnDate: Date;
        LastColumnDate: Date;
        NoOfColumns: Integer;
        MATRIX_PKFirstRecInCurrSet: Text;
        MATRIX_CurrSetLength: Integer;
        MATRIX_CaptionRange: Text;
        MATRIX_CodeRange: Text[250];
        MATRIX_SetWanted: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn;
        NewItemAnalysisCode: Code[10];
        [InDataSet]
        Dim1FilterEnable: Boolean;
        [InDataSet]
        Dim2FilterEnable: Boolean;
        [InDataSet]
        Dim3FilterEnable: Boolean;

    local procedure FindPeriod(SearchText: Code[3])
    var
        PeriodFormMgt: Codeunit PeriodFormManagement;
    begin
        PeriodFormMgt.FindPeriodOnMatrixPage(
          DateFilter, InternalDateFilter, SearchText, PeriodType,
          (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period));
    end;

    local procedure RefreshInternalDateFilter()
    var
        Item: Record Item;
    begin
        Item.SetRange("Date Filter", FirstColumnDate, LastColumnDate);
        if Item.GetRangeMin("Date Filter") = Item.GetRangeMax("Date Filter") then
            Item.SetRange("Date Filter", Item.GetRangeMin("Date Filter"));
        InternalDateFilter := CopyStr(Item.GetFilter("Date Filter"), 1, MaxStrLen(InternalDateFilter));
    end;

    local procedure UpdateFilterFields()
    var
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
    begin
        ItemFilter := ItemAnalysisView."Item Filter";
        Dim1Filter := '';
        Dim2Filter := '';
        Dim3Filter := '';

        Dim1FilterEnable := ItemAnalysisView."Dimension 1 Code" <> '';
        Dim2FilterEnable := ItemAnalysisView."Dimension 2 Code" <> '';
        Dim3FilterEnable := ItemAnalysisView."Dimension 3 Code" <> '';

        if Dim1FilterEnable then
            if ItemAnalysisViewFilter.Get(
                 ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, ItemAnalysisView."Dimension 1 Code")
            then
                Dim1Filter := ItemAnalysisViewFilter."Dimension Value Filter";

        if Dim2FilterEnable then
            if ItemAnalysisViewFilter.Get(
                 ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, ItemAnalysisView."Dimension 2 Code")
            then
                Dim2Filter := ItemAnalysisViewFilter."Dimension Value Filter";

        if Dim3FilterEnable then
            if ItemAnalysisViewFilter.Get(
                 ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, ItemAnalysisView."Dimension 3 Code")
            then
                Dim3Filter := ItemAnalysisViewFilter."Dimension Value Filter";
    end;

    local procedure MATRIX_GenerateColumnCaptions(SetWanted: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn)
    begin
        case ColumnDimOption of
            ColumnDimOption::Item:
                SetPointsItem(SetWanted);
            ColumnDimOption::Location:
                SetPointsLocation(SetWanted);
            ColumnDimOption::Period:
                begin
                    MatrixMgt.GeneratePeriodMatrixData(SetWanted, NoOfColumns, ShowColumnName, PeriodType, DateFilter, MATRIX_PKFirstRecInCurrSet,
                      MatrixColumnCaptions, MATRIX_CaptionRange, MATRIX_CurrSetLength, MATRIX_PeriodRecords);
                    if MATRIX_CurrSetLength > 0 then begin
                        FirstColumnDate := MATRIX_PeriodRecords[1]."Period Start";
                        LastColumnDate := MATRIX_PeriodRecords[MATRIX_CurrSetLength]."Period Start";
                    end;
                    RefreshInternalDateFilter;
                end;
            ColumnDimOption::"Dimension 1":
                SetPointsDim(ItemAnalysisView."Dimension 1 Code", Dim1Filter, SetWanted);
            ColumnDimOption::"Dimension 2":
                SetPointsDim(ItemAnalysisView."Dimension 2 Code", Dim2Filter, SetWanted);
            ColumnDimOption::"Dimension 3":
                SetPointsDim(ItemAnalysisView."Dimension 3 Code", Dim3Filter, SetWanted);
        end;
    end;

    local procedure SetPointsItem(SetWanted: Option Initial,Previous,Same,Next)
    var
        Item: Record Item;
        RecRef: RecordRef;
        CaptionFieldNo: Integer;
    begin
        Clear(MatrixColumnCaptions);
        Item.SetFilter("No.", ItemFilter);
        RecRef.GetTable(Item);
        RecRef.SetTable(Item);

        if ShowColumnName then
            CaptionFieldNo := Item.FieldNo(Description)
        else
            CaptionFieldNo := Item.FieldNo("No.");

        MatrixMgt.GenerateMatrixData(RecRef, SetWanted, NoOfColumns, CaptionFieldNo, MATRIX_PKFirstRecInCurrSet, MatrixColumnCaptions,
          MATRIX_CaptionRange, MATRIX_CurrSetLength);
        MATRIX_CodeRange :=
          MatrixMgt.GetPKRange(RecRef, Item.FieldNo("No."), MATRIX_PKFirstRecInCurrSet, MATRIX_CurrSetLength);
    end;

    local procedure SetPointsLocation(SetWanted: Option Initial,Previous,Same,Next)
    var
        Location: Record Location;
        RecRef: RecordRef;
        CaptionFieldNo: Integer;
    begin
        Clear(MatrixColumnCaptions);
        Location.SetFilter(Code, LocationFilter);
        RecRef.GetTable(Location);
        RecRef.SetTable(Location);

        if ShowColumnName then
            CaptionFieldNo := Location.FieldNo(Name)
        else
            CaptionFieldNo := Location.FieldNo(Code);

        MatrixMgt.GenerateMatrixData(RecRef, SetWanted, NoOfColumns, CaptionFieldNo, MATRIX_PKFirstRecInCurrSet, MatrixColumnCaptions,
          MATRIX_CaptionRange, MATRIX_CurrSetLength);
        MATRIX_CodeRange :=
          MatrixMgt.GetPKRange(RecRef, Location.FieldNo(Code), MATRIX_PKFirstRecInCurrSet, MATRIX_CurrSetLength)
    end;

    local procedure SetPointsDim(DimensionCode: Code[20]; DimFilter: Code[250]; SetWanted: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn)
    var
        DimVal: Record "Dimension Value";
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        CaptionFieldNo: Integer;
    begin
        Clear(MatrixColumnCaptions);
        DimVal.SetRange("Dimension Code", DimensionCode);
        if DimFilter <> '' then
            DimVal.SetFilter(Code, DimFilter);
        RecRef.GetTable(DimVal);
        RecRef.SetTable(DimVal);

        if ShowColumnName then
            CaptionFieldNo := DimVal.FieldNo(Name)
        else
            CaptionFieldNo := DimVal.FieldNo(Code);

        MatrixMgt.GenerateMatrixData(RecRef, SetWanted, NoOfColumns, CaptionFieldNo, MATRIX_PKFirstRecInCurrSet, MatrixColumnCaptions,
          MATRIX_CaptionRange, MATRIX_CurrSetLength);
        if DimensionCode <> '' then
            MATRIX_CodeRange :=
              MatrixMgt.GetPKRange(RecRef, DimVal.FieldNo(Code), MATRIX_PKFirstRecInCurrSet, MATRIX_CurrSetLength);
    end;

    local procedure ShowMatrix()
    var
        CurItemFilter: Text[250];
        CurLocationFilter: Text[250];
        CurDim1Filter: Text[250];
        CurDim2Filter: Text[250];
        CurDim3Filter: Text[250];
    begin
        PeriodInitialized := ColumnDimOption = ColumnDimOption::Period;
        if CurItemFilter = '' then
            CurItemFilter := ItemFilter;
        if CurLocationFilter = '' then
            CurLocationFilter := LocationFilter;
        if CurDim1Filter = '' then
            CurDim1Filter := Dim1Filter;
        if CurDim2Filter = '' then
            CurDim2Filter := Dim2Filter;
        if CurDim3Filter = '' then
            CurDim3Filter := Dim3Filter;

        SalesAnalysisByDimMatrix.LoadVariables(ItemAnalysisView,
          CurrentItemAnalysisViewCode, CurrentAnalysisArea,
          LineDimOption, ColumnDimOption, PeriodType, ValueType,
          RoundingFactor, ShowActualBudget, MatrixColumnCaptions,
          ShowOppositeSign, PeriodInitialized, ShowColumnName, MATRIX_CurrSetLength);
        SalesAnalysisByDimMatrix.LoadFilters(CurItemFilter, CurLocationFilter, CurDim1Filter, CurDim2Filter, CurDim3Filter,
          DateFilter, BudgetFilter, InternalDateFilter);
        SalesAnalysisByDimMatrix.LoadCodeRange(MATRIX_CodeRange);

        SalesAnalysisByDimMatrix.RunModal;
    end;

    procedure SetCurrentAnalysisViewCode(NewAnalysisViewCode: Code[10])
    begin
        NewItemAnalysisCode := NewAnalysisViewCode;
    end;

    local procedure CurrentItemAnalysisViewCodeOnA()
    begin
        ItemAnalysisMgt.SetItemAnalysisView(
          CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
          Dim1Filter, Dim2Filter, Dim3Filter);
        ItemAnalysisMgt.SetLineAndColDim(
          ItemAnalysisView, LineDimCode, LineDimOption, ColumnDimCode, ColumnDimOption);
        UpdateFilterFields;
        CurrPage.Update(false);
    end;

    local procedure LineDimCodeOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ColumnDimCodeOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure Dim2FilterOnAfterValidate()
    begin
        CurrPage.Update;
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure Dim1FilterOnAfterValidate()
    begin
        CurrPage.Update;
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure Dim3FilterOnAfterValidate()
    begin
        CurrPage.Update;
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure ItemFilterOnAfterValidate()
    begin
        ItemStatisticsBuffer.SetFilter("Item Filter", ItemFilter);
        CurrPage.Update(false);
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure LocationFilterOnAfterValidate()
    begin
        ItemStatisticsBuffer.SetFilter("Location Filter", LocationFilter);
        CurrPage.Update(false);
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure BudgetFilterOnAfterValidate()
    begin
        ItemStatisticsBuffer.SetFilter("Budget Filter", BudgetFilter);
        CurrPage.Update(false);
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure ShowColumnNameOnAfterValidate()
    begin
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Same);
    end;
}

