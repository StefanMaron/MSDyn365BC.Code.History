#if not CLEAN20
page 9165 "Support Contact Info Card"
{
    Caption = 'Support Contact Information';
    DataCaptionExpression = '';
    PageType = StandardDialog;
    Permissions = TableData "Support Contact Information" = rimd;
    ObsoleteReason = 'The support contact information is an administrative task, and has been moved to the Admin center.';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            group(Control2)
            {
                InstructionalText = 'This information is shown in the Help & Support page so that users know how to contact the people who are responsible for technical support.';
                ShowCaption = false;
            }
            field(WebsiteInputControl; SupportContactWebsite)
            {
                ApplicationArea = All;
                Caption = 'Support website address';
                Editable = HasWritePermissions;
            }
            field(EmailInputControl; SupportContactEmail)
            {
                ApplicationArea = All;
                Caption = 'Support email address';
                Editable = HasWritePermissions;
            }
            field(PopulateFromAuthControl; PopulateFromAuthText)
            {
                ApplicationArea = All;
                Editable = false;
                ShowCaption = false;
                Visible = PopulateFromAuthVisible;

                trigger OnDrillDown()
                var
                    User: Record User;
                begin
                    if User.ReadPermission then
                        if User.Get(UserSecurityId()) then
                            SupportContactEmail := User."Authentication Email";
                end;
            }
            field(PopulateFromContactControl; PopulateFromContactText)
            {
                ApplicationArea = All;
                Editable = false;
                ShowCaption = false;
                Visible = PopulateFromContactVisible;

                trigger OnDrillDown()
                var
                    User: Record User;
                begin
                    if User.ReadPermission then
                        if User.Get(UserSecurityId()) then
                            SupportContactEmail := User."Contact Email";
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnInit()
    begin
        HasWritePermissions := SupportContactInformation.WritePermission;

        PopulateFields();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::LookupOK, ACTION::OK] then
            SaveSupportContactInformation(SupportContactEmail, SupportContactWebsite);
    end;

    var
        SupportContactInformation: Record "Support Contact Information";
        SupportContactEmail: Text[250];
        PopulateEmailFromAuthLbl: Label 'Use my authentication email (%1)', Comment = '%1 = the email that the user used to log in';
        PopulateEmailFromContactLbl: Label 'Use my contact email (%1)', Comment = '%1 = the email that the user specified as contact email';
        SupportContactWebsite: Text[250];
        HasWritePermissions: Boolean;
        PopulateFromAuthVisible: Boolean;
        PopulateFromAuthText: Text;
        PopulateFromContactVisible: Boolean;
        PopulateFromContactText: Text;

    local procedure PopulateFields()
    var
        User: Record User;
    begin
        if SupportContactInformation.Get() then begin
            SupportContactEmail := SupportContactInformation.Email;
            SupportContactWebsite := SupportContactInformation.URL;
        end else
            if HasWritePermissions then begin
                SupportContactInformation.Init();
                SupportContactInformation.Insert(true);
            end;

        PopulateFromAuthVisible := false;
        PopulateFromContactVisible := false;

        if HasWritePermissions then // Do not show the field if the user will not have permissions anyway
            if User.ReadPermission then
                if User.Get(UserSecurityId()) then begin
                    if User."Authentication Email" <> '' then begin
                        PopulateFromAuthVisible := true;
                        PopulateFromAuthText := StrSubstNo(PopulateEmailFromAuthLbl, User."Authentication Email");
                    end;

                    if User."Contact Email" <> '' then begin
                        PopulateFromContactVisible := true;
                        PopulateFromContactText := StrSubstNo(PopulateEmailFromContactLbl, User."Contact Email");
                    end;
                end;
    end;

    local procedure SaveSupportContactInformation(EmailAddress: Text[250]; Url: Text[250])
    begin
        if not HasWritePermissions then
            exit;

        SupportContactInformation.Validate(Email, EmailAddress);
        SupportContactInformation.Validate(URL, Url);
        SupportContactInformation.Modify(true);
    end;
}
#endif
