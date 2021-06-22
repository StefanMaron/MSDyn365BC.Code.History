page 408 "G/L Balance by Dimension"
{
    Caption = 'G/L Balance by Dimension';
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
                        NewCode := GetDimSelection(ColumnDimCode);
                        if NewCode = ColumnDimCode then
                            exit(false);

                        Text := NewCode;
                        ColumnDimCode := NewCode;
                        ValidateColumnDimCode;
                        ColumnDimCodeOnAfterValidate;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            LineDimCode := '';
                            ValidateLineDimCode;
                        end;
                        ValidateColumnDimCode;
                        ColumnDimCodeOnAfterValidate;
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
                        FilterTokens: Codeunit "Filter Tokens";
                        Date1: Date;
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        if DateFilter <> '' then
                            if Evaluate(Date1, DateFilter) then
                                if Date1 <> NormalDate(Date1) then
                                    DateFilter := StrSubstNo('%1..%2', NormalDate(Date1), Date1);
                        GLAcc.SetFilter("Date Filter", DateFilter);
                        DateFilter := GLAcc.GetFilter("Date Filter");
                        InternalDateFilter := DateFilter;
                        DateFilterOnAfterValidate;
                    end;
                }
                field(GLAccFilter; GLAccFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'G/L Account Filter';
                    ToolTip = 'Specifies the G/L accounts for which you will see information in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLAccList: Page "G/L Account List";
                    begin
                        GLAccList.LookupMode(true);
                        if not (GLAccList.RunModal = ACTION::LookupOK) then
                            exit(false);

                        Text := GLAccList.GetSelectionFilter;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        GLAccFilterOnAfterValidate;
                    end;
                }
                field(BudgetFilter; BudgetFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Budget Filter';
                    LookupPageID = "G/L Budget Names";
                    TableRelation = "G/L Budget Name".Name;
                    ToolTip = 'Specifies the budget that information in the matrix is shown for.';

                    trigger OnValidate()
                    begin
                        BudgetFilterOnAfterValidate;
                    end;
                }
                field(BusUnitFilter; BusUnitFilter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '3,' + BusUnitFilterCaption;

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

                    trigger OnValidate()
                    begin
                        BusUnitFilterOnAfterValidate;
                    end;
                }
                field(Dim1Filter; GlobalDim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,3,1';
                    Enabled = Dim1FilterEnable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(GLSetup."Global Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        GlobalDim1FilterOnAfterValidat;
                    end;
                }
                field(Dim2Filter; GlobalDim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,3,2';
                    Enabled = Dim2FilterEnable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(GLSetup."Global Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        GlobalDim2FilterOnAfterValidat;
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
                    OptionCaption = 'Actual Amounts,Budgeted Amounts,Variance,Variance%,Index%';
                    ToolTip = 'Specifies if the selected value is shown in the window.';
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
                    ToolTip = 'Specifies whether the balance shown will include closing entries. If you want to see the amounts on income statement accounts in closed years, you must exclude closing entries.';

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
                    ToolTip = 'Specifies whether to show the reported amounts in the additional reporting currency.';
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
                        PeriodTypeOnAfterValidate;
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'View as';
                    OptionCaption = 'Net Change,Balance at Date';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        AmountTypeOnAfterValidate;
                    end;
                }
                field(MATRIX_ColumnSet; MATRIX_ColumnSet)
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
                        MATRIX_Step: Option First,Previous,Next;
                    begin
                        TempDimCode := ColumnDimCode;
                        ColumnDimCode := LineDimCode;
                        LineDimCode := TempDimCode;
                        ValidateLineDimCode;
                        ValidateColumnDimCode;
                        MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
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
                    MatrixForm: Page "G/L Balance by Dim. Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.Load(
                      LineDimCode, ColumnDimCode, PeriodType, DateFilter, GLAccFilter, BusUnitFilter,
                      BudgetFilter, GlobalDim1Filter, GlobalDim2Filter,
                      ShowActualBudg, AmountField, ClosingEntryFilter, RoundingFactor, ShowInAddCurr,
                      MATRIX_ColumnCaptions, MATRIX_PrimaryKeyFirstColInSet,
                      AmountType, MATRIX_CurrSetLength);
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
                var
                    MATRIX_Step: Option Initial,Previous,Same,Next;
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
                PromotedOnly = true;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                var
                    MATRIX_Step: Option Initial,Previous,Same,Next;
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_Step::Next);
                end;
            }
        }
    }

    trigger OnInit()
    var
        "Field": Record "Field";
    begin
        Dim2FilterEnable := true;
        Dim1FilterEnable := true;
        Field.Get(DATABASE::"G/L Account", 42);
        BusUnitFilterCaption := Field."Field Caption";
    end;

    trigger OnOpenPage()
    var
        MATRIX_Step: Option Initial,Previous,Same,Next;
    begin
        OnBeforeGLAccFilter(GLAcc, GLAccFilter, LineDimOption, ColumnDimOption);
        GlobalDim1Filter := GLAcc.GetFilter("Global Dimension 1 Filter");
        GlobalDim2Filter := GLAcc.GetFilter("Global Dimension 2 Filter");

        GLSetup.Get;
        Dim1FilterEnable :=
          (GLSetup."Global Dimension 1 Code" <> '') and
          (GLAcc.GetFilter("Global Dimension 1 Filter") = '');
        Dim2FilterEnable :=
          (GLSetup."Global Dimension 2 Code" <> '') and
          (GLAcc.GetFilter("Global Dimension 2 Filter") = '');

        if GLSetup."Additional Reporting Currency" = '' then
            ShowInAddCurr := false;

        if (LineDimCode = '') and (ColumnDimCode = '') then begin
            LineDimCode := GLAcc.TableCaption;
            ColumnDimCode := Text001;
        end;
        LineDimOption := DimCodeToOption(LineDimCode);
        ColumnDimOption := DimCodeToOption(ColumnDimCode);

        FindPeriod('');

        MATRIX_NoOfColumns := 32;
        MATRIX_GenerateColumnCaptions(MATRIX_Step::Initial);
    end;

    var
        Text001: Label 'Period';
        Text002: Label '%1 is not a valid line definition.';
        Text003: Label '%1 is not a valid column definition.';
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        LineDimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4";
        ColumnDimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4";
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";
        RoundingFactor: Option "None","1","1000","1000000";
        AmountField: Option Amount,"Debit Amount","Credit Amount";
        ShowActualBudg: Option "Actual Amounts","Budgeted Amounts",Variance,"Variance%","Index%";
        ShowInAddCurr: Boolean;
        ClosingEntryFilter: Option Include,Exclude;
        ShowColumnName: Boolean;
        DateFilter: Text;
        InternalDateFilter: Text;
        GLAccFilter: Text;
        BudgetFilter: Text;
        BusUnitFilter: Text;
        GlobalDim1Filter: Text;
        GlobalDim2Filter: Text;
        BusUnitFilterCaption: Text[80];
        PeriodInitialized: Boolean;
        MATRIX_ColumnCaptions: array[32] of Text[1024];
        MATRIX_NoOfColumns: Integer;
        MATRIX_ColumnSet: Text[1024];
        MATRIX_PrimaryKeyFirstColInSet: Text[1024];
        MATRIX_CurrSetLength: Integer;
        [InDataSet]
        Dim1FilterEnable: Boolean;
        [InDataSet]
        Dim2FilterEnable: Boolean;

    local procedure DimCodeToOption(DimCode: Text[30]): Integer
    var
        BusUnit: Record "Business Unit";
    begin
        case DimCode of
            '':
                exit(-1);
            GLAcc.TableCaption:
                exit(0);
            Text001:
                exit(1);
            BusUnit.TableCaption:
                exit(2);
            GLSetup."Global Dimension 1 Code":
                exit(3);
            GLSetup."Global Dimension 2 Code":
                exit(4);
            else
                exit(-1);
        end;
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
        Period: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
    begin
        if DateFilter <> '' then begin
            Period.SetFilter("Period Start", DateFilter);
            if not PeriodFormMgt.FindDate('+', Period, PeriodType) then
                PeriodFormMgt.FindDate('+', Period, PeriodType::Day);
            Period.SetRange("Period Start");
        end;
        if PeriodFormMgt.FindDate(SearchText, Period, PeriodType) then
            if ClosingEntryFilter = ClosingEntryFilter::Include then
                Period."Period End" := ClosingDate(Period."Period End");
        if AmountType = AmountType::"Net Change" then begin
            GLAcc.SetRange("Date Filter", Period."Period Start", Period."Period End");
            if GLAcc.GetRangeMin("Date Filter") = GLAcc.GetRangeMax("Date Filter") then
                GLAcc.SetRange("Date Filter", GLAcc.GetRangeMin("Date Filter"));
        end else
            GLAcc.SetRange("Date Filter", 0D, Period."Period End");

        InternalDateFilter := GLAcc.GetFilter("Date Filter");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then
            DateFilter := InternalDateFilter;
    end;

    local procedure GetDimSelection(OldDimSelCode: Text[30]): Text[30]
    var
        DimSelection: Page "Dimension Selection";
    begin
        DimSelection.InsertDimSelBuf(false, GLAcc.TableCaption, GLAcc.TableCaption);
        DimSelection.InsertDimSelBuf(false, BusUnit.TableCaption, BusUnit.TableCaption);
        DimSelection.InsertDimSelBuf(false, Text001, Text001);
        if GLSetup."Global Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 1 Code", '');
        if GLSetup."Global Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 2 Code", '');

        DimSelection.LookupMode := true;
        if DimSelection.RunModal = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode);

        exit(OldDimSelCode);
    end;

    local procedure ValidateLineDimCode()
    var
        BusUnit: Record "Business Unit";
    begin
        if (UpperCase(LineDimCode) <> UpperCase(GLAcc.TableCaption)) and
           (UpperCase(LineDimCode) <> UpperCase(BusUnit.TableCaption)) and
           (UpperCase(LineDimCode) <> UpperCase(Text001)) and
           (UpperCase(LineDimCode) <> GLSetup."Global Dimension 1 Code") and
           (UpperCase(LineDimCode) <> GLSetup."Global Dimension 2 Code") and
           (LineDimCode <> '')
        then begin
            Message(Text002, LineDimCode);
            LineDimCode := '';
        end;
        LineDimOption := DimCodeToOption(LineDimCode);
        InternalDateFilter := GLAcc.GetFilter("Date Filter");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    local procedure ValidateColumnDimCode()
    var
        BusUnit: Record "Business Unit";
    begin
        if (UpperCase(ColumnDimCode) <> UpperCase(GLAcc.TableCaption)) and
           (UpperCase(ColumnDimCode) <> UpperCase(BusUnit.TableCaption)) and
           (UpperCase(ColumnDimCode) <> UpperCase(Text001)) and
           (UpperCase(ColumnDimCode) <> GLSetup."Global Dimension 1 Code") and
           (UpperCase(ColumnDimCode) <> GLSetup."Global Dimension 2 Code") and
           (ColumnDimCode <> '')
        then begin
            Message(Text003, ColumnDimCode);
            ColumnDimCode := '';
        end;
        ColumnDimOption := DimCodeToOption(ColumnDimCode);
        InternalDateFilter := GLAcc.GetFilter("Date Filter");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    local procedure FindRec(DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]): Boolean
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        Found: Boolean;
    begin
        case DimOption of
            DimOption::"G/L Account":
                begin
                    GLAcc."No." := DimCodeBuf.Code;
                    if GLAccFilter <> '' then
                        GLAcc.SetFilter("No.", GLAccFilter);
                    Found := GLAcc.Find(Which);
                    if Found then
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if not PeriodInitialized then
                        DateFilter := '';
                    PeriodInitialized := true;
                    Evaluate(Period."Period Start", DimCodeBuf.Code);
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter)
                    else
                        if not PeriodInitialized and (InternalDateFilter <> '') then
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
            DimOption::"Dimension 1":
                begin
                    if GlobalDim1Filter <> '' then
                        DimVal.SetFilter(Code, GlobalDim1Filter);
                    DimVal."Dimension Code" := GLSetup."Global Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 2":
                begin
                    if GlobalDim2Filter <> '' then
                        DimVal.SetFilter(Code, GlobalDim2Filter);
                    DimVal."Dimension Code" := GLSetup."Global Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;
        exit(Found);
    end;

    local procedure NextRec(DimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer): Integer
    var
        GLAcc: Record "G/L Account";
        BusUnit: Record "Business Unit";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        ResultSteps: Integer;
    begin
        case DimOption of
            DimOption::"G/L Account":
                begin
                    GLAcc."No." := DimCodeBuf.Code;
                    if GLAccFilter <> '' then
                        GLAcc.SetFilter("No.", GLAccFilter);
                    ResultSteps := GLAcc.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter);
                    Evaluate(Period."Period Start", DimCodeBuf.Code);
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
            DimOption::"Dimension 1":
                begin
                    if GlobalDim1Filter <> '' then
                        DimVal.SetFilter(Code, GlobalDim1Filter);
                    DimVal."Dimension Code" := GLSetup."Global Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 2":
                begin
                    if GlobalDim2Filter <> '' then
                        DimVal.SetFilter(Code, GlobalDim2Filter);
                    DimVal."Dimension Code" := GLSetup."Global Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;
        exit(ResultSteps);
    end;

    local procedure MATRIX_GenerateColumnCaptions(Step: Option Initial,Previous,Same,Next)
    var
        CurrentColumn: Record "Dimension Code Buffer";
        Found: Boolean;
        Which: Text[30];
    begin
        MATRIX_CurrSetLength := 0;
        Clear(MATRIX_ColumnCaptions);
        MATRIX_ColumnSet := '';

        case Step of
            Step::Initial:
                begin
                    if (ColumnDimOption = ColumnDimOption::Period) and (PeriodType <> PeriodType::"Accounting Period")
                       and (DateFilter = '')
                    then begin
                        Evaluate(CurrentColumn.Code, Format(WorkDate));
                        Which := '=><';
                    end else
                        Which := '-';
                    Found := FindRec(ColumnDimOption, CurrentColumn, Which);
                end;
            Step::Previous:
                begin
                    CurrentColumn.SetPosition(MATRIX_PrimaryKeyFirstColInSet);
                    Found := FindRec(ColumnDimOption, CurrentColumn, '=');
                    NextRec(ColumnDimOption, CurrentColumn, -MATRIX_NoOfColumns)
                end;
            Step::Same:
                begin
                    CurrentColumn.SetPosition(MATRIX_PrimaryKeyFirstColInSet);
                    Found := FindRec(ColumnDimOption, CurrentColumn, '=');
                end;
            Step::Next:
                begin
                    CurrentColumn.SetPosition(MATRIX_PrimaryKeyFirstColInSet);
                    Found := FindRec(ColumnDimOption, CurrentColumn, '=');
                    if not (NextRec(ColumnDimOption, CurrentColumn, MATRIX_NoOfColumns) = MATRIX_NoOfColumns) then begin
                        CurrentColumn.SetPosition(MATRIX_PrimaryKeyFirstColInSet);
                        Found := FindRec(ColumnDimOption, CurrentColumn, '=');
                    end
                end;
        end;

        MATRIX_PrimaryKeyFirstColInSet := CurrentColumn.GetPosition;

        if Found then begin
            repeat
                MATRIX_CurrSetLength := MATRIX_CurrSetLength + 1;
                if ShowColumnName then
                    MATRIX_ColumnCaptions[MATRIX_CurrSetLength] := CurrentColumn.Name
                else
                    MATRIX_ColumnCaptions[MATRIX_CurrSetLength] := CurrentColumn.Code;
            until (MATRIX_CurrSetLength = MATRIX_NoOfColumns) or (NextRec(ColumnDimOption, CurrentColumn, 1) <> 1);

            if MATRIX_CurrSetLength = 1 then
                MATRIX_ColumnSet := MATRIX_ColumnCaptions[1]
            else
                MATRIX_ColumnSet := MATRIX_ColumnCaptions[1] + '..' + MATRIX_ColumnCaptions[MATRIX_CurrSetLength];
        end;
    end;

    local procedure LineDimCodeOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure ColumnDimCodeOnAfterValidate()
    var
        MATRIX_Steps: Option First,Previous,Next;
    begin
        CurrPage.Update;
        MATRIX_GenerateColumnCaptions(MATRIX_Steps::First);
    end;

    local procedure DateFilterOnAfterValidate()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
        CurrPage.Update;
        if ColumnDimOption = ColumnDimOption::Period then begin
            PeriodInitialized := true;
            MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
        end;
    end;

    local procedure GLAccFilterOnAfterValidate()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
        CurrPage.Update;
        if ColumnDimOption = ColumnDimOption::"G/L Account" then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
    end;

    local procedure GlobalDim2FilterOnAfterValidat()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
        CurrPage.Update;
        if ColumnDimOption = ColumnDimOption::"Dimension 2" then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
    end;

    local procedure GlobalDim1FilterOnAfterValidat()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
        CurrPage.Update;
        if ColumnDimOption = ColumnDimOption::"Dimension 1" then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
    end;

    local procedure BudgetFilterOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure BusUnitFilterOnAfterValidate()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
        CurrPage.Update;
        if ColumnDimOption = ColumnDimOption::"Business Unit" then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
    end;

    local procedure ShowColumnNameOnAfterValidate()
    var
        MATRIX_Step: Option Initial,Previous,Same,Next;
    begin
        MATRIX_GenerateColumnCaptions(MATRIX_Step::Same);
    end;

    local procedure PeriodTypeOnAfterValidate()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
        if ColumnDimOption = ColumnDimOption::Period then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
    end;

    local procedure AmountTypeOnAfterValidate()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
        if ColumnDimOption = ColumnDimOption::Period then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLAccFilter(var GLAccount: Record "G/L Account"; var GLAccFilter: Text; LineDimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4"; ColumnDimOption: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4")
    begin
    end;
}

