table 9012 "AAD Application"
{
    Caption = 'AAD Application';
    DataPerCompany = false;
    ReplicateData = false;
    DataCaptionFields = Description;

    fields
    {
        field(1; "Client Id"; Guid)
        {
            Caption = 'Client Id';
        }
        field(2; State; Option)
        {
            Caption = 'State';
            OptionCaption = 'Enabled,Disabled';
            OptionMembers = Enabled,Disabled;
            trigger OnValidate()
            var
                User: Record User;
            begin
                if xRec.State = state then
                    exit;
                If not UserExists() then
                    CreateUserFromAADApplication();
                User.Get("User Id");
                if State = State::Enabled then
                    User.State := User.State::Enabled
                else
                    User.State := User.State::Disabled;
                User.Modify()
            end;
        }
        field(5; "App ID"; Guid)
        {
            Caption = 'App ID';
            trigger OnLookup()
            var
                PublishedApplication: Record "Published Application";
            begin
                if PAGE.RunModal(PAGE::"Extension Management", PublishedApplication) = ACTION::LookupOK then begin
                    "App ID" := PublishedApplication."Package ID";
                    "App Name" := PublishedApplication.Name;
                    exit
                end;
            end;

            trigger OnValidate()
            begin
                if IsNullGuid("App ID") then
                    "App Name" := '';
            end;

        }
        field(6; "App Name"; Text[250])
        {
            Caption = 'App Name';
            Editable = false;
        }
        field(10; Description; Text[50])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                if (xRec.Description = '') and (Description <> '') then
                    CreateUserFromAADApplication();
            end;
        }
        field(11; "Contact Information"; Text[50])
        {
            Caption = 'Contact Information';
        }
        field(12; "Permission Granted"; Boolean)
        {
            Caption = 'Permission Granted';
        }
        field(20; "User ID"; Guid)
        {
            Caption = 'User Id';
        }

    }

    keys
    {
        key(Key1; "Client Id")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure CreateUserFromAADApplication()
    var
        User: Record User;
        NavUserAccountHelper: DotNet NavUserAccountHelper;
        ErrText: Text;
    begin
        if UserExists() then begin
            User.Get("User Id");
            User.State := User.State::Enabled;
            User.Modify();
        end;

        User.SetRange("License Type", User."License Type"::"Full User");
        User.SetRange(State, User.State::Enabled);
        if User.IsEmpty then begin
            ErrText := StrSubstNo(UserMustExistErr, Rec.TableCaption);
            Error(ErrText);
        end;

        "User Id" := NavUserAccountHelper.CreateApplicationRegistration(Description, "Client Id");
        Modify();
    end;


    [Scope('OnPrem')]
    procedure UserExists(): Boolean;
    var
        User: Record User;
    begin
        User.SetRange("User Security ID", "User ID");
        exit(not User.IsEmpty());
    end;


    [Scope('OnPrem')]
    procedure DisableUser()
    var
        User: Record User;
    begin
        If not UserExists() then
            exit;
        User.Get("User Id");
        User.State := User.State::Disabled;
        User.Modify();
    end;

    trigger OnInsert()
    begin
        TestField("Client Id");
    end;

    trigger OnDelete()
    begin
        DisableUser();
    end;

    trigger OnRename()
    begin
        Error(CannotRenameErr, TableCaption);
    end;

    var
        CannotRenameErr: Label 'You cannot rename a %1.', Comment = '%1 Table name';
        UserMustExistErr: Label 'Register an user before enabling the %1', Comment = '%1 Table AAD Application';
}


