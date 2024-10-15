report 31000 "Sales - Advance Letter CZ"
{
    DefaultLayout = RDLC;
    RDLCLayout = './SalesAdvanceLetterCZ.rdlc';
    Caption = 'Sales - Advance Letter CZ';
    PreviewMode = PrintLayout;

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
        dataitem("Sales Advance Letter Header"; "Sales Advance Letter Header")
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
            column(VendLbl; VendLbl)
            {
            }
            column(CustLbl; CustLbl)
            {
            }
            column(PaymentTermsLbl; PaymentTermsLbl)
            {
            }
            column(PaymentMethodLbl; PaymentMethodLbl)
            {
            }
            column(SalespersonLbl; SalespersonLbl)
            {
            }
            column(TotalLbl; TotalLbl)
            {
            }
            column(CreatorLbl; CreatorLbl)
            {
            }
            column(No_SalesAdvanceLetterHeader; "No.")
            {
            }
            column(VATRegistrationNo_SalesAdvanceLetterHeaderCaption; FieldCaption("VAT Registration No."))
            {
            }
            column(VATRegistrationNo_SalesAdvanceLetterHeader; "VAT Registration No.")
            {
            }
            column(RegistrationNo_SalesAdvanceLetterHeaderCaption; FieldCaption("Registration No."))
            {
            }
            column(RegistrationNo_SalesAdvanceLetterHeader; "Registration No.")
            {
            }
            column(BankAccountNo_SalesAdvanceLetterHeaderCaption; FieldCaption("Bank Account No."))
            {
            }
            column(BankAccountNo_SalesAdvanceLetterHeader; "Bank Account No.")
            {
            }
            column(IBAN_SalesAdvanceLetterHeaderCaption; FieldCaption(IBAN))
            {
            }
            column(IBAN_SalesAdvanceLetterHeader; IBAN)
            {
            }
            column(BIC_SalesAdvanceLetterHeaderCaption; FieldCaption("SWIFT Code"))
            {
            }
            column(BIC_SalesAdvanceLetterHeader; "SWIFT Code")
            {
            }
            column(DocumentDate_SalesAdvanceLetterHeaderCaption; FieldCaption("Document Date"))
            {
            }
            column(DocumentDate_SalesAdvanceLetterHeader; "Document Date")
            {
            }
            column(PmntSymbol1; PaymentSymbolLabel[1])
            {
            }
            column(PmntSymbol2; PaymentSymbol[1])
            {
            }
            column(PmntSymbol3; PaymentSymbolLabel[2])
            {
            }
            column(PmntSymbol4; PaymentSymbol[2])
            {
            }
            column(PaymentTerms; PaymentTerms.Description)
            {
            }
            column(PaymentMethod; PaymentMethod.Description)
            {
            }
            column(YourReference_SalesAdvancLetterHeaderCaption; FieldCaption("Your Reference"))
            {
            }
            column(YourReference_SalesAdvancLetterHeader; "Your Reference")
            {
            }
            column(CurrencyCode_SalesAdvanceLetterHeader; "Currency Code")
            {
            }
            column(DocFooterText; DocFooterText)
            {
            }
            column(PerformCountryRegionCode; RegistrationCountryRegion."Country/Region Code")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                ObsoleteTag = '15.3';
            }
            column(PerformVATRegistrationNo; RegistrationCountryRegion."VAT Registration No.")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                ObsoleteTag = '15.3';
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
            column(AdvanceDueDate_SalesAdvancLetterHeaderCaption; FieldCaption("Advance Due Date"))
            {
            }
            column(AdvanceDueDate_SalesAdvancLetterHeader; "Advance Due Date")
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
                    DataItemLink = Code = FIELD("Salesperson Code");
                    DataItemLinkReference = "Sales Advance Letter Header";
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
                dataitem("Sales Advance Letter Line"; "Sales Advance Letter Line")
                {
                    DataItemLink = "Letter No." = FIELD("No.");
                    DataItemLinkReference = "Sales Advance Letter Header";
                    DataItemTableView = SORTING("Letter No.", "Line No.");
                    column(LineNo_SalesAdvanceLetterLine; "Line No.")
                    {
                    }
                    column(Description_SalesAdvanceLetterLineCaption; FieldCaption(Description))
                    {
                    }
                    column(Description_SalesAdvanceLetterLine; Description)
                    {
                    }
                    column(VAT_SalesAdvanceLetterLineCaption; FieldCaption("VAT %"))
                    {
                    }
                    column(VAT_SalesAdvanceLetterLine; "VAT %")
                    {
                    }
                    column(AmountIncludingVAT_SalesAdvanceLetterLineCaption; FieldCaption("Amount Including VAT"))
                    {
                    }
                    column(AmountIncludingVAT_SalesAdvanceLetterLine; "Amount Including VAT")
                    {
                    }
                }
                dataitem("User Setup"; "User Setup")
                {
                    DataItemLinkReference = "Sales Advance Letter Header";
                    DataItemTableView = SORTING("User ID");
                    dataitem(Employee; Employee)
                    {
                        DataItemLink = "No." = FIELD("Employee No.");
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

                FormatDocumentFields("Sales Advance Letter Header");

                if "Currency Code" = '' then
                    "Currency Code" := "General Ledger Setup"."LCY Code";

                FormatAddr.FormatAddr(CustAddr, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");

                if not RegistrationCountryRegion.Get(
                     RegistrationCountryRegion."Account Type"::"Company Information", '', "Perform. Country/Region Code")
                then
                    Clear(RegistrationCountryRegion);
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
    }

    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
        RegistrationCountryRegion: Record "Registration Country/Region";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        CompanyAddr: array[8] of Text[100];
        CustAddr: array[8] of Text[100];
        DocFooterText: Text[250];
        PaymentSymbol: array[2] of Text;
        PaymentSymbolLabel: array[2] of Text;
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
        SalespersonLbl: Label 'Salesperson';
        TotalLbl: Label 'total';
        CreatorLbl: Label 'Posted by';

    local procedure FormatDocumentFields(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        with SalesAdvanceLetterHeader do begin
            FormatDocument.SetPaymentTerms(PaymentTerms, "Payment Terms Code", "Language Code");
            FormatDocument.SetPaymentMethod(PaymentMethod, "Payment Method Code", "Language Code");

            FormatDocument.SetPaymentSymbols(
              PaymentSymbol, PaymentSymbolLabel,
              "Variable Symbol", FieldCaption("Variable Symbol"),
              "Constant Symbol", FieldCaption("Constant Symbol"),
              "Specific Symbol", FieldCaption("Specific Symbol"));
            DocFooterText := FormatDocument.GetDocumentFooterText("Language Code");
        end;
    end;
}

