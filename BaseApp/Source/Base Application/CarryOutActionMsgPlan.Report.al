report 99001020 "Carry Out Action Msg. - Plan."
{
    Caption = 'Carry Out Action Msg. - Plan.';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Requisition Line"; "Requisition Line")
        {
            DataItemTableView = SORTING("Worksheet Template Name", "Journal Batch Name", "Vendor No.", "Sell-to Customer No.", "Ship-to Code", "Order Address Code", "Currency Code", "Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Location Code", "Transfer-from Code");
            RequestFilterHeading = 'Planning Line';

            trigger OnAfterGetRecord()
            begin
                WindowUpdate;

                if not "Accept Action Message" then
                    CurrReport.Skip();
                LockTable();

                Commit();
                case "Ref. Order Type" of
                    "Ref. Order Type"::"Prod. Order":
                        if ProdOrderChoice <> ProdOrderChoice::" " then
                            CarryOutActions(2, ProdOrderChoice, ProdWkshTempl, ProdWkshName);
                    "Ref. Order Type"::Purchase:
                        if PurchOrderChoice = PurchOrderChoice::"Copy to Req. Wksh" then
                            CarryOutActions(0, PurchOrderChoice, ReqWkshTemp, ReqWksh);
                    "Ref. Order Type"::Transfer:
                        if TransOrderChoice <> TransOrderChoice::" " then begin
                            CarryOutAction.SetSplitTransferOrders(not CombineTransferOrders);
                            CarryOutActions(1, TransOrderChoice, TransWkshTemp, TransWkshName);
                        end;
                    "Ref. Order Type"::Assembly:
                        if AsmOrderChoice <> AsmOrderChoice::" " then
                            CarryOutActions(3, AsmOrderChoice, '', '');
                    else
                        CurrReport.Skip();
                end;
                Commit();
            end;

            trigger OnPostDataItem()
            begin
                Window.Close;

                CarryOutAction.PrintTransferOrders;

                if PurchOrderChoice in [PurchOrderChoice::"Make Purch. Orders",
                                        PurchOrderChoice::"Make Purch. Orders & Print"]
                then begin
                    SetRange("Accept Action Message", true);

                    if PurchaseSuggestionExists("Requisition Line") then begin
                        PurchOrderHeader."Order Date" := WorkDate;
                        PurchOrderHeader."Posting Date" := WorkDate;
                        PurchOrderHeader."Expected Receipt Date" := WorkDate;

                        EndOrderDate := WorkDate;

                        PrintOrders := (PurchOrderChoice = PurchOrderChoice::"Make Purch. Orders & Print");

                        Clear(ReqWkshMakeOrders);
                        ReqWkshMakeOrders.SetCreatedDocumentBuffer(TempDocumentEntry);
                        ReqWkshMakeOrders.Set(PurchOrderHeader, EndOrderDate, PrintOrders);
                        if not NoPlanningResiliency then
                            ReqWkshMakeOrders.SetPlanningResiliency;
                        ReqWkshMakeOrders.CarryOutBatchAction("Requisition Line");
                        CounterFailed := CounterFailed + ReqWkshMakeOrders.GetFailedCounter;
                    end;
                end;

                if ReserveforPlannedProd then
                    Message(Text010);

                if CounterFailed > 0 then
                    if GetLastErrorText = '' then
                        Message(Text013, CounterFailed)
                    else
                        Message(GetLastErrorText);
            end;

            trigger OnPreDataItem()
            begin
                LockTable();

                SetReqLineFilters;
                if not Find('-') then
                    Error(Text000);

                if PurchOrderChoice = PurchOrderChoice::"Copy to Req. Wksh" then
                    CheckCopyToWksh(ReqWkshTemp, ReqWksh);
                if TransOrderChoice = TransOrderChoice::"Copy to Req. Wksh" then
                    CheckCopyToWksh(TransWkshTemp, TransWkshName);
                if ProdOrderChoice = ProdOrderChoice::"Copy to Req. Wksh" then
                    CheckCopyToWksh(ProdWkshTempl, ProdWkshName);

                Window.Open(Text012);
                CheckPreconditions;
                CounterTotal := Count;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Production Order")
                    {
                        Caption = 'Production Order';
                        field(ProductionOrder; ProdOrderChoice)
                        {
                            ApplicationArea = Planning;
                            Caption = 'Production Order';
                            OptionCaption = ' ,Planned,Firm Planned,Firm Planned & Print';
                            ToolTip = 'Specifies that you want to create production orders for item with the Prod. Order replenishment system. You can select to create either planned or firm planned production order, and you can have the new order documents printed.';
                        }
                    }
                    group("Assembly Order")
                    {
                        Caption = 'Assembly Order';
                        field(AsmOrderChoice; AsmOrderChoice)
                        {
                            ApplicationArea = Assembly;
                            Caption = 'Assembly Order';
                            OptionCaption = ' ,Make Assembly Orders,Make Assembly Orders & Print';
                            ToolTip = 'Specifies the assembly orders that are created for items with the Assembly replenishment method.';
                        }
                    }
                    group("Purchase Order")
                    {
                        Caption = 'Purchase Order';
                        field(PurchaseOrder; PurchOrderChoice)
                        {
                            ApplicationArea = Planning;
                            Caption = 'Purchase Order';
                            OptionCaption = ' ,Make Purch. Orders,Make Purch. Orders & Print,Copy to Req. Wksh';
                            ToolTip = 'Specifies that you want to create purchase orders for items with the Purchase replenishment method. You can have the new order documents printed.';

                            trigger OnValidate()
                            begin
                                PurchOrderCopyToReqWksh := PurchOrderChoice = PurchOrderChoice::"Copy to Req. Wksh";
                            end;
                        }
                        group(Control10)
                        {
                            ShowCaption = false;
                            Visible = PurchOrderCopyToReqWksh;
                            field(ReqTemp; ReqWkshTemp)
                            {
                                ApplicationArea = Planning;
                                Caption = 'Req. Wksh. Template';
                                Enabled = true;
                                TableRelation = "Req. Wksh. Template";
                                ToolTip = 'Specifies that you want to copy the planning line proposals for transfer orders to this requisition worksheet template.';

                                trigger OnLookup(var Text: Text): Boolean
                                begin
                                    if PAGE.RunModal(PAGE::"Req. Worksheet Templates", ReqWkshTmpl) = ACTION::LookupOK then begin
                                        Text := ReqWkshTmpl.Name;
                                        exit(true);
                                    end;
                                    exit(false);
                                end;

                                trigger OnValidate()
                                begin
                                    ReqWksh := '';
                                end;
                            }
                            field(ReqName; ReqWksh)
                            {
                                ApplicationArea = Planning;
                                Caption = 'Req. Wksh. Name';
                                Enabled = true;
                                TableRelation = "Requisition Wksh. Name".Name;
                                ToolTip = 'Specifies that you want to copy the planning line proposals for transfer orders to this requisition worksheet name.';

                                trigger OnLookup(var Text: Text): Boolean
                                begin
                                    ReqWkshName.SetFilter("Worksheet Template Name", ReqWkshTemp);
                                    if PAGE.RunModal(PAGE::"Req. Wksh. Names", ReqWkshName) = ACTION::LookupOK then begin
                                        Text := ReqWkshName.Name;
                                        exit(true);
                                    end;
                                    exit(false);
                                end;
                            }
                        }
                    }
                    group("Transfer Order")
                    {
                        Caption = 'Transfer Order';
                        field(TransOrderChoice; TransOrderChoice)
                        {
                            ApplicationArea = Location;
                            Caption = 'Transfer Order';
                            OptionCaption = ' ,Make Trans. Orders,Make Trans. Orders & Print,Copy to Req. Wksh';
                            ToolTip = 'Specifies that you want to create transfer orders for items with the Transfer replenishment method in the SKU card. You can have the new order documents printed.';

                            trigger OnValidate()
                            begin
                                TransOrderCopyToReqWksh := TransOrderChoice = TransOrderChoice::"Copy to Req. Wksh";
                            end;
                        }
                        group(Control3)
                        {
                            ShowCaption = false;
                            Visible = TransOrderCopyToReqWksh;
                            field(TransTemp; TransWkshTemp)
                            {
                                ApplicationArea = Planning;
                                Caption = 'Req. Wksh. Template';
                                Enabled = true;
                                TableRelation = "Req. Wksh. Template";
                                ToolTip = 'Specifies that you want to copy the planning line proposals for transfer orders to this requisition worksheet template.';

                                trigger OnLookup(var Text: Text): Boolean
                                begin
                                    if PAGE.RunModal(PAGE::"Req. Worksheet Templates", ReqWkshTmpl) = ACTION::LookupOK then begin
                                        Text := ReqWkshTmpl.Name;
                                        exit(true);
                                    end;
                                    exit(false);
                                end;

                                trigger OnValidate()
                                begin
                                    TransWkshName := '';
                                end;
                            }
                            field(TransName; TransWkshName)
                            {
                                ApplicationArea = Planning;
                                Caption = 'Req. Wksh. Name';
                                Enabled = true;
                                TableRelation = "Requisition Wksh. Name".Name;
                                ToolTip = 'Specifies that you want to copy the planning line proposals for transfer orders to this requisition worksheet name.';

                                trigger OnLookup(var Text: Text): Boolean
                                begin
                                    ReqWkshName.SetFilter("Worksheet Template Name", TransWkshTemp);
                                    if PAGE.RunModal(PAGE::"Req. Wksh. Names", ReqWkshName) = ACTION::LookupOK then begin
                                        Text := ReqWkshName.Name;
                                        exit(true);
                                    end;
                                    exit(false);
                                end;
                            }
                        }
                    }
                    field(CombineTransferOrders; CombineTransferOrders)
                    {
                        ApplicationArea = Location;
                        Caption = 'Combine Transfer Orders';
                        ToolTip = 'Specifies whether to stop as soon as the batch job encounters an error.';
                    }
                }
                field(NoPlanningResiliency; NoPlanningResiliency)
                {
                    ApplicationArea = Planning;
                    Caption = 'Stop and Show First Error';
                    ToolTip = 'Specifies whether to stop as soon as the batch job encounters an error.';
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            PurchOrderCopyToReqWksh := false;
            TransOrderCopyToReqWksh := false;
        end;

        trigger OnOpenPage()
        begin
            PurchOrderCopyToReqWksh := PurchOrderChoice = PurchOrderChoice::"Copy to Req. Wksh";
            TransOrderCopyToReqWksh := TransOrderChoice = TransOrderChoice::"Copy to Req. Wksh";
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OnBeforePreReport;
    end;

    var
        Text000: Label 'There are no planning lines to make orders for.';
        Text007: Label 'This template and worksheet are currently active. ';
        Text008: Label 'You must select a different template name or worksheet name to copy to.';
        PurchOrderHeader: Record "Purchase Header";
        ReqWkshTmpl: Record "Req. Wksh. Template";
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLineFilters: Record "Requisition Line";
        TempDocumentEntry: Record "Document Entry" temporary;
        CarryOutAction: Codeunit "Carry Out Action";
        ReqWkshMakeOrders: Codeunit "Req. Wksh.-Make Order";
        Window: Dialog;
        ReqWkshTemp: Code[10];
        ReqWksh: Code[10];
        TransWkshTemp: Code[10];
        TransWkshName: Code[10];
        ProdWkshTempl: Code[10];
        ProdWkshName: Code[10];
        CurrReqWkshTemp: Code[10];
        CurrReqWkshName: Code[10];
        ProdOrderChoice: Option " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
        PurchOrderChoice: Option " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh";
        TransOrderChoice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh";
        Text009: Label 'You must select a worksheet to copy to';
        AsmOrderChoice: Option " ","Make Assembly Orders","Make Assembly Orders & Print";
        PrintOrders: Boolean;
        CombineTransferOrders: Boolean;
        ReserveforPlannedProd: Boolean;
        NoPlanningResiliency: Boolean;
        Text010: Label 'Components were not reserved for orders with status Planned.';
        Text011: Label 'You must make order for both line %1 and %2 because they are associated.';
        Text012: Label 'Carrying Out Actions  #1########## @2@@@@@@@@@@@@@';
        Counter: Integer;
        CounterTotal: Integer;
        CounterFailed: Integer;
        Text013: Label 'Not all Requisition Lines were carried out.\A total of %1 lines were not carried out because of errors encountered.';
        EndOrderDate: Date;
        [InDataSet]
        PurchOrderCopyToReqWksh: Boolean;
        [InDataSet]
        TransOrderCopyToReqWksh: Boolean;

    local procedure CarryOutActions(SourceType: Option Purchase,Transfer,Production,Assembly; Choice: Option; WkshTempl: Code[10]; WkshName: Code[10])
    begin
        if NoPlanningResiliency then begin
            CarryOutAction.SetTryParameters(SourceType, Choice, WkshTempl, WkshName);
            CarryOutAction.Run("Requisition Line");
        end else
            if not CarryOutAction.TryCarryOutAction(SourceType, "Requisition Line", Choice, WkshTempl, WkshName) then
                CounterFailed := CounterFailed + 1;
    end;

    procedure SetCreatedDocumentBuffer(var TempDocumentEntryNew: Record "Document Entry" temporary)
    begin
        TempDocumentEntry.Copy(TempDocumentEntryNew, true);
        CarryOutAction.SetCreatedDocumentBuffer(TempDocumentEntryNew);
    end;

    procedure SetReqWkshLine(var CurrentReqLine: Record "Requisition Line")
    begin
        CurrReqWkshTemp := CurrentReqLine."Worksheet Template Name";
        CurrReqWkshName := CurrentReqLine."Journal Batch Name";
        ReqLineFilters.Copy(CurrentReqLine);
    end;

    procedure SetDemandOrder(var ReqLine: Record "Requisition Line"; MfgUserTempl: Record "Manufacturing User Template")
    begin
        SetReqWkshLine(ReqLine);

        InitializeRequest(
          MfgUserTempl."Create Production Order",
          MfgUserTempl."Create Purchase Order",
          MfgUserTempl."Create Transfer Order",
          MfgUserTempl."Create Assembly Order");

        ReqWkshTemp := MfgUserTempl."Purchase Req. Wksh. Template";
        ReqWksh := MfgUserTempl."Purchase Wksh. Name";
        ProdWkshTempl := MfgUserTempl."Prod. Req. Wksh. Template";
        ProdWkshName := MfgUserTempl."Prod. Wksh. Name";
        TransWkshTemp := MfgUserTempl."Transfer Req. Wksh. Template";
        TransWkshName := MfgUserTempl."Transfer Wksh. Name";

        with ReqLineFilters do
            case MfgUserTempl."Make Orders" of
                MfgUserTempl."Make Orders"::"The Active Line":
                    begin
                        ReqLineFilters := ReqLine;
                        SetRecFilter;
                    end;
                MfgUserTempl."Make Orders"::"The Active Order":
                    begin
                        SetCurrentKey(
                          "User ID", "Demand Type", "Demand Subtype", "Demand Order No.", "Demand Line No.", "Demand Ref. No.");
                        CopyFilters(ReqLine);
                        SetRange("Demand Type", ReqLine."Demand Type");
                        SetRange("Demand Subtype", ReqLine."Demand Subtype");
                        SetRange("Demand Order No.", ReqLine."Demand Order No.");
                    end;
                MfgUserTempl."Make Orders"::"All Lines":
                    begin
                        SetCurrentKey(
                          "User ID", "Worksheet Template Name", "Journal Batch Name", "Line No.");
                        Copy(ReqLine);
                    end;
            end;

        OnAfterSetDemandOrder(ReqLine, MfgUserTempl, ReqLineFilters);
    end;

    procedure InitializeRequest(NewProdOrderChoice: Option; NewPurchOrderChoice: Option; NewTransOrderChoice: Option; NewAsmOrderChoice: Option)
    begin
        ProdOrderChoice := NewProdOrderChoice;
        PurchOrderChoice := NewPurchOrderChoice;
        TransOrderChoice := NewTransOrderChoice;
        AsmOrderChoice := NewAsmOrderChoice;
    end;

    procedure InitializeRequest2(NewProdOrderChoice: Option; NewPurchOrderChoice: Option; NewTransOrderChoice: Option; NewAsmOrderChoice: Option; NewReqWkshTemp: Code[10]; NewReqWksh: Code[10]; NewTransWkshTemp: Code[10]; NewTransWkshName: Code[10])
    begin
        InitializeRequest(NewProdOrderChoice, NewPurchOrderChoice, NewTransOrderChoice, NewAsmOrderChoice);
        ReqWkshTemp := NewReqWkshTemp;
        ReqWksh := NewReqWksh;
        TransWkshTemp := NewTransWkshTemp;
        TransWkshName := NewTransWkshName;
    end;

    local procedure SetReqLineFilters()
    begin
        with "Requisition Line" do begin
            if ReqLineFilters.GetFilters <> '' then
                CopyFilters(ReqLineFilters);
            SetRange("Worksheet Template Name", CurrReqWkshTemp);
            SetRange("Journal Batch Name", CurrReqWkshName);
            SetRange(Type, Type::Item);
            SetFilter("Action Message", '<>%1', "Action Message"::" ");
        end;
        OnAfterSetReqLineFilters("Requisition Line");
    end;

    local procedure CheckCopyToWksh(ToReqWkshTempl: Code[10]; ToReqWkshName: Code[10])
    begin
        if (ToReqWkshTempl <> '') and
           (CurrReqWkshTemp = ToReqWkshTempl) and
           (CurrReqWkshName = ToReqWkshName)
        then
            Error(Text007 + Text008);

        if (ToReqWkshTempl = '') or (ToReqWkshName = '') then
            Error(Text009);
    end;

    local procedure CheckPreconditions()
    begin
        with "Requisition Line" do
            repeat
                CheckLine;
            until Next = 0;
    end;

    local procedure CheckLine()
    var
        SalesLine: Record "Sales Line";
        ProdOrderComp: Record "Prod. Order Component";
        ServLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        AsmLine: Record "Assembly Line";
        ReqLine2: Record "Requisition Line";
    begin
        with "Requisition Line" do begin
            if "Planning Line Origin" <> "Planning Line Origin"::"Order Planning" then
                exit;

            CheckAssociations("Requisition Line");

            if "Planning Level" > 0 then
                exit;

            if "Replenishment System" in ["Replenishment System"::Purchase,
                                          "Replenishment System"::Transfer]
            then
                TestField("Supply From");

            case "Demand Type" of
                DATABASE::"Sales Line":
                    begin
                        SalesLine.Get("Demand Subtype", "Demand Order No.", "Demand Line No.");
                        SalesLine.TestField(Type, SalesLine.Type::Item);
                        if not (("Demand Date" = WorkDate) and (SalesLine."Shipment Date" in [0D, WorkDate])) then
                            TestField("Demand Date", SalesLine."Shipment Date");
                        TestField("No.", SalesLine."No.");
                        TestField("Qty. per UOM (Demand)", SalesLine."Qty. per Unit of Measure");
                        TestField("Variant Code", SalesLine."Variant Code");
                        TestField("Location Code", SalesLine."Location Code");
                        SalesLine.CalcFields("Reserved Qty. (Base)");
                        TestField(
                          "Demand Quantity (Base)",
                          -SalesLine.SignedXX(SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)"))
                    end;
                DATABASE::"Prod. Order Component":
                    begin
                        ProdOrderComp.Get("Demand Subtype", "Demand Order No.", "Demand Line No.", "Demand Ref. No.");
                        TestField("No.", ProdOrderComp."Item No.");
                        if not (("Demand Date" = WorkDate) and (ProdOrderComp."Due Date" in [0D, WorkDate])) then
                            TestField("Demand Date", ProdOrderComp."Due Date");
                        TestField("Qty. per UOM (Demand)", ProdOrderComp."Qty. per Unit of Measure");
                        TestField("Variant Code", ProdOrderComp."Variant Code");
                        TestField("Location Code", ProdOrderComp."Location Code");
                        ProdOrderComp.CalcFields("Reserved Qty. (Base)");
                        TestField(
                          "Demand Quantity (Base)",
                          ProdOrderComp."Remaining Qty. (Base)" - ProdOrderComp."Reserved Qty. (Base)");
                        if (ProdOrderChoice = ProdOrderChoice::Planned) and Reserve then
                            ReserveforPlannedProd := true;
                    end;
                DATABASE::"Service Line":
                    begin
                        ServLine.Get("Demand Subtype", "Demand Order No.", "Demand Line No.");
                        ServLine.TestField(Type, ServLine.Type::Item);
                        if not (("Demand Date" = WorkDate) and (ServLine."Needed by Date" in [0D, WorkDate])) then
                            TestField("Demand Date", ServLine."Needed by Date");
                        TestField("No.", ServLine."No.");
                        TestField("Qty. per UOM (Demand)", ServLine."Qty. per Unit of Measure");
                        TestField("Variant Code", ServLine."Variant Code");
                        TestField("Location Code", ServLine."Location Code");
                        ServLine.CalcFields("Reserved Qty. (Base)");
                        TestField(
                          "Demand Quantity (Base)",
                          -ServLine.SignedXX(ServLine."Outstanding Qty. (Base)" - ServLine."Reserved Qty. (Base)"))
                    end;
                DATABASE::"Job Planning Line":
                    begin
                        JobPlanningLine.SetRange("Job Contract Entry No.", "Demand Line No.");
                        JobPlanningLine.FindFirst;
                        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
                        JobPlanningLine.TestField("Job No.");
                        JobPlanningLine.TestField(Status, JobPlanningLine.Status::Order);
                        if not (("Demand Date" = WorkDate) and (JobPlanningLine."Planning Date" in [0D, WorkDate])) then
                            TestField("Demand Date", JobPlanningLine."Planning Date");
                        TestField("No.", JobPlanningLine."No.");
                        TestField("Qty. per UOM (Demand)", JobPlanningLine."Qty. per Unit of Measure");
                        TestField("Variant Code", JobPlanningLine."Variant Code");
                        TestField("Location Code", JobPlanningLine."Location Code");
                        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
                        TestField(
                          "Demand Quantity (Base)",
                          JobPlanningLine."Remaining Qty. (Base)" - JobPlanningLine."Reserved Qty. (Base)")
                    end;
                DATABASE::"Assembly Line":
                    begin
                        AsmLine.Get("Demand Subtype", "Demand Order No.", "Demand Line No.");
                        AsmLine.TestField(Type, AsmLine.Type::Item);
                        if not (("Demand Date" = WorkDate) and (AsmLine."Due Date" in [0D, WorkDate])) then
                            TestField("Demand Date", AsmLine."Due Date");
                        TestField("No.", AsmLine."No.");
                        TestField("Qty. per UOM (Demand)", AsmLine."Qty. per Unit of Measure");
                        TestField("Variant Code", AsmLine."Variant Code");
                        TestField("Location Code", AsmLine."Location Code");
                        AsmLine.CalcFields("Reserved Qty. (Base)");
                        TestField(
                          "Demand Quantity (Base)",
                          -AsmLine.SignedXX(AsmLine."Remaining Quantity (Base)" - AsmLine."Reserved Qty. (Base)"))
                    end;
            end;

            ReqLine2.SetCurrentKey(
              "User ID", "Demand Type", "Demand Subtype", "Demand Order No.", "Demand Line No.", "Demand Ref. No.");
            ReqLine2.SetFilter("User ID", '<>%1', UserId);
            ReqLine2.SetRange("Demand Type", "Demand Type");
            ReqLine2.SetRange("Demand Subtype", "Demand Subtype");
            ReqLine2.SetRange("Demand Order No.", "Demand Order No.");
            ReqLine2.SetRange("Demand Line No.", "Demand Line No.");
            ReqLine2.SetRange("Demand Ref. No.", "Demand Ref. No.");
            ReqLine2.DeleteAll(true);
        end;
    end;

    local procedure CheckAssociations(var ReqLine: Record "Requisition Line")
    var
        ReqLine2: Record "Requisition Line";
        ReqLine3: Record "Requisition Line";
    begin
        with ReqLine do begin
            ReqLine3.Copy(ReqLine);
            ReqLine2 := ReqLine;

            if ReqLine2."Planning Level" > 0 then
                while (ReqLine2.Next(-1) <> 0) and (ReqLine2."Planning Level" > 0) do;

            repeat
                ReqLine3 := ReqLine2;
                if not ReqLine3.Find then
                    Error(Text011, "Line No.", ReqLine2."Line No.");
            until (ReqLine2.Next = 0) or (ReqLine2."Planning Level" = 0)
        end;
    end;

    local procedure WindowUpdate()
    begin
        Counter := Counter + 1;
        Window.Update(1, "Requisition Line"."No.");
        Window.Update(2, Round(Counter / CounterTotal * 10000, 1));
    end;

    local procedure PurchaseSuggestionExists(var RequisitionLine: Record "Requisition Line"): Boolean
    var
        StopLoop: Boolean;
        PurchaseExists: Boolean;
    begin
        with RequisitionLine do begin
            if FindSet then
                repeat
                    PurchaseExists := "Ref. Order Type" = "Ref. Order Type"::Purchase;
                    if not PurchaseExists then
                        StopLoop := Next = 0
                    else
                        StopLoop := true;
                until StopLoop;
            if PurchaseExists then
                SetRange("Ref. Order Type", "Ref. Order Type"::Purchase);
        end;
        exit(PurchaseExists);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDemandOrder(var RequisitionLine: Record "Requisition Line"; MfgUserTempl: Record "Manufacturing User Template"; var ReqLineFilters: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReqLineFilters(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforePreReport()
    begin
    end;
}

