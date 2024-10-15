report 11787 "Vendor - Bal. Reconciliation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VendorBalReconciliation.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Bal. Reconciliation (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Print Statements", Blocked;
            column(Vendor__Last_Statement_No__; "Last Statement No.")
            {
            }
            column(WORKDATE__; Format(WorkDate))
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(CompanyInfo_Name; CompanyInfo.Name)
            {
            }
            column(Vendor_Address; Address)
            {
            }
            column(Vendor_City; City)
            {
            }
            column(Vendor__Post_Code_; "Post Code")
            {
            }
            column(CompanyInfo_Address; CompanyInfo.Address)
            {
            }
            column(CompanyInfo_City; CompanyInfo.City)
            {
            }
            column(CompanyInfo__Post_Code_; CompanyInfo."Post Code")
            {
            }
            column(Vendor__Phone_No__; "Phone No.")
            {
            }
            column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
            {
            }
            column(Vendor__Fax_No__; "Fax No.")
            {
            }
            column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
            {
            }
            column(Vendor__E_Mail_; "E-Mail")
            {
            }
            column(CompanyInfo__E_Mail_; CompanyInfo."E-Mail")
            {
            }
            column(Vendor__VAT_Registration_No__; "VAT Registration No.")
            {
            }
            column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompanyInfo_Name_Control1470080; CompanyInfo.Name)
            {
            }
            column(STRSUBSTNO_Text003_LongReconcileDate_; StrSubstNo(Text003, LongReconcileDate))
            {
            }
            column(CompanyInfo_Name_Control1470088; CompanyInfo.Name)
            {
            }
            column(Vendor_Vendor_Name; Vendor.Name)
            {
            }
            column(CompanyInfo__Registration_No__; CompanyInfo."Registration No.")
            {
            }
            column(CompanyInfo__Tax_Registration_No__; CompanyInfo."Tax Registration No.")
            {
            }
            column(Vendor__Registration_No__; "Registration No.")
            {
            }
            column(Vendor__Tax_Registration_No__; "Tax Registration No.")
            {
            }
            column(CompanyInfo_GetDocFooter__Language_Code__; CompanyInfo.GetDocFooter("Language Code"))
            {
            }
            column(DOCUMENT_No_Caption; DOCUMENT_No_CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(For_mutual_balance_reconcile_betweenCaption; For_mutual_balance_reconcile_betweenCaptionLbl)
            {
            }
            column(andCaption; andCaptionLbl)
            {
            }
            column(Vendor__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
            column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
            {
            }
            column(Vendor__Fax_No__Caption; FieldCaption("Fax No."))
            {
            }
            column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
            {
            }
            column(Vendor__E_Mail_Caption; FieldCaption("E-Mail"))
            {
            }
            column(CompanyInfo__E_Mail_Caption; CompanyInfo__E_Mail_CaptionLbl)
            {
            }
            column(Vendor__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
            {
            }
            column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
            {
            }
            column(In_accordance_with_data_ofCaption; In_accordance_with_data_ofCaptionLbl)
            {
            }
            column(In_accordance_with_data_ofCaption_Control1470084; In_accordance_with_data_ofCaption_Control1470084Lbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(DebitCaption_Control1470090; DebitCaption_Control1470090Lbl)
            {
            }
            column(CreditCaption_Control1470091; CreditCaption_Control1470091Lbl)
            {
            }
            column(CompanyInfo__Registration_No__Caption; CompanyInfo__Registration_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Tax_Registration_No__Caption; CompanyInfo__Tax_Registration_No__CaptionLbl)
            {
            }
            column(Vendor__Registration_No__Caption; FieldCaption("Registration No."))
            {
            }
            column(Vendor__Tax_Registration_No__Caption; FieldCaption("Tax Registration No."))
            {
            }
            column(Customer_TotalAmountLCY; TotalAmountLCY)
            {
            }
            column(DoNotPrintDetails; (TotalAmountLCY = 0) and CVLedgEntry.IsEmpty or (not PrintDetails))
            {
            }
            column(Vendor_No_; "No.")
            {
            }
            column(CustomerCaptionLabel; CustomerCaption)
            {
            }
            column(VendorCaptionLabel; VendorCaption)
            {
            }
            column(SubjectText; StrSubstNo(SubjectText, Format(ReconcileDate, 0, DateFormatTxt)))
            {
            }
            column(HeaderText1; HeaderText1)
            {
            }
            column(HeaderText2; StrSubstNo(HeaderText2, Format(ReconcileDate, 0, DateFormatTxt)))
            {
            }
            column(ConfirmationText1; StrSubstNo(ConfirmationText1, Format(ReturnDate, 0, DateFormatTxt)))
            {
            }
            column(CityAndDate; StrSubstNo(CityOnDate, CompanyInfo.City, Format(ReconcileDate, 0, DateFormatTxt)))
            {
            }
            column(ConfirmationText2; StrSubstNo(ConfirmationText2, Format(ReconcileDate, 0, DateFormatTxt)))
            {
            }
            column(AppendixText; AppendixText)
            {
            }
            column(ForCompany; StrSubstNo(ForCompany, CompanyInfo.Name))
            {
            }
            column(ForCompanyConfirms; StrSubstNo(ForCompanyConfirms, Vendor.Name))
            {
            }
            column(AndLabel; andCaptionLbl)
            {
            }
            column(AppendixHeaderText; StrSubstNo(AppendixHeaderText, Format(ReconcileDate, 0, DateFormatTxt)))
            {
            }
            column(ResponsibleEmployee; ResponsibleEmployee)
            {
            }
            dataitem(TotalInCurrency; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(DebitAmount; DebitAmount)
                {
                }
                column(CreditAmount; CreditAmount)
                {
                }
                column(STRSUBSTNO_Text011_GetCurrCode_CurrencyBuf_Code__; StrSubstNo(Text011, GetCurrCode(CurrencyBuf.Code)))
                {
                }
                column(TotalInCurrency_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        CurrencyBuf.FindSet
                    else
                        CurrencyBuf.Next;

                    if PrintAmountsInCurrency then begin
                        TotalAmount := CVMgt.CalcCVDebt(CustomerNo, Vendor."No.", CurrencyBuf.Code, ReconcileDate, false);
                        CalcDebitCredit(TotalAmount);
                    end else
                        CalcDebitCredit(TotalAmountLCY);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, CurrencyBuf.Count);
                end;
            }
            dataitem(Footer; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(STRSUBSTNO_Text004_ReconcileDate_ReturnDate_; StrSubstNo(Text004, ReconcileDate, ReturnDate))
                {
                }
                column(STRSUBSTNO_Text005_CompanyInfo_Address_CompanyInfo_City_CompanyInfo__Post_Code__; StrSubstNo(Text005, CompanyInfo.Address, CompanyInfo.City, CompanyInfo."Post Code"))
                {
                }
                column(STRSUBSTNO_Text006_CompanyInfo__Fax_No___; StrSubstNo(Text006, CompanyInfo."Fax No."))
                {
                }
                column(STRSUBSTNO_Text007_ReturnDate____Text008___STRSUBSTNO_Text009_CompanyInfo__Phone_No___; StrSubstNo(Text007, ReturnDate) + Text008 + StrSubstNo(Text009, CompanyInfo."Phone No."))
                {
                }
                column(CompanyInfo_Name_Control1470112; CompanyInfo.Name)
                {
                }
                column(ChiefAccountant_FullName__; ChiefAccountant.FullName())
                {
                }
                column(Vendor_Name_Control1470121; Vendor.Name)
                {
                }
                column(AccountantCaption; AccountantCaptionLbl)
                {
                }
                column(AccountantCaption_Control1470127; AccountantCaption_Control1470127Lbl)
                {
                }
                column(Name_Caption; Name_CaptionLbl)
                {
                }
                column(Name_Caption_Control1470129; Name_Caption_Control1470129Lbl)
                {
                }
                column(Signature_Caption; Signature_CaptionLbl)
                {
                }
                column(Signature_Caption_Control1470134; Signature_Caption_Control1470134Lbl)
                {
                }
                column(Footer_Number; Number)
                {
                }
            }
            dataitem(Currencies; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(WORKDATE___Control1470018; Format(WorkDate))
                {
                }
                column(Vendor_Name_Control1470033; Vendor.Name)
                {
                }
                column(CompanyInfo_Name_Control1470034; CompanyInfo.Name)
                {
                }
                column(STRSUBSTNO_Text013_GetCurrCode_CurrencyBuf_Code__; StrSubstNo(Text013, GetCurrCode(CurrencyBuf.Code)))
                {
                }
                column(andCaption_Control1470004; andCaption_Control1470004Lbl)
                {
                }
                column(AmountCaption; AmountCaptionLbl)
                {
                }
                column(Currency_CodeCaption; Currency_CodeCaptionLbl)
                {
                }
                column(Document_No_Caption_Control1470060; Document_No_Caption_Control1470060Lbl)
                {
                }
                column(Document_TypeCaption; Document_TypeCaptionLbl)
                {
                }
                column(Document_DateCaption; Document_DateCaptionLbl)
                {
                }
                column(Remaining_AmountCaption; Remaining_AmountCaptionLbl)
                {
                }
                column(Due_DateCaption; Due_DateCaptionLbl)
                {
                }
                column(Remaining_Amt___LCY_Caption; StrSubstNo(Remaining_AmtLCY, GLSetup."LCY Code"))
                {
                }
                column(Currencies_Number; Number)
                {
                }
                column(ExtDocNoCaption; CVLedgEntry.FieldCaption("External Document No."))
                {
                }
                dataitem(CVLedgEntryBuf; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    column(CVLedgEntry__Document_Date_; Format(CVLedgEntry."Document Date"))
                    {
                    }
                    column(FORMAT_CVLedgEntry__Document_Type__; Format(CVLedgEntry."Document Type"))
                    {
                    }
                    column(CVLedgEntry__Currency_Code_; CVLedgEntry."Currency Code")
                    {
                    }
                    column(CVLedgEntry__Due_Date_; Format(CVLedgEntry."Due Date"))
                    {
                    }
                    column(CVLedgEntry_Amount; CVLedgEntry.Amount)
                    {
                    }
                    column(CVLedgEntry__Remaining_Amount_; CVLedgEntry."Remaining Amount")
                    {
                    }
                    column(CVLedgEntry__Remaining_Amt___LCY__; CVLedgEntry."Remaining Amt. (LCY)")
                    {
                    }
                    column(CVLedgEntry__Document_No__; CVLedgEntry."Document No.")
                    {
                    }
                    column(CVLedgEntryBuf_Number; Number)
                    {
                    }
                    column(CVLedgEntry_ExtDocNo; CVLedgEntry."External Document No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            CVLedgEntry.FindSet
                        else
                            CVLedgEntry.Next;
                    end;

                    trigger OnPreDataItem()
                    begin
                        CVLedgEntry.SetCurrentKey("Document Date");
                        if PrintAmountsInCurrency then
                            CVLedgEntry.SetFilter("Currency Code", '%1', CurrencyBuf.Code);

                        SetRange(Number, 1, CVLedgEntry.Count);
                    end;
                }
                dataitem(Total; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(STRSUBSTNO_Text012_GetCurrCode_CurrencyBuf_Code__; StrSubstNo(Text012, GetCurrCode(CurrencyBuf.Code)))
                    {
                    }
                    column(TotalAmount; TotalAmount)
                    {
                    }
                    column(Total_Number; Number)
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if not PrintAmountsInCurrency or LCYEntriesOnly then
                            CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        CurrencyBuf.FindSet
                    else
                        CurrencyBuf.Next;

                    LCYEntriesOnly := (CurrencyBuf.Code = '') and (CurrencyBuf.Count = 1);
                    if PrintAmountsInCurrency then begin
                        TotalAmount := CVMgt.CalcCVDebt(CustomerNo, Vendor."No.", CurrencyBuf.Code, ReconcileDate, false);
                        if PrintAmountsInCurrency then
                            CVLedgEntry.SetFilter("Currency Code", '%1', CurrencyBuf.Code);
                        if (TotalAmount = 0) and CVLedgEntry.IsEmpty() then
                            CurrReport.Skip();
                    end else
                        TotalAmount := TotalAmountLCY;
                end;

                trigger OnPreDataItem()
                begin
                    if (TotalAmountLCY = 0) and CVLedgEntry.IsEmpty or (not PrintDetails) then
                        CurrReport.Break();

                    SetRange(Number, 1, CurrencyBuf.Count);
                end;
            }
            dataitem(TotalLCY; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(STRSUBSTNO_Text012_Text014_; StrSubstNo(Text012, GLSetup."LCY Code"))
                {
                }
                column(TotalAmountLCY; TotalAmountLCY)
                {
                }
                column(TotalLCY_Number; Number)
                {
                }

                trigger OnPreDataItem()
                begin
                    CVLedgEntry.Reset();
                    if (TotalAmountLCY = 0) and CVLedgEntry.IsEmpty or (not PrintDetails) then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                if not CurrReport.Preview then begin
                    LockTable();
                    Find;
                    "Last Statement No." += 1;
                    "Last Statement Date" := Today;
                    Modify;
                    Commit();
                end else
                    "Last Statement No." += 1;

                if IncludeCustDebts then
                    CustomerNo := GetLinkedCustomer
                else
                    CustomerNo := '';

                TotalAmountLCY := CVMgt.CalcCVDebt(CustomerNo, "No.", '', ReconcileDate, true);

                if PrintOnlyNotZero and (TotalAmountLCY = 0) then
                    CurrReport.Skip();

                CalcDebitCredit(TotalAmountLCY);

                CVMgt.FillCVBuffer(CurrencyBuf, CVLedgEntry, CustomerNo, "No.", ReconcileDate, PrintAmountsInCurrency);

                ResponsibleEmployee := GetFormattedResponsibleEmployee;
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
                    field(ReturnDate; ReturnDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Return Date';
                        ToolTip = 'Specifies the date that the statement must be returned';
                    }
                    field(ReconcileDate; ReconcileDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reconcile Date';
                        ToolTip = 'Specifies reconcile date. This date will be used to calculate debt that is before and equal to the reconcile date';
                    }
                    field(IncludeCustDebts; IncludeCustDebts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Customer Debts';
                        ToolTip = 'Specifies to indicate that vendor debt must be subtracted from customer debt.';
                    }
                    field(PrintDetails; PrintDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Details';
                        ToolTip = 'Specifies to indicate that detailed documents will print.';
                    }
                    field(PrintOnlyNotZero; PrintOnlyNotZero)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Only Not Zero';
                        ToolTip = 'Specifies to indicate that only vendors with debt greater than zero will be printed.';
                    }
                    field(PrintAmountsInCurrency; PrintAmountsInCurrency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Amounts In Currency';
                        ToolTip = 'Specifies to indicate that the report must show vendor debt in the original currency.';
                    }
                    field(EmployeeNo; EmployeeNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Responsible Employee No.';
                        TableRelation = Employee;
                        ToolTip = 'Specifies which emloyee prints the report';
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

    trigger OnPreReport()
    begin
        if ReturnDate = 0D then
            Error(EmptyReturnDateErr);
        if ReconcileDate = 0D then
            Error(EmptyReconcileDateErr);

        GLSetup.Get();
        CompanyInfo.Get();
        LongReconcileDate := Format(ReconcileDate);
        if ChiefAccountant.Get(CompanyInfo."Accounting Manager No.") then;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        CurrencyBuf: Record Currency temporary;
        CVLedgEntry: Record "CV Ledger Entry Buffer" temporary;
        ChiefAccountant: Record "Company Officials";
        Employee: Record Employee;
        Language: Codeunit Language;
        CVMgt: Codeunit CustVendManagement;
        ReturnDate: Date;
        ReconcileDate: Date;
        PrintOnlyNotZero: Boolean;
        PrintAmountsInCurrency: Boolean;
        CustomerNo: Code[20];
        LongReconcileDate: Text[30];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
        LCYEntriesOnly: Boolean;
        IncludeCustDebts: Boolean;
        PrintDetails: Boolean;
        EmployeeNo: Code[20];
        ResponsibleEmployee: Text;
        EmptyReturnDateErr: Label 'You must specify return date.';
        EmptyReconcileDateErr: Label 'You must specify reconcile date.';
        Text003: Label 'ask You to confirm our company mutual balances at %1';
        Text004: Label 'Please confirm balance at %1 and return to us until %2';
        Text005: Label 'To our address %1, %2, %3';
        Text006: Label 'Or to fax %1';
        Text007: Label 'If we don''t receive your answer until %1, we suppose you accept balance mentioned in this document.';
        Text008: Label ' If You find any differences in the balance, we kindly ask you to add comments and explanations.';
        Text009: Label ' If you have any question, please call to our accountant by phone %1.';
        Text011: Label 'Final balance amount in %1';
        Text012: Label 'Total %1';
        Text013: Label 'Open documents in details %1';
        DOCUMENT_No_CaptionLbl: Label 'DOCUMENT No.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        For_mutual_balance_reconcile_betweenCaptionLbl: Label 'For mutual balance reconcile between';
        andCaptionLbl: Label 'and';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__E_Mail_CaptionLbl: Label 'E-Mail';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Registration No.';
        In_accordance_with_data_ofCaptionLbl: Label 'In accordance with data of';
        In_accordance_with_data_ofCaption_Control1470084Lbl: Label 'In accordance with data of';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        DebitCaption_Control1470090Lbl: Label 'Debit';
        CreditCaption_Control1470091Lbl: Label 'Credit';
        CompanyInfo__Registration_No__CaptionLbl: Label 'Registration No.';
        CompanyInfo__Tax_Registration_No__CaptionLbl: Label 'Tax Registration No.';
        AccountantCaptionLbl: Label 'Accountant';
        AccountantCaption_Control1470127Lbl: Label 'Accountant';
        Name_CaptionLbl: Label '(Name)';
        Name_Caption_Control1470129Lbl: Label '(Name)';
        Signature_CaptionLbl: Label '(Signature)';
        Signature_Caption_Control1470134Lbl: Label '(Signature, Stamp)';
        andCaption_Control1470004Lbl: Label 'and';
        AmountCaptionLbl: Label 'Amount';
        Currency_CodeCaptionLbl: Label 'Currency Code';
        Document_No_Caption_Control1470060Lbl: Label 'Document No.';
        Document_TypeCaptionLbl: Label 'Document Type';
        Document_DateCaptionLbl: Label 'Document Date';
        Remaining_AmountCaptionLbl: Label 'Remaining Amount';
        Due_DateCaptionLbl: Label 'Due Date';
        CustomerCaption: Label 'Customer';
        VendorCaption: Label 'Vendor';
        SubjectText: Label 'Subject: Payables reconcilitation at %1';
        HeaderText1: Label 'In accordance with par. 29 of the Act No. 563/1991 Coll. on Accounting as amended';
        HeaderText2: Label 'We ask you to agree and confirm the status of our payables on %1';
        ConfirmationText1: Label 'Please confirm your balance to %1. If we do not receive your reply within that period, we will consider receivables status approved.';
        CityOnDate: Label '%1 on %2:';
        ForCompany: Label 'For company %1:';
        ForCompanyConfirms: Label 'For company %1 confirms:';
        ConfirmationText2: Label 'We acknowledge our receivables on %1 to the payee as to the reason and amount';
        AppendixText: Label 'from the documents listed in the appendix, which forms an integral part of this document.';
        AppendixHeaderText: Label 'Appendix to the reconciliation of payables on %1 between';
        ResponsibleEmployeeLbl: Label 'Responsible Employee: %1';
        Remaining_AmtLCY: Label 'Remaining Amt. (%1)';
        DateFormatTxt: Label '<Day>.<Month>.<Year4>', Locked = true;

    [Scope('OnPrem')]
    procedure CalcDebitCredit(TotalAmt: Decimal)
    begin
        TotalAmount := TotalAmt;
        if TotalAmount < 0 then begin
            CreditAmount := -TotalAmount;
            DebitAmount := 0;
        end else begin
            CreditAmount := 0;
            DebitAmount := TotalAmount;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCurrCode("Code": Code[10]): Code[10]
    begin
        if Code = '' then
            exit(GLSetup."LCY Code");
        exit(Code);
    end;

    local procedure GetFormattedResponsibleEmployee(): Text
    var
        FormattedEmployee: Text;
    begin
        if EmployeeNo = '' then
            exit;

        if EmployeeNo <> Employee."No." then
            Employee.Get(EmployeeNo);

        FormattedEmployee := Employee.FullName;

        AddFieldInfoToCommaSeparatedText(Employee.FieldCaption("Phone No."), Employee."Phone No.", FormattedEmployee);
        AddFieldInfoToCommaSeparatedText(Employee.FieldCaption("E-Mail"), Employee."E-Mail", FormattedEmployee);

        if FormattedEmployee <> '' then
            FormattedEmployee := StrSubstNo(ResponsibleEmployeeLbl, FormattedEmployee);

        exit(FormattedEmployee);
    end;

    local procedure AddFieldInfoToCommaSeparatedText(FieldCaption: Text; FieldValue: Text; var CommaSeparatedText: Text)
    begin
        if FieldValue = '' then
            exit;

        if CommaSeparatedText <> '' then
            CommaSeparatedText := StrSubstNo('%1, %2: %3', CommaSeparatedText, FieldCaption, FieldValue)
        else
            CommaSeparatedText := StrSubstNo('%1: %2', FieldCaption, FieldValue);
    end;
}

