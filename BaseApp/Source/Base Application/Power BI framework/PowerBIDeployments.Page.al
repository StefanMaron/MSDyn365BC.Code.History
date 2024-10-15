page 6321 "Power BI Deployments"
{
    // // Page for letting the user delete their uploaded OOB PBI reports.

    Caption = 'Power BI Deployments';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Power BI Customer Reports";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control3)
            {
                ShowCaption = false;
                field(SelectedUser; SelectedUser)
                {
                    ApplicationArea = All;
                    Caption = 'User';
                    Editable = false;
                    Enabled = IsUserPBIAdmin;

                    trigger OnAssistEdit()
                    var
                        User: Record User;
                        Users: Page Users;
                    begin
                        // Handles clicking the ellipsis button next to the user field.
                        Users.SetRecord(User);
                        Users.LookupMode(true);
                        if Users.RunModal in [ACTION::OK, ACTION::LookupOK] then begin
                            Users.GetRecord(User);
                            SelectedUser := User."User Name";
                            SelectedUserSecurityId := User."User Security ID";
                            LoadReports();
                        end;
                    end;

                    trigger OnValidate()
                    var
                        User: Record User;
                    begin
                        // Handles typing a value into the user field.
                        User.Reset();
                        User.SetFilter("User Name", SelectedUser);
                        if User.FindFirst() then begin
                            SelectedUser := User."User Name";
                            SelectedUserSecurityId := User."User Security ID";
                        end else
                            Clear(SelectedUserSecurityId);

                        LoadReports();
                    end;
                }
            }
            repeater("Default Reports")
            {
                Caption = 'Default Reports';
                field(ReportName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'Report Name';
                    Editable = false;
                }
                field(ReportID; Id)
                {
                    ApplicationArea = All;
                    Caption = 'Report ID';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Delete)
            {
                ApplicationArea = All;
                Caption = 'Delete';
                Ellipsis = true;
                Image = Delete;
                Promoted = true;
                PromotedCategory = "Report";
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Removes the deployed report from your Power BI account.';

                trigger OnAction()
                var
                    PowerBIReportUploads: Record "Power BI Report Uploads";
                    PowerBICustomerReports: Record "Power BI Customer Reports";
                begin
                    CurrPage.SetSelectionFilter(PowerBICustomerReports);

                    if not Dialog.Confirm(DeleteQst, false) then
                        exit;

                    if PowerBICustomerReports.FindSet() then
                        repeat
                            if PowerBIReportUploads.Get(PowerBICustomerReports.Id, SelectedUserSecurityId) then begin
                                PowerBIReportUploads."Needs Deletion" := true;
                                PowerBIReportUploads.Modify();
                            end;
                        until PowerBICustomerReports.Next() = 0;

                    PowerBIServiceMgt.SynchronizeReportsInBackground();
                    LoadReports();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        IsUserPBIAdmin := PowerBIServiceMgt.IsUserAdminForPowerBI(UserSecurityId());
    end;

    trigger OnOpenPage()
    begin
        SelectedUser := CopyStr(UserId(), 1, MaxStrLen(SelectedUser));
        SelectedUserSecurityId := UserSecurityId();
        LoadReports();
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        DeleteQst: Label 'Would you like to delete the selection from the table?';
        SelectedUserSecurityId: Guid;
        SelectedUser: Code[50];
        IsUserPBIAdmin: Boolean;

    local procedure LoadReports()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBICustomerReports: Record "Power BI Customer Reports";
    begin
        // Clear temp records
        DeleteAll();

        if IsNullGuid(SelectedUserSecurityId) then
            exit;

        PowerBIReportUploads.SetRange("User ID", SelectedUserSecurityId);
        PowerBIReportUploads.SetRange("Is Selection Done", false);

        // Check all upload records for the user and find only the ones for customer reports
        if PowerBIReportUploads.FindSet() then
            repeat
                if PowerBICustomerReports.Get(PowerBIReportUploads."PBIX BLOB ID") then begin
                    Copy(PowerBICustomerReports);
                    Insert();
                end;
            until PowerBIReportUploads.Next() = 0;

    end;
}

