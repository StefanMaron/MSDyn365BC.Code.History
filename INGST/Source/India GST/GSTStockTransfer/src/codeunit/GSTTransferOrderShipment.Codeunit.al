Codeunit 18391 "GST Transfer Order Shipment"
{
    SingleInstance = True;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Line", 'OnAfterCopyFromTransferLine', '', false, false)]
    local procedure CopyInfotoShipmentLine(var TransferShipmentLine: Record "Transfer Shipment Line"; TransferLine: Record "Transfer Line")
    var
        Location: Record Location;
    begin
        If not Location.Get(TransferLine."Transfer-from Code") then
            exit;
        if not Location."Bonded warehouse" then begin
            TransferShipmentLine."GST Group Code" := TransferLine."GST Group Code";
            TransferShipmentLine."GST Credit" := TransferLine."GST Credit";
            TransferShipmentLine."HSN/SAC Code" := TransferLine."HSN/SAC Code";
            TransferShipmentLine.Exempted := TransferLine.Exempted;
        end;

        TransferShipmentLine."Unit Price" := TransferLine."Transfer Price";
        TransferShipmentLine.Amount := TransferLine.Amount * TransferLine."Qty. to Ship" / TransferLine.Quantity;
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"TransferOrder-Post Shipment", 'OnBeforeGenNextNo', '', false, false)]
    local procedure GetPostingNoSeries(TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header")
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
    begin
        NoSeriesCode := GetTransferShipmentPostingNoSeries(TransferHeader);
        if NoSeriesCode <> '' then begin
            TransferShipmentHeader."No. Series" := NoSeriesCode;
            TransferShipmentHeader."No." := NoSeriesMgt.GetNextNo(TransferShipmentHeader."No. Series", TransferHeader."Posting Date", true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"TransferOrder-Post Shipment", 'OnBeforeTransferOrderPostShipment', '', false, false)]
    local procedure ClearBuffer(var TransferHeader: Record "Transfer Header")
    begin
        CheckGSTAccountingPeriod(TransferHeader."Posting Date");

        ClearAll();
        TransferBuffer[1].Deleteall();
        GSTPostingBuffer[1].Deleteall();
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"TransferOrder-Post Shipment", 'OnAfterInsertTransShptLine', '', false, false)]
    local procedure InsertTransferBuffer(TransLine: Record "Transfer Line")
    begin
        FillTransferBuffer(TransLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"TransferOrder-Post Shipment", 'OnAfterInsertTransShptLine', '', false, false)]
    local procedure InsertDetailedGSTEntry(TransLine: Record "Transfer Line"; var TransShptLine: Record "Transfer Shipment Line")
    var
        TransferHeader: Record "Transfer Header";
        Location: Record Location;
        DocTransferType: option "Transfer Shipment","Transfer Receipt";
    begin
        TransferHeader.Get(TransLine."Document No.");
        Location.Get(TransferHeader."Transfer-from Code");
        if not Location."Bonded warehouse" then
            InsertDetailedGSTLedgEntryTransfer(
              TransLine, TransferHeader,
              TransShptLine."Document No.",
              GenJnlPostLine.GetNextTransactionNo(),
              DocTransferType::"Transfer Shipment");
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"TransferOrder-Post Shipment", 'OnRunOnBeforeCommit', '', false, false)]
    local procedure PostGLEntries(var TransferHeader: Record "Transfer Header"; TransferShipmentHeader: Record "Transfer Shipment Header")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Item: Record Item;
    begin
        // Post GST to G/L entries from GST posting buffer.. GST Sales
        GSTPostingBuffer[1].SetCurrentKey(
            "Transaction Type",
            Type,
            "Gen. Bus. Posting Group",
            "Gen. Prod. Posting Group",
            "GST Component Code",
            "GST Group Type",
            "Account No.",
            "Dimension Set ID",
            "GST Reverse Charge",
            Availment,
            "Normal Payment",
            "Forex Fluctuation",
            "Document Line No.");

        GSTPostingBuffer[1].SetAscEnding("Document Line No.", False);
        if GSTPostingBuffer[1].FindSet() then
            repeat
                PostTransLineToGenJnlLine(TransferHeader, TransferShipmentHeader."No.");
            until GSTPostingBuffer[1].Next() = 0;

        TransferBuffer[1].SetCurrentKey("sorting no.");
        TransferBuffer[1].SetAscEnding("Sorting No.", False);
        if TransferBuffer[1].FindSet() then
            repeat
                GenJnlLine.Init();
                GenJnlLine."Posting Date" := TransferHeader."Posting Date";
                GenJnlLine."Document Date" := TransferHeader."Posting Date";
                GenJnlLine."Document No." := TransferShipmentHeader."No.";
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
                InventoryPostingSetup.Get(TransferHeader."In-Transit Code", TransferBuffer[1]."Inventory Posting Group");
                If Item.get(TransferBuffer[1]."Item No.") then
                    if item."HSN/SAC Code" <> '' then
                        InventoryPostingSetup.TestField("Unrealized Profit Account");
                GenJnlLine."Account No." := InventoryPostingSetup."Unrealized Profit Account";
                GenJnlLine."System-Created Entry" := TransferBuffer[1]."System-Created Entry";
                GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
                GenJnlLine."Gen. Bus. Posting Group" := TransferBuffer[1]."Gen. Bus. Posting Group";
                GenJnlLine."Gen. Prod. Posting Group" := TransferBuffer[1]."Gen. Prod. Posting Group";
                GenJnlLine.Amount := TransferBuffer[1].Amount + TransferBuffer[1]."Charges Amount";
                GenJnlLine.Quantity := TransferBuffer[1].Quantity;
                GenJnlLine."Shortcut Dimension 1 Code" := TransferBuffer[1]."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := TransferBuffer[1]."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := TransferBuffer[1]."Dimension Set ID";
                GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                GenJnlLine."VAT Base Amount" := GenJnlLine.Amount;
                GenJnlLine.Description := STRSUBSTNO(Text13700Msg, TransferShipmentHeader."No.");
                if GenJnlLine.Amount <> 0 then
                    RunGenJnlPostLine(GenJnlLine);
            until TransferBuffer[1].Next() = 0;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnBeforeTransferOrderPostShipment', '', False, False)]
    local procedure FillGSTLedgerBuffer(var TransferHeader: Record "Transfer Header")
    var
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
    begin
        TransferBuffer[1].Deleteall();
        GSTPostingBuffer[1].Deleteall();

        DetailedGSTEntryBuffer.SetRange("Document Type", DetailedGSTEntryBuffer."Document Type"::Quote);
        DetailedGSTEntryBuffer.SetRange("Transaction Type", DetailedGSTEntryBuffer."Transaction Type"::Transfer);
        DetailedGSTEntryBuffer.SetRange("Document No.", TransferHeader."No.");
        if DetailedGSTEntryBuffer.FindFirst() then
            DetailedGSTEntryBuffer.DeleteAll(true);
        FillDetailLedgBufferServTran(TransferHeader."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Header", 'OnAfterCopyFromTransferHeader', '', False, False)]
    local procedure CopyInfointoTransShptHeader(TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        TransferShipmentHeader."Time of Removal" := TransferHeader."Time of Removal";
        TransferShipmentHeader."Vehicle No." := TransferHeader."Vehicle No.";
        TransferShipmentHeader."LR/RR No." := TransferHeader."LR/RR No.";
        TransferShipmentHeader."LR/RR Date" := TransferHeader."LR/RR Date";
        TransferShipmentHeader."Mode of Transport" := TransferHeader."Mode of Transport";
        TransferShipmentHeader."Distance (Km)" := TransferHeader."Distance (Km)";
        TransferShipmentHeader."Vehicle Type" := TransferHeader."Vehicle Type";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnBeforeInsertTransShptLine', '', False, False)]
    local procedure FillBuffer(var TransShptLine: Record "Transfer Shipment Line"; TransLine: Record "Transfer Line")
    var
        GSTGroup: Record "GST Group";
    begin
        if GSTGroup.Get(TransLine."GST Group Code") and (GSTGroup."GST Group Type" <> GSTGroup."GST Group Type"::Goods) then
            Error(GSTGroupServiceErr);

        if (TransLine."Qty. to Ship" <> 0) and (GetGSTAmount(TransLine.RecordId) <> 0) then
            FillGSTPostingBuffer(TransLine);
    end;

    procedure CheckGSTAccountingPeriod(PostingDate: Date)
    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
        TaxTypeSetup: Record "Tax Type Setup";
        LastClosedDate: Date;
    begin
        LastClosedDate := GetLastClosedSubAccPeriod();

        if not TaxTypeSetup.Get() then
            exit;
        TaxAccountingPeriod.SetRange("tax type Code", TaxTypeSetup.Code);
        TaxAccountingPeriod.SetFilter("Starting Date", '<=%1', PostingDate);
        if TaxAccountingPeriod.FindLast() then begin
            TaxAccountingPeriod.SetFilter("Starting Date", '>=%1', PostingDate);
            if not TaxAccountingPeriod.FindFirst() then
                Error(AccountingPeriodErr, PostingDate);
            if LastClosedDate <> 0D then
                if PostingDate < CalcDate('<1M>', LastClosedDate) then
                    Error(
                        PeriodClosedErr,
                        CalcDate('<-1D>', CalcDate('<1M>', LastClosedDate)),
                        CalcDate('<1M>', LastClosedDate));
            TaxAccountingPeriod.Get(TaxTypeSetup.Code, TaxAccountingPeriod."starting date");
        end else
            Error(AccountingPeriodErr, PostingDate);

        TaxAccountingPeriod.SetRange(Closed, False);
        TaxAccountingPeriod.SetFilter("Starting Date", '<=%1', PostingDate);
        if TaxAccountingPeriod.FindLast() then begin
            TaxAccountingPeriod.SetFilter("Starting Date", '>=%1', PostingDate);
            if not TaxAccountingPeriod.FindFirst() then
                if LastClosedDate <> 0D then
                    if PostingDate < CalcDate('<1M>', LastClosedDate) then
                        Error(
                            PeriodClosedErr,
                            CalcDate('<-1D>', CalcDate('<1M>', LastClosedDate)),
                            CalcDate('<1M>', LastClosedDate));

            TaxAccountingPeriod.TestField(Closed, False);
        end else
            if LastClosedDate <> 0D then
                if PostingDate < CalcDate('<1M>', LastClosedDate) then
                    Error(
                        PeriodClosedErr, CalcDate('<-1D>', CalcDate('<1M>', LastClosedDate)),
                        CalcDate('<1M>', LastClosedDate));
    end;

    local procedure FillDetailLedgBufferServTran(DocNo: Code[20])
    var
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
        TaxTypeSetup: Record "Tax Type Setup";
        TaxTransValue: Record "Tax Transaction Value";
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
        if TransferLine.FindSet() then
            repeat
                if TransferLine."Item No." <> '' then begin
                    TransferLine.TestField(Quantity);
                    Item.Get(TransferLine."Item No.");
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

    local procedure GetSign(DocumentType: Option Quote,Order,Invoice,"Credit Memo","Blanket Order","Return Order";
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

    local procedure FillTransferBuffer(TransLine: Record "Transfer Line")
    var
        Item: Record Item;
        BondedLocation: Record Location;
        TransHeader: Record "Transfer Header";
        DocTransactionType: Option Purchase,Sale,Transfer,Service;
    begin
        if TransLine."Qty. to Ship" = 0 then
            exit;

        TransHeader.Get(TransLine."Document No.");
        Clear(TransferBuffer[1]);

        BondedLocation.Get(TransHeader."Transfer-from Code");

        TransferBuffer[1]."System-Created Entry" := true;
        TransferBuffer[1]."Gen. Prod. Posting Group" := TransLine."Gen. Prod. Posting Group";
        TransferBuffer[1]."Global Dimension 1 Code" := TransLine."Shortcut Dimension 1 Code";
        TransferBuffer[1]."Global Dimension 2 Code" := TransLine."Shortcut Dimension 2 Code";
        TransferBuffer[1]."Dimension Set ID" := TransLine."Dimension Set ID";
        TransferBuffer[1]."Inventory Posting Group" := TransLine."Inventory Posting Group";
        TransferBuffer[1]."Item No." := TransLine."Item No.";
        if not BondedLocation."Bonded warehouse" then begin
            TransferBuffer[1].Amount :=
                Round(RoundTotalGSTAmountQtyFactor(DocTransactionType::Transfer, 0,
                TransLine."Document No.", TransLine."Line No.", TransLine."Qty. to Ship" / TransLine.Quantity, '', false));
            TransferBuffer[1]."GST Amount" := Round(RoundTotalGSTAmountQtyFactor(DocTransactionType::Transfer, 0,
                TransLine."Document No.", TransLine."Line No.", TransLine."Qty. to Ship" / TransLine.Quantity, '', false));
        end;

        TransferBuffer[1].Quantity := TransLine."Qty. to Ship";
        TransferBuffer[1]."Amount Loaded on Inventory" := Round(TransLine."Amount Added to Inventory" * TransLine."Qty. to Ship" / TransLine.Quantity);
        TransferBuffer[1]."Charges Amount" := Round(TransLine."Charges to Transfer" * TransLine."Qty. to Ship" / TransLine.Quantity);
        Item.Get(TransLine."Item No.");
        TransferBuffer[1].Amount := TransferBuffer[1].Amount;
        UpdTransferBuffer(TransLine, TransLine."Line No.");
    end;

    local procedure UpdTransferBuffer(TransLine: Record "Transfer Line"; SortingNo: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        TransferBuffer[1]."Dimension Set ID" := TransLine."Dimension Set ID";

        DimMgt.UpdateGlobalDimFromDimSetID(TransferBuffer[1]."Dimension Set ID",
          TransferBuffer[1]."Global Dimension 1 Code", TransferBuffer[1]."Global Dimension 2 Code");

        TransferBuffer[2] := TransferBuffer[1];
        if TransferBuffer[2].Find() then begin
            TransferBuffer[2].Amount := TransferBuffer[2].Amount + TransferBuffer[1].Amount;
            TransferBuffer[2]."GST Amount" := TransferBuffer[2]."GST Amount" + TransferBuffer[1]."GST Amount";
            TransferBuffer[2].Quantity :=
              TransferBuffer[2].Quantity + TransferBuffer[1].Quantity;
            TransferBuffer[2]."Amount Loaded on Inventory" := TransferBuffer[2]."Amount Loaded on Inventory" +
              TransferBuffer[1]."Amount Loaded on Inventory";
            TransferBuffer[2]."Charges Amount" := TransferBuffer[2]."Charges Amount" +
              TransferBuffer[1]."Charges Amount";
            if not TransferBuffer[1]."System-Created Entry" then
                TransferBuffer[2]."System-Created Entry" := false;
            TransferBuffer[2].Modify();
        end else begin
            TransferBuffer[1]."Sorting No." := SortingNo;
            TransferBuffer[1].Insert();
        end;
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
        if not Location.Get(TransferHeader."Transfer-from Code") then
            exit;
        if Location."Bonded warehouse" then
            exit;

        Location.TestField("State Code");
        GSTStateCode := Location."State Code";

        DetailedGSTEntryBuffer.Reset();
        DetailedGSTEntryBuffer.SetCurrentKey("Transaction Type", "Document Type", "Document No.", "Line No.");
        DetailedGSTEntryBuffer.SetRange("Transaction Type", DetailedGSTEntryBuffer."Transaction Type"::Transfer);
        DetailedGSTEntryBuffer.SetRange("Document Type", 0);
        DetailedGSTEntryBuffer.SetRange("Document No.", TransLine."Document No.");
        DetailedGSTEntryBuffer.SetRange("Line No.", TransLine."Line No.");
        DetailedGSTEntryBuffer.SetFilter("GST Base Amount", '<>%1', 0);
        if DetailedGSTEntryBuffer.FindSet() then
            repeat
                GSTPostingBuffer[1].Type := GSTPostingBuffer[1].Type::Item;
                GSTPostingBuffer[1]."Global Dimension 1 Code" := TransLine."Shortcut Dimension 1 Code";
                GSTPostingBuffer[1]."Global Dimension 2 Code" := TransLine."Shortcut Dimension 2 Code";
                GSTPostingBuffer[1]."Gen. Prod. Posting Group" := TransLine."Gen. Prod. Posting Group";
                GSTPostingBuffer[1]."GST Group Code" := TransLine."GST Group Code";
                QFactor := ABS(TransLine."Qty. to Ship" / TransLine.Quantity);
                GSTPostingBuffer[1]."GST Base Amount" :=
                  RoundGSTPrecision(QFactor * DetailedGSTEntryBuffer."GST Base Amount");
                GSTPostingBuffer[1]."GST Amount" :=
                  RoundGSTPrecision(QFactor * DetailedGSTEntryBuffer."GST Amount");
                GSTPostingBuffer[1]."GST %" := DetailedGSTEntryBuffer."GST %";
                GSTPostingBuffer[1]."GST Component Code" := DetailedGSTEntryBuffer."GST Component Code";
                GSTPostingBuffer[1]."Account No." :=
                  GetGSTPayableAccountNo(GSTStateCode, DetailedGSTEntryBuffer."GST Component Code");
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

    local procedure RoundGSTPrecision(GSTAmount: Decimal): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTRoundingDirection: Text[1];
        GSTRoundingPrecision: Decimal;
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("GST Rounding Precision");
        case GeneralLedgerSetup."GST Rounding Type" of
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

    local procedure GetGSTPayableAccountNo(LocationCode: Code[10]; GSTComponentCode: Code[10]): Code[20]
    var
        GSTPostingSetup: Record "GST Posting Setup";
    begin
        GSTPostingSetup.Reset();
        GSTPostingSetup.SetRange("State Code", LocationCode);
        GSTPostingSetup.SetRange("Component ID", GSTComponentID(GSTComponentCode));
        GSTPostingSetup.FindFirst();
        exit(GSTPostingSetup."Payable Account")
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
        if DetailedGSTEntryBuffer.FindSet() then
            repeat
                if DetailedGSTEntryBuffer."Amount Loaded on Item" <> 0 then
                    TotalGSTAmount += DetailedGSTEntryBuffer."Amount Loaded on Item" * QtyFactor
                else
                    if DetailedGSTEntryBuffer."GST Input/Output Credit Amount" <> 0 then
                        TotalGSTAmount += DetailedGSTEntryBuffer."GST Input/Output Credit Amount" * QtyFactor;

                if CurrencyCode = '' then
                    if GSTInvoiceRouding then
                        TotalGSTAmount := RoundGSTInvoicePrecision(TotalGSTAmount)
                    else
                        TotalGSTAmount := RoundGSTPrecision(TotalGSTAmount);
                if (CurrencyCode <> '') and GSTInvoiceRouding then
                    TotalGSTAmount := RoundGSTInvoicePrecision(TotalGSTAmount);
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

    local procedure RoundGSTInvoicePrecision(GSTAmount: Decimal): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTRoundingDirection: Text[1];
        GSTRoundingPrecision: Decimal;
    begin
        if GSTAmount = 0 then
            exit(0);

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."GST Inv. Rounding Precision" = 0 then
            exit;

        case GeneralLedgerSetup."GST Inv. Rounding Type" of
            GeneralLedgerSetup."GST Inv. Rounding Type"::Nearest:
                GSTRoundingDirection := '=';
            GeneralLedgerSetup."GST Inv. Rounding Type"::Up:
                GSTRoundingDirection := '>';
            GeneralLedgerSetup."GST Inv. Rounding Type"::Down:
                GSTRoundingDirection := '<';
        end;

        GSTRoundingPrecision := GeneralLedgerSetup."GST Inv. Rounding Precision";
        exit(Round(GSTAmount, GSTRoundingPrecision, GSTRoundingDirection));
    end;

    local procedure PostTransLineToGenJnlLine(TransferHeader: Record "Transfer Header"; TransferShptNo: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        DocTransferType: option "Transfer Shipment","Transfer Receipt";
    begin
        SourceCodeSetup.Get();

        GenJnlLine.Init();
        GenJnlLine."Posting Date" := TransferHeader."Posting Date";
        GenJnlLine.Description := STRSUBSTNO(Text13700Msg, TransferShptNo);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
        GenJnlLine."Document No." := TransferShptNo;
        GenJnlLine."External Document No." := TransferHeader."No.";
        if GSTPostingBuffer[1]."GST Amount" <> 0 then begin
            GenJnlLine.VALIDATE(Amount, Round(GSTPostingBuffer[1]."GST Amount"));
            GenJnlLine."Account No." := GSTPostingBuffer[1]."Account No.";
        end;
        GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
        GenJnlLine."GST Group Code" := GSTPostingBuffer[1]."GST Group Code";
        GenJnlLine."GST Component Code" := GSTPostingBuffer[1]."GST Component Code";
        GenJnlLine."System-Created Entry" := TransferBuffer[1]."System-Created Entry";
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
        GenJnlLine."Gen. Bus. Posting Group" := GSTPostingBuffer[1]."Gen. Bus. Posting Group";
        GenJnlLine."Gen. Prod. Posting Group" := GSTPostingBuffer[1]."Gen. Prod. Posting Group";
        GenJnlLine."Shortcut Dimension 1 Code" := GSTPostingBuffer[1]."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := GSTPostingBuffer[1]."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := GSTPostingBuffer[1]."Dimension Set ID";
        GenJnlLine."Location Code" := TransferHeader."Transfer-from Code";
        GenJnlLine."Source Code" := SourceCodeSetup.Transfer;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        RunGenJnlPostLine(GenJnlLine);
        InsertGSTLedgerEntryTransfer(
           GSTPostingBuffer[1], TransferHeader, GenJnlPostLine.GetNextTransactionNo(),
          GenJnlLine."Document No.", SourceCodeSetup.Transfer, DocTransferType::"Transfer Shipment");
    end;

    procedure InsertGSTLedgerEntryTransfer(
        GSTPostingBuffer: Record "GST Posting Buffer";
        TransferHeader: Record "Transfer Header";
        NextTransactionNo: Integer;
        DocumentNo: Code[20]; SourceCode: Code[10];
        DocTransferType: option TransferShpmnt,TransferReciept)
    var
        GSTLedgerEntry: Record "GST Ledger Entry";
        Location: Record Location;
    begin
        Location.Get(TransferHeader."Transfer-from Code");

        GSTLedgerEntry.Init();
        GSTLedgerEntry."Entry No." := 0;
        GSTLedgerEntry."Gen. Bus. Posting Group" := GSTPostingBuffer."Gen. Bus. Posting Group";
        GSTLedgerEntry."Gen. Prod. Posting Group" := GSTPostingBuffer."Gen. Prod. Posting Group";
        GSTLedgerEntry."Posting Date" := TransferHeader."Posting Date";
        GSTLedgerEntry."Document No." := DocumentNo;
        GSTLedgerEntry."Document Type" := GSTLedgerEntry."Document Type"::Invoice;
        GSTLedgerEntry."GST Base Amount" := GSTPostingBuffer."GST Base Amount";
        GSTLedgerEntry."GST Amount" := GSTPostingBuffer."GST Amount";
        GSTLedgerEntry."Source Type" := GSTLedgerEntry."Source Type"::Transfer;
        if DocTransferType = DocTransferType::TransferShpmnt then begin
            GSTLedgerEntry."Transaction Type" := GSTLedgerEntry."Transaction Type"::Sales;
            GSTLedgerEntry."External Document No." := TransferHeader."No.";
        end else begin
            GSTLedgerEntry."Transaction Type" := GSTLedgerEntry."Transaction Type"::Purchase;
            GSTLedgerEntry."External Document No." := TransferHeader."Last Shipment No.";
            if Location."Bonded warehouse" then begin
                GSTLedgerEntry."Source Type" := GSTLedgerEntry."Source Type"::VEndor;
                GSTLedgerEntry."Source No." := TransferHeader."VEndor No.";
                GSTLedgerEntry."Reverse Charge" := true;
            end;
        end;

        GSTLedgerEntry."GST Base Amount" := GSTPostingBuffer."GST Base Amount";
        GSTLedgerEntry."User ID" := Copystr(USERID, 1, MaxStrLen(GSTLedgerEntry."User ID"));
        GSTLedgerEntry."Source Type" := GSTLedgerEntry."Source Type"::Transfer;
        GSTLedgerEntry."Source Code" := SourceCode;
        GSTLedgerEntry."Transaction No." := NextTransactionNo;
        GSTLedgerEntry."GST Component Code" := GSTPostingBuffer."GST Component Code";
        GSTLedgerEntry.Insert(true);
    end;

    procedure InsertDetailedGSTLedgEntryTransfer(
        var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header";
        DocumentNo: Code[20];
        TransactionNo: Integer; DocTransferType: option TransferShpmnt,TransferReciept)
    var
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        Item: Record Item;
        Location: Record Location;
        Location2: Record Location;
        ShipRcvQuantity: Decimal;
    begin
        DetailedGSTEntryBuffer.SetCurrentKey("Transaction Type", "Document Type", "Document No.", "Line No.");
        DetailedGSTEntryBuffer.SetRange("Transaction Type", DetailedGSTEntryBuffer."Transaction Type"::Transfer);
        DetailedGSTEntryBuffer.SetRange("Document Type", 0);
        DetailedGSTEntryBuffer.SetRange("Document No.", TransferLine."Document No.");
        DetailedGSTEntryBuffer.SetRange("Line No.", TransferLine."Line No.");
        if DetailedGSTEntryBuffer.FindSet() then
            repeat
                DetailedGSTLedgerEntry.Init();
                DetailedGSTLedgerEntry."Entry No." := 0;
                DetailedGSTLedgerEntry."Entry Type" := DetailedGSTLedgerEntry."Entry Type"::"Initial Entry";
                if DocTransferType = DocTransferType::TransferShpmnt then
                    DetailedGSTLedgerEntry."Transaction Type" := DetailedGSTLedgerEntry."Transaction Type"::Sales
                else
                    DetailedGSTLedgerEntry."Transaction Type" := DetailedGSTLedgerEntry."Transaction Type"::Purchase;
                DetailedGSTLedgerEntry."Document Type" := DetailedGSTLedgerEntry."Document Type"::Invoice;
                DetailedGSTLedgerEntry."Document No." := DocumentNo;
                DetailedGSTLedgerEntry."Original Doc. No." := TransferHeader."No.";
                DetailedGSTLedgerEntry."Posting Date" := TransferHeader."Posting Date";
                DetailedGSTLedgerEntry.Type := Type::Item;
                DetailedGSTLedgerEntry."Product Type" := DetailedGSTLedgerEntry."Product Type"::Item;
                DetailedGSTLedgerEntry."No." := TransferLine."Item No.";
                Location.Get(TransferHeader."Transfer-from Code");
                if not Location."Bonded warehouse" then begin
                    Location.TestField("State Code");
                    if (Location."GST Registration No." = '') and (Location."Location ARN No." = '') then
                        Error(LocGSTRegNoARNNoErr);
                end;

                Location2.Get(TransferHeader."Transfer-to Code");
                if (Location2."GST Registration No." = '') and (Location2."Location ARN No." = '') then
                    Error(LocGSTRegNoARNNoErr);

                DetailedGSTLedgerEntry."GST Jurisdiction Type" := GETGSTJurisdictionType(TransferHeader);
                DetailedGSTLedgerEntry."GST Group Type" := "GST Group Type"::Goods;
                DetailedGSTLedgerEntry."GST Without Payment of Duty" := false;
                DetailedGSTLedgerEntry."GST Component Code" := DetailedGSTEntryBuffer."GST Component Code";
                DetailedGSTLedgerEntry."GST Exempted Goods" := TransferLine.Exempted;
                if DocTransferType = DocTransferType::TransferShpmnt then begin
                    DetailedGSTLedgerEntry."G/L Account No." := GetGSTPayableAccountNo(
                        Location."State Code",
                        DetailedGSTEntryBuffer."GST Component Code");
                    ShipRcvQuantity := TransferLine."Qty. to Ship (Base)";
                    DetailedGSTLedgerEntry."Location Code" := Location.Code;
                    DetailedGSTLedgerEntry."Location ARN No." := Location."Location ARN No.";
                    DetailedGSTLedgerEntry."Location State Code" := Location."State Code";
                    DetailedGSTLedgerEntry."Buyer/Seller State Code" := Location2."State Code";
                    DetailedGSTLedgerEntry."Shipping Address State Code" := '';
                    DetailedGSTLedgerEntry."Location  Reg. No." := Location."GST Registration No.";
                    DetailedGSTLedgerEntry."Buyer/Seller Reg. No." := Location2."GST Registration No.";
                    DetailedGSTLedgerEntry."Original Doc. Type" := DetailedGSTLedgerEntry."Original Doc. Type"::"Transfer Shipment";
                    DetailedGSTLedgerEntry."External Document No." := TransferHeader."No.";
                    DetailedGSTLedgerEntry."GST Customer Type" := "GST Customer Type"::Registered;
                    DetailedGSTLedgerEntry."Sales Invoice Type" := "Sales Invoice Type"::Taxable;
                    DetailedGSTLedgerEntry."Liable to Pay" := true;
                end else begin
                    DetailedGSTLedgerEntry."G/L Account No." := GetGSTReceivableAccountNo(
                        Location2."State Code",
                        DetailedGSTEntryBuffer."GST Component Code");
                    ShipRcvQuantity := TransferLine."Qty. to Receive (Base)";
                    DetailedGSTLedgerEntry."Location Code" := Location2.Code;
                    DetailedGSTLedgerEntry."Location ARN No." := Location2."Location ARN No.";
                    DetailedGSTLedgerEntry."Location State Code" := Location2."State Code";
                    DetailedGSTLedgerEntry."Buyer/Seller State Code" := Location."State Code";
                    DetailedGSTLedgerEntry."Shipping Address State Code" := '';
                    DetailedGSTLedgerEntry."Location  Reg. No." := Location2."GST Registration No.";
                    DetailedGSTLedgerEntry."Buyer/Seller Reg. No." := Location."GST Registration No.";
                    DetailedGSTLedgerEntry."Original Doc. Type" := DetailedGSTLedgerEntry."Original Doc. Type"::"Transfer Receipt";
                    DetailedGSTLedgerEntry."External Document No." := TransferHeader."Last Shipment No.";
                    DetailedGSTLedgerEntry."GST VEndor Type" := "GST VEndor Type"::Registered;
                    if Location."Bonded warehouse" then begin
                        DetailedGSTLedgerEntry."GST VEndor Type" := "GST VEndor Type"::Import;
                        DetailedGSTLedgerEntry."Credit Availed" := true;
                        DetailedGSTLedgerEntry."Reverse Charge" := true;
                        DetailedGSTLedgerEntry."Buyer/Seller Reg. No." := '';
                        DetailedGSTLedgerEntry."Buyer/Seller State Code" := '';
                        DetailedGSTLedgerEntry."Bill of Entry No." := TransferHeader."Bill of Entry No.";
                        DetailedGSTLedgerEntry."Bill of Entry Date" := TransferHeader."Bill of Entry Date";
                        DetailedGSTLedgerEntry."Source Type" := "Source Type"::VEndor;
                        DetailedGSTLedgerEntry."Source No." := TransferHeader."VEndor No.";
                        DetailedGSTLedgerEntry."GST Assessable Value" := TransferLine."GST Assessable Value";
                        DetailedGSTLedgerEntry."Custom Duty Amount" := TransferLine."Custom Duty Amount";
                    end;
                end;

                UpdateDetailGSTLedgerEntryTransfer(
                  DetailedGSTLedgerEntry, TransferLine."Document No.", TransferLine."Line No.", TransactionNo,
                  TransferLine."Quantity (Base)", ShipRcvQuantity, DocTransferType);
                DetailedGSTLedgerEntry.TestField("HSN/SAC Code");
                DetailedGSTLedgerEntry."Skip Tax Engine Trigger" := True;
                DetailedGSTLedgerEntry.Insert(true);
            until DetailedGSTEntryBuffer.Next() = 0;

        if DetailedGSTLedgerEntry."Transaction Type" = DetailedGSTLedgerEntry."Transaction Type"::Purchase then
            UpdateGSTTrackingEntryFromTransferOrder(
              DocumentNo,
              TransferLine."Item No.",
              TransferLine."Line No.",
              DetailedGSTLedgerEntry."Original Doc. Type"::"Transfer Receipt");
    end;

    local procedure UpdateDetailGSTLedgerEntryTransfer(
        var DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        DocumentNo: Code[20];
        LineNo: Integer;
        TransactionNo: Integer;
        QtyBase: Decimal;
        QtyShip: Decimal;
        DocTransferType: Option TransferShpmnt,TransferReciept)
    var
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
    begin
        DetailedGSTEntryBuffer.SetCurrentKey("Transaction Type", "Document Type", "Document No.", "Line No.");
        DetailedGSTEntryBuffer.SetRange("Transaction Type", DetailedGSTEntryBuffer."Transaction Type"::Transfer);
        DetailedGSTEntryBuffer.SetRange("Document Type", DetailedGSTEntryBuffer."Document Type"::Quote);
        DetailedGSTEntryBuffer.SetRange("Document No.", DocumentNo);
        DetailedGSTEntryBuffer.SetRange("Line No.", LineNo);
        DetailedGSTEntryBuffer.SetRange("GST Component Code", DetailedGSTLedgerEntry."GST Component Code");
        if DetailedGSTEntryBuffer.FindFirst() then begin
            DetailedGSTLedgerEntry.Type := DetailedGSTEntryBuffer.Type;
            DetailedGSTLedgerEntry."No." := DetailedGSTEntryBuffer."No.";
            DetailedGSTLedgerEntry."Product Type" := DetailedGSTLedgerEntry."Product Type"::Item;
            DetailedGSTLedgerEntry."HSN/SAC Code" := DetailedGSTEntryBuffer."HSN/SAC Code";
            DetailedGSTLedgerEntry."GST Component Code" := DetailedGSTEntryBuffer."GST Component Code";
            DetailedGSTLedgerEntry."GST Group Code" := DetailedGSTEntryBuffer."GST Group Code";
            DetailedGSTLedgerEntry."Document Line No." := DetailedGSTEntryBuffer."Line No.";
            if DetailedGSTEntryBuffer."GST Assessable Value" <> 0 then begin
                DetailedGSTLedgerEntry."GST Base Amount" :=
                  -RoundGSTPrecision(DetailedGSTEntryBuffer."GST Assessable Value" + DetailedGSTEntryBuffer."Custom Duty Amount");
                DetailedGSTLedgerEntry."GST Amount" := RoundGSTPrecision(DetailedGSTEntryBuffer."GST Amount");
            end else begin
                DetailedGSTLedgerEntry."GST Base Amount" := RoundGSTPrecision(DetailedGSTEntryBuffer."GST Base Amount" * QtyShip / QtyBase);
                DetailedGSTLedgerEntry."GST Amount" := RoundGSTPrecision(DetailedGSTEntryBuffer."GST Amount" * QtyShip / QtyBase);
            end;

            DetailedGSTLedgerEntry."Remaining Base Amount" := 0;
            DetailedGSTLedgerEntry."Remaining GST Amount" := 0;
            DetailedGSTLedgerEntry."GST %" := DetailedGSTEntryBuffer."GST %";
            if DocTransferType = DocTransferType::TransferShpmnt then begin
                DetailedGSTLedgerEntry.Quantity := -QtyShip;
                DetailedGSTLedgerEntry."Remaining Quantity" := -QtyShip;
            end else begin
                DetailedGSTLedgerEntry.Quantity := QtyShip;
                DetailedGSTLedgerEntry."Remaining Quantity" := QtyShip;
            end;

            if DocTransferType = DocTransferType::TransferReciept then
                if DetailedGSTEntryBuffer."GST Assessable Value" <> 0 then
                    DetailedGSTLedgerEntry."Amount Loaded on Item" :=
                      RoundGSTPrecision(
                        DetailedGSTEntryBuffer."Amount Loaded on Item")
                else
                    DetailedGSTLedgerEntry."Amount Loaded on Item" :=
                      RoundGSTPrecision(
                        DetailedGSTEntryBuffer."Amount Loaded on Item" * QtyShip / QtyBase)
            else
                DetailedGSTLedgerEntry."Amount Loaded on Item" := 0;

            if DocTransferType = DocTransferType::TransferReciept then
                if DetailedGSTLedgerEntry."Amount Loaded on Item" <> 0 then
                    DetailedGSTLedgerEntry."GST Credit" := DetailedGSTLedgerEntry."GST Credit"::"Non-Availment"
                else
                    DetailedGSTLedgerEntry."GST Credit" := DetailedGSTLedgerEntry."GST Credit"::Availment;

            DetailedGSTLedgerEntry."Credit Availed" := GetReceivableApplicable(
                DetailedGSTLedgerEntry."GST VEndor Type",
                DetailedGSTLedgerEntry."GST Group Type",
                DetailedGSTLedgerEntry."GST Credit", false, false);

            if DocTransferType = DocTransferType::TransferReciept then
                ReverseDetailedGSTEntryQtyAmt(DetailedGSTLedgerEntry);

            DetailedGSTLedgerEntry."GST Rounding Type" := DetailedGSTEntryBuffer."GST Rounding Type";
            DetailedGSTLedgerEntry."GST Rounding Precision" := DetailedGSTEntryBuffer."GST Rounding Precision";
            DetailedGSTLedgerEntry."GST Inv. Rounding Type" := DetailedGSTEntryBuffer."GST Inv. Rounding Type";
            DetailedGSTLedgerEntry."GST Inv. Rounding Precision" := DetailedGSTEntryBuffer."GST Inv. Rounding Precision";
            DetailedGSTLedgerEntry.Positive := DetailedGSTLedgerEntry."GST Amount" > 0;
            DetailedGSTLedgerEntry."User ID" := copystr(USERID, 1, MaxStrLen(DetailedGSTLedgerEntry."User ID"));
            DetailedGSTLedgerEntry."Transaction No." := TransactionNo;
            DetailedGSTLedgerEntry.Cess := DetailedGSTEntryBuffer.Cess;
            DetailedGSTLedgerEntry."Component Calc. Type" := DetailedGSTEntryBuffer."Component Calc. Type";
            DetailedGSTLedgerEntry."Cess Amount Per Unit Factor" := DetailedGSTEntryBuffer."Cess Amt Per Unit Factor (LCY)";
            DetailedGSTLedgerEntry."Cess UOM" := DetailedGSTEntryBuffer."Cess UOM";
            DetailedGSTLedgerEntry."Cess Factor Quantity" := DetailedGSTEntryBuffer."Cess Factor Quantity";
            DetailedGSTLedgerEntry.UOM := DetailedGSTEntryBuffer.UOM;
            if DetailedGSTLedgerEntry."GST Credit" = DetailedGSTLedgerEntry."GST Credit"::"Non-Availment" then
                DetailedGSTLedgerEntry."Eligibility for ITC" := DetailedGSTLedgerEntry."Eligibility for ITC"::Ineligible
            else
                if DetailedGSTLedgerEntry."GST Credit" = DetailedGSTLedgerEntry."GST Credit"::Availment then
                    if DetailedGSTLedgerEntry."GST Group Type" = DetailedGSTLedgerEntry."GST Group Type"::Service then
                        DetailedGSTLedgerEntry."Eligibility for ITC" := DetailedGSTLedgerEntry."Eligibility for ITC"::"Input Services"
                    else
                        if DetailedGSTLedgerEntry.Type = DetailedGSTLedgerEntry.Type::"Fixed Asset" then
                            DetailedGSTLedgerEntry."Eligibility for ITC" := DetailedGSTLedgerEntry."Eligibility for ITC"::"Capital goods"
                        else
                            DetailedGSTLedgerEntry."Eligibility for ITC" := DetailedGSTLedgerEntry."Eligibility for ITC"::Inputs;
        end;
    end;

    local procedure ReverseDetailedGSTEntryQtyAmt(
        var DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry")
    begin
        DetailedGSTLedgerEntry."GST Base Amount" := -DetailedGSTLedgerEntry."GST Base Amount";
        DetailedGSTLedgerEntry."GST Amount" := -DetailedGSTLedgerEntry."GST Amount";
        DetailedGSTLedgerEntry."Amount Loaded on Item" := -DetailedGSTLedgerEntry."Amount Loaded on Item";
    end;

    local procedure GetReceivableApplicable(
        GSTVEndorType: Enum "GST Vendor Type";
        GSTGroupType: enum "GST Group Type";
        GSTCredit: Enum "Detail GST Credit";
        AssociatedEnterprises: Boolean; ReverseCharge: Boolean): Boolean
    begin
        if GSTCredit = GSTCredit::Availment then
            case GSTVEndorType of
                GSTVEndorType::Registered:
                    begin
                        if ReverseCharge then
                            exit(false);
                        exit(true);
                    end;
                GSTVEndorType::Unregistered:
                    if GSTGroupType = GSTGroupType::Goods then
                        exit(true);
                GSTVEndorType::Import, GSTVEndorType::SEZ:
                    begin
                        if (GSTGroupType = GSTGroupType::Service) and NOT ReverseCharge then
                            exit(true);
                        if GSTGroupType = GSTGroupType::Goods then
                            exit(true);
                        exit(AssociatedEnterprises = true);
                    end;
            end;
    end;

    procedure UpdateGSTTrackingEntryFromTransferOrder(
        DocumentNo: Code[20]; ItemNo: Code[20];
        DocumentLineNo: Integer;
        OrignalDocType: enum "Original Doc Type")
    var
        GSTTrackingEntry: Record "GST Tracking Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        GSTTrackingEntry2: Record "GST Tracking Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Open, true);
        if ItemLedgerEntry.FindSet() then
            repeat
                GSTTrackingEntry.Init();
                GSTTrackingEntry2.Reset();
                if GSTTrackingEntry2.FindLast() then
                    GSTTrackingEntry."Entry No." := GSTTrackingEntry2."Entry No." + 1
                else
                    GSTTrackingEntry."Entry No." := 1;
                GSTTrackingEntry."From Entry No." := GetFromEntryNo(DocumentNo, DocumentLineNo, OrignalDocType);
                GSTTrackingEntry."From To No." := GetFromToNo(DocumentNo, DocumentLineNo, OrignalDocType);
                GSTTrackingEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
                GSTTrackingEntry.Quantity := ItemLedgerEntry.Quantity;
                GSTTrackingEntry."Remaining Quantity" := ItemLedgerEntry."Remaining Quantity";
                GSTTrackingEntry.Insert();
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure GetFromEntryNo(DocumentNo: Code[20]; LineNo: Integer; OrignalDocType: Enum "Original Doc Type"): Integer
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", LineNo);
        DetailedGSTLedgerEntry.SetRange("Transaction Type", DetailedGSTLedgerEntry."Transaction Type"::Purchase);
        DetailedGSTLedgerEntry.SetRange("Original Doc. Type", OrignalDocType);
        DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::"Initial Entry");
        if DetailedGSTLedgerEntry.FindFirst() then
            exit(DetailedGSTLedgerEntry."Entry No.");
        exit(1);
    end;

    local procedure GetFromToNo(DocumentNO: Code[20]; LineNo: Integer; OrignalDocType: enum "Original Doc Type"): Integer
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNO);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", LineNo);
        DetailedGSTLedgerEntry.SetRange("Transaction Type", DetailedGSTLedgerEntry."Transaction Type"::Purchase);
        DetailedGSTLedgerEntry.SetRange("Original Doc. Type", OrignalDocType);
        DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::"Initial Entry");
        if DetailedGSTLedgerEntry.FindLast() then
            exit(DetailedGSTLedgerEntry."Entry No.");
        exit(1);
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure GETGSTJurisdictionType(TransferHeader: Record "Transfer Header"): Enum "GST Jurisdiction Type"
    var
        Location: Record Location;
        Location1: Record Location;
        GSTJurisdictionType: Enum "GST Jurisdiction Type";
    begin
        Location.Get(TransferHeader."Transfer-from Code");
        Location1.Get(TransferHeader."Transfer-to Code");
        if Location."State Code" <> Location1."State Code" then
            exit(GSTJurisdictionType::Interstate)
        else
            exit(GSTJurisdictionType::Intrastate);
    end;

    local procedure GetLastClosedSubAccPeriod(): Date
    var
        TaxAccountingPeriod: record "Tax Accounting Period";
        TaxTypeSetup: Record "Tax Type Setup";
    begin
        if not TaxTypeSetup.Get() then
            exit;
        TaxAccountingPeriod.SetRange("Tax Type Code", TaxTypeSetup.Code);
        TaxAccountingPeriod.SetRange(Closed, True);
        if TaxAccountingPeriod.FindLast() then
            exit(TaxAccountingPeriod."Starting Date");
    end;

    local procedure GetTransferShipmentPostingNoSeries(var TansferHeader: Record "Transfer Header"): Code[20]
    var
        PostingNoSeries: Record "Posting No. Series";
        NoSeriesCode: Code[20];
    begin
        PostingNoSeries.SetRange("Table Id", Database::"Transfer Header");
        NoSeriesCode := LoopPostingNoSeries(
            PostingNoSeries,
            TansferHeader,
            PostingNoSeries."Document Type"::"Transfer Shipment Header");

        exit(NoSeriesCode);
    end;

    procedure LoopPostingNoSeries(
        var PostingNoSeries: Record "Posting No. Series";
        Record: Variant;
        PostingDocumentType: Enum "Posting Document Type"): Code[20]
    var
        Filters: Text;
    begin
        PostingNoSeries.SetRange("Document Type", PostingDocumentType);
        if PostingNoSeries.FindSet() then
            repeat
                Filters := GetRecordView(PostingNoSeries);
                if RecordViewFound(Record, Filters) then begin
                    PostingNoSeries.TestField("Posting No. Series");
                    exit(PostingNoSeries."Posting No. Series");
                end;
            until PostingNoSeries.Next() = 0;
    end;

    local procedure RecordViewFound(Record: Variant; Filters: Text) Found: Boolean;
    var
        Field: Record Field;
        DuplicateRecRef: RecordRef;
        TempRecRef: RecordRef;
        FieldRef: FieldRef;
        TempFieldRef: FieldRef;
    begin
        DuplicateRecRef.GetTable(Record);
        Clear(TempRecRef);
        TempRecRef.Open(DuplicateRecRef.Number(), True);
        Field.SetRange(TableNo, DuplicateRecRef.Number());
        if Field.FindSet() then
            repeat
                FieldRef := DuplicateRecRef.Field(Field."No.");
                TempFieldRef := TempRecRef.Field(Field."No.");
                TempFieldRef.VALUE := FieldRef.Value();
            until Field.Next() = 0;

        TempRecRef.Insert();
        Found := True;
        if Filters = '' then
            exit;

        TempRecRef.SetView(Filters);
        Found := TempRecRef.Find();
    end;

    local procedure GetRecordView(var PostingNoSeries: Record "Posting No. Series") Filters: Text;
    var
        ConditionInStream: InStream;
    begin
        PostingNoSeries.calcfields(Condition);
        PostingNoSeries.Condition.CREATEINSTREAM(ConditionInStream);
        ConditionInStream.READ(Filters);
    end;

    var
        GSTPostingBuffer: array[2] of Record "GST Posting Buffer" temporary;
        TransferBuffer: array[2] of Record "Transfer Buffer" temporary;
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GSTGroupServiceErr: Label 'You canNot select GST Group Type Service for transfer.';
        LocGSTRegNoARNNoErr: Label 'Location must have either GST Registration No. or Location ARN No.';
        Text13700Msg: Label 'Transfer - %1', Comment = '%1= Transfer Shipment No.';
        AccountingPeriodErr: Label 'GST Accounting Period Does not exist for the given Date %1.', Comment = '%1 =PostingDate';
        PeriodClosedErr: Label 'Accounting Period has been closed till %1, Document Posting Date must be greater than or equal to %2.', Comment = '%1 =LastClosedDate , %2 = LastClosedDate';
}