page 5540 "Item Availability by Timeline"
{
    Caption = 'Item Availability by Timeline';
    DataCaptionExpression = PageCaption;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    SourceTable = "Timeline Event Change";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Due Date")
                      ORDER(Ascending);

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field("<ItemNo>"; ItemNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item No.';
                    Importance = Promoted;
                    TableRelation = Item;
                    ToolTip = 'Specifies the number of the item you want to view item availability for.';

                    trigger OnValidate()
                    var
                        ItemNo2: Code[20];
                    begin
                        if ItemNo <> Item."No." then begin
                            ItemNo2 := ItemNo;
                            Item.Reset();
                            Item.Get(ItemNo);
                            if LocationFilter <> '' then
                                Item.SetFilter("Location Filter", LocationFilter);
                            ItemSelected := true;
                            InitAndCreateTimelineEvents;
                            VariantFilter := Item."Variant Filter";
                            ItemNo := ItemNo2;
                        end;
                    end;
                }
                field("<VariantFilter>"; VariantFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Filter';
                    Importance = Promoted;
                    ToolTip = 'Specifies a variant code to view only the projected available balance for that variant of the item.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemVariant: Record "Item Variant";
                        ItemVariants: Page "Item Variants";
                    begin
                        ItemVariant.SetRange("Item No.", ItemNo);
                        ItemVariants.SetTableView(ItemVariant);
                        ItemVariants.LookupMode := true;
                        if ItemVariants.RunModal = ACTION::LookupOK then begin
                            ItemVariants.GetRecord(ItemVariant);
                            Text := ItemVariant.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    var
                        VariantFilter2: Text;
                    begin
                        if VariantFilter <> Item.GetFilter("Variant Filter") then begin
                            CalcItemAvailTimeline.FindVariantWithinFilter(ItemNo, VariantFilter);

                            VariantFilter2 := VariantFilter;
                            Item.SetRange("Variant Filter");
                            if VariantFilter <> '' then
                                Item.SetFilter("Variant Filter", VariantFilter);
                            InitAndCreateTimelineEvents;
                            VariantFilter := VariantFilter2;
                        end;
                    end;
                }
                field("<LocationFilter>"; LocationFilter)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Filter';
                    Importance = Promoted;
                    ToolTip = 'Specifies a location code to view only the projected available balance for the item at that location.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Location: Record Location;
                        LocationList: Page "Location List";
                    begin
                        LocationList.SetTableView(Location);
                        LocationList.LookupMode := true;
                        if LocationList.RunModal = ACTION::LookupOK then begin
                            LocationList.GetRecord(Location);
                            Text := Location.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    var
                        LocationFilter2: Text;
                    begin
                        if LocationFilter <> Item.GetFilter("Location Filter") then begin
                            CalcItemAvailTimeline.FindLocationWithinFilter(LocationFilter);

                            LocationFilter2 := LocationFilter;
                            Item.SetRange("Location Filter");
                            if LocationFilter <> '' then
                                Item.SetFilter("Location Filter", LocationFilter);
                            InitAndCreateTimelineEvents;
                            LocationFilter := LocationFilter2;
                        end;
                    end;
                }
                field("<LastUpdateTime>"; LastUpdateTime)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Updated';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies when the availability figures in the Item Availability by Timeline window were last updated.';
                }
                field("<ForecastName>"; ForecastName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Forecast Name';
                    Importance = Promoted;
                    TableRelation = "Production Forecast Name";
                    ToolTip = 'Specifies a demand forecast you want to include as anticipated demand in the graphical view of projected available balance.';

                    trigger OnValidate()
                    var
                        ForecastName2: Code[10];
                    begin
                        ForecastName2 := ForecastName;
                        InitAndCreateTimelineEvents;
                        ForecastName := ForecastName2;
                    end;
                }
                field("<IncludeBlanketOrders>"; IncludeBlanketOrders)
                {
                    ApplicationArea = Suite;
                    Caption = 'Include Blanket Sales Orders';
                    Importance = Promoted;
                    ToolTip = 'Specifies if you want to include anticipated demand from blanket sales orders in the graphical view of projected available balance.';

                    trigger OnValidate()
                    var
                        IncludeBlanketOrders2: Boolean;
                    begin
                        IncludeBlanketOrders2 := IncludeBlanketOrders;
                        InitAndCreateTimelineEvents;
                        IncludeBlanketOrders := IncludeBlanketOrders2;
                    end;
                }
            }
            group(Timeline)
            {
                Caption = 'Timeline';
                usercontrol(Visualization; "Microsoft.Dynamics.Nav.Client.TimelineVisualization")
                {
                    ApplicationArea = Basic, Suite;

                    trigger TransactionActivated(refNo: Text)
                    begin
                        ShowDocument(refNo);
                    end;

                    trigger SelectedTransactionChanged(refNo: Text)
                    begin
                        SetCurrentChangeRec(refNo);
                    end;

                    trigger TransactionValueChanged(refNo: Text)
                    begin
                        if IgnoreChanges then
                            exit;

                        if refNo <> '' then begin // Specific Transaction Value Changed
                            State := State::"Unsaved Changes";
                            if NewSupply then
                                CurrReferenceNo := CopyStr(refNo, 1, MaxStrLen("Reference No."));
                        end;

                        ImportChangesFromTimeline;
                    end;

                    trigger AddInReady()
                    begin
                        if ItemSelected then
                            InitAndCreateTimelineEvents;
                    end;
                }
            }
            grid(changeListGroup)
            {
                Caption = 'Event Changes';
                repeater(changeList)
                {
                    Caption = 'Change List';
                    field(ActionMessage; ActionMsg)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Action Message';
                        Editable = false;
                        ToolTip = 'Specifies the action to take to rebalance the demand-supply situation shown in the graph on the Timeline FastTab.';
                    }
                    field(Description; Description)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        Editable = false;
                        ToolTip = 'Specifies the description of the planning worksheet lines that are represented on the Timeline FastTab.';

                        trigger OnDrillDown()
                        begin
                            ShowDocument("Reference No.");
                        end;
                    }
                    field("Original Due Date"; "Original Due Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the due date that is stated on the existing supply order, when an action message proposes to reschedule the order.';
                    }
                    field("Due Date"; "Due Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the due date of the suggested supply order that the line on the Event Changes FastTab represents.';

                        trigger OnValidate()
                        begin
                            if "Due Date" <> xRec."Due Date" then begin
                                TestField("Due Date");
                                CurrPage.Visualization.RescheduleTransaction("Reference No.", CreateDateTime("Due Date", TempTimelineEvent.DefaultTime));
                                State := State::"Unsaved Changes";
                            end;
                        end;
                    }
                    field("Original Quantity"; "Original Quantity")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the quantity on the supply order, when an action message suggests a change to the quantity on the order.';
                    }
                    field(Quantity; Quantity)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the quantity of the suggested supply order that the line on the Event Changes FastTab represents.';

                        trigger OnValidate()
                        begin
                            if Quantity <> xRec.Quantity then begin
                                CurrPage.Visualization.ChangeTransactionQuantity("Reference No.", Quantity);
                                State := State::"Unsaved Changes";
                            end;
                        end;
                    }
                    field("Reference No."; "Reference No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the reference number for the item in the timeline event change table.';
                        Visible = false;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Delete)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Ctrl+Delete';
                ToolTip = 'Delete the record.';

                trigger OnAction()
                begin
                    if not Confirm(Text009, true) then
                        exit;

                    DeleteSelectedRecords;
                end;
            }
            action("<Reload>")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reload';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Update the window with values created by other users since you opened the window.';

                trigger OnAction()
                begin
                    InitAndCreateTimelineEvents;
                end;
            }
            action("<TransferChanges>")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Save Changes';
                Image = SuggestLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Transfer the changes to the planning worksheet lines.';

                trigger OnAction()
                begin
                    TransferChangesToPlanningWksh;
                    InitAndCreateTimelineEvents;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if (not BlockCurrRecNotifications) and (CurrReferenceNo <> "Reference No.") then begin
            CurrReferenceNo := "Reference No.";
            CurrPage.Visualization.SelectTransaction("Reference No.");
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        Description := TimelineEventDescription;
        ActionMsg := ActionMessage;
    end;

    trigger OnInit()
    begin
        BlockCurrRecNotifications := false;
        IgnoreChanges := false;
        TemplateNameNewSupply := '';
        WorksheetNameNewSupply := '';
        State := State::" ";
    end;

    trigger OnOpenPage()
    begin
        ItemSelected := Item."No." <> '';
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not (State = State::"Unsaved Changes") then
            exit(true);

        exit(Confirm(Text003));
    end;

    var
        Item: Record Item;
        TempTimelineEvent: Record "Timeline Event" temporary;
        CalcItemAvailTimeline: Codeunit "Calc. Item Avail. Timeline";
        ItemNo: Code[20];
        LocationFilter: Text;
        VariantFilter: Text;
        [InDataSet]
        ForecastName: Code[10];
        TemplateNameNewSupply: Code[10];
        WorksheetNameNewSupply: Code[10];
        Description: Text[250];
        ActionMsg: Enum "Action Message Type";
        State: Option " ",Initialized,"Unsaved Changes";
        LastUpdateTime: DateTime;
        [InDataSet]
        IncludeBlanketOrders: Boolean;
        Text001: Label 'The changes have been saved to the planning or requisition worksheet.';
        CurrReferenceNo: Text[200];
        BlockCurrRecNotifications: Boolean;
        Text002: Label 'The changes have been saved to the planning or requisition worksheet.\\New supply is saved to worksheet Template Name %1, Batch Name %2, Location Code %3, and Variant Code %4.';
        Text003: Label 'All unsaved changes will not be saved. Are you sure that you want to close the window?';
        Text004: Label 'Show Projected Available Balance';
        Text005: Label 'Include Planning Suggestions';
        Text006: Label 'Workdate';
        Text007: Label 'Today';
        IgnoreChanges: Boolean;
        [InDataSet]
        ItemSelected: Boolean;
        Text008: Label 'New Supply %1';
        Text009: Label 'Do you want to delete?';

    [Scope('OnPrem')]
    procedure InitAndCreateTimelineEvents()
    begin
        InitTimeline;
        CreateTimelineEvents;
        SetScenarioTitles;
        State := State::Initialized;
    end;

    local procedure InitTimeline()
    var
        timeSpan: DotNet TimeSpan;
    begin
        CurrPage.Visualization.RemoveSpecialDates;
        CurrPage.Visualization.AddSpecialDate(CreateDateTime(WorkDate, TempTimelineEvent.DefaultTime), Text006);
        CurrPage.Visualization.AddSpecialDate(CreateDateTime(Today, TempTimelineEvent.DefaultTime), Text007);
        CurrPage.Visualization.TransactionPrecision := Decimals(Item."Rounding Precision");
        CurrPage.Visualization.TransactionUnitOfMeasure := Item."Base Unit of Measure";
        CurrPage.Visualization.InitialLevelDateMargin := timeSpan.FromDays(CalcItemAvailTimeline.InitialTimespanDays);
        CurrPage.Visualization.FinalLevelDateMargin := timeSpan.FromDays(CalcItemAvailTimeline.FinalTimespanDays);
    end;

    local procedure UpdateItemRequestFields(var Item: Record Item)
    begin
        ItemNo := Item."No.";
        LocationFilter := '';
        if Item.GetFilter("Location Filter") <> '' then
            LocationFilter := Item.GetFilter("Location Filter");
        VariantFilter := '';
        if Item.GetFilter("Variant Filter") <> '' then
            VariantFilter := Item.GetFilter("Variant Filter");
    end;

    local procedure PageCaption(): Text[250]
    begin
        exit(StrSubstNo('%1 %2', Item."No.", Item.Description));
    end;

    procedure SetItem(var NewItem: Record Item)
    begin
        Item.Copy(NewItem);
        UpdateItemRequestFields(Item);
    end;

    procedure SetForecastName(NewForcastName: Code[10])
    begin
        ForecastName := NewForcastName;
    end;

    procedure SetWorksheet(NewTemplateName: Code[10]; NewWorksheetName: Code[10])
    begin
        TemplateNameNewSupply := NewTemplateName;
        WorksheetNameNewSupply := NewWorksheetName;
    end;

    local procedure ExportDataToTimeline(var TimelineEvent: Record "Timeline Event")
    var
        transactionTable: DotNet DataModel_TransactionDataTable;
        visualizationScenarios: DotNet VisualizationScenarios;
        WithForecast: Integer;
        WithForecastAndAdjustments: Integer;
    begin
        TimelineEvent.TransferToTransactionTable(TimelineEvent, transactionTable);

        WithForecast := 2; // Enum value for CoreTransactionsWithForecast check box
        WithForecastAndAdjustments := 4; // Enum value for CoreTransactionsWithForecastAndAdjustments check box
        visualizationScenarios := WithForecast + WithForecastAndAdjustments; // Show the specified check boxes
        CurrPage.Visualization.SetTransactions(transactionTable, visualizationScenarios);
    end;

    local procedure ImportChangesFromTimeline()
    var
        changeTable: DotNet DataModel_TransactionChangesDataTable;
    begin
        BlockCurrRecNotifications := true;

        changeTable := CurrPage.Visualization.GetTransactionChanges;
        TransferFromTransactionChangeTable(Rec, changeTable);
        SetCurrentChangeRec(CurrReferenceNo);

        BlockCurrRecNotifications := false;
    end;

    local procedure CreateTimelineEvents()
    begin
        Reset;
        DeleteAll();
        TempTimelineEvent.DeleteAll();
        Item.SetRange("Drop Shipment Filter", false);
        CalcItemAvailTimeline.Initialize(Item, ForecastName, IncludeBlanketOrders, 0D, true);
        CalcItemAvailTimeline.CreateTimelineEvents(TempTimelineEvent);
        ExportDataToTimeline(TempTimelineEvent);
        LastUpdateTime := CurrentDateTime;
    end;

    local procedure DeleteSelectedRecords()
    var
        TempTimelineEventChange: Record "Timeline Event Change" temporary;
    begin
        TempTimelineEventChange.Copy(Rec, true);
        CurrPage.SetSelectionFilter(TempTimelineEventChange);
        if TempTimelineEventChange.FindSet then begin
            IgnoreChanges := true;
            repeat
                CurrPage.Visualization.DeleteTransaction(TempTimelineEventChange."Reference No.");
            until TempTimelineEventChange.Next = 0;
            ImportChangesFromTimeline;
            IgnoreChanges := false;
            if (State = State::"Unsaved Changes") and (Count = 0) then
                State := State::Initialized;
        end;
    end;

    local procedure ShowDocument(RefNo: Text[255])
    var
        ReferenceNo: Integer;
    begin
        if Evaluate(ReferenceNo, RefNo) then begin
            TempTimelineEvent.Get(ReferenceNo);
            CalcItemAvailTimeline.ShowDocument(TempTimelineEvent."Source Document ID");
        end;
    end;

    local procedure SetCurrentChangeRec(RefNo: Text[255])
    begin
        if IsEmpty or (RefNo = '') then
            exit;

        SetRange("Reference No.", RefNo);
        if FindFirst then begin
            CurrPage.SetRecord(Rec);
            CurrPage.Update(false);
        end;
        SetRange("Reference No.");
    end;

    local procedure TimelineEventDescription(): Text[250]
    var
        ReferenceNo: Integer;
    begin
        if NewSupply then
            exit(StrSubstNo(Text008, Format("Due Date")));

        if Evaluate(ReferenceNo, "Reference No.") then
            if TempTimelineEvent.Get(ReferenceNo) then
                exit(TempTimelineEvent.Description);

        exit("Reference No.");
    end;

    local procedure SetScenarioTitles()
    var
        visualizationScenarios: DotNet VisualizationScenarios;
    begin
        CurrPage.Visualization.SetScenarioTitle(visualizationScenarios.CoreTransactionsWithForecast, Text004);
        CurrPage.Visualization.SetScenarioTitle(visualizationScenarios.CoreTransactionsWithForecastAndAdjustments, Text005);
    end;

    local procedure TransferChangesToPlanningWksh()
    var
        LocationCodeNewSupply: Code[10];
        VariantCodeNewSupply: Code[10];
        NewSupplyTransfer: Boolean;
    begin
        NewSupplyTransfer :=
          CalcItemAvailTimeline.TransferChangesToPlanningWksh(
            Rec, ItemNo, LocationFilter, VariantFilter, TemplateNameNewSupply, WorksheetNameNewSupply);

        if not NewSupplyTransfer then
            Message(Text001)
        else begin
            if LocationCodeNewSupply = '' then
                LocationCodeNewSupply := CalcItemAvailTimeline.BlankValue;
            if VariantCodeNewSupply = '' then
                VariantCodeNewSupply := CalcItemAvailTimeline.BlankValue;
            Message(Text002, TemplateNameNewSupply, WorksheetNameNewSupply, LocationCodeNewSupply, VariantCodeNewSupply)
        end;
    end;

    local procedure Decimals(Precision: Decimal) Decimals: Integer
    begin
        if (Precision <= 0) or (Precision > 1) then
            exit(DefaultPrecision);

        Decimals := 0;

        while (Decimals <= MaxPrecision) and (Round(Precision, 1, '>') > Precision) do begin
            Decimals += 1;
            Precision *= 10;
        end;

        exit(Decimals);
    end;

    local procedure DefaultPrecision(): Integer
    begin
        exit(5);
    end;

    local procedure MaxPrecision(): Integer
    begin
        exit(5);
    end;
}

