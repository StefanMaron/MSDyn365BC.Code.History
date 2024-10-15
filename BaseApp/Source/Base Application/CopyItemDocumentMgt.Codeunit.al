codeunit 12458 "Copy Item Document Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Please enter a Document No.';
        Text001: Label '%1 %2 cannot be copied onto itself.';
        Text002: Label 'The existing lines for %1 %2 will be deleted.\\';
        Text003: Label 'Do you want to continue?';
        Text004: Label 'The document line(s) with a G/L account where direct posting is not allowed have not been copied to the new document by the Copy Document batch job.';
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        ItemDocType: Option Receipt,Shipment,"Posted Receipt","Posted Shipment";
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;
        CreateToHeader: Boolean;
        HideDialog: Boolean;
        FillAppliesFields: Boolean;

    [Scope('OnPrem')]
    procedure SetProperties(NewIncludeHeader: Boolean; NewRecalculateLines: Boolean; NewCreateToHeader: Boolean; NewHideDialog: Boolean; NewFillAppliesFields: Boolean)
    begin
        IncludeHeader := NewIncludeHeader;
        RecalculateLines := NewRecalculateLines;
        CreateToHeader := NewCreateToHeader;
        HideDialog := NewHideDialog;
        FillAppliesFields := NewFillAppliesFields;
    end;

    [Scope('OnPrem')]
    procedure CopyItemDoc(FromDocType: Option; FromDocNo: Code[20]; var ToItemDocHeader: Record "Item Document Header")
    var
        ToItemDocLine: Record "Item Document Line";
        OldItemDocHeader: Record "Item Document Header";
        FromItemDocHeader: Record "Item Document Header";
        FromItemDocLine: Record "Item Document Line";
        FromItemRcptHeader: Record "Item Receipt Header";
        FromItemRcptLine: Record "Item Receipt Line";
        FromItemShptHeader: Record "Item Shipment Header";
        FromItemShptLine: Record "Item Shipment Line";
        NextLineNo: Integer;
        LinesNotCopied: Integer;
    begin
        with ToItemDocHeader do begin
            if not CreateToHeader then begin
                TestField(Status, Status::Open);
                if FromDocNo = '' then
                    Error(Text000);
                Find;
            end;
            TransferOldExtLines.ClearLineNumbers;
            case FromDocType of
                ItemDocType::Receipt,
                ItemDocType::Shipment:
                    begin
                        FromItemDocHeader.Get(FromDocType, FromDocNo);
                        if (FromItemDocHeader."Document Type" = "Document Type") and
                           (FromItemDocHeader."No." = "No.")
                        then
                            Error(
                              Text001,
                              "Document Type", "No.");

                        FromItemDocLine.SetRange("Document Type", FromItemDocHeader."Document Type");
                        FromItemDocLine.SetRange("Document No.", FromItemDocHeader."No.");
                        if FromItemDocLine.Find('-') then
                            repeat
                                if FromItemDocLine.Quantity > 0 then begin
                                    ToItemDocLine."Item No." := FromItemDocLine."Item No.";
                                    ToItemDocLine."Variant Code" := FromItemDocLine."Variant Code";
                                    ToItemDocLine."Location Code" := FromItemDocLine."Location Code";
                                    ToItemDocLine."Bin Code" := FromItemDocLine."Bin Code";
                                    ToItemDocLine."Unit of Measure Code" := FromItemDocLine."Unit of Measure Code";
                                    ToItemDocLine."Qty. per Unit of Measure" := FromItemDocLine."Qty. per Unit of Measure";
                                    ToItemDocLine.Quantity := FromItemDocLine.Quantity;
                                    CheckItemAvailable(ToItemDocHeader, ToItemDocLine);
                                end;
                            until FromItemDocLine.Next = 0;
                        if not IncludeHeader and not RecalculateLines then
                            FromItemDocHeader.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                    end;
                ItemDocType::"Posted Receipt":
                    begin
                        FromItemRcptHeader.Get(FromDocNo);
                        FromItemRcptLine.SetRange("Document No.", FromItemRcptHeader."No.");
                        if FromItemRcptLine.Find('-') then
                            repeat
                                if FromItemRcptLine.Quantity > 0 then begin
                                    ToItemDocLine."Item No." := FromItemRcptLine."Item No.";
                                    ToItemDocLine."Variant Code" := FromItemRcptLine."Variant Code";
                                    ToItemDocLine."Location Code" := FromItemRcptLine."Location Code";
                                    ToItemDocLine."Bin Code" := FromItemRcptLine."Bin Code";
                                    ToItemDocLine."Unit of Measure Code" := FromItemRcptLine."Unit of Measure Code";
                                    ToItemDocLine."Qty. per Unit of Measure" := FromItemRcptLine."Qty. per Unit of Measure";
                                    ToItemDocLine.Quantity := FromItemRcptLine.Quantity;
                                    CheckItemAvailable(ToItemDocHeader, ToItemDocLine);
                                end;
                            until FromItemRcptLine.Next = 0;
                        if not IncludeHeader and not RecalculateLines then
                            FromItemRcptHeader.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                    end;
                ItemDocType::"Posted Shipment":
                    begin
                        FromItemShptHeader.Get(FromDocNo);
                        FromItemShptLine.SetRange("Document No.", FromItemShptHeader."No.");
                        if FromItemShptLine.Find('-') then
                            repeat
                                if FromItemShptLine.Quantity > 0 then begin
                                    ToItemDocLine."Item No." := FromItemShptLine."Item No.";
                                    ToItemDocLine."Variant Code" := FromItemShptLine."Variant Code";
                                    ToItemDocLine."Location Code" := FromItemShptLine."Location Code";
                                    ToItemDocLine."Bin Code" := FromItemShptLine."Bin Code";
                                    ToItemDocLine."Unit of Measure Code" := FromItemShptLine."Unit of Measure Code";
                                    ToItemDocLine."Qty. per Unit of Measure" := FromItemShptLine."Qty. per Unit of Measure";
                                    ToItemDocLine.Quantity := FromItemShptLine.Quantity;
                                    CheckItemAvailable(ToItemDocHeader, ToItemDocLine);
                                end;
                            until FromItemShptLine.Next = 0;
                        if not IncludeHeader and not RecalculateLines then
                            FromItemShptHeader.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                    end;
            end;

            ToItemDocLine.LockTable();

            if CreateToHeader then begin
                Insert(true);
                ToItemDocLine.SetRange("Document Type", "Document Type");
                ToItemDocLine.SetRange("Document No.", "No.");
            end else begin
                ToItemDocLine.SetRange("Document Type", "Document Type");
                ToItemDocLine.SetRange("Document No.", "No.");
                if IncludeHeader then
                    if ToItemDocLine.FindFirst then begin
                        Commit();
                        if not
                           Confirm(
                             Text002 +
                             Text003, true,
                             "Document Type", "No.")
                        then
                            exit;
                        ToItemDocLine.DeleteAll(true);
                    end;
            end;

            if ToItemDocLine.FindLast then
                NextLineNo := ToItemDocLine."Line No."
            else
                NextLineNo := 0;

            if IncludeHeader then begin
                OldItemDocHeader := ToItemDocHeader;
                case FromDocType of
                    ItemDocType::Receipt,
                    ItemDocType::Shipment:
                        begin
                            TransferFields(FromItemDocHeader, false);
                            if OldItemDocHeader."Posting Date" = 0D then
                                "Posting Date" := WorkDate
                            else
                                "Posting Date" := OldItemDocHeader."Posting Date";
                        end;
                    ItemDocType::"Posted Receipt":
                        TransferFields(FromItemRcptHeader, false);
                    ItemDocType::"Posted Shipment":
                        TransferFields(FromItemShptHeader, false);
                end;
                Status := Status::Open;
                "No. Series" := OldItemDocHeader."No. Series";
                "Posting Description" := OldItemDocHeader."Posting Description";
                "Posting No." := OldItemDocHeader."Posting No.";
                "Posting No. Series" := OldItemDocHeader."Posting No. Series";
                "No. Printed" := 0;

                if CreateToHeader then begin
                    Modify(true);
                end else
                    Modify;
            end;

            LinesNotCopied := 0;
            case FromDocType of
                ItemDocType::Receipt,
                ItemDocType::Shipment:
                    begin
                        FromItemDocLine.Reset();
                        FromItemDocLine.SetRange("Document Type", FromItemDocHeader."Document Type");
                        FromItemDocLine.SetRange("Document No.", FromItemDocHeader."No.");
                        if FromItemDocLine.Find('-') then
                            repeat
                                CopyItemDocLine(ToItemDocHeader, ToItemDocLine, FromItemDocHeader, FromItemDocLine, NextLineNo, LinesNotCopied);
                            until FromItemDocLine.Next = 0;
                    end;
                ItemDocType::"Posted Receipt":
                    begin
                        FromItemDocHeader.TransferFields(FromItemRcptHeader);
                        FromItemRcptLine.Reset();
                        FromItemRcptLine.SetRange("Document No.", FromItemRcptHeader."No.");
                        if FromItemRcptLine.Find('-') then
                            repeat
                                FromItemDocLine.TransferFields(FromItemRcptLine);
                                CopyItemDocLine(
                                  ToItemDocHeader, ToItemDocLine, FromItemDocHeader, FromItemDocLine,
                                  NextLineNo, LinesNotCopied);
                            until FromItemRcptLine.Next = 0;
                    end;
                ItemDocType::"Posted Shipment":
                    begin
                        FromItemDocHeader.TransferFields(FromItemShptHeader);
                        FromItemDocHeader."Document Type" := FromItemDocHeader."Document Type"::Shipment;
                        FromItemShptLine.Reset();
                        FromItemShptLine.SetRange("Document No.", FromItemShptHeader."No.");
                        if FromItemShptLine.Find('-') then
                            repeat
                                FromItemDocLine.TransferFields(FromItemShptLine);
                                CopyItemDocLine(ToItemDocHeader, ToItemDocLine, FromItemDocHeader, FromItemDocLine, NextLineNo, LinesNotCopied);
                            until FromItemShptLine.Next = 0;
                    end;
            end;
        end;

        if LinesNotCopied > 0 then
            Message(Text004);
    end;

    [Scope('OnPrem')]
    procedure ShowItemDoc(ToItemDocHeader: Record "Item Document Header")
    begin
        with ToItemDocHeader do
            case "Document Type" of
                "Document Type"::Receipt:
                    PAGE.Run(PAGE::"Item Receipt", ToItemDocHeader);
                "Document Type"::Shipment:
                    PAGE.Run(PAGE::"Item Shipment", ToItemDocHeader);
            end;
    end;

    local procedure CopyItemDocLine(var ToItemDocHeader: Record "Item Document Header"; var ToItemDocLine: Record "Item Document Line"; var FromItemDocHeader: Record "Item Document Header"; var FromItemDocLine: Record "Item Document Line"; var NextLineNo: Integer; var LinesNotCopied: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        CopyThisLine: Boolean;
    begin
        CopyThisLine := true;
        if RecalculateLines then
            ToItemDocLine.Init
        else
            ToItemDocLine := FromItemDocLine;
        NextLineNo := NextLineNo + 10000;
        ToItemDocLine."Document Type" := ToItemDocHeader."Document Type";
        ToItemDocLine."Document No." := ToItemDocHeader."No.";
        ToItemDocLine."Line No." := NextLineNo;
        if RecalculateLines then begin
            ToItemDocLine.Validate(Description, FromItemDocLine.Description);
            if FromItemDocLine."Item No." <> '' then begin
                ToItemDocLine.Validate("Item No.", FromItemDocLine."Item No.");
                ToItemDocLine.Validate("Variant Code", FromItemDocLine."Variant Code");
                ToItemDocLine.Validate("Location Code", FromItemDocLine."Location Code");
                ToItemDocLine.Validate("Unit of Measure Code", FromItemDocLine."Unit of Measure Code");
                ToItemDocLine.Validate(Quantity, FromItemDocLine.Quantity);
            end;
        end else begin
            ToItemDocLine."Reserved Quantity Inbnd." := 0;
            ToItemDocLine."Reserved Qty. Inbnd. (Base)" := 0;
            ToItemDocLine."Reserved Quantity Outbnd." := 0;
            ToItemDocLine."Reserved Qty. Outbnd. (Base)" := 0;
            if not CreateToHeader then
                ToItemDocLine."Document Date" := ToItemDocHeader."Document Date";
        end;
        if FillAppliesFields then
            if FromItemDocHeader."Document Type" = FromItemDocHeader."Document Type"::Receipt then
                ToItemDocLine.Validate(
                  "Applies-to Entry",
                  GetItemDocLedgerEntryNo(
                    FromItemDocLine."Document No.",
                    ItemLedgerEntry."Document Type"::"Item Receipt".AsInteger(),
                    FromItemDocLine."Line No."))
            else
                ToItemDocLine.Validate(
                  "Applies-from Entry",
                  GetItemDocLedgerEntryNo(
                    FromItemDocLine."Document No.",
                    ItemLedgerEntry."Document Type"::"Item Shipment".AsInteger(),
                    FromItemDocLine."Line No."));
        if CopyThisLine then
            ToItemDocLine.Insert
        else
            LinesNotCopied := LinesNotCopied + 1;
    end;

    local procedure CheckItemAvailable(var ToItemDocHeader: Record "Item Document Header"; var ToItemDocLine: Record "Item Document Line")
    begin
        if HideDialog then
            exit;

        ToItemDocLine."Document Type" := ToItemDocHeader."Document Type";
        ToItemDocLine."Document No." := ToItemDocHeader."No.";
        ToItemDocLine."Line No." := 0;

        if ToItemDocLine."Document Date" = 0D then begin
            if ToItemDocHeader."Document Date" <> 0D then
                ToItemDocLine.Validate("Document Date", ToItemDocHeader."Document Date")
            else
                ToItemDocLine.Validate("Document Date", WorkDate);
        end;

        ItemCheckAvail.ItemDocCheckLine(ToItemDocLine);
    end;

    [Scope('OnPrem')]
    procedure GetItemDocLedgerEntryNo(DocNo: Code[20]; DocType: Integer; DocLineNo: Integer): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgerEntry do begin
            Reset;
            SetCurrentKey("Document No.", "Document Type", "Document Line No.");
            SetRange("Document No.", DocNo);
            SetRange("Document Type", DocType);
            SetRange("Document Line No.", DocLineNo);

            if FindFirst then
                exit("Entry No.");

            exit(0);
        end;
    end;
}

