codeunit 9000 "Users - Create Super User"
{

    trigger OnRun()
    var
        User: Record User;
    begin
        if not User.IsEmpty() then
            exit;

        SafeCreateUser(UserId, Sid());
    end;

    [Scope('OnPrem')]
    procedure SafeCreateUser(UserID: Code[50]; SID: Text[119])
    var
        User: Record User;
        PermissionSet: Record "Permission Set";
    begin
        User.SetRange("User Name", UserID);
        if User.FindFirst() then
            exit;

        GetSuperRole(PermissionSet);
        CreateUser(User, UserID, SID);
        AssignPermissionSetToUser(User, PermissionSet);
    end;

    local procedure GetSuperRole(var PermissionSet: Record "Permission Set")
    begin
        PermissionSet.Get('SUPER');
    end;

    local procedure CreateUser(var User: Record User; UserName: Code[50]; WindowsSecurityID: Text[119])
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := UserName;
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            User."Windows Security ID" := WindowsSecurityID;
        User.Insert(true);
    end;

    local procedure AssignPermissionSetToUser(var User: Record User; var PermissionSet: Record "Permission Set")
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", User."User Security ID");
        AccessControl.SetRange("Role ID", PermissionSet."Role ID");
        if not AccessControl.IsEmpty() then
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

