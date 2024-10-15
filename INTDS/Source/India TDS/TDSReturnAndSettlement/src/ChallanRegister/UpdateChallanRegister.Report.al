report 18747 "Update Challan Register"
{
    Caption = 'Update Challan Register';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    dataset
    {
        dataitem(DataItem2129; "TDS Challan Register")
        {
            DataItemTableView = SORTING("Entry No.");

            trigger OnAfterGetRecord()
            var
                TDSJournalLine: Record "TDS Journal Line";
            begin
                "TDS Interest Amount" := TDSJournalLine.RoundTDSAmount(InterestAmount);
                "TDS Others" := TDSJournalLine.RoundTDSAmount(OtherFee);
                "Oltas Interest" := TDSJournalLine.RoundTDSAmount(InterestAmount);
                "Oltas Others" := TDSJournalLine.RoundTDSAmount(OtherFee);
                "TDS Fee" := TDSJournalLine.RoundTDSAmount(LateFee);
                "Paid By Book Entry" := PaidByBook;
                "Transfer Voucher No." := TransferVoucherNo;
                Modify();
            end;

            trigger OnPreDataItem()
            begin
                SETRANGE("Entry No.", EntryNo);
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
                    field("Interest Amount"; InterestAmount)
                    {
                        Caption = 'Interest Amount';
                        ToolTip = 'Specifies the value of interest payable.';
                        ApplicationArea = Basic, Suite;
                    }
                    field("Others"; OtherFee)
                    {
                        Caption = 'Others';
                        ToolTip = 'Specifies the value of other charges payable.';
                        ApplicationArea = Basic, Suite;
                    }
                    field(Fee; LateFee)
                    {
                        Caption = 'Fee';
                        ToolTip = 'Specifies the value of fees payable.';
                        ApplicationArea = Basic, Suite;
                    }
                    field("Paid By Book Entry"; PaidByBook)
                    {
                        Caption = 'Paid By Book Entry';
                        ToolTip = 'Select this field to specify that challan has been paid by book entry.';
                        ApplicationArea = Basic, Suite;
                        trigger OnValidate()
                        var
                            CompanyInfo: Record "Company Information";
                            PaidBookErr: Label 'Paid by book entry can be true only for Govt. Organisations.';
                        begin
                            if not (CompanyInfo."Company Status" = CompanyInfo."Company Status"::Government) and (PaidByBook = TRUE) then
                                Error(PaidBookErr);
                        end;
                    }
                    field("Transfer Voucher No."; TransferVoucherNo)
                    {
                        Caption = 'Transfer Voucher No.';
                        ToolTip = 'Specifies the transfer voucher reference.';
                        ApplicationArea = Basic, Suite;
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

    trigger OnInitReport()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.GET();
        PaidByBook := FALSE;
    end;

    trigger OnPreReport()
    var
        CompanyInfo: Record "Company Information";
        VoucherEmptyErr: Label 'Transfer Voucher No. cannot be empty when Deductor Category is %1 - %2.', Comment = '%1=Deductor Category Code, %2= Deductor Description';
        VoucherInsertErr: Label 'Transfer Voucher No. cannot be entered when  Deductor Category is %1 - %2.', Comment = '%1=Deductor Category Code, %2= Deductor Description';
        PayTransferErr: Label 'Paid by Book Entry cannot be false when Transfer Voucher No. is entered.';
    begin
        CompanyInfo.get();
        DeductorCategory.get(CompanyInfo."Deductor Category");
        if DeductorCategory."Transfer Voucher No. Mandatory" and (TransferVoucherNo = '') then
            Error(VoucherEmptyErr, DeductorCategory.Code, DeductorCategory.Description);
        if not DeductorCategory."Transfer Voucher No. Mandatory" and (TransferVoucherNo <> '') then
            Error(VoucherInsertErr, DeductorCategory.Code, DeductorCategory.Description);
        if DeductorCategory."Transfer Voucher No. Mandatory" and (TransferVoucherNo <> '') and not PaidByBook then
            Error(PayTransferErr);
    end;

    var
        DeductorCategory: Record "Deductor Category";
        GLSetup: Record "General Ledger Setup";
        InterestAmount: Decimal;
        OtherFee: Decimal;
        EntryNo: Integer;
        PaidByBook: Boolean;
        TransferVoucherNo: Code[9];
        LateFee: Decimal;

    procedure UpdateChallan(NewInterestAmount: Decimal; NewOtherAmount: Decimal; NewLateFee: Decimal; NewEntryNo: Integer)
    var
        TDSJournalLine: Record "TDS Journal Line";
    begin
        InterestAmount := TDSJournalLine.RoundTDSAmount(NewInterestAmount);
        OtherFee := TDSJournalLine.RoundTDSAmount(NewOtherAmount);
        LateFee := TDSJournalLine.RoundTDSAmount(NewLateFee);
        EntryNo := NewEntryNo;
    end;

    procedure UpdateVoucherNo(PaidByBookEntry: Boolean; VoucherNo: Code[9])
    begin
        PaidByBook := PaidByBookEntry;
        TransferVoucherNo := VoucherNo;
    end;
}

