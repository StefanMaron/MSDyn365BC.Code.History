page 7159 "Invt. Analysis by Dimensions"
{
    Caption = 'Invt. Analysis by Dimensions';
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
                        ItemAnalysisMgt.SetItemAnalysisView(
                          CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
                          Dim1Filter, Dim2Filter, Dim3Filter);
                        ItemAnalysisMgt.SetLineAndColDim(
                          ItemAnalysisView, LineDimCode, LineDimOption, ColumnDimCode, ColumnDimOption);
                        UpdateFilterFields;
                        CurrPage.Update(false);
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
                        CurrPage.Update(false);
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
                            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
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

                        MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
                        CurrPage.Update(false);
                    end;
                }
                field(ValueType; ValueType)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Value As';
                    OptionCaption = 'Sales Amount,Inventory Value,Quantity';
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

                        MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
                        CurrPage.Update;
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
                        ItemStatisticsBuffer.SetFilter("Item Filter", ItemFilter);
                        if ColumnDimOption = ColumnDimOption::Item then
                            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
                        CurrPage.Update(false);
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies the filter through which you want to analyze inventory entries.';

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
                        ItemStatisticsBuffer.SetFilter("Location Filter", LocationFilter);
                        if ColumnDimOption = ColumnDimOption::Location then
                            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
                        CurrPage.Update(false);
                    end;
                }
                field(BudgetFilter; BudgetFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Budget Filter';
                    ToolTip = 'Specifies the budget that information in the matrix is shown for.';
                    Visible = false;
                }
                field(Dim1Filter; Dim1Filter)
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
                        if ColumnDimOption = ColumnDimOption::"Dimension 1" then
                            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
                        CurrPage.Update;
                    end;
                }
                field(Dim2Filter; Dim2Filter)
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
                        if ColumnDimOption = ColumnDimOption::"Dimension 2" then
                            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
                        CurrPage.Update;
                    end;
                }
                field(Dim3Filter; Dim3Filter)
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
                        if ColumnDimOption = ColumnDimOption::"Dimension 3" then
                            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
                        CurrPage.Update;
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
                        MATRIX_GenerateColumnCaptions(MATRIX_Step::Same);
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
                        if ColumnDimOption = ColumnDimOption::Period then
                            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
                    end;
                }
                field(MATRIX_CaptionRange; MATRIX_CaptionRange)
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
                action(ReverseLinesAndColumns)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Reverse Lines and Columns';
                    Image = Undo;
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
                    end;
                }
                action(ExportToExcel)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Export to Excel';
                    Image = ExportToExcel;
                    ToolTip = 'Export the information in the analysis report to Excel.';

                    trigger OnAction()
                    var
                        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
                        ItemAnalysisViewToExcel: Codeunit "Export Item Analysis View";
                    begin
                        ItemAnalysisViewToExcel.SetCommonFilters(
                          CurrentAnalysisArea, CurrentItemAnalysisViewCode,
                          ItemAnalysisViewEntry, DateFilter, ItemFilter, Dim1Filter, Dim2Filter, Dim3Filter, LocationFilter);
                        ItemAnalysisViewEntry.FindFirst;
                        ItemAnalysisViewToExcel.ExportData(
                          ItemAnalysisViewEntry, ShowColumnName, DateFilter, ItemFilter, BudgetFilter,
                          Dim1Filter, Dim2Filter, Dim3Filter, ShowActualBudget, LocationFilter, ShowOppositeSign);
                    end;
                }
            }
        }
        area(processing)
        {
            action(ShowMatrix)
            {
                ApplicationArea = Dimensions;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'View the actual analysis report according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Invt. Analys by Dim. Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.Load(MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns,
                      LineDimOption, ColumnDimOption, RoundingFactor, DateFilter,
                      ValueType, ItemAnalysisView, CurrentItemAnalysisViewCode,
                      ItemFilter, LocationFilter, BudgetFilter, Dim1Filter, Dim2Filter, Dim3Filter, ShowOppositeSign);
                    MatrixForm.RunModal;
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Dimensions;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_Step::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Dimensions;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_Step::Next);
                end;
            }
        }
    }

    trigger OnInit()
    begin
        Dim3FilterEnable := true;
        Dim2FilterEnable := true;
        Dim1FilterEnable := true;
    end;

    trigger OnOpenPage()
    begin
        CurrentAnalysisArea := CurrentAnalysisArea::Inventory;

        GLSetup.Get();

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
        MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
    end;

    var
        MATRIX_MatrixRecords: array[32] of Record "Dimension Code Buffer";
        GLSetup: Record "General Ledger Setup";
        ItemAnalysisView: Record "Item Analysis View";
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        ItemAnalysisMgt: Codeunit "Item Analysis Management";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        FirstColumn: Text;
        LastColumn: Text;
        MATRIX_PrimKeyFirstCaption: Text;
        MATRIX_CurrentNoOfColumns: Integer;
        MATRIX_Step: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn;
        CurrentAnalysisArea: Option Sales,Purchase,Inventory;
        CurrentItemAnalysisViewCode: Code[10];
        ItemFilter: Code[250];
        LocationFilter: Code[250];
        BudgetFilter: Code[250];
        ValueType: Option "Sales Amount","Inventory Value","Sales Quantity";
        ShowActualBudget: Option "Actual Amounts","Budgeted Amounts",Variance,"Variance%","Index%";
        RoundingFactor: Option "None","1","1000","1000000";
        LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
        ColumnDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        Dim1Filter: Code[250];
        Dim2Filter: Code[250];
        Dim3Filter: Code[250];
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        DateFilter: Text[30];
        InternalDateFilter: Text[30];
        PeriodInitialized: Boolean;
        ShowColumnName: Boolean;
        ShowOppositeSign: Boolean;
        Text100: Label 'Period';
        NewItemAnalysisCode: Code[10];
        [InDataSet]
        Dim1FilterEnable: Boolean;
        [InDataSet]
        Dim2FilterEnable: Boolean;
        [InDataSet]
        Dim3FilterEnable: Boolean;

    local procedure MATRIX_GenerateColumnCaptions(MATRIX_SetWanted: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn)
    var
        MATRIX_PeriodRecords: array[32] of Record Date;
        Location: Record Location;
        Item: Record Item;
        Customer: Record Customer;
        Vendor: Record Vendor;
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        i: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MATRIX_MatrixRecords);
        FirstColumn := '';
        LastColumn := '';
        MATRIX_CurrentNoOfColumns := ArrayLen(MATRIX_CaptionSet);

        case ColumnDimCode of
            Text100: // Period
                begin
                    MatrixMgt.GeneratePeriodMatrixData(MATRIX_SetWanted, ArrayLen(MATRIX_CaptionSet), ShowColumnName,
                      PeriodType, DateFilter, MATRIX_PrimKeyFirstCaption,
                      MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns, MATRIX_PeriodRecords);
                    for i := 1 to ArrayLen(MATRIX_CaptionSet) do begin
                        MATRIX_MatrixRecords[i]."Period Start" := MATRIX_PeriodRecords[i]."Period Start";
                        MATRIX_MatrixRecords[i]."Period End" := MATRIX_PeriodRecords[i]."Period End";
                    end;
                    FirstColumn := Format(MATRIX_PeriodRecords[1]."Period Start");
                    LastColumn := Format(MATRIX_PeriodRecords[MATRIX_CurrentNoOfColumns]."Period End");
                end;
            Location.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    Location.SetFilter(Code, LocationFilter);
                    RecRef.GetTable(Location);
                    RecRef.SetTable(Location);
                    MatrixMgt.GenerateMatrixData(RecRef, MATRIX_SetWanted, ArrayLen(MATRIX_CaptionSet), 1,
                      MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(RecRef, MATRIX_SetWanted::Same, ArrayLen(MATRIX_CaptionSet), 2,
                          MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            Item.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    Item.SetFilter("No.", ItemFilter);
                    RecRef.GetTable(Item);
                    RecRef.SetTable(Item);

                    MatrixMgt.GenerateMatrixData(RecRef, MATRIX_SetWanted, ArrayLen(MATRIX_CaptionSet), 1,
                      MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(RecRef, MATRIX_SetWanted::Same, ArrayLen(MATRIX_CaptionSet), 3,
                          MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            Customer.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Customer);
                    RecRef.SetTable(Customer);
                    MatrixMgt.GenerateMatrixData(RecRef, MATRIX_SetWanted, ArrayLen(MATRIX_CaptionSet), 1,
                      MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(RecRef, MATRIX_SetWanted::Same, ArrayLen(MATRIX_CaptionSet), 2,
                          MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            Vendor.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Vendor);
                    RecRef.SetTable(Vendor);
                    MatrixMgt.GenerateMatrixData(RecRef, MATRIX_SetWanted, ArrayLen(MATRIX_CaptionSet), 1,
                      MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(RecRef, MATRIX_SetWanted::Same, ArrayLen(MATRIX_CaptionSet), 2,
                          MATRIX_PrimKeyFirstCaption, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            ItemAnalysisView."Dimension 1 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  ItemAnalysisView."Dimension 1 Code",
                  Dim1Filter, MATRIX_SetWanted, MATRIX_PrimKeyFirstCaption, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            ItemAnalysisView."Dimension 2 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  ItemAnalysisView."Dimension 2 Code",
                  Dim2Filter, MATRIX_SetWanted, MATRIX_PrimKeyFirstCaption, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            ItemAnalysisView."Dimension 3 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  ItemAnalysisView."Dimension 3 Code",
                  Dim3Filter, MATRIX_SetWanted, MATRIX_PrimKeyFirstCaption, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
        end;
    end;

    local procedure FindPeriod(SearchText: Code[3])
    var
        PeriodFormMgt: Codeunit PeriodFormManagement;
    begin
        PeriodFormMgt.FindPeriodOnMatrixPage(
          DateFilter, InternalDateFilter, SearchText, PeriodType,
          (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period));
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

    procedure SetCurrentAnalysisViewCode(NewAnalysisViewCode: Code[10])
    begin
        NewItemAnalysisCode := NewAnalysisViewCode;
    end;
}

