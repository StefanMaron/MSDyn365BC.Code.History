codeunit 5920 ServItemManagement
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Do you want to create a %1?';
        Text001: Label 'Service item %1 was created. This service item does not belong to any service contract.';
        Item: Record Item;
        ServItemGr: Record "Service Item Group";
        ServItem: Record "Service Item";
        ServMgtSetup: Record "Service Mgt. Setup";
        ServHeader: Record "Service Header";
        ServInvoiceLine: Record "Service Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TempReservEntry: Record "Reservation Entry" temporary;
        GLSetup: Record "General Ledger Setup";
        TempServiceItem: Record "Service Item" temporary;
        TempServiceItemComp: Record "Service Item Component" temporary;
        ResSkillMgt: Codeunit "Resource Skill Mgt.";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ServLogMgt: Codeunit ServLogManagement;
        ServOrderMgt: Codeunit ServOrderManagement;
        NextLineNo: Integer;
        Index: Integer;
        Text002: Label 'You have inserted a %1 on the selected %2.\Would you like to copy this information into the %1 field for the newly created %3?';
        Text003: Label 'Posting cannot be completed successfully. %1 %2  belongs to the %3 that requires creating service items. Check if the %4 field contains a whole number.';
        Text004: Label 'Posting cannot be completed successfully. For the items that are used to replace or create service item components, the %1 field on the %2 must contain a whole number.';
        Text005: Label 'The service item that is linked to the order has been deleted.';

    procedure AddOrReplaceSIComponent(var ServLine: Record "Service Line"; ServHeader: Record "Service Header"; ServShptDocNo: Code[20]; ServShptLineNo: Integer; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ServItemComponent: Record "Service Item Component";
        ServItemComponent2: Record "Service Item Component";
        NewServItemComponent: Record "Service Item Component";
        ComponentLine: Integer;
        x: Integer;
        TrackingLinesExist: Boolean;
    begin
        if (ServLine.Type <> ServLine.Type::Item) or (ServLine."Qty. to Ship" = 0) then
            exit;

        OnBeforeReplaceSIComponent(ServLine, ServHeader, ServShptDocNo, ServShptLineNo, TempTrackingSpecification);

        with ServLine do
            case "Spare Part Action" of
                "Spare Part Action"::"Component Replaced":
                    begin
                        CheckWholeNumber(ServLine);
                        NewServItemComponent.LockTable();
                        NewServItemComponent.Reset();
                        NewServItemComponent.SetRange(Active, false);
                        NewServItemComponent.SetRange("Parent Service Item No.", "Service Item No.");
                        if NewServItemComponent.FindLast then
                            ComponentLine := NewServItemComponent."Line No."
                        else
                            ComponentLine := 0;

                        if ServItemComponent2.Get(true, "Service Item No.", "Component Line No.") then begin
                            ServItemComponent := ServItemComponent2;
                            ServItemComponent."Service Order No." := "Document No.";
                            Clear(ServLogMgt);
                            ServLogMgt.ServItemComponentRemoved(ServItemComponent);
                            ServItemComponent.Delete();
                            ServItemComponent2.Active := false;
                            ServItemComponent2."Line No." := ComponentLine + 10000;
                            ServItemComponent2."From Line No." := ServItemComponent."Line No.";
                            ServItemComponent2."Service Order No." := ServHeader."No.";
                            ServItemComponent2.Insert();
                            if ServItemComponent2.Type = ServItemComponent2.Type::"Service Item" then begin
                                ServItem.Get(ServItemComponent2."No.");
                                ServItem.Status := ServItem.Status::Defective;
                                ServItem.Modify();
                            end;
                        end;

                        InitNewServItemComponent(NewServItemComponent, ServLine, ServItemComponent."Line No.", ServHeader."Posting Date");
                        TempTrackingSpecification.SetSourceFilter(DATABASE::"Service Line", "Document Type", "Document No.", "Line No.", false);
                        TrackingLinesExist := TempTrackingSpecification.Find('-');
                        if TrackingLinesExist then begin
                            NewServItemComponent."Serial No." := TempTrackingSpecification."Serial No.";
                            if TempTrackingSpecification.Next = 0 then
                                TrackingLinesExist := false;
                        end;
                        OnBeforeInsertNewServItemComponent(NewServItemComponent, ServLine);
                        NewServItemComponent.Insert();
                        Clear(ServLogMgt);
                        ServLogMgt.ServItemComponentAdded(NewServItemComponent);

                        NewServItemComponent.SetRange(Active, true);
                        if NewServItemComponent.FindLast then
                            ComponentLine := NewServItemComponent."Line No."
                        else
                            ComponentLine := 0;

                        for x := 2 to "Qty. to Ship" do begin
                            ComponentLine := ComponentLine + 10000;
                            InitNewServItemComponent(NewServItemComponent, ServLine, ComponentLine, ServHeader."Posting Date");
                            if TrackingLinesExist then begin
                                NewServItemComponent."Serial No." := TempTrackingSpecification."Serial No.";
                                if TempTrackingSpecification.Next = 0 then
                                    TrackingLinesExist := false;
                            end;
                            OnBeforeInsertNewServItemComponent(NewServItemComponent, ServLine);
                            NewServItemComponent.Insert();
                            Clear(ServLogMgt);
                            ServLogMgt.ServItemComponentAdded(NewServItemComponent);
                        end;
                    end;
                "Spare Part Action"::"Component Installed":
                    begin
                        CheckWholeNumber(ServLine);
                        NewServItemComponent.LockTable();
                        NewServItemComponent.Reset();
                        NewServItemComponent.SetRange(Active, true);
                        NewServItemComponent.SetRange("Parent Service Item No.", "Service Item No.");
                        if NewServItemComponent.FindLast then
                            ComponentLine := NewServItemComponent."Line No."
                        else
                            ComponentLine := 0;

                        TempTrackingSpecification.SetSourceFilter(DATABASE::"Service Line", "Document Type", "Document No.", "Line No.", false);
                        TrackingLinesExist := TempTrackingSpecification.Find('-');

                        for x := 1 to "Qty. to Ship" do begin
                            ComponentLine := ComponentLine + 10000;
                            InitNewServItemComponent(NewServItemComponent, ServLine, ComponentLine, ServHeader."Posting Date");
                            NewServItemComponent."Service Order No." := "Document No.";
                            if TrackingLinesExist then begin
                                NewServItemComponent."Serial No." := TempTrackingSpecification."Serial No.";
                                if TempTrackingSpecification.Next = 0 then
                                    TrackingLinesExist := false;
                            end;
                            OnBeforeInsertNewServItemComponent(NewServItemComponent, ServLine);
                            NewServItemComponent.Insert();
                            Clear(ServLogMgt);
                            ServLogMgt.ServItemComponentAdded(NewServItemComponent);
                        end;
                    end;
                "Spare Part Action"::Permanent,
                "Spare Part Action"::"Temporary":
                    begin
                        ServItem.Get("Service Item No.");
                        ServOrderMgt.ReplacementCreateServItem(ServItem, ServLine,
                          ServShptDocNo, ServShptLineNo, TempTrackingSpecification);
                    end;
            end;
    end;

    local procedure InitNewServItemComponent(var NewServItemComponent: Record "Service Item Component"; ServiceLine: Record "Service Line"; NextLineNo: Integer; PostingDate: Date)
    begin
        with NewServItemComponent do begin
            Init;
            "Parent Service Item No." := ServiceLine."Service Item No.";
            "Line No." := NextLineNo;
            Active := true;
            "No." := ServiceLine."No.";
            Type := Type::Item;
            "Date Installed" := PostingDate;
            Description := ServiceLine.Description;
            "Description 2" := ServiceLine."Description 2";
            "Variant Code" := ServiceLine."Variant Code";
            "Service Order No." := ServiceLine."Document No.";
            "Last Date Modified" := Today;
        end;

        OnAfterInitNewServItemComponent(NewServItemComponent, ServiceLine);
    end;

    local procedure InsertServItemComponent(var ServiceItemComponent: Record "Service Item Component"; BOMComponent: Record "BOM Component"; BOMComponent2: Record "BOM Component"; SalesHeader: Record "Sales Header"; SalesShipmentLine: Record "Sales Shipment Line")
    begin
        with ServiceItemComponent do begin
            Init;
            Active := true;
            "Parent Service Item No." := ServItem."No.";
            "Line No." := NextLineNo;
            Type := Type::Item;
            "No." := BOMComponent2."No.";
            "Date Installed" := SalesHeader."Posting Date";
            Description := BOMComponent2.Description;
            "Serial No." := '';
            "Variant Code" := BOMComponent2."Variant Code";
            OnBeforeInsertServItemComponent(ServiceItemComponent, ServItem, SalesHeader, SalesShipmentLine, BOMComponent, BOMComponent2);
            Insert;
        end;
    end;

    procedure CreateServItemOnSalesLineShpt(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line")
    var
        ServItemComponent: Record "Service Item Component";
        ItemTrackingCode: Record "Item Tracking Code";
        BOMComp: Record "BOM Component";
        BOMComp2: Record "BOM Component";
        PurchaseHeader: Record "Purchase Header";
        TrackingLinesExist: Boolean;
        x: Integer;
        ServItemWithSerialNoExist: Boolean;
        IsHandled: Boolean;
        WarrantyStartDate: Date;
    begin
        IsHandled := false;
        OnBeforeCreateServItemOnSalesLineShpt(SalesHeader, SalesLine, SalesShipmentLine, IsHandled);
        if IsHandled then
            exit;

        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice]) then
            exit;

        if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine."Qty. to Ship (Base)" > 0) then begin
            Item.Get(SalesLine."No.");
            if not ItemTrackingCode.Get(Item."Item Tracking Code") then
                ItemTrackingCode.Init();
            if ServItemGr.Get(Item."Service Item Group") and ServItemGr."Create Service Item" then begin
                if SalesLine."Qty. to Ship (Base)" <> Round(SalesLine."Qty. to Ship (Base)", 1) then
                    Error(
                      Text003,
                      Item.TableCaption,
                      Item."No.",
                      ServItemGr.TableCaption,
                      SalesLine.FieldCaption("Qty. to Ship (Base)"));

                TempReservEntry.SetRange("Item No.", SalesLine."No.");
                TempReservEntry.SetRange("Location Code", SalesLine."Location Code");
                TempReservEntry.SetRange("Variant Code", SalesLine."Variant Code");
                TempReservEntry.SetRange("Source Subtype", SalesLine."Document Type");
                TempReservEntry.SetRange("Source ID", SalesLine."Document No.");
                TempReservEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
                TrackingLinesExist := TempReservEntry.FindSet;

                TempServiceItem.DeleteAll();
                TempServiceItemComp.DeleteAll();

                GLSetup.Get();
                ServMgtSetup.Get();
                ServMgtSetup.TestField("Service Item Nos.");
                for x := 1 to SalesLine."Qty. to Ship (Base)" do begin
                    Clear(ServItem);
                    ServItemWithSerialNoExist := false;
                    if TempReservEntry."Serial No." <> '' then begin
                        ServItem.SetRange("Item No.", SalesLine."No.");
                        ServItem.SetRange("Serial No.", TempReservEntry."Serial No.");
                        if ServItem.FindFirst then
                            ServItemWithSerialNoExist := true;
                    end;
                    if (TempReservEntry."Serial No." = '') or (not ServItemWithSerialNoExist) then begin
                        ServItem.Init();
                        NoSeriesMgt.InitSeries(
                          ServMgtSetup."Service Item Nos.", ServItem."No. Series", 0D, ServItem."No.", ServItem."No. Series");
                        ServItem.Insert();
                    end;
                    ServItem."Sales/Serv. Shpt. Document No." := SalesShipmentLine."Document No.";
                    ServItem."Sales/Serv. Shpt. Line No." := SalesShipmentLine."Line No.";
                    ServItem."Shipment Type" := ServItem."Shipment Type"::Sales;
                    ServItem.Validate(Description,
                      CopyStr(SalesLine.Description, 1, MaxStrLen(ServItem.Description)));
                    ServItem."Description 2" := CopyStr(
                        StrSubstNo('%1 %2', SalesHeader."Document Type", SalesHeader."No."),
                        1, MaxStrLen(ServItem."Description 2"));
                    ServItem.Validate("Customer No.", SalesHeader."Sell-to Customer No.");
                    ServItem.Validate("Ship-to Code", SalesHeader."Ship-to Code");
                    ServItem.OmitAssignResSkills(true);
                    ServItem.Validate("Item No.", Item."No.");
                    ServItem.OmitAssignResSkills(false);
                    if TrackingLinesExist then
                        ServItem."Serial No." := TempReservEntry."Serial No.";
                    ServItem."Variant Code" := SalesLine."Variant Code";

                    ItemUnitOfMeasure.Get(Item."No.", SalesLine."Unit of Measure Code");

                    ServItem.Validate("Sales Unit Cost", Round(SalesLine."Unit Cost (LCY)" /
                        ItemUnitOfMeasure."Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision"));
                    if SalesHeader."Currency Code" <> '' then
                        ServItem.Validate(
                          "Sales Unit Price",
                          AmountToLCY(
                            Round(SalesLine."Unit Price" /
                              ItemUnitOfMeasure."Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision"),
                            SalesHeader."Currency Factor",
                            SalesHeader."Currency Code",
                            SalesHeader."Posting Date"))
                    else
                        ServItem.Validate("Sales Unit Price", Round(SalesLine."Unit Price" /
                            ItemUnitOfMeasure."Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision"));
                    ServItem."Vendor No." := Item."Vendor No.";
                    ServItem."Vendor Item No." := Item."Vendor Item No.";
                    ServItem."Unit of Measure Code" := Item."Base Unit of Measure";
                    ServItem."Sales Date" := SalesHeader."Posting Date";
                    ServItem."Installation Date" := SalesHeader."Posting Date";
                    ServItem."Warranty % (Parts)" := ServMgtSetup."Warranty Disc. % (Parts)";
                    ServItem."Warranty % (Labor)" := ServMgtSetup."Warranty Disc. % (Labor)";

                    if TrackingLinesExist and (TempReservEntry."Warranty Date" <> 0D) then
                        WarrantyStartDate := TempReservEntry."Warranty Date"
                    else begin
                        WarrantyStartDate := SalesHeader."Posting Date";
                        if (WarrantyStartDate = 0D) and SalesLine."Drop Shipment" then
                            if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, SalesLine."Purchase Order No.") then
                                WarrantyStartDate := PurchaseHeader."Posting Date";
                    end;
                    CalcServiceItemWarrantyDates(
                      ServItem, WarrantyStartDate, ItemTrackingCode."Warranty Date Formula", ServMgtSetup."Default Warranty Duration");

                    OnCreateServItemOnSalesLineShpt(ServItem, SalesHeader, SalesLine);

                    ServItem.Modify();
                    Clear(TempServiceItem);
                    TempServiceItem := ServItem;
                    if TempServiceItem.Insert() then;
                    ResSkillMgt.AssignServItemResSkills(ServItem);
                    if SalesLine."BOM Item No." <> '' then begin
                        Clear(BOMComp);
                        BOMComp.SetRange("Parent Item No.", SalesLine."BOM Item No.");
                        BOMComp.SetRange(Type, BOMComp.Type::Item);
                        BOMComp.SetRange("No.", SalesLine."No.");
                        BOMComp.SetRange("Installed in Line No.", 0);
                        if BOMComp.FindSet then
                            repeat
                                Clear(BOMComp2);
                                BOMComp2.SetRange("Parent Item No.", SalesLine."BOM Item No.");
                                BOMComp2.SetRange("Installed in Line No.", BOMComp."Line No.");
                                NextLineNo := 0;
                                if BOMComp2.FindSet then
                                    repeat
                                        for Index := 1 to Round(BOMComp2."Quantity per", 1) do begin
                                            NextLineNo := NextLineNo + 10000;
                                            InsertServItemComponent(ServItemComponent, BOMComp, BOMComp2, SalesHeader, SalesShipmentLine);
                                            Clear(TempServiceItemComp);
                                            TempServiceItemComp := ServItemComponent;
                                            TempServiceItemComp.Insert();
                                        end;
                                    until BOMComp2.Next = 0;
                            until BOMComp.Next = 0;
                    end;

                    OnCreateServItemOnSalesLineShptOnAfterAddServItemComponents(
                      SalesHeader, SalesLine, SalesShipmentLine, ServItem, TempServiceItem, TempServiceItemComp);

                    Clear(ServLogMgt);
                    ServLogMgt.ServItemAutoCreated(ServItem);
                    TrackingLinesExist := TempReservEntry.Next = 1;
                end;
            end;
        end;
    end;

    local procedure CalcServiceItemWarrantyDates(var ServiceItem: Record "Service Item"; StartingWarrantyDate: Date; ItemTrackingWarrantyDateFormula: DateFormula; ServMgtSetupDefaultWarrantyDuration: DateFormula)
    begin
        ServiceItem."Warranty Starting Date (Parts)" := StartingWarrantyDate;
        ServiceItem."Warranty Starting Date (Labor)" := StartingWarrantyDate;
        if Format(ItemTrackingWarrantyDateFormula) <> '' then
            ServiceItem."Warranty Ending Date (Parts)" := CalcDate(ItemTrackingWarrantyDateFormula, StartingWarrantyDate)
        else
            ServiceItem."Warranty Ending Date (Parts)" := CalcDate(ServMgtSetupDefaultWarrantyDuration, StartingWarrantyDate);
        ServiceItem."Warranty Ending Date (Labor)" := CalcDate(ServMgtSetupDefaultWarrantyDuration, StartingWarrantyDate);
    end;

    procedure CreateServItemOnServItemLine(var ServItemLine: Record "Service Item Line")
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        with ServItemLine do begin
            TestField("Service Item No.", '');
            TestField("Document No.");
            TestField(Description);
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text000, LowerCase(ServItem.TableCaption)), true) then
                exit;

            Clear(ServItem);
            ServItem.Init();
            ServMgtSetup.Get();
            ServMgtSetup.TestField("Service Item Nos.");
            NoSeriesMgt.InitSeries(
              ServMgtSetup."Service Item Nos.", ServItem."No. Series", 0D, ServItem."No.",
              ServItem."No. Series");
            ServItem.Insert();
            ServItem.Validate(Description, Description);
            Clear(ServHeader);
            ServHeader.Get("Document Type", "Document No.");
            ServItem.Validate("Customer No.", ServHeader."Customer No.");
            ServItem.Validate("Ship-to Code", ServHeader."Ship-to Code");
            ServItem.OmitAssignResSkills(true);
            ServItem.Validate("Item No.", "Item No.");
            ServItem.OmitAssignResSkills(false);
            ServItem."Variant Code" := "Variant Code";
            ServItem.Validate("Serial No.", "Serial No.");
            ServItem."Response Time (Hours)" := "Response Time (Hours)";
            ServItem."Sales Unit Cost" := 0;
            ServItem."Sales Unit Price" := 0;
            ServItem."Vendor No." := "Vendor No.";
            ServItem."Vendor Item No." := "Vendor Item No.";
            ServItem."Unit of Measure Code" := '';
            ServItem."Sales Date" := 0D;
            ServItem."Installation Date" := ServHeader."Posting Date";
            ServItem."Warranty Starting Date (Parts)" := "Warranty Starting Date (Parts)";
            ServItem."Warranty Ending Date (Parts)" := "Warranty Ending Date (Parts)";
            ServItem."Warranty Starting Date (Labor)" := "Warranty Starting Date (Labor)";
            ServItem."Warranty Ending Date (Labor)" := "Warranty Ending Date (Labor)";
            ServItem."Warranty % (Parts)" := "Warranty % (Parts)";
            ServItem."Warranty % (Labor)" := "Warranty % (Labor)";
            ServItem."Service Item Group Code" := "Service Item Group Code";
            if "Service Price Group Code" <> '' then
                if ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(
                       Text002, FieldCaption("Service Price Group Code"),
                       TableCaption, ServItem.TableCaption), true)
                then
                    ServItem."Service Price Group Code" := "Service Price Group Code";

            OnCreateServItemOnServItemLineOnBeforeServItemModify(ServItem, ServHeader, ServItemLine);
            ServItem.Modify();
            ResSkillMgt.AssignServItemResSkills(ServItem);
            Clear(ServLogMgt);
            ServLogMgt.ServItemAutoCreated(ServItem);
            Message(Text001, ServItem."No.");
            "Service Item No." := ServItem."No.";
            "Contract No." := '';

            OnCreateServItemOnServItemLine(ServItem, ServItemLine);

            Modify;
            CreateDim(
              DATABASE::"Service Item", "Service Item No.",
              DATABASE::"Service Item Group", "Service Item Group Code",
              DATABASE::"Responsibility Center", "Responsibility Center");
        end;

        ServLogMgt.ServItemToServOrder(ServItemLine);

        ServInvoiceLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
        ServInvoiceLine.SetRange("Document Type", ServItemLine."Document Type");
        ServInvoiceLine.SetRange("Document No.", ServItemLine."Document No.");
        ServInvoiceLine.SetRange("Service Item Line No.", ServItemLine."Line No.");
        ServInvoiceLine.ModifyAll("Service Item No.", ServItemLine."Service Item No.");
    end;

    local procedure AmountToLCY(FCAmount: Decimal; CurrencyFactor: Decimal; CurrencyCode: Code[10]; CurrencyDate: Date): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        Currency.TestField("Unit-Amount Rounding Precision");
        exit(
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              CurrencyDate, CurrencyCode,
              FCAmount, CurrencyFactor),
            Currency."Unit-Amount Rounding Precision"));
    end;

    procedure CopyReservationEntry(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Qty. to Ship", '<>0');
        if SalesLine.FindSet then
            repeat
                CopyReservationEntryLine(SalesLine);
            until SalesLine.Next = 0;
    end;

    procedure CopyReservationEntryService(ServHeader: Record "Service Header")
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.Reset();
        Clear(TempReservEntry);

        ReservEntry.SetRange("Source Subtype", ServHeader."Document Type");
        ReservEntry.SetRange("Source ID", ServHeader."No.");
        ReservEntry.SetRange(Positive, false);
        ReservEntry.SetRange("Source Type", DATABASE::"Service Line");
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Source Prod. Order Line", 0);
        ReservEntry.SetFilter("Serial No.", '<>%1', '');
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>%1', 0);

        if ReservEntry.FindSet then
            repeat
                TempReservEntry := ReservEntry;
                TempReservEntry.Insert();
            until ReservEntry.Next = 0;
    end;

    procedure CreateServItemOnSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        DummySalesShptLine: Record "Sales Shipment Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet then
            repeat
                CreateServItemOnSalesLineShpt(SalesHeader, SalesLine, DummySalesShptLine);
            until SalesLine.Next = 0;
    end;

    local procedure CheckWholeNumber(var ServLine: Record "Service Line")
    begin
        with ServLine do begin
            if Quantity <> Round(Quantity, 1) then
                Error(Text004, FieldCaption(Quantity), TableCaption);
            if "Qty. to Ship" <> Round("Qty. to Ship", 1) then
                Error(Text004, FieldCaption("Qty. to Ship"), TableCaption);
        end;
    end;

    procedure ReturnServItemComp(var TempServItem: Record "Service Item" temporary; var TempServItemComp: Record "Service Item Component" temporary)
    begin
        TempServItem.DeleteAll();
        if TempServiceItem.Find('-') then
            repeat
                TempServItem := TempServiceItem;
                TempServItem.Insert();
            until TempServiceItem.Next = 0;
        TempServItemComp.DeleteAll();
        if TempServiceItemComp.Find('-') then
            repeat
                TempServItemComp := TempServiceItemComp;
                TempServItemComp.Insert();
            until TempServiceItemComp.Next = 0;
    end;

    procedure DeleteServItemOnSaleCreditMemo(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        ServItem: Record "Service Item";
        ReservationEntry: Record "Reservation Entry";
        ServItemDeleted: Boolean;
    begin
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::"Return Order"]) then
            exit;

        ServItemDeleted := false;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet then
            repeat
                if SalesLine.Type = SalesLine.Type::Item then begin
                    ReservationEntry.SetRange("Item No.", SalesLine."No.");
                    ReservationEntry.SetRange("Location Code", SalesLine."Location Code");
                    ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
                    ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
                    if ReservationEntry.FindSet then
                        repeat
                            ServItem.SetRange("Item No.", SalesLine."No.");
                            ServItem.SetRange("Customer No.", SalesLine."Sell-to Customer No.");
                            ServItem.SetRange("Serial No.", ReservationEntry."Serial No.");
                            if ServItem.FindFirst then begin
                                if ServItem.CheckIfCanBeDeleted <> '' then begin
                                    ServItem.Validate(Status, ServItem.Status::" ");
                                    ServItem.Modify(true);
                                end else
                                    if ServItem.Delete(true) then
                                        ServItemDeleted := true;
                            end;
                        until ReservationEntry.Next = 0;
                end;
            until SalesLine.Next = 0;
        if ServItemDeleted then
            Message(Text005);
    end;

    local procedure CopyReservationEntryLine(SalesLine: Record "Sales Line")
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.Reset();
        ReservEntry.SetRange("Source Subtype", SalesLine."Document Type");
        ReservEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservEntry.SetRange(Positive, false);
        ReservEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Source Prod. Order Line", 0);
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>%1', 0);

        if ReservEntry.FindSet then
            repeat
                TempReservEntry := ReservEntry;
                TempReservEntry.Insert();
            until ReservEntry.Next = 0;
    end;

    procedure CopyReservation(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Drop Shipment", true);
        PurchaseLine.SetFilter(Quantity, '<>0');
        if PurchaseLine.FindSet then
            repeat
                if SalesLine.Get(SalesLine."Document Type"::Order, PurchaseLine."Sales Order No.", PurchaseLine."Sales Order Line No.") then
                    CopyReservationEntryLine(SalesLine);
            until PurchaseLine.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNewServItemComponent(var ServItemComponent: Record "Service Item Component"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateServItemOnSalesLineShpt(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServItemComponent(var ServiceItemComponent: Record "Service Item Component"; ServiceItem: Record "Service Item"; SalesHeader: Record "Sales Header"; SalesShipmentLine: Record "Sales Shipment Line"; BOMComponent: Record "BOM Component"; BOMComponent2: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewServItemComponent(var ServiceItemComponent: Record "Service Item Component"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReplaceSIComponent(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServShptDocNo: Code[20]; ServShptLineNo: Integer; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServItemOnSalesLineShpt(var ServiceItem: Record "Service Item"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServItemOnServItemLine(var ServiceItem: Record "Service Item"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServItemOnServItemLineOnBeforeServItemModify(var ServiceItem: Record "Service Item"; ServiceHeader: Record "Service Header"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServItemOnSalesLineShptOnAfterAddServItemComponents(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var SalesShipmentLine: Record "Sales Shipment Line"; var ServiceItem: Record "Service Item"; var TempServiceItem: Record "Service Item" temporary; var TempServiceItemComp: Record "Service Item Component" temporary)
    begin
    end;
}

