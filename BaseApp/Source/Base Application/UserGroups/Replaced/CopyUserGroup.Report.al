#if not CLEAN22
report 9001 "Copy User Group"
{
    Caption = 'Copy User Group';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the Copy Security Group page in the security groups system.';
    ObsoleteTag = '22.0';


    dataset
    {
        dataitem("User Group"; "User Group")
        {
            DataItemTableView = SORTING(Code);

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