#if not CLEAN19
report 31020 "Purchase - Advance Letter CZ"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PurchaseAdvanceLetterCZ.rdlc';
    Caption = 'Purchase - Advance Letter CZ (Obsolete)';
    PreviewMode = PrintLayout;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

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

            trigger OnPreDataItem()
            begin
                CalcFields(Picture);
            end;
        }
        dataitem("Purch. Advance Letter Header"; "Purch. Advance Letter Header")
        {
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
            column(PaymentTermsLbl; PaymentTermsLbl)
            {
            }
            column(PaymentMethodLbl; PaymentMethodLbl)
            {
            }
            column(PurchaserLbl; PurchaserLbl)
            {
            }
            column(TotalLbl; TotalLbl)
            {
            }
            column(CreatorLbl; CreatorLbl)
            {
            }
            column(No_PurchSalesAdvanceLetterHeader; "No.")
            {
            }
            column(VATRegistrationNo_PurchAdvanceLetterHeaderCaption; FieldCaption("VAT Registration No."))
            {
            }
            column(VATRegistrationNo_PurchAdvanceLetterHeader; "VAT Registration No.")
            {
            }
            column(RegistrationNo_PurchAdvanceLetterHeaderCaption; FieldCaption("Registration No."))
            {
            }
            column(RegistrationNo_PurchAdvanceLetterHeader; "Registration No.")
            {
            }
            column(BankAccountNo_PurchAdvanceLetterHeaderCaption; FieldCaption("Bank Account No."))
            {
            }
            column(BankAccountNo_PurchAdvanceLetterHeader; "Bank Account No.")
            {
            }
            column(IBAN_PurchAdvanceLetterHeaderCaption; FieldCaption(IBAN))
            {
            }
            column(IBAN_PurchAdvanceLetterHeader; IBAN)
            {
            }
            column(BIC_PurchAdvanceLetterHeaderCaption; FieldCaption("SWIFT Code"))
            {
            }
            column(BIC_PurchAdvanceLetterHeader; "SWIFT Code")
            {
            }
            column(DocumentDate_PurchAdvanceLetterHeaderCaption; FieldCaption("Document Date"))
            {
            }
            column(DocumentDate_PurchAdvanceLetterHeader; "Document Date")
            {
            }
            column(PaymentTerms; PaymentTerms.Description)
            {
            }
            column(PaymentMethod; PaymentMethod.Description)
            {
            }
            column(YourReference_PurchAdvanceLetterHeaderCaption; FieldCaption("Your Reference"))
            {
            }
            column(YourReference_PurchAdvanceLetterHeader; "Your Reference")
            {
            }
            column(CurrencyCode_PurchAdvanceLetterHeader; "Currency Code")
            {
            }
            column(DocFooterText; DocFooterText)
            {
            }
            column(VendAddr1; VendAddr[1])
            {
            }
            column(VendAddr2; VendAddr[2])
            {
            }
            column(VendAddr3; VendAddr[3])
            {
            }
            column(VendAddr4; VendAddr[4])
            {
            }
            column(VendAddr5; VendAddr[5])
            {
            }
            column(VendAddr6; VendAddr[6])
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(CopyNo; CopyNo)
                {
                }
                dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
                {
                    DataItemLink = Code = FIELD("Purchaser Code");
                    DataItemLinkReference = "Purch. Advance Letter Header";
                    DataItemTableView = SORTING(Code);
                    column(Name_SalespersonPurchaser; Name)
                    {
                    }
                    column(EMail_SalespersonPurchaser; "E-Mail")
                    {
                    }
                    column(PhoneNo_SalespersonPurchaser; "Phone No.")
                    {
                    }
                }
                dataitem("Purch. Advance Letter Line"; "Purch. Advance Letter Line")
                {
                    DataItemLink = "Letter No." = FIELD("No.");
                    DataItemLinkReference = "Purch. Advance Letter Header";
                    DataItemTableView = SORTING("Letter No.", "Line No.");
                    column(LineNo_PurchAdvanceLetterLine; "Line No.")
                    {
                    }
                    column(Description_PurchAdvanceLetterLineCaption; FieldCaption(Description))
                    {
                    }
                    column(Description_PurchAdvanceLetterLine; Description)
                    {
                    }
                    column(AdvanceDueDate_PurchAdvanceLetterLineCaption; FieldCaption("Advance Due Date"))
                    {
                    }
                    column(AdvanceDueDate_PurchAdvanceLetterLine; "Advance Due Date")
                    {
                    }
                    column(VAT_PurchAdvanceLetterLineCaption; FieldCaption("VAT %"))
                    {
                    }
                    column(VAT_PurchAdvanceLetterLine; "VAT %")
                    {
                    }
                    column(AmountIncludingVAT_PurchAdvanceLetterLineCaption; FieldCaption("Amount Including VAT"))
                    {
                    }
                    column(AmountIncludingVAT_PurchAdvanceLetterLine; "Amount Including VAT")
                    {
                    }
                }
                dataitem("User Setup"; "User Setup")
                {
                    DataItemLinkReference = "Purch. Advance Letter Header";
                    DataItemTableView = SORTING("User ID");
                    dataitem(Employee; Employee)
                    {
#if not CLEAN18
                        DataItemLink = "No." = FIELD("Employee No.");
#endif
                        DataItemTableView = SORTING("No.");
                        column(FullName_Employee; Employee.FullName)
                        {
                        }
                        column(PhoneNo_Employee; Employee."Phone No.")
                        {
                        }
                        column(CompanyEMail_Employee; Employee."Company E-Mail")
                        {
                        }
                    }

                    trigger OnPreDataItem()
                    begin
                        SetRange("User ID", UserId);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        CopyNo := 1
                    else
                        CopyNo += 1;
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

                if "Currency Code" = '' then
                    "Currency Code" := "General Ledger Setup"."LCY Code";

                FormatAddr.FormatAddr(VendAddr, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
                  "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");

                FormatDocumentFields("Purch. Advance Letter Header");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        VATIdentLbl = 'VAT Recapitulation';
        VATPercentLbl = 'VAT %';
        VATBaseLbl = 'VAT Base';
        VATAmtLbl = 'VAT Amount';
    }

    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        CompanyAddr: array[8] of Text[100];
        VendAddr: array[8] of Text[100];
        DocFooterText: Text[250];
        NoOfCopies: Integer;
        CopyNo: Integer;
        NoOfLoops: Integer;
        DocumentLbl: Label 'Advance Letter';
        PageLbl: Label 'Page';
        CopyLbl: Label 'Copy';
        VendLbl: Label 'Vendor';
        CustLbl: Label 'Customer';
        PaymentTermsLbl: Label 'Payment Terms';
        PaymentMethodLbl: Label 'Payment Method';
        PurchaserLbl: Label 'Purchaser';
        TotalLbl: Label 'total';
        CreatorLbl: Label 'Posted by';

    local procedure FormatDocumentFields(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        with PurchAdvanceLetterHeader do begin
            FormatDocument.SetPaymentTerms(PaymentTerms, "Payment Terms Code", "Language Code");
            FormatDocument.SetPaymentMethod(PaymentMethod, "Payment Method Code", "Language Code");
        end;
    end;
}
#endif