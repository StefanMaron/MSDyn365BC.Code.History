page 680 "Report Inbox"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Inbox';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Report Inbox";
    SourceTableView = SORTING("User ID", "Created Date-Time")
                      ORDER(Descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("Created Date-Time"; "Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time that the scheduled report was processed from the job queue.';
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Name"; "Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the report.';

                    trigger OnDrillDown()
                    begin
                        ShowReport;
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenInOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open in OneDrive';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and open it in a new window so you can manage or share the file.', Comment = 'OneDrive should not be translated';
                Image = Cloud;
                Enabled = ShareOptionsEnabled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Scope = Repeater;
                trigger OnAction()
                begin
                    Rec.OpenInOneDrive();
                end;
            }
            action(Show)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Download';
                Enabled = DownloadEnabled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Scope = Repeater;
                Image = Download;
                ShortCutKey = 'Return';
                ToolTip = 'Download the file to your device. Depending on the file, you will need an app to view or edit the file.';

                trigger OnAction()
                begin
                    ShowReport();
                    CurrPage.Update();
                end;
            }

        }
    }

    trigger OnAfterGetCurrRecord()
    var
        DocumentSharing: Codeunit "Document Sharing";
    begin
        ShareOptionsEnabled := (not ("Report Name" = '')) and (DocumentSharing.ShareEnabled());
        DownloadEnabled := (not ("Report Name" = ''));
    end;

    var
        ShareOptionsEnabled: Boolean;
        DownloadEnabled: Boolean;
}

