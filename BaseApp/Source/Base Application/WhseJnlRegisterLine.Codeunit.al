codeunit 7301 "Whse. Jnl.-Register Line"
{
    Permissions = TableData "Warehouse Entry" = imd,
                  TableData "Warehouse Register" = imd;
    TableNo = "Warehouse Journal Line";

    trigger OnRun()
    begin
        RegisterWhseJnlLine(Rec);
    end;

    var
        Location: Record Location;
        WhseJnlLine: Record "Warehouse Journal Line";
        Item: Record Item;
        Bin: Record Bin;
        WhseReg: Record "Warehouse Register";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WMSMgt: Codeunit "WMS Management";
        WhseEntryNo: Integer;
        Text000: Label 'is not sufficient to complete this action. The quantity in the bin is %1. %2 units are not available', Comment = '%1 = the value of the Quantity that is in the bin; %2 = the value of the Quantity that is not available.';
        Text001: Label 'Serial No. %1 is found in inventory .';
        OnMovement: Boolean;

    local procedure "Code"()
    var
        GlobalWhseEntry: Record "Warehouse Entry";
    begin
        OnBeforeCode(WhseJnlLine);

        with WhseJnlLine do begin
            if ("Qty. (Absolute)" = 0) and ("Qty. (Base)" = 0) and (not "Phys. Inventory") then
                exit;
            TestField("Item No.");
            GetLocation("Location Code");
            if WhseEntryNo = 0 then begin
                GlobalWhseEntry.LockTable();
                WhseEntryNo := GlobalWhseEntry.GetLastEntryNo();
            end;
            OnMovement := false;
            if "From Bin Code" <> '' then begin
                InitWhseEntry(GlobalWhseEntry, "From Zone Code", "From Bin Code", -1);
                if "To Bin Code" <> '' then begin
                    InsertWhseEntry(GlobalWhseEntry);
                    OnMovement := true;
                    InitWhseEntry(GlobalWhseEntry, "To Zone Code", "To Bin Code", 1);
                end;
            end else
                InitWhseEntry(GlobalWhseEntry, "To Zone Code", "To Bin Code", 1);

            InsertWhseEntry(GlobalWhseEntry);
        end;

        OnAfterCode(WhseJnlLine);
    end;

    local procedure InitWhseEntry(var WhseEntry: Record "Warehouse Entry"; ZoneCode: Code[10]; BinCode: Code[20]; Sign: Integer)
    var
        ToBinContent: Record "Bin Content";
        WMSMgt: Codeunit "WMS Management";
    begin
        WhseEntryNo := WhseEntryNo + 1;

        with WhseJnlLine do begin
            WhseEntry.Init();
            WhseEntry."Entry No." := WhseEntryNo;
            WhseEntryNo := WhseEntry."Entry No.";
            WhseEntry."Journal Template Name" := "Journal Template Name";
            WhseEntry."Journal Batch Name" := "Journal Batch Name";
            if "Entry Type" <> "Entry Type"::Movement then begin
                if Sign >= 0 then
                    WhseEntry."Entry Type" := WhseEntry."Entry Type"::"Positive Adjmt."
                else
                    WhseEntry."Entry Type" := WhseEntry."Entry Type"::"Negative Adjmt.";
            end else
                WhseEntry."Entry Type" := "Entry Type";
            WhseEntry."Line No." := "Line No.";
            WhseEntry."Whse. Document No." := "Whse. Document No.";
            WhseEntry."Whse. Document Type" := "Whse. Document Type";
            WhseEntry."Whse. Document Line No." := "Whse. Document Line No.";
            WhseEntry."No. Series" := "Registering No. Series";
            WhseEntry."Location Code" := "Location Code";
            WhseEntry."Zone Code" := ZoneCode;
            WhseEntry."Bin Code" := BinCode;
            GetBin("Location Code", BinCode);
            WhseEntry.Dedicated := Bin.Dedicated;
            WhseEntry."Bin Type Code" := Bin."Bin Type Code";
            WhseEntry."Item No." := "Item No.";
            WhseEntry.Description := GetItemDescription("Item No.", Description);
            if Location."Directed Put-away and Pick" then begin
                WhseEntry.Quantity := "Qty. (Absolute)" * Sign;
                WhseEntry."Unit of Measure Code" := "Unit of Measure Code";
                WhseEntry."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            end else begin
                WhseEntry.Quantity := "Qty. (Absolute, Base)" * Sign;
                WhseEntry."Unit of Measure Code" := WMSMgt.GetBaseUOM("Item No.");
                WhseEntry."Qty. per Unit of Measure" := 1;
            end;
            WhseEntry."Qty. (Base)" := "Qty. (Absolute, Base)" * Sign;
            WhseEntry."Registering Date" := "Registering Date";
            WhseEntry."User ID" := "User ID";
            WhseEntry."Variant Code" := "Variant Code";
            WhseEntry."Source Type" := "Source Type";
            WhseEntry."Source Subtype" := "Source Subtype";
            WhseEntry."Source No." := "Source No.";
            WhseEntry."Source Line No." := "Source Line No.";
            WhseEntry."Source Subline No." := "Source Subline No.";
            WhseEntry."Source Document" := "Source Document";
            WhseEntry."Reference Document" := "Reference Document";
            WhseEntry."Reference No." := "Reference No.";
            WhseEntry."Source Code" := "Source Code";
            WhseEntry."Reason Code" := "Reason Code";
            WhseEntry.Cubage := Cubage * Sign;
            WhseEntry.Weight := Weight * Sign;
            WhseEntry.CopyTrackingFromWhseJnlLine(WhseJnlLine);
            WhseEntry."Expiration Date" := "Expiration Date";
            if OnMovement and ("Entry Type" = "Entry Type"::Movement) then begin
                if "New Serial No." <> '' then
                    WhseEntry."Serial No." := "New Serial No.";
                if "New Lot No." <> '' then
                    WhseEntry."Lot No." := "New Lot No.";
                if ("New Expiration Date" <> "Expiration Date") and (WhseEntry."Entry Type" = WhseEntry."Entry Type"::Movement) then
                    WhseEntry."Expiration Date" := "New Expiration Date";
            end;
            WhseEntry."Warranty Date" := "Warranty Date";
            WhseEntry."Phys Invt Counting Period Code" := "Phys Invt Counting Period Code";
            WhseEntry."Phys Invt Counting Period Type" := "Phys Invt Counting Period Type";

            OnInitWhseEntryCopyFromWhseJnlLine(WhseEntry, WhseJnlLine, OnMovement, Sign);

            if Sign > 0 then begin
                if BinCode <> Location."Adjustment Bin Code" then begin
                    if not ToBinContent.Get(
                         "Location Code", BinCode, "Item No.", "Variant Code", "Unit of Measure Code")
                    then
                        InsertToBinContent(WhseEntry)
                    else
                        if Location."Default Bin Selection" = Location."Default Bin Selection"::"Last-Used Bin" then
                            UpdateDefaultBinContent("Item No.", "Variant Code", "Location Code", BinCode);
                end
            end else begin
                if BinCode <> Location."Adjustment Bin Code" then
                    DeleteFromBinContent(WhseEntry);
            end;
        end;
    end;

    local procedure DeleteFromBinContent(var WhseEntry: Record "Warehouse Entry")
    var
        FromBinContent: Record "Bin Content";
        WhseEntry2: Record "Warehouse Entry";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        Sign: Integer;
        IsHandled: Boolean;
    begin
        with WhseEntry do begin
            FromBinContent.Get("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
            ItemTrackingMgt.GetWhseItemTrkgSetup(FromBinContent."Item No.", WhseItemTrackingSetup);
            if WhseItemTrackingSetup."Lot No. Required" then
                FromBinContent.SetRange("Lot No. Filter", "Lot No.");
            if WhseItemTrackingSetup."Serial No. Required" then
                FromBinContent.SetRange("Serial No. Filter", "Serial No.");
            OnDeleteFromBinContentOnAfterSetFiltersForBinContent(FromBinContent, WhseEntry);
            FromBinContent.CalcFields("Quantity (Base)", "Positive Adjmt. Qty. (Base)", "Put-away Quantity (Base)");
            if FromBinContent."Quantity (Base)" + "Qty. (Base)" = 0 then begin
                WhseEntry2.SetCurrentKey(
                  "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code");
                WhseEntry2.SetRange("Item No.", "Item No.");
                WhseEntry2.SetRange("Bin Code", "Bin Code");
                WhseEntry2.SetRange("Location Code", "Location Code");
                WhseEntry2.SetRange("Variant Code", "Variant Code");
                WhseEntry2.SetRange("Unit of Measure Code", "Unit of Measure Code");
                if WhseItemTrackingSetup."Lot No. Required" then
                    WhseEntry2.SetRange("Lot No.", "Lot No.");
                if WhseItemTrackingSetup."Serial No. Required" then
                    WhseEntry2.SetRange("Serial No.", "Serial No.");
                OnDeleteFromBinContentOnAfterSetFiltersForWhseEntry(WhseEntry2, FromBinContent, WhseEntry);
                WhseEntry2.CalcSums(Cubage, Weight, "Qty. (Base)");
                Cubage := -WhseEntry2.Cubage;
                Weight := -WhseEntry2.Weight;
                if WhseEntry2."Qty. (Base)" + "Qty. (Base)" <> 0 then
                    RegisterRoundResidual(WhseEntry, WhseEntry2);

                FromBinContent.SetRange("Lot No. Filter");
                FromBinContent.SetRange("Serial No. Filter");
                FromBinContent.CalcFields("Quantity (Base)");
                if FromBinContent."Quantity (Base)" + "Qty. (Base)" = 0 then
                    if (FromBinContent."Positive Adjmt. Qty. (Base)" = 0) and
                       (FromBinContent."Put-away Quantity (Base)" = 0) and
                       (not FromBinContent.Fixed)
                    then begin
                        OnDeleteFromBinContentOnBeforeFromBinContentDelete(FromBinContent);
                        FromBinContent.Delete();
                    end;
            end else begin
                OnDeleteFromBinContentOnBeforeCheckQuantity(FromBinContent, WhseEntry);
                FromBinContent.CalcFields(Quantity);
                if FromBinContent.Quantity + Quantity = 0 then begin
                    "Qty. (Base)" := -FromBinContent."Quantity (Base)";
                    Sign := WhseJnlLine."Qty. (Base)" / WhseJnlLine."Qty. (Absolute, Base)";
                    WhseJnlLine."Qty. (Base)" := "Qty. (Base)" * Sign;
                    WhseJnlLine."Qty. (Absolute, Base)" := Abs("Qty. (Base)");
                end else
                    if FromBinContent."Quantity (Base)" + "Qty. (Base)" < 0 then begin
                        IsHandled := false;
                        OnDeleteFromBinContentOnBeforeFieldError(FromBinContent, WhseEntry, IsHandled);
                        if not IsHandled then
                            FromBinContent.FieldError(
                              "Quantity (Base)",
                              StrSubstNo(Text000, FromBinContent."Quantity (Base)", -(FromBinContent."Quantity (Base)" + "Qty. (Base)")));
                    end;
            end;
        end;
    end;

    local procedure RegisterRoundResidual(var WhseEntry: Record "Warehouse Entry"; WhseEntry2: Record "Warehouse Entry")
    var
        WhseJnlLine2: Record "Warehouse Journal Line";
        WhseJnlRegLine: Codeunit "Whse. Jnl.-Register Line";
    begin
        with WhseEntry do begin
            WhseJnlLine2 := WhseJnlLine;
            GetBin(WhseJnlLine2."Location Code", Location."Adjustment Bin Code");
            WhseJnlLine2.Quantity := 0;
            WhseJnlLine2."Qty. (Base)" := WhseEntry2."Qty. (Base)" + "Qty. (Base)";
            if WhseEntry2."Qty. (Base)" > Abs("Qty. (Base)") then begin
                WhseJnlLine2."To Zone Code" := Bin."Zone Code";
                WhseJnlLine2."To Bin Code" := Bin.Code;
            end else begin
                WhseJnlLine2."To Zone Code" := WhseJnlLine2."From Zone Code";
                WhseJnlLine2."To Bin Code" := WhseJnlLine2."From Bin Code";
                WhseJnlLine2."From Zone Code" := Bin."Zone Code";
                WhseJnlLine2."From Bin Code" := Bin.Code;
                WhseJnlLine2."Qty. (Base)" := -WhseJnlLine2."Qty. (Base)";
            end;
            WhseJnlLine2."Qty. (Absolute)" := 0;
            WhseJnlLine2."Qty. (Absolute, Base)" := Abs(WhseJnlLine2."Qty. (Base)");
            WhseJnlRegLine.SetWhseRegister(WhseReg);
            WhseJnlRegLine.Run(WhseJnlLine2);
            WhseJnlRegLine.GetWhseRegister(WhseReg);
            WhseEntryNo := WhseReg."To Entry No." + 1;
            "Entry No." := WhseReg."To Entry No." + 1;
        end;
    end;

    local procedure InsertWhseEntry(var WhseEntry: Record "Warehouse Entry")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ExistingExpDate: Date;
        IsHandled: Boolean;
    begin
        with WhseEntry do begin
            GetItem("Item No.");
            if ItemTrackingCode.Get(Item."Item Tracking Code") then
                if ("Serial No." <> '') and
                   ("Bin Code" <> Location."Adjustment Bin Code") and
                   (Quantity > 0) and
                   ItemTrackingCode."SN Specific Tracking"
                then begin
                    IsHandled := false;
                    OnInsertWhseEntryOnBeforeCheckSerialNo(WhseEntry, IsHandled);
                    if not IsHandled then
                        if WMSMgt.SerialNoOnInventory("Location Code", "Item No.", "Variant Code", "Serial No.") then
                            Error(Text001, "Serial No.");
                end;

            if ItemTrackingCode."Man. Expir. Date Entry Reqd." and ("Entry Type" = "Entry Type"::"Positive Adjmt.")
               and (ItemTrackingCode."Lot Warehouse Tracking" or ItemTrackingCode."SN Warehouse Tracking")
            then begin
                TestField("Expiration Date");
                ItemTrackingMgt.GetWhseExpirationDate("Item No.", "Variant Code", Location, "Lot No.", "Serial No.", ExistingExpDate);
                if (ExistingExpDate <> 0D) and ("Expiration Date" <> ExistingExpDate) then
                    TestField("Expiration Date", ExistingExpDate)
            end;

            OnBeforeInsertWhseEntry(WhseEntry);
            Insert;
            InsertWhseReg("Entry No.");
            UpdateBinEmpty(WhseEntry);
        end;

        OnAfterInsertWhseEntry(WhseEntry);
    end;

    local procedure UpdateBinEmpty(NewWarehouseEntry: Record "Warehouse Entry")
    var
        WarehouseEntry: Record "Warehouse Entry";
        IsHandled: Boolean;
    begin
        OnBeforeUpdateBinEmpty(NewWarehouseEntry, Bin, IsHandled);
        if IsHandled then
            exit;

        with NewWarehouseEntry do
            if Quantity > 0 then
                ModifyBinEmpty(false)
            else begin
                WarehouseEntry.SetCurrentKey("Bin Code", "Location Code");
                WarehouseEntry.SetRange("Bin Code", "Bin Code");
                WarehouseEntry.SetRange("Location Code", "Location Code");
                WarehouseEntry.CalcSums("Qty. (Base)");
                ModifyBinEmpty(WarehouseEntry."Qty. (Base)" = 0);
            end;
    end;

    local procedure ModifyBinEmpty(NewEmpty: Boolean)
    begin
        if Bin.Empty <> NewEmpty then begin
            Bin.Empty := NewEmpty;
            Bin.Modify();
        end;
    end;

    local procedure InsertToBinContent(WhseEntry: Record "Warehouse Entry")
    var
        BinContent: Record "Bin Content";
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        with WhseEntry do begin
            GetBin("Location Code", "Bin Code");
            BinContent.Init();
            BinContent."Location Code" := "Location Code";
            BinContent."Zone Code" := "Zone Code";
            BinContent."Bin Code" := "Bin Code";
            BinContent.Dedicated := Bin.Dedicated;
            BinContent."Bin Type Code" := Bin."Bin Type Code";
            BinContent."Block Movement" := Bin."Block Movement";
            BinContent."Bin Ranking" := Bin."Bin Ranking";
            BinContent."Cross-Dock Bin" := Bin."Cross-Dock Bin";
            BinContent."Warehouse Class Code" := Bin."Warehouse Class Code";
            BinContent."Item No." := "Item No.";
            BinContent."Variant Code" := "Variant Code";
            BinContent."Unit of Measure Code" := "Unit of Measure Code";
            BinContent."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            BinContent.Fixed := WhseIntegrationMgt.IsOpenShopFloorBin("Location Code", "Bin Code");
            if not Location."Directed Put-away and Pick" then begin
                if WMSMgt.CheckDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code") then begin
                    if Location."Default Bin Selection" = Location."Default Bin Selection"::"Last-Used Bin" then begin
                        DeleteDefaultBinContent("Item No.", "Variant Code", "Location Code");
                        BinContent.Default := true;
                    end
                end else
                    BinContent.Default := true;
                BinContent.Fixed := BinContent.Default;
            end;
            OnBeforeBinContentInsert(BinContent, WhseEntry);
            BinContent.Insert();
        end;
    end;

    local procedure UpdateDefaultBinContent(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20])
    var
        BinContent: Record "Bin Content";
        BinContent2: Record "Bin Content";
    begin
        BinContent.SetCurrentKey(Default);
        BinContent.SetRange(Default, true);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        if BinContent.FindFirst then
            if BinContent."Bin Code" <> BinCode then begin
                BinContent.Default := false;
                OnUpdateDefaultBinContentOnBeforeBinContentModify(BinContent);
                BinContent.Modify();
            end;

        if BinContent."Bin Code" <> BinCode then begin
            BinContent2.SetRange("Location Code", LocationCode);
            BinContent2.SetRange("Item No.", ItemNo);
            BinContent2.SetRange("Variant Code", VariantCode);
            BinContent2.SetRange("Bin Code", BinCode);
            BinContent2.FindFirst;
            BinContent2.Default := true;
            BinContent2.Modify();
        end;
    end;

    local procedure DeleteDefaultBinContent(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetCurrentKey(Default);
        BinContent.SetRange(Default, true);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        if BinContent.FindFirst then begin
            BinContent.Default := false;
            BinContent.Modify();
        end;
    end;

    local procedure InsertWhseReg(WhseEntryNo: Integer)
    begin
        with WhseJnlLine do
            if WhseReg."No." = 0 then begin
                WhseReg.LockTable();
                if WhseReg.Find('+') then
                    WhseReg."No." := WhseReg."No." + 1
                else
                    WhseReg."No." := 1;
                WhseReg.Init();
                WhseReg."From Entry No." := WhseEntryNo;
                WhseReg."To Entry No." := WhseEntryNo;
                WhseReg."Creation Date" := Today;
                WhseReg."Creation Time" := Time;
                WhseReg."Journal Batch Name" := "Journal Batch Name";
                WhseReg."Source Code" := "Source Code";
                WhseReg."User ID" := UserId;
                WhseReg.Insert();
            end else begin
                if ((WhseEntryNo < WhseReg."From Entry No.") and (WhseEntryNo <> 0)) or
                   ((WhseReg."From Entry No." = 0) and (WhseEntryNo > 0))
                then
                    WhseReg."From Entry No." := WhseEntryNo;
                if WhseEntryNo > WhseReg."To Entry No." then
                    WhseReg."To Entry No." := WhseEntryNo;
                WhseReg.Modify();
            end;
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (Bin."Location Code" <> LocationCode) or
           (Bin.Code <> BinCode)
        then
            Bin.Get(LocationCode, BinCode);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    local procedure GetItemDescription(ItemNo: Code[20]; Description2: Text[100]): Text[100]
    begin
        GetItem(ItemNo);
        if Item.Description = Description2 then
            exit('');
        exit(Description2);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." <> ItemNo then
            Item.Get(ItemNo);
    end;

    procedure SetWhseRegister(WhseRegDef: Record "Warehouse Register")
    begin
        WhseReg := WhseRegDef;
    end;

    procedure GetWhseRegister(var WhseRegDef: Record "Warehouse Register")
    begin
        WhseRegDef := WhseReg;
    end;

    procedure RegisterWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        WhseJnlLine.Copy(WarehouseJournalLine);
        Code;
        WarehouseJournalLine := WhseJnlLine;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitWhseEntryCopyFromWhseJnlLine(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line"; OnMovement: Boolean; Sign: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertWhseEntry(var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBinContentInsert(var BinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWhseEntry(var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBinEmpty(WarehouseEntry: Record "Warehouse Entry"; Bin: Record Bin; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContentOnAfterSetFiltersForWhseEntry(var WarehouseEntry2: Record "Warehouse Entry"; var BinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContentOnAfterSetFiltersForBinContent(var BinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContentOnBeforeFieldError(BinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContentOnBeforeFromBinContentDelete(var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteFromBinContentOnBeforeCheckQuantity(var BinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertWhseEntryOnBeforeCheckSerialNo(WarehouseEntry: Record "Warehouse Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDefaultBinContentOnBeforeBinContentModify(var BinContent: Record "Bin Content")
    begin
    end;
}

