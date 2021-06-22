page 2349 "BC O365 Mobile App"
{
    Caption = ' ';
    PageType = CardPart;

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
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                ShowCaption = false;

                trigger OnDrillDown()
                begin
                    SendTraceTag('00006ZG', InvoicingMobileAppSettingsCategoryLbl, VERBOSITY::Normal,
                      LearnMoreTelemetryTxt, DATACLASSIFICATION::SystemMetadata);
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

