page 1391 "Chart List"
{
    Caption = 'Key Performance Indicators';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Chart Definition";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Chart Name"; "Chart Name")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Chart Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the chart.';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies that the chart is enabled.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (CloseAction = ACTION::LookupOK) and not Enabled then
            DIALOG.Error(DisabledChartSelectedErr);
    end;

    var
        DisabledChartSelectedErr: Label 'The chart that you selected is disabled and cannot be opened on the role center. Enable the selected chart or select another chart.';
}

