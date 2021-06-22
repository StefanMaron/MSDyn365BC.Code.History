page 9812 "Set Web Service Access Key"
{
    Caption = 'Set Web Service Access Key';
    DataCaptionExpression = "Full Name";
    InstructionalText = 'Set Web Service Access Key';
    PageType = StandardDialog;
    SourceTable = User;

    layout
    {
        area(content)
        {
            group(somegroup)
            {
                Caption = 'Setting a new Web Service key makes the old key not valid.';
            }
            field(NeverExpires; NeverExpires)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Key Never Expires';
                ToolTip = 'Specifies that the web service access key cannot expire.';
            }
            field(ExpirationDate; ExpirationDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Key Expiration Date';
                Editable = NOT NeverExpires;
                ToolTip = 'Specifies when the web service access key expires.';
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        UserPermissions: Codeunit "User Permissions";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if ("User Security ID" <> UserSecurityId()) and EnvironmentInfo.IsSaaS() then
            if not UserPermissions.CanManageUsersOnTenant(UserSecurityID()) then
                error(CannotEditForOtherUsersErr);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::OK then begin
            if NeverExpires then
                IdentityManagement.CreateWebServicesKeyNoExpiry("User Security ID")
            else
                IdentityManagement.CreateWebServicesKey("User Security ID", ExpirationDate);
        end;
    end;

    var
        IdentityManagement: Codeunit "Identity Management";
        ExpirationDate: DateTime;
        NeverExpires: Boolean;
        CannotEditForOtherUsersErr: Label 'You can only change your own web service access keys.';
}

