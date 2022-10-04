#if not CLEAN21
page 2349 "BC O365 Mobile App"
{
    Caption = ' ';
    PageType = CardPart;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control5)
            {
                InstructionalText = 'Did you know that you can also get Microsoft Invoicing on your phone?';
                ShowCaption = false;
            }
            field("Learn more"; LearnMoreLbl)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Editable = false;
                ShowCaption = false;

                trigger OnDrillDown()
                begin
                    Session.LogMessage('00006ZG', LearnMoreTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InvoicingMobileAppSettingsCategoryLbl);
                    HyperLink(InvoicingDocsUrlTok);
                end;
            }
        }
    }

    actions
    {
    }

    var
        LearnMoreLbl: Label 'Learn more';
        InvoicingDocsUrlTok: Label 'https://go.microsoft.com/fwlink/?linkid=2030384', Locked = true;
        InvoicingMobileAppSettingsCategoryLbl: Label 'AL Invoicing Mobile App Settings', Locked = true;
        LearnMoreTelemetryTxt: Label 'Learn more link has been clicked.', Locked = true;
}
#endif
