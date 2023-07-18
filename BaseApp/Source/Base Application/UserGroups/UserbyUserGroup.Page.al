#if not CLEAN22
page 9838 "User by User Group"
{
    Caption = 'User by User Group';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = User;
    ObsoleteState = Pending;
    ObsoleteReason = 'The user groups functionality is deprecated. Adding users to security groups is done in M365 admin center or Users and Groups menu in Windows.';
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(SelectedCompany; SelectedCompany)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Name';
                    TableRelation = Company;
                    ToolTip = 'Specifies the company that you want to see users for.';

                    trigger OnValidate()
                    begin
                        Company.Name := SelectedCompany;
                        if SelectedCompany <> '' then begin
                            Company.Find('=<>');
                            SelectedCompany := Company.Name;
                        end;
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Group)
            {
                Caption = 'Permission Set';
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user''s name. If the user is required to present credentials when starting the client, this is the name that the user must present.';
                }
                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the full name of the user.';
                }
                field(MemberOfAllGroups; MemberOfAllGroups)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'All User Groups';
                    ToolTip = 'Specifies if the user is a member of all user groups.';

                    trigger OnValidate()
                    begin
                        SetColumnPermission(0, MemberOfAllGroups);
                        CurrPage.Update(false);
                    end;
                }
                field(Column1; IsMemberOfUserGroup[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[1];
                    ToolTip = 'Specifies if the user is a member of this user group.';
                    Visible = NoOfRecords >= 1;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(1, IsMemberOfUserGroup[1]);
                    end;
                }
                field(Column2; IsMemberOfUserGroup[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[2];
                    ToolTip = 'Specifies if the user is a member of this user group.';
                    Visible = NoOfRecords >= 2;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(2, IsMemberOfUserGroup[2]);
                    end;
                }
                field(Column3; IsMemberOfUserGroup[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[3];
                    ToolTip = 'Specifies if the user is a member of this user group.';
                    Visible = NoOfRecords >= 3;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(3, IsMemberOfUserGroup[3]);
                    end;
                }
                field(Column4; IsMemberOfUserGroup[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[4];
                    ToolTip = 'Specifies if the user is a member of this user group.';
                    Visible = NoOfRecords >= 4;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(4, IsMemberOfUserGroup[4]);
                    end;
                }
                field(Column5; IsMemberOfUserGroup[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[5];
                    ToolTip = 'Specifies if the user is a member of this user group.';
                    Visible = NoOfRecords >= 5;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(5, IsMemberOfUserGroup[5]);
                    end;
                }
                field(Column6; IsMemberOfUserGroup[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[6];
                    ToolTip = 'Specifies if the user is a member of this user group.';
                    Visible = NoOfRecords >= 6;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(6, IsMemberOfUserGroup[6]);
                    end;
                }
                field(Column7; IsMemberOfUserGroup[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[7];
                    ToolTip = 'Specifies if the user is a member of this user group.';
                    Visible = NoOfRecords >= 7;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(7, IsMemberOfUserGroup[7]);
                    end;
                }
                field(Column8; IsMemberOfUserGroup[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[8];
                    ToolTip = 'Specifies if the user is a member of this user group.';
                    Visible = NoOfRecords >= 8;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(8, IsMemberOfUserGroup[8]);
                    end;
                }
                field(Column9; IsMemberOfUserGroup[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[9];
                    ToolTip = 'Specifies if the user is a member of this user group.';
                    Visible = NoOfRecords >= 9;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(9, IsMemberOfUserGroup[9]);
                    end;
                }
                field(Column10; IsMemberOfUserGroup[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserGroupCodeArr[10];
                    ToolTip = 'Specifies if the user is a member of this user group.';
                    Visible = NoOfRecords >= 10;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(10, IsMemberOfUserGroup[10]);
                    end;
                }
            }
        }
        area(factboxes)
        {
            part(Control6; "Permission Sets FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "User Security ID" = FIELD("User Security ID");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(AllColumnsLeft)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'All Columns Left';
                Image = PreviousSet;
                ToolTip = 'Jump to the left-most column.';

                trigger OnAction()
                begin
                    PermissionPagesMgt.AllColumnsLeft();
                end;
            }
            action(ColumnLeft)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Column Left';
                Image = PreviousRecord;
                ToolTip = 'Jump one column to the left.';

                trigger OnAction()
                begin
                    PermissionPagesMgt.ColumnLeft();
                end;
            }
            action(ColumnRight)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Column Right';
                Image = NextRecord;
                ToolTip = 'Jump one column to the right.';

                trigger OnAction()
                begin
                    PermissionPagesMgt.ColumnRight();
                end;
            }
            action(AllColumnsRight)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'All Columns Right';
                Image = NextSet;
                ToolTip = 'Jump to the right-most column.';

                trigger OnAction()
                begin
                    PermissionPagesMgt.AllColumnsRight();
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
                Caption = 'Browse', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(AllColumnsLeft_Promoted; AllColumnsLeft)
                {
                }
                actionref(ColumnLeft_Promoted; ColumnLeft)
                {
                }
                actionref(ColumnRight_Promoted; ColumnRight)
                {
                }
                actionref(AllColumnsRight_Promoted; AllColumnsRight)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        FindUserGroups();
    end;

    trigger OnAfterGetRecord()
    begin
        FindUserGroups();
    end;

    trigger OnInit()
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
    end;

    trigger OnOpenPage()
    var
        UserGroup: Record "User Group";
    begin
        NoOfRecords := UserGroup.Count();
        PermissionPagesMgt.Init(NoOfRecords, ArrayLen(UserGroupCodeArr));
        SelectedCompany := CompanyName;
        HideExternalUsers();
    end;

    var
        Company: Record Company;
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        SelectedCompany: Text[30];
        UserGroupCodeArr: array[10] of Code[20];
        IsMemberOfUserGroup: array[10] of Boolean;
        MemberOfAllGroups: Boolean;
        NoOfRecords: Integer;

    local procedure FindUserGroups()
    var
        UserGroup: Record "User Group";
        i: Integer;
    begin
        Clear(UserGroupCodeArr);
        Clear(IsMemberOfUserGroup);
        MemberOfAllGroups := true;
        if UserGroup.FindSet() then
            repeat
                i += 1;
                if PermissionPagesMgt.IsInColumnsRange(i) then begin
                    UserGroupCodeArr[i - PermissionPagesMgt.GetOffset()] := UserGroup.Code;
                    IsMemberOfUserGroup[i - PermissionPagesMgt.GetOffset()] := UserGroup.IsUserMember(Rec, SelectedCompany);
                    MemberOfAllGroups := MemberOfAllGroups and IsMemberOfUserGroup[i - PermissionPagesMgt.GetOffset()];
                end else
                    if MemberOfAllGroups then
                        MemberOfAllGroups := UserGroup.IsUserMember(Rec, SelectedCompany);
            until (UserGroup.Next() = 0) or (PermissionPagesMgt.IsPastColumnRange(i) and not MemberOfAllGroups);
    end;

    local procedure SetColumnPermission(ColumnNo: Integer; NewUserGroupMembership: Boolean)
    var
        UserGroup: Record "User Group";
    begin
        if ColumnNo > 0 then begin
            UserGroup.Get(UserGroupCodeArr[ColumnNo]);
            UserGroup.SetUserGroupMembership(Rec, NewUserGroupMembership, SelectedCompany);
            MemberOfAllGroups := MemberOfAllGroups and NewUserGroupMembership;
        end else
            if UserGroup.FindSet() then
                repeat
                    UserGroup.SetUserGroupMembership(Rec, NewUserGroupMembership, SelectedCompany);
                until UserGroup.Next() = 0;
    end;

    local procedure HideExternalUsers()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        OriginalFilterGroup: Integer;
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        OriginalFilterGroup := FilterGroup;
        FilterGroup := 2;
        SetFilter("License Type", '<>%1&<>%2', "License Type"::"External User", "License Type"::"AAD Group");
        FilterGroup := OriginalFilterGroup;
    end;
}

#endif