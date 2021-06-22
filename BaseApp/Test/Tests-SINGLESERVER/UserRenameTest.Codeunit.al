codeunit 132904 UserRenameTest
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [User] [UI] [Permissions]
    end;

    var
        Assert: Codeunit Assert;
        Text001: Label 'Rolling back changes...';
        ChangeByPage: Option Card,List;
        OldUserNameExist: Label 'Old user name still exists for table %1, field %2.';
        NewUserNameNotFound: Label 'New user name is not found for table %1, field %2.';
        IsInitialized: Boolean;
        UserName: array[2] of Text;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure RenameUserTest_Card()
    var
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        RenameUser(ChangeByPage::Card);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure RenameUserTest_List()
    var
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize;
        BindSubscription(LibraryJobQueue);
        RenameUser(ChangeByPage::List);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        InitializeTestUsers;

        IsInitialized := true;
    end;

    local procedure InitializeTestUsers()
    var
        IdentityManagement: Codeunit "Identity Management";
        PrincipalContext: DotNet "System.DirectoryServices.AccountManagement.PrincipalContext";
        ContextType: DotNet "System.DirectoryServices.AccountManagement.ContextType";
        GroupPrincipal: DotNet "System.DirectoryServices.AccountManagement.GroupPrincipal";
        IdentityType: DotNet "System.DirectoryServices.AccountManagement.IdentityType";
        Principal: DotNet "System.DirectoryServices.AccountManagement.Principal";
        Counter: Integer;
        TypeName: Text;
    begin
        Counter := ArrayLen(UserName);
        PrincipalContext := PrincipalContext.PrincipalContext(ContextType.Domain);
        GroupPrincipal := GroupPrincipal.FindByIdentity(PrincipalContext, IdentityType.SamAccountName, 'Domain Users');
        foreach Principal in GroupPrincipal.GetMembers(false) do begin
            TypeName := Principal.GetType.ToString;
            if TypeName = 'System.DirectoryServices.AccountManagement.UserPrincipal' then begin
                UserName[Counter] := UpperCase(IdentityManagement.UserName(Sid(Principal.UserPrincipalName)));
                Counter -= 1;
            end;
            if Counter = 0 then
                exit;
        end;
    end;

    local procedure AddUserHelper(NewUserName: Text)
    var
        UserCardPage: TestPage "User Card";
    begin
        UserCardPage.OpenNew;
        UserCardPage."User Name".Value := NewUserName;
        UserCardPage.Close;
    end;

    local procedure RenameUser(ChangeBy: Integer)
    begin
        // SETUP
        AddUserHelper(GetShortName(UserName[1]));
        CreateUserRelatedRecords(GetShortName(UserName[1]));

        // EXECUTE
        RenameUserHelper(ChangeBy, GetShortName(UserName[1]), GetShortName(UserName[2]));

        // VERIFY
        VerifyUserRelatedRecords(GetShortName(UserName[1]), GetShortName(UserName[2]));

        TearDown;
    end;

    local procedure CreateUserRelatedRecords(GivenUserName: Text)
    var
        User: Record User;
        "Field": Record "Field";
        TempInteger: Record "Integer" temporary;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        FindRelatedTableIDs(TempInteger);

        Field.SetRange(RelationTableNo, DATABASE::User);
        Field.SetRange(RelationFieldNo, User.FieldNo("User Name"));
        Field.SetFilter(Type, '%1|%2', Field.Type::Code, Field.Type::Text);
        if TempInteger.FindSet then
            repeat
                RecRef.Open(TempInteger.Number);
                RecRef.Init;
                Field.SetRange(TableNo, TempInteger.Number);
                if Field.FindSet then
                    repeat
                        FieldRef := RecRef.Field(Field."No.");
                        FieldRef.Value := CopyStr(GivenUserName, 1, Field.Len);
                    until Field.Next = 0;
                RecRef.Insert;
                RecRef.Close;
            until TempInteger.Next = 0;
    end;

    local procedure FindRelatedTableIDs(var TempInteger: Record "Integer")
    var
        User: Record User;
        "Field": Record "Field";
    begin
        Field.SetRange(RelationTableNo, DATABASE::User);
        Field.SetRange(RelationFieldNo, User.FieldNo("User Name"));
        if Field.FindSet then
            repeat
                if not TempInteger.Get(Field.TableNo) then begin
                    TempInteger.Number := Field.TableNo;
                    TempInteger.Insert;
                end;
            until Field.Next = 0;
    end;

    local procedure GetShortName(UserName: Text): Text
    begin
        exit(CopyStr(UserName, StrPos(UserName, '\') + 1));
    end;

    local procedure RenameUserHelper(ChangeBy: Integer; OldName: Text; NewName: Text)
    begin
        case ChangeBy of
            ChangeByPage::Card:
                RenameUserHelper_Card(OldName, NewName);
            ChangeByPage::List:
                RenameUserHelper_List(OldName, NewName);
        end;
    end;

    local procedure RenameUserHelper_Card(OldUserName: Text; NewUserName: Text)
    var
        UserCardPage: TestPage "User Card";
    begin
        UserCardPage.OpenEdit;
        UserCardPage.FILTER.SetFilter("User Name", OldUserName);
        UserCardPage."User Name".Value := NewUserName;
        UserCardPage.Close;
    end;

    local procedure RenameUserHelper_List(OldUserName: Text; NewUserName: Text)
    var
        UsersPage: TestPage Users;
    begin
        UsersPage.OpenEdit;
        UsersPage.FILTER.SetFilter("User Name", OldUserName);
        UsersPage."User Name".Value := NewUserName;
        UsersPage.Close;
    end;

    local procedure VerifyUserRelatedRecords(OldUserName: Text; NewUserName: Text)
    var
        User: Record User;
        "Field": Record "Field";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        Field.SetRange(RelationTableNo, DATABASE::User);
        Field.SetRange(RelationFieldNo, User.FieldNo("User Name"));
        Field.SetFilter(Type, '%1|%2', Field.Type::Code, Field.Type::Text);
        if Field.FindSet then
            repeat
                RecRef.Open(Field.TableNo);
                FieldRef := RecRef.Field(Field."No.");
                FieldRef.SetRange(CopyStr(OldUserName, 1, Field.Len));
                Assert.IsFalse(RecRef.FindFirst, StrSubstNo(OldUserNameExist, Field.TableName, Field.FieldName));
                if Field.Len < StrLen(NewUserName) then
                    FieldRef.SetRange(CopyStr(NewUserName, 1, Field.Len))
                else
                    FieldRef.SetRange(NewUserName);

                Assert.IsTrue(RecRef.FindFirst, StrSubstNo(NewUserNameNotFound, Field.TableName, Field.FieldName));
                RecRef.Close;
            until Field.Next = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Msg: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure TearDown()
    begin
        asserterror Error(Text001);
    end;
}

