page 2102 "O365 Sales Month Summary"
{
    Caption = 'Invoiced this Month';
    DataCaptionExpression = Name;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            usercontrol(Chart; "Microsoft.Dynamics.Nav.Client.BusinessChart")
            {
                ApplicationArea = Basic, Suite, Invoicing;

                trigger DataPointClicked(point: DotNet BusinessChartDataPoint)
                begin
                end;

                trigger DataPointDoubleClicked(point: DotNet BusinessChartDataPoint)
                begin
                end;

                trigger AddInReady()
                var
                    GLSetup: Record "General Ledger Setup";
                    TempNameValueBuffer: Record "Name/Value Buffer" temporary;
                    O365SalesStatistics: Codeunit "O365 Sales Statistics";
                begin
                    GLSetup.Get();

                    O365SalesStatistics.GenerateWeeklyOverview(TempNameValueBuffer, SelectedMonth);
                    O365SalesStatistics.GenerateChart(CurrPage.Chart, TempNameValueBuffer, WeekTxt, StrSubstNo(AmountTxt, GLSetup.GetCurrencySymbol));
                end;

                trigger Refresh()
                var
                    GLSetup: Record "General Ledger Setup";
                    TempNameValueBuffer: Record "Name/Value Buffer" temporary;
                    O365SalesStatistics: Codeunit "O365 Sales Statistics";
                begin
                    GLSetup.Get();

                    O365SalesStatistics.GenerateWeeklyOverview(TempNameValueBuffer, SelectedMonth);
                    O365SalesStatistics.GenerateChart(CurrPage.Chart, TempNameValueBuffer, WeekTxt, StrSubstNo(AmountTxt, GLSetup.GetCurrencySymbol));
                end;
            }
            part(O365MonthlyCustomerListpart; "O365 Monthly Customer Listpart")
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        if Name = '' then
            SelectedMonth := ID
        else
            SelectedMonth := TypeHelper.GetLocalizedMonthToInt(Name);

        ShowCustomers;

        if Insert() then;
    end;

    var
        WeekTxt: Label 'Week';
        AmountTxt: Label 'Amount (%1)', Comment = '%1=Currency Symbol (e.g. $)';
        SelectedMonth: Integer;

    local procedure ShowCustomers()
    begin
        CurrPage.O365MonthlyCustomerListpart.PAGE.InsertData(SelectedMonth);
    end;
}

