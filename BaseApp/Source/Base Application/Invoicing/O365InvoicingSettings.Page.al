#if not CLEAN21
page 2191 "O365 Invoicing Settings"
{
    Caption = 'Settings';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "O365 Settings Menu";
    SourceTableTemporary = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Title; Rec.Title)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies a description of the invoice setting.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
                Visible = false;

                trigger OnAction()
                begin
                    Rec.OpenPage();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        InsertMenuItems();
    end;

    var
        BusinessInformationTitleTxt: Label 'Business Information';
        BusinessInformationDescriptionTxt: Label 'Company info, logo';
        TaxPaymentsSettingsTitleTxt: Label 'Tax Payments Settings';
        TaxPaymentsSettingsDescriptionTxt: Label 'Tax, bank and payment information';
        ImportExportTitleTxt: Label 'Import & Export ';
        ImportExportDescriptionTxt: Label 'Import contacts and prices, and export invoices';
        InvoiceSendOptionsTitleTxt: Label 'Invoice send options';
        InvoiceSendOptionsDescriptionTxt: Label 'Email account, CC, BCC';
        HelpAndFeedbackTitleTxt: Label 'Help and Feedback';
        HelpAndFeedbackDesriptionTxt: Label 'Learn, provide feedback, terms, privacy';
        ServicesTitleTxt: Label 'Services';
        ServicesDescriptionTxt: Label 'External Services Settings';

    local procedure InsertMenuItems()
    begin
        Rec.InsertPageMenuItem(
          PAGE::"O365 Business Info Settings",
          BusinessInformationTitleTxt,
          BusinessInformationDescriptionTxt);
        Rec.InsertPageMenuItem(
          PAGE::"O365 Invoice Send Settings",
          InvoiceSendOptionsTitleTxt,
          InvoiceSendOptionsDescriptionTxt);
        Rec.InsertPageMenuItem(
          PAGE::"O365 Tax Payments Settings",
          TaxPaymentsSettingsTitleTxt,
          TaxPaymentsSettingsDescriptionTxt);
        Rec.InsertPageMenuItem(
          PAGE::"VAT Registration Config",
          ServicesTitleTxt,
          ServicesDescriptionTxt);
        Rec.InsertPageMenuItem(
          PAGE::"O365 Import Export Settings",
          ImportExportTitleTxt,
          ImportExportDescriptionTxt);
        Rec.InsertPageMenuItem(
          PAGE::"O365 Help Feedback Settings",
          HelpAndFeedbackTitleTxt,
          HelpAndFeedbackDesriptionTxt);
    end;
}
#endif

