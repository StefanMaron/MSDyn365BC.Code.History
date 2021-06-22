report 6521 "Item Tracking Appendix"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ItemTrackingAppendix.rdlc';
    Caption = 'Item Tracking Appendix';

    dataset
    {
        dataitem(MainRecord; "Integer")
        {
            DataItemTableView = SORTING(Number);
            PrintOnlyIfDetail = false;
            dataitem(PageLoop; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(Addr1; Addr[1])
                {
                }
                column(Addr2; Addr[2])
                {
                }
                column(SourceCaption; SourceCaption)
                {
                }
                column(Addr3; Addr[3])
                {
                }
                column(Addr4; Addr[4])
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(Addr5; Addr[5])
                {
                }
                column(Addr6; Addr[6])
                {
                }
                column(DocumentDate; Format(DocumentDate))
                {
                }
                column(Addr7; Addr[7])
                {
                }
                column(Addr8; Addr[8])
                {
                }
                column(Addr2Caption; Addr2Caption)
                {
                }
                column(Addr21; Addr2[1])
                {
                }
                column(Addr22; Addr2[2])
                {
                }
                column(Addr23; Addr2[3])
                {
                }
                column(Addr24; Addr2[4])
                {
                }
                column(Addr25; Addr2[5])
                {
                }
                column(Addr26; Addr2[6])
                {
                }
                column(Addr27; Addr2[7])
                {
                }
                column(Addr28; Addr2[8])
                {
                }
                column(ShowAddr2; ShowAddr2)
                {
                }
                column(ItemTrackingAppendixCaption; ItemTrackingAppendixCaptionLbl)
                {
                }
                column(DocumentDateCaption; DocumentDateCaptionLbl)
                {
                }
                column(PageCaption; PageCaptionLbl)
                {
                }
                dataitem(ItemTrackingLine; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    PrintOnlyIfDetail = false;
                    column(SerialNo_ItemTrackingLine; TrackingSpecBuffer."Serial No.")
                    {
                    }
                    column(No_ItemTrackingLine; TrackingSpecBuffer."Item No.")
                    {
                    }
                    column(Desc_ItemTrackingLine; TrackingSpecBuffer.Description)
                    {
                    }
                    column(Qty_ItemTrackingLine; TrackingSpecBuffer."Quantity (Base)")
                    {
                    }
                    column(LotNo; TrackingSpecBuffer."Lot No.")
                    {
                    }
                    column(ShowGroup; ShowGroup)
                    {
                    }
                    column(NoCaption; NoCaptionLbl)
                    {
                    }
                    column(DescriptionCaption; DescriptionCaptionLbl)
                    {
                    }
                    column(QuantityCaption; QuantityCaptionLbl)
                    {
                    }
                    column(LotNoCaption; LotNoCaptionLbl)
                    {
                    }
                    column(SerialNoCaption; SerialNoCaptionLbl)
                    {
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                        column(TotalQuantity; TotalQty)
                        {
                        }
                        column(ShowTotal; ShowTotal)
                        {
                        }
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            TrackingSpecBuffer.FindSet
                        else
                            TrackingSpecBuffer.Next;

                        if TrackingSpecBuffer.Correction then
                            TrackingSpecBuffer."Quantity (Base)" := -TrackingSpecBuffer."Quantity (Base)";

                        ShowTotal := false;
                        if IsStartNewGroup(TrackingSpecBuffer) then
                            ShowTotal := true;

                        ShowGroup := false;
                        if (TrackingSpecBuffer."Source Ref. No." <> OldRefNo) or
                           (TrackingSpecBuffer."Item No." <> OldNo)
                        then begin
                            OldRefNo := TrackingSpecBuffer."Source Ref. No.";
                            OldNo := TrackingSpecBuffer."Item No.";
                            TotalQty := 0;
                        end else
                            ShowGroup := true;
                        TotalQty += TrackingSpecBuffer."Quantity (Base)";
                    end;

                    trigger OnPreDataItem()
                    begin
                        if TrackingSpecCount = 0 then
                            CurrReport.Break();
                        SetRange(Number, 1, TrackingSpecCount);
                        TrackingSpecBuffer.SetCurrentKey("Source ID", "Source Type", "Source Subtype", "Source Batch Name",
                          "Source Prod. Order Line", "Source Ref. No.");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    // exclude documents without Item Tracking
                    if TrackingSpecCount = 0 then begin
                        CurrReport.Break();
                    end;
                    OldRefNo := 0;
                    ShowGroup := false;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                HandleRec(Number);
            end;

            trigger OnPreDataItem()
            begin
                if MainRecCount = 0 then
                    CurrReport.Break();
                SetRange(Number, 1, MainRecCount);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Document; DocType)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Document';
                        Lookup = false;
                        OptionCaption = 'Sales Quote,Sales Order,Sales Invoice,Sales Credit Memo,Sales Return Order,Sales Post. Shipment,Sales Post. Invoice,Purch. Quote,Purch. Order,Purch. Invoice,Purch. Credit Memo,Purch. Return Order';
                        ToolTip = 'Specifies the type of document for which you would like to print the item tracking numbers.';
                    }
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the document for which you would like to print the item tracking numbers.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        SetRecordFilter;
    end;

    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesShipmentHdr: Record "Sales Shipment Header";
        SalesInvoiceHdr: Record "Sales Invoice Header";
        TrackingSpecBuffer: Record "Tracking Specification" temporary;
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        FormatAddr: Codeunit "Format Address";
        DocNo: Code[20];
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
        Addr: array[8] of Text[100];
        Addr2: array[8] of Text[100];
        SourceCaption: Text;
        Addr2Caption: Text;
        ShowAddr2: Boolean;
        ShowGroup: Boolean;
        ShowTotal: Boolean;
        DocumentDate: Date;
        MainRecCount: Integer;
        Text002: Label 'Pay-to Address';
        Text003: Label 'Bill-to Address';
        TrackingSpecCount: Integer;
        Text004: Label 'Sales - Shipment';
        OldRefNo: Integer;
        OldNo: Code[20];
        TotalQty: Decimal;
        Text005: Label 'Sales - Invoice';
        Text006: Label 'Sales';
        Text007: Label 'Purchase';
        ItemTrackingAppendixCaptionLbl: Label 'Item Tracking - Appendix';
        DocumentDateCaptionLbl: Label 'Document Date';
        PageCaptionLbl: Label 'Page';
        NoCaptionLbl: Label 'No.';
        DescriptionCaptionLbl: Label 'Description';
        QuantityCaptionLbl: Label 'Quantity';
        LotNoCaptionLbl: Label 'Lot No.';
        SerialNoCaptionLbl: Label 'Serial No.';

    local procedure SetRecordFilter()
    begin
        case DocType of
            DocType::"Sales Quote", DocType::"Sales Order", DocType::"Sales Invoice",
          DocType::"Sales Credit Memo", DocType::"Sales Return Order":
                FilterSalesHdr;
            DocType::"Purch. Quote", DocType::"Purch. Order", DocType::"Purch. Invoice",
          DocType::"Purch. Credit Memo", DocType::"Purch. Return Order":
                FilterPurchHdr;
            DocType::"Sales Post. Shipment":
                FilterSalesShip;
            DocType::"Sales Post. Invoice":
                FilterSalesInv;
        end;
    end;

    local procedure HandleRec(Nr: Integer)
    begin
        case DocType of
            DocType::"Sales Quote", DocType::"Sales Order", DocType::"Sales Invoice",
            DocType::"Sales Credit Memo", DocType::"Sales Return Order":
                begin
                    if Nr = 1 then
                        SalesHeader.FindSet
                    else
                        SalesHeader.Next;
                    HandleSales;
                end;
            DocType::"Purch. Quote", DocType::"Purch. Order", DocType::"Purch. Invoice",
            DocType::"Purch. Credit Memo", DocType::"Purch. Return Order":
                begin
                    if Nr = 1 then
                        PurchaseHeader.FindSet
                    else
                        PurchaseHeader.Next;
                    HandlePurchase;
                end;
            DocType::"Sales Post. Shipment":
                begin
                    if Nr = 1 then
                        SalesShipmentHdr.FindSet
                    else
                        SalesShipmentHdr.Next;
                    HandleShipment;
                end;
            DocType::"Sales Post. Invoice":
                begin
                    if Nr = 1 then
                        SalesInvoiceHdr.FindSet
                    else
                        SalesInvoiceHdr.Next;
                    HandleInvoice;
                end;
        end;
    end;

    local procedure HandleSales()
    begin
        AddressSalesHdr(SalesHeader);
        TrackingSpecCount :=
          ItemTrackingDocMgt.RetrieveDocumentItemTracking(TrackingSpecBuffer, SalesHeader."No.",
            DATABASE::"Sales Header", SalesHeader."Document Type");
    end;

    local procedure HandlePurchase()
    begin
        AddressPurchaseHdr(PurchaseHeader);
        TrackingSpecCount :=
          ItemTrackingDocMgt.RetrieveDocumentItemTracking(TrackingSpecBuffer, PurchaseHeader."No.",
            DATABASE::"Purchase Header", PurchaseHeader."Document Type");
    end;

    local procedure HandleShipment()
    begin
        AddressShipmentHdr(SalesShipmentHdr);
        TrackingSpecCount :=
          ItemTrackingDocMgt.RetrieveDocumentItemTracking(TrackingSpecBuffer, SalesShipmentHdr."No.",
            DATABASE::"Sales Shipment Header", 0);
    end;

    local procedure HandleInvoice()
    begin
        AddressInvoiceHdr(SalesInvoiceHdr);
        TrackingSpecCount :=
          ItemTrackingDocMgt.RetrieveDocumentItemTracking(TrackingSpecBuffer, SalesInvoiceHdr."No.",
            DATABASE::"Sales Invoice Header", 0);
    end;

    local procedure AddressSalesHdr(SalesHdr: Record "Sales Header")
    begin
        ShowAddr2 := false;
        with SalesHdr do begin
            case "Document Type" of
                "Document Type"::Invoice, "Document Type"::"Credit Memo":
                    begin
                        FormatAddr.SalesHeaderSellTo(Addr, SalesHdr);
                        if "Bill-to Customer No." <> "Sell-to Customer No." then begin
                            FormatAddr.SalesHeaderBillTo(Addr2, SalesHdr);
                            ShowAddr2 := true;
                        end;
                    end
                else
                    FormatAddr.SalesHeaderBillTo(Addr, SalesHdr);
            end;
            DocumentDate := "Document Date";
            SourceCaption := StrSubstNo('%1 %2 %3', Text006, "Document Type", "No.");
            Addr2Caption := Text003;
        end;
    end;

    local procedure AddressPurchaseHdr(PurchaseHdr: Record "Purchase Header")
    begin
        ShowAddr2 := false;
        with PurchaseHdr do begin
            case "Document Type" of
                "Document Type"::Quote, "Document Type"::"Blanket Order":
                    FormatAddr.PurchHeaderPayTo(Addr, PurchaseHdr);
                "Document Type"::Order, "Document Type"::"Return Order":
                    begin
                        FormatAddr.PurchHeaderBuyFrom(Addr, PurchaseHdr);
                        if "Buy-from Vendor No." <> "Pay-to Vendor No." then begin
                            FormatAddr.PurchHeaderPayTo(Addr2, PurchaseHdr);
                            ShowAddr2 := true;
                        end;
                    end;
                "Document Type"::Invoice, "Document Type"::"Credit Memo":
                    begin
                        FormatAddr.PurchHeaderPayTo(Addr, PurchaseHdr);
                        if not ("Pay-to Vendor No." in ['', "Buy-from Vendor No."]) then begin
                            FormatAddr.PurchHeaderBuyFrom(Addr2, PurchaseHdr);
                            ShowAddr2 := true;
                        end;
                    end;
            end;
            DocumentDate := "Document Date";
            SourceCaption := StrSubstNo('%1 %2 %3', Text007, "Document Type", "No.");
            Addr2Caption := Text002;
        end;
    end;

    local procedure AddressShipmentHdr(SalesShipHdr: Record "Sales Shipment Header")
    begin
        ShowAddr2 := false;
        with SalesShipHdr do begin
            FormatAddr.SalesShptShipTo(Addr, SalesShipHdr);
            if "Bill-to Customer No." <> "Sell-to Customer No." then begin
                FormatAddr.SalesShptBillTo(Addr2, Addr2, SalesShipHdr);
                ShowAddr2 := true;
            end;
            DocumentDate := "Document Date";
            SourceCaption := StrSubstNo('%1 %2', Text004, "No.");
            Addr2Caption := Text003;
        end;
    end;

    local procedure AddressInvoiceHdr(SalesInvHdr: Record "Sales Invoice Header")
    begin
        ShowAddr2 := false;
        with SalesInvHdr do begin
            FormatAddr.SalesInvBillTo(Addr, SalesInvHdr);
            DocumentDate := "Document Date";
            SourceCaption := StrSubstNo('%1 %2', Text005, "No.");
            Addr2Caption := Text002;
        end;
    end;

    procedure IsStartNewGroup(var TrackingSpecBuffer: Record "Tracking Specification" temporary): Boolean
    var
        TrackingSpecBuffer2: Record "Tracking Specification" temporary;
        SourceRef: Integer;
    begin
        TrackingSpecBuffer2 := TrackingSpecBuffer;
        SourceRef := TrackingSpecBuffer2."Source Ref. No.";
        if TrackingSpecBuffer.Next = 0 then begin
            TrackingSpecBuffer := TrackingSpecBuffer2;
            exit(true);
        end;
        if SourceRef <> TrackingSpecBuffer."Source Ref. No." then begin
            TrackingSpecBuffer := TrackingSpecBuffer2;
            exit(true);
        end;
        TrackingSpecBuffer := TrackingSpecBuffer2;
        exit(false);
    end;

    local procedure FilterSalesHdr()
    begin
        case DocType of
            DocType::"Sales Quote":
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
            DocType::"Sales Order":
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
            DocType::"Sales Invoice":
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
            DocType::"Sales Credit Memo":
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
            DocType::"Sales Return Order":
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        end;
        if DocNo <> '' then
            SalesHeader.SetFilter("No.", DocNo);
        MainRecCount := SalesHeader.Count();
    end;

    local procedure FilterSalesShip()
    begin
        if DocNo <> '' then
            SalesShipmentHdr.SetRange("No.", DocNo);
        MainRecCount := SalesShipmentHdr.Count();
    end;

    local procedure FilterSalesInv()
    begin
        if DocNo <> '' then
            SalesInvoiceHdr.SetRange("No.", DocNo);
        MainRecCount := SalesInvoiceHdr.Count();
    end;

    local procedure FilterPurchHdr()
    begin
        case DocType of
            DocType::"Purch. Quote":
                PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
            DocType::"Purch. Order":
                PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
            DocType::"Purch. Invoice":
                PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
            DocType::"Purch. Credit Memo":
                PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
            DocType::"Purch. Return Order":
                PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Return Order");
        end;
        if DocNo <> '' then
            PurchaseHeader.SetFilter("No.", DocNo);
        MainRecCount := PurchaseHeader.Count();
    end;
}

