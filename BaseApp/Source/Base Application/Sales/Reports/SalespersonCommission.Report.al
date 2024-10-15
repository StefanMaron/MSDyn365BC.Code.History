namespace Microsoft.Sales.Reports;

using Microsoft.CRM.Team;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Receivables;

report 115 "Salesperson - Commission"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/SalespersonCommission.rdlc';
    ApplicationArea = Suite;
    Caption = 'Salesperson - Commission';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
        {
            DataItemTableView = sorting(Code);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Code";
            column(STRSUBSTNO_Text000_PeriodText_; StrSubstNo(PeriodTxt, PeriodText))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Salesperson_Purchaser__TABLECAPTION__________SalespersonFilter; TableCaption + ': ' + SalespersonFilter)
            {
            }
            column(SalespersonFilter; SalespersonFilter)
            {
            }
            column(Cust__Ledger_Entry__TABLECAPTION__________CustLedgEntryFilter; "Cust. Ledger Entry".TableCaption + ': ' + CustLedgEntryFilter)
            {
            }
            column(CustLedgEntryFilter; CustLedgEntryFilter)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(Salesperson_Purchaser_Code; Code)
            {
            }
            column(Salesperson_Purchaser_Name; Name)
            {
            }
            column(Salesperson_Purchaser__Commission___; "Commission %")
            {
            }
            column(Cust__Ledger_Entry___Sales__LCY__; "Cust. Ledger Entry"."Sales (LCY)")
            {
            }
            column(Cust__Ledger_Entry___Profit__LCY__; "Cust. Ledger Entry"."Profit (LCY)")
            {
            }
            column(SalesCommissionAmt; SalesCommissionAmt)
            {
                AutoFormatType = 1;
            }
            column(ProfitCommissionAmt; ProfitCommissionAmt)
            {
                AutoFormatType = 1;
            }
            column(AdjProfit; AdjProfit)
            {
                AutoFormatType = 1;
            }
            column(AdjProfitCommissionAmt; AdjProfitCommissionAmt)
            {
                AutoFormatType = 1;
            }
            column(Salesperson___CommissionCaption; Salesperson___CommissionCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(All_amounts_are_in_LCYCaption; All_amounts_are_in_LCYCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Posting_Date_Caption; Cust__Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Document_No__Caption; "Cust. Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Cust__Ledger_Entry__Customer_No__Caption; "Cust. Ledger Entry".FieldCaption("Customer No."))
            {
            }
            column(Cust__Ledger_Entry__Sales__LCY__Caption; "Cust. Ledger Entry".FieldCaption("Sales (LCY)"))
            {
            }
            column(Cust__Ledger_Entry__Profit__LCY__Caption; "Cust. Ledger Entry".FieldCaption("Profit (LCY)"))
            {
            }
            column(SalesCommissionAmt_Control32Caption; SalesCommissionAmt_Control32CaptionLbl)
            {
            }
            column(ProfitCommissionAmt_Control33Caption; ProfitCommissionAmt_Control33CaptionLbl)
            {
            }
            column(AdjProfit_Control39Caption; AdjProfit_Control39CaptionLbl)
            {
            }
            column(AdjProfitCommissionAmt_Control45Caption; AdjProfitCommissionAmt_Control45CaptionLbl)
            {
            }
            column(Salesperson_Purchaser__Commission___Caption; FieldCaption("Commission %"))
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemLink = "Salesperson Code" = field(Code);
                DataItemTableView = sorting("Salesperson Code", "Posting Date") where("Document Type" = filter(Invoice | "Credit Memo"));
                RequestFilterFields = "Posting Date";
                column(Cust__Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Cust__Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Cust__Ledger_Entry__Customer_No__; "Customer No.")
                {
                }
                column(Cust__Ledger_Entry__Sales__LCY__; "Sales (LCY)")
                {
                }
                column(Cust__Ledger_Entry__Profit__LCY__; "Profit (LCY)")
                {
                }
                column(SalesCommissionAmt_Control32; SalesCommissionAmt)
                {
                    AutoFormatType = 1;
                }
                column(ProfitCommissionAmt_Control33; ProfitCommissionAmt)
                {
                    AutoFormatType = 1;
                }
                column(AdjProfit_Control39; AdjProfit)
                {
                    AutoFormatType = 1;
                }
                column(AdjProfitCommissionAmt_Control45; AdjProfitCommissionAmt)
                {
                    AutoFormatType = 1;
                }
                column(Salesperson_Purchaser__Name; "Salesperson/Purchaser".Name)
                {
                }

                trigger OnAfterGetRecord()
                var
                    CostCalcMgt: Codeunit "Cost Calculation Management";
                begin
                    SalesCommissionAmt := Round("Sales (LCY)" * "Salesperson/Purchaser"."Commission %" / 100);
                    ProfitCommissionAmt := Round("Profit (LCY)" * "Salesperson/Purchaser"."Commission %" / 100);
                    AdjProfit := "Profit (LCY)" + CostCalcMgt.CalcCustLedgAdjmtCostLCY("Cust. Ledger Entry");
                    AdjProfitCommissionAmt := Round(AdjProfit * "Salesperson/Purchaser"."Commission %" / 100);
                end;

                trigger OnPreDataItem()
                begin
                    ClearAmounts();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if PrintOnlyOnePerPageReq then
                    PageGroupNo := PageGroupNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                ClearAmounts();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPageReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'New Page per Person';
                        ToolTip = 'Specifies if each person''s information is printed on a new page if you have chosen two or more persons to be included in the report.';
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
        SalespersonFilter := "Salesperson/Purchaser".GetFilters();
        CustLedgEntryFilter := "Cust. Ledger Entry".GetFilters();
        PeriodText := "Cust. Ledger Entry".GetFilter("Posting Date");
    end;

    var
        PeriodTxt: Label 'Period: %1', Comment = '%1 - period text';
        SalespersonFilter: Text;
        CustLedgEntryFilter: Text;
        PeriodText: Text;
        AdjProfit: Decimal;
        ProfitCommissionAmt: Decimal;
        AdjProfitCommissionAmt: Decimal;
        SalesCommissionAmt: Decimal;
        PrintOnlyOnePerPageReq: Boolean;
        PageGroupNo: Integer;
        Salesperson___CommissionCaptionLbl: Label 'Salesperson - Commission';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        All_amounts_are_in_LCYCaptionLbl: Label 'All amounts are in LCY';
        Cust__Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        SalesCommissionAmt_Control32CaptionLbl: Label 'Sales Commission (LCY)';
        ProfitCommissionAmt_Control33CaptionLbl: Label 'Profit Commission (LCY)';
        AdjProfit_Control39CaptionLbl: Label 'Adjusted Profit (LCY)';
        AdjProfitCommissionAmt_Control45CaptionLbl: Label 'Adjusted Profit Commission (LCY)';
        TotalCaptionLbl: Label 'Total';

    local procedure ClearAmounts()
    begin
        Clear(AdjProfit);
        Clear(ProfitCommissionAmt);
        Clear(AdjProfitCommissionAmt);
        Clear(SalesCommissionAmt);
    end;
}

