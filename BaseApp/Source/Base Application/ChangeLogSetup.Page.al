page 592 "Change Log Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Change Log Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Setup';
    SourceTable = "Change Log Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Change Log Activated"; "Change Log Activated")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the change log is active.';

                    trigger OnValidate()
                    begin
                        ConfirmActivationOfChangeLog;
                        ChangeLogSettingsUpdated := true;
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Setup")
            {
                Caption = '&Setup';
                Image = Setup;
                action(Tables)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tables';
                    Image = "Table";
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'View what must be logged for each table.';

                    trigger OnAction()
                    var
                        ChangeLogSetupList: Page "Change Log Setup (Table) List";
                    begin
                        ChangeLogSetupList.SetSource;
                        ChangeLogSetupList.RunModal;
                        ChangeLogSettingsUpdated := ChangeLogSetupList.IsChangeLogSettingsUpdated();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;

    trigger OnClosePage()
    begin
        if ChangeLogSettingsUpdated then
            if Confirm(RestartSessionQst) then
                RestartSession();
    end;

    var
        ActivateChangeLogQst: Label 'Turning on the Change Log might slow things down, especially if you are monitoring entities that often change. Do you want to log changes?';
        RestartSessionQst: Label 'Changes are displayed on the Change Log Entries page after the user''s session has restarted. Do you want to restart the session now?';
        ChangeLogSettingsUpdated: Boolean;

    local procedure ConfirmActivationOfChangeLog()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not "Change Log Activated" then
            exit;
        if not EnvironmentInfo.IsSaaS then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(ActivateChangeLogQst, true) then
            Error('');
    end;

    local procedure RestartSession()
    var
        SessionSetting: SessionSettings;
    begin
        SessionSetting.Init();
        SessionSetting.RequestSessionUpdate(false);
    end;

}

