﻿namespace Microsoft.Manufacturing.Reports;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

report 99000789 "Subcontractor - Dispatch List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/SubcontractorDispatchList.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Subcontractor - Dispatch List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(Name_VendorCaption; FieldCaption(Name))
            {
            }
            column(No_VendorCaption; FieldCaption("No."))
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(OprtnNo_ProdOrderRtngLineCaption; "Prod. Order Routing Line".FieldCaption("Operation No."))
            {
            }
            column(PONo_ProdOrderRtngLineCaption; "Prod. Order Routing Line".FieldCaption("Prod. Order No."))
            {
            }
            column(Desc_ProdOrderRtngLineCaption; "Prod. Order Routing Line".FieldCaption(Description))
            {
            }
            column(RemaingQty_ProdOrderLineCaption; "Prod. Order Line".FieldCaption("Remaining Quantity"))
            {
            }
            column(UOMCode_ProdOrderLineCaption; "Prod. Order Line".FieldCaption("Unit of Measure Code"))
            {
            }
            column(SubcntrctrDispatchistCapt; SubcntrctrDispatchistCaptLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ProdOrdRtngLnStrtDtCapt; ProdOrdRtngLnStrtDtCaptLbl)
            {
            }
            column(ProdOrdRtngLnEndDtCapt; ProdOrdRtngLnEndDtCaptLbl)
            {
            }
            column(PurchLineDocNoCaption; PurchLineDocNoCaptionLbl)
            {
            }
            column(PurchLineOutstandgQtyCapt; PurchLineOutstandgQtyCaptLbl)
            {
            }
            dataitem("Work Center"; "Work Center")
            {
                DataItemLink = "Subcontractor No." = field("No.");
                DataItemTableView = sorting("Subcontractor No.");
                PrintOnlyIfDetail = true;
                RequestFilterFields = "No.";
                column(No_WorkCenter; "No.")
                {
                }
                column(Name_WorkCenter; Name)
                {
                }
                column(No_WorkCenterCaption; FieldCaption("No."))
                {
                }
                column(Name_WorkCenterCaption; FieldCaption(Name))
                {
                }
                dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
                {
                    DataItemLink = "Work Center No." = field("No.");
                    DataItemTableView = sorting(Status, "Work Center No.") where(Status = const(Released));
                    PrintOnlyIfDetail = true;
                    RequestFilterFields = "Prod. Order No.", "Starting Date", "Ending Date";
                    column(OprtnNo_ProdOrderRtngLine; "Operation No.")
                    {
                    }
                    column(PONo_ProdOrderRtngLine; "Prod. Order No.")
                    {
                    }
                    column(Desc_ProdOrderRtngLine; Description)
                    {
                    }
                    column(StrtDt_ProdOrderRtngLine; Format("Starting Date"))
                    {
                    }
                    column(EndDate_ProdOrderRtngLine; Format("Ending Date"))
                    {
                    }
                    dataitem("Prod. Order Line"; "Prod. Order Line")
                    {
                        DataItemLink = Status = field(Status), "Prod. Order No." = field("Prod. Order No."), "Routing No." = field("Routing No.");
                        DataItemTableView = sorting(Status, "Prod. Order No.", "Routing No.");
                        column(ItemNo_ProdOrderLine; "Item No.")
                        {
                        }
                        column(UOMCode_ProdOrderLine; "Unit of Measure Code")
                        {
                        }
                        column(RemaingQty_ProdOrderLine; "Remaining Quantity")
                        {
                        }
                        column(Desc_ProdOrderLine; Description)
                        {
                        }
                        column(PurchLineDocNo; PurchLine."Document No.")
                        {
                        }
                        column(PurchLineOutstandingQty; PurchLine."Outstanding Quantity")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        dataitem("Prod. Order Component"; "Prod. Order Component")
                        {
                            DataItemLink = Status = field(Status), "Prod. Order No." = field("Prod. Order No."), "Prod. Order Line No." = field("Line No.");
                            DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");
                            column(ItemNo_ProdOrderComp; "Item No.")
                            {
                            }
                            column(Desc_ProdOrderComp; Description)
                            {
                            }
                            column(RemaingQty_ProdOrderComp; "Remaining Quantity")
                            {
                            }
                            column(UOMCode_ProdOrderComp; "Unit of Measure Code")
                            {
                            }
                            column(PONo_ProdOrderComp; "Prod. Order No.")
                            {
                            }
                            column(ComponentsneededCaption; ComponentsneededCaptionLbl)
                            {
                            }

                            trigger OnPreDataItem()
                            begin
                                if "Prod. Order Routing Line"."Previous Operation No." <> '' then begin
                                    if "Prod. Order Routing Line"."Routing Link Code" = '' then
                                        CurrReport.Break();

                                    SetRange("Routing Link Code", "Prod. Order Routing Line"."Routing Link Code");
                                end else
                                    SetFilter("Routing Link Code", '%1|%2', '', "Prod. Order Routing Line"."Routing Link Code");

                                SetFilter("Remaining Quantity", '<>0');
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            PurchLine.SetCurrentKey(
                              "Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
                            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                            PurchLine.SetRange("Prod. Order No.", "Prod. Order No.");
                            PurchLine.SetRange(Type, PurchLine.Type::Item);
                            PurchLine.SetRange("No.", "Item No.");
                            PurchLine.SetRange("Routing No.", "Prod. Order Routing Line"."Routing No.");
                            PurchLine.SetRange("Operation No.", "Prod. Order Routing Line"."Operation No.");
                            if not PurchLine.FindFirst() then
                                Clear(PurchLine);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetFilter("Remaining Quantity", '<>0');
                        end;
                    }
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        PurchLine: Record "Purchase Line";
        SubcntrctrDispatchistCaptLbl: Label 'Subcontractor Dispatch List';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ProdOrdRtngLnStrtDtCaptLbl: Label 'Starting Date';
        ProdOrdRtngLnEndDtCaptLbl: Label 'Ending Date';
        PurchLineDocNoCaptionLbl: Label 'Purch. Order No.';
        PurchLineOutstandgQtyCaptLbl: Label 'Qty. on Purch. Order';
        ComponentsneededCaptionLbl: Label 'Components needed';
}

