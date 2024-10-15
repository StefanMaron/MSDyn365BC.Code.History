page 629 "IC Chart of Accounts Setup"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Synchronization Setup';
    PageType = StandardDialog;
    SourceTable = "IC Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                ShowCaption = false;
                field(PartnerCode; Rec."Partner Code for Acc. Syn.")
                {
                    Caption = 'Partner Code';
                    ToolTip = 'Specifies the partner code with which you want to synchronize the intercompany chart of accounts.';
                    ApplicationArea = All;
                    Editable = true;
                    Enabled = true;
                }
            }
        }
    }

    trigger OnClosePage()
    var
        ICAccounts: Record "IC G/L Account";
        ICPartner: Record "IC Partner";
        ICPartnerAccounts: Record "IC G/L Account";
        ICMappingAccounts: Codeunit "IC Mapping Accounts";
        MessageText: Text;
    begin
        if Rec."Partner Code for Acc. Syn." = '' then
            exit;

        if not ICPartner.Get(Rec."Partner Code for Acc. Syn.") then
            exit;

        if not ICPartnerAccounts.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, ICPartner.Name);

        if not ICPartnerAccounts.ReadPermission() then
            Error(MissingPermissionToReadTableErr, ICPartner.Name);

        if ICPartnerAccounts.IsEmpty() then
            exit;

        if GuiAllowed() then begin
            MessageText := StrSubstNo(SyncronizeChartOfAccountsQst, Rec."Partner Code for Acc. Syn.");
            if not ICAccounts.IsEmpty() then
                MessageText := StrSubstNo(SplitMessageTxt, MessageText, CleanExistingICAccountsMsg);
            MessageText := StrSubstNo(SplitMessageTxt, MessageText, ContinueQst);
            if not Confirm(MessageText, false) then
                exit;
        end;

        ICMappingAccounts.SynchronizeAccounts(true, Rec."Partner Code for Acc. Syn.");
    end;

    var
        SplitMessageTxt: Label '%1\%2', Comment = '%1 = First part of the message, %2 = Second part of the message.';
        SyncronizeChartOfAccountsQst: Label 'Partner %1 has an intercompany chart of accounts that can be synchronized now.', Comment = '%1 = IC Partner code';
        CleanExistingICAccountsMsg: Label 'Before synchronizing with a new partner it is necessary to delete existing intercompany accounts.';
        ContinueQst: Label 'Do you want to continue?';
        FailedToChangeCompanyErr: Label 'It was not possible to find the intercompany chart of accounts of partner %1.', Comment = '%1 = Partner Code';
        MissingPermissionToReadTableErr: Label 'You do not have the necessary permissions to access the intercompany chart of accounts of partner %1.', Comment = '%1 = Partner Code';
}