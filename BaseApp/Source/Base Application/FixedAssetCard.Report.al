report 31048 "Fixed Asset Card"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssetCard.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Fixed Asset Card';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
            {
            }
            column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
            {
            }
            column(CompanyAddr_6_; CompanyAddr[6])
            {
            }
            column(CompanyAddr_5_; CompanyAddr[5])
            {
            }
            column(CompanyAddr_4_; CompanyAddr[4])
            {
            }
            column(CompanyAddr_3_; CompanyAddr[3])
            {
            }
            column(CompanyAddr_2_; CompanyAddr[2])
            {
            }
            column(Fixed_Asset__Description_2_; "Description 2")
            {
            }
            column(Fixed_Asset_Description; Description)
            {
            }
            column(CompanyAddr_1_; CompanyAddr[1])
            {
            }
            column(Fixed_Asset__No__; "No.")
            {
            }
            column(CompanyInfo__Registration_No__; CompanyInfo."Registration No.")
            {
            }
            column(CompanyInfo__Tax_Registration_No__; CompanyInfo."Tax Registration No.")
            {
            }
            column(Fixed_Asset_Inactive; Format(Inactive))
            {
            }
            column(Employee_FullName; Employee.FullName)
            {
            }
            column(Fixed_Asset__Serial_No__; "Serial No.")
            {
            }
            column(Fixed_Asset__FA_Class_Code_; "FA Class Code")
            {
            }
            column(Fixed_Asset__FA_Subclass_Code_; "FA Subclass Code")
            {
            }
            column(FALocation_Name; FALocation.Name)
            {
            }
            column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
            {
            }
            column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
            {
            }
            column(Fixed_Asset_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Fixed_Asset__No__Caption; Fixed_Asset__No__CaptionLbl)
            {
            }
            column(Fixed_Asset_CardCaption; Fixed_Asset_CardCaptionLbl)
            {
            }
            column(CompanyInfo__Registration_No__Caption; CompanyInfo__Registration_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Tax_Registration_No__Caption; CompanyInfo__Tax_Registration_No__CaptionLbl)
            {
            }
            column(Employee_FullNameCaption; Employee_FullNameCaptionLbl)
            {
            }
            column(Fixed_Asset_InactiveCaption; FieldCaption(Inactive))
            {
            }
            column(Fixed_Asset__Serial_No__Caption; FieldCaption("Serial No."))
            {
            }
            column(Fixed_Asset__FA_Class_Code_Caption; FieldCaption("FA Class Code"))
            {
            }
            column(Fixed_Asset__FA_Subclass_Code_Caption; FieldCaption("FA Subclass Code"))
            {
            }
            column(FALocation_NameCaption; FALocation_NameCaptionLbl)
            {
            }
            column(Last_PageCaption; Last_PageCaptionLbl)
            {
            }
            dataitem("FA Depreciation Book"; "FA Depreciation Book")
            {
                DataItemLink = "FA No." = FIELD("No.");
                DataItemTableView = SORTING("FA No.", "Depreciation Book Code");
                RequestFilterFields = "Depreciation Book Code", "FA Posting Date Filter";
                column(DisposedText; DisposedText)
                {
                }
                column(FABook_Book_Value_on_Disposal; "Book Value on Disposal")
                {
                }
                column(FABook_Gain_Loss; "Gain/Loss")
                {
                }
                column(FABook_Proceeds_on_Disposal; "Proceeds on Disposal")
                {
                }
                column(FABook_Book_Value; "Book Value")
                {
                }
                column(FABook_Depreciation; Depreciation)
                {
                }
                column(FABook_Acquisition_Cost; "Acquisition Cost")
                {
                }
                column(FABook_Depreciation_Method; "Depreciation Method")
                {
                }
                column(FABook_Depreciation_Starting_Date; "Depreciation Starting Date")
                {
                }
                column(FABook_No__of_Depreciation_Years; "No. of Depreciation Years")
                {
                }
                column(FABook_Straight_Line; "Straight-Line %")
                {
                }
                column(FABook_Disposal_Date; "Disposal Date")
                {
                }
                column(FABook_Acquisition_Date; "Acquisition Date")
                {
                }
                column(FABook_FA_Posting_Date_Filter; "FA Depreciation Book".GetFilter("FA Posting Date Filter"))
                {
                }
                column(FABook_Depreciation_Book_Code; "Depreciation Book Code")
                {
                }
                column(FABook_ReceiptDate; ReceiptDate)
                {
                }
                column(FABook_Depreciation_Group_Code; "Depreciation Group Code")
                {
                }
                column(FABook_FA_Posting_Group; "FA Posting Group")
                {
                }
                column(FABook_Gain_Loss_Caption; FieldCaption("Gain/Loss"))
                {
                }
                column(FABook_Book_Value_on_Disposal_Caption; FieldCaption("Book Value on Disposal"))
                {
                }
                column(FABook_Proceeds_on_Disposal_Caption; FieldCaption("Proceeds on Disposal"))
                {
                }
                column(FABook_Book_Value_Caption; FieldCaption("Book Value"))
                {
                }
                column(FABook_DepreciationCaption; FieldCaption(Depreciation))
                {
                }
                column(FABook_Acquisition_Cost_Caption; FieldCaption("Acquisition Cost"))
                {
                }
                column(FABook_GETFILTER__FA_Posting_Date_Filter__Caption; FA_Depreciation_Book__GETFILTER__FA_Posting_Date_Filter__CaptionLbl)
                {
                }
                column(FABook_Acquisition_Date_Caption; FieldCaption("Acquisition Date"))
                {
                }
                column(FABook_Disposal_Date_Caption; FieldCaption("Disposal Date"))
                {
                }
                column(FABook_Depreciation_Method_Caption; FieldCaption("Depreciation Method"))
                {
                }
                column(FABook_Depreciation_Starting_Date_Caption; FieldCaption("Depreciation Starting Date"))
                {
                }
                column(FABook_No__of_Depreciation_Years_Caption; FieldCaption("No. of Depreciation Years"))
                {
                }
                column(FABook_Straight_Line___Caption; FieldCaption("Straight-Line %"))
                {
                }
                column(FABook_Depreciation_Book_Code_Caption; FA_Depreciation_Book__Depreciation_Book_Code_CaptionLbl)
                {
                }
                column(FABook_ReceiptDateCaption; ReceiptDateCaptionLbl)
                {
                }
                column(FABook_Depreciation_Group_Code_Caption; FieldCaption("Depreciation Group Code"))
                {
                }
                column(FABook_FA_Posting_Group_Caption; FieldCaption("FA Posting Group"))
                {
                }
                column(FABook_FA_No_; "FA No.")
                {
                }
                column(FABook_NoOfDepreciationMonths; "No. of Depreciation Months")
                {
                    IncludeCaption = true;
                }
                column(FABook_Appreciation; Appreciation)
                {
                    IncludeCaption = true;
                }
                column(FABook_BookValueAfterDisposalCaption; BookValueAfterDisposalLbl)
                {
                }
                column(FABook_BookValueAfterDisposal; BookValueAfterDisposal)
                {
                }
                dataitem("FA Ledger Entry"; "FA Ledger Entry")
                {
                    DataItemLink = "FA No." = FIELD("FA No."), "Depreciation Book Code" = FIELD("Depreciation Book Code");
                    DataItemTableView = SORTING("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date");
                    column(FA_Ledger_Entry__Credit_Amount_; "Credit Amount")
                    {
                    }
                    column(FA_Ledger_Entry__Debit_Amount_; "Debit Amount")
                    {
                    }
                    column(FA_Ledger_Entry_Amount; Amount)
                    {
                    }
                    column(FA_Ledger_Entry_Quantity; Quantity)
                    {
                    }
                    column(FA_Ledger_Entry__FA_Posting_Type_; "FA Posting Type")
                    {
                    }
                    column(FA_Ledger_Entry__FA_Posting_Category_; "FA Posting Category")
                    {
                    }
                    column(FA_Ledger_Entry__External_Document_No__; "External Document No.")
                    {
                    }
                    column(FA_Ledger_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(FA_Ledger_Entry__Document_Type_; "Document Type")
                    {
                    }
                    column(FA_Ledger_Entry__FA_Posting_Date_; Format("FA Posting Date"))
                    {
                    }
                    column(FA_Ledger_Entry__No__of_Depreciation_Days_; "No. of Depreciation Days")
                    {
                    }
                    column(CustVendText; CustVendText)
                    {
                    }
                    column(VendCustName; VendCustName)
                    {
                    }
                    column(VendCustName2; VendCustName2)
                    {
                    }
                    column(TotalText; TotalTxt)
                    {
                    }
                    column(FA_Ledger_Entry_Amount_Control1470088; Amount)
                    {
                    }
                    column(FA_Ledger_Entry__Debit_Amount__Control1470089; "Debit Amount")
                    {
                    }
                    column(FA_Ledger_Entry__Credit_Amount__Control1470090; "Credit Amount")
                    {
                    }
                    column(FA_Ledger_Entry__Credit_Amount_Caption; FieldCaption("Credit Amount"))
                    {
                    }
                    column(FA_Ledger_Entry__Debit_Amount_Caption; FieldCaption("Debit Amount"))
                    {
                    }
                    column(FA_Ledger_Entry_AmountCaption; FieldCaption(Amount))
                    {
                    }
                    column(FA_Ledger_Entry_QuantityCaption; FieldCaption(Quantity))
                    {
                    }
                    column(FA_Ledger_Entry__FA_Posting_Type_Caption; FieldCaption("FA Posting Type"))
                    {
                    }
                    column(FA_Ledger_Entry__FA_Posting_Category_Caption; FieldCaption("FA Posting Category"))
                    {
                    }
                    column(FA_Ledger_Entry__External_Document_No__Caption; FieldCaption("External Document No."))
                    {
                    }
                    column(FA_Ledger_Entry__Document_No__Caption; FieldCaption("Document No."))
                    {
                    }
                    column(FA_Ledger_Entry__Document_Type_Caption; FieldCaption("Document Type"))
                    {
                    }
                    column(FA_Ledger_Entry__FA_Posting_Date_Caption; FieldCaption("FA Posting Date"))
                    {
                    }
                    column(FA_Depr__DaysCaption; FA_Depr__DaysCaptionLbl)
                    {
                    }
                    column(FA_Ledger_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(FA_Ledger_Entry_FA_No_; "FA No.")
                    {
                    }
                    column(FA_Ledger_Entry_Depreciation_Book_Code; "Depreciation Book Code")
                    {
                    }
                    column(FA_Ledger_Entry_HideCustVend; not ShowCustVend)
                    {
                    }
                    column(FA_Ledger_Entry_FAPostTypeGroup; FAPostTypeGroup)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        VendCustName := '';
                        VendCustName2 := '';
                        ShowCustVend := false;
                        if SalesInvoiceHeader.Get("Document No.") then begin
                            VendCustName := SalesInvoiceHeader."Sell-to Customer Name";
                            VendCustName2 := SalesInvoiceHeader."Sell-to Customer Name 2";
                            ShowCustVend := true;
                            CustVendText := CustNameLbl;
                        end;
                        if PurchInvHeader.Get("Document No.") then begin
                            VendCustName := PurchInvHeader."Buy-from Vendor Name";
                            VendCustName2 := PurchInvHeader."Buy-from Vendor Name 2";
                            ShowCustVend := true;
                            CustVendText := VendNameLbl;
                        end;
                        ShowCustVend := (ShowCustVend and
                                         (("FA Posting Type" = "FA Posting Type"::"Acquisition Cost") or
                                          ("FA Posting Type" = "FA Posting Type"::"Proceeds on Disposal")));

                        case "FA Posting Type" of
                            "FA Posting Type"::"Custom 2":
                                FAPostTypeGroup := 1;
                            "FA Posting Type"::"Acquisition Cost":
                                FAPostTypeGroup := 2;
                            "FA Posting Type"::Appreciation:
                                FAPostTypeGroup := 3;
                            "FA Posting Type"::"Write-Down":
                                FAPostTypeGroup := 4;
                            "FA Posting Type"::Depreciation:
                                FAPostTypeGroup := 5;
                            "FA Posting Type"::"Custom 1":
                                FAPostTypeGroup := 6;
                            "FA Posting Type"::"Book Value on Disposal":
                                FAPostTypeGroup := 7;
                            "FA Posting Type"::"Proceeds on Disposal":
                                FAPostTypeGroup := 8;
                            "FA Posting Type"::"Salvage Value":
                                FAPostTypeGroup := 9;
                            "FA Posting Type"::"Gain/Loss":
                                FAPostTypeGroup := 10;
                            else
                                FAPostTypeGroup := 99;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowEntries then
                            CurrReport.Break();

                        SetFilter("FA Posting Date", "FA Depreciation Book".GetFilter("FA Posting Date Filter"));
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    FALedgerEntry: Record "FA Ledger Entry";
                begin
                    Disposed := "Disposal Date" > 0D;
                    if Disposed then
                        DisposedText := DispTxt
                    else
                        DisposedText := NotDispTxt;

                    ReceiptDate := 0D;

                    FASetup.Get();
                    if FASetup."FA Acquisition As Custom 2" then begin
                        FALedgerEntry.Reset();
                        FALedgerEntry.SetCurrentKey(
                          "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date");
                        FALedgerEntry.SetRange("FA No.", "FA No.");
                        FALedgerEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                        FALedgerEntry.SetRange("FA Posting Category", FALedgerEntry."FA Posting Category"::" ");
                        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Custom 2");
                        if FALedgerEntry.FindLast then
                            ReceiptDate := FALedgerEntry."FA Posting Date"
                        else begin
                            FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
                            if FALedgerEntry.FindLast then
                                ReceiptDate := FALedgerEntry."FA Posting Date";
                        end;
                    end else begin
                        FALedgerEntry.Reset();
                        FALedgerEntry.SetCurrentKey(
                          "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date");
                        FALedgerEntry.SetRange("FA No.", "FA No.");
                        FALedgerEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                        FALedgerEntry.SetRange("FA Posting Category", FALedgerEntry."FA Posting Category"::" ");
                        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
                        if FALedgerEntry.FindLast then
                            ReceiptDate := FALedgerEntry."FA Posting Date";
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not Location.Get("Location Code") then
                    Location.Init();
                if not FALocation.Get("FA Location Code") then
                    FALocation.Init();
                if not Employee.Get("Responsible Employee") then
                    Employee.Init();
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);
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
                    field(ShowEntries; ShowEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Entries';
                        ToolTip = 'Specifies when the entries is to be show';
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
        CompanyInfo: Record "Company Information";
        Location: Record Location;
        FALocation: Record "FA Location";
        Employee: Record Employee;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        FASetup: Record "FA Setup";
        FormatAddr: Codeunit "Format Address";
        Disposed: Boolean;
        ShowCustVend: Boolean;
        DisposedText: Text[30];
        CompanyAddr: array[8] of Text[100];
        VendCustName: Text[100];
        VendCustName2: Text[50];
        CustVendText: Text[100];
        ReceiptDate: Date;
        NotDispTxt: Label 'Not Disposed Of';
        DispTxt: Label 'Disposed Of';
        CustNameLbl: Label 'Customer Name: ';
        VendNameLbl: Label 'Vendor Name: ';
        TotalTxt: Label 'Total';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        Fixed_Asset__No__CaptionLbl: Label 'Fixed Asset No.';
        Fixed_Asset_CardCaptionLbl: Label 'Fixed Asset Card';
        CompanyInfo__Registration_No__CaptionLbl: Label 'Reg. No.';
        CompanyInfo__Tax_Registration_No__CaptionLbl: Label 'Tax Reg. No.';
        Employee_FullNameCaptionLbl: Label 'Responsible Employee';
        FALocation_NameCaptionLbl: Label 'FA Location';
        Last_PageCaptionLbl: Label 'Last Page';
        FA_Depreciation_Book__GETFILTER__FA_Posting_Date_Filter__CaptionLbl: Label 'Period';
        FA_Depreciation_Book__Depreciation_Book_Code_CaptionLbl: Label 'FA Depreciation Book';
        ReceiptDateCaptionLbl: Label 'Receipt Date';
        FA_Depr__DaysCaptionLbl: Label 'FA Depr. Days';
        ShowEntries: Boolean;
        BookValueAfterDisposalLbl: Label 'Book Value after Disposal';
        BookValueAfterDisposal: Decimal;
        AcquisitionDateCustom2Lbl: Label 'Acquisition Date Custom2';
        FAPostTypeGroup: Integer;
}

