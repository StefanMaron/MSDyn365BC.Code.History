#if not CLEAN21
page 2100 "O365 Sales Year Summary"
{
    Caption = 'Sales per month';
    DataCaptionExpression = Format(Date2DMY(WorkDate(), 3));
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(MonthyInfo)
            {
                Caption = '';
            }
            usercontrol(Chart; "Microsoft.Dynamics.Nav.Client.BusinessChart")
            {
                ApplicationArea = Invoicing, Basic, Suite;

                trigger DataPointClicked(point: DotNet BusinessChartDataPoint)
                begin
                    ShowMonth(point.XValueString);
                end;

                trigger DataPointDoubleClicked(point: DotNet BusinessChartDataPoint)
                begin
                end;

                trigger AddInReady()
                var
                    GLSetup: Record "General Ledger Setup";
                    O365SalesStatistics: Codeunit "O365 Sales Statistics";
                begin
                    GLSetup.Get();
                    O365SalesStatistics.GenerateMonthlyOverview(Rec);
                    O365SalesStatistics.GenerateChart(CurrPage.Chart, Rec, MonthTxt, StrSubstNo(AmountTxt, GLSetup.GetCurrencySymbol()));
                end;

                trigger Refresh()
                var
                    GLSetup: Record "General Ledger Setup";
                    O365SalesStatistics: Codeunit "O365 Sales Statistics";
                begin
                    GLSetup.Get();
                    DeleteAll();
                    O365SalesStatistics.GenerateMonthlyOverview(Rec);
                    O365SalesStatistics.GenerateChart(CurrPage.Chart, Rec, MonthTxt, StrSubstNo(AmountTxt, GLSetup.GetCurrencySymbol()));
                end;
            }
            repeater(Control4)
            {
                ShowCaption = false;
                Visible = MonthlyDataVisible;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Month';
                    Editable = false;
                    ToolTip = 'Specifies the month';
                }
                field(Value; Value)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the summarized amount';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        MonthlyDataVisible := false;
    end;

    var
        MonthTxt: Label 'Month';
        AmountTxt: Label 'Amount (%1)', Comment = '%1=Currency Symbol (e.g. $)';
        MonthlyDataVisible: Boolean;

    local procedure ShowMonth(Month: Text)
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        TypeHelper: Codeunit "Type Helper";
    begin
        TempNameValueBuffer.Copy(Rec, true);
        TempNameValueBuffer.Get(TypeHelper.GetLocalizedMonthToInt(Month));

        PAGE.Run(PAGE::"O365 Sales Month Summary", TempNameValueBuffer);
    end;

    procedure ShowMonthlyDataPart()
    begin
        MonthlyDataVisible := true;
    end;
}
#endif
