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
                Caption = 'Next Scheduled Run';
                Tooltip = 'Specifies the date and time of the next scheduled migration.';
                Enabled = false;
                Editable = false;
                ApplicationArea = Basic, Suite;
                Visible = ShowNextScheduled;
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
                        Caption = 'Source Product';
                        ToolTip = 'Specifies the selected source product for the migration.';
                        Enabled = false;
                        Editable = false;
                        ApplicationArea = Basic, Suite;
                        Visible = false;
                    }

                    field("Total Successful Tables"; TotalSuccessfulTables)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tables Successful';
                        ToolTip = 'Indicates the total number of tables that have been successfully migrated.';
                        Style = Favorable;
                        StyleExpr = (TotalSuccessfulTables > 0);
                    }

                    field("Tables not Migrated"; TotalTablesNotMigrated)
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = TablesNotMigratedEnabled;
                        Style = Ambiguous;
                        StyleExpr = (TotalTablesNotMigrated > 0);
                        Caption = 'Tables not Migrated';
                        ToolTip = 'Indicates the number of tables that are ignored during the migration.';

                        trigger OnDrillDown()
                        begin
                            ShowTablesNotMigrated();
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

                cuegroup(RunStatistics)
                {
                    Caption = 'Run Statistics';
                    ShowCaption = true;

                    field("Tables Successful"; "Tables Successful")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tables Successful';
                        Tooltip = 'Indicates the number of tables that were successful for the selected migration.';
                        Style = Favorable;
                        StyleExpr = ("Tables Successful" > 0);

                        trigger OnDrillDown()
                        var
                            HybridReplicationDetail: Record "Hybrid Replication Detail";
                        begin
                            HybridReplicationDetail.SetRange("Run ID", "Run ID");
                            HybridReplicationDetail.SetRange(Status, HybridReplicationDetail.Status::Successful);
                            Page.Run(Page::"Intelligent Cloud Details", HybridReplicationDetail);
                        end;
                    }
                    field("Tables Failed"; "Tables Failed")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tables Failed';
                        Tooltip = 'Indicates the number of tables that failed for the selected migration.';
                        Style = Unfavorable;
                        StyleExpr = ("Tables Failed" > 0);

                        trigger OnDrillDown()
                        var
                            HybridReplicationDetail: Record "Hybrid Replication Detail";
                        begin
                            HybridReplicationDetail.SetRange("Run ID", "Run ID");
                            HybridReplicationDetail.SetRange(Status, HybridReplicationDetail.Status::Failed);
                            Page.Run(Page::"Intelligent Cloud Details", HybridReplicationDetail);
                        end;
                    }
                }
                cuegroup(RunStatistics2)
                {
                    Caption = '_';
                    ShowCaption = false;

                    field("Tables Remaining"; "Tables Remaining")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tables Remaining';
                        Tooltip = 'Indicates the number of remaining tables to migrate for the selected migration.';
                        Style = Ambiguous;
                        StyleExpr = ("Tables Remaining" > 0);

                        trigger OnDrillDown()
                        var
                            HybridReplicationDetail: Record "Hybrid Replication Detail";
                        begin
                            HybridReplicationDetail.SetRange("Run ID", "Run ID");
                            HybridReplicationDetail.SetFilter(Status, '%1|%2', HybridReplicationDetail.Status::NotStarted, HybridReplicationDetail.Status::InProgress);
                            Page.Run(Page::"Intelligent Cloud Details", HybridReplicationDetail);
                        end;
                    }

                    field("Tables with Warnings"; "Tables with Warnings")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tables with Warnings';
                        Tooltip = 'Indicates the number of tables that had warnings for the selected migration.';
                        Style = Ambiguous;
                        StyleExpr = ("Tables with Warnings" > 0);

                        trigger OnDrillDown()
                        var
                            HybridReplicationDetail: Record "Hybrid Replication Detail";
                        begin
                            HybridReplicationDetail.SetRange("Run ID", "Run ID");
                            HybridReplicationDetail.SetRange(Status, HybridReplicationDetail.Status::Warning);
                            Page.Run(Page::"Intelligent Cloud Details", HybridReplicationDetail);
                        end;
                    }
                }

                field(Spacer2; '')
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
        CanShowTablesNotMigrated(TablesNotMigratedEnabled);
        if TablesNotMigratedEnabled then
            TotalTablesNotMigrated := HybridCloudManagement.GetTotalTablesNotMigrated();

        if IntelligentCloudSetup.Get() then
            NextScheduledRun := IntelligentCloudSetup.GetNextScheduledRunDateTime(CurrentDateTime());

        ShowNextScheduled := NextScheduledRun <> 0DT;
        Rec.FindFirst();
        if Rec."Run ID" <> '' then begin
            TotalSuccessfulTables := HybridCloudManagement.GetTotalSuccessfulTables();
            TotalTablesNotMigrated := HybridCloudManagement.GetTotalTablesNotMigrated();
            ReplicationEnabled := IntelligentCloud.Get() and IntelligentCloud.Enabled;
            SourceProduct := HybridCloudManagement.GetChosenProductName();
        end;
    end;

    local procedure ShowTablesNotMigrated()
    var
        HybridCompany: Record "Hybrid Company";
        IntelligentCloudNotMigrated: Record "Intelligent Cloud Not Migrated" temporary;
        TableMetadata: Record "Table Metadata";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
    begin
        HybridCompany.Reset();
        HybridCompany.SetRange(Replicate, true);
        if HybridCompany.FindSet() then begin
            IntelligentCloudNotMigrated.Reset();
            IntelligentCloudNotMigrated.DeleteAll();
            repeat
                TableMetadata.Reset();
                TableMetadata.SetRange(ReplicateData, false);
                TableMetadata.SetFilter(ID, '<%1|>%2', 2000000000, 2000000300);
                TableMetadata.SetFilter(Name, '<>*Buffer');
                TableMetadata.ChangeCompany(HybridCompany.Name);
                if TableMetadata.FindSet() then
                    repeat
                        IntelligentCloudNotMigrated.Init();
                        IntelligentCloudNotMigrated."Company Name" := HybridCompany.Name;
                        IntelligentCloudNotMigrated."Table Name" := HybridCloudManagement.ConstructTableName(TableMetadata.Name, TableMetadata.ID);
                        IntelligentCloudNotMigrated."Table Id" := TableMetadata.ID;
                        IntelligentCloudNotMigrated.Insert();
                    until TableMetadata.Next() = 0;
            until HybridCompany.Next() = 0;
        end;

        // Now add the system tables
        TableMetadata.Reset();
        TableMetadata.SetRange(ReplicateData, false);
        TableMetadata.SetRange(DataPerCompany, false);
        TableMetadata.SetFilter(ID, '<%1|>%2', 2000000000, 2000000300);
        TableMetadata.SetFilter(Name, '<>*Buffer');
        if TableMetadata.FindSet() then
            repeat
                IntelligentCloudNotMigrated.Init();
                IntelligentCloudNotMigrated."Company Name" := '';
                IntelligentCloudNotMigrated."Table Name" := HybridCloudManagement.ConstructTableName(TableMetadata.Name, TableMetadata.ID);
                IntelligentCloudNotMigrated."Table Id" := TableMetadata.ID;
                IntelligentCloudNotMigrated.Insert();
            until TableMetadata.Next() = 0;


        Page.Run(4019, IntelligentCloudNotMigrated);
    end;

    [IntegrationEvent(false, false)]
    local procedure CanShowTablesNotMigrated(var Enabled: Boolean)
    begin
    end;

    var
        NextScheduledRun: DateTime;
        SourceProduct: Text;
        TotalSuccessfulTables: Integer;
        TotalTablesNotMigrated: Integer;
        ReplicationEnabled: Boolean;
        ShowNextScheduled: Boolean;
        TablesNotMigratedEnabled: Boolean;
}