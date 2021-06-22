page 1366 "Field Monitoring Setup"
{
    PageType = Card;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    SourceTable = "Field Monitoring Setup";
    DeleteAllowed = false;
    InsertAllowed = false;
    Extensible = false;
    AccessByPermission = tabledata "Field Monitoring Setup" = M;
    RefreshOnActivate = true;
    Caption = 'Field Monitoring Setup';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("User ID"; "User Id")
                {
                    ToolTip = 'Specifies the user ID';
                    ApplicationArea = Basic, Suite;
                }
                group(Email)
                {
                    Visible = IsEmailSystemModuleEnabled;
                    ShowCaption = false;
                    field("Email Account Name"; "Email Account Name")
                    {
                        ToolTip = 'Specifies the email account that will send the notification email. Typically, this is a system account that is not associated with a user.';
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Caption = 'Notification Email Account';

                        trigger OnAssistEdit()
                        var
                            TempEmailAccount: Record "Email Account" temporary;
                        begin
                            if Page.RunModal(Page::"Email Accounts", TempEmailAccount) = Action::LookupOK then begin
                                "Email Account Id" := TempEmailAccount."Account Id";
                                "Email Account Name" := TempEmailAccount.Name;
                                "Email Connector" := TempEmailAccount.Connector;
                            end;
                        end;
                    }
                }

                field("Monitor Status"; "Monitor Status")
                {
                    ToolTip = 'Specifies the monitor status';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Start")
            {
                ToolTip = 'Start monitoring fields for changes.';
                ApplicationArea = Basic, Suite;
                Promoted = true;
                Image = Start;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Enabled = not IsMonitorEnabled;

                trigger OnAction()
                begin
                    MonitorSensitiveField.EnableMonitor(True);
                end;
            }
            action("Stop")
            {
                ToolTip = 'Stop monitoring fields for changes.';
                ApplicationArea = Basic, Suite;
                Promoted = true;
                Image = Stop;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Enabled = IsMonitorEnabled;

                trigger OnAction()
                begin
                    MonitorSensitiveField.DisableMonitor();
                end;
            }
            action(RetentionPolicy)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Retention Policy';
                Tooltip = 'View or edit the retention policy.';
                Image = Delete;
                RunObject = Page "Retention Policy Setup Card";
                RunPageLink = "Table Id" = Filter(405); // Database::"Change Log Entry";
                AccessByPermission = tabledata "Retention Policy Setup" = R;
                RunPageMode = View;
                Ellipsis = true;
            }
        }
    }

    var
        EmailFeature: Codeunit "Email Feature";
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
        IsMonitorEnabled, IsEmailSystemModuleEnabled : Boolean;

    trigger OnOpenPage()
    begin
        MonitorSensitiveField.GetSetupTable(Rec);
        IsEmailSystemModuleEnabled := EmailFeature.IsEnabled();
        MonitorSensitiveField.ShowEmailFeatureEnabledInSetupPageNotification();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsMonitorEnabled := "Monitor Status";
    end;
}