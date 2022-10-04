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
                field("Chart Name"; Rec."Chart Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Chart Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the chart.';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the chart is enabled.';

                }
            }
        }
    }

    actions
    {
        area(navigation)

        {
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Setup';
                Image = Setup;
                Enabled = SetupActive;
                ToolTip = 'Specifies setup for this Chart';
                trigger OnAction()
                var
                    AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
                    ChartManagement: Codeunit "Chart Management";
                begin
                    if not AccountSchedulesChartSetup.get('', "Chart Name") then begin
                        AccountSchedulesChartSetup.Init();
                        AccountSchedulesChartSetup."User ID" := '';
                        AccountSchedulesChartSetup.Name := copystr("Chart Name", 1, MaxStrLen(AccountSchedulesChartSetup.Name));
                        AccountSchedulesChartSetup.Description := "Chart Name";
                        AccountSchedulesChartSetup."Start Date" := Today;
                        AccountSchedulesChartSetup."Period Length" := AccountSchedulesChartSetup."Period Length"::Month;
                        AccountSchedulesChartSetup.Insert(true);
                        Commit();
                    end;
                    if Page.RunModal(Page::"Account Schedules Chart Setup", AccountSchedulesChartSetup) = ACTION::LookupOK THEN begin
                        ChartManagement.EnableChart(rec);
                        if Enabled then
                            modify();
                    end;


                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Setup_Promoted; Setup)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetupActive := SupportSetup();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (CloseAction = ACTION::LookupOK) and not Enabled then
            DIALOG.Error(DisabledChartSelectedErr);
    end;

    var
        DisabledChartSelectedErr: Label 'The chart that you selected is disabled and cannot be opened on the role center. Enable the selected chart or select another chart.';
        SetupActive: Boolean;
}

