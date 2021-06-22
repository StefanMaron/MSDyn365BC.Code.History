page 9801 "User Subform"
{
    Caption = 'User Permission Sets';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Access Control";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'User Permissions';
                field(PermissionSet; "Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    ToolTip = 'Specifies the ID of a security role that has been assigned to this Windows login in the current database.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PermissionSetLookupRecord: Record "Aggregate Permission Set";
                        PermissionSetLookup: Page "Permission Set Lookup";
                    begin
                        PermissionSetLookup.LookupMode := true;
                        if PermissionSetLookup.RunModal = ACTION::LookupOK then begin
                            PermissionSetLookup.GetRecord(PermissionSetLookupRecord);
                            Scope := PermissionSetLookupRecord.Scope;
                            "App ID" := PermissionSetLookupRecord."App ID";
                            "Role ID" := PermissionSetLookupRecord."Role ID";
                            CalcFields("App Name", "Role Name");
                            SkipValidation := true;
                            PermissionScope := Format(PermissionSetLookupRecord.Scope);
                        end;
                    end;

                    trigger OnValidate()
                    var
                        AggregatePermissionSet: Record "Aggregate Permission Set";
                    begin
                        // If the user used the lookup, skip validation
                        if SkipValidation then begin
                            SkipValidation := false;
                            exit;
                        end;

                        // Get the Scope and App ID for a matching Role ID
                        AggregatePermissionSet.SetRange("Role ID", "Role ID");
                        AggregatePermissionSet.FindFirst;

                        if AggregatePermissionSet.Count > 1 then
                            Error(MultipleRoleIDErr, "Role ID");

                        Scope := AggregatePermissionSet.Scope;
                        "App ID" := AggregatePermissionSet."App ID";
                        PermissionScope := Format(AggregatePermissionSet.Scope);

                        CalcFields("App Name", "Role Name");

                        SkipValidation := false; // re-enable validation
                    end;
                }
                field(Description; "Role Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the security role that has been given to this Windows login in the current database.';
                }
                field(Company; "Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company';
                    ToolTip = 'Specifies the name of the company that this role is limited to for this Windows login.';
                }
                field(ExtensionName; "App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the extension.';
                }
                field(PermissionScope; PermissionScope)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Scope';
                    Editable = false;
                    ToolTip = 'Specifies the scope of the permission set.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Permissions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Permissions';
                Image = Permission;
                ToolTip = 'View or edit which feature objects that users need to access and set up the related permissions in permission sets that you can assign to the users of the database.';

                trigger OnAction()
                var
                    PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
                begin
                    PermissionPagesMgt.ShowPermissions(Scope, "App ID", "Role ID", false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if User."User Name" <> '' then
            CurrPage.Caption := User."User Name";

        PermissionScope := Format(Scope);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        UserGroupAccessControl: Record "User Group Access Control";
    begin
        UserGroupAccessControl.SetFilter("User Group Code", '<>%1', '');
        UserGroupAccessControl.SetRange("User Security ID", "User Security ID");
        UserGroupAccessControl.SetRange("Role ID", "Role ID");
        UserGroupAccessControl.SetRange("Company Name", "Company Name");
        if UserGroupAccessControl.FindFirst then
            Error(InUserGroupErr, UserGroupAccessControl."User Group Code");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        User.TestField("User Name");
        CalcFields("App Name", "Role Name");
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CalcFields("App Name", "Role Name");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if User.Get("User Security ID") then;
        CalcFields("App Name", "Role Name");
        PermissionScope := '';
    end;

    var
        User: Record User;
        InUserGroupErr: Label 'You cannot remove this permission set because it is included in user group %1.', Comment = '%1=a user group code, e.g. ADMIN or SALESDEPT';
        MultipleRoleIDErr: Label 'The permission set %1 is defined multiple times in this context. Use the lookup button to select the relevant permission set.', Comment = '%1 will be replaced with a Role ID code value from the Permission Set table';
        SkipValidation: Boolean;
        PermissionScope: Text;
}

