report 714 "Inventory - Vendor Purchases"
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryVendorPurchases.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - Vendor Purchases';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(ReportHeader; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(0));
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(ItemLedgEntryFilter; ItemLedgEntryFilter)
            {
            }
        }
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "No. 2", "Search Description", "Assembly BOM", "Inventory Posting Group";
            column(No_Item; "No.")
            {
            }
            column(Desc_Item; Description)
            {
            }
            column(BaseUOM_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemLink = "Item No." = FIELD("No."), "Variant Code" = FIELD("Variant Filter"), "Location Code" = FIELD("Location Filter"), "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"), "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter");
                DataItemTableView = SORTING("Source Type", "Source No.", "Item No.") WHERE("Source Type" = CONST(Vendor), "Expected Cost" = CONST(false));
                RequestFilterFields = "Posting Date", "Source No.", "Source Posting Group";

                trigger OnAfterGetRecord()
                begin
                    FillTempValueEntry("Value Entry");

                    CurrReport.Skip();
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(> 0));
                column(SourceNo_ValueEntry; TempValueEntry."Source No.")
                {
                }
                column(VendName; Vend.Name)
                {
                }
                column(InvQty_ValueEntry; TempValueEntry."Invoiced Quantity")
                {
                    IncludeCaption = true;
                }
                column(CostAmtAct_ValueEntry; TempValueEntry."Cost Amount (Actual)")
                {
                    IncludeCaption = true;
                }
                column(DiscAmt_ValueEntry; TempValueEntry."Discount Amount")
                {
                    IncludeCaption = true;
                }

                trigger OnAfterGetRecord()
                begin
                    TempValueEntry.SetRange("Source No.");

                    if Number = 1 then
                        TempValueEntry.FindSet
                    else
                        if TempValueEntry.Next = 0 then
                            CurrReport.Break();

                    if not Vend.Get(TempValueEntry."Source No.") then
                        Clear(Vend);
                end;

                trigger OnPreDataItem()
                begin
                    if TempValueEntry.IsEmpty then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TempValueEntry.DeleteAll();
            end;
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
        PageCaption = 'Page';
        ReportTitle = 'Inventory - Vendor Purchases';
        VendorNoCaption = 'Vendor No.';
        NameCaption = 'Name';
        TotalCaption = 'Total';
    }

    trigger OnPreReport()
    begin
        ItemFilter := GetTableFilters(Item.TableCaption, Item.GetFilters);
        ItemLedgEntryFilter := GetTableFilters("Value Entry".TableCaption, "Value Entry".GetFilters);
        PeriodText := StrSubstNo(PeriodInfo, "Value Entry".GetFilter("Posting Date"));
    end;

    var
        PeriodInfo: Label 'Period: %1';
        Vend: Record Vendor;
        TempValueEntry: Record "Value Entry" temporary;
        PeriodText: Text;
        ItemFilter: Text;
        ItemLedgEntryFilter: Text;

    local procedure FillTempValueEntry(ValueEntry: Record "Value Entry")
    begin
        with ValueEntry do begin
            TempValueEntry.SetRange("Source No.", "Source No.");
            if not TempValueEntry.FindSet then begin
                TempValueEntry.Init();
                TempValueEntry := "Value Entry";
                TempValueEntry.Insert();
            end else begin
                TempValueEntry."Cost Amount (Actual)" := TempValueEntry."Cost Amount (Actual)" + "Cost Amount (Actual)";
                TempValueEntry."Invoiced Quantity" := TempValueEntry."Invoiced Quantity" + "Invoiced Quantity";
                TempValueEntry."Discount Amount" := TempValueEntry."Discount Amount" + "Discount Amount";
                TempValueEntry.Modify();
            end;
        end;
    end;

    local procedure GetTableFilters(TableName: Text; Filters: Text): Text
    begin
        if Filters <> '' then
            exit(StrSubstNo('%1: %2', TableName, Filters));
        exit('');
    end;
}

