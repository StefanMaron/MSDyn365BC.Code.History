report 18929 "Day Book"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/report/rdlc/DayBook.rdl';
    Caption = 'Day Book';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = Basic, Suite;

    dataset
    {
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = sorting("Posting Date", "Transaction No.");
            RequestFilterFields = "Posting Date", "Document No.", "Global Dimension 1 Code", "Global Dimension 2 Code";

            column(TodayFormatted; FORMAT(TODAY(), 0, 4))
            {
            }
            column(Time; TIME())
            {
            }
            column(CompinfoName; Compinfo.Name)
            {
            }
            column(GetFilters; GETFILTERS())
            {
            }
            column(DebitAmount_GLEntry; "Debit Amount")
            {
            }
            column(CreditAmount_GLEntry; "Credit Amount")
            {
            }
            column(GLAccName; GLAccName)
            {
            }
            column(DocNo; DocNo)
            {
            }
            column(PostingDate_GLEntry; FORMAT(PostingDate))
            {
            }
            column(SourceDesc; SourceDesc)
            {
            }
            column(EntryNo_GLEntry; "Entry No.")
            {
            }
            column(TransactionNo_GLEntry; "Transaction No.")
            {
            }
            column(DayBookCaption; DayBookCaptionLbl)
            {
            }
            column(DocumentNoCaption; DocumentNoCaptionLbl)
            {
            }
            column(AccountNameCaption; AccountNameCaptionLbl)
            {
            }
            column(DebitAmountCaption; DebitAmountCaptionLbl)
            {
            }
            column(CreditAmountCaption; CreditAmountCaptionLbl)
            {
            }
            column(VoucherTypeCaption; VoucherTypeCaptionLbl)
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(TransDebits; TransDebits)
            {
            }
            column(TransCredits; TransCredits)
            {
            }
            dataitem(PostedNarration; "Posted Narration")
            {
                DataItemLink = "Entry No." = field("Entry No.");
                DataItemTableView = sorting("Entry No.", "Transaction No.", "Line No.")
                                         ORDER(ascending);

                column(Narration_PostedNarration; Narration)
                {
                }

                trigger OnPreDataItem()
                begin
                    if not LineNarration then
                        CurrReport.Break();
                end;
            }
            dataitem(PostedNarration1; "Posted Narration")
            {
                DataItemLink = "Transaction No." = field("Transaction No.");
                DataItemTableView = sorting("Entry No.", "Transaction No.", "Line No.")
                                         where("Entry No." = filter(0));

                column(Narration_PostedNarration1; Narration)
                {
                }

                trigger OnPreDataItem()
                begin
                    if not VoucherNarration then
                        CurrReport.Break();

                    GLEntry.SetCurrentKey("Posting Date", "Source Code", "Transaction No.");
                    GLEntry.SetRange(GLEntry."Posting Date", "G/L Entry"."Posting Date");
                    GLEntry.SetRange(GLEntry."Source Code", "G/L Entry"."Source Code");
                    GLEntry.SetRange(GLEntry."Transaction No.", "G/L Entry"."Transaction No.");
                    GLEntry.FindLast();
                    if not (GLEntry."Entry No." = "G/L Entry"."Entry No.") then
                        CurrReport.Break();
                end;
            }

            trigger OnPreDataItem()
            begin
                SetCurrentKey("Posting Date", "Source Code", "Transaction No.");
            end;

            trigger OnAfterGetRecord()
            begin
                DocNo := '';
                PostingDate := 0D;
                SourceDesc := '';

                GLAccName := FindGLAccName("Source Type", "Entry No.", "Source No.", "G/L Account No.");

                if TransNo = 0 then begin
                    TransNo := "Transaction No.";
                    DocNo := "Document No.";
                    PostingDate := "Posting Date";
                    if "Source Code" <> '' then begin
                        SourceCode.Get("Source Code");
                        SourceDesc := CopyStr(SourceCode.Description, 1, MaxStrLen(SourceDesc));
                    end;
                end else
                    if TransNo <> "Transaction No." then begin
                        TransNo := "Transaction No.";
                        DocNo := "Document No.";
                        PostingDate := "Posting Date";
                        if "Source Code" <> '' then begin
                            SourceCode.Get("Source Code");
                            SourceDesc := CopyStr(SourceCode.Description, 1, MaxStrLen(SourceDesc));
                        end;
                    end;

                if Amount > 0 then
                    TransDebits := TransDebits + Amount;
                if Amount < 0 then
                    TransCredits := TransCredits - Amount;
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
                    field("Line Narration"; LineNarration)
                    {
                        Caption = 'Line Narration';
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Place a check mark in this field if line narration is to be printed.';
                    }
                    field("Voucher Narration"; VoucherNarration)
                    {
                        Caption = 'Voucher Narration';
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Place a check mark in this field if voucher narration is to be printed.';
                    }
                }
            }
        }
    }


    trigger OnPreReport()
    begin
        Compinfo.Get();
    end;

    var
        Compinfo: Record "Company Information";
        GLEntry: Record "G/L Entry";
        SourceCode: Record "Source Code";
        GLAccName: Text[50];
        SourceDesc: Text[50];
        PostingDate: Date;
        LineNarration: Boolean;
        VoucherNarration: Boolean;
        DocNo: Code[20];
        TransNo: Integer;
        TransDebits: Decimal;
        TransCredits: Decimal;
        DayBookCaptionLbl: Label 'Day Book';
        DocumentNoCaptionLbl: Label 'Document No.';
        AccountNameCaptionLbl: Label 'Account Name';
        DebitAmountCaptionLbl: Label 'Debit Amount';
        CreditAmountCaptionLbl: Label 'Credit Amount';
        VoucherTypeCaptionLbl: Label 'Voucher Type';
        DateCaptionLbl: Label 'Date';
        TotalCaptionLbl: Label 'Total';

    procedure FindGLAccName(
        "Source Type": Enum "Gen. Journal Source Type";
        "Entry No.": Integer;
        "Source No.": Code[20];
        "G/L Account No.": Code[20]): Text[50]
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vend: Record Vendor;
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankLedgEntry: Record "Bank Account Ledger Entry";
        Bank: Record "Bank Account";
        FALedgEntry: Record "FA Ledger Entry";
        FA: Record "Fixed Asset";
        GLAccount: Record "G/L Account";
        AccName: Text[50];
    begin
        case "Source Type" of
            "Source Type"::Vendor:
                if VendLedgEntry.Get("Entry No.") then begin
                    Vend.Get("Source No.");
                    AccName := CopyStr(Vend.Name, 1, MaxStrLen(AccName));
                end else begin
                    GLAccount.Get("G/L Account No.");
                    AccName := CopyStr(GLAccount.Name, 1, MaxStrLen(AccName));
                end;
            "Source Type"::Customer:
                if CustLedgEntry.Get("Entry No.") then begin
                    Cust.Get("Source No.");
                    AccName := CopyStr(Cust.Name, 1, MaxStrLen(AccName));
                end else begin
                    GLAccount.Get("G/L Account No.");
                    AccName := CopyStr(GLAccount.Name, 1, MaxStrLen(AccName));
                end;
            "Source Type"::"Bank Account":
                if BankLedgEntry.Get("Entry No.") then begin
                    Bank.Get("Source No.");
                    AccName := CopyStr(Bank.Name, 1, MaxStrLen(AccName));
                end else begin
                    GLAccount.Get("G/L Account No.");
                    AccName := CopyStr(GLAccount.Name, 1, MaxStrLen(AccName));
                end;
            "Source Type"::"Fixed Asset":
                begin
                    FALedgEntry.Reset();
                    FALedgEntry.SetRange("G/L Entry No.", "Entry No.");
                    if FALedgEntry.FindFirst() then begin
                        FA.Get("Source No.");
                        AccName := CopyStr(FA.Description, 1, MaxStrLen(AccName));
                    end else begin
                        GLAccount.Get("G/L Account No.");
                        AccName := CopyStr(GLAccount.Name, 1, MaxStrLen(AccName));
                    end;
                end else begin
                            GLAccount.Get("G/L Account No.");
                            AccName := CopyStr(GLAccount.Name, 1, MaxStrLen(AccName));
                        end;
                        GLAccount.Get("G/L Account No.");
                        AccName := CopyStr(GLAccount.Name, 1, MaxStrLen(AccName));
        end;
        exit(AccName);
    end;
}