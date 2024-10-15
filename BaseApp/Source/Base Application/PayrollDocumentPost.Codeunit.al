codeunit 17405 "Payroll Document - Post"
{
    Permissions = TableData "Posted Payroll Document" = rim,
                  TableData "Posted Payroll Document Line" = rim,
                  TableData "Payroll Ledger Entry" = rim,
                  TableData "Detailed Payroll Ledger Entry" = rim,
                  TableData "Payroll Document Line AE" = rim,
                  TableData "Posted Payroll Doc. Line AE" = rim,
                  TableData "Payroll Ledger Base Amount" = rim,
                  TableData "Posted Payroll Doc. Line Calc." = rim,
                  TableData "Posted Payroll Doc. Line Expr." = rim;
    TableNo = "Payroll Document";

    trigger OnRun()
    var
        PayrollDocBufRemainder: Record "Payroll Document Buffer" temporary;
    begin
        ClearAll;

        PayrollDoc.Copy(Rec);
        with PayrollDoc do begin
            TestField("Employee No.");
            TestField("Posting Date");
            TestField("Period Code");

            Employee.Get("Employee No.");
            Employee.TestField("Person No.");
            Person.Get(Employee."Person No.");
            Person.TestField("Vendor No.");

            if Correction then
                TestField("Reversing Document No.");

            if Status = Status::Open then begin
                CODEUNIT.Run(CODEUNIT::"Release Payroll Document", PayrollDoc);
                Status := Status::Open;
                Modify;
                Commit;
                Status := Status::Released;
            end;

            PayrollCalcGroup.Get("Calc Group Code");
            if PayrollCalcGroup.Type <> PayrollCalcGroup.Type::Between then begin
                PayrollStatus.Get("Period Code", "Employee No.");
                if "Posting Type" = "Posting Type"::Calculation then begin
                    if Correction then
                        PayrollStatus.TestField("Payroll Status", PayrollStatus."Payroll Status"::Posted)
                    else
                        PayrollStatus.TestField("Payroll Status", PayrollStatus."Payroll Status"::Calculated);
                end;
            end;

            CheckDim;

            HRSetup.Get;
            SourceCodeSetup.Get;
            SourceCodeSetup.TestField("Payroll Calculation");

            // Lock tables
            GLEntry.LockTable;
            if GLEntry.FindLast then;
            PayrollLedgEntry.LockTable;
            if PayrollLedgEntry.FindLast then;
            DtldPayrollLedgEntry.LockTable;
            if DtldPayrollLedgEntry.FindLast then;

            SepareteEntryBuffer.DeleteAll;
            PayrollDocBuffer.DeleteAll;

            // Insert posted document header
            PostedPayrollDoc.Init;
            PostedPayrollDoc.TransferFields(PayrollDoc);
            PostedPayrollDoc."No." :=
              NoSeriesMgt.GetNextNo(
                HRSetup."Posted Payroll Document Nos.", "Posting Date", true);
            PostedPayrollDoc.Reversed := Correction;
            PostedPayrollDoc.Insert;

            if Correction then begin
                ReversingPayrollDoc.Get("Reversing Document No.");
                ReversingPayrollDoc.Reversed := true;
                ReversingPayrollDoc.Modify;

                PayrollLedgEntry.SetCurrentKey("Document No.", "Posting Date");
                PayrollLedgEntry.SetRange("Document No.", ReversingPayrollDoc."No.");
                PayrollLedgEntry.SetRange("Posting Date", ReversingPayrollDoc."Posting Date");
                PayrollLedgEntry.ModifyAll(Reversed, true);
            end;

            PostToGL := "Posting Type" = "Posting Type"::Calculation;

            // Insert posted document lines
            PayrollDocLine.Reset;
            PayrollDocLine.SetRange("Document No.", "No.");
            if PayrollDocLine.FindSet then
                repeat
                    if Correction then
                        ReverseAmount;

                    PostedPayrollDocLine.Init;
                    PostedPayrollDocLine.TransferFields(PayrollDocLine);
                    PostedPayrollDocLine."Document No." := PostedPayrollDoc."No.";
                    PostedPayrollDocLine.Insert;

                    if PayrollCalcGroup.Type <> PayrollCalcGroup.Type::Between then
                        PostPayrollDocumentLine;

                    PostedPayrollDocLine."Payroll Ledger Entry No." := PayrollDocLine."Payroll Ledger Entry No.";
                    PostedPayrollDocLine.Modify;

                    // copy calculation
                    PayrollDocLineCalc.SetRange("Document No.", PayrollDocLine."Document No.");
                    PayrollDocLineCalc.SetRange("Document Line No.", PayrollDocLine."Line No.");
                    if PayrollDocLineCalc.FindSet then
                        repeat
                            PostedPayrollDocLineCalc.Init;
                            PostedPayrollDocLineCalc.TransferFields(PayrollDocLineCalc);
                            PostedPayrollDocLineCalc."Document No." := PostedPayrollDoc."No.";
                            PostedPayrollDocLineCalc.Insert;

                            PayrollDocLineExpr.SetRange("Document No.", PayrollDocLineCalc."Document No.");
                            PayrollDocLineExpr.SetRange("Document Line No.", PayrollDocLineCalc."Document Line No.");
                            PayrollDocLineExpr.SetRange("Calculation Line No.", PayrollDocLineCalc."Line No.");
                            if PayrollDocLineExpr.FindSet then
                                repeat
                                    PostedPayrollDocLineExpr.Init;
                                    PostedPayrollDocLineExpr.TransferFields(PayrollDocLineExpr);
                                    PostedPayrollDocLineExpr."Document No." := PostedPayrollDoc."No.";
                                    PostedPayrollDocLineExpr.Insert;
                                until PayrollDocLineExpr.Next = 0;
                        until PayrollDocLineCalc.Next = 0;

                    // Insert AE entries
                    PayrollDocLineAE.Reset;
                    PayrollDocLineAE.SetRange("Document No.", PayrollDocLine."Document No.");
                    PayrollDocLineAE.SetRange("Document Line No.", PayrollDocLine."Line No.");
                    if PayrollDocLineAE.FindSet then
                        repeat
                            PostedPayrollDocLineAE.Init;
                            PostedPayrollDocLineAE.TransferFields(PayrollDocLineAE);
                            PostedPayrollDocLineAE."Document No." := PostedPayrollDoc."No.";
                            PostedPayrollDocLineAE.Insert;
                        until PayrollDocLineAE.Next = 0;

                    PayrollPeriodAE.Reset;
                    PayrollPeriodAE.SetRange("Document No.", PayrollDocLine."Document No.");
                    PayrollPeriodAE.SetRange("Line No.", PayrollDocLine."Line No.");
                    if PayrollPeriodAE.FindSet then
                        repeat
                            PostedPayrollPeriodAE.Init;
                            PostedPayrollPeriodAE.TransferFields(PayrollPeriodAE);
                            PostedPayrollPeriodAE."Document No." := PostedPayrollDoc."No.";
                            PostedPayrollPeriodAE.Insert;
                        until PayrollPeriodAE.Next = 0;
                    if PayrollCalcGroup.Type <> PayrollCalcGroup.Type::Between then
                        PersonIncomeMgt.CreateSocialTaxLine(PostedPayrollDocLine);
                    if PayrollDocLine."Days To Exclude" <> 0 then
                        PersonIncomeMgt.UpdateSocialTaxLine(PostedPayrollDocLine);

                    // Update income tax form
                    PersonIncomeMgt.CreateIncomeTaxLine(PostedPayrollDocLine, PayrollDoc."Posting Date", PayrollDoc.Correction);

                until PayrollDocLine.Next = 0;

            if (PayrollCalcGroup.Type <> PayrollCalcGroup.Type::Between) and PostToGL then begin
                // Post vendor's liability
                if DocumentBalance <> 0 then begin
                    GenJnlLine.Init;
                    GenJnlLine.Validate("Posting Date", "Posting Date");
                    GenJnlLine."Document No." := PostedPayrollDoc."No.";
                    GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
                    GenJnlLine.Validate("Account No.", Person."Vendor No.");
                    GenJnlLine.Description := "Posting Description";
                    GenJnlLine.Validate(Amount, -DocumentBalance);
                    GenJnlLine."Payroll Ledger Entry No." := 0;
                    GenJnlLine."Source Code" := SourceCodeSetup."Payroll Calculation";
                    GenJnlLine.Correction := Correction;
                    if LaborContract.Get(Employee."Contract No.") then
                        if LaborContract."Vendor Agreement No." <> '' then begin
                            VendorAgreement.Get(LaborContract."Vendor No.", LaborContract."Vendor Agreement No.");
                            VendorAgreement.Validate("Vendor Posting Group");
                            GenJnlLine.Validate("Posting Group", VendorAgreement."Vendor Posting Group");
                        end;
                    GenJnlPostLine.RunWithoutCheck(GenJnlLine);
                end;

                // Post fund entries
                AggregateTaxes(PayrollDocLine);
                PayrollDocBuffer.Reset;
                if PayrollDocBuffer.FindSet then
                    repeat
                        GenJnlLine.Init;
                        GenJnlLine."Payment Purpose" := "Employee No.";
                        GenJnlLine.Validate("Posting Date", "Posting Date");
                        PostedPayrollDocLine.Reset;
                        PostedPayrollDocLine.SetRange("Document No.", PostedPayrollDoc."No.");
                        PostedPayrollDocLine.SetRange("Element Code", PayrollDocBuffer."Element Code");
                        PostedPayrollDocLine.FindFirst;
                        TaxAllocationPostingSetup.Get(PayrollDocBuffer."Payroll Posting Group", PayrollDocBuffer."Element Code");
                        TaxAllocationPostingSetup.TestField("Tax Allocated Posting Group");
                        PayrollPostingGroup.Get(TaxAllocationPostingSetup."Tax Allocated Posting Group");
                        case PayrollPostingGroup."Account Type" of
                            PayrollPostingGroup."Account Type"::"G/L Account":
                                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                            PayrollPostingGroup."Account Type"::Vendor:
                                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                        end;
                        PayrollPostingGroup.TestField("Account No.");
                        GenJnlLine.Validate("Account No.", PayrollPostingGroup."Account No.");
                        PayrollPostingGroup.TestField("Fund Vendor No.");
                        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::Vendor);
                        GenJnlLine.Validate("Bal. Account No.", PayrollPostingGroup."Fund Vendor No.");
                        PostedPayrDocLineToGenJnlLine(PostedPayrollDocLine, GenJnlLine);
                        CalcRoundedTaxAmt(GenJnlLine, PayrollDocBuffer, PayrollDocBufRemainder);
                        PayrollElement.Get(PayrollDocBuffer."Element Code");
                        GenJnlLine.Description := CopyStr(PayrollElement.Description, 1, MaxStrLen(GenJnlLine.Description));

                        GenJnlLine."Source Code" := SourceCodeSetup."Payroll Calculation";
                        GenJnlLine.Correction := Correction;
                        GenJnlLine."Dimension Set ID" := PayrollDocBuffer."Dimension Set ID";
                        GenJnlLine."Payroll Ledger Entry No." := PayrollDocBuffer."Payroll Ledger Entry No.";

                        GenJnlPostLine.RunWithoutCheck(GenJnlLine);
                    until PayrollDocBuffer.Next = 0;

                // post income tax and deductions entries
                SepareteEntryBuffer.Reset;
                if SepareteEntryBuffer.FindSet then
                    repeat
                        GenJnlLine.Init;
                        GenJnlLine."Payment Purpose" := "Employee No.";
                        GenJnlLine.Validate("Posting Date", "Posting Date");
                        GenJnlLine."Document No." := PostedPayrollDoc."No.";
                        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
                        GenJnlLine.Validate("Account No.", Person."Vendor No.");
                        if LaborContract.Get(Employee."Contract No.") then
                            if LaborContract."Vendor Agreement No." <> '' then begin
                                VendorAgreement.Get(LaborContract."Vendor No.", LaborContract."Vendor Agreement No.");
                                VendorAgreement.Validate("Vendor Posting Group");
                                GenJnlLine.Validate("Posting Group", VendorAgreement."Vendor Posting Group");
                            end;
                        GenJnlLine.Validate(Amount, -SepareteEntryBuffer."Payroll Amount");
                        GenJnlLine.Correction := Correction;
                        GenJnlLine.Description := SepareteEntryBuffer.Description;
                        GenJnlLine."Source Code" := SourceCodeSetup."Payroll Calculation";
                        GenJnlLine."System-Created Entry" := true;
                        GenJnlLine."Dimension Set ID" := SepareteEntryBuffer."Dimension Set ID";
                        GenJnlLine."Payroll Ledger Entry No." := SepareteEntryBuffer."Payroll Ledger Entry No.";
                        GenJnlPostLine.RunWithoutCheck(GenJnlLine);

                        GenJnlLine.Init;
                        GenJnlLine."Payment Purpose" := "Employee No.";
                        GenJnlLine.Validate("Posting Date", "Posting Date");
                        GenJnlLine."Document No." := PostedPayrollDoc."No.";
                        PayrollPostingGroup.Get(SepareteEntryBuffer."Posting Group");
                        case PayrollPostingGroup."Account Type" of
                            PayrollPostingGroup."Account Type"::"G/L Account":
                                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                            PayrollPostingGroup."Account Type"::Vendor:
                                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                        end;
                        PayrollPostingGroup.TestField("Account No.");
                        GenJnlLine.Validate("Account No.", PayrollPostingGroup."Account No.");
                        GenJnlLine.Validate(Amount, SepareteEntryBuffer."Payroll Amount");
                        GenJnlLine.Correction := Correction;
                        GenJnlLine.Description := SepareteEntryBuffer.Description;
                        GenJnlLine."Source Code" := SourceCodeSetup."Payroll Calculation";
                        GenJnlLine."System-Created Entry" := true;
                        GenJnlLine."Dimension Set ID" := SepareteEntryBuffer."Dimension Set ID";
                        GenJnlLine."Payroll Ledger Entry No." := SepareteEntryBuffer."Payroll Ledger Entry No.";
                        GenJnlPostLine.RunWithoutCheck(GenJnlLine);
                    until SepareteEntryBuffer.Next = 0;
            end;

            // Delete document and lines
            Delete;

            PayrollDocLine.Reset;
            PayrollDocLine.SetRange("Document No.", "No.");
            PayrollDocLine.DeleteAll(true);

            if PayrollCalcGroup.Type <> PayrollCalcGroup.Type::Between then begin
                if Correction then
                    PayrollStatus."Payroll Status" := PayrollStatus."Payroll Status"::" "
                else
                    PayrollStatus."Payroll Status" := PayrollStatus."Payroll Status"::Posted;
                PayrollStatus.UpdateCalculated(PayrollStatus);
                PayrollStatus.UpdatePosted(PayrollStatus);
                PayrollStatus.Modify;
            end;

            Commit;
        end;
    end;

    var
        GLEntry: Record "G/L Entry";
        GenJnlLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        VendorAgreement: Record "Vendor Agreement";
        LaborContract: Record "Labor Contract";
        Person: Record Person;
        HRSetup: Record "Human Resources Setup";
        PayrollElement: Record "Payroll Element";
        PayrollCalcGroup: Record "Payroll Calc Group";
        PayrollLedgEntry: Record "Payroll Ledger Entry";
        DtldPayrollLedgEntry: Record "Detailed Payroll Ledger Entry";
        PayrollPostingGroup: Record "Payroll Posting Group";
        PayrollLedgBaseAmt: Record "Payroll Ledger Base Amount";
        PayrollDocLineAE: Record "Payroll Document Line AE";
        PayrollDocLineExpr: Record "Payroll Document Line Expr.";
        PayrollDocLineCalc: Record "Payroll Document Line Calc.";
        PayrollDoc: Record "Payroll Document";
        PayrollDocLine: Record "Payroll Document Line";
        SepareteEntryBuffer: Record "Payroll Document Line" temporary;
        PayrollPeriodAE: Record "Payroll Period AE";
        PostedPayrollDoc: Record "Posted Payroll Document";
        ReversingPayrollDoc: Record "Posted Payroll Document";
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
        PostedPayrollDocLineAE: Record "Posted Payroll Doc. Line AE";
        PostedPayrollDocLineCalc: Record "Posted Payroll Doc. Line Calc.";
        PostedPayrollDocLineExpr: Record "Posted Payroll Doc. Line Expr.";
        PostedPayrollPeriodAE: Record "Posted Payroll Period AE";
        PayrollStatus: Record "Payroll Status";
        SourceCodeSetup: Record "Source Code Setup";
        PayrollDocBuffer: Record "Payroll Document Buffer" temporary;
        TaxAllocationPostingSetup: Record "Tax Allocation Posting Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        PersonIncomeMgt: Codeunit "Person Income Management";
        Text000: Label 'Incorrect %1.';
        Text005: Label 'The combination of dimensions used in payroll document %1 is blocked. %2';
        Text006: Label 'The combination of dimensions used in payroll %1, line no. %2 is blocked. %3';
        Text007: Label 'The dimensions used in payroll document %1 are invalid. %2';
        Text008: Label 'The dimensions used in payroll document %1, line no. %2 are invalid. %3';
        NextEntryNo: Integer;
        NextDocBufferEntryNo: Integer;
        DocumentBalance: Decimal;
        PostToGL: Boolean;

    local procedure CheckDim()
    var
        PayrollDocLine2: Record "Payroll Document Line";
    begin
        PayrollDocLine2."Line No." := 0;
        CheckDimValuePosting(PayrollDocLine2);
        CheckDimComb(PayrollDocLine2);

        PayrollDocLine2.SetRange("Document No.", PayrollDoc."No.");
        if PayrollDocLine2.FindSet then
            repeat
                CheckDimComb(PayrollDocLine2);
                CheckDimValuePosting(PayrollDocLine2);
            until PayrollDocLine2.Next = 0;
    end;

    local procedure CheckDimComb(PayrolDocLine: Record "Payroll Document Line")
    begin
        if PayrollDocLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(PayrollDoc."Dimension Set ID") then
                Error(
                  Text005,
                  PayrollDoc."No.", DimMgt.GetDimCombErr);

        if PayrollDocLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(PayrollDocLine."Dimension Set ID") then
                Error(
                  Text006,
                  PayrollDoc."No.", PayrollDocLine."Line No.", DimMgt.GetDimCombErr);
    end;

    local procedure CheckDimValuePosting(var PayrollDocLine2: Record "Payroll Document Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        if PayrollDocLine2."Line No." = 0 then begin
            TableIDArr[1] := DATABASE::Employee;
            NumberArr[1] := PayrollDoc."Employee No.";
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, PayrollDoc."Dimension Set ID") then
                Error(
                  Text007,
                  PayrollDoc."No.", DimMgt.GetDimValuePostingErr);
        end else begin
            TableIDArr[1] := DATABASE::Employee;
            NumberArr[1] := PayrollDocLine2."Employee No.";
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, PayrollDocLine2."Dimension Set ID") then
                Error(
                  Text008,
                  PayrollDoc."No.", PayrollDocLine2."Line No.", DimMgt.GetDimValuePostingErr);
        end;
    end;

    [Scope('OnPrem')]
    procedure PostPayrollDocumentLine()
    begin
        with PayrollDocLine do begin
            if ("Payroll Amount" = 0) and ("Taxable Amount" = 0) and ("Element Type" <> "Element Type"::"Netto Salary") then
                exit;

            CheckDocumentLine;

            PayrollLedgEntry.Reset;
            if NextEntryNo = 0 then begin
                if PayrollLedgEntry.FindLast then
                    NextEntryNo := PayrollLedgEntry."Entry No." + 1
                else
                    NextEntryNo := 1;
            end;

            "Payroll Ledger Entry No." := NextEntryNo;
            Modify;

            // G/L posting
            PayrollElement.Get("Element Code");
            if not (PayrollElement."Posting Type" in
                    [PayrollElement."Posting Type"::"Not Post",
                     PayrollElement."Posting Type"::"Information Only"]) and PostToGL
            then
                case PayrollElement.Type of
                    PayrollElement.Type::Wage,
                    PayrollElement.Type::"Netto Salary",
                    PayrollElement.Type::Bonus:
                        begin
                            GenJnlLine.Init;
                            GenJnlLine."Payment Purpose" := PayrollDoc."Employee No.";
                            GenJnlLine.Validate("Posting Date", PayrollDoc."Posting Date");
                            PostedPayrDocLineToGenJnlLine(PostedPayrollDocLine, GenJnlLine);
                            PayrollPostingGroup.Get("Posting Group");
                            case PayrollPostingGroup."Account Type" of
                                PayrollPostingGroup."Account Type"::"G/L Account":
                                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                                PayrollPostingGroup."Account Type"::Vendor:
                                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                            end;
                            PayrollPostingGroup.TestField("Account No.");
                            GenJnlLine.Validate("Account No.", PayrollPostingGroup."Account No.");
                            GenJnlLine.Description := CopyStr(PayrollElement.Description, 1, MaxStrLen(GenJnlLine.Description));
                            GenJnlLine.Correction := PayrollDoc.Correction or GenJnlLine.Correction;
                            GenJnlLine."Source Code" := SourceCodeSetup."Payroll Calculation";
                            DocumentBalance := DocumentBalance + GenJnlLine."Amount (LCY)";

                            GenJnlPostLine.RunWithoutCheck(GenJnlLine);
                        end;
                    PayrollElement.Type::Deduction,
                    PayrollElement.Type::"Income Tax":
                        begin
                            SepareteEntryBuffer := PayrollDocLine;
                            SepareteEntryBuffer.Insert;
                        end;
                end;
            InsertPayrollLedgerEntry;

            // Insert detailed ledger entries
            InsertDtldLedgerEntries;

            // Insert Base Amount entries
            if "FSI Base" then
                InsertBaseAmountEntry(PayrollLedgEntry, PayrollLedgBaseAmt."Base Type"::FSI, 0);
            if "FSI Injury Base" then
                InsertBaseAmountEntry(PayrollLedgEntry, PayrollLedgBaseAmt."Base Type"::"FSI Injury", 0);
            if "Federal FMI Base" then
                InsertBaseAmountEntry(PayrollLedgEntry, PayrollLedgBaseAmt."Base Type"::"Federal FMI", 0);
            if "Territorial FMI Base" then
                InsertBaseAmountEntry(PayrollLedgEntry, PayrollLedgBaseAmt."Base Type"::"Territorial FMI", 0);
            if "Pension Fund Base" then
                InsertBaseAmountEntry(PayrollLedgEntry, PayrollLedgBaseAmt."Base Type"::"PF Insur. Part", 0);
            if "Income Tax Base" then
                InsertBaseAmountEntry(PayrollLedgEntry, PayrollLedgBaseAmt."Base Type"::"Income Tax", 0);

            NextEntryNo := NextEntryNo + 1;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckDocumentLine()
    begin
        with PayrollDocLine do begin
            if ("Payroll Amount" = 0) and
               ("Taxable Amount" = 0) and
               ("Element Type" <> "Element Type"::"Netto Salary")
            then
                exit;

            TestField("Element Code");

            if "Posting Type" <> "Posting Type"::"Not Post" then
                TestField("Posting Group");
            if PayrollDoc."Employee No." <> '' then
                TestField("Calc Group");
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertPayrollLedgerEntry()
    begin
        with PayrollLedgEntry do begin
            Init;
            PayrDocLineToPayrLedgEntry(PostedPayrollDocLine, PayrollLedgEntry);
            PayrElementToPayrLedgEntry(PayrollElement, PayrollLedgEntry);
            SetPayrollCategoryCode;
            "User ID" := UserId;
            "Source Code" := SourceCodeSetup."Payroll Calculation";
            case "Posting Type" of
                "Posting Type"::"Not Post":
                    "Distrib. Costs" := true;
                "Posting Type"::Charge:
                    begin
                        if PayrollElement.Type <> PayrollElement.Type::"Netto Salary" then begin
                            "Distrib. Costs" := false;
                        end else
                            "Distrib. Costs" := true;
                    end;
                "Posting Type"::Liability:
                    begin
                        if PayrollElement.Type <> PayrollElement.Type::"Netto Salary" then
                            ;
                        "Distrib. Costs" := true;
                    end;
                "Posting Type"::"Liability Charge":
                    begin
                        if PayrollElement.Type <> PayrollElement.Type::"Netto Salary" then
                            "Distrib. Costs" := false
                        else
                            "Distrib. Costs" := true;
                    end;
            end;
            if Person."Birth Date" >= 19670101D then
                "Use PF Accum. System" := true;
            if LaborContract.Get(Employee."Contract No.") then begin
                PayrollLedgEntry."Work Mode" := LaborContract."Work Mode";
                PayrollLedgEntry."Contract Type" := LaborContract."Contract Type";
            end;
            "Disability Group" := Person.GetDisabilityGroup("Posting Date");
            Reversed := PayrollDoc.Correction;
            "Entry No." := NextEntryNo;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertDtldLedgerEntries()
    var
        WagePeriod: Record "Payroll Period";
        TempWagePeriod: Record "Payroll Period" temporary;
        WagePeriodNumber: Decimal;
        TotalAmount: Decimal;
        TotalTaxableAmount: Decimal;
        NextDtldEntryNo: Integer;
    begin
        // analyze periods
        TempWagePeriod.DeleteAll;
        TempWagePeriod.Reset;

        WagePeriodNumber := 0;
        WagePeriod.Reset;
        WagePeriod.SetRange(Code, PayrollDocLine."Wage Period From", PayrollDocLine."Wage Period To");
        if WagePeriod.FindSet then
            repeat
                TempWagePeriod := WagePeriod;
                TempWagePeriod.Insert;
                WagePeriodNumber := WagePeriodNumber + 1;
            until WagePeriod.Next = 0
        else
            Error(Text000, PayrollDocLine.FieldCaption("Wage Period From"));

        TotalAmount := 0;
        TotalTaxableAmount := 0;

        if NextDtldEntryNo = 0 then begin
            if DtldPayrollLedgEntry.FindLast then
                NextDtldEntryNo := DtldPayrollLedgEntry."Entry No." + 1
            else
                NextDtldEntryNo := 1;
        end;

        TempWagePeriod.Find('-');
        repeat
            DtldPayrollLedgEntry.Init;
            DtldPayrollLedgEntry."Entry No." := NextDtldEntryNo;
            NextDtldEntryNo := NextDtldEntryNo + 1;
            DtldPayrollLedgEntry."Payroll Ledger Entry No." := PayrollLedgEntry."Entry No.";
            DtldPayrollLedgEntry."Posting Date" := PayrollLedgEntry."Posting Date";
            DtldPayrollLedgEntry."Document Type" := PayrollLedgEntry."Document Type";
            DtldPayrollLedgEntry."Document No." := PayrollLedgEntry."Document No.";
            DtldPayrollLedgEntry."HR Order No." := PayrollLedgEntry."HR Order No.";
            DtldPayrollLedgEntry."HR Order Date" := PayrollLedgEntry."HR Order Date";
            DtldPayrollLedgEntry."Employee No." := PayrollLedgEntry."Employee No.";
            DtldPayrollLedgEntry."Posting Type" := PayrollLedgEntry."Posting Type";
            DtldPayrollLedgEntry."Posting Group" := PayrollLedgEntry."Posting Group";
            DtldPayrollLedgEntry."Directory Code" := PayrollLedgEntry."Directory Code";
            DtldPayrollLedgEntry."Element Type" := PayrollLedgEntry."Element Type";
            DtldPayrollLedgEntry."Element Group" := PayrollLedgEntry."Element Group";
            DtldPayrollLedgEntry."Element Code" := PayrollLedgEntry."Element Code";
            DtldPayrollLedgEntry."Bonus Type" := PayrollLedgEntry."Bonus Type";
            DtldPayrollLedgEntry."User ID" := PayrollLedgEntry."User ID";
            DtldPayrollLedgEntry."Source Code" := PayrollLedgEntry."Source Code";
            DtldPayrollLedgEntry."Salary Indexation" := PostedPayrollDocLine."Salary Indexation";
            DtldPayrollLedgEntry."Depends on Salary Element" := PostedPayrollDocLine."Depends on Salary Element";
            DtldPayrollLedgEntry."Period Code" := PayrollLedgEntry."Period Code";
            DtldPayrollLedgEntry."Wage Period Code" := TempWagePeriod.Code;

            DtldPayrollLedgEntry."Payroll Amount" :=
              Round(PayrollLedgEntry."Payroll Amount" / WagePeriodNumber);
            TotalAmount := TotalAmount + DtldPayrollLedgEntry."Payroll Amount";
            DtldPayrollLedgEntry."Taxable Amount" :=
              Round(PayrollLedgEntry."Taxable Amount" / WagePeriodNumber);
            TotalTaxableAmount := TotalTaxableAmount + DtldPayrollLedgEntry."Taxable Amount";
            DtldPayrollLedgEntry.Insert;
        until TempWagePeriod.Next = 0;

        if (TotalAmount <> 0) or (TotalTaxableAmount <> 0) or (TotalTaxableAmount <> 0) then begin
            DtldPayrollLedgEntry."Payroll Amount" :=
              DtldPayrollLedgEntry."Payroll Amount" + (PayrollLedgEntry."Payroll Amount" - TotalAmount);
            DtldPayrollLedgEntry."Taxable Amount" :=
              DtldPayrollLedgEntry."Taxable Amount" + (PayrollLedgEntry."Taxable Amount" - TotalTaxableAmount);
            DtldPayrollLedgEntry.Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertBaseAmountEntry(PayrollLedgEntry: Record "Payroll Ledger Entry"; BaseType: Integer; DetailedBaseType: Integer)
    begin
        with PayrollLedgEntry do begin
            PayrollLedgBaseAmt.Init;
            PayrollLedgBaseAmt."Entry No." := "Entry No.";
            PayrollLedgBaseAmt."Base Type" := BaseType;
            PayrollLedgBaseAmt."Detailed Base Type" := DetailedBaseType;
            PayrollLedgBaseAmt."Element Type" := "Element Type";
            PayrollLedgBaseAmt."Element Code" := "Element Code";
            PayrollLedgBaseAmt."Employee No." := "Employee No.";
            PayrollLedgBaseAmt."Period Code" := "Period Code";
            PayrollLedgBaseAmt."Posting Date" := "Posting Date";
            PayrollLedgBaseAmt."Payroll Directory Code" := "Directory Code";
            PayrollLedgBaseAmt.Amount := "Payroll Amount";
            PayrollLedgBaseAmt.Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure PayrDocLineToPayrLedgEntry(PostedPayrollDocLine: Record "Posted Payroll Document Line"; var PayrollLedgerEntry: Record "Payroll Ledger Entry")
    begin
        with PayrollLedgerEntry do begin
            "Employee No." := PostedPayrollDocLine."Employee No.";
            "Posting Date" := PostedPayrollDoc."Posting Date";
            "Document Type" := PostedPayrollDocLine."Document Type";
            "Document No." := PostedPayrollDocLine."Document No.";
            "HR Order No." := PostedPayrollDocLine."HR Order No.";
            "HR Order Date" := PostedPayrollDocLine."HR Order Date";
            Description := PostedPayrollDocLine.Description;
            "Period Code" := PostedPayrollDocLine."Period Code";
            "Posting Group" := PostedPayrollDocLine."Posting Group";
            "Time Activity Code" := PostedPayrollDocLine."Time Activity Code";
            "Element Code" := PostedPayrollDocLine."Element Code";
            "Element Type" := PostedPayrollDocLine."Element Type";
            "Payroll Amount" := PostedPayrollDocLine."Payroll Amount";
            "Taxable Amount" := PostedPayrollDocLine."Taxable Amount";
            Quantity := PostedPayrollDocLine.Quantity;
            "Calc Group" := PostedPayrollDocLine."Calc Group";
            "Calendar Code" := PostedPayrollDocLine."Calendar Code";
            "Directory Code" := PostedPayrollDocLine."Directory Code";
            "Calc Type Code" := PostedPayrollDocLine."Calc Type Code";
            "Calculate Priority" := PostedPayrollDocLine.Priority;
            "AE Period From" := PostedPayrollDocLine."AE Period From";
            "AE Period To" := PostedPayrollDocLine."AE Period To";
            "Print Priority" := PostedPayrollDocLine."Print Priority";
            "Org. Unit Code" := PostedPayrollDocLine."Org. Unit Code";
            "Pay Type" := PostedPayrollDocLine."Pay Type";
            "Employee Payroll Account No." := PostedPayrollDocLine."Employee Account No.";
            "Org. Unit Code" := PostedPayrollDocLine."Org. Unit Code";
            "Source Pay" := PostedPayrollDocLine."Source Pay";
            "Working Days" := PostedPayrollDocLine."Planned Days";
            "Working Hours" := PostedPayrollDocLine."Planned Hours";
            "Payment Days" := PostedPayrollDocLine."Payment Days";
            "Payment Hours" := PostedPayrollDocLine."Payment Hours";
            "Payment Percent" := PostedPayrollDocLine."Payment Percent";
            "Payment Source" := PostedPayrollDocLine."Payment Source";
            "Days Not Paid" := PostedPayrollDocLine."Days Not Paid";
            "Global Dimension 1 Code" := PostedPayrollDocLine."Shortcut Dimension 1 Code";
            "Global Dimension 2 Code" := PostedPayrollDocLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := PostedPayrollDocLine."Dimension Set ID";
            "Code OKATO" := PostedPayrollDocLine."Code OKATO";
            "Code KPP" := PostedPayrollDocLine."Code KPP";
            "Vacation Posting Group" := PostedPayrollDocLine."Vacation Posting Group";
            "Action Start Date" := PostedPayrollDocLine."Action Starting Date";
            "Action End Date" := PostedPayrollDocLine."Action Ending Date";
        end;
    end;

    [Scope('OnPrem')]
    procedure PostedPayrDocLineToGenJnlLine(PostedPayrollDocLine: Record "Posted Payroll Document Line"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        with GenJnlLine do begin
            "Account Type" := "Account Type"::"G/L Account";
            "Document Type" := 0;
            "Document No." := PostedPayrollDocLine."Document No.";
            Description := PostedPayrollDocLine.Description;
            Amount := PostedPayrollDocLine."Payroll Amount";
            "Amount (LCY)" := PostedPayrollDocLine."Payroll Amount";
            "Check Printed" := PostedPayrollDocLine."Pay-Sheet Print";
            "Document Date" := "Posting Date";
            "System-Created Entry" := true;
            "Source Type" := "Source Type"::Employee;
            "Source No." := PostedPayrollDocLine."Employee No.";
            "Shortcut Dimension 1 Code" := PostedPayrollDocLine."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := PostedPayrollDocLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := PostedPayrollDocLine."Dimension Set ID";
            if ((PostedPayrollDocLine."Posting Type" = 1) and (PostedPayrollDocLine."Payroll Amount" < 0)) or
               ((PostedPayrollDocLine."Posting Type" = 2) and (PostedPayrollDocLine."Payroll Amount" > 0)) or
               ((PostedPayrollDocLine."Posting Type" = 3) and (PostedPayrollDocLine."Payroll Amount" > 0))
            then
                Validate(Correction, true);
        end;
    end;

    [Scope('OnPrem')]
    procedure PayrElementToPayrLedgEntry(PayrollElement: Record "Payroll Element"; var PayrollLedgerEntry: Record "Payroll Ledger Entry")
    begin
        with PayrollLedgerEntry do begin
            "Element Type" := PayrollElement.Type;
            "Element Group" := PayrollElement."Element Group";
            "Posting Type" := PayrollElement."Posting Type";
            "Bonus Type" := PayrollElement."Bonus Type";
            if "Source Pay" = 0 then
                "Source Pay" := PayrollElement."Source Pay";
            "FSI Base" := PayrollElement."FSI Base";
            "Federal FMI Base" := PayrollElement."Federal FMI Base";
            "Territorial FMI Base" := PayrollElement."Territorial FMI Base";
            "Pension Fund Base" := PayrollElement."PF Base";
            "Income Tax Base" := PayrollElement."Income Tax Base";
            "FSI Injury Base" := PayrollElement."FSI Injury Base";
        end;
    end;

    [Scope('OnPrem')]
    procedure ReverseAmount()
    begin
        with PayrollDocLine do begin
            Amount := -Amount;
            "Payroll Amount" := -"Payroll Amount";
            "Taxable Amount" := -"Taxable Amount";
            Quantity := -Quantity;
            "Payment Days" := -"Payment Days";
            "Payment Hours" := -"Payment Hours";
            "Days Not Paid" := -"Days Not Paid";
            "Original Amount" := -"Original Amount";
            "Corr. Amount" := -"Corr. Amount";
            "Corr. Amount 2" := -"Corr. Amount 2";
            "Amount (ACY)" := -"Amount (ACY)";
            "Days To Exclude" := -"Days To Exclude";
        end;
    end;

    [Scope('OnPrem')]
    procedure AggregateTaxes(var TempPayrollDocLine: Record "Payroll Document Line")
    var
        PayrollDocLineFund: Record "Payroll Document Line" temporary;
        TempPayrollDocLine2: Record "Payroll Document Line" temporary;
        PayrollDocCalculate: Codeunit "Payroll Document - Calculate";
        YTDTaxableAmount: Decimal;
        CurrPeriodTaxableAmount: Decimal;
        YTDTaxAmount: Decimal;
        YTDPostedTaxAmount: Decimal;
        CurrPeriodTaxAmount: Decimal;
        ResultFlag: Option;
        PeriodCode: Code[10];
        Sign: Integer;
    begin
        PayrollDocBuffer.Reset;
        PayrollDocBuffer.DeleteAll;
        NextDocBufferEntryNo := 0;

        // copy fund lines
        TempPayrollDocLine.SetRange("Element Type", TempPayrollDocLine."Element Type"::Funds);
        TempPayrollDocLine.SetFilter("Posting Type", '>0');
        if TempPayrollDocLine.FindSet then
            repeat
                PayrollDocLineFund := TempPayrollDocLine;
                PayrollDocLineFund.Insert;
            until TempPayrollDocLine.Next = 0;

        // filter accruals lines
        TempPayrollDocLine.SetRange("Posting Type");
        TempPayrollDocLine.SetFilter(
          "Element Type",
          '%1|%2|%3',
          TempPayrollDocLine."Element Type"::Wage,
          TempPayrollDocLine."Element Type"::Bonus,
          TempPayrollDocLine."Element Type"::Other);

        // look through the fund lines
        if PayrollDocLineFund.FindSet then
            repeat
                if PeriodCode <> PayrollDocLineFund."Period Code" then begin
                    // init period variables
                    PayrollDocCalculate.InitPayrollPeriod(
                      PayrollDocLineFund."Period Code", PayrollDocLineFund."Wage Period From");
                    PeriodCode := PayrollDocLineFund."Period Code";
                end;
                if PayrollDocLineFund."Payroll Amount" <> 0 then begin
                    // look through the accruals
                    if TempPayrollDocLine.FindSet then
                        repeat
                            if TempPayrollDocLine."Payroll Amount" <> 0 then
                                // is accrual a base for current tax
                                if CheckTaxBase(TempPayrollDocLine."Element Code", PayrollDocLineFund."Element Code") then
                                    // add accrual to the document buffer
                                    AddLineToDocBuffer(TempPayrollDocLine, PayrollDocLineFund);
                        until TempPayrollDocLine.Next = 0;

                    // Year to date taxable amount (posted)
                    // ¡á½«ú«óá´ íáºá ß ¡áþá½á ú«ñá »« ÒþÔÑ¡¡Ù¼ «»ÑÓáµ¿´¼
                    PayrollDocCalculate.CalculateFunction(PayrollDocLineFund, 2003, YTDTaxableAmount, ResultFlag);

                    // current period taxable amount
                    // íáºá ¡á½«ú« ºá ÔÑ¬ÒÚ¿® »ÑÓ¿«ñ (¼«ª¡« óº´Ôý ¿º »«½´ ßÔÓ«¬¿)
                    // PayrollDocCalculate.CalculateFunction(PayrollDocLineFund,220,CurrPeriodTaxableAmount,ResultFlag);
                    CurrPeriodTaxableAmount := PayrollDocLineFund."Taxable Amount";

                    // year to date tax posted
                    // ßÒ¼¼á ¡á½«úá ÒþÔÑ¡¡«ú« ß ¡áþá½á ú«ñá
                    PayrollDocCalculate.CalculateFunction(PayrollDocLineFund, 2005, YTDPostedTaxAmount, ResultFlag);

                    // look through buffer lines for current fund
                    PayrollDocBuffer.Reset;
                    PayrollDocBuffer.SetRange("Element Code", PayrollDocLineFund."Element Code");
                    if PayrollDocBuffer.FindSet then
                        repeat
                            Sign := GetSignFactor(PayrollDocBuffer."Base Amount");

                            // ÒóÑ½¿þ¿Ôý íáºÒ ¡á½«úá
                            YTDTaxableAmount := YTDTaxableAmount + Sign * PayrollDocBuffer."Base Amount";

                            // óÙþ¿ß½¿Ôý ßÒ¼¼Ò ¡á½«úá ß ÒþÑÔ«¼ íáºÙ ÔÑ¬ÒÚÑ® ßÔÓ«¬¿ íÒõÑÓá
                            TempPayrollDocLine2."Document No." := PayrollDocLineFund."Document No.";
                            TempPayrollDocLine2."Employee No." := PayrollDocLineFund."Employee No.";
                            TempPayrollDocLine2."Period Code" := PayrollDocLineFund."Period Code";
                            TempPayrollDocLine2."Element Code" := PayrollDocLineFund."Element Code";
                            YTDTaxAmount := PayrollDocCalculate.Withholding(TempPayrollDocLine2, YTDTaxableAmount);
                            CurrPeriodTaxAmount := Sign * YTDTaxAmount + Sign * YTDPostedTaxAmount; // FIX - to +
                            PayrollDocBuffer."Tax Amount" := CurrPeriodTaxAmount;
                            PayrollDocBuffer.Modify;

                            // ñ«íáó¿Ôý ¡á®ñÑ¡¡Ò¯ ßÒ¼¼Ò ¡á½«úá ¬ ßÒ¼¼Ñ ÒªÑ ÒþÔÑ¡¡«ú« ¡á½«úá
                            YTDPostedTaxAmount := YTDPostedTaxAmount - Sign * CurrPeriodTaxAmount;  // FIX + to -
                        until PayrollDocBuffer.Next = 0;
                end;
            until PayrollDocLineFund.Next = 0;
    end;

    local procedure AddLineToDocBuffer(TempPayrollDocLine: Record "Payroll Document Line"; PayrollDocLineFund: Record "Payroll Document Line")
    begin
        // insert or update payroll document buffer line
        PayrollDocBuffer.SetRange("Payroll Posting Group", TempPayrollDocLine."Posting Group");
        PayrollDocBuffer.SetRange("Element Code", PayrollDocLineFund."Element Code");
        if PayrollDocBuffer.FindFirst then begin
            if PayrollDocLineFund."Dimension Set ID" = TempPayrollDocLine."Dimension Set ID" then begin
                PayrollDocBuffer."Base Amount" :=
                  PayrollDocBuffer."Base Amount" + TempPayrollDocLine."Payroll Amount";
                PayrollDocBuffer.Modify;
            end else
                InsertNewDocBufferLine(TempPayrollDocLine, PayrollDocLineFund);
        end else
            InsertNewDocBufferLine(TempPayrollDocLine, PayrollDocLineFund);
    end;

    local procedure InsertNewDocBufferLine(TempPayrollDocLine: Record "Payroll Document Line"; PayrollDocLineFund: Record "Payroll Document Line")
    var
        DimensionSetIDArr: array[10] of Integer;
        DummyGlobalDim: array[2] of Code[10];
    begin
        NextDocBufferEntryNo := NextDocBufferEntryNo + 1;
        PayrollDocBuffer.Init;
        PayrollDocBuffer."Entry No." := NextDocBufferEntryNo;
        PayrollDocBuffer."Element Code" := PayrollDocLineFund."Element Code";
        PayrollDocBuffer."Payroll Posting Group" := TempPayrollDocLine."Posting Group";
        PayrollDocBuffer."Base Amount" := TempPayrollDocLine."Payroll Amount";
        DimensionSetIDArr[1] := TempPayrollDocLine."Dimension Set ID";
        DimensionSetIDArr[2] := PayrollDocLineFund."Dimension Set ID";

        PayrollDocBuffer."Dimension Set ID" :=
          DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, DummyGlobalDim[1], DummyGlobalDim[2]);
        PayrollDocBuffer."Payroll Ledger Entry No." := PayrollDocLineFund."Payroll Ledger Entry No.";
        PayrollDocBuffer.Insert;
    end;

    [Scope('OnPrem')]
    procedure GetPayrollDocBuffer(var NewPayrollDocBuffer: Record "Payroll Document Buffer")
    begin
        PayrollDocBuffer.Reset;
        if PayrollDocBuffer.FindSet then
            repeat
                NewPayrollDocBuffer := PayrollDocBuffer;
                NewPayrollDocBuffer.Insert;
            until PayrollDocBuffer.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckTaxBase(AccrualElementCode: Code[20]; TaxElementCode: Code[20]): Boolean
    var
        TempPayrollElement: Record "Payroll Element" temporary;
        AccrualPayrollElement: Record "Payroll Element";
        PayrollBaseAmount: Record "Payroll Base Amount";
    begin
        AccrualPayrollElement.Get(AccrualElementCode);
        TempPayrollElement := AccrualPayrollElement;
        TempPayrollElement.Insert;
        with PayrollBaseAmount do begin
            SetRange("Element Code", TaxElementCode);
            if FindSet then
                repeat
                    if "Element Type Filter" <> '' then
                        TempPayrollElement.SetFilter(Type, "Element Type Filter");
                    if "Element Code Filter" <> '' then
                        TempPayrollElement.SetFilter(Code, "Element Code Filter");
                    if "Element Group Filter" <> '' then
                        TempPayrollElement.SetFilter("Element Group", "Element Group Filter");
                    if "Posting Type Filter" <> '' then
                        TempPayrollElement.SetFilter("Posting Type", "Posting Type Filter");
                    if TempPayrollElement.IsEmpty then
                        exit(false);
                    case true of
                        "Income Tax Base Filter" = "Income Tax Base Filter"::Impose:
                            if AccrualPayrollElement."Income Tax Base" then
                                exit(true);
                        "FSI Injury Base Filter" = "FSI Injury Base Filter"::Impose:
                            if AccrualPayrollElement."FSI Injury Base" then
                                exit(true);
                        "FSI Base Filter" = "FSI Base Filter"::Impose:
                            if AccrualPayrollElement."FSI Base" then
                                exit(true);
                        "Federal FMI Base Filter" = "Federal FMI Base Filter"::Impose:
                            if AccrualPayrollElement."Federal FMI Base" then
                                exit(true);
                        "Territorial FMI Base Filter" = "Territorial FMI Base Filter"::Impose:
                            if AccrualPayrollElement."Territorial FMI Base" then
                                exit(true);
                        "PF Base Filter" = "PF Base Filter"::Impose:
                            if AccrualPayrollElement."PF Base" then
                                exit(true);
                    end;
                until Next = 0;
        end;
    end;

    local procedure SetPayrollCategoryCode()
    begin
        with PayrollLedgEntry do begin
            if Employee.IsInvalid("Posting Date") then
                "Insurance Fee Category Code" := '03'
            else
                "Insurance Fee Category Code" := '01';
        end;
    end;

    local procedure GetSignFactor(Amount: Decimal): Integer
    begin
        if Amount >= 0 then
            exit(1);
        exit(-1);
    end;

    local procedure CalcRoundedTaxAmt(var PassedGenJnlLine: Record "Gen. Journal Line"; PayrollDocBuf: Record "Payroll Document Buffer" temporary; var PayrollDocBufRemainder: Record "Payroll Document Buffer")
    begin
        with PassedGenJnlLine do begin
            GetPayrollDocBufRemainder(PayrollDocBufRemainder, PayrollDocBuf."Element Code");
            Validate(
              Amount, PayrollDocBufRemainder."Tax Amount" + PayrollDocBuf."Tax Amount");
            PayrollDocBufRemainder."Tax Amount" :=
              PayrollDocBuf."Tax Amount" - Amount;
            PayrollDocBufRemainder.Modify;
        end;
    end;

    local procedure GetPayrollDocBufRemainder(var PayrollDocBufRemainder: Record "Payroll Document Buffer"; ElementCode: Code[20])
    var
        NextEntryNo: Integer;
    begin
        with PayrollDocBufRemainder do begin
            SetRange("Element Code", ElementCode);
            if not FindFirst then begin
                SetRange("Element Code");
                if FindLast then
                    NextEntryNo := "Entry No.";
                NextEntryNo += 1;
                Init;
                "Entry No." := NextEntryNo;
                "Element Code" := ElementCode;
                Insert;
            end;
        end;
    end;
}

