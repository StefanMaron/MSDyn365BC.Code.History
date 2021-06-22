pageextension 4030 "Intelligent Cloud Stat Ext" extends "Intelligent Cloud Stat Factbox"
{
    layout
    {
        addlast(MigrationStatistics)
        {
            field("Tables not Migrated"; TotalTablesNotMigrated)
            {
                ApplicationArea = Basic, Suite;
                Style = Ambiguous;
                StyleExpr = (TotalTablesNotMigrated > 0);
                trigger OnDrillDown()
                var
                    HybridCompany: Record "Hybrid Company";
                    IntelligentCloudNotMigrated: Record "Intelligent Cloud Not Migrated" temporary;
                    TableMetadata: Record "Table Metadata";
                    HybridCloudManagement: Codeunit "Hybrid Cloud Management";
                begin
                    if SourceProduct = ProductNameTxt then begin
                        HybridCompany.Reset();
                        HybridCompany.SetRange(Replicate, true);
                        if HybridCompany.FindSet() then begin
                            IntelligentCloudNotMigrated.Reset();
                            IntelligentCloudNotMigrated.DeleteAll();
                            repeat
                                TableMetadata.RESET();
                                TableMetadata.SETRANGE(ReplicateData, false);
                                TableMetadata.SetFilter(ID, '<%1|>%2', 2000000000, 2000000300);
                                TableMetadata.SetFilter(Name, '<>*Buffer');
                                TableMetadata.CHANGECOMPANY(HybridCompany.Name);
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
                        TableMetadata.RESET();
                        TableMetadata.SETRANGE(ReplicateData, false);
                        TableMetadata.SETRANGE(DataPerCompany, false);
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
                    end;

                    Page.Run(4019, IntelligentCloudNotMigrated);
                end;
            }

        }
    }
    trigger OnOpenPage()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
    begin
        SourceProduct := HybridCloudManagement.GetChosenProductName();
        TotalTablesNotMigrated := 0;
        HybridReplicationSummary.FindFirst();
        if SourceProduct = ProductNameTxt then
            if HybridReplicationSummary."Run ID" <> '' then
                TotalTablesNotMigrated := HybridCloudManagement.GetTotalTablesNotMigrated();
    end;

    var
        TotalTablesNotMigrated: Integer;
        ProductNameTxt: Label 'Dynamics 365 Business Central', Locked = true;
        SourceProduct: Text;
}

