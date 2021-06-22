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
                        ToolTip = 'Specifies the selected source product for the migration.';
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
            ReplicationEnabled := IntelligentCloud.Get() and IntelligentCloud.Enabled;
            SourceProduct := HybridCloudManagement.GetChosenProductName();
        end;
    end;

    protected procedure ShowTablesNotMigrated()
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
    protected procedure CanShowTablesNotMigrated(var Enabled: Boolean)
    begin
    end;

    var
        NextScheduledRun: DateTime;
        SourceProduct: Text;
        TotalSuccessfulTables: Integer;
        ReplicationEnabled: Boolean;
}