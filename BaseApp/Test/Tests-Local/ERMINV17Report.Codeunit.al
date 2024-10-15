codeunit 144704 "ERM INV-17 Report"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LocMgt: Codeunit "Localisation Management";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure InventActHeader()
    var
        InvtActHeader: Record "Invent. Act Header";
    begin
        Initialize;
        MockInvActHeader(InvtActHeader);
        RunINV17Report(InvtActHeader);
        VerifyReportHeader(
          InvtActHeader."Reason Document No.", InvtActHeader."Reason Document Date",
          InvtActHeader."No.", InvtActHeader."Act Date", InvtActHeader."Inventory Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultilineInventAct()
    var
        InvtActHeader: Record "Invent. Act Header";
        TempInvtActLine: Record "Invent. Act Line" temporary;
    begin
        Initialize;
        MockInvActHeader(InvtActHeader);
        InitCustBuffer(TempInvtActLine, InvtActHeader."No.");
        InitVendBuffer(TempInvtActLine, InvtActHeader."No.");
        RunINV17Report(InvtActHeader);
        VerifyReportLineValuesFromBuffer(TempInvtActLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplementInvAct()
    var
        InvtActHeader: Record "Invent. Act Header";
        InvtActLine: Record "Invent. Act Line";
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        CategoryType: Option;
        Counter: Integer;
    begin
        Initialize;
        MockInvActHeader(InvtActHeader);
        MockCustomerWithLedgEntries(TempCustLedgEntry, InvtActHeader."Inventory Date");
        MockVendorWithLedgEntries(TempVendLedgEntry, InvtActHeader."Inventory Date");
        for CategoryType := InvtActLine.Category::Debts to InvtActLine.Category::Liabilities do begin
            MockInvActLine(
              InvtActLine, InvtActHeader."No.", InvtActLine."Contractor Type"::Customer, TempCustLedgEntry."Customer No."
              , '', TempCustLedgEntry."Customer Posting Group", CategoryType);
            MockInvActLine(
              InvtActLine, InvtActHeader."No.", InvtActLine."Contractor Type"::Vendor, TempVendLedgEntry."Vendor No."
              , '', TempVendLedgEntry."Vendor Posting Group", CategoryType);
        end;
        RunINV17SupplementReport(InvtActHeader);
        VerifySupplementLineValuesFromCustBuffer(TempCustLedgEntry, Counter);
        VerifySupplementLineValuesFromVendBuffer(TempVendLedgEntry, Counter);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryReportValidation);

        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup;

        isInitialized := true;
        Commit();
    end;

    local procedure MockInvActHeader(var InvtActHeader: Record "Invent. Act Header")
    begin
        with InvtActHeader do begin
            Init;
            Insert(true);
            Validate("Inventory Date", WorkDate);
            Validate("Reason Document No.", LibraryUtility.GenerateGUID);
            Validate("Reason Document Date", CalcDate('<1D>', "Inventory Date"));
            Validate("Act Date", CalcDate('<1D>', "Reason Document Date"));
            Modify(true);
        end;
    end;

    local procedure InitCustBuffer(var TempInvtActLine: Record "Invent. Act Line" temporary; ActNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        i: Integer;
        j: Integer;
    begin
        LibraryERM.FindGLAccount(GLAccount);
        Customer.SetFilter(Name, '<>%1', '');
        Customer.FindSet;
        for i := 1 to 2 do begin
            CustomerPostingGroup.FindSet;
            for j := 1 to 2 do begin
                MockGroupInvtActLine(
                  TempInvtActLine, ActNo, TempInvtActLine."Contractor Type"::Customer, Customer."No.", GLAccount."No.",
                  CustomerPostingGroup.Code);
                CustomerPostingGroup.Next;
            end;
            Customer.Next;
        end;
    end;

    local procedure InitVendBuffer(var TempInvtActLine: Record "Invent. Act Line" temporary; ActNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        i: Integer;
        j: Integer;
    begin
        LibraryERM.FindGLAccount(GLAccount);
        Vendor.SetFilter(Name, '<>%1', '');
        Vendor.FindSet;
        for i := 1 to 2 do begin
            VendorPostingGroup.FindSet;
            for j := 1 to 2 do begin
                MockGroupInvtActLine(
                  TempInvtActLine, ActNo, TempInvtActLine."Contractor Type"::Vendor, Vendor."No.", GLAccount."No.",
                  VendorPostingGroup.Code);
                VendorPostingGroup.Next;
            end;
            Vendor.Next;
        end;
    end;

    local procedure MockGroupInvtActLine(var TempInvtActLine: Record "Invent. Act Line" temporary; ActNo: Code[20]; ContractorType: Option; ContractorNo: Code[20]; GLAccNo: Code[20]; PostingGroupCode: Code[20])
    var
        InvtActLine: Record "Invent. Act Line";
        CategoryType: Option;
    begin
        TempInvtActLine.SetRange("Contractor No.", ContractorNo);
        TempInvtActLine.SetRange("Contractor Type", ContractorType);

        for CategoryType := InvtActLine.Category::Debts to InvtActLine.Category::Liabilities do begin
            MockInvActLine(
              InvtActLine, ActNo, ContractorType, ContractorNo, GLAccNo, PostingGroupCode,
              CategoryType);
            TempInvtActLine.SetRange(Category, CategoryType);
            if TempInvtActLine.FindFirst then
                SummarizeAmounts(TempInvtActLine, InvtActLine)
            else begin
                TempInvtActLine := InvtActLine;
                TempInvtActLine.Insert();
            end;
        end;
    end;

    local procedure MockInvActLine(var InvtActLine: Record "Invent. Act Line"; ActNo: Code[20]; ContractorType: Option; ContractorNo: Code[20]; GLAccNo: Code[20]; PostingGroup: Code[20]; CategoryType: Option)
    begin
        with InvtActLine do begin
            Init;
            Validate("Act No.", ActNo);
            Validate("Contractor Type", ContractorType);
            Validate("Contractor No.", ContractorNo);
            Validate("Posting Group", PostingGroup);
            Validate(Category, CategoryType);
            Validate("Contractor Name", GetContractorName(ContractorType, ContractorNo));
            Validate("G/L Account No.", GLAccNo);
            Validate("Total Amount", LibraryRandom.RandDec(100, 2));
            Validate("Confirmed Amount", LibraryRandom.RandDec(100, 2));
            Validate("Not Confirmed Amount", LibraryRandom.RandDec(100, 2));
            Validate("Overdue Amount", LibraryRandom.RandDec(100, 2));
            Insert(true);
        end;
    end;

    local procedure MockCustomerWithLedgEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; InvDate: Date)
    var
        Customer: Record Customer;
        CustAgreement: Record "Customer Agreement";
        CustPostingGroup: Record "Customer Posting Group";
        EntryAmount: Decimal;
    begin
        CustPostingGroup.FindFirst;
        Customer.Init();
        Customer."Customer Posting Group" := CustPostingGroup.Code;
        Customer.Name := LibraryUtility.GenerateGUID;
        Customer."Name 2" := LibraryUtility.GenerateGUID;
        Customer.Address := LibraryUtility.GenerateGUID;
        Customer."Address 2" := LibraryUtility.GenerateGUID;
        Customer."Phone No." := LibraryUtility.GenerateGUID;
        Customer."Agreement Posting" := Customer."Agreement Posting"::Mandatory;
        Customer.Insert(true);

        CustAgreement.Init();
        CustAgreement."Customer No." := Customer."No.";
        CustAgreement.Description := LibraryUtility.GenerateGUID;
        CustAgreement.Insert(true);

        EntryAmount := LibraryRandom.RandDec(100, 2);
        with Customer do begin
            // Ledger entry outside of date range
            MockCustLedgEntryWithDtldEntry(
              CustLedgEntry, Customer, CalcDate('<1M>', InvDate), InvDate, CustAgreement."No.", EntryAmount, false);
            // Dtld. Ledger Entry outside of date range
            MockCustLedgEntryWithDtldEntry(
              CustLedgEntry, Customer, InvDate, CalcDate('<1M>', InvDate), CustAgreement."No.", EntryAmount, false);
            // Ledger Entries that should be print in report
            MockCustLedgEntryWithDtldEntry(
              CustLedgEntry, Customer, InvDate, InvDate, CustAgreement."No.", EntryAmount, true);
            MockCustLedgEntryWithDtldEntry(
              CustLedgEntry, Customer, InvDate, InvDate, CustAgreement."No.", -EntryAmount, true);
        end;
    end;

    local procedure MockVendorWithLedgEntries(var VendLedgEntry: Record "Vendor Ledger Entry"; InvDate: Date)
    var
        Vendor: Record Vendor;
        VendAgreement: Record "Vendor Agreement";
        VendPostingGroup: Record "Vendor Posting Group";
        EntryAmount: Decimal;
    begin
        VendPostingGroup.FindFirst;
        Vendor.Init();
        Vendor."Vendor Posting Group" := VendPostingGroup.Code;
        Vendor.Name := LibraryUtility.GenerateGUID;
        Vendor."Name 2" := LibraryUtility.GenerateGUID;
        Vendor.Address := LibraryUtility.GenerateGUID;
        Vendor."Address 2" := LibraryUtility.GenerateGUID;
        Vendor."Phone No." := LibraryUtility.GenerateGUID;
        Vendor."Agreement Posting" := Vendor."Agreement Posting"::Mandatory;
        Vendor.Insert(true);

        VendAgreement.Init();
        VendAgreement."Vendor No." := Vendor."No.";
        VendAgreement.Description := LibraryUtility.GenerateGUID;
        VendAgreement.Insert(true);

        EntryAmount := LibraryRandom.RandDec(100, 2);
        with Vendor do begin
            // Ledger entry outside of date range
            MockVendLedgEntryWithDtldEntry(
              VendLedgEntry, Vendor, CalcDate('<1M>', InvDate), InvDate, VendAgreement."No.", EntryAmount, false);
            // Dtld. Ledger Entry outside of date range
            MockVendLedgEntryWithDtldEntry(
              VendLedgEntry, Vendor, InvDate, CalcDate('<1M>', InvDate), VendAgreement."No.", EntryAmount, false);
            // Ledger Entries that should be print in report
            MockVendLedgEntryWithDtldEntry(
              VendLedgEntry, Vendor, InvDate, InvDate, VendAgreement."No.", EntryAmount, true);
            MockVendLedgEntryWithDtldEntry(
              VendLedgEntry, Vendor, InvDate, InvDate, VendAgreement."No.", -EntryAmount, true);
        end;
    end;

    local procedure MockCustLedgEntryWithDtldEntry(var CustLedgEntryBuffer: Record "Cust. Ledger Entry"; Customer: Record Customer; PostingDate: Date; DtldEntryPostingDate: Date; AgreementNo: Code[20]; EntryAmount: Decimal; InsertInBuffer: Boolean)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EntryNo: Integer;
    begin
        if CustLedgEntry.FindLast then
            EntryNo := CustLedgEntry."Entry No."
        else
            EntryNo := 0;
        EntryNo += 1;
        MockCustLedgEntry(CustLedgEntry, EntryNo, Customer."No.", Customer."Customer Posting Group", PostingDate, AgreementNo);

        if DtldCustLedgEntry.FindLast then
            EntryNo := DtldCustLedgEntry."Entry No."
        else
            EntryNo := 0;
        EntryNo += 1;
        MockDtldCustLedgEntry(DtldCustLedgEntry, EntryNo, CustLedgEntry."Entry No.", DtldEntryPostingDate, EntryAmount);

        if InsertInBuffer then begin
            CustLedgEntryBuffer := CustLedgEntry;
            CustLedgEntryBuffer.Insert();
        end;
    end;

    local procedure MockCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; EntryNo: Integer; CustNo: Code[20]; CustPostGroupCode: Code[20]; PostingDate: Date; AgreementNo: Code[20])
    begin
        with CustLedgEntry do begin
            Init;
            "Entry No." := EntryNo;
            "Customer No." := CustNo;
            "Customer Posting Group" := CustPostGroupCode;
            "Posting Date" := PostingDate;
            "Document Type" := "Document Type"::Invoice;
            "Document No." := LibraryUtility.GenerateGUID;
            "Agreement No." := AgreementNo;
            Insert;
        end;
    end;

    local procedure MockDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EntryNo: Integer; CustLedgEntryNo: Integer; DtldEntryPostingDate: Date; EntryAmount: Decimal)
    begin
        with DtldCustLedgEntry do begin
            Init;
            "Entry No." := EntryNo;
            "Cust. Ledger Entry No." := CustLedgEntryNo;
            "Entry Type" := "Entry Type"::"Initial Entry";
            "Posting Date" := DtldEntryPostingDate;
            "Amount (LCY)" := EntryAmount;
            Insert;
        end;
    end;

    local procedure MockVendLedgEntryWithDtldEntry(var VendLedgEntryBuffer: Record "Vendor Ledger Entry"; Vendor: Record Vendor; PostingDate: Date; DtldEntryPostingDate: Date; AgreementNo: Code[20]; EntryAmount: Decimal; InsertInBuffer: Boolean)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        EntryNo: Integer;
    begin
        if VendLedgEntry.FindLast then
            EntryNo := VendLedgEntry."Entry No."
        else
            EntryNo := 0;
        EntryNo += 1;
        MockVendLedgEntry(VendLedgEntry, EntryNo, Vendor."No.", Vendor."Vendor Posting Group", PostingDate, AgreementNo);

        if DtldVendLedgEntry.FindLast then
            EntryNo := DtldVendLedgEntry."Entry No."
        else
            EntryNo := 0;
        EntryNo += 1;
        MockDtldVendLedgEntry(DtldVendLedgEntry, EntryNo, VendLedgEntry."Entry No.", DtldEntryPostingDate, EntryAmount);

        if InsertInBuffer then begin
            VendLedgEntryBuffer := VendLedgEntry;
            VendLedgEntryBuffer.Insert();
        end;
    end;

    local procedure MockVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; EntryNo: Integer; VendNo: Code[20]; VendPostGroupCode: Code[20]; PostingDate: Date; AgreementNo: Code[20])
    begin
        with VendLedgEntry do begin
            Init;
            "Entry No." := EntryNo;
            "Vendor No." := VendNo;
            "Vendor Posting Group" := VendPostGroupCode;
            "Posting Date" := PostingDate;
            "Document Type" := "Document Type"::Invoice;
            "Document No." := LibraryUtility.GenerateGUID;
            "Agreement No." := AgreementNo;
            Insert;
        end;
    end;

    local procedure MockDtldVendLedgEntry(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; EntryNo: Integer; VendLedgEntryNo: Integer; DtldEntryPostingDate: Date; EntryAmount: Decimal)
    begin
        with DtldVendLedgEntry do begin
            Init;
            "Entry No." := EntryNo;
            "Vendor Ledger Entry No." := VendLedgEntryNo;
            "Entry Type" := "Entry Type"::"Initial Entry";
            "Posting Date" := DtldEntryPostingDate;
            "Amount (LCY)" := EntryAmount;
            Insert;
        end;
    end;

    local procedure GetContractorName(ContractorType: Option; ContractorNo: Code[20]): Text[250]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        InvtActLine: Record "Invent. Act Line";
    begin
        case ContractorType of
            InvtActLine."Contractor Type"::Customer:
                begin
                    Customer.Get(ContractorNo);
                    exit(Customer.Name);
                end;
            InvtActLine."Contractor Type"::Vendor:
                begin
                    Vendor.Get(ContractorNo);
                    exit(Vendor.Name);
                end;
        end;
    end;

    local procedure GetCustFullNameAndContacts(CustNo: Code[20]): Text
    var
        Customer: Record Customer;
    begin
        with Customer do begin
            Get(CustNo);
            exit(
              Name + "Name 2" + ', ' + Address +
              "Address 2" + ', ' + "Phone No.");
        end;
    end;

    local procedure GetCustAgrDescription(CustLedgEntry: Record "Cust. Ledger Entry"): Text
    var
        CustAgreement: Record "Customer Agreement";
    begin
        with CustLedgEntry do begin
            CustAgreement.Get("Customer No.", "Agreement No.");
            exit(Description + ' ' + CustAgreement.Description);
        end;
    end;

    local procedure GetVendFullNameAndContacts(VendNo: Code[20]): Text
    var
        Vendor: Record Vendor;
    begin
        with Vendor do begin
            Get(VendNo);
            exit(
              Name + "Name 2" + ', ' + Address +
              "Address 2" + ', ' + "Phone No.");
        end;
    end;

    local procedure GetVendAgrDescription(VendLedgEntry: Record "Vendor Ledger Entry"): Text
    var
        VendAgreement: Record "Vendor Agreement";
    begin
        with VendLedgEntry do begin
            VendAgreement.Get("Vendor No.", "Agreement No.");
            exit(Description + ' ' + VendAgreement.Description);
        end;
    end;

    local procedure CalcDebtLiabilitiesAmount(var DebtsAmount: Decimal; var LiabilitiesAmount: Decimal; Amount: Decimal)
    begin
        DebtsAmount := 0;
        LiabilitiesAmount := 0;
        if Amount > 0 then
            DebtsAmount := Amount
        else
            LiabilitiesAmount := -Amount;
    end;

    local procedure SummarizeAmounts(var ToInvActLine: Record "Invent. Act Line"; FromInvActLine: Record "Invent. Act Line")
    begin
        with ToInvActLine do begin
            "Total Amount" += FromInvActLine."Total Amount";
            "Confirmed Amount" += FromInvActLine."Confirmed Amount";
            "Not Confirmed Amount" += FromInvActLine."Not Confirmed Amount";
            "Overdue Amount" += FromInvActLine."Overdue Amount";
            Modify;
        end;
    end;

    local procedure RunINV17Report(InvtActHeader: Record "Invent. Act Header")
    var
        InvActRep: Report "Invent. Act INV-17";
    begin
        LibraryReportValidation.SetFileName(InvtActHeader."No.");
        InvtActHeader.SetRecFilter;
        InvActRep.SetFileNameSilent(LibraryReportValidation.GetFileName);
        InvActRep.SetTableView(InvtActHeader);
        InvActRep.UseRequestPage(false);
        InvActRep.Run;
    end;

    local procedure RunINV17SupplementReport(InvtActHeader: Record "Invent. Act Header")
    var
        SupplementInvActRep: Report "Supplement to INV-17";
    begin
        LibraryReportValidation.SetFileName(InvtActHeader."No.");
        InvtActHeader.SetRecFilter;
        SupplementInvActRep.SetFileNameSilent(LibraryReportValidation.GetFileName);
        SupplementInvActRep.SetTableView(InvtActHeader);
        SupplementInvActRep.UseRequestPage(false);
        SupplementInvActRep.Run;
    end;

    local procedure VerifyReportHeader(ReasonDocNo: Code[20]; ReasonDocDate: Date; DocNo: Code[20]; DocDate: Date; InvDate: Date)
    var
        CompanyInfo: Record "Company Information";
        StdRepMgt: Codeunit "Local Report Management";
    begin
        CompanyInfo.Get();
        LibraryReportValidation.VerifyCellValue(7, 1, StdRepMgt.GetCompanyName);
        LibraryReportValidation.VerifyCellValue(7, 22, CompanyInfo."OKPO Code");
        LibraryReportValidation.VerifyCellValue(12, 22, ReasonDocNo);
        LibraryReportValidation.VerifyCellValue(13, 22, Format(ReasonDocDate));
        LibraryReportValidation.VerifyCellValue(18, 11, DocNo);
        LibraryReportValidation.VerifyCellValue(18, 14, Format(DocDate));
        LibraryReportValidation.VerifyCellValue(21, 6, Format(Date2DMY(InvDate, 1)));
        LibraryReportValidation.VerifyCellValue(21, 8, LocMgt.Month2Text(InvDate));
        LibraryReportValidation.VerifyCellValue(21, 15, Format(Date2DMY(InvDate, 1)));
    end;

    local procedure VerifyReportLineValuesFromBuffer(var TempInvtActLine: Record "Invent. Act Line")
    var
        CategoryType: Integer;
        RowShift: Integer;
    begin
        RowShift := 0;
        TempInvtActLine.Reset();
        for CategoryType := TempInvtActLine.Category::Debts to TempInvtActLine.Category::Liabilities do begin
            TempInvtActLine.SetRange(Category, CategoryType);
            TempInvtActLine.FindSet;
            with TempInvtActLine do begin
                repeat
                    VerifyLineValue(
                      RowShift,
                      "Contractor Name",
                      "G/L Account No.",
                      "Total Amount",
                      "Confirmed Amount",
                      "Not Confirmed Amount",
                      "Overdue Amount");
                    RowShift += 1;
                until Next = 0;
            end;
            RowShift += 6; // Printing of page header
        end;
    end;

    local procedure VerifyLineValue(RowShift: Integer; ContractorName: Text; AccountNo: Code[20]; TotalAmount: Decimal; ConfirmedAmount: Decimal; NotConfirmedAmount: Decimal; OverdueAmount: Decimal)
    var
        LineRowId: Integer;
    begin
        LineRowId := 29 + RowShift;
        LibraryReportValidation.VerifyCellValue(LineRowId, 1, ContractorName);
        LibraryReportValidation.VerifyCellValue(LineRowId, 5, AccountNo);
        VerifyAmounts(RowShift, TotalAmount, ConfirmedAmount, NotConfirmedAmount, OverdueAmount);
    end;

    local procedure VerifyAmounts(RowShift: Integer; TotalAmount: Decimal; ConfirmedAmount: Decimal; NotConfirmedAmount: Decimal; OverdueAmount: Decimal)
    var
        LineRowId: Integer;
    begin
        LineRowId := 29 + RowShift;
        LibraryReportValidation.VerifyCellValue(LineRowId, 10, Format(TotalAmount));
        LibraryReportValidation.VerifyCellValue(LineRowId, 12, Format(ConfirmedAmount));
        LibraryReportValidation.VerifyCellValue(LineRowId, 18, Format(NotConfirmedAmount));
        LibraryReportValidation.VerifyCellValue(LineRowId, 23, Format(OverdueAmount));
    end;

    local procedure VerifySupplementLineValuesFromCustBuffer(var CustLedgEntry: Record "Cust. Ledger Entry" temporary; var Counter: Integer)
    var
        DebtsAmount: Decimal;
        LiabilitiesAmount: Decimal;
    begin
        with CustLedgEntry do begin
            FindSet;
            repeat
                CalcFields("Remaining Amt. (LCY)");
                TestField("Remaining Amt. (LCY)");
                CalcDebtLiabilitiesAmount(DebtsAmount, LiabilitiesAmount, "Remaining Amt. (LCY)");
                VerifySupplementLineValue(
                  Counter, GetCustFullNameAndContacts("Customer No."),
                  GetCustAgrDescription(CustLedgEntry), Format("Posting Date"),
                  Format(DebtsAmount), Format(LiabilitiesAmount),
                  Format("Document Type"), "Document No.", Format("Posting Date"));
                Counter += 1;
            until Next = 0;
        end;
    end;

    local procedure VerifySupplementLineValuesFromVendBuffer(var VendLedgEntry: Record "Vendor Ledger Entry" temporary; var Counter: Integer)
    var
        DebtsAmount: Decimal;
        LiabilitiesAmount: Decimal;
    begin
        with VendLedgEntry do begin
            FindSet;
            repeat
                CalcFields("Remaining Amt. (LCY)");
                TestField("Remaining Amt. (LCY)");
                CalcDebtLiabilitiesAmount(DebtsAmount, LiabilitiesAmount, "Remaining Amt. (LCY)");
                VerifySupplementLineValue(
                  Counter, GetVendFullNameAndContacts("Vendor No."),
                  GetVendAgrDescription(VendLedgEntry), Format("Posting Date"),
                  Format(DebtsAmount), Format(LiabilitiesAmount),
                  Format("Document Type"), "Document No.", Format("Posting Date"));
                Counter += 1;
            until Next = 0;
        end;
    end;

    local procedure VerifySupplementLineValue(Counter: Integer; Name: Text; AgreementDescription: Text; DocDate: Text; DebtsAmount: Text; LiabilitiesAmount: Text; DocType: Text; DocNo: Text; PostingDate: Text)
    var
        LineRowId: Integer;
    begin
        LineRowId := 19 + Counter;
        LibraryReportValidation.VerifyCellValue(LineRowId, 1, Format(Counter + 1));
        LibraryReportValidation.VerifyCellValue(LineRowId, 2, Name);
        LibraryReportValidation.VerifyCellValue(LineRowId, 4, AgreementDescription);
        LibraryReportValidation.VerifyCellValue(LineRowId, 7, DocDate);
        LibraryReportValidation.VerifyCellValue(LineRowId, 12, DebtsAmount);
        LibraryReportValidation.VerifyCellValue(LineRowId, 14, LiabilitiesAmount);
        LibraryReportValidation.VerifyCellValue(LineRowId, 19, DocType);
        LibraryReportValidation.VerifyCellValue(LineRowId, 20, DocNo);
        LibraryReportValidation.VerifyCellValue(LineRowId, 21, PostingDate);
    end;
}

