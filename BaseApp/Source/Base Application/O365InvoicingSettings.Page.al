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

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Title; Title)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
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
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
                Visible = false;

                trigger OnAction()
                begin
                    OpenPage;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        InsertMenuItems;
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
        InsertPageMenuItem(
          PAGE::"O365 Business Info Settings",
          BusinessInformationTitleTxt,
          BusinessInformationDescriptionTxt);
        InsertPageMenuItem(
          PAGE::"O365 Invoice Send Settings",
          InvoiceSendOptionsTitleTxt,
          InvoiceSendOptionsDescriptionTxt);
        InsertPageMenuItem(
          PAGE::"O365 Tax Payments Settings",
          TaxPaymentsSettingsTitleTxt,
          TaxPaymentsSettingsDescriptionTxt);
        InsertPageMenuItem(
          PAGE::"VAT Registration Config",
          ServicesTitleTxt,
          ServicesDescriptionTxt);
        InsertPageMenuItem(
          PAGE::"O365 Import Export Settings",
          ImportExportTitleTxt,
          ImportExportDescriptionTxt);
        InsertPageMenuItem(
          PAGE::"O365 Help Feedback Settings",
          HelpAndFeedbackTitleTxt,
          HelpAndFeedbackDesriptionTxt);
    end;
}

