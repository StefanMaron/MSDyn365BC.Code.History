page 554 "Analysis by Dimensions"
{
    Caption = 'Analysis by Dimensions';
    DataCaptionExpression = AnalysisViewCode;
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
                field(AnalysisViewCode; AnalysisViewCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Analysis View Code';
                    TableRelation = "Analysis View";
                    ToolTip = 'Specifies the code for the analysis view that the filter belongs to.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AnalysisViewList: Page "Analysis View List";
                    begin
                        AnalysisViewList.LookupMode := true;
                        AnalysisView.SetRange("Account Source", AnalysisView."Account Source");
                        AnalysisViewList.SetTableView(AnalysisView);
                        AnalysisViewList.SetRecord(AnalysisView);
                        if AnalysisViewList.RunModal = ACTION::LookupOK then begin
                            AnalysisViewList.GetRecord(AnalysisView);
                            AnalysisViewCode := AnalysisView.Code;
                            Text := AnalysisView.Code;
                            ValidateAnalysisViewCode;
                            ValidateColumnDimCode;
                            ValidateLineDimCode;
                            CurrPage.Update;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ValidateAnalysisViewCode;
                        ValidateColumnDimCode;
                        ValidateLineDimCode;
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
                        NewCode := GetDimSelection(LineDimCode);
                        if NewCode = LineDimCode then
                            exit(false);

                        Text := NewCode;
                        LineDimCode := NewCode;
                        ValidateLineDimCode;
                        CurrPage.Update;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            ColumnDimCode := '';
                            ValidateColumnDimCode;
                        end;
                        ValidateLineDimCode;
                        if LineDimOption = LineDimOption::Period then
                            SetCurrentKey("Period Start")
                        else
                            SetCurrentKey(Code);
                        CurrPage.Update;
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
                        NewCode := GetDimSelection(ColumnDimCode);
                        if NewCode = ColumnDimCode then
                            exit(false);

                        Text := NewCode;
                        ColumnDimCode := NewCode;
                        ValidateColumnDimCode;
                        CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
                        CurrPage.Update;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            LineDimCode := '';
                            ValidateLineDimCode;
                        end;
                        ValidateColumnDimCode;

                        CurrPage.Update;
                        CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
                    end;
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
                        GLAcc: Record "G/L Account";
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        GLAcc.SetFilter("Date Filter", DateFilter);
                        DateFilter := GLAcc.GetFilter("Date Filter");
                        InternalDateFilter := DateFilter;
                        if ColumnDimOption = ColumnDimOption::Period then
                            CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
                        CurrPage.Update;
                    end;
                }
                field(AccFilter; AccFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Account Filter';
                    ToolTip = 'Specifies a filter for the general ledger accounts for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLAccList: Page "G/L Account List";
                        CFAccList: Page "Cash Flow Account List";
                    begin
                        if GLAccountSource then begin
                            GLAccList.LookupMode(true);
                            if not (GLAccList.RunModal = ACTION::LookupOK) then
                                exit(false);

                            Text := GLAccList.GetSelectionFilter;
                        end else begin
                            CFAccList.LookupMode(true);
                            if not (CFAccList.RunModal = ACTION::LookupOK) then
                                exit(false);

                            Text := CFAccList.GetSelectionFilter;
                        end;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (ColumnDimOption = ColumnDimOption::"G/L Account") or (ColumnDimOption = ColumnDimOption::"Cash Flow Account") then
                            CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
                        CurrPage.Update;
                    end;
                }
                field(BusUnitFilter; BusUnitFilter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '3,' + BusUnitFilterCaption;
                    Visible = GLAccountSource;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BusUnitList: Page "Business Unit List";
                    begin
                        BusUnitList.LookupMode(true);
                        if not (BusUnitList.RunModal = ACTION::LookupOK) then
                            exit(false);
                        Text := BusUnitList.GetSelectionFilter;
                        exit(true);
                    end;
                }
                field(CashFlowFilter; CashFlowFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Cash Flow Forecast Filter';
                    LookupPageID = "Cash Flow Forecast List";
                    TableRelation = "Cash Flow Forecast";
                    ToolTip = 'Specifies the cash flow forecast that information in the matrix is shown for.';
                    Visible = (GLAccountSource = FALSE);

                    trigger OnValidate()
                    begin
                        if ColumnDimOption = ColumnDimOption::"Cash Flow Forecast" then
                            CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
                        CurrPage.Update;
                    end;
                }
                field(BudgetFilter; BudgetFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Budget Filter';
                    LookupPageID = "G/L Budget Names";
                    TableRelation = "G/L Budget Name".Name;
                    ToolTip = 'Specifies the budget that information in the matrix is shown for.';
                    Visible = GLAccountSource;
                }
                field(Dim1Filter; Dim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(1);
                    Caption = 'Dimension 1 Filter';
                    Enabled = Dim1FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 1 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(AnalysisView."Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        if ColumnDimOption = ColumnDimOption::"Dimension 1" then
                            CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
                        CurrPage.Update;
                    end;
                }
                field(Dim2Filter; Dim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(2);
                    Caption = 'Dimension 2 Filter';
                    Enabled = Dim2FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 2 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(AnalysisView."Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        if ColumnDimOption = ColumnDimOption::"Dimension 2" then
                            CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
                        CurrPage.Update;
                    end;
                }
                field(Dim3Filter; Dim3Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(3);
                    Caption = 'Dimension 3 Filter';
                    Enabled = Dim3FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 3 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(AnalysisView."Dimension 3 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        if ColumnDimOption = ColumnDimOption::"Dimension 3" then
                            CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
                        CurrPage.Update;
                    end;
                }
                field(Dim4Filter; Dim4Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = GetCaptionClass(4);
                    Caption = 'Dimension 4 Filter';
                    Enabled = Dim4FilterEnable;
                    ToolTip = 'Specifies a filter for the Dimension 4 for which entries will be shown in the matrix window.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookUpDimFilter(AnalysisView."Dimension 4 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        if ColumnDimOption = ColumnDimOption::"Dimension 4" then
                            CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
                        CurrPage.Update;
                    end;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field(ShowActualBudg; ShowActualBudg)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show';
                    OptionCaption = 'Actual Amounts,Budgeted Amounts,Variance,Variance%,Index%,Amounts';
                    ToolTip = 'Specifies if the selected value is shown in the window.';
                    Visible = GLAccountSource;
                }
                field(AmountField; AmountField)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Amount Field';
                    OptionCaption = 'Amount,Debit Amount,Credit Amount';
                    ToolTip = 'Specifies the type of entries that will be included in the matrix window. The Amount options means that amounts that are the sum of debit and credit amounts are shown.';
                }
                field(ClosingEntryFilter; ClosingEntryFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Closing Entries';
                    OptionCaption = 'Include,Exclude';
                    ToolTip = 'Specifies whether the amounts shown in the matrix window will include closing entries.';
                    Visible = GLAccountSource;

                    trigger OnValidate()
                    begin
                        FindPeriod('=');
                    end;
                }
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Rounding Factor';
                    OptionCaption = 'None,1,1000,1000000';
                    ToolTip = 'Specifies the factor that is used to round the amounts.';
                }
                field(ShowInAddCurr; ShowInAddCurr)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Amounts in Add. Reporting Currency';
                    MultiLine = true;
                    ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                    Visible = GLAccountSource;
                }
                field(ShowColumnName; ShowColumnName)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Column Name';
                    ToolTip = 'Specifies that the names of columns are shown in the matrix window.';

                    trigger OnValidate()
                    begin
                        CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
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
                            CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
                    end;
                }
                field(ColumnsSet; ColumnsSet)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Column Set';
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
                field(QtyType; QtyType)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'View as';
                    OptionCaption = 'Net Change,Balance at Date';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';
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
                        ValidateLineDimCode;
                        ValidateColumnDimCode;
                        CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
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
                PromotedOnly = true;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Analysis by Dimensions Matrix";
                begin
                    Clear(MatrixForm);

                    if GLAccountSource then
                        CashFlowFilter := '';

                    MatrixForm.Load(
                      LineDimOption, ColumnDimOption, LineDimCode, ColumnDimCode, PeriodType, DateFilter, AccFilter,
                      BusUnitFilter, BudgetFilter, Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter, CashFlowFilter);
                    MatrixForm.Load(
                      QtyType, AnalysisViewCode, ShowOppositeSign, ShowColumnName,
                      ShowActualBudg, AmountField, ClosingEntryFilter, RoundingFactor, ShowInAddCurr,
                      ColumnCaptions, PrimaryKeyFirstColInSet);

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
                PromotedOnly = true;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    CreateCaptionSet(Rec, Step::Previous, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
                end;
            }
            action("Next Set")
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
                    CreateCaptionSet(Rec, Step::Next, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(FindRec(LineDimOption, Rec, Which));
    end;

    trigger OnInit()
    begin
        Dim4FilterEnable := true;
        Dim3FilterEnable := true;
        Dim2FilterEnable := true;
        Dim1FilterEnable := true;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(NextRec(LineDimOption, Rec, Steps));
    end;

    trigger OnOpenPage()
    var
        GLAcc: Record "G/L Account";
        "Field": Record "Field";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        if (NewAnalysisViewCode <> '') and (NewAnalysisViewCode <> AnalysisViewCode) then
            AnalysisViewCode := NewAnalysisViewCode;

        ValidateAnalysisViewCode;

        GLSetup.Get;
        if GLSetup."Additional Reporting Currency" = '' then
            ShowInAddCurr := false
        else
            Currency.Get(GLSetup."Additional Reporting Currency");

        if GLAccountSource then
            LineDimCode := GLAcc.TableCaption
        else
            LineDimCode := CashFlowAccount.TableCaption;
        ColumnDimCode := Text000;

        LineDimOption := DimCodeToOption(LineDimCode);
        ColumnDimOption := DimCodeToOption(ColumnDimCode);
        if GLAccountSource then begin
            Field.Get(DATABASE::"G/L Account", 42);
            BusUnitFilterCaption := Field."Field Caption";
        end;

        FindPeriod('');

        CreateCaptionSet(Rec, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, ColumnsSet);
    end;

    var
        Text000: Label 'Period';
        Text002: Label 'You have not yet defined an analysis view.';
        Text003: Label '%1 is not a valid line definition.';
        Text004: Label '%1 is not a valid column definition.';
        Text005: Label '1,6,,Dimension 1 Filter';
        Text006: Label '1,6,,Dimension 2 Filter';
        Text007: Label '1,6,,Dimension 3 Filter';
        Text008: Label '1,6,,Dimension 4 Filter';
        GLSetup: Record "General Ledger Setup";
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        Currency: Record Currency;
        LineDimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast";
        ColumnDimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";
        RoundingFactor: Option "None","1","1000","1000000";
        AmountField: Option Amount,"Debit Amount","Credit Amount";
        ShowActualBudg: Option "Actual Amounts","Budgeted Amounts",Variance,"Variance%","Index%",Amounts;
        ClosingEntryFilter: Option Include,Exclude;
        [InDataSet]
        GLAccountSource: Boolean;
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        DateFilter: Text;
        InternalDateFilter: Text;
        CashFlowFilter: Text;
        ColumnCaptions: array[32] of Text[80];
        PrimaryKeyFirstColInSet: Text[1024];
        ColumnsSet: Text[1024];
        AnalysisViewCode: Code[10];
        NewAnalysisViewCode: Code[10];
        AccFilter: Text;
        BudgetFilter: Text;
        Dim1Filter: Text;
        Dim2Filter: Text;
        Dim3Filter: Text;
        Dim4Filter: Text;
        ShowOppositeSign: Boolean;
        ShowColumnName: Boolean;
        PeriodInitialized: Boolean;
        ShowInAddCurr: Boolean;
        BusUnitFilter: Text;
        Step: Option First,Previous,Same,Next;
        QtyType: Option "Net Change","Balance at Date";
        BusUnitFilterCaption: Text[80];
        [InDataSet]
        Dim1FilterEnable: Boolean;
        [InDataSet]
        Dim2FilterEnable: Boolean;
        [InDataSet]
        Dim3FilterEnable: Boolean;
        [InDataSet]
        Dim4FilterEnable: Boolean;
        Text009: Label 'Unsupported Account Source %1.';

    local procedure DimCodeToOption(DimCode: Text[30]): Integer
    var
        AccountCaption: Text[30];
        UnitCaption: Text[30];
    begin
        GetAccountCaption(AccountCaption, UnitCaption);
        case DimCode of
            AccountCaption:
                begin
                    if GLAccountSource then
                        exit(0);
                    exit(7);
                end;
            Text000:
                exit(1);
            UnitCaption:
                begin
                    if GLAccountSource then
                        exit(2);
                    exit(8);
                end;
            AnalysisView."Dimension 1 Code":
                exit(3);
            AnalysisView."Dimension 2 Code":
                exit(4);
            AnalysisView."Dimension 3 Code":
                exit(5);
            AnalysisView."Dimension 4 Code":
                exit(6);
            else
                exit(-1);
        end;
    end;

    local procedure FindRec(DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]): Boolean
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        CFAccount: Record "Cash Flow Account";
        CashFlowForecast: Record "Cash Flow Forecast";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        Found: Boolean;
    begin
        case DimOption of
            DimOption::"G/L Account":
                begin
                    GLAcc."No." := DimCodeBuf.Code;
                    if AccFilter <> '' then
                        GLAcc.SetFilter("No.", AccFilter);
                    Found := GLAcc.Find(Which);
                    if Found then
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                end;
            DimOption::"Cash Flow Account":
                begin
                    CFAccount."No." := DimCodeBuf.Code;
                    if AccFilter <> '' then
                        CFAccount.SetFilter("No.", AccFilter);
                    Found := CFAccount.Find(Which);
                    if Found then
                        CopyCFAccToBuf(CFAccount, DimCodeBuf);
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
                        CopyPeriodToBuf(Period, DimCodeBuf);
                end;
            DimOption::"Business Unit":
                begin
                    BusUnit.Code := DimCodeBuf.Code;
                    if BusUnitFilter <> '' then
                        BusUnit.SetFilter(Code, BusUnitFilter);
                    Found := BusUnit.Find(Which);
                    if Found then
                        CopyBusUnitToBuf(BusUnit, DimCodeBuf);
                end;
            DimOption::"Cash Flow Forecast":
                begin
                    CashFlowForecast."No." := DimCodeBuf.Code;
                    if CashFlowFilter <> '' then
                        CashFlowForecast.SetFilter("No.", CashFlowFilter);
                    Found := CashFlowForecast.Find(Which);
                    if Found then
                        CopyCashFlowToBuf(CashFlowForecast, DimCodeBuf);
                end;
            DimOption::"Dimension 1":
                begin
                    if Dim1Filter <> '' then
                        DimVal.SetFilter(Code, Dim1Filter);
                    DimVal."Dimension Code" := AnalysisView."Dimension 1 Code";
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
                    DimVal."Dimension Code" := AnalysisView."Dimension 2 Code";
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
                    DimVal."Dimension Code" := AnalysisView."Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 4":
                begin
                    if Dim4Filter <> '' then
                        DimVal.SetFilter(Code, Dim4Filter);
                    DimVal."Dimension Code" := AnalysisView."Dimension 4 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;
        exit(Found);
    end;

    local procedure NextRec(DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer): Integer
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        CFAccount: Record "Cash Flow Account";
        CashFlowForecast: Record "Cash Flow Forecast";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        ResultSteps: Integer;
    begin
        case DimOption of
            DimOption::"G/L Account":
                begin
                    GLAcc."No." := DimCodeBuf.Code;
                    if AccFilter <> '' then
                        GLAcc.SetFilter("No.", AccFilter);
                    ResultSteps := GLAcc.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                end;
            DimOption::"Cash Flow Account":
                begin
                    CFAccount."No." := DimCodeBuf.Code;
                    if AccFilter <> '' then
                        CFAccount.SetFilter("No.", AccFilter);
                    ResultSteps := CFAccount.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyCFAccToBuf(CFAccount, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter);
                    Period."Period Start" := DimCodeBuf."Period Start";
                    ResultSteps := PeriodFormMgt.NextDate(Steps, Period, PeriodType);
                    if ResultSteps <> 0 then
                        CopyPeriodToBuf(Period, DimCodeBuf);
                end;
            DimOption::"Business Unit":
                begin
                    BusUnit.Code := DimCodeBuf.Code;
                    if BusUnitFilter <> '' then
                        BusUnit.SetFilter(Code, BusUnitFilter);
                    ResultSteps := BusUnit.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyBusUnitToBuf(BusUnit, DimCodeBuf);
                end;
            DimOption::"Cash Flow Forecast":
                begin
                    CashFlowForecast."No." := DimCodeBuf.Code;
                    if CashFlowFilter <> '' then
                        CashFlowForecast.SetFilter("No.", CashFlowFilter);
                    ResultSteps := CashFlowForecast.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyCashFlowToBuf(CashFlowForecast, DimCodeBuf);
                end;
            DimOption::"Dimension 1":
                begin
                    if Dim1Filter <> '' then
                        DimVal.SetFilter(Code, Dim1Filter);
                    DimVal."Dimension Code" := AnalysisView."Dimension 1 Code";
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
                    DimVal."Dimension Code" := AnalysisView."Dimension 2 Code";
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
                    DimVal."Dimension Code" := AnalysisView."Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 4":
                begin
                    if Dim4Filter <> '' then
                        DimVal.SetFilter(Code, Dim4Filter);
                    DimVal."Dimension Code" := AnalysisView."Dimension 4 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;
        exit(ResultSteps);
    end;

    local procedure CopyGLAccToBuf(var TheGLAcc: Record "G/L Account"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init;
            Code := TheGLAcc."No.";
            Name := TheGLAcc.Name;
            Totaling := TheGLAcc.Totaling;
            Indentation := TheGLAcc.Indentation;
            "Show in Bold" := TheGLAcc."Account Type" <> TheGLAcc."Account Type"::Posting;
        end;
    end;

    local procedure CopyCFAccToBuf(var TheCFAcc: Record "Cash Flow Account"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init;
            Code := TheCFAcc."No.";
            Name := TheCFAcc.Name;
            Totaling := TheCFAcc.Totaling;
            Indentation := TheCFAcc.Indentation;
            "Show in Bold" := TheCFAcc."Account Type" <> TheCFAcc."Account Type"::Entry;
        end;
    end;

    local procedure CopyPeriodToBuf(var ThePeriod: Record Date; var TheDimCodeBuf: Record "Dimension Code Buffer")
    var
        Period2: Record Date;
    begin
        with TheDimCodeBuf do begin
            Init;
            Code := Format(ThePeriod."Period Start");
            "Period Start" := ThePeriod."Period Start";
            if ClosingEntryFilter = ClosingEntryFilter::Include then
                "Period End" := ClosingDate(ThePeriod."Period End")
            else
                "Period End" := ThePeriod."Period End";
            if DateFilter <> '' then begin
                Period2.SetFilter("Period End", DateFilter);
                if Period2.GetRangeMax("Period End") < "Period End" then
                    "Period End" := Period2.GetRangeMax("Period End");
            end;
            Name := ThePeriod."Period Name";
        end;
    end;

    local procedure CopyBusUnitToBuf(var TheBusUnit: Record "Business Unit"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init;
            Code := TheBusUnit.Code;
            Name := TheBusUnit.Name;
        end;
    end;

    local procedure CopyCashFlowToBuf(var TheCashFlowForecast: Record "Cash Flow Forecast"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init;
            Code := TheCashFlowForecast."No.";
            Name := TheCashFlowForecast.Description;
        end;
    end;

    local procedure CopyDimValueToBuf(var TheDimVal: Record "Dimension Value"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init;
            Code := TheDimVal.Code;
            Name := TheDimVal.Name;
            Totaling := TheDimVal.Totaling;
            Indentation := TheDimVal.Indentation;
            "Show in Bold" :=
              TheDimVal."Dimension Value Type" <> TheDimVal."Dimension Value Type"::Standard;
        end;
    end;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
        TempDate: Date;
    begin
        if not PeriodInitialized then
            DateFilter := '';
        if (DateFilter <> '') and Evaluate(TempDate, DateFilter) then begin
            Calendar.SetFilter("Period Start", DateFilter);
            if not PeriodFormMgt.FindDate('+', Calendar, PeriodType) then
                PeriodFormMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        if PeriodFormMgt.FindDate(SearchText, Calendar, PeriodType) then
            if ClosingEntryFilter = ClosingEntryFilter::Include then
                Calendar."Period End" := ClosingDate(Calendar."Period End");
        if AmountType = AmountType::"Net Change" then begin
            AnalysisViewEntry.SetRange("Posting Date", Calendar."Period Start", Calendar."Period End");
            if AnalysisViewEntry.GetRangeMin("Posting Date") = AnalysisViewEntry.GetRangeMax("Posting Date") then
                AnalysisViewEntry.SetRange("Posting Date", AnalysisViewEntry.GetRangeMin("Posting Date"));
        end else
            AnalysisViewEntry.SetRange("Posting Date", 0D, Calendar."Period End");

        InternalDateFilter := AnalysisViewEntry.GetFilter("Posting Date");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then
            DateFilter := InternalDateFilter;
    end;

    local procedure GetDimSelection(OldDimSelCode: Text[30]): Text[30]
    var
        DimSelection: Page "Dimension Selection";
        AccountCaption: Text[30];
        UnitCaption: Text[30];
    begin
        GetAccountCaption(AccountCaption, UnitCaption);
        DimSelection.InsertDimSelBuf(false, AccountCaption, AccountCaption);
        DimSelection.InsertDimSelBuf(false, Text000, Text000);
        DimSelection.InsertDimSelBuf(false, UnitCaption, UnitCaption);

        if AnalysisView."Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 1 Code", '');
        if AnalysisView."Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 2 Code", '');
        if AnalysisView."Dimension 3 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 3 Code", '');
        if AnalysisView."Dimension 4 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 4 Code", '');

        DimSelection.LookupMode := true;
        if DimSelection.RunModal = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode);

        exit(OldDimSelCode);
    end;

    local procedure LookUpDimFilter(Dim: Code[20]; var Text: Text): Boolean
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
        exit(false)
    end;

    local procedure ValidateAnalysisViewCode()
    var
        AnalysisViewFilter: Record "Analysis View Filter";
    begin
        AnalysisView.Code := AnalysisViewCode;
        if not AnalysisView.Find('=<>') then
            Error(Text002);
        AnalysisViewCode := AnalysisView.Code;
        AccFilter := AnalysisView."Account Filter";
        Dim1Filter := '';
        Dim2Filter := '';
        Dim3Filter := '';
        Dim4Filter := '';
        Dim1Filter := GetFilter("Dimension 1 Value Filter");
        Dim2Filter := GetFilter("Dimension 2 Value Filter");
        Dim3Filter := GetFilter("Dimension 3 Value Filter");
        Dim4Filter := GetFilter("Dimension 4 Value Filter");

        Dim1FilterEnable :=
          (AnalysisView."Dimension 1 Code" <> '') and
          (GetFilter("Dimension 1 Value Filter") = '');
        Dim2FilterEnable :=
          (AnalysisView."Dimension 2 Code" <> '') and
          (GetFilter("Dimension 2 Value Filter") = '');
        Dim3FilterEnable :=
          (AnalysisView."Dimension 3 Code" <> '') and
          (GetFilter("Dimension 3 Value Filter") = '');
        Dim4FilterEnable :=
          (AnalysisView."Dimension 4 Code" <> '') and
          (GetFilter("Dimension 4 Value Filter") = '');

        if Dim1FilterEnable then
            if AnalysisViewFilter.Get(AnalysisView.Code, AnalysisView."Dimension 1 Code") then
                Dim1Filter := AnalysisViewFilter."Dimension Value Filter";

        if Dim2FilterEnable then
            if AnalysisViewFilter.Get(AnalysisView.Code, AnalysisView."Dimension 2 Code") then
                Dim2Filter := AnalysisViewFilter."Dimension Value Filter";

        if Dim3FilterEnable then
            if AnalysisViewFilter.Get(AnalysisView.Code, AnalysisView."Dimension 3 Code") then
                Dim3Filter := AnalysisViewFilter."Dimension Value Filter";

        if Dim4FilterEnable then
            if AnalysisViewFilter.Get(AnalysisView.Code, AnalysisView."Dimension 4 Code") then
                Dim4Filter := AnalysisViewFilter."Dimension Value Filter";

        case AnalysisView."Account Source" of
            AnalysisView."Account Source"::"G/L Account":
                GLAccountSource := true;
            AnalysisView."Account Source"::"Cash Flow Account":
                GLAccountSource := false;
            else
                Error(Text009, AnalysisView."Account Source");
        end;
    end;

    local procedure ValidateLineDimCode()
    var
        AccountCaption: Text[30];
        UnitCaption: Text[30];
    begin
        GetAccountCaption(AccountCaption, UnitCaption);

        if (UpperCase(LineDimCode) <> UpperCase(AccountCaption)) and
           (UpperCase(LineDimCode) <> UpperCase(UnitCaption)) and
           (UpperCase(LineDimCode) <> UpperCase(Text000)) and
           (UpperCase(LineDimCode) <> AnalysisView."Dimension 1 Code") and
           (UpperCase(LineDimCode) <> AnalysisView."Dimension 2 Code") and
           (UpperCase(LineDimCode) <> AnalysisView."Dimension 3 Code") and
           (UpperCase(LineDimCode) <> AnalysisView."Dimension 4 Code") and
           (LineDimCode <> '')
        then begin
            Message(Text003, LineDimCode);
            LineDimCode := '';
        end;
        LineDimOption := DimCodeToOption(LineDimCode);
        InternalDateFilter := AnalysisViewEntry.GetFilter("Posting Date");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end;
    end;

    local procedure ValidateColumnDimCode()
    var
        AccountCaption: Text[30];
        UnitCaption: Text[30];
    begin
        GetAccountCaption(AccountCaption, UnitCaption);

        if (UpperCase(ColumnDimCode) <> UpperCase(AccountCaption)) and
           (UpperCase(ColumnDimCode) <> UpperCase(UnitCaption)) and
           (UpperCase(ColumnDimCode) <> UpperCase(Text000)) and
           (UpperCase(ColumnDimCode) <> AnalysisView."Dimension 1 Code") and
           (UpperCase(ColumnDimCode) <> AnalysisView."Dimension 2 Code") and
           (UpperCase(ColumnDimCode) <> AnalysisView."Dimension 3 Code") and
           (UpperCase(ColumnDimCode) <> AnalysisView."Dimension 4 Code") and
           (ColumnDimCode <> '')
        then begin
            Message(Text004, ColumnDimCode);
            ColumnDimCode := '';
        end;
        ColumnDimOption := DimCodeToOption(ColumnDimCode);
        InternalDateFilter := AnalysisViewEntry.GetFilter("Posting Date");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    local procedure GetCaptionClass(AnalysisViewDimType: Integer): Text[250]
    begin
        if AnalysisView.Code <> AnalysisViewCode then
            AnalysisView.Get(AnalysisViewCode);
        case AnalysisViewDimType of
            1:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 1 Code");

                    exit(Text005);
                end;
            2:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 2 Code");

                    exit(Text006);
                end;
            3:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 3 Code");

                    exit(Text007);
                end;
            4:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 4 Code");

                    exit(Text008);
                end;
        end;
    end;

    local procedure CreateCaptionSet(RecRef: Record "Dimension Code Buffer"; Step: Option First,Previous,Same,Next; MaximumNoOfCaptions: Integer; var PrimaryKeyFirstCaptionInCurrSe: Text[1024]; var CaptionSet: array[32] of Text[1024]; var CaptionRange: Text[1024])
    var
        CurrentCaptionOrdinal: Integer;
    begin
        Clear(CaptionSet);
        CaptionRange := '';

        CurrentCaptionOrdinal := 0;

        case Step of
            Step::First:
                begin
                    if (ColumnDimOption = ColumnDimOption::Period) and (DateFilter = '') then
                        FindRec(ColumnDimOption, RecRef, '=><')
                    else
                        if not FindRec(ColumnDimOption, RecRef, '-') then
                            exit;
                end;
            Step::Previous:
                begin
                    RecRef.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
                    if ColumnDimOption = ColumnDimOption::Period then
                        Evaluate(RecRef."Period Start", RecRef.Code);
                    if not FindRec(ColumnDimOption, RecRef, '=') then
                        exit;
                    NextRec(ColumnDimOption, RecRef, -MaximumNoOfCaptions);
                end;
            Step::Same:
                begin
                    RecRef.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
                    if ColumnDimOption = ColumnDimOption::Period then
                        Evaluate(RecRef."Period Start", RecRef.Code);
                    if not FindRec(ColumnDimOption, RecRef, '=') then
                        exit;
                end;
            Step::Next:
                begin
                    RecRef.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
                    if ColumnDimOption = ColumnDimOption::Period then
                        Evaluate(RecRef."Period Start", RecRef.Code);
                    if not FindRec(ColumnDimOption, RecRef, '=') then
                        exit;
                    if not (NextRec(ColumnDimOption, RecRef, MaximumNoOfCaptions) = MaximumNoOfCaptions) then begin
                        RecRef.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
                        FindRec(ColumnDimOption, RecRef, '=');
                    end;
                end;
        end;

        PrimaryKeyFirstCaptionInCurrSe := RecRef.GetPosition;

        repeat
            CurrentCaptionOrdinal := CurrentCaptionOrdinal + 1;
            if ShowColumnName then
                CaptionSet[CurrentCaptionOrdinal] := RecRef.Name
            else
                CaptionSet[CurrentCaptionOrdinal] := RecRef.Code;
        until (CurrentCaptionOrdinal = MaximumNoOfCaptions) or (NextRec(ColumnDimOption, RecRef, 1) <> 1);

        if CurrentCaptionOrdinal = 1 then
            CaptionRange := CaptionSet[1]
        else
            CaptionRange := CopyStr(CaptionSet[1] + '..' + CaptionSet[CurrentCaptionOrdinal], 1, MaxStrLen(CaptionRange));
    end;

    procedure SetAnalysisViewCode(NextAnalysisViewCode: Code[10])
    begin
        NewAnalysisViewCode := NextAnalysisViewCode;
    end;

    local procedure GetAccountCaption(var AccountCaption: Text[30]; var UnitCaption: Text[30])
    var
        GLAcc: Record "G/L Account";
        CFAccount: Record "Cash Flow Account";
        BusUnit: Record "Business Unit";
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        if GLAccountSource then begin
            AccountCaption := GLAcc.TableCaption;
            UnitCaption := BusUnit.TableCaption;
        end else begin
            AccountCaption := CFAccount.TableCaption;
            UnitCaption := CashFlowForecast.TableCaption;
        end;
    end;
}

