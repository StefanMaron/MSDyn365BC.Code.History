codeunit 76 "Purch.-Get Drop Shpt."
{
    Permissions = TableData "Sales Header" = m,
                  TableData "Sales Line" = m;
    TableNo = "Purchase Header";

    trigger OnRun()
    begin
        PurchHeader.Copy(Rec);
        Code;
        Rec := PurchHeader;
    end;

    var
        Text000: Label 'There were no lines to be retrieved from sales order %1.';
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        NextLineNo: Integer;
        Text001: Label 'The %1 for %2 %3 has changed from %4 to %5 since the Sales Order was created. Adjust the %6 on the Sales Order or the %1.';
        SelltoCustomerBlankErr: Label 'The Sell-to Customer No. field must have a value.';

    local procedure "Code"()
    var
        PurchLine2: Record "Purchase Line";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        IsHandled: Boolean;
    begin
        with PurchHeader do begin
            TestField("Document Type", "Document Type"::Order);

            if "Sell-to Customer No." = '' then
                Error(SelltoCustomerBlankErr);

            IsHandled := false;
            OnCodeOnBeforeSelectSalesHeader(PurchHeader, SalesHeader, IsHandled);
            if not IsHandled then begin
                SalesHeader.SetCurrentKey("Document Type", "Sell-to Customer No.");
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                SalesHeader.SetRange("Sell-to Customer No.", "Sell-to Customer No.");
                if (PAGE.RunModal(PAGE::"Sales List", SalesHeader) <> ACTION::LookupOK) or
                   (SalesHeader."No." = '')
                then
                    exit;
            end;

            LockTable();
            SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Order);
            TestField("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
            TestField("Ship-to Code", SalesHeader."Ship-to Code");
            if DropShptOrderExists(SalesHeader) then
                AddShipToAddress(SalesHeader, true);

            PurchLine.LockTable();
            SalesLine.LockTable();

            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
            PurchLine.SetRange("Document No.", "No.");
            if PurchLine.FindLast then
                NextLineNo := PurchLine."Line No." + 10000
            else
                NextLineNo := 10000;

            SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.SetRange("Drop Shipment", true);
            SalesLine.SetFilter("Outstanding Quantity", '<>0');
            SalesLine.SetRange(Type, SalesLine.Type::Item);
            SalesLine.SetFilter("No.", '<>%1', '');
            SalesLine.SetRange("Purch. Order Line No.", 0);

            if SalesLine.Find('-') then
                repeat
                    if (SalesLine.Type = SalesLine.Type::Item) and ItemUnitofMeasure.Get(SalesLine."No.", SalesLine."Unit of Measure Code") then
                        if SalesLine."Qty. per Unit of Measure" <> ItemUnitofMeasure."Qty. per Unit of Measure" then
                            Error(Text001,
                              SalesLine.FieldCaption("Qty. per Unit of Measure"),
                              SalesLine.FieldCaption("Unit of Measure Code"),
                              SalesLine."Unit of Measure Code",
                              SalesLine."Qty. per Unit of Measure",
                              ItemUnitofMeasure."Qty. per Unit of Measure",
                              SalesLine.FieldCaption(Quantity));

                    PurchLine.Init();
                    PurchLine."Document Type" := PurchLine."Document Type"::Order;
                    PurchLine."Document No." := "No.";
                    PurchLine."Line No." := NextLineNo;
                    CopyDocMgt.TransfldsFromSalesToPurchLine(SalesLine, PurchLine);
                    GetDescription(PurchLine, SalesLine);
                    PurchLine."Sales Order No." := SalesLine."Document No.";
                    PurchLine."Sales Order Line No." := SalesLine."Line No.";
                    PurchLine."Drop Shipment" := true;
                    PurchLine."Purchasing Code" := SalesLine."Purchasing Code";
                    Evaluate(PurchLine."Inbound Whse. Handling Time", '<0D>');
                    PurchLine.Validate("Inbound Whse. Handling Time");
                    OnBeforePurchaseLineInsert(PurchLine, SalesLine);
                    PurchLine.Insert();
                    OnAfterPurchaseLineInsert(PurchLine);

                    NextLineNo := NextLineNo + 10000;

                    SalesLine."Unit Cost (LCY)" := PurchLine."Unit Cost (LCY)";
                    SalesLine.Validate("Unit Cost (LCY)");
                    SalesLine."Purchase Order No." := PurchLine."Document No.";
                    SalesLine."Purch. Order Line No." := PurchLine."Line No.";
                    OnBeforeSalesLineModify(SalesLine, PurchLine);
                    SalesLine.Modify();
                    OnAfterSalesLineModify(SalesLine, PurchLine);
                    ItemTrackingMgt.CopyItemTracking(SalesLine.RowID1, PurchLine.RowID1, true);

                    if TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, true) then begin
                        TransferExtendedText.InsertPurchExtText(PurchLine);
                        PurchLine2.SetRange("Document Type", "Document Type");
                        PurchLine2.SetRange("Document No.", "No.");
                        if PurchLine2.FindLast then
                            NextLineNo := PurchLine2."Line No.";
                        NextLineNo := NextLineNo + 10000;
                    end;

                until SalesLine.Next = 0
            else
                Error(
                  Text000,
                  SalesHeader."No.");

            OnCodeOnBeforeModify(PurchHeader, SalesHeader);

            Modify; // Only version check
            SalesHeader.Modify(); // Only version check
        end;
    end;

    procedure GetDescription(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    var
        Item: Record Item;
    begin
        if (SalesLine.Type <> SalesLine.Type::Item) or (SalesLine."No." = '') then
            exit;
        Item.Get(SalesLine."No.");

        if GetDescriptionFromItemCrossReference(PurchaseLine, SalesLine, Item) then
            exit;
        if GetDescriptionFromItemTranslation(PurchaseLine, SalesLine) then
            exit;
        if GetDescriptionFromSalesLine(PurchaseLine, SalesLine) then
            exit;
        if GetDescriptionFromItemVariant(PurchaseLine, SalesLine, Item) then
            exit;
        GetDescriptionFromItem(PurchaseLine, Item);
    end;

    local procedure GetDescriptionFromItemCrossReference(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line"; Item: Record Item): Boolean
    var
        ItemCrossRef: Record "Item Cross Reference";
    begin
        if PurchHeader."Buy-from Vendor No." <> '' then
            exit(
              ItemCrossRef.GetItemDescription(
                PurchaseLine.Description, PurchaseLine."Description 2", Item."No.", SalesLine."Variant Code",
                SalesLine."Unit of Measure Code", ItemCrossRef."Cross-Reference Type"::Vendor, PurchHeader."Buy-from Vendor No."));
    end;

    local procedure GetDescriptionFromItemTranslation(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line"): Boolean
    var
        Vend: Record Vendor;
        ItemTranslation: Record "Item Translation";
    begin
        if PurchHeader."Buy-from Vendor No." <> '' then begin
            Vend.Get(PurchHeader."Buy-from Vendor No.");
            if Vend."Language Code" <> '' then
                if ItemTranslation.Get(SalesLine."No.", SalesLine."Variant Code", Vend."Language Code") then begin
                    PurchaseLine.Description := ItemTranslation.Description;
                    PurchaseLine."Description 2" := ItemTranslation."Description 2";
                    OnGetDescriptionFromItemTranslation(PurchaseLine, ItemTranslation);
                    exit(true);
                end;
        end;
        exit(false)
    end;

    local procedure GetDescriptionFromItemVariant(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line"; Item: Record Item): Boolean
    var
        ItemVariant: Record "Item Variant";
    begin
        if SalesLine."Variant Code" <> '' then begin
            ItemVariant.Get(Item."No.", SalesLine."Variant Code");
            PurchaseLine.Description := ItemVariant.Description;
            PurchaseLine."Description 2" := ItemVariant."Description 2";
            OnGetDescriptionFromItemVariant(PurchaseLine, ItemVariant);
            exit(true);
        end;
        exit(false)
    end;

    local procedure GetDescriptionFromItem(var PurchaseLine: Record "Purchase Line"; Item: Record Item)
    begin
        PurchaseLine.Description := Item.Description;
        PurchaseLine."Description 2" := Item."Description 2";
        OnGetDescriptionFromItem(PurchaseLine, Item);
    end;

    local procedure GetDescriptionFromSalesLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line"): Boolean
    begin
        if (SalesLine.Description <> '') or (SalesLine."Description 2" <> '') then begin
            PurchaseLine.Description := SalesLine.Description;
            PurchaseLine."Description 2" := SalesLine."Description 2";
            OnGetDescriptionFromSalesLine(PurchaseLine, SalesLine);
            exit(true);
        end;
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseLineInsert(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineModify(var SalesLine: Record "Sales Line"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseLineInsert(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeModify(var PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeSelectSalesHeader(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDescriptionFromItemTranslation(var PurchaseLine: Record "Purchase Line"; ItemTranslation: Record "Item Translation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDescriptionFromItemVariant(var PurchaseLine: Record "Purchase Line"; ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDescriptionFromItem(var PurchaseLine: Record "Purchase Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDescriptionFromSalesLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
    end;
}

