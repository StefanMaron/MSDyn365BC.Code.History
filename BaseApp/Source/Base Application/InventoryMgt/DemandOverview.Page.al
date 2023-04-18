page 5830 "Demand Overview"
{
    AccessByPermission = TableData "Service Header" = R;
    AdditionalSearchTerms = 'supply planning,availability overview';
    ApplicationArea = Planning;
    Caption = 'Demand Overview';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    RefreshOnActivate = true;
    SourceTable = "Availability Calc. Overview";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Item No.", Date, "Attached to Entry No.", Type);
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(StartDate; StartDate)
                {
                    ApplicationArea = Planning;
                    Caption = 'Start Date';
                    ToolTip = 'Specifies the start date of the period for which you want to calculate demand.';

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                    end;
                }
                field(EndDate; EndDate)
                {
                    ApplicationArea = Planning;
                    Caption = 'End Date';
                    ToolTip = 'Specifies the end date of the period for which you want to calculate demand. Enter a date that is later than the start date.';

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                    end;
                }
                field(DemandType; DemandType)
                {
                    ApplicationArea = Planning;
                    Caption = 'Demand Type';
                    OptionCaption = ' All Demand,Sale,Production,Job,Service,Assembly';
                    ToolTip = 'Specifies a list of the types of orders for which you can calculate demand. Select one order type from the list:';

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                        DemandNoCtrlEnable := DemandType <> DemandType::" ";
                    end;
                }
                field(DemandNoCtrl; DemandNo)
                {
                    ApplicationArea = Planning;
                    Caption = 'Demand No.';
                    Enabled = DemandNoCtrlEnable;
                    ToolTip = 'Specifies the number of the item for which the demand calculation was initiated.';

                    trigger OnLookup(var Text: Text) Result: Boolean
                    var
                        SalesHeader: Record "Sales Header";
                        ProdOrder: Record "Production Order";
                        Job: Record Job;
                        ServHeader: Record "Service Header";
                        AsmHeader: Record "Assembly Header";
                        SalesList: Page "Sales List";
                        ProdOrderList: Page "Production Order List";
                        JobList: Page "Job List";
                        ServiceOrders: Page "Service Orders";
                        AsmOrders: Page "Assembly Orders";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeLookupDemandNo(Rec, DemandType, Result, IsHandled, Text);
                        if IsHandled then
                            exit(Result);

                        case DemandType of
                            DemandType::Sales:
                                begin
                                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                                    SalesList.SetTableView(SalesHeader);
                                    SalesList.LookupMode := true;
                                    if SalesList.RunModal() = ACTION::LookupOK then begin
                                        SalesList.GetRecord(SalesHeader);
                                        Text := SalesHeader."No.";
                                        exit(true);
                                    end;
                                    exit(false);
                                end;
                            DemandType::Production:
                                begin
                                    ProdOrder.SetRange(Status, ProdOrder.Status::Planned, ProdOrder.Status::Released);
                                    ProdOrderList.SetTableView(ProdOrder);
                                    ProdOrderList.LookupMode := true;
                                    if ProdOrderList.RunModal() = ACTION::LookupOK then begin
                                        ProdOrderList.GetRecord(ProdOrder);
                                        Text := ProdOrder."No.";
                                        exit(true);
                                    end;
                                    exit(false);
                                end;
                            DemandType::Services:
                                begin
                                    ServHeader.SetRange("Document Type", ServHeader."Document Type"::Order);
                                    ServiceOrders.SetTableView(ServHeader);
                                    ServiceOrders.LookupMode := true;
                                    if ServiceOrders.RunModal() = ACTION::LookupOK then begin
                                        ServiceOrders.GetRecord(ServHeader);
                                        Text := ServHeader."No.";
                                        exit(true);
                                    end;
                                    exit(false);
                                end;
                            DemandType::Jobs:
                                begin
                                    Job.SetRange(Status, Job.Status::Open);
                                    JobList.SetTableView(Job);
                                    JobList.LookupMode := true;
                                    if JobList.RunModal() = ACTION::LookupOK then begin
                                        JobList.GetRecord(Job);
                                        Text := Job."No.";
                                        exit(true);
                                    end;
                                    exit(false);
                                end;
                            DemandType::Assembly:
                                begin
                                    AsmHeader.SetRange("Document Type", AsmHeader."Document Type"::Order);
                                    AsmOrders.SetTableView(AsmHeader);
                                    AsmOrders.LookupMode := true;
                                    if AsmOrders.RunModal() = ACTION::LookupOK then begin
                                        AsmOrders.GetRecord(AsmHeader);
                                        Text := AsmHeader."No.";
                                        exit(true);
                                    end;
                                    exit(false);
                                end;
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                    end;
                }
                field(IsCalculated; IsCalculated)
                {
                    ApplicationArea = Planning;
                    Caption = 'Calculated';
                    Editable = false;
                    ToolTip = 'Specifies whether the demand overview has been calculated. The check box is selected after you choose the Calculate button.';
                }
            }
            repeater(Control1)
            {
                IndentationColumn = TypeIndent;
                IndentationControls = Type;
                ShowAsTree = true;
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    HideValue = ItemNoHideValue;
                    Style = Strong;
                    StyleExpr = ItemNoEmphasize;
                    ToolTip = 'Specifies the identifier number for the item.';
                }
                field("Matches Criteria"; Rec."Matches Criteria")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies whether the line in the Demand Overview window is related to the lines where the demand overview was calculated.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = TypeEmphasize;
                    ToolTip = 'Specifies the type of availability being calculated.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    Style = Unfavorable;
                    StyleExpr = DateEmphasize;
                    ToolTip = 'Specifies the date of the availability calculation.';
                }
                field(SourceTypeText; SourceTypeText)
                {
                    ApplicationArea = Planning;
                    CaptionClass = FieldCaption("Source Type");
                    Editable = false;
                    HideValue = SourceTypeHideValue;
                }
                field("Source Order Status"; Rec."Source Order Status")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    HideValue = SourceOrderStatusHideValue;
                    ToolTip = 'Specifies the order status of the item for which availability is being calculated.';
                    Visible = false;
                }
                field("Source ID"; Rec."Source ID")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the identifier code of the source.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies the description of the item for which availability is being calculated.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the location code of the item for which availability is being calculated.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field(QuantityText; QuantityText)
                {
                    ApplicationArea = Planning;
                    CaptionClass = FieldCaption(Quantity);
                    Caption = 'Quantity';
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item are demanded.';
                }
                field(ReservedQuantityText; ReservedQuantityText)
                {
                    ApplicationArea = Reservation;
                    CaptionClass = FieldCaption("Reserved Quantity");
                    Caption = 'Reserved Quantity';
                    Editable = false;
                    ToolTip = 'Specifies how many units of the demanded item are reserved.';
                }
                field("Running Total"; Rec."Running Total")
                {
                    ApplicationArea = Planning;
                    CaptionClass = FieldCaption("Running Total");
                    Editable = false;
                    HideValue = RunningTotalHideValue;
                    Style = Strong;
                    StyleExpr = RunningTotalEmphasize;
                    ToolTip = 'Specifies the total count of items from inventory, supply, and demand.';
                }
                field("Inventory Running Total"; Rec."Inventory Running Total")
                {
                    ApplicationArea = Planning;
                    CaptionClass = FieldCaption("Inventory Running Total");
                    Editable = false;
                    HideValue = InventoryRunningTotalHideValue;
                    Style = Strong;
                    StyleExpr = InventoryRunningTotalEmphasize;
                    ToolTip = 'Specifies the count of items in inventory.';
                    Visible = false;
                }
                field("Supply Running Total"; Rec."Supply Running Total")
                {
                    ApplicationArea = Planning;
                    CaptionClass = FieldCaption("Supply Running Total");
                    Editable = false;
                    HideValue = SupplyRunningTotalHideValue;
                    Style = Strong;
                    StyleExpr = SupplyRunningTotalEmphasize;
                    ToolTip = 'Specifies the count of items in supply.';
                    Visible = false;
                }
                field("Demand Running Total"; Rec."Demand Running Total")
                {
                    ApplicationArea = Planning;
                    CaptionClass = FieldCaption("Demand Running Total");
                    Editable = false;
                    HideValue = DemandRunningTotalHideValue;
                    Style = Strong;
                    StyleExpr = DemandRunningTotalEmphasize;
                    ToolTip = 'Specifies the count of items in demand.';
                    Visible = false;
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies the item number or a filter on the item numbers that you want to trace.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                        ItemList: Page "Item List";
                    begin
                        Item.SetRange(Type, Item.Type::Inventory);
                        ItemList.SetTableView(Item);
                        ItemList.LookupMode := true;
                        if ItemList.RunModal() = ACTION::LookupOK then begin
                            ItemList.GetRecord(Item);
                            Text := Item."No.";
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies the location you want to show item availability for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Location: Record Location;
                        LocationList: Page "Location List";
                    begin
                        LocationList.SetTableView(Location);
                        LocationList.LookupMode := true;
                        if LocationList.RunModal() = ACTION::LookupOK then begin
                            LocationList.GetRecord(Location);
                            Text := Location.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                    end;
                }
                field(VariantFilter; VariantFilter)
                {
                    ApplicationArea = Service, Planning;
                    Caption = 'Variant Filter';
                    ToolTip = 'Specifies the variant code or a filter on the variant code that you want to trace.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemVariant: Record "Item Variant";
                        ItemVariants: Page "Item Variants";
                    begin
                        ItemVariant.SetFilter("Item No.", ItemFilter);
                        ItemVariants.SetTableView(ItemVariant);
                        ItemVariants.LookupMode := true;
                        if ItemVariants.RunModal() = ACTION::LookupOK then begin
                            ItemVariants.GetRecord(ItemVariant);
                            Text := ItemVariant.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        IsCalculated := false;
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Calculate)
            {
                ApplicationArea = Planning;
                Caption = 'Calculate';
                Image = Calculate;
                ToolTip = 'Update the window with any demand. ';

                trigger OnAction()
                begin
                    CalculationOfDemand := true;
                    InitTempTable();
                    IsCalculated := true;
                    SetRange("Matches Criteria");
                    if MatchCriteria then
                        SetRange("Matches Criteria", true);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Calculate_Promoted; Calculate)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TypeIndent := 0;
        ItemNoHideValue := Type <> Type::Item;
        if Type = Type::Item then
            ItemNoEmphasize := "Matches Criteria";

        TypeEmphasize := "Matches Criteria" and (Type in [Type::Item, Type::"As of Date"]);
        TypeIndent := Level;

        SourceTypeText := Format("Source Type");
        SourceTypeTextOnFormat(SourceTypeText);

        if Type in [Type::Item, Type::"As of Date"] then begin
            QuantityText := '';
            ReservedQuantityText := '';
        end else begin
            QuantityText := Format(Quantity);
            ReservedQuantityText := Format("Reserved Quantity");
        end;

        SupplyRunningTotalHideValue := Type = Type::Item;
        SourceOrderStatusHideValue := Type = Type::Item;
        RunningTotalHideValue := Type = Type::Item;
        InventoryRunningTotalHideValue := Type = Type::Item;
        DemandRunningTotalHideValue := Type = Type::Item;

        DateEmphasize := "Running Total" < 0;
        DescriptionEmphasize := Type = Type::Item;
        SupplyRunningTotalEmphasize := Type = Type::"As of Date";
        DemandRunningTotalEmphasize := Type = Type::"As of Date";
        RunningTotalEmphasize := Type = Type::"As of Date";
        InventoryRunningTotalEmphasize := Type = Type::"As of Date";
    end;

    trigger OnInit()
    begin
        DemandNoCtrlEnable := true;
        MatchCriteria := true;
    end;

    trigger OnOpenPage()
    begin
        InitTempTable();

        SetRange("Matches Criteria");
        if MatchCriteria then
            SetRange("Matches Criteria", true);
        DemandNoCtrlEnable := DemandType <> DemandType::" ";
        CurrPage.Update(false);
    end;

    var
        TempAvailCalcOverview: Record "Availability Calc. Overview" temporary;
        CalcAvailOverview: Codeunit "Calc. Availability Overview";
        ItemFilter: Code[250];
        LocationFilter: Code[250];
        VariantFilter: Code[250];
        StartDate: Date;
        EndDate: Date;
        DemandType: Option " ",Sales,Production,Jobs,Services,Assembly;
        DemandNo: Code[20];
        IsCalculated: Boolean;
        MatchCriteria: Boolean;
        Text001: Label 'Sales';
        Text002: Label 'Production';
        Text003: Label 'Purchase';
        Text004: Label 'Inventory';
        Text005: Label 'Service';
        Text006: Label 'Job';
        Text007: Label 'Prod. Comp.';
        Text008: Label 'Transfer';
        Text009: Label 'Assembly';
        Text020: Label 'Expanding...\';
        Text021: Label 'Status    #1###################\';
        Text022: Label 'Setting Filters';
        Text023: Label 'Fetching Items';
        Text025: Label 'Fetching Specific Entries in Dates';
        Text026: Label 'Displaying results';

    protected var
        [InDataSet]
        DemandNoCtrlEnable: Boolean;
        [InDataSet]
        ItemNoHideValue: Boolean;
        [InDataSet]
        ItemNoEmphasize: Boolean;
        [InDataSet]
        TypeEmphasize: Boolean;
        [InDataSet]
        TypeIndent: Integer;
        [InDataSet]
        SourceTypeHideValue: Boolean;
        [InDataSet]
        SourceTypeText: Text[1024];
        [InDataSet]
        SourceOrderStatusHideValue: Boolean;
        [InDataSet]
        DescriptionEmphasize: Boolean;
        [InDataSet]
        QuantityText: Text[1024];
        [InDataSet]
        DateEmphasize: Boolean;
        [InDataSet]
        ReservedQuantityText: Text[1024];
        [InDataSet]
        RunningTotalHideValue: Boolean;
        [InDataSet]
        RunningTotalEmphasize: Boolean;
        [InDataSet]
        InventoryRunningTotalHideValue: Boolean;
        [InDataSet]
        InventoryRunningTotalEmphasize: Boolean;
        [InDataSet]
        SupplyRunningTotalHideValue: Boolean;
        [InDataSet]
        SupplyRunningTotalEmphasize: Boolean;
        [InDataSet]
        DemandRunningTotalHideValue: Boolean;
        [InDataSet]
        DemandRunningTotalEmphasize: Boolean;
        CalculationOfDemand: Boolean;

    local procedure ApplyUserFilters(var AvailCalcOverview: Record "Availability Calc. Overview")
    begin
        AvailCalcOverview.Reset();
        AvailCalcOverview.SetFilter("Item No.", ItemFilter);
        if (StartDate <> 0D) or (EndDate <> 0D) then begin
            if EndDate <> 0D then
                AvailCalcOverview.SetRange(Date, StartDate, EndDate)
            else
                AvailCalcOverview.SetRange(Date, StartDate, DMY2Date(31, 12, 9999));
        end;
        if LocationFilter <> '' then
            AvailCalcOverview.SetFilter("Location Code", LocationFilter);
        if VariantFilter <> '' then
            AvailCalcOverview.SetFilter("Variant Code", VariantFilter);
    end;

    procedure InitTempTable()
    var
        AvailCalcOverviewFilters: Record "Availability Calc. Overview";
    begin
        if not CalculationOfDemand then
            exit;
        AvailCalcOverviewFilters.Copy(Rec);
        ApplyUserFilters(TempAvailCalcOverview);
        CalcAvailOverview.SetParam(DemandType, DemandNo);
        CalcAvailOverview.Run(TempAvailCalcOverview);
        TempAvailCalcOverview.Reset();
        Reset();
        DeleteAll();
        if TempAvailCalcOverview.Find('-') then
            repeat
                if TempAvailCalcOverview.Level = 0 then begin
                    Rec := TempAvailCalcOverview;
                    Insert();
                end;
            until TempAvailCalcOverview.Next() = 0;
        CopyFilters(AvailCalcOverviewFilters);
        ExpandAll(TempAvailCalcOverview);
        Copy(AvailCalcOverviewFilters);
        if Find('-') then;
        IsCalculated := true;
    end;

    local procedure ExpandAll(var AvailCalcOverview: Record "Availability Calc. Overview")
    var
        AvailCalcOverviewFilters: Record "Availability Calc. Overview";
        Window: Dialog;
    begin
        Window.Open(Text020 + Text021);
        AvailCalcOverviewFilters.Copy(Rec);

        // Set Filters
        Window.Update(1, Text022);
        AvailCalcOverview.Reset();
        AvailCalcOverview.DeleteAll();
        ApplyUserFilters(AvailCalcOverview);
        CalcAvailOverview.SetParam(DemandType, DemandNo);

        // Fetching Items
        Window.Update(1, Text023);
        Reset();
        if Find('+') then
            repeat
                if Type = Type::Item then begin
                    AvailCalcOverview := Rec;
                    if CalcAvailOverview.EntriesExist(AvailCalcOverview) then begin
                        AvailCalcOverview.Insert();
                        CalcAvailOverview.CalculateItem(AvailCalcOverview);
                    end;
                end;
            until Next(-1) = 0;

        // Fetch Entries in Dates
        Window.Update(1, Text025);
        if AvailCalcOverview.Find('+') then
            repeat
                Rec := AvailCalcOverview;
                if AvailCalcOverview.Type = Type::"As of Date" then
                    CalcAvailOverview.CalculateDate(AvailCalcOverview);
                AvailCalcOverview := Rec;
            until AvailCalcOverview.Next(-1) = 0;

        // Copy to View Table
        Window.Update(1, Text026);
        DeleteAll();
        if AvailCalcOverview.Find('-') then
            repeat
                Rec := AvailCalcOverview;
                Insert();
            until AvailCalcOverview.Next() = 0;

        Window.Close();
        Copy(AvailCalcOverviewFilters);
        if Find('-') then;
    end;

    procedure SetRecFilters()
    begin
        Reset();
        SetCurrentKey("Item No.", Date, "Attached to Entry No.", Type);
        CurrPage.Update(false);
    end;

    procedure Initialize(NewStartDate: Date; NewDemandType: Integer; NewDemandNo: Code[20]; NewItemNo: Code[20]; NewLocationFilter: Code[250])
    begin
        StartDate := NewStartDate;
        DemandType := NewDemandType;
        DemandNo := NewDemandNo;
        ItemFilter := NewItemNo;
        LocationFilter := NewLocationFilter;
        MatchCriteria := true;
    end;

    local procedure SourceTypeTextOnFormat(var Text: Text[1024])
    begin
        SourceTypeHideValue := false;
        case "Source Type" of
            DATABASE::"Sales Line":
                Text := Text001;
            DATABASE::"Service Line":
                Text := Text005;
            DATABASE::"Job Planning Line":
                Text := Text006;
            DATABASE::"Prod. Order Line":
                Text := Text002;
            DATABASE::"Prod. Order Component":
                Text := Text007;
            DATABASE::"Purchase Line":
                Text := Text003;
            DATABASE::"Item Ledger Entry":
                Text := Text004;
            DATABASE::"Transfer Line":
                Text := Text008;
            DATABASE::"Assembly Header",
          DATABASE::"Assembly Line":
                Text := Text009;
            else
                SourceTypeHideValue := true;
        end
    end;

    procedure SetCalculationParameter(CalculateDemandParam: Boolean)
    begin
        CalculationOfDemand := CalculateDemandParam;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDemandNo(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; DemandType: Option; var Result: Boolean; var IsHandled: Boolean; var Text: Text)
    begin
    end;
}

