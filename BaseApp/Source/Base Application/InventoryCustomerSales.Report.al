report 713 "Inventory - Customer Sales"
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryCustomerSales.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Customer Sales';
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
            DataItemTableView = SORTING("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "No. 2", "Search Description", "Assembly BOM", "Inventory Posting Group";
            column(No_Item; "No.")
            {
            }
            column(Description_Item; Description)
            {
            }
            column(BaseUnitofMeasure_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = FIELD("No."), "Variant Code" = FIELD("Variant Filter"), "Location Code" = FIELD("Location Filter"), "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"), "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter");
                DataItemTableView = SORTING("Source Type", "Source No.", "Item No.") WHERE("Source Type" = CONST(Customer));
                RequestFilterFields = "Posting Date", "Source No.";
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    column(SourceNo_ItemLedgEntry; TempValueEntryBuf."Source No.")
                    {
                    }
                    column(CustName; GetCustName(TempValueEntryBuf."Source No."))
                    {
                    }
                    column(InvQty_ItemLedgEntry; -TempValueEntryBuf."Invoiced Quantity")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(SalesAmtActual_ItemLedgEntry; TempValueEntryBuf."Sales Amount (Actual)")
                    {
                        AutoFormatType = 1;
                    }
                    column(Profit_ItemLedgEntry; TempValueEntryBuf."Sales Amount (Expected)")
                    {
                        AutoFormatType = 1;
                    }
                    column(DiscountAmount; -TempValueEntryBuf."Purchase Amount (Expected)")
                    {
                        AutoFormatType = 1;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not TempValueEntryBuf.FindSet then
                                CurrReport.Break;
                        end else
                            if TempValueEntryBuf.Next = 0 then
                                CurrReport.Break;
                    end;

                    trigger OnPostDataItem()
                    begin
                        TempValueEntryBuf.DeleteAll;
                    end;

                    trigger OnPreDataItem()
                    begin
                        TempValueEntryBuf.Reset;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if IsNewGroup then
                        AddReportLine(ValueEntryBuf);

                    IncrLineAmounts(ValueEntryBuf, "Item Ledger Entry");

                    if IsLastEntry then
                        AddReportLine(ValueEntryBuf);
                end;

                trigger OnPreDataItem()
                begin
                    LastItemLedgEntryNo := GetLastItemLedgerEntryNo("Item Ledger Entry");
                    Clear(ValueEntryBuf);
                    ReportLineNo := 0;
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
        ReportTitle = 'Inventory - Customer Sales';
        Page = 'Page';
        CustomerNo = 'Customer No.';
        Name = 'Name';
        InvoicedQty = 'Invoiced Quantity';
        Amount = 'Amount';
        DiscountAmt = 'Discount Amount';
        Profit = 'Profit';
        ProfitPct = 'Profit %';
        Total = 'Total';
    }

    trigger OnPreReport()
    begin
        ItemFilter := GetTableFilters(Item.TableCaption, Item.GetFilters);
        ItemLedgEntryFilter := GetTableFilters("Item Ledger Entry".TableCaption, "Item Ledger Entry".GetFilters);
        PeriodText := StrSubstNo(PeriodInfo, "Item Ledger Entry".GetFilter("Posting Date"));
    end;

    var
        PeriodInfo: Label 'Period: %1';
        ValueEntryBuf: Record "Value Entry";
        TempValueEntryBuf: Record "Value Entry" temporary;
        PeriodText: Text;
        ItemFilter: Text;
        ItemLedgEntryFilter: Text;
        LastItemLedgEntryNo: Integer;
        ReportLineNo: Integer;

    local procedure CalcDiscountAmount(ItemLedgerEntryNo: Integer): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetCurrentKey("Item Ledger Entry No.");
            SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
            CalcSums("Discount Amount");
            exit("Discount Amount");
        end;
    end;

    local procedure GetLastItemLedgerEntryNo(var ItemLedgerEntry: Record "Item Ledger Entry"): Integer
    var
        LastItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LastItemLedgerEntry.Copy(ItemLedgerEntry);
        if LastItemLedgerEntry.FindLast then
            exit(LastItemLedgerEntry."Entry No.");
        exit(0);
    end;

    local procedure IncrLineAmounts(var ValueEntryBuf: Record "Value Entry"; CurrItemLedgEntry: Record "Item Ledger Entry")
    var
        Profit: Decimal;
        DiscountAmount: Decimal;
    begin
        with CurrItemLedgEntry do begin
            CalcFields("Sales Amount (Actual)", "Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)");
            Profit := "Sales Amount (Actual)" + "Cost Amount (Actual)" + "Cost Amount (Non-Invtbl.)";
            DiscountAmount := CalcDiscountAmount("Entry No.");

            if ValueEntryBuf."Item No." = '' then begin
                ValueEntryBuf.Init;
                ValueEntryBuf."Item No." := "Item No.";
                ValueEntryBuf."Source No." := "Source No.";
            end;
            ValueEntryBuf."Invoiced Quantity" += "Invoiced Quantity";
            ValueEntryBuf."Sales Amount (Actual)" += "Sales Amount (Actual)";
            ValueEntryBuf."Sales Amount (Expected)" += Profit;
            ValueEntryBuf."Purchase Amount (Expected)" += DiscountAmount;
        end;
    end;

    local procedure AddReportLine(var ValueEntryBuf: Record "Value Entry")
    begin
        TempValueEntryBuf := ValueEntryBuf;
        ReportLineNo += 1;
        TempValueEntryBuf."Entry No." := ReportLineNo;
        TempValueEntryBuf.Insert;
        Clear(ValueEntryBuf);
    end;

    local procedure IsNewGroup(): Boolean
    begin
        exit(("Item Ledger Entry"."Source No." <> ValueEntryBuf."Source No.") and (ValueEntryBuf."Source No." <> ''));
    end;

    local procedure IsLastEntry(): Boolean
    begin
        exit("Item Ledger Entry"."Entry No." = LastItemLedgEntryNo);
    end;

    local procedure GetCustName(CustNo: Code[20]): Text[100]
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustNo) then
            exit(Customer.Name);
        exit('');
    end;

    local procedure GetTableFilters(TableName: Text; Filters: Text): Text
    begin
        if Filters <> '' then
            exit(StrSubstNo('%1: %2', TableName, Filters));
        exit('');
    end;
}

