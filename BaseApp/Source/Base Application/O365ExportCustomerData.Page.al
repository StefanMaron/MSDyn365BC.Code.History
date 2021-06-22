page 2380 "O365 Export Customer Data"
{
    Caption = 'Export Customer Data';
    DataCaptionExpression = Name;
    PageType = StandardDialog;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                field(CustomerNo; "No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Customer Number';
                    Visible = false;
                }
                field(CustomerName; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Customer Name';
                    Editable = false;
                }
                field(Email; SendToEmail)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Send to Email';
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email recipients for the exported invoices';

                    trigger OnValidate()
                    begin
                        if SendToEmail = '' then
                            exit;

                        MailManagement.CheckValidEmailAddress(SendToEmail);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        User: Record User;
        CompanyInformation: Record "Company Information";
    begin
        if GetFilters <> '' then
            if FindFirst then
                SetRecFilter;

        if User.Get(UserSecurityId) then
            SendToEmail := User."Contact Email";
        if SendToEmail = '' then
            if CompanyInformation.Get then
                SendToEmail := CompanyInformation."E-Mail";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> ACTION::OK then
            exit;
        if SendToEmail = '' then
            Error(EmailAddressErr);

        if SendToEmail = "E-Mail" then // sending directly to the customer?
            if not Confirm(StrSubstNo(CustomerEmailQst, SendToEmail), false) then
                Error('');

        O365EmailCustomerData.ExportDataToExcelAndEmail(Rec, SendToEmail);
    end;

    var
        MailManagement: Codeunit "Mail Management";
        O365EmailCustomerData: Codeunit "O365 Email Customer Data";
        SendToEmail: Text;
        EmailAddressErr: Label 'The email address is required.';
        CustomerEmailQst: Label 'Warning: The email (%1) is the same as specified on the customer. Note that the data may contain information that is internal to your company.\Do you want to send the email anyway?', Comment = '%1 = an email address.';
}

