namespace System.Visualization;

using System.Reflection;

page 9187 "Copy Generic Chart"
{
    Caption = 'Copy Generic Chart';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = StandardDialog;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            field(NewChartID; NewChartID)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New Chart ID';
                ToolTip = 'Specifies the ID of the new chart that you copy information to.';
            }
            field(NewChartTitle; NewChartTitle)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New Chart Title';
                ToolTip = 'Specifies the name of the new chart that you copy information to.';
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GenericChartMgt: Codeunit "Generic Chart Mgt";
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then begin
            ValidateUserInput();
            GenericChartMgt.CopyChart(SourceChart, NewChartID, NewChartTitle);
            Message(Text001);
        end
    end;

    var
        SourceChart: Record Chart;
        NewChartID: Code[20];
        NewChartTitle: Text[50];
#pragma warning disable AA0074
        Text001: Label 'The chart was successfully copied.';
        Text002: Label 'Specify a chart ID.';
#pragma warning restore AA0074

    local procedure ValidateUserInput()
    begin
        if NewChartID = '' then
            Error(Text002);
    end;

    procedure SetSourceChart(SourceChartInput: Record Chart)
    begin
        SourceChart := SourceChartInput;
        CurrPage.Caption(CurrPage.Caption + ' ' + SourceChart.ID);
    end;
}

