page 9178 "Available Roles"
{
    Caption = 'Available Roles';
    Editable = false;
    LinksAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    PageType = List;
    SourceTable = "All Profile";
    SourceTableView = where(Enabled = const(true));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(CaptionField; Caption)
                {
                    Caption = 'Display Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the organizational role.';
                }
                field(AppNameField; "App Name")
                {
                    Caption = 'Source';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the origin of this role, which can be either an extension, shown by its name, or a custom profile created by a user.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        EmptyGuid: Guid;
    begin
        // Solves the case where the profile is user-created; not using a local variable allows to keep the sorting capabilities
        if "App ID" = EmptyGuid then
            "App Name" := ConfPersonalizationMgt.ResolveAppNameFromAppId("App ID");
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        EmptyGuid: Guid;
    begin
        // Since this value is set in OnAfterGetRecord, sorting by this field causes confusion in server that looks for the next record with a wrong string 
        if "App ID" = EmptyGuid then
            "App Name" := '';
        exit(Next(Steps));
    end;

    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";

}

