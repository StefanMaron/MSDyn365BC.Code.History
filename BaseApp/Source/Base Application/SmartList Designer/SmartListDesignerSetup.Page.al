page 889 "SmartList Designer Setup"
{
    PageType = StandardDialog;
    Caption = 'SmartList Designer Setup';
    ShowFilter = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(Unsupported)
            {
                Caption = 'Unsupported';
                Visible = not IsEnabled;
                InstructionalText = 'The SmartList Designer has been disabled.';
            }

            label(Description)
            {
                ApplicationArea = All;
                Caption = 'With SmartList Designer, you can create new SmartList queries based on Dynamics 365 Business Central data, including data from extension tables. You can create SmartList queries from a single data source or multiple data sources.';
                Visible = IsEnabled;
            }

            label(Explanation)
            {
                ApplicationArea = All;
                Caption = 'To complete the setup, follow the link below to install SmartList Designer from Microsoft AppSource and then copy and paste the SmartList Designer App ID into the field below.';
                Visible = IsEnabled;
            }

            field(AppSourceLink; AppSourceLbl)
            {
                ApplicationArea = All;
                Caption = ' ', Locked = true;
                ShowCaption = false;
                Editable = false;
                ToolTip = 'A link to AppSource where the SmartList Designer can be installed';
                Visible = IsEnabled;

                trigger OnDrillDown()
                begin
                    HyperLink(AppSourceLinkLbl);
                end;
            }

            field(HowToGetIdLink; HowToGetIdLbl)
            {
                ApplicationArea = All;
                Caption = ' ', Locked = true;
                ShowCaption = false;
                Editable = false;
                ToolTip = 'A link to documentation describing how to locate the AppId of a PowerApp';
                Visible = IsEnabled;

                trigger OnDrillDown()
                begin
                    HyperLink(HowToGetIdLinkLbl);
                end;
            }

            part(SetupPart; "SmartList Designer Setup Part")
            {
                ApplicationArea = All;
                Caption = ' ', Locked = true; // Don't want the page part's actual caption to display
                Visible = IsEnabled;
            }
        }
    }

    trigger OnOpenPage()
    var
        SmartListDesigner: Codeunit "SmartList Designer";
    begin
        IsEnabled := SmartListDesigner.IsEnabled();

        if not IsEnabled then
            exit;

        if not SmartListDesigner.DoesUserHaveAPIAccess(UserSecurityId()) then
            Error(UserDoesNotHaveAccessErr);

    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        SetupRec: Record "SmartList Designer Setup";
        TempRec: Record "SmartList Designer Setup" temporary;
        IsNull: Boolean;
    begin
        // Check if the fields in the record are 'null'. This would indicate that
        // the user opened up the page for inital setup and then decided not to enter anything
        CurrPage.SetupPart.Page.GetRecord(TempRec);
        IsNull := IsNullGuid(TempRec.PowerAppId) or IsNullGuid(TempRec.PowerAppTenantId);

        // Consider the dialog cancelled if
        // A) The user selects 'cancel'
        // B) The user did not enter in initial values
        Cancelled := (CloseAction <> Action::OK) or IsNull;

        // If not cancelled, then update the actual record
        if not Cancelled then
            if SetupRec.Get() then begin
                SetupRec.Copy(TempRec);
                SetupRec.Modify();
            end else begin
                SetupRec.Copy(TempRec);
                SetupRec.Insert();
            end;
    end;

    procedure WasCancelled(): Boolean
    begin
        exit(Cancelled);
    end;

    var
        Cancelled: Boolean;
        IsEnabled: Boolean;
        UserDoesNotHaveAccessErr: Label 'You do not have permission to access the SmartList Designer. Contact your system administrator.';
        AppSourceLbl: Label 'Install the SmartList Designer from AppSource';
        AppSourceLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2123766', Locked = true;
        HowToGetIdLbl: Label 'How to find the SmartList Designer App Id';
        HowToGetIdLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2124500', Locked = true;
}