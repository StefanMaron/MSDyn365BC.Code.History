codeunit 7130 "Item Budget Management"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'DEFAULT';
        Text002: Label 'Default budget';
        GLSetup: Record "General Ledger Setup";
        PrevItemBudgetName: Record "Item Budget Name";
        Text003: Label 'Period';
        Text004: Label '%1 is not a valid line definition.';
        Text005: Label '%1 is not a valid column definition.';
        MatrixMgt: Codeunit "Matrix Management";
        GLSetupRead: Boolean;
        Text006: Label 'Do you want to delete the budget entries shown?';
        Text007: Label '<Sign><Integer Thousand><Decimals,2>, Locked = true';
        GlobalDimOption: Option Item,Customer,Vendor,Period,Location,"Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3";

    procedure BudgetNameSelection(CurrentAnalysisArea: Option; var CurrentItemBudgetName: Code[10]; var ItemBudgetName: Record "Item Budget Name"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var BudgetDim1Filter: Text; var BudgetDim2Filter: Text; var BudgetDim3Filter: Text)
    begin
        if not ItemBudgetName.Get(CurrentAnalysisArea, CurrentItemBudgetName) then begin
            ItemBudgetName.FilterGroup := 2;
            ItemBudgetName.SetRange("Analysis Area", CurrentAnalysisArea);
            ItemBudgetName.FilterGroup := 0;
            if not ItemBudgetName.Find('-') then begin
                ItemBudgetName.Init();
                ItemBudgetName."Analysis Area" := CurrentAnalysisArea;
                ItemBudgetName.Name := Text001;
                ItemBudgetName.Description := Text002;
                ItemBudgetName.Insert(true);
            end;
            CurrentItemBudgetName := ItemBudgetName.Name;
        end;

        SetItemBudgetName(
          CurrentItemBudgetName, ItemBudgetName, ItemStatisticsBuffer,
          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
    end;

    procedure CheckBudgetName(CurrentAnalysisType: Option; CurrentItemBudgetName: Code[10]; var ItemBudgetName: Record "Item Budget Name")
    begin
        ItemBudgetName.Get(CurrentAnalysisType, CurrentItemBudgetName);
    end;

    procedure SetItemBudgetName(CurrentItemBudgetName: Code[10]; var ItemBudgetName: Record "Item Budget Name"; var ItemStatisticsBuf: Record "Item Statistics Buffer"; var BudgetDim1Filter: Text; var BudgetDim2Filter: Text; var BudgetDim3Filter: Text)
    begin
        ItemStatisticsBuf.SetRange("Budget Filter", CurrentItemBudgetName);
        if PrevItemBudgetName.Name <> '' then begin
            if ItemBudgetName."Budget Dimension 1 Code" <> PrevItemBudgetName."Budget Dimension 1 Code" then
                BudgetDim1Filter := '';
            if ItemBudgetName."Budget Dimension 2 Code" <> PrevItemBudgetName."Budget Dimension 2 Code" then
                BudgetDim2Filter := '';
            if ItemBudgetName."Budget Dimension 3 Code" <> PrevItemBudgetName."Budget Dimension 3 Code" then
                BudgetDim3Filter := '';
        end;
        ItemStatisticsBuf.SetFilter("Dimension 1 Filter", BudgetDim1Filter);
        ItemStatisticsBuf.SetFilter("Dimension 2 Filter", BudgetDim2Filter);
        ItemStatisticsBuf.SetFilter("Dimension 3 Filter", BudgetDim3Filter);

        PrevItemBudgetName := ItemBudgetName;
    end;

    procedure LookupItemBudgetName(var CurrentItemBudgetName: Code[10]; var ItemBudgetName: Record "Item Budget Name"; var ItemStatisticsBuf: Record "Item Statistics Buffer"; var BudgetDim1Filter: Text; var BudgetDim2Filter: Text; var BudgetDim3Filter: Text)
    var
        ItemBudgetName2: Record "Item Budget Name";
    begin
        ItemBudgetName2.Copy(ItemBudgetName);
        ItemBudgetName2.FilterGroup := 2;
        ItemBudgetName2.SetRange("Analysis Area", ItemBudgetName2."Analysis Area");
        ItemBudgetName2.FilterGroup := 0;
        if PAGE.RunModal(0, ItemBudgetName2) = ACTION::LookupOK then begin
            ItemBudgetName := ItemBudgetName2;
            CurrentItemBudgetName := ItemBudgetName.Name;
            SetItemBudgetName(
              CurrentItemBudgetName, ItemBudgetName, ItemStatisticsBuf,
              BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        end else
            BudgetNameSelection(
              ItemBudgetName."Analysis Area", CurrentItemBudgetName, ItemBudgetName, ItemStatisticsBuf,
              BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
    end;

    procedure SetLineAndColDim(ItemBudgetName: Record "Item Budget Name"; var LineDimCode: Text[30]; var LineDimOption: Option; var ColumnDimCode: Text[30]; var ColumnDimOption: Option)
    var
        Item: Record Item;
    begin
        if (LineDimCode = '') and (ColumnDimCode = '') then begin
            LineDimCode := Item.TableCaption;
            ColumnDimCode := Text003;
        end;
        LineDimOption := DimCodeToOption(LineDimCode, ItemBudgetName);
        ColumnDimOption := DimCodeToOption(ColumnDimCode, ItemBudgetName);
    end;

    procedure FindRec(ItemBudgetName: Record "Item Budget Name"; DimOption: Option; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]; ItemFilter: Text; SourceNoFilter: Text; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; DateFilter: Text; var PeriodInitialized: Boolean; InternalDateFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text): Boolean
    var
        Item: Record Item;
        Cust: Record Customer;
        Vend: Record Vendor;
        Location: Record Location;
        Period: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
        Found: Boolean;
    begin
        GetGLSetup;
        case DimOption of
            GlobalDimOption::Item:
                begin
                    Item."No." := DimCodeBuf.Code;
                    if ItemFilter <> '' then
                        Item.SetFilter("No.", ItemFilter);
                    OnFindRecOnBeforeItemFind(Item);
                    Found := Item.Find(Which);
                    if Found then
                        CopyItemToBuf(Item, DimCodeBuf);
                end;
            GlobalDimOption::Customer:
                begin
                    Cust."No." := DimCodeBuf.Code;
                    if SourceNoFilter <> '' then
                        Cust.SetFilter("No.", SourceNoFilter);
                    Found := Cust.Find(Which);
                    if Found then
                        CopyCustToBuf(Cust, DimCodeBuf);
                end;
            GlobalDimOption::Vendor:
                begin
                    Vend."No." := DimCodeBuf.Code;
                    if SourceNoFilter <> '' then
                        Vend.SetFilter("No.", SourceNoFilter);
                    Found := Vend.Find(Which);
                    if Found then
                        CopyVendToBuf(Vend, DimCodeBuf);
                end;
            GlobalDimOption::Period:
                begin
                    Period."Period Start" := DimCodeBuf."Period Start";
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter)
                    else
                        if not PeriodInitialized and (InternalDateFilter <> '') then
                            Period.SetFilter("Period Start", InternalDateFilter);
                    Found := PeriodFormMgt.FindDate(Which, Period, PeriodType);
                    if Found then
                        CopyPeriodToBuf(Period, DimCodeBuf, DateFilter);
                    PeriodInitialized := true;
                end;
            GlobalDimOption::Location:
                begin
                    Location.Code := DimCodeBuf.Code;
                    if SourceNoFilter <> '' then
                        Location.SetFilter(Code, SourceNoFilter);
                    Found := Location.Find(Which);
                    if Found then
                        CopyLocationToBuf(Location, DimCodeBuf);
                end;
            GlobalDimOption::"Global Dimension 1":
                Found := FindDim(DimCodeBuf, Which, GlobalDim1Filter, GLSetup."Global Dimension 1 Code");
            GlobalDimOption::"Global Dimension 2":
                Found := FindDim(DimCodeBuf, Which, GlobalDim2Filter, GLSetup."Global Dimension 2 Code");
            GlobalDimOption::"Budget Dimension 1":
                Found := FindDim(DimCodeBuf, Which, BudgetDim1Filter, ItemBudgetName."Budget Dimension 1 Code");
            GlobalDimOption::"Budget Dimension 2":
                Found := FindDim(DimCodeBuf, Which, BudgetDim2Filter, ItemBudgetName."Budget Dimension 2 Code");
            GlobalDimOption::"Budget Dimension 3":
                Found := FindDim(DimCodeBuf, Which, BudgetDim3Filter, ItemBudgetName."Budget Dimension 3 Code");
        end;
        exit(Found);
    end;

    local procedure FindDim(var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]; DimFilter: Text; DimCode: Code[20]): Boolean
    var
        DimVal: Record "Dimension Value";
    begin
        if DimFilter <> '' then
            DimVal.SetFilter(Code, DimFilter);
        DimVal."Dimension Code" := DimCode;
        DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
        DimVal.Code := DimCodeBuf.Code;
        if DimVal.Find(Which) then begin
            CopyDimValToBuf(DimVal, DimCodeBuf);
            exit(true);
        end
    end;

    procedure NextRec(ItemBudgetName: Record "Item Budget Name"; DimOption: Option; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; ItemFilter: Text; SourceNoFilter: Text; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; DateFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text): Integer
    var
        Item: Record Item;
        Cust: Record Customer;
        Vend: Record Vendor;
        Location: Record Location;
        Period: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
        ResultSteps: Integer;
    begin
        GetGLSetup;
        case DimOption of
            GlobalDimOption::Item:
                begin
                    Item."No." := DimCodeBuf.Code;
                    if ItemFilter <> '' then
                        Item.SetFilter("No.", ItemFilter);
                    OnNextRecOnBeforeItemFind(Item);
                    ResultSteps := Item.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyItemToBuf(Item, DimCodeBuf);
                end;
            GlobalDimOption::Customer:
                begin
                    Cust."No." := DimCodeBuf.Code;
                    if SourceNoFilter <> '' then
                        Cust.SetFilter("No.", SourceNoFilter);
                    ResultSteps := Cust.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyCustToBuf(Cust, DimCodeBuf);
                end;
            GlobalDimOption::Vendor:
                begin
                    Vend."No." := DimCodeBuf.Code;
                    if SourceNoFilter <> '' then
                        Vend.SetFilter("No.", SourceNoFilter);
                    ResultSteps := Vend.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyVendToBuf(Vend, DimCodeBuf);
                end;
            GlobalDimOption::Period:
                begin
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter);
                    Period."Period Start" := DimCodeBuf."Period Start";
                    ResultSteps := PeriodFormMgt.NextDate(Steps, Period, PeriodType);
                    if ResultSteps <> 0 then
                        CopyPeriodToBuf(Period, DimCodeBuf, DateFilter);
                end;
            GlobalDimOption::Location:
                begin
                    Location.Code := DimCodeBuf.Code;
                    if SourceNoFilter <> '' then
                        Location.SetFilter(Code, SourceNoFilter);
                    ResultSteps := Location.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyLocationToBuf(Location, DimCodeBuf);
                end;
            GlobalDimOption::"Global Dimension 1":
                ResultSteps := NextDim(DimCodeBuf, Steps, GlobalDim1Filter, GLSetup."Global Dimension 1 Code");
            GlobalDimOption::"Global Dimension 2":
                ResultSteps := NextDim(DimCodeBuf, Steps, GlobalDim2Filter, GLSetup."Global Dimension 2 Code");
            GlobalDimOption::"Budget Dimension 1":
                ResultSteps := NextDim(DimCodeBuf, Steps, BudgetDim1Filter, ItemBudgetName."Budget Dimension 1 Code");
            GlobalDimOption::"Budget Dimension 2":
                ResultSteps := NextDim(DimCodeBuf, Steps, BudgetDim2Filter, ItemBudgetName."Budget Dimension 2 Code");
            GlobalDimOption::"Budget Dimension 3":
                ResultSteps := NextDim(DimCodeBuf, Steps, BudgetDim3Filter, ItemBudgetName."Budget Dimension 3 Code");
        end;
        exit(ResultSteps);
    end;

    local procedure NextDim(var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; DimFilter: Text; DimCode: Code[20]): Integer
    var
        DimVal: Record "Dimension Value";
        ActualSteps: Integer;
    begin
        if DimFilter <> '' then
            DimVal.SetFilter(Code, DimFilter);
        DimVal."Dimension Code" := DimCode;
        DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
        DimVal.Code := DimCodeBuf.Code;
        ActualSteps := DimVal.Next(Steps);
        if ActualSteps <> 0 then
            CopyDimValToBuf(DimVal, DimCodeBuf);
        exit(ActualSteps);
    end;

    procedure SetCommonFilters(var ItemStatisticsBuf: Record "Item Statistics Buffer"; ItemBudgetName: Record "Item Budget Name"; ItemFilter: Text; SourceTypeFilter: Option; SourceNoFilter: Text; DateFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text)
    begin
        with ItemStatisticsBuf do begin
            Reset;
            SetRange("Analysis Area Filter", ItemBudgetName."Analysis Area");
            SetRange("Budget Filter", ItemBudgetName.Name);
            if ItemFilter <> '' then
                SetFilter("Item Filter", ItemFilter);
            if SourceNoFilter <> '' then begin
                SetFilter("Source Type Filter", '%1', SourceTypeFilter);
                SetFilter("Source No. Filter", SourceNoFilter);
            end;
            if DateFilter <> '' then
                SetFilter("Date Filter", DateFilter);
            if GlobalDim1Filter <> '' then
                SetFilter("Global Dimension 1 Filter", GlobalDim1Filter);
            if GlobalDim2Filter <> '' then
                SetFilter("Global Dimension 2 Filter", GlobalDim2Filter);
            if BudgetDim1Filter <> '' then
                SetFilter("Dimension 1 Filter", BudgetDim1Filter);
            if BudgetDim2Filter <> '' then
                SetFilter("Dimension 2 Filter", BudgetDim2Filter);
            if BudgetDim3Filter <> '' then
                SetFilter("Dimension 3 Filter", BudgetDim3Filter);
        end;
    end;

    procedure SetDimFilters(var ItemStatisticsBuf: Record "Item Statistics Buffer"; DimOption: Option; DimCodeBuf: Record "Dimension Code Buffer")
    begin
        with ItemStatisticsBuf do
            case DimOption of
                GlobalDimOption::Item:
                    SetRange("Item Filter", DimCodeBuf.Code);
                GlobalDimOption::Customer:
                    begin
                        SetRange("Source Type Filter", "Source Type Filter"::Customer);
                        SetRange("Source No. Filter", DimCodeBuf.Code);
                    end;
                GlobalDimOption::Vendor:
                    begin
                        SetRange("Source Type Filter", "Source Type Filter"::Vendor);
                        SetRange("Source No. Filter", DimCodeBuf.Code);
                    end;
                GlobalDimOption::Location:
                    SetRange("Location Filter", DimCodeBuf.Code);
                GlobalDimOption::Period:
                    SetRange("Date Filter", DimCodeBuf."Period Start", DimCodeBuf."Period End");
                GlobalDimOption::"Global Dimension 1":
                    if DimCodeBuf.Totaling <> '' then
                        SetFilter("Global Dimension 1 Filter", DimCodeBuf.Totaling)
                    else
                        SetRange("Global Dimension 1 Filter", DimCodeBuf.Code);
                GlobalDimOption::"Global Dimension 2":
                    if DimCodeBuf.Totaling <> '' then
                        SetFilter("Global Dimension 2 Filter", DimCodeBuf.Totaling)
                    else
                        SetRange("Global Dimension 2 Filter", DimCodeBuf.Code);
                GlobalDimOption::"Budget Dimension 1":
                    if DimCodeBuf.Totaling <> '' then
                        SetFilter("Dimension 1 Filter", DimCodeBuf.Totaling)
                    else
                        SetRange("Dimension 1 Filter", DimCodeBuf.Code);
                GlobalDimOption::"Budget Dimension 2":
                    if DimCodeBuf.Totaling <> '' then
                        SetFilter("Dimension 2 Filter", DimCodeBuf.Totaling)
                    else
                        SetRange("Dimension 2 Filter", DimCodeBuf.Code);
                GlobalDimOption::"Budget Dimension 3":
                    if DimCodeBuf.Totaling <> '' then
                        SetFilter("Dimension 3 Filter", DimCodeBuf.Totaling)
                    else
                        SetRange("Dimension 3 Filter", DimCodeBuf.Code);
            end;
    end;

    local procedure DimCodeToOption(DimCode: Code[20]; ItemBudgetName: Record "Item Budget Name"): Integer
    var
        Location: Record Location;
        Item: Record Item;
        Cust: Record Customer;
        Vend: Record Vendor;
    begin
        GetGLSetup;
        case DimCode of
            '':
                exit(-1);
            UpperCase(Item.TableCaption):
                exit(0);
            UpperCase(Cust.TableCaption):
                exit(1);
            UpperCase(Vend.TableCaption):
                exit(2);
            UpperCase(Text003):
                exit(3);
            UpperCase(Location.TableCaption):
                exit(4);
            GLSetup."Global Dimension 1 Code":
                exit(5);
            GLSetup."Global Dimension 2 Code":
                exit(6);
            ItemBudgetName."Budget Dimension 1 Code":
                exit(7);
            ItemBudgetName."Budget Dimension 2 Code":
                exit(8);
            ItemBudgetName."Budget Dimension 3 Code":
                exit(9);
            else
                exit(-1);
        end;
    end;

    procedure GetDimSelection(OldDimSelCode: Text[30]; ItemBudgetName: Record "Item Budget Name"): Text[30]
    var
        Item: Record Item;
        Cust: Record Customer;
        Vend: Record Vendor;
        Location: Record Location;
        DimSelection: Page "Dimension Selection";
    begin
        GetGLSetup;
        DimSelection.InsertDimSelBuf(false, Item.TableCaption, Item.TableCaption);
        DimSelection.InsertDimSelBuf(false, Cust.TableCaption, Cust.TableCaption);
        DimSelection.InsertDimSelBuf(false, Location.TableCaption, Location.TableCaption);
        DimSelection.InsertDimSelBuf(false, Vend.TableCaption, Vend.TableCaption);
        DimSelection.InsertDimSelBuf(false, Text003, Text003);
        if GLSetup."Global Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 1 Code", '');
        if GLSetup."Global Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, GLSetup."Global Dimension 2 Code", '');
        if ItemBudgetName."Budget Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, ItemBudgetName."Budget Dimension 1 Code", '');
        if ItemBudgetName."Budget Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, ItemBudgetName."Budget Dimension 2 Code", '');
        if ItemBudgetName."Budget Dimension 3 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, ItemBudgetName."Budget Dimension 3 Code", '');

        DimSelection.LookupMode := true;
        if DimSelection.RunModal = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode);
        exit(OldDimSelCode);
    end;

    procedure ValidateLineDimCode(ItemBudgetName: Record "Item Budget Name"; var LineDimCode: Text[30]; var LineDimOption: Option; ColumnDimOption: Option; var InternalDateFilter: Text; var DateFilter: Text; var ItemStatisticsBuf: Record "Item Statistics Buffer"; var PeriodInitialized: Boolean)
    begin
        if DimCodeNotAllowed(LineDimCode, ItemBudgetName) then begin
            Message(Text004, LineDimCode);
            LineDimCode := '';
        end;
        LineDimOption := DimCodeToOption(LineDimCode, ItemBudgetName);
        InternalDateFilter := ItemStatisticsBuf.GetFilter("Date Filter");
        if (not OptionIsPeriod(LineDimOption)) and (not OptionIsPeriod(ColumnDimOption)) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    procedure ValidateColumnDimCode(ItemBudgetName: Record "Item Budget Name"; var ColumnDimCode: Text[30]; var ColumnDimOption: Option; LineDimOption: Option; var InternalDateFilter: Text; var DateFilter: Text; var ItemStatisticsBuf: Record "Item Statistics Buffer"; var PeriodInitialized: Boolean)
    begin
        if DimCodeNotAllowed(ColumnDimCode, ItemBudgetName) then begin
            Message(Text005, ColumnDimCode);
            ColumnDimCode := '';
        end;
        ColumnDimOption := DimCodeToOption(ColumnDimCode, ItemBudgetName);
        InternalDateFilter := ItemStatisticsBuf.GetFilter("Date Filter");
        if (not OptionIsPeriod(ColumnDimOption)) and (not OptionIsPeriod(LineDimOption)) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    procedure DimCodeNotAllowed(DimCode: Text[30]; ItemBudgetName: Record "Item Budget Name"): Boolean
    var
        Item: Record Item;
        Cust: Record Customer;
        Vend: Record Vendor;
        Location: Record Location;
    begin
        GetGLSetup;
        exit(
          not (UpperCase(DimCode) in
               [UpperCase(Item.TableCaption),
                UpperCase(Cust.TableCaption),
                UpperCase(Vend.TableCaption),
                UpperCase(Location.TableCaption),
                UpperCase(Text003),
                ItemBudgetName."Budget Dimension 1 Code",
                ItemBudgetName."Budget Dimension 2 Code",
                ItemBudgetName."Budget Dimension 3 Code",
                GLSetup."Global Dimension 1 Code",
                GLSetup."Global Dimension 2 Code",
                '']));
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
                    Text := Format(Amount, 0, Text007);
            end;
    end;

    procedure BudgetDrillDown(ItemBudgetName: Record "Item Budget Name"; ItemFilter: Text; SourceTypeFilter: Option; SourceNoFilter: Text; DateFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text; RowDimOption: Option Item,Customer,Vendor,Period,Location,"Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3"; RowDimCodeBuf: Record "Dimension Code Buffer"; ColDimOption: Option Item,Customer,Vendor,Period,Location,"Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3"; ColDimCodeBuf: Record "Dimension Code Buffer"; ValueType: Option "Sales Amount","Cost Amount",Quantity; LinesOnly: Boolean)
    var
        ItemStatisticsBuf: Record "Item Statistics Buffer";
        ItemBudgetEntry: Record "Item Budget Entry";
    begin
        SetCommonFilters(
          ItemStatisticsBuf, ItemBudgetName,
          ItemFilter, SourceTypeFilter, SourceNoFilter, DateFilter,
          GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        SetDimFilters(ItemStatisticsBuf, RowDimOption, RowDimCodeBuf);
        if not LinesOnly then
            SetDimFilters(ItemStatisticsBuf, ColDimOption, ColDimCodeBuf);

        ItemBudgetEntry.SetRange("Analysis Area", ItemBudgetName."Analysis Area");
        ItemBudgetEntry.SetRange("Budget Name", ItemBudgetName.Name);

        if ItemStatisticsBuf.GetFilter("Item Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Item Filter", ItemBudgetEntry."Item No.");
        if ItemStatisticsBuf.GetFilter("Global Dimension 1 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Global Dimension 1 Filter", ItemBudgetEntry."Global Dimension 1 Code");
        if ItemStatisticsBuf.GetFilter("Global Dimension 2 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Global Dimension 2 Filter", ItemBudgetEntry."Global Dimension 2 Code");
        if ItemStatisticsBuf.GetFilter("Dimension 1 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Dimension 1 Filter", ItemBudgetEntry."Budget Dimension 1 Code");
        if ItemStatisticsBuf.GetFilter("Dimension 2 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Dimension 2 Filter", ItemBudgetEntry."Budget Dimension 2 Code");
        if ItemStatisticsBuf.GetFilter("Dimension 3 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Dimension 3 Filter", ItemBudgetEntry."Budget Dimension 3 Code");
        if ItemStatisticsBuf.GetFilter("Location Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Location Filter", ItemBudgetEntry."Location Code");
        if ItemStatisticsBuf.GetFilter("Date Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Date Filter", ItemBudgetEntry.Date)
        else
            ItemBudgetEntry.SetRange(Date, 0D, DMY2Date(31, 12, 9999));

        if ItemStatisticsBuf.GetFilter("Source No. Filter") <> '' then begin
            ItemStatisticsBuf.CopyFilter("Source Type Filter", ItemBudgetEntry."Source Type");
            ItemStatisticsBuf.CopyFilter("Source No. Filter", ItemBudgetEntry."Source No.");
            ItemBudgetEntry.SetCurrentKey("Analysis Area", "Budget Name", "Source Type", "Source No.", "Item No.");
        end else
            ItemBudgetEntry.SetCurrentKey("Analysis Area", "Budget Name", "Item No.");

        case ValueType of
            ValueType::"Sales Amount":
                PAGE.Run(0, ItemBudgetEntry, ItemBudgetEntry."Sales Amount");
            ValueType::"Cost Amount":
                PAGE.Run(0, ItemBudgetEntry, ItemBudgetEntry."Cost Amount");
            ValueType::Quantity:
                PAGE.Run(0, ItemBudgetEntry, ItemBudgetEntry.Quantity);
        end;
    end;

    procedure DeleteBudget(AnalysisArea: Integer; ItemBudgetName: Code[10]; ItemFilter: Text; DateFilter: Text; SourceTypeFilter: Option; SourceNoFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text)
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
    begin
        if Confirm(Text006) then
            with ItemBudgetEntry do begin
                SetRange("Analysis Area", AnalysisArea);
                SetRange("Budget Name", ItemBudgetName);
                if ItemFilter <> '' then
                    SetFilter("Item No.", ItemFilter);
                if DateFilter <> '' then
                    SetFilter(Date, DateFilter);
                if SourceNoFilter <> '' then begin
                    SetRange("Source Type", SourceTypeFilter);
                    SetFilter("Source No.", SourceNoFilter);
                end;
                if GlobalDim1Filter <> '' then
                    SetFilter("Global Dimension 1 Code", GlobalDim1Filter);
                if GlobalDim2Filter <> '' then
                    SetFilter("Global Dimension 2 Code", GlobalDim2Filter);
                if BudgetDim1Filter <> '' then
                    SetFilter("Budget Dimension 1 Code", BudgetDim1Filter);
                if BudgetDim2Filter <> '' then
                    SetFilter("Budget Dimension 2 Code", BudgetDim2Filter);
                if BudgetDim3Filter <> '' then
                    SetFilter("Budget Dimension 3 Code", BudgetDim3Filter);
                SetCurrentKey("Entry No.");
                if FindFirst then
                    UpdateItemAnalysisView.SetLastBudgetEntryNo("Entry No." - 1);
                SetCurrentKey("Analysis Area", "Budget Name");
                DeleteAll(true);
            end;
    end;

    local procedure GetGLSetup()
    begin
        if GLSetupRead then
            exit;
        GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure CopyItemToBuf(var Item: Record Item; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Item."No.";
        DimCodeBuf.Name := Item.Description;

        OnAfterCopyItemToBuf(Item, DimCodeBuf);
    end;

    local procedure CopyCustToBuf(var Cust: Record Customer; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Cust."No.";
        DimCodeBuf.Name := Cust.Name;
    end;

    local procedure CopyVendToBuf(var Vend: Record Vendor; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Vend."No.";
        DimCodeBuf.Name := Vend.Name;
    end;

    local procedure CopyPeriodToBuf(var DatePeriod: Record Date; var DimCodeBuf: Record "Dimension Code Buffer"; DateFilter: Text)
    var
        DatePeriod2: Record Date;
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Format(DatePeriod."Period Start");
        DimCodeBuf."Period Start" := DatePeriod."Period Start";
        DimCodeBuf."Period End" := DatePeriod."Period End";
        if DateFilter <> '' then begin
            DatePeriod2.SetFilter("Period End", DateFilter);
            if DatePeriod2.GetRangeMax("Period End") < DimCodeBuf."Period End" then
                DimCodeBuf."Period End" := DatePeriod2.GetRangeMax("Period End");
        end;
        DimCodeBuf.Name := DatePeriod."Period Name";
    end;

    local procedure CopyLocationToBuf(var Location: Record Location; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Location.Code;
        if Location.Name <> '' then
            DimCodeBuf.Name := Location.Name
    end;

    local procedure CopyDimValToBuf(var DimVal: Record "Dimension Value"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := DimVal.Code;
        DimCodeBuf.Name := DimVal.Name;
        DimCodeBuf.Totaling := DimVal.Totaling;
        DimCodeBuf.Indentation := DimVal.Indentation;
        DimCodeBuf."Show in Bold" := DimVal."Dimension Value Type" <> DimVal."Dimension Value Type"::Standard;
    end;

    procedure CalcAmount(ValueType: Option "Sales Amount","Cost Amount",Quantity; SetColumnFilter: Boolean; var ItemStatisticsBuf: Record "Item Statistics Buffer"; ItemBudgetName: Record "Item Budget Name"; ItemFilter: Text; SourceTypeFilter: Option " ",Customer,Vendor,Item; SourceNoFilter: Text; DateFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text; RowDimOption: Option Item,Customer,Vendor,Period,Location,"Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3","Budget Dimension 4"; RowDimCodeBuf: Record "Dimension Code Buffer"; ColDimOption: Option Item,Customer,Vendor,Period,Location,"Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3","Budget Dimension 4"; ColDimCodeBuf: Record "Dimension Code Buffer"): Decimal
    begin
        SetCommonFilters(
          ItemStatisticsBuf, ItemBudgetName, ItemFilter, SourceTypeFilter, SourceNoFilter,
          DateFilter, GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        SetDimFilters(ItemStatisticsBuf, RowDimOption, RowDimCodeBuf);
        if SetColumnFilter then
            SetDimFilters(ItemStatisticsBuf, ColDimOption, ColDimCodeBuf);

        case ValueType of
            ValueType::"Sales Amount":
                begin
                    ItemStatisticsBuf.CalcFields("Budgeted Sales Amount");
                    exit(ItemStatisticsBuf."Budgeted Sales Amount");
                end;
            ValueType::"Cost Amount":
                begin
                    ItemStatisticsBuf.CalcFields("Budgeted Cost Amount");
                    exit(ItemStatisticsBuf."Budgeted Cost Amount");
                end;
            ValueType::Quantity:
                begin
                    ItemStatisticsBuf.CalcFields("Budgeted Quantity");
                    exit(ItemStatisticsBuf."Budgeted Quantity");
                end;
        end;
    end;

    procedure UpdateAmount(ValueType: Option "Sales Amount","Cost Amount",Quantity; SetColumnFilter: Boolean; var ItemStatisticsBuf: Record "Item Statistics Buffer"; ItemBudgetName: Record "Item Budget Name"; ItemFilter: Text; SourceTypeFilter: Option " ",Customer,Vendor,Item; SourceNoFilter: Text; DateFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text; BudgetDim1Filter: Text; BudgetDim2Filter: Text; BudgetDim3Filter: Text; RowDimOption: Option Item,Customer,Vendor,Period,Location,"Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3","Budget Dimension 4"; RowDimCodeBuf: Record "Dimension Code Buffer"; ColDimOption: Option Item,Customer,Vendor,Period,Location,"Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3","Budget Dimension 4"; ColDimCodeBuf: Record "Dimension Code Buffer"; NewAmount: Decimal)
    begin
        SetCommonFilters(
          ItemStatisticsBuf, ItemBudgetName, ItemFilter, SourceTypeFilter, SourceNoFilter,
          DateFilter, GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        SetDimFilters(ItemStatisticsBuf, RowDimOption, RowDimCodeBuf);
        if SetColumnFilter then
            SetDimFilters(ItemStatisticsBuf, ColDimOption, ColDimCodeBuf);

        case ValueType of
            ValueType::"Sales Amount":
                begin
                    ItemStatisticsBuf.CalcFields("Budgeted Sales Amount");
                    ItemStatisticsBuf.Validate("Budgeted Sales Amount", NewAmount);
                end;
            ValueType::"Cost Amount":
                begin
                    ItemStatisticsBuf.CalcFields("Budgeted Cost Amount");
                    ItemStatisticsBuf.Validate("Budgeted Cost Amount", NewAmount);
                end;
            ValueType::Quantity:
                begin
                    ItemStatisticsBuf.CalcFields("Budgeted Quantity");
                    ItemStatisticsBuf.Validate("Budgeted Quantity", NewAmount);
                end;
        end;
    end;

    local procedure OptionIsPeriod(DimOption: Option): Boolean
    begin
        exit(DimOption = GlobalDimOption::Period);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemToBuf(var Item: Record Item; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecOnBeforeItemFind(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextRecOnBeforeItemFind(var Item: Record Item)
    begin
    end;
}

