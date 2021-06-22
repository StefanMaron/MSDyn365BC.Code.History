table 6507 "Item Entry Relation"
{
    Caption = 'Item Entry Relation';

    fields
    {
        field(1; "Item Entry No."; Integer)
        {
            Caption = 'Item Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(10; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(11; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(12; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(13; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(14; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(15; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(20; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(21; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(30; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(31; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
    }

    keys
    {
        key(Key1; "Item Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Source ID", "Source Type", "Source Subtype", "Source Ref. No.", "Source Prod. Order Line", "Source Batch Name")
        {
        }
        key(Key3; "Order No.", "Order Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure InitFromTrackingSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        Init;
        "Item Entry No." := TrackingSpecification."Entry No.";
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterInitFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgEntry."Serial No.";
        "Lot No." := ItemLedgEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure CopyTrackingFromItemJnlLine(ItemJnlLine: Record "Item Journal Line")
    begin
        "Serial No." := ItemJnlLine."Serial No.";
        "Lot No." := ItemJnlLine."Lot No.";

        OnAfterCopyTrackingFromItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure CopyTrackingFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterCopyTrackingFromSpec(Rec, TrackingSpecification);
    end;

    procedure TransferFieldsSalesShptLine(var SalesShptLine: Record "Sales Shipment Line")
    begin
        SetSource(DATABASE::"Sales Shipment Line", 0, SalesShptLine."Document No.", SalesShptLine."Line No.");
        SetOrderInfo(SalesShptLine."Order No.", SalesShptLine."Order Line No.");
    end;

    procedure TransferFieldsReturnRcptLine(var ReturnRcptLine: Record "Return Receipt Line")
    begin
        SetSource(DATABASE::"Return Receipt Line", 0, ReturnRcptLine."Document No.", ReturnRcptLine."Line No.");
        SetOrderInfo(ReturnRcptLine."Return Order No.", ReturnRcptLine."Return Order Line No.");
    end;

    procedure TransferFieldsPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        SetSource(DATABASE::"Purch. Rcpt. Line", 0, PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        SetOrderInfo(PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
    end;

    procedure TransferFieldsReturnShptLine(var ReturnShptLine: Record "Return Shipment Line")
    begin
        SetSource(DATABASE::"Return Shipment Line", 0, ReturnShptLine."Document No.", ReturnShptLine."Line No.");
        SetOrderInfo(ReturnShptLine."Return Order No.", ReturnShptLine."Return Order Line No.");
    end;

    procedure TransferFieldsTransShptLine(var TransShptLine: Record "Transfer Shipment Line")
    begin
        SetSource(DATABASE::"Transfer Shipment Line", 0, TransShptLine."Document No.", TransShptLine."Line No.");
        SetOrderInfo(TransShptLine."Transfer Order No.", TransShptLine."Line No.");
    end;

    procedure TransferFieldsTransRcptLine(var TransRcptLine: Record "Transfer Receipt Line")
    begin
        SetSource(DATABASE::"Transfer Receipt Line", 0, TransRcptLine."Document No.", TransRcptLine."Line No.");
        SetOrderInfo(TransRcptLine."Transfer Order No.", TransRcptLine."Line No.");
    end;

    procedure TransferFieldsServShptLine(var ServShptLine: Record "Service Shipment Line")
    begin
        SetSource(DATABASE::"Service Shipment Line", 0, ServShptLine."Document No.", ServShptLine."Line No.");
        SetOrderInfo(ServShptLine."Order No.", ServShptLine."Order Line No.");
    end;

    procedure TransferFieldsPostedAsmHeader(var PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
        SetSource(DATABASE::"Posted Assembly Header", 0, PostedAssemblyHeader."No.", 0);
        SetOrderInfo(PostedAssemblyHeader."Order No.", 0);
    end;

    procedure TransferFieldsPostedAsmLine(var PostedAssemblyLine: Record "Posted Assembly Line")
    begin
        SetSource(DATABASE::"Posted Assembly Line", 0, PostedAssemblyLine."Document No.", PostedAssemblyLine."Line No.");
        SetOrderInfo(PostedAssemblyLine."Order No.", PostedAssemblyLine."Order Line No.");
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubtype;
        "Source ID" := SourceID;
        "Source Ref. No." := SourceRefNo;
    end;

    procedure SetSource2(SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        "Source Batch Name" := SourceBatchName;
        "Source Prod. Order Line" := SourceProdOrderLine;
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
        if SourceKey then
            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
        SetRange("Source Type", SourceType);
        SetRange("Source Subtype", SourceSubtype);
        SetRange("Source ID", SourceID);
        if SourceRefNo >= 0 then
            SetRange("Source Ref. No.", SourceRefNo);
    end;

    procedure SetSourceFilter2(SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        SetRange("Source Batch Name", SourceBatchName);
        SetRange("Source Prod. Order Line", SourceProdOrderLine);
    end;

    procedure SetOrderInfo(OrderNo: Code[20]; OrderLineNo: Integer)
    begin
        "Order No." := OrderNo;
        "Order Line No." := OrderLineNo;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromTrackingSpec(var ItemEntryRelation: Record "Item Entry Relation"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var ItemEntryRelation: Record "Item Entry Relation"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemJnlLine(var ItemEntryRelation: Record "Item Entry Relation"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromSpec(var ItemEntryRelation: Record "Item Entry Relation"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;
}

