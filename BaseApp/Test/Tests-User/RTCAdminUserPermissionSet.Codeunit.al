codeunit 132901 RTCAdmin_User_PermissionSet
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [User] [Windows User Name] [UI]
    end;

    var
        ErrorStringCom001: Label 'Missing Expected error message: %1. \ Actual error received: %2.';
        UserIsNotValidWinAccountTxt: Label 'The account  is not a valid Windows account.';
        NotSupportedOS001: Label 'OS number %1 is not handled in the test.';
        UserInvalid001: Label 'JANE\Doe';
        User002: Label 'USER001';
        UserEveryoneIsNotAllowedTxt: Label 'The account Everyone is not allowed.';
        UserAnonymousIsNotAllowedTxt: Label 'The account Anonymous is not allowed.';
        UserAdministratorsIsNotAllowedTxt: Label 'The account BUILTIN\Administrators is not allowed.';

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RTCAdmin_AddAnonymousTest()
    var
        UserCard: TestPage "User Card";
        Version: Text;
        ExpectedError: Text;
        ValidationError: Text;
    begin
        Version := GetOsVersion;
        case Version of
            '6.0':
                ExpectedError := UserAnonymousIsNotAllowedTxt;
            '6.1', '6.2', '10.0':
                ExpectedError := UserIsNotValidWinAccountTxt;
            else
                Error(NotSupportedOS001, Version);
        end;

        UserCard.OpenNew();
        asserterror UserCard."Windows User Name".Value := 'Anonymous';
        ValidationError := UserCard.GetValidationError;
        if ValidationError <> ExpectedError then begin
            UserCard.Close();
            Error(ErrorStringCom001, ExpectedError, ValidationError);
        end;

        UserCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RTCAdmin_AddEveryoneTest()
    var
        UserCard: TestPage "User Card";
        ValidationError: Text;
    begin
        UserCard.OpenNew();
        asserterror UserCard."Windows User Name".Value := 'Everyone';
        if UserCard.GetValidationError <> UserEveryoneIsNotAllowedTxt then begin
            ValidationError := UserCard.GetValidationError;
            UserCard.Close();
            Error(ErrorStringCom001, UserEveryoneIsNotAllowedTxt, ValidationError);
        end;

        UserCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RTCAdmin_AddAdministratorsTest()
    var
        UserCard: TestPage "User Card";
        ValidationError: Text;
    begin
        UserCard.OpenNew();
        asserterror UserCard."Windows User Name".Value := 'Administrators';
        if UserCard.GetValidationError <> UserAdministratorsIsNotAllowedTxt then begin
            ValidationError := UserCard.GetValidationError;
            UserCard.Close();
            Error(ErrorStringCom001, UserAdministratorsIsNotAllowedTxt, ValidationError);
        end;

        UserCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RTCAdmin_CheckUserDoNotExist()
    var
        UserCard: TestPage "User Card";
        ValidationError: Text;
    begin
        AddUserHelper(User002);
        UserCard.OpenNew();
        asserterror UserCard."Windows User Name".Value := UserInvalid001;
        if UserCard.GetValidationError <> UserIsNotValidWinAccountTxt then begin
            ValidationError := UserCard.GetValidationError;
            UserCard.Close();
            Error(ErrorStringCom001, UserIsNotValidWinAccountTxt, ValidationError);
        end;
        UserCard.Close();
    end;

    [Normal]
    local procedure AddUserHelper(UserName: Code[50])
    var
        UserCard: TestPage "User Card";
    begin
        UserCard.OpenNew();
        UserCard."User Name".Value := UserName;
        UserCard.Close();
    end;

    [Normal]
    local procedure GetOsVersion() ClientOsversion: Text
    var
        OS: DotNet Environment;
        NavOsMinorNo: Integer;
        NavOsMajorNo: Integer;
    begin
        NavOsMajorNo := OS.OSVersion.Version.Major;
        NavOsMinorNo := OS.OSVersion.Version.Minor;
        ClientOsversion := Format(NavOsMajorNo) + '.' + Format(NavOsMinorNo);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

