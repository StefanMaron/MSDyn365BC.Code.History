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
                            LoadReports;
                        end;

                        // TODO: Try changing uploads table to User Name instead of security id instead?? (allows use of TableRelation instead of manual lookup?)

                        // TODO: Restrict ability to edit field based on current user's permissions (only admins can look at someone other than themself)
                    end;

                    trigger OnValidate()
                    var
                        User: Record User;
                    begin
                        // Handles typing a value into the user field.
                        User.Reset();
                        User.SetFilter("User Name", SelectedUser);
                        if User.FindFirst then begin
                            SelectedUser := User."User Name";
                            SelectedUserSecurityId := User."User Security ID";
                        end else
                            Clear(SelectedUserSecurityId);

                        LoadReports;

                        // TODO: Restrict ability to edit field based on current user's permissions (only admins can look at someone other than themself)
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
                    WillDelete: Boolean;
                begin
                    // TODO: Get selected rows
                    CurrPage.SetSelectionFilter(Rec);
                    MarkedOnly(true);
                    PowerBIReportUploads.Reset();

                    WillDelete := DIALOG.Confirm(DeleteQst, false);

                    FindFirst;
                    PowerBIReportUploads.FindFirst;

                    repeat
                        if Id = PowerBIReportUploads."PBIX BLOB ID" then begin
                            PowerBIReportUploads."Needs Deletion" := WillDelete;
                            PowerBIReportUploads.Modify();
                            Next;
                        end;
                    until PowerBIReportUploads.Next = 0;

                    // TODO: Go into table 6307 and set "Needs Deletion" on each row to TRUE
                    // TODO: Call codeunit 6301 to delete immediately (or let spinner part pick it up on refresh)
                    PowerBIServiceMgt.DeleteDefaultReportsInBackground;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        // Fill in
        // PowerBIBlob.GET("PBIX BLOB ID");
        // ReportName := PowerBIBlob.Name;
    end;

    trigger OnOpenPage()
    begin
        SelectedUser := UserId;
        SelectedUserSecurityId := UserSecurityId;
        LoadReports;
    end;

    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        DeleteQst: Label 'Would you like to delete the selection from the table?', Comment = 'Identifies the reports to be deleted.';
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        SelectedUserSecurityId: Guid;
        SelectedUser: Code[50];

    local procedure LoadReports()
    var
        PowerBICustomerReports: Record "Power BI Customer Reports";
    begin
        // Clear temp records
        DeleteAll();
        PowerBICustomerReports.Next;
        // Fill the Blob table with actual upload table values
        if not IsNullGuid(SelectedUserSecurityId) then
            if PowerBIReportUploads.Find('-') then begin
                repeat
                    PowerBIReportUploads.Reset();
                    PowerBIReportUploads.SetFilter("User ID", SelectedUserSecurityId);
                    PowerBIReportUploads.SetFilter("Is Selection Done", 'No');
                    if PowerBICustomerReports.Get(PowerBIReportUploads."PBIX BLOB ID") then begin
                        Copy(PowerBICustomerReports);
                        Insert;
                        PowerBICustomerReports.Next;
                    end;
                until PowerBIReportUploads.Next = 0;
            end;
    end;
}

