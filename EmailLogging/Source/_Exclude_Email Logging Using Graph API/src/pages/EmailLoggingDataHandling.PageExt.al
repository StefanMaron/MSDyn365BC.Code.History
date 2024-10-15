pageextension 1680 "Email Logging Data Handling" extends "Schedule Feature Data Update"
{
    trigger OnOpenPage()
    begin
        EmailLogging := FeatureKeyMatches(Rec, Enum::"Feature To Update"::EmailLoggingUsingGraphApi);
        if EmailLogging then
            if not Confirm(DataHandlingConsentQst, false) then
                Error('');
    end;

    local procedure FeatureKeyMatches(FeatureDataUpdateStatus: Record "Feature Data Update Status"; FeatureToUpdate: Enum "Feature To Update"): Boolean
    begin
        if FeatureToUpdate.Names.Contains(FeatureDataUpdateStatus."Feature Key") then
            exit(FeatureToUpdate.AsInteger() =
                FeatureToUpdate.Ordinals.Get(FeatureToUpdate.Names.IndexOf(FeatureDataUpdateStatus."Feature Key")));
        exit(false);
    end;

    var
        EmailLogging: Boolean;
        DataHandlingConsentQst: Label 'This feature requires that you are using Microsoft Exchange Online. By enabling this feature, you consent to sharing some of your organization''s data in Office 365 with Business Central. Business Central will access details about email messages in the shared mailbox that your administrator created for email logging. The details include the message’s IDs, whether it is a draft, the dates and times it was sent and received, the text from the Subject line, a link to the message in Exchange Online, and the email addresses of the sender and the recipients on the To and Cc lines.\\Business Central will store only the IDs, dates, subject, and weblink. We do not store the content of the messages, but there is a link that will open the email message in Outlook Online.\\Do you want to continue?';
}
