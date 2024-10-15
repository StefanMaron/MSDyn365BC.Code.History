// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides an overview of all e-mail that were sent out.
/// </summary>
page 8883 "Sent Emails"
{
    PageType = List;
    Caption = 'Sent Emails';
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Sent Email";
    SourceTableTemporary = true;
    Permissions = tabledata "Sent Email" = rd;
    InsertAllowed = false;
    ModifyAllowed = false;
    Extensible = true;

    layout
    {
        area(Content)
        {
            repeater(SentEmails)
            {
                field(Desc; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a short description of the email that was sent.';

                    trigger OnDrillDown()
                    begin
                        EmailViewer.Open(Rec);
                    end;
                }

                field(ConnectorType; Rec.Connector)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the type of email extension that was used to send the email.';
                }

                field(DateTimeSent; Rec."Date Time Sent")
                {
                    Caption = 'Sent';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date and time the email was sent.';
                }

                field(Sender; Rec.Sender)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Business Central user who sent this email.';
                }

                field(SentFrom; Rec."Sent From")
                {
                    ApplicationArea = All;
                    Caption = 'Sent From';
                    ToolTip = 'Specifies the email address that this email was sent from.';

                    trigger OnDrillDown()
                    begin
                        ShowAccountInformation();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(Resend)
            {
                ApplicationArea = All;
                Caption = 'Resend';
                ToolTip = 'Resend the email.';
                Image = Email;
                Enabled = not NoSentEmails;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    SelectedSentEmail: Record "Sent Email";
                begin
                    CurrPage.SetSelectionFilter(SelectedSentEmail);
                    if not SelectedSentEmail.FindSet() then
                        exit;

                    repeat
                        EmailViewer.Resend(SelectedSentEmail);
                    until SelectedSentEmail.Next() = 0;
                end;
            }

            action(EditAndSend)
            {
                ApplicationArea = All;
                Caption = 'Edit and Send';
                ToolTip = 'Edit and send the email.';
                Image = Email;
                Enabled = not NoSentEmails;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    EmailViewer.EditAndSend(Rec)
                end;
            }

            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                ToolTip = 'Refresh';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    EmailViewer.RefreshSentMailForUser(EmailAccountId, NewerThanDate, SourceTableID, SourceSystemID, Rec);
                    CurrPage.Update(false);
                    NoSentEmails := Rec.IsEmpty();
                end;
            }

            action(ShowSourceRecord)
            {
                ApplicationArea = All;
                Image = GetSourceDoc;
                Caption = 'Show Source';
                ToolTip = 'Open the page from where the email was sent.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    EmailImpl: Codeunit "Email Impl";
                begin
                    EmailImpl.ShowSourceRecord(Rec."Message Id");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        EmailViewer.RefreshSentMailForUser(EmailAccountId, NewerThanDate, SourceTableID, SourceSystemID, Rec);
        Rec.SetCurrentKey("Date Time Sent");
        NoSentEmails := Rec.IsEmpty();
        Rec.Ascending(false);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        SentEmail: Record "Sent Email";
    begin
        if SentEmail.Get(Rec.Id) then
            SentEmail.Delete(true);
    end;

    local procedure ShowAccountInformation()
    var
        EmailAccountImpl: Codeunit "Email Account Impl.";
        EmailConnector: Interface "Email Connector";
    begin
        if not EmailAccountImpl.IsValidConnector(Rec.Connector) then
            Error(EmailConnectorHasBeenUninstalledMsg);

        EmailConnector := Rec.Connector;
        EmailConnector.ShowAccountInformation(Rec."Account Id");
    end;

    internal procedure SetNewerThan(NewDate: DateTime)
    begin
        NewerThanDate := NewDate;
    end;

    internal procedure SetEmailAccountId(AccountId: Guid)
    begin
        EmailAccountId := AccountId;
    end;

    internal procedure SetRelatedRecord(TableID: Integer; SystemID: Guid)
    begin
        SourceTableID := TableID;
        SourceSystemID := SystemID;
    end;

    var
        EmailViewer: Codeunit "Email Viewer";
        NewerThanDate: DateTime;
        EmailAccountId, SourceSystemID : Guid;
        SourceTableID: Integer;
        NoSentEmails: Boolean;
        EmailConnectorHasBeenUninstalledMsg: Label 'The email extension that was used to send this email has been uninstalled. To view information about the email account, you must reinstall the extension.';
}