codeunit 5857 "Copy Invt. Document Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        InvtDocType: Enum "Invt. Doc. Document Type From";
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;
        CreateToHeader: Boolean;
        HideDialog: Boolean;
        FillAppliesFields: Boolean;
        MissingDocumentNoErr: Label 'Please enter a Document No.';
        CannotCopyToItselfErr: Label '%1 %2 cannot be copied onto itself.', Comment = '%1 = document type, %2 = document number';
        LinesWillBeDeletedQst: Label 'The existing lines for %1 %2 will be deleted.\\Do you want to continue?', Comment = '%1 = document type, %2 = document number';
        LinesNotCopiedMsg: Label 'The document line(s) with a G/L account where direct posting is not allowed have not been copied to the new document by the Copy Document batch job.';
        LinesNotAppliedMsg: Label 'There is %1 document line(s) with Item Tracking which requires manual specify of apply to/from numbers within Item Tracking Lines', Comment = '%1-line count';

    procedure SetProperties(NewIncludeHeader: Boolean; NewRecalculateLines: Boolean; NewCreateToHeader: Boolean; NewHideDialog: Boolean; NewFillAppliesFields: Boolean)
    begin
        IncludeHeader := NewIncludeHeader;
        RecalculateLines := NewRecalculateLines;
        CreateToHeader := NewCreateToHeader;
        HideDialog := NewHideDialog;
        FillAppliesFields := NewFillAppliesFields;
    end;

    procedure CopyItemDoc(FromDocType: Enum "Invt. Doc. Document Type From"; FromDocNo: Code[20]; var ToInvtDocHeader: Record "Invt. Document Header")
    var
        ToInvtDocLine: Record "Invt. Document Line";
        OldInvtDocHeader: Record "Invt. Document Header";
        FromInvtDocHeader: Record "Invt. Document Header";
        FromInvtDocLine: Record "Invt. Document Line";
        FromInvtRcptHeader: Record "Invt. Receipt Header";
        FromInvtRcptLine: Record "Invt. Receipt Line";
        FromInvtShptHeader: Record "Invt. Shipment Header";
        FromInvtShptLine: Record "Invt. Shipment Line";
        NextLineNo: Integer;
        LinesNotCopied: Integer;
        LinesSkipApplies: Integer;
    begin
        with ToInvtDocHeader do begin
            if not CreateToHeader then begin
                TestField(Status, Status::Open);
                if FromDocNo = '' then
                    Error(MissingDocumentNoErr);
                Find();
            end;
            TransferOldExtLines.ClearLineNumbers();
            case FromDocType of
                InvtDocType::Receipt,
                InvtDocType::Shipment:
                    begin
                        FromInvtDocHeader.Get(FromDocType, FromDocNo);
                        if (FromInvtDocHeader."Document Type" = "Document Type") and
                           (FromInvtDocHeader."No." = "No.")
                        then
                            Error(CannotCopyToItselfErr, "Document Type", "No.");

                        FromInvtDocLine.SetRange("Document Type", FromInvtDocHeader."Document Type");
                        FromInvtDocLine.SetRange("Document No.", FromInvtDocHeader."No.");
                        if FromInvtDocLine.Find('-') then
                            repeat
                                if FromInvtDocLine.Quantity > 0 then begin
                                    ToInvtDocLine."Item No." := FromInvtDocLine."Item No.";
                                    ToInvtDocLine."Variant Code" := FromInvtDocLine."Variant Code";
                                    ToInvtDocLine."Location Code" := FromInvtDocLine."Location Code";
                                    ToInvtDocLine."Bin Code" := FromInvtDocLine."Bin Code";
                                    ToInvtDocLine."Unit of Measure Code" := FromInvtDocLine."Unit of Measure Code";
                                    ToInvtDocLine."Qty. per Unit of Measure" := FromInvtDocLine."Qty. per Unit of Measure";
                                    ToInvtDocLine."Qty. Rounding Precision" := FromInvtDocLine."Qty. Rounding Precision";
                                    ToInvtDocLine."Qty. Rounding Precision (Base)" := FromInvtDocLine."Qty. Rounding Precision (Base)";
                                    ToInvtDocLine.Quantity := FromInvtDocLine.Quantity;
                                    CheckItemAvailable(ToInvtDocHeader, ToInvtDocLine);
                                end;
                            until FromInvtDocLine.Next() = 0;
                        if not IncludeHeader and not RecalculateLines then
                            FromInvtDocHeader.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                    end;
                InvtDocType::"Posted Receipt":
                    begin
                        FromInvtRcptHeader.Get(FromDocNo);
                        FromInvtRcptLine.SetRange("Document No.", FromInvtRcptHeader."No.");
                        if FromInvtRcptLine.Find('-') then
                            repeat
                                if FromInvtRcptLine.Quantity > 0 then begin
                                    ToInvtDocLine."Item No." := FromInvtRcptLine."Item No.";
                                    ToInvtDocLine."Variant Code" := FromInvtRcptLine."Variant Code";
                                    ToInvtDocLine."Location Code" := FromInvtRcptLine."Location Code";
                                    ToInvtDocLine."Bin Code" := FromInvtRcptLine."Bin Code";
                                    ToInvtDocLine."Unit of Measure Code" := FromInvtRcptLine."Unit of Measure Code";
                                    ToInvtDocLine."Qty. per Unit of Measure" := FromInvtRcptLine."Qty. per Unit of Measure";
                                    ToInvtDocLine."Qty. Rounding Precision" := FromInvtRcptLine."Qty. Rounding Precision";
                                    ToInvtDocLine."Qty. Rounding Precision (Base)" := FromInvtRcptLine."Qty. Rounding Precision (Base)";
                                    ToInvtDocLine.Quantity := FromInvtRcptLine.Quantity;
                                    CheckItemAvailable(ToInvtDocHeader, ToInvtDocLine);
                                end;
                            until FromInvtRcptLine.Next() = 0;
                        if not IncludeHeader and not RecalculateLines then
                            FromInvtRcptHeader.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                    end;
                InvtDocType::"Posted Shipment":
                    begin
                        FromInvtShptHeader.Get(FromDocNo);
                        FromInvtShptLine.SetRange("Document No.", FromInvtShptHeader."No.");
                        if FromInvtShptLine.Find('-') then
                            repeat
                                if FromInvtShptLine.Quantity > 0 then begin
                                    ToInvtDocLine."Item No." := FromInvtShptLine."Item No.";
                                    ToInvtDocLine."Variant Code" := FromInvtShptLine."Variant Code";
                                    ToInvtDocLine."Location Code" := FromInvtShptLine."Location Code";
                                    ToInvtDocLine."Bin Code" := FromInvtShptLine."Bin Code";
                                    ToInvtDocLine."Unit of Measure Code" := FromInvtShptLine."Unit of Measure Code";
                                    ToInvtDocLine."Qty. per Unit of Measure" := FromInvtShptLine."Qty. per Unit of Measure";
                                    ToInvtDocLine."Qty. Rounding Precision" := FromInvtShptLine."Qty. Rounding Precision";
                                    ToInvtDocLine."Qty. Rounding Precision (Base)" := FromInvtShptLine."Qty. Rounding Precision (Base)";
                                    ToInvtDocLine.Quantity := FromInvtShptLine.Quantity;
                                    CheckItemAvailable(ToInvtDocHeader, ToInvtDocLine);
                                end;
                            until FromInvtShptLine.Next() = 0;
                        if not IncludeHeader and not RecalculateLines then
                            FromInvtShptHeader.TestField("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                    end;
            end;

            ToInvtDocLine.LockTable();

            if CreateToHeader then begin
                Insert(true);
                ToInvtDocLine.SetRange("Document Type", "Document Type");
                ToInvtDocLine.SetRange("Document No.", "No.");
            end else begin
                ToInvtDocLine.SetRange("Document Type", "Document Type");
                ToInvtDocLine.SetRange("Document No.", "No.");
                if IncludeHeader then
                    if ToInvtDocLine.FindFirst() then begin
                        Commit();
                        if not Confirm(LinesWillBeDeletedQst, true, "Document Type", "No.") then
                            exit;
                        ToInvtDocLine.DeleteAll(true);
                    end;
            end;

            if ToInvtDocLine.FindLast() then
                NextLineNo := ToInvtDocLine."Line No."
            else
                NextLineNo := 0;

            if IncludeHeader then begin
                OldInvtDocHeader := ToInvtDocHeader;
                case FromDocType of
                    InvtDocType::Receipt,
                    InvtDocType::Shipment:
                        begin
                            TransferFields(FromInvtDocHeader, false);
                            if OldInvtDocHeader."Posting Date" = 0D then
                                "Posting Date" := WorkDate()
                            else
                                "Posting Date" := OldInvtDocHeader."Posting Date";
                        end;
                    InvtDocType::"Posted Receipt":
                        TransferFields(FromInvtRcptHeader, false);
                    InvtDocType::"Posted Shipment":
                        TransferFields(FromInvtShptHeader, false);
                end;
                Status := Status::Open;
                "No. Series" := OldInvtDocHeader."No. Series";
                "Posting Description" := OldInvtDocHeader."Posting Description";
                "Posting No." := OldInvtDocHeader."Posting No.";
                "Posting No. Series" := OldInvtDocHeader."Posting No. Series";
                "No. Printed" := 0;

                if CreateToHeader then
                    Modify(true)
                else
                    Modify();
            end;

            LinesNotCopied := 0;
            LinesSkipApplies := 0;
            case FromDocType of
                InvtDocType::Receipt,
                InvtDocType::Shipment:
                    begin
                        FromInvtDocLine.Reset();
                        FromInvtDocLine.SetRange("Document Type", FromInvtDocHeader."Document Type");
                        FromInvtDocLine.SetRange("Document No.", FromInvtDocHeader."No.");
                        if FromInvtDocLine.Find('-') then
                            repeat
                                CopyInvtDocLine(ToInvtDocHeader, ToInvtDocLine, FromInvtDocHeader, FromInvtDocLine, NextLineNo, LinesNotCopied, LinesSkipApplies);
                            until FromInvtDocLine.Next() = 0;
                    end;
                InvtDocType::"Posted Receipt":
                    begin
                        FromInvtDocHeader.TransferFields(FromInvtRcptHeader);
                        FromInvtRcptLine.Reset();
                        FromInvtRcptLine.SetRange("Document No.", FromInvtRcptHeader."No.");
                        if FromInvtRcptLine.Find('-') then
                            repeat
                                FromInvtDocLine.TransferFields(FromInvtRcptLine);
                                CopyInvtDocLine(
                                  ToInvtDocHeader, ToInvtDocLine, FromInvtDocHeader, FromInvtDocLine,
                                  NextLineNo, LinesNotCopied, LinesSkipApplies);
                            until FromInvtRcptLine.Next() = 0;
                    end;
                InvtDocType::"Posted Shipment":
                    begin
                        FromInvtDocHeader.TransferFields(FromInvtShptHeader);
                        FromInvtDocHeader."Document Type" := FromInvtDocHeader."Document Type"::Shipment;
                        FromInvtShptLine.Reset();
                        FromInvtShptLine.SetRange("Document No.", FromInvtShptHeader."No.");
                        if FromInvtShptLine.Find('-') then
                            repeat
                                FromInvtDocLine.TransferFields(FromInvtShptLine);
                                CopyInvtDocLine(ToInvtDocHeader, ToInvtDocLine, FromInvtDocHeader, FromInvtDocLine, NextLineNo, LinesNotCopied, LinesSkipApplies);
                            until FromInvtShptLine.Next() = 0;
                    end;
            end;
        end;

        if LinesNotCopied > 0 then
            Message(LinesNotCopiedMsg);

        if LinesSkipApplies > 0 then
            Message(LinesNotAppliedMsg, LinesSkipApplies);
    end;

    local procedure CopyInvtDocLine(var ToInvtDocHeader: Record "Invt. Document Header"; var ToInvtDocLine: Record "Invt. Document Line"; var FromInvtDocHeader: Record "Invt. Document Header"; var FromInvtDocLine: Record "Invt. Document Line"; var NextLineNo: Integer; var LinesNotCopied: Integer; var LinesSkipApplies: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        CopyThisLine: Boolean;
    begin
        CopyThisLine := true;
        if RecalculateLines then
            ToInvtDocLine.Init()
        else
            ToInvtDocLine := FromInvtDocLine;
        NextLineNo := NextLineNo + 10000;
        ToInvtDocLine."Document Type" := ToInvtDocHeader."Document Type";
        ToInvtDocLine."Document No." := ToInvtDocHeader."No.";
        ToInvtDocLine."Line No." := NextLineNo;
        if RecalculateLines then begin
            ToInvtDocLine.Validate(Description, FromInvtDocLine.Description);
            if FromInvtDocLine."Item No." <> '' then begin
                ToInvtDocLine.Validate("Item No.", FromInvtDocLine."Item No.");
                ToInvtDocLine.Validate("Variant Code", FromInvtDocLine."Variant Code");
                ToInvtDocLine.Validate("Location Code", FromInvtDocLine."Location Code");
                ToInvtDocLine.Validate("Unit of Measure Code", FromInvtDocLine."Unit of Measure Code");
                ToInvtDocLine.Validate(Quantity, FromInvtDocLine.Quantity);
            end;
        end else begin
            ToInvtDocLine."Reserved Quantity Inbnd." := 0;
            ToInvtDocLine."Reserved Qty. Inbnd. (Base)" := 0;
            ToInvtDocLine."Reserved Quantity Outbnd." := 0;
            ToInvtDocLine."Reserved Qty. Outbnd. (Base)" := 0;
            if not CreateToHeader then
                ToInvtDocLine."Document Date" := ToInvtDocHeader."Document Date";
        end;
        if FillAppliesFields then begin
            if FromInvtDocHeader."Document Type" = FromInvtDocHeader."Document Type"::Receipt then
                ToInvtDocLine.Validate(
                  "Applies-to Entry",
                  GetItemDocLedgerEntryNo(
                    FromInvtDocLine."Document No.",
                    ItemLedgerEntry."Document Type"::"Inventory Receipt".AsInteger(),
                    FromInvtDocLine."Line No."))
            else
                ToInvtDocLine.Validate(
                  "Applies-from Entry",
                  GetItemDocLedgerEntryNo(
                    FromInvtDocLine."Document No.",
                    ItemLedgerEntry."Document Type"::"Inventory Shipment".AsInteger(),
                    FromInvtDocLine."Line No."));

            if (ToInvtDocLine."Applies-to Entry" = 0) and (ToInvtDocLine."Applies-from Entry" = 0) then
                LinesSkipApplies += 1;
        end;
        if CopyThisLine then
            ToInvtDocLine.Insert()
        else
            LinesNotCopied := LinesNotCopied + 1;
    end;

    procedure CheckItemAvailable(var ToInvtDocHeader: Record "Invt. Document Header"; var ToInvtDocLine: Record "Invt. Document Line")
    begin
        if HideDialog then
            exit;

        ToInvtDocLine."Document Type" := ToInvtDocHeader."Document Type";
        ToInvtDocLine."Document No." := ToInvtDocHeader."No.";
        ToInvtDocLine."Line No." := 0;

        if ToInvtDocLine."Document Date" = 0D then
            if ToInvtDocHeader."Document Date" <> 0D then
                ToInvtDocLine.Validate("Document Date", ToInvtDocHeader."Document Date")
            else
                ToInvtDocLine.Validate("Document Date", WorkDate());

        ItemCheckAvail.InvtDocCheckLine(ToInvtDocLine);
    end;

    procedure GetItemDocLedgerEntryNo(DocNo: Code[20]; DocType: Integer; DocLineNo: Integer): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgerEntry.SetRange("Document No.", DocNo);
        ItemLedgerEntry.SetRange("Document Type", DocType);
        ItemLedgerEntry.SetRange("Document Line No.", DocLineNo);
        if ItemLedgerEntry.FindFirst() then
            if not ItemLedgerEntry.TrackingExists() then
                exit(ItemLedgerEntry."Entry No.");

        exit(0);
    end;
}

