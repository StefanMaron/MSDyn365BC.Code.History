page 7138 "Purchase Budget Overview"
{
    Caption = 'Purchase Budget Overview';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SaveValues = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrentBudgetName; CurrentBudgetName)
                {
                    ApplicationArea = PurchaseBudget;
                    Caption = 'Item Budget Name';
                    ToolTip = 'Specifies the name of the budget to be shown in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ItemBudgetManagement.LookupItemBudgetName(
                          CurrentBudgetName, ItemBudgetName, ItemStatisticsBuffer,
                          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
                        ItemBudgetManagement.ValidateLineDimCode(
                          ItemBudgetName, LineDimCode, LineDimOption, ColumnDimOption,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        ItemBudgetManagement.ValidateColumnDimCode(
                          ItemBudgetName, ColumnDimCode, ColumnDimOption, LineDimOption,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        UpdateDimCtrls;
                        UpdateMatrixSubForm;
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        ItemBudgetManagement.CheckBudgetName(CurrentAnalysisArea, CurrentBudgetName, ItemBudgetName);
                        UpdateMatrixSubForm;
                        CurrentBudgetNameOnAfterValida;
                    end;
                }
                field(LineDimCode; LineDimCode)
                {
                    ApplicationArea = PurchaseBudget;
                    Caption = 'Show as Lines';
                    ToolTip = 'Specifies which values you want to show as lines in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := ItemBudgetManagement.GetDimSelection(LineDimCode, ItemBudgetName);
                        if NewCode <> LineDimCode then begin
                            Text := NewCode;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            ColumnDimCode := '';
                            ItemBudgetManagement.ValidateColumnDimCode(
                              ItemBudgetName, ColumnDimCode, ColumnDimOption, LineDimOption,
                              InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        end;
                        ItemBudgetManagement.ValidateLineDimCode(
                          ItemBudgetName, LineDimCode, LineDimOption, ColumnDimOption,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        LineDimCodeOnAfterValidate;
                    end;
                }
                field(ColumnDimCode; ColumnDimCode)
                {
                    ApplicationArea = PurchaseBudget;
                    Caption = 'Show as Columns';
                    ToolTip = 'Specifies which values you want to show as columns in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := ItemBudgetManagement.GetDimSelection(ColumnDimCode, ItemBudgetName);
                        if NewCode <> ColumnDimCode then begin
                            Text := NewCode;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            LineDimCode := '';
                            ItemBudgetManagement.ValidateLineDimCode(
                              ItemBudgetName, LineDimCode, LineDimOption, ColumnDimOption,
                              InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        end;
                        ItemBudgetManagement.ValidateColumnDimCode(
                          ItemBudgetName, ColumnDimCode, ColumnDimOption, LineDimOption,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);

                        MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
                        ColumnDimCodeOnAfterValidate;
                    end;
                }
                field(ValueType; ValueType)
                {
                    ApplicationArea = PurchaseBudget;
                    Caption = 'Show Value as';
                    OptionCaption = ',Cost Amount,Quantity';
                    ToolTip = 'Specifies if you want to view the item values by cost amount or by quantity.';

                    trigger OnValidate()
                    begin
                        ValueTypeOnAfterValidate;
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = PurchaseBudget;
                    Caption = 'View by';
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        PeriodTypeOnAfterValidate;
                    end;
                }
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = PurchaseBudget;
                    Caption = 'Rounding Factor';
                    OptionCaption = 'None,1,1000,1000000';
                    ToolTip = 'Specifies the factor that is used to round the amounts in the columns.';

                    trigger OnValidate()
                    begin
                        RoundingFactorOnAfterValidate;
                    end;
                }
                field(ShowColumnName; ShowColumnName)
                {
                    ApplicationArea = PurchaseBudget;
                    Caption = 'Show Column Name';
                    ToolTip = 'Specifies that the names of columns are shown in the matrix window.';

                    trigger OnValidate()
                    begin
                        ShowColumnNameOnAfterValidate;
                    end;
                }
            }
            part(MATRIX; "Purch. Budget Overview Matrix")
            {
                ApplicationArea = PurchaseBudget;
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = PurchaseBudget;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies a date filter by which budget amounts are displayed.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        ItemStatisticsBuffer.SetFilter("Date Filter", DateFilter);
                        DateFilter := ItemStatisticsBuffer.GetFilter("Date Filter");
                        InternalDateFilter := DateFilter;
                        DateFilterOnAfterValidate;
                    end;
                }
                field(SalesCodeFilterCtrl; SourceNoFilter)
                {
                    ApplicationArea = PurchaseBudget;
                    Caption = 'Vendor Filter';
                    ToolTip = 'Specifies that the budget is delimited by the vendors from whom items are purchased.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustList: Page "Customer List";
                        VendList: Page "Vendor List";
                    begin
                        case SourceTypeFilter of
                            SourceTypeFilter::Customer:
                                begin
                                    CustList.LookupMode := true;
                                    if CustList.RunModal = ACTION::LookupOK then
                                        Text := CustList.GetSelectionFilter
                                    else
                                        exit(false);
                                end;
                            SourceTypeFilter::Vendor:
                                begin
                                    VendList.LookupMode := true;
                                    if VendList.RunModal = ACTION::LookupOK then
                                        Text := VendList.GetSelectionFilter
                                    else
                                        exit(false);
                                end;
                        end;

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        SourceNoFilterOnAfterValidate;
                    end;
                }
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = PurchaseBudget;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies which items to include in the budget overview.';

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
                        ItemFilterOnAfterValidate;
                    end;
                }
                field(BudgetDim1Filter; BudgetDim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(1);
                    Caption = 'Budget Dimension 1 Filter';
                    Enabled = BudgetDim1FilterEnable;
                    ToolTip = 'Specifies a filter by a budget dimension. ';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(ItemBudgetName."Budget Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        BudgetDim1FilterOnAfterValidat;
                    end;
                }
                field(BudgetDim2Filter; BudgetDim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(2);
                    Caption = 'Budget Dimension 2 Filter';
                    Enabled = BudgetDim2FilterEnable;
                    ToolTip = 'Specifies a second filter by a budget dimension. ';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(ItemBudgetName."Budget Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        BudgetDim2FilterOnAfterValidat;
                    end;
                }
                field(BudgetDim3Filter; BudgetDim3Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(3);
                    Caption = 'Budget Dimension 3 Filter';
                    Enabled = BudgetDim3FilterEnable;
                    ToolTip = 'Specifies a third filter by a budget dimension. ';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(ItemBudgetName."Budget Dimension 3 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        BudgetDim3FilterOnAfterValidat;
                    end;
                }
                field(GlobalDim1Filter; GlobalDim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,3,1';
                    Caption = 'Global Dimension 1 Filter';
                    ToolTip = 'Specifies by which global dimension data is shown. Global dimensions are the dimensions that you analyze most frequently. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(GLSetup."Global Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        GlobalDim1FilterOnAfterValidat;
                    end;
                }
                field(GlobalDim2Filter; GlobalDim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,3,2';
                    Caption = 'Global Dimension 2 Filter';
                    ToolTip = 'Specifies by which global dimension data is shown. Global dimensions are the dimensions that you analyze most frequently. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(GLSetup."Global Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        GlobalDim2FilterOnAfterValidat;
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Reverse Lines and Columns")
                {
                    ApplicationArea = PurchaseBudget;
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
                        ItemBudgetManagement.ValidateLineDimCode(
                          ItemBudgetName, LineDimCode, LineDimOption, ColumnDimOption,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        ItemBudgetManagement.ValidateColumnDimCode(
                          ItemBudgetName, ColumnDimCode, ColumnDimOption, LineDimOption,
                          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
                        MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
                        UpdateMatrixSubForm;
                    end;
                }
                separator(Action53)
                {
                }
                action("Delete Budget")
                {
                    ApplicationArea = PurchaseBudget;
                    Caption = 'Delete Budget';
                    Image = Delete;
                    ToolTip = 'Delete the current budget.';

                    trigger OnAction()
                    begin
                        ItemBudgetManagement.DeleteBudget(
                          CurrentAnalysisArea, CurrentBudgetName,
                          ItemFilter, DateFilter,
                          SourceTypeFilter, SourceNoFilter,
                          GlobalDim1Filter, GlobalDim2Filter,
                          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
                    end;
                }
                separator(Action55)
                {
                }
            }
            group(Excel)
            {
                Caption = 'Excel';
                group("Export to Excel")
                {
                    Caption = 'Export to Excel';
                    Image = ExportToExcel;
                    action("Create New Document")
                    {
                        ApplicationArea = PurchaseBudget;
                        Caption = 'Create New Document';
                        Image = ExportToExcel;
                        ToolTip = 'Open the analysis report in a new Excel workbook. This creates an Excel workbook on your device.';

                        trigger OnAction()
                        var
                            ExportItemBudgetToExcel: Report "Export Item Budget to Excel";
                        begin
                            ExportItemBudgetToExcel.SetOptions(
                              CurrentAnalysisArea,
                              CurrentBudgetName,
                              ValueType,
                              GlobalDim1Filter, GlobalDim2Filter,
                              BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter,
                              DateFilter,
                              SourceTypeFilter, SourceNoFilter,
                              ItemFilter,
                              InternalDateFilter, PeriodInitialized, PeriodType,
                              LineDimOption, ColumnDimOption, LineDimCode, ColumnDimCode, RoundingFactor);
                            ExportItemBudgetToExcel.Run;
                        end;
                    }
                    action("Update Existing Document")
                    {
                        ApplicationArea = PurchaseBudget;
                        Caption = 'Update Existing Document';
                        Image = ExportToExcel;
                        ToolTip = 'Refresh the data in an existing Excel workbook. You must specify the workbook that you want to update.';

                        trigger OnAction()
                        var
                            ExportItemBudgetToExcel: Report "Export Item Budget to Excel";
                        begin
                            ExportItemBudgetToExcel.SetOptions(
                              CurrentAnalysisArea,
                              CurrentBudgetName,
                              ValueType,
                              GlobalDim1Filter, GlobalDim2Filter,
                              BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter,
                              DateFilter,
                              SourceTypeFilter, SourceNoFilter,
                              ItemFilter,
                              InternalDateFilter, PeriodInitialized, PeriodType,
                              LineDimOption, ColumnDimOption, LineDimCode, ColumnDimCode, RoundingFactor);
                            ExportItemBudgetToExcel.SetUpdateExistingWorksheet(true);
                            ExportItemBudgetToExcel.Run;
                        end;
                    }
                }
                action("Import from Excel")
                {
                    ApplicationArea = PurchaseBudget;
                    Caption = 'Import from Excel';
                    Ellipsis = true;
                    Image = ImportExcel;
                    ToolTip = 'Import a budget that you exported to Excel earlier.';

                    trigger OnAction()
                    var
                        ImportItemBudgetFromExcel: Report "Import Item Budget from Excel";
                    begin
                        ImportItemBudgetFromExcel.SetParameters(CurrentBudgetName, CurrentAnalysisArea, ValueType);
                        ImportItemBudgetFromExcel.RunModal;
                        Clear(ImportItemBudgetFromExcel);
                    end;
                }
            }
            action("Next Period")
            {
                ApplicationArea = PurchaseBudget;
                Caption = 'Next Period';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    if (LineDimOption = LineDimOption::Period) or (ColumnDimOption = ColumnDimOption::Period) then
                        exit;
                    FindPeriod('>');
                    CurrPage.Update;
                    UpdateMatrixSubForm;
                end;
            }
            action("Previous Period")
            {
                ApplicationArea = PurchaseBudget;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    if (LineDimOption = LineDimOption::Period) or (ColumnDimOption = ColumnDimOption::Period) then
                        exit;
                    FindPeriod('<');
                    CurrPage.Update;
                    UpdateMatrixSubForm;
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = PurchaseBudget;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                var
                    MATRIX_Step: Option Initial,Previous,Same,Next;
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_Step::Previous);
                    UpdateMatrixSubForm;
                end;
            }
            action("Previous Column")
            {
                ApplicationArea = PurchaseBudget;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Go to the previous column.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_Step::PreviousColumn);
                    UpdateMatrixSubForm;
                end;
            }
            action("Next Column")
            {
                ApplicationArea = PurchaseBudget;
                Caption = 'Next Column';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Go to the next column.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_Step::NextColumn);
                    UpdateMatrixSubForm;
                end;
            }
            action("Next Set")
            {
                ApplicationArea = PurchaseBudget;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                var
                    MATRIX_Step: Option Initial,Previous,Same,Next;
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_Step::Next);
                    UpdateMatrixSubForm;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        BudgetDim3FilterEnable := true;
        BudgetDim2FilterEnable := true;
        BudgetDim1FilterEnable := true;
    end;

    trigger OnOpenPage()
    begin
        if ValueType = 0 then
            ValueType := ValueType::"Cost Amount";
        CurrentAnalysisArea := CurrentAnalysisArea::Purchase;
        ItemBudgetManagement.BudgetNameSelection(
          CurrentAnalysisArea, CurrentBudgetName, ItemBudgetName, ItemStatisticsBuffer,
          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);

        if (NewBudgetName <> '') and (CurrentBudgetName <> NewBudgetName) then begin
            CurrentBudgetName := NewBudgetName;
            ItemBudgetManagement.CheckBudgetName(CurrentAnalysisArea, CurrentBudgetName, ItemBudgetName);
            ItemBudgetManagement.SetItemBudgetName(
              CurrentBudgetName, ItemBudgetName, ItemStatisticsBuffer,
              BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        end;

        ItemBudgetManagement.SetLineAndColDim(
          ItemBudgetName, LineDimCode, LineDimOption, ColumnDimCode, ColumnDimOption);

        GLSetup.Get();
        SourceTypeFilter := SourceTypeFilter::Vendor;

        UpdateDimCtrls;

        FindPeriod('');
        MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
        UpdateMatrixSubForm;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ItemBudgetName: Record "Item Budget Name";
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        MATRIX_MatrixRecords: array[32] of Record "Dimension Code Buffer";
        ItemBudgetManagement: Codeunit "Item Budget Management";
        MATRIX_CaptionSet: array[32] of Text[80];
        MATRIX_CaptionRange: Text;
        FirstColumn: Text;
        LastColumn: Text;
        MATRIX_PrimKeyFirstCaptionInCu: Text;
        MATRIX_CurrentNoOfColumns: Integer;
        CurrentAnalysisArea: Option Sale,Purchase,Inventory;
        CurrentBudgetName: Code[10];
        SourceTypeFilter: Option " ",Customer,Vendor,Item;
        SourceNoFilter: Text;
        ItemFilter: Text;
        ValueType: Option ,"Cost Amount",Quantity;
        RoundingFactor: Option "None","1","1000","1000000";
        LineDimOption: Option Item,Customer,Vendor,Period,Location,"Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3";
        ColumnDimOption: Option Item,Customer,Vendor,Period,Location,"Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        GlobalDim1Filter: Text;
        GlobalDim2Filter: Text;
        BudgetDim1Filter: Text;
        BudgetDim2Filter: Text;
        BudgetDim3Filter: Text;
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        DateFilter: Text;
        InternalDateFilter: Text;
        PeriodInitialized: Boolean;
        ShowColumnName: Boolean;
        Text003: Label '1,6,,Budget Dimension 1 Filter';
        Text004: Label '1,6,,Budget Dimension 2 Filter';
        Text005: Label '1,6,,Budget Dimension 3 Filter';
        Text100: Label 'Period';
        NewBudgetName: Code[10];
        MATRIX_Step: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn;
        [InDataSet]
        BudgetDim1FilterEnable: Boolean;
        [InDataSet]
        BudgetDim2FilterEnable: Boolean;
        [InDataSet]
        BudgetDim3FilterEnable: Boolean;

    local procedure MATRIX_GenerateColumnCaptions(MATRIX_SetWanted: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn)
    var
        Item: Record Item;
        Customer: Record Customer;
        Vendor: Record Vendor;
        Location: Record Location;
        MATRIX_PeriodRecords: array[32] of Record Date;
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        i: Integer;
    begin
        Clear(MATRIX_CaptionSet);
        Clear(MATRIX_MatrixRecords);
        FirstColumn := '';
        LastColumn := '';
        MATRIX_CurrentNoOfColumns := 12;

        if ColumnDimCode = '' then
            exit;

        case ColumnDimCode of
            Text100:  // Period
                begin
                    MatrixMgt.GeneratePeriodMatrixData(
                      MATRIX_SetWanted, 12, ShowColumnName,
                      PeriodType, DateFilter, MATRIX_PrimKeyFirstCaptionInCu,
                      MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns, MATRIX_PeriodRecords);
                    for i := 1 to 12 do begin
                        MATRIX_MatrixRecords[i]."Period Start" := MATRIX_PeriodRecords[i]."Period Start";
                        MATRIX_MatrixRecords[i]."Period End" := MATRIX_PeriodRecords[i]."Period End";
                    end;
                    FirstColumn := Format(MATRIX_PeriodRecords[1]."Period Start");
                    LastColumn := Format(MATRIX_PeriodRecords[MATRIX_CurrentNoOfColumns]."Period End");
                end;
            Location.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Location);
                    RecRef.SetTable(Location);
                    MatrixMgt.GenerateMatrixData(
                      RecRef, MATRIX_SetWanted, 12, 1,
                      MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                          RecRef, MATRIX_SetWanted::Same, 12, 2,
                          MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            Item.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Item);
                    RecRef.SetTable(Item);
                    if ItemFilter <> '' then begin
                        FieldRef := RecRef.Field(Item.FieldNo("No."));
                        FieldRef.SetFilter(ItemFilter);
                    end;
                    MatrixMgt.GenerateMatrixData(
                      RecRef, MATRIX_SetWanted, 12, 1,
                      MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                          RecRef, MATRIX_SetWanted::Same, 12, 3,
                          MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            Customer.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Customer);
                    RecRef.SetTable(Customer);
                    MatrixMgt.GenerateMatrixData(
                      RecRef, MATRIX_SetWanted, 12, 1,
                      MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                          RecRef, MATRIX_SetWanted::Same, 12, 2,
                          MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            Vendor.TableCaption:
                begin
                    Clear(MATRIX_CaptionSet);
                    RecRef.GetTable(Vendor);
                    RecRef.SetTable(Vendor);
                    if SourceNoFilter <> '' then begin
                        FieldRef := RecRef.Field(Vendor.FieldNo("No."));
                        FieldRef.SetFilter(SourceNoFilter);
                    end;
                    MatrixMgt.GenerateMatrixData(
                      RecRef, MATRIX_SetWanted, 12, 1,
                      MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                    for i := 1 to MATRIX_CurrentNoOfColumns do
                        MATRIX_MatrixRecords[i].Code := MATRIX_CaptionSet[i];
                    if ShowColumnName then
                        MatrixMgt.GenerateMatrixData(
                          RecRef, MATRIX_SetWanted::Same, 12, 2,
                          MATRIX_PrimKeyFirstCaptionInCu, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrentNoOfColumns);
                end;
            GLSetup."Global Dimension 1 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  GLSetup."Global Dimension 1 Code",
                  GlobalDim1Filter, MATRIX_SetWanted, MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            GLSetup."Global Dimension 2 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  GLSetup."Global Dimension 2 Code",
                  GlobalDim2Filter, MATRIX_SetWanted, MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            ItemBudgetName."Budget Dimension 1 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  ItemBudgetName."Budget Dimension 1 Code",
                  BudgetDim1Filter, MATRIX_SetWanted, MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            ItemBudgetName."Budget Dimension 2 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  ItemBudgetName."Budget Dimension 2 Code",
                  BudgetDim2Filter, MATRIX_SetWanted, MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
                  MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns, ShowColumnName, MATRIX_CaptionRange);
            ItemBudgetName."Budget Dimension 3 Code":
                MatrixMgt.GenerateDimColumnCaption(
                  ItemBudgetName."Budget Dimension 3 Code",
                  BudgetDim3Filter, MATRIX_SetWanted, MATRIX_PrimKeyFirstCaptionInCu, FirstColumn, LastColumn,
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

    local procedure GetCaptionClass(BudgetDimType: Integer): Text[250]
    begin
        if ItemBudgetName.Name <> CurrentBudgetName then
            ItemBudgetName.Get(CurrentAnalysisArea, CurrentBudgetName);
        case BudgetDimType of
            1:
                begin
                    if ItemBudgetName."Budget Dimension 1 Code" <> '' then
                        exit('1,6,' + ItemBudgetName."Budget Dimension 1 Code");
                    exit(Text003);
                end;
            2:
                begin
                    if ItemBudgetName."Budget Dimension 2 Code" <> '' then
                        exit('1,6,' + ItemBudgetName."Budget Dimension 2 Code");
                    exit(Text004);
                end;
            3:
                begin
                    if ItemBudgetName."Budget Dimension 3 Code" <> '' then
                        exit('1,6,' + ItemBudgetName."Budget Dimension 3 Code");
                    exit(Text005);
                end;
        end;
    end;

    local procedure LookUpDimFilter(Dim: Code[20]; var Text: Text[250]): Boolean
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        if Dim = '' then
            exit(false);
        DimVal.SetRange("Dimension Code", Dim);
        DimValList.SetTableView(DimVal);
        DimValList.LookupMode(true);
        if DimValList.RunModal = ACTION::LookupOK then begin
            DimValList.GetRecord(DimVal);
            Text := DimValList.GetSelectionFilter;
        end;
        exit(true);
    end;

    local procedure UpdateDimCtrls()
    begin
        BudgetDim1FilterEnable := ItemBudgetName."Budget Dimension 1 Code" <> '';
        BudgetDim2FilterEnable := ItemBudgetName."Budget Dimension 2 Code" <> '';
        BudgetDim3FilterEnable := ItemBudgetName."Budget Dimension 3 Code" <> '';
    end;

    procedure SetNewBudgetName(NewPurchBudgetName: Code[10])
    begin
        NewBudgetName := NewPurchBudgetName;
    end;

    local procedure UpdateMatrixSubForm()
    begin
        CurrPage.MATRIX.PAGE.SetFilters(
          DateFilter, ItemFilter, SourceNoFilter,
          GlobalDim1Filter, GlobalDim2Filter,
          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        CurrPage.MATRIX.PAGE.Load(
          MATRIX_CaptionSet, MATRIX_MatrixRecords, MATRIX_CurrentNoOfColumns,
          CurrentBudgetName, LineDimOption, ColumnDimOption, RoundingFactor, ValueType, PeriodType);
        CurrPage.Update(false);
    end;

    local procedure CurrentBudgetNameOnAfterValida()
    begin
        ItemBudgetManagement.SetItemBudgetName(
          CurrentBudgetName, ItemBudgetName, ItemStatisticsBuffer,
          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        ItemBudgetManagement.ValidateLineDimCode(
          ItemBudgetName, LineDimCode, LineDimOption, ColumnDimOption,
          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
        ItemBudgetManagement.ValidateColumnDimCode(
          ItemBudgetName, ColumnDimCode, ColumnDimOption, LineDimOption,
          InternalDateFilter, DateFilter, ItemStatisticsBuffer, PeriodInitialized);
        UpdateDimCtrls;
        CurrPage.Update(false);
    end;

    local procedure ColumnDimCodeOnAfterValidate()
    begin
        FindPeriod('');
        MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
        UpdateMatrixSubForm;
    end;

    local procedure LineDimCodeOnAfterValidate()
    begin
        FindPeriod('');
        MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
        UpdateMatrixSubForm;
    end;

    local procedure ValueTypeOnAfterValidate()
    begin
        FindPeriod('');
        MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
        UpdateMatrixSubForm;
    end;

    local procedure PeriodTypeOnAfterValidate()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
        if ColumnDimOption = ColumnDimOption::Period then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
        UpdateMatrixSubForm;
    end;

    local procedure ShowColumnNameOnAfterValidate()
    var
        MATRIX_SetWanted: Option First,Previous,Same,Next;
    begin
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Same);
        UpdateMatrixSubForm;
    end;

    local procedure RoundingFactorOnAfterValidate()
    begin
        UpdateMatrixSubForm;
    end;

    local procedure BudgetDim3FilterOnAfterValidat()
    begin
        if ColumnDimOption = ColumnDimOption::"Budget Dimension 3" then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
        UpdateMatrixSubForm;
    end;

    local procedure BudgetDim2FilterOnAfterValidat()
    begin
        if ColumnDimOption = ColumnDimOption::"Budget Dimension 2" then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
        UpdateMatrixSubForm;
    end;

    local procedure BudgetDim1FilterOnAfterValidat()
    begin
        if ColumnDimOption = ColumnDimOption::"Budget Dimension 1" then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
        UpdateMatrixSubForm;
    end;

    local procedure GlobalDim2FilterOnAfterValidat()
    begin
        if ColumnDimOption = ColumnDimOption::"Global Dimension 2" then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
        UpdateMatrixSubForm;
    end;

    local procedure GlobalDim1FilterOnAfterValidat()
    begin
        if ColumnDimOption = ColumnDimOption::"Global Dimension 1" then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
        UpdateMatrixSubForm;
    end;

    local procedure SourceNoFilterOnAfterValidate()
    begin
        if ColumnDimOption = ColumnDimOption::Vendor then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
        UpdateMatrixSubForm;
    end;

    local procedure ItemFilterOnAfterValidate()
    begin
        if ColumnDimOption = ColumnDimOption::Item then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
        UpdateMatrixSubForm;
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        if ColumnDimOption = ColumnDimOption::Period then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
        UpdateMatrixSubForm;
    end;
}

