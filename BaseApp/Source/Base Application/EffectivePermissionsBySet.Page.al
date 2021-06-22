page 9853 "Effective Permissions By Set"
{
    Caption = 'By Permission Set';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Permission Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control5)
            {
                ShowCaption = false;
                field("Permission Set"; "Permission Set")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the permission set through which the user has the permission selected above.';

                    trigger OnDrillDown()
                    var
                        TenantPermission: Record "Tenant Permission";
                    begin
                        if Source = Source::Entitlement then
                            exit;
                        OpenPermissionsPage(true);
                        if Type = Type::"User-Defined" then begin
                            TenantPermission.Get(GetAppID, "Permission Set", CurrObjectType, CurrObjectID);
                            "Read Permission" := TenantPermission."Read Permission";
                            "Insert Permission" := TenantPermission."Insert Permission";
                            "Modify Permission" := TenantPermission."Modify Permission";
                            "Delete Permission" := TenantPermission."Delete Permission";
                            "Execute Permission" := TenantPermission."Execute Permission";
                            Modify;
                            RefreshDisplayTexts;
                        end;
                    end;
                }
                field(Source; Source)
                {
                    ApplicationArea = All;
                    Enabled = false;
                    Style = Strong;
                    StyleExpr = Source = Source::Entitlement;
                    ToolTip = 'Specifies the origin of the permission through which the user has the permission selected above. NOTE: Rows of source Entitlement originate from the subscription plan. The permission values of the entitlement overrule values in other permission sets if they have a higher ranking. In those cases, the permission value is in brackets to indicate that it is not effective.';
                    Visible = IsSaaS;
                }
                field(Type; Type)
                {
                    ApplicationArea = All;
                    Enabled = false;
                    ToolTip = 'Specifies the type of the permission set through which the user has the permission selected above. NOTE: Only permission sets of type User-Defined can be edited. ';
                }
                field(ReadTxt; ReadTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Read Permission';
                    Enabled = IsPermissionSetEditable AND IsTableData;
                    LookupPageID = "Option Lookup List";
                    Style = Subordinate;
                    StyleExpr = ReadIgnored;
                    TableRelation = "Option Lookup Buffer"."Option Caption" WHERE("Lookup Type" = CONST(Permissions));
                    ToolTip = 'Specifies the user''s read permission with this permission set. ';

                    trigger OnValidate()
                    var
                        TenantPermission: Record "Tenant Permission";
                    begin
                        OnPermissionValidate(TenantPermission.FieldNo("Read Permission"), ReadTxt, FieldCaption("Read Permission"));
                    end;
                }
                field(InsertTxt; InsertTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Insert Permission';
                    Enabled = IsPermissionSetEditable AND IsTableData;
                    LookupPageID = "Option Lookup List";
                    Style = Subordinate;
                    StyleExpr = InsertIgnored;
                    TableRelation = "Option Lookup Buffer"."Option Caption" WHERE("Lookup Type" = CONST(Permissions));
                    ToolTip = 'Specifies the user''s insert permission with this permission set.';

                    trigger OnValidate()
                    var
                        TenantPermission: Record "Tenant Permission";
                    begin
                        OnPermissionValidate(TenantPermission.FieldNo("Insert Permission"), InsertTxt, FieldCaption("Insert Permission"));
                    end;
                }
                field(ModifyTxt; ModifyTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Modify Permission';
                    Enabled = IsPermissionSetEditable AND IsTableData;
                    LookupPageID = "Option Lookup List";
                    Style = Subordinate;
                    StyleExpr = ModifyIgnored;
                    TableRelation = "Option Lookup Buffer"."Option Caption" WHERE("Lookup Type" = CONST(Permissions));
                    ToolTip = 'Specifies the user''s modify permission with this permission set.';

                    trigger OnValidate()
                    var
                        TenantPermission: Record "Tenant Permission";
                    begin
                        OnPermissionValidate(TenantPermission.FieldNo("Modify Permission"), ModifyTxt, FieldCaption("Modify Permission"));
                    end;
                }
                field(DeleteTxt; DeleteTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Delete Permission';
                    Enabled = IsPermissionSetEditable AND IsTableData;
                    LookupPageID = "Option Lookup List";
                    Style = Subordinate;
                    StyleExpr = DeleteIgnored;
                    TableRelation = "Option Lookup Buffer"."Option Caption" WHERE("Lookup Type" = CONST(Permissions));
                    ToolTip = 'Specifies the user''s delete permission with this permission set.';

                    trigger OnValidate()
                    var
                        TenantPermission: Record "Tenant Permission";
                    begin
                        OnPermissionValidate(TenantPermission.FieldNo("Delete Permission"), DeleteTxt, FieldCaption("Delete Permission"));
                    end;
                }
                field(ExecuteTxt; ExecuteTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Execute Permission';
                    Enabled = IsPermissionSetEditable AND (NOT IsTableData);
                    LookupPageID = "Option Lookup List";
                    Style = Subordinate;
                    StyleExpr = ExecuteIgnored;
                    TableRelation = "Option Lookup Buffer"."Option Caption" WHERE("Lookup Type" = CONST(Permissions));
                    ToolTip = 'Specifies the user''s execute permission with this permission set.';

                    trigger OnValidate()
                    var
                        TenantPermission: Record "Tenant Permission";
                    begin
                        OnPermissionValidate(TenantPermission.FieldNo("Execute Permission"), ExecuteTxt, FieldCaption("Execute Permission"));
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnAfterGetRecord()
    begin
        IsPermissionSetEditable := (Type = Type::"User-Defined") and CurrentUserCanManageUser;
        RefreshDisplayTexts;
    end;

    trigger OnInit()
    var
        PermissionManager: Codeunit "Permission Manager";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        CurrentUserCanManageUser := PermissionManager.CanManageUsersOnTenant(UserSecurityId);
        IsSaaS := EnvironmentInfo.IsSaaS;
    end;

    trigger OnOpenPage()
    begin
        SetCurrentKey(Source, Type);
    end;

    var
        EntitlementPermissionBuffer: Record "Permission Buffer";
        ReadTxt: Text;
        InsertTxt: Text;
        ModifyTxt: Text;
        DeleteTxt: Text;
        ExecuteTxt: Text;
        IsPermissionSetEditable: Boolean;
        CurrentUserCanManageUser: Boolean;
        IsSaaS: Boolean;
        IsTableData: Boolean;
        CurrObjectType: Option;
        CurrObjectID: Integer;
        BadlyFormattedTextErr: Label 'Your entry of ''%1'' is not an acceptable value for ''%2''.', Comment = '%1 = The entered value for the permission field;%2 = the caption of the permission field';
        CurrUserID: Guid;
        [InDataSet]
        ReadIgnored: Boolean;
        [InDataSet]
        InsertIgnored: Boolean;
        [InDataSet]
        ModifyIgnored: Boolean;
        [InDataSet]
        DeleteIgnored: Boolean;
        [InDataSet]
        ExecuteIgnored: Boolean;

    local procedure RefreshDisplayTexts()
    var
        PermissionManager: Codeunit "Permission Manager";
    begin
        ReadIgnored := PermissionManager.IsFirstPermissionHigherThanSecond("Read Permission",
            EntitlementPermissionBuffer."Read Permission");
        InsertIgnored := PermissionManager.IsFirstPermissionHigherThanSecond("Insert Permission",
            EntitlementPermissionBuffer."Insert Permission");
        ModifyIgnored := PermissionManager.IsFirstPermissionHigherThanSecond("Modify Permission",
            EntitlementPermissionBuffer."Modify Permission");
        DeleteIgnored := PermissionManager.IsFirstPermissionHigherThanSecond("Delete Permission",
            EntitlementPermissionBuffer."Delete Permission");
        ExecuteIgnored := PermissionManager.IsFirstPermissionHigherThanSecond("Execute Permission",
            EntitlementPermissionBuffer."Execute Permission");

        ReadTxt := FormatPermissionOption("Read Permission", ReadIgnored);
        InsertTxt := FormatPermissionOption("Insert Permission", InsertIgnored);
        ModifyTxt := FormatPermissionOption("Modify Permission", ModifyIgnored);
        DeleteTxt := FormatPermissionOption("Delete Permission", DeleteIgnored);
        ExecuteTxt := FormatPermissionOption("Execute Permission", ExecuteIgnored);

        CurrPage.Update(false);
    end;

    procedure SetRecordAndRefresh(PassedUserID: Guid; PassedCompanyName: Text[50]; CurrentObjectType: Option; CurrentObjectID: Integer)
    var
        TempPermissionBuffer: Record "Permission Buffer" temporary;
        Permission: Record Permission;
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
    begin
        EffectivePermissionsMgt.PopulatePermissionBuffer(TempPermissionBuffer, PassedUserID, PassedCompanyName,
          CurrentObjectType, CurrentObjectID);

        DeleteAll;

        if TempPermissionBuffer.FindSet then
            repeat
                Rec := TempPermissionBuffer;
                Insert;
                if TempPermissionBuffer.Source = TempPermissionBuffer.Source::Entitlement then
                    EntitlementPermissionBuffer := TempPermissionBuffer;
            until TempPermissionBuffer.Next = 0;

        CurrObjectType := CurrentObjectType;
        CurrObjectID := CurrentObjectID;
        CurrUserID := PassedUserID;
        IsTableData := CurrObjectType = Permission."Object Type"::"Table Data";

        CurrPage.Update(false);
    end;

    local procedure FormatPermissionOption(PermissionOption: Option; AddParenthesis: Boolean): Text
    var
        PermissionBuffer: Record "Permission Buffer";
    begin
        PermissionBuffer."Read Permission" := PermissionOption;
        if AddParenthesis then
            exit(StrSubstNo('(%1)', PermissionBuffer."Read Permission"));
        exit(Format(PermissionBuffer."Read Permission"));
    end;

    local procedure GetPermissionOptionFromCaptionText(Text: Text): Integer
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        if StrPos(Text, '(') = 1 then begin
            Text := CopyStr(Text, 2);
            Text := CopyStr(Text, 1, StrPos(Text, ')') - 1);
        end;
        exit(TypeHelper.GetOptionNoFromTableField(Text, DATABASE::"Permission Buffer", FieldNo("Read Permission")));
    end;

    local procedure OnPermissionValidate(FieldNum: Integer; NewValue: Text; FieldCaption: Text)
    var
        TenantPermission: Record "Tenant Permission";
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        NewPermOption: Integer;
    begin
        NewPermOption := GetPermissionOptionFromCaptionText(NewValue);
        if NewPermOption < 0 then
            Error(BadlyFormattedTextErr, NewValue, FieldCaption);
        case FieldNum of
            TenantPermission.FieldNo("Read Permission"):
                "Read Permission" := NewPermOption;
            TenantPermission.FieldNo("Insert Permission"):
                "Insert Permission" := NewPermOption;
            TenantPermission.FieldNo("Modify Permission"):
                "Modify Permission" := NewPermOption;
            TenantPermission.FieldNo("Delete Permission"):
                "Delete Permission" := NewPermOption;
            TenantPermission.FieldNo("Execute Permission"):
                "Execute Permission" := NewPermOption;
        end;
        EffectivePermissionsMgt.ModifyPermission(FieldNum, Rec, CurrObjectType, CurrObjectID, CurrUserID);
        Modify;
        RefreshDisplayTexts;
    end;
}

