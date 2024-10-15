page 9852 "Effective Permissions"
{
    ApplicationArea = All;
    Caption = 'Effective Permissions';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = Permission;
    SourceTableTemporary = true;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ChooseUser; ChosenUserName)
                {
                    ApplicationArea = All;
                    Caption = 'User';
                    ToolTip = 'Specifies the user that the effective permissions apply to.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ChosenUser: Record User;
                        User: Record User;
                        Users: Page Users;
                    begin
                        User.SetFilter("License Type", '<>%1', User."License Type"::"External User");
                        Users.SetTableView(User);
                        ChosenUser.SetRange("User Name", Text);
                        if ChosenUser.FindFirst then
                            Users.SetRecord(ChosenUser);
                        Users.LookupMode(true);
                        if Users.RunModal = ACTION::LookupOK then begin
                            Users.GetRecord(User);

                            if Text <> User."User Name" then begin
                                Text := User."User Name";
                                ChosenUserName := Text;
                                CurrentUserID := User."User Security ID";
                                FillByObject;
                            end;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        User: Record User;
                    begin
                        User.SetRange("User Name", ChosenUserName);
                        User.FindFirst;
                        CurrentUserID := User."User Security ID";
                        FillByObject;
                    end;
                }
                field(ChooseCompany; CurrentCompanyName)
                {
                    ApplicationArea = All;
                    Caption = 'Company';
                    ToolTip = 'Specifies the company for which effective permissions for the chosen user will be shown.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Company: Record Company;
                        Companies: Page Companies;
                    begin
                        if Company.Get(CurrentCompanyName) then
                            Companies.SetRecord(Company);
                        Companies.LookupMode(true);
                        if Companies.RunModal = ACTION::LookupOK then begin
                            Companies.GetRecord(Company);

                            if Text <> Company.Name then begin
                                Text := Company.Name;
                                CurrentCompanyName := Text;
                                FillByObject;
                            end;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        Company: Record Company;
                    begin
                        Company.Get(CurrentCompanyName);
                        FillByObject;
                    end;
                }
                field(ShowAllObjects; ShowAllObjects)
                {
                    ApplicationArea = All;
                    Caption = 'Show All Objects';
                    ToolTip = 'Specifies if the effective permissions are shown for all objects or only for objects in the user''s assigned permission sets.';

                    trigger OnValidate()
                    begin
                        CurrentObjectId := 0;
                        FillByObject;
                    end;
                }
            }
            group(Permissions)
            {
                Caption = 'Permissions';
                repeater(EffectivePermissions)
                {
                    field("Object Type"; "Object Type")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the type of object that the permissions apply to in the current database.';
                    }
                    field("Object ID"; "Object ID")
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ToolTip = 'Specifies the ID of the object to which the permissions apply.';
                        Visible = false;
                    }
                    field("Object Name"; "Object Name")
                    {
                        ApplicationArea = All;
                        Caption = 'Object Name';
                        Editable = false;
                    }
                    field("Read Permission"; "Read Permission")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies information about whether the permission set has read permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have read permission.';
                    }
                    field("Insert Permission"; "Insert Permission")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies information about whether the permission set has insert permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have insert permission.';
                    }
                    field("Modify Permission"; "Modify Permission")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies information about whether the permission set has modify permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have modify permission.';
                    }
                    field("Delete Permission"; "Delete Permission")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies information about whether the permission set has delete permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have delete permission.';
                    }
                    field("Execute Permission"; "Execute Permission")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies information about whether the permission set has execute permission to this object. The values for the field are blank, Yes, and Indirect. Indirect means permission only through another object. If the field is empty, the permission set does not have execute permission.';
                    }
                    field(ContainedInCustomPermissionSet; ContainedInCustomPermissionSet)
                    {
                        ApplicationArea = All;
                        Caption = 'In User-Defined Permission Set';
                        Editable = false;
                        ToolTip = 'Specifies if the object is included in a User-Defined permission set.';
                    }
                }
            }
            part(ByPermissionSet; "Effective Permissions By Set")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Permission Sets")
            {
                ApplicationArea = All;
                Caption = 'Permission Sets';
                Image = Permission;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Permission Sets";
                ToolTip = 'View or edit which feature objects that users need to access and set up the related permissions in permission sets that you can assign to the users of the database.';
            }
            action("Permission Set by User")
            {
                ApplicationArea = All;
                Caption = 'Permission Set by User';
                Image = Permission;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Permission Set by User";
                ToolTip = 'View or edit the available permission sets and apply permission sets to existing users.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
    begin
        // Refresh
        if "Object ID" <> 0 then begin // handle case when there are no records at all
            EffectivePermissionsMgt.PopulatePermissionRecordWithEffectivePermissionsForObject(Rec, CurrentUserID, CurrentCompanyName,
              "Object Type", "Object ID");
            Modify;
        end;

        CurrPage.ByPermissionSet.PAGE.SetRecordAndRefresh(CurrentUserID, CurrentCompanyName, "Object Type", "Object ID");
    end;

    trigger OnAfterGetRecord()
    var
        TenantPermission: Record "Tenant Permission";
        ZeroGuid: Guid;
    begin
        if "Object ID" = 0 then
            exit;
        TenantPermission.SetRange("App ID", ZeroGuid); // does not come from an extension
        TenantPermission.SetRange("Object Type", "Object Type");
        TenantPermission.SetRange("Object ID", "Object ID");
        ContainedInCustomPermissionSet := not TenantPermission.IsEmpty;
    end;

    trigger OnInit()
    begin
        CurrentUserID := UserSecurityId;
        ChosenUserName := UserId;
        CurrentCompanyName := CompanyName;
    end;

    trigger OnOpenPage()
    begin
        FillByObject;
    end;

    var
        CurrentUserID: Guid;
        CurrentObjectType: Option;
        CurrentObjectId: Integer;
        CurrentCompanyName: Text[30];
        ChosenUserName: Code[50];
        LastUsedUserID: Guid;
        LastUsedCompanyName: Text[30];
        LastUsedObjectType: Option;
        LastUsedObjectId: Integer;
        LastUsedShowAllObjects: Boolean;
        ShowAllObjects: Boolean;
        ContainedInCustomPermissionSet: Boolean;
        OnlyAadUsersAllowedErr: Label 'The effective permissions content can be shown only for Azure AAD users.';

    local procedure FillByObject()
    var
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
        UserProperty: Record "User Property";
    begin
        if (LastUsedUserID = CurrentUserID) and
           (LastUsedCompanyName = CurrentCompanyName) and
           (LastUsedObjectType = CurrentObjectType) and
           (LastUsedObjectId = CurrentObjectId) and
           (LastUsedShowAllObjects = ShowAllObjects)
        then
            exit;

        if EnvironmentInfo.IsSaaS() then
            if (not UserProperty.Get(CurrentUserID)) or (UserProperty."Authentication Object ID" = '') then
                Error(OnlyAadUsersAllowedErr);

        EffectivePermissionsMgt.PopulateEffectivePermissionsBuffer(Rec,
          CurrentUserID, CurrentCompanyName, CurrentObjectType, CurrentObjectId, ShowAllObjects);
        CurrPage.Update(false);

        LastUsedUserID := CurrentUserID;
        LastUsedCompanyName := CurrentCompanyName;
        LastUsedObjectType := CurrentObjectType;
        LastUsedObjectId := CurrentObjectId;
        LastUsedShowAllObjects := ShowAllObjects;
        OnEffectivePermissionsPopulated(CurrentUserID, CurrentCompanyName, CurrentObjectType, CurrentObjectId);
    end;

    procedure SetUserSID(UserSID: Guid)
    var
        User: Record User;
    begin
        User.Get(UserSID);
        CurrentUserID := UserSID;
        ChosenUserName := User."User Name";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEffectivePermissionsPopulated(CurrUserId: Guid; CurrCompanyName: Text[30]; CurrObjectType: Integer; CurrObjectId: Integer)
    begin
    end;
}

