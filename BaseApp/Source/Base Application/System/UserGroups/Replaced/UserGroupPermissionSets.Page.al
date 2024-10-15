#if not CLEAN22
namespace System.Security.AccessControl;

page 9834 "User Group Permission Sets"
{
    Caption = 'User Group Permission Sets';
    PageType = List;
    SourceTable = "User Group Permission Set";
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] Replaced by the Security Group Permission Sets page in the security groups system; by Permission Set Subform page in the permission sets system. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
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
                            Rec."Role ID" := TempPermissionSetBuffer."Role ID";
                            Rec.Scope := TempPermissionSetBuffer.Scope;
                            Rec."App ID" := TempPermissionSetBuffer."App ID";
                            Rec.CalcFields("Extension Name", "Role Name");
                            Text := Rec."Role ID";
                            AppRoleName := TempPermissionSetBuffer.Name;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        AggregatePermissionSet: Record "Aggregate Permission Set";
                    begin
                        AggregatePermissionSet.SetRange("Role ID", Rec."Role ID");
                        AggregatePermissionSet.FindFirst();
                        Rec.Scope := AggregatePermissionSet.Scope;
                        Rec."App ID" := AggregatePermissionSet."App ID";
                        Rec.CalcFields("Extension Name", "Role Name");
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
        if Rec.Scope = Rec.Scope::Tenant then begin
            if TenantPermissionSet.Get(Rec."App ID", Rec."Role ID") then
                AppRoleName := TenantPermissionSet.Name
        end else
            if MetadataPermissionSet.Get(Rec."App ID", Rec."Role ID") then
                AppRoleName := MetadataPermissionSet.Name;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        exit(Rec."Role ID" <> '');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.TestField("Role ID");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AppRoleName := '';
    end;

    trigger OnOpenPage()
    begin
        if Rec."User Group Code" = IntelligentCloudTok then
            CurrPage.Editable(false);
    end;

    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        AppRoleName: Text[30];
        IntelligentCloudTok: Label 'INTELLIGENT CLOUD', Locked = true;
}

#endif