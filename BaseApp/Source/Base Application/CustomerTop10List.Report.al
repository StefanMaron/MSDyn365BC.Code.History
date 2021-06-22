report 111 "Customer - Top 10 List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CustomerTop10List.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Top 10 List';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Customer Posting Group", "Currency Code", "Date Filter";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                CalcFields("Sales (LCY)", "Balance (LCY)");
                if ("Sales (LCY)" = 0) and ("Balance (LCY)" = 0) then
                    CurrReport.Skip();
                CustAmount.Init();
                CustAmount."Customer No." := "No.";
                if ShowType = ShowType::"Sales (LCY)" then begin
                    CustAmount."Amount (LCY)" := -"Sales (LCY)";
                    CustAmount."Amount 2 (LCY)" := -"Balance (LCY)";
                end else begin
                    CustAmount."Amount (LCY)" := -"Balance (LCY)";
                    CustAmount."Amount 2 (LCY)" := -"Sales (LCY)";
                end;
                CustAmount.Insert();
                if (NoOfRecordsToPrint = 0) or (i < NoOfRecordsToPrint) then
                    i := i + 1
                else begin
                    CustAmount.Find('+');
                    CustAmount.Delete();
                end;

                TotalSales += "Sales (LCY)";
                TotalBalance += "Balance (LCY)";
                ChartTypeNo := ChartType;
                ShowTypeNo := ShowType;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000);
                i := 0;
                CustAmount.DeleteAll();
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(SortingCustomersCustDateFilter; StrSubstNo(Text001, CustDateFilter))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(RankedAccordingShowType; StrSubstNo(Text002, SelectStr(ShowType + 1, Text004)))
            {
            }
            column(ShowTypeNo; ShowTypeNo)
            {
            }
            column(ChartTypeNo; ChartTypeNo)
            {
            }
            column(CustFilter_Customer; Customer.TableCaption + ': ' + CustFilter)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(No_Customer; Customer."No.")
            {
                IncludeCaption = true;
            }
            column(Name_Customer; Customer.Name)
            {
                IncludeCaption = true;
            }
            column(SalesLCY_Customer; Customer."Sales (LCY)")
            {
                IncludeCaption = true;
            }
            column(BalanceLCY_Customer; Customer."Balance (LCY)")
            {
                IncludeCaption = true;
            }
            column(TotalSales; TotalSales)
            {
            }
            column(TotalBalance; TotalBalance)
            {
            }
            column(CustomerTop10ListCaption; CustomerTop10ListCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(TotalSalesCaption; TotalSalesCaptionLbl)
            {
            }
            column(PercentofTotalSalesCaption; PercentofTotalSalesCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not CustAmount.Find('-') then
                        CurrReport.Break();
                end else
                    if CustAmount.Next = 0 then
                        CurrReport.Break();
                CustAmount."Amount (LCY)" := -CustAmount."Amount (LCY)";
                Customer.Get(CustAmount."Customer No.");
                Customer.CalcFields("Sales (LCY)", "Balance (LCY)");
                if MaxAmount = 0 then
                    MaxAmount := CustAmount."Amount (LCY)";
                CustAmount."Amount (LCY)" := -CustAmount."Amount (LCY)";
            end;

            trigger OnPreDataItem()
            begin
                Window.Close;
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
                    field(Show; ShowType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show';
                        OptionCaption = 'Sales (LCY),Balance (LCY)';
                        ToolTip = 'Specifies how the report will sort the customers: Sales, to sort by purchase volume; or Balance, to sort by balance. In either case, the customers with the largest amounts will be shown first.';
                    }
                    field(NoOfRecordsToPrint; NoOfRecordsToPrint)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Quantity';
                        ToolTip = 'Specifies the number of customers that will be included in the report.';
                    }
                    field(ChartType; ChartType)
                    {
                        ApplicationArea = All;
                        Caption = 'Chart Type';
                        OptionCaption = 'Bar chart,Pie chart';
                        ToolTip = 'Specifies the chart type.';
                        Visible = ChartTypeVisible;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            ChartTypeVisible := true;
        end;

        trigger OnOpenPage()
        begin
            if NoOfRecordsToPrint = 0 then
                NoOfRecordsToPrint := 10;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
        CustDateFilter := Customer.GetFilter("Date Filter");
    end;

    var
        Text000: Label 'Sorting customers    #1##########';
        Text001: Label 'Period: %1';
        Text002: Label 'Ranked according to %1';
        CustAmount: Record "Customer Amount" temporary;
        Window: Dialog;
        CustFilter: Text;
        CustDateFilter: Text;
        ShowType: Option "Sales (LCY)","Balance (LCY)";
        NoOfRecordsToPrint: Integer;
        MaxAmount: Decimal;
        i: Integer;
        TotalSales: Decimal;
        Text004: Label 'Sales (LCY),Balance (LCY)';
        TotalBalance: Decimal;
        ChartType: Option "Bar chart","Pie chart";
        ChartTypeNo: Integer;
        ShowTypeNo: Integer;
        [InDataSet]
        ChartTypeVisible: Boolean;
        CustomerTop10ListCaptionLbl: Label 'Customer - Top 10 List';
        CurrReportPageNoCaptionLbl: Label 'Page';
        TotalCaptionLbl: Label 'Total';
        TotalSalesCaptionLbl: Label 'Total Sales';
        PercentofTotalSalesCaptionLbl: Label '% of Total Sales';

    procedure InitializeRequest(SetChartType: Option; SetShowType: Option; NoOfRecords: Integer)
    begin
        ChartType := SetChartType;
        ShowType := SetShowType;
        NoOfRecordsToPrint := NoOfRecords;
    end;
}

