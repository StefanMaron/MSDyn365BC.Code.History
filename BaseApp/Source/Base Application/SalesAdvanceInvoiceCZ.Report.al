report 31001 "Sales - Advance Invoice CZ"
{
    DefaultLayout = RDLC;
    RDLCLayout = './SalesAdvanceInvoiceCZ.rdlc';
    Caption = 'Sales - Advance Invoice CZ';
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
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
            DataItemTableView = SORTING("Letter No.") WHERE("Letter No." = FILTER(<> ''));
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
            column(SalespersonLbl; SalespersonLbl)
            {
            }
            column(CreatorLbl; CreatorLbl)
            {
            }
            column(VATIdentLbl; VATIdentLbl)
            {
            }
            column(VATPercentLbl; VATPercentLbl)
            {
            }
            column(VATBaseLbl; VATBaseLbl)
            {
            }
            column(VATAmtLbl; VATAmtLbl)
            {
            }
            column(TotalLbl; TotalLbl)
            {
            }
            column(VATLbl; VATLbl)
            {
            }
            column(AdvanceLetterLbl; AdvanceLetterLbl)
            {
            }
            column(No_SalesInvoiceHeader; "No.")
            {
            }
            column(VATRegistrationNo_SalesInvoiceHeaderCaption; FieldCaption("VAT Registration No."))
            {
            }
            column(VATRegistrationNo_SalesInvoiceHeader; "VAT Registration No.")
            {
            }
            column(RegistrationNo_SalesInvoiceHeaderCaption; FieldCaption("Registration No."))
            {
            }
            column(RegistrationNo_SalesInvoiceHeader; "Registration No.")
            {
            }
            column(BankAccountNo_SalesInvoiceHeaderCaption; FieldCaption("Bank Account No."))
            {
            }
            column(BankAccountNo_SalesInvoiceHeader; "Bank Account No.")
            {
            }
            column(IBAN_SalesInvoiceHeaderCaption; FieldCaption(IBAN))
            {
            }
            column(IBAN_SalesInvoiceHeader; IBAN)
            {
            }
            column(BIC_SalesInvoiceHeaderCaption; FieldCaption("SWIFT Code"))
            {
            }
            column(BIC_SalesInvoiceHeader; "SWIFT Code")
            {
            }
            column(DocumentDate_SalesInvoiceHeaderCaption; FieldCaption("Document Date"))
            {
            }
            column(DocumentDate_SalesInvoiceHeader; "Document Date")
            {
            }
            column(VATDate_SalesInvoiceHeaderCaption; FieldCaption("VAT Date"))
            {
            }
            column(VATDate_SalesInvoiceHeader; "VAT Date")
            {
            }
            column(PaymentTerms; PaymentTerms.Description)
            {
            }
            column(PaymentMethod; PaymentMethod.Description)
            {
            }
            column(CurrencyCode_SalesInvoiceHeader; "Currency Code")
            {
            }
            column(CalculatedExchRate; CalculatedExchRate)
            {
            }
            column(ExchRateText; ExchRateText)
            {
            }
            column(DocFooterText; DocFooterText)
            {
            }
            column(LetterNo_SalesInvoiiceHeader; "Letter No.")
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
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(CopyNo; CopyNo)
                {
                }
                dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
                {
                    DataItemLink = Code = FIELD("Salesperson Code");
                    DataItemLinkReference = "Sales Invoice Header";
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
                dataitem("VAT Entry"; "VAT Entry")
                {
                    DataItemLink = "Document No." = FIELD("No."), "Posting Date" = FIELD("Posting Date");
                    DataItemLinkReference = "Sales Invoice Header";
                    DataItemTableView = SORTING("Document No.", "Posting Date");

                    trigger OnAfterGetRecord()
                    begin
                        if not VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                            VATPostingSetup.Init();

                        TempVATAmountLine.Init();
                        TempVATAmountLine."VAT Identifier" := "VAT Identifier";
                        TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                        TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                        TempVATAmountLine."VAT %" := VATPostingSetup."VAT %";
                        TempVATAmountLine."VAT Base" := -"Advance Base";
                        TempVATAmountLine."Amount Including VAT" := -"Advance Base" - Amount;
                        TempVATAmountLine.InsertLine;
                    end;

                    trigger OnPreDataItem()
                    begin
                        TempVATAmountLine.DeleteAll();
                    end;
                }
                dataitem(VATCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(VATAmtLineVATIdentifier; TempVATAmountLine."VAT Identifier")
                    {
                    }
                    column(VATAmtLineVATPer; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(VATAmtLineVATBase; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Sales Invoice Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATAmt; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Sales Invoice Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATBaseLCY; TempVATAmountLine."VAT Base (LCY)")
                    {
                        AutoFormatExpression = "Sales Invoice Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATAmtLCY; TempVATAmountLine."VAT Amount (LCY)")
                    {
                        AutoFormatExpression = "Sales Invoice Header"."Currency Code";
                        AutoFormatType = 1;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);

                        if CalculatedExchRate <> 1 then begin
                            TempVATAmountLine."VAT Base (LCY)" := TempVATAmountLine."VAT Base";
                            TempVATAmountLine."VAT Amount (LCY)" := TempVATAmountLine."VAT Amount";
                            TempVATAmountLine."VAT Base" :=
                              Round(TempVATAmountLine."VAT Base (LCY)" / CalculatedExchRate * CurrExchRate."Exchange Rate Amount");
                            TempVATAmountLine."VAT Amount" :=
                              Round(TempVATAmountLine."VAT Amount (LCY)" / CalculatedExchRate * CurrExchRate."Exchange Rate Amount");
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TempVATAmountLine.Count);
                    end;
                }
                dataitem(VATClauseEntryCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(VATClauseIdentifier; TempVATAmountLine."VAT Identifier")
                    {
                    }
                    column(VATClauseDescription; VATClause.Description)
                    {
                    }
                    column(VATClauseDescription2; VATClause."Description 2")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);
                        if not VATClause.Get(TempVATAmountLine."VAT Clause Code") then
                            CurrReport.Skip();
                        VATClause.GetDescription("Sales Invoice Header");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TempVATAmountLine.Count);
                    end;
                }
                dataitem("User Setup"; "User Setup")
                {
                    DataItemLink = "User ID" = FIELD("User ID");
                    DataItemLinkReference = "Sales Invoice Header";
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
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        CopyNo := 1
                    else
                        CopyNo += 1;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode then
                        CODEUNIT.Run(CODEUNIT::"Sales Inv.-Printed", "Sales Invoice Header");
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

                DocFooter.SetFilter("Language Code", '%1|%2', '', "Language Code");
                if DocFooter.FindLast then
                    DocFooterText := DocFooter."Footer Text"
                else
                    DocFooterText := '';

                if "Currency Code" = '' then
                    "Currency Code" := "General Ledger Setup"."LCY Code";

                if ("Currency Factor" <> 0) and ("Currency Factor" <> 1) then begin
                    CurrExchRate.FindCurrency("Posting Date", "Currency Code", 1);
                    CalculatedExchRate := Round(1 / "Currency Factor" * CurrExchRate."Exchange Rate Amount", 0.00001);
                    ExchRateText :=
                      StrSubstNo(Text009Txt, CalculatedExchRate, "General Ledger Setup"."LCY Code",
                        CurrExchRate."Exchange Rate Amount", "Currency Code");
                end else
                    CalculatedExchRate := 1;

                FormatAddr.SalesInvBillTo(CustAddr, "Sales Invoice Header");
                if "Payment Terms Code" = '' then
                    PaymentTerms.Init
                else begin
                    PaymentTerms.Get("Payment Terms Code");
                    PaymentTerms.TranslateDescription(PaymentTerms, "Language Code");
                end;
                if "Payment Method Code" = '' then
                    PaymentMethod.Init
                else
                    PaymentMethod.Get("Payment Method Code");

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
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        CurrExchRate: Record "Currency Exchange Rate";
        DocFooter: Record "Document Footer";
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
        RegistrationCountryRegion: Record "Registration Country/Region";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        ExchRateText: Text[50];
        CompanyAddr: array[8] of Text[100];
        CustAddr: array[8] of Text[100];
        DocFooterText: Text[250];
        CalculatedExchRate: Decimal;
        NoOfCopies: Integer;
        CopyNo: Integer;
        NoOfLoops: Integer;
        Text009Txt: Label 'Exchange Rate %1 %2 / %3 %4', Comment = '%1=calculatedexchrate;%2=general ledger setup.LCY Code;%3=currexchrate.exchange rate amount;%4=currency code';
        DocumentLbl: Label 'VAT Document to Recieved Payment';
        PageLbl: Label 'Page';
        CopyLbl: Label 'Copy';
        VendLbl: Label 'Vendor';
        CustLbl: Label 'Customer';
        SalespersonLbl: Label 'Salesperson';
        CreatorLbl: Label 'Posted by';
        VATIdentLbl: Label 'VAT Recapitulation';
        VATPercentLbl: Label 'VAT %';
        VATBaseLbl: Label 'VAT Base';
        VATAmtLbl: Label 'VAT Amount';
        TotalLbl: Label 'total';
        VATLbl: Label 'VAT';
        AdvanceLetterLbl: Label 'VAT Document to Advance Letter';

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;
}

