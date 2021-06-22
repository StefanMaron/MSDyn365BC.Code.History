page 9803 Permissions
{
    Caption = 'Permissions';
    DataCaptionFields = "Object Type", "Object Name";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PopulateAllFields = true;
    PromotedActionCategories = 'New,Process,Report,Read,Insert,Modify,Delete,Execute';
    ShowFilter = false;
    SourceTable = Permission;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                group(Control42)
                {
                    ShowCaption = false;
                    field(CurrentRoleID; CurrentRoleID)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Permission Set';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the permission set that the permission belongs to.';
                    }
                }
            }
            repeater(Group)
            {
                Caption = 'AllPermission';
                field(PermissionSet; "Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    Enabled = false;
                    ToolTip = 'Specifies the ID of the permission sets that exist in the current database.';
                    Visible = false;
                }
                field("Object Type"; "Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AllowChangePrimaryKey;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies the type of object that the permissions apply to in the current database.';
                }
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AllowChangePrimaryKey;
                    LookupPageID = "All Objects with Caption";
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies the ID of the object to which the permissions apply.';
                }
                field(ObjectName; ObjectName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Name';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies the name of the object to which the permissions apply.';
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
                field("Read Permission"; "Read Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies information about whether the permission set has read permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have read permission.';
                }
                field("Insert Permission"; "Insert Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies information about whether the permission set has insert permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have insert permission.';
                }
                field("Modify Permission"; "Modify Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies information about whether the permission set has modify permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have modify permission.';
                }
                field("Delete Permission"; "Delete Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies information about whether the permission set has delete permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have delete permission.';
                }
                field("Execute Permission"; "Execute Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = NOT IsTableData;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies information about whether the permission set has execute permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have execute permission.';
                }
                field("Security Filter"; "Security Filter")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies the security filter that is being applied to this permission set to limit the access that this permission set has to the data contained in this table.';

                    trigger OnAssistEdit()
                    var
                        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
                        OutputSecurityFilter: Text;
                    begin
                        // User cannot edit Security filter field for Systems.
                        // Since this field is empty for System type it can be used as a flag it.
                        if Format("Security Filter") = '' then
                            exit;

                        if PermissionPagesMgt.ShowSecurityFilterForPermission(OutputSecurityFilter, Rec) then
                            Evaluate("Security Filter", OutputSecurityFilter);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(FilterPermissionSet)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select Permission Set';
                Image = Filter;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Specifies the filter of the permission sets that the object applies to.';

                trigger OnAction()
                var
                    AggregatePermissionSet: Record "Aggregate Permission Set";
                    SelectionFilterManagement: Codeunit SelectionFilterManagement;
                    PermissionSetList: Page "Permission Set List";
                begin
                    PermissionSetList.LookupMode(true);
                    if PermissionSetList.RunModal() = Action::LookupOK then begin
                        PermissionSetList.GetSelectionFilter(AggregatePermissionSet);
                        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::System);
                        CurrentRoleID := SelectionFilterManagement.GetSelectionFilterForAggregatePermissionSetRoleId(AggregatePermissionSet);
                        Reset();
                        FillTempPermissions();
                    end;
                end;
            }
            action(IncludeExclude)
            {
                AccessByPermission = TableData "Tenant Permission" = ID;
                ApplicationArea = Basic, Suite;
                Caption = 'Include/Exclude Permission Set';
                Visible = IsOnPrem;
                Image = Edit;
                ToolTip = 'Add or remove a specific permission set.';

                trigger OnAction()
                var
                    AggregatePermissionSet: Record "Aggregate Permission Set";
                    AddSubtractPermissionSet: Report "Add/Subtract Permission Set";
                    NullGuid: Guid;
                begin
                    AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, NullGuid, "Role ID");
                    AddSubtractPermissionSet.SetDestination(AggregatePermissionSet);
                    AddSubtractPermissionSet.RunModal;
                    Reset();
                    FillTempPermissions;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Permission: Record Permission;
    begin
        ActivateControls;
        SetObjectZeroName(Rec);
        if not IsNewRecord then begin
            Permission := Rec;
            PermissionRecExists := Permission.Find;
        end else
            PermissionRecExists := false;
        AllowChangePrimaryKey := not PermissionRecExists and (Show = Show::"Only In Permission Set");
        ZeroObjStyleExpr := PermissionRecExists and ("Object ID" = 0);
    end;

    trigger OnAfterGetRecord()
    begin
        SetObjectZeroName(Rec);
        ZeroObjStyleExpr := "Object ID" = 0;
        IsNewRecord := false;
    end;

    trigger OnOpenPage()
    var
        PermissionSet: Record "Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        PermissionPagesMgt.RaiseNotificationThatSecurityFilterNotEditableForSystemAndExtension;
        IsOnPrem := EnvironmentInformation.IsOnPrem();

        if CurrentRoleID = '' then
            if GetFilter("Role ID") <> '' then
                CurrentRoleID := GetFilter("Role ID")
            else
                if PermissionSet.FindFirst then
                    CurrentRoleID := PermissionSet."Role ID";
        Reset;
        FillTempPermissions;
    end;

    var
        CurrentRoleID: Text;
        Show: Option "Only In Permission Set",All;
        [InDataSet]
        IsTableData: Boolean;
        IsNewRecord: Boolean;
        PermissionRecExists: Boolean;
        AllowChangePrimaryKey: Boolean;
        AllObjTxt: Label 'All objects of type %1', Comment = '%1= type name, e.g. Table Data or Report or Page';
        ZeroObjStyleExpr: Boolean;
        ObjectName: Text;
        ObjectCaption: Text;
        IsOnPrem: Boolean;

    local procedure FillTempPermissions()
    var
        TempPermission: Record Permission temporary;
        Permission: Record Permission;
    begin
        TempPermission.Copy(Rec, true);
        TempPermission.Reset();
        TempPermission.DeleteAll();
        FilterGroup(2);
        SetFilter("Role ID", CurrentRoleID);
        Permission.SetFilter("Role ID", CurrentRoleID);
        FilterGroup(0);

        if Permission.Find('-') then
            repeat
                TempPermission := Permission;
                TempPermission.Insert();
            until Permission.Next = 0;

        if Show = Show::All then
            FillTempPermissionsForAllObjects(TempPermission);
        IsNewRecord := false;
        if Find('=<>') then;
        CurrPage.Update(false);
    end;

    local procedure FillTempPermissionsForAllObjects(var Permission: Record Permission)
    var
        TempPermission: Record Permission temporary;
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type");
        TempPermission.Copy(Permission, true);
        TempPermission.Init();
        if AllObj.FindSet then
            repeat
                TempPermission."Object Type" := AllObj."Object Type";
                TempPermission."Object ID" := AllObj."Object ID";
                TempPermission."Read Permission" := "Read Permission"::" ";
                TempPermission."Insert Permission" := "Insert Permission"::" ";
                TempPermission."Modify Permission" := "Modify Permission"::" ";
                TempPermission."Delete Permission" := "Delete Permission"::" ";
                TempPermission."Execute Permission" := "Execute Permission"::" ";
                SetObjectZeroName(TempPermission);
                if TempPermission.Insert() then;
            until AllObj.Next = 0;
    end;

    local procedure ActivateControls()
    begin
        IsTableData := "Object Type" = "Object Type"::"Table Data"
    end;

    local procedure SetObjectZeroName(var Permission: Record Permission)
    var
        AllObj: Record AllObj;
    begin
        if Permission."Object ID" <> 0 then begin
            Permission.CalcFields("Object Name");
            ObjectCaption := Permission."Object Name";
            ObjectName := '';
            if AllObj.Get(Permission."Object Type", Permission."Object ID") then
                ObjectName := AllObj."Object Name";
        end else begin
            ObjectName := CopyStr(StrSubstNo(AllObjTxt, Permission."Object Type"), 1, MaxStrLen(Permission."Object Name"));
            ObjectCaption := ObjectName;
        end;
    end;
}

