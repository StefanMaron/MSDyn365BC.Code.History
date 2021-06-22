report 9000 "Add/Subtract Permission Set"
{
    Caption = 'Add/Subtract Permission Set';
    ProcessingOnly = true;

    dataset
    {
        dataitem(SourcePermissionSet; "Aggregate Permission Set")
        {
            DataItemTableView = SORTING(Scope, "App ID", "Role ID") ORDER(Ascending);

            trigger OnAfterGetRecord()
            var
                Permission: Record Permission;
                TenantPermission: Record "Tenant Permission";
            begin
                if DummySourceAggregatePermissionSet.Scope = DummySourceAggregatePermissionSet.Scope::System then begin
                    Permission.SetRange("Role ID", DummySourceAggregatePermissionSet."Role ID");
                    if Permission.FindSet then
                        repeat
                            IncludeExcludePermission(Permission);
                        until Permission.Next = 0;
                end else begin
                    TenantPermission.SetRange("App ID", DummySourceAggregatePermissionSet."App ID");
                    TenantPermission.SetRange("Role ID", DummySourceAggregatePermissionSet."Role ID");
                    if TenantPermission.FindSet then
                        repeat
                            IncludeExcludeTenantPermission(TenantPermission);
                        until TenantPermission.Next = 0;
                end;
            end;

            trigger OnPreDataItem()
            begin
                CopyFilters(DummySourceAggregatePermissionSet);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(DstnAggregatePermissionSet; DestinationAggregatePermissionSet."Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Destination';
                    Editable = false;
                    TableRelation = "Aggregate Permission Set"."Role ID";
                    ToolTip = 'Specifies the permission set for which permission sets are included or excluded.';
                }
                field(SetOperation; SetOperation)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Operation';
                    OptionCaption = 'Include,Exclude';
                    ToolTip = 'Specifies if the batch job includes or excludes a permission set for the destination permission set.';
                }
                field(SourceAggregatePermissionSet; DummySourceAggregatePermissionSet."Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source';
                    Editable = false;
                    ToolTip = 'Specifies which permission set is included or excluded for the destination permission set.';

                    trigger OnAssistEdit()
                    var
                        TempPermissionSetBuffer: Record "Permission Set Buffer" temporary;
                        PermissionSetList: Page "Permission Set List";
                    begin
                        PermissionSetList.LookupMode := true;
                        if PermissionSetList.RunModal = ACTION::LookupOK then begin
                            PermissionSetList.GetRecord(TempPermissionSetBuffer);
                            DummySourceAggregatePermissionSet.TransferFields(TempPermissionSetBuffer);
                        end;
                    end;
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if DestinationAggregatePermissionSet."Role ID" = '' then
            Error(NoDestinationErr);
        if DummySourceAggregatePermissionSet."Role ID" = '' then
            Error(NoSourceErr);
        if DestinationAggregatePermissionSet.RecordId = DummySourceAggregatePermissionSet.RecordId then
            Error(SameSrcDestnErr);
        DummySourceAggregatePermissionSet.SetRecFilter;
    end;

    var
        DestinationAggregatePermissionSet: Record "Aggregate Permission Set";
        DummySourceAggregatePermissionSet: Record "Aggregate Permission Set";
        SetOperation: Option Include,Exclude;
        NoDestinationErr: Label 'No destination permission set has been set.';
        NoSourceErr: Label 'You must select a source permission set.';
        SameSrcDestnErr: Label 'You cannot select permission set as both source and destination.';

    procedure SetDestination(NewDestinationAggregatePermissionSet: Record "Aggregate Permission Set")
    begin
        DestinationAggregatePermissionSet := NewDestinationAggregatePermissionSet;
    end;

    local procedure PermissionValueIsGreaterOrEqual(Left: Option " ",Yes,Indirect; Right: Option " ",Yes,Indirect): Boolean
    begin
        // Returns (Left >= Right)
        case Left of
            Left::" ":
                exit(Right = Right::" ");
            Left::Yes:
                exit(true);
            Left::Indirect:
                exit(Right <> Right::Yes);
        end;
    end;

    local procedure IncludeExcludePermission(SourcePermission: Record Permission)
    var
        DestinationTenantPermission: Record "Tenant Permission";
    begin
        case SetOperation of
            SetOperation::Include:
                if DestinationTenantPermission.Get(
                     DestinationAggregatePermissionSet."App ID", DestinationAggregatePermissionSet."Role ID",
                     SourcePermission."Object Type", SourcePermission."Object ID")
                then begin
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Read Permission", DestinationTenantPermission."Read Permission") then
                        DestinationTenantPermission."Read Permission" := SourcePermission."Read Permission";
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Insert Permission", DestinationTenantPermission."Insert Permission") then
                        DestinationTenantPermission."Insert Permission" := SourcePermission."Insert Permission";
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Modify Permission", DestinationTenantPermission."Modify Permission") then
                        DestinationTenantPermission."Modify Permission" := SourcePermission."Modify Permission";
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Delete Permission", DestinationTenantPermission."Delete Permission") then
                        DestinationTenantPermission."Delete Permission" := SourcePermission."Delete Permission";
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Execute Permission", DestinationTenantPermission."Execute Permission") then
                        DestinationTenantPermission."Execute Permission" := SourcePermission."Execute Permission";
                    DestinationTenantPermission.Modify;
                end else begin
                    DestinationTenantPermission."Object ID" := SourcePermission."Object ID";
                    DestinationTenantPermission."Object Type" := SourcePermission."Object Type";
                    DestinationTenantPermission."Read Permission" := SourcePermission."Read Permission";
                    DestinationTenantPermission."Insert Permission" := SourcePermission."Insert Permission";
                    DestinationTenantPermission."Modify Permission" := SourcePermission."Modify Permission";
                    DestinationTenantPermission."Delete Permission" := SourcePermission."Delete Permission";
                    DestinationTenantPermission."Execute Permission" := SourcePermission."Execute Permission";
                    DestinationTenantPermission."Security Filter" := SourcePermission."Security Filter";
                    DestinationTenantPermission."Role ID" := DestinationAggregatePermissionSet."Role ID";
                    DestinationTenantPermission."App ID" := DestinationAggregatePermissionSet."App ID";
                    DestinationTenantPermission.Insert;
                end;
            SetOperation::Exclude:
                begin
                    DestinationTenantPermission.SetRange("App ID", DestinationAggregatePermissionSet."App ID");
                    DestinationTenantPermission.SetRange("Role ID", DestinationAggregatePermissionSet."Role ID");
                    DestinationTenantPermission.SetRange("Object Type", SourcePermission."Object Type");
                    if SourcePermission."Object ID" <> 0 then
                        DestinationTenantPermission.SetRange("Object ID", SourcePermission."Object ID");
                    if DestinationTenantPermission.FindSet then
                        repeat
                            if PermissionValueIsGreaterOrEqual(SourcePermission."Read Permission", DestinationTenantPermission."Read Permission") then
                                DestinationTenantPermission."Read Permission" := SourcePermission."Read Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(SourcePermission."Insert Permission", DestinationTenantPermission."Insert Permission") then
                                DestinationTenantPermission."Insert Permission" := SourcePermission."Insert Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(SourcePermission."Modify Permission", DestinationTenantPermission."Modify Permission") then
                                DestinationTenantPermission."Modify Permission" := SourcePermission."Modify Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(SourcePermission."Delete Permission", DestinationTenantPermission."Delete Permission") then
                                DestinationTenantPermission."Delete Permission" := SourcePermission."Delete Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourcePermission."Execute Permission", DestinationTenantPermission."Execute Permission")
                            then
                                DestinationTenantPermission."Execute Permission" := SourcePermission."Execute Permission"::" ";
                            DestinationTenantPermission.Modify;
                            if (DestinationTenantPermission."Read Permission" = SourcePermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Insert Permission" = SourcePermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Modify Permission" = SourcePermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Delete Permission" = SourcePermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Execute Permission" = SourcePermission."Read Permission"::" ")
                            then
                                DestinationTenantPermission.Delete;
                        until DestinationTenantPermission.Next = 0;
                end;
        end;
    end;

    local procedure IncludeExcludeTenantPermission(SourceTenantPermission: Record "Tenant Permission")
    var
        DestinationTenantPermission: Record "Tenant Permission";
    begin
        case SetOperation of
            SetOperation::Include:
                if DestinationTenantPermission.Get(
                     DestinationAggregatePermissionSet."App ID", DestinationAggregatePermissionSet."Role ID",
                     SourceTenantPermission."Object Type", SourceTenantPermission."Object ID")
                then begin
                    if PermissionValueIsGreaterOrEqual(SourceTenantPermission."Read Permission", DestinationTenantPermission."Read Permission") then
                        DestinationTenantPermission."Read Permission" := SourceTenantPermission."Read Permission";
                    if PermissionValueIsGreaterOrEqual(
                         SourceTenantPermission."Insert Permission", DestinationTenantPermission."Insert Permission")
                    then
                        DestinationTenantPermission."Insert Permission" := SourceTenantPermission."Insert Permission";
                    if PermissionValueIsGreaterOrEqual(
                         SourceTenantPermission."Modify Permission", DestinationTenantPermission."Modify Permission")
                    then
                        DestinationTenantPermission."Modify Permission" := SourceTenantPermission."Modify Permission";
                    if PermissionValueIsGreaterOrEqual(
                         SourceTenantPermission."Delete Permission", DestinationTenantPermission."Delete Permission")
                    then
                        DestinationTenantPermission."Delete Permission" := SourceTenantPermission."Delete Permission";
                    if PermissionValueIsGreaterOrEqual(
                         SourceTenantPermission."Execute Permission", DestinationTenantPermission."Execute Permission")
                    then
                        DestinationTenantPermission."Execute Permission" := SourceTenantPermission."Execute Permission";
                    DestinationTenantPermission.Modify;
                end else begin
                    DestinationTenantPermission := SourceTenantPermission;
                    DestinationTenantPermission."Role ID" := DestinationAggregatePermissionSet."Role ID";
                    DestinationTenantPermission."App ID" := DestinationAggregatePermissionSet."App ID";
                    DestinationTenantPermission.Insert;
                end;
            SetOperation::Exclude:
                begin
                    DestinationTenantPermission.SetRange("App ID", DestinationAggregatePermissionSet."App ID");
                    DestinationTenantPermission.SetRange("Role ID", DestinationAggregatePermissionSet."Role ID");
                    DestinationTenantPermission.SetRange("Object Type", SourceTenantPermission."Object Type");
                    if SourceTenantPermission."Object ID" <> 0 then
                        DestinationTenantPermission.SetRange("Object ID", SourceTenantPermission."Object ID");
                    if DestinationTenantPermission.FindSet then
                        repeat
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Read Permission", DestinationTenantPermission."Read Permission")
                            then
                                DestinationTenantPermission."Read Permission" := SourceTenantPermission."Read Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Insert Permission", DestinationTenantPermission."Insert Permission")
                            then
                                DestinationTenantPermission."Insert Permission" := SourceTenantPermission."Insert Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Modify Permission", DestinationTenantPermission."Modify Permission")
                            then
                                DestinationTenantPermission."Modify Permission" := SourceTenantPermission."Modify Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Delete Permission", DestinationTenantPermission."Delete Permission")
                            then
                                DestinationTenantPermission."Delete Permission" := SourceTenantPermission."Delete Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Execute Permission", DestinationTenantPermission."Execute Permission")
                            then
                                DestinationTenantPermission."Execute Permission" := SourceTenantPermission."Execute Permission"::" ";
                            DestinationTenantPermission.Modify;
                            if (DestinationTenantPermission."Read Permission" = SourceTenantPermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Insert Permission" = SourceTenantPermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Modify Permission" = SourceTenantPermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Delete Permission" = SourceTenantPermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Execute Permission" = SourceTenantPermission."Read Permission"::" ")
                            then
                                DestinationTenantPermission.Delete;
                        until DestinationTenantPermission.Next = 0;
                end;
        end;
    end;
}

