page 408 "G/L Balance by Dimension"
{
    Caption = 'G/L Balance by Dimension';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTableTemporary = true;
    SourceTable = "Analysis by Dim. Parameters";

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
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            ColumnDimCode := '';
                            ValidateColumnDimCode;
                        end;
                        ValidateLineDimCode;
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
                field(DateFilter; "Date Filter")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                        Date1: Date;
                    begin
                        FilterTokens.MakeDateFilter("Date Filter");
                        if "Date Filter" <> '' then
                            if Evaluate(Date1, "Date Filter") then
                                if Date1 <> NormalDate(Date1) then
                                    "Date Filter" := StrSubstNo('%1..%2', NormalDate(Date1), Date1);
                        GLAcc.SetFilter("Date Filter", "Date Filter");
                        "Date Filter" := GLAcc.GetFilter("Date Filter");
                        InternalDateFilter := "Date Filter";
                        DateFilterOnAfterValidate;
                    end;
                }
                field(GLAccFilter; "Account Filter")
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
                field(BudgetFilter; "Budget Filter")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Budget Filter';
                    LookupPageID = "G/L Budget Names";
                    TableRelation = "G/L Budget Name".Name;
                    ToolTip = 'Specifies the budget that information in the matrix is shown for.';
                }
                field(BusUnitFilter; "Bus. Unit Filter")
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
                field(Dim1Filter; "Dimension 1 Filter")
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
                field(Dim2Filter; "Dimension 2 Filter")
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
                field(ShowActualBudg; "Show Actual/Budgets")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies if the selected value is shown in the window.';
                }
                field(AmountField; "Show Amount Field")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the type of entries that will be included in the matrix window. The Amount options means that amounts that are the sum of debit and credit amounts are shown.';
                }
                field(ClosingEntryFilter; "Closing Entries")
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
                field(RoundingFactor; "Rounding Factor")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Rounding Factor';
                    OptionCaption = 'None,1,1000,1000000';
                    ToolTip = 'Specifies the factor that is used to round the amounts.';
                }
                field(ShowInAddCurr; "Show In Add. Currency")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Show Amounts in Add. Reporting Currency';
                    MultiLine = true;
                    ToolTip = 'Specifies whether to show the reported amounts in the additional reporting currency.';
                }
                field(ShowColumnName; "Show Column Name")
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
                field(PeriodType; "Period Type")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        PeriodTypeOnAfterValidate;
                    end;
                }
                field(AmountType; "Amount Type")
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
                field(MATRIX_ColumnSet; "Column Set")
                {
                    ApplicationArea = Dimensions;
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

                    MatrixForm.Load(Rec, LineDimCode, ColumnDimCode, MATRIX_ColumnCaptions, MATRIX_PrimaryKeyFirstColInSet, MATRIX_CurrSetLength);
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
        Insert();
        OnBeforeGLAccFilter(GLAcc, "Account Filter", LineDimOption, ColumnDimOption);
        "Dimension 1 Filter" := GLAcc.GetFilter("Global Dimension 1 Filter");
        "Dimension 2 Filter" := GLAcc.GetFilter("Global Dimension 2 Filter");

        GLSetup.Get();
        Dim1FilterEnable :=
          (GLSetup."Global Dimension 1 Code" <> '') and
          (GLAcc.GetFilter("Global Dimension 1 Filter") = '');
        Dim2FilterEnable :=
          (GLSetup."Global Dimension 2 Code" <> '') and
          (GLAcc.GetFilter("Global Dimension 2 Filter") = '');

        if GLSetup."Additional Reporting Currency" = '' then
            "Show In Add. Currency" := false;

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
        InternalDateFilter: Text;
        BusUnitFilterCaption: Text[80];
        PeriodInitialized: Boolean;
        MATRIX_ColumnCaptions: array[32] of Text[1024];
        MATRIX_NoOfColumns: Integer;
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
        if "Date Filter" <> '' then begin
            Period.SetFilter("Period Start", "Date Filter");
            if not PeriodFormMgt.FindDate('+', Period, "Period Type") then
                PeriodFormMgt.FindDate('+', Period, "Period Type"::Day);
            Period.SetRange("Period Start");
        end;
        if PeriodFormMgt.FindDate(SearchText, Period, "Period Type") then
            if "Closing Entries" = "Closing Entries"::Include then
                Period."Period End" := ClosingDate(Period."Period End");
        if "Amount Type" = "Amount Type"::"Net Change" then begin
            GLAcc.SetRange("Date Filter", Period."Period Start", Period."Period End");
            if GLAcc.GetRangeMin("Date Filter") = GLAcc.GetRangeMax("Date Filter") then
                GLAcc.SetRange("Date Filter", GLAcc.GetRangeMin("Date Filter"));
        end else
            GLAcc.SetRange("Date Filter", 0D, Period."Period End");

        InternalDateFilter := GLAcc.GetFilter("Date Filter");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then
            "Date Filter" := InternalDateFilter;
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
            "Date Filter" := InternalDateFilter;
            if StrPos("Date Filter", '&') > 1 then
                "Date Filter" := CopyStr("Date Filter", 1, StrPos("Date Filter", '&') - 1);
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
            "Date Filter" := InternalDateFilter;
            if StrPos("Date Filter", '&') > 1 then
                "Date Filter" := CopyStr("Date Filter", 1, StrPos("Date Filter", '&') - 1);
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
                    if "Account Filter" <> '' then
                        GLAcc.SetFilter("No.", "Account Filter");
                    Found := GLAcc.Find(Which);
                    if Found then
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if not PeriodInitialized then
                        "Date Filter" := '';
                    PeriodInitialized := true;
                    Evaluate(Period."Period Start", DimCodeBuf.Code);
                    if "Date Filter" <> '' then
                        Period.SetFilter("Period Start", "Date Filter")
                    else
                        if not PeriodInitialized and (InternalDateFilter <> '') then
                            Period.SetFilter("Period Start", InternalDateFilter);
                    Found := PeriodFormMgt.FindDate(Which, Period, "Period Type");
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
            DimOption::"Dimension 1":
                begin
                    if "Dimension 1 Filter" <> '' then
                        DimVal.SetFilter(Code, "Dimension 1 Filter");
                    DimVal."Dimension Code" := GLSetup."Global Dimension 1 Code";
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
                    if "Account Filter" <> '' then
                        GLAcc.SetFilter("No.", "Account Filter");
                    ResultSteps := GLAcc.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyGLAccToBuf(GLAcc, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if "Date Filter" <> '' then
                        Period.SetFilter("Period Start", "Date Filter");
                    Evaluate(Period."Period Start", DimCodeBuf.Code);
                    ResultSteps := PeriodFormMgt.NextDate(Steps, Period, "Period Type");
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
            DimOption::"Dimension 1":
                begin
                    if "Dimension 1 Filter" <> '' then
                        DimVal.SetFilter(Code, "Dimension 1 Filter");
                    DimVal."Dimension Code" := GLSetup."Global Dimension 1 Code";
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
        "Column Set" := '';

        case Step of
            Step::Initial:
                begin
                    if (ColumnDimOption = ColumnDimOption::Period) and ("Period Type" <> "Period Type"::"Accounting Period")
                       and ("Date Filter" = '')
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
                if "Show Column Name" then
                    MATRIX_ColumnCaptions[MATRIX_CurrSetLength] := CurrentColumn.Name
                else
                    MATRIX_ColumnCaptions[MATRIX_CurrSetLength] := CurrentColumn.Code;
            until (MATRIX_CurrSetLength = MATRIX_NoOfColumns) or (NextRec(ColumnDimOption, CurrentColumn, 1) <> 1);

            if MATRIX_CurrSetLength = 1 then
                "Column Set" := MATRIX_ColumnCaptions[1]
            else
                "Column Set" := MATRIX_ColumnCaptions[1] + '..' + MATRIX_ColumnCaptions[MATRIX_CurrSetLength];
        end;
    end;

    local procedure ColumnDimCodeOnAfterValidate()
    var
        MATRIX_Steps: Option First,Previous,Next;
    begin
        MATRIX_GenerateColumnCaptions(MATRIX_Steps::First);
    end;

    local procedure DateFilterOnAfterValidate()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
        if ColumnDimOption = ColumnDimOption::Period then begin
            PeriodInitialized := true;
            MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
        end;
    end;

    local procedure GLAccFilterOnAfterValidate()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
        if ColumnDimOption = ColumnDimOption::"G/L Account" then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
    end;

    local procedure GlobalDim2FilterOnAfterValidat()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
        if ColumnDimOption = ColumnDimOption::"Dimension 2" then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
    end;

    local procedure GlobalDim1FilterOnAfterValidat()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
        if ColumnDimOption = ColumnDimOption::"Dimension 1" then
            MATRIX_GenerateColumnCaptions(MATRIX_Step::First);
    end;

    local procedure BusUnitFilterOnAfterValidate()
    var
        MATRIX_Step: Option First,Previous,Next;
    begin
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

