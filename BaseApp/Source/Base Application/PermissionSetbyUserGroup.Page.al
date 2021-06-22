page 9837 "Permission Set by User Group"
{
    Caption = 'Permission Set by User Group';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Browse';
    SourceTable = "Aggregate Permission Set";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Permission Set';
                field("Role ID"; "Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    Editable = false;
                    ToolTip = 'Specifies the permission set.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the record.';
                }
                field("App ID"; "App ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension ID';
                    ToolTip = 'Specifies the unique identifier for the extension. A unique identifier will be generated if a value is not provided.';
                    Visible = false;
                }
                field("App Name"; "App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    ToolTip = 'Specifies the name of an extension.';
                }
                field(AllUsersHavePermission; AllGroupsHavePermission)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'All User Groups';
                    ToolTip = 'Specifies if the user is a member of all user groups.';

                    trigger OnValidate()
                    begin
                        if AllGroupsHavePermission then
                            if not Confirm(AllUserGrpGetsPermissionQst) then
                                Error('');

                        SetColumnPermission(0, AllGroupsHavePermission);
                        CurrPage.Update(false);
                    end;
                }
                field(Column1; UserGroupHasPermissionSet[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[1];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 1;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(1, UserGroupHasPermissionSet[1]);
                    end;
                }
                field(Column2; UserGroupHasPermissionSet[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[2];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 2;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(2, UserGroupHasPermissionSet[2]);
                    end;
                }
                field(Column3; UserGroupHasPermissionSet[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[3];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 3;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(3, UserGroupHasPermissionSet[3]);
                    end;
                }
                field(Column4; UserGroupHasPermissionSet[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[4];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 4;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(4, UserGroupHasPermissionSet[4]);
                    end;
                }
                field(Column5; UserGroupHasPermissionSet[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[5];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 5;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(5, UserGroupHasPermissionSet[5]);
                    end;
                }
                field(Column6; UserGroupHasPermissionSet[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[6];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 6;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(6, UserGroupHasPermissionSet[6]);
                    end;
                }
                field(Column7; UserGroupHasPermissionSet[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[7];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 7;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(7, UserGroupHasPermissionSet[7]);
                    end;
                }
                field(Column8; UserGroupHasPermissionSet[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[8];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 8;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(8, UserGroupHasPermissionSet[8]);
                    end;
                }
                field(Column9; UserGroupHasPermissionSet[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[9];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 9;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(9, UserGroupHasPermissionSet[9]);
                    end;
                }
                field(Column10; UserGroupHasPermissionSet[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[10];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 10;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(10, UserGroupHasPermissionSet[10]);
                    end;
                }
            }
        }
        area(factboxes)
        {
            part(Control23; "Permissions FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Permissions';
                SubPageLink = "Role ID" = FIELD("Role ID");
            }
            part("Tenant Permissions"; "Tenant Permissions FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Tenant Permissions';
                Editable = false;
                SubPageLink = "Role ID" = FIELD("Role ID"),
                              "App ID" = FIELD("App ID");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Permissions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Permissions';
                Image = Permission;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'View or edit which feature objects that users need to access and set up the related permissions in permission sets that you can assign to the users of the database.';

                trigger OnAction()
                var
                    PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
                begin
                    PermissionPagesMgt.ShowPermissions(Scope, "App ID", "Role ID", false);
                end;
            }
        }
        area(processing)
        {
            action(CopyPermissionSet)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Permission Set';
                Ellipsis = true;
                Enabled = CanManageUsersOnTenant;
                Image = Copy;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Create a copy of the selected permission set with a name that you specify.';

                trigger OnAction()
                var
                    AggregatePermissionSet: Record "Aggregate Permission Set";
                begin
                    AggregatePermissionSet.SetRange(Scope, Scope);
                    AggregatePermissionSet.SetRange("App ID", "App ID");
                    AggregatePermissionSet.SetRange("Role ID", "Role ID");

                    REPORT.RunModal(REPORT::"Copy Permission Set", true, true, AggregatePermissionSet);
                end;
            }
            action(AllColumnsLeft)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'All Columns Left';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Jump to the left-most column.';

                trigger OnAction()
                begin
                    PermissionPagesMgt.AllColumnsLeft;
                end;
            }
            action(ColumnLeft)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Column Left';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Jump one column to the left.';

                trigger OnAction()
                begin
                    PermissionPagesMgt.ColumnLeft;
                end;
            }
            action(ColumnRight)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Column Right';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Jump one column to the right.';

                trigger OnAction()
                begin
                    PermissionPagesMgt.ColumnRight;
                end;
            }
            action(AllColumnsRight)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'All Columns Right';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Jump to the right-most column.';

                trigger OnAction()
                begin
                    PermissionPagesMgt.AllColumnsRight;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        FindUserGroups;
    end;

    trigger OnAfterGetRecord()
    begin
        FindUserGroups;
    end;

    trigger OnInit()
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        CanManageUsersOnTenant := UserPermissions.CanManageUsersOnTenant(UserSecurityId);
    end;

    trigger OnOpenPage()
    var
        UserGroup: Record "User Group";
    begin
        NoOfRecords := UserGroup.Count();
        PermissionPagesMgt.Init(NoOfRecords, ArrayLen(UserGroupCodeArr));
    end;

    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        AllGroupsHavePermission: Boolean;
        CanManageUsersOnTenant: Boolean;
        NoOfRecords: Integer;
        UserGroupCodeArr: array[10] of Code[20];
        UserGroupHasPermissionSet: array[10] of Boolean;
        AllUserGrpGetsPermissionQst: Label 'Are you sure you want to add this permission set to all user groups?';

    local procedure FindUserGroups()
    var
        UserGroup: Record "User Group";
        i: Integer;
    begin
        Clear(UserGroupCodeArr);
        Clear(UserGroupHasPermissionSet);
        AllGroupsHavePermission := true;
        if UserGroup.FindSet then
            repeat
                i += 1;
                if PermissionPagesMgt.IsInColumnsRange(i) then begin
                    UserGroupCodeArr[i - PermissionPagesMgt.GetOffset] := UserGroup.Code;
                    UserGroupHasPermissionSet[i - PermissionPagesMgt.GetOffset] := UserGroupHasPermission(Rec, UserGroup);
                    AllGroupsHavePermission := AllGroupsHavePermission and UserGroupHasPermissionSet[i - PermissionPagesMgt.GetOffset];
                end else
                    if AllGroupsHavePermission then
                        AllGroupsHavePermission := UserGroupHasPermission(Rec, UserGroup);
            until (UserGroup.Next = 0) or (PermissionPagesMgt.IsPastColumnRange(i) and not AllGroupsHavePermission);
    end;

    local procedure UserGroupHasPermission(var AggregatePermissionSet: Record "Aggregate Permission Set"; var UserGroup: Record "User Group"): Boolean
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet.SetRange("User Group Code", UserGroup.Code);
        UserGroupPermissionSet.SetRange("Role ID", AggregatePermissionSet."Role ID");
        UserGroupPermissionSet.SetRange("App ID", AggregatePermissionSet."App ID");
        exit(not UserGroupPermissionSet.IsEmpty);
    end;

    local procedure SetColumnPermission(ColumnNo: Integer; UserHasPermission: Boolean)
    var
        UserGroup: Record "User Group";
    begin
        if ColumnNo > 0 then begin
            SetUserGroupPermission(UserGroupCodeArr[ColumnNo], UserHasPermission);
            AllGroupsHavePermission := AllGroupsHavePermission and UserHasPermission;
        end else
            if UserGroup.FindSet then
                repeat
                    SetUserGroupPermission(UserGroup.Code, UserHasPermission);
                until UserGroup.Next = 0;
    end;

    local procedure SetUserGroupPermission(UserGroupCode: Code[20]; UserGroupHasPermission: Boolean)
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        if UserGroupPermissionSet.Get(UserGroupCode, "Role ID", Scope, "App ID") then begin
            if not UserGroupHasPermission then
                UserGroupPermissionSet.Delete(true);
            exit;
        end;
        if not UserGroupHasPermission then
            exit;
        UserGroupPermissionSet.Init();
        UserGroupPermissionSet."User Group Code" := UserGroupCode;
        UserGroupPermissionSet."Role ID" := "Role ID";
        UserGroupPermissionSet."App ID" := "App ID";
        UserGroupPermissionSet.Scope := Scope;
        UserGroupPermissionSet.Insert(true);
    end;
}

