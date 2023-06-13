page 554 "Analysis by Dimensions"
{
    Caption = 'Analysis by Dimensions';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Analysis by Dim. Parameters";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(AnalysisViewCode; "Analysis View Code")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Analysis View Code';
                    TableRelation = "Analysis View";
                    ToolTip = 'Specifies the code for the analysis view that the filter belongs to.';
                    Editable = false;
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
                        ValidateLineDimCode();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            ColumnDimCode := '';
                            ValidateColumnDimCode();
                        end;
                        ValidateLineDimCode();
                        if "Line Dim Option" = "Line Dim Option"::Period then
                            TempDimensionCodeBuffer.SetCurrentKey("Period Start")
                        else
                            TempDimensionCodeBuffer.SetCurrentKey(Code);
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
                        ValidateColumnDimCode();
                        CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            LineDimCode := '';
                            ValidateLineDimCode();
                        end;
                        ValidateColumnDimCode();

                        CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                    end;
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(DateFilter; "Date Filter")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        GLAcc: Record "G/L Account";
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter("Date Filter");
                        GLAcc.SetFilter("Date Filter", "Date Filter");
                        "Date Filter" := GLAcc.GetFilter("Date Filter");
                        InternalDateFilter := "Date Filter";
                        if "Column Dim Option" = "Column Dim Option"::Period then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                    end;
                }
                field(AccFilter; "Account Filter")
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
                            if not (GLAccList.RunModal() = ACTION::LookupOK) then
                                exit(false);

                            Text := GLAccList.GetSelectionFilter();
                        end else begin
                            CFAccList.LookupMode(true);
                            if not (CFAccList.RunModal() = ACTION::LookupOK) then
                                exit(false);

                            Text := CFAccList.GetSelectionFilter();
                        end;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if ("Column Dim Option" = "Column Dim Option"::"G/L Account") or ("Column Dim Option" = "Column Dim Option"::"Cash Flow Account") then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                    end;
                }
                field(BusUnitFilter; "Bus. Unit Filter")
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '3,' + BusUnitFilterCaption;
                    Visible = GLAccountSource;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BusUnitList: Page "Business Unit List";
                    begin
                        BusUnitList.LookupMode(true);
                        if not (BusUnitList.RunModal() = ACTION::LookupOK) then
                            exit(false);
                        Text := BusUnitList.GetSelectionFilter();
                        exit(true);
                    end;
                }
                field(CashFlowFilter; "Cash Flow Forecast Filter")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Cash Flow Forecast Filter';
                    LookupPageID = "Cash Flow Forecast List";
                    TableRelation = "Cash Flow Forecast";
                    ToolTip = 'Specifies the cash flow forecast that information in the matrix is shown for.';
                    Visible = (GLAccountSource = FALSE);

                    trigger OnValidate()
                    begin
                        if "Column Dim Option" = "Column Dim Option"::"Cash Flow Forecast" then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                    end;
                }
                field(BudgetFilter; "Budget Filter")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Budget Filter';
                    LookupPageID = "G/L Budget Names";
                    TableRelation = "G/L Budget Name".Name;
                    ToolTip = 'Specifies the budget that information in the matrix is shown for.';
                    Visible = GLAccountSource;
                }
                field(Dim1Filter; "Dimension 1 Filter")
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
                        if "Column Dim Option" = "Column Dim Option"::"Dimension 1" then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                    end;
                }
                field(Dim2Filter; "Dimension 2 Filter")
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
                        if "Column Dim Option" = "Column Dim Option"::"Dimension 2" then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                    end;
                }
                field(Dim3Filter; "Dimension 3 Filter")
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
                        if "Column Dim Option" = "Column Dim Option"::"Dimension 3" then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                    end;
                }
                field(Dim4Filter; "Dimension 4 Filter")
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
                        if "Column Dim Option" = "Column Dim Option"::"Dimension 4" then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                    end;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field(ShowActualBudg; "Show Actual/Budgets")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies if the selected value is shown in the window.';
                    Visible = GLAccountSource;
                }
                field(AmountField; "Show Amount Field")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Amount Field';
                    ToolTip = 'Specifies the type of entries that will be included in the matrix window. The Amount options means that amounts that are the sum of debit and credit amounts are shown.';
                }
                field(ClosingEntryFilter; "Closing Entries")
                {
                    ApplicationArea = Dimensions;
                    OptionCaption = 'Include,Exclude';
                    ToolTip = 'Specifies whether the amounts shown in the matrix window will include closing entries.';
                    Visible = GLAccountSource;

                    trigger OnValidate()
                    begin
                        FindPeriod('=');
                    end;
                }
                field(RoundingFactor; "Rounding Factor")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the factor that is used to round the amounts.';
                }
                field(ShowInAddCurr; "Show In Add. Currency")
                {
                    ApplicationArea = Dimensions;
                    MultiLine = true;
                    ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                    Visible = GLAccountSource;
                }
                field(ShowColumnName; "Show Column Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that the names of columns are shown in the matrix window.';

                    trigger OnValidate()
                    begin
                        CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                    end;
                }
                field(ShowOppositeSign; "Show Opposite Sign")
                {
                    ApplicationArea = Dimensions;
                    MultiLine = true;
                    ToolTip = 'Specifies whether to show debits as negative amounts (with minus signs) and credits as positive amounts in the matrix window.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; "Period Type")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        if "Column Dim Option" = "Column Dim Option"::Period then
                            CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                    end;
                }
                field(ColumnsSet; "Column Set")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
                field(QtyType; "Amount Type")
                {
                    ApplicationArea = Dimensions;
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
                    ToolTip = 'Change the display of the matrix by inverting the values in the Show as Lines and Show as Columns fields.';

                    trigger OnAction()
                    var
                        TempDimCode: Text[30];
                    begin
                        TempDimCode := ColumnDimCode;
                        ColumnDimCode := LineDimCode;
                        LineDimCode := TempDimCode;
                        ValidateLineDimCode();
                        ValidateColumnDimCode();
                        CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
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
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Analysis by Dimensions Matrix";
                begin
                    Clear(MatrixForm);

                    if GLAccountSource then
                        "Cash Flow Forecast Filter" := '';

                    MatrixForm.Load(Rec, LineDimCode, ColumnDimCode, ColumnCaptions, PrimaryKeyFirstColInSet);
                    MatrixForm.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Dimensions;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    CreateCaptionSet(TempDimensionCodeBuffer, Step::Previous, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Dimensions;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    CreateCaptionSet(TempDimensionCodeBuffer, Step::Next, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
                actionref(ShowMatrix_Promoted; ShowMatrix)
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
                actionref("Reverse Lines and Columns_Promoted"; "Reverse Lines and Columns")
                {
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(FindRecord("Line Dim Option", TempDimensionCodeBuffer, Which));
    end;

    trigger OnInit()
    begin
        Dim4FilterEnable := true;
        Dim3FilterEnable := true;
        Dim2FilterEnable := true;
        Dim1FilterEnable := true;
    end;

    trigger OnOpenPage()
    var
        GLAcc: Record "G/L Account";
        "Field": Record "Field";
        CashFlowAccount: Record "Cash Flow Account";
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
        AccountCaption: Text[30];
        UnitCaption: Text[30];
    begin
        OnBeforeOpenPage(Rec);
        if (NewAnalysisViewCode <> '') and (NewAnalysisViewCode <> "Analysis View Code") then
            "Analysis View Code" := NewAnalysisViewCode;
        AnalysisByDimUserParam.Load(Rec, Page::"Analysis by Dimensions");
        ValidateAnalysisViewCode();

        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" = '' then
            "Show In Add. Currency" := false
        else
            Currency.Get(GLSetup."Additional Reporting Currency");

        case Rec."Analysis Account Source" of
            Rec."Analysis Account Source"::"G/L Account":
                LineDimCode := GLAcc.TableCaption;
            Rec."Analysis Account Source"::"Cash Flow Account":
                LineDimCode := CashFlowAccount.TableCaption();
            else
                OnGetCaptions(AnalysisView, LineDimCode, AccountCaption, UnitCaption, true);
        end;
        ColumnDimCode := Text000;

        "Line Dim Option" := DimCodeToDimOption(LineDimCode);
        "Column Dim Option" := DimCodeToDimOption(ColumnDimCode);
        if GLAccountSource then begin
            Field.Get(DATABASE::"G/L Account", 42);
            BusUnitFilterCaption := Field."Field Caption";
        end;

        FindPeriod('');

        CreateCaptionSet(TempDimensionCodeBuffer, Step::First, 32, PrimaryKeyFirstColInSet, ColumnCaptions, "Column Set");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
    begin
        AnalysisByDimUserParam.Save(Rec, Page::"Analysis by Dimensions");
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
        AmountType: Enum "Analysis Amount Type";
        [InDataSet]
        GLAccountSource: Boolean;
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        InternalDateFilter: Text;
        NewAnalysisViewCode: Code[10];
        PeriodInitialized: Boolean;
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

    protected var
        TempDimensionCodeBuffer: Record "Dimension Code Buffer" temporary;
        ColumnCaptions: array[32] of Text[80];
        PrimaryKeyFirstColInSet: Text[1024];
        Step: Option First,Previous,Same,Next;

#if not CLEAN20
    [Obsolete('Replaced by DimCodeToDimOption()', '20.0')]
    procedure DimCodeToOption(DimCode: Text[30]) Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDimCodeToOption(DimCode, AnalysisView, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(DimCodeToDimOption(DimCode).AsInteger());
    end;
#endif

    procedure DimCodeToDimOption(DimCode: Text[30]) Result: Enum "Analysis Dimension Option"
    var
        AccountCaption: Text[30];
        UnitCaption: Text[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDimCodeToDimOption(DimCode, AnalysisView, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GetAccountCaption(AccountCaption, UnitCaption);
        case DimCode of
            AccountCaption:
                case Rec."Analysis Account Source" of
                    Rec."Analysis Account Source"::"G/L Account":
                        exit("Analysis Dimension Option"::"G/L Account");
                    Rec."Analysis Account Source"::"Cash Flow Account":
                        exit("Analysis Dimension Option"::"Cash Flow Account");
                    else begin
                        OnGetAnalysisViewDimensionOption(AnalysisView, Result, DimCode);
                        exit(Result);
                    end;
                end;
            Text000:
                exit("Analysis Dimension Option"::Period);
            UnitCaption:
                case Rec."Analysis Account Source" of
                    Rec."Analysis Account Source"::"G/L Account":
                        exit("Analysis Dimension Option"::"Business Unit");
                    Rec."Analysis Account Source"::"Cash Flow Account":
                        exit("Analysis Dimension Option"::"Cash Flow Forecast");
                    else begin
                        OnGetAnalysisViewDimensionOption(AnalysisView, Result, DimCode);
                        exit(Result);
                    end;
                end;
            AnalysisView."Dimension 1 Code":
                exit("Analysis Dimension Option"::"Dimension 1");
            AnalysisView."Dimension 2 Code":
                exit("Analysis Dimension Option"::"Dimension 2");
            AnalysisView."Dimension 3 Code":
                exit("Analysis Dimension Option"::"Dimension 3");
            AnalysisView."Dimension 4 Code":
                exit("Analysis Dimension Option"::"Dimension 4");
            else
                exit("Analysis Dimension Option"::Undefined);
        end;
    end;

#if not CLEAN20
    [Obsolete('Replaced by FindRecord()', '20.0')]
    procedure FindRec(DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]) Found: Boolean
    begin
        Found := FindRecord("Analysis Dimension Option".FromInteger(DimOption), DimCodeBuf, Which);

        OnAfterFindRec(DimOption, DimCodeBuf, AnalysisView, Which, Found);
    end;
#endif

    procedure FindRecord(DimOption: Enum "Analysis Dimension Option"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]) Found: Boolean
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        CFAccount: Record "Cash Flow Account";
        CashFlowForecast: Record "Cash Flow Forecast";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        OnBeforeFindRecord(DimOption, DimVal);
        case DimOption of
            DimOption::"G/L Account":
                begin
                    GLAcc."No." := DimCodeBuf.Code;
                    if "Account Filter" <> '' then
                        GLAcc.SetFilter("No.", "Account Filter");
                    Found := GLAcc.Find(Which);
                    if Found then
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                end;
            DimOption::"Cash Flow Account":
                begin
                    CFAccount."No." := DimCodeBuf.Code;
                    if "Account Filter" <> '' then
                        CFAccount.SetFilter("No.", "Account Filter");
                    Found := CFAccount.Find(Which);
                    if Found then
                        CopyCFAccToBuf(CFAccount, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if not PeriodInitialized then
                        "Date Filter" := '';
                    PeriodInitialized := true;
                    Period."Period Start" := DimCodeBuf."Period Start";
                    if "Date Filter" <> '' then
                        Period.SetFilter("Period Start", "Date Filter")
                    else
                        if Period."Period Start" <> 0D then
                            Period.SetFilter("Period Start", '%1..%2', Period."Period Start", ClosingDate(Period."Period Start"))
                        else
                            if InternalDateFilter <> '' then
                                Period.SetFilter("Period Start", InternalDateFilter);

                    Found := PeriodPageMgt.FindDate(Which, Period, "Period Type");
                    if Found then
                        CopyPeriodToBuf(Period, DimCodeBuf);
                end;
            DimOption::"Business Unit":
                begin
                    BusUnit.Code := DimCodeBuf.Code;
                    if "Bus. Unit Filter" <> '' then
                        BusUnit.SetFilter(Code, "Bus. Unit Filter");
                    Found := BusUnit.Find(Which);
                    if Found then
                        CopyBusUnitToBuf(BusUnit, DimCodeBuf);
                end;
            DimOption::"Cash Flow Forecast":
                begin
                    CashFlowForecast."No." := DimCodeBuf.Code;
                    if "Cash Flow Forecast Filter" <> '' then
                        CashFlowForecast.SetFilter("No.", "Cash Flow Forecast Filter");
                    Found := CashFlowForecast.Find(Which);
                    if Found then
                        CopyCashFlowToBuf(CashFlowForecast, DimCodeBuf);
                end;
            DimOption::"Dimension 1":
                begin
                    if "Dimension 1 Filter" <> '' then
                        DimVal.SetFilter(Code, "Dimension 1 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 2":
                begin
                    if "Dimension 2 Filter" <> '' then
                        DimVal.SetFilter(Code, "Dimension 2 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 3":
                begin
                    if "Dimension 3 Filter" <> '' then
                        DimVal.SetFilter(Code, "Dimension 3 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 4":
                begin
                    if "Dimension 4 Filter" <> '' then
                        DimVal.SetFilter(Code, "Dimension 4 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 4 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;

        OnAfterFindRecord(DimOption, DimCodeBuf, AnalysisView, Which, Found, Rec);
    end;

#if not CLEAN20
    [Obsolete('Replaced by NextRecord()', '20.0')]
    procedure NextRec(DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer) ResultSteps: Integer
    begin
        ResultSteps := NextRecord("Analysis Dimension Option".FromInteger(DimOption), DimCodeBuf, Steps);

        OnAfterNextRec(DimOption, DimCodeBuf, AnalysisView, Steps, ResultSteps);
    end;
#endif

    procedure NextRecord(DimOption: Enum "Analysis Dimension Option"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer) ResultSteps: Integer
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        CFAccount: Record "Cash Flow Account";
        CashFlowForecast: Record "Cash Flow Forecast";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        OnBeforeNextRecord(DimOption, DimVal);
        case DimOption of
            DimOption::"G/L Account":
                begin
                    GLAcc."No." := DimCodeBuf.Code;
                    if "Account Filter" <> '' then
                        GLAcc.SetFilter("No.", "Account Filter");
                    ResultSteps := GLAcc.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                end;
            DimOption::"Cash Flow Account":
                begin
                    CFAccount."No." := DimCodeBuf.Code;
                    if "Account Filter" <> '' then
                        CFAccount.SetFilter("No.", "Account Filter");
                    ResultSteps := CFAccount.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyCFAccToBuf(CFAccount, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if "Date Filter" <> '' then
                        Period.SetFilter("Period Start", "Date Filter");
                    Period."Period Start" := DimCodeBuf."Period Start";
                    ResultSteps := PeriodPageMgt.NextDate(Steps, Period, "Period Type");
                    if ResultSteps <> 0 then
                        CopyPeriodToBuf(Period, DimCodeBuf);
                end;
            DimOption::"Business Unit":
                begin
                    BusUnit.Code := DimCodeBuf.Code;
                    if "Bus. Unit Filter" <> '' then
                        BusUnit.SetFilter(Code, "Bus. Unit Filter");
                    ResultSteps := BusUnit.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyBusUnitToBuf(BusUnit, DimCodeBuf);
                end;
            DimOption::"Cash Flow Forecast":
                begin
                    CashFlowForecast."No." := DimCodeBuf.Code;
                    if "Cash Flow Forecast Filter" <> '' then
                        CashFlowForecast.SetFilter("No.", "Cash Flow Forecast Filter");
                    ResultSteps := CashFlowForecast.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyCashFlowToBuf(CashFlowForecast, DimCodeBuf);
                end;
            DimOption::"Dimension 1":
                begin
                    if "Dimension 1 Filter" <> '' then
                        DimVal.SetFilter(Code, "Dimension 1 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 2":
                begin
                    if "Dimension 2 Filter" <> '' then
                        DimVal.SetFilter(Code, "Dimension 2 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 3":
                begin
                    if "Dimension 3 Filter" <> '' then
                        DimVal.SetFilter(Code, "Dimension 3 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 4":
                begin
                    if "Dimension 4 Filter" <> '' then
                        DimVal.SetFilter(Code, "Dimension 4 Filter");
                    DimVal."Dimension Code" := AnalysisView."Dimension 4 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;

        OnAfterNextRecord(DimOption, DimCodeBuf, AnalysisView, Steps, ResultSteps);
    end;

    local procedure CopyGLAccToBuf(var TheGLAcc: Record "G/L Account"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init();
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
            Init();
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
            Init();
            Code := Format(ThePeriod."Period Start");
            "Period Start" := ThePeriod."Period Start";
            if "Closing Entries" = "Closing Entries"::Include then
                "Period End" := ClosingDate(ThePeriod."Period End")
            else
                "Period End" := ThePeriod."Period End";
            if "Date Filter" <> '' then begin
                Period2.SetFilter("Period End", "Date Filter");
                if Period2.GetRangeMax("Period End") < "Period End" then
                    "Period End" := Period2.GetRangeMax("Period End");
            end;
            Name := ThePeriod."Period Name";
        end;
    end;

    local procedure CopyBusUnitToBuf(var TheBusUnit: Record "Business Unit"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init();
            Code := TheBusUnit.Code;
            Name := TheBusUnit.Name;
        end;
    end;

    local procedure CopyCashFlowToBuf(var TheCashFlowForecast: Record "Cash Flow Forecast"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init();
            Code := TheCashFlowForecast."No.";
            Name := TheCashFlowForecast.Description;
        end;
    end;

    local procedure CopyDimValueToBuf(var TheDimVal: Record "Dimension Value"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init();
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
        PeriodPageMgt: Codeunit PeriodPageManagement;
        TempDate: Date;
    begin
        if not PeriodInitialized then
            "Date Filter" := '';
        if ("Date Filter" <> '') and Evaluate(TempDate, "Date Filter") then begin
            Calendar.SetFilter("Period Start", "Date Filter");
            if not PeriodPageMgt.FindDate('+', Calendar, "Period Type") then
                PeriodPageMgt.FindDate('+', Calendar, "Period Type"::Day);
            Calendar.SetRange("Period Start");
        end;
        if PeriodPageMgt.FindDate(SearchText, Calendar, "Period Type") then
            if "Closing Entries" = "Closing Entries"::Include then
                Calendar."Period End" := ClosingDate(Calendar."Period End");
        if AmountType = AmountType::"Net Change" then begin
            AnalysisViewEntry.SetRange("Posting Date", Calendar."Period Start", Calendar."Period End");
            if AnalysisViewEntry.GetRangeMin("Posting Date") = AnalysisViewEntry.GetRangeMax("Posting Date") then
                AnalysisViewEntry.SetRange("Posting Date", AnalysisViewEntry.GetRangeMin("Posting Date"));
        end else
            AnalysisViewEntry.SetRange("Posting Date", 0D, Calendar."Period End");

        InternalDateFilter := AnalysisViewEntry.GetFilter("Posting Date");
        if ("Line Dim Option" <> "Line Dim Option"::Period) and ("Column Dim Option" <> "Column Dim Option"::Period) then
            "Date Filter" := InternalDateFilter;
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
        if UnitCaption <> '' then
            DimSelection.InsertDimSelBuf(false, UnitCaption, UnitCaption);

        if AnalysisView."Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 1 Code", '');
        if AnalysisView."Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 2 Code", '');
        if AnalysisView."Dimension 3 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 3 Code", '');
        if AnalysisView."Dimension 4 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, AnalysisView."Dimension 4 Code", '');

        OnGetDimSelectionOnBeforeDimSelectionLookup(AnalysisView, DimSelection);
        DimSelection.LookupMode := true;
        if DimSelection.RunModal() = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode());

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
        if DimValList.RunModal() = ACTION::LookupOK then begin
            DimValList.GetRecord(DimVal);
            Text := DimValList.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    local procedure ValidateAnalysisViewCode()
    var
        AnalysisViewFilter: Record "Analysis View Filter";
        IsSupported: Boolean;
    begin
        AnalysisView.Code := "Analysis View Code";
        if not AnalysisView.Find('=<>') then
            Error(Text002);
        "Analysis View Code" := AnalysisView.Code;

        if ((Rec."Analysis Account Source" = AnalysisView."Account Source") or ("Account Filter" = '')) then
            Rec."Account Filter" := AnalysisView."Account Filter";

        "Dimension 1 Filter" := '';
        "Dimension 2 Filter" := '';
        "Dimension 3 Filter" := '';
        "Dimension 4 Filter" := '';

        Dim1FilterEnable :=
          (AnalysisView."Dimension 1 Code" <> '') and
          ("Dimension 1 Filter" = '');
        Dim2FilterEnable :=
          (AnalysisView."Dimension 2 Code" <> '') and
          ("Dimension 2 Filter" = '');
        Dim3FilterEnable :=
          (AnalysisView."Dimension 3 Code" <> '') and
          ("Dimension 3 Filter" = '');
        Dim4FilterEnable :=
          (AnalysisView."Dimension 4 Code" <> '') and
          ("Dimension 4 Filter" = '');

        if Dim1FilterEnable then
            if AnalysisViewFilter.Get(AnalysisView.Code, AnalysisView."Dimension 1 Code") then
                "Dimension 1 Filter" := AnalysisViewFilter."Dimension Value Filter";

        if Dim2FilterEnable then
            if AnalysisViewFilter.Get(AnalysisView.Code, AnalysisView."Dimension 2 Code") then
                "Dimension 2 Filter" := AnalysisViewFilter."Dimension Value Filter";

        if Dim3FilterEnable then
            if AnalysisViewFilter.Get(AnalysisView.Code, AnalysisView."Dimension 3 Code") then
                "Dimension 3 Filter" := AnalysisViewFilter."Dimension Value Filter";

        if Dim4FilterEnable then
            if AnalysisViewFilter.Get(AnalysisView.Code, AnalysisView."Dimension 4 Code") then
                "Dimension 4 Filter" := AnalysisViewFilter."Dimension Value Filter";

        OnValidateAnalysisViewCodeOnAfterRecSetFilters(Rec, AnalysisView);

        case Rec."Analysis Account Source" of
            Rec."Analysis Account Source"::"G/L Account":
                GLAccountSource := true;
            Rec."Analysis Account Source"::"Cash Flow Account":
                GLAccountSource := false;
            else begin
                AnalysisView.OnGetAnalysisViewSupported(AnalysisView, IsSupported);
                if not IsSupported then
                    Error(Text009, AnalysisView."Account Source");
            end;
        end;
    end;

    local procedure ValidateLineDimCode()
    var
        AccountCaption: Text[30];
        UnitCaption: Text[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateLineDimCode(GLAccountSource, LineDimCode, InternalDateFilter, IsHandled, Rec, AnalysisView, AnalysisViewEntry);
        if IsHandled then
            exit;

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
        "Line Dim Option" := DimCodeToDimOption(LineDimCode);
        InternalDateFilter := AnalysisViewEntry.GetFilter("Posting Date");
        if ("Line Dim Option" <> "Line Dim Option"::Period) and ("Column Dim Option" <> "Column Dim Option"::Period) then begin
            "Date Filter" := InternalDateFilter;
            if StrPos("Date Filter", '&') > 1 then
                "Date Filter" := CopyStr("Date Filter", 1, StrPos("Date Filter", '&') - 1);
        end;
    end;

    local procedure ValidateColumnDimCode()
    var
        AccountCaption: Text[30];
        UnitCaption: Text[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateColumnDimCode(GLAccountSource, ColumnDimCode, InternalDateFilter, IsHandled, Rec, AnalysisView, AnalysisViewEntry, PeriodInitialized);
        if IsHandled then
            exit;

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
        "Column Dim Option" := DimCodeToDimOption(ColumnDimCode);
        InternalDateFilter := AnalysisViewEntry.GetFilter("Posting Date");
        if ("Line Dim Option" <> "Line Dim Option"::Period) and ("Column Dim Option" <> "Column Dim Option"::Period) then begin
            "Date Filter" := InternalDateFilter;
            if StrPos("Date Filter", '&') > 1 then
                "Date Filter" := CopyStr("Date Filter", 1, StrPos("Date Filter", '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    procedure GetCaptionClass(AnalysisViewDimType: Integer) Result: Text[250]
    var
        DummyAnalysisbyDimParameters: Record "Analysis by Dim. Parameters";
    begin
        if AnalysisView.Code <> "Analysis View Code" then
            if AnalysisView.Get("Analysis View Code") then
                if Rec."Analysis Account Source" = DummyAnalysisbyDimParameters."Analysis Account Source" then
                    Rec."Analysis Account Source" := AnalysisView."Account Source";

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

        OnAfterGetCaptionClass(AnalysisViewDimType, AnalysisView, Result);
    end;

    protected procedure CreateCaptionSet(RecRef: Record "Dimension Code Buffer"; Step: Option First,Previous,Same,Next; MaximumNoOfCaptions: Integer; var PrimaryKeyFirstCaptionInCurrSe: Text[1024]; var CaptionSet: array[32] of Text[1024]; var CaptionRange: Text[1024])
    var
        CurrentCaptionOrdinal: Integer;
    begin
        Clear(CaptionSet);
        CaptionRange := '';

        CurrentCaptionOrdinal := 0;

        case Step of
            Step::First:
                begin
                    if ("Column Dim Option" = "Column Dim Option"::Period) and ("Date Filter" = '') then
                        FindRecord("Column Dim Option", RecRef, '=><')
                    else
                        if not FindRecord("Column Dim Option", RecRef, '-') then
                            exit;
                end;
            Step::Previous:
                begin
                    RecRef.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
                    if "Column Dim Option" = "Column Dim Option"::Period then
                        Evaluate(RecRef."Period Start", RecRef.Code);
                    if not FindRecord("Column Dim Option", RecRef, '=') then
                        exit;
                    NextRecord("Column Dim Option", RecRef, -MaximumNoOfCaptions);
                end;
            Step::Same:
                begin
                    RecRef.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
                    if "Column Dim Option" = "Column Dim Option"::Period then
                        Evaluate(RecRef."Period Start", RecRef.Code);
                    if not FindRecord("Column Dim Option", RecRef, '=') then
                        exit;
                end;
            Step::Next:
                begin
                    RecRef.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
                    if "Column Dim Option" = "Column Dim Option"::Period then
                        Evaluate(RecRef."Period Start", RecRef.Code);
                    if not FindRecord("Column Dim Option", RecRef, '=') then
                        exit;
                    if not (NextRecord("Column Dim Option", RecRef, MaximumNoOfCaptions) = MaximumNoOfCaptions) then begin
                        RecRef.SetPosition(PrimaryKeyFirstCaptionInCurrSe);
                        FindRecord("Column Dim Option", RecRef, '=');
                    end;
                end;
        end;

        PrimaryKeyFirstCaptionInCurrSe := RecRef.GetPosition();

        repeat
            CurrentCaptionOrdinal := CurrentCaptionOrdinal + 1;
            if "Show Column Name" then
                CaptionSet[CurrentCaptionOrdinal] := RecRef.Name
            else
                CaptionSet[CurrentCaptionOrdinal] := RecRef.Code;
        until (CurrentCaptionOrdinal = MaximumNoOfCaptions) or (NextRecord("Column Dim Option", RecRef, 1) <> 1);

        if CurrentCaptionOrdinal = 1 then
            CaptionRange := CaptionSet[1]
        else
            CaptionRange := CopyStr(CaptionSet[1] + '..' + CaptionSet[CurrentCaptionOrdinal], 1, MaxStrLen(CaptionRange));
    end;

    procedure SetAnalysisViewCode(NextAnalysisViewCode: Code[10])
    begin
        NewAnalysisViewCode := NextAnalysisViewCode;
        "Analysis View Code" := NextAnalysisViewCode;
        Insert();
    end;

    local procedure GetAccountCaption(var AccountCaption: Text[30]; var UnitCaption: Text[30])
    var
        GLAcc: Record "G/L Account";
        CFAccount: Record "Cash Flow Account";
        BusUnit: Record "Business Unit";
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        case Rec."Analysis Account Source" of
            Rec."Analysis Account Source"::"G/L Account":
                begin
                    AccountCaption := GLAcc.TableCaption();
                    UnitCaption := BusUnit.TableCaption();
                end;
            Rec."Analysis Account Source"::"Cash Flow Account":
                begin
                    AccountCaption := CFAccount.TableCaption();
                    UnitCaption := CashFlowForecast.TableCaption();
                end;
            else
                OnGetCaptions(AnalysisView, LineDimCode, AccountCaption, UnitCaption, false);
        end;
    end;

#if not CLEAN20
    [Obsolete('Replaced by event OnAfterFindRecord()', '20.0')]
    [IntegrationEvent(true, false)]
    local procedure OnAfterFindRec(var DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast",Fund,DimAttrib1,DimAttrib2,DimAttrib3,DimAttrib4; var DimCodeBuf: Record "Dimension Code Buffer"; var AnalysisView: Record "Analysis View"; Which: Text[250]; var Found: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnAfterFindRecord(var DimOption: Enum "Analysis Dimension Option"; var DimCodeBuf: Record "Dimension Code Buffer"; var AnalysisView: Record "Analysis View"; Which: Text[250]; var Found: Boolean; var AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCaptionClass(AnalysisViewDimType: Integer; var AnalysisView: Record "Analysis View"; var ReturnValue: Text[250])
    begin
    end;

#if not CLEAN20
    [Obsolete('Replaced by OnAfterNextRecord()', '20.0')]
    [IntegrationEvent(true, false)]
    local procedure OnAfterNextRec(DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast",Fund,DimAttrib1,DimAttrib2,DimAttrib3,DimAttrib4; var DimCodeBuf: Record "Dimension Code Buffer"; var AnalysisView: Record "Analysis View"; Steps: Integer; var ResultSteps: Integer)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnAfterNextRecord(DimOption: Enum "Analysis Dimension Option"; var DimCodeBuf: Record "Dimension Code Buffer"; var AnalysisView: Record "Analysis View"; Steps: Integer; var ResultSteps: Integer)
    begin
    end;

#if not CLEAN20
    [Obsolete('Replaced by OnBeforeDimCodeToDimOption()', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDimCodeToOption(DimCode: Text[30]; var AnalysisView: Record "Analysis View"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPage(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDimCodeToDimOption(DimCode: Text[30]; var AnalysisView: Record "Analysis View"; var Result: Enum "Analysis Dimension Option"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNextRecord(DimOption: Enum "Analysis Dimension Option"; var DimensionValue: Record "Dimension Value")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecord(DimOption: Enum "Analysis Dimension Option"; var DimensionValue: Record "Dimension Value")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateColumnDimCode(var GLAccountSource: Boolean; var ColumnDimCode: Text[30]; var InternalDateFilter: Text; var IsHandled: Boolean; var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; var AnalysisView: Record "Analysis View"; var AnalysisViewEntry: Record "Analysis View Entry"; var PeriodInitialized: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateLineDimCode(var GLAccountSource: Boolean; var LineDimCode: Text[30]; var InternalDateFilter: Text; var IsHandled: Boolean; var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; var AnalysisView: Record "Analysis View"; var AnalysisViewEntry: Record "Analysis View Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDimSelectionOnBeforeDimSelectionLookup(var AnalysisView: Record "Analysis View"; var DimSelection: Page "Dimension Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAnalysisViewCodeOnAfterRecSetFilters(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; var AnalysisView: Record "Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCaptions(var AnalysisView: Record "Analysis View"; var LineDimCode: Text[30]; var AccountCaption: Text[30]; var UnitCaption: Text[30]; OpenPage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAnalysisViewDimensionOption(var AnalysisView: Record "Analysis View"; var Result: enum "Analysis Dimension Option"; DimCode: Text[30])
    begin
    end;
}

