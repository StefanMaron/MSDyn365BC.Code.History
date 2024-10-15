Codeunit 18390 "GST Transfer Order Receipt"
{
    SingleInstance = True;
    [EventSubscriber(ObjectType::Table, Database::"Transfer Receipt Line", 'OnAfterCopyFromTransferLine', '', false, false)]
    local procedure CopyInfotoReceiptLine(var TransferReceiptLine: Record "Transfer Receipt Line"; TransferLine: Record "Transfer Line")
    var
        Location: Record Location;
    begin
        if not Location.Get(TransferLine."Transfer-from Code") then
            exit;
        if not Location."Bonded warehouse" then begin
            TransferReceiptLine."GST Group Code" := TransferLine."GST Group Code";
            TransferReceiptLine."GST Credit" := TransferLine."GST Credit";
            TransferReceiptLine."HSN/SAC Code" := TransferLine."HSN/SAC Code";
            TransferReceiptLine.Exempted := TransferLine.Exempted;
        end;
        TransferReceiptLine."Unit Price" := TransferLine."Transfer Price";
        TransferReceiptLine.Amount := TransferLine.Amount * TransferLine."Qty. to Receive" / TransferLine.Quantity;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeTransRcptHeaderInsert', '', false, false)]
    local procedure GetPostingNoSeries(TransferHeader: Record "Transfer Header"; var TransferReceiptHeader: Record "Transfer Receipt Header")
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeries: Code[20];
    begin
        NoSeries := GetTransferReceiptPostingNoSeries(TransferHeader);
        if NoSeries <> '' then begin
            TransferReceiptHeader."No. Series" := NoSeries;
            if TransferReceiptHeader."No. Series" <> '' then
                TransferReceiptHeader."No." := NoSeriesMgt.GetNextNo(
                    TransferReceiptHeader."No. Series",
                    TransferHeader."Posting Date",
                    true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeTransferOrderPostReceipt', '', false, false)]
    local procedure ClearBuffer(var TransferHeader: Record "Transfer Header")
    begin
        ClearAll();
        TransferBuffer[1].DeleteAll();
        GSTPostingBuffer[1].DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnPostItemOnBeforeUpdateUnitCost', '', False, False)]
    local procedure GetTranfsrePrice(GlobalItemLedgEntry: Record "Item Ledger Entry")
    begin
        if GlobalItemLedgEntry."Entry Type" = GlobalItemLedgEntry."Entry Type"::Transfer then
            TransferCost := GlobalItemLedgEntry."Cost Amount (Actual)"
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeTransRcptHeaderInsert', '', False, False)]
    local procedure SetTransferReceiptNo(var TransferReceiptHeader: Record "Transfer Receipt Header")
    begin
        TransReceiptHeaderNo := TransferReceiptHeader."No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterInsertTransRcptLine', '', False, False)]
    local procedure CeateGSTLedgerEntry(TransLine: Record "Transfer Line")
    var
        TransHeader: Record "Transfer Header";
        DocTransferType: Option TransferShpmnt,TransferReciept;
    begin
        TransHeader.Get(TransLine."Document No.");
        GSTTransferShipment.InsertDetailedGSTLedgEntryTransfer(
                TransLine, TransHeader,
                 TransReceiptHeaderNo,
                GenJnlPostLine.GetNextTransactionNo(), DocTransferType::TransferReciept);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterInsertTransRcptLine', '', False, False)]
    local procedure InsertTransferBuffer(TransLine: Record "Transfer Line"; var TransRcptLine: Record "Transfer Receipt Line")
    var
        TransRcptHeader: Record "Transfer Receipt Header";
    begin
        TransRcptHeader.Get(TransRcptLine."Document No.");
        PostRevaluationEntryGST(TransLine, TransRcptHeader, TransRcptLine);
        PostRevaluationEntryunrealizedProfit(TransLine, TransRcptHeader, TransRcptLine);
        FillTransferBuffer(TransLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeInsertTransRcptLine', '', False, False)]
    local procedure FillReceiptLine(var TransRcptLine: Record "Transfer Receipt Line"; TransLine: Record "Transfer Line")
    begin
        TransRcptLine."GST Group Code" := TransLine."GST Group Code";
        TransRcptLine."GST Credit" := TransLine."GST Credit";
        TransRcptLine."HSN/SAC Code" := TransLine."HSN/SAC Code";
        TransRcptLine.Exempted := TransLine.Exempted;
        TransRcptLine."Custom Duty Amount" := TransLine."Custom Duty Amount";
        TransRcptLine."GST Assessable Value" := TransLine."GST Assessable Value";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnCheckTransLine', '', False, False)]
    local procedure FillBuffers(TransferLine: Record "Transfer Line")
    var
        GSTGroup: Record "GST Group";
        DocTransactionType: Option Purchase,Sales,Transfer;
    begin
        if TransferLine.Quantity <> 0 then
            GSTAmountLoaded := Abs(RoundTotalGSTAmountLoadedQtyFactor(
              DocTransactionType::Transfer, 0,
              TransferLine."Document No.", TransferLine."Line No.", TransferLine."Qty. to Receive" / TransferLine.Quantity, ''));

        if GSTGroup.Get(TransferLine."GST Group Code") and (GSTGroup."GST Group Type" <> GSTGroup."GST Group Type"::Goods) then
            Error(GSTGroupServiceErr);

        if (TransferLine."Qty. to Receive" <> 0) and (GetGSTAmount(TransferLine.RecordId) <> 0) then
            FillGSTPostingBuffer(TransferLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeTransferOrderPostReceipt', '', False, False)]
    local procedure CheckGSTValidation(var TransferHeader: Record "Transfer Header")
    begin
        CheckValidations(TransferHeader);
        GSTTransferShipment.CheckGSTAccountingPeriod(TransferHeader."Posting Date");

        ClearAll();
        TransferBuffer[1].DeleteAll();
        GSTPostingBuffer[1].DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeTransRcptHeaderInsert', '', False, False)]
    local procedure CopyInfointoTransRcpttHeader(
        var TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferHeader: Record "Transfer Header")
    begin
        TransferReceiptHeader."Vendor Invoice No." := TransferHeader."Vendor Invoice No.";
        TransferReceiptHeader."Bill of Entry No." := TransferHeader."Bill of Entry No.";
        TransferReceiptHeader."Bill of Entry Date" := TransferHeader."Bill of Entry Date";
        TransferReceiptHeader."Vendor No." := TransferHeader."Vendor No.";
        TransferReceiptHeader."Distance (Km)" := TransferHeader."Distance (Km)";
        TransferReceiptHeader."Vehicle Type" := TransferHeader."Vehicle Type";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeTransRcptHeaderInsert', '', False, False)]
    local procedure FillGSTLedgerBuffer(TransferHeader: Record "Transfer Header")
    var
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
    begin
        TransferBuffer[1].DeleteAll();
        GSTPostingBuffer[1].DeleteAll();

        DetailedGSTEntryBuffer.SetRange("Document Type", DetailedGSTEntryBuffer."Document Type"::Quote);
        DetailedGSTEntryBuffer.SetRange("Transaction Type", DetailedGSTEntryBuffer."Transaction Type"::Transfer);
        DetailedGSTEntryBuffer.SetRange("Document No.", TransferHeader."No.");
        if DetailedGSTEntryBuffer.FindFirst() then
            DetailedGSTEntryBuffer.DeleteAll(true);

        FillDetailLedgBufferServTran(TransferHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeDeleteOneTransferHeader', '', False, False)]
    local procedure PostEntries(TransferHeader: Record "Transfer Header")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        SourcecodeSetup: Record "Source Code Setup";
        GenPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        CustomDutyBase: Boolean;
    begin
        SourcecodeSetup.Get();
        FirstExecution := True;
        //Post G/L Entries
        if TransferBuffer[1].FIND('+') then
            repeat
                //Goods in transit
                GenJnlLine.Init();
                GenJnlLine."Posting Date" := TransferHeader."Posting Date";
                GenJnlLine."Document Date" := TransferHeader."Posting Date";
                GenJnlLine."Document No." := TransReceiptHeaderNo;
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
                InventoryPostingSetup.Get(TransferHeader."In-Transit Code", TransferBuffer[1]."Inventory Posting Group");
                If Item.get(TransferBuffer[1]."Item No.") then
                    if item."HSN/SAC Code" <> '' then
                        InventoryPostingSetup.TestField("Unrealized Profit Account");
                if (TransferBuffer[1]."Gen. Bus. Posting Group" <> '') then
                    GenJnlLine."Account No." := GetIGSTImportAccountNo(TransferBuffer[1]."Location Code")
                else
                    GenJnlLine."Account No." := InventoryPostingSetup."Unrealized Profit Account";
                GenJnlLine."System-Created Entry" := TransferBuffer[1]."System-Created Entry";
                GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
                GenJnlLine."Gen. Bus. Posting Group" := TransferBuffer[1]."Gen. Bus. Posting Group";
                GenJnlLine."Gen. Prod. Posting Group" := TransferBuffer[1]."Gen. Prod. Posting Group";
                if (TransferBuffer[1]."Gen. Bus. Posting Group" <> '') then
                    GenJnlLine.Amount := (TransferBuffer[1]."GST Amount")
                else
                    GenJnlLine.Amount := -(TransferBuffer[1].Amount + TransferBuffer[1]."Charges Amount" + TransferBuffer[1]."GST Amount");
                GenJnlLine.Quantity := TransferBuffer[1].Quantity;
                GenJnlLine."Source Code" := SourcecodeSetup.Transfer;
                GenJnlLine."Source Code" := SourcecodeSetup.Transfer;
                GenJnlLine."Shortcut Dimension 1 Code" := TransferBuffer[1]."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := TransferBuffer[1]."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := TransferBuffer[1]."Dimension Set ID";
                GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                GenJnlLine."VAT Base Amount" := GenJnlLine.Amount;
                GenJnlLine.Description := STRSUBSTNO(Text13700Msg, TransReceiptHeaderNo);
                if (GenJnlLine.Amount <> 0) then
                    RunGenJnlPostLine(GenJnlLine);

                // Post GST to G/L entries from GST posting buffer.. GST Sales
                GSTPostingBufferforTransferDocument(CustomDutyBase, TransferHeader);
                // Post Unrealized Profit Account Entries
                if not (TransferBuffer[1]."Gen. Bus. Posting Group" <> '') then begin
                    GenJnlLine.Init();
                    GenJnlLine."Posting Date" := TransferHeader."Posting Date";
                    GenJnlLine."Document Date" := TransferHeader."Posting Date";
                    GenJnlLine."Document No." := TransReceiptHeaderNo;
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
                    InventoryPostingSetup.Get(TransferHeader."Transfer-to Code", TransferBuffer[1]."Inventory Posting Group");
                    If Item.get(TransferBuffer[1]."Item No.") then
                        if item."HSN/SAC Code" <> '' then
                            InventoryPostingSetup.TestField("Unrealized Profit Account");
                    if (TransferBuffer[1]."Gen. Bus. Posting Group" <> '') then
                        GenJnlLine."Account No." := GetIGSTImportAccountNo(TransferBuffer[1]."Location Code")
                    else
                        GenJnlLine."Account No." := InventoryPostingSetup."Unrealized Profit Account";
                    GenJnlLine."System-Created Entry" := TransferBuffer[1]."System-Created Entry";

                    if (TransferBuffer[1]."Gen. Bus. Posting Group" <> '') then
                        GenJnlLine.Amount := (TransferBuffer[1].Amount)
                    else
                        GenJnlLine.Amount := TransferBuffer[1].Amount;
                    GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
                    GenJnlLine."Source Code" := SourcecodeSetup.Transfer;
                    GenJnlLine."Gen. Bus. Posting Group" := TransferBuffer[1]."Gen. Bus. Posting Group";
                    GenJnlLine."Gen. Prod. Posting Group" := TransferBuffer[1]."Gen. Prod. Posting Group";
                    GenJnlLine."Shortcut Dimension 1 Code" := TransferBuffer[1]."Global Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := TransferBuffer[1]."Global Dimension 2 Code";
                    GenJnlLine."Dimension Set ID" := TransferBuffer[1]."Dimension Set ID";
                    GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                    GenJnlLine."VAT Base Amount" := GenJnlLine.Amount;
                    GenJnlLine.Description := STRSUBSTNO(Text13700Msg, TransReceiptHeaderNo);
                    if (GenJnlLine.Amount <> 0) then
                        RunGenJnlPostLine(GenJnlLine);
                end;

                // Amount loaded on inventory
                if (TransferBuffer[1]."Amount Loaded on Inventory" <> 0) OR (TransferBuffer[1]."GST Amount Loaded on Inventory" <> 0) then begin
                    GenJnlLine.Init();
                    GenJnlLine."Posting Date" := TransferHeader."Posting Date";
                    GenJnlLine."Document Date" := TransferHeader."Posting Date";
                    GenJnlLine."Document No." := TransReceiptHeaderNo;
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
                    GenPostingSetup.Get(TransferBuffer[1]."Gen. Bus. Posting Group", TransferBuffer[1]."Gen. Prod. Posting Group");
                    GenPostingSetup.TestField("Inventory Adjmt. Account");
                    if (TransferBuffer[1]."Gen. Bus. Posting Group" <> '') then
                        GenJnlLine."Account No." := TransferBuffer[1]."G/L Account"
                    else
                        GenJnlLine."Account No." := GenPostingSetup."Inventory Adjmt. Account";
                    GenJnlLine."System-Created Entry" := TransferBuffer[1]."System-Created Entry";
                    GenJnlLine.Amount := ABS(TransferBuffer[1]."Amount Loaded on Inventory" +
                      TransferBuffer[1]."GST Amount Loaded on Inventory");
                    GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
                    GenJnlLine."Gen. Bus. Posting Group" := TransferBuffer[1]."Gen. Bus. Posting Group";
                    GenJnlLine."Gen. Prod. Posting Group" := TransferBuffer[1]."Gen. Prod. Posting Group";
                    GenJnlLine."Source Code" := SourcecodeSetup.Transfer;
                    GenJnlLine."Shortcut Dimension 1 Code" := TransferBuffer[1]."Global Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := TransferBuffer[1]."Global Dimension 2 Code";
                    GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                    GenJnlLine."VAT Base Amount" := GenJnlLine.Amount;
                    GenJnlLine.Description := STRSUBSTNO(Text13700Msg, TransReceiptHeaderNo);
                    if (GenJnlLine.Amount <> 0) then
                        RunGenJnlPostLine(GenJnlLine);
                end;
                // Purchase Account posting
                if (TransferBuffer[1]."Gen. Bus. Posting Group" <> '') then begin
                    if not Item.Exempted then
                        TransferBuffer[1].TestField("GST Amount");
                    GSTPurchAccPosting(TransferHeader);
                end;
            until TransferBuffer[1].Next(-1) = 0;
        TransferBuffer[1].DeleteAll();
    end;

    local procedure PostRevaluationEntryGST(
        var TransLine3: Record "Transfer Line";
        TransRcptHeader2: Record "Transfer Receipt Header";
        TransRcptLine2: Record "Transfer Receipt Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        ItemReg: Record "Item Register";
        ItemLedgEntry: Record "Item Ledger Entry";
        AmtToLoad: Decimal;
        Ctr: Integer;
    begin
        if TransLine3."Qty. to Receive" = 0 then
            exit;

        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Revaluation Journal");

        ItemReg.FindLast();
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Location Code", "Posting Date", "Document No.", "Item No.");
        ItemLedgEntry.SetRange("Entry No.", ItemReg."From Entry No.", ItemReg."To Entry No.");
        ItemLedgEntry.SetRange("Location Code", TransRcptHeader2."Transfer-to Code");
        ItemLedgEntry.SetRange("Posting Date", TransRcptHeader2."Posting Date");
        ItemLedgEntry.SetRange("Document No.", TransRcptHeader2."No.");
        ItemLedgEntry.SetRange("Document Line No.", TransLine3."Line No.");
        ItemLedgEntry.SetRange("Item No.", TransLine3."Item No.");
        if ItemLedgEntry.FIND('-') then
            repeat
                AmtToLoad := GSTAmountLoaded + TransLine3."Custom Duty Amount";
                if AmtToLoad <> 0 then begin
                    ItemJnlLine.Init();
                    ItemJnlLine.Validate("Posting Date", TransRcptHeader2."Posting Date");
                    ItemJnlLine."Document Date" := TransRcptHeader2."Posting Date";
                    ItemJnlLine.Validate("Document No.", TransRcptHeader2."No.");
                    ItemJnlLine."External Document No." := TransRcptHeader2."External Document No.";
                    ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Transfer);
                    ItemJnlLine."Value Entry Type" := ItemJnlLine."Value Entry Type"::Revaluation;
                    ItemJnlLine.Validate("Item No.", TransRcptLine2."Item No.");
                    ItemJnlLine.Description := TransRcptLine2.Description;
                    ItemJnlLine."Inventory Posting Group" := TransRcptLine2."Inventory Posting Group";
                    ItemJnlLine."Gen. Prod. Posting Group" := TransLine3."Gen. Prod. Posting Group";
                    ItemJnlLine."Source Code" := SourceCodeSetup."Revaluation Journal";
                    ItemJnlLine.Validate("Applies-to Entry", ItemLedgEntry."Entry No.");
                    ItemJnlLine.Validate("Unit Cost (Revalued)", (ItemJnlLine."Unit Cost (Revalued)" + (AmtToLoad / TransRcptLine2.Quantity)));
                    ItemJnlLine.Description := STRSUBSTNO(Text13700Msg, TransRcptHeader2."No.");
                    ItemJnlLine."New Location Code" := TransRcptHeader2."Transfer-to Code";

                    Ctr := TempItemJnlLine."Line No." + 10000;
                    TempItemJnlLine.Init();
                    TempItemJnlLine.Transferfields(ItemJnlLine);
                    TempItemJnlLine."Line No." := Ctr;
                    if ItemLedgEntry."Lot No." <> '' then begin
                        CreateReservationEntryRevaluation(TransRcptHeader2, ItemLedgEntry, TransLine3);
                        ReserveTransLine.TransferTransferToItemJnlLine(
                          TransLine3, TempItemJnlLine, TempItemJnlLine.Quantity, "Transfer Direction"::Inbound);
                    end;
                    ItemJnlPostLine.Run(TempItemJnlLine);
                end;
            until ItemLedgEntry.Next() = 0;
    end;

    local procedure CreateReservationEntryRevaluation(
        TransferReceiptHeader: Record "Transfer Receipt Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferLine: Record "Transfer Line")
    var
        ReservationEntry: Record "Reservation Entry";
        EntryNo: Integer;
    begin
        if ReservationEntry.FindLast() then
            EntryNo := ReservationEntry."Entry No." + 1
        else
            EntryNo := 1;
        ReservationEntry.Init();
        ReservationEntry."Entry No." := EntryNo;
        ReservationEntry."Item No." := ItemLedgerEntry."Item No.";
        ReservationEntry."Location Code" := TransferReceiptHeader."Transfer-to Code";
        ReservationEntry.Quantity := ItemLedgerEntry.Quantity;
        ReservationEntry.Validate("Quantity (Base)", ItemLedgerEntry.Quantity);
        ReservationEntry."Reservation Status" := "Reservation Status"::Surplus;
        ReservationEntry."Source Type" := Database::"Transfer Line";
        ReservationEntry."Source Subtype" := 1;
        ReservationEntry."Source ID" := TransferLine."Document No.";
        ReservationEntry."Source Ref. No." := TransferLine."Line No.";
        ReservationEntry.Positive := true;
        ReservationEntry."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
        ReservationEntry."Lot No." := ItemLedgerEntry."Lot No.";
        ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot No.";
        ReservationEntry."Appl.-to Item Entry" := ItemLedgerEntry."Entry No.";
        ReservationEntry.Insert();
    end;

    local procedure FillDetailLedgBufferServTran(DocNo: Code[20])
    var
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
        TaxTypeSetup: Record "Tax Type Setup";
        TaxTransValue: Record "Tax Transaction value";
        Item: Record Item;
        Sign: Integer;
        LastEntryNo: Integer;
        DocumentType: Option Quote,Order,Invoice,"Credit Memo","Blanket Order","Return Order";
        TransactionType: Option Purchase,Sales,Transfer,Service,"Service Transfer",Production;
    begin
        // TODO: Can cause locking issues
        if DetailedGSTEntryBuffer.FindLast() then
            LastEntryNo := DetailedGSTEntryBuffer."Entry No." + 1
        else
            LastEntryNo := 1;

        TransferHeader.Get(DocNo);
        GeneralLedgerSetup.Get();
        Sign := GetSign(DocumentType::Quote, TransactionType::"Transfer");

        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);

        TransferLine.Reset();
        TransferLine.SetRange("Document No.", DocNo);
        if TransferLine.Findset() then
            repeat
                if TransferLine."Item No." <> '' then begin
                    TransferLine.TestField(Quantity);
                    item.Get(TransferLine."Item No.");
                    TaxTransValue.Reset();
                    TaxTransValue.SetRange("Tax Type", TaxTypeSetup.Code);
                    TaxTransValue.SetRange("Tax Record ID", TransferLine.RecordId);
                    TaxTransValue.SetRange("Value Type", TaxTransValue."Value Type"::COMPONENT);
                    TaxTransValue.SetFilter(Percent, '<>%1', 0);
                    if TaxTransValue.FindSet() then
                        repeat
                            DetailedGSTEntryBuffer.Init();
                            DetailedGSTEntryBuffer."Entry No." := LastEntryNo;
                            DetailedGSTEntryBuffer."Document Type" := DetailedGSTEntryBuffer."Document Type"::Quote;
                            DetailedGSTEntryBuffer."Document No." := TransferHeader."No.";
                            DetailedGSTEntryBuffer."Posting Date" := TransferHeader."Posting Date";
                            DetailedGSTEntryBuffer."Transaction Type" := DetailedGSTEntryBuffer."Transaction Type"::transfer;
                            DetailedGSTEntryBuffer.Type := DetailedGSTEntryBuffer.Type::Item;
                            DetailedGSTEntryBuffer.UOM := Item."Base Unit of Measure";
                            DetailedGSTEntryBuffer."No." := TransferLine."Item No.";
                            DetailedGSTEntryBuffer."Source No." := '';
                            DetailedGSTEntryBuffer.Quantity := TransferLine.Quantity * Sign;
                            DetailedGSTEntryBuffer."HSN/SAC Code" := TransferLine."HSN/SAC Code";
                            DetailedGSTEntryBuffer.Exempted := TransferLine.Exempted;
                            DetailedGSTEntryBuffer."Location Code" := TransferHeader."Transfer-from Code";
                            DetailedGSTEntryBuffer."Line No." := TransferLine."Line No.";
                            DetailedGSTEntryBuffer."Source Type" := "Source Type"::" ";
                            DetailedGSTEntryBuffer."GST Input/Output Credit Amount" := Sign * TaxTransValue.Amount;
                            DetailedGSTEntryBuffer."GST Base Amount" := Sign * TransferLine.Amount;
                            DetailedGSTEntryBuffer."GST %" := TaxTransValue.Percent;
                            DetailedGSTEntryBuffer."GST Rounding Precision" := GeneralLedgerSetup."GST Rounding Precision";
                            DetailedGSTEntryBuffer."GST Rounding Type" := GeneralLedgerSetup."GST Rounding Type";
                            DetailedGSTEntryBuffer."GST Inv. Rounding Precision" := GeneralLedgerSetup."GST Inv. Rounding Precision";
                            DetailedGSTEntryBuffer."GST Inv. Rounding Type" := GeneralLedgerSetup."GST Inv. Rounding Type";
                            DetailedGSTEntryBuffer."Currency Factor" := 1;
                            DetailedGSTEntryBuffer."GST Amount" := Sign * TaxTransValue.Amount;
                            DetailedGSTEntryBuffer."Custom Duty Amount" := TransferLine."Custom Duty Amount";
                            DetailedGSTEntryBuffer."GST Assessable Value" := TransferLine."GST Assessable Value";
                            if TransferLine."GST Credit" = TransferLine."GST Credit"::"Non-Availment" then begin
                                DetailedGSTEntryBuffer."Amount Loaded on Item" := Sign * TaxTransValue.Amount;
                                DetailedGSTEntryBuffer."Non-Availment" := true;
                            end else
                                DetailedGSTEntryBuffer."GST Input/Output Credit Amount" := Sign * TaxTransValue.Amount;
                            DetailedGSTEntryBuffer."GST Component Code" := GetGSTComponent(TaxTransValue."Value ID");
                            DetailedGSTEntryBuffer."GST Group Code" := TransferLine."GST Group Code";
                            if DetailedGSTEntryBuffer."Non-Availment" then begin
                                DetailedGSTEntryBuffer."GST Input/Output Credit Amount" := 0;
                                DetailedGSTEntryBuffer."Amount Loaded on Item" := TaxTransValue.Amount;
                            end;
                            DetailedGSTEntryBuffer.Insert();
                            LastEntryNo += 1;
                        until TaxTransValue.Next() = 0;
                end;
            until TransferLine.Next() = 0;
    end;

    local procedure CheckValidations(TransferHeader: Record "Transfer Header")
    var
        Location: Record Location;
        TransLine: Record "Transfer Line";
        GSTGroup: Record "GST Group";
    begin
        if not location.Get(TransferHeader."Transfer-from Code") then
            exit;
        if not Location."Bonded warehouse" then
            exit;

        TransLine.Reset();
        TransLine.SetRange("Document No.", TransferHeader."No.");
        TransLine.Setfilter(Quantity, '<>0');
        TransLine.SetRange("Derived From Line No.", 0);
        TransLine.Setfilter("Qty. to Receive", '<>0');
        if TransLine.Findset() then
            repeat
                if (GSTGroup.Get(TransLine."GST Group Code") and (GSTGroup."GST Group Type" <> GSTGroup."GST Group Type"::Goods))
                then
                    Error(GSTGroupServiceErr);
                if TransLine."GST Assessable Value" <> 0 then
                    Error(GSTAssessableErr);
                if (TransLine."Custom Duty Amount" <> 0) then
                    Error(GSTCustomDutyErr);
                TransLine.TestField("GST Assessable Value");
            until TransLine.Next() = 0;
        TransferHeader.TestField("Vendor No.");
        TransferHeader.TestField("Bill of Entry Date");
        TransferHeader.TestField("Bill of Entry No.");
    end;

    local procedure RoundTotalGSTAmountLoadedQtyFactor(
        TransactionType: Option Purchase,Sale,Transfer,Service;
        DocumentType: Option Quote,Order,Invoice,"Credit Memo","Blanket Order","Return Order";
        DocumentNo: Code[20];
        LineNo: Integer;
        QtyFactor: Decimal;
        CurrencyCode: Code[10]): Decimal
    var
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
        TotalGSTAmount: Decimal;
        Sign: Integer;
    begin
        DetailedGSTEntryBuffer.SetCurrentKey("Transaction Type", "Document Type", "Document No.", "Line No.");
        DetailedGSTEntryBuffer.SetRange("Transaction Type", TransactionType);
        DetailedGSTEntryBuffer.SetRange("Document Type", DocumentType);
        DetailedGSTEntryBuffer.SetRange("Document No.", DocumentNo);
        DetailedGSTEntryBuffer.SetRange("Line No.", LineNo);
        if DetailedGSTEntryBuffer.Findset() then
            repeat
                if DetailedGSTEntryBuffer."Amount Loaded on Item" <> 0 then
                    TotalGSTAmount += DetailedGSTEntryBuffer."Amount Loaded on Item" * QtyFactor;
                if CurrencyCode = '' then
                    TotalGSTAmount := RoundGSTPrecision(TotalGSTAmount);
            until DetailedGSTEntryBuffer.Next() = 0;

        if DocumentType IN [DocumentType::Order, DocumentType::Invoice, DocumentType::Quote, DocumentType::"Blanket Order"] then
            Sign := 1
        else
            if DocumentType IN [DocumentType::"Return Order", DocumentType::"Credit Memo"] then
                Sign := -1;

        if TransactionType = TransactionType::Purchase then
            Sign := Sign * 1
        else
            Sign := Sign * -1;

        exit(TotalGSTAmount * Sign);
    end;

    local procedure RoundGSTPrecision(GSTAmount: Decimal): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTRoundingDirection: Text[1];
        GSTRoundingPrecision: Decimal;
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("GST Rounding Precision");
        CASE GeneralLedgerSetup."GST Rounding Type" OF
            GeneralLedgerSetup."GST Rounding Type"::Nearest:
                GSTRoundingDirection := '=';
            GeneralLedgerSetup."GST Rounding Type"::Up:
                GSTRoundingDirection := '>';
            GeneralLedgerSetup."GST Rounding Type"::Down:
                GSTRoundingDirection := '<';
        end;
        GSTRoundingPrecision := GeneralLedgerSetup."GST Rounding Precision";
        exit(Round(GSTAmount, GSTRoundingPrecision, GSTRoundingDirection));
    end;

    local procedure FillGSTPostingBuffer(TransLine: Record "Transfer Line")
    var
        Location: Record Location;
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
        TransferHeader: Record "Transfer Header";
        QFactor: Decimal;
        GSTStateCode: Code[10];
    begin
        TransferHeader.Get(TransLine."Document No.");

        if not Location.Get(TransferHeader."Transfer-to Code") then
            exit;
        Location.TestField("State Code");
        GSTStateCode := Location."State Code";

        DetailedGSTEntryBuffer.Reset();
        DetailedGSTEntryBuffer.SetCurrentKey("Transaction Type", "Document Type", "Document No.", "Line No.");
        DetailedGSTEntryBuffer.SetRange("Transaction Type", DetailedGSTEntryBuffer."Transaction Type"::Transfer);
        DetailedGSTEntryBuffer.SetRange("Document Type", 0);
        DetailedGSTEntryBuffer.SetRange("Document No.", TransLine."Document No.");
        DetailedGSTEntryBuffer.SetRange("Line No.", TransLine."Line No.");
        DetailedGSTEntryBuffer.Setfilter("GST Base Amount", '<>%1', 0);
        if DetailedGSTEntryBuffer.Findset() then
            repeat
                GSTPostingBuffer[1].Type := GSTPostingBuffer[1].Type::Item;
                GSTPostingBuffer[1]."Global Dimension 1 Code" := TransLine."Shortcut Dimension 1 Code";
                GSTPostingBuffer[1]."Global Dimension 2 Code" := TransLine."Shortcut Dimension 2 Code";
                GSTPostingBuffer[1]."Gen. Prod. Posting Group" := TransLine."Gen. Prod. Posting Group";
                GSTPostingBuffer[1]."GST Group Code" := TransLine."GST Group Code";
                if (DetailedGSTEntryBuffer."GST Assessable Value" <> 0) OR (DetailedGSTEntryBuffer."Custom Duty Amount" <> 0) then
                    QFactor := 1
                else
                    QFactor := ABS(TransLine."Qty. to Receive" / TransLine.Quantity);
                GSTPostingBuffer[1]."GST Base Amount" := -RoundGSTPrecision(QFactor * DetailedGSTEntryBuffer."GST Base Amount");
                GSTPostingBuffer[1]."GST Amount" := -RoundGSTPrecision(QFactor * DetailedGSTEntryBuffer."GST Amount");
                GSTPostingBuffer[1]."GST %" := DetailedGSTEntryBuffer."GST %";
                GSTPostingBuffer[1]."GST Component Code" := DetailedGSTEntryBuffer."GST Component Code";
                GSTPostingBuffer[1]."Custom Duty Amount" := DetailedGSTEntryBuffer."Custom Duty Amount";
                if not DetailedGSTEntryBuffer."Non-Availment" then
                    GSTPostingBuffer[1]."Account No." := GetGSTReceivableAccountNo(GSTStateCode,
                      DetailedGSTEntryBuffer."GST Component Code")
                else
                    GSTPostingBuffer[1]."Account No." := '';
                UpdateGSTPostingBuffer(TransLine);
            until DetailedGSTEntryBuffer.Next() = 0;
    end;

    local procedure UpdateGSTPostingBuffer(TransLine: Record "Transfer Line")
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        GSTPostingBuffer[1]."Dimension Set ID" := TransLine."Dimension Set ID";
        DimMgt.UpdateGlobalDimFromDimSetID(GSTPostingBuffer[1]."Dimension Set ID",
          GSTPostingBuffer[1]."Global Dimension 1 Code", GSTPostingBuffer[1]."Global Dimension 2 Code");
        GSTPostingBuffer[2] := GSTPostingBuffer[1];
        if GSTPostingBuffer[2].Find() then begin
            GSTPostingBuffer[2]."GST Base Amount" += GSTPostingBuffer[1]."GST Base Amount";
            GSTPostingBuffer[2]."GST Amount" += GSTPostingBuffer[1]."GST Amount";
            GSTPostingBuffer[2]."Interim Amount" += GSTPostingBuffer[1]."Interim Amount";
            GSTPostingBuffer[2].Modify();
        end else
            GSTPostingBuffer[1].Insert();
    end;

    local procedure GetGSTReceivableAccountNo(LocationCode: Code[10]; GSTComponentCode: Code[10]): Code[20]
    var
        GSTPostingSetup: Record "GST Posting Setup";
    begin
        GSTPostingSetup.Reset();
        GSTPostingSetup.SetRange("State Code", LocationCode);
        GSTPostingSetup.SetRange("Component ID", GSTComponentID(GSTComponentCode));
        GSTPostingSetup.FindFirst();
        exit(GSTPostingSetup."Receivable Account")
    end;

    local procedure GetIGSTImportAccountNo(LocationCode: Code[10]): Code[20]
    var
        GSTPostingSetup: Record "GST Posting Setup";
    begin
        GSTPostingSetup.Reset();
        GSTPostingSetup.SetRange("State Code", LocationCode);
        GSTPostingSetup.SetRange("Component ID", GSTComponentID('IGST'));
        GSTPostingSetup.FindFirst();
        exit(GSTPostingSetup."IGST Payable A/c (Import)")
    end;

    local procedure GSTComponentID(ComponentCode: Code[10]): Integer
    var
        TaxTypeSetup: Record "Tax Type Setup";
        TaxComponent: Record "Tax Component";
    begin
        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);

        TaxComponent.SetRange("Tax Type", TaxTypeSetup.Code);
        TaxComponent.SetRange(Name, ComponentCode);
        if TaxComponent.FindFirst() then
            exit(TaxComponent.ID)
    end;

    local procedure GetSign(
        DocumentType: Option Quote,Order,Invoice,"Credit Memo","Blanket Order","Return Order";
        TransactionType: Option Purchase,Sales,Transfer,Service,"Service Transfer",Production) Sign: Integer
    begin
        if DocumentType IN [DocumentType::Order, DocumentType::Invoice, DocumentType::Quote, DocumentType::"Blanket Order"] then
            Sign := 1
        else
            Sign := -1;
        if TransactionType = TransactionType::Purchase then
            Sign := Sign * 1
        else
            Sign := Sign * -1;
        exit(Sign);
    end;

    local procedure GetGSTComponent(ComponentID: integer): Code[10]
    var
        TaxTypeSetup: Record "Tax Type Setup";
        TaxComponent: Record "Tax Component";
    begin
        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);

        TaxComponent.SetRange("Tax Type", TaxTypeSetup.Code);
        TaxComponent.SetRange(ID, ComponentID);
        if TaxComponent.FindFirst() then
            exit(TaxComponent.Name);
    end;

    local procedure GetGSTAmount(TaxRecordId: RecordId): Decimal
    var
        TaxTransValue: Record "Tax Transaction Value";
        TaxTypeSetup: Record "Tax Type Setup";
    begin
        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);

        TaxTransValue.Reset();
        TaxTransValue.SetRange("Tax Type", TaxTypeSetup.Code);
        TaxTransValue.SetRange("Tax Record ID", TaxRecordId);
        TaxTransValue.SetRange("Value Type", TaxTransValue."Value Type"::COMPONENT);
        TaxTransValue.SetFilter(Amount, '<>%1', 0);
        if TaxTransValue.FindFirst() then
            exit(TaxTransValue.Amount);
    end;

    local procedure GetGSTPer(TaxRecordId: RecordId): Decimal
    var
        TaxTransValue: Record "Tax Transaction Value";
        TaxTypeSetup: Record "Tax Type Setup";
    begin
        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);

        TaxTransValue.Reset();
        TaxTransValue.SetRange("Tax Type", TaxTypeSetup.Code);
        TaxTransValue.SetRange("Tax Record ID", TaxRecordId);
        TaxTransValue.SetRange("Value Type", TaxTransValue."Value Type"::COMPONENT);
        if TaxTransValue.FindFirst() then
            exit(TaxTransValue.Percent);
    end;

    local procedure FillTransferBuffer(TransLine: Record "Transfer Line")
    var
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
        BondedLocation: Record Location;
        TransHeader: Record "Transfer Header";
        DocTransactionType: Option Purchase,Sale,Transfer,Service;
    begin
        if TransLine."Qty. to Receive" = 0 then
            exit;

        TransHeader.Get(TransLine."Document No.");
        Clear(TransferBuffer[1]);

        BondedLocation.Get(TransHeader."Transfer-from Code");

        if (TransHeader."Vendor No." <> '') and
           (BondedLocation."Bonded warehouse") then begin
            Vendor.Get(TransHeader."Vendor No.");
            GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", TransLine."Gen. Prod. Posting Group");
            GeneralPostingSetup.TestField("Purch. Account");
            TransferBuffer[1]."Gen. Bus. Posting Group" := Vendor."Gen. Bus. Posting Group";
            TransferBuffer[1]."G/L Account" := GeneralPostingSetup."Purch. Account";
        end;

        TransferBuffer[1]."Gen. Prod. Posting Group" := TransLine."Gen. Prod. Posting Group";
        TransferBuffer[1]."System-Created Entry" := true;
        TransferBuffer[1]."Location Code" := TransLine."Transfer-to Code";
        TransferBuffer[1]."Item No." := TransLine."Item No.";
        TransferBuffer[1].Quantity := TransLine."Qty. to Receive";
        TransferBuffer[1]."Inventory Posting Group" := TransLine."Inventory Posting Group";
        TransferBuffer[1]."Global Dimension 1 Code" := TransLine."Shortcut Dimension 1 Code";
        TransferBuffer[1]."Global Dimension 2 Code" := TransLine."Shortcut Dimension 2 Code";
        TransferBuffer[1]."Dimension Set ID" := TransLine."Dimension Set ID";
        TransferBuffer[1]."Charges Amount" := TransLine."Charges to Transfer";
        TransferBuffer[1]."Amount Loaded on Inventory" := TransLine."Amount Added to Inventory";
        TransferBuffer[1].Amount := Round(TransLine.Amount - (-TransferCost));
        if BondedLocation."Bonded warehouse" then
            TransferBuffer[1]."GST Amount" := -Round(RoundTotalGSTAmountQtyFactor(DocTransactionType::Transfer, 0,
            TransLine."Document No.", TransLine."Line No.", TransLine."Qty. to Receive" / TransLine.Quantity, '', False))
        else
            TransferBuffer[1]."GST Amount" := Round(RoundTotalGSTAmountQtyFactor(DocTransactionType::Transfer, 0,
                TransLine."Document No.", TransLine."Line No.", TransLine."Qty. to Receive" / TransLine.Quantity, '', False));
        if TransLine."Custom Duty Amount" <> 0 then
            TransferBuffer[1]."Custom Duty Amount" := TransLine."Custom Duty Amount";
        if TransLine.Quantity <> 0 then
            TransferBuffer[1]."GST Amount Loaded on Inventory" := ABS(RoundTotalGSTAmountLoadedQtyFactor(
              DocTransactionType::Transfer, 0,
              TransLine."Document No.", TransLine."Line No.", TransLine."Qty. to Receive" / TransLine.Quantity, ''));
        GSTAmountLoaded := TransferBuffer[1]."GST Amount Loaded on Inventory";
        UpdTransferBuffer();
    end;

    local procedure RoundTotalGSTAmountQtyFactor(
        TransactionType: Option Purchase,Sale,Transfer,Service;
        DocumentType: Option Quote,Order,Invoice,"Credit Memo","Blanket Order","Return Order";
        DocumentNo: Code[20];
        LineNo: Integer;
        QtyFactor: Decimal;
        CurrencyCode: Code[10];
        GSTInvoiceRouding: Boolean): Decimal
    var
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
        TotalGSTAmount: Decimal;
        Sign: Integer;
    begin
        DetailedGSTEntryBuffer.SetCurrentKey("Transaction Type", "Document Type", "Document No.", "Line No.");
        DetailedGSTEntryBuffer.SetRange("Transaction Type", TransactionType);
        DetailedGSTEntryBuffer.SetRange("Document Type", DocumentType);
        DetailedGSTEntryBuffer.SetRange("Document No.", DocumentNo);
        DetailedGSTEntryBuffer.SetRange("Line No.", LineNo);
        if DetailedGSTEntryBuffer.Findset() then
            repeat
                if DetailedGSTEntryBuffer."Amount Loaded on Item" <> 0 then
                    TotalGSTAmount += DetailedGSTEntryBuffer."Amount Loaded on Item" * QtyFactor
                else
                    if DetailedGSTEntryBuffer."GST Input/Output Credit Amount" <> 0 then
                        TotalGSTAmount += DetailedGSTEntryBuffer."GST Input/Output Credit Amount" * QtyFactor;
                if CurrencyCode = '' then
                    if GSTInvoiceRouding then
                        TotalGSTAmount := RoundGSTInvoicePrecision(TotalGSTAmount, DetailedGSTEntryBuffer."Currency Code")
                    else
                        TotalGSTAmount := RoundGSTPrecision(TotalGSTAmount);
                if (CurrencyCode <> '') and GSTInvoiceRouding then
                    TotalGSTAmount := RoundGSTInvoicePrecision(TotalGSTAmount, DetailedGSTEntryBuffer."Currency Code");
            until DetailedGSTEntryBuffer.Next() = 0;

        if DocumentType IN [DocumentType::Order, DocumentType::Invoice, DocumentType::Quote, DocumentType::"Blanket Order"] then
            Sign := 1
        else
            if DocumentType IN [DocumentType::"Return Order", DocumentType::"Credit Memo"] then
                Sign := -1;
        if TransactionType = TransactionType::Purchase then
            Sign := Sign * 1
        else
            Sign := Sign * -1;

        exit(TotalGSTAmount * Sign);
    end;

    local procedure UpdTransferBuffer()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.UpdateGlobalDimFromDimSetID(TransferBuffer[1]."Dimension Set ID",
          TransferBuffer[1]."Global Dimension 1 Code", TransferBuffer[1]."Global Dimension 2 Code");

        TransferBuffer[2] := TransferBuffer[1];
        if TransferBuffer[2].FIND() then begin
            TransferBuffer[2].Amount := TransferBuffer[2].Amount + TransferBuffer[1].Amount;
            TransferBuffer[2]."Amount Loaded on Inventory" := TransferBuffer[2]."Amount Loaded on Inventory" +
              TransferBuffer[1]."Amount Loaded on Inventory";
            TransferBuffer[2]."Charges Amount" := TransferBuffer[2]."Charges Amount" + TransferBuffer[1]."Charges Amount";
            TransferBuffer[2].Quantity := TransferBuffer[2].Quantity + TransferBuffer[1].Quantity;
            TransferBuffer[2]."GST Amount" := TransferBuffer[2]."GST Amount" +
              TransferBuffer[1]."GST Amount";
            TransferBuffer[2]."GST Amount Loaded on Inventory" := TransferBuffer[2]."GST Amount Loaded on Inventory" +
              TransferBuffer[1]."GST Amount Loaded on Inventory";
            TransferBuffer[2]."Custom Duty Amount" := TransferBuffer[2]."Custom Duty Amount" +
              TransferBuffer[1]."Custom Duty Amount";
            if not TransferBuffer[1]."System-Created Entry" then
                TransferBuffer[2]."System-Created Entry" := False;
            TransferBuffer[2].Modify();
        end else
            TransferBuffer[1].Insert();
    end;

    local procedure RoundGSTInvoicePrecision(GSTAmount: Decimal; CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTRoundingDirection: Text[1];
        GSTRoundingPrecision: Decimal;
    begin
        if GSTAmount = 0 then
            exit(0);

        if CurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            if GeneralLedgerSetup."GST Inv. Rounding Precision" = 0 then
                exit;
            CASE GeneralLedgerSetup."GST Inv. Rounding Type" OF
                GeneralLedgerSetup."GST Inv. Rounding Type"::Nearest:
                    GSTRoundingDirection := '=';
                GeneralLedgerSetup."GST Inv. Rounding Type"::Up:
                    GSTRoundingDirection := '>';
                GeneralLedgerSetup."GST Inv. Rounding Type"::Down:
                    GSTRoundingDirection := '<';
            end;
            GSTRoundingPrecision := GeneralLedgerSetup."GST Inv. Rounding Precision";
        end else
            Currency.Get(CurrencyCode);
        exit(Round(GSTAmount, GSTRoundingPrecision, GSTRoundingDirection));
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure GSTPostingBufferforTransferDocument(CustomDutyBase: Boolean; Transheader: Record "Transfer Header")
    begin
        if FirstExecution then begin
            if GSTPostingBuffer[1].FindLast() then
                repeat
                    if (GSTPostingBuffer[1]."Custom Duty Amount" <> 0) and (not CustomDutyBase) then begin
                        CustomDutyBase := true;
                        GSTPostingBuffer[1]."Custom Duty Amount" := GetCustomDutyAmount(TransHeader."No.");
                        FillGenJnlLineForCustomDuty(TransHeader);
                    end;
                    PostTransLineToGenJnlLine(TransHeader);
                until GSTPostingBuffer[1].Next(-1) = 0;
            FirstExecution := False;
        end;
    end;

    local procedure GetCustomDutyAmount(DocumentNo: Code[20]) CustomDutyAmount: Decimal
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        TransferLine.Setfilter("Qty. to Receive", '<>%1', 0);
        TransferLine.Setfilter("Custom Duty Amount", '<>%1', 0);
        TransferLine.SetRange("Derived From Line No.", 0);
        if TransferLine.FindSet() then
            repeat
                CustomDutyAmount += TransferLine."Custom Duty Amount";
            until TransferLine.Next() = 0;
        exit(CustomDutyAmount);
    end;

    local procedure PostTransLineToGenJnlLine(TransferHeader: Record "Transfer Header");
    var
        SourceCodeSetup: Record "Source Code Setup";
        DocTransferType: Option TransferShpmnt,TransferReciept;
    begin
        GenJnlLine.Init();
        GenJnlLine."Posting Date" := TransferHeader."Posting Date";
        GenJnlLine.Description := STRSUBSTNO(Text13700Msg, TransReceiptHeaderNo);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
        GenJnlLine."Document No." := TransReceiptHeaderNo;
        GenJnlLine."External Document No." := TransferHeader."No.";
        if GSTPostingBuffer[1]."GST Amount" <> 0 then begin
            GenJnlLine.Validate(Amount, Round(GSTPostingBuffer[1]."GST Amount"));
            GenJnlLine."Account No." := GSTPostingBuffer[1]."Account No.";
        end;
        GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
        GenJnlLine."GST Group Code" := GSTPostingBuffer[1]."GST Group Code";
        GenJnlLine."GST Component Code" := GSTPostingBuffer[1]."GST Component Code";
        GenJnlLine."System-Created Entry" := TransferBuffer[1]."System-Created Entry";
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
        GenJnlLine."Gen. Bus. Posting Group" := GSTPostingBuffer[1]."Gen. Bus. Posting Group";
        GenJnlLine."Gen. Prod. Posting Group" := GSTPostingBuffer[1]."Gen. Prod. Posting Group";
        GenJnlLine."Shortcut Dimension 1 Code" := GSTPostingBuffer[1]."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := GSTPostingBuffer[1]."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := GSTPostingBuffer[1]."Dimension Set ID";
        GenJnlLine."Location Code" := TransferHeader."Transfer-to Code";
        SourceCodeSetup.Get();
        GenJnlLine."Source Code" := SourceCodeSetup.Transfer;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        if GSTPostingBuffer[1]."Account No." <> '' then
            RunGenJnlPostLine(GenJnlLine);
        GSTTransferShipment.InsertGSTLedgerEntryTransfer(
        GSTPostingBuffer[1], TransferHeader,
          GenJnlPostLine.GetNextTransactionNo(), GenJnlLine."Document No.",
          SourceCodeSetup.Transfer, DocTransferType::TransferReciept);
    end;

    local procedure GSTPurchAccPosting(TransferHader: Record "Transfer Header")
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();

        GenJnlLine.Init();
        GenJnlLine."Posting Date" := TransferHader."Posting Date";
        GenJnlLine."Document Date" := TransferHader."Posting Date";
        GenJnlLine."Document No." := TransReceiptHeaderNo;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
        GenJnlLine."Account No." := TransferBuffer[1]."G/L Account";
        GenJnlLine."System-Created Entry" := TransferBuffer[1]."System-Created Entry";
        GenJnlLine.Amount := TransferBuffer[1]."Custom Duty Amount";
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
        GenJnlLine."Source Code" := SourceCodeSetup.Transfer;
        GenJnlLine."Gen. Bus. Posting Group" := TransferBuffer[1]."Gen. Bus. Posting Group";
        GenJnlLine."Gen. Prod. Posting Group" := TransferBuffer[1]."Gen. Prod. Posting Group";
        GenJnlLine."Shortcut Dimension 1 Code" := TransferBuffer[1]."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := TransferBuffer[1]."Global Dimension 2 Code";
        GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
        GenJnlLine."VAT Base Amount" := GenJnlLine.Amount;
        GenJnlLine.Description := STRSUBSTNO(Text13700Msg, TransReceiptHeaderNo);
        if GenJnlLine.Amount <> 0 then
            RunGenJnlPostLine(GenJnlLine);
    end;

    local procedure FillGenJnlLineForCustomDuty(TransferHeader: Record "Transfer Header")
    var
        SourceCodeSetup: Record "Source Code Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SourceCodeSetup.Get();

        GenJournalLine.Init();
        GenJournalLine."Posting Date" := TransferHeader."Posting Date";
        GenJournalLine.Description := STRSUBSTNO(Text13700Msg, TransReceiptHeaderNo);
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Invoice;
        GenJournalLine."Document No." := TransReceiptHeaderNo;
        GenJournalLine."External Document No." := TransferHeader."No.";
        GenJournalLine."System-Created Entry" := true;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Account No." := GetIGSTImportAccountNo(TransferBuffer[1]."Location Code");
        GenJournalLine."Bal. Account No." := '';
        GenJournalLine.Validate(Amount, -Round(GSTPostingBuffer[1]."Custom Duty Amount"));
        GenJournalLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
        GenJournalLine."Gen. Bus. Posting Group" := GSTPostingBuffer[1]."Gen. Bus. Posting Group";
        GenJournalLine."Gen. Prod. Posting Group" := GSTPostingBuffer[1]."Gen. Prod. Posting Group";
        GenJournalLine."Shortcut Dimension 1 Code" := GSTPostingBuffer[1]."Global Dimension 1 Code";
        GenJournalLine."Shortcut Dimension 2 Code" := GSTPostingBuffer[1]."Global Dimension 2 Code";
        GenJournalLine."Dimension Set ID" := GSTPostingBuffer[1]."Dimension Set ID";
        GenJournalLine."Source Type" := GenJournalLine."Source Type"::Vendor;
        GenJournalLine."Source No." := TransferHeader."Vendor No.";
        GenJournalLine."Location Code" := TransferHeader."Transfer-from Code";
        GenJournalLine."Source Code" := SourceCodeSetup.Transfer;
        GenJournalLine."GST Component Code" := GSTPostingBuffer[1]."GST Component Code";
        GenJournalLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
        if (GenJournalLine.Amount <> 0) then
            RunGenJnlPostLine(GenJournalLine);
    end;

    local procedure PostRevaluationEntryunrealizedProfit(
        var TransferLine3: Record "Transfer Line";
        TransferReceiptHeader2: Record "Transfer Receipt Header";
        TransferReceiptLine2: Record "Transfer Receipt Line")
    var
        ValueEntry: Record "Value Entry";
        SourceCodeSetup: Record "Source Code Setup";
        ItemRegister: Record "Item Register";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        Location: Record Location;
        Ctr: Integer;
        TransferPriceDiff: Decimal;
        EntryNo: Integer;
        TotalTransferPriceDiff: Decimal;
        Amnt: Decimal;
        AmntUnitCost: Decimal;
    begin
        if TransferLine3."Qty. to Receive" = 0 then
            exit;

        Location.Get(TransferReceiptHeader2."Transfer-from Code");
        if Location."Bonded warehouse" then
            exit;

        TransferHeader.Get(TransferLine3."Document No.");
        if not TransferHeader."Load Unreal Prof Amt on Invt." then
            exit;

        Amnt := -TransferCost;
        RoundDiffAmt := TransferLine3.Amount - Amnt;
        TotalTransferPriceDiff := 0;

        ItemRegister.FindLast();
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetCurrentKey("Location Code", "Posting Date", "Document No.", "Item No.");
        ItemLedgerEntry.SetRange("Entry No.", ItemRegister."From Entry No.", ItemRegister."To Entry No.");
        ItemLedgerEntry.SetRange("Location Code", TransferReceiptHeader2."Transfer-to Code");
        ItemLedgerEntry.SetRange("Posting Date", TransferReceiptHeader2."Posting Date");
        ItemLedgerEntry.SetRange("Document No.", TransferReceiptHeader2."No.");
        ItemLedgerEntry.SetRange("Document Line No.", TransferLine3."Line No.");
        ItemLedgerEntry.SetRange("Item No.", TransferLine3."Item No.");
        if ItemLedgerEntry.FindLast() then
            EntryNo := ItemLedgerEntry."Entry No.";

        SourceCodeSetup.Get();

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetCurrentKey("Location Code", "Posting Date", "Document No.", "Item No.");
        ItemLedgerEntry.SetRange("Entry No.", ItemRegister."From Entry No.", ItemRegister."To Entry No.");
        ItemLedgerEntry.SetRange("Location Code", TransferReceiptHeader2."Transfer-to Code");
        ItemLedgerEntry.SetRange("Posting Date", TransferReceiptHeader2."Posting Date");
        ItemLedgerEntry.SetRange("Document No.", TransferReceiptHeader2."No.");
        ItemLedgerEntry.SetRange("Document Line No.", TransferLine3."Line No.");
        ItemLedgerEntry.SetRange("Item No.", TransferLine3."Item No.");
        if ItemLedgerEntry.Find('-') then
            repeat
                ValueEntry.Reset();
                ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
                ValueEntry.FindFirst();
                AmntUnitCost := ValueEntry."Cost Amount (Actual)" / ValueEntry."Item Ledger Entry Quantity";
                TransferPriceDiff := Round((TransferLine3."Transfer Price" / ItemLedgerEntry."Qty. per Unit of Measure") - AmntUnitCost);
                if TransferPriceDiff <> 0 then begin
                    TotalTransferPriceDiff += TransferPriceDiff * ItemLedgerEntry.Quantity;
                    if (EntryNo = ItemLedgerEntry."Entry No.") and (TotalTransferPriceDiff <> RoundDiffAmt) and
                       (ItemLedgerEntry."Lot No." = '')
                    then
                        TransferPriceDiff := TransferPriceDiff - (TotalTransferPriceDiff - RoundDiffAmt);
                    ItemJnlLine.Init();
                    ItemJnlLine.Validate("Posting Date", TransferReceiptHeader2."Posting Date");
                    ItemJnlLine."Document Date" := TransferReceiptHeader2."Posting Date";
                    ItemJnlLine.Validate("Document No.", TransferReceiptHeader2."No.");
                    ItemJnlLine."External Document No." := TransferReceiptHeader2."External Document No.";
                    ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Transfer);
                    ItemJnlLine."Value Entry Type" := ItemJnlLine."Value Entry Type"::Revaluation;
                    ItemJnlLine.Validate("Item No.", TransferReceiptLine2."Item No.");
                    ItemJnlLine.Description := TransferReceiptLine2.Description;
                    ItemJnlLine."Inventory Posting Group" := TransferReceiptLine2."Inventory Posting Group";
                    ItemJnlLine."Gen. Prod. Posting Group" := TransferLine3."Gen. Prod. Posting Group";
                    ItemJnlLine."Source Code" := SourceCodeSetup."Revaluation Journal";
                    ItemJnlLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
                    ItemJnlLine.Validate("Unit Cost (Revalued)", (ItemJnlLine."Unit Cost (Revalued)" + TransferPriceDiff));
                    ItemJnlLine.Description := STRSUBSTNO(Text13700Msg, TransferReceiptHeader2."No.");
                    ItemJnlLine."New Location Code" := TransferReceiptHeader2."Transfer-to Code";

                    Ctr := TempItemJnlLine."Line No." + 1;
                    TempItemJnlLine.Init();
                    TempItemJnlLine.Transferfields(ItemJnlLine);
                    TempItemJnlLine."Line No." := Ctr;
                    if ItemLedgerEntry."Lot No." <> '' then begin
                        CreateReservationEntryRevaluation(TransferReceiptHeader2, ItemLedgerEntry, TransferLine3);
                        ReserveTransLine.TransferTransferToItemJnlLine(
                          TransferLine3, TempItemJnlLine, TransferLine3."Qty. to Receive (Base)", "Transfer Direction"::Inbound);
                    end;
                    ItemJnlPostLine.Run(TempItemJnlLine);
                end;
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure GetTransferReceiptPostingNoSeries(var TansferHeader: Record "Transfer Header"): Code[20]
    var
        PostingNoSeries: Record "Posting No. Series";
        NoSeriesCode: Code[20];
    begin
        PostingNoSeries.SetRange("Table Id", Database::"Transfer Header");
        NoSeriesCode := GSTTransferShipment.LoopPostingNoSeries(
            PostingNoSeries,
            TansferHeader,
            PostingNoSeries."Document Type"::"Transfer Receipt Header");
        exit(NoSeriesCode);
    end;

    var
        GSTPostingBuffer: Array[2] of Record "GST Posting Buffer" Temporary;
        TransferBuffer: Array[2] of Record "Transfer Buffer" Temporary;
        GenJnlLine: Record "Gen. Journal Line";
        ItemJnlLine: Record "Item Journal Line";
        TempItemJnlLine: Record "Item Journal Line" temporary;
        GSTTransferShipment: Codeunit "GST Transfer order Shipment";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        RoundDiffAmt: Decimal;
        TransReceiptHeaderNo: Code[20];
        FirstExecution: Boolean;
        GSTAmountLoaded: Decimal;
        TransferCost: Decimal;
        GSTAssessableErr: Label 'GST Assessable Value must be 0 if GST Group Type is Service while transferring from Bonded Warehouse location.';
        GSTCustomDutyErr: Label 'Custom Duty Amount must be 0 if GST Group Type is Service while transferring from Bonded Warehouse location.';
        GSTGroupServiceErr: Label 'You cannot select GST Group Type Service for transfer.';
        Text13700Msg: Label 'Transfer - %1', Comment = '%1 = Transfer Receipt No.';

}