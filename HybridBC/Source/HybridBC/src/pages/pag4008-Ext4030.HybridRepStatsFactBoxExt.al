pageextension 4030 "Intelligent Cloud Stat Ext" extends "Intelligent Cloud Stat Factbox"
{
    layout
    {
        addlast(MigrationStatistics)
        {
            field("Tables not Migrated"; TotalTablesNotMigrated)
            {
                ApplicationArea = Basic, Suite;
                Visible = TablesNotMigratedEnabled;
                Style = Ambiguous;
                StyleExpr = (TotalTablesNotMigrated > 0);
                trigger OnDrillDown()
                begin
                    ShowTablesNotMigrated();
                end;
            }
        }
    }
    
    trigger OnOpenPage()
    var
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
    begin
        CanShowTablesNotMigrated(TablesNotMigratedEnabled);
        if TablesNotMigratedEnabled then
            TotalTablesNotMigrated := HybridCloudManagement.GetTotalTablesNotMigrated();
    end;

    var
        TotalTablesNotMigrated: Integer;  
        TablesNotMigratedEnabled: Boolean;
}

