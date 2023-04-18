#if not CLEAN22
page 9834 "User Group Permission Sets"
{
    Caption = 'User Group Permission Sets';
    PageType = List;
    SourceTable = "User Group Permission Set";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the Security Group Permission Sets page in the security groups system.';
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Role ID"; Rec."Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    NotBlank = true;
                    ToolTip = 'Specifies a permission set that defines the role.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TempPermissionSetBuffer: Record "Permission Set Buffer" temporary;
                        PermissionSets: Page "Permission Sets";
                    begin
                        PermissionSets.LookupMode(true);
                        if PermissionSets.RunModal() = ACTION::LookupOK then begin
                            PermissionSets.GetRecord(TempPermissionSetBuffer);
                            "Role ID" := TempPermissionSetBuffer."Role ID";
                            Scope := TempPermissionSetBuffer.Scope;
                            "App ID" := TempPermissionSetBuffer."App ID";
                            CalcFields("Extension Name", "Role Name");
                            Text := "Role ID";
                            AppRoleName := TempPermissionSetBuffer.Name;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        AggregatePermissionSet: Record "Aggregate Permission Set";
                    begin
                        AggregatePermissionSet.SetRange("Role ID", "Role ID");
                        AggregatePermissionSet.FindFirst();
                        Scope := AggregatePermissionSet.Scope;
                        "App ID" := AggregatePermissionSet."App ID";
                        CalcFields("Extension Name", "Role Name");
                        AppRoleName := AggregatePermissionSet.Name;
                    end;
                }
                field("Role Name"; AppRoleName)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the permission set.';
                }
                field("App Name"; Rec."Extension Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the extension that provides the permission set.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SelectPermissionSets)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select Permission Sets';
                Ellipsis = true;
                Image = NewItem;
                ToolTip = 'Add two or more permission sets.';

                trigger OnAction()
                var
                    ManageUserPlansAndGroups: Codeunit "Manage User Plans And Groups";
                begin
                    ManageUserPlansAndGroups.SelectUserGroups(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Scope = Scope::Tenant then begin
            if TenantPermissionSetRec.Get("App ID", "Role ID") then
                AppRoleName := TenantPermissionSetRec.Name
        end else
            if PermissionSetRec.Get("Role ID") then
                AppRoleName := PermissionSetRec.Name;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        exit("Role ID" <> '');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        TestField("Role ID");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AppRoleName := '';
    end;

    trigger OnOpenPage()
    begin
        if "User Group Code" = IntelligentCloudTok then
            CurrPage.Editable(false);
    end;

    var
        PermissionSetRec: Record "Permission Set";
        TenantPermissionSetRec: Record "Tenant Permission Set";
        AppRoleName: Text[30];
        IntelligentCloudTok: Label 'INTELLIGENT CLOUD', Locked = true;
}

#endif