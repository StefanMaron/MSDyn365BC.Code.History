#if not CLEAN21
namespace System.Security.AccessControl;

using System.Reflection;
using System.Security.User;
using System.Text;

page 9850 "Tenant Permissions"
{
    Caption = 'Permissions';
    DataCaptionFields = "Object Type", "Object Name";
    DelayedInsert = true;
    PageType = Worksheet;
    PopulateAllFields = true;
    ShowFilter = false;
    SourceTable = "Tenant Permission";
    SourceTableTemporary = true;
    ObsoleteReason = 'Replaced by the Permission Set page.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = ControlsAreEditable;
                group(Control42)
                {
                    Editable = ControlsAreEditable;
                    ShowCaption = false;
                    field(CurrentRoleID; CurrentRoleID)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Permission Set';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the permission set that the permission belongs to.';

                        trigger OnValidate()
                        begin
                            FillTempPermissions();
                        end;

                        trigger OnAssistEdit()
                        begin
                            SelectFilterSet();
                        end;
                    }
                    field(Show; Show)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show';
                        OptionCaption = 'Only In Permission Set,All';
                        ToolTip = 'Specifies if the selected value is shown in the window.';
                        Visible = ControlsAreEditable;
                        Editable = SingleFilterSelected;

                        trigger OnValidate()
                        begin
                            FillTempPermissions();
                        end;
                    }
                }
                field(AddRelatedTables; AddRelatedTables)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Add Read Permission to Related Tables';
                    ToolTip = 'Specifies that all tables that are related to the selected table will be added to the window with Read permission.';
                    Visible = ControlsAreEditable;
                    Editable = SingleFilterSelected;
                }
                field(CopiedFromSystemRoleId; CopiedFromSystemRoleId)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copied from System Permission Set';
                    Editable = false;
                    ToolTip = 'Specifies the System Permission Set from which this was copied.';
                    Visible = ControlsAreEditable;

                    trigger OnDrillDown()
                    var
                        AggregatePermissionSet: Record "Aggregate Permission Set";
                        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
                        ZeroGuid: Guid;
                    begin
                        if CopiedFromSystemRoleId = '' then
                            exit;

                        PermissionPagesMgt.ShowPermissions(AggregatePermissionSet.Scope::System, ZeroGuid, CopiedFromSystemRoleId, false);
                    end;
                }
            }
            repeater(Group)
            {
                Caption = 'AllPermission';
                Editable = ControlsAreEditable;
                field(PermissionSet; Rec."Role ID")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Permission Set';
                    Enabled = false;
                    ToolTip = 'Specifies the ID of the permission sets that exist in the current database. This field is used internally.';
                    Visible = false;
                }
                field("Object Type"; Rec."Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AllowChangePrimaryKey;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies the type of object that the permissions apply to in the current database.';

                    trigger OnValidate()
                    begin
                        ActivateControls();
                        SetObjectZeroName(Rec);
                        EmptyIrrelevantPermissionFields();
                        SetRelevantPermissionFieldsToYes();
                    end;
                }
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AllowChangePrimaryKey;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies the ID of the object that the permissions apply to.';
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AllObjectswithCaption: Page "All Objects with Caption";
                    begin
                        exit(AllObjectswithCaption.OnLookupObjectId(Rec."Object Type", Text));
                    end;

                    trigger OnValidate()
                    begin
                        IsValidatedObjectID := false;
                        ActivateControls();
                        SetObjectZeroName(Rec);
                    end;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include/Exclude';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies whether the permission is effective for this permission set. If you create a hierarchy of permission sets, the setting for the permission in the highest set in the hierarchy is used..';
                }
                field(ObjectName; ObjectName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Name';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies the name of the object that the permissions apply to.';
                }
                field(ObjectCaption; ObjectCaption)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Caption';
                    Editable = false;
                    Visible = false;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies the caption of the object that the permissions apply to.';
                }
                field(Control8; Rec."Read Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData and SingleFilterSelected;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies if the permission set has read permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have read permission.';
                }
                field(Control7; Rec."Insert Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData and SingleFilterSelected;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies if the permission set has insert permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have insert permission.';
                }
                field(Control6; Rec."Modify Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData and SingleFilterSelected;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies if the permission set has modify permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have modify permission.';
                }
                field(Control5; Rec."Delete Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData and SingleFilterSelected;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies if the permission set has delete permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have delete permission.';
                }
                field(Control4; Rec."Execute Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = NOT IsTableData and SingleFilterSelected;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies if the permission set has execute permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have execute permission.';
                }
                field("Security Filter"; Rec."Security Filter")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData and SingleFilterSelected;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies a security filter that applies to this permission set to limit the access that this permission set has to the data contained in this table.';

                    trigger OnAssistEdit()
                    var
                        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
                        OutputSecurityFilter: Text;
                    begin
                        // User cannot edit Security filter field for Extensions but can edit for user created types.
                        // Since this field is empty and GUID exists for Extensions it can be used as a flag for them.
                        if (Format(Rec."Security Filter") = '') and (not IsNullGuid(CurrentAppID)) then
                            exit;

                        if PermissionPagesMgt.ShowSecurityFilterForTenantPermission(OutputSecurityFilter, Rec, ControlsAreEditable) then
                            Evaluate(Rec."Security Filter", OutputSecurityFilter);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Read Permission")
            {
                Caption = 'Read Permission';
                Image = Ledger;
                group("Allow Read")
                {
                    Caption = 'Allow Read';
                    Enabled = IsEditable and (Rec."Object Type" = Rec."Object Type"::"Table Data");
                    Image = Confirm;
                    action(AllowReadYes)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Yes';
                        Image = Approve;
                        ToolTip = 'Allow access to read data in the object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('R', Rec."Read Permission"::Yes);
                        end;
                    }
                    action(AllowReadNo)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'No';
                        Image = Reject;
                        ToolTip = 'Disallow access to read data in the object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('R', Rec."Read Permission"::" ");
                        end;
                    }
                    action(AllowReadIndirect)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Indirect';
                        Image = Indent;
                        ToolTip = 'Allow access to read data in the object if there is read access to a related object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('R', Rec."Read Permission"::Indirect);
                        end;
                    }
                }
            }
            group("Insert Permission")
            {
                Caption = 'Insert Permission';
                Image = FiledPosted;
                group("Allow Insertion")
                {
                    Caption = 'Allow Insertion';
                    Enabled = IsEditable and (Rec."Object Type" = Rec."Object Type"::"Table Data");
                    Image = Confirm;
                    action(AllowInsertYes)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Yes';
                        Image = Approve;
                        ToolTip = 'Allow access to insert data in the object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('I', Rec."Insert Permission"::Yes);
                        end;
                    }
                    action(AllowInsertNo)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'No';
                        Image = Reject;
                        ToolTip = 'Disallow access to insert data in the object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('I', Rec."Insert Permission"::" ");
                        end;
                    }
                    action(AllowInsertIndirect)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Indirect';
                        Image = Indent;
                        ToolTip = 'Allow access to insert data in the object if there is insert access to a related object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('I', Rec."Insert Permission"::Indirect);
                        end;
                    }
                }
            }
            group("Modify Permission")
            {
                Caption = 'Modify Permission';
                Image = Statistics;
                group("Allow Modification")
                {
                    Caption = 'Allow Modification';
                    Enabled = IsEditable and (Rec."Object Type" = Rec."Object Type"::"Table Data");
                    Image = Confirm;
                    action(AllowModifyYes)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Yes';
                        Image = Approve;
                        ToolTip = 'Allow access to modify data in the object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('M', Rec."Modify Permission"::Yes);
                        end;
                    }
                    action(AllowModifyNo)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'No';
                        Image = Reject;
                        ToolTip = 'Disallow access to modify data in the object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('M', Rec."Modify Permission"::" ");
                        end;
                    }
                    action(AllowModifyIndirect)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Indirect';
                        Image = Indent;
                        ToolTip = 'Allow access to modify data in the object if there is modify access to a related object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('M', Rec."Modify Permission"::Indirect);
                        end;
                    }
                }
            }
            group("Delete Permission")
            {
                Caption = 'Delete Permission';
                Image = Transactions;
                group("Allow Deletion")
                {
                    Caption = 'Allow Deletion';
                    Enabled = IsEditable and (Rec."Object Type" = Rec."Object Type"::"Table Data");
                    Image = Confirm;
                    action(AllowDeleteYes)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Yes';
                        Image = Approve;
                        ToolTip = 'Allow access to delete data in the object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('D', Rec."Delete Permission"::Yes);
                        end;
                    }
                    action(AllowDeleteNo)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'No';
                        Image = Reject;
                        ToolTip = 'Disallow access to delete data in the object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('D', Rec."Delete Permission"::" ");
                        end;
                    }
                    action(AllowDeleteIndirect)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Indirect';
                        Image = Indent;
                        ToolTip = 'Allow access to delete data in the object if there is delete access to a related object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('D', Rec."Delete Permission"::Indirect);
                        end;
                    }
                }
            }
            group("Execute Permission")
            {
                Caption = 'Execute Permission';
                Image = Transactions;
                group("Allow Execution")
                {
                    Caption = 'Allow Execution';
                    Enabled = IsEditable AND (Rec."Object Type" <> Rec."Object Type"::"Table Data");
                    Image = Confirm;
                    action(AllowExecuteYes)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Yes';
                        Image = Approve;
                        ToolTip = 'Allow access to execute functions in the object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('X', Rec."Execute Permission"::Yes);
                        end;
                    }
                    action(AllowExecuteNo)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'No';
                        Image = Reject;
                        ToolTip = 'Disallow access to execute functions in the object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('X', Rec."Execute Permission"::" ");
                        end;
                    }
                    action(AllowExecuteIndirect)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Indirect';
                        Image = Indent;
                        ToolTip = 'Allow access to execute functions in the object if there is execute access to a related object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('X', Rec."Execute Permission"::Indirect);
                        end;
                    }
                }
            }
            group("All Permissions")
            {
                Caption = 'All Permissions';
                Image = Transactions;
                group("Allow All")
                {
                    Caption = 'Allow All';
                    Image = Confirm;
                    action(AllowAllYes)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Yes';
                        Enabled = IsEditable;
                        Image = Approve;
                        ToolTip = 'Allow access to perform all actions in the object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('*', Rec."Read Permission"::Yes);
                        end;
                    }
                    action(AllowAllNo)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'No';
                        Enabled = IsEditable;
                        Image = Reject;
                        ToolTip = 'Disallow access to perform all actions in the object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('*', Rec."Read Permission"::" ");
                        end;
                    }
                    action(AllowAllIndirect)
                    {
                        AccessByPermission = TableData "Tenant Permission" = M;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Indirect';
                        Enabled = IsEditable;
                        Image = Indent;
                        ToolTip = 'Allow access to perform all actions in the object if there is full access to a related object.';

                        trigger OnAction()
                        begin
                            UpdateSelected('*', Rec."Read Permission"::Indirect);
                        end;
                    }
                }
            }
            group("Manage Permission Sets")
            {
                Caption = 'Manage Permission Sets';
                action(AddRelatedTablesAction)
                {
                    AccessByPermission = TableData "Tenant Permission" = I;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Add Read Permission to Related Tables';
                    Enabled = IsEditable and SingleFilterSelected;
                    Image = Relationship;
                    ToolTip = 'Define read access to tables that are related to the object.';

                    trigger OnAction()
                    begin
                        AddRelatedTablesToSelected();
                    end;
                }
                action(IncludeExclude)
                {
                    AccessByPermission = TableData "Tenant Permission" = ID;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include/Exclude Permission Set';
                    Enabled = IsEditable and SingleFilterSelected;
                    Image = Edit;
                    ToolTip = 'Add or remove a specific permission set.';

                    trigger OnAction()
                    var
                        AggregatePermissionSet: Record "Aggregate Permission Set";
                        AddSubtractPermissionSet: Report "Add/Subtract Permission Set";
                    begin
                        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, Rec."App ID", Rec."Role ID");
                        AddSubtractPermissionSet.SetDestination(AggregatePermissionSet);
                        AddSubtractPermissionSet.RunModal();
                        FillTempPermissions();
                    end;
                }
            }
            group("Code Coverage Actions")
            {
                Caption = 'Record Permissions';
                action(Start)
                {
                    AccessByPermission = TableData "Tenant Permission" = I;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start';
                    Enabled = (NOT PermissionLoggingRunning) AND (ControlsAreEditable);
                    Image = Start;
                    ToolTip = 'Start recording UI activities to generate the required permission set.';

                    trigger OnAction()
                    begin
                        if not Confirm(StartRecordingQst) then
                            exit;
                        LogTablePermissions.Start();
                        PermissionLoggingRunning := true;
                    end;
                }
                action(Stop)
                {
                    AccessByPermission = TableData "Tenant Permission" = I;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Stop';
                    Enabled = PermissionLoggingRunning AND ControlsAreEditable;
                    Image = Stop;
                    ToolTip = 'Stop recording.';

                    trigger OnAction()
                    var
                        TempTablePermissionBuffer: Record "Table Permission Buffer" temporary;
                    begin
                        LogTablePermissions.Stop(TempTablePermissionBuffer);
                        PermissionLoggingRunning := false;
                        if not Confirm(AddPermissionsQst) then
                            exit;
                        AddLoggedPermissions(TempTablePermissionBuffer);
                        FillTempPermissions();
                        if Rec.FindFirst() then;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Start_Promoted; Start)
                {
                }
                actionref(Stop_Promoted; Stop)
                {
                }
                actionref(IncludeExclude_Promoted; IncludeExclude)
                {
                }
                actionref(AddRelatedTablesAction_Promoted; AddRelatedTablesAction)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Read', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category5)
            {
                Caption = 'Insert', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Category6)
            {
                Caption = 'Modify', Comment = 'Generated from the PromotedActionCategories property index 5.';
            }
            group(Category_Category7)
            {
                Caption = 'Delete', Comment = 'Generated from the PromotedActionCategories property index 6.';
            }
            group(Category_Category8)
            {
                Caption = 'Execute', Comment = 'Generated from the PromotedActionCategories property index 7.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        TenantPermission: Record "Tenant Permission";
    begin
        ActivateControls();
        SetObjectZeroName(Rec);
        if not IsNewRecord then begin
            TenantPermission := Rec;
            PermissionRecExists := TenantPermission.Find();
        end else
            PermissionRecExists := false;
        SingleFilterSelected := Rec.GetRangeMin("Role ID") = Rec.GetRangeMax("Role ID");
        AllowChangePrimaryKey := not PermissionRecExists and (Show = Show::"Only In Permission Set") and SingleFilterSelected;
        ZeroObjStyleExpr := PermissionRecExists and (Rec."Object ID" = 0);
    end;

    trigger OnAfterGetRecord()
    begin
        SetObjectZeroName(Rec);
        ZeroObjStyleExpr := Rec."Object ID" = 0;
        IsValidatedObjectID := false;
        IsNewRecord := false;
        CurrPage.Editable := IsNullGuid(Rec."App ID");
    end;

    trigger OnDeleteRecord(): Boolean
    var
        TenantPermission: Record "Tenant Permission";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        if (Show = Show::All) and (Rec."Object ID" <> 0) then
            exit(false);

        if not IsNullGuid(CurrentAppID) then
            Error(CannotChangeExtensionPermissionErr);

        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();

        TenantPermission := Rec;
        TenantPermission.Find();
        exit(TenantPermission.Delete());
    end;

    trigger OnInit()
    begin
        SetControlsAsReadOnly();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TenantPermission: Record "Tenant Permission";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        if (Rec."Object ID" = 0) and ((Show = Show::All) or IsValidatedObjectID) then
            exit(false);

        if not IsNullGuid(CurrentAppID) then
            Error(CannotChangeExtensionPermissionErr);

        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();

        if (Rec."Execute Permission" = Rec."Execute Permission"::" ") and
           (Rec."Read Permission" = Rec."Read Permission"::" ") and
           (Rec."Insert Permission" = Rec."Insert Permission"::" ") and
           (Rec."Modify Permission" = Rec."Modify Permission"::" ") and
           (Rec."Delete Permission" = Rec."Delete Permission"::" ")
        then
            exit(false);

        if Rec."Object Type" = Rec."Object Type"::"Table Data" then
            Rec."Execute Permission" := Rec."Execute Permission"::" "
        else begin
            Rec."Read Permission" := Rec."Read Permission"::" ";
            Rec."Insert Permission" := Rec."Insert Permission"::" ";
            Rec."Modify Permission" := Rec."Modify Permission"::" ";
            Rec."Delete Permission" := Rec."Delete Permission"::" ";
        end;
        TenantPermission := Rec;
        TenantPermission.Insert();
        if AddRelatedTables then
            DoAddRelatedTables(Rec);
        Rec := TenantPermission;
        SetObjectZeroName(Rec);
        PermissionRecExists := true;
        IsNewRecord := false;
        ZeroObjStyleExpr := Rec."Object ID" = 0;
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        if not IsNullGuid(CurrentAppID) then
            Error(CannotChangeExtensionPermissionErr);

        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();

        ModifyRecord(Rec);
        PermissionRecExists := true;
        IsNewRecord := false;
        exit(Rec.Modify());
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ActivateControls();
        PermissionRecExists := false;
        IsNewRecord := true;
        IsValidatedObjectID := false;
        EmptyIrrelevantPermissionFields();
    end;

    trigger OnOpenPage()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionSetLink: Record "Permission Set Link";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        UserPermissions: Codeunit "User Permissions";
    begin
        if Rec.GetFilter("App ID") <> '' then
            CurrentAppID := Rec.GetFilter("App ID")
        else
            if TenantPermissionSet.FindFirst() then
                CurrentAppID := TenantPermissionSet."App ID";

        if not IsNullGuid(CurrentAppID) then
            PermissionPagesMgt.RaiseNotificationThatSecurityFilterNotEditableForSystemAndExtension();

        if CurrentRoleID = '' then
            if Rec.GetFilter("Role ID") <> '' then
                CurrentRoleID := Rec.GetFilter("Role ID")
            else
                if TenantPermissionSet.FindFirst() then
                    CurrentRoleID := TenantPermissionSet."Role ID";
        Rec.Reset();
        FillTempPermissions();
        IsEditable := CurrPage.Editable;
        SingleFilterSelected := Rec.GetRangeMin("Role ID") = Rec.GetRangeMax("Role ID");
        if SingleFilterSelected then
            CopiedFromSystemRoleId := PermissionSetLink.GetSourceForLinkedPermissionSet(CurrentRoleID);

        CanManageUsersOnTenant := UserPermissions.CanManageUsersOnTenant(UserSecurityId());
        IsEmptyCurrentAppID := IsNullGuid(CurrentAppID)
    end;

    var
        LogTablePermissions: Codeunit "Log Table Permissions";
        CurrentAppID: Text;
        CurrentRoleID: Text;
        CopiedFromSystemRoleId: Code[20];
        Show: Option "Only In Permission Set",All;
        AddRelatedTables: Boolean;
        IsTableData: Boolean;
        IsNewRecord: Boolean;
        IsValidatedObjectID: Boolean;
        PermissionRecExists: Boolean;
        AllowChangePrimaryKey: Boolean;
        AddPermissionsQst: Label 'Do you want to add the recorded permissions?';
        StartRecordingQst: Label 'Do you want to start the recording now?';
        AllObjTxt: Label 'All objects of type %1', Comment = '%1= type name, e.g. Table Data or Report or Page';
        ZeroObjStyleExpr: Boolean;
        PermissionLoggingRunning: Boolean;
        ControlsAreEditable: Boolean;
        ObjectName: Text;
        IsEditable: Boolean;
        CannotChangeExtensionPermissionErr: Label 'You cannot change permissions sets of type Extension.';
        ObjectCaption: Text;
        SingleFilterSelected: Boolean;
        CanManageUsersOnTenant: Boolean;
        IsEmptyCurrentAppID: Boolean;

    local procedure FillTempPermissions()
    var
        TempTenantPermission: Record "Tenant Permission" temporary;
        TenantPermission: Record "Tenant Permission";
    begin
        TempTenantPermission.Copy(Rec, true);
        TempTenantPermission.Reset();
        TempTenantPermission.DeleteAll();
        Rec.FilterGroup(2);
        Rec.SetFilter("Role ID", CurrentRoleID);
        TenantPermission.SetFilter("Role ID", CurrentRoleID);
        TenantPermission.SetFilter("App ID", CurrentAppID);
        Rec.FilterGroup(0);

        if TenantPermission.FindSet() then
            repeat
                TempTenantPermission := TenantPermission;
                TempTenantPermission.Insert();
            until TenantPermission.Next() = 0;

        if Show = Show::All then
            FillTempPermissionsForAllObjects(TempTenantPermission);
        IsNewRecord := false;
        if Rec.Find('=<>') then;
        CurrPage.Update(false);
    end;

    local procedure FillTempPermissionsForAllObjects(var TenantPermission: Record "Tenant Permission")
    var
        TempTenantPermission: Record "Tenant Permission" temporary;
        AllObj: Record AllObj;
    begin
        AllObj.SetFilter("Object Type", '%1|%2|%3|%4|%5|%6|%7|%8|%9',
          TenantPermission."Object Type"::"Table Data",
          TenantPermission."Object Type"::Table,
          TenantPermission."Object Type"::Report,
          TenantPermission."Object Type"::Codeunit,
          TenantPermission."Object Type"::XMLport,
          TenantPermission."Object Type"::MenuSuite,
          TenantPermission."Object Type"::Page,
          TenantPermission."Object Type"::Query,
          TenantPermission."Object Type"::System);
        TempTenantPermission.Copy(TenantPermission, true);
        TempTenantPermission.Init();
        if AllObj.FindSet() then
            repeat
                TempTenantPermission."Object Type" := AllObj."Object Type";
                TempTenantPermission."Object ID" := AllObj."Object ID";
                TempTenantPermission."Read Permission" := Rec."Read Permission"::" ";
                TempTenantPermission."Insert Permission" := Rec."Insert Permission"::" ";
                TempTenantPermission."Modify Permission" := Rec."Modify Permission"::" ";
                TempTenantPermission."Delete Permission" := Rec."Delete Permission"::" ";
                TempTenantPermission."Execute Permission" := Rec."Execute Permission"::" ";
                SetObjectZeroName(TempTenantPermission);
                if TempTenantPermission.Insert() then;
            until AllObj.Next() = 0;
    end;

    local procedure SelectFilterSet()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        PermissionSetList: Page "Permission Set List";
    begin
        PermissionSetList.LookupMode(true);
        if PermissionSetList.RunModal() = Action::LookupOK then begin
            PermissionSetList.GetSelectionFilter(AggregatePermissionSet);
            AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
            CurrentRoleID := SelectionFilterManagement.GetSelectionFilterForAggregatePermissionSetRoleId(AggregatePermissionSet);
            Rec.Reset();
            FillTempPermissions();
        end;
    end;

    local procedure ActivateControls()
    begin
        IsTableData := Rec."Object Type" = Rec."Object Type"::"Table Data"
    end;

    local procedure ModifyRecord(var ModifiedTenantPermission: Record "Tenant Permission")
    var
        TenantPermission: Record "Tenant Permission";
        IsNewPermission: Boolean;
    begin
        TenantPermission.LockTable();
        IsNewPermission :=
          not TenantPermission.Get(ModifiedTenantPermission."App ID", ModifiedTenantPermission."Role ID",
            ModifiedTenantPermission."Object Type", ModifiedTenantPermission."Object ID");
        if IsNewPermission then begin
            TenantPermission.TransferFields(ModifiedTenantPermission, true);
            TenantPermission.Insert();
        end else begin
            TenantPermission.TransferFields(ModifiedTenantPermission, false);
            TenantPermission.Modify();
        end;

        if (TenantPermission."Read Permission" = 0) and
           (TenantPermission."Insert Permission" = 0) and
           (TenantPermission."Modify Permission" = 0) and
           (TenantPermission."Delete Permission" = 0) and
           (TenantPermission."Execute Permission" = 0)
        then
            DeleteTenantPermission(TenantPermission, ModifiedTenantPermission, IsNewPermission);

        if IsNewPermission and AddRelatedTables then
            DoAddRelatedTables(ModifiedTenantPermission);
    end;

    local procedure DeleteTenantPermission(var TenantPermission: Record "Tenant Permission"; var ModifiedTenantPermission: Record "Tenant Permission"; var IsNewPermission: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteTenantPermission(TenantPermission, IsHandled);
        if IsHandled then
            exit;

        TenantPermission.Delete();
        if Show = Show::"Only In Permission Set" then
            ModifiedTenantPermission.Delete();
        IsNewPermission := false;
    end;

    local procedure UpdateSelected(RIMDX: Text[1]; PermissionOption: Option)
    var
        TempTenantPermission: Record "Tenant Permission" temporary;
        OriginalTenantPermission: Record "Tenant Permission";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();

        OriginalTenantPermission := Rec;
        TempTenantPermission.Copy(Rec, true);
        CurrPage.SetSelectionFilter(TempTenantPermission);

        if TempTenantPermission.FindSet() then
            repeat
                case RIMDX of
                    'R':
                        if TempTenantPermission."Object Type" = Rec."Object Type"::"Table Data" then
                            TempTenantPermission."Read Permission" := PermissionOption;
                    'I':
                        if TempTenantPermission."Object Type" = Rec."Object Type"::"Table Data" then
                            TempTenantPermission."Insert Permission" := PermissionOption;
                    'M':
                        if TempTenantPermission."Object Type" = Rec."Object Type"::"Table Data" then
                            TempTenantPermission."Modify Permission" := PermissionOption;
                    'D':
                        if TempTenantPermission."Object Type" = Rec."Object Type"::"Table Data" then
                            TempTenantPermission."Delete Permission" := PermissionOption;
                    'X':
                        if TempTenantPermission."Object Type" <> Rec."Object Type"::"Table Data" then
                            TempTenantPermission."Execute Permission" := PermissionOption;
                    '*':
                        if TempTenantPermission."Object Type" = Rec."Object Type"::"Table Data" then begin
                            TempTenantPermission."Read Permission" := PermissionOption;
                            TempTenantPermission."Insert Permission" := PermissionOption;
                            TempTenantPermission."Modify Permission" := PermissionOption;
                            TempTenantPermission."Delete Permission" := PermissionOption;
                        end else
                            TempTenantPermission."Execute Permission" := PermissionOption;
                end;
                ModifyRecord(TempTenantPermission);
                if Rec.Get(TempTenantPermission."App ID", TempTenantPermission."Role ID",
                     TempTenantPermission."Object Type", TempTenantPermission."Object ID")
                then begin
                    Rec := TempTenantPermission;
                    Rec.Modify();
                end;
            until TempTenantPermission.Next() = 0;

        Rec := OriginalTenantPermission;
        if Rec.Find() then;
    end;

    local procedure AddRelatedTablesToSelected()
    var
        TempTenantPermission: Record "Tenant Permission" temporary;
    begin
        TempTenantPermission.Copy(Rec, true);
        CurrPage.SetSelectionFilter(TempTenantPermission);
        if TempTenantPermission.FindSet() then
            repeat
                DoAddRelatedTables(TempTenantPermission);
            until TempTenantPermission.Next() = 0;
        if Rec.Find() then;
    end;

    local procedure AddLoggedPermissions(var TablePermissionBuffer: Record "Table Permission Buffer")
    begin
        TablePermissionBuffer.SetRange("Session ID", SessionId());
        if TablePermissionBuffer.FindSet() then
            repeat
                AddPermission(CurrentAppID, CurrentRoleID,
                  TablePermissionBuffer."Object Type",
                  TablePermissionBuffer."Object ID",
                  TablePermissionBuffer."Read Permission",
                  TablePermissionBuffer."Insert Permission",
                  TablePermissionBuffer."Modify Permission",
                  TablePermissionBuffer."Delete Permission",
                  TablePermissionBuffer."Execute Permission");
            until TablePermissionBuffer.Next() = 0;
        TablePermissionBuffer.DeleteAll();
    end;

    local procedure DoAddRelatedTables(var TenantPermission: Record "Tenant Permission")
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
    begin
        if TenantPermission."Object Type" <> TenantPermission."Object Type"::"Table Data" then
            exit;
        if TenantPermission."Object ID" = 0 then
            exit;

        TableRelationsMetadata.SetRange("Table ID", TenantPermission."Object ID");
        TableRelationsMetadata.SetFilter("Related Table ID", '>0&<>%1', TenantPermission."Object ID");
        if TableRelationsMetadata.FindSet() then
            repeat
                AddPermission(
                  CurrentAppID, CurrentRoleID, Rec."Object Type"::"Table Data", TableRelationsMetadata."Related Table ID", Rec."Read Permission"::Yes,
                  Rec."Insert Permission"::" ", Rec."Modify Permission"::" ", Rec."Delete Permission"::" ", Rec."Execute Permission"::" ");
            until TableRelationsMetadata.Next() = 0;
    end;

    local procedure AddPermission(AppID: Guid; RoleID: Code[20]; ObjectType: Option; ObjectID: Integer; AddRead: Option; AddInsert: Option; AddModify: Option; AddDelete: Option; AddExecute: Option): Boolean
    var
        TenantPermission: Record "Tenant Permission";
        LogTablePermissions: Codeunit "Log Table Permissions";
    begin
        if not Rec.Get(AppID, RoleID, ObjectType, ObjectID) then begin
            Rec.Init();
            Rec."App ID" := AppID;
            Rec."Role ID" := RoleID;
            Rec."Object Type" := ObjectType;
            Rec."Object ID" := ObjectID;
            Rec."Read Permission" := Rec."Read Permission"::" ";
            Rec."Insert Permission" := Rec."Insert Permission"::" ";
            Rec."Modify Permission" := Rec."Modify Permission"::" ";
            Rec."Delete Permission" := Rec."Delete Permission"::" ";
            Rec."Execute Permission" := Rec."Execute Permission"::" ";
            Rec.Insert();
            TenantPermission.TransferFields(Rec, true);
            TenantPermission.Insert();
        end;

        Rec."Read Permission" := LogTablePermissions.GetMaxPermission(Rec."Read Permission", AddRead);
        Rec."Insert Permission" := LogTablePermissions.GetMaxPermission(Rec."Insert Permission", AddInsert);
        Rec."Modify Permission" := LogTablePermissions.GetMaxPermission(Rec."Modify Permission", AddModify);
        Rec."Delete Permission" := LogTablePermissions.GetMaxPermission(Rec."Delete Permission", AddDelete);
        Rec."Execute Permission" := LogTablePermissions.GetMaxPermission(Rec."Execute Permission", AddExecute);

        SetObjectZeroName(Rec);
        Rec.Modify();
        TenantPermission.LockTable();
        if not TenantPermission.Get(AppID, RoleID, ObjectType, ObjectID) then begin
            TenantPermission.TransferFields(Rec, true);
            TenantPermission.Insert();
        end else begin
            TenantPermission.TransferFields(Rec, false);
            TenantPermission.Modify();
        end;
        exit(true);
    end;

    local procedure SetObjectZeroName(var TenantPermission: Record "Tenant Permission")
    var
        AllObj: Record AllObj;
    begin
        if TenantPermission."Object ID" <> 0 then begin
            TenantPermission.CalcFields("Object Name");
            ObjectCaption := TenantPermission."Object Name";
            ObjectName := '';
            if AllObj.Get(TenantPermission."Object Type", TenantPermission."Object ID") then
                ObjectName := AllObj."Object Name";
        end else begin
            ObjectName := CopyStr(StrSubstNo(AllObjTxt, TenantPermission."Object Type"), 1, MaxStrLen(TenantPermission."Object Name"));
            ObjectCaption := ObjectName;
        end;
    end;

    procedure SetControlsAsEditable()
    begin
        ControlsAreEditable := true;
    end;

    procedure SetControlsAsReadOnly()
    begin
        ControlsAreEditable := false;
    end;

    local procedure EmptyIrrelevantPermissionFields()
    begin
        if Rec."Object Type" = Rec."Object Type"::"Table Data" then
            Rec."Execute Permission" := Rec."Execute Permission"::" "
        else begin
            Rec."Read Permission" := Rec."Read Permission"::" ";
            Rec."Insert Permission" := Rec."Insert Permission"::" ";
            Rec."Modify Permission" := Rec."Modify Permission"::" ";
            Rec."Delete Permission" := Rec."Delete Permission"::" ";
        end;
    end;

    local procedure SetRelevantPermissionFieldsToYes()
    begin
        if Rec."Object Type" = Rec."Object Type"::"Table Data" then begin
            Rec."Read Permission" := Rec."Read Permission"::Yes;
            Rec."Insert Permission" := Rec."Insert Permission"::Yes;
            Rec."Modify Permission" := Rec."Modify Permission"::Yes;
            Rec."Delete Permission" := Rec."Delete Permission"::Yes;
        end else
            Rec."Execute Permission" := Rec."Execute Permission"::Yes;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteTenantPermission(var TenantPermission: Record "Tenant Permission"; var IsHandled: Boolean)
    begin
    end;
}

#endif
