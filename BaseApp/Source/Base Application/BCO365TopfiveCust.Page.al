page 2301 "BC O365 Top five Cust"
{
    Caption = 'Top five customers';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Business Chart Buffer";
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
                    SetDrillDownIndexes(point);
                    TopFiveCustomersChartMgt.DrillDown(Rec);
                end;

                trigger DataPointDoubleClicked(point: DotNet BusinessChartDataPoint)
                begin
                end;

                trigger AddInReady()
                begin
                    InitializeSelectedChart;
                end;

                trigger Refresh()
                begin
                    InitializeSelectedChart;
                end;
            }
        }
    }

    actions
    {
    }

    var
        TopFiveCustomersChartMgt: Codeunit "Top Five Customers Chart Mgt.";

    local procedure InitializeSelectedChart()
    begin
        TopFiveCustomersChartMgt.UpdateChart(Rec);
        UpdateChart;
    end;

    local procedure UpdateChart()
    begin
        Update(CurrPage.Chart);
    end;
}

