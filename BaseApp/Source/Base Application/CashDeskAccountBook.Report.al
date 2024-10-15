#if not CLEAN17
report 11741 "Cash Desk Account Book"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CashDeskAccountBook.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Desk Account Book (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            DataItemTableView = SORTING("No.") WHERE("Account Type" = CONST("Cash Desk"));
            column(Bank_Account_No; "No.")
            {
                IncludeCaption = true;
            }
            column(Bank_Account_Currency_Code; "Currency Code")
            {
                IncludeCaption = true;
            }
            column(Bank_Account_Name; Name)
            {
            }
            column(Variables_CompanyAddrCA_3; CompanyAddrCA[3])
            {
            }
            column(Variables_CompanyAddrCA_2; CompanyAddrCA[2])
            {
            }
            column(Variables_CompanyAddrCA_1; CompanyAddrCA[1])
            {
            }
            column(Variables_CashDeskFilter; CashDeskFilter)
            {
            }
            column(Variables_ShowLCY; Format(ShowLCY))
            {
            }
            column(Variables_ShowEntry; ShowEntry)
            {
            }
            column(Variables_EndDate; EndDate)
            {
            }
            column(Variables_StartDate; StartDate)
            {
            }
            column(System_Report_Id; CurrReport.ObjectId(false))
            {
            }
            column(Variables_ReceiptTotal; ReceiptTotal)
            {
            }
            column(Variables_PaymentTotal; PaymentTotal)
            {
            }
            column(Variables_BalanceToDate; BalanceToDate)
            {
            }
            dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
            {
                DataItemLink = "Bank Account No." = FIELD("No."), "Posting Date" = FIELD("Date Filter");
                DataItemTableView = SORTING("Entry No.");
                column(Bank_Account_Ledger_Entry_Posting_Date; "Posting Date")
                {
                    IncludeCaption = true;
                }
                column(Bank_Account_Ledger_Entry_External_Document_No; "External Document No.")
                {
                    IncludeCaption = true;
                }
                column(Bank_Account_Ledger_Entry_Description; Description)
                {
                    IncludeCaption = true;
                }
                column(Bank_Account_Ledger_Entry_Document_No; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Bank_Account_Ledger_Entry_Entry_No; "Entry No.")
                {
                }
                column(Bank_Account_Ledger_Entry_Bank_Account_No; "Bank Account No.")
                {
                }
                column(Variables_Balance; Balance)
                {
                }
                column(Variables_Receipt; Receipt)
                {
                }
                column(Variables_Payment; Payment)
                {
                }
                dataitem("Posted Cash Document Header"; "Posted Cash Document Header")
                {
                    DataItemLink = "No." = FIELD("Document No."), "Posting Date" = FIELD("Posting Date");
                    DataItemTableView = SORTING("No.", "Posting Date");
                    column(Posted_Cash_Document_Header_Cash_Desk_No; "Cash Desk No.")
                    {
                    }
                    column(Posted_Cash_Document_Header_No; "No.")
                    {
                    }
                    column(Posted_Cash_Document_Header_Posting_Date; "Posting Date")
                    {
                    }
                    dataitem("Posted Cash Document Line"; "Posted Cash Document Line")
                    {
                        DataItemLink = "Cash Desk No." = FIELD("Cash Desk No."), "Cash Document No." = FIELD("No.");
                        DataItemTableView = SORTING("Cash Desk No.", "Cash Document No.", "Line No.") ORDER(Ascending);
                        column(Posted_Cash_Document_Line_Cash_Desk_No; "Cash Desk No.")
                        {
                        }
                        column(Posted_Cash_Document_Line_Line_No; "Line No.")
                        {
                        }
                        column(Posted_Cash_Document_Line_Cash_Document_No; "Cash Document No.")
                        {
                        }
                        column(Posted_Cash_Document_Line_External_Document_No; "External Document No.")
                        {
                        }
                        column(Posted_Cash_Document_Line_Description; Description)
                        {
                        }
                        column(Variables_PostedReceipt; PostedReceipt)
                        {
                        }
                        column(Variables_PostedPayment; PostedPayment)
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                            Amt: Decimal;
                        begin
                            PostedReceipt := 0;
                            PostedPayment := 0;

                            if "Cash Document Type" = "Cash Document Type"::Withdrawal then begin
                                "Amount Including VAT (LCY)" *= -1;
                                "Amount Including VAT" *= -1;
                            end;

                            if ShowLCY then
                                Amt := "Amount Including VAT (LCY)"
                            else
                                Amt := "Amount Including VAT";

                            if Amt < 0 then
                                PostedPayment := Amt
                            else
                                PostedReceipt := Amt;
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        if not ShowEntry then
                            CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    Amt: Decimal;
                begin
                    Receipt := 0;
                    Payment := 0;

                    if ShowLCY then
                        Amt := "Amount (LCY)"
                    else
                        Amt := Amount;

                    if Amt < 0 then begin
                        Payment := Amt;
                        PaymentTotal += Amt;
                    end else begin
                        Receipt := Amt;
                        ReceiptTotal += Amt;
                    end;

                    Balance += Amt;
                end;

                trigger OnPreDataItem()
                begin
                    case Sorting of
                        Sorting::PostingDate:
                            SetCurrentKey("Bank Account No.", "Posting Date");
                        Sorting::CashDeskNo:
                            SetCurrentKey("Document No.");
                    end;

                    if (StartDate <> 0D) or (EndDate <> 0D) then
                        SetFilter("Posting Date", '%1..%2', StartDate, EndDate);
                    Balance := 0;
                    BalanceToDate := 0;

                    if StartDate <> 0D then begin
                        BankAccountLedgerEntry.Reset();
                        BankAccountLedgerEntry.SetCurrentKey("Bank Account No.");
                        BankAccountLedgerEntry.SetRange("Bank Account No.", "Bank Account"."No.");
                        if StartDate <> 0D then
                            BankAccountLedgerEntry.SetFilter("Posting Date", '..%1', CalcDate('<-1D>', StartDate));
                        BankAccountLedgerEntry.CalcSums(Amount, "Amount (LCY)");

                        if ShowLCY then
                            BalanceToDate := BankAccountLedgerEntry."Amount (LCY)"
                        else
                            BalanceToDate := BankAccountLedgerEntry.Amount;

                        Balance := BalanceToDate;
                    end;

                    ReceiptTotal := 0;
                    PaymentTotal := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Currency Code" = '' then
                    "Currency Code" := GLSetup."LCY Code";
            end;

            trigger OnPreDataItem()
            begin
                if (StartDate <> 0D) or (EndDate <> 0D) then
                    SetFilter("Date Filter", '%1..%2', StartDate, EndDate);

                if CashDeskNo <> '' then
                    SetRange("No.", CashDeskNo);

                if GetFilters <> '' then
                    CashDeskFilter := StrSubstNo('%1: %2', TableCaption, GetFilters);
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
                    field(CashDeskNo; CashDeskNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Desk No.';
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies the cash desk that the printed book will be drawn from.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            BankAcc: Record "Bank Account";
                        begin
                            if PAGE.RunModal(PAGE::"Cash Desk List", BankAcc) = ACTION::LookupOK then
                                CashDeskNo := BankAcc."No.";
                        end;

                        trigger OnValidate()
                        begin
                            CheckCashDeskNo(CashDeskNo);
                        end;
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the start date of cash desk account book.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closing Date';
                        ToolTip = 'Specifies the end date of cash desk account book.';
                    }
                    field(ShowEntry; ShowEntry)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Ledger Entry';
                        ToolTip = 'Specifies if you want notes about ledger entry to be shown on the report.';
                    }
                    field(ShowLCY; ShowLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
                    }
                    field(Sorting; Sorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorting';
                        OptionCaption = 'Posting Date,Cash Desk No.';
                        ToolTip = 'Specifies the method by which the entries are sorted on the report.';
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
        Label_Report_Name = 'Cash Desk Book';
        Label_Posted_Document = '(posted document)';
        Label_Page = 'Page No.';
        Label_ShowLCY = 'Show in LCY';
        Label_Initial_Condition = 'Initial Condition:';
        Label_Initial_Condition_LCY = 'Initial Condition in LCY:';
        Label_Positive_Adjmt = 'Positive Adjmt.';
        Label_Negative_Adjmt = 'Negative Adjmt.';
        Label_Balance = 'Balance';
        Label_Date_Filter = 'Date Filter:';
        Label_Total_Balance = 'Total Balance';
        Label_Date = 'Date';
        Label_Sign = 'Cash Sign';
    }

    trigger OnPreReport()
    begin
        if CashDeskNo = '' then
            Error(CashDeskCannotBeEmptyErr);

        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddrCA, CompanyInfo);

        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CompanyInfo: Record "Company Information";
        FormatAddr: Codeunit "Format Address";
        Balance: Decimal;
        BalanceToDate: Decimal;
        Receipt: Decimal;
        Payment: Decimal;
        ReceiptTotal: Decimal;
        PaymentTotal: Decimal;
        PostedReceipt: Decimal;
        PostedPayment: Decimal;
        CashDeskFilter: Text[250];
        CompanyAddrCA: array[8] of Text[150];
        Sorting: Option PostingDate,CashDeskNo;
        StartDate: Date;
        EndDate: Date;
        ShowEntry: Boolean;
        ShowLCY: Boolean;
        CashDeskNo: Code[20];
        CashDeskCannotBeEmptyErr: Label 'Cash Desk No. cannot be empty.';

    [Scope('OnPrem')]
    procedure InitializeRequest(NewCashDeskNo: Code[20]; NewStartDate: Date; NewEndDate: Date; NewShowEntry: Boolean; NewShowLCY: Boolean; NewSorting: Option PostingDate,CashDeskNo)
    begin
        CashDeskNo := NewCashDeskNo;
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        ShowEntry := NewShowEntry;
        ShowLCY := NewShowLCY;
        Sorting := NewSorting;
    end;

    local procedure CheckCashDeskNo(CashDeskNo: Code[20])
    var
        CashDeskManagement: Codeunit CashDeskManagement;
    begin
        CashDeskManagement.CheckCashDesk(CashDeskNo);
    end;
}
#endif