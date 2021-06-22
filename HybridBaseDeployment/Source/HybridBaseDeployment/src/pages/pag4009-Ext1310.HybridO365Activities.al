pageextension 4009 "Hybrid O365 Activities" extends "O365 Activities"
{
    layout
    {
        addlast(Control54)
        {
            field("Replication Success Rate"; "Replication Success Rate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Table Migration Success Rate';
                DrillDownPageId = "Intelligent Cloud Management";
                StyleExpr = CueStyle;
                ToolTip = 'Specifies the percentage rate for the number of tables successfully migrated.';
                Visible = IsIntelligentCloudEnabled;
            }
        }
    }

    trigger OnOpenPage()
    var
        PermissionManager: Codeunit "Permission Manager";
    begin
        IsIntelligentCloudEnabled := PermissionManager.IsIntelligentCloud();
    end;

    trigger OnAfterGetRecord()
    var
        HybridCueSetupManagement: Codeunit "Hybrid Cue Setup Management";
    begin
        if FieldActive("Replication Success Rate") then begin
            "Replication Success Rate" := HybridCueSetupManagement.GetReplicationSuccessRateCueValue();
            CueStyle := Format(HybridCueSetupManagement.GetReplicationSuccessRateCueStyle("Replication Success Rate"));
        end;
    end;

    var
        CueStyle: Text;
        IsIntelligentCloudEnabled: Boolean;
}