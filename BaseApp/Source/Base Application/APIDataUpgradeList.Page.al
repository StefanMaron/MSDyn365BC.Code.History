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
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Upgrade Name';
                    ToolTip = 'Name of the API data upgrade.';
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
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
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
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Reset status of selected scheduled API data upgrade.';

                trigger OnAction();
                begin
                    if Rec.Status = Rec.Status::Scheduled then begin
                        Clear(Rec.Status);
                        Rec.Modify();
                        CurrPage.Update();
                    end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Load();
    end;
}