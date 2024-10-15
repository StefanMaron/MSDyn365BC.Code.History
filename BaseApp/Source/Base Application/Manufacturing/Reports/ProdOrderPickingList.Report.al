﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;

report 99000766 "Prod. Order - Picking List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/ProdOrderPickingList.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Prod. Order - Picking List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description", "Assembly BOM", "Inventory Posting Group", "Location Filter", "Bin Filter", "Shelf No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTableCaptionFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(CompneedCompFilter; StrSubstNo(Text000, ComponentFilter))
            {
            }
            column(ComponentFilter; ComponentFilter)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(BaseUOM_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(ProdOrderPickingListCapt; ProdOrderPickingListCaptLbl)
            {
            }
            column(CurrReportPageNoCapt; CurrReportPageNoCaptLbl)
            {
            }
            column(ProdOrderDescCaption; ProdOrderDescCaptionLbl)
            {
            }
            column(ProdOrderCompDueDateCapt; ProdOrderCompDueDateCaptLbl)
            {
            }
            dataitem("Prod. Order Component"; "Prod. Order Component")
            {
                DataItemLink = "Item No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Bin Code" = field("Bin Filter");
                DataItemTableView = sorting("Item No.", "Variant Code", "Location Code", Status, "Due Date");
                RequestFilterFields = Status, "Due Date";
                column(ProdOrdNo_ProdOrderComp; "Prod. Order No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_ProdOrder; ProdOrder.Description)
                {
                }
                column(DueDate_ProdOrderComp; "Due Date")
                {
                }
                column(RmngQty_ProdOrderComp; "Remaining Quantity")
                {
                    IncludeCaption = true;
                }
                column(Scrap_ProdOrderComp; "Scrap %")
                {
                    IncludeCaption = true;
                }
                column(LoctionCode_ProdOrderComp; "Location Code")
                {
                    IncludeCaption = true;
                }
                column(BinCode_ProdOrderComp; "Bin Code")
                {
                    IncludeCaption = true;
                }
                column(Description_Item; Item.Description)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Status = Status::Finished then
                        CurrReport.Skip();
                    ProdOrder.Get(Status, "Prod. Order No.");
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Remaining Quantity", '<>0');
                end;
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

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
        ComponentFilter := "Prod. Order Component".GetFilters();
    end;

    var
        Text000: Label 'Component Need : %1.';
        ProdOrder: Record "Production Order";
        ItemFilter: Text;
        ComponentFilter: Text;
        ProdOrderPickingListCaptLbl: Label 'Prod. Order - Picking List';
        CurrReportPageNoCaptLbl: Label 'Page';
        ProdOrderDescCaptionLbl: Label 'Name';
        ProdOrderCompDueDateCaptLbl: Label 'Due Date';
}

