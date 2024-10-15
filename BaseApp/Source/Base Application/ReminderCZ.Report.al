report 31086 "Reminder CZ"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ReminderCZ.rdlc';
    Caption = 'Reminder CZ (Obsolete)';
    PreviewMode = PrintLayout;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("Company Information"; "Company Information")
        {
            DataItemTableView = SORTING("Primary Key");
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(RegistrationNo_CompanyInformation; "Registration No.")
            {
            }
            column(VATRegistrationNo_CompanyInformation; "VAT Registration No.")
            {
            }
            column(HomePage_CompanyInformation; "Home Page")
            {
            }
            column(Picture_CompanyInformation; Picture)
            {
            }
            dataitem("Sales & Receivables Setup"; "Sales & Receivables Setup")
            {
                DataItemTableView = SORTING("Primary Key");
                column(LogoPositiononDocuments_SalesReceivablesSetup; Format("Logo Position on Documents", 0, 2))
                {
                }
                dataitem("General Ledger Setup"; "General Ledger Setup")
                {
                    DataItemTableView = SORTING("Primary Key");
                    column(LCYCode_GeneralLedgerSetup; "LCY Code")
                    {
                    }
                }
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddr.Company(CompanyAddr, "Company Information");
            end;
        }
        dataitem("Issued Reminder Header"; "Issued Reminder Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            column(DocumentLbl; DocumentLbl)
            {
            }
            column(PageLbl; PageLbl)
            {
            }
            column(CopyLbl; CopyLbl)
            {
            }
            column(VendorLbl; VendLbl)
            {
            }
            column(CustomerLbl; CustLbl)
            {
            }
            column(CreatorLbl; CreatorLbl)
            {
            }
            column(No_IssuedReminderHeader; "No.")
            {
            }
            column(VATRegistrationNo_IssuedReminderHeaderCaption; FieldCaption("VAT Registration No."))
            {
            }
            column(VATRegistrationNo_IssuedReminderHeader; "VAT Registration No.")
            {
            }
            column(RegistrationNo_IssuedReminderHeaderCaption; FieldCaption("Registration No."))
            {
            }
            column(RegistrationNo_IssuedReminderHeader; "Registration No.")
            {
            }
            column(BankAccountNo_IssuedReminderHeaderCaption; FieldCaption("Bank Account No."))
            {
            }
            column(BankAccountNo_IssuedReminderHeader; "Bank Account No.")
            {
            }
            column(IBAN_IssuedReminderHeaderCaption; FieldCaption(IBAN))
            {
            }
            column(IBAN_IssuedReminderHeader; IBAN)
            {
            }
            column(SWIFTCode_IssuedReminderHeaderCaption; FieldCaption("SWIFT Code"))
            {
            }
            column(SWIFTCode_IssuedReminderHeader; "SWIFT Code")
            {
            }
            column(CustomerNo_IssuedReminderHeaderCaption; FieldCaption("Customer No."))
            {
            }
            column(CustomerNo_IssuedReminderHeader; "Customer No.")
            {
            }
            column(PostingDate_IssuedReminderHeaderCaption; FieldCaption("Posting Date"))
            {
            }
            column(PostingDate_IssuedReminderHeader; "Posting Date")
            {
            }
            column(DocumentDate_IssuedReminderHeaderCaption; FieldCaption("Document Date"))
            {
            }
            column(DocumentDate_IssuedReminderHeader; "Document Date")
            {
            }
            column(CurrencyCode_IssuedReminderHeader; "Currency Code")
            {
            }
            column(DocFooterText; DocFooterText)
            {
            }
            column(CustAddr1; CustAddr[1])
            {
            }
            column(CustAddr2; CustAddr[2])
            {
            }
            column(CustAddr3; CustAddr[3])
            {
            }
            column(CustAddr4; CustAddr[4])
            {
            }
            column(CustAddr5; CustAddr[5])
            {
            }
            column(CustAddr6; CustAddr[6])
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(CopyNo; Number)
                {
                }
                dataitem("Issued Reminder Line"; "Issued Reminder Line")
                {
                    DataItemLink = "Reminder No." = FIELD("No.");
                    DataItemLinkReference = "Issued Reminder Header";
                    DataItemTableView = SORTING("Reminder No.", "Line No.");
                    column(TotalLbl; TotalLbl)
                    {
                    }
                    column(DocumentDate_IssuedReminderLineCaption; FieldCaption("Document Date"))
                    {
                    }
                    column(DocumentDate_IssuedReminderLine; "Document Date")
                    {
                    }
                    column(DocumentType_IssuedReminderLineCaption; FieldCaption("Document Type"))
                    {
                    }
                    column(DocumentType_IssuedReminderLine; "Document Type")
                    {
                    }
                    column(DocumentNo_IssuedReminderLineCaption; FieldCaption("Document No."))
                    {
                    }
                    column(DocumentNo_IssuedReminderLine; "Document No.")
                    {
                    }
                    column(DueDate_IssuedReminderLineCaption; FieldCaption("Due Date"))
                    {
                    }
                    column(DueDate_IssuedReminderLine; "Due Date")
                    {
                    }
                    column(OriginalAmount_IssuedReminderLineCaption; FieldCaption("Original Amount"))
                    {
                    }
                    column(OriginalAmount_IssuedReminderLine; "Original Amount")
                    {
                    }
                    column(RemainingAmount_IssuedReminderLineCaption; FieldCaption("Remaining Amount"))
                    {
                    }
                    column(RemainingAmount_IssuedReminderLine; "Remaining Amount")
                    {
                    }
                    column(InterestAmount_IssuedReminderLineCaption; FieldCaption("Interest Amount"))
                    {
                    }
                    column(InterestAmount_IssuedReminderLine; "Interest Amount")
                    {
                    }
                    column(Description_IssuedReminderLine; Description)
                    {
                    }
                    column(Type_IssuedReminderLine; Format(Type, 0, 2))
                    {
                    }
                    column(LineType_IssuedReminderLine; Format("Line Type", 0, 2))
                    {
                    }
                    column(LineNo_IssuedReminderLine; "Line No.")
                    {
                    }
                    column(InterestAmountInclVAT; InterestAmountInclVAT)
                    {
                    }
                    column(AmountInclVAT; AmountInclVAT)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        AmountInclVAT := 0;
                        InterestAmountInclVAT := 0;

                        if "Interest Amount" <> 0 then
                            InterestAmountInclVAT := "Interest Amount" + "VAT Amount";

                        if Amount <> 0 then
                            AmountInclVAT := Amount + "VAT Amount"
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Line Type", '<>%1&<>%2', "Line Type"::"Not Due", "Line Type"::"On Hold");
                    end;
                }
                dataitem(NotDueLine; "Issued Reminder Line")
                {
                    DataItemLink = "Reminder No." = FIELD("No.");
                    DataItemLinkReference = "Issued Reminder Header";
                    DataItemTableView = SORTING("Reminder No.", "Line No.");
                    column(DocumentDate_NotDueLine; "Document Date")
                    {
                    }
                    column(DocumentType_NotDueLine; "Document Type")
                    {
                    }
                    column(DocumentNo_NotDueLine; "Document No.")
                    {
                    }
                    column(DueDate_NotDueLine; "Due Date")
                    {
                    }
                    column(OriginalAmount_NotDueLine; "Original Amount")
                    {
                    }
                    column(RemainingAmount_NotDueLine; "Remaining Amount")
                    {
                    }
                    column(Description_NotDueLine; Description)
                    {
                    }
                    column(Type_NotDueLine; Format(Type, 0, 2))
                    {
                    }
                    column(LineType_NotDueLine; Format("Line Type", 0, 2))
                    {
                    }
                    column(LineNo_NotDueLine; "Line No.")
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if not ShowNotDueAmounts then
                            CurrReport.Break();

                        SetFilter("Line Type", '%1|%2', "Line Type"::"Not Due", "Line Type"::"On Hold");
                    end;
                }
                dataitem("User Setup"; "User Setup")
                {
                    DataItemLink = "User ID" = FIELD("User ID");
                    DataItemLinkReference = "Issued Reminder Header";
                    DataItemTableView = SORTING("User ID");
                    dataitem(Employee; Employee)
                    {
                        DataItemLink = "No." = FIELD("Employee No.");
                        DataItemTableView = SORTING("No.");
                        column(FullName_Employee; FullName)
                        {
                        }
                        column(PhoneNo_Employee; "Phone No.")
                        {
                        }
                        column(CompanyEMail_Employee; "Company E-Mail")
                        {
                        }
                    }
                }

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode then
                        "Issued Reminder Header".IncrNoPrinted;
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    if NoOfLoops <= 0 then
                        NoOfLoops := 1;

                    SetRange(Number, 1, NoOfLoops);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                FormatAddr.IssuedReminder(CustAddr, "Issued Reminder Header");

                DocumentFooter.SetFilter("Language Code", '%1|%2', '', "Language Code");
                if DocumentFooter.FindLast then
                    DocFooterText := DocumentFooter."Footer Text"
                else
                    DocFooterText := '';

                if "Currency Code" = '' then
                    "Currency Code" := "General Ledger Setup"."LCY Code";

                if LogInteraction and not IsReportInPreviewMode then
                    SegMgt.LogDocument(
                      8, "No.", 0, 0, DATABASE::Customer, "Customer No.", '', '', "Posting Description", '');
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies the number of copies to print.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the program to record the reminder you print as Interactions and add them to the Interaction Log Entry table.';
                    }
                    field(ShowNotDueAmounts; ShowNotDueAmounts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Not Due Amounts';
                        ToolTip = 'Specifies if you want to show amounts that are not due from customers.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteractionEnable := true;
        end;

        trigger OnOpenPage()
        begin
            InitLogInteraction;
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            InitLogInteraction;
    end;

    var
        DocumentFooter: Record "Document Footer";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        SegMgt: Codeunit SegManagement;
        CompanyAddr: array[8] of Text[100];
        DocumentLbl: Label 'Reminder';
        PageLbl: Label 'Page';
        CopyLbl: Label 'Copy';
        VendLbl: Label 'Vendor';
        CustLbl: Label 'Customer';
        CustAddr: array[8] of Text[100];
        DocFooterText: Text[250];
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        LogInteraction: Boolean;
        [InDataSet]
        LogInteractionEnable: Boolean;
        TotalLbl: Label 'Total';
        ShowNotDueAmounts: Boolean;
        InterestAmountInclVAT: Decimal;
        AmountInclVAT: Decimal;
        CreatorLbl: Label 'Created by';

    [Scope('OnPrem')]
    procedure InitializeRequest(NoOfCopiesFrom: Integer; LogInteractionFrom: Boolean; ShowNotDueAmountsFrom: Boolean)
    begin
        NoOfCopies := NoOfCopiesFrom;
        LogInteraction := LogInteractionFrom;
        ShowNotDueAmounts := ShowNotDueAmountsFrom;
    end;

    local procedure InitLogInteraction()
    begin
        LogInteraction := SegMgt.FindInteractTmplCode(8) <> '';
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;
}

