#if not CLEAN21
page 9803 Permissions
{
    Caption = 'Permissions';
    DataCaptionFields = "Object Type", "Object Name";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    PopulateAllFields = true;
    ShowFilter = false;
    SourceTable = Permission;
    SourceTableTemporary = true;
    ObsoleteReason = 'Replaced by the Expanded Permissions page.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

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

                        trigger OnAssistEdit()
                        begin
                            SelectFilterSet();
                        end;
                    }
                }
            }
            repeater(Group)
            {
                Caption = 'AllPermission';
                Editable = false;
                field(PermissionSet; "Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    Enabled = false;
                    ToolTip = 'Specifies the ID of the permission sets that exist in the current database.';
                    Visible = false;
                }
                field("Object Type"; Rec."Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AllowChangePrimaryKey;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies the type of object that the permissions apply to in the current database.';
                }
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AllowChangePrimaryKey;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies the ID of the object to which the permissions apply.';
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AllObjectswithCaption: Page "All Objects with Caption";
                    begin
                        exit(AllObjectswithCaption.OnLookupObjectId("Object Type", Text));
                    end;
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
                field("Read Permission"; Rec."Read Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies information about whether the permission set has read permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have read permission.';
                }
                field("Insert Permission"; Rec."Insert Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies information about whether the permission set has insert permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have insert permission.';
                }
                field("Modify Permission"; Rec."Modify Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies information about whether the permission set has modify permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have modify permission.';
                }
                field("Delete Permission"; Rec."Delete Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsTableData;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies information about whether the permission set has delete permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have delete permission.';
                }
                field("Execute Permission"; Rec."Execute Permission")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = NOT IsTableData;
                    Style = Strong;
                    StyleExpr = ZeroObjStyleExpr;
                    ToolTip = 'Specifies information about whether the permission set has execute permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have execute permission.';
                }
                field("Security Filter"; Rec."Security Filter")
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
                    AddSubtractPermissionSet.RunModal();
                    Reset();
                    FillTempPermissions();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
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
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Permission: Record Permission;
    begin
        ActivateControls();
        SetObjectZeroName(Rec);
        if not IsNewRecord then begin
            Permission := Rec;
            PermissionRecExists := Permission.Find();
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
        PermissionPagesMgt.RaiseNotificationThatSecurityFilterNotEditableForSystemAndExtension();
        IsOnPrem := EnvironmentInformation.IsOnPrem();

        if CurrentRoleID = '' then
            if GetFilter("Role ID") <> '' then
                CurrentRoleID := GetFilter("Role ID")
            else
                if PermissionSet.FindFirst() then
                    CurrentRoleID := PermissionSet."Role ID";
        Reset();
        FillTempPermissions();
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
            until Permission.Next() = 0;

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
        if AllObj.FindSet() then
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
            AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::System);
            CurrentRoleID := SelectionFilterManagement.GetSelectionFilterForAggregatePermissionSetRoleId(AggregatePermissionSet);
            Reset();
            FillTempPermissions();
        end;
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

#endif