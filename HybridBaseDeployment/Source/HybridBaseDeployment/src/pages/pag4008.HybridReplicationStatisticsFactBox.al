page 4008 "Intelligent Cloud Stat Factbox"
{
    Caption = 'Migration Information';
    SourceTable = "Hybrid Replication Summary";
    PageType = CardPart;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            field("Next Scheduled Run"; NextScheduledRun)
            {
                Enabled = false;
                Editable = false;
                ApplicationArea = Basic, Suite;
                Visible = ReplicationEnabled;
            }
            group(Group1)
            {
                ShowCaption = false;
                cuegroup(MigrationStatistics)
                {
                    Caption = 'Migration Statistics';
                    InstructionalText = 'Migration Statistics';
                    ShowCaption = true;

                    field("Source Product"; SourceProduct)
                    {
                        Enabled = false;
                        Editable = false;
                        ApplicationArea = Basic, Suite;
                        Visible = false;
                    }
                    field("Total Successful Tables"; TotalSuccessfulTables)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tables Successful';
                        Style = Favorable;
                        StyleExpr = (TotalSuccessfulTables > 0);
                    }
                }
                cuegroup(RunStatistics)
                {
                    Caption = 'Run Statistics';
                    ShowCaption = true;
                    field("Tables Successful"; "Tables Successful")
                    {
                        ApplicationArea = Basic, Suite;
                        Style = Favorable;
                        StyleExpr = ("Tables Successful" > 0);
                        trigger OnDrillDown()
                        var
                            HybridReplicationDetail: Record "Hybrid Replication Detail";
                        begin
                            HybridReplicationDetail.SetRange("Run ID", "Run ID");
                            HybridReplicationDetail.SetRange(Status, Status::Completed);
                            Page.Run(4006, HybridReplicationDetail);
                        end;
                    }
                    field("Tables Failed"; "Tables Failed")
                    {
                        ApplicationArea = Basic, Suite;
                        Style = Unfavorable;
                        StyleExpr = ("Tables Failed" > 0);
                        trigger OnDrillDown()
                        var
                            HybridReplicationDetail: Record "Hybrid Replication Detail";
                        begin
                            HybridReplicationDetail.SetRange("Run ID", "Run ID");
                            HybridReplicationDetail.SetFilter(Status, '%1', HybridReplicationDetail.Status::Failed);
                            Page.Run(4006, HybridReplicationDetail);
                        end;
                    }
                }
                cuegroup(RunStatistics2)
                {
                    Caption = '_';
                    ShowCaption = false;
                    field("Tables with Warnings"; "Tables with Warnings")
                    {
                        ApplicationArea = Basic, Suite;
                        Style = Ambiguous;
                        StyleExpr = ("Tables with Warnings" > 0);
                        trigger OnDrillDown()
                        var
                            HybridReplicationDetail: Record "Hybrid Replication Detail";
                        begin
                            HybridReplicationDetail.SetRange("Run ID", "Run ID");
                            HybridReplicationDetail.SetFilter(Status, '%1', HybridReplicationDetail.Status::Warning);
                            Page.Run(4006, HybridReplicationDetail);
                        end;
                    }
                }
                field(Spacer1; '')
                {
                    ApplicationArea = All;
                    Caption = '';
                    Editable = false;
                    MultiLine = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        IntelligentCloud: Record "Intelligent Cloud";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
    begin
        if IntelligentCloudSetup.Get() then
            NextScheduledRun := IntelligentCloudSetup.GetNextScheduledRunDateTime(CurrentDateTime());

        Rec.FindFirst();
        if Rec."Run ID" <> '' then begin
            TotalSuccessfulTables := HybridCloudManagement.GetTotalSuccessfulTables();
            TotalTablesNotMigrated := HybridCloudManagement.GetTotalTablesNotMigrated();
            ReplicationEnabled := IntelligentCloud.Get() and IntelligentCloud.Enabled;
            SourceProduct := HybridCloudManagement.GetChosenProductName();
        end;
    end;

    var
        NextScheduledRun: DateTime;
        SourceProduct: Text;
        TotalSuccessfulTables: Integer;
        TotalTablesNotMigrated: Integer;
        ReplicationEnabled: Boolean;
}