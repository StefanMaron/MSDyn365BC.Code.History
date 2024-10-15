report 18748 "Update Challan Details"
{
    Caption = 'Update Challan Details';
    ProcessingOnly = true;
    UseRequestPage = true;
    UsageCategory = ReportsAndAnalysis;
    dataset
    {
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
                    field("Pay TDS Document No."; PayTDSDocNo)
                    {
                        Caption = 'Pay TDS Document No.';
                        ToolTip = 'Specifies the document number of the TDS entry to be paid to government.';
                        ApplicationArea = Basic, Suite;
                    }
                    field("Challan No."; ChallanNo)
                    {
                        Caption = 'Challan No.';
                        ToolTip = 'Specifies the challan number provided by the bank while depositing the TDS amount.';
                        ApplicationArea = Basic, Suite;
                    }
                    field("Challan Date"; ChallanDate)
                    {
                        Caption = 'Challan Date';
                        ToolTip = 'Specifies the challan date on which TDS is paid to government.';
                        ApplicationArea = Basic, Suite;
                    }
                    field("Bank Name"; BankName)
                    {
                        Caption = 'Bank Name';
                        ToolTip = 'Specifies the name of the bank where TDS amount has been deposited.';
                        ApplicationArea = Basic, Suite;
                    }
                    field("BSR Code"; BSRCode)
                    {
                        Caption = 'BSR Code';
                        ToolTip = 'Specifies the Basic Statistical Return Code provided by the bank while depositing the TDS amount.';
                        ApplicationArea = Basic, Suite;
                    }
                    field("Check No."; CheckNo)
                    {
                        Caption = 'Cheque No.';
                        ToolTip = 'Specifies the No. of the check through which payment has been made.';
                        ApplicationArea = Basic, Suite;
                    }
                    field("Check Date"; CheckDate)
                    {
                        Caption = 'Cheque Date';
                        ToolTip = 'Specifies the date of the check through which payment has been made.';
                        ApplicationArea = Basic, Suite;
                    }
                    field("Minor Head Code"; MinorHeadCode)
                    {
                        Caption = 'Minor Head Code';
                        ToolTip = 'Specifies the minor head code used for the payment.';
                        ApplicationArea = Basic, Suite;
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            MinorHeadCode := MinorHeadCode::"200";
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        CompanyInformation: Record "Company Information";
        PayTDSDocNoErr: Label 'Enter Pay TDS Document No.';
        ChallanNoErr: Label 'Enter Challan No.';
        ChallanDateErr: Label 'Enter Challan Date.';
        BSRCodeErr: Label 'Enter BSR Code.';
        BankNameErr: Label 'Enter Bank Name.';
        MinorHeadCodeNotBlankErr: Label 'Minor Head Code must not be Blank.';
        BSRLengthErr: Label 'BSR code must have at least 7 digits.';
    begin
        CompanyInformation.get();
        if PayTDSDocNo = '' then
            Error(PayTDSDocNoErr);
        if ChallanNo = '' then
            Error(ChallanNoErr);
        if ChallanDate = 0D then
            Error(ChallanDateErr);
        if BankName = '' then
            Error(BankNameErr);
        if BSRCode = '' then
            if CompanyInformation."Company Status" <> CompanyInformation."Company Status"::Government then
                Error(BSRCodeErr);
        if STRLEN(BSRCode) < 7 then
            if CompanyInformation."Company Status" <> CompanyInformation."Company Status"::Government then
                Error(BSRLengthErr);
        if MinorHeadCode = MinorHeadCode::" " then
            Error(MinorHeadCodeNotBlankErr);
        UpdateTDSRegister();
    end;

    var
        ChallanNo: Code[5];
        ChallanDate: Date;
        BankName: Text[100];
        PayTDSDocNo: Code[20];
        BSRCode: Text[7];
        CheckNo: Code[10];
        CheckDate: Date;
        MinorHeadCode: Enum "Minor Head Type";

    local procedure UpdateTDSRegister()
    var
        TDSEntry: Record "TDS Entry";
        NoRecordErr: Label 'There are no records with this document no.';
    begin
        TDSEntry.Reset();
        TDSEntry.SetRange("Pay TDS Document No.", PayTDSDocNo);
        TDSEntry.SetRange("Challan No.", '');
        if TDSEntry.FindSet() then begin
            repeat
                TDSEntry."Challan No." := ChallanNo;
                TDSEntry."Challan Date" := ChallanDate;
                TDSEntry."Bank Name" := BankName;
                TDSEntry."BSR Code" := BSRCode;
                TDSEntry."Check/DD No." := CheckNo;
                TDSEntry."Check Date" := CheckDate;
                TDSEntry."Minor Head Code" := MinorHeadCode;
                TDSEntry.Modify();
            until TDSEntry.Next() = 0;
            UpdateChallanRegister();
        end else
            Message(NoRecordErr);
    end;

    procedure SetDocumentNo(DocumentNo: Code[20])
    begin
        PayTDSDocNo := DocumentNo;
    end;

    procedure UpdateChallanRegister()
    var
        ChallanRegister: Record "TDS Challan Register";
        TDSEntry: Record "TDS Entry";
        CompanyInfo: Record "Company Information";
        GenJnlPosLine: Codeunit "Gen. Jnl.-Post Line";
        ChallanAlreadyExistErr: Label 'Challan No already filed.';
    begin
        ChallanRegister.SetRange("Challan No.", ChallanNo);
        ChallanRegister.SetRange("Challan Date", ChallanDate);
        if ChallanRegister.FindFirst() then
            if ChallanRegister.Filed OR ChallanRegister.Revised then
                Error(ChallanAlreadyExistErr);

        CompanyInfo.get();
        ChallanRegister.Reset();
        ChallanRegister.SetRange("Pay TDS Document No.", PayTDSDocNo);
        TDSEntry.SetCurrentKey("Pay TDS Document No.", "Posting Date");
        TDSEntry.SetRange("Challan No.", ChallanNo);
        TDSEntry.FindLast();
        ChallanRegister.SetRange("TDS Payment Date", TDSEntry."TDS Payment Date");
        if ChallanRegister.FindFirst() then begin
            ChallanRegister."Last Bank Challan No." := ChallanRegister."Challan No.";
            ChallanRegister."Last Bank-Branch Code" := ChallanRegister."BSR Code";
            ChallanRegister."Last Date of Challan No." := ChallanRegister."Last Date of Challan No.";
            ChallanRegister."Challan No." := ChallanNo;
            ChallanRegister."BSR Code" := BSRCode;
            ChallanRegister."Challan Date" := ChallanDate;
            ChallanRegister."Bank Name" := BankName;
            ChallanRegister."Minor Head Code" := MinorHeadCode;
            if CompanyInfo."Company Status" = CompanyInfo."Company Status"::Government then begin
                ChallanRegister."Last Transfer Voucher No." := ChallanRegister."Transfer Voucher No.";
                ChallanRegister."Transfer Voucher No." := ChallanNo;
            end;
            if ChallanRegister.Filed OR (ChallanRegister.Revised AND (NOT ChallanRegister."Correction-C3"))
            then begin
                if ChallanRegister.Filed then
                    ChallanRegister."No. of Revision" := ChallanRegister."No. of Revision" + 1;
                ChallanRegister."Correction-C2" := TRUE;
                ChallanRegister.Filed := FALSE;
                ChallanRegister.Revised := TRUE;
            end;
            ChallanRegister.Modify();
        END ELSE begin
            ChallanRegister.Init();
            ChallanRegister."Entry No." := GetLastEntryNo() + 1;
            ChallanRegister."Challan No." := ChallanNo;
            ChallanRegister."Last Bank Challan No." := ChallanNo;
            ChallanRegister."BSR Code" := COPYSTR(BSRCode, 1, 7);
            ChallanRegister."Last Bank-Branch Code" := COPYSTR(BSRCode, 1, 7);
            ChallanRegister."Challan Date" := ChallanDate;
            ChallanRegister."Last Date of Challan No." := ChallanDate;
            ChallanRegister."Bank Name" := BankName;
            ChallanRegister."Pay TDS Document No." := PayTDSDocNo;
            ChallanRegister."Minor Head Code" := MinorHeadCode;
            ChallanRegister."TDS Payment Date" := ChallanDate;
            ChallanRegister."Non Resident Payment" := TDSEntry."Non Resident Payments";
            ChallanRegister."T.A.N. No." := TDSEntry."T.A.N. No.";
            ChallanRegister."TDS Section" := TDSEntry.Section;
            ChallanRegister."Check / DD No." := TDSEntry."Check/DD No.";
            ChallanRegister."Check / DD Date" := TDSEntry."Check Date";
            ChallanRegister."Challan-Detail Record No." :=
              GetChallanDetailRecNo(
                GetQuarter(TDSEntry."Posting Date"),
                GetFinancialYear(TDSEntry."Posting Date"), TDSEntry."Non Resident Payments", TDSEntry."T.A.N. No.");
            if CheckFiledEntries(
                 GetQuarter(TDSEntry."Posting Date"),
                 GetFinancialYear(TDSEntry."Posting Date"), TDSEntry."Non Resident Payments")
            then begin
                ChallanRegister."Correction-C9" := TRUE;
                ChallanRegister.Revised := TRUE;
                ChallanRegister."No. of Revision" += 1;
            end;
            ChallanRegister."Financial Year" := GetFinancialYear(TDSEntry."Posting Date");
            ChallanRegister.Quarter := GetQuarter(TDSEntry."Posting Date");
            ChallanRegister."Assessment Year" := GetAssessmentYear(TDSEntry."Posting Date");
            if CompanyInfo."Company Status" = CompanyInfo."Company Status"::Government then
                ChallanRegister."Transfer Voucher No." := ChallanNo;
            ChallanRegister."Last Tot Deposit Amt/ Challan" := ChallanRegister."Total TDS Including SHE Cess" +
            ChallanRegister."Oltas Interest";
            ChallanRegister."User ID" := CopyStr(USERID, 1, 50);
            ChallanRegister.Insert();
            TDSEntry.Reset();
            TDSEntry.SetRange("Challan No.", ChallanRegister."Challan No.");
            TDSEntry.ModifyAll("Challan Register Entry No.", ChallanRegister."Entry No.");
        end;
    end;

    procedure CheckFiledEntries(Quarter: Code[10]; FinancialYear: Code[9]; NRIPayment: Boolean): Boolean
    var
        ChallanRegister: Record "TDS Challan Register";
    begin
        ChallanRegister.SetRange(Quarter, Quarter);
        ChallanRegister.SetRange("Financial Year", FinancialYear);
        ChallanRegister.SetRange("Non Resident Payment", NRIPayment);
        ChallanRegister.SetRange(Filed, TRUE);
        if not ChallanRegister.FindFirst() then begin
            ChallanRegister.SetRange(Filed);
            ChallanRegister.SetRange(Revised, TRUE);
            exit(Not ChallanRegister.IsEmpty);
        end;
        exit(true);
    end;

    procedure UpdateNilChallanEntries(TANNo: Code[10]; Quarter: Option; FinancialYear: Code[9]; Resident: Boolean)
    var
        TDSEntry: Record "TDS Entry";
        TDSEntryLoc: Record "TDS Entry";
        TDSSetup: Record "TDS Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        TDSSetup.get();
        TDSSetup.TestField("TDS Nil Challan Nos.");
        TDSSetup.TestField("Nil Pay TDS Document Nos.");
        TDSEntry.SETCURRENTKEY(Section);
        TDSEntry.SetFilter("Posting Date", GenerateDateFilterFromQuarter(Quarter, FinancialYear));
        ChallanDate := TDSEntry.GetRangeMax(TDSEntry."Posting Date");
        TDSEntry.SetRange("Non Resident Payments", not Resident);
        TDSEntry.SetRange("T.A.N. No.", TANNo);
        TDSEntry.SetRange("TDS Paid", FALSE);
        TDSEntry.SetRange("NIL Challan Indicator", TRUE);
        TDSEntry.SetRange(Reversed, FALSE);

        if TDSEntry.FindSet(true, false) then
            repeat
                if IsEndOfTDSGroup(TDSEntry) then begin
                    PayTDSDocNo := NoSeriesManagement.GetNextNo(TDSSetup."Nil Pay TDS Document Nos.", WorkDate(), true);
                    ChallanNo := GetNewNilChallanNo(TDSSetup."TDS Nil Challan Nos.");
                    TDSEntryLoc.COPY(TDSEntry);
                    TDSEntryLoc.SetRange(Section, TDSEntry.Section);
                    TDSEntryLoc.ModifyAll("Pay TDS Document No.", PayTDSDocNo, TRUE);
                    TDSEntryLoc.ModifyAll("TDS Paid", TRUE, TRUE);
                    UpdateTDSRegister();
                end;
            until TDSEntry.Next() = 0;
    end;

    local procedure IsEndOfTDSGroup(var TDSEntry: Record "TDS Entry"): Boolean
    var
        TDSEntryCopy: Record "TDS Entry";
    begin
        TDSEntryCopy.COPY(TDSEntry);
        if TDSEntryCopy.Next() = 0 then
            exit(TRUE);
        exit(TDSEntryCopy.Section <> TDSEntry.Section);
    end;

    procedure InitializeRequest(NewPayTDSDocumentNo: Code[20]; NewChallanNo: Code[5]; NewChallanDate: Date; NewBankName: Text[100]; NewBSRCode: Code[7]; NewChequeNo: Code[10]; NewChequeDate: Date; NewMinorHeadCode: Enum "Minor Head Type")
    begin
        PayTDSDocNo := NewPayTDSDocumentNo;
        ChallanNo := NewChallanNo;
        ChallanDate := NewChallanDate;
        BankName := NewBankName;
        BSRCode := NewBSRCode;
        CheckNo := NewChequeNo;
        CheckDate := NewChequeDate;
        MinorHeadCode := NewMinorHeadCode;
    end;

    local procedure GetNewNilChallanNo(NoSeries: Code[10]): Code[5]
    var
        ChallanRegister: Record "TDS Challan Register";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        CandidateChallanNo: Code[20];
        ChallanLengthErr: Label 'The Challan number that has been generated is longer than expected. Make sure that the No. Series for the TDS Nil Challan number in the General Ledger Setup window does not contain more than %1 characters.', Comment = '%1= Previous Challan Length';
    begin
        CandidateChallanNo := NoSeriesManagement.GetNextNo(NoSeries, WorkDate(), true);
        if STRLEN(CandidateChallanNo) > MAXSTRLEN(ChallanRegister."Challan No.") then
            Error(ChallanLengthErr, MAXSTRLEN(ChallanRegister."Challan No."));
        exit(copystr(CandidateChallanNo, 1, 5));
    end;

    procedure GetLastEntryNo(): Integer
    var
        TDSChallanRegister: Record "TDS Challan Register";
    begin
        if TDSChallanRegister.FindLast() then
            exit(TDSChallanRegister."Entry No.")
        else
            exit(1);
    end;

    local procedure GetChallanDetailRecNo(Quarter: Code[10]; FinancialYear: Code[9]; NRIPayment: Boolean; TANNo: Code[10]): Integer
    var
        ChallanReg: Record "TDS Challan Register";
    begin
        ChallanReg.Reset();
        ChallanReg.SetRange(Quarter, Quarter);
        ChallanReg.SetRange("Financial Year", FinancialYear);
        ChallanReg.SetRange("Non Resident Payment", NRIPayment);
        ChallanReg.SetRange("T.A.N. No.", TANNo);
        if ChallanReg.FindLast() then
            exit(ChallanReg.Count + 1);
        exit(1);
    end;

    local procedure GetQuarter(EntryDate: Date): Code[10]
    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
    begin
        TaxAccountingPeriod.SetFilter("Starting Date", '<=%1', EntryDate);
        TaxAccountingPeriod.SetFilter("Ending Date", '>=%1', EntryDate);
        TaxAccountingPeriod.SetRange("Tax Type Code", GetTDSAccountingPeriodType());
        if TaxAccountingPeriod.FindFirst() then
            exit(TaxAccountingPeriod.Quarter);
    end;

    local procedure GetFinancialYear(EntryDate: Date): Code[9]
    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
    begin
        TaxAccountingPeriod.SetFilter("Starting Date", '<=%1', EntryDate);
        TaxAccountingPeriod.SetFilter("Ending Date", '>=%1', EntryDate);
        TaxAccountingPeriod.SetRange("Tax Type Code", GetTDSAccountingPeriodType());
        if TaxAccountingPeriod.FindFirst() then
            exit(CopyStr(TaxAccountingPeriod."Financial Year", 1, 9));
    end;

    local procedure GetTDSAccountingPeriodType(): Code[10]
    var
        TDSSetup: Record "TDS Setup";
        TaxType: Record "Tax Type";
    begin
        if not TDSSetup.Get() then
            exit;
        TDSSetup.TestField("Tax Type");

        TaxType.SetRange(code, TDSSetup."Tax Type");
        if TaxType.FindFirst() then
            exit(TaxType."Accounting Period");
    end;

    local procedure GetAssessmentYear(EntryDate: Date): Code[6]
    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
        StartDate: Date;
        EndDate: Date;
    begin
        StartDate := GetAccountingStartEndDate(EntryDate, 0);
        EndDate := GetAccountingStartEndDate(EntryDate, 1);
        if DATE2DMY(StartDate, 3) = DATE2DMY(EndDate, 3) then
            exit(FORMAT(DATE2DMY(StartDate, 3) + 1));

        exit(FORMAT(DATE2DMY(EndDate, 3)) + FORMAT(CALCDATE('<+1Y>', EndDate), 2, '<Year,2>'));
    end;

    local procedure GetAccountingStartEndDate(ReferenceDate: Date; StartorEnd: Integer): Date
    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
    begin
        TaxAccountingPeriod.Reset();
        TaxAccountingPeriod.SetRange(Closed, FALSE);
        TaxAccountingPeriod.SetFilter("Starting Date", '<=%1', ReferenceDate);
        TaxAccountingPeriod.SetFilter("Ending Date", '>=%1', ReferenceDate);
        if TaxAccountingPeriod.FindLast() then begin
            if StartorEnd = 0 then
                exit(TaxAccountingPeriod."Starting Date");

            exit(TaxAccountingPeriod."Ending Date");
        end;
    end;

    local procedure GenerateDateFilterFromQuarter(Quarter: Option; FinancialYear: Code[9]): Text
    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
        StartDate: date;
        DateRangeLbl: Label '%1..%2', Comment = '%1=Start date,%2= End Date';
        DateFilterAccPeriodErr: Label 'Cannot calculate a date filter because you have not set up an income tax accounting period for the posting date of the specified TDS entry.';
    begin
        TaxAccountingPeriod.setrange("Financial Year", FinancialYear);
        TaxAccountingPeriod.setrange("Tax Type Code", GetTDSAccountingPeriodType());
        if TaxAccountingPeriod.FindFirst() then
            StartDate := TaxAccountingPeriod."Starting Date"
        else
            Error(DateFilterAccPeriodErr);
        if TaxAccountingPeriod.FindLast() then
            exit(StrSubstNo(DateRangeLbl, StartDate, TaxAccountingPeriod."Ending Date"))
    end;
}

