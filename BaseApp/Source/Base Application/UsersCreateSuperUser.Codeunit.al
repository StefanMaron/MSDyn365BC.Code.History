codeunit 9000 "Users - Create Super User"
{

    trigger OnRun()
    var
        User: Record User;
    begin
        if not User.IsEmpty then
            exit;

        SafeCreateUser(UserId, Sid);
    end;

    var
        SuperPermissonSetDescTxt: Label 'This user has all permissions.';

    [Scope('OnPrem')]
    procedure SafeCreateUser(UserID: Code[50]; SID: Text[119])
    var
        User: Record User;
        PermissionSet: Record "Permission Set";
    begin
        User.SetRange("User Name", UserID);
        if User.FindFirst then
            exit;

        GetSuperRole(PermissionSet);
        CreateUser(User, UserID, SID);
        AssignPermissionSetToUser(User, PermissionSet);
    end;

    local procedure GetSuperRole(var PermissionSet: Record "Permission Set")
    var
        Permission: Record Permission;
    begin
        if PermissionSet.Get('SUPER') then
            exit;
        PermissionSet."Role ID" := 'SUPER';
        PermissionSet.Name := CopyStr(SuperPermissonSetDescTxt, 1, MaxStrLen(PermissionSet.Name));
        PermissionSet.Insert(true);
        AddPermissionToPermissionSet(PermissionSet, Permission."Object Type"::"Table Data", 0);
        AddPermissionToPermissionSet(PermissionSet, Permission."Object Type"::Table, 0);
        AddPermissionToPermissionSet(PermissionSet, Permission."Object Type"::Report, 0);
        AddPermissionToPermissionSet(PermissionSet, Permission."Object Type"::Codeunit, 0);
        AddPermissionToPermissionSet(PermissionSet, Permission."Object Type"::XMLport, 0);
        AddPermissionToPermissionSet(PermissionSet, Permission."Object Type"::MenuSuite, 0);
        AddPermissionToPermissionSet(PermissionSet, Permission."Object Type"::Page, 0);
        AddPermissionToPermissionSet(PermissionSet, Permission."Object Type"::Query, 0);
        AddPermissionToPermissionSet(PermissionSet, Permission."Object Type"::System, 0);
    end;

    local procedure CreateUser(var User: Record User; UserName: Code[50]; WindowsSecurityID: Text[119])
    begin
        User.Init();
        User."User Security ID" := CreateGuid;
        User."User Name" := UserName;
        User."Windows Security ID" := WindowsSecurityID;
        User.Insert(true);
    end;

    local procedure AddPermissionToPermissionSet(var PermissionSet: Record "Permission Set"; ObjectType: Option; ObjectID: Integer)
    var
        Permission: Record Permission;
    begin
        with Permission do begin
            Init;
            "Role ID" := PermissionSet."Role ID";
            "Object Type" := ObjectType;
            "Object ID" := ObjectID;
            if "Object Type" = "Object Type"::"Table Data" then
                "Execute Permission" := "Execute Permission"::" "
            else begin
                "Read Permission" := "Read Permission"::" ";
                "Insert Permission" := "Insert Permission"::" ";
                "Modify Permission" := "Modify Permission"::" ";
                "Delete Permission" := "Delete Permission"::" ";
            end;
            Insert(true);
        end;
    end;

    local procedure AssignPermissionSetToUser(var User: Record User; var PermissionSet: Record "Permission Set")
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", User."User Security ID");
        AccessControl.SetRange("Role ID", PermissionSet."Role ID");
        if not AccessControl.IsEmpty then
            exit;
        AccessControl."User Security ID" := User."User Security ID";
        AccessControl."Role ID" := PermissionSet."Role ID";
        AccessControl.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure AddUserAsSuper(var User: Record User)
    var
        PermissionSet: Record "Permission Set";
    begin
        GetSuperRole(PermissionSet);
        AssignPermissionSetToUser(User, PermissionSet);
    end;
}

