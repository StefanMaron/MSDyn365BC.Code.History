report 721 "Inventory - Cost Variance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryMgt/InventoryCostVariance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - Cost Variance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = SORTING("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Costing Method", "Location Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TableCaptionItemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(ValueEntryItemLedgFilter_Item; "Value Entry".TableCaption + ': ' + ItemLedgEntryFilter)
            {
            }
            column(ItemLedgEntryFilter; ItemLedgEntryFilter)
            {
            }
            column(ItemNo_Item; "No.")
            {
            }
            column(Comment_Item; Description)
            {
            }
            column(StandardCost_Item; "Standard Cost")
            {
                IncludeCaption = true;
            }
            column(BaseUOM_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(CostingMethod_Item; "Costing Method")
            {
                IncludeCaption = true;
            }
            column(InvoicedQty_Item; "Value Entry"."Invoiced Quantity")
            {
                DecimalPlaces = 0 : 5;
            }
            column(Variance; Variance)
            {
                AutoFormatType = 1;
            }
            column(InvCostVarianceCaption; InvCostVarianceCaptionLbl)
            {
            }
            column(CurrReportPAGENOCaption; CurrReportPAGENOCaptionLbl)
            {
            }
            column(UnitAmountCaption; UnitAmountCaptionLbl)
            {
            }
            column(CostperUnitCaption; CostperUnitCaptionLbl)
            {
            }
            column(UnitCostVarianceCaption; UnitCostVarianceCaptionLbl)
            {
            }
            column(TotalVarianceAmtCaption; TotalVarianceAmtCaptionLbl)
            {
            }
            column(ItemLedEntryPostDtCaption; ItemLedEntryPostDtCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = FIELD("No."), "Variant Code" = FIELD("Variant Filter"), "Location Code" = FIELD("Location Filter"), "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"), "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter");
                DataItemTableView = SORTING("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date") WHERE("Entry Type" = FILTER(Purchase | "Positive Adjmt."));
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Posting Date", "Source Type", "Source No.";
                dataitem("Value Entry"; "Value Entry")
                {
                    DataItemLink = "Item Ledger Entry No." = FIELD("Entry No."), "Variant Code" = FIELD("Variant Code"), "Location Code" = FIELD("Location Code"), "Global Dimension 1 Code" = FIELD("Global Dimension 1 Code"), "Global Dimension 2 Code" = FIELD("Global Dimension 2 Code");
                    DataItemTableView = SORTING("Item Ledger Entry No.") WHERE("Expected Cost" = CONST(false));
                    column(No_ItemLedgerEntry; "Item Ledger Entry"."Entry No.")
                    {
                        IncludeCaption = true;
                    }
                    column(InvoicedQty_ValueEntry; "Invoiced Quantity")
                    {
                        IncludeCaption = true;
                    }
                    column(UnitAmtCostPerUnit_ValueEntry; UnitAmount - "Cost per Unit")
                    {
                        AutoFormatType = 1;
                    }
                    column(CostPerUnit_ValueEntry; "Cost per Unit")
                    {
                    }
                    column(UnitAmount; UnitAmount)
                    {
                        AutoFormatType = 2;
                    }
                    column(DocNo_ItemLedgerEntry; "Document No.")
                    {
                        IncludeCaption = true;
                    }
                    column(EntryType_ItemLedgerEntry; "Item Ledger Entry"."Entry Type")
                    {
                        IncludeCaption = true;
                    }
                    column(PostDate_ItemLedgerEntry; Format("Item Ledger Entry"."Posting Date"))
                    {
                    }
                    column(SourceNo_ValueEntry; "Source No.")
                    {
                        IncludeCaption = true;
                    }
                    column(ItemLedgEntryNo_ValueEntry; "Item Ledger Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        UnitAmount := "Cost per Unit" * "Invoiced Quantity";

                        if ("Item Charge No." <> '') and "Item Ledger Entry".Positive then
                            UnitAmount := "Cost Amount (Actual)";

                        Variance := 0;

                        if "Entry Type" = "Entry Type"::Variance then
                            Variance := "Cost Amount (Actual)";

                        if "Invoiced Quantity" <> 0 then
                            UnitAmount := UnitAmount / "Invoiced Quantity";
                    end;
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

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
        ItemLedgEntryFilter := "Value Entry".GetFilters();
    end;

    var
        ItemFilter: Text;
        ItemLedgEntryFilter: Text;
        UnitAmount: Decimal;
        Variance: Decimal;
        InvCostVarianceCaptionLbl: Label 'Inventory - Cost Variance';
        CurrReportPAGENOCaptionLbl: Label 'Page';
        UnitAmountCaptionLbl: Label 'Unit Amount';
        CostperUnitCaptionLbl: Label 'Cost per Unit';
        UnitCostVarianceCaptionLbl: Label 'Unit Cost Variance';
        TotalVarianceAmtCaptionLbl: Label 'Total Variance Amount';
        ItemLedEntryPostDtCaptionLbl: Label 'Posting Date';
        TotalCaptionLbl: Label 'Total';
}

