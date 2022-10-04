page 9994 "API Data Upgrade List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "API Data Upgrade";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Control2)
            {
                field("Upgrade Tag"; Rec."Upgrade Tag")
                {
                    ApplicationArea = All;
                    Caption = 'Entity Name';
                    ToolTip = 'Name of the entity.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Endpoints';
                    ToolTip = 'API endpoints of the entity.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Status of the API data upgrade.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Schedule Upgrades")
            {
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Schedules an upgrade job queue entry for selected API data upgrades.';

                trigger OnAction();
                var
                    APIDataUpgrade: Record "API Data Upgrade";
                    GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
                begin
                    APIDataUpgrade.Copy(Rec);
                    CurrPage.SetSelectionFilter(APIDataUpgrade);
                    APIDataUpgrade.SetRange(Status, APIDataUpgrade.Status::" ");
                    APIDataUpgrade.ModifyAll(Status, APIDataUpgrade.Status::Scheduled);
                    GraphMgtGeneralTools.ScheduleUpdateAPIRecordsJob(Codeunit::"API Data Upgrade");
                    CurrPage.Update();
                end;
            }
            action(Reset)
            {
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Reset status of selected scheduled API data upgrade.';

                trigger OnAction();
                begin
                    Clear(Rec.Status);
                    Rec.Modify();
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Schedule Upgrades_Promoted"; "Schedule Upgrades")
                {
                }
                actionref(Reset_Promoted; Reset)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Load();
    end;
}