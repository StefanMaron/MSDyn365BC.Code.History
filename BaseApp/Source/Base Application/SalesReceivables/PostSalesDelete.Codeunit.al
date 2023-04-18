codeunit 363 "PostSales-Delete"
{
    Permissions = TableData "Sales Shipment Header" = ri,
                  TableData "Sales Shipment Line" = rid,
                  TableData "Sales Invoice Header" = ri,
                  TableData "Sales Invoice Line" = rid,
                  TableData "Sales Cr.Memo Header" = ri,
                  TableData "Sales Cr.Memo Line" = rid,
                  TableData "Return Receipt Header" = ri,
                  TableData "Return Receipt Line" = rid;

    trigger OnRun()
    begin
    end;

    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MoveEntries: Codeunit MoveEntries;
        DocumentDeletionErr: Label 'You cannot delete posted sales documents that are posted after %1. \\The date is defined by the Allow Document Deletion Before field in the Sales & Receivables Setup window.', Comment = '%1 - Posting Date';

    procedure DeleteHeader(SalesHeader: Record "Sales Header"; var SalesShptHeader: Record "Sales Shipment Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnRcptHeader: Record "Return Receipt Header"; var SalesInvHeaderPrePmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrePmt: Record "Sales Cr.Memo Header")
    var
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteHeader(SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader, SalesInvHeaderPrePmt, SalesCrMemoHeaderPrePmt, IsHandled);
        if IsHandled then
            exit;

        with SalesHeader do begin
            SourceCodeSetup.Get();
            SourceCodeSetup.TestField("Deleted Document");
            SourceCode.Get(SourceCodeSetup."Deleted Document");

            InitDeleteHeader(
              SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader,
              ReturnRcptHeader, SalesInvHeaderPrePmt, SalesCrMemoHeaderPrePmt, SourceCode.Code);

            if SalesShptHeader."No." <> '' then begin
                SalesShptHeader.Insert();
                SalesShptLine.Init();
                SalesShptLine."Document No." := SalesShptHeader."No.";
                SalesShptLine."Line No." := 10000;
                SalesShptLine.Description := SourceCode.Description;
                SalesShptLine.Insert();
            end;

            if ReturnRcptHeader."No." <> '' then begin
                ReturnRcptHeader.Insert();
                ReturnRcptLine.Init();
                ReturnRcptLine."Document No." := ReturnRcptHeader."No.";
                ReturnRcptLine."Line No." := 10000;
                ReturnRcptLine.Description := SourceCode.Description;
                ReturnRcptLine.Insert();
            end;

            if SalesInvHeader."No." <> '' then begin
                SalesInvHeader.Insert();
                SalesInvLine.Init();
                SalesInvLine."Document No." := SalesInvHeader."No.";
                SalesInvLine."Line No." := 10000;
                SalesInvLine.Description := SourceCode.Description;
                SalesInvLine.Insert();
            end;

            if SalesCrMemoHeader."No." <> '' then begin
                SalesCrMemoHeader.Insert();
                SalesCrMemoLine.Init();
                SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
                SalesCrMemoLine."Line No." := 10000;
                SalesCrMemoLine.Description := SourceCode.Description;
                SalesCrMemoLine.Insert();
            end;

            if SalesInvHeaderPrePmt."No." <> '' then begin
                SalesInvHeaderPrePmt.Insert();
                SalesInvLine."Document No." := SalesInvHeaderPrePmt."No.";
                SalesInvLine."Line No." := 10000;
                SalesInvLine.Description := SourceCode.Description;
                SalesInvLine.Insert();
            end;

            if SalesCrMemoHeaderPrePmt."No." <> '' then begin
                SalesCrMemoHeaderPrePmt.Insert();
                SalesCrMemoLine.Init();
                SalesCrMemoLine."Document No." := SalesCrMemoHeaderPrePmt."No.";
                SalesCrMemoLine."Line No." := 10000;
                SalesCrMemoLine.Description := SourceCode.Description;
                SalesCrMemoLine.Insert();
            end;
        end;

        OnAfterDeleteHeader(
          SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader, SalesInvHeaderPrePmt, SalesCrMemoHeaderPrePmt);
    end;

    procedure DeleteSalesShptLines(SalesShptHeader: Record "Sales Shipment Header")
    var
        SalesShptLine: Record "Sales Shipment Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        if SalesShptLine.Find('-') then
            repeat
                OnDeleteSalesShptLinesOnBeforeSalesShptLineDelete(SalesShptLine);
                SalesShptLine.TestField("Quantity Invoiced", SalesShptLine.Quantity);
                SalesShptLine.Delete(true);
            until SalesShptLine.Next() = 0;

        ItemChargeAssignmentSales.CheckAssignment(
            "Sales Applies-to Document Type"::Shipment, SalesShptLine."Document No.", SalesShptLine."Line No.");

        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Sales Shipment Line", 0, SalesShptHeader."No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Sales Shipment Header", SalesShptHeader."No.");
    end;

    procedure DeleteSalesInvLines(SalesInvHeader: Record "Sales Invoice Header")
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        if SalesInvLine.Find('-') then
            repeat
                OnDeleteSalesInvLinesOnBeforeSalesInvLineDelete(SalesInvLine);
                SalesInvLine.Delete();
                ItemTrackingMgt.DeleteValueEntryRelation(SalesInvLine.RowID1());
            until SalesInvLine.Next() = 0;

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Sales Invoice Header", SalesInvHeader."No.");
    end;

    procedure DeleteSalesCrMemoLines(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.Find('-') then
            repeat
                OnDeleteSalesCrMemoLinesOnBeforeSalesCrMemoLineDelete(SalesCrMemoLine);
                SalesCrMemoLine.Delete();
            until SalesCrMemoLine.Next() = 0;
        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Sales Cr.Memo Line", 0, SalesCrMemoHeader."No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.");
    end;

    procedure DeleteSalesRcptLines(ReturnRcptHeader: Record "Return Receipt Header")
    var
        ReturnRcptLine: Record "Return Receipt Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        if ReturnRcptLine.Find('-') then
            repeat
                OnDeleteSalesRcptLinesOnBeforeSalesRcptLineDelete(ReturnRcptLine);
                ReturnRcptLine.TestField("Quantity Invoiced", ReturnRcptLine.Quantity);
                ReturnRcptLine.Delete();
            until ReturnRcptLine.Next() = 0;

        ItemChargeAssignmentSales.CheckAssignment(
            "Sales Applies-to Document Type"::"Return Receipt", ReturnRcptLine."Document No.", ReturnRcptLine."Line No.");

        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Return Receipt Line", 0, ReturnRcptHeader."No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Return Receipt Header", ReturnRcptHeader."No.");
    end;

    procedure InitDeleteHeader(SalesHeader: Record "Sales Header"; var SalesShptHeader: Record "Sales Shipment Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnRcptHeader: Record "Return Receipt Header"; var SalesInvHeaderPrePmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrePmt: Record "Sales Cr.Memo Header"; SourceCode: Code[10])
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        OnBeforeInitDeleteHeader(
          SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader, SalesInvHeaderPrePmt, SalesCrMemoHeaderPrePmt,
          SourceCode);

        with SalesHeader do begin
            Clear(SalesShptHeader);
            Clear(SalesInvHeader);
            Clear(SalesCrMemoHeader);
            Clear(ReturnRcptHeader);
            SalesSetup.Get();

            if ("Shipping No. Series" <> '') and ("Shipping No." <> '') then begin
                SalesShptHeader.TransferFields(SalesHeader);
                SalesShptHeader."No." := "Shipping No.";
                SalesShptHeader."Posting Date" := Today;
                SalesShptHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(SalesShptHeader."User ID"));
                SalesShptHeader."Source Code" := SourceCode;
            end;

            if ("Return Receipt No. Series" <> '') and ("Return Receipt No." <> '') then begin
                ReturnRcptHeader.TransferFields(SalesHeader);
                ReturnRcptHeader."No." := "Return Receipt No.";
                ReturnRcptHeader."Posting Date" := Today;
                ReturnRcptHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(ReturnRcptHeader."User ID"));
                ReturnRcptHeader."Source Code" := SourceCode;
            end;

            if ("Posting No. Series" <> '') and
               (("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) and
                ("Posting No." <> '') or
                ("Document Type" = "Document Type"::Invoice) and
                ("No. Series" = "Posting No. Series"))
            then
                InitSalesInvHeader(SalesInvHeader, SalesHeader, SourceCode);

            if ("Posting No. Series" <> '') and
               (("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) and
                ("Posting No." <> '') or
                ("Document Type" = "Document Type"::"Credit Memo") and
                ("No. Series" = "Posting No. Series"))
            then begin
                SalesCrMemoHeader.TransferFields(SalesHeader);
                OnInitDeleteHeaderOnAfterSalesCrMemoHeaderTransferFields(SalesCrMemoHeader);
                if "Posting No." <> '' then
                    SalesCrMemoHeader."No." := "Posting No.";
                SalesCrMemoHeader."Pre-Assigned No. Series" := "No. Series";
                SalesCrMemoHeader."Pre-Assigned No." := "No.";
                SalesCrMemoHeader."Posting Date" := Today;
                SalesCrMemoHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(SalesCrMemoHeader."User ID"));
                SalesCrMemoHeader."Source Code" := SourceCode;
            end;
            if ("Prepayment No. Series" <> '') and ("Prepayment No." <> '') then begin
                TestField("Document Type", "Document Type"::Order);
                SalesInvHeaderPrePmt.TransferFields(SalesHeader);
                SalesInvHeaderPrePmt."No." := "Prepayment No.";
                SalesInvHeaderPrePmt."Order No. Series" := "No. Series";
                SalesInvHeaderPrePmt."Prepayment Order No." := "No.";
                SalesInvHeaderPrePmt."Posting Date" := Today;
                SalesInvHeaderPrePmt."Pre-Assigned No. Series" := '';
                SalesInvHeaderPrePmt."Pre-Assigned No." := '';
                SalesInvHeaderPrePmt."User ID" := CopyStr(UserId(), 1, MaxStrLen(SalesInvHeaderPrePmt."User ID"));
                SalesInvHeaderPrePmt."Source Code" := SourceCode;
                SalesInvHeaderPrePmt."Prepayment Invoice" := true;
            end;

            if ("Prepmt. Cr. Memo No. Series" <> '') and ("Prepmt. Cr. Memo No." <> '') then begin
                TestField("Document Type", "Document Type"::Order);
                SalesCrMemoHeaderPrePmt.TransferFields(SalesHeader);
                SalesCrMemoHeaderPrePmt."No." := "Prepmt. Cr. Memo No.";
                SalesCrMemoHeaderPrePmt."Prepayment Order No." := "No.";
                SalesCrMemoHeaderPrePmt."Posting Date" := Today;
                SalesCrMemoHeaderPrePmt."Pre-Assigned No. Series" := '';
                SalesCrMemoHeaderPrePmt."Pre-Assigned No." := '';
                SalesCrMemoHeaderPrePmt."User ID" := CopyStr(UserId(), 1, MaxStrLen(SalesCrMemoHeaderPrePmt."User ID"));
                SalesCrMemoHeaderPrePmt."Source Code" := SourceCode;
                SalesCrMemoHeaderPrePmt."Prepayment Credit Memo" := true;
            end;
        end;

        OnAfterInitDeleteHeader(
          SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader, SalesInvHeaderPrePmt, SalesCrMemoHeaderPrePmt);
    end;

    local procedure InitSalesInvHeader(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; SourceCode: Code[10])
    begin
        with SalesHeader do begin
            SalesInvHeader.TransferFields(SalesHeader);
            if "Posting No." <> '' then
                SalesInvHeader."No." := "Posting No.";
            if "Document Type" = "Document Type"::Invoice then begin
                SalesInvHeader."Pre-Assigned No. Series" := "No. Series";
                SalesInvHeader."Pre-Assigned No." := "No.";
            end else begin
                SalesInvHeader."Pre-Assigned No. Series" := '';
                SalesInvHeader."Pre-Assigned No." := '';
                SalesInvHeader."Order No. Series" := "No. Series";
                SalesInvHeader."Order No." := "No.";
            end;
            SalesInvHeader."Posting Date" := Today;
            SalesInvHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(SalesInvHeader."User ID"));
            SalesInvHeader."Source Code" := SourceCode;
        end;

        OnAfterInitSalesInvHeader(SalesInvHeader, SalesHeader);
    end;

    procedure IsDocumentDeletionAllowed(PostingDate: Date)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.TestField("Allow Document Deletion Before");
        if PostingDate >= SalesSetup."Allow Document Deletion Before" then
            Error(DocumentDeletionErr, SalesSetup."Allow Document Deletion Before");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDeleteHeader(SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var SalesInvoiceHeaderPrepmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrepmt: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSalesInvHeader(var SalesInvHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitDeleteHeaderOnAfterSalesCrMemoHeaderTransferFields(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteHeader(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var SalesInvoiceHeaderPrepmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrepmt: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteHeader(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var SalesInvoiceHeaderPrepmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrepmt: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitDeleteHeader(var SalesHeader: Record "Sales Header"; var SalesShptHeader: Record "Sales Shipment Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnRcptHeader: Record "Return Receipt Header"; var SalesInvHeaderPrePmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrePmt: Record "Sales Cr.Memo Header"; var SourceCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesShptLinesOnBeforeSalesShptLineDelete(var SalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesInvLinesOnBeforeSalesInvLineDelete(var SalesInvoiceLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesCrMemoLinesOnBeforeSalesCrMemoLineDelete(var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesRcptLinesOnBeforeSalesRcptLineDelete(var SalesRcptLine: Record "Return Receipt Line")
    begin
    end;
}

