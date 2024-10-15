#if not CLEAN22
namespace System.Security.AccessControl;

report 9001 "Copy User Group"
{
    Caption = 'Copy User Group';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] Replaced by the Copy Security Group page in the security groups system and Copy Permission Set report in the permission sets system. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';


    dataset
    {
        dataitem("User Group"; "User Group")
        {
            DataItemTableView = sorting(Code);

            trigger OnAfterGetRecord()
            var
                NewUserGroup: Record "User Group";
                UserGroupPermissionSet: Record "User Group Permission Set";
                NewUserGroupPermissionSet: Record "User Group Permission Set";
            begin
                NewUserGroup.Init();
                NewUserGroup.Code := NewUserGroupCode;
                NewUserGroup.Name := Name;
                NewUserGroup.Insert(true);
                UserGroupPermissionSet.SetRange("User Group Code", Code);
                if UserGroupPermissionSet.FindSet() then
                    repeat
                        NewUserGroupPermissionSet := UserGroupPermissionSet;
                        NewUserGroupPermissionSet."User Group Code" := NewUserGroup.Code;
                        NewUserGroupPermissionSet.Insert();
                    until UserGroupPermissionSet.Next() = 0;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewUserGroupCode; NewUserGroupCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New User Group Code';
                        NotBlank = true;
                        ToolTip = 'Specifies the code of the user group that result from the copying.';
                    }
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

    var
        NewUserGroupCode: Code[20];
}

#endif